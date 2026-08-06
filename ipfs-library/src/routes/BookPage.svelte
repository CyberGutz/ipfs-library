<script>
    let {selecionado} = $props();

    let conteudo = $state();
    let carregando = $state(false);

    async function exibirLeitor(){
        carregando = true;
        try{
            const url = 'localhost:8080/ipfs/${selecionado.cid}';
            const response = await fetch(url);
            if (!response.ok) throw new Error("Falha ao buscar conteúdo");
            conteudo = await response.text();
        }
        catch(erro){
            console.error("Erro ao carregar o conteúdo do livro pelo IPFS: ", erro);
        }
        finally{
            carregando = false;
        }
    }

</script>

<h2>
    {selecionado.title}
</h2>
<hr/>
<h3>
    CID: {selecionado.cid}
</h3>
<h3>
    ISBN: {selecionado.isbn}
</h3>

<div>
    <button onclick="{exibirLeitor}" aria-label="Leitor online">Ler no navegador</button>
    <div>
        {#if carregando}
            <p>Carregando livro do ipfs...</p>
        {:else if conteudo}
        <div>
            {conteudo}
        </div>
        {/if}
    </div>
</div>

<h3>
    LINK: <a href="localhost:8080/ipfs/{selecionado.cid}">Download</a>
</h3>
<ul>
    <li>
        Data de lançamento: {selecionado.releaseDate}
    </li>
    <li>
        Autor: {selecionado.author}
    </li>
    <li>
        Línguas Disponíveis: {selecionado.language}
    </li>
    <li>
        Categorias: {selecionado.categories}
    </li>
</ul>

<p>
    {selecionado.tags}
</p>
