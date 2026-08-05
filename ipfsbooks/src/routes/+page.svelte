<script>
    import { catalogSync, bookList, searchBooks, db } from "$lib/dbInstance";
    import { readCID, downloadCID, pinCID } from "$lib/ipfsOperations";
    import { onMount } from "svelte";

    let books= $state([]);
    let page = $state(0);
    let carregando = $state(true);

    
    onMount(async () =>{
        await catalogSync();
	books = await bookList(page,50);
	carregando = false;
    })

    async function nextPage(){
	page++;
	const newBooks = await bookList(page,50);
	books = [...books, ...newBooks];
	}

    async function prevPage(){
    	if(page + 50 < 0)
		return;
	page--;
	const newBooks = await bookList(page,50);
	books = [...books, ...newBooks];
	}

</script>

<h2>IPFSBooks!</h2>

{#if carregando}
<p>Sincronizando o catálogo, aguarde um momento...</p>
{:else}
<header>
	<p>Books to anyone, free of corporate bullshit!</p>
	<button onclick={prevPage}>Previous</button>
	<button onclick={nextPage}>Next</button>
</header>
{#each books as book}
<li>
	{book.titulo} 
	<button onclick={()=> downloadCID(book.cid)}>
		download
	</button>
</li>
{/each}
{/if}



