#!/usr/bin/env python3
"""Merge a {po_relpath: {msgid: msgstr}} JSON into the zh_TW tree, CREATING missing entries.

Used to keep ONE union catalogue that covers several UCS patchlevels: strings
that only exist in another patchlevel (see check_version.sh) are appended to the
matching .po. gettext looks up by msgid, so extra entries are harmless on
versions that don't use them.

  python3 src/tools/merge_multi.py src/univention-l10n-zh-tw/zh_TW src/tr/multiversion.json
"""
import json
import os
import subprocess
import sys
import polib

root, json_path = sys.argv[1], sys.argv[2]
with open(json_path, encoding="utf-8") as fh:
    data = json.load(fh)

bad = 0
for rel, tr in sorted(data.items()):
    po_path = os.path.join(root, rel)
    if not os.path.exists(po_path):
        print("MISSING FILE", rel)
        bad += 1
        continue
    po = polib.pofile(po_path, wrapwidth=0)
    existing = {e.msgid: e for e in po if not e.obsolete}
    filled = created = 0
    for msgid, msgstr in tr.items():
        e = existing.get(msgid)
        if e is None:
            po.append(polib.POEntry(msgid=msgid, msgstr=msgstr))
            created += 1
        elif e.msgstr != msgstr:
            e.msgstr = msgstr
            if "fuzzy" in e.flags:
                e.flags.remove("fuzzy")
            filled += 1
    if filled or created:
        po.save(po_path)
    r = subprocess.run(["msgfmt", "--check-format", "-o", "/dev/null", po_path],
                       capture_output=True, text=True)
    ok = r.returncode == 0
    bad += not ok
    print(f"{'OK ' if ok else 'ERR'} filled={filled} created={created} {rel}" + ("" if ok else "\n" + r.stderr[:600]))
sys.exit(1 if bad else 0)
