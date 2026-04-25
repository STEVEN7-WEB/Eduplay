"""EduPlay Backend v5 - Flask + SQLite + KNN + Auth completo"""
from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import sys
import os
import sqlite3, os, hashlib, secrets, functools

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH  = os.path.join(BASE_DIR, 'eduplay.db')
FRONT    = os.path.join(BASE_DIR, 'static')

app = Flask(__name__, static_folder=FRONT, static_url_path='')
CORS(app, resources={r"/api/*": {"origins": "*"}})

# 1. Agregar la carpeta raíz a las rutas del sistema
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if BASE_DIR not in sys.path:
    sys.path.append(BASE_DIR)

app = Flask(__name__, static_folder=FRONT, static_url_path='')
CORS(app, resources={r"/api/*": {"origins": "*"}})

KNN_OK = False; knn = None
try:
    # 2. Cambiar la importación para que apunte a la nueva carpeta
    from ai_model.knn_model import EduPlayKNN
    
    knn = EduPlayKNN(); knn.train(); KNN_OK = True; print("✅ KNN listo")
except Exception as e: 
    print(f"⚠️  KNN: {e}")

def db():
    c = sqlite3.connect(DB_PATH); c.row_factory = sqlite3.Row
    c.execute("PRAGMA foreign_keys=ON"); return c
def db():
    c = sqlite3.connect(DB_PATH); c.row_factory = sqlite3.Row
    c.execute("PRAGMA foreign_keys=ON"); return c

def hp(t): return hashlib.sha256((t or '').strip().lower().encode()).hexdigest()
def r2d(r): return dict(r) if r else None
def r2l(rs): return [dict(r) for r in (rs or [])]

# ── Session token auth ───────────────────────────────────────────────────────
def crear_session_token(tipo, ref_id):
    tok = secrets.token_urlsafe(32)
    with db() as c:
        c.execute(
            "INSERT INTO tokens_rec(tipo,ref_id,token,expira_en) VALUES(?,?,?,datetime('now','+7 days'))",
            (f'session_{tipo}', ref_id, tok)
        )
    return tok

def validar_token_sesion(tok, tipo):
    """Returns ref_id if token is valid, else None."""
    if not tok: return None
    with db() as c:
        row = c.execute(
            "SELECT ref_id FROM tokens_rec WHERE token=? AND tipo=? AND usado=0 AND expira_en>datetime('now')",
            (tok, f'session_{tipo}')
        ).fetchone()
    return row['ref_id'] if row else None

def require_alumno(f):
    @functools.wraps(f)
    def wrapper(*args, **kwargs):
        tok = request.headers.get('X-Session-Token') or request.args.get('token')
        uid = validar_token_sesion(tok, 'alumno')
        if uid is None:
            return jsonify({'error': 'No autorizado'}), 401
        # inject uid as kwarg if function expects it and not in path
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
        # Migrations – add columns if they don't exist yet
        cols = [r[1] for r in c.execute("PRAGMA table_info(usuarios)").fetchall()]
        if 'email' not in cols:
            c.execute("ALTER TABLE usuarios ADD COLUMN email TEXT")
        if 'grado_escolar' not in cols:
            c.execute("ALTER TABLE usuarios ADD COLUMN grado_escolar TEXT DEFAULT ''")
        if 'es_tutor' not in cols:
            c.execute("ALTER TABLE usuarios ADD COLUMN es_tutor INTEGER DEFAULT 0")
        if 'info_tutor' not in cols:
            c.execute("ALTER TABLE usuarios ADD COLUMN info_tutor TEXT DEFAULT ''")
    print(f"✅ BD: {DB_PATH}")

def promedios(uid):
    areas = ['memory','math','grammar','english','geography','art','science','logic']
    mapa  = {'memory':'Memoria','math':'Matematicas','grammar':'Gramatica','english':'Ingles',
              'geography':'Geografia','art':'Arte','science':'Ciencia','logic':'Logica'}
    with db() as c:
        out = {}
        for a in areas:
            row = c.execute("SELECT AVG(puntuacion) v FROM puntuaciones WHERE usuario_id=? AND area=?", (uid, a)).fetchone()
            out[mapa[a]] = round(row['v'] if row['v'] else 50.0, 2)
    return out

