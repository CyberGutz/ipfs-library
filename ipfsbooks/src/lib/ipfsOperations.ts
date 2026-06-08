import type { Helia } from "helia";
import { startHelia } from "./heliaInstance";
import type { UnixFS } from "@helia/unixfs";
import type { CID } from "multiformats";

const instancia = await startHelia();
let helia: Helia, fs:UnixFS;

helia = instancia.helia;
fs = instancia.fs;

export async function readCID(cid:CID){
    const chunks = [];

    for await (const chunk of fs.cat(cid)){
        chunks.push(chunk);
    }

    const tamanhoTotal = chunks.reduce((acc, val) => acc + val.length, 0);
    const arq = new Uint8Array(tamanhoTotal);

    let offset = 0;
    for (const chunk of chunks){
        arq.set(chunk, offset);
        offset += chunk.length;
    }

    return arq;
}

export async function downloadCID(cid:CID, nome:string, tipoMime:string){
    const bytes = await readCID(cid);

    const blob = new Blob([bytes], { type: tipoMime })
    const url = URL.createObjectURL(blob);

    const link = document.createElement('a');
    link.href = url;
    link.download = nome;
    document.body.appendChild(link);
    link.click()

    document.body.removeChild(link);
    URL.revokeObjectURL(url);
}

export async function provideCID(cid:CID){
    try{
        await helia.routing.provide(cid);
    } catch (err){
        console.error("Failed providing {cid}")
    }
}

export async function pinCID(cid:CID){
    try{
        await helia.pins.add(cid);
    }
    catch(err){
        console.error("Error ocurred while pinning {cid}")
    }

    try{
        await helia.pins.isPinned(cid);
    }catch(err){
        console.error("{Error: cid.toString()} did not stay pinned")
    }
}