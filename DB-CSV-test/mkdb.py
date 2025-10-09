import sqlite3

# Definição das quantidades de registros
sizes = [1000, 10000, 100000, 1000000]
db_files = []

# Geração dos bancos SQLite
for size in sizes:
    db_path = f"/mnt/data/dataset_{size}.db"
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    # Criação da tabela
    cur.execute("DROP TABLE IF EXISTS data")
    cur.execute("""
        CREATE TABLE data (
            id INTEGER PRIMARY KEY,
            col1 INTEGER,
            col2 REAL,
            col3 TEXT,
            col4 REAL
        )
    """)

    # Inserção dos dados em lote
    data = [
        (i, 
         np.random.randint(0, 100000), 
         float(np.random.random()), 
         np.random.choice(["A", "B", "C", "D"]), 
         float(np.random.randn()))
        for i in range(1, size + 1)
    ]
    cur.executemany("INSERT INTO data VALUES (?, ?, ?, ?, ?)", data)
    conn.commit()
    conn.close()

    db_files.append(db_path)

db_files