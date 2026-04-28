/* ═══════════════════════════════════════════════════════════════════
   EduPlay – script_patch.js  v4 DEFINITIVO
   Bugs corregidos:
   ✅ Avatar undefined → error JSON al crear usuario
   ✅ Página en blanco al crear usuario (mainContainer no se abría)
   ✅ Sesión persiste al recargar (localStorage)
   ✅ PIN login para alumnos + recuperación
   ✅ Botón "Informe Padres" oculto al alumno (solo en panel padre)
   ✅ Perfil padre completo: ver/agregar/eliminar hijos + informes KNN
   ═══════════════════════════════════════════════════════════════════ */

/* ── Config ──────────────────────────────────────────────────────── */
const EP_API  = 'http://localhost:5000/api';
let   EP_BACK = false;
let   EP_PADRE = null;

/* ── API helper (MEJORADO: Escudo anti-404 y string vacío) ──────────────────────── */
async function epFetch(path, method, body) {
    // 🛡️ ESCUDO V2: Bloquea 'null', 'undefined' y también el ID vacío (ruta termina en '/')
    // Nota: '/usuarios' (sin barra) es válido para traer todos, '/usuarios/' (con barra) es el error.
    if (path.includes('undefined') || path.includes('null') || path === '/usuarios/') {
        console.warn("Fetch bloqueado silenciosamente: Intento de petición con ID vacío ->", path);
        throw new Error('ID de usuario no válido');
    }

    const opts = { method: method || 'GET', headers: { 'Content-Type': 'application/json' } };
    if (body) opts.body = JSON.stringify(body);
    
    let r = await fetch(EP_API + path, opts);
    
    // 🔄 AUTO-CORRECTOR FLASK: Intento de rescate si falta/sobra la barra final
    if (r.status === 404) {
        const altPath = path.endsWith('/') ? path.slice(0, -1) : path + '/';
        let r2 = await fetch(EP_API + altPath, opts);
        if (r2.ok) r = r2; 
    }

    const d = await r.json();
    if (!r.ok) throw new Error(d.error || 'Error ' + r.status);
    return d;
}

function epNorm(u) {
    return {
        id:       u.id,
        name:     u.nombre      || u.name     || '',
        age:      u.edad        || u.age       || 0,
        avatar:   u.avatar      || '🎮',
        stars:    (u.estrellas    != null) ? u.estrellas    : (u.stars    || 0),
        playTime: (u.tiempo_juego != null) ? u.tiempo_juego : (u.playTime || 0),
        createdAt: u.creado_en  || u.createdAt || new Date().toISOString(),
        tienePIN:  u.tiene_pin === 1 || u.tiene_pin === true
    };
}

/* ── Indicador ───────────────────────────────────────────────────── */
function epMakeInd() {
    var el = document.createElement('div');
    el.style.cssText = 'position:fixed;bottom:10px;right:10px;z-index:8000;padding:4px 11px;border-radius:20px;font-size:11px;font-weight:700;box-shadow:0 2px 8px rgba(0,0,0,.2)';
    document.body.appendChild(el);
    return el;
}

/* ══════════════════════════════════════════════════════════════════
   ARRANQUE
   ══════════════════════════════════════════════════════════════════ */
window.removeEventListener('DOMContentLoaded', initializeApp);

window.addEventListener('DOMContentLoaded', async function () {
    if (typeof initializeVoiceRecognition === 'function') initializeVoiceRecognition();

    var ind = epMakeInd();
    try {
       // FIX: Intenta conectar primero, y si falla por la barra, intenta la alternativa
        let testRes = await fetch(EP_API + '/lista', { signal: AbortSignal.timeout(2500) });
        if (testRes.status === 404) {
            await fetch(EP_API + '/usuarios/', { signal: AbortSignal.timeout(2500) });
        }
        EP_BACK = true;
        ind.textContent = '🟢 BD Conectada';
        ind.style.background = '#d4edda'; ind.style.color = '#155724';
    } catch (_) {
        ind.textContent = '🟡 Modo Local';
        ind.style.background = '#fff3cd'; ind.style.color = '#856404';
    }

    /* Pregunta secreta usuario */
    var ps = document.getElementById('userPreguntaSecreta');
    if (ps) ps.addEventListener('change', function () {
        var g = document.getElementById('userRespGrp');
        if (g) g.style.display = this.value ? 'block' : 'none';
    });

    /* Botón padre en bienvenida */
    var pb = document.getElementById('padreLoginBtn');
    if (pb) pb.addEventListener('click', function () { epAbrirPadreAuth(); });

    /* OCULTAR "Informe Padres" — solo el padre puede verlo desde su panel */
    var rpb = document.getElementById('parentReportBtn');
    if (rpb) rpb.style.display = 'none';

    await epLoadUsers();

    /* Restaurar sesión previa */
    if (epRestoreSesion()) return;

    showWelcomeScreen();
});

/* ══════════════════════════════════════════════════════════════════
   PERSISTENCIA DE SESIÓN
   ══════════════════════════════════════════════════════════════════ */
function epSaveSesion(u) {
    if (!u) { 
        localStorage.removeItem('ep_sesion'); 
        localStorage.removeItem('userId'); // Limpiamos también este
        return; 
    } 
    localStorage.setItem('ep_sesion', JSON.stringify(u));
    localStorage.setItem('userId', u.id); // <--- Agregamos esto para el juego
}

function epRestoreSesion() {
    var raw = localStorage.getItem('ep_sesion');
    if (!raw) return false;
    try {
        var saved = JSON.parse(raw);
        var found = users.find(function (u) { return u.id === saved.id || u.id === parseInt(saved.id); });
        if (!found) return false;
        currentUser = found;
        epAbrirMain();
        return true;
    } catch (_) { return false; }
}
/* ══════════════════════════════════════════════════════════════════
   PERSISTENCIA DE SESIÓN
   ══════════════════════════════════════════════════════════════════ */

