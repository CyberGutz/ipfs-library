import pandas as pd
import os

if __name__ == "__main__":
    try:
        os.mkdir("books")
    except FileExistsError:
        print("Diretório já existente")
    names = []
    index = 0
    df = pd.read_csv('ipfsbooks.csv', usecols=['title', 'cid'])
    for name in df['title']:
        names.append(name)
    for cid in df['cid']:
        name = '"./books/' + names[index] + '"'
        command = "ipfs get " + cid + " -o " + name
        print(command)
        os.system(command)
        index += 1


