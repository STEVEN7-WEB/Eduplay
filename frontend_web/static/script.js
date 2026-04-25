// ========== SISTEMA DE LOGROS ==========

// Definición de logros disponibles
const achievementsList = [
    {
        id: 'first_star',
        name: 'Primera Estrella',
        description: 'Gana tu primera estrella',
        icon: '⭐',
        requirement: { type: 'stars', value: 1 },
        color: '#FFD24C'
    },
    {
        id: 'star_collector_10',
        name: 'Coleccionista de Estrellas',
        description: 'Consigue 10 estrellas',
        icon: '⭐⭐',
        requirement: { type: 'stars', value: 10 },
        color: '#FFB347'
    },
    {
        id: 'star_master_25',
        name: 'Maestro de Estrellas',
        description: 'Consigue 25 estrellas',
        icon: '⭐⭐⭐',
        requirement: { type: 'stars', value: 25 },
        color: '#FF8C42'
    },
    {
        id: 'time_explorer_15',
        name: 'Explorador del Tiempo',
        description: 'Juega 15 minutos',
        icon: '⏱️',
        requirement: { type: 'playTime', value: 15 },
        color: '#2F80ED'
    },
    {
        id: 'time_master_60',
        name: 'Maestro del Tiempo',
        description: 'Juega 60 minutos',
        icon: '⏰',
        requirement: { type: 'playTime', value: 60 },
        color: '#1A5FC1'
    },
    {
        id: 'math_whiz',
        name: 'Genio Matemático',
        description: 'Completa 5 juegos de matemáticas',
        icon: '🔢',
        requirement: { type: 'activity', value: { activity: 'math', count: 5 } },
        color: '#27AE60'
    },
    {
        id: 'memory_champion',
        name: 'Campeón de Memoria',
        description: 'Completa 5 juegos de memoria',
        icon: '🧠',
        requirement: { type: 'activity', value: { activity: 'memory', count: 5 } },
        color: '#9B51E0'
    },
    {
        id: 'language_expert',
        name: 'Experto en Idiomas',
        description: 'Completa juegos de gramática e inglés',
        icon: '🔤',
        requirement: {
            type: 'combined', value: [
                { activity: 'grammar', count: 3 },
                { activity: 'english', count: 3 }
            ]
        },
        color: '#3498DB'
    },
    {
        id: 'science_prodigy',
        name: 'Niño Prodigio de la Ciencia',
        description: 'Completa 3 juegos de ciencia',
        icon: '🔬',
        requirement: { type: 'activity', value: { activity: 'science', count: 3 } },
        color: '#E74C3C'
    },
    {
        id: 'art_artist',
        name: 'Pequeño Artista',
        description: 'Completa 3 juegos de arte',
        icon: '🎨',
        requirement: { type: 'activity', value: { activity: 'art', count: 3 } },
        color: '#FF7AB6'
    },
    {
        id: 'geography_explorer',
        name: 'Explorador Geográfico',
        description: 'Completa 3 juegos de geografía',
        icon: '🌎',
        requirement: { type: 'activity', value: { activity: 'geography', count: 3 } },
        color: '#2ECC71'
    },
    {
        id: 'logic_genius',
        name: 'Genio de la Lógica',
        description: 'Completa 3 juegos de lógica',
        icon: '🧩',
        requirement: { type: 'activity', value: { activity: 'logic', count: 3 } },
        color: '#F39C12'
    },
    {
        id: 'all_activities',
        name: 'Completista Total',
        description: 'Prueba todas las actividades al menos una vez',
        icon: '🏅',
        requirement: { type: 'all_activities', value: 8 },
        color: '#9B59B6'
    },
    {
        id: 'perfect_score',
        name: 'Puntuación Perfecta',
        description: 'Responde 10 preguntas correctamente sin errores',
        icon: '💯',
        requirement: { type: 'perfect_games', value: 10 },
        color: '#E91E63'
    },
    {
        id: 'fast_learner',
        name: 'Aprendiz Rápido',
        description: 'Gana 5 estrellas en 10 minutos',
        icon: '⚡',
        requirement: { type: 'fast_stars', value: 5 },
        color: '#00BCD4'
    }
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

    const unlocked = Object.keys(userAchievements)
        .filter(id => userAchievements[id].unlocked)
        .slice(0, 4); // Mostrar máximo 4 logros

    quickAchievements.innerHTML = '';

    unlocked.forEach(achievementId => {
        const achievement = achievementsList.find(a => a.id === achievementId);
        if (achievement) {
            const badge = document.createElement('div');
            badge.className = 'badge';
            badge.title = achievement.name;
            badge.innerHTML = achievement.icon;
            badge.style.background = achievement.color;
            quickAchievements.appendChild(badge);
        }
    });

    // Si no hay logros, mostrar placeholder
    if (unlocked.length === 0) {
        quickAchievements.innerHTML = `
            <div class="badge" style="background: var(--accent-blue)">⭐</div>
            <div class="badge" style="background: var(--accent-green)">⏱️</div>
            <div class="badge" style="background: var(--accent-purple)">🎮</div>
        `;
    }
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
function showWelcomeScreen() {
    loadUsers(); // Cargar usuarios existentes

    welcomeOverlay.style.display = 'flex';
    mainContainer.style.display = 'none';

    // Limpiar opciones anteriores
    welcomeOptions.innerHTML = '';
    welcomeButtons.style.display = 'flex';

    // Si hay usuarios registrados, mostrar opción para seleccionar uno
    if (users.length > 0) {
        const userSelectionList = document.createElement('div');
        userSelectionList.className = 'user-selection-list';

        const message = document.createElement('div');
        message.className = 'welcome-message';
        message.textContent = 'Selecciona un usuario existente para continuar:';
        welcomeOptions.appendChild(message);

        users.forEach(user => {
            const userItem = document.createElement('div');
            userItem.className = 'user-selection-item';
            userItem.innerHTML = `
                <div class="user-selection-avatar" style="background: ${getUserColor(user.id)}">
                    ${user.avatar}
                </div>
                <div class="user-selection-info">
                    <div class="user-selection-name">${user.name}</div>
                    <div class="user-selection-stats">${user.age} años | ${user.stars} ⭐ | ${user.playTime} min</div>
                </div>
            `;
            userItem.onclick = () => selectUserFromWelcome(user.id);
            userSelectionList.appendChild(userItem);
        });

        welcomeOptions.appendChild(userSelectionList);

        // También mostrar opción de crear nuevo usuario
        const orMessage = document.createElement('div');
        orMessage.className = 'welcome-message';
        orMessage.textContent = 'O si prefieres:';
        welcomeOptions.appendChild(orMessage);
    } else {
        // Si no hay usuarios, mostrar mensaje de bienvenida
        const message = document.createElement('div');
        message.className = 'welcome-message';
        message.textContent = '¡Bienvenido a EduPlay! Crea tu primer usuario para comenzar la aventura educativa.';
        welcomeOptions.appendChild(message);
    }
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


const gameContent = {
    // ========== MEMORIA ==========
    memory: {
        parejas: {
            title: "Memoria de Parejas",
            description: "Encuentra todas las parejas de cartas iguales",
            difficulties: {
                easy: { pairs: 6, grid: 'repeat(4, 1fr)' },
                medium: { pairs: 8, grid: 'repeat(4, 1fr)' },
                hard: { pairs: 12, grid: 'repeat(4, 1fr)' }
            }
        },
        secuencias: {
            title: "Memoria de Secuencias",
            description: "Memoriza y repite la secuencia de colores"
        },
        visual: {
            title: "Memoria Visual",
            description: "Encuentra los objetos que cambiaron de lugar"
        }
    },

    // ========== MATEMÁTICAS ==========
    math: {
        operaciones: {
            title: "Operaciones Básicas",
            questions: [
                { question: "15 + 8 = ?", options: ["22", "23", "24", "25"], correct: 1 },
                { question: "25 - 7 = ?", options: ["17", "18", "19", "20"], correct: 1 },
                { question: "6 × 4 = ?", options: ["20", "22", "24", "26"], correct: 2 },
                { question: "36 ÷ 6 = ?", options: ["5", "6", "7", "8"], correct: 1 },
                { question: "9 × 7 = ?", options: ["56", "63", "72", "81"], correct: 1 },
                { question: "48 ÷ 8 = ?", options: ["5", "6", "7", "8"], correct: 1 }
            ]
        },
        dinero: {
            title: "Matemáticas con Dinero",
            questions: [
                { question: "Si tengo 2 monedas de $10 y 3 de $5, ¿cuánto dinero tengo?", options: ["$25", "$30", "$35", "$40"], correct: 2 },
                { question: "Un helado cuesta $15, si pago con $20, ¿cuánto me devuelven?", options: ["$3", "$4", "$5", "$6"], correct: 2 },
                { question: "¿Cuánto es $50 - $28?", options: ["$20", "$22", "$24", "$26"], correct: 1 }
            ]
        },
        tiempo: {
            title: "Reloj y Tiempo",
            questions: [
                { question: "Si son las 3:30, ¿cuánto falta para las 4:00?", options: ["15 min", "20 min", "30 min", "45 min"], correct: 2 },
                { question: "¿Cuántos minutos tiene una hora?", options: ["50", "60", "70", "80"], correct: 1 },
                { question: "Si empezamos a las 2:15 y terminamos a las 3:00, ¿cuánto duró?", options: ["30 min", "45 min", "60 min", "75 min"], correct: 1 }
            ]
        },
        fracciones: {
            title: "Fracciones Divertidas",
            questions: [
                { question: "Si divido una pizza en 4 partes iguales, cada parte es:", options: ["1/2", "1/3", "1/4", "1/5"], correct: 2 },
                { question: "¿Cuánto es 1/2 + 1/2?", options: ["1/4", "1/2", "1", "2"], correct: 2 },
                { question: "Si tengo 3/4 de un pastel, ¿me falta?", options: ["1/8", "1/4", "1/3", "1/2"], correct: 1 }
            ]
        }
    },

    // ========== GRAMÁTICA ==========
    grammar: {
        completar: {
            title: "Completar Oraciones",
            questions: [
                { question: "Los niños ___ en el parque.", options: ["juega", "juegan", "juego", "jugamos"], correct: 1 },
                { question: "Mi hermana ___ muy inteligente.", options: ["es", "son", "está", "están"], correct: 0 },
                { question: "Nosotros ___ al cine los viernes.", options: ["vamos", "va", "van", "voy"], correct: 0 },
                { question: "Tú ___ muy rápido.", options: ["corres", "corre", "corro", "corren"], correct: 0 }
            ]
        },
        sinonimos: {
            title: "Sinónimos y Antónimos",
            questions: [
                { question: "Sinónimo de 'alegre':", options: ["feliz", "triste", "enojado", "serio"], correct: 0 },
                { question: "Antónimo de 'grande':", options: ["enorme", "pequeño", "mediano", "alto"], correct: 1 },
                { question: "Sinónimo de 'rápido':", options: ["lento", "veloz", "tranquilo", "calmado"], correct: 1 }
            ]
        },
        ordenar: {
            title: "Ordenar Palabras",
            questions: [
                { question: "Ordena: 'ella - parque - al - va'", options: ["Ella va al parque", "Al parque ella va", "Va ella al parque", "Parque al va ella"], correct: 0 },
                { question: "Ordena: 'libro - leo - yo - un'", options: ["Yo leo un libro", "Un libro yo leo", "Leo yo un libro", "Libro un leo yo"], correct: 0 }
            ]
        },
        verbos: {
            title: "Identificar Verbos",
            questions: [
                { question: "¿Cuál es el verbo en: 'El gato corre rápido'?", options: ["gato", "corre", "rápido", "el"], correct: 1 },
                { question: "¿Cuál es el verbo en: 'Nosotros comemos pizza'?", options: ["nosotros", "comemos", "pizza", "y"], correct: 1 }
            ]
        }
    },

    // ========== INGLÉS ==========
    english: {
        vocabulario: {
            title: "Vocabulario Básico",
            words: [
                { spanish: "casa", english: "House", options: ["House", "Car", "Tree", "Book"] },
                { spanish: "perro", english: "Dog", options: ["Cat", "Dog", "Bird", "Fish"] },
                { spanish: "sol", english: "Sun", options: ["Sun", "Moon", "Star", "Cloud"] },
                { spanish: "agua", english: "Water", options: ["Water", "Milk", "Juice", "Soda"] },
                { spanish: "escuela", english: "School", options: ["School", "House", "Park", "Store"] },
                { spanish: "familia", english: "Family", options: ["Family", "Friends", "Teachers", "Animals"] }
            ]
        },
        pronombres: {
            title: "Pronombres en Inglés",
            words: [
                { spanish: "yo", english: "I", options: ["I", "You", "He", "She"] },
                { spanish: "tú", english: "You", options: ["I", "You", "We", "They"] },
                { spanish: "él", english: "He", options: ["She", "He", "It", "They"] },
                { spanish: "ella", english: "She", options: ["He", "She", "It", "We"] },
                { spanish: "nosotros", english: "We", options: ["We", "They", "You", "I"] }
            ]
        },
        frases: {
            title: "Frases Útiles",
            words: [
                { spanish: "Buenos días", english: "Good morning", options: ["Good morning", "Good afternoon", "Good night", "Hello"] },
                { spanish: "¿Cómo estás?", english: "How are you?", options: ["How are you?", "What's your name?", "Where are you?", "How old are you?"] },
                { spanish: "Gracias", english: "Thank you", options: ["Thank you", "Please", "Sorry", "Welcome"] },
                { spanish: "Por favor", english: "Please", options: ["Please", "Thank you", "Sorry", "Hello"] }
            ]
        },
        opuestos: {
            title: "Opuestos en Inglés",
            words: [
                { word: "Big", opposite: "Small", options: ["Small", "Large", "Huge", "Tall"] },
                { word: "Hot", opposite: "Cold", options: ["Cold", "Warm", "Cool", "Freezing"] },
                { word: "Up", opposite: "Down", options: ["Down", "Left", "Right", "Above"] },
                { word: "Fast", opposite: "Slow", options: ["Slow", "Quick", "Rapid", "Swift"] }
            ]
        }
    },

    // ========== GEOGRAFÍA ==========
    geography: {
        paises: {
            title: "Países y Capitales",
            questions: [
                { question: "¿Cuál es la capital de México?", options: ["Guadalajara", "Monterrey", "Ciudad de México", "Puebla"], correct: 2 },
                { question: "¿Qué país tiene como capital París?", options: ["Italia", "Francia", "España", "Alemania"], correct: 1 },
                { question: "¿Cuál es la capital de Argentina?", options: ["Buenos Aires", "Santiago", "Lima", "Montevideo"], correct: 0 },
                { question: "¿Qué país tiene como capital Tokio?", options: ["China", "Corea", "Japón", "Tailandia"], correct: 2 }
            ]
        },
        banderas: {
            title: "Banderas del Mundo",
            questions: [
                { question: "¿Qué bandera tiene una hoja de maple?", options: ["Estados Unidos", "Canadá", "Australia", "Reino Unido"], correct: 1 },
                { question: "¿Qué bandera es roja con un círculo rojo?", options: ["China", "Japón", "Corea", "Vietnam"], correct: 1 },
                { question: "¿Qué bandera tiene estrellas en su escudo?", options: ["Estados Unidos", "Canadá", "Australia", "Reino Unido"], correct: 0 }
            ]
        },
        geografia: {
            title: "Accidentes Geográficos",
            questions: [
                { question: "¿Cuál es el río más largo del mundo?", options: ["Amazonas", "Nilo", "Misisipi", "Yangtsé"], correct: 0 },
                { question: "¿En qué continente está el desierto del Sahara?", options: ["Asia", "África", "América", "Australia"], correct: 1 },
                { question: "¿Qué montaña es la más alta del mundo?", options: ["Monte Everest", "K2", "Aconcagua", "Mont Blanc"], correct: 0 }
            ]
        },
        culturas: {
            title: "Culturas del Mundo",
            questions: [
                { question: "¿En qué país se originó la pizza?", options: ["Francia", "Italia", "España", "Grecia"], correct: 1 },
                { question: "¿Qué país es famoso por los samuráis?", options: ["China", "Japón", "Corea", "Tailandia"], correct: 1 },
                { question: "¿Dónde se encuentra la estatua de la Libertad?", options: ["Londres", "París", "Nueva York", "Roma"], correct: 2 }
            ]
        }
    },

    // ========== ARTE ==========
    art: {
        colores: {
            title: "Mezcla de Colores",
            questions: [
                { question: "¿Qué colores forman el naranja?", options: ["Rojo y azul", "Rojo y amarillo", "Azul y amarillo", "Verde y rojo"], correct: 1 },
                { question: "¿Qué color se obtiene mezclando azul y amarillo?", options: ["Verde", "Morado", "Naranja", "Rojo"], correct: 0 },
                { question: "¿Qué color se obtiene mezclando rojo y azul?", options: ["Verde", "Morado", "Naranja", "Amarillo"], correct: 1 }
            ]
        },
        reconocimiento: {
            title: "Reconocimiento de Colores",
            questions: [
                { question: "¿El verde es un color primario?", options: ["Sí", "No", "A veces", "Depende"], correct: 1 },
                { question: "¿Cuáles son los colores primarios?", options: ["Rojo, azul, amarillo", "Verde, naranja, morado", "Blanco, negro, gris", "Rosa, celeste, beige"], correct: 0 }
            ]
        },
        formas: {
            title: "Formas Geométricas",
            questions: [
                { question: "¿Qué figura tiene 4 lados iguales?", options: ["Triángulo", "Cuadrado", "Círculo", "Rectángulo"], correct: 1 },
                { question: "¿Cuántos lados tiene un triángulo?", options: ["3", "4", "5", "6"], correct: 0 },
                { question: "¿Qué figura no tiene lados?", options: ["Cuadrado", "Triángulo", "Círculo", "Rectángulo"], correct: 2 }
            ]
        },
        'arte-famoso': {
            title: "Arte Famoso",
            questions: [
                { question: "¿Quién pintó la Mona Lisa?", options: ["Picasso", "Van Gogh", "Da Vinci", "Monet"], correct: 2 },
                { question: "¿Qué artista cortó su propia oreja?", options: ["Picasso", "Van Gogh", "Da Vinci", "Monet"], correct: 1 }
            ]
        }
    },

    // ========== CIENCIA ==========
    science: {
        animales: {
            title: "Animales y Hábitat",
            questions: [
                { question: "¿Qué animal vive en el desierto?", options: ["Pingüino", "Camello", "Oso polar", "Mono"], correct: 1 },
                { question: "¿Qué animal es mamífero marino?", options: ["Tiburón", "Delfín", "Pulpo", "Medusa"], correct: 1 },
                { question: "¿Qué animal pone huevos?", options: ["Perro", "Gato", "Pájaro", "Ballena"], correct: 2 }
            ]
        },
        'cuerpo-humano': {
            title: "Cuerpo Humano",
            questions: [
                { question: "¿Qué órgano bombea la sangre?", options: ["Pulmón", "Corazón", "Estómago", "Cerebro"], correct: 1 },
                { question: "¿Cuántos huesos tiene el cuerpo humano aproximadamente?", options: ["106", "206", "306", "406"], correct: 1 },
                { question: "¿Qué sentido usamos para oler?", options: ["Vista", "Oído", "Olfato", "Gusto"], correct: 2 }
            ]
        },
        plantas: {
            title: "Plantas y Naturaleza",
            questions: [
                { question: "¿Qué necesitan las plantas para hacer fotosíntesis?", options: ["Agua y tierra", "Sol y agua", "Aire y sol", "Tierra y aire"], correct: 1 },
                { question: "¿Qué parte de la planta absorbe agua?", options: ["Hojas", "Flores", "Raíces", "Tallo"], correct: 2 }
            ]
        },
        experimentos: {
            title: "Experimentos Simples",
            questions: [
                { question: "¿Qué flota en el agua?", options: ["Piedra", "Llave", "Pelota", "Moneda"], correct: 2 },
                { question: "¿Qué se disuelve en agua?", options: ["Aceite", "Azúcar", "Arena", "Piedra"], correct: 1 },
                { question: "¿Qué atrae un imán?", options: ["Plástico", "Madera", "Metal", "Vidrio"], correct: 2 }
            ]
        }
    },

    // ========== LÓGICA ==========
    logic: {
        secuencias: {
            title: "Secuencias Lógicas",
            questions: [
                { question: "Completa: 2, 4, 6, ?", options: ["7", "8", "9", "10"], correct: 1 },
                { question: "Completa: A, C, E, ?", options: ["F", "G", "H", "I"], correct: 1 },
                { question: "Completa: 🟥, 🟦, 🟥, 🟦, ?", options: ["🟥", "🟦", "🟩", "🟨"], correct: 0 }
            ]
        },
        laberintos: {
            title: "Laberintos",
            description: "Encuentra el camino correcto para llegar al tesoro"
        },
        rompecabezas: {
            title: "Rompecabezas",
            description: "Arma la figura dividida en piezas"
        },
        sudoku: {
            title: "Sudoku Infantil",
            description: "Completa el tablero con números del 1 al 4"
        }
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

// Actualizar la visualización del usuario actual
function updateCurrentUserDisplay() {
    if (currentUser) {
        currentUserName.textContent = currentUser.name;
        currentUserAvatar.textContent = currentUser.avatar;
        // Generar color único para el avatar basado en el ID (no jala como pense)
        const colors = [
            '#2F80ED', '#F2994A', '#27AE60', '#FF7AB6',
            '#FFD24C', '#9B51E0', '#56CCF2', '#BB6BD9'
        ];
        currentUserAvatar.style.background = colors[currentUser.id % colors.length];

        // Actualizar estadísticas del sidebar
        starsCount.textContent = currentUser.stars;
        playTime.textContent = `${currentUser.playTime} min`;
        progressBar.style.width = `${Math.min((currentUser.stars / 100) * 100, 100)}%`;

        // Mostrar botón de cerrar sesión si hay usuario
        logoutBtn.style.display = 'flex';
    } else {
        currentUserName.textContent = 'Usuario';
        currentUserAvatar.textContent = 'U';
        currentUserAvatar.style.background = '#2F80ED';
        logoutBtn.style.display = 'none';
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
    userList.innerHTML = '';

    if (users.length === 0) {
        userList.innerHTML = `
            <div class="user-item" style="text-align: center; flex-direction: column; gap: 10px;">
                <div style="font-size: 40px; margin-bottom: 10px;">👤</div>
                <div class="user-info">
                    <div class="user-name">¡Bienvenido a EduPlay!</div>
                    <div class="user-stats">Crea tu primer usuario para empezar</div>
                </div>
                <div style="margin-top: 10px;">
                    <button class="btn btn-primary" onclick="createNewUser()" style="padding: 10px 20px;">
                        <span>➕</span> Crear Primer Usuario
                    </button>
                </div>
            </div>
        `;
        return;
    }

    users.forEach(user => {
        const isCurrent = currentUser && currentUser.id === user.id;
        const userItem = document.createElement('div');
        userItem.className = `user-item ${isCurrent ? 'active' : ''}`;
        userItem.innerHTML = `
            <div class="user-header">
                <div class="user-avatar" style="background: ${getUserColor(user.id)}">
                    ${user.avatar}
                </div>
                <div class="user-info">
                    <div class="user-name">${user.name}</div>
                    <div class="user-stats">${user.age} años | ${user.stars} ⭐ | ${user.playTime} min</div>
                </div>
            </div>
            <div class="user-actions">
                ${isCurrent ?
                '<span class="btn btn-secondary" style="padding: 5px 10px; font-size: 12px;">✓ Actual</span>' :
                `<button class="btn btn-secondary" onclick="selectUser(${user.id})" style="padding: 5px 10px; font-size: 12px;">
                                <span>👉</span> Seleccionar
                            </button>`
            }
                <button class="btn btn-secondary" onclick="editUser(${user.id})" style="padding: 5px 10px; font-size: 12px;">
                    <span>✏️</span> Editar
                </button>
                <button class="btn btn-danger" onclick="deleteUser(${user.id})" style="padding: 5px 10px; font-size: 12px;">
                    <span>🗑️</span> Eliminar
                </button>
            </div>
        `;
        userList.appendChild(userItem);
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
    instructionsTitle.textContent = activity.title;
    instructionsText.innerHTML = activity.instructions;

    // Si la actividad tiene tipos de juego, mostrarlos
    if (activity.gameTypes && activity.gameTypes.length > 0) {
        instructionsText.innerHTML += `
            <div class="game-types-container">
                <h3>Selecciona un tipo de juego:</h3>
                ${activity.gameTypes.map((type, index) => {
            let displayName = type;
            switch (type) {
                case 'parejas': displayName = 'Memoria de Parejas'; break;
                case 'secuencias': displayName = 'Memoria de Secuencias'; break;
                case 'visual': displayName = 'Memoria Visual'; break;
                case 'operaciones': displayName = 'Operaciones Básicas'; break;
                case 'dinero': displayName = 'Matemáticas con Dinero'; break;
                case 'tiempo': displayName = 'Reloj y Tiempo'; break;
                case 'fracciones': displayName = 'Fracciones Divertidas'; break;
                case 'completar': displayName = 'Completar Oraciones'; break;
                case 'sinonimos': displayName = 'Sinónimos y Antónimos'; break;
                case 'ordenar': displayName = 'Ordenar Palabras'; break;
                case 'verbos': displayName = 'Identificar Verbos'; break;
                case 'vocabulario': displayName = 'Vocabulario Básico'; break;
                case 'pronombres': displayName = 'Pronombres en Inglés'; break;
                case 'frases': displayName = 'Frases Útiles'; break;
                case 'opuestos': displayName = 'Opuestos en Inglés'; break;
                case 'paises': displayName = 'Países y Capitales'; break;
                case 'banderas': displayName = 'Banderas del Mundo'; break;
                case 'geografia': displayName = 'Accidentes Geográficos'; break;
                case 'culturas': displayName = 'Culturas del Mundo'; break;
                case 'colores': displayName = 'Mezcla de Colores'; break;
                case 'reconocimiento': displayName = 'Reconocimiento de Colores'; break;
                case 'formas': displayName = 'Formas Geométricas'; break;
                case 'arte-famoso': displayName = 'Arte Famoso'; break;
                case 'animales': displayName = 'Animales y Hábitat'; break;
                case 'cuerpo-humano': displayName = 'Cuerpo Humano'; break;
                case 'plantas': displayName = 'Plantas y Naturaleza'; break;
                case 'experimentos': displayName = 'Experimentos Simples'; break;
                case 'secuencias': displayName = 'Secuencias Lógicas'; break;
                case 'laberintos': displayName = 'Laberintos'; break;
                case 'rompecabezas': displayName = 'Rompecabezas'; break;
                case 'sudoku': displayName = 'Sudoku Infantil'; break;
            }
            return `
                                <div class="game-type-option" onclick="selectGameType('${type}')">
                                    <h4>${displayName}</h4>
                                    <p>${getGameTypeDescription(activityKey, type)}</p>
                                </div>
                            `;
        }).join('')}
            </div>
        `;
    }

    instructionsModal.style.display = 'flex';
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

startGame.addEventListener('click', startGameFunction);
closeInstructions.addEventListener('click', () => instructionsModal.style.display = 'none');
closeGame.addEventListener('click', closeModals);
backToInstructions.addEventListener('click', () => {
    gameModal.style.display = 'none';
    instructionsModal.style.display = 'flex';
});
backToMenu.addEventListener('click', closeModals);
darkModeToggle.addEventListener('click', toggleDarkMode);
audioToggle.addEventListener('click', toggleAudio);

voiceBtn.addEventListener('click', () => {
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

startNewUserBtn.addEventListener('click', () => {
    createNewUser();
    userManagementModal.style.display = 'flex';
    welcomeOverlay.style.display = 'none';
});

playAsGuestBtn.addEventListener('click', playWithoutUser);
currentUserDisplay.addEventListener('click', () => {
    renderUserList();
    userManagementModal.style.display = 'flex';
});

createNewUserBtn.addEventListener('click', createNewUser);
saveUserBtn.addEventListener('click', saveUser);
cancelEditBtn.addEventListener('click', cancelEditUser);
logoutBtn.addEventListener('click', logout);
document.getElementById('continueWithoutUser').addEventListener('click', playWithoutUser);

closeUserManagement.addEventListener('click', () => {
    if (currentUser) {
        userManagementModal.style.display = 'none';
    } else {
        userManagementModal.style.display = 'none';
        showWelcomeScreen();
    }
});

confirmDeleteBtn.addEventListener('click', confirmDelete);
cancelDeleteBtn.addEventListener('click', () => {
    confirmationModal.style.display = 'none';
    userToDelete = null;
});

viewAchievementsBtn.addEventListener('click', showAchievementsModal);
closeAchievements.addEventListener('click', () => achievementsModal.style.display = 'none');
closeAchievementsBtn.addEventListener('click', () => achievementsModal.style.display = 'none');
closeUnlocked.addEventListener('click', () => achievementUnlocked.style.display = 'none');

parentReportBtn.addEventListener('click', showParentReport);
closeParentReport.addEventListener('click', () => parentReportModal.style.display = 'none');
closeReport.addEventListener('click', () => parentReportModal.style.display = 'none');

reportTabs.forEach(tab => {
    tab.addEventListener('click', () => {
        const tabId = tab.dataset.tab;
        reportTabs.forEach(t => t.classList.remove('active'));
        reportTabContents.forEach(c => c.classList.remove('active'));
        tab.classList.add('active');
        document.getElementById(`${tabId}Tab`).classList.add('active');
    });
});

printReport.addEventListener('click', () => window.print());
exportReport.addEventListener('click', () => alert('En una versión completa, esto exportaría el informe como PDF'));

setInterval(() => {
    if (gameModal.style.display === 'flex') addPlayTime(0.1);
}, 60000);

const toggleLayoutBtn = document.getElementById('toggleLayoutBtn');
const sidebar = document.querySelector('.sidebar');

toggleLayoutBtn.addEventListener('click', () => {
    sidebar.classList.toggle('mobile-collapsed');
    toggleLayoutBtn.innerHTML = sidebar.classList.contains('mobile-collapsed')
        ? '<span>📱</span> Vista Completa'
        : '<span>📱</span> Vista Compacta';
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

window.addEventListener('resize', checkResponsive);
checkResponsive();


function createParticles() {
    const colors = ['#FFD24C', '#FF7AB6', '#2F80ED', '#27AE60', '#9B51E0'];
    for (let i = 0; i < 15; i++) {
        const particle = document.createElement('div');
        particle.className = 'particle';
        particle.style.width = `${Math.random() * 20 + 10}px`;
        particle.style.height = particle.style.width;
        particle.style.background = colors[Math.floor(Math.random() * colors.length)];
        particle.style.opacity = '0.3';
        particle.style.left = `${Math.random() * 100}%`;
        particle.style.top = `${Math.random() * 100}%`;
        document.body.appendChild(particle);

        particle.animate([
            { transform: 'translateY(0px)' },
            { transform: `translateY(${Math.random() * 100 - 50}px)` }
        ], {
            duration: 3000 + Math.random() * 4000,
            direction: 'alternate',
            iterations: Infinity,
            easing: 'ease-in-out'
        });
    }
}

createParticles();

setTimeout(() => {
    if (!currentUser) console.log('¡Bienvenido a EduPlay! Crea tu primer usuario para empezar.');
}, 1000);