# Univention UCS 繁體中文 i18n 翻譯與官方提交 SOP

文件版本：1.0  
適用對象：翻譯人員、測試人員、維護人員、提交 PR 負責人  
目標：建立、測試並提交 UCS Traditional Chinese / zh_TW 翻譯套件  
建議套件名稱：`univention-l10n-zh-tw`  
建議 locale：`zh_TW.UTF-8:UTF-8`  
建議語言名稱：`Traditional Chinese`

> 注意：Univention 官方文件目前說明 UCS 內建 English、German localization，並有 French translation package。繁體中文目前應視為新增語言套件，正式提交前需先向 Univention 確認 package naming、branch target 與是否接受新增 `zh_TW` 官方語言包。

---

## 1. 參考來源

本 SOP 依據以下官方資料整理：

- UCS Developer Reference - Translate UCS
- UCS Developer Reference - Translating a single Debian package
- UCS Developer Reference - Create a translation package for UCS
- UCS Developer Reference - Editing translation files
- Univention Corporate Server GitHub repository
- Univention CONTRIBUTING.md

---

## 2. 角色分工

| 角色 | 工作內容 | 產出 |
|---|---|---|
| Project Owner | 決定翻譯範圍、優先順序、官方溝通策略 | 任務範圍、Bugzilla issue、PR 決策 |
| Translator | 編輯 `.po` 檔案中的 `msgstr` | 已翻譯 `.po` 檔 |
| Reviewer | 檢查翻譯一致性、語意與繁中用語 | review comments / 修正清單 |
| Build Engineer | 建置 `.deb`、處理 build error | 可安裝的 translation package |
| QA Tester | 安裝測試、UMC 介面測試、回報未翻譯字串 | 測試報告 |
| PR Maintainer | 整理 commit、簽 CLA、送 GitHub PR、回應官方 review | GitHub PR |

---

## 3. 交付成果

最終至少要交付以下項目：

```text
univention-l10n-zh-tw/
├── debian/
├── zh_TW/
│   ├── *.po
│   └── ...
├── build-log.txt
├── test-report.md
└── glossary.md
```

必要交付物：

1. `univention-l10n-zh-tw` 或官方確認的套件目錄。
2. 所有已翻譯與已檢查的 `.po` 檔。
3. 可成功建置的 `.deb` package。
4. 安裝與 UMC 登入畫面選語言測試紀錄。
5. 翻譯 glossary。
6. Bugzilla issue 連結。
7. GitHub PR 連結。

---

## 4. 翻譯原則

### 4.1 語言與 locale

使用：

```text
Language: zh_TW
Locale: zh_TW.UTF-8:UTF-8
Language name: Traditional Chinese
```

### 4.2 繁中用語原則

採用台灣繁體中文，避免中國大陸用語。

建議固定用語：

| English | 繁中建議 |
|---|---|
| User | 使用者 |
| Group | 群組 |
| Computer | 電腦 |
| Domain | 網域 |
| Policy | 原則 |
| Module | 模組 |
| Settings | 設定 |
| Service | 服務 |
| Certificate | 憑證 |
| Repository | 軟體庫 |
| Token | 權仗 |
| Address | 位址 |
| Port | 通訊埠 |
| Log | 記錄 |
| Forward | 轉送 |
| Restore | 還原 |
| Macro | 巨集 |
| App Center | App Center |
| Univention Management Console | Univention Management Console |
| UMC | UMC |
| UCS | UCS |

### 4.3 不翻譯項目

以下項目原則上不翻譯：

- 指令名稱，例如 `univention-install`
- 套件名稱，例如 `univention-l10n-dev`
- 設定檔路徑
- API 名稱
- UCR 變數名稱
- LDAP attribute 名稱
- 錯誤代碼
- 產品名稱，例如 UCS、UMC、App Center

### 4.4 Placeholder 規則

看到以下格式必須保留：

```text
%s
%d
%(name)s
{0}
{name}
```

範例：

```po
#, python-format
msgid "The %s will expire in %d days."
msgstr "%s 將在 %d 天後過期。"
```

不得刪除、改名或改錯順序。

### 4.5 fuzzy 規則

`.po` 檔中若有：

```po
#, fuzzy
```

必須人工確認翻譯後移除該行。

