import Dexie, { type EntityTable } from "dexie";
import { readCID } from "./ipfsOperations";
import { parseCSV } from "./csvParse";

export interface Livro{
    id?: number;
    formato: string;
    ano: string;
    titulo: string;
    lingua: string;
    autor: string;
    tags: string;
    isbn: string;
    categorias: string;
    cid: string;
}


const db = new Dexie('AcervoDB') as Dexie & {
    livros: EntityTable<Livro, 'id'>;
};

db.version(1).stores({
        livros: '++id, formato, ano, titulo, lingua, autor, tags, isbn, categorias, cid'
});

export { db };

export async function catalogSync(){
    if(await db.livros.count() <= 0){
        try{
		console.log("1. Banco vazio! Iniciando a busca pelo CID na rede")
            const arq = await readCID('bafybeibwrtbhpjpsyoa534ypr7b63mmwgslscpgtsenuh66zdyn5os2rxa'); // CID está no pinata, pra contornar meus problemas com CGNAT.

		console.log("2. Arquivo encontrado e baixado! Tamanho:", arq.length);
        console.log("2.1 Arquivo em texto: ", arq.toString());
		console.log("3. Iniciando o processamento do CSV...");

            const parsed: Promise<any> = await parseCSV(new TextDecoder().decode(arq));
            
            await db.livros.bulkPut(await parsed);
        console.log("3.1 Arquivo parseado: ", parsed);
        console.log("3.2 DB: ", db.livros);

	    console.log("4. Finalizado!");
        }

        catch (erro){
            console.error("Falha ao ler o CSV: ", erro);
        }
    }
    return;
}

export async function bookList(offset: number = 0, limit: number = 50){
	return await db.livros
		.offset(offset*limit)
		.limit(limit)
		.toArray();
}

export async function searchBooks(termoBusca:string){
    if(!(termoBusca.length < 3)){
        return await db.livros
            .where('titulo')
            .startsWithAnyOfIgnoreCase(termoBusca)
            .limit(10)
            .toArray();
    }
    return [];
}
