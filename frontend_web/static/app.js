// ========== ESTADO GLOBAL ==========
let darkMode = false;
let audioOn = true;
let recognition = null;
let isListening = false;

// ========== FUNCIONES DE LA UI GLOBAL ==========
function showInstructions(activityKey) {
    if (!currentUser) {
        alert('Primero debes seleccionar un usuario');
        return;
    }

    const activity = activities[activityKey];
    if (!activity) return;

    currentActivity = activityKey;
    
    const instTitle = document.getElementById('instructionsTitle');
    const instText = document.getElementById('instructionsText');
    const instModal = document.getElementById('instructionsModal');

    if (instTitle) instTitle.textContent = activity.title;
    
    if (instText) {
        instText.innerHTML = activity.instructions;
        if (activity.gameTypes && activity.gameTypes.length > 0) {
            instText.innerHTML += `
                <div class="game-types-container">
                    <h3>Selecciona un tipo de juego:</h3>
                    ${activity.gameTypes.map((type) => {
                        let displayName = type;
                        switch (type) {
                            case 'parejas': displayName = 'Memoria de Parejas'; break;
                            case 'secuencias': displayName = 'Memoria de Secuencias / Lógicas'; break;
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
                            case 'laberintos': displayName = 'Laberintos'; break;
                            case 'rompecabezas': displayName = 'Rompecabezas'; break;
                            case 'sudoku': displayName = 'Sudoku Infantil'; break;
                        }
                        return `<div class="game-type-option" onclick="if(typeof selectGameType === 'function') selectGameType('${type}')"><h4>${displayName}</h4><p>${getGameTypeDescription(activityKey, type)}</p></div>`;
                    }).join('')}
                </div>
            `;
        }
    }

    if (instModal) {
        instModal.style.display = 'flex';
    } else {
        console.error("Falta agregar el modal de instrucciones y juegos en el index.html");
    }
}

function getGameTypeDescription(activity, type) {
    const descriptions = {
        memory: { parejas: 'Encuentra todas las parejas de cartas iguales', secuencias: 'Memoriza y repite la secuencia de colores', visual: 'Encuentra los objetos que cambiaron de lugar' },
        math: { operaciones: 'Sumas, restas, multiplicaciones y divisiones', dinero: 'Aprende a contar y usar monedas', tiempo: 'Reloj, horas y minutos', fracciones: 'Partes de un todo de forma divertida' },
        grammar: { completar: 'Completa oraciones con palabras correctas', sinonimos: 'Encuentra palabras con significado similar', ordenar: 'Ordena palabras para formar oraciones', verbos: 'Identifica acciones en las oraciones' }
    };
    return descriptions[activity]?.[type] || '¡Divertido juego de aprendizaje!';
}

function closeModals() {
    const modals = [
        'instructionsModal', 'gameModal', 'confirmationModal', 
        'achievementsModal', 'parentReportModal', 'achievementUnlocked',
        'userManagementModal'
    ];
    modals.forEach(id => {
        const modal = document.getElementById(id);
        if(modal) modal.style.display = 'none';
    });
}

function initializeApp() {
    if(typeof initializeVoiceRecognition === 'function') initializeVoiceRecognition();
    if(typeof showWelcomeScreen === 'function') showWelcomeScreen();
}

function checkResponsive() {
    const toggleLayoutBtn = document.getElementById('toggleLayoutBtn');
    const sidebar = document.querySelector('.sidebar');
    if (!toggleLayoutBtn || !sidebar) return;
    if (window.innerWidth <= 768) {
        toggleLayoutBtn.style.display = 'block';
        sidebar.classList.add('mobile-collapsed');
    } else {
        toggleLayoutBtn.style.display = 'none';
        sidebar.classList.remove('mobile-collapsed');
    }
}

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
        particle.style.position = 'absolute';
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

