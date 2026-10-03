#!/usr/bin/env python3
"""Dump untranslated entries of a .po as readable JSON for translation."""
import json
import sys
import polib

po = polib.pofile(sys.argv[1], wrapwidth=0)
out = []
for e in po:
    if e.obsolete:
        continue
    item = {"msgid": e.msgid}
    if e.msgid_plural:
        item["msgid_plural"] = e.msgid_plural
    if e.msgctxt:
        item["msgctxt"] = e.msgctxt
    flags = [f for f in e.flags if "format" in f]
    if flags:
        item["flags"] = flags
    item["translated"] = bool(e.translated())
    out.append(item)
print(json.dumps(out, ensure_ascii=False, indent=1))
