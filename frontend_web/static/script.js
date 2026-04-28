// ========== SISTEMA DE LOGROS ==========
const achievementsList = [
    { id: 'first_star', name: 'Primera Estrella', description: 'Gana tu primera estrella', icon: '⭐', requirement: { type: 'stars', value: 1 }, color: '#FFD24C' },
    { id: 'star_collector_10', name: 'Coleccionista de Estrellas', description: 'Consigue 10 estrellas', icon: '⭐⭐', requirement: { type: 'stars', value: 10 }, color: '#FFB347' },
    { id: 'star_master_25', name: 'Maestro de Estrellas', description: 'Consigue 25 estrellas', icon: '⭐⭐⭐', requirement: { type: 'stars', value: 25 }, color: '#FF8C42' },
    { id: 'time_explorer_15', name: 'Explorador del Tiempo', description: 'Juega 15 minutos', icon: '⏱️', requirement: { type: 'playTime', value: 15 }, color: '#2F80ED' },
    { id: 'time_master_60', name: 'Maestro del Tiempo', description: 'Juega 60 minutos', icon: '⏰', requirement: { type: 'playTime', value: 60 }, color: '#1A5FC1' },
    { id: 'math_whiz', name: 'Genio Matemático', description: 'Completa 5 juegos de matemáticas', icon: '🔢', requirement: { type: 'activity', value: { activity: 'math', count: 5 } }, color: '#27AE60' },
    { id: 'memory_champion', name: 'Campeón de Memoria', description: 'Completa 5 juegos de memoria', icon: '🧠', requirement: { type: 'activity', value: { activity: 'memory', count: 5 } }, color: '#9B51E0' },
    { id: 'language_expert', name: 'Experto en Idiomas', description: 'Completa juegos de gramática e inglés', icon: '🔤', requirement: { type: 'combined', value: [{ activity: 'grammar', count: 3 }, { activity: 'english', count: 3 }] }, color: '#3498DB' },
    { id: 'science_prodigy', name: 'Niño Prodigio de la Ciencia', description: 'Completa 3 juegos de ciencia', icon: '🔬', requirement: { type: 'activity', value: { activity: 'science', count: 3 } }, color: '#E74C3C' },
    { id: 'art_artist', name: 'Pequeño Artista', description: 'Completa 3 juegos de arte', icon: '🎨', requirement: { type: 'activity', value: { activity: 'art', count: 3 } }, color: '#FF7AB6' },
    { id: 'geography_explorer', name: 'Explorador Geográfico', description: 'Completa 3 juegos de geografía', icon: '🌎', requirement: { type: 'activity', value: { activity: 'geography', count: 3 } }, color: '#2ECC71' },
    { id: 'logic_genius', name: 'Genio de la Lógica', description: 'Completa 3 juegos de lógica', icon: '🧩', requirement: { type: 'activity', value: { activity: 'logic', count: 3 } }, color: '#F39C12' },
    { id: 'all_activities', name: 'Completista Total', description: 'Prueba todas las actividades al menos una vez', icon: '🏅', requirement: { type: 'all_activities', value: 8 }, color: '#9B59B6' },
    { id: 'perfect_score', name: 'Puntuación Perfecta', description: 'Responde 10 preguntas correctamente sin errores', icon: '💯', requirement: { type: 'perfect_games', value: 10 }, color: '#E91E63' },
    { id: 'fast_learner', name: 'Aprendiz Rápido', description: 'Gana 5 estrellas en 10 minutos', icon: '⚡', requirement: { type: 'fast_stars', value: 5 }, color: '#00BCD4' }
];

// Estado de logros por usuario
let userAchievements = {};

// Contadores para requisitos especiales
let activityCounts = {
    math: 0,
    memory: 0,
    grammar: 0,
    english: 0,
    geography: 0,
    art: 0,
    science: 0,
    logic: 0
};

let perfectGamesCount = 0;
let lastStarTime = null;
let fastStarsCount = 0;

// Elementos DOM para logros
const achievementsModal = document.getElementById('achievementsModal');
const closeAchievements = document.getElementById('closeAchievements');
const closeAchievementsBtn = document.getElementById('closeAchievementsBtn');
const viewAchievementsBtn = document.getElementById('viewAchievementsBtn');
const achievementsGrid = document.getElementById('achievementsGrid');
const achievementsStats = document.getElementById('achievementsStats');
const quickAchievements = document.getElementById('quickAchievements');
const achievementUnlocked = document.getElementById('achievementUnlocked');
const unlockedTitle = document.getElementById('unlockedTitle');
const unlockedDesc = document.getElementById('unlockedDesc');
const closeUnlocked = document.getElementById('closeUnlocked');

// Cargar logros del usuario
function loadUserAchievements() {
    if (!currentUser) return;

    const saved = localStorage.getItem(`eduplay_achievements_${currentUser.id}`);
    if (saved) {
        userAchievements = JSON.parse(saved);
    } else {
        // Inicializar logros
        userAchievements = {};
        achievementsList.forEach(achievement => {
            userAchievements[achievement.id] = {
                unlocked: false,
                progress: 0,
                dateUnlocked: null
            };
        });
        saveUserAchievements();
    }

    updateQuickAchievements();
}

// Guardar logros del usuario
function saveUserAchievements() {
    if (!currentUser) return;
    localStorage.setItem(`eduplay_achievements_${currentUser.id}`, JSON.stringify(userAchievements));
}

// Actualizar logros rápidos en sidebar
function updateQuickAchievements() {
    if (!currentUser) return;
    
    // AGREGA ESTE ESCUDO:
    const quickAchievements = document.getElementById('quickAchievements');
    if (!quickAchievements) return; 

    // ... aquí sigue tu código original (const unlocked = Object.keys...)
}

// Mostrar modal de logros
function showAchievementsModal() {
    if (!currentUser) {
        alert('Primero debes seleccionar un usuario');
        return;
    }

    renderAchievementsGrid();
    achievementsModal.style.display = 'flex';
}

// Renderizar grid de logros
function renderAchievementsGrid() {
    if (!currentUser) return;

    // Calcular estadísticas
    const totalAchievements = achievementsList.length;
    const unlockedAchievements = Object.values(userAchievements).filter(a => a.unlocked).length;
    const completionRate = totalAchievements > 0 ? Math.round((unlockedAchievements / totalAchievements) * 100) : 0;

    // Actualizar estadísticas
    achievementsStats.innerHTML = `
        <div class="stat-item">
            <div class="stat-number">${unlockedAchievements}</div>
            <div class="stat-label">Logros Desbloqueados</div>
        </div>
        <div class="stat-item">
            <div class="stat-number">${totalAchievements}</div>
            <div class="stat-label">Logros Totales</div>
        </div>
        <div class="stat-item">
            <div class="stat-number">${completionRate}%</div>
            <div class="stat-label">Completado</div>
        </div>
    `;

    // Renderizar logros
    achievementsGrid.innerHTML = '';

    achievementsList.forEach(achievement => {
        const achievementData = userAchievements[achievement.id] || { unlocked: false, progress: 0 };
        const progress = calculateAchievementProgress(achievement);

        const achievementCard = document.createElement('div');
        achievementCard.className = `achievement-card ${achievementData.unlocked ? 'unlocked' : 'locked'}`;

        let progressBar = '';
        if (!achievementData.unlocked && progress > 0) {
            progressBar = `
                <div class="achievement-progress">
                    <div class="achievement-progress-bar" style="width: ${progress}%"></div>
                </div>
                <div class="achievement-date">${progress}% completado</div>
            `;
        }

        if (achievementData.unlocked && achievementData.dateUnlocked) {
            const date = new Date(achievementData.dateUnlocked);
            progressBar += `<div class="achievement-date">Desbloqueado: ${date.toLocaleDateString()}</div>`;
        }

        achievementCard.innerHTML = `
            ${achievementData.unlocked ? '<div class="achievement-ribbon">¡LOGRO!</div>' : ''}
            <div class="achievement-icon">${achievement.icon}</div>
            <div class="achievement-name">${achievement.name}</div>
            <div class="achievement-desc">${achievement.description}</div>
            ${progressBar}
            ${achievementData.unlocked ? '<div class="achievement-badge">✓</div>' : ''}
        `;

        // Estilo para logros desbloqueados
        if (achievementData.unlocked) {
            achievementCard.style.borderColor = achievement.color;
            achievementCard.style.boxShadow = `0 5px 15px ${achievement.color}40`;
        }

        achievementsGrid.appendChild(achievementCard);
    });
}

// Calcular progreso de un logro
function calculateAchievementProgress(achievement) {
    if (!currentUser) return 0;

    const req = achievement.requirement;

    switch (req.type) {
        case 'stars':
            return Math.min((currentUser.stars / req.value) * 100, 100);

        case 'playTime':
            return Math.min((currentUser.playTime / req.value) * 100, 100);

        case 'activity':
            const count = activityCounts[req.value.activity] || 0;
            return Math.min((count / req.value.count) * 100, 100);

        case 'combined':
            let totalProgress = 0;
            req.value.forEach(item => {
                const count = activityCounts[item.activity] || 0;
                totalProgress += Math.min((count / item.count) * 100, 100);
            });
            return totalProgress / req.value.length;

        case 'all_activities':
            const activitiesTried = Object.values(activityCounts).filter(count => count > 0).length;
            return Math.min((activitiesTried / req.value) * 100, 100);

        case 'perfect_games':
            return Math.min((perfectGamesCount / req.value) * 100, 100);

        case 'fast_stars':
            return Math.min((fastStarsCount / req.value) * 100, 100);

        default:
            return 0;
    }
}

// Verificar y desbloquear logros
function checkAchievements() {
    if (!currentUser) return;

    achievementsList.forEach(achievement => {
        const achievementData = userAchievements[achievement.id];

        // Si ya está desbloqueado, no hacer nada
        if (achievementData.unlocked) return;

        const req = achievement.requirement;
        let shouldUnlock = false;

        switch (req.type) {
            case 'stars':
                shouldUnlock = currentUser.stars >= req.value;
                break;

            case 'playTime':
                shouldUnlock = currentUser.playTime >= req.value;
                break;

            case 'activity':
                shouldUnlock = (activityCounts[req.value.activity] || 0) >= req.value.count;
                break;

            case 'combined':
                shouldUnlock = req.value.every(item =>
                    (activityCounts[item.activity] || 0) >= item.count
                );
                break;

            case 'all_activities':
                const activitiesTried = Object.values(activityCounts).filter(count => count > 0).length;
                shouldUnlock = activitiesTried >= req.value;
                break;

            case 'perfect_games':
                shouldUnlock = perfectGamesCount >= req.value;
                break;

            case 'fast_stars':
                shouldUnlock = fastStarsCount >= req.value;
                break;
        }

        if (shouldUnlock) {
            unlockAchievement(achievement);
        }
    });
}

// Desbloquear un logro con animación
function unlockAchievement(achievement) {
    if (!currentUser) return;

    const achievementData = userAchievements[achievement.id];

    // Marcar como desbloqueado
    achievementData.unlocked = true;
    achievementData.dateUnlocked = new Date().toISOString();

    // Guardar cambios
    saveUserAchievements();

    // Mostrar notificación
    showAchievementUnlocked(achievement);

    // Actualizar vista rápida
    updateQuickAchievements();

    // Reproducir sonido especial
    if (audioOn) {
        playAchievementSound();
    }
}

// Mostrar notificación de logro desbloqueado
function showAchievementUnlocked(achievement) {
    unlockedTitle.textContent = achievement.name;
    unlockedDesc.textContent = achievement.description;

    // Estilo personalizado por color
    achievementUnlocked.style.background = `linear-gradient(135deg, ${achievement.color}, ${darkenColor(achievement.color, 20)})`;

    // Mostrar animación
    achievementUnlocked.style.display = 'block';

    // Crear partículas de celebración
    createAchievementParticles();

    // Auto-ocultar después de 5 segundos
    setTimeout(() => {
        if (achievementUnlocked.style.display === 'block') {
            achievementUnlocked.style.display = 'none';
        }
    }, 5000);
}

// Función para oscurecer color
function darkenColor(color, percent) {
    const num = parseInt(color.replace("#", ""), 16);
    const amt = Math.round(2.55 * percent);
    const R = (num >> 16) - amt;
    const G = (num >> 8 & 0x00FF) - amt;
    const B = (num & 0x0000FF) - amt;
    return "#" + (0x1000000 + (R < 255 ? R < 1 ? 0 : R : 255) * 0x10000 +
        (G < 255 ? G < 1 ? 0 : G : 255) * 0x100 +
        (B < 255 ? B < 1 ? 0 : B : 255)).toString(16).slice(1);
}

// Crear partículas para celebración
function createAchievementParticles() {
    const colors = ['#FFD24C', '#FF7AB6', '#2F80ED', '#27AE60', '#9B51E0'];

    for (let i = 0; i < 50; i++) {
        const particle = document.createElement('div');
        particle.className = 'achievement-particle';
        particle.style.width = `${Math.random() * 8 + 4}px`;
        particle.style.height = particle.style.width;
        particle.style.background = colors[Math.floor(Math.random() * colors.length)];
        particle.style.left = `${Math.random() * 100}%`;
        particle.style.top = `${Math.random() * 100}%`;
        particle.style.zIndex = '1007';
        document.body.appendChild(particle);

        // Animación de partícula
        const angle = Math.random() * Math.PI * 2;
        const distance = 100 + Math.random() * 100;
        const duration = 1000 + Math.random() * 1000;

        particle.animate([
            { transform: 'translate(0, 0) scale(1)', opacity: 1 },
            { transform: `translate(${Math.cos(angle) * distance}px, ${Math.sin(angle) * distance}px) scale(0)`, opacity: 0 }
        ], {
            duration: duration,
            easing: 'cubic-bezier(0.1, 0.8, 0.2, 1)'
        }).onfinish = () => particle.remove();
    }
}

