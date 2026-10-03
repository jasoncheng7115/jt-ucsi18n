#!/usr/bin/env python3
"""Append zh_TW displayName to standard UCS portal categories/entries (on the Primary)."""
import subprocess
B = "cn=portals,cn=univention,dc=jason,dc=tools"
cat = {
    "domain-admin": "管理", "local-admin": "管理", "self-service-profile": "使用者設定檔",
    "self-service-password": "密碼", "self-service-new-account": "新增帳號",
}
ent = {
    "umc-domain": "系統與網域設定", "umc-local": "系統設定", "self-service": "變更密碼",
    "univentionblog": "Univention 部落格", "univentionforum": "Univention 論壇 (說明)",
    "univentionfeedback": "意見回饋", "univentionwebsite": "Univention 網站",
    "login-ucs": "登入", "login-saml": "登入 (單一登入)", "root-cert": "根憑證",
    "certificate-revocation": "憑證撤銷清單", "self-service-my-profile": "我的設定檔",
    "self-service-protect-account": "保護您的帳號", "self-service-password-forgotten": "忘記密碼",
    "self-service-service-specific-passwords": "無線區域網路密碼", "self-service-create-account": "建立帳號",
    "self-service-verify-account": "帳號驗證", "self-service-password-change": "變更您的密碼",
}


def go(mod, sub, mapping):
    for cn, zh in mapping.items():
        dn = "cn=%s,cn=%s,%s" % (cn, sub, B)
        val = 'displayName="zh_TW" "%s"' % zh
        r = subprocess.run(["udm", mod, "modify", "--dn", dn, "--append", val],
                           capture_output=True, text=True)
        ok = r.returncode == 0 and "modified" in r.stdout
        print(("OK  " if ok else "ERR ") + cn + " -> " + zh + ("" if ok else " :: " + (r.stderr.strip()[:100])))


go("portals/category", "category", cat)
go("portals/entry", "entry", ent)
