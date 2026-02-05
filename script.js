// OMNI PROJECT - CORE CONFIGURATION
const CONFIG = {
    API_URL: "https://wekfwxlbhxvtxdhhfuwi.supabase.co/rest/v1/users",
    API_KEY: "sb_publishable_BI3-uLPVvNkxXcV76qxkOw_MxZiNYVT",
    LOG_URL: "https://wekfwxlbhxvtxdhhfuwi.functions.supabase.co/smooth-task"
};

// DOM Elements
const profileModal = document.getElementById('profileModal');
const adminModal = document.getElementById('adminModal');
const userAvatar = document.getElementById('userAvatar');
const headerAuthBtn = document.getElementById('headerAuthBtn');
const btnAdminPanel = document.getElementById('btnAdminPanel');
const closeProfileModal = document.getElementById('closeProfileModal');
const closeAdminModal = document.getElementById('closeAdminModal');

let currentUser = JSON.parse(localStorage.getItem('omni_user_data')) || null;

// Initialization
async function init() {
    console.log("System Initializing...");
    
    // Mouse glow effect
    const mouseGlow = document.querySelector('.bg-mouse-glow');
    if (mouseGlow) {
        document.addEventListener('mousemove', (e) => {
            mouseGlow.style.left = e.clientX - 250 + 'px';
            mouseGlow.style.top = e.clientY - 250 + 'px';
            mouseGlow.style.opacity = '1';
        });
        document.addEventListener('mouseleave', () => {
            mouseGlow.style.opacity = '0';
        });
    }
    
    // Setup event listeners
    setupEventListeners();
    
    // Auth check
    if (currentUser) {
        await reVerifyUser(currentUser.username, currentUser.password);
    } else {
        updateUserUI();
    }
    
    // Animation for cards
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, { threshold: 0.1 });
    
    document.querySelectorAll('.card').forEach(card => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(20px)';
        card.style.transition = 'opacity 0.5s, transform 0.5s';
        observer.observe(card);
    });
}

function setupEventListeners() {
    // Close modals
    if (closeProfileModal) {
        closeProfileModal.addEventListener('click', () => {
            profileModal.classList.remove('active');
        });
    }
    
    if (closeAdminModal) {
        closeAdminModal.addEventListener('click', () => {
            adminModal.classList.remove('active');
        });
    }
    
    // Close on outside click
    window.addEventListener('click', (e) => {
        if (e.target === profileModal) profileModal.classList.remove('active');
        if (e.target === adminModal) adminModal.classList.remove('active');
    });
    
    // Admin button
    if (btnAdminPanel) {
        btnAdminPanel.addEventListener('click', (e) => {
            e.preventDefault();
            profileModal.classList.remove('active');
            adminModal.classList.add('active');
            fetchAdminData();
        });
    }
}

async function reVerifyUser(username, password) {
    try {
        const res = await fetch(`${CONFIG.API_URL}?username=eq.${encodeURIComponent(username)}&password=eq.${encodeURIComponent(password)}&select=*`, {
            headers: {
                "apikey": CONFIG.API_KEY,
                "Authorization": "Bearer " + CONFIG.API_KEY
            }
        });
        const data = await res.json();
        if (data && data.length > 0) {
            currentUser = data[0];
            localStorage.setItem('omni_user_data', JSON.stringify(currentUser));
            updateUserUI();
        } else {
            logout();
        }
    } catch (e) {
        updateUserUI();
    }
}

function updateUserUI() {
    if (headerAuthBtn) {
        if (currentUser) {
            // Change Login button to Cabinet
            headerAuthBtn.innerHTML = `<i class="fa-solid fa-user"></i> <span>Cabinet</span>`;
            headerAuthBtn.href = "#";
            headerAuthBtn.onclick = (e) => {
                e.preventDefault();
                renderProfile();
                profileModal.classList.add('active');
            };
            
            if (userAvatar) {
                userAvatar.style.display = 'flex';
                userAvatar.textContent = currentUser.username[0].toUpperCase();
                userAvatar.style.background = currentUser.is_admin ? 
                    'linear-gradient(135deg, #ff4d4d, #ff6b6b)' : 
                    'linear-gradient(135deg, var(--accent), var(--accent-secondary))';
            }
        } else {
            // Show Login button
            headerAuthBtn.innerHTML = `<i class="fa-solid fa-right-to-bracket"></i> <span>Login</span>`;
            headerAuthBtn.href = "/login";
            headerAuthBtn.onclick = null;
            
            if (userAvatar) userAvatar.style.display = 'none';
        }
    }
}

