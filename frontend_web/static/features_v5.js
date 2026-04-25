/**
 * EduPlay Features v5
 * ===========================
 * Implementa las 10 funcionalidades requeridas:
 * 1. Registro con edad y grado escolar
 * 2. Iniciar sesión (email + PIN)
 * 3. Recuperar contraseña
 * 4. Ver perfil
 * 5. Editar perfil
 * 6. Elegir avatar inicial
 * 7. Crear perfil de tutor
 * 8. Reporte de tiempo de uso con IA
 * 9. Cerrar sesión
 * 10. Control de sesiones
 */

/* ══════════════════════════════════════════════════════════════════
   ESTADO GLOBAL
   ══════════════════════════════════════════════════════════════════ */
var EP_SESSION_TOKEN = localStorage.getItem('ep_session_token') || null;
var EP_SESSION_TIPO  = localStorage.getItem('ep_session_tipo')  || null; // 'alumno' | 'padre'
var EP_CURRENT_USER_DATA = null; // perfil completo desde backend

var GRADOS_ESCOLARES = [
    'Preescolar 1', 'Preescolar 2', 'Preescolar 3',
    '1° Primaria', '2° Primaria', '3° Primaria',
    '4° Primaria', '5° Primaria', '6° Primaria',
    '1° Secundaria', '2° Secundaria', '3° Secundaria'
];

var AVATARES_DEFAULT = [
    '🦊','🐱','🐼','🐶','🐸','🦄','🐯','🐧','🦋','🐙',
    '🦁','🐨','🐻','🦀','🐳','🦖','🦒','🐬','🦝','🦔'
];

/* ══════════════════════════════════════════════════════════════════
   UTILIDADES DE SESIÓN
   ══════════════════════════════════════════════════════════════════ */
function epV5SaveToken(token, tipo) {
    EP_SESSION_TOKEN = token;
    EP_SESSION_TIPO  = tipo;
    if (token) {
        localStorage.setItem('ep_session_token', token);
        localStorage.setItem('ep_session_tipo',  tipo);
    } else {
        localStorage.removeItem('ep_session_token');
        localStorage.removeItem('ep_session_tipo');
    }
}

function epV5GetHeaders() {
    var h = { 'Content-Type': 'application/json' };
    if (EP_SESSION_TOKEN) h['X-Session-Token'] = EP_SESSION_TOKEN;
    return h;
}

async function epV5Fetch(path, method, body) {
    var opts = { method: method || 'GET', headers: epV5GetHeaders() };
    if (body) opts.body = JSON.stringify(body);
    var res  = await fetch('/api' + path, opts);
    var data = await res.json();
    if (!res.ok) throw new Error(data.error || ('HTTP ' + res.status));
    return data;
}

/* ══════════════════════════════════════════════════════════════════
   MODAL HELPER
   ══════════════════════════════════════════════════════════════════ */
function epV5Modal(id) { return document.getElementById(id); }
function epV5Show(id)  { var m = epV5Modal(id); if (m) m.style.display = 'flex'; }
function epV5Hide(id)  { var m = epV5Modal(id); if (m) m.style.display = 'none'; }
function epV5Val(id)   { var el = document.getElementById(id); return el ? el.value.trim() : ''; }
function epV5Err(id, msg) { var el = document.getElementById(id); if (el) { el.textContent = msg || ''; el.style.display = msg ? 'block' : 'none'; } }

/* ══════════════════════════════════════════════════════════════════
   1 + 6. REGISTRO CON GRADO ESCOLAR Y AVATAR
   ══════════════════════════════════════════════════════════════════ */
function epV5AbrirRegistro() {
    epV5BuildRegistroModal();
    epV5Show('epV5RegModal');
}

function epV5BuildRegistroModal() {
    if (document.getElementById('epV5RegModal')) return; // ya existe

    var gradosOpts = GRADOS_ESCOLARES.map(function(g) {
        return '<option value="'+g+'">'+g+'</option>';
    }).join('');

    var avatarBtns = AVATARES_DEFAULT.map(function(a) {
        return '<button type="button" class="epv5-av-btn" data-av="'+a+'" onclick="epV5SelAvatar(this)">'+a+'</button>';
    }).join('');

    var html = `
    <div class="ep-overlay" id="epV5RegModal" style="display:none">
     <div class="ep-box" style="max-width:480px;max-height:92vh;overflow-y:auto">
      <button class="ep-close" onclick="epV5Hide('epV5RegModal')">×</button>
      <div style="text-align:center;margin-bottom:16px">
       <span style="font-size:2.4rem">🎓</span>
       <h3 style="margin:6px 0 0;color:#2c3e50">Crear cuenta de alumno</h3>
      </div>

      <!-- Avatar -->
      <div class="ep-fg">
       <label style="font-weight:700">Elige tu avatar</label>
       <div class="epv5-av-grid" id="epV5AvGrid">${avatarBtns}</div>
       <div id="epV5AvSel" style="text-align:center;font-size:2rem;margin-top:6px">🦊</div>
      </div>

      <div class="ep-fg">
       <label>Nombre completo *</label>
       <input type="text" id="epV5RNombre" placeholder="Tu nombre" autocomplete="off">
      </div>
      <div class="ep-fg">
       <label>Email *</label>
       <input type="email" id="epV5REmail" placeholder="correo@ejemplo.com">
      </div>
      <div class="ep-fg" style="display:flex;gap:10px">
       <div style="flex:1">
        <label>Edad * (3-18)</label>
        <input type="number" id="epV5REdad" min="3" max="18" placeholder="Edad">
       </div>
       <div style="flex:2">
        <label>Grado escolar *</label>
        <select id="epV5RGrado">
         <option value="">-- Selecciona --</option>
         ${gradosOpts}
        </select>
       </div>
      </div>
      <div class="ep-fg">
       <label>PIN de acceso (4 dígitos) *</label>
       <input type="tel" id="epV5RPin" maxlength="4" placeholder="●●●●"
        style="font-size:1.4rem;letter-spacing:8px;text-align:center">
      </div>
      <div class="ep-fg">
       <label>Confirmar PIN *</label>
       <input type="tel" id="epV5RPin2" maxlength="4" placeholder="●●●●"
        style="font-size:1.4rem;letter-spacing:8px;text-align:center">
      </div>
      <div class="ep-fg">
       <label>Pregunta de seguridad (para recuperar PIN)</label>
       <select id="epV5RPregunta">
        <option value="">-- Sin pregunta --</option>
        <option>¿Cuál es tu animal favorito?</option>
        <option>¿Cuál es el nombre de tu mejor amigo?</option>
        <option>¿Cuál es tu color favorito?</option>
        <option>¿Cuál es tu comida favorita?</option>
        <option>¿Cómo se llama tu mascota?</option>
       </select>
      </div>
      <div class="ep-fg" id="epV5RRespGrp" style="display:none">
       <label>Tu respuesta secreta</label>
       <input type="text" id="epV5RRespuesta" placeholder="Respuesta">
      </div>

      <p class="ep-err" id="epV5RegErr" style="display:none"></p>
      <button class="ep-btn ep-btn-green" onclick="epV5DoRegistro()">
       ✅ Crear cuenta
      </button>
      <button class="ep-btn ep-btn-link" onclick="epV5Hide('epV5RegModal');epV5AbrirLogin()">
       ¿Ya tienes cuenta? Inicia sesión
      </button>
     </div>
    </div>`;

    document.body.insertAdjacentHTML('beforeend', html);

    // Mostrar/ocultar respuesta cuando cambia pregunta
    document.getElementById('epV5RPregunta').addEventListener('change', function() {
        document.getElementById('epV5RRespGrp').style.display = this.value ? 'block' : 'none';
    });

    // Seleccionar primer avatar
    setTimeout(function() {
        var first = document.querySelector('.epv5-av-btn');
        if (first) epV5SelAvatar(first);
    }, 50);
}

