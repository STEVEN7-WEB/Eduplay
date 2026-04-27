// ========== VARIABLES DE JUEGOS ==========
let currentActivity = null;
let currentGameType = null;
let currentDifficulty = 'easy';
let stars = 0;
let playTimeMinutes = 0;

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

// ========== LÓGICA DE JUEGOS ==========
function selectGameType(gameType) {
    currentGameType = gameType;
    const startGame = document.getElementById('startGame');
    if(startGame) startGame.click();
}

function startGameFunction() {
    if (!currentActivity) return;
    const activity = activities[currentActivity];
    const gameEmoji = document.getElementById('gameEmoji');
    const gameTitle = document.getElementById('gameTitle');
    const instructionsModal = document.getElementById('instructionsModal');
    const gameModal = document.getElementById('gameModal');
    
    if(gameEmoji) gameEmoji.textContent = activity.emoji;
    if(gameTitle) gameTitle.textContent = activity.title;
    if(instructionsModal) instructionsModal.style.display = 'none';
    if(gameModal) gameModal.style.display = 'flex';
    loadGame(currentActivity, currentGameType);
}

function loadGame(activity, gameType) {
    const gameContainer = document.getElementById('gameContainer');
    if(!gameContainer) return;
    
    if (!gameContent[activity] || !gameContent[activity][gameType]) {
        gameContainer.innerHTML = '<p>Juego no disponible</p>';
        return;
    }
    const game = gameContent[activity][gameType];
    if (activityCounts[activity] === undefined) activityCounts[activity] = 0;
    activityCounts[activity]++;

    switch (activity) {
        case 'memory': loadMemoryGame(game, gameType); break;
        case 'math': case 'grammar': case 'geography': case 'art': case 'science': case 'logic': loadQuizGame(game, activity, gameType); break;
        case 'english': loadEnglishGame(game, gameType); break;
        default: gameContainer.innerHTML = `<p>Juego en desarrollo: ${game.title}</p>`;
    }
}

