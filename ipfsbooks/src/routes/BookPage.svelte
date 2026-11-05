<script lang="ts">
	let { selecionado } = $props();
	import { downloadCID } from "../lib/ipfsOperations";
	import { enfileirarDownload } from "$lib/downloads.svelte";

	const botao =
		"border-2 border-olive-800 bg-olive-800 px-4 py-2 text-center text-olive-50 hover:bg-olive-50 hover:text-olive-800";
	const linha = "flex flex-wrap items-center justify-between gap-3";
</script>

<div class="mx-auto grid max-w-6xl grid-cols-1 gap-8 p-3 md:grid-cols-3">
	<!--Título do Livro-->
	<h1 class="text-2xl font-bold md:self-center md:text-center md:text-3xl">
		{selecionado.titulo}
	</h1>

	<!--Informações Gerais-->
	<section>
		<h2 class="mb-3 text-2xl font-bold">Informações Gerais</h2>

		<div class="aspect-[2/3] w-full max-w-60">
			<object
				class="size-full object-cover"
				title="capa"
				data={selecionado.capa}
				type="image/png"
			>
				<object
					class="size-full object-cover"
					title="capaFallbackPNG"
					data="{selecionado.capaFallback}.png"
					type="image/png"
				>
					<img
						class="size-full object-cover"
						src="{selecionado.capaFallback}.jpg"
						alt="Capa de {selecionado.titulo}"
					/>
				</object>
			</object>
		</div>

		<dl class="mt-4 grid grid-cols-[auto_1fr] gap-x-3 gap-y-2">
			<dt class="font-bold">Autor</dt>
			<dd>{selecionado.autor}</dd>
			<dt class="font-bold">Lançamento</dt>
			<dd>{selecionado.ano}</dd>
			<dt class="font-bold">Língua</dt>
			<dd>{selecionado.lingua}</dd>
			<dt class="font-bold">ISBN</dt>
			<dd>{selecionado.isbn}</dd>
			<dt class="font-bold">Categorias</dt>
			<dd>{selecionado.categorias}</dd>
		</dl>
	</section>

	<!--Links de download-->
	<section>
		<h2 class="mb-3 text-2xl font-bold">Links de Download</h2>

		<div class="flex flex-col gap-4">
			<div class={linha}>
				<p>Baixar livro como um arquivo de texto:</p>
				<button
					class={botao}
					onclick={() =>
						enfileirarDownload(
							`${selecionado.titulo} (txt)`,
							({ progresso, sinal }) =>
								downloadCID(
									selecionado.cid,
									selecionado.titulo,
									"text/plain",
									progresso,
									sinal,
								),
						)}
				>
					Download
				</button>
			</div>

			<div class={linha}>
				<p>Baixar livro em epub:</p>
				<a class={botao} href={selecionado.epub} download>Download</a>
			</div>

			<div class={linha}>
				<p>Baixar livro pro Kindle (mobi):</p>
				<!--Descobri que não se pode colocar o nome do arquivo em um link de download que vem de outra origem, então quando
				  o usuário for baixar um .mobi ou um .epub, ele vai ter o nome esquisito da indexação do gutemberg mesmo-->
				<a class={botao} href={selecionado.kindle} download>Download</a>
			</div>
		</div>
	</section>
</div>