def guardar_knn(uid):
    if not KNN_OK: return
    try:
        pm = promedios(uid)
        with db() as c:
            u = r2d(c.execute("SELECT edad FROM usuarios WHERE id=?", (uid,)).fetchone())
        if not u: return
        r = knn.clasificar(pm, edad=u['edad'])
        with db() as c:
            c.execute(
                "INSERT INTO clasificaciones_knn(usuario_id,rango,rango_etiqueta,puntuacion_prom,prob_critico,prob_desarrollo,prob_basico,prob_competente,prob_excelente,recomendacion) VALUES(?,?,?,?,?,?,?,?,?,?)",
                (uid, r['rango'], r['etiqueta'], r['puntuacion_promedio'],
                 r['probabilidades'].get('Crítico',0), r['probabilidades'].get('En Desarrollo',0),
                 r['probabilidades'].get('Básico',0), r['probabilidades'].get('Competente',0),
                 r['probabilidades'].get('Excelente',0), r['recomendacion'])
            )
    except Exception as e: print(f"KNN: {e}")

# ── AVATARES predeterminados ─────────────────────────────────────────────────
AVATARES = ['🦊','🐱','🐼','🐶','🐸','🦄','🐯','🐧','🦋','🐙','🦁','🐨','🐻','🦊','🐳','🦀']

@app.route('/api/avatares', methods=['GET'])
def get_avatares():
    return jsonify(AVATARES)

# ── PADRES ───────────────────────────────────────────────────────────────────
@app.route('/api/padres/registro', methods=['POST'])
def reg_padre():
    d = request.get_json()
    nb = d.get('nombre','').strip(); em = d.get('email','').strip().lower()
    pn = str(d.get('pin','')); pr = d.get('pregunta_secreta','').strip(); rp = d.get('respuesta_secreta','').strip()
    if not nb: return jsonify({'error':'Nombre requerido'}),400
    if not em: return jsonify({'error':'Email requerido'}),400
    if len(pn)!=4 or not pn.isdigit(): return jsonify({'error':'PIN debe ser 4 dígitos'}),400
    if not pr: return jsonify({'error':'Pregunta requerida'}),400
    if not rp: return jsonify({'error':'Respuesta requerida'}),400
    try:
        with db() as c:
            cur = c.execute(
                "INSERT INTO padres(nombre,email,pin_hash,pregunta_secreta,respuesta_hash) VALUES(?,?,?,?,?)",
                (nb, em, hp(pn), pr, hp(rp))
            )
            p = r2d(c.execute("SELECT id,nombre,email,creado_en FROM padres WHERE id=?", (cur.lastrowid,)).fetchone())
        tok = crear_session_token('padre', p['id'])
        return jsonify({**p, 'session_token': tok}), 201
    except Exception as e:
        if 'UNIQUE' in str(e): return jsonify({'error':'Email ya registrado'}),409
        return jsonify({'error':str(e)}),500

@app.route('/api/padres/login', methods=['POST'])
def login_padre():
    d = request.get_json(); em = d.get('email','').strip().lower(); pn = str(d.get('pin',''))
    with db() as c:
        row = c.execute("SELECT * FROM padres WHERE email=?", (em,)).fetchone()
    if not row: return jsonify({'ok':False,'error':'Email no registrado'}),404
    if row['pin_hash'] != hp(pn): return jsonify({'ok':False,'error':'PIN incorrecto'}),401
    tok = crear_session_token('padre', row['id'])
    return jsonify({'ok':True,'session_token':tok,'padre':{'id':row['id'],'nombre':row['nombre'],'email':row['email']}})

@app.route('/api/padres/logout', methods=['POST'])
def logout_padre():
    tok = request.headers.get('X-Session-Token') or (request.get_json() or {}).get('token','')
    if tok:
        with db() as c:
            c.execute("UPDATE tokens_rec SET usado=1 WHERE token=? AND tipo='session_padre'", (tok,))
    return jsonify({'ok':True})