function loadMemoryGame(game, gameType) {
    const colors = { primary: gameType === 'parejas' ? '#9B51E0' : gameType === 'secuencias' ? '#F39C12' : '#00BCD4' };
    const gameContainer = document.getElementById('gameContainer');
    let gameHTML = '';

    if (gameType === 'parejas') {
        gameHTML = `
            <div style="background: white; border-radius: 20px; padding: 20px; box-shadow: 0 5px 20px rgba(0,0,0,0.1); border: 2px solid ${colors.primary}20;">
                <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 20px;">
                    <div style="font-size: 40px; background: ${colors.primary}10; width: 60px; height: 60px; border-radius: 50%; display: flex; align-items: center; justify-content: center;">🧠</div>
                    <div><h3 style="font-size: 20px; margin: 0; color: ${colors.primary};">${game.title}</h3><span style="background: ${colors.primary}; color: white; padding: 2px 8px; border-radius: 12px; font-size: 12px;">${game.difficulties[currentDifficulty].pairs} pares</span></div>
                </div>
                <div class="difficulty-selector" style="display: flex; gap: 8px; margin-bottom: 20px; justify-content: center;">
                    <button class="difficulty-btn ${currentDifficulty === 'easy' ? 'active' : ''}" onclick="setDifficulty('easy')" style="padding: 6px 12px; font-size: 13px;">Fácil</button>
                    <button class="difficulty-btn ${currentDifficulty === 'medium' ? 'active' : ''}" onclick="setDifficulty('medium')" style="padding: 6px 12px; font-size: 13px;">Medio</button>
                    <button class="difficulty-btn ${currentDifficulty === 'hard' ? 'active' : ''}" onclick="setDifficulty('hard')" style="padding: 6px 12px; font-size: 13px;">Difícil</button>
                </div>
                <div class="memory-grid" id="memoryGrid" style="grid-template-columns: ${game.difficulties[currentDifficulty].grid}; gap: 8px; margin-bottom: 20px;"></div>
                <div class="game-feedback" id="memoryFeedback" style="text-align: center; min-height: 30px; margin-bottom: 15px;"></div>
                <div style="display: flex; gap: 10px; justify-content: center;">
                    <button class="btn btn-primary" onclick="startMemoryGame()" style="background: ${colors.primary}; padding: 8px 16px; font-size: 14px;"><span>🔄</span> Empezar</button>
                    <button class="btn btn-secondary" onclick="resetMemoryGame()" style="padding: 8px 16px; font-size: 14px;"><span>↻</span> Reiniciar</button>
                </div>
            </div>
        `;
    } else if (gameType === 'secuencias') {
        gameHTML = `
            <div style="background: white; border-radius: 20px; padding: 20px; box-shadow: 0 5px 20px rgba(0,0,0,0.1); border: 2px solid ${colors.primary}20;">
                <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 20px;">
                    <div style="font-size: 40px; background: ${colors.primary}10; width: 60px; height: 60px; border-radius: 50%; display: flex; align-items: center; justify-content: center;">🔄</div>
                    <div><h3 style="font-size: 20px; margin: 0; color: ${colors.primary};">${game.title}</h3><span style="background: ${colors.primary}; color: white; padding: 2px 8px; border-radius: 12px; font-size: 12px;">Nivel 1</span></div>
                </div>
                <div class="sequence-container" id="sequenceContainer" style="margin: 20px 0;"></div>
                <div class="game-feedback" id="sequenceFeedback" style="text-align: center; min-height: 30px; margin-bottom: 15px;"></div>
                <div style="display: flex; gap: 10px; justify-content: center;">
                    <button class="btn btn-primary" onclick="startSequenceGame()" style="background: ${colors.primary}; padding: 8px 16px; font-size: 14px;"><span>▶️</span> Mostrar</button>
                    <button class="btn btn-secondary" onclick="resetSequenceGame()" style="padding: 8px 16px; font-size: 14px;"><span>↻</span> Reiniciar</button>
                </div>
            </div>
        `;
    } else {
        gameHTML = `
            <div style="background: white; border-radius: 20px; padding: 20px; box-shadow: 0 5px 20px rgba(0,0,0,0.1); border: 2px solid ${colors.primary}20;">
                <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 20px;">
                    <div style="font-size: 40px; background: ${colors.primary}10; width: 60px; height: 60px; border-radius: 50%; display: flex; align-items: center; justify-content: center;">👀</div>
                    <div><h3 style="font-size: 20px; margin: 0; color: ${colors.primary};">${game.title}</h3><span style="background: ${colors.primary}; color: white; padding: 2px 8px; border-radius: 12px; font-size: 12px;">9 objetos</span></div>
                </div>
                <div class="visual-memory-container" id="visualMemoryContainer" style="margin: 20px 0;"></div>
                <div class="game-feedback" id="visualMemoryFeedback" style="text-align: center; min-height: 30px; margin-bottom: 15px;"></div>
                <div style="display: flex; gap: 10px; justify-content: center;">
                    <button class="btn btn-primary" onclick="startVisualMemoryGame()" style="background: ${colors.primary}; padding: 8px 16px; font-size: 14px;"><span>👀</span> Observar</button>
                </div>
            </div>
        `;
    }
    if(gameContainer) gameContainer.innerHTML = gameHTML;
}

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

