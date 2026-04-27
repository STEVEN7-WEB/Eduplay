import hashlib
import secrets
import functools
from flask import request, jsonify
from database import db

# --- UTILIDADES GENERALES ---
def hp(t): 
    return hashlib.sha256((t or '').strip().lower().encode()).hexdigest()

def r2d(r): 
    return dict(r) if r else None

def r2l(rs): 
    return [dict(r) for r in (rs or [])]

# --- AUTENTICACIÓN Y TOKENS (Adaptado a PostgreSQL) ---
def crear_session_token(tipo, ref_id):
    tok = secrets.token_urlsafe(32)
    conn = db()
    cur = conn.cursor()
    try:
        # En Postgres usamos CURRENT_TIMESTAMP y sumamos intervalos de tiempo
        cur.execute(
            "INSERT INTO tokens_rec(tipo, ref_id, token, expira_en) VALUES(%s, %s, %s, CURRENT_TIMESTAMP + INTERVAL '7 days')",
            (f'session_{tipo}', ref_id, tok)
        )
        conn.commit()
    finally:
        cur.close()
        conn.close()
    return tok

def validar_token_sesion(tok, tipo):
    if not tok: return None
    conn = db()
    cur = conn.cursor()
    try:
        cur.execute(
            "SELECT ref_id FROM tokens_rec WHERE token=%s AND tipo=%s AND usado=0 AND expira_en > CURRENT_TIMESTAMP",
            (tok, f'session_{tipo}')
        )
        row = cur.fetchone()
        return row['ref_id'] if row else None
    finally:
        cur.close()
        conn.close()

# --- DECORADORES DE SEGURIDAD ---
def require_alumno(f):
    @functools.wraps(f)
    def wrapper(*args, **kwargs):
        tok = request.headers.get('X-Session-Token') or request.args.get('token')
        uid = validar_token_sesion(tok, 'alumno')
        if uid is None:
            return jsonify({'error': 'No autorizado'}), 401
        if 'uid' not in kwargs:
            kwargs['uid'] = uid
        return f(*args, **kwargs)
    return wrapper

def require_padre(f):
    @functools.wraps(f)
    def wrapper(*args, **kwargs):
        tok = request.headers.get('X-Session-Token') or request.args.get('token')
        pid = validar_token_sesion(tok, 'padre')
        if pid is None:
            return jsonify({'error': 'No autorizado'}), 401
        if 'pid' not in kwargs:
            kwargs['pid'] = pid
        return f(*args, **kwargs)
    return wrapper

# --- FUNCIONES DE IA ---
def promedios(uid):
    areas = ['Memoria', 'Matematicas', 'Gramatica', 'Ingles', 'Geografia', 'Arte', 'Ciencia', 'Logica']
    conn = db()
    cur = conn.cursor()
    out = {}
    try:
        for a in areas:
            cur.execute("SELECT AVG(points) as v FROM scores WHERE user_id=%s AND subject=%s", (uid, a))
            row = cur.fetchone()
            # Si no hay partidas, asumimos un 50.0 por defecto
            out[a] = round(row['v'] if row and row['v'] else 50.0, 2)
        return out
    finally:
        cur.close()
        conn.close()