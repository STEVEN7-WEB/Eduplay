# Archivo: routes/juego.py

from flask import Blueprint, request, jsonify
from database import db
from ai_model.knn_model import EduPlayKNN
import json  # Importante para convertir las opciones de texto a lista

rutas_juego = Blueprint('juego', __name__)
knn = EduPlayKNN()

# ====================================================================
# 1. NUEVA RUTA: OBTENER PREGUNTAS DESDE NEON PARA EL JUEGO
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
            # Como tu base de datos usa diccionarios (DictCursor), accedemos por el nombre de la columna
            pregunta_texto = r['pregunta_texto'] if type(r) is dict or hasattr(r, 'keys') else r[0]
            opciones = r['opciones'] if type(r) is dict or hasattr(r, 'keys') else r[1]
            respuesta_correcta = r['respuesta_correcta'] if type(r) is dict or hasattr(r, 'keys') else r[2]

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
        c.close()
        conn.close()



# ====================================================================
# 2. RUTA EXISTENTE: GUARDAR PARTIDA Y EVALUAR CON IA (KNN)
# ====================================================================
@rutas_juego.route('/guardar_partida', methods=['POST'])
def guardar_partida():
    data = request.json
    uid = data.get('user_id')
    subject = data.get('subject') 
    points = data.get('points', 0)
    # Ya no pedimos el tiempo porque tu tabla no tiene la columna time_taken_seconds

    try:
        conn = db()
        c = conn.cursor()
        
        # 1. Guardar la puntuación en scores (¡ADAPTADO EXACTAMENTE A TUS COLUMNAS!)
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
        mejor_puntaje = row_mejor['mejor_puntaje'] if type(row_mejor) is dict else row_mejor[0]
        
        # 4. Calcular los promedios actualizados para la IA
        c.execute("""
            SELECT subject, AVG(points) as promedio 
            FROM scores 
            WHERE user_id = %s 
            GROUP BY subject
        """, (uid,))
        
        promedios_db = c.fetchall()
        promedios_dict = {}
        for row in promedios_db:
            k = row['subject'] if type(row) is dict else row[0]
            v = row['promedio'] if type(row) is dict else row[1]
            promedios_dict[k] = v
        
        # 5. Obtener grado para la IA de forma segura
        c.execute("SELECT * FROM users WHERE id = %s", (uid,))
        user_info = c.fetchone()
        
        grado = 1 
        if user_info and type(user_info) is dict:
            grado = user_info.get('grado_escolar', user_info.get('grade', user_info.get('grado', 1)))
            
        edad_estimada = grado + 5 
        
        # 6. Alimentar el modelo KNN (Adaptado a tu columna 'rango' tipo integer)
        resultado_ia = {"recomendacion": "¡Sigue jugando para desbloquear tu análisis de IA!"}
        try:
            resultado_ia_temp = knn.clasificar(promedios_dict, edad=edad_estimada)
            if resultado_ia_temp:
                resultado_ia = resultado_ia_temp
                
                # Forzamos a que el rango sea un número para que tu base de datos lo acepte
                try:
                    rango_numero = int(resultado_ia.get('rango', 0))
                except:
                    rango_numero = 0
                    
                c.execute("""
                    INSERT INTO knn_results (user_id, rango, etiqueta, promedio_general, recomendacion)
                    VALUES (%s, %s, %s, %s, %s)
                """, (uid, rango_numero, str(resultado_ia.get('etiqueta', '')), float(resultado_ia.get('puntuacion_promedio', 0)), str(resultado_ia.get('recomendacion', ''))))
        except Exception as ia_error:
            print("⚠️ Aviso: La IA KNN falló, pero el juego se guardó:", ia_error)
        
        conn.commit() 
        
        return jsonify({
            'success': True,
            'mejor_puntaje': mejor_puntaje,
            'ia_feedback': resultado_ia
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