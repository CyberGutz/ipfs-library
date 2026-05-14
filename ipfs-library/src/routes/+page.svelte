<script>
import { parseCSV } from '$lib/csvParse';

const url = "http://localhost:8080/ipfs/QmNcou4jH6m3Jd6H5orQDWzoUVXsX8e6YmLsYcoCUhQUAB";

const mod = 500;
let pesquisa = $state('');
let start = $state(0);
let end = $state(mod);
let acervo = $state([]);
let exibido = $state([]);

let fetchPromise = fetch(url)
	.then(response => response.text())
	.then(async text =>{
		const parsed = await parseCSV(text);
		console.log("o que o parser retornou: ", typeof(parsed));
		acervo = parsed?.value || parsed;
		console.log("tipo do acervo",typeof(acervo));
		console.log("Acervo: ",acervo);
		exibido = acervo.slice(0,mod);
		return acervo;
	});

function buscar(){
	if (!pesquisa.trim()){
		returnHome();
		return;
	}
	
	start = 0;
	end = mod;
	exibido = acervo.filter(livro => livro.title.toLowerCase().includes(pesquisa.toLowerCase()));
}

function returnHome(){
	start = 0;
	end = mod;
	pesquisa = '';
	exibido = acervo.slice(0,mod);
	return;
}

function nextPage(){
	if (end < acervo.length){
		start += mod;
		end += mod;
		exibido = acervo.slice(start, end)
	}
	return;
}

function prevPage(){
	if (start > 0){
		start -= mod;
		end -= mod;;
		exibido = acervo.slice(start, end)
	}
	return;
}


// let acervoFiltrado = $derived(
// 	pesquisa ? acervo.filter(d => d.title?.toLowerCase().includes(pesquisa.toLowerCase())) : acervo
// )

</script>

{#await fetchPromise}
Carregando acervo...
{:then _}
	<button onclick={returnHome}>home</button>
	<input type="search" id="search" bind:value={pesquisa} placeholder="Bram Stoker's Dracula" onkeydown={(e) => e.key === 'Enter' && buscar()}/>
	<button onclick={buscar}>search</button>
	<button onclick={prevPage}>Página anterior</button>
	<button onclick={nextPage}>Proxima página</button>

	<hr/>

	<ul>
		{#if exibido.length <= 0}
			Livro não encontrado!
			<button onclick={returnHome}>retorne ao acervo</button>
		{:else}
			{#each exibido as linha (linha.id)}
				<li><a href="http://localhost:8080/ipfs/{linha.cid}" download="{linha.title}.txt">{linha.title}</a></li>
			{/each}
		{/if}
	</ul>

{:catch erro}
	<p> deu ruim </p>
{/await}

