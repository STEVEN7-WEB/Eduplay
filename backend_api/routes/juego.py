from flask import Blueprint, request, jsonify
from database import db
import json  # Importante para convertir las opciones de texto a lista

rutas_juego = Blueprint('juego', __name__)

# ====================================================================
# 1. RUTA: OBTENER PREGUNTAS DESDE NEON PARA EL JUEGO
# ====================================================================
@rutas_juego.route('/<materia>/<int:grado>', methods=['GET'])
def obtener_preguntas_juego(materia, grado):
    try:
        conn = db()
        c = conn.cursor()
        
        # Buscamos las preguntas filtrando por materia y grado
        c.execute("""
            SELECT pregunta_texto, opciones, respuesta_correcta 
            FROM preguntas 
            WHERE materia = %s AND grado = %s
        """, (materia, grado))
        
        rows = c.fetchall()
        
        preguntas = []
        for r in rows:
            # Manejo de Diccionarios y Tuplas dependiendo de la configuración de psycopg2
            pregunta_texto = r['pregunta_texto'] if hasattr(r, 'keys') else r[0]
            opciones = r['opciones'] if hasattr(r, 'keys') else r[1]
            respuesta_correcta = r['respuesta_correcta'] if hasattr(r, 'keys') else r[2]

            # Si Neon devuelve las opciones como un string JSON, las convertimos a lista
            if isinstance(opciones, str):
                opciones = json.loads(opciones)
                
            preguntas.append({
                "pregunta": pregunta_texto,
                "opciones": opciones,
                "correcta": respuesta_correcta
            })
            
        return jsonify(preguntas)

    except Exception as e:
        print("Error al obtener preguntas de la BD:", e)
        return jsonify({"error": str(e)}), 500
    finally:
        if 'c' in locals():
            c.close()
        if 'conn' in locals():
            conn.close()

# ====================================================================
# 2. RUTA: GUARDAR PARTIDA (Sin IA, solo Base de Datos)
# ====================================================================
@rutas_juego.route('/guardar_partida', methods=['POST'])
def guardar_partida():
    data = request.json
    uid = data.get('user_id')
    subject = data.get('subject') 
    points = data.get('points', 0)

    try:
        conn = db()
        c = conn.cursor()
        
        # 1. Guardar la puntuación en scores
        c.execute("""
            INSERT INTO scores (user_id, subject, points)
            VALUES (%s, %s, %s)
        """, (uid, subject, points))
        
        # 2. Sumar las estrellas al usuario
        try:
            c.execute("""
                UPDATE users SET estrellas = COALESCE(estrellas, 0) + %s WHERE id = %s
            """, (points, uid))
        except Exception as e_estrellas:
            print("⚠️ Aviso: No se pudo sumar estrellas:", e_estrellas)
        
        # 3. Calcular el MEJOR RÉCORD histórico 
        c.execute("""
            SELECT MAX(points) as mejor_puntaje 
            FROM scores 
            WHERE user_id = %s AND subject = %s
        """, (uid, subject))
        
        row_mejor = c.fetchone()
        mejor_puntaje = row_mejor['mejor_puntaje'] if hasattr(row_mejor, 'keys') else row_mejor[0]
        
        conn.commit() 
        
        return jsonify({
            'success': True,
            'mejor_puntaje': mejor_puntaje,
            'mensaje': 'Partida guardada correctamente.'
        })

    except Exception as e:
        if 'conn' in locals():
            conn.rollback()
        print("❌ Error CRÍTICO al guardar la partida:", e)
        return jsonify({'error': str(e)}), 500
    finally:
        if 'c' in locals():
            c.close()
        if 'conn' in locals():
            conn.close()