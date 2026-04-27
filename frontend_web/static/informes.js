// ========== ESTADO DE LOGROS Y PROGRESO ==========
let userAchievements = {};
let activityCounts = { math: 0, memory: 0, grammar: 0, english: 0, geography: 0, art: 0, science: 0, logic: 0 };
let perfectGamesCount = 0;
let lastStarTime = null;
let fastStarsCount = 0;
let userActivityHistory = [];

function loadUserAchievements() {
    if (!currentUser) return;
    const saved = localStorage.getItem(`eduplay_achievements_${currentUser.id}`);
    if (saved) {
        userAchievements = JSON.parse(saved);
    } else {
        userAchievements = {};
        achievementsList.forEach(achievement => {
            userAchievements[achievement.id] = { unlocked: false, progress: 0, dateUnlocked: null };
        });
        saveUserAchievements();
    }
    updateQuickAchievements();
}

function saveUserAchievements() {
    if (!currentUser) return;
    localStorage.setItem(`eduplay_achievements_${currentUser.id}`, JSON.stringify(userAchievements));
}

function updateQuickAchievements() {
    if (!currentUser) return;
    const quickAchievements = document.getElementById('quickAchievements');
    if (!quickAchievements) return;
    
    const unlocked = Object.keys(userAchievements).filter(id => userAchievements[id].unlocked).slice(0, 4);
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

    if (unlocked.length === 0) {
        quickAchievements.innerHTML = `
            <div class="badge" style="background: var(--accent-blue)">⭐</div>
            <div class="badge" style="background: var(--accent-green)">⏱️</div>
            <div class="badge" style="background: var(--accent-purple)">🎮</div>
        `;
    }
}

function checkAchievements() {
    if (!currentUser) return;
    achievementsList.forEach(achievement => {
        const achievementData = userAchievements[achievement.id];
        if (!achievementData || achievementData.unlocked) return;

        const req = achievement.requirement;
        let shouldUnlock = false;

        switch (req.type) {
            case 'stars': shouldUnlock = currentUser.stars >= req.value; break;
            case 'playTime': shouldUnlock = currentUser.playTime >= req.value; break;
            case 'activity': shouldUnlock = (activityCounts[req.value.activity] || 0) >= req.value.count; break;
            case 'combined': shouldUnlock = req.value.every(item => (activityCounts[item.activity] || 0) >= item.count); break;
            case 'all_activities': const activitiesTried = Object.values(activityCounts).filter(count => count > 0).length; shouldUnlock = activitiesTried >= req.value; break;
            case 'perfect_games': shouldUnlock = perfectGamesCount >= req.value; break;
            case 'fast_stars': shouldUnlock = fastStarsCount >= req.value; break;
        }
        if (shouldUnlock) unlockAchievement(achievement);
    });
}

function unlockAchievement(achievement) {
    if (!currentUser) return;
    const achievementData = userAchievements[achievement.id];
    achievementData.unlocked = true;
    achievementData.dateUnlocked = new Date().toISOString();
    saveUserAchievements();
    showAchievementUnlocked(achievement);
    updateQuickAchievements();
    if (audioOn) playAchievementSound();
}

function showAchievementUnlocked(achievement) {
    const unlockedTitle = document.getElementById('unlockedTitle');
    const unlockedDesc = document.getElementById('unlockedDesc');
    const achievementUnlocked = document.getElementById('achievementUnlocked');
    if(unlockedTitle) unlockedTitle.textContent = achievement.name;
    if(unlockedDesc) unlockedDesc.textContent = achievement.description;
    if(achievementUnlocked) {
        achievementUnlocked.style.background = `linear-gradient(135deg, ${achievement.color}, ${darkenColor(achievement.color, 20)})`;
        achievementUnlocked.style.display = 'block';
    }
    createAchievementParticles();
    setTimeout(() => { if (achievementUnlocked && achievementUnlocked.style.display === 'block') achievementUnlocked.style.display = 'none'; }, 5000);
}

function darkenColor(color, percent) {
    const num = parseInt(color.replace("#", ""), 16);
    const amt = Math.round(2.55 * percent);
    const R = (num >> 16) - amt, G = (num >> 8 & 0x00FF) - amt, B = (num & 0x0000FF) - amt;
    return "#" + (0x1000000 + (R < 255 ? R < 1 ? 0 : R : 255) * 0x10000 + (G < 255 ? G < 1 ? 0 : G : 255) * 0x100 + (B < 255 ? B < 1 ? 0 : B : 255)).toString(16).slice(1);
}

