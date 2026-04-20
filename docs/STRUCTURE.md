# Claude Code 專案資料夾結構說明

本文件說明 `claude-code-folders/` 範例專案的每個檔案與資料夾用途。所有欄位皆以 2026-04 官方文件為準（https://docs.claude.com/en/docs/claude-code）。

---

## 1. 完整結構總覽

```
claude-code-folders/
├── CLAUDE.md                         # 專案主指南（自動載入 context）
├── .gitignore                        # 忽略本地/個人設定
├── .claude/                          # Claude Code 所有設定根目錄
│   ├── settings.json                 # 團隊共享設定（提交 Git）
│   ├── settings.local.json           # 個人本地設定（不提交）
│   ├── agents/
│   │   └── hello-agent.md            # 最小 subagent 範例
│   ├── commands/
│   │   └── hello.md                  # 最小 slash command 範例
│   ├── skills/
│   │   └── greet/
│   │       └── SKILL.md              # 最小 Skill 範例
│   └── hooks/
│       └── session-start.sh          # 最小 Hook 腳本範例
└── docs/
    └── STRUCTURE.md                  # 本文件
```

---

## 2. `CLAUDE.md` — 專案指南

每次在此資料夾啟動 Claude Code，`CLAUDE.md` 會自動載入到 system prompt。

### 常見擺放位置（優先級由高到低）

| 範圍 | 路徑 | 是否提交 Git |
|------|------|------------|
| Project | `./CLAUDE.md` 或 `./.claude/CLAUDE.md` | ✅ 提交 |
| User | `~/.claude/CLAUDE.md` | — |
| Local | `./CLAUDE.local.md` | ❌ gitignore |

### 建議內容

- 專案簡介
- 程式碼慣例（縮排、命名、linter）
- Build／Test 指令
- 架構決策摘要
- 大小控制在 200 行以內，避免吃掉 context

---

## 3. `.claude/settings.json` — 團隊共享設定

此檔案**提交 Git**，整個團隊共用。本範例使用的欄位：

### `permissions`

| 欄位 | 說明 |
|------|------|
| `allow` | 自動允許的工具／指令 |
| `deny` | 一律拒絕（最高優先級） |
| `ask` | 執行前詢問使用者 |

範例語法：
- `"Read"` — 允許 Read 工具（所有用法）
- `"Bash(ls:*)"` — 允許 `ls` 後接任意參數
- `"Bash(git push:*)"` — 搭配 `ask` 用於需要確認的指令

### `env`

注入環境變數至 Claude session，可在 hook 腳本或指令中引用。

### `hooks`

在特定生命週期事件觸發腳本／指令。本範例只示範 `SessionStart`。

常見 hook 事件：

| 事件 | 觸發時機 |
|------|--------|
| `SessionStart` | 啟動／恢復 session（matcher: `startup`、`resume`、`clear`、`compact`） |
| `UserPromptSubmit` | 使用者送出提示前 |
| `PreToolUse` | 工具執行前（可拒絕） |
| `PostToolUse` | 工具執行後 |
| `Stop` | Claude 完成回應 |
| `SessionEnd` | Session 結束 |

### `attribution`

控制 Claude 建立的 git commit / PR 是否附上 Claude 署名。

```json
"attribution": {
  "commit": "",   // commit 訊息附加內容；空字串 = 不加署名
  "pr": ""        // PR 描述附加內容；空字串 = 不加署名
}
```

預設值會加上 `🤖 Generated with Claude Code` 與 `Co-Authored-By: Claude <noreply@anthropic.com>`。本範例設為空字串，示範「完全隱藏 Claude 署名」的寫法。

> ⚠️ 舊欄位 `includeCoAuthoredBy` 已被官方標記為 **Deprecated**，請使用 `attribution`。若兩者同時存在，`attribution` 優先。

---

## 4. `.claude/settings.local.json` — 個人本地設定

**不提交 Git**（已列入 `.gitignore`）。用途：

- 個人偏好覆蓋團隊設定
- 本地測試的 API 金鑰、URL
- 實驗性設定

**優先級高於** `settings.json`，且陣列類欄位（如 `permissions.allow`）會**合併**而非替換。

### 完整設定優先級（高 → 低）

1. Managed（企業部署）
2. Command line flags（`--model` 等）
3. `.claude/settings.local.json`
4. `.claude/settings.json`
5. `~/.claude/settings.json`
6. 內建預設值

**Deny 規則永遠優先**：任一層設定 deny 即拒絕。

---

## 5. `.claude/agents/` — Subagents

每個 subagent 是獨立的 `.md` 檔，用 YAML frontmatter 宣告屬性。

