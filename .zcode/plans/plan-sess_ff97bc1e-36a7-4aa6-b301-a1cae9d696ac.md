# 浅色模式适配方案

## 总体思路

新建集中的 `Theme.swift`（语义化颜色 token，根据 `ColorScheme` 返回深浅色值），新增 `AppearanceMode` 偏好持久化到 `AppState`，在 `MenuBarController` 注入 `.preferredColorScheme`，在 `SettingsView` 的「通用」section 增加外观 Picker。然后逐个 view 把硬编码的 `Color(white:)` 替换为语义 token。

---

## 1. 新增 `VibeUsage/Utils/Theme.swift` —— 集中颜色 token

定义一个 `Theme` 结构/枚举，提供根据 `ColorScheme` 解析的语义颜色。基于 AGENTS.md 现有样式约定，为浅色模式提供对应值。

```swift
import SwiftUI

enum Theme {
    // 用法: .background(Theme.surface(.body))  或在 View 中 @Environment(\.colorScheme)
    // 简化: 提供静态函数，传入 colorScheme 返回对应色

    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.04) : Color(white: 0.97)
    }
    static func cardBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.09) : Color.white
    }
    static func cardBorder(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.16) : Color(white: 0.85)
    }
    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : Color(white: 0.08)
    }
    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.63) : Color(white: 0.45)
    }
    static func tertiaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.38) : Color(white: 0.62)
    }
    static func subtleText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.5) : Color(white: 0.55)
    }
    static func divider(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.16) : Color(white: 0.85)
    }
    static func buttonBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.12) : Color(white: 0.92)
    }
    static func buttonBorder(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.18) : Color(white: 0.82)
    }
    static func selectedFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.20) : Color(white: 0.80)
    }
    static func hoverFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.10) : Color(white: 0.94)
    }
    static func tooltipBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black : Color(white: 0.12)
    }
    static func tooltipText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : .white
    }
    // 品牌强调色在浅色下保持不变（对比度已足够），无需 token 化
    // 但需要复核白底上的橙/金对比度，必要时微调
}
```

为减少每个 view 都写 `@Environment(\.colorScheme)`，提供一组 SwiftUI View 扩展便利方法（可选），或直接在各 view 加 `@Environment(\.colorScheme) private var colorScheme`。

**简化策略**：考虑到 view 数量多，在 `Theme` 中再提供一组 `Color` 扩展，通过 `@Environment(\.colorScheme)` 在 view 内解析。但 SwiftUI 的 `Color` 是值类型无法访问 environment。所以采用**在每个 view 加 `@Environment(\.colorScheme) private var colorScheme`，调用 `Theme.xxx(colorScheme)`** 的方式。这是最清晰、改动可控的方案。

---

## 2. `AppState.swift` —— 新增外观偏好

仿照 `showInDock`（L188-193）和 `initialize()`（L225-258）的模式：

```swift
// 新增枚举（放 AppState.swift 顶部或单独文件）
enum AppearanceMode: String, CaseIterable {
    case system, light, dark
    var label: String {
        switch self {
        case .system: "跟随系统"
        case .light: "浅色"
        case .dark: "深色"
        }
    }
}

// AppState 中新增（L193 之后）
var appearanceMode: AppearanceMode = .system {
    didSet {
        UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode")
        appearanceModeDidChange?()
    }
}

/// 由 MenuBarController 注入回调，切换时刷新面板 colorScheme
var appearanceModeDidChange: (() -> Void)?

/// 返回 SwiftUI 需要的 ColorScheme（.system → nil 跟随系统）
var effectiveColorScheme: ColorScheme? {
    switch appearanceMode {
    case .system: nil
    case .light: .light
    case .dark: .dark
    }
}

// initialize() 中新增（L229 之后）
self.appearanceMode = AppearanceMode(rawValue: UserDefaults.standard.string(forKey: "appearanceMode") ?? "") ?? .system
```

---

