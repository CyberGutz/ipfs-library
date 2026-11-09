#! /bin/bash

echo "**** IPFSBooks Bootstrap provider *****" >> /data/getandpin.log

ipfs daemon &
echo "[$(date)] : 1. Baixando e pinando o CSV do acervo do projeto\n" >> /data/getandpin.log
echo $( ipfs get bafybeieqjjcdiz4hx3jh6txzjooqsm7bfnnbs5udnzs7gqrk4zpecrbe74 -o ipfsbooks.csv && ipfs pin add /ipfs/bafybeieqjjcdiz4hx3jh6txzjooqsm7bfnnbs5udnzs7gqrk4zpecrbe74 ) >> /data/getandpin.log

echo "[$(date)] : 2. Baixando, provisionando e pinando a HomePage do IPFSBooks\n" >> /data/getandpin.log
echo $( ipfs get /ipns/k51qzi5uqu5dhw230sl4tw3i5al7nutobz1j9g0jv9yqxtia56ckfnw24hy06a -o homepage-build && ipfs pin add /ipns/k51qzi5uqu5dhw230sl4tw3i5al7nutobz1j9g0jv9yqxtia56ckfnw24hy06a ) >> /data/getandpin.log

echo "[$(date)] : 3. Baixando, provisionando e pinando os livros do ipfs\n" >> /data/getandpin.log
echo $( ipfs get bafybeie62easb72odjenpgkmjacw5c6kyrjkzytuxwn2qb42lhujgsajse -o books && ipfs pin add /ipfs/bafybeie62easb72odjenpgkmjacw5c6kyrjkzytuxwn2qb42lhujgsajse ) >> /data/getandpin.log

echo "[$(date)] : \nPROVISIONAMENTO FINALIZADO! Muito obrigado por contribuir com o IPFSBooks!" >> /data/getandpin.log