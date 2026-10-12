/* ================= 会员管家 · 核心逻辑 ================= */

/* ---------- 预设平台库（品牌色 + 首字母） ---------- */
const PLATFORMS = [
  {id:'tencent', name:'腾讯视频',  abbr:'腾', color:'#00A4FF', cat:'视频'},
  {id:'iqiyi',   name:'爱奇艺',    abbr:'爱', color:'#00CC36', cat:'视频'},
  {id:'youku',   name:'优酷',      abbr:'优', color:'#1F7BF9', cat:'视频'},
  {id:'mango',   name:'芒果TV',    abbr:'芒', color:'#FF6A00', cat:'视频'},
  {id:'bili',    name:'哔哩哔哩',  abbr:'B', color:'#FB7299', cat:'视频'},
  {id:'meituan', name:'美团',      abbr:'美', color:'#FFD100', cat:'生活'},
  {id:'eleme',   name:'饿了么',    abbr:'饿', color:'#0F9BFF', cat:'生活'},
  {id:'jd',      name:'京东PLUS',  abbr:'京', color:'#E1251B', cat:'电商'},
  {id:'taobao',  name:'淘宝88VIP', abbr:'淘', color:'#FF5000', cat:'电商'},
  {id:'pdd',     name:'拼多多',    abbr:'拼', color:'#E02E24', cat:'电商'},
  {id:'netease', name:'网易云音乐',abbr:'网', color:'#C20C0C', cat:'音乐'},
  {id:'qqmusic', name:'QQ音乐',    abbr:'Q', color:'#31C27C', cat:'音乐'},
  {id:'spotify', name:'Spotify',   abbr:'S', color:'#1DB954', cat:'音乐'},
  {id:'wps',     name:'WPS会员',   abbr:'WP',color:'#E64A19', cat:'工具'},
  {id:'ximalaya',name:'喜马拉雅',  abbr:'喜', color:'#F86442', cat:'音频'},
  {id:'badiu',   name:'百度网盘',  abbr:'度', color:'#2A6AF0', cat:'工具'},
  {id:'icloud',  name:'iCloud+',   abbr:'☁', color:'#4A90E2', cat:'工具'},
  {id:'openai',  name:'ChatGPT',   abbr:'AI',color:'#10A37F', cat:'工具'},
  {id:'claude',  name:'Claude',    abbr:'C', color:'#D97757', cat:'工具'},
  {id:'custom',  name:'自定义',    abbr:'＋', color:'#6c8cff', cat:'其它'},
];

const CATS = {
  '视频':{ico:'🎬', color:'#6c8cff'},
  '生活':{ico:'🍜', color:'#fb923c'},
  '电商':{ico:'🛍️', color:'#f87171'},
  '音乐':{ico:'🎵', color:'#34d399'},
  '音频':{ico:'🎧', color:'#22d3ee'},
  '工具':{ico:'🧰', color:'#a855f7'},
  '其它':{ico:'📦', color:'#9aa3b2'},
};

const CYCLES = {
  monthly:{label:'按月', months:1},
  quarterly:{label:'按季', months:3},
  yearly:{label:'按年', months:12},
};

/* ---------- 状态 ---------- */
const store = {
  key:'mt_memberships_v1',
  data: [],
  load(){
    try{ this.data = JSON.parse(localStorage.getItem(this.key)) || null; }catch(e){ this.data = null; }
    if(!this.data) this.data = seedData();
    return this.data;
  },
  save(){ localStorage.setItem(this.key, JSON.stringify(this.data)); },
  get(id){ return this.data.find(m=>m.id===id); },
  upsert(m){
    const i = this.data.findIndex(x=>x.id===m.id);
    if(i>=0) this.data[i]=m; else this.data.unshift(m);
    this.save();
  },
  remove(id){ this.data = this.data.filter(m=>m.id!==id); this.save(); },
};

/* ---------- 种子数据（首次打开演示） ---------- */
function seedData(){
  const today = new Date();
  const d = (offsetDays)=>{ const x=new Date(today); x.setDate(x.getDate()+offsetDays); return iso(x); };
  return [
    {id:uid(), name:'腾讯视频', abbr:'腾', color:'#00A4FF', cat:'视频', price:25, cycle:'monthly', nextDate:d(3),  method:'微信支付', note:'自动续费，连续包月中', status:'active'},
    {id:uid(), name:'爱奇艺',   abbr:'爱', color:'#00CC36', cat:'视频', price:238,cycle:'yearly',  nextDate:d(46), method:'支付宝',  note:'年卡会员', status:'active'},
    {id:uid(), name:'美团',     abbr:'美', color:'#FFD100', cat:'生活', price:15, cycle:'monthly', nextDate:d(1),  method:'微信支付', note:'外卖红包卡', status:'active'},
    {id:uid(), name:'京东PLUS', abbr:'京', color:'#E1251B', cat:'电商', price:149,cycle:'yearly',  nextDate:d(120),method:'京东支付', note:'含运费券+会员价', status:'active'},
    {id:uid(), name:'网易云音乐',abbr:'网', color:'#C20C0C', cat:'音乐', price:88, cycle:'yearly',  nextDate:d(9),  method:'支付宝',  note:'黑胶VIP年卡', status:'active'},
    {id:uid(), name:'ChatGPT',  abbr:'AI', color:'#10A37F', cat:'工具', price:140,cycle:'monthly', nextDate:d(21), method:'信用卡',  note:'Plus 订阅', status:'active'},
  ];
}

