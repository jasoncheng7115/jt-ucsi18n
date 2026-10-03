# UCS zh_TW 翻譯詞彙表 (Glossary)

權威來源:`/Users/jasoncheng/Nextcloud/scripts/英翻中準則/zh-TW_翻譯用語對照表.md`(通用台灣繁中規範)。
本檔記錄 **UCS 專案**的關鍵用語決策與不譯項目,供 review 與後續維護一致性參考。

## 核心 UCS 物件 / 角色

| English | zh_TW | 備註 |
|---|---|---|
| User / Group / Computer | 使用者 / 群組 / 電腦 | |
| Domain | 網域 | |
| Policy | 原則 | 非「政策」 |
| Container | 容器 | |
| Share | 共用 | directory share = 目錄共用 |
| Quota | 配額 | |
| Lease | 租約 | lease time = 租約時間 |
| Primary / Backup / Replica / Managed Directory Node | 主要 / 備份 / 複本 / 受管 目錄節點 | UCS 伺服器角色 |
| Distinguished Name (DN) | 辨別名稱 | DN 保留 |
| Extended attribute / option | 擴充屬性 / 擴充選項 | |
| Recycle Bin | 資源回收筒 | |

## 通用技術詞(沿用母表)

Port→通訊埠、Repository→軟體庫、Token→權杖、Session→工作階段、Certificate→憑證、
Address→位址、Subnet→子網路、Gateway→閘道、Interface→介面、Cache→快取、
Repository→軟體庫、Authentication→認證、Validate/Verify→驗證、Override→覆寫、
Default→預設、Settings→設定、Information→資訊、Process→處理程序、Thread→執行緒、
Cluster→叢集、Queue→佇列、Redirect→重新導向、Optimize→最佳化、Refresh→重新整理。

## 標點 (母表 §5)

- 中英數之間留半形空格;半形括號 `( )` 前後留空格。
- 句內標點用**全形**:句號。逗號,頓號、問號?驚嘆號!
- **冒號用半形 + 空格**:`注意: …`、`旗標:`。
- 原文結尾非終止標點時,譯文不加中文標點(短標籤、按鈕、欄位名)。

## 不翻譯 (保留原文)

- 產品 / 元件名:UCS、UMC、App Center、Univention、Univention Management Console、
  Univention Configuration Registry、Univention Directory Manager、Keycloak、Guacamole、
  OX App Suite、opsi。
- 協定 / 技術:LDAP、DNS、DHCP、DDNS、BOOTP、NetBIOS、WINS、TCP/IP、SMB/CIFS、NFS、
  SAML、Kerberos、POSIX、Samba、Active Directory、Nagios、NRPE、Docker、RID、SID、UUID、
  UCR、UDM、ACL、SSL、TLS、IMAP、POP3、SMTP。
- 指令 / 路徑 / 變數 / 檔名 / URL / 範例 email、RADIUS NAS 廠商代碼 (cisco/juniper/…)。
- 佔位符:`%s %d %r %(name)s {0} {name} ${x} %%`、HTML `<b> <br/> <i> <a>`、`\n`。

## 複數 (gettext)

中文無單複數。`msgid_plural` 條目的 `msgstr[0]` 與 `msgstr[1]` 填**同一句**,且其格式參數
(%d 數量)需與 `msgid_plural` 完全相符(gettext --check-format 會驗證)。
