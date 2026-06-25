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
            const arq = await readCID('QmNcou4jH6m3Jd6H5orQDWzoUVXsX8e6YmLsYcoCUhQUAB');
            const parsed = await parseCSV(new TextDecoder().decode(arq));
            
            await db.livros.bulkPut(parsed);
        }
        catch (erro){
            console.error("Falha ao ler o CSV: ", erro);
        }
    }
    return;
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