正式 build 前不得留下 `fuzzy` entry。

---

## 5. 環境準備

建議使用乾淨 UCS 測試機。

### 5.1 安裝工具

```bash
sudo univention-install univention-l10n-dev dpkg-dev git
```

### 5.2 建立工作目錄

```bash
mkdir -p ~/translation
cd ~/translation
```

### 5.3 取得 UCS 原始碼

```bash
git clone \
  --single-branch \
  --depth 1 \
  --shallow-submodules \
  https://github.com/univention/univention-corporate-server
```

### 5.4 記錄版本資訊

```bash
cd ~/translation/univention-corporate-server
git branch --show-current
git rev-parse HEAD
```

把輸出記錄到 `test-report.md`。

---

## 6. 建立繁中 translation package

### 6.1 先確認官方命名策略

在大量翻譯前，Project Owner 需先開 Univention Bugzilla issue 詢問：

- 是否接受新增 Traditional Chinese / zh_TW translation package。
- package name 要使用 `univention-l10n-zh-tw` 或其他命名。
- PR target branch 要使用哪個 branch。
- 是否有最低翻譯覆蓋率要求。

建議 issue 標題：

```text
Add Traditional Chinese translation package for UCS
```

建議 issue 內容：

```text
I would like to contribute a Traditional Chinese translation package for UCS.

Proposed language code: zh_TW
Proposed locale: zh_TW.UTF-8:UTF-8
Proposed package name: univention-l10n-zh-tw

The package will be generated with univention-ucs-translation-build-package and tested on UCS 5.2.
Please advise the preferred package naming and target branch before I open a pull request.
```

### 6.2 產生 translation package

先在工作環境執行：

```bash
cd ~/translation

univention-ucs-translation-build-package \
  --source ~/translation/univention-corporate-server \
  --languagecode zh_TW \
  --locale zh_TW.UTF-8:UTF-8 \
  --language-name "Traditional Chinese"
```

如果工具產生的套件名稱包含大寫或底線，Build Engineer 需檢查 `debian/control` 與 Debian package naming 是否可成功 build。若 build 失敗，需依官方建議調整 package name，例如改為：

```text
univention-l10n-zh-tw
```

並同步確認：

```text
Source:
Package:
debian/changelog
debian/control
debian/rules
```

---

## 7. 編輯翻譯檔

### 7.1 找到 `.po` 檔

可能路徑如下，實際依工具產出為準：

```bash
find ~/translation -name "*.po" | sort
```

預期會在類似以下目錄：

```text
~/translation/univention-l10n-zh_TW/zh_TW/
```

或：

```text
~/translation/univention-l10n-zh-tw/zh_TW/
```

### 7.2 編輯規則

只改 `msgstr`，不要改 `msgid`。

範例：

```po
msgid "User"
msgstr "使用者"
```

多行字串要維持 `.po` 格式：

```po
msgid ""
"Create a new user account "
"for the selected domain."
msgstr ""
"為選取的網域"
"建立新的使用者帳號。"
```

### 7.3 更新 `.po` header

每個 `.po` 檔開頭建議更新：

```po
msgid ""
msgstr ""
"Project-Id-Version: univention-l10n-zh-tw\n"
"Report-Msgid-Bugs-To: jason@jason.tools\n"
"PO-Revision-Date: 2026-06-21 00:00+0800\n"
"Last-Translator: Jason Cheng <jason@jason.tools>\n"
"Language-Team: Jason Tools <jason@jason.tools>\n"
"Language: zh_TW\n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"
```

### 7.4 檢查 fuzzy

```bash
grep -RIn '^#, fuzzy' .
```

若有輸出，必須回到 `.po` 檔人工確認並移除。

### 7.5 檢查空白翻譯

```bash
grep -RIn 'msgstr ""' . | head -n 50
```

注意：`.po` header 也會出現 `msgstr ""`，不可單純以這個結果判斷錯誤。此步驟只用於抽查未翻譯項目。

---

## 8. 建置 translation package

### 8.1 安裝 build dependency

```bash
cd ~/translation/univention-l10n-zh-tw
sudo apt-get build-dep .
```

如果實際目錄不同，請改成工具產出的目錄。

### 8.2 build

```bash
dpkg-buildpackage -uc -us -b -rfakeroot 2>&1 | tee build-log.txt
```

