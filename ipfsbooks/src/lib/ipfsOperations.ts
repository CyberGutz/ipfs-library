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
	
    console.log("Download concluído!. Iniciando tentativa de pinar o cid");
    console.log("Dados pré-referência:");
    console.log(`CID: ${cidString},  bytes: ${bytes}`);
    await pinCID(cidString, bytes);
}

export async function provideCID(cidString:string){
	const { helia } = await startHelia();
    const cid = cleanCID(cidString);
    try{
        await helia.routing.provide(cid);
    } catch (err){
        console.error(`Failed providing ${cid}: ${err}`)
    }
}

export async function pinCID(cidString:string="", bytes:Uint8Array=new Uint8Array(0)){
	const { helia, fs } = await startHelia();
	let objectBytes;

	console.log(`Pinando CID: cidString: ${cidString}, bytes: ${bytes}`);

	bytes.length == 0 ? objectBytes = await readCID(cidString) : objectBytes = bytes;

	console.log("Verificação  OK. objectBytes: ", objectBytes);

	const cid = await fs.addFile({
		content: objectBytes,
		path: `./{cidString}.txt`
	});

	console.log("Objeto adicionado ao IPFS com sucesso. CID retornado: ", cid.toString());

	try{
		console.log("Tentativa de provisionar o cid na rede IPFS..");
		await helia.routing.provide(cid);
	}
	catch(err){
		console.error(`Erro ao provisionar o cid na rede: ${err}`);
	}

	try{
		await helia.pins.add(cid);
		const pin = await helia.pins.get(cid);
		console.log("Arquivo pinado com sucesso!: ", pin);
	}
	catch(err){
		console.error(`Erro ocorrido ao tentar pinar ${cid}: ${err}`)
	}

	try{
		await helia.pins.isPinned(cid) ? 
			console.log(`O CID ${cid.toString()} se manteu pinado com sucesso`) :
			console.log(`${cid.toString()} não se manteu pinado!`);
	}
	catch(err){
		console.error(`Erro ao tentar verificar o estado do pin ${err}`);
	}
}