## 3. `MenuBarController.swift` —— 注入 preferredColorScheme

在 `ensurePanel()` L289-294 修改：

```swift
let rootView = AnyView(
    PopoverView()
        .preferredColorScheme(appState.effectiveColorScheme)
        .environment(appState)
        .environmentObject(updaterViewModel)
)
```

并在 init 时注册 `appearanceModeDidChange` 回调，触发面板重新渲染（由于 `appState` 是 `@Observable`，改变 `effectiveColorScheme` 即可驱动刷新；但 `preferredColorScheme` 不会因 `@Observable` 自动重算，需要重建 hosting view 或用一个 `@State` 驱动）。

**更稳妥方案**：在 `MenuBarController` 加 `@Published`/`@Observable` 的 `appearanceMode` 镜像，或直接在 `appState` 上加一个 `@State` 触发器。但最简单的做法是：由于 `appState` 是 `@Observable`，在 `PopoverView` 内部读取 `appState.appearanceMode` 并通过 `.preferredColorScheme` 应用 —— 这样 `@Observable` 变化会自动驱动 SwiftUI 重新求值该 modifier。

**最终采用**：在 `PopoverView` body 末尾加：
```swift
.preferredColorScheme(appState.effectiveColorScheme)
```
这样无需 MenuBarController 改动，`@Observable` 自动驱动。面板 `panel.appearance`（NSAppearance）也需同步设置以确保 AppKit 层（如 Tooltip）外观正确，在 `MenuBarController` 监听变化设置 `panel?.appearance`。

---

## 4. `SettingsView.swift` —— 通用 section 新增外观 Picker

在「通用」section（L143-161）顶部新增：

```swift
Picker("外观", selection: Binding(
    get: { appState.appearanceMode },
    set: { appState.appearanceMode = $0 }
)) {
    ForEach(AppearanceMode.allCases, id: \.self) { mode in
        Text(mode.label).tag(mode)
    }
}
.pickerStyle(.segmented)
```

放在「开机自启动」之前，footer 文案说明「跟随系统时使用系统外观设置」。

---

## 5. 逐 View 替换硬编码颜色

以下文件加 `@Environment(\.colorScheme) private var colorScheme`，并替换 `Color(white:)` / `.white` / `.black` 硬编码为 `Theme.xxx(colorScheme)`：

### 5.1 `PopoverView.swift`（根背景 + 各处）
- L26 `.background(Color(white: 0.04))` → `Theme.background(colorScheme)`
- L37 `.foregroundStyle(.white)` → `Theme.primaryText(colorScheme)`
- L53/213/234/276 `Color(white: 0.16)` divider → `Theme.divider(colorScheme)`
- L68 `Color(white: 0.06)` → `Theme.cardBackground` 的次级变体
- L336/359 按钮 `Color(white: 0.12)` → `Theme.buttonBackground`
- L338/361 边框 `Color(white: 0.18)` → `Theme.buttonBorder`
- L288 标题 `.white` → `Theme.primaryText`
- L393/397/402/406 footer `Color(white: 0.38)` → `Theme.tertiaryText`
- L429/444 按钮 `Color(white: 0.5)` → `Theme.subtleText`
- L489 emptyState `Color(white: 0.3)` → `Theme.tertiaryText`
- L533/534 Skeleton → `Theme.cardBackground` / `Theme.cardBorder`
- 保留 `Color.orange.opacity(0.15)` 等品牌色（浅色下可微调透明度）
- `.ultraThinMaterial`（L479）天然支持浅色，保留

### 5.2 `RateLimitCardView.swift`（卡片 + 进度条）
- L116 卡片背景 → `Theme.cardBackground`
- L119 边框 → `Theme.cardBorder`
- L132 标题 `.white` → `Theme.primaryText`
- L585 tooltip `Color.black` → `Theme.tooltipBackground`
- L613 进度条背景 `Color(white: 0.18)` → hoverFill 或新 token
- 各 `Color(white: 0.38/0.5/0.63)` 文字 → 对应语义 token
- L374/379/382 启用按钮 `.black`/`.white` 反色按钮 → 保持视觉一致（浅色下也是高亮按钮）

