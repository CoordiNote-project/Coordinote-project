// ═══════════════════════════════════════════════
//  CoordiNote – app.js
//  Hier passiert die ganze LOGIK:
//  - Karte initialisieren
//  - API aufrufen
//  - Nachrichten anzeigen
//  - Formulare verarbeiten
// ═══════════════════════════════════════════════

// ── Konfiguration ──────────────────────────────
const API = 'http://localhost:5000/api';   // URL zu eurer Flask-API
const LISBON = [38.7169, -9.1393];         // Koordinaten von Lissabon
const DEMO_USER_ID = 1001;                 // Für Demo: fixer User

// ── Globale Variablen ──────────────────────────
let map;                    // Die Leaflet-Karte
let allMessages = [];       // Alle geladenen Nachrichten
let messageMarkers = [];    // Alle Marker auf der Karte
let poiMarkers = [];        // POI-Marker auf der Karte
let selectedLocation = null;// Angeklickter Ort auf der Karte
let currentMsgType = 'text';// Aktuell gewählter Nachrichtentyp
let currentTypeFilter = 'all';
let allPOIs = [];           // Alle geladenen POIs

// ═══════════════════════════════════════════════
//  INITIALISIERUNG (läuft wenn die Seite geladen ist)
// ═══════════════════════════════════════════════
document.addEventListener('DOMContentLoaded', () => {

  const loginBtn = document.getElementById("loginBtn");
  const loginModal = document.getElementById("loginModal");
  const app = document.getElementById("app");

  // Hide app at start
  app.classList.add("hidden");

  // When login button clicked
  loginBtn.addEventListener("click", () => {
    loginModal.classList.add("hidden");
    app.classList.remove("hidden");

    // NOW initialize the app
    initMap();
    loadUniverses();
    loadMessages();
    loadPOIs();
  });

});

// ═══════════════════════════════════════════════
//  KARTE
// ═══════════════════════════════════════════════

function initMap() {
  // Karte erstellen, zentriert auf Lissabon, Zoom-Level 13
  map = L.map('map').setView(LISBON, 13);

  // Kartenkacheln von OpenStreetMap laden (kostenlos!)
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '© OpenStreetMap contributors',
    maxZoom: 19
  }).addTo(map);

  // Klick auf die Karte → Standort für neue Nachricht wählen
  map.on('click', onMapClick);

  // Eigenen Standort anzeigen (falls Browser erlaubt)
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(pos => {
      const { latitude: lat, longitude: lng } = pos.coords;
      // Blauer Punkt für eigenen Standort
      L.circleMarker([lat, lng], {
        radius: 10,
        fillColor: '#2de4c8',
        fillOpacity: 1,
        color: 'white',
        weight: 3
      }).addTo(map).bindPopup('📍 Your location');
    });
  }
}

// Wenn der User auf die Karte klickt
function onMapClick(e) {
  selectedLocation = { lat: e.latlng.lat, lng: e.latlng.lng };

  // Temporärer oranger Marker zeigt gewählten Punkt
  if (window.tempMarker) map.removeLayer(window.tempMarker);
  window.tempMarker = L.circleMarker(e.latlng, {
    radius: 12,
    fillColor: '#f5a623',
    fillOpacity: 0.8,
    color: 'white',
    weight: 2
  }).addTo(map).bindPopup('📍 New message will be placed here').openPopup();

  // Chip im Modal auf "grün" setzen
  const chip = document.getElementById('locationChip');
  chip.className = 'location-chip ok';
  chip.textContent = `✓ Location: ${e.latlng.lat.toFixed(4)}°N, ${Math.abs(e.latlng.lng).toFixed(4)}°W`;
}

// ═══════════════════════════════════════════════
//  NACHRICHTEN LADEN (GET /api/messages/nearby)
// ═══════════════════════════════════════════════

async function loadMessages() {
  const center = map ? map.getCenter() : { lat: LISBON[0], lng: LISBON[1] };
  const radius = document.getElementById('radiusSlider')?.value || 2000;

  try {
    // API-Anfrage senden
    const res = await fetch(
      `${API}/messages/nearby?latitude=${center.lat}&longitude=${center.lng}&radius=${radius}`
    );
    const data = await res.json();
    allMessages = data.messages || [];

    renderMessageList(allMessages); // Liste in Sidebar zeigen
    renderMessageMarkers(allMessages); // Marker auf Karte setzen

  } catch (err) {
    // API nicht erreichbar? Demo-Daten zeigen
    console.warn('API not reachable, showing demo data:', err);
    allMessages = getDemoMessages();
    renderMessageList(allMessages);
    renderMessageMarkers(allMessages);
  }
}