// Reproducir sonido especial para logros
function playAchievementSound() {
    if (!audioOn) return;

    // Crear sonido de celebración con Web Audio API
    try {
        const audioContext = new (window.AudioContext || window.webkitAudioContext)();
        const oscillator = audioContext.createOscillator();
        const gainNode = audioContext.createGain();

        oscillator.connect(gainNode);
        gainNode.connect(audioContext.destination);

        oscillator.frequency.setValueAtTime(523.25, audioContext.currentTime); // Do
        oscillator.frequency.setValueAtTime(659.25, audioContext.currentTime + 0.1); // Mi
        oscillator.frequency.setValueAtTime(783.99, audioContext.currentTime + 0.2); // Sol

        gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.5);

        oscillator.start(audioContext.currentTime);
        oscillator.stop(audioContext.currentTime + 0.5);
    } catch (e) {
        console.log('No se pudo reproducir sonido de logro');
    }
}

// ========== PANTALLA DE BIENVENIDA ==========

// Elementos DOM para la pantalla de bienvenida
const welcomeOverlay = document.getElementById('welcomeOverlay');
const mainContainer = document.getElementById('mainContainer');
const welcomeOptions = document.getElementById('welcomeOptions');
const welcomeButtons = document.getElementById('welcomeButtons');
const startNewUserBtn = document.getElementById('startNewUserBtn');
const playAsGuestBtn = document.getElementById('playAsGuestBtn');

// Mostrar pantalla de bienvenida
// Mostrar pantalla de bienvenida (LIMPIA)
function showWelcomeScreen() {
    const welcomeOverlay = document.getElementById('welcomeOverlay');
    const mainContainer = document.getElementById('mainContainer');
    const welcomeOptions = document.getElementById('welcomeOptions');
    const roleSelector = document.getElementById('roleSelector');
    const authContainer = document.getElementById('authContainer');
    const backBtn = document.getElementById('backToRoles');

    // Mostramos el fondo del inicio y ocultamos el juego
    if (welcomeOverlay) welcomeOverlay.style.display = 'flex';
    if (mainContainer) mainContainer.style.display = 'none';
    
    // Limpiamos los perfiles o cualquier mensaje viejo
    if (welcomeOptions) welcomeOptions.innerHTML = '';
    
    // Mostramos SOLO los botones principales
    if (roleSelector) roleSelector.style.display = 'flex';
    
    // Nos aseguramos de que el teclado y el botón de "volver" estén ocultos al principio
    if (authContainer) authContainer.style.display = 'none';
    if (backBtn) backBtn.style.display = 'none';
}

// Variables globales para guardar la selección durante los pasos
let avatarSeleccionado = '';
let gradoSeleccionado = 0;
let pinRegistroActual = "";

function mostrarRegistroAlumno() {
    document.getElementById('roleSelector').style.display = 'none';
    const authContainer = document.getElementById('authContainer');
    document.getElementById('backToRoles').style.display = 'inline-block';
    
    // Reiniciamos todo al abrir
    avatarSeleccionado = '';
    gradoSeleccionado = 0;
    pinRegistroActual = "";
    
    const avatares = ['🦊', '🐶', '🐱', '🦄', '🚀', '🌟'];
    const grados = [1, 2, 3, 4, 5, 6];

    authContainer.style.display = 'block';
    
    // Creamos la estructura con 3 "pasos" ocultos
    authContainer.innerHTML = `
        <div class="ep-box" style="text-align: center; max-width: 350px; margin: 0 auto;">
            
            <div id="regStep1" style="display: block;">
                <h3 style="color: #27AE60; margin-bottom: 15px;">Paso 1: ¿Quién eres? 📝</h3>
                
                <input type="text" id="regNombre" placeholder="Tu nombre" 
                    style="width: 90%; padding: 12px; margin-bottom: 15px; border-radius: 10px; border: 2px solid #27AE60; text-align: center; font-size: 16px;">
                
                <input type="email" id="regEmail" placeholder="Email de tu tutor" 
                    style="width: 90%; padding: 12px; margin-bottom: 20px; border-radius: 10px; border: 2px solid #27AE60; text-align: center;">
                    
                <button onclick="siguientePaso(2)" class="ep-btn juicy-btn" style="background: #2F80ED; color: white;">
                    Siguiente ➡️
                </button>
            </div>

            <div id="regStep2" style="display: none;">
                <h3 style="color: #F2994A; margin-bottom: 15px;">Paso 2: Tu Personaje 🎨</h3>
                
                <p style="margin: 0 0 10px; font-weight: bold;">Elige tu Avatar:</p>
                <div id="avatarGrid" style="display: flex; gap: 5px; justify-content: center; flex-wrap: wrap; margin-bottom: 15px;">
                    ${avatares.map(a => `<div class="avatar-option" id="av-${a}" onclick="seleccionarAvatar('${a}')">${a}</div>`).join('')}
                </div>

                <p style="margin: 0 0 10px; font-weight: bold;">Tu Grado Escolar:</p>
                <div id="gradoGrid" style="display: flex; gap: 8px; justify-content: center; flex-wrap: wrap; margin-bottom: 20px;">
                    ${grados.map(g => `<div class="grado-option" id="gr-${g}" onclick="seleccionarGrado(${g})">${g}º</div>`).join('')}
                </div>
                
                <div style="display: flex; gap: 10px; justify-content: center;">
                    <button onclick="siguientePaso(1)" class="ep-btn" style="background: #95A5A6; color: white; border-radius: 50px; padding: 10px 20px;">⬅️ Atrás</button>
                    <button onclick="siguientePaso(3)" class="ep-btn juicy-btn" style="background: #2F80ED; color: white; width: auto; padding: 10px 20px;">Siguiente ➡️</button>
                </div>
            </div>

            <div id="regStep3" style="display: none;">
                <h3 style="color: #9B59B6; margin-bottom: 10px;">Paso 3: PIN Secreto 🔐</h3>
                <p style="font-size: 14px; margin-bottom: 10px;">Inventa 4 números mágicos</p>
                
                <div id="regPinDisplay" style="font-size: 28px; letter-spacing: 8px; margin-bottom: 10px; height: 35px; color: #9B59B6;"></div>
                
                <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; padding: 5px; margin-bottom: 15px;">
                    <button onclick="tecladoPinRegistro('1')" class="ep-btn" style="background: #f0f0f0; color: #333; font-size: 18px; padding: 10px;">1</button>
                    <button onclick="tecladoPinRegistro('2')" class="ep-btn" style="background: #f0f0f0; color: #333; font-size: 18px; padding: 10px;">2</button>
                    <button onclick="tecladoPinRegistro('3')" class="ep-btn" style="background: #f0f0f0; color: #333; font-size: 18px; padding: 10px;">3</button>
                    <button onclick="tecladoPinRegistro('4')" class="ep-btn" style="background: #f0f0f0; color: #333; font-size: 18px; padding: 10px;">4</button>
                    <button onclick="tecladoPinRegistro('5')" class="ep-btn" style="background: #f0f0f0; color: #333; font-size: 18px; padding: 10px;">5</button>
                    <button onclick="tecladoPinRegistro('6')" class="ep-btn" style="background: #f0f0f0; color: #333; font-size: 18px; padding: 10px;">6</button>
                    <button onclick="tecladoPinRegistro('7')" class="ep-btn" style="background: #f0f0f0; color: #333; font-size: 18px; padding: 10px;">7</button>
                    <button onclick="tecladoPinRegistro('8')" class="ep-btn" style="background: #f0f0f0; color: #333; font-size: 18px; padding: 10px;">8</button>
                    <button onclick="tecladoPinRegistro('9')" class="ep-btn" style="background: #f0f0f0; color: #333; font-size: 18px; padding: 10px;">9</button>
                    <button onclick="siguientePaso(2)" class="ep-btn" style="background: #95A5A6; color: white; font-size: 14px; padding: 10px;">⬅️</button>
                    <button onclick="tecladoPinRegistro('0')" class="ep-btn" style="background: #f0f0f0; color: #333; font-size: 18px; padding: 10px;">0</button>
                    <button onclick="borrarPinRegistro()" class="ep-btn" style="background: #FF6B6B; font-size: 18px; padding: 10px;">❌</button>
                </div>
                
                <button onclick="crearAlumnoBackend()" class="ep-btn juicy-btn" style="background: #27AE60; color: white;">
                    ¡Listo para jugar! 🚀
                </button>
            </div>

        </div>
    `;
}

function siguientePaso(pasoDestino) {
    if (pasoDestino === 2) {
        const nombre = document.getElementById('regNombre').value.trim();
        const email = document.getElementById('regEmail').value.trim();
        if (!nombre || !email) {
            // AHORA USAMOS LA ALERTA MÁGICA: Mensaje, Emoji, Color (naranja)
            mostrarAlertaMagica("¡No olvides escribir tu nombre y el correo de tu tutor!", "📝", "#F2994A");
            return;
        }
    }
    if (pasoDestino === 3) {
        if (!avatarSeleccionado || gradoSeleccionado === 0) {
            // AHORA USAMOS LA ALERTA MÁGICA
            mostrarAlertaMagica("¡Elige un avatar y tu grado para continuar!", "🎨", "#2F80ED");
            return;
        }
    }

    // (El resto del código se queda igual...)
    document.getElementById('regStep1').style.display = 'none';
    document.getElementById('regStep2').style.display = 'none';
    document.getElementById('regStep3').style.display = 'none';
    document.getElementById(`regStep${pasoDestino}`).style.display = 'block';
}

// Funciones visuales para resaltar la selección (se mantienen igual)
function seleccionarAvatar(avatar) {
    avatarSeleccionado = avatar;
    document.querySelectorAll('.avatar-option').forEach(el => el.classList.remove('selected'));
    document.getElementById(`av-${avatar}`).classList.add('selected');
}

function seleccionarGrado(grado) {
    gradoSeleccionado = grado;
    document.querySelectorAll('.grado-option').forEach(el => el.classList.remove('selected'));
    document.getElementById(`gr-${grado}`).classList.add('selected');
}

// Lógica del teclado numérico para el REGISTRO
function tecladoPinRegistro(numero) {
    if (pinRegistroActual.length < 4) {
        pinRegistroActual += numero;
        document.getElementById('regPinDisplay').textContent = "⭐".repeat(pinRegistroActual.length);
    }
}

function borrarPinRegistro() {
    pinRegistroActual = "";
    document.getElementById('regPinDisplay').textContent = "";
}

// Enviar datos finalmente al servidor
// Enviar datos finalmente al servidor
function crearAlumnoBackend() {
    // 1. Alerta si el PIN está incompleto (Morado para que combine con el Paso 3)
    if (pinRegistroActual.length < 4) {
        mostrarAlertaMagica("¡Tu PIN secreto debe tener 4 números (4 estrellitas)!", "🔐", "#9B59B6");
        return;
    }

    const nombre = document.getElementById('regNombre').value.trim();
    const email = document.getElementById('regEmail').value.trim();

    fetch('/api/usuarios', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            nombre: nombre,
            email: email,
            grado_escolar: gradoSeleccionado,
            pin: pinRegistroActual,
            avatar: avatarSeleccionado
        })
    })
    .then(res => res.json())
    .then(data => {
        if (data.id) {
            // 2. Alerta de Éxito (Verde festivo)
            mostrarAlertaMagica("¡Personaje creado con éxito! Ahora entra con tu nuevo PIN secreto.", "🎉", "#27AE60");
            volverARoles();
        } else {
            // 3. Alerta si falta algún dato o hay un error en Flask (Rojo)
            mostrarAlertaMagica(data.error || "Hubo un problema al crear tu perfil.", "❌", "#E74C3C");
        }
    })
    .catch(error => {
        console.error("Error:", error);
        // 4. Alerta si el servidor está apagado (Rojo coral)
        mostrarAlertaMagica("Error de conexión. ¿El servidor está encendido?", "🔌", "#FF6B6B");
    });
}

async function guardarPreguntaReal() {
    const texto = document.getElementById('q-text').value.trim();
    const materia = document.getElementById('q-subject').value;
    const grado = parseInt(document.getElementById('q-grade').value);
    
    // Obtenemos las 4 opciones
    const opciones = [
        document.getElementById('opt-0').value.trim(),
        document.getElementById('opt-1').value.trim(),
        document.getElementById('opt-2').value.trim(),
        document.getElementById('opt-3').value.trim()
    ];

    // Obtenemos cuál es la correcta (el índice 0, 1, 2 o 3)
    const correcta = parseInt(document.querySelector('input[name="correcta"]:checked').value);

    // Validación básica
    if (!texto || opciones.some(opt => opt === "")) {
        mostrarAlertaMagica("¡Faltan datos! Escribe la pregunta y todas las opciones.", "⚠️", "#F39C12");
        return;
    }

    // Enviamos a tu backend (asegúrate de tener esta ruta en actividades_bp)
    fetch('/api/preguntas', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            materia: materia,
            grado: grado,
            texto: texto,
            opciones: opciones,
            correcta: correcta
        })
    })
    .then(res => res.json())
    .then(data => {
        if (data.ok) {
            mostrarAlertaMagica("¡Pregunta guardada en Neon exitosamente!", "🚀", "#27AE60");
            // Limpiar formulario
            document.getElementById('q-text').value = '';
            opciones.forEach((_, i) => document.getElementById(`opt-${i}`).value = '');
        } else {
            mostrarAlertaMagica("Error al guardar: " + data.error, "❌", "#E74C3C");
        }
    })
    .catch(err => mostrarAlertaMagica("Error de conexión con el servidor.", "🔌", "#FF6B6B"));
}

// Función auxiliar para regresar al menú de botones
function volverARoles() {
    document.getElementById('authContainer').style.display = 'none';
    document.getElementById('backToRoles').style.display = 'none';
    document.getElementById('roleSelector').style.display = 'flex';
}

// Seleccionar usuario desde la pantalla de bienvenida
function selectUserFromWelcome(userId) {
    selectUser(userId);
    closeWelcomeScreen();
}

// Cerrar pantalla de bienvenida y mostrar contenido principal
function closeWelcomeScreen() {
    welcomeOverlay.style.display = 'none';
    mainContainer.style.display = 'flex';

    // Actualizar la interfaz con el usuario seleccionado
    if (currentUser) {
        updateCurrentUserDisplay();
        loadUserAchievements();
        loadActivityHistory();
    }
}



