# 会员管家 · Membership Tracker

集中管理腾讯视频、爱奇艺、美团、京东 PLUS 等各类互联网厂商**会员订阅**的应用——看清每月花销、到期时间、哪些在自动续费，避免忘记取消或被偷偷扣费。

本仓库包含 **两套完整实现**：

| | 技术 | 位置 | 状态 |
|---|------|------|------|
| 🌐 **Web / PWA** | 原生 HTML + CSS + JS | 根目录 | ✅ 可直接使用 |
| 📱 **iOS 原生** | SwiftUI + SwiftData | `ios/` | ✅ 源码完整，需 Xcode 编译 |

---

## ✨ 功能

- **概览**：每月订阅总支出（自动折算年费）、7 天内到期提醒、近期到期排序
- **会员列表**：按到期时间智能排序，支持分类筛选（视频/生活/电商/音乐/音频/工具/其它）
- **添加/编辑**：19 个主流平台一键预设（自动填充名称、品牌色、分类），自定义价格、周期、扣费日、支付方式
- **详情**：折合每月成本、扣费倒计时、编辑 / 标记取消 / 删除
- **统计**：月度固定支出、近 6 个月支出柱状图、按分类支出占比
- **🔔 智能到期提醒**：**到期前一天**（可配置 1/2/3/5/7 天）自动提醒，可选提醒时间
- **数据**：本地存储（Web 用 localStorage，iOS 用 SwiftData），支持导出 JSON

---

## 🌐 Web / PWA 版

### 直接运行
双击 `index.html` 用浏览器打开即可。

### 本地服务器（推荐，可手机访问 + 启用 PWA）
```bash
# Windows
双击 启动预览.bat

# 或手动
python -m http.server 8000
```
- 电脑：`http://localhost:8000`
- 手机（同一 WiFi）：`http://你的电脑IP:8000`

### 安装为 App（PWA）
- **iPhone**：用 Safari 打开 → 点分享按钮 → 「添加到主屏幕」→ 桌面生成图标，全屏运行
- **Android**：Chrome 菜单 → 「安装应用」
- **桌面**：Chrome/Edge 地址栏右侧的安装图标

> ⚠️ Service Worker 需要 http/https 环境，`file://` 直接打开无法离线缓存。

### 到期提醒
进入「我的」→ 开启「到期提醒」→ 授权通知权限。设定提前天数与时间后，到期前会自动推送通知。

#### 📱 iPhone 用户必读（重要）

iOS 对网页通知有严格限制，**必须按以下步骤**才能收到到期提醒：

1. 用 **Safari** 打开网页（Chrome 等不行）
2. 点底部 **分享按钮** ⬆️ → **「添加到主屏幕」** ➕ → 点「添加」
3. **从桌面图标**打开（不是从 Safari）
4. 进入「我的 → 到期提醒」开启 → 允许通知

> ⚠️ **iOS 的硬限制**：即使装到主屏幕，当 App **被完全关闭后**，iOS 会冻结网页的定时器，届时无法触发提醒。
> 因此 iPhone 上最可靠的方案是使用本仓库的 **原生 iOS 版（SwiftUI）**——它用系统级本地通知，即使 App 关闭也能准时提醒。
>
> Android 和桌面浏览器无此限制，网页版即可正常后台提醒。

---

## 📱 iOS 原生版（SwiftUI）

### 编译步骤（需 Mac + Xcode 15+）
1. 用 Xcode 打开 `ios/MembershipTracker/MembershipTracker.xcodeproj`
2. 选中 target `MembershipTracker` → **Signing & Capabilities**
3. 把 **Team** 改成你自己的 Apple ID（免费账号即可）
4. 把 **Bundle Identifier** 改成一个唯一的，如 `com.你的名字.membershiptracker`
5. 连接 iPhone，选中设备，按 **⌘R** 运行

> 免费 Apple ID 自签的 App 有 7 天有效期，到期后需重新运行一次。
> 想长期安装可加入 Apple Developer Program（$99/年）。

### 技术栈
- **SwiftUI**：全部界面
- **SwiftData**：本地持久化
- **UserNotifications**：本地到期提醒（`UNCalendarNotificationTrigger`）
- 最低支持 **iOS 17.0**

### 目录
```
ios/MembershipTracker/MembershipTracker/
├── MembershipTrackerApp.swift      # App 入口 + SwiftData 容器
├── Models/
│   ├── Membership.swift            # @Model 数据模型
│   └── PlatformPreset.swift        # 平台预设 + 分类 + 颜色扩展
├── Services/
│   └── NotificationService.swift   # 到期提醒调度核心
└── Views/
    ├── Theme.swift                 # 设计系统
    ├── RootView.swift              # 根视图 + 自定义 TabBar
    ├── HomeView.swift              # 概览
    ├── ListView.swift              # 会员列表
    ├── DetailView.swift            # 详情
    ├── MembershipFormView.swift     # 添加/编辑
    ├── StatsView.swift             # 统计
    └── SettingsView.swift          # 设置（含提醒配置）
```

---

## 🎨 设计

深色玻璃拟态风格，蓝紫渐变主色，每个平台使用品牌色 logo。到期状态用颜色区分：
🟢 正常 · 🟠 7 天内到期 · 🔴 今天到期 · ⚪ 已过期/已取消

---

## ⚠️ 关于「自动同步」

腾讯、爱奇艺、美团等厂商**均不提供面向个人的开放订阅查询 API**，因此无法「登录一次自动拉取全部会员」。本应用采用**手动录入**——这也是 Bobby、Subly 等第三方订阅管理 App 的通用做法。

---

## 🛠 开发工具

`make_icons.py` 用于生成应用图标（需要 Pillow）：
```bash
python make_icons.py
```
