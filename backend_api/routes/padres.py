from flask import Blueprint, request, jsonify
import secrets
from database import db
from utils import hp, r2d, r2l, crear_session_token, validar_token_sesion

# Definimos el Blueprint
padres_bp = Blueprint('padres', __name__)

@padres_bp.route('/padres/registro', methods=['POST'])
def reg_padre():
    d = request.get_json()
    nb = d.get('nombre','').strip()
    em = d.get('email','').strip().lower()
    pn = str(d.get('pin',''))
    pr = d.get('pregunta_secreta','').strip()
    rp = d.get('respuesta_secreta','').strip()
    
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

@padres_bp.route('/padres/login', methods=['POST'])
def login_padre():
    d = request.get_json()
    em = d.get('email','').strip().lower()
    pn = str(d.get('pin',''))
    with db() as c:
        row = c.execute("SELECT * FROM padres WHERE email=?", (em,)).fetchone()
    if not row: return jsonify({'ok':False,'error':'Email no registrado'}),404
    if row['pin_hash'] != hp(pn): return jsonify({'ok':False,'error':'PIN incorrecto'}),401
    tok = crear_session_token('padre', row['id'])
    return jsonify({'ok':True,'session_token':tok,'padre':{'id':row['id'],'nombre':row['nombre'],'email':row['email']}})

@padres_bp.route('/padres/logout', methods=['POST'])
def logout_padre():
    tok = request.headers.get('X-Session-Token') or (request.get_json() or {}).get('token','')
    if tok:
        with db() as c:
            c.execute("UPDATE tokens_rec SET usado=1 WHERE token=? AND tipo='session_padre'", (tok,))
    return jsonify({'ok':True})

@padres_bp.route('/padres/<int:pid>', methods=['GET'])
def get_padre(pid):
    tok = request.headers.get('X-Session-Token') or request.args.get('token')
    tid = validar_token_sesion(tok, 'padre')
    if tid != pid: return jsonify({'error':'No autorizado'}),401
    with db() as c:
        row = r2d(c.execute("SELECT id,nombre,email,creado_en FROM padres WHERE id=?", (pid,)).fetchone())
    if not row: return jsonify({'error':'No encontrado'}),404
    return jsonify(row)

@padres_bp.route('/padres/<int:pid>/hijos', methods=['GET'])
def hijos_padre(pid):
    with db() as c:
        rows = c.execute("SELECT id,nombre,edad,grado_escolar,avatar,estrellas,tiempo_juego,creado_en FROM usuarios WHERE padre_id=? ORDER BY nombre", (pid,)).fetchall()
    return jsonify(r2l(rows))