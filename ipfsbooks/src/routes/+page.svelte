<script>
	import {
		catalogSync,
		bookList,
		searchBooks,
		filtrarGenero,
		returnIdCount,
	} from "$lib/dbInstance";
	import { onMount } from "svelte";
	import BookPage from "./BookPage.svelte";
	import Paginacao from "./Paginacao.svelte";
	import { capturarConsole } from "$lib/logger.svelte";
    import Logconsole from "./Logconsole.svelte";
	import Filadownloads from "./Filadownloads.svelte";

	let books = $state([]);
	let selecionado = $state();
	let page = $state(0); // 0-based
	let totalPaginas = $state(1);
	let ordem = $state("");
	let carregando = $state(true);
	let pesquisa = $state("");
	// "catalogo" = lista paginada | "busca" / "filtro" = resultados completos (sem paginação)
	let modo = $state("catalogo");
	const limit = 50;

	const generos = [
		"Todos",
		"Aventura",
		"Contos",
		"Fantasia",
		"Faroeste",
		"Ficção Científica",
		"Ficção Geral",
		"Ficção Histórica",
		"Ficção Infantil",
		"Humor e Sátira",
		"Mistério e Suspense",
		"Mitologia, Lendas e Folclore",
		"Romance",
		"Terror",
	];

	onMount(async () => {
		capturarConsole();
		await catalogSync();
		const registros = await returnIdCount();
		totalPaginas = Math.max(1, Math.ceil(registros / limit));
		books = await bookList(page, limit);
		carregando = false;
	});

	async function buscar() {
		if (!pesquisa.trim()) {
			returnHome();
			return;
		}
		selecionado = null;
		modo = "busca";
		books = await searchBooks(pesquisa);
	}

	async function filtrar(filtro) {
		if (filtro == "Todos") {
			returnHome();
			return;
		}
		selecionado = null;
		modo = "filtro";
		books = await filtrarGenero(filtro);
	}

	async function ordenar(valor) {
		ordem = valor;
		returnHome();
	}

	async function irParaPagina(n) {
		if (n < 0 || n >= totalPaginas || n === page) return;
		page = n;
		books = await bookList(page, limit, ordem);
		window.scrollTo({ top: 0 });
	}

	async function returnHome() {
		page = 0;
		selecionado = null;
		modo = "catalogo";
		books = await bookList(page, limit, ordem);
	}

	const campo = "min-w-0 px-2 py-1 outline-2";
</script>

<!--HEADER-->
<header
	class="sticky top-0 z-10 flex flex-col gap-3 bg-olive-50 p-3 md:flex-row md:items-center"
>
	<button
		onclick={returnHome}
		class="self-start bg-olive-800 px-3 py-1 text-3xl text-olive-50 md:text-5xl"
	>
		IPFSBooks!
	</button>

	<nav class="flex flex-1 flex-col gap-3 sm:flex-row sm:flex-wrap sm:items-center">
		<input
			class="{campo} flex-1 sm:basis-48"
			type="search"
			id="search"
			bind:value={pesquisa}
			placeholder="Busque um livro"
			onkeydown={(e) => e.key === "Enter" && buscar()}
		/>
		<label class="flex items-center gap-2 whitespace-nowrap">
			Filtro:
			<select
				onchange={(e) => filtrar(e.currentTarget.value)}
				class="{campo} flex-1 truncate sm:max-w-40 sm:flex-none"
			>
				{#each generos as genero}
					<option value={genero}>{genero}</option>
				{/each}
			</select>
		</label>
		<label class="flex items-center gap-2 whitespace-nowrap">
			Exibir por:
			<select
				onchange={(e) => ordenar(e.currentTarget.value)}
				class="{campo} flex-1 truncate sm:max-w-40 sm:flex-none"
			>
				<option value="id">Adicionados Recentemente</option>
				<option value="a-z">A-Z</option>
				<option value="data">Data de Publicação</option>
			</select>
		</label>
	</nav>
</header>

<!-- pb-20 deixa espaço para a barra flutuante não cobrir os últimos livros -->
<main class="pb-20">
	{#if carregando}
		<div class="flex flex-col items-center p-4 text-center">
			<img
				class="w-full max-w-md"
				src="https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExM2VvZ3Q5OGNyMHVnMjg2MHJ3aDd5NzNoNXM5OTRxejNnYmNjanR4cyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/VgY4dDdN1W3NS/giphy.gif"
				alt="carregando"
			/>
			<p class="p-4 font-bold italic">
				Carregando, aguarde um momento...
			</p>
			<Logconsole />
		</div>
	{:else if selecionado != null}
		<BookPage {selecionado} />
	{:else if books.length == 0}
		<div class="flex flex-col items-center p-4 text-center">
			<img
				class="w-full max-w-xl"
				src="https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExaGQ5ZjB1dXJhMWcxcGY1NTgzMmpycHg0dnI5Nmo4anJhYjJyN3Z6MiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/tvGOBZKNEX0ac/giphy.gif"
				alt="nenhum livro encontrado"
			/>
			<p class="p-4">
				Nenhum livro encontrado na pesquisa! Aperte o botão Home para
				retornar ao acervo completo!
			</p>
		</div>
	{:else}
		<div
			class="grid grid-cols-2 gap-3 p-3 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6"
		>
			{#each books as book}
				<button
					onclick={() => (selecionado = book)}
					class="flex flex-col bg-olive-200 text-center hover:bg-olive-800 hover:font-bold hover:text-amber-50"
				>
					<div class="aspect-[2/3] w-full">
						<object
							class="pointer-events-none size-full object-cover"
							title="capa"
							data={book.capa}
							type="image/png"
						>
							<object
								class="pointer-events-none size-full object-cover"
								title="capaFallbackPNG"
								data="{book.capaFallback}.png"
								type="image/png"
							>
								<img
									class="size-full object-cover"
									src="{book.capaFallback}.jpg"
									alt="Capa de {book.titulo}"
								/>
							</object>
						</object>
					</div>
					<p class="line-clamp-2 p-2">{book.titulo}</p>
				</button>
			{/each}
		</div>
	{/if}
</main>

<!-- Barra flutuante: só aparece na listagem paginada do catálogo -->
{#if !carregando && selecionado == null && modo === "catalogo" && books.length > 0 && totalPaginas > 1}
	<Paginacao atual={page} total={totalPaginas} onChange={irParaPagina} />
{/if}

<Filadownloads />