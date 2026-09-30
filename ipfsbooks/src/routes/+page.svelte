<script>
	import {
		catalogSync,
		bookList,
		searchBooks,
		filtrarGenero,
		db,
	} from "$lib/dbInstance";
	import { onMount } from "svelte";
	import BookPage from "./BookPage.svelte";

	let books = $state([]);
	let selecionado = $state();
	let page = $state(0);
	let carregando = $state(true);
	let pesquisa = $state("");
	let generos = [
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
		await catalogSync();
		books = await bookList(page, 50);
		carregando = false;
	});

	async function buscar() {
		if (!pesquisa.trim()) {
			returnHome();
			return;
		}
		selecionado = null;
		books = await searchBooks(pesquisa);
	}

	async function filtrar(filtro) {
		if (filtro == "Todos") {
			returnHome();
			return;
		} else books = await filtrarGenero(filtro);
	}

	async function nextPage() {
		page++;
		const newBooks = await bookList(page, 50);
		books = [...books, ...newBooks];
	}

	async function prevPage() {
		if (page + 50 < 0) return;
		page--;
		const newBooks = await bookList(page, 50);
		books = [...books, ...newBooks];
	}

	async function returnHome() {
		selecionado = null;
		books = await bookList(page, 50);
	}
</script>

<div class="bg-olive-100 font-mono text-olive-800 h-screen w-screen">
	<!--HEADER-->
	<div class="flex justify-center">
		<p class="text-5xl w-fit bg-olive-800 text-olive-50 p-3 m-auto">
			IPFSBooks!
		</p>
	</div>

	{#if carregando}
		<div
			class="flex flex-col justify-items-center flex-auto text-center justify-center p-4"
		>
			<!--CARREGANDO-->
			<img
				class="h-lg w-lg m-auto"
				src="https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExM2VvZ3Q5OGNyMHVnMjg2MHJ3aDd5NzNoNXM5OTRxejNnYmNjanR4cyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/VgY4dDdN1W3NS/giphy.gif"
				alt="carregando"
			/>
			<p class="italic font-bold p-4">
				Carregando, aguarde um momento...
			</p>
		</div>
	{:else}
		<div class="flex justify-center-safe p-3 pl-0">
			<!--NAVBAR-->

			<button
				onclick={returnHome}
				class="hover:font-bold hover:bg-olive-800 hover:text-amber-50 m-3 p-3"
				>Home</button
			>
			<p class="m-3 p-3">Busque um livro:</p>
			<input
				class="border-2 p-2 w-lg outline-0 m-3"
				type="search"
				id="search"
				bind:value={pesquisa}
				placeholder="Bram Stoker's Dracula"
				onkeydown={(e) => e.key === "Enter" && buscar()}
			/>
			<p class="m-3 p-3">Gênero:</p>
			<select class="m-3">
				{#each generos as genero}
					<option onclick={() => filtrar(genero)}>{genero}</option>
				{/each}
			</select>
		</div>
		{#if selecionado != null}
			<BookPage {selecionado} />
		{:else if books.length == 0}
			<div
				class="flex flex-col justify-items-center flex-auto text-center justify-center p-4"
			>
				<!--CARREGANDO-->
				<img
					class="h-2xl w-2xl m-auto"
					src="https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExaGQ5ZjB1dXJhMWcxcGY1NTgzMmpycHg0dnI5Nmo4anJhYjJyN3Z6MiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/tvGOBZKNEX0ac/giphy.gif"
					alt="nenhum livro encontrado"
				/>
				<p class="p-4">
					Nenhum livro encontrado na pesquisa! Aperte o botão Home
					para retornar ao acervo completo!
				</p>
			</div>
		{:else}
			<div class="grid grid-flow-row grid-cols-5 gap-2 p-4">
				{#each books as book}
					<div
						class="flex flex-col justify-center justify-items-center text-center w-3xs h-3xs bg-olive-200 hover:font-bold hover:bg-olive-800 hover:text-amber-50"
					>
						<a
							href="localhost:8080"
							onclick={() => {
								selecionado = book;
								return false;
							}}
						>
							<object
								class="h-90 w-60"
								title="capa"
								data={book.capa}
								type="image/png"
							>
								<object
									class="h-90 w-60"
									title="capaFallbackPNG"
									data="{book.capaFallback}.png"
									type="image/png"
								>
									<img
										src="{book.capaFallback}.jpg"
										alt="Capa de {book.titulo}"
									/>
								</object>
							</object>
							<p class="p-4">
								{book.titulo}
							</p>
						</a>
						<!-- <span> <button onclick={()=> downloadCID(book.cid, book.titulo, "text/plain")}>download</button></span> -->
					</div>
				{/each}
			</div>
		{/if}
	{/if}
</div>
