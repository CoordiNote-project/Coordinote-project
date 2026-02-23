//
//  CoordiNote  java script
//  Connects to HTML with IDs
// 

// ── Configuration ──
const API = 'http://localhost:5000';
const LISBON = [38.7169, -9.1393];
const USE_API = true; 

// defining Global Variables
let map;
let currentUser = null;
let allMessages = [];
let messageMarkers = [];
let poiMarkers = [];
let allUniverses = [];
let allPOIs = [];
let isRegisterMode = false;  
let hiddenUniverses = []; // universes the user has "left"
let messageCircles = {}; // saves circles per m_id
let seenMessages = new Set(); // saves seen message IDs
let selectedLocation = null;      
let currentMsgType = 'text'; 

// 
//  START APP (when page loads)
//
document.addEventListener('DOMContentLoaded', () => {
  console.log('✓ CoordiNote starting...');

  // Get elements
  const loginBtn = document.getElementById('loginBtn');
  const registerBtn = document.getElementById('registerBtn');
  const loginModal = document.getElementById('loginModal');
  const app = document.getElementById('app');

  // Login button click
  if (loginBtn) {
    loginBtn.addEventListener('click', handleLogin);
  }

  // Register button click
  if (registerBtn) {
    registerBtn.addEventListener('click', toggleRegisterMode);
  }

  // Setup other event listeners
  setupEventListeners();
});
// 
//  REGISTER MODE TOGGLE
// 

function toggleRegisterMode() {
  isRegisterMode = !isRegisterMode;
  
  const confirmField = document.getElementById('confirmPasswordField');
  const loginBtn = document.getElementById('loginBtn');
  const registerBtn = document.getElementById('registerBtn');
  const loginError = document.getElementById('loginError');
  
  if (isRegisterMode) {
    // Switch to Register mode
    confirmField.classList.remove('hidden');
    loginBtn.textContent = 'Create Account';
    registerBtn.textContent = 'Back to Login';
    if (loginError) loginError.classList.add('hidden');
  } else {
    // Switch to Login mode
    confirmField.classList.add('hidden');
    loginBtn.textContent = 'Login';
    registerBtn.textContent = 'Register new account';
    if (loginError) loginError.classList.add('hidden');
  }
}

// 
//  LOGIN
// 
async function handleLogin() {
  const loginModal = document.getElementById('loginModal');
  const app = document.getElementById('app');
  const loginUser = document.getElementById('loginUser');
  const loginPass = document.getElementById('loginPass');
  const loginPassConfirm = document.getElementById('loginPassConfirm');
  const loginError = document.getElementById('loginError');

  const username = loginUser?.value.trim();
  const password = loginPass?.value.trim();
  
  // Check both fields filled
  if (!username || !password) {
    if (loginError) {
      loginError.classList.remove('hidden');
      loginError.textContent = '❌ Please enter username and password';
    }
    return;
  }

  // ═══ REGISTER MODE ═══
  if (isRegisterMode) {
    const passwordConfirm = loginPassConfirm?.value.trim();
    
    // Check passwords match
    if (password !== passwordConfirm) {
      if (loginError) {
        loginError.classList.remove('hidden');
        loginError.textContent = '❌ Passwords do not match';
      }
      return;
    }
    
    // Check password length
    if (password.length < 4) {
      if (loginError) {
        loginError.classList.remove('hidden');
        loginError.textContent = '❌ Password must be at least 4 characters';
      }
      return;
    }

 try {
    const res = await fetch(`${API}/users/register`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ 
    username, 
    password, 
    repeat_password: passwordConfirm 
  })
});

    const data = await res.json();

      if (!res.ok) {
        if (loginError) {
          loginError.classList.remove('hidden');
          loginError.textContent = `❌ ${data.error}`;
        }
        return;
      }

      showToast('Account created! ✅ You can now login', 'success');
      toggleRegisterMode();
      if (loginUser) loginUser.value = '';
      if (loginPass) loginPass.value = '';
      if (loginPassConfirm) loginPassConfirm.value = '';

    } catch (err) {
      if (loginError) {
        loginError.classList.remove('hidden');
        loginError.textContent = '❌ Server not reachable';
      }
    }
    return;
  }

  // LOGIN MODE 
