/**
 * EduPlay – API Client
 * ====================
 * Reemplaza localStorage por llamadas reales al backend Flask.
 * Todas las funciones son async/await.
 */

const API_BASE = 'http://localhost:5000/api';

// ─── Utilidades ──────────────────────────────────────────────────────────────
async function apiCall(endpoint, method = 'GET', body = null) {
    const opts = {
        method,
        headers: { 'Content-Type': 'application/json' }
    };
    if (body) opts.body = JSON.stringify(body);

    try {
        const res  = await fetch(`${API_BASE}${endpoint}`, opts);
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || `HTTP ${res.status}`);
        return data;
    } catch (err) {
        console.error(`[EduPlay API] ${method} ${endpoint}:`, err.message);
        throw err;
    }
}

// ═══════════════════════════════════════════════════════════════════════════
//  USUARIOS
// ═══════════════════════════════════════════════════════════════════════════

/** Obtiene todos los usuarios */
async function apiGetUsuarios() {
    return apiCall('/usuarios');
}

/** Crea un usuario nuevo */
async function apiCrearUsuario(nombre, edad, avatar) {
    return apiCall('/usuarios', 'POST', { nombre, edad, avatar });
}

/** Actualiza campos del usuario (estrellas, tiempo_juego, etc.) */
async function apiActualizarUsuario(uid, campos) {
    return apiCall(`/usuarios/${uid}`, 'PUT', campos);
}

/** Elimina un usuario y todos sus datos */
async function apiEliminarUsuario(uid) {
    return apiCall(`/usuarios/${uid}`, 'DELETE');
}

// ═══════════════════════════════════════════════════════════════════════════
//  PUNTUACIONES
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Registra la puntuación de un juego.
 * @param {number} uid     - ID del usuario
 * @param {string} area    - Nombre del área (math, memory, etc.)
 * @param {number} score   - Puntuación 0-100
 * @param {number} correctas  - Respuestas correctas
 * @param {number} total      - Total de preguntas
 */
async function apiRegistrarPuntuacion(uid, area, score, correctas = 0, total = 0) {
    return apiCall(`/usuarios/${uid}/puntuaciones`, 'POST', {
        area,
        puntuacion: score,
        correctas,
        total
    });
}

/** Historial de puntuaciones del usuario */
async function apiGetPuntuaciones(uid) {
    return apiCall(`/usuarios/${uid}/puntuaciones`);
}

// ═══════════════════════════════════════════════════════════════════════════
//  HISTORIAL DE ACTIVIDADES
// ═══════════════════════════════════════════════════════════════════════════

async function apiRegistrarActividad(uid, actividad, tipoJuego, resultado = 'completado', estrellas = 0, tiempoJugado = 0) {
    return apiCall(`/usuarios/${uid}/historial`, 'POST', {
        actividad,
        tipo_juego    : tipoJuego,
        resultado,
        estrellas,
        tiempo_jugado : tiempoJugado
    });
}

async function apiGetHistorial(uid) {
    return apiCall(`/usuarios/${uid}/historial`);
}

// ═══════════════════════════════════════════════════════════════════════════
//  LOGROS
// ═══════════════════════════════════════════════════════════════════════════

async function apiGetLogros(uid) {
    return apiCall(`/usuarios/${uid}/logros`);
}

async function apiGuardarLogro(uid, logroId, desbloqueado, progreso, fechaDesbloqueo = null) {
    return apiCall(`/usuarios/${uid}/logros`, 'POST', {
        logro_id         : logroId,
        desbloqueado     : desbloqueado ? 1 : 0,
        progreso,
        fecha_desbloqueo : fechaDesbloqueo
    });
}

// ═══════════════════════════════════════════════════════════════════════════
//  MODELO KNN
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Clasifica al usuario con el modelo KNN.
 * Retorna: { rango, etiqueta, emoji, puntuacion_promedio, probabilidades,
 *             recomendacion, areas }
 */
async function apiClasificarUsuario(uid) {
    return apiCall(`/usuarios/${uid}/clasificar`);
}