// Nachrichten-Liste in der Sidebar rendern
function renderMessageList(messages) {
  const list = document.getElementById('messageList');

  if (!messages.length) {
    list.innerHTML = '<div class="list-empty">No messages found nearby</div>';
    return;
  }

  // Für jede Nachricht ein HTML-Element erstellen
  list.innerHTML = messages.map(msg => `
    <div class="msg-item" onclick="showDetail(${msg.m_id})">
      <div class="msg-item-top">
        <span class="msg-item-icon">${typeIcon(msg.m_type)}</span>
        <span class="msg-item-title">${truncate(msg.m_txt || msg.question_text || 'Message', 32)}</span>
        <span class="msg-item-dist">${formatDist(msg.distance)}</span>
      </div>
      <div class="msg-item-sub">${msg.creator_name || 'unknown'} · ${msg.uni_name || ''}</div>
    </div>
  `).join('');
}

// Marker auf der Karte setzen
function renderMessageMarkers(messages) {
  // Alte Marker löschen
  messageMarkers.forEach(m => map.removeLayer(m));
  messageMarkers = [];

  messages.forEach(msg => {
    if (!msg.latitude || !msg.longitude) return;

    // Farbiger Kreis-Marker je nach Typ
    const marker = L.circleMarker([msg.latitude, msg.longitude], {
      radius: 14,
      fillColor: typeColor(msg.m_type),
      fillOpacity: 0.85,
      color: 'white',
      weight: 2
    }).addTo(map);

    // Popup beim Klick auf den Marker
    marker.bindPopup(`
      <div style="font-family:'DM Sans',sans-serif;min-width:180px">
        <div style="font-size:0.7rem;color:#6b7280;margin-bottom:4px">
          ${typeIcon(msg.m_type)} ${msg.m_type?.toUpperCase()} · ${msg.uni_name || ''}
        </div>
        <div style="font-size:0.9rem;font-weight:600;margin-bottom:6px">
          ${msg.m_txt || msg.question_text || 'Message'}
        </div>
        <div style="font-size:0.72rem;color:#6b7280">by ${msg.creator_name || 'unknown'}</div>
        <button onclick="showDetail(${msg.m_id})"
          style="margin-top:10px;width:100%;padding:7px;background:#f5a623;border:none;
                 border-radius:8px;font-weight:700;font-size:0.8rem;cursor:pointer;color:#0c0e14">
          Open Message
        </button>
      </div>
    `);

    marker.on('click', () => marker.openPopup());
    messageMarkers.push(marker);
  });
}

// ═══════════════════════════════════════════════
//  DETAIL-ANSICHT einer Nachricht
// ═══════════════════════════════════════════════

async function showDetail(msgId) {
  const msg = allMessages.find(m => m.m_id === msgId);
  if (!msg) return;

  document.getElementById('detailTitle').textContent =
    `${typeIcon(msg.m_type)} ${msg.m_type?.toUpperCase()} Message`;

  let body = `
    <div style="margin-bottom:12px">
      <div style="font-size:0.72rem;color:#6b7280;margin-bottom:4px">By ${msg.creator_name} · ${msg.uni_name}</div>
    </div>
  `;

  // Text-Inhalt der Nachricht
  if (msg.m_txt) {
    body += `
      <div style="background:#13151e;border-radius:10px;padding:14px;margin-bottom:14px;
                  font-size:0.88rem;line-height:1.6">
        ${msg.m_txt}
      </div>
    `;
  }

  // Frage + Antworten (für poll / yesno)
  if (msg.question_text) {
    body += `
      <div style="font-weight:600;margin-bottom:10px">${msg.question_text}</div>
    `;
    if (msg.answers?.length) {
      body += msg.answers.map((a, i) => `
        <div style="background:#13151e;border:1px solid #252836;border-radius:10px;
                    padding:10px 14px;margin-bottom:6px;font-size:0.85rem;cursor:pointer;"
             onclick="this.style.borderColor='#f5a623';this.style.color='#f5a623'">
          ${['A','B','C','D'][i] || i+1}. ${a.aswr_txt}
        </div>
      `).join('');
    }
  }

  // Distanz-Info
  if (msg.distance !== undefined) {
    const locked = msg.distance > msg.unl_rad;
    body += `
      <div style="background:${locked ? 'rgba(255,77,109,0.1)' : 'rgba(45,228,200,0.1)'};
                  border:1px solid ${locked ? 'rgba(255,77,109,0.3)' : 'rgba(45,228,200,0.3)'};
                  border-radius:10px;padding:12px;margin-top:12px;font-size:0.82rem;
                  color:${locked ? '#ff4d6d' : '#2de4c8'}">
        ${locked
          ? `🔒 Locked — you are ${formatDist(msg.distance)} away (need ${msg.unl_rad}m)`
          : `🔓 Unlocked — you are within range!`
        }
      </div>
    `;
  }

  document.getElementById('detailBody').innerHTML = body;
  document.getElementById('detailModal').classList.remove('hidden');
}

