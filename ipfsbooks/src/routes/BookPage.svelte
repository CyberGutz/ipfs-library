<script lang="ts">
	let {selecionado} = $props();
	import { downloadCID } from "../lib/ipfsOperations";
</script>

<div>
{selecionado.titulo}
</div>
<div>
	<div>
		Capa			
	</div>
	<div>
		<div>Autor: {selecionado.autor}</div>
		<div>Data de Lançamento: {selecionado.ano}</div>
		<div>Língua: {selecionado.lingua}</div>
		<div>ISBN: {selecionado.isbn}</div>	
		<div>Categorias: {selecionado.categorias}</div>
	</div>
</div>
<p>Links de Download</p>
<div>Baixar livro como um arquivo de texto: 
	<button onclick={()=> downloadCID(selecionado.cid, selecionado.titulo, "text/plain")}>Download!</button>
</div>
<div>

</div>
<div>

</div>
