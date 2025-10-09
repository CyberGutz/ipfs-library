import pandas as pd
import sqlite3
import numpy as np
import time
import random

datasets = {
        1000:      "./datasets/dataset_1K.csv",
        10000:     "./datasets/dataset_10K.csv",
        100000:    "./datasets/dataset_100K.csv",
        1000000:   "./datasets/dataset_1M.csv",
}

databases = {
        1000:      "datasets/db_1K.sqlite",
        10000:     "./datasets/db_10K.sqlite",
        100000:    "./datasets/db_100K.db",
        1000000:   "./datasets/db_1M.sqlite",
}

def db_test(file, size):
    conn = sqlite3.connect(file)
    cur = conn.cursor()
    cur.execute("select * from data where name = 'fulano'")
    result = cur.fetchone()
    print(result)
    conn.close()

def csv_test(file, size):
    dataframe = pd.read_csv(file)
    registro = dataframe[dataframe['col1'] == 'fulano'].iloc[0]
    print(registro)




if __name__ == "__main__":
    print("TESTES: BDs SQLITE\n\n")
    for size, file in databases.items():
        print(file)
        print("Número de registros: ",size)
        start = time.time()
        db_test(file, size)
        print("Tempo corrido: ", time.time() - start)

    print("\n\nTESTES: ARQUIVOS CSV\n\n")
    for size, file in datasets.items():
        start = time.time()
        csv_test(file, size)
        print("Tempo corrido: ", time.time() - start)