### 8.3 安裝

```bash
sudo dpkg -i ../univention-l10n-zh-tw_*.deb
```

如果實際 package 檔名不同，請依 `ls ../*.deb` 結果調整。

---

## 9. 測試流程

### 9.1 基本安裝測試

檢查 package 是否安裝：

```bash
dpkg -l | grep univention-l10n
```

檢查 locale：

```bash
locale -a | grep -i zh
```

### 9.2 UMC 登入測試

1. 開啟 UCS UMC login page。
2. 登出再重新進入 login page。
3. 檢查語言選單是否出現 Traditional Chinese 或繁體中文。
4. 選擇繁中登入。
5. 檢查主要選單、模組名稱、按鈕、錯誤訊息是否正常顯示。
6. 未翻譯字串可暫時 fallback English，但需記錄。

### 9.3 優先測試模組

優先檢查：

1. Login page
2. UMC navigation
3. Users
4. Groups
5. Computers
6. DNS
7. DHCP
8. App Center
9. System services
10. Software update
11. Diagnostics
12. Certificates

### 9.4 測試紀錄格式

建立 `test-report.md`：

```markdown
# UCS zh_TW Translation Test Report

## Environment

- UCS version:
- UCS git branch:
- UCS git commit:
- Translation package:
- Test date:
- Tester:

## Build Result

- Build command:
- Build status:
- Package file:

## Installation Result

- Install command:
- Install status:

## UMC Test Result

| Area | Result | Notes |
|---|---|---|
| Login page | PASS/FAIL | |
| Language selector | PASS/FAIL | |
| Navigation | PASS/FAIL | |
| Users module | PASS/FAIL | |
| Groups module | PASS/FAIL | |
| App Center | PASS/FAIL | |
| Diagnostics | PASS/FAIL | |

## Known Issues

| Issue | Severity | File | Note |
|---|---|---|---|

## Screenshots

- login-page-zh-tw.png
- users-module-zh-tw.png
```

---

## 10. 更新 translation package

當 UCS upstream 有更新時：

```bash
cd ~/translation/univention-corporate-server
git pull --rebase
```

接著 merge 新字串：

```bash
univention-ucs-translation-merge \
  ~/translation/univention-corporate-server \
  ~/translation/univention-l10n-zh-tw
```

merge 後重新檢查：

```bash
grep -RIn '^#, fuzzy' ~/translation/univention-l10n-zh-tw
```

再重新 build 與測試。

---

## 11. Git 工作流程

### 11.1 fork upstream repo

PR Maintainer 在 GitHub fork：

```text
https://github.com/univention/univention-corporate-server
```

### 11.2 建立 branch

```bash
git checkout -b bug-12345-add-zh-tw-translation
```

`12345` 替換為 Univention Bugzilla issue number。

### 11.3 加入翻譯套件

把 translation package 放入官方建議的位置。

```bash
git add univention-l10n-zh-tw
```

### 11.4 commit

commit message 必須包含 Bugzilla 編號：

```bash
git commit -m "Bug #12345: Add Traditional Chinese translation package"
```

如官方要求 conventional commit，可改為：

```bash
git commit -m "feat(i18n): Add Traditional Chinese translation package

Bug #12345"
```

---

## 12. 官方提交流程

### 12.1 提交前檢查

提交 PR 前必須確認：

- [ ] Bugzilla issue 已建立。
- [ ] 官方已回覆或至少 issue 內已清楚描述 package naming。
- [ ] CLA 可由負責人簽署。
- [ ] branch target 正確。
- [ ] build 成功。
- [ ] 安裝成功。
- [ ] UMC login 可選 zh_TW。
- [ ] 沒有 `fuzzy` entry。
- [ ] `.po` header 已更新。
- [ ] commit message 包含 `Bug #12345`。
- [ ] PR 描述為英文。
- [ ] 測試報告已附上。

### 12.2 PR 標題

```text
Bug #12345: Add Traditional Chinese translation package
```

### 12.3 PR 內容範本