var _epV5AvSelected = '🦊';
window.epV5SelAvatar = function(btn) {
    document.querySelectorAll('.epv5-av-btn').forEach(function(b) { b.classList.remove('selected'); });
    btn.classList.add('selected');
    _epV5AvSelected = btn.dataset.av;
    var sel = document.getElementById('epV5AvSel');
    if (sel) sel.textContent = _epV5AvSelected;
};

window.epV5DoRegistro = async function() {
    epV5Err('epV5RegErr');
    var nombre  = epV5Val('epV5RNombre');
    var email   = epV5Val('epV5REmail');
    var edad    = epV5Val('epV5REdad');
    var grado   = epV5Val('epV5RGrado');
    var pin     = epV5Val('epV5RPin');
    var pin2    = epV5Val('epV5RPin2');
    var pregunta= epV5Val('epV5RPregunta');
    var resp    = epV5Val('epV5RRespuesta');
    var avatar  = _epV5AvSelected || '🦊';

    if (!nombre) return epV5Err('epV5RegErr','El nombre es requerido');
    if (!email || !email.includes('@')) return epV5Err('epV5RegErr','Ingresa un email válido');
    if (!edad || edad < 3 || edad > 18) return epV5Err('epV5RegErr','Edad debe ser entre 3 y 18');
    if (!grado) return epV5Err('epV5RegErr','Selecciona tu grado escolar');
    if (!pin || pin.length !== 4 || !/^\d{4}$/.test(pin)) return epV5Err('epV5RegErr','PIN debe ser exactamente 4 dígitos');
    if (pin !== pin2) return epV5Err('epV5RegErr','Los PINs no coinciden');
    if (pregunta && !resp) return epV5Err('epV5RegErr','Escribe tu respuesta secreta');

    try {
        var data = await epV5Fetch('/usuarios', 'POST', {
            nombre, email, edad: parseInt(edad), grado_escolar: grado,
            avatar, pin, pregunta_secreta: pregunta, respuesta_secreta: resp
        });
        epV5SaveToken(data.session_token, 'alumno');
        EP_CURRENT_USER_DATA = data;
        epV5Hide('epV5RegModal');
        // Integrar con el sistema existente
        if (typeof epNorm === 'function') {
            currentUser = epNorm(data);
            users = users.filter(function(u) { return u.id !== data.id; });
            users.unshift(currentUser);
            localStorage.setItem('eduplay_users', JSON.stringify(users));
        }
        epV5MostrarToast('¡Cuenta creada! Bienvenid@ ' + nombre + ' ' + avatar);
        if (typeof epAbrirMain === 'function') epAbrirMain();
    } catch(e) {
        epV5Err('epV5RegErr', e.message);
    }
};

/* ══════════════════════════════════════════════════════════════════
   2. INICIAR SESIÓN (email + PIN)
   ══════════════════════════════════════════════════════════════════ */
function epV5AbrirLogin() {
    epV5BuildLoginModal();
    epV5Show('epV5LoginModal');
}

function epV5BuildLoginModal() {
    if (document.getElementById('epV5LoginModal')) return;
    var html = `
    <div class="ep-overlay" id="epV5LoginModal" style="display:none">
     <div class="ep-box" style="max-width:400px">
      <button class="ep-close" onclick="epV5Hide('epV5LoginModal')">×</button>
      <div style="text-align:center;margin-bottom:16px">
       <span style="font-size:2.4rem">🔐</span>
       <h3 style="margin:6px 0 0;color:#2c3e50">Iniciar sesión</h3>
      </div>
      <div class="ep-fg">
       <label>Email</label>
       <input type="email" id="epV5LEmail" placeholder="correo@ejemplo.com">
      </div>
      <div class="ep-fg">
       <label>PIN (4 dígitos)</label>
       <input type="tel" id="epV5LPin" maxlength="4" placeholder="●●●●"
        style="font-size:1.4rem;letter-spacing:8px;text-align:center">
      </div>
      <p class="ep-err" id="epV5LoginErr" style="display:none"></p>
      <button class="ep-btn ep-btn-blue" onclick="epV5DoLogin()">
       ▶ Entrar
      </button>
      <button class="ep-btn ep-btn-link" onclick="epV5Hide('epV5LoginModal');epV5AbrirRecuperar()">
       ¿Olvidaste tu PIN?
      </button>
      <button class="ep-btn ep-btn-link" onclick="epV5Hide('epV5LoginModal');epV5AbrirRegistro()">
       Crear cuenta nueva
      </button>
     </div>
    </div>`;
    document.body.insertAdjacentHTML('beforeend', html);
}

