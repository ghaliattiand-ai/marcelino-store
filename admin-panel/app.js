// ===== MARCELINO Admin Panel JS =====

const API = '/api';
let token = localStorage.getItem('admin_token') || null;
let categoriesCache = [];

// ===== Helpers =====
async function api(path, method = 'GET', body = null, isForm = false) {
  const headers = {};
  if (token) headers['Authorization'] = `Bearer ${token}`;
  if (body && !isForm) headers['Content-Type'] = 'application/json';

  const opts = {
    method,
    headers,
    body: body && !isForm ? JSON.stringify(body) : body,
  };

  const res = await fetch(`${API}${path}`, opts);
  const data = await res.json();

  if (!res.ok) {
    throw new Error(data.message || 'حدث خطأ');
  }
  return data;
}

function showToast(msg, type = 'success') {
  const toast = document.getElementById('toast');
  toast.textContent = msg;
  toast.style.background = type === 'error' ? '#E53935' : '#0D1B3E';
  toast.classList.remove('hidden');
  setTimeout(() => toast.classList.add('hidden'), 3000);
}

// حفظ آخر عنصر مfocused لاستعادة التركيز عند الإغلاق
let _lastFocusedBeforeModal = null;
function showModal(id) {
  const el = document.getElementById(id);
  if (!el) return;
  _lastFocusedBeforeModal = document.activeElement;
  el.classList.remove('hidden');
  // نضمن إعادة التدفق قبل إضافة كلاس الترانزشن ليشتغل الانتقال
  void el.offsetWidth;
  el.classList.add('modal-open');
}
function closeModal(id) {
  const el = document.getElementById(id);
  if (!el) return;
  el.classList.remove('modal-open');
  // نؤخر إضافة .hidden حتى ينتهي الترانزشن
  const onEnd = () => {
    el.classList.add('hidden');
    el.removeEventListener('transitionend', onEnd);
  };
  el.addEventListener('transitionend', onEnd);
  // fallback لو ما صدرش transitionend لأي سبب
  setTimeout(() => { el.classList.add('hidden'); }, 320);
  if (_lastFocusedBeforeModal && _lastFocusedBeforeModal.focus) {
    try { _lastFocusedBeforeModal.focus(); } catch (_) {}
  }
}

// إغلاق المودال العلوRouter بالـ Esc، أو الضغط على الخلفية فقط
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    const open = Array.from(document.querySelectorAll('.modal.modal-open'));
    const top = open[open.length - 1];
    if (top) closeModal(top.id);
  }
});
document.addEventListener('click', (e) => {
  // الضغط على الخلفية (لا على محتواها) يغلق المودال
  if (e.target.classList && e.target.classList.contains('modal') && e.target.classList.contains('modal-open')) {
    closeModal(e.target.id);
  }
});

function formatDate(dateStr) {
  const d = new Date(dateStr);
  return `${d.getDate()}/${d.getMonth() + 1}/${d.getFullYear()}`;
}

function formatPrice(n) {
  return Number(n || 0).toFixed(2);
}

// تحويل الرقم لصيغة دولية (01012345678 → 201012345678) لروابط واتساب/تليفون
function normalizePhone(number) {
  if (!number) return '';
  let n = String(number).replace(/[^\d]/g, '');
  if (n.startsWith('00')) n = n.substring(2);
  if (n.startsWith('0')) n = '20' + n.substring(1);
  return n;
}

// اختصار لطريقة الدفع بالعربي
const PAYMENT_LABELS = {
  cod: { label: 'كاش عند الاستلام', class: 'badge-active' },
  etisalat_cash: { label: 'اتصالات كاش', class: 'badge-pending' },
  instapay: { label: 'إنستا باي', class: 'badge-processing' },
  bank_transfer: { label: 'تحويل بنكي', class: 'badge-blocked' },
};
function paymentLabel(method) {
  return PAYMENT_LABELS[method] || { label: 'كاش عند الاستلام', class: 'badge-active' };
}

// ============================================================
//  Helpers حديثة: عدّ تصاعدي +Skeleton/Empty states
// ============================================================

// عدّ من 0 إلى target خلال duration ms مع easeOut — يكتب النص HTMLElement
function countUp(el, target, duration = 900) {
  if (!el) return;
  const start = 0;
  const t0 = performance.now();
  const isMoney = el.dataset && el.dataset.money === '1';
  function step(now) {
    const p = Math.min(1, (now - t0) / duration);
    const eased = 1 - Math.pow(1 - p, 3); // easeOutCubic
    const v = Math.round(start + (target - start) * eased);
    el.textContent = isMoney ? formatPrice(v) : String(v);
    if (p < 1) requestAnimationFrame(step);
    else el.textContent = isMoney ? formatPrice(target) : String(target);
  }
  requestAnimationFrame(step);
}

// عرض Skeleton في عنصر — يبني n صفوف shimmering
function renderLoading(container, rows = 5) {
  if (!container) return;
  let html = '';
  for (let i = 0; i < rows; i++) {
    html += '<div class="skeleton-row" style="width:' + (50 + (i * 7) % 50) + '%"></div>';
  }
  container.innerHTML = '<div style="padding:18px">' + html + '</div>';
}

// عرض حالة فارغة / خطأ مع زر إعادة المحاولة
function renderEmpty(container, opts) {
  if (!container) return;
  const o = Object.assign({ emoji: '📭', title: 'لا توجد بيانات', desc: '', retry: null }, opts || {});
  const retryBtn = o.retry
    ? '<button class="btn-retry" onclick="' + o.retry + '">↻ إعادة المحاولة</button>'
    : '';
  container.innerHTML =
    '<div class="empty-state">' +
    '<div class="emoji">' + o.emoji + '</div>' +
    '<div class="title">' + o.title + '</div>' +
    (o.desc ? '<div class="desc">' + o.desc + '</div>' : '') +
    retryBtn +
    '</div>';
}

// فتح واتساب برسالة جاهزة لرقم عميل
function openWhatsApp(phone, message) {
  const n = normalizePhone(phone);
  if (!n) { showToast('رقم العميل غير متوفر', 'error'); return; }
  const url = 'https://wa.me/' + n + (message ? '?text=' + encodeURIComponent(message) : '');
  window.open(url, '_blank');
}

// فتح طلب مكالمة
function openTel(phone) {
  const n = normalizePhone(phone);
  if (!n) { showToast('رقم العميل غير متوفر', 'error'); return; }
  window.open('tel:+' + n, '_blank');
}