function renderProfile() {
    if (!currentUser) return;
    
    // Update profile modal content
    const profAvatar = document.getElementById('profAvatar');
    const profUsername = document.getElementById('profUsername');
    const profBadge = document.getElementById('profBadge');
    const profSubDays = document.getElementById('profSubDays');
    const profUid = document.getElementById('profUid');
    const btnAdminPanel = document.getElementById('btnAdminPanel');
    
    if (profAvatar) {
        profAvatar.textContent = currentUser.username[0].toUpperCase();
        profAvatar.style.background = currentUser.is_admin ? 
            'linear-gradient(135deg, #ff4d4d, #ff6b6b)' : 
            'linear-gradient(135deg, var(--accent), var(--accent-secondary))';
    }
    
    if (profUsername) profUsername.textContent = currentUser.username;
    
    if (profBadge) {
        profBadge.textContent = currentUser.is_admin ? 'Admin' : 
            (currentUser.is_subscribed ? 'Premium' : 'User');
        profBadge.style.background = currentUser.is_admin ? 
            'rgba(255, 77, 77, 0.2)' : 
            'rgba(16, 185, 129, 0.2)';
        profBadge.style.color = currentUser.is_admin ? '#ff4d4d' : 'var(--success)';
    }
    
    if (btnAdminPanel) {
        btnAdminPanel.style.display = currentUser.is_admin ? 'flex' : 'none';
    }
    
    if (profSubDays) {
        profSubDays.textContent = currentUser.is_subscribed ? 'Premium' : 'Standard';
    }
    
    if (profUid) {
        profUid.textContent = '#' + (currentUser.id.toString().slice(-4) || '0000');
    }
}

// Admin functions
async function fetchAdminData() {
    if (!currentUser || !currentUser.is_admin) return;
    
    try {
        const res = await fetch(`${CONFIG.API_URL}?select=*&order=id.desc`, {
            headers: { 
                "apikey": CONFIG.API_KEY, 
                "Authorization": "Bearer " + CONFIG.API_KEY 
            }
        });
        const users = await res.json();
        
        if (users) {
            document.getElementById('admTotalUsers').textContent = users.length;
            document.getElementById('admBannedUsers').textContent = users.filter(u => u.is_banned).length;
            renderAdminTable(users);
        }
    } catch (e) {
        console.error("Admin fetch error:", e);
    }
}

function renderAdminTable(users) {
    const adminUserList = document.getElementById('adminUserList');
    if (!adminUserList) return;
    
    adminUserList.innerHTML = '';
    users.forEach(user => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td>#${user.id}</td>
            <td>
                <div style="display: flex; align-items: center; gap: 8px;">
                    <div class="user-avatar" style="width: 24px; height: 24px; font-size: 0.7rem; background: ${user.is_admin ? '#ff4d4d' : 'var(--accent)'};">
                        ${user.username[0].toUpperCase()}
                    </div>
                    ${user.username}
                </div>
            </td>
            <td style="font-family: monospace;">${user.last_ip || 'N/A'}</td>
            <td>${user.is_admin ? '<span style="color: #ff4d4d;">Admin</span>' : 'User'}</td>
            <td>${user.is_banned ? '<span style="color: #ff4d4d;">Banned</span>' : '<span style="color: #4ade80;">Active</span>'}</td>
            <td>
                <button class="a-action-btn" onclick="toggleBan(${user.id}, ${!user.is_banned})">
                    <i class="fa-solid ${user.is_banned ? 'fa-check' : 'fa-ban'}"></i>
                </button>
            </td>
        `;
        adminUserList.appendChild(tr);
    });
}

window.toggleBan = async function(userId, banStatus) {
    if (!confirm(`Are you sure you want to ${banStatus ? 'BAN' : 'UNBAN'} this user?`)) return;
    
    try {
        await fetch(`${CONFIG.API_URL}?id=eq.${userId}`, {
            method: 'PATCH',
            headers: {
                "apikey": CONFIG.API_KEY,
                "Authorization": "Bearer " + CONFIG.API_KEY,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({ is_banned: banStatus })
        });
        fetchAdminData();
    } catch (e) {
        console.error("Ban update error:", e);
    }
};

window.logout = function() {
    localStorage.removeItem('omni_user_data');
    currentUser = null;
    updateUserUI();
    if (profileModal) profileModal.classList.remove('active');
    if (adminModal) adminModal.classList.remove('active');
    window.location.reload();
};

// Initialize
document.addEventListener('DOMContentLoaded', init);