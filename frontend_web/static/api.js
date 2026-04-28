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

function mostrarLogin(rol) {
    document.getElementById('roleSelector').style.display = 'none';
    const authContainer = document.getElementById('authContainer');
    const backBtn = document.getElementById('backToRoles');
    
    authContainer.style.display = 'block';
    if(backBtn) backBtn.style.display = 'inline-block';

if (rol === 'admin') {
    authContainer.innerHTML = `
        <div class="ep-box" style="text-align: center; max-width: 320px; margin: 0 auto; border-top: 5px solid #2C3E50;">
            <h3 style="color: #2C3E50; margin-bottom: 20px; font-size: 22px;">👨‍🏫 Acceso Profesores</h3>
            
            <div style="text-align: left; margin-bottom: 15px;">
                <label style="font-size: 14px; font-weight: bold; color: #7F8C8D;">Correo Electrónico</label>
                <input type="email" id="admEmail" placeholder="profe@escuela.com" 
                    style="width: 100%; padding: 12px; margin-top: 5px; border-radius: 10px; border: 2px solid #BDC3C7; font-size: 15px; box-sizing: border-box; transition: border-color 0.3s;">
            </div>
            
            <div style="text-align: left; margin-bottom: 25px;">
                <label style="font-size: 14px; font-weight: bold; color: #7F8C8D;">Contraseña</label>
                <input type="password" id="admPass" placeholder="••••••••" 
                    style="width: 100%; padding: 12px; margin-top: 5px; border-radius: 10px; border: 2px solid #BDC3C7; font-size: 15px; box-sizing: border-box; transition: border-color 0.3s;">
            </div>
            
            <button onclick="loginAdmin()" class="ep-btn juicy-btn" style="background: #2980B9; color: white; width: 100%;">
                Entrar al Panel
            </button>
            
            <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
            
            <p style="font-size: 13px; color: #7F8C8D; margin-bottom: 10px;">¿Eres nuevo maestro?</p>
            <button onclick="mostrarRegistroAdmin()" class="ep-btn" style="background: white; color: #27AE60; border: 2px solid #27AE60; border-radius: 50px; padding: 8px 20px; font-weight: bold; cursor: pointer; transition: all 0.2s ease;">
                Crear Cuenta de Profesor
            </button>
        </div>
    `;
} else {
        // === NUEVO TECLADO PARA ESTUDIANTES ===
        authContainer.innerHTML = `
            <div class="ep-box" style="text-align: center; max-width: 300px; margin: 0 auto;">
                <h3 style="color: #2F80ED; margin-bottom: 15px;">¡Hola! ¿Quién eres?</h3>
                
                <input type="text" id="nombreEstudiante" placeholder="Escribe tu nombre" 
                    style="width: 90%; padding: 12px; font-size: 16px; border: 2px solid #2F80ED; border-radius: 10px; margin-bottom: 15px; text-align: center; font-weight: bold;">
                
                <div id="pinDisplay" style="font-size: 28px; letter-spacing: 8px; margin-bottom: 15px; height: 35px; color: #F2994A;"></div>
                
                <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; padding: 10px;">
                    <button onclick="tecladoPin('1')" class="ep-btn" style="background: #f0f0f0; color: #333; font-size: 20px; padding: 15px;">1</button>
                    <button onclick="tecladoPin('2')" class="ep-btn" style="background: #f0f0f0; color: #333; font-size: 20px; padding: 15px;">2</button>
                    <button onclick="tecladoPin('3')" class="ep-btn" style="background: #f0f0f0; color: #333; font-size: 20px; padding: 15px;">3</button>
                    <button onclick="tecladoPin('4')" class="ep-btn" style="background: #f0f0f0; color: #333; font-size: 20px; padding: 15px;">4</button>
                    <button onclick="tecladoPin('5')" class="ep-btn" style="background: #f0f0f0; color: #333; font-size: 20px; padding: 15px;">5</button>
                    <button onclick="tecladoPin('6')" class="ep-btn" style="background: #f0f0f0; color: #333; font-size: 20px; padding: 15px;">6</button>
                    <button onclick="tecladoPin('7')" class="ep-btn" style="background: #f0f0f0; color: #333; font-size: 20px; padding: 15px;">7</button>
                    <button onclick="tecladoPin('8')" class="ep-btn" style="background: #f0f0f0; color: #333; font-size: 20px; padding: 15px;">8</button>
                    <button onclick="tecladoPin('9')" class="ep-btn" style="background: #f0f0f0; color: #333; font-size: 20px; padding: 15px;">9</button>
                    <button onclick="borrarPin()" class="ep-btn" style="background: #FF6B6B; font-size: 20px; padding: 15px;">❌</button>
                    <button onclick="tecladoPin('0')" class="ep-btn" style="background: #f0f0f0; color: #333; font-size: 20px; padding: 15px;">0</button>
                    <button onclick="entrarEstudiante()" class="ep-btn" style="background: #27AE60; font-size: 20px; padding: 15px;">✔️</button>
                </div>
            </div>`;
            
        // Reiniciamos el PIN visual al abrir
        pinActual = ""; 
    }
}

