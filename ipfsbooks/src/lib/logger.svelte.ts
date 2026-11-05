export type Nivel = "log" | "info" | "warn" | "error";
export type Entrada = { id: number; nivel: Nivel; texto: string };

export const logs = $state<Entrada[]>([]);

const MAX_LOGS = 200;
let proximoId = 0;
let instalado = false;

function formatar(arg: unknown): string {
	if (arg instanceof Error) return arg.stack ?? arg.message;
	if (typeof arg === "string") return arg;
	try {
		return JSON.stringify(arg);
	} catch {
		return String(arg); // referência circular, BigInt etc.
	}
}

function registrar(nivel: Nivel, texto: string) {
	if (texto.length > 500) texto = texto.slice(0, 500) + "…";
	// queueMicrotask evita mutar estado no meio de um $derived/$effect que chamou console.log
	queueMicrotask(() => {
		logs.push({ id: proximoId++, nivel, texto });
		if (logs.length > MAX_LOGS) logs.shift();
	});
}

// Chame uma vez, no navegador (ex.: no começo do onMount).
export function capturarConsole() {
	if (instalado) return;
	instalado = true;

	for (const nivel of ["log", "info", "warn", "error"] as const) {
		const original = console[nivel].bind(console);
		console[nivel] = (...args: unknown[]) => {
			original(...args); // continua aparecendo no DevTools
			registrar(nivel, args.map(formatar).join(" "));
		};
	}

	// Erros que não passam por console.error
	window.addEventListener("error", (e) => registrar("error", e.message));
	window.addEventListener("unhandledrejection", (e) =>
		registrar("error", `Promise rejeitada: ${formatar(e.reason)}`),
	);
}