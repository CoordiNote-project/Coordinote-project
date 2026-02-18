// ═══════════════════════════════════════════════
//  CoordiNote – app.js (rewritten to match your HTML!)
//  Connects to your HTML with the correct IDs
// ═══════════════════════════════════════════════

// ── Configuration ──
const API = 'http://localhost:5000/api';
const LISBON = [38.7169, -9.1393];

// ── Global Variables ──
let map;
let currentUser = null;
let allMessages = [];
let messageMarkers = [];
let poiMarkers = [];
let selectedLocation = null;
let currentMsgType = 'text';
let allUniverses = [];
let allPOIs = [];

// ═══════════════════════════════════════════════
//  START APP (when page loads)
// ═══════════════════════════════════════════════
document.addEventListener('DOMContentLoaded', () => {
  console.log('✓ CoordiNote starting...');

  // Get elements
  const loginBtn = document.getElementById('loginBtn');
  const loginModal = document.getElementById('loginModal');
  const app = document.getElementById('app');
  
  // Hide app at start
  if (app) app.classList.add('hidden');

  // Login button click
  if (loginBtn) {
    loginBtn.addEventListener('click', handleLogin);
  }

  // Setup event listeners
  setupEventListeners();
});

// ═══════════════════════════════════════════════
//  LOGIN
// ═══════════════════════════════════════════════
function handleLogin() {
  const loginModal = document.getElementById('loginModal');
  const app = document.getElementById('app');
  const loginUser = document.getElementById('loginUser');
  const loginPass = document.getElementById('loginPass');
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

  // Check against demo users
  const validUser = DEMO_USERS.find(u => 
    u.username === username && u.password === password
  );

  if (!validUser) {
    if (loginError) {
      loginError.classList.remove('hidden');
      loginError.textContent = '❌ Wrong username or password';
    }
    return;
  }

  // Login successful!
  currentUser = { 
    username: username, 
    id: 1001,
    location: null
  };
  
  // Get user location for lock/unlock
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(pos => {
      currentUser.location = {
        lat: pos.coords.latitude,
        lng: pos.coords.longitude
      };
      console.log('✓ Got user location:', currentUser.location);
      loadMessages(); // Reload to update lock status
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

// ═══════════════════════════════════════════════
//  EVENT LISTENERS
// ═══════════════════════════════════════════════
function setupEventListeners() {

  // Close modal buttons
  const closeModalBtn = document.getElementById('closeModalBtn');
  const cancelModalBtn = document.getElementById('cancelModalBtn');
  if (closeModalBtn) closeModalBtn.addEventListener('click', closeCreateModal);
  if (cancelModalBtn) cancelModalBtn.addEventListener('click', closeCreateModal);

  // Submit message
  const submitBtn = document.getElementById('submitMessageBtn');
  if (submitBtn) submitBtn.addEventListener('click', submitMessage);

  // Type tabs
  const typeTabs = document.querySelectorAll('.type-tab');
  typeTabs.forEach(tab => {
    tab.addEventListener('click', () => {
      const type = tab.getAttribute('data-type');
      setMsgType(type, tab);
    });
  });

  // Radius slider
  const radiusSlider = document.getElementById('radiusSlider');
  if (radiusSlider) {
    radiusSlider.addEventListener('input', (e) => {
      const display = document.getElementById('radiusDisplay');
      if (display) {
        display.textContent = `${e.target.value} m`;
      }
    });
  }

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

  // Universe dropdown
  const universeDropdown = document.getElementById('universeDropdown');
  if (universeDropdown) {
    universeDropdown.addEventListener('change', (e) => {
      filterMessagesByUniverse(e.target.value);
    });
  }

  // Logout button
  const logoutBtn = document.getElementById('logoutBtn');
  if (logoutBtn) {
    logoutBtn.addEventListener('click', () => {
      location.reload(); // Simple logout - just reload page
    });
  }
}

// ═══════════════════════════════════════════════
//  MAP
// ═══════════════════════════════════════════════
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

  console.log('✓ Map initialized!');
}

function onMapClick(e) {
  selectedLocation = { lat: e.latlng.lat, lng: e.latlng.lng };

  // Remove old temp marker
  if (window.tempMarker) map.removeLayer(window.tempMarker);

  // Add new temp marker
  window.tempMarker = L.circleMarker(e.latlng, {
    radius: 12,
    fillColor: '#f5a623',
    fillOpacity: 0.8,
    color: 'white',
    weight: 2
  }).addTo(map).bindPopup('📍 New message location').openPopup();

  // Update location chip
  const chip = document.getElementById('locationChip');
  if (chip) {
    chip.className = 'location-chip ok';
    chip.textContent = `✓ Location: ${e.latlng.lat.toFixed(4)}°N, ${Math.abs(e.latlng.lng).toFixed(4)}°W`;
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

// ═══════════════════════════════════════════════
//  LOAD MESSAGES
// ═══════════════════════════════════════════════
async function loadMessages() {
  if (!map) return;
  
  const center = map.getCenter();
  const radius = 5000; // 5km

  try {
    const res = await fetch(
      `${API}/messages/nearby?latitude=${center.lat}&longitude=${center.lng}&radius=${radius}`
    );
    const data = await res.json();
    allMessages = data.messages || [];
    
    console.log('✓ Loaded', allMessages.length, 'messages');
    renderMessageMarkers(allMessages);
    updateStats();

  } catch (err) {
    console.warn('API not reachable, using demo data');
    allMessages = getDemoMessages();
    renderMessageMarkers(allMessages);
    updateStats();
  }
}

function renderMessageMarkers(messages) {
  // Clear old markers
  messageMarkers.forEach(m => map.removeLayer(m));
  messageMarkers = [];

  messages.forEach(msg => {
    if (!msg.latitude || !msg.longitude) return;

    const marker = L.circleMarker([msg.latitude, msg.longitude], {
      radius: 14,
      fillColor: typeColor(msg.m_type),
      fillOpacity: 0.85,
      color: 'white',
      weight: 2
    }).addTo(map);

    // Popup
    marker.bindPopup(`
      <div style="font-family:'DM Sans',sans-serif;min-width:180px">
        <div style="font-size:0.7rem;color:#6b7280;margin-bottom:4px">
          ${typeIcon(msg.m_type)} ${msg.m_type?.toUpperCase()}
        </div>
        <div style="font-size:0.9rem;font-weight:600;margin-bottom:6px">
          ${msg.m_txt || msg.question_text || 'Message'}
        </div>
        <div style="font-size:0.72rem;color:#6b7280">
          by ${msg.creator_name || 'unknown'}
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
  const panel = document.getElementById('sidePanel');
  const panelBadge = document.getElementById('panelBadge');
  const panelBody = document.getElementById('panelBody');

  if (!panel || !panelBody) return;

  // Set badge
  if (panelBadge) {
    panelBadge.textContent = msg.m_type.toUpperCase();
  }

  // Build body content
  let body = `
    <div style="margin-bottom:16px">
      <div style="font-size:0.75rem;color:#6b7280;margin-bottom:4px">
        ${msg.creator_name} · ${msg.uni_name || 'Unknown universe'}
      </div>
    </div>
  `;

  if (msg.m_txt) {
    body += `
      <div style="background:#13151e;border-radius:10px;padding:14px;margin-bottom:14px;
                  font-size:0.9rem;line-height:1.6">
        ${msg.m_txt}
      </div>
    `;
  }

  if (msg.question_text) {
    body += `
      <div style="font-weight:600;margin-bottom:10px;font-size:0.95rem">
        ${msg.question_text}
      </div>
    `;
  }

  if (msg.distance !== undefined) {
    const locked = msg.distance > (msg.unl_rad || 50);
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
}

function closeSidePanel() {
  const panel = document.getElementById('sidePanel');
  if (panel) panel.classList.remove('active');
}

function filterMessagesByUniverse(uniId) {
  if (uniId === 'all') {
    renderMessageMarkers(allMessages);
  } else {
    const filtered = allMessages.filter(m => m.uni_id == uniId);
    renderMessageMarkers(filtered);
  }
}

// ═══════════════════════════════════════════════
//  LOAD UNIVERSES
// ═══════════════════════════════════════════════
async function loadUniverses() {
  try {
    const res = await fetch(`${API}/universes`);
    const data = await res.json();
    allUniverses = data.universes || [];
    
    console.log('✓ Loaded', allUniverses.length, 'universes');
    fillUniverseDropdowns();

  } catch (err) {
    console.warn('Universe API not reachable');
    allUniverses = getDemoUniverses();
    fillUniverseDropdowns();
  }
}

function fillUniverseDropdowns() {
  // Sidebar dropdown
  const dropdown1 = document.getElementById('universeDropdown');
  if (dropdown1) {
    dropdown1.innerHTML = '<option value="all">All Universes</option>' +
      allUniverses.map(u => `<option value="${u.uni_id}">${u.uni_name}</option>`).join('');
  }

  // Modal dropdown
  const dropdown2 = document.getElementById('modalUniverse');
  if (dropdown2) {
    dropdown2.innerHTML = allUniverses.map(u => 
      `<option value="${u.uni_id}">${u.uni_name}</option>`
    ).join('');
  }

  // Universe list in sidebar
  const universeList = document.getElementById('universeList');
  if (universeList) {
    universeList.innerHTML = allUniverses.slice(0, 5).map(u => `
      <div class="uni-item">
        <div class="uni-dot" style="background:${getUniColor(u.uni_id)}"></div>
        <div class="uni-name">${u.uni_name}</div>
        <div class="uni-count">${u.message_count || 0}</div>
      </div>
    `).join('');
  }
}

// ═══════════════════════════════════════════════
//  LOAD POIs
// ═══════════════════════════════════════════════
async function loadPOIs() {
  try {
    const res = await fetch(
      `${API}/poi?latitude=${LISBON[0]}&longitude=${LISBON[1]}&radius=10000`
    );
    const data = await res.json();
    allPOIs = data.pois || [];
    
    console.log('✓ Loaded', allPOIs.length, 'POIs');
    // Don't render by default - wait for user to click button

  } catch (err) {
    console.warn('POI API not reachable');
    allPOIs = getDemoPOIs();
  }
}

function renderPOIMarkers(pois) {
  // Clear old POI markers
  poiMarkers.forEach(m => map.removeLayer(m));
  poiMarkers = [];

  pois.forEach(poi => {
    if (!poi.latitude || !poi.longitude) return;

    const style = getPOIStyle(poi.poi_category);
    
    const marker = L.circleMarker([poi.latitude, poi.longitude], {
      radius: 10,
      fillColor: style.color,
      fillOpacity: 0.7,
      color: 'white',
      weight: 2
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

function toggleLayer(layer) {
  const btnMessages = document.getElementById('btnMessages');
  const btnPOIs = document.getElementById('btnPOIs');

  if (layer === 'messages') {
    if (btnMessages?.classList.contains('active')) {
      // Hide messages
      messageMarkers.forEach(m => map.removeLayer(m));
      messageMarkers = [];
      btnMessages.classList.remove('active');
    } else {
      // Show messages
      renderMessageMarkers(allMessages);
      if (btnMessages) btnMessages.classList.add('active');
    }
  } else if (layer === 'pois') {
    if (btnPOIs?.classList.contains('active')) {
      // Hide POIs
      poiMarkers.forEach(m => map.removeLayer(m));
      poiMarkers = [];
      btnPOIs.classList.remove('active');
    } else {
      // Show POIs
      renderPOIMarkers(allPOIs);
      if (btnPOIs) btnPOIs.classList.add('active');
    }
  }
}

// ═══════════════════════════════════════════════
//  CREATE MESSAGE
// ═══════════════════════════════════════════════
function openCreateModal() {
  const modal = document.getElementById('createModal');
  if (modal) modal.classList.remove('hidden');
}

function closeCreateModal() {
  const modal = document.getElementById('createModal');
  if (modal) modal.classList.add('hidden');
  
  // Reset form
  const modalText = document.getElementById('modalText');
  const modalQuestion = document.getElementById('modalQuestion');
  if (modalText) modalText.value = '';
  if (modalQuestion) modalQuestion.value = '';
  
  // Reset location
  if (window.tempMarker) map.removeLayer(window.tempMarker);
  selectedLocation = null;
  
  const chip = document.getElementById('locationChip');
  if (chip) {
    chip.className = 'location-chip';
    chip.textContent = '🖱️ Click on the map to set location first';
  }
}

function setMsgType(type, btn) {
  currentMsgType = type;
  
  // Update active tab
  document.querySelectorAll('.type-tab').forEach(t => t.classList.remove('active'));
  btn.classList.add('active');

  // Show/hide fields
  const textSection = document.getElementById('textSection');
  const questionSection = document.getElementById('questionSection');
  
  if (currentMsgType === 'text') {
    if (textSection) textSection.classList.remove('hidden');
    if (questionSection) questionSection.classList.add('hidden');
  } else {
    if (textSection) textSection.classList.add('hidden');
    if (questionSection) questionSection.classList.remove('hidden');
  }
}

async function submitMessage() {
  if (!selectedLocation) {
    showToast('Please click on the map first!', 'error');
    return;
  }

  if (!currentUser) {
    showToast('Please login first!', 'error');
    return;
  }

  const universeId = parseInt(document.getElementById('modalUniverse')?.value);
  const unlockRadius = parseInt(document.getElementById('radiusSlider')?.value || 50);

  const body = {
    user_id: currentUser.id,
    message_type: currentMsgType,
    longitude: selectedLocation.lng,
    latitude: selectedLocation.lat,
    universe_id: universeId,
    unlock_radius: unlockRadius
  };

  if (currentMsgType === 'text') {
    const txt = document.getElementById('modalText')?.value.trim();
    if (!txt) {
      showToast('Please enter a message!', 'error');
      return;
    }
    body.text_content = txt;
  } else {
    const q = document.getElementById('modalQuestion')?.value.trim();
    if (!q) {
      showToast('Please enter a question!', 'error');
      return;
    }
    body.question = {
      question_text: q,
      answers: currentMsgType === 'yesno'
        ? [{ answer_text: 'Yes', is_correct: true }, { answer_text: 'No', is_correct: false }]
        : [{ answer_text: 'Option A', is_correct: true },
           { answer_text: 'Option B', is_correct: false },
           { answer_text: 'Option C', is_correct: false }]
    };
  }

  try {
    const res = await fetch(`${API}/messages`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });

    if (!res.ok) throw new Error('API error');

    showToast('Message dropped! 📍', 'success');
    closeCreateModal();
    loadMessages();

  } catch (err) {
    console.warn('API error, using demo mode');
    showToast('Message placed! (Demo mode)', 'success');
    closeCreateModal();
  }
}

// ═══════════════════════════════════════════════
//  HELPERS
// ═══════════════════════════════════════════════
function updateStats() {
  const statMessages = document.getElementById('statMessages');
  const statPOIs = document.getElementById('statPOIs');
  
  if (statMessages) statMessages.textContent = allMessages.length;
  if (statPOIs) statPOIs.textContent = allPOIs.length;
}

function showToast(msg, type = '') {
  const toast = document.getElementById('toast');
  if (!toast) return;
  
  toast.textContent = msg;
  toast.className = `toast ${type}`;
  toast.classList.remove('hidden');
  
  setTimeout(() => toast.classList.add('hidden'), 3000);
}

function typeIcon(type) {
  return { text: '💬', yesno: '✅', poll: '📊' }[type] || '📍';
}

function typeColor(type) {
  return { text: '#f5a623', yesno: '#2de4c8', poll: '#a78bfa' }[type] || '#6b7280';
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

// ═══════════════════════════════════════════════
//  DEMO DATA (if API not available)
// ═══════════════════════════════════════════════

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
    { m_id:2, m_type:'yesno', latitude:38.7200, longitude:-9.1450,
      question_text:'Would you recommend this viewpoint? 🌅',
      creator_name:'wilmadora', uni_name:'SunsetViewpoints', uni_id:2004, distance:380, unl_rad:30 },
    { m_id:3, m_type:'poll', latitude:38.7140, longitude:-9.1334,
      question_text:'Best pastel de nata spot?',
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

// ═══════════════════════════════════════════════
//  SIDEBAR VIEW SWITCHING
// ═══════════════════════════════════════════════

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
  const items = document.querySelectorAll('.uni-item-new');
  items.forEach(item => {
    const name = item.querySelector('.uni-item-name').textContent.toLowerCase();
    if (name.includes(query.toLowerCase())) {
      item.style.display = 'flex';
    } else {
      item.style.display = 'none';
    }
  });
}

// Delete universe
function deleteUniverse(uniId, event) {
  event.stopPropagation(); // Don't trigger click on parent
  if (confirm('Delete this universe?')) {
    // Remove from list
    const item = event.target.closest('.uni-item-new');
    if (item) item.remove();
    showToast('Universe deleted', 'success');
    // TODO: Call API to actually delete
  }
}

// Open create universe modal (you can build this later)
function openCreateUniverseModal() {
  showToast('Create Universe modal - coming soon!');
}

// ═══════════════════════════════════════════════
//  SENDER VIEW FUNCTIONS
// ═══════════════════════════════════════════════

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
}

function searchLocation(event) {
  if (event.key === 'Enter') {
    const query = event.target.value;
    showToast('Location search - coming soon! Try "Drop Pin" mode');
    // TODO: Add geocoding API (Nominatim/Google)
  }
}

function submitMessageFromSidebar() {
  if (!senderSelectedLocation) {
    showToast('Please select a location first!', 'error');
    return;
  }
  
  const universeId = parseInt(document.getElementById('senderUniverseSelect').value);
  const radius = parseInt(document.getElementById('senderRadiusSlider').value);
  
  let content;
  if (currentSenderMsgType === 'text') {
    content = document.getElementById('senderTextContent').value.trim();
    if (!content) {
      showToast('Please enter a message!', 'error');
      return;
    }
  } else {
    content = document.getElementById('senderQuestionContent').value.trim();
    if (!content) {
      showToast('Please enter a question!', 'error');
      return;
    }
  }
  
  // Create marker on map
  L.circleMarker([senderSelectedLocation.lat, senderSelectedLocation.lng], {
    radius: 14,
    fillColor: typeColor(currentSenderMsgType),
    fillOpacity: 0.85,
    color: 'white',
    weight: 2
  }).addTo(map).bindPopup(`
    <div style="font-family:'DM Sans',sans-serif">
      <div style="font-size:0.9rem;font-weight:600;margin-bottom:6px">
        ${content}
      </div>
      <div style="font-size:0.7rem;color:#6b7280">
        by ${currentUser.username}
      </div>
    </div>
  `).openPopup();
  
  showToast('Message dropped! 📍', 'success');
  
  // Reset form
  document.getElementById('senderTextContent').value = '';
  document.getElementById('senderQuestionContent').value = '';
  senderSelectedLocation = null;
  updateLocationDisplay(null);
  
  if (window.tempMarker) map.removeLayer(window.tempMarker);
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

// Update the onMapClick function
function onMapClick(e) {
  // If in sender view and pin mode, set location
  const senderView = document.getElementById('viewSender');
  if (senderView?.classList.contains('active') && locationMode === 'pin') {
    senderSelectedLocation = { lat: e.latlng.lat, lng: e.latlng.lng };
    
    // Remove old temp marker
    if (window.tempMarker) map.removeLayer(window.tempMarker);
    
    // Add new temp marker
    window.tempMarker = L.circleMarker(e.latlng, {
      radius: 12,
      fillColor: '#f5a623',
      fillOpacity: 0.8,
      color: 'white',
      weight: 2
    }).addTo(map).bindPopup('📍 New message location').openPopup();
    
    updateLocationDisplay(senderSelectedLocation);
  }
}