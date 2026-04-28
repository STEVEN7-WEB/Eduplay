from flask import Blueprint, request, jsonify
import secrets
from database import db
from utils import hp, r2d, r2l, crear_session_token, validar_token_sesion

usuarios_bp = Blueprint('usuarios', __name__)

AVATARES = ['🦊','🐱','🐼','🐶','🐸','🦄','🐯','🐧','🦋','🐙','🦁','🐨','🐻','🐳','🦀']

@usuarios_bp.route('/avatares', methods=['GET'])
def get_avatares():
    return jsonify(AVATARES)

# --- RUTA PARA LISTAR TODOS LOS ALUMNOS ---
@usuarios_bp.route('/lista', methods=['GET'])
def listar_usuarios():
    try:
        conn = db()
        c = conn.cursor()
        c.execute("SELECT id, name, grade FROM users")
        usuarios_db = c.fetchall()
        
        resultado = []
        for u in usuarios_db:
            resultado.append({
                'id': u['id'] if isinstance(u, dict) else u[0],
                'nombre': u['name'] if isinstance(u, dict) else u[1],
                'grade': u['grade'] if isinstance(u, dict) else u[2]
            })
        return jsonify(resultado)
    except Exception as e:
        print("Error listando usuarios:", e)
        return jsonify([])
    finally:
        if 'c' in locals(): c.close()
        if 'conn' in locals(): conn.close()

@usuarios_bp.route('/usuarios', methods=['POST'])
def crear_usuario():
    d = request.get_json()
    nb = (d.get('nombre') or d.get('name') or '').strip()
    email = (d.get('email') or '').strip().lower()
    pn = str(d.get('pin') or d.get('password') or '1234')
    grado = int(d.get('grado_escolar') or d.get('grade') or 1)
    
    if not nb: return jsonify({'error':'Nombre requerido'}), 400
    if not email: return jsonify({'error':'Email requerido'}), 400
    
    conn = db()
    cur = conn.cursor()
    try:
        cur.execute(
            "INSERT INTO users (name, email, password, grade, role) VALUES (%s, %s, %s, %s, 'student') RETURNING id, name, email, grade",
            (nb, email, hp(pn), grado)
        )
        new_user = cur.fetchone()
        conn.commit()
        
        res = {
            'id': new_user[0],
            'nombre': new_user[1],
            'email': new_user[2],
            'grado_escolar': new_user[3],
            'edad': new_user[3] + 5,
            'avatar': '🎮',
            'estrellas': 0,
            'tiempo_juego': 0,
            'tiene_pin': 1
        }
        
        tok = crear_session_token('alumno', res['id'])
        return jsonify({**res, 'session_token': tok}), 201
    except Exception as e:
        conn.rollback()
        if 'unique' in str(e).lower(): return jsonify({'error':'Email ya registrado'}), 409
        return jsonify({'error':str(e)}), 500
    finally:
        cur.close()
        conn.close()

@usuarios_bp.route('/usuarios/<int:uid>', methods=['GET'])
def get_usuario(uid):
    conn = db()
    cur = conn.cursor()
    try:
        q = """
            SELECT 
                id, name AS nombre, (grade + 5) AS edad, grade::text AS grado_escolar, 
                email, '🎮' AS avatar, 0 AS estrellas, 0 AS tiempo_juego, 
                created_at AS creado_en, 1 AS tiene_pin 
            FROM users WHERE id=%s
        """
        cur.execute(q, (uid,))
        row = cur.fetchone()
        if not row: return jsonify({'error':'No encontrado'}), 404
        return jsonify(r2d(row))
    finally:
        cur.close()
        conn.close()

# --- RUTA 1: LOGIN POR EMAIL ---
@usuarios_bp.route('/usuarios/login', methods=['POST', 'OPTIONS'], strict_slashes=False)
def login_usuario_email():
    if request.method == 'OPTIONS':
        return jsonify({}), 200

    d = request.get_json()
    email = (d.get('email') or '').strip().lower()
    pn = str(d.get('pin') or d.get('password') or '')
    
    if not email: return jsonify({'error':'Email requerido'}), 400
    
    conn = db()
    cur = conn.cursor()
    try:
        cur.execute("SELECT id, name, email, password, grade FROM users WHERE email=%s", (email,))
        row = cur.fetchone()
        
        if not row: return jsonify({'ok':False,'error':'Email no registrado'}), 404
        
        if row[3] != hp(pn) and row[3] != pn: 
            return jsonify({'ok':False,'error':'PIN o Contraseña incorrectos'}), 401
            
        tok = crear_session_token('alumno', row[0])
        u = {
            'id': row[0],
            'nombre': row[1],
            'email': row[2],
            'grado_escolar': row[4],
            'edad': (row[4] or 1) + 5
        }
        return jsonify({'ok':True,'session_token':tok,'usuario': u})
    finally:
        cur.close()
        conn.close()

