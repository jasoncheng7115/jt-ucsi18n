#!/usr/bin/env python3
"""Normalise PO headers across all generated zh_TW .po files."""
import glob
import os
import sys
import polib

root = sys.argv[1]
n = 0
for path in glob.glob(os.path.join(root, "**", "*.po"), recursive=True):
    po = polib.pofile(path, wrapwidth=0)
    po.metadata["Language"] = "zh_TW"
    po.metadata["Plural-Forms"] = "nplurals=2; plural=(n != 1);"
    po.metadata["PO-Revision-Date"] = "2026-06-21 00:00+0800"
    po.metadata["Last-Translator"] = "Jason Cheng <jason@jason.tools>"
    po.metadata["Language-Team"] = "Jason Tools <jason@jason.tools>"
    po.save(path)
    n += 1
print(f"fixed headers in {n} files")
