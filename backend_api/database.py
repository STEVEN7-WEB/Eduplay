import sqlite3
import os

# Rutas base
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_PATH  = os.path.join(BASE_DIR, 'backend_api', 'eduplay.db')

def db():
    c = sqlite3.connect(DB_PATH)
    c.row_factory = sqlite3.Row
    c.execute("PRAGMA foreign_keys=ON")
    return c

def init_db():
    with db() as c:
        c.executescript("""
        CREATE TABLE IF NOT EXISTS padres(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL, email TEXT UNIQUE NOT NULL,
            pin_hash TEXT NOT NULL, pregunta_secreta TEXT NOT NULL, respuesta_hash TEXT NOT NULL,
            creado_en TEXT DEFAULT(datetime('now'))
        );
        CREATE TABLE IF NOT EXISTS usuarios(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL, edad INTEGER NOT NULL,
            email TEXT UNIQUE,
            grado_escolar TEXT DEFAULT '',
            avatar TEXT DEFAULT '🎮',
            pin_hash TEXT, pregunta_secreta TEXT, respuesta_hash TEXT,
            estrellas INTEGER DEFAULT 0, tiempo_juego INTEGER DEFAULT 0,
            padre_id INTEGER REFERENCES padres(id) ON DELETE SET NULL,
            es_tutor INTEGER DEFAULT 0,
            info_tutor TEXT DEFAULT '',
            creado_en TEXT DEFAULT(datetime('now'))
        );
        CREATE TABLE IF NOT EXISTS puntuaciones(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            usuario_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
            area TEXT NOT NULL, puntuacion REAL NOT NULL,
            correctas INTEGER DEFAULT 0, total_preguntas INTEGER DEFAULT 0,
            registrado_en TEXT DEFAULT(datetime('now'))
        );
        CREATE TABLE IF NOT EXISTS historial_actividades(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            usuario_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
            actividad TEXT, tipo_juego TEXT, resultado TEXT DEFAULT 'completado',
            estrellas INTEGER DEFAULT 0, registrado_en TEXT DEFAULT(datetime('now'))
        );
        CREATE TABLE IF NOT EXISTS logros(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            usuario_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
            logro_id TEXT NOT NULL, desbloqueado INTEGER DEFAULT 0,
            progreso REAL DEFAULT 0, fecha_desbloqueo TEXT,
            UNIQUE(usuario_id, logro_id)
        );
        CREATE TABLE IF NOT EXISTS clasificaciones_knn(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            usuario_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
            rango INTEGER, rango_etiqueta TEXT, puntuacion_prom REAL,
            prob_critico REAL DEFAULT 0, prob_desarrollo REAL DEFAULT 0,
            prob_basico REAL DEFAULT 0, prob_competente REAL DEFAULT 0, prob_excelente REAL DEFAULT 0,
            recomendacion TEXT, generado_en TEXT DEFAULT(datetime('now'))
        );
        CREATE TABLE IF NOT EXISTS tokens_rec(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tipo TEXT, ref_id INTEGER, token TEXT UNIQUE,
            expira_en TEXT, usado INTEGER DEFAULT 0
        );
        CREATE TABLE IF NOT EXISTS reporte_tiempo(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            usuario_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
            fecha TEXT DEFAULT(date('now')),
            minutos INTEGER DEFAULT 0,
            categoria TEXT DEFAULT 'General',
            descripcion TEXT DEFAULT '',
            registrado_en TEXT DEFAULT(datetime('now'))
        );
        """)
        
        # Migraciones
        cols = [r[1] for r in c.execute("PRAGMA table_info(usuarios)").fetchall()]
        if 'email' not in cols:
            c.execute("ALTER TABLE usuarios ADD COLUMN email TEXT")
        if 'grado_escolar' not in cols:
            c.execute("ALTER TABLE usuarios ADD COLUMN grado_escolar TEXT DEFAULT ''")
        if 'es_tutor' not in cols:
            c.execute("ALTER TABLE usuarios ADD COLUMN es_tutor INTEGER DEFAULT 0")
        if 'info_tutor' not in cols:
            c.execute("ALTER TABLE usuarios ADD COLUMN info_tutor TEXT DEFAULT ''")
    print(f"✅ BD Inicializada: {DB_PATH}")