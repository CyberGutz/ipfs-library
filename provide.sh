#!/bin/bash

echo "**** IPFSBooks Bootstrap provider *****"

ipfs daemon &

while :
do

    echo "[$(date)] : 1. Provisionando e pinando o CSV do acervo do projeto" >> /data/routing.log
    echo $( ipfs routing provide bafybeieqjjcdiz4hx3jh6txzjooqsm7bfnnbs5udnzs7gqrk4zpecrbe74 ) >> /data/routing.log

    echo "$(date)] : 2. Baixando, provisionando e pinando a HomePage do IPFSBooks" >> /data/routing.log
    echo $( ipfs routing provide k51qzi5uqu5dhw230sl4tw3i5al7nutobz1j9g0jv9yqxtia56ckfnw24hy06a ) >> /data/routing.log

    echo "$(date)] : 3. Baixando, provisionando e pinando os livros do ipfs" >> /data/routing.log
    echo $( ipfs routing provide -r bafybeie62easb72odjenpgkmjacw5c6kyrjkzytuxwn2qb42lhujgsajse ) >> /data/routing.log

    echo "PROVISIONAMENTO FINALIZADO! Muito obrigado por contribuir com o IPFSBooks!" >> /data/routing.log
    
    sleep 10 | pv -t --name "Próximo provisionamento em 6h" >> /data/routing.log

done