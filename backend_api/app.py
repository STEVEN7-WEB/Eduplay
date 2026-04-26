from flask import Flask, send_from_directory
from flask_cors import CORS
import os

# Importamos la inicialización de la base de datos
from database import init_db

# Importamos los Blueprints (las rutas que moveremos a la carpeta routes)
# Nota: Estos nombres deben coincidir con los que definas dentro de cada archivo en /routes
from routes.padres import padres_bp
from routes.usuarios import usuarios_bp
from routes.actividades import actividades_bp

# Configuración de rutas estáticas (manteniendo tu lógica original)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRONT = os.path.join(BASE_DIR, 'frontend_web', 'static')

app = Flask(__name__, static_folder=FRONT, static_url_path='')
CORS(app, resources={r"/api/*": {"origins": "*"}})

# --- REGISTRO DE BLUEPRINTS ---
# Esto conecta las rutas de tus nuevos archivos con la aplicación principal
app.register_blueprint(padres_bp, url_prefix='/api')
app.register_blueprint(usuarios_bp, url_prefix='/api')
app.register_blueprint(actividades_bp, url_prefix='/api')

# --- RUTAS PARA EL FRONTEND ---
@app.route('/')
def idx(): 
    return send_from_directory(FRONT, 'index.html')

@app.route('/<path:p>')
def sta(p): 
    return send_from_directory(FRONT, p)

# --- ARRANQUE DEL SERVIDOR ---
if __name__ == '__main__':
    # Aseguramos que la carpeta estática exista
    os.makedirs(FRONT, exist_ok=True)
    
    # Inicializamos la base de datos (tablas y migraciones)
    init_db()
    
    print("🚀 EduPlay v5 Refactorizado → http://localhost:5000")
    app.run(debug=True, port=5000)