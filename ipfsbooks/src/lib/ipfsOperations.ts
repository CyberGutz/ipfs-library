import type { Helia } from "helia";
import { startHelia } from "./heliaInstance";
import type { UnixFS } from "@helia/unixfs";
import { CID } from "multiformats";
import { base32 } from "multiformats/bases/base32";

function cleanCID(cid: string) {
	const clean = cid.trim();

	if (clean.startsWith('Qm'))
		return CID.parse(clean);
	else
		return CID.parse(clean, base32);
}

const LOG = "[download]";
type Progresso = (recebido:number, total?:number) => void;

export async function readCID(
	cidString: string,
	onProgress?: Progresso,
	sinal?: AbortSignal,
) {
	const { fs } = await startHelia();
	sinal?.throwIfAborted();
 
	const cid = cleanCID(cidString);
	console.log(`${LOG} lendo CID ${cid}`);
 
	// Tamanho total do arquivo (lê só o bloco raiz). Se falhar, a barra fica indeterminada.
	let total: number | undefined;
	try {
		const info = await fs.stat(cid, { signal: sinal });
		total = Number(info.fileSize); // fileSize é bigint
	} catch {
		sinal?.throwIfAborted(); // se o erro foi o cancelamento, propaga
		console.warn(`${LOG} não consegui obter o tamanho do arquivo`);
	}
 
	const chunks: Uint8Array[] = [];
	let recebido = 0;
 
	for await (const chunk of fs.cat(cid, { signal: sinal })) {
		sinal?.throwIfAborted();
		chunks.push(chunk);
		recebido += chunk.length;
		onProgress?.(recebido, total);
	}
 
	const arq = new Uint8Array(recebido);
	let offset = 0;
	for (const chunk of chunks) {
		arq.set(chunk, offset);
		offset += chunk.length;
	}
 
	return arq;
}
 
export async function downloadCID(
	cidString: string,
	nome: string,
	tipoMime: string,
	onProgress?: Progresso,
	sinal?: AbortSignal,
) {
	const bytes = await readCID(cidString, onProgress, sinal);
	sinal?.throwIfAborted(); // cancelou no final? então não salva o arquivo
 
	const blob = new Blob([bytes], { type: tipoMime });
	const url = URL.createObjectURL(blob);
 
	const link = document.createElement("a");
	link.href = url;
	link.download = nome;
	document.body.appendChild(link);
	link.click();
 
	document.body.removeChild(link);
	URL.revokeObjectURL(url);
 
	console.log(`${LOG} arquivo salvo: ${nome} (${bytes.length} bytes)`);
 
	// Sem await: o download já terminou para o usuário, então a vaga da fila é liberada
	// agora, e um erro de pin/provide não faz um download bem-sucedido aparecer como "erro".
	void fixarEDivulgar(cidString);
}
 
async function fixarEDivulgar(cidString: string) {
	try {
		console.log(`${LOG} fixando e anunciando o CID ${cidString}`);
		await pinCID(cidString);
		await provideCID(cidString);
		console.log(`${LOG} CID fixado e anunciado na rede`);
	} catch (e) {
		console.error(`${LOG} falha ao fixar/anunciar o CID:`, e);
	}
}


export async function provideCID(cidString: string) {
	const { helia } = await startHelia();
	const cid = cleanCID(cidString);
	try {
		await helia.routing.provide(cid);
	} catch (err) {
		console.error(`Failed providing ${cid}: ${err}`)
	}
}

export async function pinCID(cidString: string = "") {
	const { helia, fs } = await startHelia();
	const cid = cleanCID(cidString);

	console.log("Tentativa de pinar o cid na rede", cid)

	for await(const pinnedCid of helia.pins.add(cid))
		console.log("Pinado", pinnedCid.toString())

	await helia.pins.isPinned(cid) ?
		console.log(`O CID ${cid.toString()} se ma nteu pinado com sucesso`) :
		console.log(`${cid.toString()} não se manteu pinado!`);
}