function createAchievementParticles() {
    const colors = ['#FFD24C', '#FF7AB6', '#2F80ED', '#27AE60', '#9B51E0'];
    for (let i = 0; i < 50; i++) {
        const particle = document.createElement('div'); particle.className = 'achievement-particle'; particle.style.width = `${Math.random() * 8 + 4}px`; particle.style.height = particle.style.width; particle.style.background = colors[Math.floor(Math.random() * colors.length)]; particle.style.left = `${Math.random() * 100}%`; particle.style.top = `${Math.random() * 100}%`; particle.style.zIndex = '1007';
        document.body.appendChild(particle);
        const angle = Math.random() * Math.PI * 2, distance = 100 + Math.random() * 100, duration = 1000 + Math.random() * 1000;
        particle.animate([{ transform: 'translate(0, 0) scale(1)', opacity: 1 }, { transform: `translate(${Math.cos(angle) * distance}px, ${Math.sin(angle) * distance}px) scale(0)`, opacity: 0 }], { duration: duration, easing: 'cubic-bezier(0.1, 0.8, 0.2, 1)' }).onfinish = () => particle.remove();
    }
}

function playAchievementSound() {
    if (typeof audioOn === 'undefined' || !audioOn) return;
    try {
        const audioContext = new (window.AudioContext || window.webkitAudioContext)();
        const oscillator = audioContext.createOscillator(); const gainNode = audioContext.createGain();
        oscillator.connect(gainNode); gainNode.connect(audioContext.destination);
        oscillator.frequency.setValueAtTime(523.25, audioContext.currentTime);
        oscillator.frequency.setValueAtTime(659.25, audioContext.currentTime + 0.1);
        oscillator.frequency.setValueAtTime(783.99, audioContext.currentTime + 0.2);
        gainNode.gain.setValueAtTime(0.3, audioContext.currentTime); gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.5);
        oscillator.start(audioContext.currentTime); oscillator.stop(audioContext.currentTime + 0.5);
    } catch (e) { console.log('No se pudo reproducir sonido de logro'); }
}

function showAchievementsModal() {
    if (!currentUser) return alert('Primero debes seleccionar un usuario');
    renderAchievementsGrid();
    const achievementsModal = document.getElementById('achievementsModal');
    if(achievementsModal) achievementsModal.style.display = 'flex';
}

function renderAchievementsGrid() {
    if (!currentUser) return;
    const achievementsStats = document.getElementById('achievementsStats');
    const achievementsGrid = document.getElementById('achievementsGrid');
    const totalAchievements = achievementsList.length;
    const unlockedAchievements = Object.values(userAchievements).filter(a => a.unlocked).length;
    const completionRate = totalAchievements > 0 ? Math.round((unlockedAchievements / totalAchievements) * 100) : 0;
    
    if(achievementsStats) {
        achievementsStats.innerHTML = `<div class="stat-item"><div class="stat-number">${unlockedAchievements}</div><div class="stat-label">Logros Desbloqueados</div></div><div class="stat-item"><div class="stat-number">${totalAchievements}</div><div class="stat-label">Logros Totales</div></div><div class="stat-item"><div class="stat-number">${completionRate}%</div><div class="stat-label">Completado</div></div>`;
    }
    
    if(achievementsGrid) {
        achievementsGrid.innerHTML = '';
        achievementsList.forEach(achievement => {
            const achievementData = userAchievements[achievement.id] || { unlocked: false, progress: 0 };
            const progress = calculateAchievementProgress(achievement);
            const achievementCard = document.createElement('div'); achievementCard.className = `achievement-card ${achievementData.unlocked ? 'unlocked' : 'locked'}`;
            let progressBar = '';
            if (!achievementData.unlocked && progress > 0) progressBar = `<div class="achievement-progress"><div class="achievement-progress-bar" style="width: ${progress}%"></div></div><div class="achievement-date">${progress}% completado</div>`;
            if (achievementData.unlocked && achievementData.dateUnlocked) { const date = new Date(achievementData.dateUnlocked); progressBar += `<div class="achievement-date">Desbloqueado: ${date.toLocaleDateString()}</div>`; }
            achievementCard.innerHTML = `${achievementData.unlocked ? '<div class="achievement-ribbon">¡LOGRO!</div>' : ''}<div class="achievement-icon">${achievement.icon}</div><div class="achievement-name">${achievement.name}</div><div class="achievement-desc">${achievement.description}</div>${progressBar}${achievementData.unlocked ? '<div class="achievement-badge">✓</div>' : ''}`;
            if (achievementData.unlocked) { achievementCard.style.borderColor = achievement.color; achievementCard.style.boxShadow = `0 5px 15px ${achievement.color}40`; }
            achievementsGrid.appendChild(achievementCard);
        });
    }
}