### 5.3 `BarChartView.swift`（柱状图 + tooltip）
- L229 卡片背景 → `Theme.cardBackground`
- L233 边框 → `Theme.cardBorder`
- L197 模式按钮 `Color(white: 0.28)` → `Theme.selectedFill`
- L302 `Color.white.opacity(0.9)` 柱体 → 在浅色下需改为深色（白底白柱不可见）→ `Theme.primaryText.opacity(0.9)` 或新 token
- L454 tooltip `Color.black` → `Theme.tooltipBackground`
- L184/278/284 文字 → 语义 token

### 5.4 `DistributionChartsView.swift`（饼图 + 模式按钮）
- L189 卡片背景 → `Theme.cardBackground`
- L191/222 边框 → `Theme.cardBorder`
- L236 模式按钮 → `Theme.selectedFill`
- L141/153/179 文字 → 语义 token
- L58-65 调色板保留（品牌色浅色下 OK）

### 5.5 `FilterTagsView.swift`（筛选 pills + 下拉菜单）
- L135 选中态 `Color(white: 0.20)` → `Theme.selectedFill`
- L184/187 checkbox `.black`/`.white` → 浅色下反转
- L438/441 下拉箭头 `Color.black` → `Theme.primaryText`
- L271 shadow `Color.black.opacity(0.35)` → 保留（阴影浅色下可减弱）
- 各容器背景 `Color(white: 0.06/0.08/0.10)` → `Theme.hoverFill` / `Theme.cardBackground`

### 5.6 `SummaryCardsView.swift`（统计卡）
- L85 卡片背景 → `Theme.cardBackground`
- L89 边框 → `Theme.cardBorder`
- L57 默认 `color: Color = .white` → `Theme.primaryText`
- L68 次级文字 → `Theme.secondaryText`

### 5.7 `SettingsView.swift`
- L25 `Color(white: 0.5)` → `Theme.subtleText`（其余已用语义色，基本无需改）

---

## 6. MenuBarController 面板 appearance 同步

在 `ensurePanel()` 创建面板后及外观切换时，设置 `panel.appearance`：
```swift
panel.appearance = appState.effectiveColorScheme.map { scheme in
    NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
}
```
并订阅 `appState.appearanceModeDidChange` 触发更新（确保 AppKit 层 tooltip 等外观正确）。

---

## 7. AGENTS.md 更新

- 更新 Styling Conventions 表格，注明深/浅色双值
- 在 Architecture 新增「Appearance / Theme」小节，说明 `Theme.swift` token 机制和 `AppearanceMode` 偏好
- 注入点说明移到 PopoverView `.preferredColorScheme`

---

## 不改动的部分
- 菜单栏模板图标（`isTemplate = true` 自动适配）
- `MenuBarController.swift:28` 已用的 `.primary` 语义色
- `SettingsView.swift` 中系统语义色（`.secondary`/`.green`/`.red`）
- 品牌强调色 `Color(red:green:blue:)`（浅色下对比度足够，仅复核橙/金）
- `.ultraThinMaterial` 等系统材质

---

## 验证
- `swift build` 编译通过
- 运行 app，在设置切换「跟随系统/浅色/深色」，确认 popover 立即切换
- 浅色下检查所有卡片、文字、图表、tooltip、按钮可读性
- 深色下确认与改动前视觉一致（回归）

## 影响文件清单
- 新增: `VibeUsage/Utils/Theme.swift`
- 修改: `AppState.swift`、`SettingsView.swift`、`PopoverView.swift`、`RateLimitCardView.swift`、`BarChartView.swift`、`DistributionChartsView.swift`、`FilterTagsView.swift`、`SummaryCardsView.swift`、`MenuBarController.swift`、`AGENTS.md`