<script>
import { parseCSV } from '$lib/csvParse';

const url = "http://localhost:8080/ipfs/QmNcou4jH6m3Jd6H5orQDWzoUVXsX8e6YmLsYcoCUhQUAB";

let fetchPromise = fetch(url)
	.then(response => response.text())
	.then(text =>{
		return parseCSV(text)
	});

</script>

{#await fetchPromise}
...
{:then dados}

	<ul>
		{#each dados as linha}
			<li><a href="http://localhost:8080/ipfs/{linha.cid}">{linha.title}</a></li>
		{/each}
	</ul>

	{:catch erro}
		<p> deu ruim </p>
{/await}