// ========== RECONOCIMIENTO DE VOZ Y ACCIONES ==========
function initializeVoiceRecognition() {
    if ('webkitSpeechRecognition' in window || 'SpeechRecognition' in window) {
        const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
        recognition = new SpeechRecognition();
        recognition.continuous = false; recognition.lang = 'es-ES'; recognition.interimResults = false; recognition.maxAlternatives = 1;
        const voiceStatus = document.getElementById('voiceStatus');
        const voiceBtn = document.getElementById('voiceBtn');
        
        recognition.onstart = function () {
            isListening = true;
            if(voiceStatus) { voiceStatus.textContent = "Escuchando... 🎤"; voiceStatus.classList.add('voice-active'); }
            if(voiceBtn) voiceBtn.innerHTML = '<span>⏹️</span> Detener';
        };
        recognition.onresult = function (event) {
            const speechResult = event.results[0][0].transcript.toLowerCase();
            if(voiceStatus) voiceStatus.textContent = `Reconocido: "${speechResult}"`;
            handleVoiceCommand(speechResult); setTimeout(() => { resetVoiceStatus(); }, 3000);
        };
        recognition.onerror = function (event) {
            console.log('Error en reconocimiento de voz: ', event.error);
            if(voiceStatus) voiceStatus.textContent = "Error al escuchar. Intenta de nuevo.";
            setTimeout(() => { resetVoiceStatus(); }, 3000);
        };
        recognition.onend = function () {
            isListening = false;
            if (voiceStatus && voiceStatus.textContent === "Escuchando... 🎤") resetVoiceStatus();
        };
    } else {
        const voiceBtn = document.getElementById('voiceBtn');
        const voiceStatus = document.getElementById('voiceStatus');
        if(voiceBtn) { voiceBtn.innerHTML = '<span>🎤</span> No Soportado'; voiceBtn.disabled = true; }
        if(voiceStatus) voiceStatus.textContent = "Reconocimiento de voz no disponible en este navegador";
    }
}

function resetVoiceStatus() {
    const voiceStatus = document.getElementById('voiceStatus');
    const voiceBtn = document.getElementById('voiceBtn');
    if(voiceStatus){ voiceStatus.textContent = "Listo para escuchar..."; voiceStatus.classList.remove('voice-active'); }
    if(voiceBtn) voiceBtn.innerHTML = '<span>🎤</span> Activar Comandos';
    isListening = false;
}

function handleVoiceCommand(command) {
    if (command.includes('matemática') || command.includes('matemáticas') || command.includes('números')) showInstructions('math');
    else if (command.includes('memoria') || command.includes('recordar')) showInstructions('memory');
    else if (command.includes('gramática') || command.includes('español') || command.includes('palabras')) showInstructions('grammar');
    else if (command.includes('inglés') || command.includes('english') || command.includes('idioma')) showInstructions('english');
    else if (command.includes('geografía') || command.includes('países') || command.includes('mundial')) showInstructions('geography');
    else if (command.includes('arte') || command.includes('colores') || command.includes('pintura')) showInstructions('art');
    else if (command.includes('ciencia') || command.includes('experimento') || command.includes('animales')) showInstructions('science');
    else if (command.includes('lógica') || command.includes('puzzle') || command.includes('rompecabezas')) showInstructions('logic');
    else if (command.includes('oscuro') || command.includes('modo oscuro') || command.includes('noche')) toggleDarkMode();
    else if (command.includes('claro') || command.includes('modo claro') || command.includes('día')) { if (darkMode) toggleDarkMode(); }
    else if (command.includes('sonido') || command.includes('audio') || command.includes('silenciar')) toggleAudio();
    else if (command.includes('volver') || command.includes('menú') || command.includes('inicio')) closeModals();
    else if (command.includes('progreso') || command.includes('estrellas') || command.includes('puntaje')) alert(`Tienes ${currentUser ? currentUser.stars : 0} estrellas y ${currentUser ? currentUser.playTime : 0} minutos jugando!`);
    else if (command.includes('ayuda') || command.includes('instrucciones')) alert('Puedes decir: "Abrir matemáticas", "Jugar memoria", "Modo oscuro", "Apagar sonido", etc.');
    else if (command.includes('logros') || command.includes('trofeos') || command.includes('medallas')) { if(typeof showAchievementsModal === 'function') showAchievementsModal(); }
    else if (command.includes('informe') || command.includes('padres') || command.includes('reporte')) { if(typeof showParentReport === 'function') showParentReport(); }
    else {
        const voiceStatus = document.getElementById('voiceStatus');
        if(voiceStatus) voiceStatus.textContent = `Comando no reconocido: "${command}". Intenta decir "ayuda" para ver opciones.`;
    }
}