window.epV5DoLogin = async function() {
    epV5Err('epV5LoginErr');
    var email = epV5Val('epV5LEmail');
    var pin   = epV5Val('epV5LPin');
    if (!email) return epV5Err('epV5LoginErr','Ingresa tu email');
    if (!pin || pin.length !== 4) return epV5Err('epV5LoginErr','Ingresa tu PIN de 4 dígitos');
    try {
        var data = await epV5Fetch('/usuarios/login', 'POST', { email, pin });
        if (!data.ok) return epV5Err('epV5LoginErr', data.error || 'Credenciales incorrectas');
        epV5SaveToken(data.session_token, 'alumno');
        EP_CURRENT_USER_DATA = data.usuario;
        epV5Hide('epV5LoginModal');
        if (typeof epNorm === 'function' && data.usuario) {
            currentUser = epNorm(data.usuario);
            users = users.filter(function(u) { return u.id !== data.usuario.id; });
            users.unshift(currentUser);
            localStorage.setItem('eduplay_users', JSON.stringify(users));
        }
        epV5MostrarToast('¡Bienvenid@ de vuelta! ' + (data.usuario ? data.usuario.avatar : ''));
        if (typeof epAbrirMain === 'function') epAbrirMain();
    } catch(e) {
        epV5Err('epV5LoginErr', e.message);
    }
};

/* ══════════════════════════════════════════════════════════════════
   3. RECUPERAR CONTRASEÑA (email → pregunta → nuevo PIN)
   ══════════════════════════════════════════════════════════════════ */
function epV5AbrirRecuperar() {
    epV5BuildRecuperarModal();
    epV5Show('epV5RecModal');
    epV5RecReset();
}

var _epV5RecUid = null;
var _epV5RecToken = null;
var _epV5RecStep = 1;

function epV5RecReset() {
    _epV5RecUid = null; _epV5RecToken = null; _epV5RecStep = 1;
    epV5Err('epV5RecErr');
    ['epV5RecS1','epV5RecS2','epV5RecS3'].forEach(function(id,i) {
        var el = document.getElementById(id);
        if (el) el.style.display = i===0 ? 'block' : 'none';
    });
    ['epV5RecEmail','epV5RecResp','epV5RecNPin','epV5RecNPin2'].forEach(function(id) {
        var el = document.getElementById(id); if (el) el.value = '';
    });
}

function epV5BuildRecuperarModal() {
    if (document.getElementById('epV5RecModal')) return;
    var html = `
    <div class="ep-overlay" id="epV5RecModal" style="display:none">
     <div class="ep-box" style="max-width:400px">
      <button class="ep-close" onclick="epV5Hide('epV5RecModal')">×</button>
      <div style="text-align:center;margin-bottom:16px">
       <span style="font-size:2.2rem">🔑</span>
       <h3 style="margin:6px 0 0">Recuperar PIN</h3>
      </div>
      <!-- Paso 1: email -->
      <div id="epV5RecS1">
       <p style="color:#666;font-size:.9rem;margin-bottom:12px">Ingresa el email con el que te registraste.</p>
       <div class="ep-fg"><label>Email</label>
        <input type="email" id="epV5RecEmail" placeholder="correo@ejemplo.com">
       </div>
       <button class="ep-btn ep-btn-blue" onclick="epV5RecBuscar()">Buscar cuenta</button>
      </div>
      <!-- Paso 2: pregunta secreta -->
      <div id="epV5RecS2" style="display:none">
       <p style="background:#eef6ff;padding:10px 14px;border-radius:8px;font-weight:600;font-size:.9rem"
          id="epV5RecPregLbl"></p>
       <div class="ep-fg"><label>Tu respuesta</label>
        <input type="text" id="epV5RecResp" placeholder="Escribe tu respuesta">
       </div>
       <button class="ep-btn ep-btn-blue" onclick="epV5RecVerif()">Verificar</button>
      </div>
      <!-- Paso 3: nuevo PIN -->
      <div id="epV5RecS3" style="display:none">
       <p style="color:#27ae60;font-weight:700;text-align:center;margin-bottom:12px">✅ Identidad verificada</p>
       <div class="ep-fg"><label>Nuevo PIN (4 dígitos)</label>
        <input type="tel" id="epV5RecNPin" maxlength="4" placeholder="●●●●"
         style="font-size:1.4rem;letter-spacing:8px;text-align:center">
       </div>
       <div class="ep-fg"><label>Confirmar nuevo PIN</label>
        <input type="tel" id="epV5RecNPin2" maxlength="4" placeholder="●●●●"
         style="font-size:1.4rem;letter-spacing:8px;text-align:center">
       </div>
       <button class="ep-btn ep-btn-green" onclick="epV5RecCambiar()">Guardar nuevo PIN</button>
      </div>
      <p class="ep-err" id="epV5RecErr" style="display:none"></p>
      <button class="ep-btn ep-btn-link" onclick="epV5Hide('epV5RecModal');epV5AbrirLogin()">← Volver al login</button>
     </div>
    </div>`;
    document.body.insertAdjacentHTML('beforeend', html);
}

window.epV5RecBuscar = async function() {
    epV5Err('epV5RecErr');
    var email = epV5Val('epV5RecEmail');
    if (!email) return epV5Err('epV5RecErr','Ingresa tu email');
    try {
        var data = await epV5Fetch('/usuarios/pregunta-por-email', 'POST', { email });
        _epV5RecUid = data.usuario_id;
        document.getElementById('epV5RecPregLbl').textContent = data.pregunta;
        document.getElementById('epV5RecS1').style.display = 'none';
        document.getElementById('epV5RecS2').style.display = 'block';
    } catch(e) { epV5Err('epV5RecErr', e.message); }
};