### 本範例：`hello-agent.md`

```yaml
---
name: hello-agent
description: 示範用的問候 subagent，只會回覆一句招呼語。
tools: Read
model: sonnet
---
```

### 常用 frontmatter 欄位

| 欄位 | 用途 |
|------|------|
| `name` | Agent 識別名稱（小寫、連字號） |
| `description` | 說明何時使用此 agent（主 agent 會依此自動選擇） |
| `tools` | 限定可用工具清單 |
| `model` | 指定模型（`sonnet`、`opus`、`haiku` 等） |

### 使用方式

主 Claude 會根據 `description` 自動調用，或使用 `/agents` 查看清單。

---

## 6. `.claude/commands/` — Slash Commands

每個 `.md` 檔就是一個 `/` 指令。本範例建立 `/hello`。

### 本範例：`hello.md`

```yaml
---
description: 示範用的打招呼指令
---

請用繁體中文回覆一句：「Hello from Claude Code！」
```

檔名即指令名稱（`hello.md` → `/hello`）。

---

## 7. `.claude/skills/` — Skills

Skills 是 Claude 在需要時自動載入的「知識封裝」，每個 skill 是一個**資料夾**，內含主檔 `SKILL.md`（可搭配 scripts/、templates/ 等輔助檔案）。

### 本範例：`skills/greet/SKILL.md`

```yaml
---
name: greet
description: 示範用 Skill，收到問候請求時回覆一段友善訊息。當使用者說「問候」「打招呼」「greet」時使用。
---
```

### 關鍵欄位

| 欄位 | 用途 |
|------|------|
| `name` | Skill 名稱 |
| `description` | 何時應該載入此 skill（Claude 依此決定是否使用） |

> 💡 `description` 中寫清楚「觸發詞」是讓 Claude 正確啟用 Skill 的關鍵。

---

## 8. `.claude/hooks/` — Hook 腳本存放處

### 重要觀念

**Hook 的「配置」寫在 `settings.json` 的 `hooks` 欄位**。`hooks/` 資料夾只是放腳本檔案的地方，並非約定路徑——你可以放在任何路徑，`settings.json` 中用絕對路徑或 `$CLAUDE_PROJECT_DIR` 指向。

### 本範例：`session-start.sh`

```bash
#!/usr/bin/env bash
echo "[Hook] Claude Code session started for ${CLAUDE_PROJECT_NAME:-unknown-project}"
```

搭配 `settings.json`：

```json
"hooks": {
  "SessionStart": [
    {
      "matcher": "startup",
      "hooks": [
        { "type": "command", "command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh" }
      ]
    }
  ]
}
```

### Hook 腳本慣例

- 第一行 shebang（`#!/usr/bin/env bash`）
- 從 stdin 讀取 JSON（進階用法）
- exit 0 = 通過；exit 2 = 阻止（blocking error）

---

## 9. 本範例刻意省略的進階項目

教學以「最小可運作」為原則。以下項目確實存在，但未放入此範例，請學員於進階課程再接觸：

| 項目 | 說明 |
|------|------|
| `.claude/rules/` | Path-scoped 規則檔（依檔案路徑自動套用） |
| `.claude/output-styles/` | 自訂 Claude 的輸出風格 |
| `statusLine` | 自訂底部狀態列 |
| MCP servers | 擴充外部工具與資料來源 |
| `apiKeyHelper` | 動態取得 API Key |
| `additionalDirectories` | 允許存取專案外的額外資料夾 |
| 進階 hook 類型 | `http`、`prompt`、`agent` 等非 command 類型 |

---

## 10. 延伸閱讀（官方文件）

- Settings：https://docs.claude.com/en/docs/claude-code/settings
- Permissions：https://docs.claude.com/en/docs/claude-code/permissions
- Subagents：https://docs.claude.com/en/docs/claude-code/sub-agents
- Skills：https://docs.claude.com/en/docs/claude-code/skills
- Hooks：https://docs.claude.com/en/docs/claude-code/hooks
- Memory（CLAUDE.md）：https://docs.claude.com/en/docs/claude-code/memory

---

## 11. 驗證方式

在本資料夾執行：

```bash
# 檢查 JSON 合法
python3 -m json.tool .claude/settings.json
python3 -m json.tool .claude/settings.local.json

# 手動執行 hook 腳本
bash .claude/hooks/session-start.sh

# 啟動 Claude Code 驗證
claude
# 在 Claude 內檢查：
#   /agents     → 應看到 hello-agent
#   /hello      → 應能執行
#   啟動時應出現 hook 輸出
```