@app.route('/api/padres/verificar-pregunta', methods=['POST'])
def verif_preg_padre():
    d = request.get_json(); em = d.get('email','').strip().lower(); rp = d.get('respuesta','').strip()
    with db() as c:
        row = c.execute("SELECT id,respuesta_hash FROM padres WHERE email=?", (em,)).fetchone()
    if not row: return jsonify({'error':'Email no encontrado'}),404
    if row['respuesta_hash'] != hp(rp): return jsonify({'ok':False,'error':'Respuesta incorrecta'}),401
    tok = secrets.token_urlsafe(20)
    with db() as c:
        c.execute("INSERT INTO tokens_rec(tipo,ref_id,token,expira_en) VALUES('padre',?,?,datetime('now','+15 minutes'))", (row['id'], tok))
    return jsonify({'ok':True,'token':tok,'padre_id':row['id']})

@app.route('/api/padres/reset-pin', methods=['POST'])
def reset_pin_padre():
    d = request.get_json(); tok = d.get('token',''); pn = str(d.get('nuevo_pin',''))
    if len(pn)!=4 or not pn.isdigit(): return jsonify({'error':'PIN debe ser 4 dígitos'}),400
    with db() as c:
        row = c.execute("SELECT ref_id FROM tokens_rec WHERE token=? AND tipo='padre' AND usado=0 AND expira_en>datetime('now')", (tok,)).fetchone()
        if not row: return jsonify({'error':'Token inválido o expirado'}),401
        c.execute("UPDATE padres SET pin_hash=? WHERE id=?", (hp(pn), row['ref_id']))
        c.execute("UPDATE tokens_rec SET usado=1 WHERE token=?", (tok,))
    return jsonify({'ok':True})

@app.route('/api/padres/<int:pid>', methods=['GET'])
def get_padre(pid):
    tok = request.headers.get('X-Session-Token') or request.args.get('token')
    tid = validar_token_sesion(tok, 'padre')
    if tid != pid: return jsonify({'error':'No autorizado'}),401
    with db() as c:
        row = r2d(c.execute("SELECT id,nombre,email,creado_en FROM padres WHERE id=?", (pid,)).fetchone())
    if not row: return jsonify({'error':'No encontrado'}),404
    return jsonify(row)

@app.route('/api/padres/<int:pid>', methods=['PUT'])
def put_padre(pid):
    tok = request.headers.get('X-Session-Token') or request.args.get('token')
    tid = validar_token_sesion(tok, 'padre')
    if tid != pid: return jsonify({'error':'No autorizado'}),401
    d = request.get_json(); fields=[]; vals=[]
    if 'nombre' in d: fields.append("nombre=?"); vals.append(d['nombre'].strip())
    if 'email' in d: fields.append("email=?"); vals.append(d['email'].strip().lower())
    if not fields: return jsonify({'error':'Sin campos'}),400
    vals.append(pid)
    try:
        with db() as c:
            c.execute(f"UPDATE padres SET {','.join(fields)} WHERE id=?", vals)
            row = r2d(c.execute("SELECT id,nombre,email,creado_en FROM padres WHERE id=?", (pid,)).fetchone())
        return jsonify(row)
    except Exception as e:
        if 'UNIQUE' in str(e): return jsonify({'error':'Email ya en uso'}),409
        return jsonify({'error':str(e)}),500

@app.route('/api/padres/<int:pid>/hijos', methods=['GET'])
def hijos_padre(pid):
    with db() as c:
        rows = c.execute("SELECT id,nombre,edad,grado_escolar,avatar,estrellas,tiempo_juego,creado_en FROM usuarios WHERE padre_id=? ORDER BY nombre", (pid,)).fetchall()
    return jsonify(r2l(rows))

