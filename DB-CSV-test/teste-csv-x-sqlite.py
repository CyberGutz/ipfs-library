import pandas as pd
import sqlite3
import numpy as np
import time
import random

# Caminhos dos arquivos CSV e SQLite já criados
csv_files = {
    1000: "./datasets/dataset_1000.csv",
    10000: "/mnt/data/dataset_10000.csv",
    100000: "/mnt/data/dataset_100000.csv",
    1000000: "/mnt/data/dataset_1000000.csv"
}

sqlite_files = {
    1000: "/mnt/data/dataset_1000.db",
    10000: "/mnt/data/dataset_10000.db",
    100000: "/mnt/data/dataset_100000.db",
    1000000: "/mnt/data/dataset_1000000.db"
}

results = []

def benchmark_csv(file, size):
    df = pd.read_csv(file)

    # Índices de teste
    first = 0
    last = size - 1
    rand = random.randint(0, size - 1)

    # Leitura
    for idx, name in zip([first, last, rand], ["primeiro", "último", "aleatório"]):
        start = time.time()
        _ = df.iloc[idx]
        elapsed = time.time() - start
        results.append(("CSV", size, "Leitura", name, elapsed))

    # Inserção
    new_row = {"id": size + 1, "col1": 999, "col2": 0.5, "col3": "Z", "col4": 1.23}
    for idx, name in zip([first, last, rand], ["primeiro", "último", "aleatório"]):
        df_copy = df.copy()
        start = time.time()
        if name == "primeiro":
            df_copy.loc[-1] = new_row
            df_copy.index = df_copy.index + 1
            df_copy.sort_index(inplace=True)
        elif name == "último":
            df_copy.loc[size] = new_row
        else:
            df_copy.loc[idx + 0.5] = new_row
            df_copy.sort_index(inplace=True)
        elapsed = time.time() - start
        results.append(("CSV", size, "Inserção", name, elapsed))

    # Atualização
    for idx, name in zip([first, last, rand], ["primeiro", "último", "aleatório"]):
        df_copy = df.copy()
        start = time.time()
        df_copy.at[idx, "col1"] = 123456
        elapsed = time.time() - start
        results.append(("CSV", size, "Atualização", name, elapsed))


def benchmark_sqlite(file, size):
    conn = sqlite3.connect(file)
    cur = conn.cursor()

    # Índices de teste
    first = 1
    last = size
    rand = random.randint(1, size)

    # Leitura
    for idx, name in zip([first, last, rand], ["primeiro", "último", "aleatório"]):
        start = time.time()
        cur.execute("SELECT * FROM data WHERE id=?", (idx,))
        _ = cur.fetchone()
        elapsed = time.time() - start
        results.append(("SQLite", size, "Leitura", name, elapsed))

    # Inserção
    new_row = (size + 1, 999, 0.5, "Z", 1.23)
    for idx, name in zip([first, last, rand], ["primeiro", "último", "aleatório"]):
        start = time.time()
        cur.execute("INSERT INTO data VALUES (?, ?, ?, ?, ?)", new_row)
        conn.commit()
        elapsed = time.time() - start
        results.append(("SQLite", size, "Inserção", name, elapsed))

    # Atualização
    for idx, name in zip([first, last, rand], ["primeiro", "último", "aleatório"]):
        start = time.time()
        cur.execute("UPDATE data SET col1=? WHERE id=?", (123456, idx))
        conn.commit()
        elapsed = time.time() - start
        results.append(("SQLite", size, "Atualização", name, elapsed))

    conn.close()


# Executar benchmarks
for size, file in csv_files.items():
    benchmark_csv(file, size)

for size, file in sqlite_files.items():
    benchmark_sqlite(file, size)

import pandas as pd
df_results = pd.DataFrame(results, columns=["Tipo", "Tamanho", "Operação", "Posição", "Tempo (s)"])
import caas_jupyter_tools
caas_jupyter_tools.display_dataframe_to_user("Resultados de desempenho", df_results)
