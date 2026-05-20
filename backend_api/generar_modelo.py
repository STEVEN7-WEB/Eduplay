import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.neighbors import KNeighborsClassifier
from sklearn.metrics import accuracy_score
import joblib

# ==========================================
# 1. GENERACIÓN DE DATOS REALISTAS
# ==========================================
print("⏳ 1. Generando dataset realista...")
np.random.seed(42)
N = 10000
AREAS = ['Memoria', 'Matematicas', 'Gramatica', 'Ingles', 'Geografia', 'Arte', 'Ciencia', 'Logica']

# Generamos un nivel base aleatorio para cada alumno para garantizar que haya casos Críticos y Excelentes
nivel_base_alumnos = np.random.uniform(5, 95, N)

def gen_scores_realistas(nivel_base, varianza):
    return np.clip(np.random.normal(nivel_base, varianza), 0, 100).astype(int)

data = {
    'ID_Alumno': [f'ALU{str(i+1).zfill(4)}' for i in range(N)],
    'Memoria': gen_scores_realistas(nivel_base_alumnos, 10),
    'Matematicas': gen_scores_realistas(nivel_base_alumnos, 15),
    'Gramatica': gen_scores_realistas(nivel_base_alumnos, 12),
    'Ingles': gen_scores_realistas(nivel_base_alumnos, 18),
    'Geografia': gen_scores_realistas(nivel_base_alumnos, 10),
    'Arte': gen_scores_realistas(nivel_base_alumnos, 15),
    'Ciencia': gen_scores_realistas(nivel_base_alumnos, 12),
    'Logica': gen_scores_realistas(nivel_base_alumnos, 14),
}

df = pd.DataFrame(data)
df['Puntuacion_Promedio'] = df[AREAS].mean(axis=1).round(2)

def clasificar_rango(score):
    if score < 40:   return 1 # Crítico
    elif score < 60: return 2 # En Desarrollo
    elif score < 75: return 3 # Básico
    elif score < 90: return 4 # Competente
    else:            return 5 # Excelente

df['Rango'] = df['Puntuacion_Promedio'].apply(clasificar_rango)
df.to_csv('EduPlay_Dataset.csv', index=False)
print("✅ Dataset guardado como 'EduPlay_Dataset.csv'")

# ==========================================
# 2. PREPROCESAMIENTO Y ESCALADO
# ==========================================
print("\n⏳ 2. Preprocesando datos...")
X = df[AREAS]
y = df['Rango']

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.20, random_state=42)

# Normalizamos los datos y GUARDAMOS EL SCALER
scaler = StandardScaler()
X_train_sc = scaler.fit_transform(X_train)
X_test_sc  = scaler.transform(X_test)

joblib.dump(scaler, 'scaler_eduplay.pkl')
print("✅ Scaler exportado como 'scaler_eduplay.pkl'")

# ==========================================
# 3. ENTRENAMIENTO DEL MODELO KNN
# ==========================================
print("\n⏳ 3. Entrenando IA (KNN)...")
# Ajustamos K=5 y weights='distance' para máxima precisión
knn = KNeighborsClassifier(n_neighbors=5, metric='minkowski', p=2, weights='distance')
knn.fit(X_train_sc, y_train)

y_pred = knn.predict(X_test_sc)
acc = accuracy_score(y_test, y_pred)

# GUARDAMOS EL MODELO
joblib.dump(knn, 'modelo_knn.pkl')
print("✅ Modelo exportado como 'modelo_knn.pkl'")

print("\n" + "="*50)
print("🎯 RESUMEN DEL MODELO")
print("="*50)
print(f"Precisión (Accuracy): {acc*100:.2f}%")
print("El modelo de IA ahora está perfectamente calibrado para EduPlay 2.0")