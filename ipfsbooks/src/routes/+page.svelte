<script>
	import { catalogSync, bookList, searchBooks, db } from "$lib/dbInstance";
	import { onMount } from "svelte";
	import BookPage from "./BookPage.svelte";

	let books = $state([]);
	let selecionado = $state();
	let page = $state(0);
	let carregando = $state(true);

	onMount(async () => {
		await catalogSync();
		books = await bookList(page, 50);
		carregando = false;
	});

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
</script>

<h2>IPFSBooks!</h2>

{#if carregando}
	<p>Sincronizando o catálogo, aguarde um momento...</p>
{:else}
	<header>
		<p>Books to anyone, free of corporate bullshit!</p>
		<button onclick={()=> selecionado = null}>Home</button>
	</header>
	{#if selecionado != null}
		<BookPage {selecionado}/>
	{:else}
		{#each books as book}
			<div>
				<a href="localhost:8080" onclick={()=>{
					selecionado = book;
					return false;
				}}>
					{book.titulo}
				</a>
				<!-- <span> <button onclick={()=> downloadCID(book.cid, book.titulo, "text/plain")}>download</button></span> -->
			</div>
		{/each}
	{/if}
{/if}