// Elementos DOM
const activityCards = document.querySelectorAll('.activity-card');
const instructionsModal = document.getElementById('instructionsModal');
const instructionsTitle = document.getElementById('instructionsTitle');
const instructionsText = document.getElementById('instructionsText');
const startGame = document.getElementById('startGame');
const closeInstructions = document.getElementById('closeInstructions');
const gameModal = document.getElementById('gameModal');
const gameActivityTitle = document.getElementById('gameActivityTitle');
const gameEmoji = document.getElementById('gameEmoji');
const gameTitle = document.getElementById('gameTitle');
const gameContainer = document.getElementById('gameContainer');
const closeGame = document.getElementById('closeGame');
const backToInstructions = document.getElementById('backToInstructions');
const backToMenu = document.getElementById('backToMenu');
const darkModeToggle = document.getElementById('darkModeToggle');
const audioToggle = document.getElementById('audioToggle');
const voiceBtn = document.getElementById('voiceBtn');
const voiceStatus = document.getElementById('voiceStatus');
const starsCount = document.getElementById('stars-count');
const playTime = document.getElementById('play-time');
const progressBar = document.querySelector('.progress-bar');

// Elementos de gestión de usuarios
const userManagementModal = document.getElementById('userManagementModal');
const closeUserManagement = document.getElementById('closeUserManagement');
const userList = document.getElementById('userList');
const userForm = document.getElementById('userForm');
const userFormTitle = document.getElementById('userFormTitle');
const userNameInput = document.getElementById('userName');
const userAgeInput = document.getElementById('userAge');
const userAvatarInput = document.getElementById('userAvatar');
const saveUserBtn = document.getElementById('saveUser');
const cancelEditBtn = document.getElementById('cancelEdit');
const createNewUserBtn = document.getElementById('createNewUser');
const confirmationModal = document.getElementById('confirmationModal');
const confirmationText = document.getElementById('confirmationText');
const confirmDeleteBtn = document.getElementById('confirmDelete');
const cancelDeleteBtn = document.getElementById('cancelDelete');
const currentUserDisplay = document.getElementById('currentUserDisplay');
const currentUserName = document.getElementById('currentUserName');
const currentUserAvatar = document.getElementById('currentUserAvatar');
const logoutBtn = document.getElementById('logoutBtn');

// Datos de las actividades COMPLETAS
const activities = {
    memory: {
        emoji: '🧠',
        title: 'Memoria Increíble',
        instructions: `
            <p><strong>¡Entrena tu memoria con estos juegos desafiantes!</strong></p>
            <div class="instructions-example">
                <strong>Tipos de juegos:</strong><br>
                • Memoria de parejas: Encuentra las cartas iguales<br>
                • Memoria de secuencias: Recuerda el orden de los elementos<br>
                • Memoria visual: Encuentra los objetos que cambiaron
            </div>
            <p>¡Desarrolla tu memoria mientras te diviertes!</p>
        `,
        gameTypes: ['parejas', 'secuencias', 'visual']
    },
    math: {
        emoji: '🔢',
        title: 'Matemáticas Mágicas',
        instructions: `
            <p><strong>¡Descubre el mundo mágico de las matemáticas!</strong></p>
            <div class="instructions-example">
                <strong>Tipos de juegos:</strong><br>
                • Operaciones básicas: Sumas, restas, multiplicaciones<br>
                • Problemas con dinero: Aprende a contar monedas<br>
                • Reloj y tiempo: Aprende a leer la hora<br>
                • Fracciones divertidas: Partes de un todo
            </div>
            <p>¡Las matemáticas nunca fueron tan divertidas!</p>
        `,
        gameTypes: ['operaciones', 'dinero', 'tiempo', 'fracciones']
    },
    logic: {
        emoji: '🧩',
        title: 'Lógica y Puzzles',
        instructions: `
            <p><strong>¡Pon a prueba tu cerebro con estos acertijos!</strong></p>
            <div class="instructions-example">
                <strong>Tipos de juegos:</strong><br>
                • Patrones y secuencias: Descubre qué sigue<br>
                • Rompecabezas: Ordena las piezas<br>
                • Acertijos visuales: Encuentra la lógica oculta<br>
                • Pensamiento lateral: Piensa fuera de la caja
            </div>
            <p>¡Entrena tu mente para resolver cualquier problema!</p>
        `,
        gameTypes: ['patrones', 'rompecabezas', 'acertijos', 'pensamiento']
    },
    grammar: {
        emoji: '📝',
        title: 'Gramática Divertida',
        instructions: `
            <p><strong>¡Aprende gramática de forma entretenida!</strong></p>
            <div class="instructions-example">
                <strong>Tipos de juegos:</strong><br>
                • Completar oraciones: Elige la palabra correcta<br>
                • Sinónimos y antónimos: Encuentra palabras relacionadas<br>
                • Ordenar palabras: Forma oraciones correctas<br>
                • Identificar verbos: Reconoce acciones en las oraciones
            </div>
            <p>¡Mejora tu español mientras juegas!</p>
        `,
        gameTypes: ['completar', 'sinonimos', 'ordenar', 'verbos']
    },
    english: {
        emoji: '🔤',
        title: 'Inglés Básico',
        instructions: `
            <p><strong>¡Aprende inglés con juegos interactivos!</strong></p>
            <div class="instructions-example">
                <strong>Tipos de juegos:</strong><br>
                • Vocabulario básico: Palabras comunes en inglés<br>
                • Pronombres y verbos: Partes fundamentales del inglés<br>
                • Frases útiles: Expresiones para el día a día<br>
                • Opuestos: Aprende antónimos en inglés
            </div>
            <p>¡Hablar inglés es más fácil de lo que piensas!</p>
        `,
        gameTypes: ['vocabulario', 'pronombres', 'frases', 'opuestos']
    },
    geography: {
        emoji: '🌎',
        title: 'Aventura Geográfica',
        instructions: `
            <p><strong>¡Explora el mundo desde tu casa!</strong></p>
            <div class="instructions-example">
                <strong>Tipos de juegos:</strong><br>
                • Países y capitales: Aprende sobre naciones del mundo<br>
                • Banderas del mundo: Reconocimiento de banderas<br>
                • Accidentes geográficos: Montañas, ríos y océanos<br>
                • Culturas del mundo: Tradiciones y costumbres
            </div>
            <p>¡Conviértete en un gran explorador!</p>
        `,
        gameTypes: ['paises', 'banderas', 'geografia', 'culturas']
    },
    art: {
        emoji: '🎨',
        title: 'Arte Creativo',
        instructions: `
            <p><strong>¡Desarrolla tu creatividad artística!</strong></p>
            <div class="instructions-example">
                <strong>Tipos de juegos:</strong><br>
                • Mezcla de colores: Crea nuevos colores<br>
                • Reconocimiento de colores: Identifica colores primarios y secundarios<br>
                • Formas geométricas: Aprende sobre figuras<br>
                • Arte famoso: Conoce obras de arte reconocidas
            </div>
            <p>¡Descubre el artista que llevas dentro!</p>
        `,
        gameTypes: ['colores', 'reconocimiento', 'formas', 'arte-famoso']
    },
    science: {
        emoji: '🔬',
        title: 'Ciencia Divertida',
        instructions: `
            <p><strong>¡Descubre los misterios de la ciencia!</strong></p>
            <div class="instructions-example">
                <strong>Tipos de juegos:</strong><br>
                • Animales y habitat: Clasificación de animales<br>
                • Cuerpo humano: Partes y sistemas del cuerpo<br>
                • Plantas y naturaleza: Mundo vegetal<br>
                • Experimentos simples: Ciencia práctica
            </div>
            <p>¡Conviértete en un pequeño científico!</p>
        `,
        gameTypes: ['animales', 'cuerpo-humano', 'plantas', 'experimentos']
    }
};


// Estado de la aplicación
let currentActivity = null;
let currentGameType = null;
let currentDifficulty = 'easy';
let stars = 0;
let playTimeMinutes = 0;
let darkMode = false;
let audioOn = true;
let recognition = null;
let isListening = false;

// Gestión de usuarios
let users = [];
let currentUser = null;
let editingUserId = null;
let userToDelete = null;

//SISTEMA DE INFORME PARA PADRES 

// Elementos DOM para el informe
const parentReportModal = document.getElementById('parentReportModal');
const parentReportBtn = document.getElementById('parentReportBtn');
const closeParentReport = document.getElementById('closeParentReport');
const closeReport = document.getElementById('closeReport');
const printReport = document.getElementById('printReport');
const exportReport = document.getElementById('exportReport');
const reportTabs = document.querySelectorAll('.report-tab');
const reportTabContents = document.querySelectorAll('.report-tab-content');

// Datos históricos para seguimiento
let userActivityHistory = [];

// Cargar historial de actividades
function loadActivityHistory() {
    if (!currentUser) return;

    const savedHistory = localStorage.getItem(`eduplay_history_${currentUser.id}`);
    if (savedHistory) {
        userActivityHistory = JSON.parse(savedHistory);
    } else {
        userActivityHistory = [];
    }
}

// Guardar historial de actividades
function saveActivityHistory() {
    if (!currentUser) return;
    localStorage.setItem(`eduplay_history_${currentUser.id}`, JSON.stringify(userActivityHistory));
}

// Registrar actividad en el historial
function recordActivity(activity, gameType, result = 'completado') {
    if (!currentUser) return;

    const activityRecord = {
        id: Date.now(),
        timestamp: new Date().toISOString(),
        user: currentUser.id,
        activity: activity,
        gameType: gameType,
        result: result,
        starsEarned: 1
    };

    userActivityHistory.unshift(activityRecord);

    // Mantener solo las últimas 50 actividades
    if (userActivityHistory.length > 50) {
        userActivityHistory = userActivityHistory.slice(0, 50);
    }

    saveActivityHistory();
}

// Mostrar modal de informe
function showParentReport() {
    if (!currentUser) {
        alert('Primero debes seleccionar un usuario');
        return;
    }

    loadActivityHistory();
    renderParentReport();
    parentReportModal.style.display = 'flex';
}

// Renderizar el informe completo
function renderParentReport() {
    if (!currentUser) return;

    // Actualizar información del usuario
    document.getElementById('reportUserInfo').innerHTML = `
        <div class="report-user-avatar" style="background: ${getUserColor(currentUser.id)}">
            ${currentUser.avatar}
        </div>
        <div class="report-user-details">
            <h3>${currentUser.name}</h3>
            <p>${currentUser.age} años | ${currentUser.stars} ⭐ | ${currentUser.playTime} min</p>
            <p>Usuario desde: ${new Date(currentUser.id).toLocaleDateString()}</p>
        </div>
    `;

    // Actualizar fecha del informe
    document.getElementById('reportDate').textContent = new Date().toLocaleString();

    // Renderizar cada pestaña
    renderOverviewTab();
    renderActivitiesTab();
    renderAchievementsTab();
    renderRecommendationsTab();
}

// Pestaña de resumen general
function renderOverviewTab() {
    if (!currentUser) return;

    // Estadísticas principales
    document.getElementById('overviewStars').textContent = currentUser.stars;
    document.getElementById('overviewTime').textContent = `${currentUser.playTime} min`;

    const unlockedAchievements = Object.values(userAchievements).filter(a => a.unlocked).length;
    document.getElementById('overviewAchievements').textContent = `${unlockedAchievements}/15`;

    const progress = Math.min((currentUser.stars / 100) * 100, 100);
    document.getElementById('overviewProgress').textContent = `${progress.toFixed(1)}%`;

    // Gráfico de distribución de actividades
    renderDistributionChart();

    // Línea de tiempo de actividad reciente
    renderActivityTimeline();
}

// Gráfico de distribución
function renderDistributionChart() {
    const distributionChart = document.getElementById('distributionChart');
    distributionChart.innerHTML = '';

    // Calcular conteo por actividad
    const activityData = {};
    Object.keys(activityCounts).forEach(activity => {
        if (activityCounts[activity] > 0) {
            const activityInfo = activities[activity];
            activityData[activity] = {
                name: activityInfo.title,
                emoji: activityInfo.emoji,
                count: activityCounts[activity]
            };
        }
    });

    // Ordenar por frecuencia
    const sortedActivities = Object.entries(activityData)
        .sort((a, b) => b[1].count - a[1].count)
        .slice(0, 6); // Mostrar solo las 6 principales

    // Calcular total para porcentajes
    const total = sortedActivities.reduce((sum, [, data]) => sum + data.count, 0);

    // Crear elementos del gráfico
    sortedActivities.forEach(([activity, data]) => {
        const percentage = total > 0 ? (data.count / total) * 100 : 0;

        const chartItem = document.createElement('div');
        chartItem.className = 'chart-item';
        chartItem.innerHTML = `
            <div class="chart-emoji">${data.emoji}</div>
            <div class="chart-name">${data.name}</div>
            <div class="chart-bar">
                <div class="chart-fill" style="width: ${percentage}%"></div>
            </div>
            <div class="chart-count">${data.count} juegos (${percentage.toFixed(1)}%)</div>
        `;

        distributionChart.appendChild(chartItem);

        // Animar la barra
        setTimeout(() => {
            chartItem.querySelector('.chart-fill').style.width = `${percentage}%`;
        }, 100);
    });
}

// Renderizar línea de tiempo de actividad
function renderActivityTimeline() {
    const activityTimeline = document.getElementById('activityTimeline');
    activityTimeline.innerHTML = '';

    // Tomar las últimas 10 actividades
    const recentActivities = userActivityHistory.slice(0, 10);

    if (recentActivities.length === 0) {
        activityTimeline.innerHTML = `
            <div class="timeline-item">
                <div class="timeline-activity">
                    <span class="timeline-emoji">📝</span>
                    <span class="timeline-text">No hay actividad registrada todavía</span>
                </div>
            </div>
        `;
        return;
    }

    recentActivities.forEach(activity => {
        const activityInfo = activities[activity.activity];
        const gameInfo = gameContent[activity.activity]?.[activity.gameType];

        const time = new Date(activity.timestamp);
        const timeStr = time.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

        const timelineItem = document.createElement('div');
        timelineItem.className = 'timeline-item';
        timelineItem.innerHTML = `
            <div class="timeline-time">${timeStr}</div>
            <div class="timeline-activity">
                <span class="timeline-emoji">${activityInfo?.emoji || '🎮'}</span>
                <span class="timeline-text">${gameInfo?.title || activity.activity} - ${activity.result}</span>
            </div>
        `;

        activityTimeline.appendChild(timelineItem);
    });
}

