from flask import Flask, send_from_directory, render_template
from flask_cors import CORS
import os
import sys

# --- CONFIGURACIÓN DE PATHS ---
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(BASE_DIR)

FRONT_STATIC = os.path.join(BASE_DIR, 'frontend_web', 'static')
FRONT_TEMPLATES = os.path.join(BASE_DIR, 'frontend_web', 'templates')

# --- INICIALIZACIÓN DE FLASK ---
app = Flask(__name__, static_folder=FRONT_STATIC, template_folder=FRONT_TEMPLATES)

# Configuración de CORS
CORS(app, resources={r"/api/*": {"origins": "*"}})

# Importamos la base de datos y Blueprints
from database import init_db
from routes.padres import padres_bp
from routes.usuarios import usuarios_bp
from routes.actividades import actividades_bp
from routes.juego import rutas_juego  

# --- REGISTRO DE BLUEPRINTS ---
app.register_blueprint(padres_bp, url_prefix='/api')
app.register_blueprint(usuarios_bp, url_prefix='/api/usuarios/')
app.register_blueprint(actividades_bp, url_prefix='/api')
app.register_blueprint(rutas_juego, url_prefix='/api/juegos') # ¡Agregamos /juegos aquí!

# --- RUTAS PARA EL FRONTEND ---
@app.route('/')
def idx(): 
    # Flask unirá todos los pedacitos de HTML aquí
    return render_template('index.html')

@app.route('/admin')
def panel_admin(): 
    return render_template('admin.html')

@app.route('/<path:p>')
def sta(p): 
    # Seguimos enviando el CSS y JS desde la carpeta static
    return send_from_directory(FRONT_STATIC, p)

# --- ARRANQUE DEL SERVIDOR ---
if __name__ == '__main__':
    os.makedirs(FRONT_STATIC, exist_ok=True)
    os.makedirs(FRONT_TEMPLATES, exist_ok=True)
    
    init_db()
    
    print("🚀 Servidor EduPlay v5 Iniciado → http://localhost:5000")
    app.run(debug=True, port=5000)