```markdown
## Summary

This pull request adds a Traditional Chinese translation package for UCS.

- Language: Traditional Chinese
- Language code: zh_TW
- Locale: zh_TW.UTF-8:UTF-8
- Package: univention-l10n-zh-tw

## Bug

Bug #12345

## Testing

- Built the package with dpkg-buildpackage.
- Installed the generated package with dpkg -i.
- Verified that Traditional Chinese is selectable in the UMC login window.
- Verified that untranslated strings fall back to English.
- Checked that no fuzzy entries remain in the translated PO files.

## Notes

Please advise if the package naming or branch target should be adjusted.
```

### 12.4 CLA

Univention 要求外部貢獻者簽署 Contributor License Agreement。  
PR 建立後，通常會觸發數位簽署流程。PR Maintainer 需完成 CLA 後，官方才會繼續 review。

---

## 13. 官方 review 回應原則

回應官方 review 時：

1. 使用英文。
2. 明確回覆每一個 comment。
3. 如果官方要求 rename package，先調整 package metadata，再重新 build。
4. 如果官方要求補測試，更新 `test-report.md`。
5. 如果官方要求拆 commit，依官方建議整理 commit history。
6. 不要 force push 前未確認是否會影響 review，除非官方要求整理 history。

---

## 14. 驗收標準

內部驗收需滿足：

- [ ] package 可成功 build。
- [ ] package 可成功安裝。
- [ ] UMC login language selector 可看到 Traditional Chinese 或繁體中文。
- [ ] 主要 UMC 模組可正常顯示繁中。
- [ ] 未翻譯內容有記錄。
- [ ] `.po` 檔沒有 `fuzzy` entry。
- [ ] placeholder 沒有損壞。
- [ ] glossary 已建立。
- [ ] `test-report.md` 完成。
- [ ] PR 已送出或已準備送出。

---

## 15. 常見問題

### Q1：可以只翻部分字串嗎？

可以。UCS 未翻譯字串會 fallback English。不過提交官方時，若覆蓋率太低，官方可能要求補足重要模組。

### Q2：可以直接把 `.po` 檔丟給官方嗎？

不建議。應該建立可 build、可安裝、可測試的 translation package，並透過 Bugzilla issue 與 GitHub PR 提交。

### Q3：`zh_TW` package name build 失敗怎麼辦？

Debian package naming 可能不接受大寫與底線。若發生 build error，請把 Debian package name 調整為小寫與破折號，例如 `univention-l10n-zh-tw`，但 `.po` header 與 locale 仍使用 `zh_TW` / `zh_TW.UTF-8`。

### Q4：要翻 UCS@school 嗎？

本 SOP 主要針對 UCS。若要涵蓋 UCS@school，需另外確認該 repository 與 translation workflow。

### Q5：官方一定會合併嗎？

不一定。官方 CONTRIBUTING 說明他們會檢查 side effects、文件、安全性、usability、priority 與 release management。因此務必先開 issue 並確認官方接受方向。

---

## 16. 建議執行順序

1. Project Owner 開 Univention Bugzilla issue。
2. Build Engineer 建立 `univention-l10n-zh-tw` 初始套件。
3. Translator 先翻 login / navigation / common strings。
4. Build Engineer 第一次 build。
5. QA Tester 安裝並確認 UMC login 可選繁中。
6. Translator 依優先模組繼續翻譯。
7. Reviewer 做 glossary 與一致性檢查。
8. QA Tester 完成 `test-report.md`。
9. PR Maintainer 整理 commit。
10. PR Maintainer 簽 CLA 並送 GitHub PR。
11. 依官方 review 修改。
12. merge 後記錄 release 版本與維護流程。

---

## 17. 維護週期

建議每次 UCS minor release 或重大更新後執行：

```bash
cd ~/translation/univention-corporate-server
git pull --rebase

univention-ucs-translation-merge \
  ~/translation/univention-corporate-server \
  ~/translation/univention-l10n-zh-tw

grep -RIn '^#, fuzzy' ~/translation/univention-l10n-zh-tw
```

然後重新 build、安裝、測試與更新 PR 或後續 maintenance branch。

---

## 18. 完成定義

此任務完成定義：

- Translation package 已能 build。
- `.deb` 已能安裝。
- UMC 可選 Traditional Chinese。
- 主要模組完成繁中化。
- 測試報告完成。
- Bugzilla issue 已建立。
- GitHub PR 已送出。
- CLA 已完成。
- 官方 review 已回應。
