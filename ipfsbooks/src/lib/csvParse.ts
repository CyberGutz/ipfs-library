import Papa from "papaparse";

export function parseCSV(file: any) {
    return new Promise((resolve, reject) => {
        Papa.parse(file, {
            header: true,
            skipEmptyLines: true,
            complete: (results: any) => resolve(results.data.map((linha: any) => ({
                titulo: linha.title,
                ano: linha.releaseDate,     // era "data" — não batia com o schema (item abaixo)
                lingua: linha.language,
                autor: linha.author,
                tags: linha.tags,
                isbn: linha.isbn,
                categorias: linha.categories,
                cid: linha.cid,
            }))),
            error: (error: Error) => reject(error)
        });
    });
}