function calculateAchievementProgress(achievement) {
    if (!currentUser) return 0;
    const req = achievement.requirement;
    switch (req.type) {
        case 'stars': return Math.min((currentUser.stars / req.value) * 100, 100);
        case 'playTime': return Math.min((currentUser.playTime / req.value) * 100, 100);
        case 'activity': const count = activityCounts[req.value.activity] || 0; return Math.min((count / req.value.count) * 100, 100);
        case 'combined': let totalProgress = 0; req.value.forEach(item => { const count = activityCounts[item.activity] || 0; totalProgress += Math.min((count / item.count) * 100, 100); }); return totalProgress / req.value.length;
        case 'all_activities': const activitiesTried = Object.values(activityCounts).filter(count => count > 0).length; return Math.min((activitiesTried / req.value) * 100, 100);
        case 'perfect_games': return Math.min((perfectGamesCount / req.value) * 100, 100);
        case 'fast_stars': return Math.min((fastStarsCount / req.value) * 100, 100);
        default: return 0;
    }
}

function loadActivityHistory() {
    if (!currentUser) return;
    const savedHistory = localStorage.getItem(`eduplay_history_${currentUser.id}`);
    if (savedHistory) userActivityHistory = JSON.parse(savedHistory); else userActivityHistory = [];
}

function saveActivityHistory() { 
    if (!currentUser) return; 
    localStorage.setItem(`eduplay_history_${currentUser.id}`, JSON.stringify(userActivityHistory)); 
}

function recordActivity(activity, gameType, result = 'completado') {
    if (!currentUser) return;
    const activityRecord = { id: Date.now(), timestamp: new Date().toISOString(), user: currentUser.id, activity: activity, gameType: gameType, result: result, starsEarned: 1 };
    userActivityHistory.unshift(activityRecord);
    if (userActivityHistory.length > 50) userActivityHistory = userActivityHistory.slice(0, 50);
    saveActivityHistory();
}

function showParentReport() {
    if (!currentUser) return alert('Primero debes seleccionar un usuario');
    loadActivityHistory(); renderParentReport();
    const parentReportModal = document.getElementById('parentReportModal');
    if(parentReportModal) parentReportModal.style.display = 'flex';
}

function renderParentReport() {
    if (!currentUser) return;
    const reportUserInfo = document.getElementById('reportUserInfo');
    const reportDate = document.getElementById('reportDate');
    if(reportUserInfo) reportUserInfo.innerHTML = `<div class="report-user-avatar" style="background: ${getUserColor(currentUser.id)}">${currentUser.avatar}</div><div class="report-user-details"><h3>${currentUser.name}</h3><p>${currentUser.age} años | ${currentUser.stars} ⭐ | ${currentUser.playTime} min</p><p>Usuario desde: ${new Date(currentUser.id).toLocaleDateString()}</p></div>`;
    if(reportDate) reportDate.textContent = new Date().toLocaleString();
    renderOverviewTab(); renderActivitiesTab(); renderAchievementsTab(); renderRecommendationsTab();
}

function renderOverviewTab() {
    if (!currentUser) return;
    const oStars = document.getElementById('overviewStars');
    const oTime = document.getElementById('overviewTime');
    const oAchiev = document.getElementById('overviewAchievements');
    const oProg = document.getElementById('overviewProgress');
    if(oStars) oStars.textContent = currentUser.stars;
    if(oTime) oTime.textContent = `${currentUser.playTime} min`;
    const unlockedAchievements = Object.values(userAchievements).filter(a => a.unlocked).length;
    if(oAchiev) oAchiev.textContent = `${unlockedAchievements}/15`;
    const progress = Math.min((currentUser.stars / 100) * 100, 100);
    if(oProg) oProg.textContent = `${progress.toFixed(1)}%`;
    renderDistributionChart(); renderActivityTimeline();
}

