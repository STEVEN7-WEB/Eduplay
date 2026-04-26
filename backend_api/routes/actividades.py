from flask import Blueprint, request, jsonify
from database import db
from utils import r2d, r2l

# IMPORTANTE: Aquí importaremos la IA cuando llenemos ai_service.py
# from ai_service import knn, KNN_OK, guardar_knn 

actividades_bp = Blueprint('actividades', __name__)

@actividades_bp.route('/usuarios/<int:uid>/puntuaciones', methods=['POST'])
def reg_punt(uid):
    d = request.get_json()
    area = (d.get('area') or '').lower()
    if not area: return jsonify({'error':'Área requerida'}),400
    with db() as c:
        c.execute(
            "INSERT INTO puntuaciones(usuario_id,area,puntuacion,correctas,total_preguntas) VALUES(?,?,?,?,?)",
            (uid, area, min(100,max(0,float(d.get('puntuacion',0)))), int(d.get('correctas',0)), int(d.get('total',0)))
        )
        ts = c.execute("SELECT SUM(correctas) FROM puntuaciones WHERE usuario_id=?", (uid,)).fetchone()[0] or 0
        c.execute("UPDATE usuarios SET estrellas=? WHERE id=?", (ts, uid))
    
    # guardar_knn(uid) # Descomentar cuando ai_service esté listo
    return jsonify({'ok':True}),201

@actividades_bp.route('/usuarios/<int:uid>/puntuaciones', methods=['GET'])
def get_punt(uid):
    with db() as c:
        rows = c.execute("SELECT * FROM puntuaciones WHERE usuario_id=? ORDER BY registrado_en DESC", (uid,)).fetchall()
    return jsonify(r2l(rows))

@actividades_bp.route('/usuarios/<int:uid>/historial', methods=['POST'])
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

@actividades_bp.route('/usuarios/<int:uid>/logros', methods=['GET'])
def get_logros(uid):
    with db() as c:
        rows = c.execute("SELECT * FROM logros WHERE usuario_id=? ORDER BY fecha_desbloqueo DESC", (uid,)).fetchall()
    return jsonify(r2l(rows))

@actividades_bp.route('/usuarios/<int:uid>/reporte-tiempo', methods=['POST'])
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