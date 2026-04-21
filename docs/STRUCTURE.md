# Claude Code 專案資料夾結構說明

本文件說明 `claude-code-folders/` 範例專案的每個檔案與資料夾用途。所有欄位皆以 2026-04 官方文件為準（https://code.claude.com/docs/en）。

---

## 1. 完整結構總覽

```
claude-code-folders/
├── CLAUDE.md                         # 專案主指南（自動載入 context）
├── .gitignore                        # 忽略本地/個人設定
├── .mcp.json                         # 專案層級 MCP servers 設定
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
│   ├── hooks/
│   │   └── on-stop.sh                # Hook 腳本範例（Stop 事件）
│   └── rules/
│       └── src-convention.md         # Path-scoped rule 範例
├── src/
│   └── .gitkeep                      # 讓 src/**/* rule 有匹配目標
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

範例語法（官方採用 **空格 + `*`** 寫法，不是冒號）：
- `"Read"` — 允許 Read 工具（所有用法）
- `"Bash(ls *)"` — 允許 `ls` 後接任意參數
- `"Bash(git push *)"` — 搭配 `ask` 用於需要確認的指令
- `"Read(./.env)"` — 精確匹配單一檔案
- `"Read(./secrets/**)"` — 匹配目錄下所有檔案

### `env`

注入環境變數至 Claude session，可在 hook 腳本或指令中引用。

### `hooks`

在特定生命週期事件觸發腳本／指令。本範例示範 `Stop`（每次 Claude 回應結束後觸發）。

常見 hook 事件：

| 事件 | 觸發時機 |
|------|--------|
| `SessionStart` | 啟動／恢復 session（matcher: `startup`、`resume`、`clear`、`compact`） |
| `UserPromptSubmit` | 使用者送出提示前 |
| `PreToolUse` | 工具執行前（可拒絕） |
| `PostToolUse` | 工具執行後 |
| `Stop` | Claude 完成回應 |
| `SessionEnd` | Session 結束 |

### `permissions.additionalDirectories`

允許 Claude 存取**專案資料夾外**的其他目錄（用於讀寫檔案）。

```json
"permissions": {
  "additionalDirectories": ["../shared-config/", "/Users/me/snippets"]
}
```

本範例設為 `[]` 空陣列，代表不允許任何專案外目錄。

> ⚠️ 注意：位於 `additionalDirectories` 的資料夾**不會**被掃描為 Claude Code 設定（例如 `../shared-config/.claude/agents/` 不會被載入）。這個欄位只給予「檔案存取」權限，不是「設定發現」。

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

### 本範例：`on-stop.sh`

每次 Claude 回應完成後將時間戳記寫入 log 檔，可在 VS Code 終端機以 `tail -f .claude/hooks/stop.log` 即時觀察。

```bash
#!/usr/bin/env bash
PROJECT="${CLAUDE_PROJECT_NAME:-unknown-project}"
LOG_FILE="$(dirname "$0")/stop.log"

echo "$(date '+%H:%M:%S')  Claude 回應完成 — ${PROJECT}" >> "$LOG_FILE"
```

> **VS Code 注意**：擴充套件模式下 hook 的 stdout 不會顯示在 UI，寫入 log 檔是最通用的做法。

搭配 `settings.json`：

```json
"hooks": {
  "Stop": [
    {
      "matcher": "",
      "hooks": [
        { "type": "command", "command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/on-stop.sh" }
      ]
    }
  ]
}
```

> `matcher: ""` 表示不篩選，每次 Stop 事件都觸發。`SessionStart` 支援 `startup`／`resume` 等 matcher；`Stop` 沒有內建 matcher 值，留空即可。

### Hook 腳本慣例

- 第一行 shebang（`#!/usr/bin/env bash`）
- 從 stdin 讀取 JSON（進階用法）
- exit 0 = 通過；exit 2 = 阻止（blocking error）

---

## 9. `.claude/rules/` — Path-scoped 規則

Rules 是把 `CLAUDE.md` 中的專案指南**拆分成主題檔案**，並可依檔案路徑**條件載入**，避免 `CLAUDE.md` 過長吃掉 context。

### 位置與發現規則

- `.claude/rules/*.md`
- 支援子資料夾（例：`.claude/rules/frontend/react.md` 會被自動發現）

### 載入時機

| frontmatter | 載入時機 |
|-------------|---------|
| 有 `paths:` | 當 Claude 讀取符合 glob 的檔案時才載入 |
| 沒有 `paths:` | Session 啟動時載入（類似 CLAUDE.md） |

### 本範例：`rules/src-convention.md`

```markdown
---
paths:
  - "src/**/*"
---

# src/ 資料夾開發規範

- 每個模組放在獨立檔案中
- 檔名使用 kebab-case
- 對外輸出一律 named export
```

只有當 Claude 讀取 `src/` 底下任一檔案時，這條規則才會進入 context。

### 與 CLAUDE.md 的分工

| 情境 | 建議放哪 |
|------|---------|
| 全專案都適用的慣例 | `CLAUDE.md` |
| 只對特定路徑有效的規則 | `.claude/rules/*.md` 加 `paths:` |
| `CLAUDE.md` 超過 200 行 | 開始拆分到 `rules/` |

