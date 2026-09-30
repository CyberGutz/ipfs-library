<script lang="ts">
	let { selecionado } = $props();
	import { downloadCID } from "../lib/ipfsOperations";
</script>

<div class="grid grid-flow-col grid-cols-3">
	<div class="text-2xl p-3 align-middle text-center">
		<!--Div do Título do Livro-->
		{selecionado.titulo}
	</div>

	<div>
		<!--Div das informações Gerais-->
		<p class="text-bold text-2xl p-3">Informações Gerais</p>
		<div class="p-3">
			<object
				class="h-90 w-60"
				title="capa"
				data={selecionado.capa}
				type="image/png"
			>
				<object
					class="h-90 w-60"
					title="capaFallbackPNG"
					data="{selecionado.capaFallback}.png"
					type="image/png"
				>
					<img
						src="{selecionado.capaFallback}.jpg"
						alt="Capa de {selecionado.titulo}"
					/>
				</object>
			</object>
		</div>
		<div class="p-3">
			<!--Tabela de info-->
			<div class="p-3"><p>Autor: {selecionado.autor}</p></div>
			<div class="p-3"><p>Data de Lançamento: {selecionado.ano}</p></div>
			<div class="p-3"><p>Língua: {selecionado.lingua}</p></div>
			<div class="p-3"><p>ISBN: {selecionado.isbn}</p></div>
			<div class="p-3"><p>Categorias: {selecionado.categorias}</p></div>
		</div>
	</div>
	<div>
		<!-- Div dos links de download -->
		<p class="text-bold text-2xl p-3">Links de Download</p>
		<div class="grid grid-flow-row grid-cols-2 p-3">
			<p class="w-fit m-3 ml-0">Baixar livro como um arquivo de texto:</p>
			<div class="m-3">
				<button
					class="bg-olive-800 text-olive-50 border-2 border-olive-800 hover:bg-olive-50 hover:text-olive-800 hover:border-2 hover:border-olive-800 p-3 justify-self-end"
					onclick={() =>
						downloadCID(
							selecionado.cid,
							selecionado.titulo,
							"text/plain",
						)}>Download</button
				>
			</div>
			<p class="w-fit m-3 ml-0">Baixar livro em epub:</p>
			<div class="m-3">
				<a
					class="bg-olive-800 text-olive-50 border-2 border-olive-800 hover:bg-olive-50 hover:text-olive-800 hover:border-2 hover:border-olive-800 p-3 justify-self-end"
					href={selecionado.epub}
					download
				>
					<button>Download</button>
				</a>
			</div>
			<p class="w-fit m-3 ml-0">Baixar livro pro Kindle (mobi):</p>
			<div class="m-3">
				<a
					class="bg-olive-800 text-olive-50 border-2 border-olive-800 hover:bg-olive-50 hover:text-olive-800 hover:border-2 hover:border-olive-800 p-3 justify-self-end"
					href={selecionado.kindle}
					download
				>
					<!--Descobri que não se pode colocar o nome do arquivo em um link de download que vem de outra origem, então quando
					  o usuário for baixar um .mobi ou um .epub, ele vai ter o nome esquisito da indexação do gutemberg mesmo-->
					<button>Download</button>
				</a>
			</div>
		</div>
	</div>
</div>
