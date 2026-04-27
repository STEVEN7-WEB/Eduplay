from flask import Blueprint, request, jsonify
from database import db
import json

actividades_bp = Blueprint('actividades', __name__)

# RUTA PARA EL ADMIN: Guardar la pregunta
@actividades_bp.route('/preguntas', methods=['POST'])
def guardar_pregunta():
    data = request.get_json()
    conn = db()
    cur = conn.cursor()
    try:
        cur.execute("""
            INSERT INTO preguntas (materia, grado, pregunta_texto, opciones, respuesta_correcta)
            VALUES (%s, %s, %s, %s, %s)
        """, (data['materia'], data['grado'], data['texto'], 
              json.dumps(data['opciones']), data['correcta']))
        conn.commit()
        return jsonify({"ok": True, "mensaje": "Pregunta guardada"}), 201
    except Exception as e:
        return jsonify({"ok": False, "error": str(e)}), 500
    finally:
        cur.close()
        conn.close()

# RUTA PARA LA APP MÓVIL: Obtener preguntas por filtro
@actividades_bp.route('/obtener_preguntas/<materia>/<int:grado>', methods=['GET'])
def obtener_preguntas(materia, grado):
    conn = db()
    cur = conn.cursor()
    cur.execute("SELECT pregunta_texto, opciones, respuesta_correcta FROM preguntas WHERE materia=%s AND grado=%s", (materia, grado))
    rows = cur.fetchall()
    
    # Convertimos a una lista de diccionarios para la app
    preguntas = []
    for r in rows:
        preguntas.append({
            "pregunta": r[0],
            "opciones": r[1],
            "correcta": r[2]
        })
    return jsonify(preguntas)