// ... aquí dejas epSaveSesion y epRestoreSesion ...

/* ══════════════════════════════════════════════════════════════════
   PERSISTENCIA DE SESIÓN
   ══════════════════════════════════════════════════════════════════ */

// ... aquí dejas epSaveSesion y epRestoreSesion ...

function cerrarSesion() {
    // 1. Borramos las llaves que identificamos en tu captura
    localStorage.removeItem('ep_sesion');
    localStorage.removeItem('session_token');
    localStorage.removeItem('userId');
    localStorage.removeItem('admin_token'); // También este por seguridad

    // 2. Limpiamos variables de ejecución
    window.usuarioActualId = null;
    if (typeof currentUser !== 'undefined') currentUser = null;

    // 3. Mandamos al usuario al inicio
    window.location.href = '/'; 
}
/* ══════════════════════════════════════════════════════════════════
   CARGAR USUARIOS
   ══════════════════════════════════════════════════════════════════ */
async function epLoadUsers() {
    if (EP_BACK) {
        try {
            var data = await epFetch('/lista');
            users = data.map(epNorm);
            localStorage.setItem('eduplay_users', JSON.stringify(users));
            return;
        } catch (_) {}
    }
    var s = localStorage.getItem('eduplay_users');
    users = s ? JSON.parse(s) : [];
}

loadUsers = function () {
    var s = localStorage.getItem('eduplay_users');
    users = s ? JSON.parse(s) : [];
};

var _origShow = showWelcomeScreen;
showWelcomeScreen = async function () {
    await epLoadUsers();
    _origShow();
};

/* ══════════════════════════════════════════════════════════════════
   ABRIR PANTALLA PRINCIPAL
   ══════════════════════════════════════════════════════════════════ */
function epAbrirMain() {
    var wo  = document.getElementById('welcomeOverlay');
    var umm = document.getElementById('userManagementModal');
    var mc  = document.getElementById('mainContainer');
    if (wo)  wo.style.display  = 'none';
    if (umm) umm.style.display = 'none';
    if (mc)  mc.style.display  = 'flex';
    var lb = document.getElementById('logoutBtn');
    if (lb) lb.style.display = 'flex';
    if (typeof updateCurrentUserDisplay === 'function') updateCurrentUserDisplay();
    if (typeof loadUserAchievements     === 'function') loadUserAchievements();
    if (typeof loadActivityHistory      === 'function') loadActivityHistory();
    if (typeof renderUserList           === 'function') renderUserList();
    epSaveSesion(currentUser);
}

/* ══════════════════════════════════════════════════════════════════
   saveUsers — local + backend sync
   ══════════════════════════════════════════════════════════════════ */
var _origSaveUsers = saveUsers;
saveUsers = function () {
    _origSaveUsers();
    if (!EP_BACK || !currentUser || String(currentUser.id).startsWith('guest')) return;
    epFetch('/usuarios/' + currentUser.id, 'PUT', {
        estrellas: currentUser.stars, tiempo_juego: currentUser.playTime
    }).catch(function () {});
};

/* ══════════════════════════════════════════════════════════════════
   saveUser — FIX: avatar correcto + navegación correcta
   ══════════════════════════════════════════════════════════════════ */
var _origSaveUser = saveUser;
saveUser = async function () {
    var nameEl = document.getElementById('userName');
    var ageEl  = document.getElementById('userAge');
    /* FIX: leer avatar del input de texto, NO de .avatar-option.selected */
    var avatEl = document.getElementById('userAvatar');
    var pinEl  = document.getElementById('userPin');
    var pregEl = document.getElementById('userPreguntaSecreta');
    var respEl = document.getElementById('userRespuesta');

    var name     = nameEl  ? nameEl.value.trim() : '';
    var age      = parseInt(ageEl  ? ageEl.value  : '0');
    /* FIX clave: asegurar que avatar tiene valor */
    var avatar   = (avatEl && avatEl.value.trim()) ? avatEl.value.trim() : '🎮';
    var pin      = (pinEl  ? String(pinEl.value).replace(/\D/g, '') : '');
    var pregunta = (pregEl ? pregEl.value : '');
    var respuesta= (respEl ? respEl.value.trim() : '');

    if (name.length < 2)        { alert('El nombre debe tener al menos 2 caracteres'); return; }
    if (!age || age < 3 || age > 16) { alert('La edad debe estar entre 3 y 16 años'); return; }
    if (pin && pin.length !== 4) { alert('El PIN debe tener exactamente 4 dígitos numéricos'); return; }

    if (!EP_BACK) {
        /* Modo local: parchar avatar también en función original */
        if (avatEl) avatEl.value = avatar;
        _origSaveUser();
        /* FIX: navegar a main después de crear */
        setTimeout(function () {
            if (currentUser) epAbrirMain();
        }, 150);
        return;
    }

    try {
        var u, payload = { nombre: name, edad: age, avatar: avatar };
        if (pin)      payload.pin = pin;
        if (pregunta) { payload.pregunta_secreta = pregunta; payload.respuesta_secreta = respuesta; }

        if (editingUserId) {
            var updated = await epFetch('/usuarios/' + editingUserId, 'PUT', payload);
            u = epNorm(updated);
            var idx = users.findIndex(function (x) { return x.id === editingUserId; });
            if (idx >= 0) users[idx] = u; else users.push(u);
        } else {
            var nuevo = await epFetch('/usuarios', 'POST', payload);
            u = epNorm(nuevo);
            users.push(u);
        }

        localStorage.setItem('eduplay_users', JSON.stringify(users));
        if (typeof cancelEditUser === 'function') cancelEditUser();

        currentUser = u;
        /* FIX: abrir main directamente */
        epAbrirMain();

    } catch (err) {
        alert('Error al guardar: ' + err.message);
    }
};

/* ══════════════════════════════════════════════════════════════════
   selectUser — pedir PIN si tiene, luego abrir main
   ══════════════════════════════════════════════════════════════════ */