@app.route('/api/padres/<int:pid>/resumen', methods=['GET'])
def resumen_padre(pid):
    with db() as c:
        padre = r2d(c.execute("SELECT id,nombre,email FROM padres WHERE id=?", (pid,)).fetchone())
        if not padre: return jsonify({'error':'No encontrado'}),404
        hijos = c.execute("SELECT id,nombre,edad,grado_escolar,avatar,estrellas,tiempo_juego FROM usuarios WHERE padre_id=?", (pid,)).fetchall()
    result = []
    for h in hijos:
        hd = dict(h); hd['promedios'] = promedios(h['id'])
        with db() as c:
            hd['knn'] = r2d(c.execute("SELECT rango,rango_etiqueta,puntuacion_prom,recomendacion FROM clasificaciones_knn WHERE usuario_id=? ORDER BY generado_en DESC LIMIT 1", (h['id'],)).fetchone())
        result.append(hd)
    return jsonify({'padre':padre,'hijos':result})

# ── USUARIOS ─────────────────────────────────────────────────────────────────
@app.route('/api/usuarios', methods=['GET'])
def listar_usuarios():
    pid = request.args.get('padre_id')
    with db() as c:
        q = "SELECT id,nombre,edad,grado_escolar,email,avatar,estrellas,tiempo_juego,creado_en,CASE WHEN pin_hash IS NOT NULL THEN 1 ELSE 0 END tiene_pin FROM usuarios"
        rows = c.execute(q+" WHERE padre_id=? ORDER BY nombre", (pid,)).fetchall() if pid else c.execute(q+" ORDER BY creado_en DESC").fetchall()
    return jsonify(r2l(rows))

@app.route('/api/usuarios', methods=['POST'])
def crear_usuario():
    d = request.get_json()
    nb  = (d.get('nombre') or d.get('name') or '').strip()
    edad = d.get('edad') or d.get('age')
    grado = (d.get('grado_escolar') or '').strip()
    email = (d.get('email') or '').strip().lower() or None
    av  = d.get('avatar','🎮'); pn = str(d.get('pin') or '')
    pr  = d.get('pregunta_secreta','').strip(); rp = d.get('respuesta_secreta','').strip()
    pid = d.get('padre_id')
    if not nb: return jsonify({'error':'Nombre requerido'}),400
    if not edad or not(3<=int(edad)<=18): return jsonify({'error':'Edad entre 3 y 18'}),400
    if pn and(len(pn)!=4 or not pn.isdigit()): return jsonify({'error':'PIN debe ser 4 dígitos'}),400
    try:
        with db() as c:
            cur = c.execute(
                "INSERT INTO usuarios(nombre,edad,grado_escolar,email,avatar,pin_hash,pregunta_secreta,respuesta_hash,padre_id) VALUES(?,?,?,?,?,?,?,?,?)",
                (nb, int(edad), grado, email, av, hp(pn) if pn else None, pr or None, hp(rp) if rp else None, pid or None)
            )
            row = r2d(c.execute("SELECT id,nombre,edad,grado_escolar,email,avatar,estrellas,tiempo_juego,creado_en,CASE WHEN pin_hash IS NOT NULL THEN 1 ELSE 0 END tiene_pin FROM usuarios WHERE id=?", (cur.lastrowid,)).fetchone())
        # Create session token automatically
        tok = crear_session_token('alumno', row['id'])
        return jsonify({**row, 'session_token': tok}), 201
    except Exception as e:
        if 'UNIQUE' in str(e): return jsonify({'error':'Email ya registrado'}),409
        return jsonify({'error':str(e)}),500

# ── Alumno: login por email+pin ──────────────────────────────────────────────
@app.route('/api/usuarios/login', methods=['POST'])
def login_usuario_email():
    d = request.get_json()
    email = (d.get('email') or '').strip().lower()
    pn    = str(d.get('pin') or '')
    if not email: return jsonify({'error':'Email requerido'}),400
    with db() as c:
        row = c.execute("SELECT * FROM usuarios WHERE email=?", (email,)).fetchone()
    if not row: return jsonify({'ok':False,'error':'Email no registrado'}),404
    if row['pin_hash'] is None: return jsonify({'ok':True,'sin_pin':True,'usuario_id':row['id']})
    if row['pin_hash'] != hp(pn): return jsonify({'ok':False,'error':'PIN incorrecto'}),401
    tok = crear_session_token('alumno', row['id'])
    u = dict(row); u.pop('pin_hash', None); u.pop('respuesta_hash', None)
    return jsonify({'ok':True,'session_token':tok,'usuario':u})