// Renderizar pestaña Actividades
function renderActivitiesTab() {
    const activityDetails = document.getElementById('activityDetails');
    activityDetails.innerHTML = '';

    Object.keys(activities).forEach(activityKey => {
        const activity = activities[activityKey];
        const count = activityCounts[activityKey] || 0;

        if (count === 0) return; // Solo mostrar actividades con uso

        // Calcular métricas
        const avgStars = count > 0 ? (currentUser.stars * 0.1 / count).toFixed(1) : 0;
        const successRate = Math.min(80 + Math.random() * 20, 100).toFixed(0);

        const detailCard = document.createElement('div');
        detailCard.className = 'activity-detail-card';
        detailCard.innerHTML = `
            <div class="activity-detail-header">
                <div class="activity-detail-emoji">${activity.emoji}</div>
                <div class="activity-detail-title">
                    <h4>${activity.title}</h4>
                    <p>${count} ${count === 1 ? 'juego' : 'juegos'} completados</p>
                </div>
            </div>
            
            <div class="activity-detail-stats">
                <div class="detail-stat">
                    <div class="detail-value">${count}</div>
                    <div class="detail-label">Total</div>
                </div>
                <div class="detail-stat">
                    <div class="detail-value">${avgStars}</div>
                    <div class="detail-label">⭐/juego</div>
                </div>
                <div class="detail-stat">
                    <div class="detail-value">${successRate}%</div>
                    <div class="detail-label">Éxito</div>
                </div>
                <div class="detail-stat">
                    <div class="detail-value">${getDifficultyLevel(activityKey)}</div>
                    <div class="detail-label">Nivel</div>
                </div>
            </div>
        `;

        activityDetails.appendChild(detailCard);
    });
}

// Función auxiliar para obtener nivel de dificultad
function getDifficultyLevel(activity) {
    const levels = {
        memory: 'Avanzado',
        math: 'Intermedio',
        grammar: 'Intermedio',
        english: 'Principiante',
        geography: 'Intermedio',
        art: 'Principiante',
        science: 'Intermedio',
        logic: 'Avanzado'
    };
    return levels[activity] || 'Intermedio';
}

// Renderizar pestaña Logros
function renderAchievementsTab() {
    const achievementsReport = document.getElementById('achievementsReport');
    achievementsReport.innerHTML = '';

    achievementsList.forEach(achievement => {
        const achievementData = userAchievements[achievement.id] || { unlocked: false, dateUnlocked: null };

        const achievementCard = document.createElement('div');
        achievementCard.className = `achievement-report-card ${achievementData.unlocked ? 'unlocked' : ''}`;

        let dateInfo = '';
        if (achievementData.unlocked && achievementData.dateUnlocked) {
            const date = new Date(achievementData.dateUnlocked);
            dateInfo = `<div class="achievement-report-date">${date.toLocaleDateString()}</div>`;
        }

        achievementCard.innerHTML = `
            <div class="achievement-report-icon">${achievement.icon}</div>
            <div class="achievement-report-name">${achievement.name}</div>
            <div class="achievement-report-desc">${achievement.description}</div>
            ${dateInfo}
            ${achievementData.unlocked ? '<div style="color: var(--accent-green); margin-top: 8px;">✓ Desbloqueado</div>' :
                '<div style="color: var(--text-secondary); margin-top: 8px;">⌛ Pendiente</div>'}
        `;

        // Estilo para logros desbloqueados
        if (achievementData.unlocked) {
            achievementCard.style.borderColor = achievement.color;
        }

        achievementsReport.appendChild(achievementCard);
    });
}

// Renderizar pestaña Recomendaciones
function renderRecommendationsTab() {
    // Calcular puntos fuertes
    const strengths = calculateStrengths();
    const improvements = calculateImprovements();
    const suggestions = generateSuggestions();

    document.getElementById('strengthsContent').innerHTML = strengths;
    document.getElementById('improvementContent').innerHTML = improvements;
    document.getElementById('suggestionsContent').innerHTML = suggestions;
}

// Calcular puntos fuertes
function calculateStrengths() {
    if (!currentUser) return '<p>No hay datos suficientes</p>';

    const strengths = [];

    // Encontrar actividades con mayor frecuencia
    const sortedActivities = Object.entries(activityCounts)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 3);

    if (sortedActivities.length > 0 && sortedActivities[0][1] > 0) {
        sortedActivities.forEach(([activity, count]) => {
            if (count > 0) {
                strengths.push(`<div class="recommendation-item">${activities[activity]?.emoji} ${activities[activity]?.title} (${count} veces)</div>`);
            }
        });
    }

    // Verificar logros
    const unlockedCount = Object.values(userAchievements).filter(a => a.unlocked).length;
    if (unlockedCount > 5) {
        strengths.push(`<div class="recommendation-item">🏆 ${unlockedCount} logros desbloqueados</div>`);
    }

    if (currentUser.stars > 25) {
        strengths.push(`<div class="recommendation-item">⭐ ${currentUser.stars} estrellas ganadas</div>`);
    }

    return strengths.join('') || '<p>¡Sigue jugando para descubrir tus fortalezas!</p>';
}

// Calcular áreas de mejora
function calculateImprovements() {
    if (!currentUser) return '<p>No hay datos suficientes</p>';

    const improvements = [];

    // Encontrar actividades con menor frecuencia
    const sortedActivities = Object.entries(activityCounts)
        .sort((a, b) => a[1] - b[1])
        .slice(0, 3);

    sortedActivities.forEach(([activity, count]) => {
        if (count < 3) {
            improvements.push(`<div class="recommendation-item">${activities[activity]?.emoji} ${activities[activity]?.title} (solo ${count} veces)</div>`);
        }
    });

    // Verificar tiempo de juego
    if (currentUser.playTime < 30) {
        improvements.push(`<div class="recommendation-item">⏱️ Solo ${currentUser.playTime} minutos de juego</div>`);
    }

    return improvements.join('') || '<p>¡Excelente! Estás explorando todas las áreas</p>';
}

// Generar sugerencias
function generateSuggestions() {
    const suggestions = [];

    // Basado en el tiempo de juego
    if (currentUser.playTime < 60) {
        suggestions.push(`<div class="recommendation-item">🎯 Juega 15 minutos diarios para mejorar</div>`);
    }

    // Basado en logros
    const unlockedCount = Object.values(userAchievements).filter(a => a.unlocked).length;
    if (unlockedCount < 5) {
        suggestions.push(`<div class="recommendation-item">🏆 Intenta completar más juegos para desbloquear logros</div>`);
    }

    // Basado en distribución de actividades
    const activityCount = Object.values(activityCounts).filter(count => count > 0).length;
    if (activityCount < 5) {
        suggestions.push(`<div class="recommendation-item">🔍 Explora diferentes tipos de actividades</div>`);
    }

    // Sugerencias generales
    suggestions.push(`<div class="recommendation-item">📅 Establece una rutina de juego regular</div>`);
    suggestions.push(`<div class="recommendation-item">🎮 Alterna entre actividades de memoria y lógica</div>`);
    suggestions.push(`<div class="recommendation-item">⭐ Intenta conseguir todas las estrellas en cada juego</div>`);

    return suggestions.join('');
}

// Función auxiliar para obtener color del usuario
function getUserColor(userId) {
    const colors = [
        '#2F80ED', '#F2994A', '#27AE60', '#FF7AB6',
        '#FFD24C', '#9B51E0', '#56CCF2', '#BB6BD9'
    ];
    return colors[userId % colors.length];
}

// Reconocimiento de voz
function initializeVoiceRecognition() {
    if ('webkitSpeechRecognition' in window || 'SpeechRecognition' in window) {
        const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
        recognition = new SpeechRecognition();
        recognition.continuous = false;
        recognition.lang = 'es-ES';
        recognition.interimResults = false;
        recognition.maxAlternatives = 1;

        recognition.onstart = function () {
            isListening = true;
            voiceStatus.textContent = "Escuchando... 🎤";
            voiceStatus.classList.add('voice-active');
            voiceBtn.innerHTML = '<span>⏹️</span> Detener';
        };

        recognition.onresult = function (event) {
            const speechResult = event.results[0][0].transcript.toLowerCase();
            voiceStatus.textContent = `Reconocido: "${speechResult}"`;
            handleVoiceCommand(speechResult);
            setTimeout(() => {
                resetVoiceStatus();
            }, 3000);
        };

        recognition.onerror = function (event) {
            console.log('Error en reconocimiento de voz: ', event.error);
            voiceStatus.textContent = "Error al escuchar. Intenta de nuevo.";
            setTimeout(() => {
                resetVoiceStatus();
            }, 3000);
        };

        recognition.onend = function () {
            isListening = false;
            if (voiceStatus.textContent === "Escuchando... 🎤") {
                resetVoiceStatus();
            }
        };
    } else {
        voiceBtn.innerHTML = '<span>🎤</span> No Soportado';
        voiceBtn.disabled = true;
        voiceStatus.textContent = "Reconocimiento de voz no disponible en este navegador";
    }
}

function resetVoiceStatus() {
    voiceStatus.textContent = "Listo para escuchar...";
    voiceStatus.classList.remove('voice-active');
    voiceBtn.innerHTML = '<span>🎤</span> Activar Comandos';
    isListening = false;
}

// Manejar comandos de voz EXPANDIDOS
function handleVoiceCommand(command) {
    if (command.includes('matemática') || command.includes('matemáticas') || command.includes('números')) {
        showInstructions('math');
    } else if (command.includes('memoria') || command.includes('recordar')) {
        showInstructions('memory');
    } else if (command.includes('gramática') || command.includes('español') || command.includes('palabras')) {
        showInstructions('grammar');
    } else if (command.includes('inglés') || command.includes('english') || command.includes('idioma')) {
        showInstructions('english');
    } else if (command.includes('geografía') || command.includes('países') || command.includes('mundial')) {
        showInstructions('geography');
    } else if (command.includes('arte') || command.includes('colores') || command.includes('pintura')) {
        showInstructions('art');
    } else if (command.includes('ciencia') || command.includes('experimento') || command.includes('animales')) {
        showInstructions('science');
    } else if (command.includes('lógica') || command.includes('puzzle') || command.includes('rompecabezas')) {
        showInstructions('logic');
    } else if (command.includes('oscuro') || command.includes('modo oscuro') || command.includes('noche')) {
        toggleDarkMode();
    } else if (command.includes('claro') || command.includes('modo claro') || command.includes('día')) {
        if (darkMode) toggleDarkMode();
    } else if (command.includes('sonido') || command.includes('audio') || command.includes('silenciar')) {
        toggleAudio();
    } else if (command.includes('volver') || command.includes('menú') || command.includes('inicio')) {
        closeModals();
    } else if (command.includes('progreso') || command.includes('estrellas') || command.includes('puntaje')) {
        alert(`Tienes ${currentUser ? currentUser.stars : 0} estrellas y ${currentUser ? currentUser.playTime : 0} minutos jugando!`);
    } else if (command.includes('ayuda') || command.includes('instrucciones')) {
        alert('Puedes decir: "Abrir matemáticas", "Jugar memoria", "Modo oscuro", "Apagar sonido", etc.');
    } else if (command.includes('logros') || command.includes('trofeos') || command.includes('medallas')) {
        showAchievementsModal();
    } else if (command.includes('informe') || command.includes('padres') || command.includes('reporte')) {
        showParentReport();
    } else {
        voiceStatus.textContent = `Comando no reconocido: "${command}". Intenta decir "ayuda" para ver opciones.`;
    }
}

// Alternar modo oscuro CON ANIMACIÓN
function toggleDarkMode() {
    darkMode = !darkMode;
    document.body.classList.toggle('dark-mode', darkMode);
    const icon = darkModeToggle.querySelector('span');
    icon.textContent = darkMode ? '☀️' : '🌙';
    createConfetti(); // Animación siempre que se cambie el modo
}

// Alternar audio pendiente
function toggleAudio() {
    audioOn = !audioOn;
    const icon = audioToggle.querySelector('span');
    const text = audioToggle.querySelector('span:last-child');
    if (audioOn) {
        icon.textContent = '🔊';
        text.textContent = 'Sonido ON';
        // Aquí podrías agregar sonidos si quisieras
        playSound('on');
    } else {
        icon.textContent = '🔇';
        text.textContent = 'Sonido OFF';
    }
}

// Función para reproducir sonidos
function playSound(type) {
    if (!audioOn) return;

    // En un futuro agregar sonido aqui xD
    console.log(`Reproduciendo sonido: ${type}`);
}

// Crear confetti para modo oscuro
function createConfetti() {
    const colors = ['#FFD24C', '#FF7AB6', '#2F80ED', '#27AE60', '#9B51E0'];
    for (let i = 0; i < 30; i++) {
        const confetti = document.createElement('div');
        confetti.style.position = 'fixed';
        confetti.style.width = '10px';
        confetti.style.height = '10px';
        confetti.style.background = colors[Math.floor(Math.random() * colors.length)];
        confetti.style.borderRadius = '50%';
        confetti.style.left = `${Math.random() * 100}vw`;
        confetti.style.top = '-10px';
        confetti.style.zIndex = '9999';
        document.body.appendChild(confetti);

        confetti.animate([
            { transform: 'translateY(0) rotate(0deg)', opacity: 1 },
            { transform: `translateY(${window.innerHeight}px) rotate(${Math.random() * 360}deg)`, opacity: 0 }
        ], {
            duration: 1000 + Math.random() * 2000,
            easing: 'cubic-bezier(0.1, 0.8, 0.2, 1)'
        }).onfinish = () => confetti.remove();
    }
}

// Gestion de usuarios

// Cargar usuarios desde localStorage
function loadUsers() {
    const savedUsers = localStorage.getItem('eduplay_users');
    if (savedUsers) {
        users = JSON.parse(savedUsers);
    } else {
        users = [];
    }
}

// Guardar usuarios en localStorage
function saveUsers() {
    localStorage.setItem('eduplay_users', JSON.stringify(users));
}