# --- RUTA 2: LOGIN POR ID (PIN) ---
@usuarios_bp.route('/usuarios/<int:uid>/login', methods=['POST', 'OPTIONS'], strict_slashes=False)
def login_usuario_pin(uid):
    if request.method == 'OPTIONS':
        return jsonify({}), 200

    d = request.get_json()
    pn = str(d.get('pin') or d.get('password') or '')
    
    conn = db()
    cur = conn.cursor()
    try:
        cur.execute("SELECT password FROM users WHERE id=%s", (uid,))
        row = cur.fetchone()
        
        if not row: return jsonify({'error':'No encontrado'}), 404
        
        if row[0] is None: return jsonify({'ok':True,'sin_pin':True})
        
        if row[0] == hp(pn) or row[0] == pn:
            tok = crear_session_token('alumno', uid)
            return jsonify({'ok':True,'session_token':tok})
            
        return jsonify({'ok':False,'error':'PIN incorrecto'}), 401
    finally:
        cur.close()
        conn.close()

@usuarios_bp.route('/usuarios/<int:uid>/pregunta', methods=['GET'])
def pregunta_usuario(uid):
    return jsonify({'error':'La recuperación por pregunta no está habilitada en la nueva base de datos.'}), 400

@usuarios_bp.route('/usuarios/logout', methods=['POST'])
def logout_usuario():
    tok = request.headers.get('X-Session-Token') or (request.get_json() or {}).get('token','')
    if tok:
        conn = db()
        cur = conn.cursor()
        try:
            cur.execute("UPDATE tokens_rec SET usado=1 WHERE token=%s AND tipo='session_alumno'", (tok,))
            conn.commit()
        except Exception as e:
            conn.rollback()
        finally:
            cur.close()
            conn.close()
    return jsonify({'ok':True})

@usuarios_bp.route('/admin/registro', methods=['POST'])
def registrar_admin():
    d = request.get_json()
    nombre = d.get('nombre', '').strip()
    email = d.get('email', '').strip().lower()
    password = str(d.get('password', ''))

    if not nombre or not email or not password:
        return jsonify({'error': 'Todos los campos son obligatorios'}), 400

    conn = db()
    cur = conn.cursor()
    try:
        cur.execute(
            "INSERT INTO users (name, email, password, role) VALUES (%s, %s, %s, 'admin') RETURNING id",
            (nombre, email, hp(password))
        )
        new_id = cur.fetchone()[0]
        conn.commit()
        
        token = crear_session_token('admin', new_id)
        return jsonify({'ok': True, 'session_token': token, 'admin_id': new_id}), 201
    except Exception as e:
        conn.rollback()
        if 'unique' in str(e).lower(): 
            return jsonify({'error': 'Este correo ya está registrado'}), 409
        return jsonify({'error': str(e)}), 500
    finally:
        cur.close()
        conn.close()

@usuarios_bp.route('/perfil/<int:uid>', methods=['GET'])
def obtener_perfil_detallado(uid):
    try:
        conn = db()
        c = conn.cursor()
        
        c.execute("SELECT name, grade FROM users WHERE id = %s", (uid,))
        u = c.fetchone()
        
        if not u:
            return jsonify({'success': False, 'error': 'No existe'}), 404

        nombre = u[0] if isinstance(u, (tuple, list)) else u.get('name', 'Usuario')
        grado = u[1] if isinstance(u, (tuple, list)) else u.get('grade', 1)
        
        # Calculamos la edad matemáticamente (Grado + 5)
        edad_calculada = (int(grado) + 5) if grado else 6

        # Buscamos la mejor materia
        c.execute("""
            SELECT subject FROM scores 
            WHERE user_id = %s 
            GROUP BY subject 
            ORDER BY AVG(points) DESC LIMIT 1
        """, (uid,))
        s = c.fetchone()
        
        mejor_raw = "math"
        if s:
            mejor_raw = s[0] if isinstance(s, (tuple, list)) else s.get('subject')

        nombres = {'math':'Matemáticas', 'memory':'Memoria', 'logic':'Lógica', 
                   'grammar':'Gramática', 'english':'Inglés', 'geography':'Geografía', 
                   'art':'Arte', 'science':'Ciencia'}

        return jsonify({
            'success': True,
            'nombre': nombre,
            'grado': grado,
            'edad': edad_calculada,
            'mejor_materia': nombres.get(mejor_raw, mejor_raw)
        })
    except Exception as e:
        print(f"❌ Error en perfil: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500
    finally:
        if 'c' in locals(): c.close()
        if 'conn' in locals(): conn.close()