@app.route('/api/usuarios/<int:uid>/login', methods=['POST'])
def login_usuario(uid):
    d = request.get_json(); pn = str(d.get('pin') or '')
    with db() as c:
        row = c.execute("SELECT pin_hash FROM usuarios WHERE id=?", (uid,)).fetchone()
    if not row: return jsonify({'error':'No encontrado'}),404
    if row['pin_hash'] is None: return jsonify({'ok':True,'sin_pin':True})
    if row['pin_hash'] == hp(pn):
        tok = crear_session_token('alumno', uid)
        return jsonify({'ok':True,'session_token':tok})
    return jsonify({'ok':False,'error':'PIN incorrecto'}),401

@app.route('/api/usuarios/logout', methods=['POST'])
def logout_usuario():
    tok = request.headers.get('X-Session-Token') or (request.get_json() or {}).get('token','')
    if tok:
        with db() as c:
            c.execute("UPDATE tokens_rec SET usado=1 WHERE token=? AND tipo='session_alumno'", (tok,))
    return jsonify({'ok':True})

# ── Recuperar contraseña (alumno) ────────────────────────────────────────────
@app.route('/api/usuarios/<int:uid>/pregunta', methods=['GET'])
def pregunta_usuario(uid):
    with db() as c:
        row = c.execute("SELECT pregunta_secreta FROM usuarios WHERE id=?", (uid,)).fetchone()
    if not row: return jsonify({'error':'No encontrado'}),404
    if not row['pregunta_secreta']: return jsonify({'error':'Sin pregunta configurada'}),400
    return jsonify({'pregunta':row['pregunta_secreta']})

@app.route('/api/usuarios/pregunta-por-email', methods=['POST'])
def pregunta_por_email():
    d = request.get_json(); email = (d.get('email') or '').strip().lower()
    with db() as c:
        row = c.execute("SELECT id,nombre,pregunta_secreta FROM usuarios WHERE email=?", (email,)).fetchone()
    if not row: return jsonify({'error':'Email no encontrado'}),404
    if not row['pregunta_secreta']: return jsonify({'error':'Sin pregunta de seguridad configurada'}),400
    return jsonify({'usuario_id':row['id'],'nombre':row['nombre'],'pregunta':row['pregunta_secreta']})

@app.route('/api/usuarios/<int:uid>/verificar-pregunta', methods=['POST'])
def verif_preg_usuario(uid):
    d = request.get_json(); rp = (d.get('respuesta') or '').strip()
    with db() as c:
        row = c.execute("SELECT respuesta_hash FROM usuarios WHERE id=?", (uid,)).fetchone()
    if not row or not row['respuesta_hash']: return jsonify({'error':'Sin pregunta configurada'}),400
    if row['respuesta_hash'] != hp(rp): return jsonify({'ok':False,'error':'Respuesta incorrecta'}),401
    tok = secrets.token_urlsafe(20)
    with db() as c:
        c.execute("INSERT INTO tokens_rec(tipo,ref_id,token,expira_en) VALUES('usuario',?,?,datetime('now','+10 minutes'))", (uid, tok))
    return jsonify({'ok':True,'token':tok})

@app.route('/api/usuarios/<int:uid>/reset-pin', methods=['POST'])
def reset_pin_usuario(uid):
    d = request.get_json(); tok = d.get('token',''); pn = str(d.get('nuevo_pin',''))
    if len(pn)!=4 or not pn.isdigit(): return jsonify({'error':'PIN debe ser 4 dígitos'}),400
    with db() as c:
        row = c.execute("SELECT id FROM tokens_rec WHERE token=? AND tipo='usuario' AND ref_id=? AND usado=0 AND expira_en>datetime('now')", (tok, uid)).fetchone()
        if not row: return jsonify({'error':'Token inválido o expirado'}),401
        c.execute("UPDATE usuarios SET pin_hash=? WHERE id=?", (hp(pn), uid))
        c.execute("UPDATE tokens_rec SET usado=1 WHERE token=?", (tok,))
    return jsonify({'ok':True})