function loadQuizGame(game, activity, gameType) {
    const activityColors = { math: { primary: '#27AE60' }, grammar: { primary: '#3498DB' }, geography: { primary: '#E67E22' }, art: { primary: '#E91E63' }, science: { primary: '#00BCD4' }, logic: { primary: '#9B59B6' }, english: { primary: '#FF6B6B' } };
    const colors = activityColors[activity] || activityColors.math;
    const emoji = activities[activity]?.emoji || '🎮';
    const totalQuestions = game.questions ? game.questions.length : 5;
    const gameContainer = document.getElementById('gameContainer');

    let gameHTML = `
        <style>
            @keyframes confettiRain { 0% { transform: translateY(-10px) rotate(0deg); opacity: 1; } 100% { transform: translateY(100vh) rotate(720deg); opacity: 0; } }
            .confetti-piece { position: fixed; width: 10px; height: 10px; pointer-events: none; z-index: 9999; animation: confettiRain 3s ease-out forwards; }
            .quiz-option { transition: all 0.2s ease; cursor: pointer; }
            .quiz-option:hover { transform: translateY(-2px); box-shadow: 0 5px 15px rgba(0,0,0,0.1); }
            .progress-ring { transition: stroke-dashoffset 0.5s ease; transform: rotate(-90deg); transform-origin: 50% 50%; }
        </style>
        <div style="background: white; border-radius: 20px; padding: 20px; box-shadow: 0 5px 20px rgba(0,0,0,0.1); border: 2px solid ${colors.primary}20;">
            <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px; flex-wrap: wrap; gap: 10px;">
                <div style="display: flex; align-items: center; gap: 12px;">
                    <div style="font-size: 40px; background: ${colors.primary}10; width: 60px; height: 60px; border-radius: 50%; display: flex; align-items: center; justify-content: center;">${emoji}</div>
                    <div><h3 style="font-size: 20px; margin: 0; color: ${colors.primary}; font-weight: bold;">${game.title}</h3>
                        <div style="display: flex; gap: 8px; margin-top: 4px;"><span style="background: ${colors.primary}; color: white; padding: 2px 8px; border-radius: 12px; font-size: 12px;">${totalQuestions} preg</span><span style="background: #FFD700; color: #333; padding: 2px 8px; border-radius: 12px; font-size: 12px;">⭐ +estrellas</span></div>
                    </div>
                </div>
                <div style="display: flex; align-items: center; gap: 10px;">
                    <div style="background: #f0f0f0; border-radius: 20px; padding: 8px 15px;"><span style="font-weight: bold; color: ${colors.primary};">⭐ <span id="score">0</span></span></div>
                    <div style="width: 60px; height: 60px;">
                        <svg width="60" height="60" viewBox="0 0 120 120">
                            <circle cx="60" cy="60" r="50" fill="none" stroke="#E0E0E0" stroke-width="12"/>
                            <circle class="progress-ring" id="progressCircle" cx="60" cy="60" r="50" fill="none" stroke="${colors.primary}" stroke-width="12" stroke-dasharray="314" stroke-dashoffset="314"/>
                            <text x="60" y="70" text-anchor="middle" fill="${colors.primary}" font-size="20" font-weight="bold" id="progressText">0/${totalQuestions}</text>
                        </svg>
                    </div>
                </div>
            </div>
            <div id="quizContainer">
                <div style="background: #f8f9fa; border-radius: 15px; padding: 20px; margin-bottom: 20px; border-left: 5px solid ${colors.primary};">
                    <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 10px;"><span style="background: ${colors.primary}; color: white; width: 24px; height: 24px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 14px;">1</span><span style="color: #666;">Pregunta</span></div>
                    <div class="game-question" id="quizQuestion" style="font-size: 18px; font-weight: 500; color: #333; min-height: 50px;"></div>
                </div>
                <div style="margin-bottom: 20px;"><p style="font-size: 14px; color: #666; margin-bottom: 10px;">🎯 Selecciona la respuesta:</p><div class="game-options" id="quizOptions" style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px;"></div></div>
                <div class="game-feedback" id="quizFeedback" style="min-height: 40px; font-size: 16px; text-align: center; padding: 10px; border-radius: 10px; background: #f8f9fa; margin-bottom: 15px;"></div>
            </div>
            <div style="display: flex; gap: 10px; justify-content: flex-end;">
                <button class="btn btn-primary" onclick="startQuiz('${activity}', '${gameType}')" style="background: ${colors.primary}; border: none; padding: 10px 20px; font-size: 14px; border-radius: 25px;"><span>▶️</span> Empezar</button>
                <button class="btn btn-secondary" id="nextQuestionBtn" onclick="nextQuestion()" style="background: white; color: ${colors.primary}; border: 2px solid ${colors.primary}; padding: 10px 20px; font-size: 14px; border-radius: 25px;"><span>⏭️</span> Siguiente</button>
            </div>
        </div>
    `;
    if(gameContainer) gameContainer.innerHTML = gameHTML;
    if (quizQuestions.length > 0 && currentQuestionIndex < quizQuestions.length) setTimeout(() => showNextQuizQuestion(), 100);
    updateProgressCircle(0, totalQuestions);
}

function showNextQuizQuestion() {
    if (currentQuestionIndex >= quizQuestions.length) return endQuiz();
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
            opt.style.cssText = 'padding: 12px 15px; border-radius: 10px; background: white; border: 2px solid var(--accent-blue); cursor: pointer; font-weight: 500; text-align: center; transition: all 0.2s ease;';
            opt.onmouseover = () => { opt.style.background = 'var(--accent-blue)'; opt.style.color = 'white'; opt.style.borderColor = 'var(--accent-blue)'; };
            opt.onmouseout = () => { if (!opt.classList.contains('selected')) { opt.style.background = 'white'; opt.style.color = 'initial'; opt.style.borderColor = 'var(--accent-blue)'; } };
            opt.onclick = () => checkAnswer(index);
            optionsContainer.appendChild(opt);
        });
    }
    const feedback = document.getElementById('quizFeedback');
    const score = document.getElementById('score');
    if(feedback) feedback.innerHTML = '';
    if(score) score.innerHTML = quizScore;
    updateProgressCircle(currentQuestionIndex, quizQuestions.length);
}

