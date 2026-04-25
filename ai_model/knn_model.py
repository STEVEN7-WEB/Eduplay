"""
EduPlay – Módulo del Modelo KNN
================================
Entrena y expone el clasificador KNN para puntuaciones de alumnos.
"""

import numpy as np
import pickle, os

AREAS = ['Memoria', 'Matematicas', 'Gramatica', 'Ingles',
         'Geografia', 'Arte', 'Ciencia', 'Logica']

RANGE_LABELS = {
    1: 'Crítico',
    2: 'En Desarrollo',
    3: 'Básico',
    4: 'Competente',
    5: 'Excelente'
}

EMOJI_RANGO = {1: '🔴', 2: '🟠', 3: '🟡', 4: '🟢', 5: '🏆'}

CONSEJOS = {
    1: 'Requiere atención inmediata. Se recomiendan actividades de refuerzo intensivo en todas las áreas.',
    2: 'Necesita práctica adicional. Se sugieren actividades guiadas y repetición de ejercicios.',
    3: 'Buen avance general. Continuar con ejercicios de consolidación para alcanzar nivel competente.',
    4: 'Desempeño sólido. Explorar actividades de mayor complejidad y profundidad.',
    5: 'Desempeño sobresaliente. ¡Listo para desafíos avanzados y actividades de enriquecimiento!'
}

MODEL_PATH = os.path.join(os.path.dirname(__file__), 'knn_model.pkl')


def _clasificar_rango(score: float) -> int:
    if score < 40:   return 1
    elif score < 60: return 2
    elif score < 75: return 3
    elif score < 90: return 4
    else:            return 5


class EduPlayKNN:
    def __init__(self):
        self.model   = None
        self.scaler  = None
        self.trained = False

    # ── Entrenamiento ─────────────────────────────────────────────────────────
    def train(self):
        """Carga modelo desde disco o entrena uno nuevo."""
        if os.path.exists(MODEL_PATH):
            with open(MODEL_PATH, 'rb') as f:
                bundle = pickle.load(f)
            self.model   = bundle['model']
            self.scaler  = bundle['scaler']
            self.trained = True
            print("✅ Modelo KNN cargado desde disco.")
            return

        self._train_new()

    def _train_new(self):
        from sklearn.neighbors import KNeighborsClassifier
        from sklearn.preprocessing import StandardScaler
        from sklearn.model_selection import GridSearchCV, StratifiedKFold

        print("🔧 Entrenando nuevo modelo KNN...")
        np.random.seed(42)
        N = 1000

        def gen(n, mu, sigma):
            return np.clip(np.random.normal(mu, sigma, n).astype(float), 0, 100)

        data_cols = {
            'Memoria'    : gen(N, 72, 18),
            'Matematicas': gen(N, 65, 20),
            'Gramatica'  : gen(N, 70, 17),
            'Ingles'     : gen(N, 60, 22),
            'Geografia'  : gen(N, 68, 19),
            'Arte'       : gen(N, 78, 15),
            'Ciencia'    : gen(N, 66, 21),
            'Logica'     : gen(N, 63, 20),
            'Edad'       : np.random.randint(6, 13, N).astype(float),
        }

        import pandas as pd
        df = pd.DataFrame(data_cols)
        df['Promedio'] = df[AREAS].mean(axis=1)
        df['Rango']    = df['Promedio'].apply(_clasificar_rango)

        FEATURES = AREAS + ['Edad']
        X = df[FEATURES].values
        y = df['Rango'].values

        scaler = StandardScaler()
        X_sc   = scaler.fit_transform(X)

        param_grid = {
            'n_neighbors': list(range(3, 16)),
            'weights'    : ['uniform', 'distance'],
            'metric'     : ['euclidean', 'manhattan'],
        }
        gs = GridSearchCV(
            KNeighborsClassifier(), param_grid,
            cv=StratifiedKFold(n_splits=10, shuffle=True, random_state=42),
            scoring='accuracy', n_jobs=-1
        )
        gs.fit(X_sc, y)

        self.model   = gs.best_estimator_
        self.scaler  = scaler
        self.trained = True

        with open(MODEL_PATH, 'wb') as f:
            pickle.dump({'model': self.model, 'scaler': self.scaler}, f)

        print(f"✅ Modelo entrenado. K={gs.best_params_['n_neighbors']} | "
              f"Acc={gs.best_score_:.4f}")

    # ── Predicción ────────────────────────────────────────────────────────────
    def clasificar(self, promedios: dict, edad: int = 9) -> dict:
        """
        Clasifica un alumno.

        Parámetros
        ----------
        promedios : dict  Ej: {'Memoria': 75, 'Matematicas': 60, ...}
        edad      : int   Edad del alumno

        Retorna
        -------
        dict con rango, etiqueta, probabilidades, recomendacion
        """
        if not self.trained:
            self.train()

        # Construir vector de features
        vec = np.array(
            [float(promedios.get(a, 50)) for a in AREAS] + [float(edad)],
            dtype=float
        ).reshape(1, -1)

        vec_sc     = self.scaler.transform(vec)
        pred_rango = int(self.model.predict(vec_sc)[0])
        pred_proba = self.model.predict_proba(vec_sc)[0]
        clases     = self.model.classes_

        probas = {RANGE_LABELS[int(c)]: round(float(p), 4)
                  for c, p in zip(clases, pred_proba)}

        promedio_total = round(float(np.mean([promedios.get(a, 50) for a in AREAS])), 2)

        return {
            'rango'             : pred_rango,
            'etiqueta'          : RANGE_LABELS[pred_rango],
            'emoji'             : EMOJI_RANGO[pred_rango],
            'puntuacion_promedio': promedio_total,
            'probabilidades'    : probas,
            'recomendacion'     : CONSEJOS[pred_rango],
            'areas'             : {a: round(float(promedios.get(a, 50)), 2) for a in AREAS}
        }
