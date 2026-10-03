#!/usr/bin/env bash
# Build the standalone release .deb on dc2 and write dist/ (deb + versions.txt) for install.sh.
#
#   bash src/tools/build_release.sh <pkg-version> [series] [min-patchlevel] [max-patchlevel]
#   bash src/tools/build_release.sh 1.1.0-1 5.2 3 7
#
# Differences from the upstream-PR tree (applied only to the build copy on dc2):
#   - Depends on univention-l10n-dev is dropped (a dev package; unmet on normal systems)
#   - Maintainer is set to the community maintainer
set -euo pipefail
VER="${1:?usage: build_release.sh <pkg-version> [series] [min-pl] [max-pl]}"
SERIES="${2:-5.2}"; MIN="${3:-3}"; MAX="${4:-7}"
DC2=root@192.168.1.113
SRC="$(cd "$(dirname "$0")/.." && pwd)"   # src/
ROOT="$(cd "$SRC/.." && pwd)"               # repo root (dist/ lives here)
REMOTE=/root/translation/release
DEB="univention-l10n-zh-tw_${VER}_all.deb"

echo "== push tree to dc2:$REMOTE =="
tar czf - -C "$SRC" --exclude .DS_Store univention-l10n-zh-tw | ssh "$DC2" "rm -rf $REMOTE && mkdir -p $REMOTE && tar xzf - -C $REMOTE 2>/dev/null"

echo "== patch control/changelog + build =="
ssh "$DC2" "set -e; cd $REMOTE/univention-l10n-zh-tw
sed -i -e '/^ univention-l10n-dev /d' -e 's/^Maintainer:.*/Maintainer: Jason Cheng <jason@jason.tools>/' debian/control
{ printf 'univention-l10n-zh-tw (%s) unstable; urgency=low\n\n  * Community release for UCS %s-%s .. %s-%s (jt-ucsi18n)\n\n -- Jason Cheng <jason@jason.tools>  %s\n\n' '$VER' '$SERIES' '$MIN' '$SERIES' '$MAX' \"\$(date -R)\"; cat debian/changelog; } > debian/changelog.new
mv debian/changelog.new debian/changelog
dpkg-buildpackage -b -uc -us -d >../build.log 2>&1 || { tail -30 ../build.log; exit 1; }
dpkg-deb -I ../$DEB | grep -E 'Version|Depends|Maintainer'"

echo "== fetch deb + write dist/versions.txt =="
mkdir -p "$ROOT/dist"
scp -q "$DC2:$REMOTE/$DEB" "$ROOT/dist/$DEB"
SHA="$(shasum -a 256 "$ROOT/dist/$DEB" | cut -d' ' -f1)"
MAN="$ROOT/dist/versions.txt"
[ -f "$MAN" ] || printf '# jt-ucsi18n version map (read by install.sh)\n# series  min_patchlevel  max_patchlevel  package_version  file  sha256\n' >"$MAN"
# one line per series: replace the existing line for this series
grep -v "^$SERIES " "$MAN" >"$MAN.new" || true
echo "$SERIES $MIN $MAX $VER dist/$DEB $SHA" >>"$MAN.new"
mv "$MAN.new" "$MAN"
cat "$MAN"