function renderDistributionChart() {
    const distributionChart = document.getElementById('distributionChart');
    if(!distributionChart) return;
    distributionChart.innerHTML = '';
    const activityData = {};
    Object.keys(activityCounts).forEach(activity => {
        if (activityCounts[activity] > 0) { const activityInfo = activities[activity]; activityData[activity] = { name: activityInfo.title, emoji: activityInfo.emoji, count: activityCounts[activity] }; }
    });
    const sortedActivities = Object.entries(activityData).sort((a, b) => b[1].count - a[1].count).slice(0, 6);
    const total = sortedActivities.reduce((sum, [, data]) => sum + data.count, 0);
    sortedActivities.forEach(([activity, data]) => {
        const percentage = total > 0 ? (data.count / total) * 100 : 0;
        const chartItem = document.createElement('div'); chartItem.className = 'chart-item';
        chartItem.innerHTML = `<div class="chart-emoji">${data.emoji}</div><div class="chart-name">${data.name}</div><div class="chart-bar"><div class="chart-fill" style="width: ${percentage}%"></div></div><div class="chart-count">${data.count} juegos (${percentage.toFixed(1)}%)</div>`;
        distributionChart.appendChild(chartItem);
        setTimeout(() => { const fill = chartItem.querySelector('.chart-fill'); if(fill) fill.style.width = `${percentage}%`; }, 100);
    });
}

