#!/usr/bin/env python3
"""Merge a {msgid: msgstr} JSON into a .po, CREATING entries that don't exist.

Use when the generated .po is missing strings that the frontend actually uses
(e.g. the portal po only captured a subset). New entries are appended.
"""
import json
import subprocess
import sys
import polib

po_path, json_path = sys.argv[1], sys.argv[2]
with open(json_path, encoding="utf-8") as fh:
    tr = json.load(fh)

po = polib.pofile(po_path, wrapwidth=0)
existing = {e.msgid: e for e in po if not e.obsolete}
filled = created = 0
for msgid, msgstr in tr.items():
    if not isinstance(msgstr, str):
        continue
    e = existing.get(msgid)
    if e is None:
        po.append(polib.POEntry(msgid=msgid, msgstr=msgstr))
        created += 1
    else:
        e.msgstr = msgstr
        if "fuzzy" in e.flags:
            e.flags.remove("fuzzy")
        filled += 1

po.save(po_path)
print(f"filled={filled} created={created} total={len([e for e in po if not e.obsolete])}")
r = subprocess.run(["msgfmt", "--check-format", "-o", "/dev/null", po_path],
                   capture_output=True, text=True)
print("msgfmt:", "OK" if r.returncode == 0 else r.stderr[:600])
