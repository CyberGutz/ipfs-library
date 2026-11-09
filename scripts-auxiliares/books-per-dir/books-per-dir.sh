#! /bin/zsh

count=0

for dir in ./ebooks/*/
do
  for arq in $dir/*
  do
    let "count=count+1"
    echo $dir $count $arq
    if [[ $count > 1 ]]; then
     echo "Mais de um ebook no diretório $dir" 
     exit
    fi
  done
  count=0
done

echo "Nenhum diretório com mais de 1 livro"