var _origSelectUser = selectUser;
selectUser = function (userId) {
    var uid = parseInt(userId) || userId;
    var u   = users.find(function (x) { return x.id === uid || x.id === userId; });
    if (!u) { _origSelectUser(userId); return; }

    if (EP_BACK && u.tienePIN) {
        epPinAbrir(u, function () {
            currentUser = u;
            epAbrirMain();
        });
        return;
    }
    currentUser = u;
    epAbrirMain();
};

/* logout limpia sesión */
var _origLogout = logout;
logout = function () {
    epSaveSesion(null);
    _origLogout();
};

/* deleteUser backend */
document.addEventListener('click', async function (e) {
    if (e.target && e.target.id === 'confirmDelete') {
        if (typeof userToDelete !== 'undefined' && userToDelete && EP_BACK) {
            try { await epFetch('/usuarios/' + userToDelete, 'DELETE'); } catch (_) {}
        }
    }
}, true);

/* addStars */
var _origAddStars = addStars;
addStars = function (count) {
    _origAddStars(count);
    if (!EP_BACK || !currentUser || String(currentUser.id).startsWith('guest')) return;
    epFetch('/usuarios/' + currentUser.id + '/puntuaciones', 'POST', {
        area: window._epAct || 'general', puntuacion: Math.min(100, count * 25),
        correctas: count, total: count
    }).catch(function () {});
};

if (typeof recordActivity !== 'undefined') {
    var _origRec = recordActivity;
    recordActivity = function (act, type, res) {
        res = res || 'completado';
        _origRec(act, type, res);
        window._epAct = act;
        if (!EP_BACK || !currentUser || String(currentUser.id).startsWith('guest')) return;
        epFetch('/usuarios/' + currentUser.id + '/historial', 'POST', {
            actividad: act, tipo_juego: type, resultado: res, estrellas: 1
        }).catch(function () {});
    };
}

/* ══════════════════════════════════════════════════════════════════
   PIN MODAL — alumno
   ══════════════════════════════════════════════════════════════════ */
var _pinBuf = '', _pinUid = null, _pinCb = null, _recToken = null;

function epPinAbrir(u, cb) {
    if (!u || u instanceof Event) u = {};
    _pinBuf = ''; 
    _pinCb = cb;
    
    // Si recibe solo el número de ID (ej. 11), buscamos los datos reales del estudiante
    if (typeof u === 'number' || typeof u === 'string') {
        _pinUid = u;
        var estudianteEncontrado = users.find(x => String(x.id) === String(u));
        if (estudianteEncontrado) u = estudianteEncontrado; 
        else u = { id: u, name: 'Estudiante', avatar: '🎮' };
    } else {
        _pinUid = u.id || u.id_usuario || window.epPinId; 
    }
    
    var nombreEstudiante = u.name || u.nombre || 'Estudiante';
    epPinDots('pd', '');
    
    document.getElementById('epPinAvatar').textContent = u.avatar || '🎮';
    document.getElementById('epPinName').textContent   = '¡Hola, ' + nombreEstudiante + '!';
    document.getElementById('epPinErr').textContent    = '';
    document.getElementById('epPinModal').style.display = 'flex';
    
    var btnEntrar = document.getElementById('btn-entrar');
    if (btnEntrar) btnEntrar.setAttribute('data-estudiante-id', _pinUid);
}

window.epPinClose = function () {
    document.getElementById('epPinModal').style.display = 'none';
    _pinBuf = ''; _pinUid = null; _pinCb = null;
};
window.epPinKey = function (d) {
    if (_pinBuf.length >= 4) return;
    _pinBuf += d; epPinDots('pd', _pinBuf);
    if (_pinBuf.length === 4) setTimeout(epPinConfirmar, 200);
};
window.epPinDel = function () { _pinBuf = _pinBuf.slice(0, -1); epPinDots('pd', _pinBuf); };
window.epPinOk  = epPinConfirmar;

function epPinDots(prefix, buf) {
    for (var i = 0; i < 4; i++) {
        var d = document.getElementById(prefix + i);
        if (d) d.className = 'pin-dot' + (i < buf.length ? ' on' : '');
    }
}

async function epPinConfirmar() {
    if (_pinBuf.length !== 4) { 
        document.getElementById('epPinErr').textContent = 'Ingresa 4 dígitos'; 
        return; 
    }
    if (!EP_BACK) { 
        document.getElementById('epPinModal').style.display = 'none'; 
        if (_pinCb) _pinCb(); 
        return; 
    }
    try {
        // ----------------------------------------------------
        // PARCHE ANTI-UNDEFINED: Atrapamos el ID sí o sí
        // ----------------------------------------------------
        var uid = _pinUid; // Intentar método original
        
        if (!uid || uid === 'undefined' || uid === 'null') {
            uid = window.epPinId; // Intentar variable de la memoria global
        }
        if (!uid || uid === 'undefined' || uid === 'null') {
            var btn = document.getElementById('btn-entrar');
            if (btn) uid = btn.getAttribute('data-estudiante-id'); // Intentar leer el botón
        }
        
        // Si después de todo sigue sin ID, detenemos el proceso para evitar el Error 405
        if (!uid || uid === 'undefined' || uid === 'null') {
            document.getElementById('epPinErr').textContent = 'Error: ID no encontrado. Por favor cierra y vuelve a seleccionar tu perfil.';
            _pinBuf = ''; epPinDots('pd', '');
            return;
        }
        // ----------------------------------------------------

        // Ahora sí, hacemos la petición con el ID seguro
        var r = await epFetch('/usuarios/' + uid + '/login', 'POST', { pin: _pinBuf });
        
        if (r.ok) { 
            document.getElementById('epPinModal').style.display = 'none'; 
            
            if (_pinCb) {
                _pinCb(); 
            } else {
                // Si falta la función callback, forzamos la entrada al sistema
                localStorage.setItem('session_token', r.session_token);
                if (typeof selectUser === 'function') selectUser(parseInt(uid));
                
                var overlay = document.getElementById('welcomeOverlay');
                var mainCont = document.getElementById('mainContainer');
                if (overlay) overlay.style.display = 'none';
                if (mainCont) mainCont.style.display = 'flex';
            }
        } else { 
            document.getElementById('epPinErr').textContent = 'PIN incorrecto ❌'; 
            _pinBuf = ''; 
            epPinDots('pd', ''); 
        }
    } catch (e) { 
        document.getElementById('epPinErr').textContent = e.message || 'Error de conexión'; 
        _pinBuf = ''; 
        epPinDots('pd', ''); 
    }
}