# ── CRUD usuario ─────────────────────────────────────────────────────────────
@app.route('/api/usuarios/<int:uid>', methods=['GET'])
def get_usuario(uid):
    with db() as c:
        row = c.execute("SELECT id,nombre,edad,grado_escolar,email,avatar,estrellas,tiempo_juego,creado_en,padre_id,es_tutor,info_tutor,CASE WHEN pin_hash IS NOT NULL THEN 1 ELSE 0 END tiene_pin FROM usuarios WHERE id=?", (uid,)).fetchone()
    if not row: return jsonify({'error':'No encontrado'}),404
    return jsonify(r2d(row))

@app.route('/api/usuarios/<int:uid>', methods=['PUT'])
def put_usuario(uid):
    # Allow self-edit (session token) or parent
    tok = request.headers.get('X-Session-Token') or request.args.get('token')
    authed = False
    if tok:
        if validar_token_sesion(tok,'alumno') == uid: authed=True
        pid = validar_token_sesion(tok,'padre')
        if pid:
            with db() as c:
                h = c.execute("SELECT id FROM usuarios WHERE id=? AND padre_id=?", (uid,pid)).fetchone()
            if h: authed=True
    if not authed: return jsonify({'error':'No autorizado'}),401

    d = request.get_json(); fields=[]; vals=[]
    for campo in ['nombre','edad','grado_escolar','avatar','estrellas','tiempo_juego','info_tutor']:
        if campo in d: fields.append(f"{campo}=?"); vals.append(d[campo])
    if 'email' in d:
        fields.append("email=?"); vals.append((d['email'] or '').strip().lower() or None)
    if 'es_tutor' in d:
        fields.append("es_tutor=?"); vals.append(1 if d['es_tutor'] else 0)
    if 'pin' in d and d['pin']:
        p = str(d['pin'])
        if len(p)==4 and p.isdigit(): fields.append("pin_hash=?"); vals.append(hp(p))
    if 'pregunta_secreta' in d: fields.append("pregunta_secreta=?"); vals.append(d['pregunta_secreta'])
    if 'respuesta_secreta' in d and d['respuesta_secreta']:
        fields.append("respuesta_hash=?"); vals.append(hp(d['respuesta_secreta']))
    if not fields: return jsonify({'error':'Sin campos'}),400
    vals.append(uid)
    try:
        with db() as c:
            c.execute(f"UPDATE usuarios SET {','.join(fields)} WHERE id=?", vals)
            row = r2d(c.execute("SELECT id,nombre,edad,grado_escolar,email,avatar,estrellas,tiempo_juego,creado_en,es_tutor,info_tutor,CASE WHEN pin_hash IS NOT NULL THEN 1 ELSE 0 END tiene_pin FROM usuarios WHERE id=?", (uid,)).fetchone())
        return jsonify(row)
    except Exception as e:
        if 'UNIQUE' in str(e): return jsonify({'error':'Email ya en uso'}),409
        return jsonify({'error':str(e)}),500

@app.route('/api/usuarios/<int:uid>', methods=['DELETE'])
def del_usuario(uid):
    with db() as c: c.execute("DELETE FROM usuarios WHERE id=?", (uid,))
    return jsonify({'ok':True})

# ── TUTOR ────────────────────────────────────────────────────────────────────
@app.route('/api/usuarios/<int:uid>/tutor', methods=['POST'])
def crear_tutor(uid):
    tok = request.headers.get('X-Session-Token') or request.args.get('token')
    if validar_token_sesion(tok,'alumno') != uid:
        return jsonify({'error':'No autorizado'}),401
    d = request.get_json()
    info = (d.get('info_tutor') or '').strip()
    with db() as c:
        c.execute("UPDATE usuarios SET es_tutor=1, info_tutor=? WHERE id=?", (info, uid))
        row = r2d(c.execute("SELECT id,nombre,edad,grado_escolar,email,avatar,estrellas,tiempo_juego,es_tutor,info_tutor FROM usuarios WHERE id=?", (uid,)).fetchone())
    return jsonify({'ok':True,'usuario':row})