function updateCurrentUserDisplay() {
    if (currentUser) {
        if(currentUserName) currentUserName.textContent = currentUser.name;
        if(currentUserAvatar) {
            currentUserAvatar.textContent = currentUser.avatar;
            const colors = ['#2F80ED', '#F2994A', '#27AE60', '#FF7AB6', '#FFD24C', '#9B51E0', '#56CCF2', '#BB6BD9'];
            currentUserAvatar.style.background = colors[currentUser.id % colors.length];
        }
        if(starsCount) starsCount.textContent = currentUser.stars;
        if(playTime) playTime.textContent = `${currentUser.playTime} min`;
        if(progressBar) progressBar.style.width = `${Math.min((currentUser.stars / 100) * 100, 100)}%`;
        if(logoutBtn) logoutBtn.style.display = 'flex';
    } else {
        if(currentUserName) currentUserName.textContent = 'Usuario';
        if(currentUserAvatar) {
            currentUserAvatar.textContent = 'U';
            currentUserAvatar.style.background = '#2F80ED';
        }
        if(logoutBtn) logoutBtn.style.display = 'none';
    }
}

// Crear nuevo usuario
function createNewUser() {
    editingUserId = null;
    userFormTitle.textContent = 'Crear Nuevo Usuario';
    userNameInput.value = '';
    userAgeInput.value = '';
    userAvatarInput.value = '';
    setTimeout(() => {
        userNameInput.focus();
    }, 300);
}

// Editar usuario existente
function editUser(userId) {
    const user = users.find(u => u.id === userId);
    if (!user) return;

    editingUserId = userId;
    userFormTitle.textContent = 'Editar Usuario';
    userNameInput.value = user.name;
    userAgeInput.value = user.age;
    userAvatarInput.value = user.avatar;
    setTimeout(() => {
        userNameInput.focus();
    }, 300);
}

// Guardar usuario (crear o editar)
function saveUser() {
    const name = userNameInput.value.trim();
    const age = parseInt(userAgeInput.value);
    const avatar = userAvatarInput.value.trim();

    if (!name || name.length < 2) {
        alert('El nombre debe tener al menos 2 caracteres');
        return;
    }

    if (!age || age < 3 || age > 12) {
        alert('La edad debe estar entre 3 y 12 años');
        return;
    }

    if (!avatar || avatar.length === 0) {
        alert('Por favor selecciona un emoji para el avatar');
        return;
    }

    if (editingUserId) {
        // Editar usuario existente
        const userIndex = users.findIndex(u => u.id === editingUserId);
        if (userIndex !== -1) {
            users[userIndex].name = name;
            users[userIndex].age = age;
            users[userIndex].avatar = avatar;
        }
    } else {
        // Crear nuevo usuario
        const newUser = {
            id: Date.now(),
            name: name,
            age: age,
            avatar: avatar,
            stars: 0,
            playTime: 0,
            createdAt: new Date().toISOString()
        };
        users.push(newUser);
    }

    saveUsers();
    renderUserList();
    cancelEditUser();

    // Si no hay usuario actual seleccionar este nuevo
    if (!currentUser && !editingUserId) {
        const newUser = users[users.length - 1];
        selectUser(newUser.id);
    }
}

// Eliminar usuario
function deleteUser(userId) {
    const user = users.find(u => u.id === userId);
    if (!user) return;

    userToDelete = userId;
    confirmationText.textContent = `¿Estás seguro de que quieres eliminar a ${user.name}? Todos sus datos y progreso se perderán permanentemente.`;
    confirmationModal.style.display = 'flex';
}

// Confirmar eliminación
function confirmDelete() {
    if (!userToDelete) return;

    // Si el usuario a eliminar es el actual, deseleccionarlo
    if (currentUser && currentUser.id === userToDelete) {
        currentUser = null;
        updateCurrentUserDisplay();
        logoutBtn.style.display = 'none';
    }

    // Eliminar usuario de la lista
    users = users.filter(u => u.id !== userToDelete);
    saveUsers();
    renderUserList();

    // Cerrar modal de confirmación
    confirmationModal.style.display = 'none';
    userToDelete = null;

    // Si hay usuarios disponibles, seleccionar el primero
    if (users.length > 0 && !currentUser) {
        selectUser(users[0].id);
    }
}

// Cancelar edición
function cancelEditUser() {
    editingUserId = null;
}

// Renderizar lista de usuarios
function renderUserList() {
    const userListContainer = document.getElementById('userList');
    
    // ESCUDO: Si no estamos en la pantalla de gestión de usuarios, salimos sin error [cite: 320]
    if (!userListContainer) return;

    userListContainer.innerHTML = '';
    
    if (users.length === 0) {
        userListContainer.innerHTML = `
            <div class="user-item">
                <div class="user-info">
                    <div class="user-name">No hay usuarios registrados</div>
                </div>
            </div>`;
        return;
    }

    users.forEach(user => {
        const isCurrent = currentUser && currentUser.id === user.id;
        const userItem = document.createElement('div');
        userItem.className = `user-item ${isCurrent ? 'active' : ''}`;
        userItem.innerHTML = `
            <div class="user-header">
                <div class="user-avatar" style="background: ${getUserColor(user.id)}">${user.avatar}</div>
                <div class="user-info">
                    <div class="user-name">${user.name}</div>
                    <div class="user-stats">${user.stars} ⭐ | ${user.playTime} min</div>
                </div>
            </div>`;
        userListContainer.appendChild(userItem);
    });
} 

// Seleccionar usuario
function selectUser(userId) {
    const user = users.find(u => u.id === userId);
    if (!user) return;

    currentUser = user;
    updateCurrentUserDisplay();
    loadUserAchievements();
    loadActivityHistory();
    renderUserList();

    // Cerrar el modal automáticamente al seleccionar un usuario
    setTimeout(() => {
        userManagementModal.style.display = 'none';
    }, 300);
}

// Cerrar sesión
function logout() {
    if (currentUser) {
        // Guardar el progreso actual antes de cerrar sesión
        saveUsers();
        saveUserAchievements();
        saveActivityHistory();

        // Mostrar mensaje de confirmación
        alert(`Sesión de ${currentUser.name} cerrada. Tu progreso ha sido guardado.`);

        // Limpiar usuario actual
        currentUser = null;

        // Actualizar la interfaz
        updateCurrentUserDisplay();
        updateQuickAchievements();

        // Mostrar pantalla de bienvenida nuevamente
        showWelcomeScreen();
    }
}

// Jugar sin usuario (modo invitado)
function playWithoutUser() {
    currentUser = {
        id: 'guest_' + Date.now(),
        name: 'Invitado',
        age: 8,
        avatar: '👤',
        stars: 0,
        playTime: 0,
        createdAt: new Date().toISOString()
    };
    updateCurrentUserDisplay();
    loadUserAchievements();
    loadActivityHistory();

    // Cerrar pantalla de bienvenida
    closeWelcomeScreen();

    // Mostrar mensaje de bienvenida
    alert('¡Bienvenido a EduPlay! Estás jugando como invitado. Tu progreso se guardará durante esta sesión.');
}

//Funcionalidades del juego creo

// Mostrar instrucciones de la actividad
function showInstructions(activityKey) {
    if (!currentUser) {
        alert('Primero debes seleccionar un usuario');
        return;
    }

    const activity = activities[activityKey];
    if (!activity) return;

    currentActivity = activityKey;
    
    // ESCUDOS: Solo cambia el texto si el modal existe en el HTML
    const instTitle = document.getElementById('instructionsTitle');
    const instText = document.getElementById('instructionsText');
    const instModal = document.getElementById('instructionsModal');

    if (instTitle) instTitle.textContent = activity.title;
    
    if (instText) {
        instText.innerHTML = activity.instructions;
        // ... (aquí sigue el código que inyecta los botones de "gameTypes") ...
    }

    // Solo mostramos el modal si existe, si no, lanzamos un aviso
    if (instModal) {
        instModal.style.display = 'flex';
    } else {
        console.error("Falta agregar el modal de instrucciones y juegos en el index.html");
    }
}

// Obtener descripción del tipo de juego
function getGameTypeDescription(activity, type) {
    const descriptions = {
        memory: {
            parejas: 'Encuentra todas las parejas de cartas iguales',
            secuencias: 'Memoriza y repite la secuencia de colores',
            visual: 'Encuentra los objetos que cambiaron de lugar'
        },
        math: {
            operaciones: 'Sumas, restas, multiplicaciones y divisiones',
            dinero: 'Aprende a contar y usar monedas',
            tiempo: 'Reloj, horas y minutos',
            fracciones: 'Partes de un todo de forma divertida'
        },
        grammar: {
            completar: 'Completa oraciones con palabras correctas',
            sinonimos: 'Encuentra palabras con significado similar',
            ordenar: 'Ordena palabras para formar oraciones',
            verbos: 'Identifica acciones en las oraciones'
        }
    };

    return descriptions[activity]?.[type] || '¡Divertido juego de aprendizaje!';
}

// Seleccionar tipo de juego
function selectGameType(gameType) {
    currentGameType = gameType;
    startGame.click();
}

// Iniciar juego
function startGameFunction() {
    if (!currentActivity) return;

    const activity = activities[currentActivity];
    gameEmoji.textContent = activity.emoji;
    gameTitle.textContent = activity.title;

    // Cerrar instrucciones y abrir juego
    instructionsModal.style.display = 'none';
    gameModal.style.display = 'flex';

    // Cargar el juego específico
    loadGame(currentActivity, currentGameType);
}

function loadGame(activity, gameType) {
    if (!gameContent[activity] || !gameContent[activity][gameType]) {
        gameContainer.innerHTML = '<p>Juego no disponible</p>';
        return;
    }

    const game = gameContent[activity][gameType];

    /* Contador de actividades */
    if (activityCounts[activity] === undefined) {
        activityCounts[activity] = 0;
    }
    activityCounts[activity]++;

    switch (activity) {
        case 'memory':
            loadMemoryGame(game, gameType);
            break;

        case 'math':
            loadQuizGame(game, activity, gameType);
            break;

        case 'grammar':
            loadQuizGame(game, activity, gameType);
            break;

        case 'english':
            loadEnglishGame(game, gameType);
            break;

        case 'geography':
            loadQuizGame(game, activity, gameType);
            break;

        case 'art':
            loadQuizGame(game, activity, gameType);
            break;

        case 'science':
            loadQuizGame(game, activity, gameType);
            break;

        case 'logic':
            loadQuizGame(game, activity, gameType);
            break;

        default:
            gameContainer.innerHTML = `<p>Juego en desarrollo: ${game.title}</p>`;
    }
}

function toggleProfileMenu() {
    const menu = document.getElementById('profileMenu');
    const isVisible = menu.style.display === 'block';
    menu.style.display = isVisible ? 'none' : 'block';
    
    if (!isVisible) {
        cargarDatosPerfil();
    }
}

async function cargarDatosPerfil() {
    const uid = localStorage.getItem('userId');
    if (!uid) return;

    try {
        // Llamamos a una nueva ruta de API que crearemos
        const res = await fetch(`/api/usuarios/perfil/${uid}`);
        const data = await res.json();

        if (data.success) {
            document.getElementById('menuFullname').innerText = data.nombre;
            document.getElementById('statGrado').innerText = `${data.grado}º Grado`;
            document.getElementById('statEdad').innerText = `${data.edad} años`;
            document.getElementById('statMejorMateria').innerText = `🚀 ${data.mejor_materia}`;
        }
    } catch (e) {
        console.error("Error al cargar perfil:", e);
    }
}

// Cerrar el menú si haces clic afuera
window.onclick = function(event) {
    if (!event.target.closest('.profile-dropdown')) {
        document.getElementById('profileMenu').style.display = 'none';
    }
}

function loadMemoryGame(game, gameType) {
    const memoryColors = {
        parejas: { primary: '#9B51E0', secondary: '#AF7AC5' },
        secuencias: { primary: '#F39C12', secondary: '#F7DC6F' },
        visual: { primary: '#00BCD4', secondary: '#4DD0E1' }
    };

    const colors = memoryColors[gameType] || memoryColors.parejas;

    let gameHTML = '';

    if (gameType === 'parejas') {
        gameHTML = `
            <div style="background: white; border-radius: 20px; padding: 20px; box-shadow: 0 5px 20px rgba(0,0,0,0.1); border: 2px solid ${colors.primary}20;">
                <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 20px;">
                    <div style="font-size: 40px; background: ${colors.primary}10; width: 60px; height: 60px; border-radius: 50%; display: flex; align-items: center; justify-content: center;">
                        🧠
                    </div>
                    <div>
                        <h3 style="font-size: 20px; margin: 0; color: ${colors.primary};">${game.title}</h3>
                        <span style="background: ${colors.primary}; color: white; padding: 2px 8px; border-radius: 12px; font-size: 12px;">${game.difficulties[currentDifficulty].pairs} pares</span>
                    </div>
                </div>

                <div class="difficulty-selector" style="display: flex; gap: 8px; margin-bottom: 20px; justify-content: center;">
                    <button class="difficulty-btn ${currentDifficulty === 'easy' ? 'active' : ''}" onclick="setDifficulty('easy')" style="padding: 6px 12px; font-size: 13px;">Fácil</button>
                    <button class="difficulty-btn ${currentDifficulty === 'medium' ? 'active' : ''}" onclick="setDifficulty('medium')" style="padding: 6px 12px; font-size: 13px;">Medio</button>
                    <button class="difficulty-btn ${currentDifficulty === 'hard' ? 'active' : ''}" onclick="setDifficulty('hard')" style="padding: 6px 12px; font-size: 13px;">Difícil</button>
                </div>

                <div class="memory-grid" id="memoryGrid" style="grid-template-columns: ${game.difficulties[currentDifficulty].grid}; gap: 8px; margin-bottom: 20px;"></div>
                
                <div class="game-feedback" id="memoryFeedback" style="text-align: center; min-height: 30px; margin-bottom: 15px;"></div>
                
                <div style="display: flex; gap: 10px; justify-content: center;">
                    <button class="btn btn-primary" onclick="startMemoryGame()" style="background: ${colors.primary}; padding: 8px 16px; font-size: 14px;">
                        <span>🔄</span> Empezar
                    </button>
                    <button class="btn btn-secondary" onclick="resetMemoryGame()" style="padding: 8px 16px; font-size: 14px;">
                        <span>↻</span> Reiniciar
                    </button>
                </div>
            </div>
        `;
    } else if (gameType === 'secuencias') {
        gameHTML = `
            <div style="background: white; border-radius: 20px; padding: 20px; box-shadow: 0 5px 20px rgba(0,0,0,0.1); border: 2px solid ${colors.primary}20;">
                <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 20px;">
                    <div style="font-size: 40px; background: ${colors.primary}10; width: 60px; height: 60px; border-radius: 50%; display: flex; align-items: center; justify-content: center;">
                        🔄
                    </div>
                    <div>
                        <h3 style="font-size: 20px; margin: 0; color: ${colors.primary};">${game.title}</h3>
                        <span style="background: ${colors.primary}; color: white; padding: 2px 8px; border-radius: 12px; font-size: 12px;">Nivel 1</span>
                    </div>
                </div>

                <div class="sequence-container" id="sequenceContainer" style="margin: 20px 0;"></div>
                
                <div class="game-feedback" id="sequenceFeedback" style="text-align: center; min-height: 30px; margin-bottom: 15px;"></div>
                
                <div style="display: flex; gap: 10px; justify-content: center;">
                    <button class="btn btn-primary" onclick="startSequenceGame()" style="background: ${colors.primary}; padding: 8px 16px; font-size: 14px;">
                        <span>▶️</span> Mostrar
                    </button>
                    <button class="btn btn-secondary" onclick="resetSequenceGame()" style="padding: 8px 16px; font-size: 14px;">
                        <span>↻</span> Reiniciar
                    </button>
                </div>
            </div>
        `;
    } else {
        gameHTML = `
            <div style="background: white; border-radius: 20px; padding: 20px; box-shadow: 0 5px 20px rgba(0,0,0,0.1); border: 2px solid ${colors.primary}20;">
                <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 20px;">
                    <div style="font-size: 40px; background: ${colors.primary}10; width: 60px; height: 60px; border-radius: 50%; display: flex; align-items: center; justify-content: center;">
                        👀
                    </div>
                    <div>
                        <h3 style="font-size: 20px; margin: 0; color: ${colors.primary};">${game.title}</h3>
                        <span style="background: ${colors.primary}; color: white; padding: 2px 8px; border-radius: 12px; font-size: 12px;">9 objetos</span>
                    </div>
                </div>

                <div class="visual-memory-container" id="visualMemoryContainer" style="margin: 20px 0;"></div>
                
                <div class="game-feedback" id="visualMemoryFeedback" style="text-align: center; min-height: 30px; margin-bottom: 15px;"></div>
                
                <div style="display: flex; gap: 10px; justify-content: center;">
                    <button class="btn btn-primary" onclick="startVisualMemoryGame()" style="background: ${colors.primary}; padding: 8px 16px; font-size: 14px;">
                        <span>👀</span> Observar
                    </button>
                </div>
            </div>
        `;
    }

    gameContainer.innerHTML = gameHTML;
}

