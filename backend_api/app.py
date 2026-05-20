from flask import Flask, send_from_directory, render_template, request, jsonify
from flask_cors import CORS
import os
import sys
import joblib
import numpy as np

# --- CONFIGURACIÓN DE PATHS CORREGIDA ---
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(BASE_DIR)

# IMPORTANTE: Asegúrate de que estos dos archivos existan en esta ruta.
# Si los archivos .pkl se guardaron en la raíz de backend_api, usa estas rutas:
MODEL_PATH = os.path.join(BASE_DIR, 'modelo_knn.pkl')
SCALER_PATH = os.path.join(BASE_DIR, 'scaler_eduplay.pkl')

print(f"🔍 Buscando modelo en: {MODEL_PATH}")
if os.path.exists(MODEL_PATH) and os.path.exists(SCALER_PATH):
    print("✅ ¡Archivos del modelo y scaler encontrados!")
else:
    print("❌ ADVERTENCIA: Faltan archivos .pkl en la ruta. Revisa los nombres y ubicación.")

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

# --- CARGA DEL MODELO IA Y SCALER ---
try:
    modelo_knn = joblib.load(MODEL_PATH)
    scaler = joblib.load(SCALER_PATH)
    print("✅ Cerebro IA y Traductor (Scaler) cargados y listos.")
except Exception as e:
    print(f"⚠️ Error al cargar la IA: {e}")
    modelo_knn = None
    scaler = None

# --- RUTA DE PREDICCIÓN ACTUALIZADA Y CALIBRADA ---
@app.route('/api/predict', methods=['POST'])
def predict_knn():
    if modelo_knn is None or scaler is None:
        return jsonify({'error': 'Modelo o Scaler no cargados en el servidor'}), 500
        
    try:
        data = request.json
        
        # 1. Extraer SOLAMENTE las 8 calificaciones enviadas por Flutter
        features = [
            float(data.get('memoria', 0)),
            float(data.get('matematicas', 0)),
            float(data.get('gramatica', 0)),
            float(data.get('ingles', 0)),
            float(data.get('geografia', 0)),
            float(data.get('arte', 0)),
            float(data.get('ciencia', 0)),
            float(data.get('logica', 0))
        ]
        
        # Convertimos la lista a un arreglo de numpy para scikit-learn
        input_data = np.array(features).reshape(1, -1)
        
        # 2. ESCALAMOS LOS DATOS (¡El paso crucial para la precisión!)
        features_scaled = scaler.transform(input_data)
        
        # 3. Hacer las predicciones y obtener probabilidades con los datos escalados
        prediccion_num = int(modelo_knn.predict(features_scaled)[0])
        probabilidades = modelo_knn.predict_proba(features_scaled)[0]
        
        # 4. Calcular el promedio original
        promedio = sum(features) / len(features)
        
        # 5. Mapeo de datos (Etiquetas, Emojis y Recomendaciones)
        etiquetas = {1: "Crítico", 2: "En Desarrollo", 3: "Básico", 4: "Competente", 5: "Excelente"}
        emojis = {1: "🔴", 2: "🟠", 3: "🟡", 4: "🟢", 5: "🏆"}
        consejos = {
            1: 'Requiere atención inmediata y actividades de refuerzo intensivo.',
            2: 'Necesita práctica adicional. Se recomiendan actividades guiadas.',
            3: 'Buen avance. Continuar con ejercicios de consolidación.',
            4: 'Desempeño sólido. Explorar actividades de mayor complejidad.',
            5: 'Desempeño sobresaliente. ¡Listo para nuevos desafíos avanzados!'
        }
        
        # 6. Formatear las probabilidades para que encajen con los nombres
        clases = modelo_knn.classes_
        prob_dict = {etiquetas[c]: round(float(p) * 100, 2) for c, p in zip(clases, probabilidades)}
        
        # 7. Retornar TODO a Flutter
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