function toggleDarkMode() {
    darkMode = !darkMode;
    document.body.classList.toggle('dark-mode', darkMode);
    const darkModeToggle = document.getElementById('darkModeToggle');
    if(darkModeToggle) {
        const icon = darkModeToggle.querySelector('span');
        if(icon) icon.textContent = darkMode ? '☀️' : '🌙';
    }
    createConfetti();
}

function toggleAudio() {
    audioOn = !audioOn;
    const audioToggle = document.getElementById('audioToggle');
    if(audioToggle) {
        const icon = audioToggle.querySelector('span');
        const text = audioToggle.querySelector('span:last-child');
        if(icon && text) {
            if (audioOn) { icon.textContent = '🔊'; text.textContent = 'Sonido ON'; playSound('on'); }
            else { icon.textContent = '🔇'; text.textContent = 'Sonido OFF'; }
        }
    }
}

function playSound(type) { if (!audioOn) return; console.log(`Reproduciendo sonido: ${type}`); }

function createConfetti() {
    const colors = ['#FFD24C', '#FF7AB6', '#2F80ED', '#27AE60', '#9B51E0'];
    for (let i = 0; i < 30; i++) {
        const confetti = document.createElement('div');
        confetti.style.position = 'fixed'; confetti.style.width = '10px'; confetti.style.height = '10px'; confetti.style.background = colors[Math.floor(Math.random() * colors.length)]; confetti.style.borderRadius = '50%'; confetti.style.left = `${Math.random() * 100}vw`; confetti.style.top = '-10px'; confetti.style.zIndex = '9999';
        document.body.appendChild(confetti);
        confetti.animate([{ transform: 'translateY(0) rotate(0deg)', opacity: 1 }, { transform: `translateY(${window.innerHeight}px) rotate(${Math.random() * 360}deg)`, opacity: 0 }], { duration: 1000 + Math.random() * 2000, easing: 'cubic-bezier(0.1, 0.8, 0.2, 1)' }).onfinish = () => confetti.remove();
    }
}

