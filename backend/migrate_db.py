import sqlite3

# Conectar ao banco de dados existente
conn = sqlite3.connect('garagem.db')
cursor = conn.cursor()

# Obter lista de colunas existentes na tabela maintenance
cursor.execute("PRAGMA table_info(maintenance)")
columns = cursor.fetchall()
column_names = [col[1] for col in columns]

# Adicionar as colunas que faltam
columns_to_add = [
    ('workshop', 'VARCHAR(100)'),
    ('mechanic', 'VARCHAR(100)'),
    ('labor_warranty_date', 'VARCHAR(20)'),
    ('labor_cost', 'FLOAT'),
    ('parts', 'VARCHAR(200)'),
    ('parts_store', 'VARCHAR(100)'),
    ('parts_warranty_date', 'VARCHAR(20)'),
    ('parts_cost', 'FLOAT')
]

for col_name, col_type in columns_to_add:
    if col_name not in column_names:
        try:
            cursor.execute(f"ALTER TABLE maintenance ADD COLUMN {col_name} {col_type}")
            print(f"Coluna '{col_name}' adicionada com sucesso")
        except sqlite3.OperationalError as e:
            print(f"Erro ao adicionar coluna '{col_name}': {e}")

# Salvar as alterações
conn.commit()
conn.close()

print("Migração concluída!")