window.epV5RecVerif = async function() {
    epV5Err('epV5RecErr');
    var resp = epV5Val('epV5RecResp');
    if (!resp) return epV5Err('epV5RecErr','Escribe tu respuesta');
    try {
        var data = await epV5Fetch('/usuarios/'+_epV5RecUid+'/verificar-pregunta','POST',{respuesta:resp});
        if (!data.ok) return epV5Err('epV5RecErr','Respuesta incorrecta');
        _epV5RecToken = data.token;
        document.getElementById('epV5RecS2').style.display = 'none';
        document.getElementById('epV5RecS3').style.display = 'block';
    } catch(e) { epV5Err('epV5RecErr', e.message); }
};

window.epV5RecCambiar = async function() {
    epV5Err('epV5RecErr');
    var pin  = epV5Val('epV5RecNPin');
    var pin2 = epV5Val('epV5RecNPin2');
    if (!pin || pin.length!==4 || !/^\d{4}$/.test(pin)) return epV5Err('epV5RecErr','PIN debe ser 4 dígitos');
    if (pin !== pin2) return epV5Err('epV5RecErr','Los PINs no coinciden');
    try {
        await epV5Fetch('/usuarios/'+_epV5RecUid+'/reset-pin','POST',{token:_epV5RecToken,nuevo_pin:pin});
        epV5Hide('epV5RecModal');
        epV5MostrarToast('✅ PIN actualizado. Inicia sesión con tu nuevo PIN.');
        setTimeout(epV5AbrirLogin, 800);
    } catch(e) { epV5Err('epV5RecErr', e.message); }
};

/* ══════════════════════════════════════════════════════════════════
   4 + 5. VER Y EDITAR PERFIL
   ══════════════════════════════════════════════════════════════════ */
async function epV5AbrirPerfil() {
    if (!currentUser) return epV5MostrarToast('⚠ Inicia sesión primero');
    epV5BuildPerfilModal();
    await epV5CargarPerfil();
    epV5Show('epV5PerfilModal');
}

function epV5BuildPerfilModal() {
    if (document.getElementById('epV5PerfilModal')) return;
    var gradosOpts = GRADOS_ESCOLARES.map(function(g) {
        return '<option value="'+g+'">'+g+'</option>';
    }).join('');

    var avatarBtns = AVATARES_DEFAULT.map(function(a) {
        return '<button type="button" class="epv5-av-btn" data-av="'+a+'" onclick="epV5SelAvatar2(this)">'+a+'</button>';
    }).join('');

    var html = `
    <div class="ep-overlay" id="epV5PerfilModal" style="display:none">
     <div class="ep-box" style="max-width:480px;max-height:92vh;overflow-y:auto">
      <button class="ep-close" onclick="epV5Hide('epV5PerfilModal')">×</button>

      <!-- VISTA PERFIL -->
      <div id="epV5PVista">
       <div style="text-align:center;margin-bottom:16px">
        <div id="epV5PAv" style="font-size:4rem;line-height:1">🦊</div>
        <h2 id="epV5PNombre" style="margin:8px 0 2px"></h2>
        <span id="epV5PGrado" style="background:#e8f4fd;color:#2980b9;padding:3px 10px;border-radius:20px;font-size:.85rem;font-weight:600"></span>
       </div>
       <div class="epv5-perfil-card">
        <div class="epv5-perfil-row"><span>📧 Email</span><span id="epV5PEmail">—</span></div>
        <div class="epv5-perfil-row"><span>🎂 Edad</span><span id="epV5PEdad">—</span></div>
        <div class="epv5-perfil-row"><span>⭐ Estrellas</span><span id="epV5PStars">—</span></div>
        <div class="epv5-perfil-row"><span>⏱ Tiempo jugado</span><span id="epV5PTiempo">—</span></div>
        <div class="epv5-perfil-row"><span>📅 Miembro desde</span><span id="epV5PFecha">—</span></div>
        <div class="epv5-perfil-row" id="epV5PTutorRow" style="display:none"><span>🏫 Rol</span><span style="color:#8e44ad;font-weight:700">Tutor</span></div>
       </div>
       <div style="display:flex;gap:8px;margin-top:12px">
        <button class="ep-btn ep-btn-blue" style="flex:1" onclick="epV5ModoEditar()">✏️ Editar perfil</button>
        <button class="ep-btn" style="flex:1;background:#8e44ad;color:#fff" onclick="epV5AbrirTutor()">🏫 Perfil tutor</button>
       </div>
       <button class="ep-btn ep-btn-link" onclick="epV5AbrirReporte()">📊 Ver reporte de uso</button>
      </div>

      <!-- EDITAR PERFIL -->
      <div id="epV5PEditar" style="display:none">
       <h3 style="margin:0 0 14px">✏️ Editar perfil</h3>
       <div style="text-align:center;margin-bottom:10px">
        <div class="epv5-av-grid" id="epV5AvGrid2">${avatarBtns}</div>
        <div id="epV5AvSel2" style="font-size:2.2rem;margin-top:6px">🦊</div>
       </div>
       <div class="ep-fg"><label>Nombre</label>
        <input type="text" id="epV5ENombre" placeholder="Tu nombre">
       </div>
       <div class="ep-fg"><label>Email</label>
        <input type="email" id="epV5EEmail" placeholder="correo@ejemplo.com">
       </div>
       <div class="ep-fg" style="display:flex;gap:10px">
        <div style="flex:1"><label>Edad</label>
         <input type="number" id="epV5EEdad" min="3" max="18" placeholder="Edad">
        </div>
        <div style="flex:2"><label>Grado escolar</label>
         <select id="epV5EGrado"><option value="">-- Selecciona --</option>${gradosOpts}</select>
        </div>
       </div>
       <div class="ep-fg"><label>Nuevo PIN (dejar vacío para no cambiar)</label>
        <input type="tel" id="epV5EPin" maxlength="4" placeholder="●●●●" style="font-size:1.3rem;letter-spacing:8px;text-align:center">
       </div>
       <p class="ep-err" id="epV5EditErr" style="display:none"></p>
       <div style="display:flex;gap:8px">
        <button class="ep-btn ep-btn-green" style="flex:1" onclick="epV5DoEditar()">💾 Guardar</button>
        <button class="ep-btn btn-secondary" style="flex:1" onclick="epV5ModoVista()">Cancelar</button>
       </div>
      </div>
     </div>
    </div>`;
    document.body.insertAdjacentHTML('beforeend', html);
}

