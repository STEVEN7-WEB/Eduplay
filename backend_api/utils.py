import hashlib
import secrets
import functools
from flask import request, jsonify
from database import db  # Importamos la conexión desde tu nuevo archivo

# Utilidades generales
def hp(t): 
    return hashlib.sha256((t or '').strip().lower().encode()).hexdigest()

def r2d(r): 
    return dict(r) if r else None

def r2l(rs): 
    return [dict(r) for r in (rs or [])]

# Autenticación y Tokens
def crear_session_token(tipo, ref_id):
    tok = secrets.token_urlsafe(32)
    with db() as c:
        c.execute(
            "INSERT INTO tokens_rec(tipo,ref_id,token,expira_en) VALUES(?,?,?,datetime('now','+7 days'))",
            (f'session_{tipo}', ref_id, tok)
        )
    return tok

def validar_token_sesion(tok, tipo):
    if not tok: return None
    with db() as c:
        row = c.execute(
            "SELECT ref_id FROM tokens_rec WHERE token=? AND tipo=? AND usado=0 AND expira_en>datetime('now')",
            (tok, f'session_{tipo}')
        ).fetchone()
    return row['ref_id'] if row else None

# Decoradores de seguridad
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