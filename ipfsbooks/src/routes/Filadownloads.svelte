<script lang="ts">
	import { onMount } from "svelte";
	import {
		downloads,
		cancelarDownload,
		limparFinalizados,
		PREFIXO_LOG,
		type Download,
	} from "$lib/downloads.svelte.js";
	import { logs, capturarConsole, type Nivel } from "$lib/logger.svelte.js";

	let minimizado = $state(false);
	let mostrarTudo = $state(false); // false = só logs de download; true = todo o console
	let caixaLogs: HTMLDivElement | undefined = $state();

	// Idempotente: pode ser chamado também no _page.svelte sem problema.
	onMount(capturarConsole);

	let ativos = $derived(downloads.filter((d) => d.status === "baixando").length);
	let naFila = $derived(downloads.filter((d) => d.status === "fila").length);
	let finalizados = $derived(
		downloads.filter((d) => d.status !== "fila" && d.status !== "baixando").length,
	);
	let logsVisiveis = $derived(
		mostrarTudo ? logs : logs.filter((l) => l.texto.startsWith(PREFIXO_LOG)),
	);

	// Rola os logs até a última mensagem
	$effect(() => {
		logsVisiveis.length;
		caixaLogs?.scrollTo({ top: caixaLogs.scrollHeight });
	});

	const corLog: Record<Nivel, string> = {
		log: "",
		info: "",
		warn: "text-amber-300",
		error: "text-red-300",
	};

	function bytes(n: number): string {
		if (n < 1024) return `${n} B`;
		if (n < 1024 ** 2) return `${(n / 1024).toFixed(1)} KB`;
		return `${(n / 1024 ** 2).toFixed(1)} MB`;
	}

	function porcentagem(d: Download): number {
		return d.total ? Math.min(100, Math.round((d.recebido / d.total) * 100)) : 0;
	}
</script>

{#if downloads.length > 0}
	<aside
		aria-label="Fila de downloads"
		class="fixed right-3 bottom-20 z-30 w-[calc(100%-1.5rem)] border-2 border-olive-800 bg-olive-50 shadow-lg sm:w-96"
	>
		<header class="flex items-center justify-between gap-2 bg-olive-800 px-3 py-2 text-olive-50">
			<h2 class="font-bold">
				Downloads
				<span class="font-normal">({ativos} ativo{ativos === 1 ? "" : "s"}, {naFila} na fila)</span>
			</h2>
			<div class="flex items-center gap-3">
				{#if finalizados > 0}
					<button class="text-sm underline" onclick={limparFinalizados}>Limpar</button>
				{/if}
				<button
					onclick={() => (minimizado = !minimizado)}
					aria-expanded={!minimizado}
					aria-label={minimizado ? "Expandir fila de downloads" : "Minimizar fila de downloads"}
				>
					{minimizado ? "▴" : "▾"}
				</button>
			</div>
		</header>

		{#if !minimizado}
			<ul class="max-h-56 divide-y divide-olive-200 overflow-y-auto">
				{#each downloads as d (d.id)}
					<li class="p-3 text-sm">
						<div class="flex items-start justify-between gap-2">
							<span class="min-w-0 flex-1 truncate font-bold" title={d.titulo}>{d.titulo}</span>
							{#if d.status === "fila" || d.status === "baixando"}
								<button
									onclick={() => cancelarDownload(d.id)}
									aria-label="Cancelar download de {d.titulo}"
								>
									✕
								</button>
							{/if}
						</div>

						{#if d.status === "baixando"}
							{#if d.total}
								<progress class="mt-1 w-full accent-olive-800" value={d.recebido} max={d.total}></progress>
								<span>{bytes(d.recebido)} / {bytes(d.total)} ({porcentagem(d)}%)</span>
							{:else}
								<!-- sem total conhecido: barra indeterminada -->
								<progress class="mt-1 w-full accent-olive-800"></progress>
								<span>{bytes(d.recebido)}</span>
							{/if}
						{:else if d.status === "fila"}
							<span class="opacity-70">Na fila</span>
						{:else if d.status === "concluido"}
							<span>Concluído ✓ ({bytes(d.recebido)})</span>
						{:else if d.status === "cancelado"}
							<span class="opacity-70">Cancelado</span>
						{:else}
							<span class="text-red-700">Erro: {d.erro}</span>
						{/if}
					</li>
				{/each}
			</ul>

			<details class="border-t-2 border-olive-800">
				<summary class="cursor-pointer px-3 py-2 font-bold">Logs</summary>
				<label class="flex items-center gap-2 px-3 pb-2 text-sm">
					<input type="checkbox" bind:checked={mostrarTudo} />
					Mostrar todo o console
				</label>
				<div
					bind:this={caixaLogs}
					role="log"
					aria-live="polite"
					class="max-h-40 overflow-y-auto bg-olive-800 p-2 font-mono text-xs text-olive-50"
				>
					{#each logsVisiveis as l (l.id)}
						<div class="break-words whitespace-pre-wrap {corLog[l.nivel]}">{l.texto}</div>
					{:else}
						<div class="opacity-60">Sem mensagens.</div>
					{/each}
				</div>
			</details>
		{/if}
	</aside>
{/if}