let pinActual = "";

// Función para cuando el niño presiona un número
function tecladoPin(numero) {
    if (pinActual.length < 4) { // Suponiendo que el PIN es de 4 dígitos
        pinActual += numero;
        // Mostramos estrellas en lugar de los números para que sea secreto
        document.getElementById('pinDisplay').textContent = "⭐".repeat(pinActual.length);
    }
}

// Función para el botón rojo (borrar)
function borrarPin() {
    pinActual = "";
    document.getElementById('pinDisplay').textContent = "";
}

// Función para el botón verde (Entrar)
function entrarEstudiante() {
    const nombre = document.getElementById('nombreEstudiante').value.trim();
    
    // Validaciones básicas
    if (!nombre) {
        alert("¡No olvides escribir tu nombre!");
        return;
    }
    if (pinActual.length === 0) {
        alert("¡Usa el teclado para escribir tu PIN secreto!");
        return;
    }

    // 1. Buscamos al estudiante por su nombre en la base de datos
    fetch('/api/lista')
        .then(res => res.json())
        .then(estudiantes => {
            // Buscamos ignorando mayúsculas y minúsculas
            const estudianteEncontrado = estudiantes.find(est => est.nombre.toLowerCase() === nombre.toLowerCase());

            if (!estudianteEncontrado) {
                alert("Mmm... no encontré a ningún estudiante con ese nombre. ¡Revisa que esté bien escrito!");
                borrarPin();
                return;
            }

            // 2. Si lo encontramos, enviamos su PIN al servidor usando su ID
 // 2. Si lo encontramos, enviamos su PIN al servidor usando su ID
        fetch(`/api/usuarios/${estudianteEncontrado.id}/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ pin: pinActual })
        })
        .then(response => response.json())
        .then(data => {
            if (data.ok) {
                // ¡Éxito! 
                
                // === GUARDADO DE SESIÓN EN MEMORIA PERSISTENTE ===
                // Guardamos los datos para que el juego sepa quién eres
                localStorage.setItem('userId', estudianteEncontrado.id);
                localStorage.setItem('userName', estudianteEncontrado.nombre);
                
                // Guardamos el grado (usando grade o grado_escolar según tu tabla)
                const grado = estudianteEncontrado.grade || estudianteEncontrado.grado_escolar || 1;
                localStorage.setItem('userGrade', grado);
                
                // Variable global de respaldo
                window.usuarioActualId = estudianteEncontrado.id;
                console.log("✅ Sesión activa para:", estudianteEncontrado.nombre, "(ID:", estudianteEncontrado.id, ")");
                // ================================================

                selectUser(estudianteEncontrado.id);
                closeWelcomeScreen();
            } else {
                alert("Ese PIN no es correcto. ¡Inténtalo de nuevo!");
                borrarPin(); // Limpiamos el teclado para que intente otra vez
            }
        })
        .catch(error => {
            console.error("Error validando el PIN:", error);
            alert("Hubo un error al validar el PIN.");
        });
    })
    .catch(error => {
        console.error("Error conectando con el servidor:", error);
        alert("Error de conexión. ¿El servidor está encendido?");
    });
}
function mostrarRegistroAdmin() {
    const authContainer = document.getElementById('authContainer');
    authContainer.innerHTML = `
        <div class="ep-box" style="text-align: center; max-width: 320px; margin: 0 auto; border-top: 5px solid #27AE60;">
            <h3 style="color: #27AE60; margin-bottom: 20px; font-size: 22px;">✨ Nuevo Profesor</h3>
            
            <input type="text" id="regAdmNombre" placeholder="Tu Nombre Completo" 
                style="width: 100%; padding: 12px; margin-bottom: 15px; border-radius: 10px; border: 2px solid #27AE60; font-size: 15px; box-sizing: border-box; text-align: center;">
            
            <input type="email" id="regAdmEmail" placeholder="Tu Correo" 
                style="width: 100%; padding: 12px; margin-bottom: 15px; border-radius: 10px; border: 2px solid #27AE60; font-size: 15px; box-sizing: border-box; text-align: center;">
            
            <input type="password" id="regAdmPass" placeholder="Crea una Contraseña" 
                style="width: 100%; padding: 12px; margin-bottom: 20px; border-radius: 10px; border: 2px solid #27AE60; font-size: 15px; box-sizing: border-box; text-align: center;">
            
            <button onclick="registrarAdminBackend()" class="ep-btn juicy-btn" style="background: #27AE60; color: white; width: 100%; margin-bottom: 15px;">
                Registrar y Entrar
            </button>
            
            <button onclick="mostrarLogin('admin')" style="background: transparent; color: #7F8C8D; border: none; text-decoration: underline; cursor: pointer; font-size: 14px;">
                ← Volver al Login
            </button>
        </div>
    `;
}

function loginAdmin() {
    const email = document.getElementById('admEmail').value.trim();
    const password = document.getElementById('admPass').value.trim();

    if(!email || !password) {
        mostrarAlertaMagica("Por favor ingresa tu correo y contraseña.", "⚠️", "#F39C12");
        return;
    }

    // Tu backend espera esto en la ruta /api/usuarios/login
    fetch('/api/usuarios/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: email, password: password })
    })
    .then(res => res.json())
    .then(data => {
        if(data.ok) {
            mostrarAlertaMagica("¡Bienvenido Maestro!", "👨‍🏫", "#2980B9");
            
            // Redirigimos al panel después de 1 segundo para que vea el mensaje
            setTimeout(() => {
                window.location.href = '/admin';
            }, 1000);
            
        } else {
            mostrarAlertaMagica(data.error || "Datos incorrectos.", "❌", "#E74C3C");
        }
    })
    .catch(e => mostrarAlertaMagica("Error de conexión con el servidor.", "🔌", "#FF6B6B"));
}

function registrarAdminBackend() {
    const nombre = document.getElementById('regAdmNombre').value.trim();
    const email = document.getElementById('regAdmEmail').value.trim();
    const password = document.getElementById('regAdmPass').value.trim();

    if(!nombre || !email || !password) {
        mostrarAlertaMagica("Llena todos los campos para registrarte.", "⚠️", "#F39C12");
        return;
    }

    // Tu backend espera esto en la ruta /api/admin/registro
    fetch('/api/admin/registro', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ nombre: nombre, email: email, password: password })
    })
    .then(res => res.json())
    .then(data => {
        if(data.ok) {
            mostrarAlertaMagica("¡Cuenta creada! Inicia sesión para continuar.", "✨", "#27AE60");
            mostrarLogin('admin');
        } else {
            mostrarAlertaMagica(data.error || "Hubo un error al crear la cuenta.", "❌", "#E74C3C");
        }
    })
    .catch(e => mostrarAlertaMagica("Error de conexión con el servidor.", "🔌", "#FF6B6B"));
}

async function ejecutarRegistroAdmin() {
    const nombre = document.getElementById('regAdmNombre').value;
    const email = document.getElementById('regAdmEmail').value;
    const password = document.getElementById('regAdmPass').value;

    try {
        const res = await fetch('/api/admin/registro', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ nombre, email, password })
        });
        const data = await res.json();
        if (data.ok) {
            alert("¡Cuenta de administrador creada exitosamente!");
            localStorage.setItem('admin_token', data.session_token);
            window.location.href = "/admin_dashboard.html";
        } else {
            alert("Error: " + data.error);
        }
    } catch (e) {
        console.error(e);
    }
}
function toggleDarkMode() {
    const body = document.documentElement;
    const btn = document.getElementById('theme-toggle');
    
    // Cambiamos el atributo data-theme
    if (body.getAttribute('data-theme') === 'dark') {
        body.removeAttribute('data-theme');
        btn.innerText = '🌙';
        localStorage.setItem('theme', 'light');
    } else {
        body.setAttribute('data-theme', 'dark');
        btn.innerText = '☀️';
        localStorage.setItem('theme', 'dark');
    }
}

// Al cargar la página, verificamos si ya tenía el modo oscuro activado
window.addEventListener('DOMContentLoaded', () => {
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme === 'dark') {
        document.documentElement.setAttribute('data-theme', 'dark');
        document.getElementById('theme-toggle').innerText = '☀️';
    }
});
function volverARoles() {
    document.getElementById('roleSelector').style.display = 'flex';
    document.getElementById('authContainer').style.display = 'none';
    document.getElementById('backToRoles').style.display = 'none';
}