// حماية من XSS - تحويل أي نص لـ HTML آمن
// مهم: & لازم يكون الأول عشان ما نعمّرش الكيانات اللي بننتجها
function escapeHtml(str) {
  if (str == null) return '';
  return String(str)

    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

// الحصول على رقم الطلب من الـ _id (آخر 6 خانات)
function shortId(id) {
  if (!id) return '';
  return id.length > 6 ? id.slice(-6) : id;
}

const STATUS_LABELS = {
  pending: { label: 'قيد المراجعة', class: 'badge-blue' },
  processing: { label: 'جاري التجهيز', class: 'badge-orange' },
  delivered: { label: 'تم التوصيل', class: 'badge-green' },
  cancelled: { label: 'ملغي', class: 'badge-red' },
};

// ===== Dark Mode =====
function applyDarkMode(isDark) {
  document.body.setAttribute('data-theme', isDark ? 'dark' : 'light');
  const btn = document.getElementById('darkModeToggle');
  if (btn) btn.textContent = isDark ? '☀️' : '🌙';
}

function toggleDarkMode() {
  const current = document.body.getAttribute('data-theme') === 'dark';
  const next = !current;
  localStorage.setItem('admin_dark_mode', next ? '1' : '0');
  applyDarkMode(next);
}

// ===== Notifications (Low Stock) =====
async function loadLowStockAlert() {
  try {
    const data = await api('/admin/low-stock');
    const products = data.products || [];
    const badge = document.getElementById('notifBadge');
    const list = document.getElementById('notifList');
    if (products.length > 0) {
      badge.textContent = products.length;
      badge.style.display = 'flex';
      list.innerHTML = products.length === 0
        ? '<div class="notification-item"><span class="notification-item-name">لا توجد تنبيهات</span></div>'
        : products.map((p) => `
          <div class="notification-item">
            <span class="notification-item-name">${escapeHtml(p.nameAr)}</span>
            <span class="notification-item-stock">متبقي: ${p.stock}</span>
          </div>
        `).join('');
    } else {
      badge.style.display = 'none';
      list.innerHTML = '<div class="notification-item"><span class="notification-item-name">لا توجد منتجات قاربت على النفاد</span></div>';
    }
  } catch (err) {
    // لو السيرفر مش شغال أو الtoken منتهي، نتجاهل
    document.getElementById('notifBadge').style.display = 'none';
  }
}

function toggleNotifications() {
  document.getElementById('notifDropdown').classList.toggle('show');
}

// نقفل الـ dropdown لو المستخدم ضغط بره
document.addEventListener('click', (e) => {
  if (!e.target.closest('#notifBtn') && !e.target.closest('#notifDropdown')) {
    document.getElementById('notifDropdown').classList.remove('show');
  }
});

// ===== Auth =====
async function login() {
  const phone = document.getElementById('loginPhone').value.trim();
  const password = document.getElementById('loginPassword').value;

  try {
    const data = await api('/auth/login', 'POST', { email: phone, password });
    if (data.user.role !== 'admin') {
      document.getElementById('loginError').textContent = 'صلاحيات الأدمن مطلوبة';
      return;
    }
    token = data.token;
    localStorage.setItem('admin_token', token);
    localStorage.setItem('admin_name', data.user.name);

    showApp();
  } catch (err) {
    document.getElementById('loginError').textContent = err.message;
  }
}

function logout() {
  if (!confirm('هل تريد تسجيل الخروج؟')) return;
  token = null;
  localStorage.removeItem('admin_token');
  localStorage.removeItem('admin_name');
  location.reload();
}

function showApp() {
  document.getElementById('loginScreen').classList.add('hidden');
  document.getElementById('app').classList.remove('hidden');
  document.getElementById('adminName').textContent = localStorage.getItem('admin_name') || 'Admin';
  showSection('dashboard');
  // نحمّل تنبيهات المخزون بعد تسجيل الدخول
  loadLowStockAlert();
}

function checkAuth() {
  if (!token) {
    document.getElementById('loginScreen').classList.remove('hidden');
    return false;
  }
  // نتأكد إن الـ token لسه صالح قبل ما نعرض الـ app
  fetch(`${API}/admin/stats`, {
    headers: { 'Authorization': `Bearer ${token}` },
  }).then(res => {
    if (res.ok) {
      showApp();
    } else {
      // token منتهي أو غلط — نظّفه واعرض شاشة الدخول
      localStorage.removeItem('admin_token');
      localStorage.removeItem('admin_name');
      token = null;
      document.getElementById('loginScreen').classList.remove('hidden');
      document.getElementById('loginError').textContent = 'الجلسة منتهية، سجّل دخول تاني';
    }
  }).catch(() => {
    // السيرفر مش شغال — نظّف ونعرض الدخول
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_name');
    token = null;
    document.getElementById('loginScreen').classList.remove('hidden');
  });
  return true;
}

// ===== Sections =====
const SECTIONS = {
  dashboard: 'الرئيسية',
  products: 'المنتجات',
  categories: 'الأقسام',
  orders: 'الطلبات',
  coupons: 'الكوبونات',
  banners: 'الإعلانات',
  users: 'المستخدمين',
  analytics: 'التحليلات',
  chats: 'محادثات المساعد',
  appUsage: 'الاستخدام والمنتجات',
  settings: 'الإعدادات',
};

// Chart instances (عشان نقدر نمسحهم قبل إعادة الرسم)
let salesChartInstance = null;
let categoriesChartInstance = null;
let appOpensChartInstance = null;

// ===== Sidebar (تابلت) =====
function toggleSidebar() {
  const sidebar = document.getElementById('sidebar');
  const overlay = document.getElementById('sidebarOverlay');
  if (!sidebar || !overlay) return;
  const isOpen = sidebar.classList.toggle('open');
  overlay.classList.toggle('open', isOpen);
}
function closeSidebar() {
  const sidebar = document.getElementById('sidebar');
  const overlay = document.getElementById('sidebarOverlay');
  if (sidebar) sidebar.classList.remove('open');
  if (overlay) overlay.classList.remove('open');
}

function showSection(name) {
  document.querySelectorAll('.content-section').forEach((s) => s.classList.remove('active'));
  document.querySelectorAll('.nav-btn').forEach((b) => b.classList.remove('active'));

  document.getElementById(name).classList.add('active');
  document.getElementById('pageTitle').textContent = SECTIONS[name] || '';

  // تفعيل الزر بالـ onclick match (أدق من text matching)
  document.querySelectorAll('.nav-btn').forEach((b) => {
    if (b.getAttribute('onclick') === `showSection('${name}')`) b.classList.add('active');
  });

  // تحميل البيانات لكل قسم
  if (name === 'dashboard') loadStats();
  if (name === 'products') loadProducts();
  if (name === 'categories') loadCategories();
  if (name === 'orders') loadOrders();
  if (name === 'coupons') loadCoupons();
  if (name === 'banners') loadBanners();
  if (name === 'users') loadUsers();
  if (name === 'analytics') loadAnalytics('daily');
  if (name === 'chats') loadChats();
  if (name === 'appUsage') loadAppUsage('daily');
  if (name === 'settings') loadSettings();

  // نقفل الـ sidebar على التابلت بعد اختيار قسم
  closeSidebar();
}

// ===== Dashboard =====
async function loadStats() {
  try {
    const data = await api('/admin/stats');
    const sP = document.getElementById('statProducts');
    const sO = document.getElementById('statOrders');
    const sR = document.getElementById('statRevenue');
    const sU = document.getElementById('statUsers');
    if (sR) sR.dataset.money = '1';
    countUp(sP, data.productsCount || 0);
    countUp(sO, data.ordersCount || 0);
    countUp(sR, data.totalRevenue || 0);
    countUp(sU, data.usersCount || 0);

    // أحدث الطلبات
    const recentEl = document.getElementById('recentOrders');
    if (data.recentOrders && data.recentOrders.length) {
      recentEl.innerHTML = data.recentOrders.map((o) => `
        <div class="recent-item">
          <div class="recent-item-info">
            <div class="recent-item-title">#${shortId(o._id)} - ${escapeHtml(o.customerName || 'عميل')}</div>
            <div class="recent-item-sub">${formatDate(o.createdAt)}</div>
          </div>
          <div class="recent-item-value">${formatPrice(o.total)} ج</div>
        </div>
      `).join('');
    } else {
      recentEl.innerHTML = '<div style="text-align:center;color:#888;padding:20px">لا توجد طلبات</div>';
    }

    // الأكثر مبيعاً
    const topEl = document.getElementById('topProducts');
    if (data.topProducts && data.topProducts.length) {
      topEl.innerHTML = data.topProducts.map((p) => `
        <div class="recent-item">
          <div class="recent-item-info">
            <div class="recent-item-title">${p.name}</div>
            <div class="recent-item-sub">مبيع: ${p.totalSold} قطعة</div>
          </div>
          <div class="recent-item-value">${formatPrice(p.revenue)} ج</div>
        </div>
      `).join('');
    } else {
      topEl.innerHTML = '<div style="text-align:center;color:#888;padding:20px">لا توجد بيانات</div>';
    }
  } catch (err) {
    showToast('فشل تحميل الإحصائيات', 'error');
  }
}

// ===== Products =====
let lastLoadedProducts = [];
async function loadProducts() {
  const tbody = document.getElementById('productsTable');
  const search = document.getElementById('productSearch').value;
  renderLoading(tbody, 6);
  try {
    let url = '/products';
    if (search) url += `?search=${encodeURIComponent(search)}`;
    const data = await api(url);
    const products = data.products || [];
    lastLoadedProducts = products;

    // تحميل الأقسام للـ dropdown
    if (categoriesCache.length === 0) {
      const cats = await api('/categories');
      categoriesCache = cats.categories || [];
    }

    if (products.length === 0) {
      renderEmpty(tbody, { emoji: '📦', title: 'لا توجد منتجات', desc: search ? 'جرّب كلمة بحث أخرى' : 'أضف أول منتج ليتحول هنا', retry: 'loadProducts()' });
      return;
    }

    tbody.innerHTML = products.map((p) => {
      const cat = categoriesCache.find((c) => c._id === (p.categoryId && p.categoryId._id ? p.categoryId._id : p.categoryId));
      const imgSrc = p.images && p.images[0] ? escapeHtml(p.images[0]) : '';
      const thumb = imgSrc
        ? `<img src="${imgSrc}" class="product-thumb">`
        : `<div class="product-thumb-placeholder">${escapeHtml((cat && cat.icon) || '📦')}</div>`;

      return `
        <tr>
          <td>${thumb}</td>
          <td>${escapeHtml(p.nameAr || '')}<br><small style="color:#888">${escapeHtml(p.nameEn || '')}</small></td>
          <td>${cat ? escapeHtml(cat.nameAr) : '-'}</td>
          <td>${formatPrice(p.effectivePrice || p.price)} ${p.discountPrice ? `<small style="text-decoration:line-through;color:#888"> ${formatPrice(p.price)}</small>` : ''}</td>
          <td>${p.stock}${p.stock === 0 ? ' <span class="badge badge-red">نفذ</span>' : ''}</td>
          <td>${p.isFeatured ? '<span class="badge badge-orange">مميز</span>' : '-'}</td>
          <td>
            <div class="action-btns">
  <button class="action-btn btn-view" onclick="addProductToCategory('${c._id}')">➕ منتج</button>
  <button class="action-btn btn-edit" onclick="editCategory('${c._id}')">تعديل</button>
  <button class="action-btn btn-delete" onclick="deleteCategory('${c._id}')">حذف</button>
</div>
          </td>
        </tr>
      `;
    }).join('');
  } catch (err) {
    showToast('فشل تحميل المنتجات', 'error');
  }
}

function openProductModal() {
  // تحميل الأقسام في dropdown
  const select = document.getElementById('pCategory');
  select.innerHTML = categoriesCache.map((c) => `<option value="${c._id}">${c.nameAr}</option>`).join('');
  document.getElementById('productForm').reset();
  document.getElementById('productId').value = '';
  document.getElementById('productModalTitle').textContent = 'إضافة منتج جديد';
  document.getElementById('currentImages').innerHTML = '';
  showModal('productModal');
}

async function editProduct(id) {
  try {
    const data = await api(`/products/${id}`);
    const p = data.product;

    const select = document.getElementById('pCategory');
    if (categoriesCache.length === 0) {
      const cats = await api('/categories');
      categoriesCache = cats.categories || [];
    }
    select.innerHTML = categoriesCache.map((c) =>
      `<option value="${c._id}" ${c._id === (p.categoryId && p.categoryId._id ? p.categoryId._id : p.categoryId) ? 'selected' : ''}>${c.nameAr}</option>`
    ).join('');

    document.getElementById('productId').value = p._id;
    document.getElementById('pNameAr').value = p.nameAr;
    document.getElementById('pNameEn').value = p.nameEn;
    document.getElementById('pPrice').value = p.price;
    document.getElementById('pDiscountPrice').value = p.discountPrice || '';
    document.getElementById('pStock').value = p.stock;
    document.getElementById('pUnit').value = p.unit;
    document.getElementById('pRating').value = p.rating;
    document.getElementById('pColor').value = p.color || '#1565C0';
    document.getElementById('pIcon').value = p.icon || 'inventory_2';
    document.getElementById('pDescription').value = p.description || '';
    document.getElementById('pFeatured').checked = p.isFeatured;
    document.getElementById('pSpecs').value = p.specifications ? JSON.stringify(p.specifications) : '';

    // عرض الصور الحالية
    if (p.images && p.images.length) {
      document.getElementById('currentImages').innerHTML = p.images.map((img) =>
        `<img src="${img.startsWith('http') ? img : img}">`
      ).join('');
    }

    document.getElementById('productModalTitle').textContent = 'تعديل المنتج';
    showModal('productModal');
  } catch (err) {
    showToast('فشل تحميل المنتج', 'error');
  }
}

async function saveProduct(event) {
  event.preventDefault();
  const id = document.getElementById('productId').value;
  const formData = new FormData();

  formData.append('categoryId', document.getElementById('pCategory').value);
  formData.append('nameAr', document.getElementById('pNameAr').value);
  formData.append('nameEn', document.getElementById('pNameEn').value);
  formData.append('description', document.getElementById('pDescription').value);
  formData.append('price', document.getElementById('pPrice').value);
  const dp = document.getElementById('pDiscountPrice').value;
  if (dp) formData.append('discountPrice', dp);
  formData.append('stock', document.getElementById('pStock').value);
  formData.append('unit', document.getElementById('pUnit').value);
  formData.append('rating', document.getElementById('pRating').value);
  formData.append('color', document.getElementById('pColor').value);
  formData.append('icon', document.getElementById('pIcon').value);
  formData.append('specifications', document.getElementById('pSpecs').value);
  formData.append('isFeatured', document.getElementById('pFeatured').checked);

  const files = document.getElementById('pImages').files;
  for (let i = 0; i < files.length; i++) {
    formData.append('images', files[i]);
  }

  try {
    const headers = {};
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const res = await fetch(`${API}/products${id ? `/${id}` : ''}`, {
      method: id ? 'PUT' : 'POST',
      headers,
      body: formData,
    });

    const data = await res.json();
    if (!res.ok) throw new Error(data.message);

    closeModal('productModal');
    showToast(id ? 'تم تحديث المنتج' : 'تم إضافة المنتج');
    loadProducts();
  } catch (err) {
    showToast(err.message, 'error');
  }
}

async function deleteProduct(id) {
  if (!confirm('هل تريد حذف هذا المنتج؟')) return;
  try {
    await api(`/products/${id}`, 'DELETE');
    showToast('تم حذف المنتج');
    loadProducts();
  } catch (err) {
    showToast(err.message, 'error');
  }
}

async function addProductToCategory(categoryId) {
  // تحميل الأقسام لو مش موجودين في الكاش
  if (categoriesCache.length === 0) {
    const cats = await api('/categories');
    categoriesCache = cats.categories || [];
  }

  // reset الفورم أولاً
  document.getElementById('productForm').reset();
  document.getElementById('productId').value = '';
  document.getElementById('productModalTitle').textContent = 'إضافة منتج جديد';
  document.getElementById('currentImages').innerHTML = '';

  // نبني الـ dropdown ونحدد القسم مباشرة
  const select = document.getElementById('pCategory');
  select.innerHTML = categoriesCache.map((c) =>
    `<option value="${c._id}" ${c._id === categoryId ? 'selected' : ''}>${c.nameAr}</option>`
  ).join('');
  select.value = categoryId;

  showModal('productModal');
}
// ===== Categories =====

// قائمة أيقونات Material مناسبة لمتجر سباكة وحدايد وبويات
const CATEGORY_ICONS = [
  'category', 'water_drop', 'plumbing', 'flash_on', 'electric_bolt', 'electrical_services',
  'lightbulb', 'handyman', 'build', 'construction', 'hardware', 'home_repair_service',
  'precision_manufacturing', 'format_paint', 'brush', 'inventory_2', 'settings', 'more_horiz',
  'cleaning_services', 'ac_unit', 'thermostat', 'door_front', 'window', 'keys',
  'chair', 'grass', 'agriculture', 'roofing', 'straighten', 'forest',
];

// يرسم شبكة الأيقونات القابلة للاختيار ويحدد المختار حالياً
function renderCategoryIconPicker(selected) {
  const wrap = document.getElementById('categoryIconPicker');
  if (!wrap) return;
  wrap.innerHTML = CATEGORY_ICONS.map((name) => `
    <button type="button" class="icon-chip ${name === selected ? 'selected' : ''}"
            onclick="selectCategoryIcon('${name}')" title="${name}">
      <span class="material-icons-round">${name}</span>
    </button>
  `).join('');
}

// اختيار أيقونة من القائمة
function selectCategoryIcon(name) {
  document.getElementById('cIcon').value = name;
  renderCategoryIconPicker(name);
}

// عرض صورة الأيقونة (المرفوعة أو الحالية) داخل منطقة المعاينة
function renderCategoryIconPreview(src) {
  const box = document.getElementById('currentCategoryIcon');
  if (!box) return;
  if (src) {
    box.innerHTML = `
      <div class="cat-icon-preview">
        <img src="${src}" alt="أيقونة القسم">
        <button type="button" class="cat-icon-remove" onclick="removeCategoryIconImage()" title="حذف الصورة">✕</button>
      </div>
    `;
  } else {
    box.innerHTML = '';
  }
}

// عند اختيار ملف صورة جديد من الجهاز
function onCategoryIconImageChange(input) {
  const file = input.files && input.files[0];
  if (!file) return;
  // معاينة محلية فورية
  const reader = new FileReader();
  reader.onload = (e) => renderCategoryIconPreview(e.target.result);
  reader.readAsDataURL(file);
  // لما نرفع صورة جديدة، نلغي أي طلب حذف سابق
  document.getElementById('cRemoveIconImage').value = '0';
}

// حذف صورة الأيقونة (الموجودة حالياً) — نرفع علم الحذف ونفضي المعاينة
function removeCategoryIconImage() {
  document.getElementById('cIconImage').value = '';
  document.getElementById('cRemoveIconImage').value = '1';
  renderCategoryIconPreview('');
}

async function loadCategories() {
  try {
    const data = await api('/categories');
    const cats = data.categories || [];
    if (cats.length) categoriesCache = cats;

    const grid = document.getElementById('categoriesGrid');
    if (cats.length === 0) {
      grid.innerHTML = '<div style="text-align:center;padding:40px;color:#888">لا توجد أقسام</div>';
      return;
    }

    grid.innerHTML = cats.map((c) => `
      <div class="category-card">
        <div class="category-head">
          <div class="category-icon-wrap" style="background:${escapeHtml(c.color)}20;color:${escapeHtml(c.color)}">
            ${c.imageUrl
              ? `<img src="${escapeHtml(c.imageUrl)}" class="category-icon-img" alt="${escapeHtml(c.nameAr || '')}">`
              : `<span>${escapeHtml(c.icon || 'category')}</span>`}
          </div>
          <div class="category-titles">
            <h4>${escapeHtml(c.nameAr || '')}</h4>
            ${c.nameEn ? `<span class="category-name-en">${escapeHtml(c.nameEn)}</span>` : ''}
          </div>
        </div>
        ${c.description ? `<p class="category-desc">${escapeHtml(c.description)}</p>` : '<p class="category-desc empty">— لا يوجد وصف</p>'}
        <div class="action-btns">
          <button class="action-btn btn-edit" onclick="editCategory('${c._id}')">تعديل</button>
          <button class="action-btn btn-delete" onclick="deleteCategory('${c._id}')">حذف</button>
        </div>
      </div>
    `).join('');
  } catch (err) {
    showToast('فشل تحميل الأقسام', 'error');
  }
}

function openCategoryModal() {
  document.getElementById('categoryForm').reset();
  document.getElementById('categoryId').value = '';
  document.getElementById('cIcon').value = 'category';
  document.getElementById('cRemoveIconImage').value = '0';
  document.getElementById('cColor').value = '#1565C0';
  renderCategoryIconPicker('category');
  renderCategoryIconPreview('');
  document.getElementById('categoryModalTitle').textContent = 'إضافة قسم جديد';
  showModal('categoryModal');
}

async function editCategory(id) {
  try {
    const data = await api(`/categories/${id}`);
    const c = data.category;
    document.getElementById('categoryId').value = c._id;
    document.getElementById('cNameAr').value = c.nameAr;
    document.getElementById('cNameEn').value = c.nameEn;
    document.getElementById('cIcon').value = c.icon || 'category';
    document.getElementById('cColor').value = c.color;
    document.getElementById('cDescription').value = c.description || '';
    document.getElementById('cOrder').value = c.order || 0;
    document.getElementById('cRemoveIconImage').value = '0';
    document.getElementById('cIconImage').value = '';
    renderCategoryIconPicker(c.icon || 'category');
    renderCategoryIconPreview(c.imageUrl || '');
    document.getElementById('categoryModalTitle').textContent = 'تعديل القسم';
    showModal('categoryModal');
  } catch (err) {
    showToast(err.message, 'error');
  }
}

async function saveCategory(event) {
  event.preventDefault();
  const id = document.getElementById('categoryId').value;
  const fileInput = document.getElementById('cIconImage');
  const hasNewImage = fileInput.files && fileInput.files.length > 0;
  const removeImage = document.getElementById('cRemoveIconImage').value === '1';

  const nameAr = document.getElementById('cNameAr').value;
  const nameEn = document.getElementById('cNameEn').value;
  const icon = document.getElementById('cIcon').value;
  const color = document.getElementById('cColor').value;
  const description = document.getElementById('cDescription').value;
  const order = parseInt(document.getElementById('cOrder').value) || 0;

  try {
    // لو فيه صورة مرفوعة أو طلب حذف → نرسل FormData (multipart)
    if (hasNewImage || removeImage) {
      const formData = new FormData();
      formData.append('folder', 'categories');
      formData.append('nameAr', nameAr);
      formData.append('nameEn', nameEn);
      formData.append('icon', icon);
      formData.append('color', color);
      formData.append('description', description);
      formData.append('order', order);
      if (hasNewImage) {
        formData.append('iconImage', fileInput.files[0]);
      }
      if (removeImage) {
        formData.append('imageUrl', ''); // الباك إند يحوّلها لـ null (مسح الصورة)
      }
      await api(`/categories${id ? `/${id}` : ''}`, id ? 'PUT' : 'POST', formData, true);
    } else {
      // ما فيهش صورة → JSON عادي
      const body = { nameAr, nameEn, icon, color, description, order };
      await api(`/categories${id ? `/${id}` : ''}`, id ? 'PUT' : 'POST', body);
    }

    closeModal('categoryModal');
    showToast(id ? 'تم تحديث القسم' : 'تم إضافة القسم');
    loadCategories();
  } catch (err) {
    showToast(err.message, 'error');
  }
}

async function deleteCategory(id) {
  if (!confirm('هل تريد حذف هذا القسم؟')) return;
  try {
    await api(`/categories/${id}`, 'DELETE');
    showToast('تم حذف القسم');
    loadCategories();
  } catch (err) {
    showToast(err.message, 'error');
  }
}

// ===== Orders =====
let lastLoadedOrders = [];
async function loadOrders() {
  const tbody = document.getElementById('ordersTable');
  const filter = document.getElementById('orderFilter').value;
  renderLoading(tbody, 6);
  try {
    let url = '/admin/orders';
    if (filter) url += `?status=${filter}`;
    const data = await api(url);
    const orders = data.orders || [];
    lastLoadedOrders = orders;

    if (orders.length === 0) {
      renderEmpty(tbody, { emoji: '🛒', title: 'لا توجد طلبات', desc: filter ? 'لا طلبات بهذه الحالة' : 'ستظهر الطلبات هنا عند إنشائها', retry: 'loadOrders()' });
      return;
    }

    tbody.innerHTML = orders.map((o) => {
      const s = STATUS_LABELS[o.status] || STATUS_LABELS.pending;
      const pm = paymentLabel(o.paymentMethod);
      const phone = o.customerPhone || (o.userId && o.userId.phone) || '';
      const customerName = o.customerName || (o.userId && o.userId.name) || '-';
      return `
        <tr>
          <td>#${shortId(o._id)}</td>
          <td>${escapeHtml(customerName)}</td>
          <td dir="ltr">${escapeHtml(phone || '-')}</td>
          <td>${formatPrice(o.total)} ج</td>
          <td><span class="badge ${pm.class}">${pm.label}</span></td>
          <td><span class="badge ${s.class}">${s.label}</span></td>
          <td>${formatDate(o.createdAt)}</td>
          <td>
            <div class="action-btns">
              <button class="action-btn btn-view" onclick="viewOrder('${o._id}')">عرض</button>
              ${phone ? `<button class="action-btn btn-success" title="واتساب العميل" onclick="openWhatsApp('${escapeHtml(phone)}')">💬</button>` : ''}
            </div>
          </td>
        </tr>
      `;
    }).join('');
  } catch (err) {
    showToast('فشل تحميل الطلبات', 'error');
  }
}

async function viewOrder(id) {
  try {
    const data = await api(`/admin/orders/${id}`);
    const order = data.order;
    if (!order) { showToast('الطلب غير موجود', 'error'); return; }

    const s = STATUS_LABELS[order.status] || STATUS_LABELS.pending;
    const pm = paymentLabel(order.paymentMethod);
    const phone = order.customerPhone || (order.userId && order.userId.phone) || '';
    const itemsHtml = order.items.map((item) => `
      <div style="display:flex;justify-content:space-between;padding:10px;background:#F2F3F7;border-radius:8px;margin-bottom:6px">
        <div>
          <strong>${item.name}</strong> × ${item.quantity}
          <div style="color:#888;font-size:12px">${formatPrice(item.price)} ج × ${item.quantity} = ${formatPrice(item.price * item.quantity)} ج</div>
        </div>
      </div>
    `).join('');

    document.getElementById('orderDetails').innerHTML = `
      <div style="padding:20px">
        <div style="margin-bottom:16px;display:flex;justify-content:space-between;align-items:center">
          <div>
            <strong>الطلب #${shortId(order._id)}</strong>
            <span class="badge ${s.class}" style="margin-right:10px">${s.label}</span>
            <span class="badge ${pm.class}" style="margin-right:10px">${pm.label}</span>
          </div>
          <button class="btn-info" onclick="printInvoice('${order._id}')">🖨️ طباعة فاتورة</button>
        </div>
        <div class="order-info-grid">
          <div class="order-info-item">
            <div class="order-info-label">العميل</div>
            <div class="order-info-value">${escapeHtml(order.customerName || '-')}</div>
          </div>
          <div class="order-info-item">
            <div class="order-info-label">الهاتف</div>
            <div class="order-info-value" dir="ltr">${escapeHtml(order.customerPhone || '-')}</div>
          </div>
          <div class="order-info-item">
            <div class="order-info-label">التاريخ</div>
            <div class="order-info-value">${formatDate(order.createdAt)}</div>
          </div>
          <div class="order-info-item">
            <div class="order-info-label">العنوان</div>
            <div class="order-info-value">${escapeHtml(order.address || '-')}</div>
          </div>
          <div class="order-info-item">
            <div class="order-info-label">طريقة الدفع</div>
            <div class="order-info-value"><span class="badge ${pm.class}">${pm.label}</span></div>
          </div>
        </div>
        ${phone ? `
        <div style="margin:16px 0;display:flex;gap:10px">
          <button class="btn-success" onclick="openWhatsApp('${escapeHtml(phone)}', 'مرحباً، بخصوص طلبك #${shortId(order._id)} من متجر MARCELINO')">💬 واتساب العميل</button>
          <button class="btn-info" onclick="openTel('${escapeHtml(phone)}')">📞 اتصال</button>
        </div>` : ''}
        <h4 style="margin:20px 0 10px">المنتجات</h4>
        ${itemsHtml}
        <div style="margin-top:16px;padding:12px;background:#F2F3F7;border-radius:10px">
          <div style="display:flex;justify-content:space-between;margin-bottom:4px"><span>المجموع:</span><strong>${formatPrice(order.subtotal)} ج</strong></div>
          <div style="display:flex;justify-content:space-between;margin-bottom:4px"><span>الشحن:</span><strong>${formatPrice(order.shipping)} ج</strong></div>
          ${order.discount ? '<div style="display:flex;justify-content:space-between;margin-bottom:4px"><span>الخصم' + (order.couponCode ? ' (' + escapeHtml(order.couponCode) + ')' : '') + ':</span><strong style="color:#2E7D32">- ' + formatPrice(order.discount) + ' ج</strong></div>' : ''}
          <div style="display:flex;justify-content:space-between;padding-top:8px;border-top:1px solid #ddd"><span>الإجمالي:</span><strong style="color:#FF6B00;font-size:18px">${formatPrice(order.total)} ج</strong></div>
        </div>
        ${order.paymentMethod && order.paymentMethod !== 'cod' && (order.proofFromNumber || order.proofImage) ? `
        <h4 style="margin:20px 0 10px">إثبات التحويل 🧾</h4>
        <div style="margin-top:8px;padding:14px;background:#FFF8E1;border:1px solid #FFE082;border-radius:10px">
          <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-bottom:10px">
            <div><strong style="color:#5D4037">رقم اللي حوّل منه:</strong><br><span dir="ltr">${escapeHtml(order.proofFromNumber || '-')}</span></div>
            <div><strong style="color:#5D4037">الاسم:</strong><br>${escapeHtml(order.proofFromName || '-')}</div>
            <div><strong style="color:#5D4037">التاريخ:</strong><br>${escapeHtml(order.proofDate || '-')}</div>
          </div>
          ${order.proofImage ? `
          <div style="text-align:center">
            <a href="${escapeHtml(order.proofImage)}" target="_blank" title="افتح بحجم كامل">
              <img src="${escapeHtml(order.proofImage)}" alt="إثبات التحويل" style="max-width:100%;max-height:320px;border-radius:10px;border:1px solid #ddd;cursor:zoom-in" onerror="this.style.display='none'">
            </a>
            <div style="margin-top:6px">
              <a href="${escapeHtml(order.proofImage)}" download class="btn-info" style="font-size:12px;padding:6px 14px;text-decoration:none;color:#fff;display:inline-block;border-radius:6px">⬇ تنزيل الصورة</a>
            </div>
          </div>` : '<div style="text-align:center;color:#888;padding:10px">لا توجد صورة مرفوعة</div>'}
        </div>
        ` : ''}
        <h4 style="margin:20px 0 10px">تغيير الحالة</h4>
        <select class="status-select" onchange="updateOrderStatus('${order._id}', this.value)">
          <option value="pending" ${order.status === 'pending' ? 'selected' : ''}>قيد المراجعة</option>
          <option value="processing" ${order.status === 'processing' ? 'selected' : ''}>جاري التجهيز</option>
          <option value="delivered" ${order.status === 'delivered' ? 'selected' : ''}>تم التوصيل</option>
          <option value="cancelled" ${order.status === 'cancelled' ? 'selected' : ''}>ملغي</option>
        </select>
      </div>
    `;
    showModal('orderModal');
  } catch (err) {
    showToast(err.message, 'error');
  }
}

async function updateOrderStatus(id, status) {
  try {
    await api(`/admin/orders/${id}/status`, 'PUT', { status });
    showToast('تم تحديث حالة الطلب');
    loadOrders();
  } catch (err) {
    showToast(err.message, 'error');
  }
}

// ===== Coupons =====
async function loadCoupons() {
  try {
    const data = await api('/coupons?all=true');
    const coupons = data.coupons || [];

    const grid = document.getElementById('couponsGrid');
    if (coupons.length === 0) {
      grid.innerHTML = '<div style="text-align:center;padding:40px;color:#888">لا توجد كوبونات</div>';
      return;
    }

    grid.innerHTML = coupons.map((c) => {
      const expired = new Date(c.expiresAt) < new Date();
      return `
        <div class="coupon-card">
          <div class="coupon-code">${escapeHtml(c.code || '')}</div>
          <h4>${c.type === 'percent' ? c.discount + '%' : c.type === 'fixed' ? c.discount + ' جنيه' : 'شحن مجاني'}</h4>
          <p>${escapeHtml(c.description || '')}</p>
          <p style="font-size:12px">ينتهي: ${formatDate(c.expiresAt)}</p>
          <p>
            ${expired ? '<span class="badge badge-gray">منتهي</span>' : c.isActive ? '<span class="badge badge-green">نشط</span>' : '<span class="badge badge-gray">متوقف</span>'}
          </p>
          <div class="action-btns">
            <button class="action-btn btn-edit" onclick="editCoupon('${c._id}')">تعديل</button>
            <button class="action-btn btn-delete" onclick="deleteCoupon('${c._id}')">حذف</button>
          </div>
        </div>
      `;
    }).join('');
  } catch (err) {
    showToast('فشل تحميل الكوبونات', 'error');
  }
}

function openCouponModal() {
  document.getElementById('couponForm').reset();
  document.getElementById('couponId').value = '';
  const nextWeek = new Date();
  nextWeek.setDate(nextWeek.getDate() + 30);
  document.getElementById('cuExpiresAt').value = nextWeek.toISOString().split('T')[0];
  document.getElementById('couponModalTitle').textContent = 'إضافة كوبون';
  showModal('couponModal');
}

async function editCoupon(id) {
  try {
    const data = await api(`/coupons/${id}`);
    const c = data.coupon;
    if (!c) { showToast('الكوبون غير موجود', 'error'); return; }
    document.getElementById('couponId').value = c._id;
    document.getElementById('cuCode').value = c.code;
    document.getElementById('cuDescription').value = c.description;
    document.getElementById('cuDiscount').value = c.discount;
    document.getElementById('cuType').value = c.type;
    document.getElementById('cuMinOrder').value = c.minOrder || 0;
    document.getElementById('cuExpiresAt').value = c.expiresAt.split('T')[0];
    document.getElementById('cuActive').checked = c.isActive;
    document.getElementById('couponModalTitle').textContent = 'تعديل الكوبون';
    showModal('couponModal');
  } catch (err) {
    showToast(err.message, 'error');
  }
}

async function saveCoupon(event) {
  event.preventDefault();
  const id = document.getElementById('couponId').value;
  const body = {
    code: document.getElementById('cuCode').value,
    description: document.getElementById('cuDescription').value,
    discount: parseFloat(document.getElementById('cuDiscount').value),
    type: document.getElementById('cuType').value,
    minOrder: parseFloat(document.getElementById('cuMinOrder').value) || 0,
    expiresAt: document.getElementById('cuExpiresAt').value,
    isActive: document.getElementById('cuActive').checked,
  };

  try {
    await api(`/coupons${id ? `/${id}` : ''}`, id ? 'PUT' : 'POST', body);
    closeModal('couponModal');
    showToast(id ? 'تم تحديث الكوبون' : 'تم إضافة الكوبون');
    loadCoupons();
  } catch (err) {
    showToast(err.message, 'error');
  }
}

async function deleteCoupon(id) {
  if (!confirm('هل تريد حذف هذا الكوبون؟')) return;
  try {
    await api(`/coupons/${id}`, 'DELETE');
    showToast('تم حذف الكوبون');
    loadCoupons();
  } catch (err) {
    showToast(err.message, 'error');
  }
}

// ===== Users =====
let usersCache = [];

async function loadUsers() {
  try {
    const data = await api('/admin/users');
    usersCache = data.users || [];
    const search = (document.getElementById('userSearch')?.value || '').toLowerCase().trim();
    let users = usersCache;
    if (search) {
      users = users.filter((u) =>
        (u.name || '').toLowerCase().includes(search) ||
        (u.email || '').toLowerCase().includes(search) ||
        (u.phone || '').toLowerCase().includes(search)
      );
    }
    const tbody = document.getElementById('usersTable');
    if (users.length === 0) {
      tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;padding:30px">لا يوجد مستخدمين</td></tr>';
      return;
    }
    tbody.innerHTML = users.map((u) => {
      const statusBadge = u.isActive === false
        ? '<span class="badge badge-blocked">محظور</span>'
        : '<span class="badge badge-active">نشط</span>';
      const blockBtn = u.isActive === false
        ? `<button class="action-btn btn-view" onclick="blockUser('${u._id}', true)">إلغاء الحظر</button>`
        : `<button class="action-btn btn-delete" onclick="blockUser('${u._id}', false)">حظر</button>`;
      return `
        <tr>
          <td>${escapeHtml(u.name)}</td>
          <td>${escapeHtml(u.email)}</td>
          <td dir="ltr">${escapeHtml(u.phone)}</td>
          <td>${statusBadge}</td>
          <td id="userOrders_${u._id}">-</td>
          <td>${formatDate(u.createdAt)}</td>
          <td>
            <div class="action-btns">
              <button class="action-btn btn-view" onclick="viewUser('${u._id}')">عرض</button>
              <button class="action-btn btn-edit" onclick="editUser('${u._id}')">تعديل</button>
              ${blockBtn}
              <button class="action-btn btn-delete" onclick="deleteUser('${u._id}')">حذف</button>
            </div>
          </td>
        </tr>`;
    }).join('');
    // نجيب عدد طلبات كل مستخدم (بشكل lazy)
    users.forEach(async (u) => {
      try {
        const ordersData = await api(`/admin/users/${u._id}`);
        const el = document.getElementById(`userOrders_${u._id}`);
        if (el) el.textContent = (ordersData.orders || []).length;
      } catch (_) {}
    });
  } catch (err) {
    showToast('فشل تحميل المستخدمين', 'error');
  }
}

async function viewUser(id) {
  try {
    const data = await api(`/admin/users/${id}`);
    const u = data.user;
    const orders = data.orders || [];
    const totalSpent = orders.reduce((s, o) => s + (o.total || 0), 0);
    const statusBadge = u.isActive === false
      ? '<span class="badge badge-blocked">محظور</span>'
      : '<span class="badge badge-active">نشط</span>';

    const ordersRows = orders.length === 0
      ? '<tr><td colspan="4" style="text-align:center;padding:16px">لا توجد طلبات</td></tr>'
      : orders.map((o) => {
          const s = STATUS_LABELS[o.status] || STATUS_LABELS.pending;
          return `
            <tr>
              <td>#${shortId(o._id)}</td>
              <td>${formatPrice(o.total)} ج</td>
              <td><span class="badge ${s.class}">${s.label}</span></td>
              <td>${formatDate(o.createdAt)}</td>
            </tr>`;
      }).join('');

    document.getElementById('userModalTitle').textContent = 'تفاصيل المستخدم';
    document.getElementById('userDetails').innerHTML = `
      <div style="padding:20px">
        <div class="user-stats-grid">
          <div class="user-stat-card"><div class="num">${orders.length}</div><div class="label">إجمالي الطلبات</div></div>
          <div class="user-stat-card"><div class="num">${formatPrice(totalSpent)}</div><div class="label">إجمالي الإنفاق (ج)</div></div>
          <div class="user-stat-card"><div class="num">${u.isActive === false ? 'محظور' : 'نشط'}</div><div class="label">الحالة</div></div>
        </div>
        <div class="order-info-grid">
          <div class="order-info-item"><div class="order-info-label">الاسم</div><div class="order-info-value">${escapeHtml(u.name)}</div></div>
          <div class="order-info-item"><div class="order-info-label">البريد</div><div class="order-info-value">${escapeHtml(u.email)}</div></div>
          <div class="order-info-item"><div class="order-info-label">الهاتف</div><div class="order-info-value" dir="ltr">${escapeHtml(u.phone)}</div></div>
          <div class="order-info-item"><div class="order-info-label">الحالة</div><div class="order-info-value">${statusBadge}</div></div>
        </div>
        ${u.phone ? `
        <div style="margin:16px 0;display:flex;gap:10px">
          <button class="btn-success" onclick="openWhatsApp('${escapeHtml(u.phone)}', 'مرحباً ${escapeHtml(u.name)} من متجر MARCELINO')">💬 واتساب</button>
          <button class="btn-info" onclick="openTel('${escapeHtml(u.phone)}')">📞 اتصال</button>
        </div>` : ''}
        <h4 style="margin:20px 0 10px">طلبات المستخدم</h4>
        <table class="data-table">
          <thead><tr><th>رقم الطلب</th><th>المبلغ</th><th>الحالة</th><th>التاريخ</th></tr></thead>
          <tbody>${ordersRows}</tbody>
        </table>
      </div>
    `;
    showModal('userModal');
  } catch (err) {
    showToast(err.message || 'فشل تحميل المستخدم', 'error');
  }
}

async function editUser(id) {
  const u = usersCache.find((x) => x._id === id);
  if (!u) return;
  document.getElementById('userModalTitle').textContent = 'تعديل المستخدم';
  document.getElementById('userDetails').innerHTML = `
    <div style="padding:20px">
      <div class="form-grid">
        <div class="form-group"><label>الاسم</label><input type="text" id="editUserName" value="${escapeHtml(u.name)}"></div>
        <div class="form-group"><label>الهاتف</label><input type="text" id="editUserPhone" value="${escapeHtml(u.phone)}"></div>
        <div class="form-group"><label>البريد الإلكتروني</label><input type="email" id="editUserEmail" value="${escapeHtml(u.email)}"></div>
        <div class="form-group">
          <label>الصلاحية</label>
          <select id="editUserRole">
            <option value="customer" ${u.role === 'customer' ? 'selected' : ''}>عميل</option>
            <option value="admin" ${u.role === 'admin' ? 'selected' : ''}>أدمن</option>
          </select>
        </div>
      </div>
      <div style="display:flex;gap:10px;justify-content:flex-end;margin-top:16px">
        <button class="btn-secondary" onclick="viewUser('${id}')">إلغاء</button>
        <button class="btn-primary" onclick="saveUser('${id}')">💾 حفظ</button>
      </div>
    </div>
  `;
  showModal('userModal');
}

async function saveUser(id) {
  try {
    const body = {
      name: document.getElementById('editUserName').value,
      phone: document.getElementById('editUserPhone').value,
      email: document.getElementById('editUserEmail').value,
      role: document.getElementById('editUserRole').value,
    };
    await api(`/admin/users/${id}`, 'PUT', body);
    showToast('تم تحديث المستخدم');
    closeModal('userModal');
    loadUsers();
  } catch (err) {
    showToast(err.message || 'فشل تحديث المستخدم', 'error');
  }
}

async function blockUser(id, isUnblock) {
  const action = isUnblock ? 'إلغاء حظر' : 'حظر';
  if (!confirm(`هل تريد ${action} هذا المستخدم؟`)) return;
  try {
    await api(`/admin/users/${id}/block`, 'PUT');
    showToast(`تم ${action} المستخدم`);
    loadUsers();
  } catch (err) {
    showToast(err.message || `فشل ${action} المستخدم`, 'error');
  }
}

async function deleteUser(id) {
  if (!confirm('هل أنت متأكد من حذف هذا المستخدم؟ لا يمكن التراجع.')) return;
  try {
    await api(`/admin/users/${id}`, 'DELETE');
    showToast('تم حذف المستخدم');
    loadUsers();
  } catch (err) {
    showToast(err.message || 'فشل حذف المستخدم', 'error');
  }
}

// ===== Banners =====
let productsCacheForBanners = [];

async function loadBanners() {
  try {
    const data = await api('/banners?all=1');
    const banners = data.banners || [];
    const tbody = document.getElementById('bannersTable');
    if (banners.length === 0) {
      tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;padding:30px">لا توجد إعلانات بعد. اضغط "إضافة إعلان" لإضافة أول إعلان.</td></tr>';
      return;
    }
    tbody.innerHTML = banners.map((b) => {
      const img = b.image
        ? `<img src="${b.image.startsWith('http') ? b.image : b.image}" class="product-thumb" style="width:80px;height:50px;object-fit:cover">`
        : '<div class="product-thumb-placeholder" style="width:80px;height:50px">لا صورة</div>';
      const productName = b.productId
        ? (typeof b.productId === 'object' ? (b.productId.nameAr || '—') : 'منتج محذوف')
        : '—';
      const statusBadge = b.isActive
        ? '<span class="badge badge-green">نشط</span>'
        : '<span class="badge badge-gray">معطل</span>';
      return `
        <tr>
          <td>${img}</td>
          <td>${b.title}${b.subtitle ? `<br><small style="color:#888">${b.subtitle}</small>` : ''}</td>
          <td>${productName}</td>
          <td>${b.order}</td>
          <td>${statusBadge}</td>
          <td>
            <div class="action-btns">
              <button class="action-btn btn-edit" onclick="editBanner('${b._id}')">تعديل</button>
              <button class="action-btn btn-delete" onclick="deleteBanner('${b._id}')">حذف</button>
            </div>
          </td>
        </tr>`;
    }).join('');
  } catch (err) {
    showToast('فشل تحميل الإعلانات', 'error');
  }
}

async function openBannerModal() {
  document.getElementById('bannerForm').reset();
  document.getElementById('bannerId').value = '';
  document.getElementById('bannerModalTitle').textContent = 'إضافة إعلان جديد';
  document.getElementById('currentBannerImage').innerHTML = '';
  document.getElementById('bActive').value = 'true';
  document.getElementById('bOrder').value = '0';

  // تحميل قائمة المنتجات في الـ dropdown
  await loadProductsForBannerDropdown();

  showModal('bannerModal');
}

async function loadProductsForBannerDropdown() {
  const select = document.getElementById('bProduct');
  try {
    if (productsCacheForBanners.length === 0) {
      const data = await api('/products?limit=100');
      productsCacheForBanners = data.products || [];
    }
    select.innerHTML = '<option value="">— بدون رابط لمنتج —</option>' +
      productsCacheForBanners.map((p) =>
        `<option value="${p._id}">${p.nameAr}</option>`
      ).join('');
  } catch (err) {
    select.innerHTML = '<option value="">— تعذّر تحميل المنتجات —</option>';
  }
}

async function editBanner(id) {
  try {
    const data = await api(`/banners/${id}`);
    const b = data.banner;
    if (!b) return;

    await loadProductsForBannerDropdown();

    document.getElementById('bannerId').value = b._id;
    document.getElementById('bTitle').value = b.title || '';
    document.getElementById('bSubtitle').value = b.subtitle || '';
    document.getElementById('bOrder').value = b.order || 0;
    document.getElementById('bActive').value = b.isActive ? 'true' : 'false';

    // اختيار المنتج المرتبط
    const select = document.getElementById('bProduct');
    const productId = b.productId ? (typeof b.productId === 'object' ? b.productId._id : b.productId) : '';
    select.value = productId;

    // عرض الصورة الحالية
    const curImg = document.getElementById('currentBannerImage');
    if (b.image) {
      curImg.innerHTML = `<img src="${b.image}" style="width:100%;max-width:300px;border-radius:8px">`;
    } else {
      curImg.innerHTML = '';
    }

    document.getElementById('bannerModalTitle').textContent = 'تعديل الإعلان';
    showModal('bannerModal');
  } catch (err) {
    showToast(err.message || 'فشل تحميل الإعلان', 'error');
  }
}

async function saveBanner(event) {
  event.preventDefault();
  const id = document.getElementById('bannerId').value;
  const formData = new FormData();

  formData.append('folder', 'banners');
  formData.append('title', document.getElementById('bTitle').value);
  formData.append('subtitle', document.getElementById('bSubtitle').value);
  formData.append('productId', document.getElementById('bProduct').value);
  formData.append('order', document.getElementById('bOrder').value);
  formData.append('isActive', document.getElementById('bActive').value);

  const fileInput = document.getElementById('bImage');
  if (fileInput.files.length > 0) {
    formData.append('image', fileInput.files[0]);
  }

  try {
    const headers = {};
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const res = await fetch(`${API}/banners${id ? `/${id}` : ''}`, {
      method: id ? 'PUT' : 'POST',
      headers,
      body: formData,
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.message || 'حدث خطأ');

    closeModal('bannerModal');
    showToast(id ? 'تم تحديث الإعلان' : 'تم إضافة الإعلان');
    loadBanners();
  } catch (err) {
    showToast(err.message || 'فشل حفظ الإعلان', 'error');
  }
}

async function deleteBanner(id) {
  if (!confirm('هل أنت متأكد من حذف هذا الإعلان؟')) return;
  try {
    await api(`/banners/${id}`, 'DELETE');
    showToast('تم حذف الإعلان');
    loadBanners();
  } catch (err) {
    showToast(err.message || 'فشل حذف الإعلان', 'error');
  }
}

// ===== Analytics =====
async function loadAnalytics(period = 'daily') {
  // تنشيط الزر الصح
  document.getElementById('periodDaily').classList.toggle('active', period === 'daily');
  if (document.getElementById('periodMonthly')) {
    document.getElementById('periodMonthly').classList.toggle('active', period === 'monthly');
  }

  try {
    // Sales chart
    const salesData = await api(`/admin/analytics/sales?period=${period}`);
    const sales = salesData.sales || [];
    const labels = sales.map((s) => s._id);
    const revenues = sales.map((s) => s.revenue);
    const ordersCounts = sales.map((s) => s.ordersCount);

    if (salesChartInstance) salesChartInstance.destroy();
    const ctxSales = document.getElementById('salesChart');
    if (ctxSales) {
      salesChartInstance = new Chart(ctxSales, {
        type: 'line',
        data: {
          labels,
          datasets: [
            {
              label: 'الإيرادات (ج)',
              data: revenues,
              borderColor: '#FF6B00',
              backgroundColor: 'rgba(255, 107, 0, 0.1)',
              fill: true,
              tension: 0.3,
              yAxisID: 'y',
            },
            {
              label: 'عدد الطلبات',
              data: ordersCounts,
              borderColor: '#0D1B3E',
              backgroundColor: 'rgba(13, 27, 62, 0.05)',
              tension: 0.3,
              yAxisID: 'y1',
            },
          ],
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: { legend: { labels: { font: { family: 'Cairo' } } } },
          scales: {
            y: { type: 'linear', position: 'right', title: { display: true, text: 'الإيرادات' } },
            y1: { type: 'linear', position: 'left', grid: { drawOnChartArea: false }, title: { display: true, text: 'عدد الطلبات' } },
          },
        },
      });
    }

    // Categories chart
    const catsData = await api('/admin/analytics/categories');
    const cats = catsData.categories || [];
    if (categoriesChartInstance) categoriesChartInstance.destroy();
    const ctxCats = document.getElementById('categoriesChart');
    if (ctxCats) {
      categoriesChartInstance = new Chart(ctxCats, {
        type: 'doughnut',
        data: {
          labels: cats.map((c) => c.name),
          datasets: [{
            data: cats.map((c) => c.totalSold),
            backgroundColor: ['#1565C0', '#FF6B00', '#2E7D32', '#6A1B9A', '#F57F17', '#00695C'],
          }],
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: { legend: { position: 'bottom', labels: { font: { family: 'Cairo' } } } },
        },
      });
    }
  } catch (err) {
    showToast('فشل تحميل التحليلات', 'error');
  }
}

// ===== Settings =====
async function loadSettings() {
  try {
    const data = await api('/settings');
    const s = data.settings;
    document.getElementById('setStoreName').value = s.storeName || '';
    document.getElementById('setCurrency').value = s.currency || 'ج.م';
    document.getElementById('setWelcome').value = s.welcomeMessage || '';
    document.getElementById('setShippingFee').value = s.shippingFee ?? 30;
    document.getElementById('setFreeShipping').value = s.freeShippingThreshold ?? 500;
    document.getElementById('setShippingNote').value = s.shippingNote || '';
    document.getElementById('setContactPhone').value = s.contactPhone || '';
    document.getElementById('setContactEmail').value = s.contactEmail || '';
    document.getElementById('setLowStock').value = s.lowStockThreshold ?? 5;
    // بيانات الدفع
    document.getElementById('setWhatsapp').value = s.whatsappNumber || '';
    document.getElementById('setEtisalatNumber').value = s.etisalatCashNumber || '';
    document.getElementById('setEtisalatName').value = s.etisalatCashName || '';
    document.getElementById('setInstapay').value = s.instapayHandle || '';
    document.getElementById('setBankName').value = s.bankName || '';
    document.getElementById('setBankAccountName').value = s.bankAccountName || '';
    document.getElementById('setBankAccountNumber').value = s.bankAccountNumber || '';
  } catch (err) {
    showToast('فشل تحميل الإعدادات', 'error');
  }
}

async function saveSettings() {
  try {
    const body = {
      storeName: document.getElementById('setStoreName').value.trim(),
      currency: document.getElementById('setCurrency').value.trim(),
      welcomeMessage: document.getElementById('setWelcome').value.trim(),
      shippingFee: parseFloat(document.getElementById('setShippingFee').value) || 0,
      freeShippingThreshold: parseFloat(document.getElementById('setFreeShipping').value) || 0,
      shippingNote: document.getElementById('setShippingNote').value.trim(),
      contactPhone: document.getElementById('setContactPhone').value.trim(),
      contactEmail: document.getElementById('setContactEmail').value.trim(),
      lowStockThreshold: parseInt(document.getElementById('setLowStock').value) || 5,
      // بيانات الدفع
      whatsappNumber: document.getElementById('setWhatsapp').value.trim(),
      etisalatCashNumber: document.getElementById('setEtisalatNumber').value.trim(),
      etisalatCashName: document.getElementById('setEtisalatName').value.trim(),
      instapayHandle: document.getElementById('setInstapay').value.trim(),
      bankName: document.getElementById('setBankName').value.trim(),
      bankAccountName: document.getElementById('setBankAccountName').value.trim(),
      bankAccountNumber: document.getElementById('setBankAccountNumber').value.trim(),
    };
    await api('/settings', 'PUT', body);
    showToast('تم حفظ الإعدادات بنجاح');
  } catch (err) {
    showToast(err.message || 'فشل حفظ الإعدادات', 'error');
  }
}

async function changeAdminPassword() {
  const current = document.getElementById('curAdminPassword').value;
  const newPass = document.getElementById('newAdminPassword').value;
  if (!current || !newPass) {
    showToast('املا الحقلين', 'error');
    return;
  }
  if (newPass.length < 6) {
    showToast('كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل', 'error');
    return;
  }
  try {
    await api('/auth/admin/change-password', 'PUT', {
      currentPassword: current,
      newPassword: newPass,
    });
    document.getElementById('curAdminPassword').value = '';
    document.getElementById('newAdminPassword').value = '';
    showToast('تم تغيير كلمة المرور بنجاح');
  } catch (err) {
    showToast(err.message || 'فشل تغيير كلمة المرور', 'error');
  }
}

// ===== Print Invoice =====
async function printInvoice(orderId) {
  try {
    const data = await api(`/admin/orders/${orderId}`);
    const order = data.order;
    if (!order) return;

    const itemsRows = (order.items || []).map((it, i) => `
      <tr>
        <td>${i + 1}</td>
        <td>${escapeHtml(it.name)}</td>
        <td>${formatPrice(it.price)}</td>
        <td>${it.quantity}</td>
        <td>${formatPrice(it.price * it.quantity)}</td>
      </tr>
    `).join('');

    const s = STATUS_LABELS[order.status] || STATUS_LABELS.pending;
    document.getElementById('invoiceContent').innerHTML = `
      <div class="invoice-preview">
        <div class="invoice-header">
          <div>
            <div class="invoice-logo">🏪 MARCELINO</div>
            <p style="color:#888;font-size:12px;margin-top:4px">متجر مستلزمات السباكة والحدايد والبويات</p>
          </div>
          <div class="invoice-meta">
            <h4>فاتورة رقم</h4>
            <p>#${shortId(order._id)}</p>
            <h4 style="margin-top:8px">التاريخ</h4>
            <p>${formatDate(order.createdAt)}</p>
          </div>
        </div>
        <div class="order-info-grid" style="margin-bottom:20px">
          <div><strong>العميل:</strong> ${escapeHtml(order.customerName || (order.userId && order.userId.name) || '-')}</div>
          <div><strong>الهاتف:</strong> <span dir="ltr">${escapeHtml(order.customerPhone || (order.userId && order.userId.phone) || '-')}</span></div>
          <div><strong>العنوان:</strong> ${escapeHtml(order.address || '-')}</div>
          <div><strong>الحالة:</strong> ${s.label}</div>
        </div>
        <table class="invoice-table">
          <thead>
            <tr><th>#</th><th>المنتج</th><th>السعر</th><th>الكمية</th><th>الإجمالي</th></tr>
          </thead>
          <tbody>${itemsRows}</tbody>
        </table>
        <div class="invoice-totals">
          <div class="total-row"><span>المجموع الفرعي:</span><span>${formatPrice(order.subtotal)} ج</span></div>
          <div class="total-row"><span>الشحن:</span><span>${formatPrice(order.shipping)} ج</span></div>
          <div class="total-row grand"><span>الإجمالي:</span><span>${formatPrice(order.total)} ج</span></div>
        </div>
        <p style="text-align:center;margin-top:30px;color:#888;font-size:12px">شكراً لتسوقكم من MARCELINO 🙏</p>
      </div>
    `;
    showModal('invoiceModal');
  } catch (err) {
    showToast(err.message || 'فشل تحميل الفاتورة', 'error');
  }
}

// ===== Export CSV =====
function exportCSV(type) {
  let headers = [];
  let rows = [];
  let filename = '';

  if (type === 'products') {
    filename = 'products.csv';
    headers = ['الاسم (عربي)', 'الاسم (إنجليزي)', 'القسم', 'السعر', 'سعر الخصم', 'الكمية', 'مميز'];
    const catName = (p) => {
      if (p.categoryId && typeof p.categoryId === 'object') return p.categoryId.nameAr || '';
      const c = categoriesCache.find((x) => x._id === p.categoryId);
      return c ? c.nameAr : '';
    };
    rows = (typeof lastLoadedProducts !== 'undefined' ? lastLoadedProducts : []).map((p) => [
      p.nameAr, p.nameEn, catName(p), p.price, p.discountPrice || '', p.stock, p.isFeatured ? 'نعم' : 'لا'
    ]);
  } else if (type === 'orders') {
    filename = 'orders.csv';
    headers = ['رقم الطلب', 'العميل', 'الهاتف', 'المبلغ', 'الحالة', 'التاريخ'];
    rows = (typeof lastLoadedOrders !== 'undefined' ? lastLoadedOrders : []).map((o) => {
      const s = STATUS_LABELS[o.status] || {};
      return [shortId(o._id), o.customerName || (o.userId && o.userId.name) || '', o.customerPhone || '', o.total, s.label || '', formatDate(o.createdAt)];
    });
  } else if (type === 'users') {
    filename = 'users.csv';
    headers = ['الاسم', 'البريد', 'الهاتف', 'الحالة', 'تاريخ التسجيل'];
    rows = usersCache.map((u) => [u.name, u.email, u.phone, u.isActive === false ? 'محظور' : 'نشط', formatDate(u.createdAt)]);
  }

  // دمج CSV مع BOM لدعم العربية في Excel
  const csv = [headers, ...rows]
    .map((r) => r.map((cell) => `"${String(cell == null ? '' : cell).replace(/"/g, '""')}"`).join(','))
    .join('\n');
  const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  link.click();
  URL.revokeObjectURL(url);
  showToast(`تم تصدير ${filename}`);
}

// ===== محادثات المساعد الذكي =====
async function loadChats() {
  const tbody = document.getElementById('chatsTable');
  if (!tbody) return;
  tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;padding:30px">جاري التحميل...</td></tr>';
  try {
    const data = await api('/admin/chats?limit=50');
    const chats = data.chats || [];
    if (chats.length === 0) {
      tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;padding:30px;color:var(--text-muted)">لا توجد محادثات بعد</td></tr>';
      return;
    }
    tbody.innerHTML = chats.map((c) => {
      const user = c.userId || {};
      const name = escapeHtml(user.name || 'زائر');
      const phone = escapeHtml(user.phone || '—');
      const title = escapeHtml(c.title || 'محادثة جديدة');
      const date = formatDate(c.updatedAt || c.createdAt);
      const safeTitle = title.replace(/'/g, "\\'");
      return '<tr>' +
        '<td><div style="font-weight:600">' + name + '</div>' +
        '<div style="font-size:12px;color:var(--text-muted)">' + phone + '</div></td>' +
        '<td>' + title + '</td>' +
        '<td>' + (c.messageCount || 0) + '</td>' +
        '<td>' + date + '</td>' +
        '<td><button class="btn-primary" style="padding:6px 12px;font-size:12px" onclick="openChatModal(\'' + c._id + '\', \'' + safeTitle + '\')">عرض</button></td>' +
        '</tr>';
    }).join('');
  } catch (e) {
    tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;padding:30px;color:#E53935">خطأ: ' + escapeHtml(e.message) + '</td></tr>';
  }
}

// ===== عرض محادثة كاملة =====
async function openChatModal(chatId, title) {
  const body = document.getElementById('chatConversationBody');
  document.getElementById('chatModalTitle').textContent = title ? ('محادثة: ' + title) : 'محادثة المساعد';
  body.innerHTML = '<div style="text-align:center;padding:30px">جاري تحميل المحادثة...</div>';
  showModal('chatModal');
  try {
    const data = await api('/admin/chats/' + chatId);
    const chat = data.chat;
    if (!chat || !chat.messages || chat.messages.length === 0) {
      body.innerHTML = '<div style="text-align:center;padding:30px;color:var(--text-muted)">لا توجد رسائل</div>';
      return;
    }
    const user = chat.userId || {};
    const userInfo = user.name
      ? '<div style="padding:8px 14px;background:var(--bg-secondary);border-radius:8px;margin-bottom:12px;font-size:13px">العميل: <strong>' + escapeHtml(user.name) + '</strong>' + (user.phone ? (' — ' + escapeHtml(user.phone)) : '') + '</div>'
      : '';
    const messagesHtml = chat.messages.map((m) => {
      const isUser = m.role === 'user';
      const align = isUser ? 'flex-end' : 'flex-start';
      const bg = isUser ? '#0D1B3E' : 'var(--bg-secondary)';
      const color = isUser ? '#fff' : 'var(--text-primary)';
      const time = new Date(m.createdAt).toLocaleString('ar-EG', { dateStyle: 'short', timeStyle: 'short' });
      let productsHtml = '';
      if (m.products && Array.isArray(m.products) && m.products.length > 0) {
        productsHtml = '<div style="margin-top:6px;font-size:12px;color:var(--text-muted)">المنتجات المقترحة: ' +
          m.products.map((p) => escapeHtml(p.nameAr || 'منتج')).join('، ') + '</div>';
      }
      return '<div style="display:flex;justify-content:' + align + ';margin-bottom:10px">' +
        '<div style="max-width:75%;padding:10px 14px;border-radius:12px;background:' + bg + ';color:' + color + '">' +
        '<div style="white-space:pre-wrap;font-size:14px;line-height:1.6">' + escapeHtml(m.text || '') + '</div>' +
        productsHtml +
        '<div style="font-size:10px;opacity:0.6;margin-top:4px">' + time + '</div>' +
        '</div></div>';
    }).join('');
    body.innerHTML = userInfo + '<div id="chatScroll" style="max-height:60vh;overflow-y:auto;padding:4px">' + messagesHtml + '</div>';
    const scroll = document.getElementById('chatScroll');
    if (scroll) scroll.scrollTop = scroll.scrollHeight;
  } catch (e) {
    body.innerHTML = '<div style="text-align:center;padding:30px;color:#E53935">خطأ: ' + escapeHtml(e.message) + '</div>';
  }
}

// ===== الاستخدام والمنتجات الأكثر مشاهدة =====
async function loadAppUsage(period = 'daily') {
  // تظبيط أزرار الفترة
  const dailyBtn = document.getElementById('usagePeriodDaily');
  const monthlyBtn = document.getElementById('usagePeriodMonthly');
  if (dailyBtn) dailyBtn.classList.toggle('active', period !== 'monthly');
  if (monthlyBtn) monthlyBtn.classList.toggle('active', period === 'monthly');

  try {
    const [usageRes, visitorsRes, topRes] = await Promise.all([
      api('/admin/analytics/app-usage?period=' + period),
      api('/admin/analytics/visitors'),
      api('/admin/analytics/top-products-views?limit=10'),
    ]);

    const totalOpens = document.getElementById('statTotalOpens');
    if (totalOpens) totalOpens.textContent = usageRes.totalOpens || 0;
    const opensToday = document.getElementById('statOpensToday');
    if (opensToday) opensToday.textContent = usageRes.opensToday || 0;
    const activeUsers = document.getElementById('statActiveUsers');
    if (activeUsers) activeUsers.textContent = usageRes.activeUsers || 0;
    const productViews = document.getElementById('statProductViews');
    if (productViews) productViews.textContent = visitorsRes.totalProductViews || 0;

    // رسم دخول التطبيق
    if (appOpensChartInstance) appOpensChartInstance.destroy();
    const ctx = document.getElementById('appOpensChart');
    if (ctx) {
      const opens = usageRes.opensOverTime || [];
      appOpensChartInstance = new Chart(ctx, {
        type: 'bar',
        data: {
          labels: opens.map((x) => x._id),
          datasets: [{
            label: 'دخول التطبيق',
            data: opens.map((x) => x.opens),
            backgroundColor: '#0D1B3E',
            borderRadius: 6,
          }],
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: { legend: { display: false } },
          scales: { y: { beginAtZero: true, ticks: { precision: 0 } } },
        },
      });
    }

    // أكثر المنتجات مشاهدة
    const topList = document.getElementById('topProductsViews');
    if (topList) {
      const products = topRes.products || [];
      if (products.length === 0) {
        topList.innerHTML = '<div style="text-align:center;padding:30px;color:var(--text-muted)">لا توجد بيانات بعد</div>';
      } else {
        topList.innerHTML = products.map((p, i) => {
          const name = escapeHtml(p.name || 'منتج محذوف');
          const price = Number(p.price || 0).toFixed(0);
          const views = p.views || 0;
          const origin = API.replace('/api', '');
          const imgSrc = p.image ? (p.image.indexOf('http') === 0 ? p.image : origin + '/uploads/products/' + p.image) : '';
          const img = imgSrc
            ? '<img src="' + imgSrc + '" alt="' + name + '" style="width:40px;height:40px;border-radius:8px;object-fit:cover">'
            : '<div style="width:40px;height:40px;border-radius:8px;background:var(--bg-secondary);display:flex;align-items:center;justify-content:center">📦</div>';
          return '<div style="display:flex;align-items:center;gap:12px;padding:10px;border-bottom:1px solid var(--border)">' +
            '<div style="font-weight:bold;color:var(--text-muted);width:24px">' + (i + 1) + '</div>' +
            img +
            '<div style="flex:1"><div style="font-weight:600">' + name + '</div>' +
            '<div style="font-size:12px;color:var(--text-muted)">' + price + ' ج.م</div></div>' +
            '<div style="text-align:right"><div style="font-weight:bold;color:#FF6B00">' + views + '</div>' +
            '<div style="font-size:11px;color:var(--text-muted)">مشاهدة</div></div>' +
            '</div>';
        }).join('');
      }
    }
  } catch (e) {
    showToast('خطأ في جلب إحصائيات الاستخدام: ' + e.message, 'error');
  }
}

// ===== Init =====
window.addEventListener('DOMContentLoaded', () => {
  // إضافة Enter listener على شاشة الدخول
  document.getElementById('loginPassword').addEventListener('keydown', (e) => {
    if (e.key === 'Enter') login();
  });

  // تطبيق dark mode من localStorage
  const isDark = localStorage.getItem('admin_dark_mode') === '1';
  applyDarkMode(isDark);

  checkAuth();
});