function closeDetailModal() {
  document.getElementById('detailModal').classList.add('hidden');
}

// ═══════════════════════════════════════════════
//  UNIVERSES LADEN (GET /api/universes)
// ═══════════════════════════════════════════════

const UNI_COLORS = ['#f5a623','#2de4c8','#a78bfa','#ff4d6d','#34d399','#60a5fa','#fb923c','#f472b6'];
const UNI_ICONS  = {'LisboaFunfacts':'🏙️','SunsetViewpoints':'🌅','GeoTech252627':'🎓',
                    'LisbonRepair':'🔧','LisbonEvents':'🎵','LostAndFound':'🔍',
                    'RestaurantReviewsLisbon':'🍽️','Swifties':'🎤','Erasmus2026summer':'✈️'};

async function loadUniverses() {
  try {
    const res = await fetch(`${API}/universes`);
    const data = await res.json();
    const universes = data.universes || [];

    renderUniverseGrid(universes);
    fillUniverseDropdown(universes);

  } catch (err) {
    console.warn('Universe API not reachable:', err);
    renderUniverseGrid(getDemoUniverses());
    fillUniverseDropdown(getDemoUniverses());
  }
}

function renderUniverseGrid(universes) {
  const grid = document.getElementById('universeGrid');
  if (!universes.length) {
    grid.innerHTML = '<div class="list-empty">No universes found</div>';
    return;
  }

  grid.innerHTML = universes.map((u, i) => `
    <div class="uni-card" style="--uni-color:${UNI_COLORS[i % UNI_COLORS.length]}">
      <div class="uni-icon">${UNI_ICONS[u.uni_name] || '🌐'}</div>
      ${!u.pub_priv ? '<div class="uni-private">🔒 Private</div>' : ''}
      <div class="uni-name">${u.uni_name}</div>
      <div class="uni-desc">${u.descri || 'No description'}</div>
      <div class="uni-stats">
        <span>👥 ${u.member_count || '–'}</span>
        <span>📍 ${u.message_count || '–'}</span>
      </div>
    </div>
  `).join('');
}

function fillUniverseDropdown(universes) {
  const sel = document.getElementById('msgUniverse');
  sel.innerHTML = universes.map(u =>
    `<option value="${u.uni_id}">${u.uni_name}</option>`
  ).join('');
}

// ═══════════════════════════════════════════════
//  POIs LADEN (GET /api/poi)
// ═══════════════════════════════════════════════

const POI_STYLES = {
  metro_stations: { icon: '🚇', color: '#818cf8', bg: 'rgba(99,102,241,0.15)' },
  picnic_parks:   { icon: '🌿', color: '#34d399', bg: 'rgba(52,211,153,0.15)' },
  statues:        { icon: '🗿', color: '#f5a623', bg: 'rgba(245,166,35,0.15)' },
  theaters:       { icon: '🎭', color: '#fb923c', bg: 'rgba(251,146,60,0.15)' },
};

async function loadPOIs() {
  const center = LISBON;
  try {
    const res = await fetch(`${API}/poi?latitude=${center[0]}&longitude=${center[1]}&radius=10000`);
    const data = await res.json();
    allPOIs = data.pois || [];
    renderPOIList(allPOIs);
  } catch (err) {
    console.warn('POI API not reachable:', err);
    allPOIs = getDemoPOIs();
    renderPOIList(allPOIs);
  }
}

function renderPOIList(pois) {
  const list = document.getElementById('poiList');
  if (!pois.length) {
    list.innerHTML = '<div class="list-empty">No POIs found</div>';
    return;
  }

  list.innerHTML = pois.map(poi => {
    const style = POI_STYLES[poi.poi_category] || { icon:'📌', color:'#6b7280', bg:'rgba(107,114,128,0.15)' };
    return `
      <div class="poi-row">
        <div class="poi-icon-wrap" style="background:${style.bg}">${style.icon}</div>
        <div class="poi-text">
          <div class="poi-name">${poi.poi_name}</div>
          <div class="poi-cat">${poi.poi_category?.replace(/_/g,' ')}</div>
        </div>
        <div class="poi-dist" style="color:${style.color}">
          ${poi.distance ? formatDist(poi.distance) : ''}
        </div>
      </div>
    `;
  }).join('');
}

