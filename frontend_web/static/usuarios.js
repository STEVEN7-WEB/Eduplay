// ========== ESTADO DE USUARIOS ==========
let users = [];
let currentUser = null;
let editingUserId = null;
let userToDelete = null;

function loadUsers() {
    const savedUsers = localStorage.getItem('eduplay_users');
    if (savedUsers) users = JSON.parse(savedUsers);
    else users = [];
}

function saveUsers() {
    localStorage.setItem('eduplay_users', JSON.stringify(users));
}

function updateCurrentUserDisplay() {
    if (currentUser) {
        const currentUserName = document.getElementById('currentUserName');
        const currentUserAvatar = document.getElementById('currentUserAvatar');
        const starsCount = document.getElementById('stars-count');
        const playTime = document.getElementById('play-time');
        const progressBar = document.querySelector('.progress-bar');
        const logoutBtn = document.getElementById('logoutBtn');

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
        const currentUserName = document.getElementById('currentUserName');
        const currentUserAvatar = document.getElementById('currentUserAvatar');
        const logoutBtn = document.getElementById('logoutBtn');
        
        if(currentUserName) currentUserName.textContent = 'Usuario';
        if(currentUserAvatar) {
            currentUserAvatar.textContent = 'U';
            currentUserAvatar.style.background = '#2F80ED';
        }
        if(logoutBtn) logoutBtn.style.display = 'none';
    }
}

function getUserColor(userId) {
    const colors = ['#2F80ED', '#F2994A', '#27AE60', '#FF7AB6', '#FFD24C', '#9B51E0', '#56CCF2', '#BB6BD9'];
    return colors[userId % colors.length];
}

function createNewUser() {
    editingUserId = null;
    const userFormTitle = document.getElementById('userFormTitle');
    const userNameInput = document.getElementById('userName');
    const userAgeInput = document.getElementById('userAge');
    const userAvatarInput = document.getElementById('userAvatar');
    
    if(userFormTitle) userFormTitle.textContent = 'Crear Nuevo Usuario';
    if(userNameInput) userNameInput.value = '';
    if(userAgeInput) userAgeInput.value = '';
    if(userAvatarInput) userAvatarInput.value = '';
    setTimeout(() => { if(userNameInput) userNameInput.focus(); }, 300);
}

function editUser(userId) {
    const user = users.find(u => u.id === userId);
    if (!user) return;
    editingUserId = userId;
    const userFormTitle = document.getElementById('userFormTitle');
    const userNameInput = document.getElementById('userName');
    const userAgeInput = document.getElementById('userAge');
    const userAvatarInput = document.getElementById('userAvatar');
    
    if(userFormTitle) userFormTitle.textContent = 'Editar Usuario';
    if(userNameInput) userNameInput.value = user.name;
    if(userAgeInput) userAgeInput.value = user.age;
    if(userAvatarInput) userAvatarInput.value = user.avatar;
    setTimeout(() => { if(userNameInput) userNameInput.focus(); }, 300);
}

function saveUser() {
    const userNameInput = document.getElementById('userName');
    const userAgeInput = document.getElementById('userAge');
    const userAvatarInput = document.getElementById('userAvatar');
    
    const name = userNameInput ? userNameInput.value.trim() : '';
    const age = userAgeInput ? parseInt(userAgeInput.value) : 0;
    const avatar = userAvatarInput ? userAvatarInput.value.trim() : '🎮';

    if (!name || name.length < 2) return alert('El nombre debe tener al menos 2 caracteres');
    if (!age || age < 3 || age > 12) return alert('La edad debe estar entre 3 y 12 años');
    if (!avatar || avatar.length === 0) return alert('Por favor selecciona un emoji para el avatar');

    if (editingUserId) {
        const userIndex = users.findIndex(u => u.id === editingUserId);
        if (userIndex !== -1) {
            users[userIndex].name = name;
            users[userIndex].age = age;
            users[userIndex].avatar = avatar;
        }
    } else {
        users.push({ id: Date.now(), name: name, age: age, avatar: avatar, stars: 0, playTime: 0, createdAt: new Date().toISOString() });
    }

    saveUsers();
    renderUserList();
    cancelEditUser();
    if (!currentUser && !editingUserId) selectUser(users[users.length - 1].id);
}

