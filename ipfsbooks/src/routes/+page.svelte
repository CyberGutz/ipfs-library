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
	let ordem = $state("");
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
	let ordens = ["Ordem de Lançamento", "A-Z", "Data de Publicação"];

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

	async function ordenar(valor) {
		ordem = valor;
		returnHome();
	}

	async function ordenarId() {
		ordem = "id";
		returnHome();
	}

	async function ordenarAz() {
		ordem = "a-z";
		returnHome();
	}

	async function ordenarData() {
		ordem = "data";
		returnHome();
	}

	async function pageChange(offset) {
		if (page + offset < 0) return;
		page = page + offset;
		books = await bookList(page, 50, ordem);
	}

	async function returnHome() {
		page = 0;
		selecionado = null;
		books = await bookList(page, 50, ordem);
	}
</script>

<!--HEADER-->
<div>
	<div
		class="flex items-center justify-between sticky top-0 bg-olive-50 text-center p-3 align-middle"
	>
		<p class="text-5xl bg-olive-800 text-olive-50 p-3">IPFSBooks!</p>
		<nav class="flex w-full items-center align-middle gap-4 p-3">
			<!--NAVBAR-->
			<button
				onclick={() => pageChange(-1)}
				class="hover:font-bold hover:bg-olive-800 hover:text-amber-50 px-3 py-2"
				>Anterior</button
			>
			<button
				onclick={returnHome}
				class="hover:font-bold hover:bg-olive-800 hover:text-amber-50 px-3 py-2"
				>Home</button
			>
			<button
				onclick={() => pageChange(1)}
				class="hover:font-bold hover:bg-olive-800 hover:text-amber-50 px-3 py-2"
				>Proxima</button
			>
			<input
				class="outline-2 flex-1 min-w-0 h-fit px-2 py-1"
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
					class="max-w-40 truncate px-2 py-1"
				>
					{#each generos as genero}
						<option vlaue={genero}>{genero}</option>
					{/each}
				</select>
			</label>
			<label class="flex items-center gap-2 whitespace-nowrap">
				Exibir por:
				<select
					onchange={(e) => ordenar(e.currentTarget.value)}
					class="max-w-40 truncate px-2 py-1"
				>
					<option value="id">Adicionados Recentemente</option>
					<option value="a-z">A-Z</option>
					<option value="data">Data de Publicação</option>
				</select>
			</label>
		</nav>
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
				frontend debug mode Carregando, aguarde um momento...
			</p>
		</div>
	{:else}
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