function filterPOI(cat, btn) {
  // Chip-Buttons updaten
  document.querySelectorAll('#panel-poi .chip').forEach(c => c.classList.remove('active'));
  btn.classList.add('active');

  const filtered = cat === 'all' ? allPOIs : allPOIs.filter(p => p.poi_category === cat);
  renderPOIList(filtered);
}

// ═══════════════════════════════════════════════
//  NACHRICHT ERSTELLEN (POST /api/messages)
// ═══════════════════════════════════════════════

function openCreateModal() {
  document.getElementById('createModal').classList.remove('hidden');
}

function closeCreateModal() {
  document.getElementById('createModal').classList.add('hidden');
  // Formular zurücksetzen
  document.getElementById('msgText').value = '';
  document.getElementById('msgQuestion').value = '';
}

function setMsgType(type, btn) {
  currentMsgType = type;
  document.querySelectorAll('.type-tab').forEach(t => t.classList.remove('active'));
  btn.classList.add('active');

  // Felder ein-/ausblenden
  document.getElementById('fieldText').classList.toggle('hidden', type !== 'text');
  document.getElementById('fieldQuestion').classList.toggle('hidden', type === 'text');
}

async function submitMessage() {
  // Standort gewählt?
  if (!selectedLocation) {
    showToast('Please click on the map first!', 'error');
    return;
  }

  const universeId = parseInt(document.getElementById('msgUniverse').value);
  const unlockRadius = parseInt(document.getElementById('unlockSlider').value);

  // Daten zusammenbauen
  const body = {
    user_id:       DEMO_USER_ID,
    message_type:  currentMsgType,
    longitude:     selectedLocation.lng,
    latitude:      selectedLocation.lat,
    universe_id:   universeId,
    unlock_radius: unlockRadius,
  };

  if (currentMsgType === 'text') {
    const txt = document.getElementById('msgText').value.trim();
    if (!txt) { showToast('Please enter a message!', 'error'); return; }
    body.text_content = txt;
  } else {
    const q = document.getElementById('msgQuestion').value.trim();
    if (!q) { showToast('Please enter a question!', 'error'); return; }
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

    // Karte updaten
    if (window.tempMarker) map.removeLayer(window.tempMarker);
    selectedLocation = null;
    loadMessages();

  } catch (err) {
    // Auch ohne API: Demo-Marker zeigen
    showToast('Message placed! (Demo mode)', 'success');
    closeCreateModal();
    if (window.tempMarker) {
      window.tempMarker.bindPopup('📍 Your new message!').openPopup();
    }
  }
}

// ═══════════════════════════════════════════════
//  FILTER & SUCHE
// ═══════════════════════════════════════════════

function setTypeFilter(type, btn) {
  currentTypeFilter = type;
  document.querySelectorAll('.filter-chips .chip').forEach(c => c.classList.remove('active'));
  btn.classList.add('active');
  applyFilters();
}

function filterMessages() { applyFilters(); }

function applyFilters() {
  const search = document.getElementById('searchInput').value.toLowerCase();
  const filtered = allMessages.filter(msg => {
    const text = (msg.m_txt || msg.question_text || '').toLowerCase();
    const matchType = currentTypeFilter === 'all' || msg.m_type === currentTypeFilter;
    const matchSearch = !search || text.includes(search) ||
                        (msg.creator_name || '').toLowerCase().includes(search);
    return matchType && matchSearch;
  });
  renderMessageList(filtered);
}

function updateRadius(val) {
  document.getElementById('radiusLabel').textContent =
    val >= 1000 ? `${(val/1000).toFixed(1)} km` : `${val} m`;
  loadMessages(); // Nachrichten neu laden
}

// ═══════════════════════════════════════════════
//  PANEL NAVIGATION
// ═══════════════════════════════════════════════

function showPanel(name) {
  // Alle Panels verstecken
  document.querySelectorAll('.panel').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));

  // Gewähltes Panel zeigen
  document.getElementById(`panel-${name}`).classList.add('active');
  event.target.classList.add('active');

  // Karte neu rendern wenn Map-Tab (wegen Leaflet-Bug)
  if (name === 'map' && map) setTimeout(() => map.invalidateSize(), 100);
}

// ═══════════════════════════════════════════════
//  MODAL HELPERS
// ═══════════════════════════════════════════════