window.epPinOlvide = async function () {
    if (!_pinUid || !EP_BACK) { document.getElementById('epPinErr').textContent = 'Necesitas el servidor activo'; return; }
    try {
        var r = await epFetch('/usuarios/' + _pinUid + '/pregunta');
        document.getElementById('epRecPregunta').textContent = r.pregunta;
        document.getElementById('epRecResp').value = '';
        document.getElementById('epRecErr').textContent = '';
        document.getElementById('epRecModal').style.display = 'flex';
    } catch (e) { document.getElementById('epPinErr').textContent = 'Sin pregunta de recuperación configurada'; }
};

window.epRecVerificar = async function () {
    var resp = document.getElementById('epRecResp').value.trim();
    var err  = document.getElementById('epRecErr');
    if (!resp) { err.textContent = 'Escribe tu respuesta'; return; }
    try {
        var r = await epFetch('/usuarios/' + _pinUid + '/verificar-pregunta', 'POST', { respuesta: resp });
        _recToken = r.token;
        document.getElementById('epRecModal').style.display = 'none';
        _nPinBuf = ''; epPinDots('npd', '');
        document.getElementById('epNPinErr').textContent = '';
        document.getElementById('epNewPinModal').style.display = 'flex';
    } catch (e) { err.textContent = e.message; }
};

/* Nuevo PIN */
var _nPinBuf = '';
window.epNPinKey = function (d) {
    if (_nPinBuf.length >= 4) return;
    _nPinBuf += d; epPinDots('npd', _nPinBuf);
    if (_nPinBuf.length === 4) setTimeout(epNPinConfirmar, 200);
};
window.epNPinDel = function () { _nPinBuf = _nPinBuf.slice(0, -1); epPinDots('npd', _nPinBuf); };
window.epNPinOk  = epNPinConfirmar;

async function epNPinConfirmar() {
    if (_nPinBuf.length !== 4) { document.getElementById('epNPinErr').textContent = '4 dígitos requeridos'; return; }
    try {
        await epFetch('/usuarios/' + _pinUid + '/reset-pin', 'POST', { token: _recToken, nuevo_pin: _nPinBuf });
        document.getElementById('epNewPinModal').style.display = 'none';
        document.getElementById('epPinErr').textContent = '✅ PIN cambiado. Ingresa tu nuevo PIN.';
        _nPinBuf = ''; epPinDots('npd', '');
    } catch (e) { document.getElementById('epNPinErr').textContent = e.message; }
}

/* ══════════════════════════════════════════════════════════════════
   AUTH PADRE
   ══════════════════════════════════════════════════════════════════ */
function epAbrirPadreAuth() {
    paTab('login');
    document.getElementById('epPadreAuth').style.display = 'flex';
}
window.paTab = function (t) {
    document.getElementById('paFormLogin').style.display = t === 'login' ? 'block' : 'none';
    document.getElementById('paFormReg').style.display   = t === 'reg'   ? 'block' : 'none';
    document.getElementById('paFormRec').style.display   = t === 'rec'   ? 'block' : 'none';
    document.getElementById('paTabL').className = 'ep-tab' + (t === 'login' ? ' active' : '');
    document.getElementById('paTabR').className = 'ep-tab' + (t === 'reg'   ? ' active' : '');
    if (t === 'rec') { _paRecStep = 1; document.getElementById('paRecRespGrp').style.display = 'none'; document.getElementById('paRecNuevoGrp').style.display = 'none'; document.getElementById('paRecBtn').textContent = 'Buscar cuenta'; }
};

window.paDoLogin = async function () {
    var email = document.getElementById('paEmail').value.trim();
    var pin   = document.getElementById('paPin').value.replace(/\D/g, '');
    var err   = document.getElementById('paLoginErr');
    if (!email) { err.textContent = 'Ingresa tu email'; return; }
    if (pin.length !== 4) { err.textContent = 'PIN de 4 dígitos requerido'; return; }
    if (!EP_BACK) { err.textContent = '⚠️ Servidor no disponible. Inicia app.py'; return; }
    try {
        var r = await epFetch('/padres/login', 'POST', { email: email, pin: pin });
        EP_PADRE = r.padre;
        document.getElementById('epPadreAuth').style.display = 'none';
        epAbrirPanelPadre();
    } catch (e) { err.textContent = e.message; }
};

window.paDoRegistro = async function () {
    var nombre   = document.getElementById('paRegNombre').value.trim();
    var email    = document.getElementById('paRegEmail').value.trim();
    var pin      = document.getElementById('paRegPin').value.replace(/\D/g, '');
    var pregunta = document.getElementById('paRegPregunta').value;
    var respuesta= document.getElementById('paRegResp').value.trim();
    var err      = document.getElementById('paRegErr');
    if (!nombre)           { err.textContent = 'Nombre requerido'; return; }
    if (!email)            { err.textContent = 'Email requerido'; return; }
    if (pin.length !== 4)  { err.textContent = 'PIN de 4 dígitos requerido'; return; }
    if (!pregunta)         { err.textContent = 'Elige una pregunta secreta'; return; }
    if (!respuesta)        { err.textContent = 'Escribe tu respuesta secreta'; return; }
    if (!EP_BACK)          { err.textContent = '⚠️ Servidor no disponible'; return; }
    try {
        var r = await epFetch('/padres/registro', 'POST', { nombre: nombre, email: email, pin: pin, pregunta_secreta: pregunta, respuesta_secreta: respuesta });
        EP_PADRE = { id: r.id, nombre: r.nombre, email: r.email };
        document.getElementById('epPadreAuth').style.display = 'none';
        epAbrirPanelPadre();
    } catch (e) { err.textContent = e.message; }
};