// ==========================================
// DELEGACIÓN DE EVENTOS PRINCIPAL
// ==========================================
window.addEventListener('DOMContentLoaded', () => {
    initializeApp();

    // 1. Tarjetas de Actividades
    const tarjetasActividades = document.querySelectorAll('.activity-card');
    tarjetasActividades.forEach(card => {
        card.addEventListener('click', () => showInstructions(card.dataset.target));
    });

    // 2. Botones Globales (Con IFs de seguridad)
    const startGame = document.getElementById('startGame');
    if (startGame) {
        startGame.addEventListener('click', () => {
            if (typeof startGameFunction === 'function') startGameFunction();
        });
    }
    
    const closeInstructions = document.getElementById('closeInstructions');
    if (closeInstructions) {
        closeInstructions.addEventListener('click', () => {
            const instructionsModal = document.getElementById('instructionsModal');
            if (instructionsModal) instructionsModal.style.display = 'none';
        });
    }
    
    const closeGame = document.getElementById('closeGame');
    if (closeGame) closeGame.addEventListener('click', closeModals);
    
    const backToInstructions = document.getElementById('backToInstructions');
    if (backToInstructions) {
        backToInstructions.addEventListener('click', () => {
            const gameModal = document.getElementById('gameModal');
            const instructionsModal = document.getElementById('instructionsModal');
            if(gameModal) gameModal.style.display = 'none';
            if(instructionsModal) instructionsModal.style.display = 'flex';
        });
    }
    
    const backToMenu = document.getElementById('backToMenu');
    if (backToMenu) backToMenu.addEventListener('click', closeModals);

    const darkModeToggle = document.getElementById('darkModeToggle');
    if (darkModeToggle) darkModeToggle.addEventListener('click', toggleDarkMode);
    
    const audioToggle = document.getElementById('audioToggle');
    if (audioToggle) audioToggle.addEventListener('click', toggleAudio);
    
    const voiceBtn = document.getElementById('voiceBtn');
    if (voiceBtn) {
        voiceBtn.addEventListener('click', () => {
            if (!recognition) return;
            if (isListening) { recognition.stop(); resetVoiceStatus(); } 
            else { try { recognition.start(); } catch (error) { setTimeout(resetVoiceStatus, 2000); } }
        });
    }

    // 3. Botones UI Adicionales
    const startNewUserBtn = document.getElementById('startNewUserBtn');
    if (startNewUserBtn) {
        startNewUserBtn.addEventListener('click', () => {
            if(typeof createNewUser === 'function') createNewUser();
            const userManagementModal = document.getElementById('userManagementModal');
            const welcomeOverlay = document.getElementById('welcomeOverlay');
            if(userManagementModal) userManagementModal.style.display = 'flex';
            if(welcomeOverlay) welcomeOverlay.style.display = 'none';
        });
    }

    const playAsGuestBtn = document.getElementById('playAsGuestBtn');
    if (playAsGuestBtn) playAsGuestBtn.addEventListener('click', () => { if(typeof playWithoutUser === 'function') playWithoutUser(); });
    
    const currentUserDisplay = document.getElementById('currentUserDisplay');
    if (currentUserDisplay) {
        currentUserDisplay.addEventListener('click', () => {
            if(typeof renderUserList === 'function') renderUserList();
            const userManagementModal = document.getElementById('userManagementModal');
            if(userManagementModal) userManagementModal.style.display = 'flex';
        });
    }

    const createNewUserBtn = document.getElementById('createNewUser');
    if (createNewUserBtn) createNewUserBtn.addEventListener('click', () => { if(typeof createNewUser === 'function') createNewUser(); });
    
    const saveUserBtn = document.getElementById('saveUser');
    if (saveUserBtn) saveUserBtn.addEventListener('click', () => { if(typeof saveUser === 'function') saveUser(); });
    
    const cancelEditBtn = document.getElementById('cancelEdit');
    if (cancelEditBtn) cancelEditBtn.addEventListener('click', () => { if(typeof cancelEditUser === 'function') cancelEditUser(); });
    
    const logoutBtn = document.getElementById('logoutBtn');
    if (logoutBtn) logoutBtn.addEventListener('click', () => { if(typeof logout === 'function') logout(); });
    
    const continueWithoutUser = document.getElementById('continueWithoutUser');
    if (continueWithoutUser) continueWithoutUser.addEventListener('click', () => { if(typeof playWithoutUser === 'function') playWithoutUser(); });

    const closeUserManagement = document.getElementById('closeUserManagement');
    if (closeUserManagement) {
        closeUserManagement.addEventListener('click', () => {
            const userManagementModal = document.getElementById('userManagementModal');
            if(userManagementModal) userManagementModal.style.display = 'none';
            if (!currentUser && typeof showWelcomeScreen === 'function') showWelcomeScreen();
        });
    }

    const confirmDeleteBtn = document.getElementById('confirmDelete');
    if (confirmDeleteBtn) confirmDeleteBtn.addEventListener('click', () => { if(typeof confirmDelete === 'function') confirmDelete(); });
    
    const cancelDeleteBtn = document.getElementById('cancelDelete');
    if (cancelDeleteBtn) {
        cancelDeleteBtn.addEventListener('click', () => {
            const confirmationModal = document.getElementById('confirmationModal');
            if(confirmationModal) confirmationModal.style.display = 'none';
            userToDelete = null;
        });
    }

    const viewAchievementsBtn = document.getElementById('viewAchievementsBtn');
    if (viewAchievementsBtn) viewAchievementsBtn.addEventListener('click', () => { if(typeof showAchievementsModal === 'function') showAchievementsModal(); });
    
    const closeAchievements = document.getElementById('closeAchievements');
    if (closeAchievements) closeAchievements.addEventListener('click', () => {
        const achievementsModal = document.getElementById('achievementsModal');
        if(achievementsModal) achievementsModal.style.display = 'none';
    });
    
    const closeAchievementsBtn = document.getElementById('closeAchievementsBtn');
    if (closeAchievementsBtn) closeAchievementsBtn.addEventListener('click', () => {
        const achievementsModal = document.getElementById('achievementsModal');
        if(achievementsModal) achievementsModal.style.display = 'none';
    });
    
    const closeUnlocked = document.getElementById('closeUnlocked');
    if (closeUnlocked) closeUnlocked.addEventListener('click', () => {
        const achievementUnlocked = document.getElementById('achievementUnlocked');
        if(achievementUnlocked) achievementUnlocked.style.display = 'none';
    });

    const parentReportBtn = document.getElementById('parentReportBtn');
    if (parentReportBtn) parentReportBtn.addEventListener('click', () => { if(typeof showParentReport === 'function') showParentReport(); });
    
    const closeParentReport = document.getElementById('closeParentReport');
    if (closeParentReport) closeParentReport.addEventListener('click', () => {
        const parentReportModal = document.getElementById('parentReportModal');
        if(parentReportModal) parentReportModal.style.display = 'none';
    });
    
    const closeReport = document.getElementById('closeReport');
    if (closeReport) closeReport.addEventListener('click', () => {
        const parentReportModal = document.getElementById('parentReportModal');
        if(parentReportModal) parentReportModal.style.display = 'none';
    });
    
    const reportTabs = document.querySelectorAll('.report-tab');
    const reportTabContents = document.querySelectorAll('.report-tab-content');
    if (reportTabs) {
        reportTabs.forEach(tab => {
            tab.addEventListener('click', () => {
                const tabId = tab.dataset.tab;
                reportTabs.forEach(t => t.classList.remove('active'));
                reportTabContents.forEach(c => c.classList.remove('active'));
                tab.classList.add('active');
                const targetTab = document.getElementById(`${tabId}Tab`);
                if(targetTab) targetTab.classList.add('active');
            });
        });
    }

    const printReport = document.getElementById('printReport');
    if (printReport) printReport.addEventListener('click', () => window.print());
    
    const exportReport = document.getElementById('exportReport');
    if (exportReport) exportReport.addEventListener('click', () => alert('En una versión completa, esto exportaría el informe como PDF'));

    const toggleLayoutBtn = document.getElementById('toggleLayoutBtn');
    const sidebar = document.querySelector('.sidebar');
    if (toggleLayoutBtn && sidebar) {
        toggleLayoutBtn.addEventListener('click', () => {
            sidebar.classList.toggle('mobile-collapsed');
            toggleLayoutBtn.innerHTML = sidebar.classList.contains('mobile-collapsed') ? '<span>📱</span> Vista Completa' : '<span>📱</span> Vista Compacta';
        });
    }

    window.addEventListener('resize', checkResponsive);
    checkResponsive();

    // 4. Temporizador Global
    setInterval(() => {
        const gameModal = document.getElementById('gameModal');
        if (typeof gameModal !== 'undefined' && gameModal && gameModal.style.display === 'flex') {
            if(typeof addPlayTime === 'function') addPlayTime(0.1);
        }
    }, 60000);

    createParticles();
    setTimeout(() => { if (!currentUser) console.log('¡Bienvenido a EduPlay!'); }, 1000);
});