> ⚠️ Rules 跟 CLAUDE.md 一樣是「Claude 會讀到的指南」，**不是強制執行的配置**。若要強制行為，改用 `hooks` 或 `permissions`。

---

## 10. `.mcp.json` — 專案級 MCP 設定

**MCP（Model Context Protocol）** 讓 Claude Code 能連接外部工具、資料來源、API。例如 filesystem、GitHub、資料庫連線等。

### 位置（重要）

**專案層級** MCP 設定放在**專案根目錄**的 `.mcp.json`，不是 `.claude/` 裡面。

```
claude-code-folders/
├── .mcp.json              # ← 這裡（根目錄）
└── .claude/
```

### 本範例內容

本範例註冊了 MCP 官方 reference 中的 **time** server，提供「查詢當前時間」與「時區轉換」功能，供學員實際驗證 MCP 是否運作：

```json
{
  "mcpServers": {
    "time": {
      "command": "uvx",
      "args": [
        "mcp-server-time",
        "--local-timezone=Asia/Taipei"
      ]
    }
  }
}
```

> 前置需求：需預先安裝 [`uv`](https://docs.astral.sh/uv/)（提供 `uvx` 指令）。`uvx` 首次啟動時會自動下載 `mcp-server-time`（Python package）。

### 欄位說明

| 欄位 | 用途 |
|-----|------|
| `command` | 啟動 server 的執行檔（此例為 `uvx`） |
| `args` | 傳給 command 的參數陣列 |
| `env`（選填）| 注入 MCP server 行程的環境變數 |
| `type`（選填）| `stdio`（預設）、`http`、`sse` |

### 驗證方式

啟動 `claude` 後：

1. Claude Code 會跳出「是否信任此專案的 MCP servers？」**需手動批准**（安全設計）
2. 執行 `/mcp` 應看到 `time` 為 `connected` 狀態
3. 問 Claude「現在台北時間幾點？」或「把 2026-04-21 15:00 UTC 換成 Asia/Tokyo」，它會自動呼叫 time MCP 的工具

### 移除此範例

若不需要此範例，只要把 `.mcp.json` 改回空殼即可：

```json
{ "mcpServers": {} }
```

之後執行一次 `claude mcp reset-project-choices` 清掉批准記錄。

### 三種 MCP Scope

| Scope | 位置 | 是否提交 Git |
|-------|------|------------|
| Project | `.mcp.json`（專案根） | ✅ 團隊共用 |
| User | `~/.claude.json` | ❌ 個人跨專案 |
| Local | `~/.claude.json`（per-project 區段） | ❌ 個人專屬於此專案 |

### 相關 settings.json 欄位（進階）

- `enableAllProjectMcpServers` — 自動信任 `.mcp.json` 所有 server
- `enabledMcpjsonServers` — 指定信任清單
- `disabledMcpjsonServers` — 指定拒絕清單

本範例未使用這些進階欄位。

---

## 11. 本範例仍刻意省略的進階項目

v2 已涵蓋 rules、MCP、additionalDirectories。以下仍保留於「未涵蓋」清單，留給進階課程：

| 項目 | 說明 |
|------|------|
| `.claude/output-styles/` | 自訂 Claude 的輸出風格 |
| `statusLine` | 自訂底部狀態列 |
| `apiKeyHelper` | 動態取得 API Key |
| 進階 hook 類型 | `http`、`prompt`、`agent` 等非 command 類型 |
| Managed scope | 企業級全機器部署設定 |

---

## 12. 延伸閱讀（官方文件）

- Settings：https://code.claude.com/docs/en/settings
- Permissions：https://code.claude.com/docs/en/permissions
- Subagents：https://code.claude.com/docs/en/sub-agents
- Skills：https://code.claude.com/docs/en/skills
- Hooks：https://code.claude.com/docs/en/hooks
- Memory（CLAUDE.md / rules）：https://code.claude.com/docs/en/memory
- MCP：https://code.claude.com/docs/en/mcp
- `.claude/` 目錄導覽：https://code.claude.com/docs/en/claude-directory

---

## 13. 驗證方式

在本資料夾執行：

```bash
# 1. JSON 合法性（使用 npm 生態工具）
npx -y jsonlint -q .claude/settings.json
npx -y jsonlint -q .claude/settings.local.json
npx -y jsonlint -q .mcp.json

# 2. 手動執行 hook 腳本
bash .claude/hooks/on-stop.sh

# 3. 啟動 Claude Code 驗證
claude
# 在 Claude 內檢查：
#   /memory     → 確認 CLAUDE.md 已載入
#   /agents     → 應看到 hello-agent
#   /hello      → 應能執行
#   /mcp        → 應看到 time server 為 connected（首次需批准信任）
#   每次 Claude 回應結束後應出現 Stop hook 輸出（分隔線 + 回應完成訊息）
#
# 4. Rule 條件載入驗證：
#   請 Claude 讀取 src/ 底下任一檔案
#   再執行 /memory，應看到 src-convention.md 已進入規則列表
```