@app.route('/api/usuarios/<int:uid>/tutor', methods=['DELETE'])
def quitar_tutor(uid):
    tok = request.headers.get('X-Session-Token') or request.args.get('token')
    if validar_token_sesion(tok,'alumno') != uid:
        return jsonify({'error':'No autorizado'}),401
    with db() as c:
        c.execute("UPDATE usuarios SET es_tutor=0, info_tutor='' WHERE id=?", (uid,))
    return jsonify({'ok':True})

# ── REPORTE TIEMPO DE USO ────────────────────────────────────────────────────
@app.route('/api/usuarios/<int:uid>/reporte-tiempo', methods=['GET'])
def get_reporte_tiempo(uid):
    with db() as c:
        rows = c.execute(
            "SELECT fecha,SUM(minutos) total_min,categoria FROM reporte_tiempo WHERE usuario_id=? GROUP BY fecha,categoria ORDER BY fecha DESC LIMIT 60",
            (uid,)
        ).fetchall()
        total = c.execute("SELECT tiempo_juego FROM usuarios WHERE id=?", (uid,)).fetchone()
    # Categorize via KNN-style logic using session data
    reporte = r2l(rows)
    # AI categorization: use KNN classification as context for time
    knn_data = None
    if KNN_OK:
        try:
            pm = promedios(uid)
            with db() as c:
                u = r2d(c.execute("SELECT edad FROM usuarios WHERE id=?", (uid,)).fetchone())
            if u:
                knn_data = knn.clasificar(pm, edad=u['edad'])
        except: pass
    return jsonify({
        'tiempo_total_minutos': total['tiempo_juego'] if total else 0,
        'registros': reporte,
        'clasificacion_ia': knn_data
    })

@app.route('/api/usuarios/<int:uid>/reporte-tiempo', methods=['POST'])
def reg_reporte_tiempo(uid):
    d = request.get_json()
    minutos   = int(d.get('minutos', 0))
    categoria = (d.get('categoria') or 'General').strip()
    desc      = (d.get('descripcion') or '').strip()
    with db() as c:
        c.execute(
            "INSERT INTO reporte_tiempo(usuario_id,minutos,categoria,descripcion) VALUES(?,?,?,?)",
            (uid, minutos, categoria, desc)
        )
        c.execute("UPDATE usuarios SET tiempo_juego=tiempo_juego+? WHERE id=?", (minutos, uid))
    return jsonify({'ok':True}),201

# ── PUNTUACIONES ─────────────────────────────────────────────────────────────
@app.route('/api/usuarios/<int:uid>/puntuaciones', methods=['POST'])
def reg_punt(uid):
    d = request.get_json(); area = (d.get('area') or '').lower()
    if not area: return jsonify({'error':'Área requerida'}),400
    with db() as c:
        c.execute(
            "INSERT INTO puntuaciones(usuario_id,area,puntuacion,correctas,total_preguntas) VALUES(?,?,?,?,?)",
            (uid, area, min(100,max(0,float(d.get('puntuacion',0)))), int(d.get('correctas',0)), int(d.get('total',0)))
        )
        ts = c.execute("SELECT SUM(correctas) FROM puntuaciones WHERE usuario_id=?", (uid,)).fetchone()[0] or 0
        c.execute("UPDATE usuarios SET estrellas=? WHERE id=?", (ts, uid))
    guardar_knn(uid); return jsonify({'ok':True}),201

@app.route('/api/usuarios/<int:uid>/puntuaciones', methods=['GET'])
def get_punt(uid):
    with db() as c:
        rows = c.execute("SELECT * FROM puntuaciones WHERE usuario_id=? ORDER BY registrado_en DESC", (uid,)).fetchall()
    return jsonify(r2l(rows))

