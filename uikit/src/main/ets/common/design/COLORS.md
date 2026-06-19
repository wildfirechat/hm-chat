# 颜色规范（Color Tokens）

颜色不放在 TS 令牌里，而是继续用 HarmonyOS 资源 `$r('app.color.wf_*')`——
因为资源系统负责**暗色模式**自动切换（`resources/base/element/color.json` +
`resources/dark/element/color.json`）。本文件把 `wf_*` 资源登记为项目唯一色板。

## 用法
```ts
.fontColor($r('app.color.wf_primary_text'))
.backgroundColor($r('app.color.wf_background'))
```
新增颜色时：在 uikit 的 `base` 与 `dark` 两个 color.json 同步加 `wf_*` 项，
**不要**在组件里写死 `#RRGGBB`（除非是与主题无关的固定品牌色，如完成按钮的微信绿 `#07C160`）。

## 语义色板（uikit `wf_*`）
| Token | 用途 |
|---|---|
| `wf_background` | 主背景 / 卡片背景（白） |
| `wf_secondary_background` | 次级背景 |
| `wf_primary_background_color` | 页面底色（浅灰 #EEEEEE） |
| `wf_primary_text` | 主文字 |
| `wf_secondary_text` | 次文字 |
| `wf_tertiary_text` | 辅助 / 占位文字 |
| `wf_divider` | 分割线 |
| `wf_primary` | 主题强调色 |
| `wf_link` | 链接 |
| `wf_danger` | 危险 / 删除 |
| `wf_badge_color` | 未读红点 |
| `wf_item_pressed` | 列表按压态 |
| `wf_sent_bubble_bg` / `wf_received_bubble_bg` | 聊天气泡 |
| `c_gray` | 通用灰（图标等） |

## 待办（去重）
moment_kit / chat 各自的 `color.json` 中与 uikit 语义重复的项（如 moment_kit 的
`text_primary`/`text_secondary`/`divider`/`background`）应逐步统一到 `wf_*`，
减少多套色板。迁移时若改动相关组件，顺手替换为 `wf_*`。
