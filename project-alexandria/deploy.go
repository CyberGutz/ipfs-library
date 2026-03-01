package main

import(
	"fmt"
	"os/exec"
	"strings"
)

func handleError(err error){
	if err != nil{
		panic(err)
		fmt.Println("Falha no deploy")
		fmt.Println("*********************************")
	}
}

func main(){
	const target = "./index.html"
	fmt.Println("********** IPNS DEPLOY **********")
	fmt.Println("\nInicializando o algoritmo de deploy")
	out, execError := exec.Command("ipfs", "add", target).Output()
	handleError(execError)
	parsedCID := strings.Fields(string(out))
	cid := parsedCID[1]
	fmt.Println("CID da nova versão do site: ",cid)
	exec.Command("ipfs", "pin", "add", cid)
	out, execError = exec.Command("ipfs", "name", "publish", cid).Output()
	handleError(execError)
	parsedName := strings.Fields(string(out))
	name, _ := strings.CutSuffix(parsedName[2], ":")
	fmt.Println("Nome no ipns: ", name)
	exec.Command("ipfs", "routing", "provide", name)
	fmt.Println("Nome provisionado")
	fmt.Println("Deploy concluido com sucesso!")
	fmt.Println("*********************************")
}
