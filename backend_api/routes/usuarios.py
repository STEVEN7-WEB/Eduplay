from flask import Blueprint, request, jsonify
import secrets
from database import db
from utils import hp, r2d, r2l, crear_session_token, validar_token_sesion

usuarios_bp = Blueprint('usuarios', __name__)

AVATARES = ['🦊','🐱','🐼','🐶','🐸','🦄','🐯','🐧','🦋','🐙','🦁','🐨','🐻','🐳','🦀']

@usuarios_bp.route('/avatares', methods=['GET'])
def get_avatares():
    return jsonify(AVATARES)

@usuarios_bp.route('/usuarios', methods=['GET'])
def listar_usuarios():
    pid = request.args.get('padre_id')
    with db() as c:
        q = "SELECT id,nombre,edad,grado_escolar,email,avatar,estrellas,tiempo_juego,creado_en,CASE WHEN pin_hash IS NOT NULL THEN 1 ELSE 0 END tiene_pin FROM usuarios"
        rows = c.execute(q+" WHERE padre_id=? ORDER BY nombre", (pid,)).fetchall() if pid else c.execute(q+" ORDER BY creado_en DESC").fetchall()
    return jsonify(r2l(rows))

@usuarios_bp.route('/usuarios', methods=['POST'])
def crear_usuario():
    d = request.get_json()
    nb  = (d.get('nombre') or d.get('name') or '').strip()
    edad = d.get('edad') or d.get('age')
    grado = (d.get('grado_escolar') or '').strip()
    email = (d.get('email') or '').strip().lower() or None
    av  = d.get('avatar','🎮')
    pn = str(d.get('pin') or '')
    pr  = d.get('pregunta_secreta','').strip()
    rp = d.get('respuesta_secreta','').strip()
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
        tok = crear_session_token('alumno', row['id'])
        return jsonify({**row, 'session_token': tok}), 201
    except Exception as e:
        if 'UNIQUE' in str(e): return jsonify({'error':'Email ya registrado'}),409
        return jsonify({'error':str(e)}),500

@usuarios_bp.route('/usuarios/login', methods=['POST'])
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
    u = dict(row)
    u.pop('pin_hash', None); u.pop('respuesta_hash', None)
    return jsonify({'ok':True,'session_token':tok,'usuario':u})

@usuarios_bp.route('/usuarios/<int:uid>', methods=['GET'])
def get_usuario(uid):
    with db() as c:
        row = c.execute("SELECT id,nombre,edad,grado_escolar,email,avatar,estrellas,tiempo_juego,creado_en,padre_id,es_tutor,info_tutor,CASE WHEN pin_hash IS NOT NULL THEN 1 ELSE 0 END tiene_pin FROM usuarios WHERE id=?", (uid,)).fetchone()
    if not row: return jsonify({'error':'No encontrado'}),404
    return jsonify(r2d(row))