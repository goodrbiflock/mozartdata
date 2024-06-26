import re
import os

def preprocess_sql_file(file_path):
    with open(file_path, 'r') as file:
        sql = file.read()

    # Remove "CREATE OR REPLACE TABLE ... COPY GRANTS as" statements
    sql = re.sub(r'CREATE OR REPLACE TABLE .*?COPY GRANTS as', '', sql, flags=re.IGNORECASE | re.DOTALL)

    with open(file_path, 'w') as file:
        file.write(sql)

def main():
    # Directory where your SQL scripts are located
    sql_directory = 'mozartdata/transforms/fact'

    for root, dirs, files in os.walk(sql_directory):
        for file in files:
            if file.endswith('.sql'):
                preprocess_sql_file(os.path.join(root, file))

if __name__ == "__main__":
    main()