var _paRecStep = 1, _paRecToken = null, _paRecId = null;
window.paDoRec = async function () {
    var email    = document.getElementById('paRecEmail').value.trim();
    var respuesta= document.getElementById('paRecResp').value.trim();
    var nuevoPin = document.getElementById('paRecNuevoPin').value.replace(/\D/g, '');
    var err      = document.getElementById('paRecErr');
    if (_paRecStep === 1) {
        if (!email) { err.textContent = 'Ingresa tu email'; return; }
        document.getElementById('paRecRespGrp').style.display = 'block';
        document.getElementById('paRecBtn').textContent = 'Verificar respuesta';
        err.textContent = ''; _paRecStep = 2; return;
    }
    if (_paRecStep === 2) {
        if (!respuesta) { err.textContent = 'Escribe tu respuesta'; return; }
        if (!EP_BACK)   { err.textContent = 'Servidor no disponible'; return; }
        try {
            var r = await epFetch('/padres/verificar-pregunta', 'POST', { email: email, respuesta: respuesta });
            _paRecToken = r.token; _paRecId = r.padre_id;
            document.getElementById('paRecNuevoGrp').style.display = 'block';
            document.getElementById('paRecBtn').textContent = 'Guardar nuevo PIN';
            err.textContent = ''; _paRecStep = 3;
        } catch (e) { err.textContent = e.message; }
        return;
    }
    if (_paRecStep === 3) {
        if (nuevoPin.length !== 4) { err.textContent = 'PIN de 4 dígitos requerido'; return; }
        try {
            await epFetch('/padres/reset-pin', 'POST', { token: _paRecToken, nuevo_pin: nuevoPin });
            alert('✅ PIN cambiado. Ya puedes iniciar sesión.');
            _paRecStep = 1; paTab('login');
        } catch (e) { err.textContent = e.message; }
    }
};

/* ══════════════════════════════════════════════════════════════════
   PANEL PADRE
   ══════════════════════════════════════════════════════════════════ */
async function epAbrirPanelPadre() {
    if (!EP_PADRE) return;
    document.getElementById('ppNombre').textContent = EP_PADRE.nombre;
    document.getElementById('ppEmail').textContent  = EP_PADRE.email;

    /* ocultar welcome */
    var wo = document.getElementById('welcomeOverlay');
    var mc = document.getElementById('mainContainer');
    if (wo) wo.style.display = 'none';
    if (mc) mc.style.display = 'none';

    await ppCargarHijos();
    ppCargarInfBtns();
    document.getElementById('epPanelPadre').style.display = 'flex';
}

window.ppMostrarTab = function (t) {
    document.querySelectorAll('.pp-tab').forEach(function (b) { b.classList.remove('active'); });
    document.querySelectorAll('.pp-pane').forEach(function (p) { p.classList.remove('active'); });
    var btn = document.querySelector('.pp-tab[onclick="ppMostrarTab(\'' + t + '\')"]');
    var pane = document.getElementById('ppTab' + t.charAt(0).toUpperCase() + t.slice(1));
    if (btn)  btn.classList.add('active');
    if (pane) pane.classList.add('active');
    if (t === 'informes') ppCargarInfBtns();
};

window.ppSalir = function () {
    EP_PADRE = null;
    document.getElementById('epPanelPadre').style.display = 'none';
    showWelcomeScreen();
};
window.ppMostrarWelcome = function () { showWelcomeScreen(); };

async function ppCargarHijos() {
    var cont = document.getElementById('ppHijosLista');
    if (!cont) return;
    if (!EP_BACK) { cont.innerHTML = '<p style="color:#E67E22;text-align:center;padding:20px">⚠️ Servidor no disponible</p>'; return; }
    try {
        var hijos = await epFetch('/padres/' + EP_PADRE.id + '/hijos');
        if (!hijos.length) {
            cont.innerHTML = '<p style="color:#888;text-align:center;padding:24px">Sin hijos registrados.<br>Ve a la pestaña <b>➕ Agregar</b></p>';
            return;
        }
        cont.innerHTML = hijos.map(function (h) {
            return '<div class="hijo-card">'
                + '<div class="hijo-avatar">' + h.avatar + '</div>'
                + '<div class="hijo-info">'
                +   '<div class="hijo-name">' + h.nombre + '</div>'
                +   '<div class="hijo-stats">' + h.edad + ' años · ⭐ ' + h.estrellas + ' · ⏱ ' + h.tiempo_juego + ' min</div>'
                + '</div>'
                + '<button onclick="ppJugarHijo(' + h.id + ')" style="padding:6px 10px;background:#27AE60;color:#fff;border:none;border-radius:8px;cursor:pointer;font-size:.8rem;margin-right:4px">▶ Jugar</button>'
                + '<button onclick="ppElimHijo(' + h.id + ',\'' + h.nombre + '\')" style="padding:6px 10px;background:#E74C3C;color:#fff;border:none;border-radius:8px;cursor:pointer;font-size:.8rem">🗑</button>'
                + '</div>';
        }).join('');
    } catch (e) { cont.innerHTML = '<p style="color:#E74C3C">' + e.message + '</p>'; }
}

window.ppJugarHijo = async function (uid) {
    await epLoadUsers();
    var u = users.find(function (x) { return x.id === uid || x.id === parseInt(uid); });
    if (!u) {
        try { var raw = await epFetch('/usuarios/' + uid); u = epNorm(raw); users.push(u); localStorage.setItem('eduplay_users', JSON.stringify(users)); }
        catch (e) { alert('Error: ' + e.message); return; }
    }
    document.getElementById('epPanelPadre').style.display = 'none';
    currentUser = u;
    epAbrirMain();
};