var _epV5AvSel2 = '🦊';
window.epV5SelAvatar2 = function(btn) {
    document.querySelectorAll('#epV5AvGrid2 .epv5-av-btn').forEach(function(b) { b.classList.remove('selected'); });
    btn.classList.add('selected');
    _epV5AvSel2 = btn.dataset.av;
    var el = document.getElementById('epV5AvSel2'); if (el) el.textContent = _epV5AvSel2;
};

async function epV5CargarPerfil() {
    var uid = currentUser && currentUser.id;
    if (!uid) return;
    try {
        var data = await fetch('/api/usuarios/'+uid).then(function(r){return r.json();});
        EP_CURRENT_USER_DATA = data;
        document.getElementById('epV5PAv').textContent    = data.avatar || '🦊';
        document.getElementById('epV5PNombre').textContent = data.nombre || '—';
        document.getElementById('epV5PGrado').textContent  = data.grado_escolar || '—';
        document.getElementById('epV5PEmail').textContent  = data.email || '—';
        document.getElementById('epV5PEdad').textContent   = (data.edad || '—') + (data.edad ? ' años' : '');
        document.getElementById('epV5PStars').textContent  = (data.estrellas || 0) + ' ⭐';
        document.getElementById('epV5PTiempo').textContent = Math.round((data.tiempo_juego||0)/60) + ' min';
        document.getElementById('epV5PFecha').textContent  = data.creado_en ? data.creado_en.split('T')[0] : '—';
        var tutorRow = document.getElementById('epV5PTutorRow');
        if (tutorRow) tutorRow.style.display = data.es_tutor ? 'flex' : 'none';
    } catch(e) {}
}

window.epV5ModoEditar = function() {
    var d = EP_CURRENT_USER_DATA || {};
    document.getElementById('epV5ENombre').value = d.nombre || '';
    document.getElementById('epV5EEmail').value  = d.email  || '';
    document.getElementById('epV5EEdad').value   = d.edad   || '';
    var gSel = document.getElementById('epV5EGrado');
    if (gSel) gSel.value = d.grado_escolar || '';
    _epV5AvSel2 = d.avatar || '🦊';
    var av2 = document.getElementById('epV5AvSel2'); if (av2) av2.textContent = _epV5AvSel2;
    // Mark selected avatar
    document.querySelectorAll('#epV5AvGrid2 .epv5-av-btn').forEach(function(b) {
        b.classList.toggle('selected', b.dataset.av === _epV5AvSel2);
    });
    document.getElementById('epV5PVista').style.display  = 'none';
    document.getElementById('epV5PEditar').style.display = 'block';
};

window.epV5ModoVista = function() {
    document.getElementById('epV5PVista').style.display  = 'block';
    document.getElementById('epV5PEditar').style.display = 'none';
};

window.epV5DoEditar = async function() {
    epV5Err('epV5EditErr');
    var uid    = currentUser && currentUser.id;
    if (!uid) return;
    var nombre = epV5Val('epV5ENombre');
    var email  = epV5Val('epV5EEmail');
    var edad   = epV5Val('epV5EEdad');
    var grado  = epV5Val('epV5EGrado');
    var pin    = epV5Val('epV5EPin');
    if (!nombre) return epV5Err('epV5EditErr','El nombre es requerido');
    if (email && !email.includes('@')) return epV5Err('epV5EditErr','Email inválido');
    if (pin && (pin.length!==4 || !/^\d{4}$/.test(pin))) return epV5Err('epV5EditErr','PIN debe ser 4 dígitos');
    var body = { nombre, avatar: _epV5AvSel2 };
    if (email) body.email = email;
    if (edad)  body.edad  = parseInt(edad);
    if (grado) body.grado_escolar = grado;
    if (pin)   body.pin   = pin;
    try {
        var data = await epV5Fetch('/usuarios/'+uid, 'PUT', body);
        EP_CURRENT_USER_DATA = data;
        if (typeof epNorm === 'function') {
            currentUser = epNorm(data);
            var idx = users.findIndex(function(u) { return u.id === uid; });
            if (idx >= 0) users[idx] = currentUser; else users.unshift(currentUser);
            localStorage.setItem('eduplay_users', JSON.stringify(users));
            if (typeof updateCurrentUserDisplay === 'function') updateCurrentUserDisplay();
        }
        epV5ModoVista();
        await epV5CargarPerfil();
        epV5MostrarToast('✅ Perfil actualizado');
    } catch(e) { epV5Err('epV5EditErr', e.message); }
};

/* ══════════════════════════════════════════════════════════════════
   7. CREAR/VER PERFIL DE TUTOR
   ══════════════════════════════════════════════════════════════════ */
function epV5AbrirTutor() {
    epV5BuildTutorModal();
    var d = EP_CURRENT_USER_DATA || {};
    document.getElementById('epV5TInfo').value = d.info_tutor || '';
    document.getElementById('epV5TStatus').textContent = d.es_tutor
        ? '✅ Eres tutor activo'
        : '⬜ Aún no tienes perfil de tutor';
    document.getElementById('epV5TBtnQuitar').style.display = d.es_tutor ? 'block' : 'none';
    epV5Err('epV5TutorErr');
    epV5Show('epV5TutorModal');
}

