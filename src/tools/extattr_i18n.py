#!/usr/bin/env python3
"""Append zh_TW translations to UCS extended-attribute LDAP objects (tab/short/group)."""
import subprocess
B = "cn=custom attributes,cn=univention,dc=jason,dc=tools"
# cn -> (tabName, shortDescription, groupName)  ; None = skip that field
data = {
    "UniventionPasswordSelfServiceEmail": ("密碼復原", "電子郵件地址", None),
    "UniventionPasswordSelfServiceMobile": ("密碼復原", "行動電話號碼", None),
    "UniventionPasswordRecoveryEmailVerified": ("密碼復原", "電子郵件地址已驗證", None),
    "UniventionRegisteredThroughSelfService": ("密碼復原", "自助註冊", None),
    "UniventionDeregisteredThroughSelfService": ("密碼復原", "自助取消註冊", None),
    "UniventionDeregistrationTimestamp": ("密碼復原", "取消註冊時間戳記", None),
    "serviceprovider": ("帳號", "為下列服務提供者啟用此使用者", "SAML 設定"),
    "serviceprovidergroup": ("一般", "為下列服務提供者啟用此群組", "SAML 設定"),
    "ucs-monitoring": ("警報", "已指派的監控警報", None),
    "objectFlag": (None, "Univention 物件旗標", None),
    "lastbind": (None, "上次成功登入的時間戳記", None),
    "portal": ("入口網站", "入口網站", None),
}
fieldmap = {0: "translationTabName", 1: "translationShortDescription", 2: "translationGroupName"}
for cn, vals in data.items():
    dn = "cn=%s,%s" % (cn, B)
    args = ["udm", "settings/extended_attribute", "modify", "--dn", dn]
    for i, v in enumerate(vals):
        if v:
            args += ["--append", '%s="zh_TW" "%s"' % (fieldmap[i], v)]
    r = subprocess.run(args, capture_output=True, text=True)
    ok = r.returncode == 0 and "modified" in r.stdout
    print(("OK  " if ok else "ERR ") + cn + ("" if ok else " :: " + r.stderr.strip()[:120]))
