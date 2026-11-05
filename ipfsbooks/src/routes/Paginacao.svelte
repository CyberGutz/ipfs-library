<script lang="ts">
	import { MediaQuery } from "svelte/reactivity";

	// `atual` é 0-based (igual ao seu `page`); na tela mostramos atual + 1.
	let {
		atual,
		total,
		onChange,
	}: {
		atual: number;
		total: number;
		onChange: (pagina: number) => void;
	} = $props();

	// Em telas pequenas mostramos menos números para caber na largura.
	const telaGrande = new MediaQuery("min-width: 640px", false);
	let vizinhos = $derived(telaGrande.current ? 2 : 1);
	let itens = $derived(gerarPaginas(atual + 1, total, vizinhos));

	// Retorna algo como [1, 2, 3, 4, 5, "…", 100] (números 1-based).
	function gerarPaginas(
		paginaAtual: number,
		totalPaginas: number,
		viz: number,
	): (number | "…")[] {
		const tamanhoJanela = viz * 2 + 1;

		// Janela de números ao redor da página atual, sem sair de [1, total].
		const inicio = Math.max(
			1,
			Math.min(paginaAtual - viz, totalPaginas - tamanhoJanela + 1),
		);
		const fim = Math.min(totalPaginas, inicio + tamanhoJanela - 1);

		// Primeira e última página sempre aparecem.
		const visiveis = new Set<number>([1, totalPaginas]);
		for (let i = inicio; i <= fim; i++) visiveis.add(i);

		const ordenados = [...visiveis].sort((a, b) => a - b);
		const resultado: (number | "…")[] = [];
		let anterior = 0;
		for (const n of ordenados) {
			if (n - anterior === 2) resultado.push(anterior + 1); // buraco de 1 número: mostra ele em vez de "…"
			else if (n - anterior > 2) resultado.push("…");
			resultado.push(n);
			anterior = n;
		}
		return resultado;
	}

	const botao =
		"inline-flex h-10 min-w-10 items-center justify-center gap-1 px-2 hover:bg-olive-800 hover:text-olive-50 disabled:pointer-events-none disabled:opacity-40";
	const botaoAtual = "bg-olive-800 font-bold text-olive-50";
</script>

<nav
	aria-label="Paginação"
	class="fixed inset-x-0 bottom-0 z-20 border-t-2 border-olive-800 bg-olive-50 pb-[env(safe-area-inset-bottom)]"
>
	<ul class="mx-auto flex max-w-5xl items-center justify-center gap-1 p-2">
		<li>
			<button
				class={botao}
				disabled={atual === 0}
				onclick={() => onChange(atual - 1)}
				aria-label="Página anterior"
			>
				‹<span class="hidden sm:inline">Anterior</span>
			</button>
		</li>

		{#each itens as item}
			<li>
				{#if item === "…"}
					<span class="inline-flex h-10 min-w-6 items-center justify-center">…</span>
				{:else}
					<button
						class="{botao} {item === atual + 1 ? botaoAtual : ''}"
						aria-current={item === atual + 1 ? "page" : undefined}
						aria-label="Página {item}"
						onclick={() => onChange(item - 1)}
					>
						{item}
					</button>
				{/if}
			</li>
		{/each}

		<li>
			<button
				class={botao}
				disabled={atual >= total - 1}
				onclick={() => onChange(atual + 1)}
				aria-label="Próxima página"
			>
				<span class="hidden sm:inline">Próxima</span>›
			</button>
		</li>
	</ul>
</nav>