function epV5BuildTutorModal() {
    if (document.getElementById('epV5TutorModal')) return;
    var html = `
    <div class="ep-overlay" id="epV5TutorModal" style="display:none">
     <div class="ep-box" style="max-width:440px">
      <button class="ep-close" onclick="epV5Hide('epV5TutorModal')">×</button>
      <div style="text-align:center;margin-bottom:14px">
       <span style="font-size:2.2rem">🏫</span>
       <h3 style="margin:6px 0 0">Perfil de Tutor</h3>
      </div>
      <p id="epV5TStatus" style="text-align:center;font-weight:700;color:#8e44ad;margin-bottom:14px"></p>
      <p style="color:#666;font-size:.88rem;margin-bottom:10px">
       Activar tu perfil de tutor te permite supervisar alumnos y acceder a funciones de seguimiento académico.
      </p>
      <div class="ep-fg"><label>Información adicional (institución, materias, etc.)</label>
       <textarea id="epV5TInfo" rows="3" style="width:100%;padding:8px;border:1px solid #ddd;border-radius:8px;resize:vertical;font-size:.9rem" placeholder="Ej: Tutor de primaria, Escuela Benito Juárez"></textarea>
      </div>
      <p class="ep-err" id="epV5TutorErr" style="display:none"></p>
      <button class="ep-btn ep-btn-green" onclick="epV5DoActivarTutor()">🏫 Activar perfil de tutor</button>
      <button class="ep-btn" id="epV5TBtnQuitar" style="background:#e74c3c;color:#fff;display:none" onclick="epV5DoQuitarTutor()">❌ Quitar perfil de tutor</button>
      <button class="ep-btn ep-btn-link" onclick="epV5Hide('epV5TutorModal')">← Volver</button>
     </div>
    </div>`;
    document.body.insertAdjacentHTML('beforeend', html);
}

window.epV5DoActivarTutor = async function() {
    epV5Err('epV5TutorErr');
    var uid  = currentUser && currentUser.id;
    if (!uid) return;
    var info = (document.getElementById('epV5TInfo') || {}).value || '';
    try {
        await epV5Fetch('/usuarios/'+uid+'/tutor', 'POST', { info_tutor: info });
        if (EP_CURRENT_USER_DATA) { EP_CURRENT_USER_DATA.es_tutor=1; EP_CURRENT_USER_DATA.info_tutor=info; }
        document.getElementById('epV5TStatus').textContent = '✅ Eres tutor activo';
        document.getElementById('epV5TBtnQuitar').style.display = 'block';
        epV5MostrarToast('✅ Perfil de tutor activado');
    } catch(e) { epV5Err('epV5TutorErr', e.message); }
};

window.epV5DoQuitarTutor = async function() {
    var uid = currentUser && currentUser.id;
    if (!uid) return;
    try {
        await epV5Fetch('/usuarios/'+uid+'/tutor', 'DELETE');
        if (EP_CURRENT_USER_DATA) { EP_CURRENT_USER_DATA.es_tutor=0; EP_CURRENT_USER_DATA.info_tutor=''; }
        document.getElementById('epV5TStatus').textContent = '⬜ Aún no tienes perfil de tutor';
        document.getElementById('epV5TBtnQuitar').style.display = 'none';
        epV5MostrarToast('Perfil de tutor desactivado');
    } catch(e) { epV5Err('epV5TutorErr', e.message); }
};

/* ══════════════════════════════════════════════════════════════════
   8. REPORTE DE TIEMPO DE USO CON IA
   ══════════════════════════════════════════════════════════════════ */
async function epV5AbrirReporte() {
    epV5BuildReporteModal();
    epV5Show('epV5ReporteModal');
    await epV5CargarReporte();
}

function epV5BuildReporteModal() {
    if (document.getElementById('epV5ReporteModal')) return;
    var html = `
    <div class="ep-overlay" id="epV5ReporteModal" style="display:none">
     <div class="ep-box" style="max-width:520px;max-height:92vh;overflow-y:auto">
      <button class="ep-close" onclick="epV5Hide('epV5ReporteModal')">×</button>
      <div style="text-align:center;margin-bottom:16px">
       <span style="font-size:2.2rem">📊</span>
       <h3 style="margin:6px 0 0">Reporte de Tiempo de Uso</h3>
       <p style="color:#888;font-size:.85rem;margin:4px 0 0">Análisis inteligente de tu actividad 🤖</p>
      </div>

      <div id="epV5RLoad" style="text-align:center;padding:20px;color:#888">🔄 Cargando análisis IA...</div>

      <div id="epV5RContent" style="display:none">
       <!-- KNN Banner -->
       <div id="epV5RKnn" style="border-radius:12px;padding:14px;margin-bottom:14px;background:linear-gradient(135deg,#667eea,#764ba2);color:#fff">
        <div style="display:flex;align-items:center;gap:10px">
         <div id="epV5RKnnEmoji" style="font-size:2rem">🤖</div>
         <div>
          <div id="epV5RKnnEtiqueta" style="font-weight:800;font-size:1.1rem"></div>
          <div id="epV5RKnnRec" style="font-size:.82rem;opacity:.9;margin-top:2px"></div>
         </div>
        </div>
       </div>

       <!-- Tiempo total -->
       <div style="display:flex;gap:10px;margin-bottom:14px">
        <div class="epv5-stat-box" style="flex:1">
         <div class="epv5-stat-val" id="epV5RTotalMin">0</div>
         <div class="epv5-stat-lbl">Minutos totales</div>
        </div>
        <div class="epv5-stat-box" style="flex:1">
         <div class="epv5-stat-val" id="epV5RTotalSes">0</div>
         <div class="epv5-stat-lbl">Sesiones</div>
        </div>
        <div class="epv5-stat-box" style="flex:1">
         <div class="epv5-stat-val" id="epV5RProm">0</div>
         <div class="epv5-stat-lbl">Min promedio</div>
        </div>
       </div>

       <!-- Categorías -->
       <h4 style="margin:0 0 8px;color:#2c3e50">Actividad por categoría</h4>
       <div id="epV5RCats"></div>

       <!-- Historial reciente -->
       <h4 style="margin:14px 0 8px;color:#2c3e50">Últimas sesiones</h4>
       <div id="epV5RHistorial" style="max-height:180px;overflow-y:auto"></div>
      </div>
     </div>
    </div>`;
    document.body.insertAdjacentHTML('beforeend', html);
}

