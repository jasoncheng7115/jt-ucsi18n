#!/usr/bin/env python3
"""Globally fix half-width punctuation to full-width when preceded by a CJK / full-width
character, across all zh_TW .po msgstr. Comma/question/exclamation become full-width per
the glossary (§5.2). Colons are intentionally left half-width (§5.4). Placeholders, code
and English-context punctuation are untouched (only punctuation right after CJK changes)."""
import glob
import re
import subprocess
import sys
import polib

root = sys.argv[1]
# CJK ideographs + CJK punctuation + full-width forms (so 」,  etc. also count as "CJK side")
CJK = r'[　-〿㐀-䶿一-鿿豈-﫿！-｠￠-￮]'
rules = [(re.compile(CJK + r','), ','), (re.compile(CJK + r'\?'), '?'), (re.compile(CJK + r'!'), '!')]
full = {',': '，', '?': '？', '!': '！'}


def fix(s):
    if not s:
        return s, 0
    n = 0
    for rx, ch in rules:
        def repl(m):
            nonlocal n
            n += 1
            return m.group(0)[:-1] + full[ch]
        s = rx.sub(repl, s)
    return s, n


total = 0
files = 0
for p in glob.glob(root + "/**/*.po", recursive=True):
    po = polib.pofile(p, wrapwidth=0)
    changed = 0
    for e in po:
        if e.obsolete:
            continue
        if e.msgstr:
            ns, c = fix(e.msgstr)
            if c:
                e.msgstr = ns
                changed += c
        if e.msgstr_plural:
            for k in list(e.msgstr_plural):
                ns, c = fix(e.msgstr_plural[k])
                if c:
                    e.msgstr_plural[k] = ns
                    changed += c
    if changed:
        po.save(p)
        r = subprocess.run(["msgfmt", "--check-format", "-o", "/dev/null", p], capture_output=True, text=True)
        if r.returncode != 0:
            print("MSGFMT FAIL", p, r.stderr[:200])
        total += changed
        files += 1
print(f"fixed {total} punctuation marks across {files} files")
