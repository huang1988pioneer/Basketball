# 喵萌籃球大作戰

一款使用 Godot 4 製作的可玩 2D 街頭籃球遊戲原型。玩家可切換四名喵星球員，在霓虹屋頂球場迎戰不同模式的 AI 對手，也能啟用本機雙人對戰。

![遊戲畫面](artifacts/basketball-final-game.png)

## 遊戲內容

- WASD／方向鍵移動，Shift 衝刺
- 按住 Space 蓄力，放開後投籃
- 兩分球、三分球、籃板與球權切換
- 抄球、假傳變向與 AI 進攻
- Q／E／R／F 四種必殺技能
- 快速比賽、故事模式、挑戰模式與 Boss 挑戰
- 雙人對戰：P1 使用 WASD／Space／X，P2 使用方向鍵／Enter／/（瀏覽器與 Godot 皆支援）
- 支援滑鼠與觸控操作
- 底部角色卡或 `C` 切換上場角色，角色屬性會影響速度、投籃與抄球成功率
- 完整比分、時間、能量、體力、結算與重賽流程
- 連續命中連段：4 秒內延續命中可累積倍率提示，投失或對手得分會中斷
- 角色圖鑑包含喵白白、喵布布、喵橘橘、喵霸霸與支援角色喵藍藍

## 執行方式

需要 Godot 4.7 或相容的 Godot 4 版本。

```bash
godot --path .
```

也可以在 Godot 編輯器中開啟 `project.godot`，再執行主場景。

## 專案結構

- `scripts/main.gd`：遊戲邏輯、AI、輸入與介面繪製
- `main.tscn`：主場景
- `assets/`：角色、主角群、球場、角色選擇展示、技能展示、透明必殺 VFX、終場獎盃、App icon、啟動畫面與介面生成素材
- `artifacts/basketball-final-game.png`：最新遊戲預覽
- `index.html`、`game.js`、`styles.css`：瀏覽器版可玩原型（載入與 Godot 版共用的生成夜景與角色 PNG，並保留離線向量 fallback）

## 跨平台輸出

最新本機輸出位於 `dist/v1.0.0/`：Windows x86_64 `.exe`、macOS universal `.zip`、Android `.apk`，以及可在 Xcode 開啟的 iOS 專案 `.zip`。`Basketball-v1.0.0-android.apk` 使用本機 debug keystore 簽署，可供裝置測試；`Basketball-v1.0.0-android-unsigned.apk` 保留未簽署版本，正式上架仍需改用自己的 release keystore。iOS 目前輸出 Xcode 專案，需在已接受 Xcode license 並配置 Apple signing 後再封裝 IPA。
