#!/usr/bin/env bash
# Compare a UCS source branch against our zh_TW tree, to extend support to a new UCS version.
#
#   bash src/tools/check_version.sh 5.2-8 > /tmp/missing.json
#
# On dc2: fetches the branch (shallow), generates a fresh translation template with
# univention-ucs-translation-build-package, then reports
#   - install targets that differ from our all_targets.mk (stderr)
#   - msgids of that version missing from our tree, as {po_relpath: {msgid: ""}} (stdout)
# Fill in the msgstr values, then:
#   python3 src/tools/merge_multi.py src/univention-l10n-zh-tw/zh_TW <that json>
#   bash src/tools/build_release.sh <new-pkg-version> <series> <min-pl> <max-pl>
set -euo pipefail
V="${1:?usage: check_version.sh <ucs-branch, e.g. 5.2-8>}"
DC2=root@192.168.1.113
SRC="$(cd "$(dirname "$0")/.." && pwd)"

tar czf - -C "$SRC/univention-l10n-zh-tw" --exclude .DS_Store zh_TW all_targets.mk \
	| ssh "$DC2" "rm -rf /root/translation/cmp && mkdir -p /root/translation/cmp && tar xzf - -C /root/translation/cmp 2>/dev/null"

ssh "$DC2" "V='$V' bash -s" <<'REMOTE'
set -euo pipefail
T=/root/translation
cd $T/univention-corporate-server
git fetch -q --depth 1 origin "refs/heads/$V:refs/remotes/origin/$V"
git worktree prune
if [ -d $T/src/$V ]; then git -C $T/src/$V checkout -q --detach origin/$V; else git worktree add -q --detach $T/src/$V origin/$V; fi
rm -rf $T/gen/$V && mkdir -p $T/gen/$V && cd $T/gen/$V
univention-ucs-translation-build-package -s $T/src/$V -c zh_TW -l zh_TW.UTF-8:UTF-8 -n "Traditional Chinese" >gen.log 2>&1
G=$T/gen/$V/univention-l10n-zh_TW
# monitoring-client de.mo is a known bogus target of the generator (removed from our tree)
diff <(grep DESTDIR $G/all_targets.mk | tr -d ' \t\\' | grep -v 'monitoring-client/udm/de.mo' | sort) \
     <(grep DESTDIR $T/cmp/all_targets.mk | tr -d ' \t\\' | sort) >&2 \
	&& echo "targets: identical to ours" >&2 || echo "targets: DIFFER (< $V, > ours) -> all_targets.mk needs a per-series build" >&2
python3 - "$G/zh_TW" "$T/cmp/zh_TW" <<'EOF'
import json, os, sys
import polib
new, ours = sys.argv[1], sys.argv[2]
out, n = {}, 0
for d, _, fs in os.walk(new):
    for f in fs:
        if not f.endswith(".po"):
            continue
        rel = os.path.relpath(os.path.join(d, f), new)
        mine = os.path.join(ours, rel)
        have = {e.msgid for e in polib.pofile(mine)} if os.path.exists(mine) else None
        if have is None:
            print("NEW PO FILE:", rel, file=sys.stderr)
            have = set()
        miss = [e.msgid for e in polib.pofile(os.path.join(d, f)) if not e.obsolete and e.msgid not in have]
        if miss:
            out[rel] = {m: "" for m in miss}
            n += len(miss)
print("missing msgids: %d in %d files" % (n, len(out)), file=sys.stderr)
print(json.dumps(out, ensure_ascii=False, indent=1))
EOF
REMOTE
