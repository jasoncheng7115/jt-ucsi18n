#!/usr/bin/env python3
"""Apply a {msgid: msgstr} JSON dict to a .po file, preserving structure.

Plural entries: value may be {"0": "...", "1": "..."}.
Context entries: key may be "msgctxt\\u0004msgid"; falls back to plain msgid.
Only fills entries present in the dict; leaves others untouched.
Clears fuzzy on filled entries. Saves with wrapwidth=0.
"""
import json
import subprocess
import sys
import polib

po_path, json_path = sys.argv[1], sys.argv[2]
with open(json_path, encoding="utf-8") as fh:
    tr = json.load(fh)

po = polib.pofile(po_path, wrapwidth=0)
filled = skipped = 0
for e in po:
    if e.obsolete:
        continue
    ckey = f"{e.msgctxt}{e.msgid}" if e.msgctxt else None
    val = tr.get(ckey) if ckey and ckey in tr else tr.get(e.msgid)
    if val is None:
        continue
    if e.msgid_plural:
        if isinstance(val, dict):
            for k, v in val.items():
                e.msgstr_plural[int(k)] = v
        else:  # single string given for a plural -> apply to all indices
            for k in (e.msgstr_plural or {0: "", 1: ""}):
                e.msgstr_plural[k] = val
    else:
        if not isinstance(val, str):
            skipped += 1
            continue
        e.msgstr = val
    if "fuzzy" in e.flags:
        e.flags.remove("fuzzy")
    filled += 1

po.save(po_path)
print(f"filled={filled} skipped={skipped} total={len([e for e in po if not e.obsolete])}")

# validate
r = subprocess.run(["msgfmt", "--check-format", "-o", "/dev/null", po_path],
                   capture_output=True, text=True)
if r.returncode != 0:
    print("MSGFMT ERROR:\n" + r.stderr, file=sys.stderr)
    sys.exit(1)
print("msgfmt OK")
