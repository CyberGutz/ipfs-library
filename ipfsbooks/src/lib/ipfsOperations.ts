import type { Helia } from "helia";
import { startHelia } from "./heliaInstance";
import type { UnixFS } from "@helia/unixfs";
import { CID } from "multiformats";
import { base32 } from "multiformats/bases/base32";

function cleanCID(cid: string){
	const clean = cid.trim();

	if (clean.startsWith('Qm'))
		return CID.parse(clean);
	else
		return CID.parse(clean, base32);
}

export async function readCID(cidString:string){

	const { fs } = await startHelia();

	console.log("iniciou o helia: ", fs);
	 console.log(cidString);

    const cid = cleanCID(cidString);

    console.log(cid);

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

export async function downloadCID(cidString:string, nome:string, tipoMime:string){
    const bytes = await readCID(cidString);

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

export async function provideCID(cidString:string){
	const { helia } = await startHelia();
    const cid = cleanCID(cidString);
    try{
        await helia.routing.provide(cid);
    } catch (err){
        console.error(`Failed providing {cid}`)
    }
}

export async function pinCID(cidString:string){
	const { helia } = await startHelia();
    const cid = cleanCID(cidString);
    try{
        await helia.pins.add(cid);
    }
    catch(err){
        console.error("Error ocurred while pinning {cid}")
    }

    try{
        await helia.pins.isPinned(cid);
    }catch(err){
        console.error(`{Error: cid.toString()} did not stay pinned`)
    }
}