/* ---------- 工具 ---------- */
function uid(){ return Date.now().toString(36)+Math.random().toString(36).slice(2,7); }
function iso(d){ return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`; }
function parseDate(s){ const [y,m,dd]=s.split('-').map(Number); return new Date(y,m-1,dd); }
function daysUntil(s){ const t=new Date(); t.setHours(0,0,0,0); const d=parseDate(s); d.setHours(0,0,0,0); return Math.round((d-t)/86400000); }
function fmtYMD(s){ const d=parseDate(s); return `${d.getMonth()+1}月${d.getDate()}日`; }
function monthlyCost(m){
  if(m.status!=='active') return 0;
  return m.price / CYCLES[m.cycle].months;
}
function totalMonthly(){ return store.data.reduce((s,m)=>s+monthlyCost(m),0); }
function fmtMoney(n){ return n.toFixed(n%1===0?0:2); }
function esc(s){ return String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c])); }

/* ---------- 路由 ---------- */
const state = { tab:'home', filterCat:'全部' };
const screenEl = document.getElementById('screen');

function render(){
  const map = {home:renderHome, list:renderList, stats:renderStats, settings:renderSettings};
  (map[state.tab]||renderHome)();
  // 更新 tab 高亮
  document.querySelectorAll('.tab').forEach(t=>t.classList.toggle('active', t.dataset.tab===state.tab));
  screenEl.scrollTop = screenEl._keep ? screenEl._keep : 0;
  screenEl._keep = 0;
}

/* ---------- 页面：概览 ---------- */
function renderHome(){
  const monthly = totalMonthly();
  const active = store.data.filter(m=>m.status==='active');
  const soon = active.filter(m=>{ const d=daysUntil(m.nextDate); return d>=0 && d<=7; }).sort((a,b)=>daysUntil(a.nextDate)-daysUntil(b.nextDate));
  const yearly = active.filter(m=>m.cycle==='yearly').length;
  const soonest = [...active].sort((a,b)=>daysUntil(a.nextDate)-daysUntil(b.nextDate))[0];

  let html = `
  <div class="page-head">
    <div class="page-title">会员概览</div>
    <div class="page-sub">${active.length} 个在订阅 · 每月自动扣费一目了然</div>
  </div>

  <div class="hero">
    <div class="hero-label">每月订阅支出</div>
    <div class="hero-amount"><span class="cur">¥</span>${fmtMoney(monthly)}<span class="per">/月</span></div>
    <div class="hero-meta">
      <div class="m">折合年费<b>¥${fmtMoney(monthly*12)}</b></div>
      <div class="m">在订阅<b>${active.length} 项</b></div>
    </div>
  </div>

  <div class="quick-row">
    <div class="quick">
      <div class="q-ico" style="background:rgba(251,146,60,.18);color:#fb923c">⏰</div>
      <div class="q-val">${soon.length}</div><div class="q-lab">7天内到期</div>
    </div>
    <div class="quick">
      <div class="q-ico" style="background:rgba(52,211,153,.18);color:#34d399">📅</div>
      <div class="q-val">${yearly}</div><div class="q-lab">年付会员</div>
    </div>
    <div class="quick">
      <div class="q-ico" style="background:rgba(108,140,255,.18);color:#6c8cff">💳</div>
      <div class="q-val">${active.length}</div><div class="q-lab">自动续费</div>
    </div>
  </div>`;

  if(soon.length){
    const f = soon[0];
    const dd = daysUntil(f.nextDate);
    const w = dd<0?'已过期':(dd===0?'今天':(dd===1?'明天':`${dd}天后`));
    html += `
    <div class="alert-strip">
      <div class="a-ico">🔔</div>
      <div class="a-txt">最近一笔：<span>${esc(f.name)}</span> ${w}自动续费 <span>¥${fmtMoney(f.price)}</span>，注意账户余额</div>
    </div>`;
  }

  html += `<div class="sec-title">近期到期 <span class="link" onclick="state.tab='list';render()">全部 ›</span></div>`;
  html += `<div class="card-list">`;
  const upcoming = [...active].sort((a,b)=>daysUntil(a.nextDate)-daysUntil(b.nextDate)).slice(0,5);
  if(upcoming.length===0) html += emptyCard('还没有在订阅的会员','点击下方 ＋ 添加你的第一个会员');
  upcoming.forEach(m=> html += cardHTML(m));
  html += `</div>`;

  screenEl.innerHTML = html;
}

/* ---------- 会员卡片 ---------- */
function cardHTML(m){
  const d = daysUntil(m.nextDate);
  let dueCls='due-ok', dueTxt=fmtYMD(m.nextDate);
  if(m.status==='cancelled'){ dueCls='due-expired'; dueTxt='已取消'; }
  else if(d<0){ dueCls='due-expired'; dueTxt='已过期'; }
  else if(d===0){ dueCls='due-today'; dueTxt='今天到期'; }
  else if(d<=7){ dueCls='due-soon'; dueTxt=`${d}天后 · ${fmtYMD(m.nextDate)}`; }
  else { dueTxt=`${fmtYMD(m.nextDate)} 到期`; }
  const cyc = CYCLES[m.cycle].label;
  const badge = m.status==='cancelled' ? `<span class="badge" style="background:rgba(154,163,178,.2);color:#9aa3b2">已取消</span>` : '';
  return `
  <div class="mcard ${m.status==='cancelled'?'cancelled':''}" onclick="openDetail('${m.id}')">
    <div class="bar" style="background:${m.color}"></div>
    <div class="logo" style="background:linear-gradient(135deg,${m.color},${shade(m.color)})">${esc(m.abbr)}</div>
    <div class="m-main">
      <div class="m-name">${esc(m.name)} ${badge}</div>
      <div class="m-sub">${CATS[m.cat]?CATS[m.cat].ico:''} ${esc(m.cat)} · ${cyc} · ${esc(m.method||'未填')}</div>
    </div>
    <div class="m-right">
      <div class="m-price">¥${fmtMoney(m.price)}</div>
      <div class="m-due ${dueCls}">${dueTxt}</div>
    </div>
  </div>`;
}
function shade(hex){ // 生成同色系更深的颜色用于渐变
  try{
    let c = hex.replace('#',''); if(c.length===3) c=c.split('').map(x=>x+x).join('');
    let r=parseInt(c.slice(0,2),16), g=parseInt(c.slice(2,4),16), b=parseInt(c.slice(4,6),16);
    r=Math.round(r*.62); g=Math.round(g*.62); b=Math.round(b*.62);
    return `rgb(${r},${g},${b})`;
  }catch(e){ return hex; }
}
function emptyCard(t,s){ return `<div class="empty"><div class="e-ico">📭</div><div class="e-t">${t}</div><div class="e-s">${s}</div></div>`; }

/* ---------- 页面：会员列表 ---------- */
function renderList(){
  const cats = ['全部', ...Object.keys(CATS)];
  let html = `
  <div class="page-head"><div class="page-title">我的会员</div>
    <div class="page-sub">共 ${store.data.length} 项 · 点按查看详情</div></div>
  <div class="cat-chips" style="display:flex;gap:8px;overflow-x:auto;padding:14px 18px 4px;scrollbar-width:none">`;
  cats.forEach(c=>{
    const on = state.filterCat===c;
    html += `<button onclick="state.filterCat='${c}';render()" style="flex:0 0 auto;font-family:inherit;font-size:13px;font-weight:700;padding:8px 15px;border-radius:20px;border:1px solid ${on?'var(--accent)':'rgba(255,255,255,.1)'};background:${on?'var(--accent)':'rgba(255,255,255,.05)'};color:${on?'#fff':'var(--txt-2)'};cursor:pointer">${c}</button>`;
  });
  html += `</div><div class="card-list">`;
  let list = store.data;
  if(state.filterCat!=='全部') list = list.filter(m=>m.cat===state.filterCat);
  list = [...list].sort((a,b)=>{
    if(a.status!==b.status) return a.status==='active'?-1:1;
    return daysUntil(a.nextDate)-daysUntil(b.nextDate);
  });
  if(list.length===0) html += emptyCard('这里是空的','换个分类看看，或添加新会员');
  list.forEach(m=> html += cardHTML(m));
  html += `</div>`;
  screenEl._keep = undefined;
  screenEl.innerHTML = html;
}

/* ---------- 页面：统计 ---------- */
function renderStats(){
  const monthly = totalMonthly();
  const active = store.data.filter(m=>m.status==='active');
  // 按分类聚合
  const byCat = {};
  active.forEach(m=>{ byCat[m.cat]=(byCat[m.cat]||0)+monthlyCost(m); });
  const catArr = Object.entries(byCat).sort((a,b)=>b[1]-a[1]);
  const maxCat = catArr.length?catArr[0][1]:1;

  // 近 6 个月柱状（模拟：按当前月度支出推算，年付会员在到期月一次性计入）
  const months=[], now=new Date();
  for(let i=5;i>=0;i--){
    const d=new Date(now.getFullYear(), now.getMonth()-i, 1);
    let cost=0;
    active.forEach(m=>{
      if(m.cycle==='monthly') cost+=m.price;
      else{ const dd=parseDate(m.nextDate); if(dd.getFullYear()===d.getFullYear()&&dd.getMonth()===d.getMonth()) cost+=m.price; }
    });
    months.push({lab:`${d.getMonth()+1}月`, cost});
  }
  const maxM = Math.max(...months.map(x=>x.cost), 1);

  let html = `
  <div class="page-head"><div class="page-title">支出统计</div>
    <div class="page-sub">看清钱都花在了哪些会员上</div></div>
  <div class="stat-hero">
    <div class="sh-lab">月度固定支出</div>
    <div class="sh-num">¥${fmtMoney(monthly)} <small>/ 月</small></div>
    <div style="font-size:13px;color:var(--txt-2);font-weight:600;margin-top:6px">折合全年约 ¥${fmtMoney(monthly*12)}</div>
  </div>
  <div class="sec-title">近 6 个月支出</div>
  <div class="bar-chart">`;
  months.forEach(m=>{
    const h = Math.max(3, Math.round(m.cost/maxM*104));
    html += `<div class="bar-col">
      <div class="bv">${m.cost?fmtMoney(m.cost):'—'}</div>
      <div class="bar" style="height:${h}px" title="¥${fmtMoney(m.cost)}"></div>
      <div class="bl">${m.lab}</div></div>`;
  });
  html += `</div><div class="sec-title">按分类</div><div class="cat-list">`;
  if(catArr.length===0) html += emptyCard('暂无数据','添加会员后自动统计');
  catArr.forEach(([cat,amt])=>{
    const c=CATS[cat]||CATS['其它'];
    html += `
    <div class="cat-row">
      <div class="cat-ico" style="background:${c.color}22;color:${c.color}">${c.ico}</div>
      <div class="cat-info">
        <div style="display:flex;justify-content:space-between;align-items:center">
          <div class="cn">${cat}</div><div class="cat-amt">¥${fmtMoney(amt)}<small style="font-size:11px;color:var(--txt-2);font-weight:600">/月</small></div>
        </div>
        <div class="cat-track"><div class="cat-fill" style="width:${Math.round(amt/maxCat*100)}%;background:${c.color}"></div></div>
      </div>
    </div>`;
  });
  html += `</div>`;
  screenEl.innerHTML = html;
}

/* ---------- 页面：设置 ---------- */
function renderSettings(){
  const active = store.data.filter(m=>m.status==='active').length;
  screenEl.innerHTML = `
  <div class="page-head"><div class="page-title">我的</div></div>
  <div class="profile-head">
    <div class="avatar">会</div>
    <div><div class="pname">我的会员账户</div><div class="pdesc">${active} 个在订阅 · 数据存于本机</div></div>
  </div>
  <div class="set-group">
    <div class="set-item" onclick="toggleNotify()">
      <div class="set-ico" style="background:rgba(251,146,60,.18);color:#fb923c">🔔</div>
      <div class="set-lab">到期提醒</div><div class="set-val" id="notifyState">${notifyLabel()}</div><div class="chev">›</div></div>
    <div class="set-item" onclick="pickNotifyDay()">
      <div class="set-ico" style="background:rgba(251,191,36,.18);color:#fbbf24">⏱️</div>
      <div class="set-lab">提前提醒天数</div><div class="set-val">${settings.notifyDay} 天前</div><div class="chev">›</div></div>
    <div class="set-item" onclick="pickNotifyTime()">
      <div class="set-ico" style="background:rgba(139,92,246,.18);color:#8b5cf6">🕘</div>
      <div class="set-lab">提醒时间</div><div class="set-val">${settings.notifyTime}</div><div class="chev">›</div></div>
    <div class="set-item" onclick="testNotify()">
      <div class="set-ico" style="background:rgba(52,211,153,.18);color:#34d399">🧪</div>
      <div class="set-lab">发送测试提醒</div><div class="chev">›</div></div>
  </div>
  <div class="set-group">
    <div class="set-item" onclick="toast('默认货币：人民币 ¥')">
      <div class="set-ico" style="background:rgba(52,211,153,.18);color:#34d399">💱</div>
      <div class="set-lab">货币单位</div><div class="set-val">¥ 人民币</div><div class="chev">›</div></div>
    <div class="set-item" onclick="toast('已切换为深色主题')">
      <div class="set-ico" style="background:rgba(139,92,246,.18);color:#8b5cf6">🌙</div>
      <div class="set-lab">外观</div><div class="set-val">深色</div><div class="chev">›</div></div>
  </div>
  <div class="set-group">
    <div class="set-item" onclick="installApp()">
      <div class="set-ico" style="background:rgba(108,140,255,.18);color:#6c8cff">📲</div>
      <div class="set-lab">添加到主屏幕</div><div class="set-val" id="installState">${installLabel()}</div><div class="chev">›</div></div>
    <div class="set-item" onclick="exportData()">
      <div class="set-ico" style="background:rgba(108,140,255,.18);color:#6c8cff">⬆️</div>
      <div class="set-lab">导出数据</div><div class="chev">›</div></div>
    <div class="set-item" onclick="importData()">
      <div class="set-ico" style="background:rgba(108,140,255,.18);color:#6c8cff">⬇️</div>
      <div class="set-lab">导入数据</div><div class="chev">›</div></div>
    <div class="set-item" onclick="if(confirm('确定清空所有数据？此操作不可恢复')){store.data=[];store.save();render();toast('已清空')}">
      <div class="set-ico" style="background:rgba(248,113,113,.18);color:#f87171">🗑️</div>
      <div class="set-lab" style="color:#f87171">清空数据</div><div class="chev">›</div></div>
  </div>
  <div style="text-align:center;color:var(--txt-3);font-size:12px;font-weight:600;padding:26px 0 10px">会员管家 v1.1 · PWA + 智能提醒</div>
  `;
}

/* ---------- 详情抽屉 ---------- */
function openDetail(id){
  const m = store.get(id); if(!m) return;
  const d = daysUntil(m.nextDate);
  const cyc = CYCLES[m.cycle].label;
  const perMonth = monthlyCost(m);
  let statusTxt = m.status==='cancelled' ? '<span style="color:var(--txt-3)">已取消</span>'
    : d<0 ? '<span style="color:var(--red)">已过期</span>'
    : d<=7 ? `<span style="color:var(--orange)">${d} 天后到期</span>`
    : `<span style="color:var(--green)">生效中</span>`;

  openSheet(`
    <div class="detail-top">
      <div class="logo" style="background:linear-gradient(135deg,${m.color},${shade(m.color)})">${esc(m.abbr)}</div>
      <div class="dn">${esc(m.name)}</div>
      <div class="ds">${CATS[m.cat]?CATS[m.cat].ico:''} ${esc(m.cat)} · ${statusTxt}</div>
    </div>
    <div class="info-list">
      <div class="info-row"><span class="k">订阅价格</span><span class="v hl">¥${fmtMoney(m.price)} / ${cyc}</span></div>
      <div class="info-row"><span class="k">折合每月</span><span class="v">¥${fmtMoney(perMonth)}</span></div>
      <div class="info-row"><span class="k">下次扣费</span><span class="v">${fmtYMD(m.nextDate)}（${d>=0?d+'天后':'已过期'}）</span></div>
      <div class="info-row"><span class="k">支付方式</span><span class="v">${esc(m.method||'未填写')}</span></div>
      <div class="info-row"><span class="k">订阅周期</span><span class="v">${cyc}</span></div>
      ${m.note?`<div class="info-row"><span class="k">备注</span><span class="v" style="font-weight:600;color:var(--txt-2);max-width:60%">${esc(m.note)}</span></div>`:''}
    </div>
    <div class="form" style="margin-top:22px">
      <button class="btn" onclick="openForm('${m.id}')">编辑信息</button>
      <button class="btn ghost" onclick="toggleStatus('${m.id}')">${m.status==='cancelled'?'恢复订阅':'标记为已取消'}</button>
      <button class="btn danger" onclick="delMembership('${m.id}')">删除该会员</button>
    </div>
  `);
}

/* ---------- 添加/编辑表单 ---------- */
let formState = {};
function openForm(id){
  const m = id ? {...store.get(id)} : {
    id:uid(), name:'', abbr:'', color:'#6c8cff', cat:'视频', price:'', cycle:'monthly',
    nextDate: iso(new Date(Date.now()+30*86400000)), method:'微信支付', note:'', status:'active'
  };
  formState = m;

  const presetGrid = PLATFORMS.map(p=>`
    <div class="preset ${p.id===presetOf(m)?'sel':''}" onclick="pickPreset('${p.id}')">
      <div class="pl" style="background:linear-gradient(135deg,${p.color},${shade(p.color)})">${p.abbr}</div>
      <div class="pn">${p.name}</div>
    </div>`).join('');

  openSheet(`
    <div class="sheet-head"><h3>${id?'编辑会员':'添加会员'}</h3><button class="x" onclick="closeSheet()">✕</button></div>
    <div class="form">
      <div class="field">
        <label>快捷选择平台</label>
        <div class="preset-grid">${presetGrid}</div>
      </div>
      <div class="field"><label>会员名称</label>
        <input id="f_name" value="${esc(m.name)}" placeholder="如：腾讯视频 VIP"></div>
      <div class="row2">
        <div class="field"><label>价格（元）</label>
          <input id="f_price" type="number" inputmode="decimal" value="${m.price}" placeholder="0.00"></div>
        <div class="field"><label>分类</label>
          <select id="f_cat">${Object.keys(CATS).map(c=>`<option ${c===m.cat?'selected':''}>${c}</option>`).join('')}</select></div>
      </div>
      <div class="field"><label>订阅周期</label>
        <div class="seg">
          <button type="button" class="${m.cycle==='monthly'?'on':''}" onclick="setCycle('monthly',this)">按月</button>
          <button type="button" class="${m.cycle==='quarterly'?'on':''}" onclick="setCycle('quarterly',this)">按季</button>
          <button type="button" class="${m.cycle==='yearly'?'on':''}" onclick="setCycle('yearly',this)">按年</button>
        </div>
      </div>
      <div class="field"><label>下次扣费/到期日</label>
        <input id="f_date" type="date" value="${m.nextDate}"></div>
      <div class="field"><label>支付方式</label>
        <select id="f_method">${['微信支付','支付宝','京东支付','信用卡','Apple Pay','其它'].map(x=>`<option ${x===m.method?'selected':''}>${x}</option>`).join('')}</select></div>
      <div class="field"><label>备注</label>
        <textarea id="f_note" placeholder="如：连续包月，自动续费">${esc(m.note||'')}</textarea></div>
      <button class="btn" onclick="saveMembership('${id||''}')">保存</button>
    </div>
  `);
}
function presetOf(m){
  const p = PLATFORMS.find(p=>p.name===m.name || p.abbr===m.abbr);
  return p?p.id:'custom';
}
function pickPreset(pid){
  const p = PLATFORMS.find(x=>x.id===pid); if(!p) return;
  document.querySelectorAll('.preset').forEach(e=>e.classList.remove('sel'));
  event.currentTarget.classList.add('sel');
  if(p.id==='custom'){
    const n = document.getElementById('f_name'); n.value=''; n.focus();
    formState.abbr=''; formState.color='#6c8cff';
  }else{
    document.getElementById('f_name').value = p.name;
    formState.abbr = p.abbr; formState.color = p.color;
    document.getElementById('f_cat').value = p.cat;
  }
}
function setCycle(c, el){
  formState.cycle = c;
  el.parentNode.querySelectorAll('button').forEach(b=>b.classList.remove('on'));
  el.classList.add('on');
}
function saveMembership(id){
  const name = document.getElementById('f_name').value.trim();
  const price = parseFloat(document.getElementById('f_price').value);
  if(!name){ toast('请填写会员名称'); return; }
  if(isNaN(price)||price<0){ toast('请填写有效价格'); return; }
  const prev = id ? store.get(id) : null;
  const m = {
    id: id||formState.id,
    name,
    abbr: formState.abbr || name.slice(0,1),
    color: formState.color || (prev?prev.color:'#6c8cff'),
    cat: document.getElementById('f_cat').value,
    price,
    cycle: formState.cycle || 'monthly',
    nextDate: document.getElementById('f_date').value || iso(new Date()),
    method: document.getElementById('f_method').value,
    note: document.getElementById('f_note').value.trim(),
    status: prev?prev.status:'active',
  };
  store.upsert(m);
  closeSheet(); toast(id?'已保存修改':'已添加会员');
  if(!id) state.tab='home';
  render();
}
function toggleStatus(id){
  const m = store.get(id); if(!m) return;
  m.status = m.status==='cancelled'?'active':'cancelled'; store.save();
  closeSheet(); toast(m.status==='cancelled'?'已标记取消':'已恢复订阅'); render();
}
function delMembership(id){
  if(!confirm('确定删除该会员？')) return;
  store.remove(id); closeSheet(); toast('已删除'); render();
}

/* ---------- 导入导出 ---------- */
function exportData(){
  const blob = new Blob([JSON.stringify(store.data,null,2)],{type:'application/json'});
  const a=document.createElement('a'); a.href=URL.createObjectURL(blob);
  a.download='我的会员数据.json'; a.click(); toast('已导出 JSON');
}
function importData(){
  const inp=document.createElement('input'); inp.type='file'; inp.accept='.json';
  inp.onchange=e=>{
    const f=e.target.files[0]; if(!f) return;
    const r=new FileReader();
    r.onload=()=>{ try{ const d=JSON.parse(r.result); if(Array.isArray(d)){ store.data=d; store.save(); render(); toast('导入成功'); } else toast('文件格式错误'); }catch(err){ toast('解析失败'); } };
    r.readAsText(f);
  };
  inp.click();
}

/* ---------- Sheet / Toast ---------- */
const sheetEl=document.getElementById('sheet'), maskEl=document.getElementById('sheetMask');
function openSheet(html){
  sheetEl.innerHTML = `<div class="sheet-grab"></div>`+html;
  sheetEl.classList.add('open'); maskEl.classList.add('open');
}
function closeSheet(){ sheetEl.classList.remove('open'); maskEl.classList.remove('open'); }
maskEl.addEventListener('click', closeSheet);

let toastTimer;
function toast(msg){
  const t=document.getElementById('toast'); t.textContent=msg; t.classList.add('show');
  clearTimeout(toastTimer); toastTimer=setTimeout(()=>t.classList.remove('show'),1800);
}

/* ---------- Tab 切换 ---------- */
document.getElementById('tabbar').addEventListener('click', e=>{
  const btn=e.target.closest('.tab'); if(!btn) return;
  const tab=btn.dataset.tab;
  if(tab==='add'){ openForm(''); return; }
  state.tab=tab; render();
});

/* ================= 设置 & 提醒配置 ================= */
// 统一引用：window.settings 即配置数据本体
const _settingsStore = {
  key:'mt_settings_v1',
  data: { notify:false, notifyDay:1, notifyTime:'09:00', lastFired:{} },
  load(){
    try{ const s=JSON.parse(localStorage.getItem(this.key)); if(s) this.data={...this.data,...s}; }catch(e){}
    window.settings = this.data;   // 让模板里的 settings.notifyDay 能用
    return this.data;
  },
  save(){ localStorage.setItem(this.key, JSON.stringify(this.data)); },
};
window.settings = _settingsStore.data;

function notifyLabel(){
  if(!('Notification' in window)) return '不支持';
  if(Notification.permission==='granted' && settings.notify) return '已开启';
  if(Notification.permission==='denied') return '已拒绝';
  return '未开启';
}
function installLabel(){
  if(window.matchMedia('(display-mode: standalone)').matches || window.navigator.standalone) return '已安装';
  return isIOS() ? '点按查看方法' : '点按安装';
}
function isIOS(){ return /iPad|iPhone|iPod/.test(navigator.userAgent) || (navigator.platform==='MacIntel' && navigator.maxTouchPoints>1); }

/* ---------- 开关通知 ---------- */
async function toggleNotify(){
  if(!('Notification' in window)){ toast('当前浏览器不支持通知'); return; }
  if(Notification.permission==='granted' && settings.notify){
    settings.notify = false; _settingsStore.save(); toast('已关闭到期提醒');
  }else{
    const perm = await Notification.requestPermission();
    if(perm==='granted'){ settings.notify = true; _settingsStore.save(); toast('已开启到期提醒'); scheduleReminderCheck(); }
    else toast('通知权限被拒绝，请在浏览器设置中开启');
  }
  render();
}
function pickNotifyDay(){
  const opts=[1,2,3,5,7];
  openSheet(`<div class="sheet-head"><h3>提前几天提醒</h3><button class="x" onclick="closeSheet()">✕</button></div>
  <div class="form">${opts.map(d=>`<button class="btn ${settings.notifyDay===d?'':'ghost'}" style="margin-top:0" onclick="settings.notifyDay=${d};_settingsStore.save();closeSheet();render();toast('已设为提前 ${d} 天')">提前 ${d} 天${d===1?'（推荐）':''}</button>`).join('')}</div>`);
}
function pickNotifyTime(){
  const opts=['08:00','09:00','12:00','18:00','20:00','21:00'];
  openSheet(`<div class="sheet-head"><h3>提醒时间</h3><button class="x" onclick="closeSheet()">✕</button></div>
  <div class="form">${opts.map(t=>`<button class="btn ${settings.notifyTime===t?'':'ghost'}" style="margin-top:0" onclick="settings.notifyTime='${t}';_settingsStore.save();closeSheet();render();toast('已设为 ${t}')">${t}</button>`).join('')}</div>`);
}
async function testNotify(){
  if(!('Notification' in window)){ toast('当前浏览器不支持通知'); return; }
  if(Notification.permission!=='granted'){
    const p=await Notification.requestPermission(); if(p!=='granted'){ toast('请先允许通知权限'); return; }
  }
  await showNotification('会员管家 · 测试提醒', '这是一条测试通知。到期前一天会自动提醒你 ✅', 'test');
  toast('已发送测试提醒');
}

/* ---------- 智能到期提醒核心 ---------- */
function dueTargets(){
  // 返回 {members:[...], targetDate: 'YYYY-MM-DD'}，即在 notifyDay 天后到期的会员
  const nd = settings.notifyDay;
  const out=[];
  store.data.filter(m=>m.status==='active').forEach(m=>{
    const d = daysUntil(m.nextDate);
    if(d === nd) out.push(m);
  });
  return out;
}
// 触发通知（前台优先用 Notification，退化为 service worker）
async function showNotification(title, body, tag){
  try{
    if(navigator.serviceWorker && navigator.serviceWorker.controller){
      navigator.serviceWorker.controller.postMessage({type:'SHOW_NOTIFICATION', title, body, tag});
      return true;
    }
  }catch(e){}
  try{ new Notification(title, {body, icon:'./icon-192.png', tag}); return true; }
  catch(e){ return false; }
}
function nowHM(){ const d=new Date(); return `${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}`; }
function todayKey(){ return iso(new Date()); }

async function checkDueAndNotify(force){
  if(!settings.notify || Notification.permission!=='granted') return;
  const nd = settings.notifyDay;
  const targets = store.data.filter(m=>m.status==='active' && daysUntil(m.nextDate)===nd);
  if(targets.length===0) return;
  const day = todayKey();
  const lastFired = settings.lastFired || {};
  // 每天只在设定时间之后提醒一次
  if(!force){
    if(nowHM() < settings.notifyTime) return;
    if(lastFired[day]) return;
  }
  const total = targets.reduce((s,m)=>s+m.price,0);
  const title = `⏰ ${targets.length} 个会员明天到期`;
  const body = targets.map(m=>`${m.name} ¥${fmtMoney(m.price)}`).join('、') + `，合计 ¥${fmtMoney(total)}，注意账户余额`;
  await showNotification(title, body, 'due-'+day);
  lastFired[day]=true; settings.lastFired=lastFired; _settingsStore.save();
  toast('已发送到期提醒');
}
let reminderTimer;
function scheduleReminderCheck(){
  clearInterval(reminderTimer);
  // 每 5 分钟检查一次
  reminderTimer = setInterval(()=>checkDueAndNotify(false), 5*60*1000);
  // 启动时先检查一次
  setTimeout(()=>checkDueAndNotify(false), 2000);
}

/* ---------- 添加到主屏幕 ---------- */
let deferredPrompt=null;
window.addEventListener('beforeinstallprompt', e=>{ e.preventDefault(); deferredPrompt=e; });
async function installApp(){
  if(window.matchMedia('(display-mode: standalone)').matches || window.navigator.standalone){ toast('已经安装到主屏幕了 🎉'); return; }
  if(deferredPrompt){ deferredPrompt.prompt(); const r=await deferredPrompt.userChoice; deferredPrompt=null; toast(r.outcome==='accepted'?'正在安装…':'已取消'); return; }
  // iOS Safari 引导
  if(isIOS()){
    openSheet(`<div class="sheet-head"><h3>添加到主屏幕</h3><button class="x" onclick="closeSheet()">✕</button></div>
    <div style="padding:0 22px 10px;color:var(--txt-2);font-size:15px;line-height:1.9;font-weight:500">
      在 iPhone 上用 <b style="color:var(--txt)">Safari</b> 打开本页：<br>
      1️⃣ 点击底部中间的 <b style="color:var(--accent)">分享按钮</b> ⬆️<br>
      2️⃣ 向下滑动，选择 <b style="color:var(--accent)">「添加到主屏幕」</b> ➕<br>
      3️⃣ 点右上角「添加」<br><br>
      完成后，桌面会出现「会员管家」图标，打开即全屏运行，像原生 App 一样。
    </div>`);
    return;
  }
  toast('请用浏览器菜单里的「安装应用」或「添加到主屏幕」');
}

/* ---------- PWA 注册 ---------- */
async function registerSW(){
  if(!('serviceWorker' in navigator)) return;
  try{
    const reg = await navigator.serviceWorker.register('service-worker.js');
    // 确保 controller 就绪，便于 postMessage 通知
    if(!navigator.serviceWorker.controller) await navigator.serviceWorker.ready;
  }catch(e){ console.warn('SW 注册失败', e); }
}

/* ---------- Hash 路由（PWA shortcuts 用） ---------- */
function applyHash(){
  const h=(location.hash||'').replace('#','');
  if(h==='add'){ setTimeout(()=>openForm(''),100); }
  else if(h==='stats'){ state.tab='stats'; render(); }
}

/* ---------- 状态栏时间 ---------- */
function tickClock(){
  const d=new Date();
  document.getElementById('sbTime').textContent = `${d.getHours()}:${String(d.getMinutes()).padStart(2,'0')}`;
}

/* ---------- 初始化 ---------- */
settings.load();
store.load();
render();
applyHash();
window.addEventListener('hashchange', applyHash);
tickClock(); setInterval(tickClock, 30000);
registerSW();
scheduleReminderCheck();
// 回到前台时补检查一次
document.addEventListener('visibilitychange', ()=>{ if(!document.hidden) checkDueAndNotify(false); });
