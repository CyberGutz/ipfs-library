import { createHelia, type Helia } from "helia";
import { IDBBlockstore } from "blockstore-idb";
import { IDBDatastore } from "datastore-idb";
import { unixfs, type UnixFS } from "@helia/unixfs";

interface heliaInstance{
    helia: Helia
    fs: UnixFS
}

let heliaInstance : Helia | null = null
let fsInstance: UnixFS | null = null

export async function startHelia(): Promise<heliaInstance> {
    if(heliaInstance && fsInstance) {
        return { helia: heliaInstance, fs: fsInstance }
    }


    const blockstore = new IDBBlockstore('ifpsbooks-blocks');
    await blockstore.open();

    const datastore = new IDBDatastore('ipfsbooks-data');
    await datastore.open();

    heliaInstance = await createHelia({
        blockstore: blockstore,
        datastore: datastore
    })

    fsInstance = unixfs(heliaInstance);

    return {
        helia: heliaInstance,
        fs: fsInstance
    }
}