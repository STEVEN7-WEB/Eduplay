import pandas as pd
from sklearn.neighbors import KNeighborsClassifier
import joblib
import os

print("🔍 Cargando dataset...")
df = pd.read_csv('EduPlay_Dataset.csv')

X = df[['Memoria', 'Matematicas', 'Gramatica', 'Ingles', 'Geografia', 'Arte', 'Ciencia', 'Logica']]
y = df['Rango']

print("🧠 Entrenando la Inteligencia Artificial...")
knn = KNeighborsClassifier(n_neighbors=5, weights='distance', metric='manhattan')
knn.fit(X, y)

print("📁 Creando carpeta modelo_ia...")
os.makedirs('modelo_ia', exist_ok=True)

print("💾 Guardando el cerebro de la IA...")
joblib.dump(knn, 'modelo_ia/knn_eduplay_model.pkl')

print("✅ ¡Éxito total! El archivo .pkl ya está listo.")