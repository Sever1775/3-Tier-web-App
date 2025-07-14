# app_tier.py
from flask import Flask, request, jsonify
import pyodbc

app = Flask(__name__)

# Replace with your actual connection string
DB_CONN = "Driver={ODBC Driver 18 for SQL Server};Server=tcp:<your-db>.database.windows.net,1433;Database=<your-db-name>;Uid=<username>;Pwd=<password>;Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"

@app.route('/get-message')
def get_message():
    try:
        conn = pyodbc.connect(DB_CONN)
        cursor = conn.cursor()
        cursor.execute("SELECT TOP 1 message FROM TestMessages")
        row = cursor.fetchone()
        return jsonify({'message': row[0] if row else 'No message found'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