window.ppElimHijo = async function (uid, nombre) {
    if (!confirm('¿Eliminar a ' + nombre + '? Se perderán todos sus datos.')) return;
    try { await epFetch('/usuarios/' + uid, 'DELETE'); await ppCargarHijos(); }
    catch (e) { alert('Error: ' + e.message); }
};

window.ppGuardarHijo = async function () {
    var nombre = document.getElementById('ppHNombre').value.trim();
    var edad   = parseInt(document.getElementById('ppHEdad').value || '0');
    var avatar = document.getElementById('ppHAvatar').value.trim() || '🦊';
    var pin    = document.getElementById('ppHPin').value.replace(/\D/g, '');
    var err    = document.getElementById('ppHErr');
    err.style.color = '#E74C3C';
    if (!nombre)              { err.textContent = 'Nombre requerido'; return; }
    if (!edad || edad < 3 || edad > 16) { err.textContent = 'Edad entre 3 y 16'; return; }
    if (pin && pin.length !== 4) { err.textContent = 'PIN debe tener 4 dígitos'; return; }
    try {
        var payload = { nombre: nombre, edad: edad, avatar: avatar, padre_id: EP_PADRE.id };
        if (pin) payload.pin = pin;
        var nuevo = await epFetch('/usuarios', 'POST', payload);
        var u = epNorm(nuevo); users.push(u); localStorage.setItem('eduplay_users', JSON.stringify(users));
        document.getElementById('ppHNombre').value = '';
        document.getElementById('ppHEdad').value   = '';
        document.getElementById('ppHPin').value    = '';
        err.style.color = '#27AE60'; err.textContent = '✅ Hijo agregado correctamente';
        setTimeout(function () { err.textContent = ''; }, 3000);
        await ppCargarHijos();
    } catch (e) { err.textContent = e.message; }
};

/* ── Informes padre ────────────────────────────────────────────── */
async function ppCargarInfBtns() {
    var cont = document.getElementById('ppInfBtns');
    if (!cont || !EP_BACK) return;
    try {
        var hijos = await epFetch('/padres/' + EP_PADRE.id + '/hijos');
        cont.innerHTML = hijos.map(function (h) {
            return '<button onclick="ppVerInforme(' + h.id + ',\'' + h.nombre + '\')" '
                + 'style="padding:8px 14px;background:#3498DB;color:#fff;border:none;border-radius:20px;cursor:pointer;font-size:.85rem">'
                + h.avatar + ' ' + h.nombre + '</button>';
        }).join('');
    } catch (_) {}
}

window.ppVerInforme = async function (uid, nombre) {
    var det = document.getElementById('ppInfDetalle');
    det.innerHTML = '<div style="text-align:center;padding:20px;color:#888">🔄 Cargando informe de ' + nombre + '...</div>';
    try {
        var d = await epFetch('/usuarios/' + uid + '/resumen');
        var knn = d.clasificacion;
        var C = { 'Crítico': '#E74C3C', 'En Desarrollo': '#E67E22', 'Básico': '#F1C40F', 'Competente': '#2ECC71', 'Excelente': '#3498DB' };
        var knnH = knn
            ? '<div style="border-left:4px solid ' + (C[knn.rango_etiqueta] || '#888') + ';padding:10px 14px;background:#f8f9fa;border-radius:0 8px 8px 0;margin:10px 0"><strong>Clasificación IA:</strong> ' + knn.rango_etiqueta + ' (' + knn.puntuacion_prom + '/100)<br><small style="color:#666">' + knn.recomendacion + '</small></div>'
            : '<p style="color:#888;font-size:.88rem">Sin clasificación IA aún (el alumno debe jugar más partidas)</p>';
        var areas = Object.entries(d.promedios || {}).map(function (kv) {
            var a = kv[0], v = kv[1], pc = Math.min(100, v);
            var bc = v >= 75 ? '#2ECC71' : v >= 60 ? '#F1C40F' : '#E74C3C';
            return '<div style="display:grid;grid-template-columns:110px 1fr 36px;align-items:center;gap:8px;margin-bottom:5px">'
                + '<span style="font-size:.82rem">' + a + '</span>'
                + '<div style="background:#e9ecef;border-radius:8px;height:9px;overflow:hidden"><div style="width:' + pc + '%;background:' + bc + ';height:100%;border-radius:8px"></div></div>'
                + '<span style="font-size:.8rem;font-weight:600">' + v + '</span></div>';
        }).join('');
        det.innerHTML = '<div style="border:1px solid #e0e0e0;border-radius:12px;padding:16px">'
            + '<h4 style="margin:0 0 10px">📋 Informe de ' + nombre + '</h4>'
            + '<p style="color:#666;font-size:.9rem">⭐ ' + (d.usuario && d.usuario.estrellas || 0) + ' estrellas &nbsp;⏱ ' + (d.usuario && d.usuario.tiempo_juego || 0) + ' min</p>'
            + knnH
            + '<h5 style="margin:12px 0 8px;font-size:.88rem">📊 Promedio por área</h5>'
            + areas + '</div>';
    } catch (e) { det.innerHTML = '<p style="color:#E74C3C">' + e.message + '</p>'; }
};

/* ══════════════════════════════════════════════════════════════════
   KNN en informe del alumno (solo visible desde panel padre)
   Inyectar tab KNN cuando el padre abre el informe desde su panel
   ══════════════════════════════════════════════════════════════════ */
document.addEventListener('click', function (e) {
    /* Detectar click en tab KNN dinámico */
    var btn = e.target.closest('.report-tab');
    if (btn && btn.dataset.tab === 'knn') {
        document.querySelectorAll('.report-tab').forEach(function (t) { t.classList.remove('active'); });
        document.querySelectorAll('.report-tab-content').forEach(function (t) { t.classList.remove('active'); });
        btn.classList.add('active');
        var pane = document.getElementById('knnTab');
        if (pane) { pane.classList.add('active'); epRenderKNN(currentUser && currentUser.id, '#knn-inner'); }
    }
});

