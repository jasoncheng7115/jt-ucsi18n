#!/usr/bin/env bash
# Push translated .po to dc2, build .deb, install on BOTH dc2 (replica) and dc1 (primary).
set -e
DC2=root@192.168.1.113   # replica: build host + test
DC1=root@192.168.1.145   # primary
LOCAL="$(cd "$(dirname "$0")/.." && pwd)/univention-l10n-zh-tw"
REMOTE=/root/translation/univention-l10n-zh-tw
DEB=/root/translation/univention-l10n-zh-tw_1.0.0-1_all.deb

echo "== push po + all_targets.mk + debian to dc2 =="
tar czf /tmp/zhtw-po.tgz -C "$LOCAL" zh_TW all_targets.mk debian 2>/dev/null
scp -q /tmp/zhtw-po.tgz "$DC2":/tmp/
ssh "$DC2" "cd $REMOTE && tar xzf /tmp/zhtw-po.tgz 2>/dev/null"

echo "== build on dc2 =="
ssh "$DC2" "cd $REMOTE && rm -f ../univention-l10n-zh-tw_*.deb && dpkg-buildpackage -b -uc -us -d 2>&1 | grep -iE 'dpkg-deb: building|error|returned exit' | tail"

echo "== install on dc2 (replica, force-depends: no umc metapackage) =="
ssh "$DC2" "dpkg -i --force-depends $DEB 2>&1 | tail -2; ucr get ucs/server/languages/zh_TW >/dev/null; locale-gen >/dev/null 2>&1; systemctl restart univention-management-console-server univention-portal-server apache2; echo dc2-done"

echo "== copy .deb to dc1 and install =="
ssh "$DC2" "cat $DEB" | ssh "$DC1" "cat > /tmp/univention-l10n-zh-tw.deb"
ssh "$DC1" "dpkg -i /tmp/univention-l10n-zh-tw.deb 2>&1 | tail -2 || dpkg -i --force-depends /tmp/univention-l10n-zh-tw.deb 2>&1 | tail -2; ucr get ucs/server/languages/zh_TW; locale-gen >/dev/null 2>&1; systemctl restart univention-management-console-server univention-portal-server apache2; echo dc1-done"

echo "== sample counts (dc2) =="
ssh "$DC2" "cnt(){ python3 -c \"import json,sys; d=json.load(open(sys.argv[1])); print(len([k for k in d if not k.startswith(chr(36))]))\" \"\$1\" 2>/dev/null || echo n/a; }; \
 echo udm: \$(cnt /usr/share/univention-management-console-frontend/js/umc/modules/i18n/zh_TW/udm.json); \
 echo appcenter: \$(cnt /usr/share/univention-management-console-frontend/js/umc/modules/i18n/zh_TW/appcenter.json); \
 echo portal: \$(cnt /usr/share/univention-portal/i18n/zh_TW.json)"