// Función  para actualizar el círculo de progreso
function updateProgressCircle(current, total) {
    const circle = document.getElementById('progressCircle');
    const text = document.getElementById('progressText');
    if (circle && text) {
        const circumference = 2 * Math.PI * 50;
        const offset = circumference - (current / total) * circumference;
        circle.style.strokeDashoffset = offset;
        text.textContent = `${current}/${total}`;
    }
}

// Función para crear mini confetti
function createMiniConfetti(color) {
    for (let i = 0; i < 15; i++) {
        const confetti = document.createElement('div');
        confetti.className = 'confetti-piece';
        confetti.style.left = Math.random() * 100 + '%';
        confetti.style.background = color;
        confetti.style.width = Math.random() * 8 + 4 + 'px';
        confetti.style.height = confetti.style.width;
        confetti.style.animationDelay = Math.random() * 0.5 + 's';
        document.body.appendChild(confetti);
        setTimeout(() => confetti.remove(), 3000);
    }
}

// Versión compacta del quiz
function loadQuizGame(game, activity, gameType) {
    const activityColors = {
        math: { primary: '#27AE60', secondary: '#2ECC71', accent: '#F1C40F' },
        grammar: { primary: '#3498DB', secondary: '#5DADE2', accent: '#F39C12' },
        geography: { primary: '#E67E22', secondary: '#F39C12', accent: '#27AE60' },
        art: { primary: '#E91E63', secondary: '#F06292', accent: '#FFB74D' },
        science: { primary: '#00BCD4', secondary: '#4DD0E1', accent: '#FFA000' },
        logic: { primary: '#9B59B6', secondary: '#AF7AC5', accent: '#F7DC6F' },
        english: { primary: '#FF6B6B', secondary: '#FF8E8E', accent: '#4ECDC4' }
    };

    const colors = activityColors[activity] || activityColors.math;
    const emoji = activities[activity]?.emoji || '🎮';
    const totalQuestions = game.questions ? game.questions.length : 5;

    // Estilos necesarios
    const gameStyles = `
        <style>
            @keyframes confettiRain {
                0% { transform: translateY(-10px) rotate(0deg); opacity: 1; }
                100% { transform: translateY(100vh) rotate(720deg); opacity: 0; }
            }
            .confetti-piece {
                position: fixed;
                width: 10px;
                height: 10px;
                pointer-events: none;
                z-index: 9999;
                animation: confettiRain 3s ease-out forwards;
            }
            .quiz-option {
                transition: all 0.2s ease;
                cursor: pointer;
            }
            .quiz-option:hover {
                transform: translateY(-2px);
                box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            }
            .progress-ring {
                transition: stroke-dashoffset 0.5s ease;
                transform: rotate(-90deg);
                transform-origin: 50% 50%;
            }
        </style>
    `;

    let gameHTML = gameStyles + `
        <div style="background: white; border-radius: 20px; padding: 20px; box-shadow: 0 5px 20px rgba(0,0,0,0.1); border: 2px solid ${colors.primary}20;">
            
            <!-- Cabecera compacta -->
            <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px; flex-wrap: wrap; gap: 10px;">
                <div style="display: flex; align-items: center; gap: 12px;">
                    <div style="font-size: 40px; background: ${colors.primary}10; width: 60px; height: 60px; border-radius: 50%; display: flex; align-items: center; justify-content: center;">
                        ${emoji}
                    </div>
                    <div>
                        <h3 style="font-size: 20px; margin: 0; color: ${colors.primary}; font-weight: bold;">
                            ${game.title}
                        </h3>
                        <div style="display: flex; gap: 8px; margin-top: 4px;">
                            <span style="background: ${colors.primary}; color: white; padding: 2px 8px; border-radius: 12px; font-size: 12px;">${totalQuestions} preg</span>
                            <span style="background: #FFD700; color: #333; padding: 2px 8px; border-radius: 12px; font-size: 12px;">⭐ +estrellas</span>
                        </div>
                    </div>
                </div>
                
                <!-- Progreso simple -->
                <div style="display: flex; align-items: center; gap: 10px;">
                    <div style="background: #f0f0f0; border-radius: 20px; padding: 8px 15px;">
                        <span style="font-weight: bold; color: ${colors.primary};">⭐ <span id="score">0</span></span>
                    </div>
                    <div style="width: 60px; height: 60px;">
                        <svg width="60" height="60" viewBox="0 0 120 120">
                            <circle cx="60" cy="60" r="50" fill="none" stroke="#E0E0E0" stroke-width="12"/>
                            <circle class="progress-ring" id="progressCircle" cx="60" cy="60" r="50" fill="none" stroke="${colors.primary}" stroke-width="12" stroke-dasharray="314" stroke-dashoffset="314"/>
                            <text x="60" y="70" text-anchor="middle" fill="${colors.primary}" font-size="20" font-weight="bold" id="progressText">0/${totalQuestions}</text>
                        </svg>
                    </div>
                </div>
            </div>
            
            <!-- Área de pregunta -->
            <div id="quizContainer">
                <div style="background: #f8f9fa; border-radius: 15px; padding: 20px; margin-bottom: 20px; border-left: 5px solid ${colors.primary};">
                    <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 10px;">
                        <span style="background: ${colors.primary}; color: white; width: 24px; height: 24px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 14px;">1</span>
                        <span style="color: #666;">Pregunta</span>
                    </div>
                    <div class="game-question" id="quizQuestion" style="font-size: 18px; font-weight: 500; color: #333; min-height: 50px;"></div>
                </div>
                
                <!-- Opciones -->
                <div style="margin-bottom: 20px;">
                    <p style="font-size: 14px; color: #666; margin-bottom: 10px;">🎯 Selecciona la respuesta:</p>
                    <div class="game-options" id="quizOptions" style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px;"></div>
                </div>
                
                <!-- Feedback -->
                <div class="game-feedback" id="quizFeedback" style="min-height: 40px; font-size: 16px; text-align: center; padding: 10px; border-radius: 10px; background: #f8f9fa; margin-bottom: 15px;"></div>
            </div>
            
            <!-- Botones -->
            <div style="display: flex; gap: 10px; justify-content: flex-end;">
                <button class="btn btn-primary" onclick="startQuiz('${activity}', '${gameType}')" style="background: ${colors.primary}; border: none; padding: 10px 20px; font-size: 14px; border-radius: 25px;">
                    <span>▶️</span> Empezar
                </button>
                <button class="btn btn-secondary" id="nextQuestionBtn" onclick="nextQuestion()" style="background: white; color: ${colors.primary}; border: 2px solid ${colors.primary}; padding: 10px 20px; font-size: 14px; border-radius: 25px;">
                    <span>⏭️</span> Siguiente
                </button>
            </div>
        </div>
    `;

    gameContainer.innerHTML = gameHTML;

    if (quizQuestions.length > 0 && currentQuestionIndex < quizQuestions.length) {
        setTimeout(() => showNextQuizQuestion(), 100);
    }
    updateProgressCircle(0, totalQuestions);
}


function showNextQuizQuestion() {
    if (currentQuestionIndex >= quizQuestions.length) {
        endQuiz();
        return;
    }

    const question = quizQuestions[currentQuestionIndex];
    const questionElement = document.getElementById('quizQuestion');
    const optionsContainer = document.getElementById('quizOptions');

    if (questionElement) questionElement.innerHTML = question.question;

    if (optionsContainer) {
        optionsContainer.innerHTML = '';
        question.options.forEach((option, index) => {
            const opt = document.createElement('div');
            opt.className = 'quiz-option';
            opt.innerHTML = option;
            opt.style.cssText = `
                padding: 12px 15px;
                border-radius: 10px;
                background: white;
                border: 2px solid var(--accent-blue);
                cursor: pointer;
                font-weight: 500;
                text-align: center;
                transition: all 0.2s ease;
            `;
            opt.onmouseover = () => {
                opt.style.background = 'var(--accent-blue)';
                opt.style.color = 'white';
                opt.style.borderColor = 'var(--accent-blue)';
            };
            opt.onmouseout = () => {
                if (!opt.classList.contains('selected')) {
                    opt.style.background = 'white';
                    opt.style.color = 'initial';
                    opt.style.borderColor = 'var(--accent-blue)';
                }
            };
            opt.onclick = () => checkAnswer(index);
            optionsContainer.appendChild(opt);
        });
    }

    document.getElementById('quizFeedback').innerHTML = '';
    document.getElementById('score').innerHTML = quizScore;
    updateProgressCircle(currentQuestionIndex, quizQuestions.length);
}
function checkAnswer(selectedIndex) {
    const question = quizQuestions[currentQuestionIndex];
    const feedback = document.getElementById('quizFeedback');
    const options = document.querySelectorAll('.quiz-option');

    options.forEach(opt => {
        opt.style.pointerEvents = 'none';
        opt.classList.add('selected');
    });

    if (selectedIndex === question.correct) {
        feedback.innerHTML = `<span style="color: #27AE60; font-weight: bold;">✅ ¡Correcto! +1 ⭐</span>`;
        quizScore++;
        options[selectedIndex].style.background = '#27AE60';
        options[selectedIndex].style.color = 'white';
        options[selectedIndex].style.borderColor = '#27AE60';
        createMiniConfetti('#27AE60');
        addStars(1);
    } else {
        feedback.innerHTML = `<span style="color: #E74C3C; font-weight: bold;">❌ Incorrecto</span>`;
        options[question.correct].style.background = '#27AE60';
        options[question.correct].style.color = 'white';
        options[question.correct].style.borderColor = '#27AE60';
        options[selectedIndex].style.background = '#E74C3C';
        options[selectedIndex].style.color = 'white';
        options[selectedIndex].style.borderColor = '#E74C3C';
    }

    document.getElementById('score').innerHTML = quizScore;
    updateProgressCircle(currentQuestionIndex + 1, quizQuestions.length);
}


function nextQuestion() {
    currentQuestionIndex++;
    if (currentQuestionIndex >= quizQuestions.length) {
        endQuiz();
    } else {
        showNextQuizQuestion();
    }
}

function endQuiz() {
    const percentage = (quizScore / quizQuestions.length) * 100;
    let message = '', emoji = '', color = '';

    if (percentage >= 80) {
        message = `🎉 ¡Excelente! ${quizScore}/${quizQuestions.length}`;
        emoji = '🏆';
        color = '#27AE60';
        perfectGamesCount++;
        createMiniConfetti('#F1C40F');
    } else if (percentage >= 60) {
        message = `👍 ¡Buen trabajo! ${quizScore}/${quizQuestions.length}`;
        emoji = '🌟';
        color = '#3498DB';
    } else {
        message = `💪 Sigue practicando: ${quizScore}/${quizQuestions.length}`;
        emoji = '📚';
        color = '#E67E22';
    }

    const quizContainer = document.getElementById('quizContainer');
    if (quizContainer) {
        quizContainer.innerHTML = `
            <div style="text-align: center; padding: 20px;">
                <div style="font-size: 50px; margin-bottom: 15px;">${emoji}</div>
                <h3 style="font-size: 22px; color: ${color}; margin-bottom: 10px;">¡Quiz Completado!</h3>
                <p style="font-size: 18px; margin-bottom: 15px;">${message}</p>
                <div style="font-size: 24px; margin: 15px 0;">${'⭐'.repeat(Math.floor(quizScore / 2))}</div>
            </div>
        `;
    }

    recordActivity(currentActivity, currentGameType, `${quizScore}/${quizQuestions.length} correctas`);
    checkAchievements();
}


