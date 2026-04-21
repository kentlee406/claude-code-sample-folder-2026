---
paths:
  - "src/**/*"
---

# src/ 資料夾開發規範

當你在編輯 `src/` 底下的檔案時，請遵守：

- 每個模組放在獨立檔案中，不要混合多個職責
- 檔名使用 kebab-case（例：`user-profile.ts`）
- 對外輸出一律使用 named export
- 新增檔案時，同步在 `src/index.ts` 追加匯出

> 此檔案僅在 Claude 讀取 `src/` 底下任一檔案時才會載入。
