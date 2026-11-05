// Salve em src/lib/downloads.svelte.ts

export type StatusDownload = "fila" | "baixando" | "concluido" | "erro" | "cancelado";

export type Download = {
	id: number;
	titulo: string;
	status: StatusDownload;
	recebido: number; // bytes recebidos até agora
	total: number | null; // null = tamanho desconhecido (barra indeterminada)
	erro?: string;
};

// O que o seu código de download recebe para reportar progresso e poder ser cancelado.
export type Contexto = {
	progresso: (recebido: number, total?: number) => void;
	sinal: AbortSignal;
};
export type Executor = (ctx: Contexto) => Promise<void>;

// Prefixo das mensagens de console desta fila (o popup filtra por ele).
export const PREFIXO_LOG = "[download]";

// Quantos downloads rodam ao mesmo tempo. Os demais esperam na fila.
const SIMULTANEOS = 2;

export const downloads = $state<Download[]>([]);

const pendentes = new Map<number, { executor: Executor; controller: AbortController }>();
let proximoId = 0;

export function enfileirarDownload(titulo: string, executor: Executor): number {
	const id = proximoId++;
	downloads.push({ id, titulo, status: "fila", recebido: 0, total: null });
	pendentes.set(id, { executor, controller: new AbortController() });
	console.log(`${PREFIXO_LOG} "${titulo}" entrou na fila`);
	processarFila();
	return id;
}

export function cancelarDownload(id: number) {
	const item = downloads.find((d) => d.id === id);
	if (!item) return;

	if (item.status === "fila") {
		item.status = "cancelado";
		pendentes.delete(id);
		console.log(`${PREFIXO_LOG} "${item.titulo}" cancelado antes de começar`);
	} else if (item.status === "baixando") {
		// Só interrompe de verdade se o seu download respeitar o `sinal` (AbortSignal).
		pendentes.get(id)?.controller.abort();
	}
}

export function limparFinalizados() {
	for (let i = downloads.length - 1; i >= 0; i--) {
		const s = downloads[i].status;
		if (s !== "fila" && s !== "baixando") downloads.splice(i, 1);
	}
}

function processarFila() {
	let ativos = downloads.filter((d) => d.status === "baixando").length;
	for (const item of downloads) {
		if (ativos >= SIMULTANEOS) break;
		if (item.status !== "fila") continue;
		ativos++;
		executar(item);
	}
}

async function executar(item: Download) {
	const { executor, controller } = pendentes.get(item.id)!;
	item.status = "baixando";
	console.log(`${PREFIXO_LOG} iniciando "${item.titulo}"`);

	try {
		await executor({
			sinal: controller.signal,
			progresso: (recebido, total) => {
				item.recebido = recebido;
				if (total != null) item.total = total;
			},
		});
		if (controller.signal.aborted) {
			item.status = "cancelado";
			console.log(`${PREFIXO_LOG} "${item.titulo}" cancelado`);
		} else {
			item.status = "concluido";
			console.log(`${PREFIXO_LOG} "${item.titulo}" concluído (${item.recebido} bytes)`);
		}
	} catch (e) {
		if (controller.signal.aborted) {
			item.status = "cancelado";
			console.log(`${PREFIXO_LOG} "${item.titulo}" cancelado`);
		} else {
			item.status = "erro";
			item.erro = e instanceof Error ? e.message : String(e);
			console.error(`${PREFIXO_LOG} erro em "${item.titulo}": ${item.erro}`);
		}
	} finally {
		pendentes.delete(item.id);
		processarFila(); // libera a vaga para o próximo da fila
	}
}