function epInjectKNNTab() {
    if (document.getElementById('knnTab')) return;
    var tabs = document.querySelector('.report-tabs');
    var cont = document.querySelector('.report-content');
    if (!tabs || !cont) return;
    var btn = document.createElement('button');
    btn.className = 'report-tab'; btn.dataset.tab = 'knn'; btn.textContent = '🤖 IA Clasificación';
    tabs.appendChild(btn);
    var pane = document.createElement('div');
    pane.className = 'report-tab-content'; pane.id = 'knnTab';
    pane.innerHTML = '<div id="knn-inner"><p style="padding:20px;color:#888;text-align:center">Haz clic en la pestaña 🤖 para cargar la clasificación IA</p></div>';
    cont.appendChild(pane);
}

/* Exponer para que el padre pueda abrir el informe del alumno */
window.epAbrirInformeAlumno = function (uid) {
    /* buscar usuario, asignar temporalmente como currentUser del informe */
    var target = users.find(function (u) { return u.id === uid || u.id === parseInt(uid); });
    if (!target) return;
    var prev = currentUser;
    currentUser = target;
    if (typeof renderParentReport === 'function') {
        renderParentReport();
        epInjectKNNTab();
    }
    document.getElementById('parentReportModal').style.display = 'flex';
    /* Al cerrar, restaurar */
    var closeBtn = document.getElementById('closeParentReport');
    if (closeBtn) {
        var _once = function () { currentUser = prev; closeBtn.removeEventListener('click', _once); };
        closeBtn.addEventListener('click', _once);
    }
};

async function epRenderKNN(uid, sel) {
    var el = document.querySelector(sel);
    if (!el) return;

    // 🛡️ ESCUDO AÑADIDO: Evita 404 si el reporte se abre sin alumno (ID vacío, nulo o indefinido)
    if (!uid || uid === 'undefined' || uid === 'null') {
        el.innerHTML = '<p style="color:#E74C3C;padding:20px;text-align:center">⚠️ Error: ID de estudiante no encontrado.</p>';
        return;
    }

    el.innerHTML = '<div style="text-align:center;padding:30px;color:#888">🔄 Clasificando con IA...</div>';
    
    if (!EP_BACK) { 
        el.innerHTML = '<p style="color:#E67E22;padding:20px;text-align:center">⚠️ Inicia <code>python app.py</code> para usar la clasificación IA.</p>'; 
        return; 
    }
    
    try {
        var d = await epFetch('/usuarios/' + uid + '/clasificar');
        var C = { 'Crítico': '#E74C3C', 'En Desarrollo': '#E67E22', 'Básico': '#F1C40F', 'Competente': '#2ECC71', 'Excelente': '#3498DB' };
        var c = C[d.etiqueta] || '#888';
        
        var aH = Object.entries(d.areas || {}).map(function (kv) {
            var a = kv[0], v = kv[1], pc = Math.min(100, v);
            var bc = v >= 90 ? '#3498DB' : v >= 75 ? '#2ECC71' : v >= 60 ? '#F1C40F' : v >= 40 ? '#E67E22' : '#E74C3C';
            return '<div style="display:grid;grid-template-columns:120px 1fr 48px;align-items:center;gap:8px;margin-bottom:6px"><span style="font-size:.82rem">' + a + '</span><div style="background:#e9ecef;border-radius:8px;height:10px;overflow:hidden"><div style="width:' + pc + '%;background:' + bc + ';height:100%;border-radius:8px"></div></div><span style="font-size:.8rem;font-weight:600">' + v + '</span></div>';
        }).join('');
        
        var pH = Object.entries(d.probabilidades || {}).map(function (kv) {
            var l = kv[0], p = kv[1];
            return '<div style="display:grid;grid-template-columns:130px 1fr 52px;align-items:center;gap:8px;margin-bottom:6px"><span style="font-size:.82rem">' + l + '</span><div style="background:#e9ecef;border-radius:8px;height:10px;overflow:hidden"><div style="width:' + (p * 100).toFixed(1) + '%;background:' + (C[l] || '#888') + ';height:100%;border-radius:8px"></div></div><span style="font-size:.8rem;font-weight:600">' + (p * 100).toFixed(1) + '%</span></div>';
        }).join('');
        
        el.innerHTML = '<div style="padding:16px">'
            + '<div style="display:flex;align-items:center;gap:14px;padding:14px;background:#f8f9fa;border-radius:10px;margin-bottom:14px;border-left:5px solid ' + c + '">'
            + '<span style="font-size:2.5rem">' + d.emoji + '</span>'
            + '<div><div style="font-size:1.4rem;font-weight:800;color:' + c + '">' + d.etiqueta + '</div><div style="color:#666">Promedio: <strong>' + d.puntuacion_promedio + '</strong> / 100</div></div></div>'
            + '<div style="background:#eef6ff;border-left:4px solid #3498DB;padding:10px 14px;border-radius:6px;margin-bottom:14px;font-size:.9rem">💡 ' + d.recomendacion + '</div>'
            + '<h4 style="font-size:.95rem;font-weight:700;color:#2c3e50;margin:14px 0 8px">📊 Puntuación por Área</h4>' + aH
            + '<h4 style="font-size:.95rem;font-weight:700;color:#2c3e50;margin:14px 0 8px">🤖 Probabilidades KNN</h4>' + pH + '</div>';
            
    } catch (e) {
        el.innerHTML = '<p style="color:#E74C3C;padding:20px;text-align:center">⚠️ ' + e.message + '</p>';
    }
}

// === MOTOR DE JUEGOS CONECTADO A NEON DB ===
window.preguntasActuales = [];
window.preguntaIndice = 0;
window.puntajeActual = 0;
window.tiempoInicio = 0;
window.materiaActual = '';