function checkAnswer(selectedIndex) {
    const question = quizQuestions[currentQuestionIndex];
    const feedback = document.getElementById('quizFeedback');
    const options = document.querySelectorAll('.quiz-option');
    options.forEach(opt => { opt.style.pointerEvents = 'none'; opt.classList.add('selected'); });
    
    if (selectedIndex === question.correct) {
        if(feedback) feedback.innerHTML = `<span style="color: #27AE60; font-weight: bold;">✅ ¡Correcto! +1 ⭐</span>`;
        quizScore++;
        options[selectedIndex].style.background = '#27AE60'; options[selectedIndex].style.color = 'white'; options[selectedIndex].style.borderColor = '#27AE60';
        createMiniConfetti('#27AE60');
        if(typeof addStars === 'function') addStars(1);
    } else {
        if(feedback) feedback.innerHTML = `<span style="color: #E74C3C; font-weight: bold;">❌ Incorrecto</span>`;
        options[question.correct].style.background = '#27AE60'; options[question.correct].style.color = 'white'; options[question.correct].style.borderColor = '#27AE60';
        options[selectedIndex].style.background = '#E74C3C'; options[selectedIndex].style.color = 'white'; options[selectedIndex].style.borderColor = '#E74C3C';
    }
    const score = document.getElementById('score');
    if(score) score.innerHTML = quizScore;
    updateProgressCircle(currentQuestionIndex + 1, quizQuestions.length);
}

function nextQuestion() { currentQuestionIndex++; if (currentQuestionIndex >= quizQuestions.length) endQuiz(); else showNextQuizQuestion(); }

function endQuiz() {
    const percentage = (quizScore / quizQuestions.length) * 100;
    let message = '', emoji = '', color = '';
    if (percentage >= 80) { message = `🎉 ¡Excelente! ${quizScore}/${quizQuestions.length}`; emoji = '🏆'; color = '#27AE60'; perfectGamesCount++; createMiniConfetti('#F1C40F'); }
    else if (percentage >= 60) { message = `👍 ¡Buen trabajo! ${quizScore}/${quizQuestions.length}`; emoji = '🌟'; color = '#3498DB'; }
    else { message = `💪 Sigue practicando: ${quizScore}/${quizQuestions.length}`; emoji = '📚'; color = '#E67E22'; }

    const quizContainer = document.getElementById('quizContainer');
    if (quizContainer) {
        quizContainer.innerHTML = `<div style="text-align: center; padding: 20px;"><div style="font-size: 50px; margin-bottom: 15px;">${emoji}</div><h3 style="font-size: 22px; color: ${color}; margin-bottom: 10px;">¡Quiz Completado!</h3><p style="font-size: 18px; margin-bottom: 15px;">${message}</p><div style="font-size: 24px; margin: 15px 0;">${'⭐'.repeat(Math.floor(quizScore / 2))}</div></div>`;
    }
    if(typeof recordActivity === 'function') recordActivity(currentActivity, currentGameType, `${quizScore}/${quizQuestions.length} correctas`);
    if(typeof checkAchievements === 'function') checkAchievements();
}