function deleteUser(userId) {
    const user = users.find(u => u.id === userId);
    if (!user) return;
    userToDelete = userId;
    const confirmationText = document.getElementById('confirmationText');
    const confirmationModal = document.getElementById('confirmationModal');
    if(confirmationText) confirmationText.textContent = `¿Estás seguro de que quieres eliminar a ${user.name}? Todos sus datos y progreso se perderán permanentemente.`;
    if(confirmationModal) confirmationModal.style.display = 'flex';
}

function confirmDelete() {
    if (!userToDelete) return;
    if (currentUser && currentUser.id === userToDelete) {
        currentUser = null;
        updateCurrentUserDisplay();
        const logoutBtn = document.getElementById('logoutBtn');
        if(logoutBtn) logoutBtn.style.display = 'none';
    }
    users = users.filter(u => u.id !== userToDelete);
    saveUsers();
    renderUserList();
    const confirmationModal = document.getElementById('confirmationModal');
    if(confirmationModal) confirmationModal.style.display = 'none';
    userToDelete = null;
    if (users.length > 0 && !currentUser) selectUser(users[0].id);
}

function cancelEditUser() {
    editingUserId = null;
}

function renderUserList() {
    const userList = document.getElementById('userList');
    if (!userList) return;
    userList.innerHTML = '';
    if (users.length === 0) {
        userList.innerHTML = `<div class="user-item" style="text-align: center; flex-direction: column; gap: 10px;"><div style="font-size: 40px; margin-bottom: 10px;">👤</div><div class="user-info"><div class="user-name">¡Bienvenido a EduPlay!</div><div class="user-stats">Crea tu primer usuario para empezar</div></div><div style="margin-top: 10px;"><button class="btn btn-primary" onclick="createNewUser()" style="padding: 10px 20px;"><span>➕</span> Crear Primer Usuario</button></div></div>`;
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
                    <div class="user-stats">${user.age} años | ${user.stars} ⭐ | ${user.playTime} min</div>
                </div>
            </div>
            <div class="user-actions">
                ${isCurrent ? '<span class="btn btn-secondary" style="padding: 5px 10px; font-size: 12px;">✓ Actual</span>' : `<button class="btn btn-secondary" onclick="selectUser(${user.id})" style="padding: 5px 10px; font-size: 12px;"><span>👉</span> Seleccionar</button>`}
                <button class="btn btn-secondary" onclick="editUser(${user.id})" style="padding: 5px 10px; font-size: 12px;"><span>✏️</span> Editar</button>
                <button class="btn btn-danger" onclick="deleteUser(${user.id})" style="padding: 5px 10px; font-size: 12px;"><span>🗑️</span> Eliminar</button>
            </div>
        `;
        userList.appendChild(userItem);
    });
}

function selectUser(userId) {
    const user = users.find(u => u.id === userId);
    if (!user) return;
    currentUser = user;
    updateCurrentUserDisplay();
    if(typeof loadUserAchievements === 'function') loadUserAchievements();
    if(typeof loadActivityHistory === 'function') loadActivityHistory();
    renderUserList();
    const userManagementModal = document.getElementById('userManagementModal');
    if(userManagementModal) setTimeout(() => userManagementModal.style.display = 'none', 300);
}

function logout() {
    if (currentUser) {
        saveUsers();
        if(typeof saveUserAchievements === 'function') saveUserAchievements();
        if(typeof saveActivityHistory === 'function') saveActivityHistory();
        alert(`Sesión de ${currentUser.name} cerrada. Tu progreso ha sido guardado.`);
        currentUser = null;
        updateCurrentUserDisplay();
        if(typeof updateQuickAchievements === 'function') updateQuickAchievements();
        if(typeof showWelcomeScreen === 'function') showWelcomeScreen();
    }
}

function playWithoutUser() {
    currentUser = { id: 'guest_' + Date.now(), name: 'Invitado', age: 8, avatar: '👤', stars: 0, playTime: 0, createdAt: new Date().toISOString() };
    updateCurrentUserDisplay();
    if(typeof loadUserAchievements === 'function') loadUserAchievements();
    if(typeof loadActivityHistory === 'function') loadActivityHistory();
    if(typeof closeWelcomeScreen === 'function') closeWelcomeScreen();
    alert('¡Bienvenido a EduPlay! Estás jugando como invitado. Tu progreso se guardará durante esta sesión.');
}