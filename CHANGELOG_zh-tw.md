# 版本紀錄

本檔記錄本專案所有重要變更。格式沿用
[Keep a Changelog](https://keepachangelog.com/zh-TW/1.1.0/)，版本號即
`univention-l10n-zh-tw` 套件的版本。

> [English version](CHANGELOG.md)

## [1.1.0] — 2026-10-03

**主題：首次獨立社群發佈，一個套件涵蓋 UCS 5.2-3 ~ 5.2-7。**

### Added
- **一行安裝腳本 `install.sh`。** 偵測 UCS 版本，依 `dist/versions.txt`
  選出對應套件，驗證 SHA256 後以 `dpkg -i` 安裝。安裝後留下
  `/usr/local/sbin/jt-ucsi18n`，支援 `status`、`update`、`remove` 指令與
  `--force`、`--no-ldap` 旗標。
- **版本對應表 `dist/versions.txt`** 與預先建好的
  `univention-l10n-zh-tw_1.1.0-1_all.deb`。
- **UCS 5.2-3 ~ 5.2-7 的字串。** 各修補層級之間相異的 62 條訊息 ID 全部
  併入同一份 `.po`，因此單一套件即可涵蓋整個範圍。
- **安裝腳本寫入 LDAP 顯示名稱。** 在 Primary Directory Node 上為入口網站
  分類/項目與 UDM 擴充屬性加上 zh_TW 名稱 (只新增)。
- 發佈工具：`src/tools/check_version.sh`、`src/tools/merge_multi.py`、
  `src/tools/build_release.sh`。

### Changed
- 發佈版套件不再相依 `univention-l10n-dev` (開發用套件，一般系統未安裝)。
- 專案由 `ucs_zhtw` 更名為 `jt-ucsi18n`。

## [1.0.0] — 2026-06-21

**主題：完成初版翻譯並提交 Univention。**

### Added
- UCS 5.2 的繁體中文 (zh_TW) 翻譯套件 `univention-l10n-zh-tw`：117 個
  `.po`、5,786 條字串，約 94% 已翻譯。涵蓋登入頁、入口網站、UMC 框架、
  UDM 操作介面 (使用者、群組、電腦、DNS、DHCP、共用、原則、設定)、
  App Center、Diagnostic、Updater、System Setup、網域加入、連接器、
  自助服務與 REST API。
- 用戶端 JSON 另外安裝一份到 `zh`，因為 UMC 網頁前端只請求主語言子標籤。
- 已提交官方：
  [Bug #59524](https://forge.univention.org/bugzilla/show_bug.cgi?id=59524)。