function closeModalOnBg(e) {
  // Modal schließen wenn Hintergrund geklickt
  if (e.target.classList.contains('modal-overlay')) {
    closeCreateModal();
    closeDetailModal();
  }
}

// ═══════════════════════════════════════════════
//  TOAST NOTIFICATION
// ═══════════════════════════════════════════════

function showToast(msg, type = '') {
  const toast = document.getElementById('toast');
  toast.textContent = msg;
  toast.className = `toast ${type}`;
  toast.classList.remove('hidden');
  setTimeout(() => toast.classList.add('hidden'), 3000);
}

// ═══════════════════════════════════════════════
//  HELPER-FUNKTIONEN
// ═══════════════════════════════════════════════

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

function truncate(str, n) {
  return str.length > n ? str.slice(0, n) + '…' : str;
}

// ═══════════════════════════════════════════════
//  DEMO-DATEN (wenn API nicht läuft)
// ═══════════════════════════════════════════════

function getDemoMessages() {
  return [
    { m_id:1, m_type:'text', latitude:38.7169, longitude:-9.1393,
      m_txt:'Did you know? The Belém Tower was built in the 16th century! 🏰',
      creator_name:'marietranova', uni_name:'LisboaFunfacts', distance:142, unl_rad:50 },
    { m_id:2, m_type:'yesno', latitude:38.7200, longitude:-9.1450,
      question_text:'Would you recommend this viewpoint? 🌅',
      creator_name:'wilmadora', uni_name:'SunsetViewpoints', distance:380, unl_rad:30 },
    { m_id:3, m_type:'poll', latitude:38.7140, longitude:-9.1334,
      question_text:'Why does Convento do Carmo have no roof?',
      creator_name:'bekirbeko', uni_name:'LisboaFunfacts', distance:520, unl_rad:40 },
    { m_id:4, m_type:'text', latitude:38.7100, longitude:-9.1480,
      m_txt:'Amazing pastel de nata here! Try it with cinnamon! 🍰',
      creator_name:'lindaelfriede', uni_name:'RestaurantReviews', distance:890, unl_rad:35 },
    { m_id:5, m_type:'text', latitude:38.7250, longitude:-9.1560,
      m_txt:'Live Fado tonight at 8pm! Free entry 🎵',
      creator_name:'jacobvanmeer', uni_name:'LisbonEvents', distance:1200, unl_rad:60 },
  ];
}

function getDemoUniverses() {
  return [
    { uni_id:2001, uni_name:'LisboaFunfacts',    pub_priv:true,  descri:'Funfacts about Lisbon', member_count:15, message_count:12 },
    { uni_id:2002, uni_name:'GeoTech252627',      pub_priv:false, descri:'For GeoTech students',  member_count:42, message_count:5  },
    { uni_id:2003, uni_name:'RestaurantReviewsLisbon', pub_priv:true, descri:'Restaurant reviews', member_count:8,  message_count:3  },
    { uni_id:2004, uni_name:'SunsetViewpoints',   pub_priv:true,  descri:'Best sunset spots',     member_count:21, message_count:8  },
    { uni_id:2005, uni_name:'Erasmus2026summer',  pub_priv:false, descri:'Erasmus network',       member_count:33, message_count:4  },
    { uni_id:2006, uni_name:'Swifties',           pub_priv:true,  descri:'Taylor Swift fans',     member_count:99, message_count:1  },
    { uni_id:2007, uni_name:'LisbonRepair',       pub_priv:true,  descri:'Report city issues',    member_count:18, message_count:3  },
    { uni_id:2008, uni_name:'LostAndFound',       pub_priv:true,  descri:'Lost & found items',    member_count:12, message_count:2  },
    { uni_id:2009, uni_name:'LisbonEvents',       pub_priv:true,  descri:'Events in Lisbon',      member_count:55, message_count:7  },
  ];
}

function getDemoPOIs() {
  return [
    { poi_name:'Praça do Comércio', poi_category:'metro_stations', distance:320 },
    { poi_name:'Jardim da Estrela', poi_category:'picnic_parks',   distance:540 },
    { poi_name:'Padrão dos Descobrimentos', poi_category:'statues', distance:1200 },
    { poi_name:'Teatro Nacional D. Maria II', poi_category:'theaters', distance:1800 },
    { poi_name:'Cais do Sodré', poi_category:'metro_stations', distance:2100 },
    { poi_name:'Torre de Belém', poi_category:'statues', distance:3400 },
    { poi_name:'Parque Eduardo VII', poi_category:'picnic_parks', distance:1600 },
  ];
}