// ═══ LOGIN MODE ═══
if (USE_API) {
  try {
    const res = await fetch(`${API}/users/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password })
    });
    const data = await res.json();
    if (!res.ok) {
      loginError.classList.remove('hidden');
      loginError.textContent = `❌ ${data.error}`;
      return;
    }
  currentUser = { username: data.us_name, id: data.us_id, token: data.token, location: null };
  } catch (err) {
    loginError.classList.remove('hidden');
    loginError.textContent = '❌ Server not reachable';
    return;
  }
} else {
  // Demo mode
  const validUser = DEMO_USERS.find(u => u.username === username && u.password === password);
  if (!validUser) {
    if (loginError) {
      loginError.classList.remove('hidden');
      loginError.textContent = '❌ Wrong username or password';
    }
    return;
  }
  currentUser = { username, id: 1001, token: null, location: null };
}

// Get user location
if (navigator.geolocation) {
  navigator.geolocation.getCurrentPosition(pos => {
    currentUser.location = {
      lat: pos.coords.latitude,
      lng: pos.coords.longitude
    };
    console.log('✓ Got user location:', currentUser.location);
    loadMessages();
  });
}

// Update UI
const userAvatar = document.getElementById('userAvatar');
const userName = document.getElementById('userName');
if (userAvatar) userAvatar.textContent = username.substring(0, 2).toUpperCase();
if (userName) userName.textContent = username;

if (loginModal) loginModal.classList.add('hidden');
if (app) app.classList.remove('hidden');

console.log('✓ User logged in:', username);
initMap();
loadUniverses();
loadMessages();
loadPOIs();
}
// 
//  EVENT LISTENERS
// 
function setupEventListeners() {

  // Close side panel
  const closePanelBtn = document.getElementById('closePanelBtn');
  if (closePanelBtn) {
    closePanelBtn.addEventListener('click', closeSidePanel);
  }

  // Toolbar buttons
  const btnMessages = document.getElementById('btnMessages');
  const btnPOIs = document.getElementById('btnPOIs');
  const btnLocate = document.getElementById('btnLocate');
  const btnRefresh = document.getElementById('btnRefresh');

  if (btnMessages) btnMessages.addEventListener('click', () => toggleLayer('messages'));
  if (btnPOIs) btnPOIs.addEventListener('click', () => toggleLayer('pois'));
  if (btnLocate) btnLocate.addEventListener('click', locateUser);
  if (btnRefresh) btnRefresh.addEventListener('click', () => {
    loadMessages();
    loadPOIs();
    showToast('Refreshed! 🔄');
  });

  // Logout button
  const logoutBtn = document.getElementById('logoutBtn');
  if (logoutBtn) {
    logoutBtn.addEventListener('click', () => {
      location.reload(); // Simple logout - just reload page
    });
  }
    const resizer = document.getElementById('sidebarResizer');
  const sidebar = document.getElementById('sidebar');

  if (resizer && sidebar) {
    let isResizing = false;

    resizer.addEventListener('mousedown', (e) => {
      isResizing = true;
      document.body.style.cursor = 'ew-resize';
      document.body.style.userSelect = 'none';
    });

    document.addEventListener('mousemove', (e) => {
      if (!isResizing) return;
      const newWidth = e.clientX;
      if (newWidth >= 200 && newWidth <= 500) {
        sidebar.style.width = newWidth + 'px';
      }
    });

    document.addEventListener('mouseup', () => {
      isResizing = false;
      document.body.style.cursor = '';
      document.body.style.userSelect = '';
    });
  }
}

// 
//  MAP
// 
function initMap() {
  console.log('✓ Initializing map...');
  
  // Create map
  map = L.map('map').setView(LISBON, 13);

  // Add tiles
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '© OpenStreetMap contributors',
    maxZoom: 19
  }).addTo(map);

  // Click to select location
  map.on('click', onMapClick);
  // User location pin
if (navigator.geolocation) {
  navigator.geolocation.getCurrentPosition(pos => {
    const lat = pos.coords.latitude;
    const lng = pos.coords.longitude;

    L.marker([lat, lng], {
      icon: L.divIcon({
        html: `<div style="font-size:2rem">📍</div>`,
        className: '',
        iconSize: [30, 30],
        iconAnchor: [15, 30]
      })
    }).addTo(map).bindPopup('📍 You are here');

    map.setView([lat, lng], 15);
  });
}
  console.log('✓ Map initialized!');
}

function onMapClick(e) {
  const senderView = document.getElementById('viewSender');
  if (senderView?.classList.contains('active') && locationMode === 'pin') {
    senderSelectedLocation = { lat: e.latlng.lat, lng: e.latlng.lng };
    
    if (window.tempMarker) map.removeLayer(window.tempMarker);
    window.tempMarker = L.circleMarker(e.latlng, {
      radius: 12,
      fillColor: '#f5a623',
      fillOpacity: 0.8,
      color: 'white',
      weight: 2
    }).addTo(map).bindPopup('📍 New message location').openPopup();

       if (window.radiusCircle) map.removeLayer(window.radiusCircle);
    window.radiusCircle = L.circle(e.latlng, {
      radius: parseInt(document.getElementById('senderRadiusSlider').value),
      fillColor: '#8f2de4', fillOpacity: 0.1,
      color: '#8f2de4', weight: 1, dashArray: '5, 5'
    }).addTo(map);
    
    updateLocationDisplay(senderSelectedLocation);
  }
}

function locateUser() {
  if (!navigator.geolocation) {
    showToast('Geolocation not supported', 'error');
    return;
  }

  navigator.geolocation.getCurrentPosition(
    (pos) => {
      const lat = pos.coords.latitude;
      const lng = pos.coords.longitude;
      
      map.setView([lat, lng], 15);
      
      L.circleMarker([lat, lng], {
        radius: 10,
        fillColor: '#2de4c8',
        fillOpacity: 1,
        color: 'white',
        weight: 3
      }).addTo(map).bindPopup('📍 You are here').openPopup();
      
      showToast('Location found! 📍', 'success');
    },
    (err) => {
      showToast('Could not get location', 'error');
      console.error(err);
    }
  );
}

// 
//  LOAD MESSAGES plus location mitsenden 
// 
async function loadMessages() {
  if (!map) return;
  if (USE_API && currentUser.token) {
    try {
      const bounds = map.getBounds();
       const res = await fetch(
  `${API}/messages/nearby?min_lat=${bounds.getSouth()}&max_lat=${bounds.getNorth()}&min_lon=${bounds.getWest()}&max_lon=${bounds.getEast()}&user_lat=${currentUser.location?.lat ?? LISBON[0]}&user_lon=${currentUser.location?.lng ?? LISBON[1]}`,
  { headers: { 'Authorization': currentUser.token } }
);
      const data = await res.json();
      allMessages = data || [];
      renderMessageMarkers(allMessages);
      return;
    } catch (err) {
      console.warn('API not reachable, using demo data');
    }
  }
  // Demo fallback
  allMessages = getDemoMessages();
  renderMessageMarkers(allMessages);
}
function renderMessageMarkers(messages) {
  messageMarkers.forEach(m => map.removeLayer(m));
  messageMarkers = [];

  messages.forEach(msg => {
    if (!msg.latitude || !msg.longitude) return;
   const isSeen = seenMessages.has(msg.m_id);
const marker = L.marker([msg.latitude, msg.longitude], {
  icon: L.divIcon({
    html: `<div style="font-size:1.4rem;${isSeen ? 'filter:grayscale(100%);opacity:0.5' : ''}">
             ${typeIcon(msg.m_type)}
           </div>`,
    className: '',
    iconSize: [30, 30],
    iconAnchor: [15, 15]
  })
}).addTo(map);

    // Popup
    marker.bindPopup(`
      <div style="font-family:'DM Sans',sans-serif;min-width:180px">
        <div style="font-size:0.7rem;color:#6b7280;margin-bottom:4px">
          ${typeIcon(msg.m_type)} ${msg.m_type?.toUpperCase()}
        </div>
        <div style="font-size:0.72rem;color:#6b7280">
          by ${msg.creator_name || 'unknown'}
           </div>
    <div style="font-size:0.75rem;color:#6b7280;margin-top:4px">
      🔍 Click for details
        </div>
      </div>
    `);

    marker.on('click', () => {
      marker.openPopup();
      showMessageDetail(msg);
    });

    messageMarkers.push(marker);
  });
}

function showMessageDetail(msg) {
   seenMessages.add(msg.m_id);
   if (msg.view_once) {
  const idx = allMessages.findIndex(m => m.m_id === msg.m_id);
  if (idx !== -1 && messageMarkers[idx]) {
    map.removeLayer(messageMarkers[idx]);
    messageMarkers.splice(idx, 1);
    allMessages.splice(idx, 1);
  }
}
  if (messageCircles[msg.m_id]) {
    map.removeLayer(messageCircles[msg.m_id]);
    delete messageCircles[msg.m_id];
  }
}
  updateMarkerAppearance(msg.m_id);
  const panel = document.getElementById('sidePanel');
  const panelBadge = document.getElementById('panelBadge');
  const panelBody = document.getElementById('panelBody');

  if (!panel || !panelBody) return;

  if (panelBadge) {
    panelBadge.textContent = msg.m_type.toUpperCase();
  }

  let body = `
    <div style="margin-bottom:16px">
      <div style="font-size:0.75rem;color:#6b7280;margin-bottom:4px">
        ${msg.creator_name} · ${msg.uni_name || 'Unknown universe'}
      </div>
    </div>
  `;

   if (msg.creator_name === currentUser?.username) {
    body += `
      <button onclick="deleteMessage(${msg.m_id})" 
              style="background:rgba(255,77,109,0.1);border:1px solid rgba(255,77,109,0.3);
                     border-radius:8px;padding:8px 12px;color:#ff4d6d;cursor:pointer;
                     font-size:0.8rem;margin-bottom:12px;width:100%">
        Delete Message
      </button>
    `;
  }

  if (msg.distance !== undefined) {
    const locked = msg.distance > (msg.unl_rad || 50);

    if (!locked && msg.m_txt) {
      body += `
        <div style="background:#13151e;border-radius:10px;padding:14px;margin-bottom:14px;
                    font-size:0.9rem;line-height:1.6">
          ${msg.m_txt}
        </div>
      `;
    }

   if (!locked && msg.m_type === 'poll' && msg.poll_options) {
  body += `<div style="font-weight:600;margin-bottom:10px">${msg.m_txt}</div>`;
  body += `<div style="display:flex;flex-direction:column;gap:8px">`;
  msg.poll_options.forEach(opt => {
    body += `
      <button onclick="votePoll(${opt.option_id})"
              style="background:#1e2030;border:1px solid #2d3048;
                     border-radius:8px;padding:10px;color:white;cursor:pointer">
        ${opt.option_text}
      </button>`;
  });
  body += `</div>`;
}

    body += `
      <div style="background:${locked ? 'rgba(255,77,109,0.1)' : 'rgba(45,228,200,0.1)'};
                  border:1px solid ${locked ? 'rgba(255,77,109,0.3)' : 'rgba(45,228,200,0.3)'};
                  border-radius:10px;padding:12px;margin-top:12px;font-size:0.85rem;
                  color:${locked ? '#ff4d6d' : '#2de4c8'}">
        ${locked
          ? `🔒 Locked — ${formatDist(msg.distance)} away (need ${msg.unl_rad}m)`
          : `🔓 Unlocked!`
        }
      </div>
    `;
  }

  panelBody.innerHTML = body;
  panel.classList.add('active');

function updateMarkerAppearance(msgId) {
  const idx = allMessages.findIndex(m => m.m_id === msgId);
  if (idx === -1) return;
  
  const marker = messageMarkers[idx];
  if (!marker) return;
  
  // Grauer Icon
  marker.setIcon(L.divIcon({
    html: `<div style="font-size:1.4rem;filter:grayscale(100%);opacity:0.5">🎁</div>`,
    className: '',
    iconSize: [30, 30],
    iconAnchor: [15, 15]
  }));
}
function closeSidePanel() {
  const panel = document.getElementById('sidePanel');
  if (panel) panel.classList.remove('active');
}

async function deleteMessage(msgId) {
  try {
    if (USE_API) {
      const res = await fetch(`${API}/messages/${msgId}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${currentUser.token}` }
      });
      if (!res.ok) throw new Error('API error');
    }
  } catch (err) {
    console.warn('API not available, deleting locally');
  }

  if (messageCircles[msgId]) {
    map.removeLayer(messageCircles[msgId]);
    delete messageCircles[msgId];
  }

  allMessages = allMessages.filter(m => m.m_id !== msgId);
  renderMessageMarkers(allMessages);
  closeSidePanel();
  showToast('Message deleted 🚪', 'success');
}

function filterMessagesByUniverse(uniId) {
  if (uniId === 'all') {
    renderMessageMarkers(allMessages);
  } else {
    const filtered = allMessages.filter(m => m.uni_id == uniId);
    renderMessageMarkers(filtered);
  }
}

// 
//  LOAD UNIVERSES
// 
async function loadUniverses() {
  if (!USE_API) {
    allUniverses = getDemoUniverses();
    fillUniverseDropdowns();
    renderUniverseListInReceiver();
    return;
  }
try {
  const res = await fetch(`${API}/universes`, {
    headers: { 'Authorization': currentUser.token }  // ← so
  });
  const data = await res.json();
  allUniverses = data.map(u => ({
    uni_id: u.uni_id,
    uni_name: u.uni_name,
    pub_priv: !u.access,
    descri: u.descri,
    message_count: 0,
    member_count: 0
  }));
    fillUniverseDropdowns();
    renderUniverseListInReceiver();
  } catch (err) {
    console.warn('API not reachable, using demo data');
    allUniverses = getDemoUniverses();
    fillUniverseDropdowns();
    renderUniverseListInReceiver();
  }
}

function fillUniverseDropdowns() {
  // Sender modal dropdown (only universes the user hasn't left)
    const dropdown3 = document.getElementById('senderUniverseSelect');
  if (dropdown3) {
    dropdown3.innerHTML = allUniverses
      .filter(u => !hiddenUniverses.includes(u.uni_id))
      .map(u => `<option value="${u.uni_id}">${getUniverseIcon(u.uni_name)} ${u.uni_name}</option>`)
      .join('');
  }
 }

//  LOAD POIs

async function loadPOIs() {
  try {
        const res = await fetch(`${API}/locations`);
    const data = await res.json();
    allPOIs = data.pois || [];
    
    console.log('✓ Loaded', allPOIs.length, 'POIs');
    // Don't render by default - wait for user to click button

  } catch (err) {
    console.warn('POI API not reachable');
    allPOIs = getDemoPOIs();
  }
}

function toggleLayer(layer) {
  const btnMessages = document.getElementById('btnMessages');
  const btnPOIs = document.getElementById('btnPOIs');

  if (layer === 'messages') {
    if (btnMessages?.classList.contains('active')) {
      messageMarkers.forEach(m => map.removeLayer(m));
      messageMarkers = [];
      btnMessages.classList.remove('active');
    } else {
      renderMessageMarkers(allMessages);
      if (btnMessages) btnMessages.classList.add('active');
    }
  } else if (layer === 'pois') {
    if (btnPOIs?.classList.contains('active')) {
      poiMarkers.forEach(m => map.removeLayer(m));
      poiMarkers = [];
      btnPOIs.classList.remove('active');
    } else {
      renderPOIMarkers(allPOIs);
      if (btnPOIs) btnPOIs.classList.add('active');
    }
  }
}

function renderPOIMarkers(pois) {
  poiMarkers.forEach(m => map.removeLayer(m));
  poiMarkers = [];

  pois.forEach(poi => {
    if (!poi.latitude || !poi.longitude) return;

    const style = getPOIStyle(poi.poi_category);

    const marker = L.marker([poi.latitude, poi.longitude], {
      icon: L.divIcon({
        html: `<div style="font-size:1.4rem">${style.icon}</div>`,
        className: '',
        iconSize: [30, 30],
        iconAnchor: [15, 15]
      })
    }).addTo(map);

    marker.bindPopup(`
      <div style="font-family:'DM Sans',sans-serif">
        <div style="font-size:1rem;margin-bottom:4px">${style.icon}</div>
        <div style="font-size:0.85rem;font-weight:600">${poi.poi_name}</div>
        <div style="font-size:0.7rem;color:#6b7280">${poi.poi_category?.replace(/_/g,' ')}</div>
      </div>
    `);

    poiMarkers.push(marker);
  });
}
 
//  HELPERS

function showToast(msg, type = '') {
  const toast = document.getElementById('toast');
  if (!toast) return;
  
  toast.textContent = msg;
  toast.className = `toast ${type}`;
  toast.classList.remove('hidden');
  
  setTimeout(() => toast.classList.add('hidden'), 3000);
}

function typeIcon(type) {
  return { text: '🎁', poll: '🎁' }[type] || '📍';
}

function formatDist(meters) {
  if (!meters && meters !== 0) return '';
  return meters >= 1000 ? `${(meters/1000).toFixed(1)}km` : `${Math.round(meters)}m`;
}

function getUniColor(uniId) {
  const colors = ['#f5a623','#2de4c8','#a78bfa','#ff4d6d','#34d399','#60a5fa'];
  return colors[uniId % colors.length];
}

function getPOIStyle(category) {
  const styles = {
    metro_stations: { icon: '🚇', color: '#818cf8' },
    picnic_parks:   { icon: '🌿', color: '#34d399' },
    statues:        { icon: '🗿', color: '#f5a623' },
    theaters:       { icon: '🎭', color: '#fb923c' }
  };
  return styles[category] || { icon: '📌', color: '#6b7280' };
}

//  DEMO DATA right now we use static data, but this simulates what an API response would look like

// Demo users with passwords for testing
const DEMO_USERS = [
  { username: 'wilmakahl', password: 'pass123' },
  { username: 'marietranova', password: 'test123' },
  { username: 'bekirbeko', password: 'demo123' },
  { username: 'admin', password: 'admin' }
];

function getDemoMessages() {
  return [
    { m_id:1, m_type:'text', latitude:38.7169, longitude:-9.1393,
      m_txt:'Did you know? The Belém Tower was built in the 16th century! 🏰',
      creator_name:'marietranova', uni_name:'LisboaFunfacts', uni_id:2001, distance:142, unl_rad:50 },
    { m_id:2, m_type:'poll', latitude:38.7200, longitude:-9.1450, 
      question_text:'Would you recommend this viewpoint? 🌅',  answers: ['Yes 👍', 'No 👎'], 
      creator_name:'wilmadora', uni_name:'SunsetViewpoints', uni_id:2004, distance:380, unl_rad:30 },
    { m_id:3, m_type:'poll', latitude:38.7140, longitude:-9.1334,
      question_text:'Best pastel de nata spot?', answers: ['Manteigaria', 'Pastéis de Belém', 'Nata Lisboa'],
      creator_name:'bekirbeko', uni_name:'LisboaFunfacts', uni_id:2001, distance:520, unl_rad:40 },
    { m_id:4, m_type:'text', latitude:38.7100, longitude:-9.1480,
      m_txt:'Amazing pastel de nata here! Try it with cinnamon! 🍰',
      creator_name:'lindaelfriede', uni_name:'RestaurantReviews', uni_id:2003, distance:890, unl_rad:35 },
    { m_id:5, m_type:'text', latitude:38.7250, longitude:-9.1560,
      m_txt:'Live Fado tonight at 8pm! Free entry 🎵',
      creator_name:'jacobvanmeer', uni_name:'LisbonEvents', uni_id:2009, distance:1200, unl_rad:60 }
  ];
}

function getDemoUniverses() {
  return [
    { uni_id:2001, uni_name:'LisboaFunfacts', pub_priv:true, descri:'Funfacts about Lisbon', member_count:15, message_count:12 },
    { uni_id:2002, uni_name:'GeoTech252627', pub_priv:false, descri:'For GeoTech students', member_count:42, message_count:5 },
    { uni_id:2003, uni_name:'RestaurantReviewsLisbon', pub_priv:true, descri:'Restaurant reviews', member_count:8, message_count:3 },
    { uni_id:2004, uni_name:'SunsetViewpoints', pub_priv:true, descri:'Best sunset spots', member_count:21, message_count:8 },
    { uni_id:2009, uni_name:'LisbonEvents', pub_priv:true, descri:'Events in Lisbon', member_count:55, message_count:7 }
  ];
}

function getDemoPOIs() {
  return [
    { poi_name:'Praça do Comércio', poi_category:'metro_stations', latitude:38.7077, longitude:-9.1371, distance:320 },
    { poi_name:'Jardim da Estrela', poi_category:'picnic_parks', latitude:38.7155, longitude:-9.1610, distance:540 },
    { poi_name:'Padrão dos Descobrimentos', poi_category:'statues', latitude:38.6936, longitude:-9.2057, distance:1200 },
    { poi_name:'Teatro Nacional D. Maria II', poi_category:'theaters', latitude:38.7139, longitude:-9.1387, distance:1800 }
  ];
}

// 
//  SIDEBAR VIEW SWITCHING
// 

let currentSenderMsgType = 'text';
let senderSelectedLocation = null;
let locationMode = 'pin'; // 'pin' or 'search'

function switchView(view) {
  // Update tabs
  document.querySelectorAll('.view-tab').forEach(t => t.classList.remove('active'));
  document.querySelectorAll('.sidebar-view').forEach(v => v.classList.remove('active'));
  
  if (view === 'receiver') {
    document.getElementById('tabReceiver').classList.add('active');
    document.getElementById('viewReceiver').classList.add('active');
  } else {
    document.getElementById('tabSender').classList.add('active');
    document.getElementById('viewSender').classList.add('active');
  }
}

// Search universes
function searchUniverses(query) {
  if (!query.trim()) {
    // empty query - show all
    renderUniverseListInReceiver();
    return;
  }

  //search for all universes that include the query (case-insensitive)
  const results = allUniverses.filter(u => 
    u.uni_name.toLowerCase().includes(query.toLowerCase())
  );

  const list = document.getElementById('universeListReceiver');
  if (!list) return;

  if (!results.length) {
    list.innerHTML = '<div class="list-empty">No universes found</div>';
    return;
  }

  list.innerHTML = results.map(u => {
    const isHidden = hiddenUniverses.includes(u.uni_id);
    return `
      <div class="uni-item-new" onclick="filterMessagesByUniverse(${u.uni_id})">
        <div class="uni-item-icon">${getUniverseIcon(u.uni_name)}</div>
        <div class="uni-item-text">
          <div class="uni-item-name">${u.uni_name}</div>
          <div class="uni-item-count">${isHidden ? '👋 Left' : u.message_count + ' messages'}</div>
        </div>
        ${isHidden
          ? `<div class="uni-item-delete" onclick="rejoinUniverse(${u.uni_id}, event)" title="Rejoin">➕</div>`
          : `<div class="uni-item-delete" onclick="deleteUniverse(${u.uni_id}, event)" title="Leave">🚪</div>`
        }
      </div>
    `;
  }).join('');
}
// Delete universe
function deleteUniverse(uniId, event) {
  event.stopPropagation(); // Don't trigger click on parent

    // Remove from list
    hiddenUniverses.push(uniId);

     renderUniverseListInReceiver();
  fillUniverseDropdowns();

  showToast('Universe left 👋', 'success'); 
}

// Rejoin universe

function rejoinUniverse(uniId, event) {
  event.stopPropagation();
  hiddenUniverses = hiddenUniverses.filter(id => id !== uniId);
  renderUniverseListInReceiver();
  fillUniverseDropdowns();
  showToast('Universe rejoined! 🌐', 'success');
}
//
//  SENDER VIEW FUNCTIONS
// 

function setSenderMsgType(type, btn) {
  currentSenderMsgType = type;
  
  document.querySelectorAll('.type-pill').forEach(p => p.classList.remove('active'));
  btn.classList.add('active');
  
  // Show/hide fields
  if (type === 'text') {
    document.getElementById('senderTextGroup').classList.remove('hidden');
    document.getElementById('senderQuestionGroup').classList.add('hidden');
  } else {
    document.getElementById('senderTextGroup').classList.add('hidden');
    document.getElementById('senderQuestionGroup').classList.remove('hidden');
  }
}

function setLocationMode(mode) {
  locationMode = mode;
  
  document.querySelectorAll('.location-btn').forEach(b => b.classList.remove('active'));
  
  if (mode === 'pin') {
    document.getElementById('btnDropPin').classList.add('active');
    document.getElementById('locationSearchBox').classList.add('hidden');
    showToast('Click on the map to drop a pin 📍');
  } else {
    document.getElementById('btnSearchLocation').classList.add('active');
    document.getElementById('locationSearchBox').classList.remove('hidden');
  }
}

function updateSenderRadius(val) {
  document.getElementById('senderRadiusLabel').textContent = val + 'm';
    if (senderSelectedLocation) {
    if (window.radiusCircle) map.removeLayer(window.radiusCircle);
    window.radiusCircle = L.circle([senderSelectedLocation.lat, senderSelectedLocation.lng], {
      radius: parseInt(val),
      fillColor: '#8f2de4', fillOpacity: 0.1,
      color: '#8f2de4', weight: 1, dashArray: '5, 5'
    }).addTo(map);
  }
}

function searchLocation(event) {
  if (event.key === 'Enter') {
    const query = event.target.value.toLowerCase();
    
    // POIs durchsuchen
    const found = allPOIs.find(poi => 
      poi.poi_name.toLowerCase().includes(query)
    );
    
    if (found) {
      // Karte auf POI zoomen
      map.setView([found.latitude, found.longitude], 17);
      
      // Temp marker setzen
      if (window.tempMarker) map.removeLayer(window.tempMarker);
      window.tempMarker = L.circleMarker([found.latitude, found.longitude], {
        radius: 12,
        fillColor: '#f5a623',
        fillOpacity: 0.8,
        color: 'white',
        weight: 2
      }).addTo(map).bindPopup(`📍 ${found.poi_name}`).openPopup();
      
      // Location setzen
      senderSelectedLocation = { lat: found.latitude, lng: found.longitude };
      updateLocationDisplay(senderSelectedLocation);
      
      showToast(`📍 ${found.poi_name} selected!`, 'success');
    } else {
      showToast('No POI found — try another name', 'error');
    }
  }
}
async function submitMessageFromSidebar() {
  if (!senderSelectedLocation) {
    showToast('Please select a location first!', 'error');
    return;
  }

  const universeId = parseInt(document.getElementById('senderUniverseSelect').value);
  const radius = parseInt(document.getElementById('senderRadiusSlider').value);
  const viewOnce = document.getElementById('viewOnceToggle').checked; 

    let content;
  if (currentSenderMsgType === 'text') {
    content = document.getElementById('senderTextContent').value.trim();
    if (!content) { showToast('Please enter a message!', 'error'); return; }
  } else {
    content = document.getElementById('senderQuestionContent').value.trim();
    if (!content) { showToast('Please enter a question!', 'error'); return; }
  }

    if (USE_API) {
    try {const uniName = allUniverses.find(u => u.uni_id == universeId)?.uni_name;
      const body = {
        m_type: currentSenderMsgType,
        uni_name: uniName,
        unl_rad: radius,
        latitude: senderSelectedLocation.lat,
        longitude: senderSelectedLocation.lng,
        view_once: viewOnce,
        m_txt: content
      };

      if (currentSenderMsgType === 'poll') {
        const answerInputs = document.querySelectorAll('.answer-option');
        const pollOptions = Array.from(answerInputs).map(i => i.value.trim()).filter(v => v);
        body.poll = { p_txt: content, poll_options: pollOptions };
      }
        const res = await fetch(`${API}/messages`, {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': currentUser.token
        },
        body: JSON.stringify(body)
      });

      if (!res.ok) {
        const data = await res.json();
        showToast(`❌ ${data.error}`, 'error');
        return;
      }

    } catch (err) {
      showToast('Server not reachable', 'error');
      return;
    }
  }
  // 1. creating message object

    const newMsg = {
    m_id: Date.now(),
    m_type: currentSenderMsgType,
    latitude: senderSelectedLocation.lat,
    longitude: senderSelectedLocation.lng,
    creator_name: currentUser.username,
    uni_name: allUniverses.find(u => u.uni_id == universeId)?.uni_name || 'Unknown',
    uni_id: universeId,
    distance: 0,
    unl_rad: radius,
    view_once: viewOnce
  };

  // 2. creating marker
  const marker = L.marker([newMsg.latitude, newMsg.longitude], {
    icon: L.divIcon({
      html: `<div style="font-size:1.4rem">${typeIcon(currentSenderMsgType)}</div>`,
      className: '', iconSize: [30, 30], iconAnchor: [15, 15]
    })
  }).addTo(map).bindPopup(`
    <div style="font-family:'DM Sans',sans-serif">
      <div style="font-size:0.9rem;font-weight:600;margin-bottom:6px">${content}</div>
      <div style="font-size:0.7rem;color:#6b7280">by ${currentUser.username}</div>
    </div>
  `).openPopup();

  marker.on('click', () => { marker.openPopup(); showMessageDetail(newMsg); });
  messageMarkers.push(marker);

  // 3. Buffer circle for unlock radius
  const circle = L.circle([newMsg.latitude, newMsg.longitude], {
    radius: radius, fillColor: '#8f2de4', fillOpacity: 0.1,
    color: '#8f2de4', weight: 1, dashArray: '5, 5'
  }).addTo(map);

  messageCircles[newMsg.m_id] = circle;
  allMessages.push(newMsg);

  // 4. Reset form
  document.getElementById('senderTextContent').value = '';
  document.getElementById('senderQuestionContent').value = '';
  senderSelectedLocation = null;
  updateLocationDisplay(null);
  if (window.tempMarker) map.removeLayer(window.tempMarker);

  showToast('Message dropped! 📍', 'success');
}

function updateLocationDisplay(location) {
  const display = document.getElementById('senderLocationDisplay');
  const icon = display.querySelector('.location-icon');
  const text = display.querySelector('.location-text');
  
  if (location) {
    display.classList.add('selected');
    icon.textContent = '✓';
    text.textContent = `${location.lat.toFixed(4)}°N, ${Math.abs(location.lng).toFixed(4)}°W`;
  } else {
    display.classList.remove('selected');
    icon.textContent = '🖱️';
    text.textContent = 'Click on map to set location';
  }
}


// 
//  CREATE & DELETE UNIVERSE

let newUniversePublic = true; // Default: public

function openCreateUniverseModal() {
  const modal = document.getElementById('createUniverseModal');
  if (modal) modal.classList.remove('hidden');
}

function closeCreateUniverseModal() {
  const modal = document.getElementById('createUniverseModal');
  if (modal) modal.classList.add('hidden');

  // Reset form
  const nameInput = document.getElementById('newUniverseName');
  const descInput = document.getElementById('newUniverseDesc');
  const errorDiv = document.getElementById('universeError');
  
  if (nameInput) nameInput.value = '';
  if (descInput) descInput.value = '';
  if (errorDiv) errorDiv.classList.add('hidden');
  
  // Reset to public
  newUniversePublic = true;
  document.getElementById('universePublic')?.classList.add('active');
  document.getElementById('universePrivate')?.classList.remove('active');
}

// if use clicks outside modal content, close modal

function closeModalOnBg(event) {
  if (event.target.classList.contains('modal-backdrop')) {
    const clickedModal = event.target;
    
    if (clickedModal.id === 'createUniverseModal') {
      closeCreateUniverseModal();
    } else if (clickedModal.id === 'aboutModal') {
      closeAboutModal();
    } else if (clickedModal.id === 'discoverModal') {
      closeDiscoverModal();
    }
    else if (clickedModal.id === 'fundModal') {
  closeFundModal();
  }
}
}

function setUniversePrivacy(isPublic, btn) {
  newUniversePublic = isPublic;
  
  document.querySelectorAll('#createUniverseModal .type-tab').forEach(t => 
    t.classList.remove('active')
  );
  btn.classList.add('active');
}

async function submitCreateUniverse() {
  const nameInput = document.getElementById('newUniverseName');
  const descInput = document.getElementById('newUniverseDesc');
  const errorDiv = document.getElementById('universeError');
  
  const name = nameInput?.value.trim();
  const desc = descInput?.value.trim();
  
  // Validation
  if (!name) {
    if (errorDiv) {
      errorDiv.classList.remove('hidden');
      errorDiv.textContent = '❌ Please enter a universe name';
    }
    return;
  }
  
  if (name.length < 3) {
    if (errorDiv) {
      errorDiv.classList.remove('hidden');
      errorDiv.textContent = '❌ Name must be at least 3 characters';
    }
    return;
  }
  
  // Check if name already exists
  const exists = allUniverses.find(u => 
    u.uni_name.toLowerCase() === name.toLowerCase()
  );
  
  if (exists) {
    if (errorDiv) {
      errorDiv.classList.remove('hidden');
      errorDiv.textContent = '❌ Universe name already taken';
    }
    return;
  }
  
  // Create universe object
  const newUniverse = {
    uni_id: Date.now(), // Simple ID generation for demo
    uni_name: name,
    descri: desc || 'No description',
    pub_priv: newUniversePublic,
    member_count: 1,
    message_count: 0
  };
  
  try {
    // Try API first
    const res = await fetch(`${API}/universes`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json',
      'Authorization': currentUser.token
    },
      body: JSON.stringify({
        uni_name: name,
        access: !newUniversePublic, 
        descri: desc,
      })
    });
    
    if (res.ok) {
      const data = await res.json();
      newUniverse.uni_id = data.universe_id || newUniverse.uni_id;
    }
  } catch (err) {
    console.warn('API not available, using local data');
  }
  
  // Add to local array
  allUniverses.push(newUniverse);
  
  // Update UI
  fillUniverseDropdowns();
  renderUniverseListInReceiver();
  
  showToast('Universe created! 🌐', 'success');
  closeCreateUniverseModal();
}

// Render universe list in receiver view with delete buttons
function renderUniverseListInReceiver() {
  const list = document.getElementById('universeListReceiver');
  if (!list) return;
  
  // to make delete work without API, we keep track of "hidden" universes in an array-- just for demo purposes
    const visible = allUniverses.filter(u => !hiddenUniverses.includes(u.uni_id));

  if (!visible.length) {
    list.innerHTML = '<div class="list-empty">No universes found</div>';
    return;
  }
  
  list.innerHTML = visible.map(u => `
    <div class="uni-item-new" onclick="filterMessagesByUniverse(${u.uni_id})">
      <div class="uni-item-icon">${getUniverseIcon(u.uni_name)}</div>
      <div class="uni-item-text">
        <div class="uni-item-name">${u.uni_name}</div>
        <div class="uni-item-count">${u.message_count || 0} messages</div>
      </div>
      <div class="uni-item-delete" onclick="deleteUniverse(${u.uni_id}, event)" title="Delete">
        🚪
      </div>
    </div>
  `).join('');
}

// Helper to get icon for universe
function getUniverseIcon(name) {
  const icons = {
    'LisboaFunfacts': '🏙️',
    'GeoTech252627': '🎓',
    'RestaurantReviews': '🍽️',
    'SunsetViewpoints': '🌅',
    'LisbonEvents': '🎵',
    'LisbonRepair': '🔧',
    'LostAndFound': '🔍',
    'Swifties': '🎤',
    'Erasmus': '✈️'
  };
  
  // Try to match by partial name
  for (const key in icons) {
    if (name.includes(key)) return icons[key];
  }
  
  return '🌐'; // Default
}

function addAnswerField() {
  const list = document.getElementById('answersList');
  const count = list.querySelectorAll('.answer-option').length + 1;
  
  const wrapper = document.createElement('div');
  wrapper.style.cssText = 'display:flex;gap:6px;margin-bottom:6px;align-items:center';
  wrapper.innerHTML = `
    <input type="text" class="field-input-compact answer-option" 
           placeholder="Option ${count}" style="flex:1"/>
    <button onclick="removeAnswerField(this)" 
            style="background:none;border:1px solid #ff4d6d;border-radius:6px;
                   padding:4px 8px;color:#ff4d6d;cursor:pointer;flex-shrink:0">
      ✕
    </button>
  `;
  list.appendChild(wrapper);
  updateRemoveButtons();
}

function removeAnswerField(btn) {
  const list = document.getElementById('answersList');
  btn.parentElement.remove();
  updateRemoveButtons();
}

function updateRemoveButtons() {
  const list = document.getElementById('answersList');
  const wrappers = list.querySelectorAll('div');
  wrappers.forEach(wrapper => {
    const btn = wrapper.querySelector('button');
    if (btn) btn.style.display = wrappers.length <= 2 ? 'none' : 'block';
  });
}

function openAboutModal() {
  document.getElementById('aboutModal').classList.remove('hidden');
}

function closeAboutModal() {
  document.getElementById('aboutModal').classList.add('hidden');
}


async function openDiscoverModal() {
  const list = document.getElementById('discoverList');
  list.innerHTML = '<div class="list-empty">Loading...</div>';
  document.getElementById('discoverModal').classList.remove('hidden');

  try {
    const res = await fetch(`${API}/universes/public`);
    const data = await res.json();

    if (!data.length) {
      list.innerHTML = '<div class="list-empty">No public universes found</div>';
      return;
    }

    list.innerHTML = data.map(u => `
      <div class="uni-item-new">
        <div class="uni-item-icon">${getUniverseIcon(u.uni_name)}</div>
        <div class="uni-item-text">
          <div class="uni-item-name">${u.uni_name}</div>
          <div class="uni-item-count">${u.descri || ''}</div>
        </div>
        <div class="uni-item-delete" onclick="joinUniverse('${u.uni_id}', '${u.uni_name}')" 
             title="Join" style="color:#2de4c8">➕</div>
      </div>
    `).join('');

  } catch (err) {
    list.innerHTML = '<div class="list-empty">Could not load universes</div>';
  }
}

function closeDiscoverModal() {
  document.getElementById('discoverModal').classList.add('hidden');
}

function joinUniverse(uniId) {
  hiddenUniverses = hiddenUniverses.filter(id => id !== uniId);
  renderUniverseListInReceiver();
  fillUniverseDropdowns();
  closeDiscoverModal();
  showToast('Universe joined! 🌍', 'success');
}

function openFundModal() {
  document.getElementById('fundModal').classList.remove('hidden');
}

function closeFundModal() {
  document.getElementById('fundModal').classList.add('hidden');
}

function updateViewOnceIcon(checkbox) {
  const icon = document.getElementById('viewOnceIcon');
  icon.textContent = checkbox.checked ? '🫣' : '👁️';
}