async function epV5CargarReporte() {
    var uid = currentUser && currentUser.id;
    if (!uid) return;
    document.getElementById('epV5RLoad').style.display    = 'block';
    document.getElementById('epV5RContent').style.display = 'none';
    try {
        var data = await fetch('/api/usuarios/'+uid+'/reporte-tiempo').then(function(r){return r.json();});
        var hist = await fetch('/api/usuarios/'+uid+'/historial').then(function(r){return r.json();});
        epV5RenderReporte(data, hist);
    } catch(e) {
        document.getElementById('epV5RLoad').textContent = '⚠ No se pudo cargar el reporte';
    }
}

function epV5RenderReporte(data, hist) {
    document.getElementById('epV5RLoad').style.display    = 'none';
    document.getElementById('epV5RContent').style.display = 'block';

    // KNN
    var knn = data.clasificacion_ia;
    if (knn) {
        document.getElementById('epV5RKnnEmoji').textContent    = knn.emoji || '🤖';
        document.getElementById('epV5RKnnEtiqueta').textContent = knn.etiqueta || '—';
        document.getElementById('epV5RKnnRec').textContent      = knn.recomendacion || '';
    } else {
        document.getElementById('epV5RKnn').style.display = 'none';
    }

    // Tiempos
    var total = data.tiempo_total_minutos || 0;
    var regs  = data.registros || [];
    document.getElementById('epV5RTotalMin').textContent = total;
    document.getElementById('epV5RTotalSes').textContent = regs.length;
    document.getElementById('epV5RProm').textContent     = regs.length ? Math.round(total/regs.length) : 0;

    // Categorías
    var cats = {};
    regs.forEach(function(r) { cats[r.categoria] = (cats[r.categoria]||0) + r.total_min; });
    var catKeys = Object.keys(cats);
    var maxCat  = catKeys.length ? Math.max.apply(null, catKeys.map(function(k){return cats[k];})) : 1;
    var COLORS  = {'Juegos':'#3498db','Matemáticas':'#e67e22','Memoria':'#9b59b6',
                   'Gramática':'#27ae60','General':'#95a5a6','Inglés':'#e74c3c'};
    var catsHtml = catKeys.map(function(k) {
        var pct = Math.round((cats[k]/maxCat)*100);
        var col = COLORS[k] || '#3498db';
        return '<div style="margin-bottom:8px"><div style="display:flex;justify-content:space-between;font-size:.85rem;margin-bottom:3px"><span>'+k+'</span><span>'+cats[k]+' min</span></div>'
            +'<div style="background:#eee;border-radius:4px;height:8px"><div style="width:'+pct+'%;background:'+col+';height:8px;border-radius:4px;transition:width .4s"></div></div></div>';
    }).join('');
    document.getElementById('epV5RCats').innerHTML = catsHtml || '<p style="color:#888;font-size:.85rem">Sin registros aún</p>';

    // Historial
    var histHtml = (hist || []).slice(0,10).map(function(h) {
        var fecha = (h.registrado_en||'').split('T')[0];
        return '<div style="display:flex;justify-content:space-between;padding:7px 10px;border-bottom:1px solid #f0f0f0;font-size:.85rem">'
            +'<span>'+epV5EmojiTipo(h.tipo_juego)+' '+(h.actividad||h.tipo_juego||'Actividad')+'</span>'
            +'<span style="color:#888">'+fecha+'</span></div>';
    }).join('');
    document.getElementById('epV5RHistorial').innerHTML = histHtml || '<p style="color:#888;font-size:.85rem;padding:10px">Sin historial aún</p>';
}

function epV5EmojiTipo(tipo) {
    var m = {memory:'🧠',math:'🔢',grammar:'📝',english:'🌍',geography:'🗺',art:'🎨',science:'🔬',logic:'🧩'};
    return m[tipo] || '🎮';
}

/* ══════════════════════════════════════════════════════════════════
   9. CERRAR SESIÓN
   ══════════════════════════════════════════════════════════════════ */
async function epV5Logout() {
    try {
        if (EP_SESSION_TIPO === 'alumno') {
            await epV5Fetch('/usuarios/logout', 'POST', { token: EP_SESSION_TOKEN });
        } else if (EP_SESSION_TIPO === 'padre') {
            await epV5Fetch('/padres/logout', 'POST', { token: EP_SESSION_TOKEN });
        }
    } catch(_) {}
    epV5SaveToken(null, null);
    EP_CURRENT_USER_DATA = null;
    currentUser = null;
    localStorage.removeItem('ep_sesion');
    epV5MostrarToast('Sesión cerrada 👋');
    if (typeof showWelcomeScreen === 'function') showWelcomeScreen();
}

/* ══════════════════════════════════════════════════════════════════
   10. CONTROL DE SESIONES — restaurar sesión al cargar
   ══════════════════════════════════════════════════════════════════ */
async function epV5RestaurarSesion() {
    if (!EP_SESSION_TOKEN || EP_SESSION_TIPO !== 'alumno') return false;
    // Verify token is still valid by fetching user list with it
    try {
        // Just load the user from localStorage and validate token passively
        var saved = JSON.parse(localStorage.getItem('ep_sesion') || 'null');
        if (!saved || !saved.id) return false;
        var data = await fetch('/api/usuarios/'+saved.id).then(function(r){return r.json();});
        if (data && data.id) {
            EP_CURRENT_USER_DATA = data;
            return true;
        }
    } catch(_) {}
    return false;
}

/* ══════════════════════════════════════════════════════════════════
   TOAST NOTIFICACIONES
   ══════════════════════════════════════════════════════════════════ */
function epV5MostrarToast(msg) {
    var el = document.createElement('div');
    el.className = 'epv5-toast';
    el.textContent = msg;
    document.body.appendChild(el);
    setTimeout(function() { el.classList.add('show'); }, 50);
    setTimeout(function() { el.classList.remove('show'); setTimeout(function() { el.remove(); }, 400); }, 3000);
}

/* ══════════════════════════════════════════════════════════════════
   INYECTAR ESTILOS
   ══════════════════════════════════════════════════════════════════ */
