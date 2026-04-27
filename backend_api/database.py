import os
import psycopg2
from psycopg2.extras import DictCursor
from dotenv import load_dotenv

# Cargamos las variables de entorno (.env)
load_dotenv()
DB_URL = os.getenv("NEON_DB_URL")

def db():
    # Nos conectamos a Neon con DictCursor para mantener la compatibilidad con tu código actual
    conn = psycopg2.connect(DB_URL, cursor_factory=DictCursor)
    return conn

def init_db():
    try:
        conn = db()
        c = conn.cursor()
        
        # Verificamos/Creamos la estructura base sin borrar datos existentes
        c.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            email VARCHAR(150) UNIQUE NOT NULL,
            password VARCHAR(255) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            grade INTEGER DEFAULT 1,
            role VARCHAR(20) DEFAULT 'student'
        );
        
        CREATE TABLE IF NOT EXISTS questions (
            id SERIAL PRIMARY KEY,
            subject VARCHAR(50) NOT NULL,
            grade INTEGER NOT NULL,
            question_text TEXT NOT NULL,
            options JSONB NOT NULL,
            correct_option INTEGER NOT NULL, 
            time_limit_seconds INTEGER DEFAULT 60,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        CREATE TABLE IF NOT EXISTS scores (
            id SERIAL PRIMARY KEY,
            user_id INTEGER NOT NULL REFERENCES users (id) ON DELETE CASCADE,
            subject VARCHAR(50) NOT NULL,
            points INTEGER DEFAULT 0,
            time_taken_seconds INTEGER DEFAULT 0,
            last_played TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        CREATE TABLE IF NOT EXISTS knn_results (
            id SERIAL PRIMARY KEY,
            user_id INTEGER NOT NULL REFERENCES users (id) ON DELETE CASCADE,
            rango INTEGER,
            etiqueta VARCHAR(50),
            promedio_general REAL,
            recomendacion TEXT,
            generado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        -- Tabla de tokens necesaria para el sistema de sesiones
        CREATE TABLE IF NOT EXISTS tokens_rec (
            id SERIAL PRIMARY KEY,
            tipo VARCHAR(50),
            ref_id INTEGER,
            token VARCHAR(255) UNIQUE,
            expira_en TIMESTAMP,
            usado INTEGER DEFAULT 0
        );
        """)
        
        conn.commit()
        print("✅ Base de datos Neon conectada y tablas verificadas.")
        
    except Exception as e:
        print(f"❌ Error conectando a Neon: {e}")
        if 'conn' in locals():
            conn.rollback()
    finally:
        if 'c' in locals(): c.close()
        if 'conn' in locals(): conn.close()