/** Resumen completo: usuario + promedios + última clasificación KNN */
async function apiResumenUsuario(uid) {
    return apiCall(`/usuarios/${uid}/resumen`);
}

/** Estadísticas globales de rangos en la plataforma */
async function apiEstadisticasKNN() {
    return apiCall('/knn/estadisticas');
}

// ═══════════════════════════════════════════════════════════════════════════
//  PANEL KNN – Renderiza el resultado en el informe de padres
// ═══════════════════════════════════════════════════════════════════════════

async function mostrarClasificacionKNN(uid, containerSelector) {
    const container = document.querySelector(containerSelector);
    if (!container) return;

    container.innerHTML = `<div class="knn-loading">🔄 Clasificando con IA...</div>`;

    try {
        const data = await apiClasificarUsuario(uid);
        const { rango, etiqueta, emoji, puntuacion_promedio, probabilidades, recomendacion, areas } = data;

        const colores = {
            'Crítico'      : '#E74C3C',
            'En Desarrollo': '#E67E22',
            'Básico'       : '#F1C40F',
            'Competente'   : '#2ECC71',
            'Excelente'    : '#3498DB'
        };

        const barrasProb = Object.entries(probabilidades).map(([label, prob]) => `
            <div class="knn-prob-row">
                <span class="knn-prob-label">${label}</span>
                <div class="knn-prob-bar-bg">
                    <div class="knn-prob-bar-fill"
                         style="width:${(prob*100).toFixed(1)}%;background:${colores[label] || '#888'}">
                    </div>
                </div>
                <span class="knn-prob-val">${(prob*100).toFixed(1)}%</span>
            </div>`).join('');

        const barrasAreas = Object.entries(areas).map(([area, val]) => {
            const pct = Math.min(100, val);
            const color = val >= 90 ? '#3498DB' : val >= 75 ? '#2ECC71' :
                          val >= 60 ? '#F1C40F' : val >= 40 ? '#E67E22' : '#E74C3C';
            return `
            <div class="knn-area-row">
                <span class="knn-area-name">${area}</span>
                <div class="knn-prob-bar-bg">
                    <div class="knn-prob-bar-fill" style="width:${pct}%;background:${color}"></div>
                </div>
                <span class="knn-prob-val">${val}</span>
            </div>`;
        }).join('');

        container.innerHTML = `
        <div class="knn-result-card">
            <div class="knn-header" style="border-left:5px solid ${colores[etiqueta] || '#888'}">
                <div class="knn-emoji">${emoji}</div>
                <div class="knn-info">
                    <div class="knn-rango" style="color:${colores[etiqueta]}">${etiqueta}</div>
                    <div class="knn-promedio">Promedio: <strong>${puntuacion_promedio}</strong> / 100</div>
                </div>
            </div>

            <div class="knn-recomendacion">
                <span>💡</span> ${recomendacion}
            </div>

            <h4 class="knn-section-title">📊 Puntuaciones por Área</h4>
            <div class="knn-areas">${barrasAreas}</div>

            <h4 class="knn-section-title">🤖 Probabilidades KNN</h4>
            <div class="knn-probs">${barrasProb}</div>
        </div>`;

    } catch (err) {
        container.innerHTML = `<p class="knn-error">⚠️ No se pudo obtener la clasificación. ¿Está el servidor corriendo?</p>`;
    }
}

// ─── Exportar al scope global ─────────────────────────────────────────────
window.EduPlayAPI = {
    getUsuarios        : apiGetUsuarios,
    crearUsuario       : apiCrearUsuario,
    actualizarUsuario  : apiActualizarUsuario,
    eliminarUsuario    : apiEliminarUsuario,
    registrarPuntuacion: apiRegistrarPuntuacion,
    getPuntuaciones    : apiGetPuntuaciones,
    registrarActividad : apiRegistrarActividad,
    getHistorial       : apiGetHistorial,
    getLogros          : apiGetLogros,
    guardarLogro       : apiGuardarLogro,
    clasificarUsuario  : apiClasificarUsuario,
    resumenUsuario     : apiResumenUsuario,
    estadisticasKNN    : apiEstadisticasKNN,
    mostrarKNN         : mostrarClasificacionKNN
};