(function epV5InjectStyles() {
    var css = `
/* ── EduPlay v5 Feature Styles ── */
.epv5-av-grid {
    display: flex; flex-wrap: wrap; gap: 6px;
    justify-content: center; margin-bottom: 4px;
}
.epv5-av-btn {
    font-size: 1.6rem; width: 44px; height: 44px;
    border: 2px solid transparent; border-radius: 10px;
    background: #f8f9fa; cursor: pointer; transition: all .15s;
    display: flex; align-items: center; justify-content: center;
}
.epv5-av-btn:hover  { background: #e8f4fd; border-color: #3498db; transform: scale(1.1); }
.epv5-av-btn.selected { border-color: #3498db; background: #e8f4fd; transform: scale(1.1); box-shadow: 0 0 0 3px rgba(52,152,219,.25); }

.epv5-perfil-card { background: #f8f9fa; border-radius: 12px; overflow: hidden; }
.epv5-perfil-row {
    display: flex; justify-content: space-between; align-items: center;
    padding: 10px 14px; border-bottom: 1px solid #eee;
    font-size: .88rem;
}
.epv5-perfil-row:last-child { border-bottom: none; }
.epv5-perfil-row span:first-child { color: #666; }
.epv5-perfil-row span:last-child  { font-weight: 600; color: #2c3e50; }

.epv5-stat-box {
    background: #f8f9fa; border-radius: 12px;
    padding: 12px; text-align: center;
}
.epv5-stat-val { font-size: 1.6rem; font-weight: 800; color: #2c3e50; }
.epv5-stat-lbl { font-size: .75rem; color: #888; margin-top: 2px; }

.epv5-toast {
    position: fixed; bottom: 20px; left: 50%; transform: translateX(-50%) translateY(20px);
    background: #2c3e50; color: #fff;
    padding: 10px 20px; border-radius: 25px; font-size: .9rem;
    opacity: 0; transition: all .35s; z-index: 99999; white-space: nowrap;
    box-shadow: 0 4px 20px rgba(0,0,0,.3);
}
.epv5-toast.show { opacity: 1; transform: translateX(-50%) translateY(0); }

/* Botones de acceso en welcome */
.epv5-nav-btns {
    display: flex; flex-direction: column; gap: 8px;
    margin-top: 10px;
}

/* Override EP errors */
.ep-err { color: #e74c3c; font-size: .85rem; margin: 4px 0 0; }
`;
    var style = document.createElement('style');
    style.textContent = css;
    document.head.appendChild(style);
})();

/* ══════════════════════════════════════════════════════════════════
   INYECTAR BOTONES EN LA PANTALLA DE BIENVENIDA
   ══════════════════════════════════════════════════════════════════ */
window.addEventListener('DOMContentLoaded', function() {
    // Agregar botones de Login Alumno y Registro al welcome
    var wb = document.getElementById('welcomeButtons');
    if (wb) {
        // Botón de iniciar sesión alumno
        var btnLogin = document.createElement('button');
        btnLogin.className = 'welcome-btn';
        btnLogin.style.cssText = 'background:linear-gradient(135deg,#27ae60,#1e8449);color:#fff;border:none;padding:14px 28px;border-radius:50px;font-size:1rem;font-weight:700;cursor:pointer;margin-top:6px;box-shadow:0 4px 15px rgba(39,174,96,.4)';
        btnLogin.innerHTML = '🔐 Iniciar sesión (alumno)';
        btnLogin.onclick = function() { epV5AbrirLogin(); };
        wb.appendChild(btnLogin);

        // Botón de registro alumno
        var btnReg = document.createElement('button');
        btnReg.className = 'welcome-btn';
        btnReg.style.cssText = 'background:linear-gradient(135deg,#e67e22,#ca6f1e);color:#fff;border:none;padding:14px 28px;border-radius:50px;font-size:1rem;font-weight:700;cursor:pointer;margin-top:6px;box-shadow:0 4px 15px rgba(230,126,34,.4)';
        btnReg.innerHTML = '📝 Registrarse como alumno';
        btnReg.onclick = function() { epV5AbrirRegistro(); };
        wb.appendChild(btnReg);
    }

    // Interceptar logout btn para usar nuestra función
    var lb = document.getElementById('logoutBtn');
    if (lb) {
        lb.addEventListener('click', function(e) {
            e.stopImmediatePropagation();
            epV5Logout();
        }, true);
    }

    // Agregar "Mi perfil" al header si hay sesión
    var hdr = document.querySelector('.header-right') || document.querySelector('header');
    if (hdr) {
        var btnPerfil = document.createElement('button');
        btnPerfil.id = 'epV5BtnPerfil';
        btnPerfil.className = 'btn btn-secondary';
        btnPerfil.innerHTML = '👤 Mi perfil';
        btnPerfil.style.display = 'none';
        btnPerfil.onclick = function() { epV5AbrirPerfil(); };
        var lb2 = document.getElementById('logoutBtn');
        if (lb2 && lb2.parentNode) lb2.parentNode.insertBefore(btnPerfil, lb2);
        else hdr.appendChild(btnPerfil);
    }

    // Mostrar botón perfil cuando hay usuario activo
    var _origEpAbrirMain = typeof epAbrirMain === 'function' ? epAbrirMain : null;
    if (_origEpAbrirMain) {
        var __wrapped = function() {
            _origEpAbrirMain();
            var bp = document.getElementById('epV5BtnPerfil');
            if (bp) bp.style.display = 'flex';
        };
        window.epAbrirMain = __wrapped;
    }
});

/* ══════════════════════════════════════════════════════════════════
   EXPORTAR FUNCIONES GLOBALES
   ══════════════════════════════════════════════════════════════════ */
window.EduPlayV5 = {
    abrirRegistro  : epV5AbrirRegistro,
    abrirLogin     : epV5AbrirLogin,
    abrirRecuperar : epV5AbrirRecuperar,
    abrirPerfil    : epV5AbrirPerfil,
    abrirTutor     : epV5AbrirTutor,
    abrirReporte   : epV5AbrirReporte,
    logout         : epV5Logout,
    toast          : epV5MostrarToast
};