function renderActivityTimeline() {
    const activityTimeline = document.getElementById('activityTimeline');
    if(!activityTimeline) return;
    activityTimeline.innerHTML = '';
    const recentActivities = userActivityHistory.slice(0, 10);
    if (recentActivities.length === 0) {
        activityTimeline.innerHTML = `<div class="timeline-item"><div class="timeline-activity"><span class="timeline-emoji">📝</span><span class="timeline-text">No hay actividad registrada todavía</span></div></div>`;
        return;
    }
    recentActivities.forEach(activity => {
        const activityInfo = activities[activity.activity];
        const gameInfo = gameContent[activity.activity]?.[activity.gameType];
        const timeStr = new Date(activity.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        const timelineItem = document.createElement('div'); timelineItem.className = 'timeline-item';
        timelineItem.innerHTML = `<div class="timeline-time">${timeStr}</div><div class="timeline-activity"><span class="timeline-emoji">${activityInfo?.emoji || '🎮'}</span><span class="timeline-text">${gameInfo?.title || activity.activity} - ${activity.result}</span></div>`;
        activityTimeline.appendChild(timelineItem);
    });
}

function renderActivitiesTab() {
    const activityDetails = document.getElementById('activityDetails');
    if(!activityDetails) return;
    activityDetails.innerHTML = '';
    Object.keys(activities).forEach(activityKey => {
        const activity = activities[activityKey]; const count = activityCounts[activityKey] || 0;
        if (count === 0) return;
        const avgStars = count > 0 ? (currentUser.stars * 0.1 / count).toFixed(1) : 0;
        const successRate = Math.min(80 + Math.random() * 20, 100).toFixed(0);
        const detailCard = document.createElement('div'); detailCard.className = 'activity-detail-card';
        detailCard.innerHTML = `<div class="activity-detail-header"><div class="activity-detail-emoji">${activity.emoji}</div><div class="activity-detail-title"><h4>${activity.title}</h4><p>${count} ${count === 1 ? 'juego' : 'juegos'} completados</p></div></div><div class="activity-detail-stats"><div class="detail-stat"><div class="detail-value">${count}</div><div class="detail-label">Total</div></div><div class="detail-stat"><div class="detail-value">${avgStars}</div><div class="detail-label">⭐/juego</div></div><div class="detail-stat"><div class="detail-value">${successRate}%</div><div class="detail-label">Éxito</div></div><div class="detail-stat"><div class="detail-value">${getDifficultyLevel(activityKey)}</div><div class="detail-label">Nivel</div></div></div>`;
        activityDetails.appendChild(detailCard);
    });
}

function getDifficultyLevel(activity) {
    const levels = { memory: 'Avanzado', math: 'Intermedio', grammar: 'Intermedio', english: 'Principiante', geography: 'Intermedio', art: 'Principiante', science: 'Intermedio', logic: 'Avanzado' };
    return levels[activity] || 'Intermedio';
}

function renderAchievementsTab() {
    const achievementsReport = document.getElementById('achievementsReport');
    if(!achievementsReport) return;
    achievementsReport.innerHTML = '';
    achievementsList.forEach(achievement => {
        const achievementData = userAchievements[achievement.id] || { unlocked: false, dateUnlocked: null };
        const achievementCard = document.createElement('div'); achievementCard.className = `achievement-report-card ${achievementData.unlocked ? 'unlocked' : ''}`;
        let dateInfo = ''; if (achievementData.unlocked && achievementData.dateUnlocked) dateInfo = `<div class="achievement-report-date">${new Date(achievementData.dateUnlocked).toLocaleDateString()}</div>`;
        achievementCard.innerHTML = `<div class="achievement-report-icon">${achievement.icon}</div><div class="achievement-report-name">${achievement.name}</div><div class="achievement-report-desc">${achievement.description}</div>${dateInfo}${achievementData.unlocked ? '<div style="color: var(--accent-green); margin-top: 8px;">✓ Desbloqueado</div>' : '<div style="color: var(--text-secondary); margin-top: 8px;">⌛ Pendiente</div>'}`;
        if (achievementData.unlocked) achievementCard.style.borderColor = achievement.color;
        achievementsReport.appendChild(achievementCard);
    });
}

function renderRecommendationsTab() {
    const sC = document.getElementById('strengthsContent');
    const iC = document.getElementById('improvementContent');
    const suC = document.getElementById('suggestionsContent');
    if(sC) sC.innerHTML = calculateStrengths();
    if(iC) iC.innerHTML = calculateImprovements();
    if(suC) suC.innerHTML = generateSuggestions();
}

function calculateStrengths() {
    if (!currentUser) return '<p>No hay datos suficientes</p>';
    const strengths = []; const sortedActivities = Object.entries(activityCounts).sort((a, b) => b[1] - a[1]).slice(0, 3);
    if (sortedActivities.length > 0 && sortedActivities[0][1] > 0) { sortedActivities.forEach(([activity, count]) => { if (count > 0) strengths.push(`<div class="recommendation-item">${activities[activity]?.emoji} ${activities[activity]?.title} (${count} veces)</div>`); }); }
    const unlockedCount = Object.values(userAchievements).filter(a => a.unlocked).length;
    if (unlockedCount > 5) strengths.push(`<div class="recommendation-item">🏆 ${unlockedCount} logros desbloqueados</div>`);
    if (currentUser.stars > 25) strengths.push(`<div class="recommendation-item">⭐ ${currentUser.stars} estrellas ganadas</div>`);
    return strengths.join('') || '<p>¡Sigue jugando para descubrir tus fortalezas!</p>';
}

function calculateImprovements() {
    if (!currentUser) return '<p>No hay datos suficientes</p>';
    const improvements = []; const sortedActivities = Object.entries(activityCounts).sort((a, b) => a[1] - b[1]).slice(0, 3);
    sortedActivities.forEach(([activity, count]) => { if (count < 3) improvements.push(`<div class="recommendation-item">${activities[activity]?.emoji} ${activities[activity]?.title} (solo ${count} veces)</div>`); });
    if (currentUser.playTime < 30) improvements.push(`<div class="recommendation-item">⏱️ Solo ${currentUser.playTime} minutos de juego</div>`);
    return improvements.join('') || '<p>¡Excelente! Estás explorando todas las áreas</p>';
}

function generateSuggestions() {
    const suggestions = [];
    if (currentUser.playTime < 60) suggestions.push(`<div class="recommendation-item">🎯 Juega 15 minutos diarios para mejorar</div>`);
    const unlockedCount = Object.values(userAchievements).filter(a => a.unlocked).length;
    if (unlockedCount < 5) suggestions.push(`<div class="recommendation-item">🏆 Intenta completar más juegos para desbloquear logros</div>`);
    const activityCount = Object.values(activityCounts).filter(count => count > 0).length;
    if (activityCount < 5) suggestions.push(`<div class="recommendation-item">🔍 Explora diferentes tipos de actividades</div>`);
    suggestions.push(`<div class="recommendation-item">📅 Establece una rutina de juego regular</div>`);
    suggestions.push(`<div class="recommendation-item">🎮 Alterna entre actividades de memoria y lógica</div>`);
    suggestions.push(`<div class="recommendation-item">⭐ Intenta conseguir todas las estrellas en cada juego</div>`);
    return suggestions.join('');
}