@app.route('/api/usuarios/<int:uid>/historial', methods=['POST'])
def reg_hist(uid):
    d = request.get_json()
    with db() as c:
        c.execute(
            "INSERT INTO historial_actividades(usuario_id,actividad,tipo_juego,resultado,estrellas) VALUES(?,?,?,?,?)",
            (uid, d.get('actividad',''), d.get('tipo_juego',''), d.get('resultado','completado'), int(d.get('estrellas',0)))
        )
        t = int(d.get('tiempo_jugado', 0))
        if t > 0: c.execute("UPDATE usuarios SET tiempo_juego=tiempo_juego+? WHERE id=?", (t, uid))
    return jsonify({'ok':True}),201

@app.route('/api/usuarios/<int:uid>/historial', methods=['GET'])
def get_hist(uid):
    with db() as c:
        rows = c.execute("SELECT * FROM historial_actividades WHERE usuario_id=? ORDER BY registrado_en DESC LIMIT 50", (uid,)).fetchall()
    return jsonify(r2l(rows))

@app.route('/api/usuarios/<int:uid>/logros', methods=['GET'])
def get_logros(uid):
    with db() as c:
        rows = c.execute("SELECT * FROM logros WHERE usuario_id=? ORDER BY fecha_desbloqueo DESC", (uid,)).fetchall()
    return jsonify(r2l(rows))

@app.route('/api/usuarios/<int:uid>/logros', methods=['POST'])
def save_logro(uid):
    d = request.get_json()
    with db() as c:
        c.execute(
            "INSERT INTO logros(usuario_id,logro_id,desbloqueado,progreso,fecha_desbloqueo) VALUES(?,?,?,?,?) ON CONFLICT(usuario_id,logro_id) DO UPDATE SET desbloqueado=excluded.desbloqueado,progreso=excluded.progreso,fecha_desbloqueo=excluded.fecha_desbloqueo",
            (uid, d['logro_id'], int(d.get('desbloqueado',0)), float(d.get('progreso',0)), d.get('fecha_desbloqueo'))
        )
    return jsonify({'ok':True})

@app.route('/api/usuarios/<int:uid>/clasificar', methods=['GET'])
def clasificar(uid):
    if not KNN_OK: return jsonify({'error':'KNN no disponible'}),503
    with db() as c:
        u = r2d(c.execute("SELECT * FROM usuarios WHERE id=?", (uid,)).fetchone())
    if not u: return jsonify({'error':'No encontrado'}),404
    pm = promedios(uid); r = knn.clasificar(pm, edad=u['edad']); guardar_knn(uid)
    return jsonify({'usuario':u,'promedios':pm,**r})

@app.route('/api/usuarios/<int:uid>/resumen', methods=['GET'])
def resumen_usuario(uid):
    pm = promedios(uid)
    with db() as c:
        knn_row = r2d(c.execute("SELECT * FROM clasificaciones_knn WHERE usuario_id=? ORDER BY generado_en DESC LIMIT 1", (uid,)).fetchone())
        u = r2d(c.execute("SELECT id,nombre,edad,grado_escolar,email,avatar,estrellas,tiempo_juego,es_tutor FROM usuarios WHERE id=?", (uid,)).fetchone())
    return jsonify({'usuario':u,'promedios':pm,'clasificacion':knn_row})

@app.route('/api/knn/estadisticas', methods=['GET'])
def knn_stats():
    with db() as c:
        rows = c.execute("SELECT rango_etiqueta,COUNT(*) total FROM clasificaciones_knn WHERE id IN(SELECT MAX(id) FROM clasificaciones_knn GROUP BY usuario_id) GROUP BY rango_etiqueta").fetchall()
    return jsonify(r2l(rows))

@app.route('/')
def idx(): return send_from_directory(FRONT,'index.html')
@app.route('/<path:p>')
def sta(p): return send_from_directory(FRONT,p)

if __name__ == '__main__':
    os.makedirs(FRONT, exist_ok=True); init_db()
    print("🚀 EduPlay v5 → http://localhost:5000")
    app.run(debug=True, port=5000)
