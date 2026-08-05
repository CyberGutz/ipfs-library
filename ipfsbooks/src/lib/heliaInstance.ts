import { createHelia, type Helia } from "helia";
import { IDBBlockstore } from "blockstore-idb";
import { IDBDatastore } from "datastore-idb";
import { unixfs, type UnixFS } from "@helia/unixfs";

import { createLibp2p } from "libp2p";
import { webSockets } from "@libp2p/websockets";
import { webRTC } from "@libp2p/webrtc";
import { circuitRelayTransport } from "@libp2p/circuit-relay-v2";
import { noise } from "@chainsafe/libp2p-noise";
import { yamux } from "@chainsafe/libp2p-yamux";
import { bootstrap } from "@libp2p/bootstrap";
import { identify } from "@libp2p/identify";

import { bitswap,trustlessGateway } from '@helia/block-brokers';

interface HeliaInstance {
    helia: Helia;
    fs: UnixFS;
}

let heliaInstance: Helia | null = null;
let fsInstance: UnixFS | null = null;

const bootstrapNodes = [
    // seu nó local, peerID corrigido — só funciona no mesmo navegador/máquina do daemon
    "/ip4/127.0.0.1/tcp/4003/ws/p2p/12D3KooWERneYkvkxWfiuyegZ4QUHPdgR5K5ea9XERY32fwSeGrM",
    // troque pelo multiaddr do SEU relay público assim que tiver um (ver seção CGNAT abaixo)
];

export async function startHelia(): Promise<HeliaInstance> {
    if (heliaInstance && fsInstance) {
        return { helia: heliaInstance, fs: fsInstance };
    }

    const blockstore = new IDBBlockstore('ipfsbooks-blocks');
    await blockstore.open();

    const datastore = new IDBDatastore('ipfsbooks-data');
    await datastore.open();

    try {
        const node = await createLibp2p({
            transports: [
                webSockets(),
                webRTC(),
                circuitRelayTransport()
            ],
            addresses: {
                listen: ['/p2p-circuit', '/webrtc']
            },
            connectionEncrypters: [noise()],
            streamMuxers: [yamux()],
            peerDiscovery: [
                bootstrap({ list: bootstrapNodes })
            ],
            services: {
                identify: identify()
            }
        });

        heliaInstance = await createHelia({
            blockstore,
            datastore,
            libp2p: node,
            blockBrokers: [
                bitswap(),
                trustlessGateway({ gateways: ['https://trustless-gateway.link'] })
            ]
        });

        fsInstance = unixfs(heliaInstance);

        return { helia: heliaInstance, fs: fsInstance };
    } catch (erro) {
        // evita ficar com singleton "meio inicializado" numa próxima chamada
        heliaInstance = null;
        fsInstance = null;
        throw erro;
    }
}