// 1. Sobrescribimos la función original loadGame
window.loadGame = async function(activity, gameType) {
    const gameArea = document.getElementById('gameArea');
    gameArea.innerHTML = '<h3 style="color:#3498DB;">Cargando preguntas mágicas... ⏳</h3>';
    
    window.materiaActual = activity; // Guardamos qué materia está jugando
    let grado = window.gradoSeleccionado || localStorage.getItem('userGrade') || 1; 

    try {
        const response = await fetch(`/api/juegos/${activity}/${grado}`);
        const preguntas = await response.json();
        
        if (!preguntas || preguntas.length === 0) {
            gameArea.innerHTML = `<p style="color:#7F8C8D;">Aún no hay preguntas de <b>${activity}</b> para <b>${grado}º Grado</b>.</p>`;
            return;
        }
        
        window.preguntasActuales = preguntas;
        window.preguntaIndice = 0;
        window.puntajeActual = 0;
        window.tiempoInicio = Date.now(); // ⏱️ Iniciamos el reloj
        
        document.getElementById('scoreDisplay').textContent = window.puntajeActual;
        mostrarPregunta();
        
    } catch (error) {
        console.error(error);
        gameArea.innerHTML = '<p style="color:#E74C3C;">Error conectando con la base de datos.</p>';
    }
};

// 2. Función para dibujar la pregunta en pantalla y GUARDAR AL TERMINAR
window.mostrarPregunta = async function() {
    const gameArea = document.getElementById('gameArea');
    
    // Si ya se acabaron las preguntas, GUARDAMOS LA PARTIDA
    if (window.preguntaIndice >= window.preguntasActuales.length) {
        const tiempoFin = Date.now();
        const tiempoSegundos = Math.floor((tiempoFin - window.tiempoInicio) / 1000); // ⏱️ Calculamos segundos
        
        gameArea.innerHTML = `<h3 style="color:#F2994A;">Guardando tu aventura... 🚀</h3>`;
        
        // Obtén el ID del usuario (ajusta esto si en tu api.js lo guardas con otro nombre)
        const userId = window.usuarioActualId || localStorage.getItem('userId') || 1;

        try {
            const res = await fetch('/api/juegos/guardar_partida', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    user_id: parseInt(userId),
                    subject: window.materiaActual,
                    points: window.puntajeActual,
                    time_taken_seconds: tiempoSegundos
                })
            });
            
            const data = await res.json();
            
            if (data.success) {
                // Dibujamos la pantalla de victoria con el MEJOR RÉCORD
                gameArea.innerHTML = `
                    <h2 style="color:#27AE60; font-size:30px;">¡Juego Terminado! 🎉</h2>
                    <p style="font-size:20px;">Ganaste <b>⭐ ${window.puntajeActual}</b> estrellas hoy.</p>
                    
                    <div style="background:#FFF3CD; color:#856404; padding:15px; border-radius:10px; margin: 20px auto; max-width: 400px;">
                        🏆 <b>Tu Récord en esta materia:</b> ${data.mejor_puntaje} estrellas
                    </div>
                    
                    <button class="ep-btn juicy-btn" style="background:#3498DB; color:white; margin-top:10px;" onclick="document.getElementById('closeGame').click()">Volver al Menú</button>
                `;
            } else {
                gameArea.innerHTML = `<p style="color:#E74C3C;">No pudimos guardar, pero ganaste ⭐ ${window.puntajeActual}</p>`;
            }
        } catch (e) {
            console.error(e);
            gameArea.innerHTML = `<p style="color:#E74C3C;">Error al conectar con el servidor.</p>`;
        }
        return;
    }
    
    // Dibujo normal de la pregunta si el juego sigue...
    const p = window.preguntasActuales[window.preguntaIndice];
    gameArea.innerHTML = `
        <h3 id="questionText" style="font-size:24px; margin-bottom:25px; color: #2C3E50;">${p.pregunta}</h3>
        <div id="optionsContainer" style="display:grid; grid-template-columns:1fr 1fr; gap:15px; max-width: 600px; margin: 0 auto;"></div>
        <div id="feedbackText" style="margin-top: 20px; font-weight: bold; font-size: 20px; min-height: 28px;"></div>
    `;
    
    const container = document.getElementById('optionsContainer');
    
    p.opciones.forEach((opcionTexto, index) => {
        const btn = document.createElement('button');
        btn.className = 'ep-btn juicy-btn';
        btn.style.padding = '15px';
        btn.style.fontSize = '18px';
        btn.style.background = '#f9f9f9';
        btn.style.color = '#333';
        btn.style.border = '2px solid #ddd';
        btn.textContent = opcionTexto;
        
        btn.onclick = () => verificarRespuesta(index, p.correcta, btn);
        container.appendChild(btn);
    });
};

// 3. Función para verificar si acertó
window.verificarRespuesta = function(indexSeleccionado, indexCorrecto, botonPresionado) {
    const feedback = document.getElementById('feedbackText');
    const botones = document.querySelectorAll('#optionsContainer button');
    
    botones.forEach(b => b.disabled = true);
    
    if (indexSeleccionado === indexCorrecto) {
        feedback.textContent = "¡Excelente! 🎉";
        feedback.style.color = "#27AE60";
        botonPresionado.style.background = "#27AE60";
        botonPresionado.style.color = "white";
        
        window.puntajeActual += 10;
        document.getElementById('scoreDisplay').textContent = window.puntajeActual;
    } else {
        feedback.textContent = "¡Casi! La próxima será ❌";
        feedback.style.color = "#E74C3C";
        botonPresionado.style.background = "#E74C3C";
        botonPresionado.style.color = "white";
        
        botones[indexCorrecto].style.background = "#27AE60";
        botones[indexCorrecto].style.color = "white";
    }
    
    setTimeout(() => {
        window.preguntaIndice++;
        mostrarPregunta();
    }, 2000);
};

console.log('✅ EduPlay Patch v4 | Backend:', EP_BACK);
