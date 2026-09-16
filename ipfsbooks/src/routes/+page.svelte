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

<div class="bg-olive-100 font-mono text-black dark:bg-black dark:text-amber-50">
	<div class="text-center bg-olive-800 text-olive-50">
		<h2 class="text-4xl">IPFSBooks!</h2>
		<p class="text-xl font-sans italic">
			Books to anyone, free of corporate bullshit!
		</p>
	</div>

	{#if carregando}
		<div class="flex items-center justify-items-center">
			<p class="italic font-bold border">
				Sincronizando o catálogo, aguarde um momento...
			</p>
			<!-- svelte-ignore a11y_missing_attribute -->
			<img
				src="https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExM2VvZ3Q5OGNyMHVnMjg2MHJ3aDd5NzNoNXM5OTRxejNnYmNjanR4cyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/VgY4dDdN1W3NS/giphy.gif"
				alt="carregando"
			/>
		</div>
	{:else}
		<div class="justify-center p-3">
			<button onclick={() => (selecionado = null)} class="g-olive-400 hover:font-bold hover:bg-olive-800 hover:text-amber-50">Home</button>
		</div>
		{#if selecionado != null}
			<BookPage {selecionado} />
		{:else}
			<div class="grid grid-cols-10 gap-4">
				{#each books as book}
					<div class="bg-olive-200 justify-center hover:font-bold hover:bg-olive-800 hover:text-amber-50 text-center">
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
							<p
								class="p-4"
							>
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
