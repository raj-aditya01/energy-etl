import psycopg2

try:
    # 1. Connect to your Docker database
    print("Connecting to the database...")
    conn = psycopg2.connect(
        host="localhost",
        port=5432,
        database="energy_learning",
        user="learner",
        password="learning123"
    )

    # 2. Open a 'cursor' (this is what actually runs the SQL commands)
    cur = conn.cursor()

    # 3. Execute our CREATE TABLE command
    print("Creating the energy_readings table...")
    cur.execute("""
        CREATE TABLE IF NOT EXISTS energy_readings (
            id SERIAL PRIMARY KEY,
            reading_time TIMESTAMP DEFAULT NOW(),
            meter_id VARCHAR(50),
            kwh_used DECIMAL(10,2)
        );
    """)

    # 4. Insert our dummy data
    print("Inserting data...")
    cur.execute("""
        INSERT INTO energy_readings (meter_id, kwh_used) 
        VALUES 
        ('METER_001', 145.50),
        ('METER_002', 89.25),
        ('METER_001', 146.10);
    """)

    # 5. COMMIT the changes (If you don't do this, Postgres throws the data away!)
    conn.commit()
    print("Data successfully saved!")

    # 6. Let's read it back to prove it worked
    print("\n--- Current Data in Database ---")
    cur.execute("SELECT * FROM energy_readings;")
    records = cur.fetchall()
    
    for row in records:
        print(row)

except Exception as e:
    print(f"Oops! An error occurred: {e}")

finally:
    # 7. Always close your connections when the script is done
    if 'cur' in locals():
        cur.close()
    if 'conn' in locals():
        conn.close()
        print("\nDatabase connection closed.")