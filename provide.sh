#!/bin/bash

echo "**** IPFSBooks Bootstrap provider *****"

ipfs daemon &

echo "Início do provisionamento: Baixando e pinando" >> /data/getandpin.log

if [-f ipfsbooks.csv]; then
    echo "CSV existe, pulando pro próximo arquivo" >> /data/getandpin.log
else
    echo "[$(date)] : 1. Baixando e pinando o CSV do acervo do projeto\n" >> /data/getandpin.log
    echo $( ipfs get bafybeieqjjcdiz4hx3jh6txzjooqsm7bfnnbs5udnzs7gqrk4zpecrbe74 -o ipfsbooks.csv && ipfs pin add /ipfs/bafybeieqjjcdiz4hx3jh6txzjooqsm7bfnnbs5udnzs7gqrk4zpecrbe74 ) >> /data/getandpin.log
fi

if [-d homepage-build]; then
    echo "Build do site existe, pulando pro próximo diretório" >> /data/getandpin.log
else
    echo "[$(date)] : 2. Baixando, provisionando e pinando a HomePage do IPFSBooks\n" >> /data/getandpin.log
    echo $( ipfs get /ipns/k51qzi5uqu5dhw230sl4tw3i5al7nutobz1j9g0jv9yqxtia56ckfnw24hy06a -o homepage-build && ipfs pin add /ipns/k51qzi5uqu5dhw230sl4tw3i5al7nutobz1j9g0jv9yqxtia56ckfnw24hy06a ) >> /data/getandpin.log
fi

if [-d books]; then
    echo "Pasta de livros existe, get não necessário" >> /data/getandpin.log
else
    echo "[$(date)] : 3. Baixando, provisionando e pinando os livros do ipfs\n" >> /data/getandpin.log
    echo $( ipfs get bafybeie62easb72odjenpgkmjacw5c6kyrjkzytuxwn2qb42lhujgsajse -o books && ipfs pin add /ipfs/bafybeie62easb72odjenpgkmjacw5c6kyrjkzytuxwn2qb42lhujgsajse ) >> /data/getandpin.log

echo "[$(date)] : \DOWNLOAD FINALIZADO! Passando pra etapa de provisionamento!" >> /data/getandpin.log

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