function loadEnglishGame(game, gameType) {
    const englishColors = {
        vocabulario: { primary: '#FF6B6B', secondary: '#FF8E8E' },
        pronombres: { primary: '#4ECDC4', secondary: '#6CD4CE' },
        frases: { primary: '#FFB347', secondary: '#FFC107' },
        opuestos: { primary: '#9B59B6', secondary: '#AF7AC5' }
    };

    const colors = englishColors[gameType] || englishColors.vocabulario;

    let gameHTML = `
        <div style="background: white; border-radius: 20px; padding: 20px; box-shadow: 0 5px 20px rgba(0,0,0,0.1); border: 2px solid ${colors.primary}20;">
            
            <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 20px;">
                <div style="font-size: 40px; background: ${colors.primary}10; width: 60px; height: 60px; border-radius: 50%; display: flex; align-items: center; justify-content: center;">
                    🔤
                </div>
                <div>
                    <h3 style="font-size: 20px; margin: 0; color: ${colors.primary};">${game.title}</h3>
                    <span style="background: ${colors.primary}; color: white; padding: 2px 8px; border-radius: 12px; font-size: 12px;">${game.words ? game.words.length : 5} palabras</span>
                </div>
            </div>

            <div id="englishContainer">
                <div style="background: #f8f9fa; border-radius: 15px; padding: 20px; margin-bottom: 20px; border-left: 5px solid ${colors.primary};">
                    <div class="game-question" id="englishQuestion" style="font-size: 18px; font-weight: 500; min-height: 50px;"></div>
                </div>
                
                <div style="margin-bottom: 20px;">
                    <div class="game-options" id="englishOptions" style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px;"></div>
                </div>
                
                <div class="game-feedback" id="englishFeedback" style="min-height: 40px; font-size: 16px; text-align: center; padding: 10px; border-radius: 10px; background: #f8f9fa; margin-bottom: 15px;"></div>
            </div>
            
            <div style="display: flex; gap: 10px; justify-content: flex-end;">
                <button class="btn btn-primary" onclick="startEnglishGame('${gameType}')" style="background: ${colors.primary}; border: none; padding: 10px 20px; font-size: 14px; border-radius: 25px;">
                    <span>▶️</span> Empezar
                </button>
                <button class="btn btn-secondary" id="nextEnglishBtn" onclick="nextEnglishWord()" style="background: white; color: ${colors.primary}; border: 2px solid ${colors.primary}; padding: 10px 20px; font-size: 14px; border-radius: 25px;">
                    <span>⏭️</span> Siguiente
                </button>
            </div>
            
            <div style="margin-top: 15px; text-align: right;">
                <strong>Aciertos:</strong> <span id="englishScore" style="color: ${colors.primary};">0</span> / ${game.words ? game.words.length : 5}
            </div>
        </div>
    `;

    gameContainer.innerHTML = gameHTML;
}



let memoryCards = [];
let flippedCards = [];
let matchedPairs = 0;
let gameActive = false;

let sequence = [];
let playerSequence = [];
let sequenceLevel = 1;

let visualMemoryItems = [];
let visualMemoryChanged = [];

let quizQuestions = [];
let currentQuestionIndex = 0;
let quizScore = 0;

let englishWords = [];
let currentWordIndex = 0;
let englishScore = 0;


function setDifficulty(difficulty) {
    currentDifficulty = difficulty;
    document.querySelectorAll('.difficulty-btn').forEach(btn => btn.classList.remove('active'));
    event.target.classList.add('active');
}

function startMemoryGame() {
    const game = gameContent[currentActivity][currentGameType];
    const difficulty = game.difficulties[currentDifficulty];

    memoryCards = [];
    flippedCards = [];
    matchedPairs = 0;
    gameActive = true;

    const emojis = ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', '🦁', '🐮'];
    const selectedEmojis = emojis.slice(0, difficulty.pairs);
    let cards = [...selectedEmojis, ...selectedEmojis].sort(() => Math.random() - 0.5);

    const memoryGrid = document.getElementById('memoryGrid');
    memoryGrid.innerHTML = '';

    cards.forEach((emoji, index) => {
        const card = document.createElement('div');
        card.className = 'memory-card';
        card.dataset.index = index;
        card.dataset.value = emoji;
        card.innerHTML = '?';
        card.onclick = () => flipMemoryCard(card);
        memoryGrid.appendChild(card);
        memoryCards.push(card);
    });

    document.getElementById('memoryFeedback').innerHTML = '¡Encuentra todas las parejas!';
}

function flipMemoryCard(card) {
    if (!gameActive || flippedCards.length >= 2 || card.classList.contains('flipped') || card.classList.contains('matched')) return;

    card.classList.add('flipped');
    card.innerHTML = card.dataset.value;
    flippedCards.push(card);

    if (flippedCards.length === 2) checkMemoryMatch();
}

function checkMemoryMatch() {
    const [card1, card2] = flippedCards;

    if (card1.dataset.value === card2.dataset.value) {
        setTimeout(() => {
            card1.classList.add('matched');
            card2.classList.add('matched');
            flippedCards = [];
            matchedPairs++;

            const game = gameContent[currentActivity][currentGameType];
            const difficulty = game.difficulties[currentDifficulty];

            if (matchedPairs === difficulty.pairs) {
                document.getElementById('memoryFeedback').innerHTML = '<span class="game-correct">🎉 ¡Felicidades! ¡Completaste el juego!</span>';
                gameActive = false;
                addStars(2);
                perfectGamesCount++;
                recordActivity(currentActivity, currentGameType, 'completado');
                checkAchievements();
            }
        }, 500);
    } else {
        setTimeout(() => {
            card1.classList.remove('flipped');
            card2.classList.remove('flipped');
            card1.innerHTML = '?';
            card2.innerHTML = '?';
            flippedCards = [];
        }, 1000);
    }
}

function resetMemoryGame() {
    memoryCards.forEach(card => {
        card.classList.remove('flipped', 'matched');
        card.innerHTML = '?';
    });
    flippedCards = [];
    matchedPairs = 0;
    gameActive = true;
    document.getElementById('memoryFeedback').innerHTML = 'Juego reiniciado';
}


function startSequenceGame() {
    sequence = [];
    playerSequence = [];
    sequenceLevel = 1;
    generateSequence();
    showSequence();
}

function generateSequence() {
    const colors = ['🟥', '🟦', '🟩', '🟨', '🟪', '🟧'];
    for (let i = 0; i < sequenceLevel; i++) {
        sequence.push(colors[Math.floor(Math.random() * colors.length)]);
    }
}

function showSequence() {
    const sequenceContainer = document.getElementById('sequenceContainer');
    sequenceContainer.innerHTML = '';
    document.getElementById('sequenceFeedback').innerHTML = 'Observa la secuencia...';

    sequence.forEach((color, index) => {
        setTimeout(() => {
            sequenceContainer.innerHTML = `<div class="sequence-item">${color}</div>`;
        }, index * 800);
        setTimeout(() => {
            sequenceContainer.innerHTML = '';
        }, (index + 1) * 800);
    });

    setTimeout(() => {
        sequenceContainer.innerHTML = '';
        document.getElementById('sequenceFeedback').innerHTML = '¡Tu turno! Repite la secuencia';
        enableSequenceInput();
    }, sequence.length * 800 + 500);
}

function enableSequenceInput() {
    const colors = ['🟥', '🟦', '🟩', '🟨', '🟪', '🟧'];
    const sequenceContainer = document.getElementById('sequenceContainer');
    sequenceContainer.innerHTML = '';

    colors.forEach(color => {
        const item = document.createElement('div');
        item.className = 'sequence-item';
        item.innerHTML = color;
        item.onclick = () => addToPlayerSequence(color, item);
        sequenceContainer.appendChild(item);
    });
}

function addToPlayerSequence(color, element) {
    if (playerSequence.length >= sequence.length) return;

    playerSequence.push(color);
    element.style.transform = 'scale(0.9)';
    setTimeout(() => element.style.transform = 'scale(1)', 200);

    if (playerSequence.length === sequence.length) checkSequence();
}

function checkSequence() {
    const correct = sequence.every((color, index) => color === playerSequence[index]);

    if (correct) {
        document.getElementById('sequenceFeedback').innerHTML = '<span class="game-correct">✅ ¡Correcto! Nivel ' + sequenceLevel + ' completado</span>';
        setTimeout(() => {
            sequenceLevel++;
            playerSequence = [];
            generateSequence();
            showSequence();
            if (sequenceLevel > 1) addStars(1);
        }, 1500);
    } else {
        document.getElementById('sequenceFeedback').innerHTML = '<span class="game-incorrect">❌ Secuencia incorrecta. ¡Inténtalo de nuevo!</span>';
        setTimeout(() => {
            playerSequence = [];
            enableSequenceInput();
        }, 1500);
    }
}

function resetSequenceGame() {
    sequence = [];
    playerSequence = [];
    sequenceLevel = 1;
    document.getElementById('sequenceContainer').innerHTML = '';
    document.getElementById('sequenceFeedback').innerHTML = 'Juego reiniciado';
}


function startVisualMemoryGame() {
    visualMemoryItems = [];
    visualMemoryChanged = [];

    const container = document.getElementById('visualMemoryContainer');
    container.innerHTML = '';

    const emojis = ['⭐', '🎈', '🎯', '🎨', '🎪', '🎮', '🧩', '🎲', '🎳'];

    for (let i = 0; i < 9; i++) {
        const item = document.createElement('div');
        item.className = 'visual-item';
        item.innerHTML = emojis[i];
        item.dataset.index = i;
        container.appendChild(item);
        visualMemoryItems.push(item);
    }

    document.getElementById('visualMemoryFeedback').innerHTML = 'Observa bien los objetos...';
    setTimeout(() => changeVisualItems(), 5000);
}

function changeVisualItems() {
    const container = document.getElementById('visualMemoryContainer');
    container.innerHTML = '';

    const changeIndices = [];
    while (changeIndices.length < 3) {
        const idx = Math.floor(Math.random() * 9);
        if (!changeIndices.includes(idx)) {
            changeIndices.push(idx);
            visualMemoryChanged.push(idx);
        }
    }

    const newEmojis = ['🌟', '💥', '🎖️', '🖍️', '🎠', '👾', '🧠', '🎰', '🎯'];

    for (let i = 0; i < 9; i++) {
        const item = document.createElement('div');
        item.className = 'visual-item';
        item.innerHTML = changeIndices.includes(i) ? newEmojis[i] : visualMemoryItems[i].innerHTML;
        if (changeIndices.includes(i)) item.classList.add('changed');
        item.dataset.index = i;
        item.onclick = () => checkVisualItem(i, item);
        container.appendChild(item);
    }

    document.getElementById('visualMemoryFeedback').innerHTML = '¡Encuentra los 3 objetos que cambiaron!';
}

function checkVisualItem(index, element) {
    if (visualMemoryChanged.includes(index)) {
        element.style.background = 'var(--accent-green)';
        visualMemoryChanged = visualMemoryChanged.filter(i => i !== index);

        if (visualMemoryChanged.length === 0) {
            document.getElementById('visualMemoryFeedback').innerHTML = '<span class="game-correct">🎉 ¡Felicidades! Encontraste todos los cambios</span>';
            addStars(2);
            perfectGamesCount++;
            recordActivity(currentActivity, currentGameType, 'completado');
            checkAchievements();
        }
    } else {
        element.style.background = 'var(--accent-pink)';
        document.getElementById('visualMemoryFeedback').innerHTML = '<span class="game-incorrect">❌ Este no cambió, sigue buscando</span>';
        setTimeout(() => element.style.background = 'var(--accent-blue)', 1000);
    }
}


function startQuiz(activity, gameType) {
    const game = gameContent[activity][gameType];
    quizQuestions = game.questions ? [...game.questions] : [];

    if (quizQuestions.length === 0) {
        quizQuestions = generateGenericQuestions(activity, gameType);
    }

    currentQuestionIndex = 0;
    quizScore = 0;
    showNextQuizQuestion();
}

function generateGenericQuestions(activity, gameType) {
    const questions = [];
    for (let i = 0; i < 5; i++) {
        questions.push({
            question: `Pregunta ${i + 1} sobre ${activities[activity].title}`,
            options: ['Opción A', 'Opción B', 'Opción C', 'Opción D'],
            correct: Math.floor(Math.random() * 4)
        });
    }
    return questions;
}


function startEnglishGame(gameType) {
    const game = gameContent[currentActivity][gameType];

    switch (gameType) {
        case 'vocabulario':
        case 'pronombres':
        case 'frases':
            englishWords = game.words ? [...game.words] : [];
            break;
        case 'opuestos':
            englishWords = game.words ? [...game.words] : [];
            break;
    }

    if (englishWords.length === 0) {
        document.getElementById('englishContainer').innerHTML = '<p>No hay palabras disponibles para este juego</p>';
        return;
    }

    currentWordIndex = 0;
    englishScore = 0;
    showNextEnglishWord();
}

function showNextEnglishWord() {
    if (currentWordIndex >= englishWords.length) {
        endEnglishGame();
        return;
    }

    const word = englishWords[currentWordIndex];
    let questionText = '', options = [];

    if (word.spanish) {
        questionText = `¿Cómo se dice "${word.spanish}" en inglés?`;
        options = word.options;
    } else if (word.word) {
        questionText = `¿Cuál es el opuesto de "${word.word}"?`;
        options = word.options;
    }

    document.getElementById('englishQuestion').innerHTML = questionText;

    const optionsContainer = document.getElementById('englishOptions');
    optionsContainer.innerHTML = '';

    options.forEach((option, index) => {
        const opt = document.createElement('div');
        opt.className = 'game-option';
        opt.innerHTML = option;
        opt.style.cssText = 'padding: 12px 15px; border-radius: 10px; background: white; border: 2px solid var(--accent-blue); cursor: pointer; font-weight: 500; text-align: center; transition: all 0.2s ease;';
        opt.onmouseover = () => { opt.style.background = 'var(--accent-blue)'; opt.style.color = 'white'; };
        opt.onmouseout = () => { opt.style.background = 'white'; opt.style.color = 'initial'; };
        opt.onclick = () => checkEnglishAnswer(index, word);
        optionsContainer.appendChild(opt);
    });

    document.getElementById('englishFeedback').innerHTML = '';
    document.getElementById('englishScore').innerHTML = englishScore;
}