function loadEnglishGame(game, gameType) {
    const colors = { primary: '#FF6B6B' };
    const gameContainer = document.getElementById('gameContainer');
    let gameHTML = `
        <div style="background: white; border-radius: 20px; padding: 20px; box-shadow: 0 5px 20px rgba(0,0,0,0.1); border: 2px solid ${colors.primary}20;">
            <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 20px;">
                <div style="font-size: 40px; background: ${colors.primary}10; width: 60px; height: 60px; border-radius: 50%; display: flex; align-items: center; justify-content: center;">🔤</div>
                <div><h3 style="font-size: 20px; margin: 0; color: ${colors.primary};">${game.title}</h3><span style="background: ${colors.primary}; color: white; padding: 2px 8px; border-radius: 12px; font-size: 12px;">${game.words ? game.words.length : 5} palabras</span></div>
            </div>
            <div id="englishContainer">
                <div style="background: #f8f9fa; border-radius: 15px; padding: 20px; margin-bottom: 20px; border-left: 5px solid ${colors.primary};"><div class="game-question" id="englishQuestion" style="font-size: 18px; font-weight: 500; min-height: 50px;"></div></div>
                <div style="margin-bottom: 20px;"><div class="game-options" id="englishOptions" style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px;"></div></div>
                <div class="game-feedback" id="englishFeedback" style="min-height: 40px; font-size: 16px; text-align: center; padding: 10px; border-radius: 10px; background: #f8f9fa; margin-bottom: 15px;"></div>
            </div>
            <div style="display: flex; gap: 10px; justify-content: flex-end;">
                <button class="btn btn-primary" onclick="startEnglishGame('${gameType}')" style="background: ${colors.primary}; border: none; padding: 10px 20px; font-size: 14px; border-radius: 25px;"><span>▶️</span> Empezar</button>
                <button class="btn btn-secondary" id="nextEnglishBtn" onclick="nextEnglishWord()" style="background: white; color: ${colors.primary}; border: 2px solid ${colors.primary}; padding: 10px 20px; font-size: 14px; border-radius: 25px;"><span>⏭️</span> Siguiente</button>
            </div>
            <div style="margin-top: 15px; text-align: right;"><strong>Aciertos:</strong> <span id="englishScore" style="color: ${colors.primary};">0</span> / ${game.words ? game.words.length : 5}</div>
        </div>
    `;
    if(gameContainer) gameContainer.innerHTML = gameHTML;
}

function setDifficulty(difficulty) {
    currentDifficulty = difficulty;
    document.querySelectorAll('.difficulty-btn').forEach(btn => btn.classList.remove('active'));
    if(event && event.target) event.target.classList.add('active');
}

function startMemoryGame() {
    const game = gameContent[currentActivity][currentGameType];
    const difficulty = game.difficulties[currentDifficulty];
    memoryCards = []; flippedCards = []; matchedPairs = 0; gameActive = true;
    const emojis = ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', '🦁', '🐮'];
    const selectedEmojis = emojis.slice(0, difficulty.pairs);
    let cards = [...selectedEmojis, ...selectedEmojis].sort(() => Math.random() - 0.5);

    const memoryGrid = document.getElementById('memoryGrid');
    if(!memoryGrid) return;
    memoryGrid.innerHTML = '';
    cards.forEach((emoji, index) => {
        const card = document.createElement('div');
        card.className = 'memory-card'; card.dataset.index = index; card.dataset.value = emoji; card.innerHTML = '?';
        card.onclick = () => flipMemoryCard(card);
        memoryGrid.appendChild(card); memoryCards.push(card);
    });
    const feedback = document.getElementById('memoryFeedback');
    if(feedback) feedback.innerHTML = '¡Encuentra todas las parejas!';
}

function flipMemoryCard(card) {
    if (!gameActive || flippedCards.length >= 2 || card.classList.contains('flipped') || card.classList.contains('matched')) return;
    card.classList.add('flipped'); card.innerHTML = card.dataset.value; flippedCards.push(card);
    if (flippedCards.length === 2) checkMemoryMatch();
}

function checkMemoryMatch() {
    const [card1, card2] = flippedCards;
    if (card1.dataset.value === card2.dataset.value) {
        setTimeout(() => {
            card1.classList.add('matched'); card2.classList.add('matched');
            flippedCards = []; matchedPairs++;
            const game = gameContent[currentActivity][currentGameType];
            if (matchedPairs === game.difficulties[currentDifficulty].pairs) {
                const feedback = document.getElementById('memoryFeedback');
                if(feedback) feedback.innerHTML = '<span class="game-correct">🎉 ¡Felicidades! ¡Completaste el juego!</span>';
                gameActive = false; 
                if(typeof addStars === 'function') addStars(2); 
                perfectGamesCount++; 
                if(typeof recordActivity === 'function') recordActivity(currentActivity, currentGameType, 'completado'); 
                if(typeof checkAchievements === 'function') checkAchievements();
            }
        }, 500);
    } else {
        setTimeout(() => {
            card1.classList.remove('flipped'); card2.classList.remove('flipped');
            card1.innerHTML = '?'; card2.innerHTML = '?'; flippedCards = [];
        }, 1000);
    }
}

