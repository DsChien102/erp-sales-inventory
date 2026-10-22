/* Toàn Theme 7 + Hub Kho (SCR-090, bản candidate — chốt 2026-10-16).
 *
 * Sở hữu: tab chế độ review (Theo BJ / UIF · Toàn Theme 7), các route của chế độ theme
 * (Thêm · Kho · đang trong một luồng), các màn của Hub Kho (Home, Nhận hàng chờ phê duyệt,
 * 5 khu Quản lý kho, Thiết lập kho), vào / ra luồng từ Hub, sidebar + inspector khi ở
 * chế độ theme, tham số URL mode / app / hubView.
 *
 * core.js gọi vào đây qua ThemeApp: renderAppScreen() hỏi isRoot() rồi renderRoot(), hoặc dựng
 * màn luồng rồi afterFlowRender(); renderInspector(), renderFlowSelector(), renderNavigation(),
 * syncReviewUrl(), previousScreen() làm tương tự. Mọi màn ở đây dựng thẳng, không vá DOM sau dựng.
 */
const ThemeApp = (() => {
  const qs = new URLSearchParams(location.search);
  let mode = qs.get('mode') === 'theme' ? 'theme' : 'bj';
  let route = qs.get('app') || (mode === 'theme' ? 'more' : null);
  if (!['more', 'inventory', 'flow'].includes(route)) route = mode === 'theme' ? 'more' : null;
  let hubView = qs.get('hubView') || 'home';
  // Kho đã kích hoạt chưa (BJ-12 khởi tạo tồn đầu kỳ). ?activation=pending mở Home ở trạng thái chưa kích hoạt.
  let inventoryActivated = qs.get('activation') !== 'pending';
  // Màn được mở thẳng từ Hub (vd. phiếu chờ duyệt → SCR-011): nút quay lại của màn đó về Hub.
  let directEntryScreen = null;

  const FLOW_LABELS = {
    'UIF-01': 'Tồn kho', 'UIF-02': 'Nhận hàng mua', 'UIF-03': 'Xác lập giá trị nhập ban đầu', 'UIF-04': 'Giữ hàng theo đơn bán',
    'UIF-05': 'Lấy hàng & bàn giao', 'UIF-06': 'Hàng khách trả', 'UIF-07': 'Trả nhà cung cấp', 'UIF-08': 'Kiểm kê kho',
    'UIF-09': 'Tình trạng hàng', 'UIF-10': 'Tiêu hủy hàng', 'UIF-11': 'Hủy & sửa sai nghiệp vụ', 'UIF-12': 'Khởi tạo tồn đầu kỳ',
    'UIF-13': 'Chi phí mua bổ sung', 'UIF-14': 'Giá vốn', 'UIF-15': 'Báo cáo tồn & thẻ kho', 'UIF-16': 'Đối soát sai lệch',
    'UIF-17': 'Xác minh kết quả', 'CAP-01': 'Chính sách tồn & cận hạn',
  };

  const WORKSPACES = {
    inventory: { title: 'Tồn kho', subtitle: 'Số lượng, khả dụng, lô và tình trạng hàng', icon: 'warehouse', items: [
      { flow: 'UIF-01', title: 'Tồn kho & khả dụng', subtitle: 'Tra cứu sản phẩm, số lượng, lô và khả dụng', icon: 'warehouse' },
      { flow: 'UIF-09', title: 'Tình trạng hàng', subtitle: 'Xem và xử lý trạng thái của sản phẩm hoặc lô', icon: 'shield' },
      { flow: 'CAP-01', title: 'Chính sách tồn & cận hạn', subtitle: 'Thiết lập ngưỡng tồn và chính sách cận hạn', icon: 'shield' },
    ] },
    movement: { title: 'Nhập, xuất & hoàn trả', subtitle: 'Hàng đi vào, đi ra và quay lại kho', icon: 'package', items: [
      { flow: 'UIF-02', title: 'Nhận hàng', subtitle: 'Nhận theo chứng từ hoặc nhập nhanh', icon: 'cloudUpload' },
      { flow: 'UIF-05', title: 'Lấy & bàn giao', subtitle: 'Chuẩn bị hàng và bàn giao theo đơn bán', icon: 'package' },
      { flow: 'UIF-06', title: 'Hàng khách trả', subtitle: 'Tiếp nhận và phân loại hàng trả lại', icon: 'rotate' },
      { flow: 'UIF-07', title: 'Trả nhà cung cấp', subtitle: 'Chuẩn bị và thực hiện trả hàng', icon: 'arrowLeft' },
    ] },
    control: { title: 'Kiểm kê & xử lý', subtitle: 'Kiểm tra thực tế, sai lệch và trường hợp bất thường', icon: 'listCheck', items: [
      { flow: 'UIF-08', title: 'Kiểm kê kho', subtitle: 'Đếm, rà soát và xử lý chênh lệch', icon: 'listCheck' },
      { flow: 'UIF-09', title: 'Hàng cần xử lý', subtitle: 'Bắt đầu từ sản phẩm hoặc lô có tình trạng cần xử lý', icon: 'shield' },
      { flow: 'UIF-11', title: 'Hủy & sửa sai nghiệp vụ', subtitle: 'Xử lý giao dịch kho có sai sót', icon: 'edit' },
      { flow: 'UIF-16', title: 'Đối soát sai lệch', subtitle: 'Điều tra khi số liệu giữa các nguồn không khớp', icon: 'search' },
    ] },
    valuation: { title: 'Giá trị kho', subtitle: 'Giá nhập, chi phí mua và giá vốn', icon: 'layers', items: [
      { flow: 'UIF-03', title: 'Hàng chờ xác lập giá trị', subtitle: 'Ghi giá nhập cho hàng đã nhận', icon: 'checkCircle' },
      { flow: 'UIF-13', title: 'Chi phí mua bổ sung', subtitle: 'Ghi nhận chi phí phát sinh đến muộn', icon: 'fileText' },
      { flow: 'UIF-14', title: 'Giá vốn', subtitle: 'Tính, rà soát và công bố giá vốn', icon: 'layers' },
    ] },
    history: { title: 'Báo cáo & lịch sử', subtitle: 'Thẻ kho, biến động và số liệu tra cứu', icon: 'history', items: [
      { flow: 'UIF-15', title: 'Báo cáo tồn & thẻ kho', subtitle: 'Xem tồn tại thời điểm và lịch sử biến động', icon: 'history' },
    ] },
    setup: { title: 'Thiết lập kho', subtitle: 'Các việc thiết lập ít dùng', icon: 'inbox', items: [
      { flow: 'UIF-12', title: 'Khởi tạo tồn đầu kỳ', subtitle: 'Thiết lập số dư tồn kho ban đầu', icon: 'inbox', actor: 'owner' },
      { flow: 'CAP-01', title: 'Chính sách tồn & cận hạn', subtitle: 'Thiết lập ngưỡng tồn và chính sách cảnh báo', icon: 'shield' },
    ] },
  };

  const ORG_NAME = 'VET45 Demo';

  // Ba dòng của prototype mở cùng một fixture ở SCR-011 (phiếu của Minh Dũng, Nguyễn Văn An gửi 09:41).
  const PENDING_RECEIPTS = [
    { id: 'REC-260916-04', supplier: 'Minh Dũng', meta: 'Kho trung tâm · 2 mặt hàng · Nguyễn Văn An gửi 09:41' },
    { id: 'REC-260916-02', supplier: 'An Việt', meta: 'Kho trung tâm · 2 mặt hàng · Lê Thu Hà gửi 08:55' },
    { id: 'REC-260916-03', supplier: 'Minh Phát', meta: 'Kho trung tâm · 4 mặt hàng · Trần Minh gửi 08:20' },
  ];

  // Nguồn "Chờ duyệt" (K2): mỗi BJ đăng ký { id, label, rows() } vào mảng toàn cục trước khi hub.js nạp; rows() rỗng = không có việc chờ.
  // Nhận hàng đứng đầu để dòng phụ đọc "3 nhận hàng · 1 số dư đầu kỳ".
  const pendingSources = (window.__T7_PENDING_SOURCES__ = window.__T7_PENDING_SOURCES__ || []);
  pendingSources.unshift({
    id: 'UIF-02',
    label: 'nhận hàng',
    // Kho chưa kích hoạt thì chưa nhận hàng được → không có phiếu nhận hàng chờ duyệt.
    // Phiếu vừa gửi trong phiên (bj02PendingSubmitted) thay dòng đầu: mở đúng phiếu đó, không nạp lại fixture.
    rows: () => (!inventoryActivated ? [] : PENDING_RECEIPTS.map((item, index) => {
      const mine = index === 0 && typeof bj02PendingSubmitted !== 'undefined' && bj02PendingSubmitted;
      return {
        title: mine ? (currentReceiptSupplier() || 'Nhập nhanh') : item.supplier,
        subtitle: mine ? `Kho trung tâm · ${bj02Lines.length} mặt hàng · ${BJ02_CONTEXT.submitted.maker} gửi 09:41` : item.meta,
        icon: 'cloudUpload',
        attrs: `data-theme-entry-flow="UIF-02" data-t380-target-screen="SCR-011" data-t380-context="${mine ? 'bj02-submitted-approval' : 'bj02-pending-approval'}" data-v464-pending-receipt="${item.id}" data-theme-entry-actor="approver"`,
      };
    })),
  });
  const pendingRows = () => pendingSources.flatMap((src) => src.rows().map((row) => ({ ...row, source: src })));
  function pendingSummary() {
    const parts = pendingSources.map((src) => ({ n: src.rows().length, label: src.label })).filter((p) => p.n > 0);
    return { total: parts.reduce((sum, p) => sum + p.n, 0), text: parts.map((p) => `${p.n} ${p.label}`).join(' · ') };
  }

  const inTheme = () => mode === 'theme';
  const isRoot = () => inTheme() && route !== 'flow';
  const atHub = () => inTheme() && route === 'inventory';
  const inThemeFlow = () => inTheme() && route === 'flow';

  // ---------------------------------------------------------------- dựng màn

  // Khung 5 tab của app (docs/02-yeu-cau/LUONG-UNG-DUNG.md); chỉ "Thêm" bấm được trong prototype.
  function bottomNav() {
    return `<nav class="t7-app-bottom-nav" aria-label="Điều hướng chính" data-theme-component="VET45BottomNavigation">
      <button type="button" disabled aria-label="Trang chủ">${icon('warehouse', 'icon--sm')}<span>Trang chủ</span></button>
      <button type="button" disabled aria-label="Đơn hàng">${icon('fileText', 'icon--sm')}<span>Đơn hàng</span></button>
      <button type="button" disabled aria-label="Sản phẩm">${icon('package', 'icon--sm')}<span>Sản phẩm</span></button>
      <button type="button" disabled aria-label="Đối tác">${icon('user', 'icon--sm')}<span>Đối tác</span></button>
      <button type="button" class="is-active" aria-current="page" data-theme-sidebar-route="more" aria-label="Thêm">${icon('more', 'icon--sm')}<span>Thêm</span></button>
    </nav>`;
  }

  // Thanh bên của khung web (W-1 mục 3.3): cùng nhãn / icon với bottomNav(), thêm mục con của "Thêm"; chỉ hiện khi khung là Web.
  function webSidebar() {
    const main = [['warehouse', 'Trang chủ'], ['fileText', 'Đơn hàng'], ['package', 'Sản phẩm'], ['user', 'Đối tác']]
      .map(([ic, label]) => `<button type="button" disabled aria-label="${label}">${icon(ic, 'icon--sm')}<span>${label}</span></button>`).join('');
    const sub = [['Giá riêng / Nhớ giá'], ['Người dùng & vai trò'], ['Tài khoản của tôi'], ['Thiết lập']]
      .map(([label]) => `<button type="button" disabled>${label}</button>`).join('');
    return `<div class="t7-web-sidebar__org">${esc(ORG_NAME)}</div>
      ${main}
      <button type="button" class="is-active" data-theme-sidebar-route="more" aria-label="Thêm">${icon('more', 'icon--sm')}<span>Thêm</span></button>
      <div class="t7-web-sidebar__sub">
        <button type="button" class="is-active" aria-current="page" data-theme-sidebar-route="inventory">Kho</button>
        ${sub}
      </div>
      <button type="button" class="t7-web-sidebar__logout" disabled>Đăng xuất</button>`;
  }

  function renderWebSidebar() {
    const nav = document.getElementById('web-sidebar');
    if (nav) nav.innerHTML = webSidebar();
  }

  function shell({ title, body, back, backAttr, extraClass = '' }) {
    return `<div class="v-page-scaffold figma-calibrated-shell t7-integrated-shell ${extraClass}" data-mobile-product data-product-app data-inspectable="true" data-ds-component="VPageScaffold" data-ds-profile="screen.shell.standard" data-ds-prop-title="${escapeAttribute(title)}" data-ds-prop-center-title="false">
      ${statusBar()}
      <header class="app-header"><div class="app-appbar ${back ? 'has-back' : 'no-back'}" data-ds-component="VAppBar" data-ds-prop-center-title="false" data-ds-prop-actions="null" data-ds-prop-show-back-button="${back}">
        ${back ? `<button class="app-icon-button app-back-button" ${backAttr} type="button" aria-label="Quay lại" data-ds-internal="VAppBar.leading">${icon('chevronLeft', 'icon--24')}</button>` : ''}
        <div class="app-appbar-copy" data-ds-component="VAppBarTitle"><h3>${esc(title)}</h3></div>
      </div></header>
      <div class="app-content" data-ds-component="VPagePadding" data-ds-profile="screen.body.standard"><div class="body-stack">${body}</div></div>
      ${bottomNav()}
    </div>`;
  }

  function disabledMoreRow(title, subtitle, leading) {
    return ds24ListRow({ title, subtitle, leading, type: 'Navigation', state: 'Disabled', disabled: true, attrs: 'data-theme-disabled-module="true"', theme: 'VET45MoreNavigationRow' });
  }

  function renderMore() {
    const rows = [
      disabledMoreRow('Khách hàng & NCC', 'Quản lý khách hàng & nhà cung cấp', 'user'),
      disabledMoreRow('Đơn nhập', 'Nhập kho từ nhà cung cấp', 'cloudUpload'),
      ds24ListRow({ title: 'Kho', subtitle: 'Tồn kho, vận hành, giá vốn và kiểm soát', leading: 'warehouse', attrs: 'data-theme-app-route="inventory"', theme: 'Theme7ModuleEntry' }),
      disabledMoreRow('Báo cáo', 'Doanh thu, tồn kho, công nợ', 'history'),
      disabledMoreRow('Giá riêng / Nhớ giá', 'Giá riêng theo khách hàng và nhớ giá', 'layers'),
      disabledMoreRow('Người dùng & vai trò', 'Quản lý thành viên và quyền truy cập', 'user'),
      disabledMoreRow('Tài khoản của tôi', 'Xem và chỉnh sửa thông tin cá nhân', 'user'),
      disabledMoreRow('Thiết lập', 'Cấu hình hệ thống và hóa đơn điện tử', 'shield'),
    ].join('');
    return shell({ title: 'Thêm', back: false, body: `<section class="ds24-list-stack t7-more-list" data-composed-from="DS v2 / List Row">${rows}</section>` });
  }

  function heading(title, meta = '') {
    return `<div class="t462-section-heading"><h2 data-ds-component="VText" data-ds-prop-style="Label/Default">${esc(title)}</h2>${meta ? `<span>${esc(meta)}</span>` : ''}</div>`;
  }

  function quickAction({ label, iconName, flow, disabled = false }) {
    return `<button class="t462-quick-action" type="button" data-theme-entry-flow="${flow}" data-t462-quick="${flow}" data-ds-component="VQuickActionButton" data-ds-prop-state="${disabled ? 'Disabled' : 'Default'}"${disabled ? ' disabled aria-disabled="true"' : ''}><span class="t462-quick-action__icon">${icon(iconName, 'icon--sm')}</span><span class="t462-quick-action__label">${esc(label)}</span></button>`;
  }

  // Dòng "Cần chú ý": tone theo nghĩa (chờ duyệt = việc cần làm → info; còn lại = cảnh báo, xem CSS), có chevron vì dòng mở một danh sách.
  function attentionRow({ title, subtitle, count, flow = '', iconName, attrs = '' }) {
    const routeAttrs = flow ? `data-theme-entry-flow="${flow}" data-t462-attention="${flow}"` : '';
    return `<button class="t462-attention-row" type="button" ${routeAttrs} ${attrs}><span class="t462-attention-row__icon">${icon(iconName, 'icon--sm')}</span><span class="t462-attention-row__copy"><strong>${esc(title)}</strong><span>${esc(subtitle)}</span></span><span class="t462-attention-row__count">${esc(count)}</span><span class="t462-attention-row__chevron" aria-hidden="true">${icon('chevronRight', 'icon--sm')}</span></button>`;
  }

  function workspaceRow(id) {
    const w = WORKSPACES[id];
    return ds24ListRow({ title: w.title, subtitle: w.subtitle, leading: w.icon, attrs: `data-t462-workspace="${id}"`, theme: 'Theme7WarehouseCandidateWorkspace', extraClass: 't462-workspace-row' });
  }

  function renderHubHome() {
    const search = `<div class="t462-search-wrap">${ds24Search('', 'data-t462-inventory-search', 'Tìm sản phẩm, SKU hoặc quét mã')}</div>`;
    const off = !inventoryActivated;
    const notActivated = off
      ? `<section class="t462-section t462-not-activated" data-ds-component="VSection">${vBanner('info', 'Kho chưa kích hoạt', 'Nhập số tồn hiện có một lần để bắt đầu nhận, bán và kiểm kê hàng.')}<button class="button button--primary t462-not-activated__action" type="button" data-theme-entry-flow="UIF-12" data-theme-entry-actor="owner" data-ds-component="VButton" data-ds-prop-variant="VButtonVariant.primary" data-ds-prop-size="VButtonSize.medium">Khởi tạo tồn kho</button></section>`
      : '';
    const quick = `<section class="t462-section t462-section--quick" data-ds-component="VSection"><div class="t462-quick-grid">
      ${quickAction({ label: 'Nhận hàng', iconName: 'cloudUpload', flow: 'UIF-02', disabled: off })}
      ${quickAction({ label: 'Lấy hàng', iconName: 'package', flow: 'UIF-05', disabled: off })}
      ${quickAction({ label: 'Kiểm kê', iconName: 'listCheck', flow: 'UIF-08', disabled: off })}
      ${quickAction({ label: 'Tra cứu tồn', iconName: 'search', flow: 'UIF-01', disabled: off })}
    </div></section>`;
    const pending = pendingSummary();
    const pendingRow = pending.total > 0 ? attentionRow({ title: 'Chờ duyệt', subtitle: pending.text, count: String(pending.total), iconName: 'clock', attrs: 'data-v464-pending-approvals' }) : '';
    // Kho chưa kích hoạt: chưa có tồn nên không có lô / sai lệch / nghiệp vụ; chỉ còn việc chờ duyệt (vd. số dư đầu kỳ), không có thì bỏ cả mục.
    const operating = off ? '' : `
        ${attentionRow({ title: 'Lô sắp hết hạn', subtitle: 'Cần kiểm tra trước khi bán hoặc xuất', count: '3 lô', flow: 'UIF-09', iconName: 'shield' })}
        ${attentionRow({ title: 'Sai lệch cần đối soát', subtitle: 'Tồn kho đang có chênh lệch cần xác minh', count: '1', flow: 'UIF-16', iconName: 'search' })}
        ${attentionRow({ title: 'Nghiệp vụ chưa xác định kết quả', subtitle: 'Cần xác minh trước khi thao tác tiếp', count: '1', flow: 'UIF-17', iconName: 'rotate' })}`;
    const attention = !pendingRow && !operating ? '' : `<section class="t462-section" data-ds-component="VSection">${heading('Cần chú ý')}
      <div class="t462-attention-list">
        ${pendingRow}${operating}
      </div></section>`;
    const workspaces = `<section class="t462-section" data-ds-component="VSection">${heading('Quản lý kho')}
      <div class="t462-workspace-list ds24-list-stack">${['inventory', 'movement', 'control', 'valuation', 'history'].map(workspaceRow).join('')}</div>
    </section>`;
    const setup = `<section class="t462-section" data-ds-component="VSection">${ds24ListRow({ title: 'Thiết lập kho', subtitle: 'Tồn đầu kỳ và chính sách ít dùng', leading: 'inbox', attrs: 'data-t462-workspace="setup"', theme: 'Theme7WarehouseCandidateSetup', extraClass: 't462-workspace-row' })}</section>`;
    // Web: thanh bên đã chỉ chỗ nên không có nút quay lại; dưới nút nhanh chia hai cột (trái: banner chưa kích hoạt + "Cần chú ý", phải: "Quản lý kho" + "Thiết lập kho"). iPhone giữ một cột.
    if (viewport === 'web') return shell({ title: 'Kho', back: false, extraClass: 't462-warehouse-hub', body: `${search}${quick}<div class="t462-columns"><div class="t462-column">${notActivated}${attention}</div><div class="t462-column">${workspaces}${setup}</div></div>` });
    return shell({ title: 'Kho', back: true, backAttr: 'data-theme-app-back', extraClass: 't462-warehouse-hub', body: `${search}${notActivated}${quick}${attention}${workspaces}${setup}` });
  }

  function renderWorkspace(id) {
    const w = WORKSPACES[id] || WORKSPACES.inventory;
    const rows = w.items.map((item) => ds24ListRow({ title: item.title, subtitle: item.subtitle, leading: item.icon, attrs: `data-theme-entry-flow="${item.flow}"${item.actor ? ` data-theme-entry-actor="${item.actor}"` : ''}`, theme: 'Theme7WarehouseCandidateCapability', extraClass: 't462-capability-row' })).join('');
    return shell({ title: w.title, back: true, backAttr: 'data-t462-workspace-back', extraClass: 't462-workspace-screen', body: `<section class="t462-section t462-section--workspace-list" data-ds-component="VSection"><div class="t462-sublist ds24-list-stack">${rows}</div></section>` });
  }

  function renderPendingApprovals() {
    const rows = pendingRows().map((item) => ds24ListRow({
      title: item.title,
      subtitle: item.subtitle,
      leading: item.icon || 'inbox',
      trailing: ds24Badge('Chờ duyệt', 'Warning'),
      attrs: item.attrs,
      theme: 'Theme7PendingReceiptApproval',
      extraClass: 't462-capability-row t464-pending-receipt-row',
    })).join('');
    return shell({ title: 'Chờ duyệt', back: true, backAttr: 'data-t462-workspace-back', extraClass: 't462-workspace-screen', body: `<section class="t462-section t462-section--workspace-list" data-ds-component="VSection">${heading('Đang chờ xử lý', pendingSummary().text)}<div class="t462-sublist ds24-list-stack">${rows}</div></section>` });
  }

  function renderRoot() {
    const app = document.getElementById('app-screen');
    if (route === 'more') app.innerHTML = renderMore();
    else if (hubView === 'home') app.innerHTML = renderHubHome();
    else if (hubView === 'pending-approvals') app.innerHTML = renderPendingApprovals();
    else app.innerHTML = renderWorkspace(hubView);
  }

  // Sau khi dựng một màn luồng: nút quay lại ở màn vào luồng / màn mở thẳng về Kho, khoá quay lại sau khi đã gửi duyệt.
  function afterFlowRender() {
    const bar = document.querySelector('#app-screen .app-appbar');
    if (inThemeFlow() && bar) {
      if (activeScreenId === activeFlow().screens[0]) setBack(bar, 'data-theme-app-back-to-inventory', 'Quay về Kho');
      if (directEntryScreen && activeScreenId === directEntryScreen) setBack(bar, 'data-t380-back-home', 'Quay về Kho');
      const st = stateByScreen[activeScreenId];
      const submitted = st === 'PENDING_APPROVAL' && ['SCR-010', 'SCR-038', 'SCR-040'].includes(activeScreenId);
      if (submitted) {
        bar.querySelector('.app-back-button')?.remove();
        bar.classList.remove('has-back'); bar.classList.add('no-back'); bar.setAttribute('data-ds-prop-show-back-button', 'false');
      }
    }
  }

  function setBack(bar, attr, label) {
    bar.classList.remove('no-back'); bar.classList.add('has-back');
    let back = bar.querySelector('.app-back-button');
    if (!back) {
      bar.insertAdjacentHTML('afterbegin', `<button class="app-icon-button app-back-button" type="button" aria-label="${label}" data-ds-internal="VAppBar.leading">${icon('chevronLeft', 'icon--24')}</button>`);
      back = bar.querySelector('.app-back-button');
    }
    [...back.attributes].forEach((a) => { if (a.name.startsWith('data-') && a.name !== 'data-ds-internal') back.removeAttribute(a.name); });
    back.setAttribute(attr, '');
    back.setAttribute('aria-label', label);
  }

  // ---------------------------------------------------------------- harness (sidebar, inspector, URL)

  function renderFlowSelector() {
    const f = activeFlow();
    document.body.dataset.workbenchMode = 'theme';
    document.body.dataset.activeUif = route === 'flow' ? f.id : 'THEME-07-APP';
    const select = document.getElementById('flow-selector');
    if (select) select.innerHTML = flowCatalog.map((x) => `<option value="${x.id}" ${x.id === activeFlowId ? 'selected' : ''}>${x.bj} · ${x.name}</option>`).join('');
    const title = route === 'more' ? 'Thêm' : route === 'inventory' ? 'Kho' : `${f.bj} · ${f.name}`;
    document.getElementById('sidebar-flow-title').textContent = route === 'flow' ? 'Toàn Theme 7 · Đang thao tác' : 'Toàn Theme 7';
    document.getElementById('sidebar-flow-intent').textContent = route === 'flow' ? `Đang dùng chung runtime ${f.id}; quay lại Kho để mở nghiệp vụ khác.` : 'Đi từ Thêm → Kho và thao tác xuyên toàn bộ Theme 7 trên cùng runtime.';
    document.getElementById('workbench-title').textContent = `Theme 7 · ${title}`;
    document.getElementById('workbench-count').textContent = '17 BJ + CAP-01';
  }

  function renderNavigation() {
    const rootButtons = `<button class="screen-nav-item ${route === 'more' ? 'is-active' : ''}" data-theme-sidebar-route="more" type="button"><span class="screen-nav-number">01</span><span class="screen-nav-copy"><strong>Thêm</strong><span>VET45 navigation</span></span><span class="nav-chevron">›</span></button><button class="screen-nav-item ${route === 'inventory' ? 'is-active' : ''}" data-theme-sidebar-route="inventory" type="button"><span class="screen-nav-number">02</span><span class="screen-nav-copy"><strong>Kho</strong><span>Theme 7 module root</span></span><span class="nav-chevron">›</span></button>`;
    const current = route === 'flow' ? `<div class="nav-group"><span class="nav-group-label">Đang mở</span><button class="screen-nav-item is-active" type="button" disabled><span class="screen-nav-number">${esc(activeFlow().bj.replace('BJ-', '').replace('CAP-', 'C'))}</span><span class="screen-nav-copy"><strong>${esc(FLOW_LABELS[activeFlowId] || activeFlow().name)}</strong><span>${esc(activeFlowId)}</span></span></button><button class="screen-nav-item" data-theme-sidebar-route="inventory" type="button"><span class="screen-nav-number">←</span><span class="screen-nav-copy"><strong>Về Kho</strong><span>Chọn nghiệp vụ khác</span></span><span class="nav-chevron">›</span></button></div>` : '';
    document.getElementById('screen-navigation').innerHTML = `<div class="nav-group"><span class="nav-group-label">Điểm vào</span>${rootButtons}</div>${current}`;
  }

  function renderRootInspector() {
    const more = route === 'more';
    const view = hubView;
    document.getElementById('current-screen-id').textContent = more ? 'VET45 · NAV-MORE' : view === 'home' ? 'THEME-07 · HUB-CANDIDATE' : view === 'pending-approvals' ? 'BJ02 · PENDING-APPROVAL-WORKLIST' : 'THEME-07 · WORKSPACE-CANDIDATE';
    document.getElementById('current-screen-name').textContent = more ? 'Thêm' : view === 'home' ? 'Kho · Candidate' : view === 'pending-approvals' ? 'Nhận hàng chờ phê duyệt' : WORKSPACES[view]?.title || 'Kho · Candidate';
    document.getElementById('state-switcher').innerHTML = '<span class="t7-inspector-static">READY · app navigation</span>';
    document.getElementById('traceability').innerHTML = more
      ? '<div class="trace-row"><span>Entry</span><strong>Bottom navigation → Thêm</strong></div><div class="trace-row"><span>UI authority</span><strong>Figma DS · VAppBar · DS v2 / List Row</strong></div><div class="trace-row"><span>Runtime</span><strong>Shared with BJ / UIF tab</strong></div><div class="trace-row"><span>Coverage</span><strong>Kho entry</strong></div>'
      : '<div class="trace-row"><span>Review mode</span><strong>Hub Kho</strong></div><div class="trace-row"><span>Primary IA</span><strong>Search + 4 Quick Actions + Cần chú ý + 5 workspace</strong></div><div class="trace-row"><span>Permission</span><strong>Không phụ thuộc role; thiết kế cho một Owner làm tất cả</strong></div>';
    document.getElementById('design-rationale').textContent = more
      ? 'Tái hiện điểm vào hiện tại của VET45. Chỉ Kho được bật trong phạm vi prototype Theme 7; các module ngoài phạm vi giữ đúng trạng thái Disabled.'
      : 'Home Kho (SCR-090): một người vận hành toàn bộ Kho qua tìm kiếm, thao tác nhanh, việc cần chú ý và 5 workspace.';
  }

  function afterFlowInspector() {
    if (!inThemeFlow()) return;
    const f = activeFlow();
    document.getElementById('workbench-title').textContent = `Theme 7 · ${FLOW_LABELS[f.id] || f.name}`;
    document.getElementById('workbench-count').textContent = 'Toàn Theme 7';
  }

  function decorateUrl(url) {
    url.searchParams.set('mode', mode);
    if (inTheme()) url.searchParams.set('app', route || 'more'); else url.searchParams.delete('app');
    if (hubView !== 'home') url.searchParams.set('hubView', hubView); else url.searchParams.delete('hubView');
  }

  function updateModeTabs() {
    document.querySelectorAll('button[data-workbench-mode]').forEach((btn) => {
      const active = btn.dataset.workbenchMode === mode;
      btn.classList.toggle('is-active', active);
      btn.setAttribute('aria-selected', String(active));
    });
  }

  function installModeTabs() {
    const meta = document.querySelector('.review-meta');
    if (!meta || document.querySelector('[data-workbench-tabs]')) return;
    const tabs = document.createElement('div');
    tabs.className = 'workbench-mode-tabs';
    tabs.setAttribute('data-workbench-tabs', '');
    tabs.setAttribute('role', 'tablist');
    tabs.setAttribute('aria-label', 'Chế độ review');
    tabs.innerHTML = '<button type="button" role="tab" data-workbench-mode="bj">Theo BJ / UIF</button><button type="button" role="tab" data-workbench-mode="theme">Toàn Theme 7</button>';
    meta.prepend(tabs);
  }

  // ---------------------------------------------------------------- điều hướng

  function go(nextRoute, nextHubView = hubView) {
    mode = 'theme'; route = nextRoute; hubView = nextHubView;
    syncReviewUrl(); render();
  }

  function setMode(next) {
    if (next === mode) return;
    mode = next;
    route = mode === 'theme' ? (['more', 'inventory', 'flow'].includes(route) ? route : 'more') : null;
    syncReviewUrl(); render();
  }

  function enterFlow(flowId) {
    const flow = flowCatalog.find((f) => f.id === flowId);
    if (!flow) return;
    activeFlowId = flow.id;
    activeScreenId = flow.screens[0];
    route = 'flow';
    syncReviewUrl(); render();
  }

  // Ngữ cảnh khi mở thẳng một màn từ Hub (giữ từ lớp v3.8 / v4.6.4).
  function applyDirectContext(context, receiptId) {
    if (context === 'bj02-pending-approval' && receiptId) {
      flowMode = 'document';
      selectedDocumentId = 'PN-260816-04';
      if (typeof resetBj02Receipt === 'function') resetBj02Receipt('document');
      // Nobivac DHPPi 121 hộp (theo lô, vượt chứng từ +1), Oxytetracycline LA 24 chai (không theo lô).
      bj02Lines = bj02Lines.map((line, index) => {
        const qty = index === 0 ? 121 : 24;
        const lots = line.trackingPolicy === 'LOT' ? [{ id: `V464-LOT-${index + 1}`, code: 'DH2508', expiry: '31/08/2027', expiryPrecision: 'DAY', manufactureDate: '', manufacturePrecision: 'DAY', accepted: qty, totalReceived: qty, quarantine: 0, damaged: 0, rejected: 0 }] : [];
        return { ...line, status: 'COMPLETED', accepted: line.trackingPolicy === 'LOT' ? 0 : qty, totalReceived: qty, quarantine: 0, damaged: 0, rejected: 0, lots };
      });
      bj02Header = { ...bj02Header, businessDate: '2026-09-16' };
      stateByScreen['SCR-010'] = 'PENDING_APPROVAL'; stateByScreen['SCR-011'] = 'READY'; stateByScreen['SCR-012'] = 'COMPLETED'; approvalRejectReason = '';
    }
  }

  function applyDirectContextMine(context) {
    if (context !== 'bj02-submitted-approval') return false;
    stateByScreen['SCR-010'] = 'PENDING_APPROVAL'; stateByScreen['SCR-011'] = 'READY'; stateByScreen['SCR-012'] = 'COMPLETED'; approvalRejectReason = '';
    return true;
  }

  function openDirect(target, context, receiptId) {
    directEntryScreen = target;
    if (!applyDirectContextMine(context)) applyDirectContext(context, receiptId);
    activeScreenId = target;
    syncReviewUrl(); render();
  }

  // Một trình nghe cho cả chế độ theme. Đăng ký ở pha capture của window để chạy trước handler của từng BJ.
  window.addEventListener('click', (event) => {
    const t = event.target;
    if (!t.closest) return;
    const stop = () => { event.preventDefault(); event.stopImmediatePropagation(); };

    const modeBtn = t.closest('button[data-workbench-mode]');
    if (modeBtn) { stop(); return setMode(modeBtn.dataset.workbenchMode); }

    if (t.closest('[data-action="exit-approval"]') && activeFlowId === 'UIF-02' && activeScreenId === 'SCR-011' && inTheme()) { stop(); directEntryScreen = null; return go('inventory', 'pending-approvals'); }

    if (t.closest('[data-t380-back-home]')) { stop(); directEntryScreen = null; return go('inventory'); }

    if (!inTheme()) return;

    if (atHub() && t.closest('[data-v464-pending-approvals]')) { stop(); return go('inventory', 'pending-approvals'); }
    const ws = atHub() && t.closest('[data-t462-workspace]');
    if (ws) { stop(); return go('inventory', ws.dataset.t462Workspace); }
    if (atHub() && t.closest('[data-t462-workspace-back]')) { stop(); return go('inventory', 'home'); }

    const sidebarRoute = t.closest('[data-theme-sidebar-route]');
    if (sidebarRoute) { stop(); return go(sidebarRoute.dataset.themeSidebarRoute); }
    const appRoute = t.closest('[data-theme-app-route]');
    if (appRoute) { stop(); return go(appRoute.dataset.themeAppRoute); }
    if (t.closest('[data-theme-app-back]')) { stop(); return go('more'); }
    if (t.closest('[data-theme-app-back-to-inventory]')) { stop(); return go('inventory'); }

    const entry = t.closest('[data-theme-entry-flow]');
    if (entry) {
      stop();
      directEntryScreen = null;
      const flow = flowCatalog.find((f) => f.id === entry.dataset.themeEntryFlow);
      if (!flow) return;
      // Vai khi vào luồng: mặc định "module"; lối vào gắn data-theme-entry-actor (vd. Owner khởi tạo kho, người duyệt từ "Chờ duyệt") đặt vai riêng.
      window.__VET45_QA__.setActor(entry.dataset.themeEntryActor || 'module');
      activeFlowId = flow.id;
      activeScreenId = flow.screens[0];
      route = 'flow';
      if (entry.dataset.t380TargetScreen) return openDirect(entry.dataset.t380TargetScreen, entry.dataset.t380Context || '', entry.dataset.v464PendingReceipt);
      syncReviewUrl(); render();
    }
  }, true);

  // Ô tìm trên Hub: Enter mở Tồn kho với từ khoá.
  document.addEventListener('keydown', (event) => {
    if (!atHub() || event.key !== 'Enter' || !event.target.matches('[data-t462-inventory-search]')) return;
    event.preventDefault();
    if (typeof bj01Query !== 'undefined') bj01Query = event.target.value.trim();
    enterFlow('UIF-01');
  }, true);

  return {
    isRoot, inTheme, renderRoot, renderWebSidebar, afterFlowRender, renderFlowSelector, renderNavigation, renderRootInspector, afterFlowInspector, decorateUrl,
    updateModeTabs, installModeTabs,
    setActivated(value) { inventoryActivated = Boolean(value); },
    handlePrevious() {
      if (inThemeFlow() && activeScreenId === activeFlow().screens[0]) { go('inventory'); return true; }
      return false;
    },
  };
})();

ThemeApp.installModeTabs();
render();
