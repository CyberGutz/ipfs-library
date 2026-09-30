import Dexie, { type EntityTable } from "dexie";
import { readCID } from "./ipfsOperations";
import { parseCSV } from "./csvParse";

export interface Livro {
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
    genero: string;
    capa: string;
    capaFallback: string;
    epub: string;
    kindle: string;
}


const db = new Dexie('AcervoDB') as Dexie & {
    livros: EntityTable<Livro, 'id'>;
};

db.version(1).stores({
    livros: '++id, formato, ano, titulo, lingua, autor, tags, isbn, categorias, cid, genero, capa, capaFallback, epub, kindle'
});

export { db };

export async function catalogSync() {
    if (await db.livros.count() <= 0) {
        try {
            console.log("1. Banco vazio! Iniciando a busca pelo CID na rede")
            const arq = await readCID('bafybeieqjjcdiz4hx3jh6txzjooqsm7bfnnbs5udnzs7gqrk4zpecrbe74'); // CID está no pinata, pra contornar meus problemas com CGNAT.

            console.log("2. Arquivo encontrado e baixado! Tamanho:", arq.length);
            console.log("2.1 Arquivo em texto: ", arq.toString());
            console.log("3. Iniciando o processamento do CSV...");

            const parsed: Promise<any> = await parseCSV(new TextDecoder().decode(arq));

            await db.livros.bulkPut(await parsed);
            console.log("3.1 Arquivo parseado: ", parsed);
            console.log("3.2 DB: ", db.livros);

            console.log("4. Finalizado!");
        }

        catch (erro) {
            console.error("Falha ao ler o CSV: ", erro);
        }
    }
    return;
}

export async function bookList(offset: number = 0, limit: number = 50) {
    return await db.livros
        .offset(offset * limit)
        .limit(limit)
        .toArray();
}

export async function searchBooks(termoBusca: string) {
    let termo = new RegExp(termoBusca, "i")                 // transforma o termo de busca em uma regex, pra ser filtrado no acervo
    return await db.livros
        .filter(livro => termo.test(livro.titulo))          // desta forma, conseguimos filtrar todo título que contém aquela substring, e não só os que começam com ela
        .limit(50)
        .toArray();
}

export async function filtrarGenero(genero: string) {
    return await db.livros
        .where('genero')
        .equals(genero)
        .toArray();
}