function resetMemoryGame() {
    memoryCards.forEach(card => { card.classList.remove('flipped', 'matched'); card.innerHTML = '?'; });
    flippedCards = []; matchedPairs = 0; gameActive = true;
    const feedback = document.getElementById('memoryFeedback');
    if(feedback) feedback.innerHTML = 'Juego reiniciado';
}

function startSequenceGame() { sequence = []; playerSequence = []; sequenceLevel = 1; generateSequence(); showSequence(); }
function generateSequence() {
    const colors = ['🟥', '🟦', '🟩', '🟨', '🟪', '🟧'];
    for (let i = 0; i < sequenceLevel; i++) sequence.push(colors[Math.floor(Math.random() * colors.length)]);
}
function showSequence() {
    const sequenceContainer = document.getElementById('sequenceContainer');
    const feedback = document.getElementById('sequenceFeedback');
    if(!sequenceContainer) return;
    sequenceContainer.innerHTML = '';
    if(feedback) feedback.innerHTML = 'Observa la secuencia...';
    sequence.forEach((color, index) => {
        setTimeout(() => { sequenceContainer.innerHTML = `<div class="sequence-item">${color}</div>`; }, index * 800);
        setTimeout(() => { sequenceContainer.innerHTML = ''; }, (index + 1) * 800);
    });
    setTimeout(() => {
        sequenceContainer.innerHTML = '';
        if(feedback) feedback.innerHTML = '¡Tu turno! Repite la secuencia';
        enableSequenceInput();
    }, sequence.length * 800 + 500);
}
function enableSequenceInput() {
    const colors = ['🟥', '🟦', '🟩', '🟨', '🟪', '🟧'];
    const sequenceContainer = document.getElementById('sequenceContainer');
    if(!sequenceContainer) return;
    sequenceContainer.innerHTML = '';
    colors.forEach(color => {
        const item = document.createElement('div'); item.className = 'sequence-item'; item.innerHTML = color;
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
    const feedback = document.getElementById('sequenceFeedback');
    if (correct) {
        if(feedback) feedback.innerHTML = '<span class="game-correct">✅ ¡Correcto! Nivel ' + sequenceLevel + ' completado</span>';
        setTimeout(() => { sequenceLevel++; playerSequence = []; generateSequence(); showSequence(); if (sequenceLevel > 1 && typeof addStars === 'function') addStars(1); }, 1500);
    } else {
        if(feedback) feedback.innerHTML = '<span class="game-incorrect">❌ Secuencia incorrecta. ¡Inténtalo de nuevo!</span>';
        setTimeout(() => { playerSequence = []; enableSequenceInput(); }, 1500);
    }
}
function resetSequenceGame() { sequence = []; playerSequence = []; sequenceLevel = 1; 
    const seqCont = document.getElementById('sequenceContainer');
    const feedback = document.getElementById('sequenceFeedback');
    if(seqCont) seqCont.innerHTML = ''; 
    if(feedback) feedback.innerHTML = 'Juego reiniciado'; 
}

function startVisualMemoryGame() {
    visualMemoryItems = []; visualMemoryChanged = [];
    const container = document.getElementById('visualMemoryContainer');
    if(!container) return;
    container.innerHTML = '';
    const emojis = ['⭐', '🎈', '🎯', '🎨', '🎪', '🎮', '🧩', '🎲', '🎳'];
    for (let i = 0; i < 9; i++) {
        const item = document.createElement('div'); item.className = 'visual-item'; item.innerHTML = emojis[i]; item.dataset.index = i;
        container.appendChild(item); visualMemoryItems.push(item);
    }
    const feedback = document.getElementById('visualMemoryFeedback');
    if(feedback) feedback.innerHTML = 'Observa bien los objetos...';
    setTimeout(() => changeVisualItems(), 5000);
}
function changeVisualItems() {
    const container = document.getElementById('visualMemoryContainer');
    if(!container) return;
    container.innerHTML = '';
    const changeIndices = [];
    while (changeIndices.length < 3) {
        const idx = Math.floor(Math.random() * 9);
        if (!changeIndices.includes(idx)) { changeIndices.push(idx); visualMemoryChanged.push(idx); }
    }
    const newEmojis = ['🌟', '💥', '🎖️', '🖍️', '🎠', '👾', '🧠', '🎰', '🎯'];
    for (let i = 0; i < 9; i++) {
        const item = document.createElement('div'); item.className = 'visual-item'; item.innerHTML = changeIndices.includes(i) ? newEmojis[i] : visualMemoryItems[i].innerHTML;
        if (changeIndices.includes(i)) item.classList.add('changed');
        item.dataset.index = i; item.onclick = () => checkVisualItem(i, item); container.appendChild(item);
    }
    const feedback = document.getElementById('visualMemoryFeedback');
    if(feedback) feedback.innerHTML = '¡Encuentra los 3 objetos que cambiaron!';
}
function checkVisualItem(index, element) {
    const feedback = document.getElementById('visualMemoryFeedback');
    if (visualMemoryChanged.includes(index)) {
        element.style.background = 'var(--accent-green)';
        visualMemoryChanged = visualMemoryChanged.filter(i => i !== index);
        if (visualMemoryChanged.length === 0) {
            if(feedback) feedback.innerHTML = '<span class="game-correct">🎉 ¡Felicidades! Encontraste todos los cambios</span>';
            if(typeof addStars === 'function') addStars(2); 
            perfectGamesCount++; 
            if(typeof recordActivity === 'function') recordActivity(currentActivity, currentGameType, 'completado'); 
            if(typeof checkAchievements === 'function') checkAchievements();
        }
    } else {
        element.style.background = 'var(--accent-pink)';
        if(feedback) feedback.innerHTML = '<span class="game-incorrect">❌ Este no cambió, sigue buscando</span>';
        setTimeout(() => element.style.background = 'var(--accent-blue)', 1000);
    }
}

function startQuiz(activity, gameType) {
    const game = gameContent[activity][gameType];
    quizQuestions = game.questions ? [...game.questions] : [];
    if (quizQuestions.length === 0) quizQuestions = generateGenericQuestions(activity, gameType);
    currentQuestionIndex = 0; quizScore = 0; showNextQuizQuestion();
}
function generateGenericQuestions(activity, gameType) {
    const questions = [];
    for (let i = 0; i < 5; i++) { questions.push({ question: `Pregunta ${i + 1} sobre ${activities[activity].title}`, options: ['Opción A', 'Opción B', 'Opción C', 'Opción D'], correct: Math.floor(Math.random() * 4) }); }
    return questions;
}

function startEnglishGame(gameType) {
    const game = gameContent[currentActivity][gameType];
    englishWords = game.words ? [...game.words] : [];
    if (englishWords.length === 0) {
        const engCont = document.getElementById('englishContainer');
        if(engCont) engCont.innerHTML = '<p>No hay palabras disponibles para este juego</p>';
        return;
    }
    currentWordIndex = 0; englishScore = 0; showNextEnglishWord();
}
function showNextEnglishWord() {
    if (currentWordIndex >= englishWords.length) return endEnglishGame();
    const word = englishWords[currentWordIndex];
    let questionText = '', options = word.options;
    if (word.spanish) questionText = `¿Cómo se dice "${word.spanish}" en inglés?`;
    else if (word.word) questionText = `¿Cuál es el opuesto de "${word.word}"?`;
    
    const engQ = document.getElementById('englishQuestion');
    const optCont = document.getElementById('englishOptions');
    if(engQ) engQ.innerHTML = questionText;
    if(optCont) {
        optCont.innerHTML = '';
        options.forEach((option, index) => {
            const opt = document.createElement('div'); opt.className = 'game-option'; opt.innerHTML = option;
            opt.style.cssText = 'padding: 12px 15px; border-radius: 10px; background: white; border: 2px solid var(--accent-blue); cursor: pointer; font-weight: 500; text-align: center; transition: all 0.2s ease;';
            opt.onmouseover = () => { opt.style.background = 'var(--accent-blue)'; opt.style.color = 'white'; };
            opt.onmouseout = () => { opt.style.background = 'white'; opt.style.color = 'initial'; };
            opt.onclick = () => checkEnglishAnswer(index, word);
            optCont.appendChild(opt);
        });
    }
    const feedback = document.getElementById('englishFeedback');
    const score = document.getElementById('englishScore');
    if(feedback) feedback.innerHTML = '';
    if(score) score.innerHTML = englishScore;
}
function checkEnglishAnswer(selectedIndex, word) {
    let correctIndex = 0, correctAnswer = '';
    if (word.english) { correctAnswer = word.english; correctIndex = word.options.indexOf(word.english); }
    else if (word.opposite) { correctAnswer = word.opposite; correctIndex = word.options.indexOf(word.opposite); }
    const feedback = document.getElementById('englishFeedback');
    const options = document.querySelectorAll('#englishOptions .game-option');
    options.forEach(opt => opt.style.pointerEvents = 'none');
    
    if (selectedIndex === correctIndex) {
        if(feedback) feedback.innerHTML = `<span style="color: #27AE60; font-weight: bold;">✅ ¡Correcto! "${correctAnswer}"</span>`;
        englishScore++; 
        if(typeof addStars === 'function') addStars(1);
        options[selectedIndex].style.background = '#27AE60'; options[selectedIndex].style.color = 'white'; options[selectedIndex].style.borderColor = '#27AE60';
    } else {
        if(feedback) feedback.innerHTML = `<span style="color: #E74C3C; font-weight: bold;">❌ Incorrecto. La respuesta es: "${correctAnswer}"</span>`;
        options[correctIndex].style.background = '#27AE60'; options[correctIndex].style.color = 'white'; options[correctIndex].style.borderColor = '#27AE60';
        options[selectedIndex].style.background = '#E74C3C'; options[selectedIndex].style.color = 'white'; options[selectedIndex].style.borderColor = '#E74C3C';
    }
    const score = document.getElementById('englishScore');
    const nextBtn = document.getElementById('nextEnglishBtn');
    if(score) score.innerHTML = englishScore;
    if(nextBtn) { nextBtn.style.background = '#27AE60'; nextBtn.style.color = 'white'; }
}
function resetEnglishNextButton() {
    const btn = document.getElementById('nextEnglishBtn');
    if (btn) { btn.style.background = ''; btn.style.color = ''; }
}
function nextEnglishWord() { resetEnglishNextButton(); currentWordIndex++; if (currentWordIndex >= englishWords.length) endEnglishGame(); else showNextEnglishWord(); }
function endEnglishGame() {
    const percentage = (englishScore / englishWords.length) * 100;
    let message = '';
    if (percentage >= 80) { message = `🎉 ¡Excelente inglés! ${englishScore}/${englishWords.length}`; perfectGamesCount++; }
    else if (percentage >= 60) message = `👍 ¡Buen trabajo! ${englishScore}/${englishWords.length}`;
    else message = `💪 Sigue practicando: ${englishScore}/${englishWords.length}`;
    const engCont = document.getElementById('englishContainer');
    if(engCont) engCont.innerHTML = `<h3>Juego Completado!</h3><p>${message}</p><div style="font-size: 24px; margin: 20px 0;">${'⭐'.repeat(Math.floor(englishScore / 2))}</div>`;
    if(typeof recordActivity === 'function') recordActivity(currentActivity, currentGameType, `${englishScore}/${englishWords.length} correctas`); 
    if(typeof checkAchievements === 'function') checkAchievements();
}

function addStars(count) {
    if (!currentUser) return;
    currentUser.stars += count;
    const now = Date.now();
    if (lastStarTime && (now - lastStarTime) < 10 * 60 * 1000) fastStarsCount++; else fastStarsCount = 1;
    lastStarTime = now;
    if(typeof saveUsers === 'function') saveUsers(); 
    if(typeof updateCurrentUserDisplay === 'function') updateCurrentUserDisplay(); 
    createStarAnimation(count); 
    if(typeof checkAchievements === 'function') checkAchievements();
}

function createStarAnimation(count) {
    for (let i = 0; i < count; i++) {
        setTimeout(() => {
            const star = document.createElement('div'); star.innerHTML = '⭐'; star.style.position = 'fixed'; star.style.fontSize = '30px'; star.style.zIndex = '9999'; star.style.left = '50%'; star.style.top = '50%'; star.style.transform = 'translate(-50%, -50%)'; star.style.pointerEvents = 'none';
            document.body.appendChild(star);
            star.animate([{ transform: 'translate(-50%, -50%) scale(0)', opacity: 0 }, { transform: 'translate(-50%, -50%) scale(1.5)', opacity: 1 }, { transform: 'translate(-50%, calc(-50% - 100px)) scale(1)', opacity: 0 }], { duration: 1500, easing: 'cubic-bezier(0.1, 0.8, 0.2, 1)' }).onfinish = () => star.remove();
        }, i * 200);
    }
}

function addPlayTime(minutes) {
    if (!currentUser) return;
    currentUser.playTime += minutes;
    if(typeof saveUsers === 'function') saveUsers(); 
    if(typeof updateCurrentUserDisplay === 'function') updateCurrentUserDisplay(); 
    if(typeof checkAchievements === 'function') checkAchievements();
}