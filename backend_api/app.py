from flask import Flask, send_from_directory, render_template, request, jsonify
from flask_cors import CORS
import os
import sys
import joblib
import numpy as np

# --- CONFIGURACIÓN DE PATHS CORREGIDA ---
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(BASE_DIR)

# Buscamos 'modelo_ia' dentro de 'backend_api'
MODEL_PATH = os.path.join(BASE_DIR, 'modelo_ia', 'knn_eduplay_model.pkl')

print(f"🔍 Buscando modelo en: {MODEL_PATH}")
if os.path.exists(MODEL_PATH):
    print("✅ ¡Archivo encontrado!")
else:
    print("❌ El archivo NO está en esa ruta. Revisa el nombre.")

FRONT_STATIC = os.path.join(BASE_DIR, 'frontend_web', 'static')
FRONT_TEMPLATES = os.path.join(BASE_DIR, 'frontend_web', 'templates')

# --- INICIALIZACIÓN ---
app = Flask(__name__, static_folder=FRONT_STATIC, template_folder=FRONT_TEMPLATES)
CORS(app, resources={r"/api/*": {"origins": "*"}})

# Importamos la base de datos y Blueprints
from database import init_db
from routes.padres import padres_bp
from routes.usuarios import usuarios_bp
from routes.actividades import actividades_bp
from routes.juego import rutas_juego  

app.register_blueprint(padres_bp, url_prefix='/api')
app.register_blueprint(usuarios_bp, url_prefix='/api')
app.register_blueprint(actividades_bp, url_prefix='/api')
app.register_blueprint(rutas_juego, url_prefix='/api/juegos')

# --- CARGA DEL MODELO IA ---
try:
    modelo_knn = joblib.load(MODEL_PATH)
    print("✅ Cerebro IA cargado y listo.")
except Exception as e:
    print(f"⚠️ Error al cargar el modelo KNN: {e}")
    modelo_knn = None

# --- RUTA DE PREDICCIÓN ACTUALIZADA ---
@app.route('/api/predict', methods=['POST'])
def predict_knn():
    if modelo_knn is None:
        return jsonify({'error': 'Modelo no cargado en el servidor'}), 500
        
    try:
        data = request.json
        
        # 1. Extraer SOLAMENTE las 8 calificaciones
        features = [
            int(data.get('memoria', 0)),
            int(data.get('matematicas', 0)),
            int(data.get('gramatica', 0)),
            int(data.get('ingles', 0)),
            int(data.get('geografia', 0)),
            int(data.get('arte', 0)),
            int(data.get('ciencia', 0)),
            int(data.get('logica', 0))
        ]
        
        input_data = np.array(features).reshape(1, -1)
        
        # 2. Hacer las predicciones y obtener probabilidades
        prediccion_num = int(modelo_knn.predict(input_data)[0])
        probabilidades = modelo_knn.predict_proba(input_data)[0]
        
        # 3. Calcular el promedio
        promedio = sum(features) / len(features)
        
        # 4. Mapeo de datos (Etiquetas, Emojis y Recomendaciones)
        etiquetas = {1: "Crítico", 2: "En Desarrollo", 3: "Básico", 4: "Competente", 5: "Excelente"}
        emojis = {1: "🔴", 2: "🟠", 3: "🟡", 4: "🟢", 5: "🏆"}
        consejos = {
            1: 'Requiere atención inmediata y actividades de refuerzo intensivo.',
            2: 'Necesita práctica adicional. Se recomiendan actividades guiadas.',
            3: 'Buen avance. Continuar con ejercicios de consolidación.',
            4: 'Desempeño sólido. Explorar actividades de mayor complejidad.',
            5: 'Desempeño sobresaliente. ¡Listo para nuevos desafíos avanzados!'
        }
        
        # 5. Formatear las probabilidades
        clases = modelo_knn.classes_
        prob_dict = {etiquetas[c]: round(p * 100, 2) for c, p in zip(clases, probabilidades)}
        
        # 6. Retornar TODO al Dashboard
        return jsonify({
            'rango': prediccion_num,
            'etiqueta': etiquetas.get(prediccion_num, "Desconocido"),
            'emoji': emojis.get(prediccion_num, ""),
            'promedio': round(promedio, 2),
            'recomendacion': consejos.get(prediccion_num, ""),
            'probabilidades': prob_dict
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@app.route('/')
def idx(): return render_template('index.html')

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', debug=True, port=5000)