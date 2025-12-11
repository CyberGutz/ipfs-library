package main

import (
	"encoding/csv"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
)

func handleError(err error) {
	if err != nil {
		panic(err)
	}
}

func mapBookIndex(path string) map[string]int {
	csvFile, csvError := os.Open(path)
	handleError(csvError)
	defer closeFile(csvFile)

	database, readError := csv.NewReader(csvFile).ReadAll()
	handleError(readError)

	mappedIndexes := make(map[string]int)
	for i, record := range database {
		// Pega somente a primeira coluna da tabela
		mappedIndexes[record[0]] = i
	}

	return mappedIndexes
}

func closeFile(arq *os.File) {
	err := arq.Close()
	handleError(err)
}

func main() {
	const ebookPath = "./ebooks/"
	const csvPath = "./pg_catalog.csv"

	// Carrega CSV
	csvfile, csvError := os.Open(csvPath)
	handleError(csvError)
	defer closeFile(csvfile)
	// Cria o Reader do csv
	database, _ := csv.NewReader(csvfile).ReadAll()
	// Indexa as linhas do csv. Chamando o map, vamos achar o índice da matriz de strings do qual o nome pertence
	indexes := mapBookIndex(csvPath)

	var newDatabaseData [][]string

	count := 0

	walkError := filepath.Walk(ebookPath,
		func(path string, info os.FileInfo, fileError error) error {
			handleError(fileError)
			count++

			_, errReadDir := os.ReadDir(path)
			if errReadDir != nil {
				// Pega o nome do arquivo (número do ebook)
				_, file := filepath.Split(path)

				fmt.Println("path> ", path)
				fmt.Println("file> ", file)

				if file != "" {
					re := regexp.MustCompile(`\d+`)
					entry := re.FindString(file)
					entryIndex := indexes[entry]
					fmt.Println("entry> ", entry)
					fmt.Println("entryIndex> ", entryIndex)

					record := database[entryIndex]

					// Adiciona livro no IPFS
					out, execError := exec.Command("ipfs", "add", path).Output()
					handleError(execError)

					// Recupera CID
					fmt.Println("CID:")
					parsedCID := strings.Fields(string(out))
					cid := parsedCID[1]
					fmt.Println(string(cid))

					// Faz pin no CID
					exec.Command("ipfs", "pin", "add", cid)

					// Monta a linha do CSV atual + CID recuperado
					var newRecord []string
					for _, field := range record {
						newRecord = append(newRecord, field, ",")
					}
					newRecord = append(newRecord, cid)
					fmt.Println("Linha completa: ")
					fmt.Println(newRecord)
					// Adiciona a nova linha no novo arquivo csv
					newDatabaseData = append(newDatabaseData, newRecord)
				}
				if count == 4 {
					return fileError
				}
			}
			return fileError
		})
	handleError(walkError)

	// Abre um novo arquivo pro database
	csvFile, csvError := os.Open("./ipfsbooks.csv")
	handleError(csvError)
	defer closeFile(csvFile)

	// Escreve os dados montados no walk
	fd := csvFile.Fd()
	newDatabase := csv.NewWriter(os.NewFile(fd, "./ipfsbooks.csv"))
	writeError := newDatabase.WriteAll(newDatabaseData)
	handleError(writeError)
}
