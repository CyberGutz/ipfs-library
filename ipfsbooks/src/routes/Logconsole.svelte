<script lang="ts">
	import { logs } from "$lib/logger.svelte";

	const cor = {
		log: "",
		info: "",
		warn: "text-amber-300",
		error: "text-red-300",
	};

	let caixa: HTMLDivElement | undefined = $state();

	// Rola para a última mensagem sempre que chegar uma nova
	$effect(() => {
		logs.length;
		caixa?.scrollTo({ top: caixa.scrollHeight });
	});
</script>

<div
	bind:this={caixa}
	role="log"
	aria-live="polite"
	class="mx-auto mt-4 max-h-60 w-full max-w-2xl overflow-y-auto bg-olive-800 p-3 text-left font-mono text-sm text-olive-50"
>
	{#each logs as entrada (entrada.id)}
		<div class="break-words whitespace-pre-wrap {cor[entrada.nivel]}">
			{entrada.texto}
		</div>
	{:else}
		<div class="opacity-60">Aguardando mensagens...</div>
	{/each}
</div>