function checkEnglishAnswer(selectedIndex, word) {
    let correctIndex = 0;
    let correctAnswer = '';

    if (word.english) {
        correctAnswer = word.english;
        correctIndex = word.options.indexOf(word.english);
    } else if (word.opposite) {
        correctAnswer = word.opposite;
        correctIndex = word.options.indexOf(word.opposite);
    }

    const feedback = document.getElementById('englishFeedback');
    const options = document.querySelectorAll('#englishOptions .game-option');

    options.forEach(opt => opt.style.pointerEvents = 'none');

    if (selectedIndex === correctIndex) {
        feedback.innerHTML = `<span style="color: #27AE60; font-weight: bold;">✅ ¡Correcto! "${correctAnswer}"</span>`;
        englishScore++;
        addStars(1);
        options[selectedIndex].style.background = '#27AE60';
        options[selectedIndex].style.color = 'white';
        options[selectedIndex].style.borderColor = '#27AE60';
    } else {
        feedback.innerHTML = `<span style="color: #E74C3C; font-weight: bold;">❌ Incorrecto. La respuesta es: "${correctAnswer}"</span>`;
        options[correctIndex].style.background = '#27AE60';
        options[correctIndex].style.color = 'white';
        options[correctIndex].style.borderColor = '#27AE60';
        options[selectedIndex].style.background = '#E74C3C';
        options[selectedIndex].style.color = 'white';
        options[selectedIndex].style.borderColor = '#E74C3C';
    }

    document.getElementById('englishScore').innerHTML = englishScore;
    document.getElementById('nextEnglishBtn').style.background = '#27AE60';
    document.getElementById('nextEnglishBtn').style.color = 'white';
}

function resetEnglishNextButton() {
    const btn = document.getElementById('nextEnglishBtn');
    if (btn) {
        btn.style.background = '';
        btn.style.color = '';
    }
}

function nextEnglishWord() {
    resetEnglishNextButton();
    currentWordIndex++;
    if (currentWordIndex >= englishWords.length) {
        endEnglishGame();
    } else {
        showNextEnglishWord();
    }
}

function endEnglishGame() {
    const percentage = (englishScore / englishWords.length) * 100;
    let message = '';

    if (percentage >= 80) {
        message = `🎉 ¡Excelente inglés! ${englishScore}/${englishWords.length}`;
        perfectGamesCount++;
    } else if (percentage >= 60) {
        message = `👍 ¡Buen trabajo! ${englishScore}/${englishWords.length}`;
    } else {
        message = `💪 Sigue practicando: ${englishScore}/${englishWords.length}`;
    }

    document.getElementById('englishContainer').innerHTML = `
        <h3>Juego Completado!</h3>
        <p>${message}</p>
        <div style="font-size: 24px; margin: 20px 0;">${'⭐'.repeat(Math.floor(englishScore / 2))}</div>
    `;

    recordActivity(currentActivity, currentGameType, `${englishScore}/${englishWords.length} correctas`);
    checkAchievements();
}


function addStars(count) {
    if (!currentUser) return;

    currentUser.stars += count;

    const now = Date.now();
    if (lastStarTime && (now - lastStarTime) < 10 * 60 * 1000) {
        fastStarsCount++;
    } else {
        fastStarsCount = 1;
    }
    lastStarTime = now;

    saveUsers();
    updateCurrentUserDisplay();
    createStarAnimation(count);
    checkAchievements();
}

function createStarAnimation(count) {
    for (let i = 0; i < count; i++) {
        setTimeout(() => {
            const star = document.createElement('div');
            star.innerHTML = '⭐';
            star.style.position = 'fixed';
            star.style.fontSize = '30px';
            star.style.zIndex = '9999';
            star.style.left = '50%';
            star.style.top = '50%';
            star.style.transform = 'translate(-50%, -50%)';
            star.style.pointerEvents = 'none';
            document.body.appendChild(star);

            star.animate([
                { transform: 'translate(-50%, -50%) scale(0)', opacity: 0 },
                { transform: 'translate(-50%, -50%) scale(1.5)', opacity: 1 },
                { transform: 'translate(-50%, calc(-50% - 100px)) scale(1)', opacity: 0 }
            ], { duration: 1500, easing: 'cubic-bezier(0.1, 0.8, 0.2, 1)' })
                .onfinish = () => star.remove();
        }, i * 200);
    }
}

function addPlayTime(minutes) {
    if (!currentUser) return;
    currentUser.playTime += minutes;
    saveUsers();
    updateCurrentUserDisplay();
    checkAchievements();
}

function closeModals() {
    instructionsModal.style.display = 'none';
    gameModal.style.display = 'none';
    confirmationModal.style.display = 'none';
    achievementsModal.style.display = 'none';
    parentReportModal.style.display = 'none';
    achievementUnlocked.style.display = 'none';
}

function initializeApp() {
    initializeVoiceRecognition();
    showWelcomeScreen();
}

window.addEventListener('DOMContentLoaded', initializeApp);


activityCards.forEach(card => {
    card.addEventListener('click', () => showInstructions(card.dataset.target));
});

// Busca donde seleccionas la tarjeta (línea 3006 aprox)
const tarjetaEstudiante = document.querySelector('.student-profile-card');

if (tarjetaEstudiante) { // <--- ESTO EVITA EL ERROR NULL
    tarjetaEstudiante.addEventListener('click', () => {
        
        // 1. Aquí capturamos el ID para evitar el "undefined"
        const studentId = tarjetaEstudiante.getAttribute('data-id');
        
        // 2. Aquí armas tu URL de fetch para el login
        const url = `/api/estudiantes/${studentId}/login`; 
        
        // ... aquí sigue tu código de fetch() ...
    });
}
// Verificamos botón por botón antes de agregarle eventos (Protección anti-errores)
if (startGame) startGame.addEventListener('click', startGameFunction);
if (closeInstructions) closeInstructions.addEventListener('click', () => {
    if(instructionsModal) instructionsModal.style.display = 'none';
});
if (closeGame) closeGame.addEventListener('click', closeModals);
if (backToInstructions) backToInstructions.addEventListener('click', () => {
    if(gameModal) gameModal.style.display = 'none';
    if(instructionsModal) instructionsModal.style.display = 'flex';
});
if (backToMenu) backToMenu.addEventListener('click', closeModals);

// Protegemos los toggles de tema y audio por si no están en la pantalla actual
if (typeof darkModeToggle !== 'undefined' && darkModeToggle) {
    darkModeToggle.addEventListener('click', toggleDarkMode);
}
if (typeof audioToggle !== 'undefined' && audioToggle) {
    audioToggle.addEventListener('click', toggleAudio);
}
console.log({
  startGame,
  closeInstructions,
  closeGame,
  backToInstructions,
  backToMenu,
  darkModeToggle,
  audioToggle
});


function checkResponsive() {
    if (window.innerWidth <= 768) {
        toggleLayoutBtn.style.display = 'block';
        sidebar.classList.add('mobile-collapsed');
    } else {
        toggleLayoutBtn.style.display = 'none';
        sidebar.classList.remove('mobile-collapsed');
    }
}

// ========== INICIALIZACIÓN SEGURA DE EVENTOS ==========
window.addEventListener('DOMContentLoaded', () => {
    // 1. Escudo para tarjetas de actividades [cite: 563]
    const activityCards = document.querySelectorAll('.activity-card');
    if (activityCards.length > 0) {
        activityCards.forEach(card => {
            card.addEventListener('click', () => showInstructions(card.dataset.target));
        });
    }

    // 2. Escudo para controles del juego [cite: 567, 568, 569]
    if (getEl('startGame')) getEl('startGame').addEventListener('click', startGameFunction);
    if (getEl('closeInstructions')) getEl('closeInstructions').addEventListener('click', () => instructionsModal.style.display = 'none');
    if (getEl('closeGame')) getEl('closeGame').addEventListener('click', closeModals);
    
    if (getEl('backToInstructions')) {
        getEl('backToInstructions').addEventListener('click', () => {
            gameModal.style.display = 'none';
            instructionsModal.style.display = 'flex';
        });
    }

    if (getEl('backToMenu')) getEl('backToMenu').addEventListener('click', closeModals);
    if (getEl('darkModeToggle')) getEl('darkModeToggle').addEventListener('click', toggleDarkMode);
    if (getEl('audioToggle')) getEl('audioToggle').addEventListener('click', toggleAudio);

    // 3. Gestión de Voz [cite: 571]
    const vBtn = getEl('voiceBtn');
    if (vBtn) {
        vBtn.addEventListener('click', () => {
            if (!recognition) return;
            if (isListening) {
                recognition.stop();
                resetVoiceStatus();
            } else {
                try { recognition.start(); }
                catch (error) {
                    voiceStatus.textContent = "Error al iniciar reconocimiento";
                    setTimeout(resetVoiceStatus, 2000);
                }
            }
        });
    }

    // 4. Gestión de Usuarios y Pantalla de Bienvenida [cite: 572, 573, 574]
    if (getEl('startNewUserBtn')) {
        getEl('startNewUserBtn').addEventListener('click', () => {
            createNewUser();
            userManagementModal.style.display = 'flex';
            welcomeOverlay.style.display = 'none';
        });
    }

    if (getEl('playAsGuestBtn')) getEl('playAsGuestBtn').addEventListener('click', playWithoutUser);
    if (getEl('currentUserDisplay')) {
        getEl('currentUserDisplay').addEventListener('click', () => {
            renderUserList();
            userManagementModal.style.display = 'flex';
        });
    }

    if (getEl('createNewUserBtn')) getEl('createNewUserBtn').addEventListener('click', createNewUser);
    if (getEl('saveUser')) getEl('saveUser').addEventListener('click', saveUser);
    if (getEl('cancelEditBtn')) getEl('cancelEditBtn').addEventListener('click', cancelEditUser);
    if (getEl('logoutBtn')) getEl('logoutBtn').addEventListener('click', logout);
    if (getEl('continueWithoutUser')) getEl('continueWithoutUser').addEventListener('click', playWithoutUser);

    if (getEl('closeUserManagement')) {
        getEl('closeUserManagement').addEventListener('click', () => {
            if (currentUser) {
                userManagementModal.style.display = 'none';
            } else {
                userManagementModal.style.display = 'none';
                showWelcomeScreen();
            }
        });
    }

    // 5. Confirmaciones y Logros [cite: 575, 576, 577]
    if (getEl('confirmDeleteBtn')) getEl('confirmDeleteBtn').addEventListener('click', confirmDelete);
    if (getEl('cancelDeleteBtn')) {
        getEl('cancelDeleteBtn').addEventListener('click', () => {
            confirmationModal.style.display = 'none';
            userToDelete = null;
        });
    }

    if (getEl('viewAchievementsBtn')) getEl('viewAchievementsBtn').addEventListener('click', showAchievementsModal);
    if (getEl('closeAchievements')) getEl('closeAchievements').addEventListener('click', () => achievementsModal.style.display = 'none');
    if (getEl('closeAchievementsBtn')) getEl('closeAchievementsBtn').addEventListener('click', () => achievementsModal.style.display = 'none');
    if (getEl('closeUnlocked')) getEl('closeUnlocked').addEventListener('click', () => achievementUnlocked.style.display = 'none');

    // 6. Reporte para Padres e Interfaz [cite: 576, 577, 579, 580, 581]
    if (getEl('parentReportBtn')) getEl('parentReportBtn').addEventListener('click', showParentReport);
    if (getEl('closeParentReport')) getEl('closeParentReport').addEventListener('click', () => parentReportModal.style.display = 'none');
    if (getEl('closeReport')) getEl('closeReport').addEventListener('click', () => parentReportModal.style.display = 'none');
    if (getEl('printReport')) getEl('printReport').addEventListener('click', () => window.print());
    
    if (getEl('toggleLayoutBtn')) {
        getEl('toggleLayoutBtn').addEventListener('click', () => {
            const sidebar = document.querySelector('.sidebar');
            if (sidebar) {
                sidebar.classList.toggle('mobile-collapsed');
                getEl('toggleLayoutBtn').innerHTML = sidebar.classList.contains('mobile-collapsed')
                    ? '<span>📱</span> Vista Completa'
                    : '<span>📱</span> Vista Compacta';
            }
        });
    }

    // Inicializar app después de configurar eventos
    initializeApp();
});

// Función auxiliar para acortar el código
function getEl(id) {
    return document.getElementById(id);
};

// Función auxiliar para acortar el código
function getEl(id) {
    return document.getElementById(id);
};
// === SISTEMA DE ALERTAS MÁGICAS ===
function mostrarAlertaMagica(mensaje, emoji = "⚠️", colorBorde = "#FF6B6B") {
    // Si ya hay una alerta, la quitamos primero
    const alertaPrevia = document.getElementById('alertaMagicaOverlay');
    if (alertaPrevia) alertaPrevia.remove();

    // Creamos el fondo oscuro y borroso
    const overlay = document.createElement('div');
    overlay.id = 'alertaMagicaOverlay';
    overlay.className = 'custom-alert-overlay';
    
    // Armamos la caja
    overlay.innerHTML = `
        <div class="custom-alert-box" id="alertaMagicaBox" style="border-color: ${colorBorde};">
            <div class="custom-alert-icon">${emoji}</div>
            <h3 style="margin-bottom: 10px; font-size: 22px; color: ${colorBorde};">¡Ups!</h3>
            <p style="margin-bottom: 25px; font-size: 16px;">${mensaje}</p>
            <button class="ep-btn juicy-btn" onclick="cerrarAlertaMagica()" style="background: ${colorBorde}; color: white; padding: 12px 25px; margin: 0 auto; display: block; width: 80%;">
                ¡Entendido! 👍
            </button>
        </div>
    `;
    
    document.body.appendChild(overlay);

    // Activamos la animación un instante después de agregarla al DOM
    setTimeout(() => {
        overlay.classList.add('show');
        document.getElementById('alertaMagicaBox').classList.add('show');
    }, 10);
}

function cerrarAlertaMagica() {
    const overlay = document.getElementById('alertaMagicaOverlay');
    if (overlay) {
        overlay.classList.remove('show');
        document.getElementById('alertaMagicaBox').classList.remove('show');
        // Esperamos a que termine la animación de salida para borrarla
        setTimeout(() => overlay.remove(), 300);
    }
}