#!/bin/bash

echo "**** IPFSBooks Bootstrap provider *****"

while :
do

    echo "1. Provisionando e pinando o CSV do acervo do projeto"
    echo $( ipfs routing provide bafybeieqjjcdiz4hx3jh6txzjooqsm7bfnnbs5udnzs7gqrk4zpecrbe74 )

    echo "2. Baixando, provisionando e pinando a HomePage do IPFSBooks"
    echo $( ipfs routing provide k51qzi5uqu5dhw230sl4tw3i5al7nutobz1j9g0jv9yqxtia56ckfnw24hy06a )

    echo "3. Baixando, provisionando e pinando os livros do ipfs"
    echo $( ipfs routing provide -r bafybeie62easb72odjenpgkmjacw5c6kyrjkzytuxwn2qb42lhujgsajse )

    echo "PROVISIONAMENTO FINALIZADO! Muito obrigado por contribuir com o IPFSBooks!"
    
    sleep 10 | pv -t --name "Próximo provisionamento em 6h"

done