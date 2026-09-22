"""Fail if any text file contains Vietnamese letters with diacritics (all software text is English).

Usage: python scripts/check_english.py [paths ...]   (default: the whole repository)
"""

import re
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
# Vietnamese letters decompose (NFD) into a base letter plus combining marks: tone marks (grave,
# acute, hook above, tilde, dot below) and vowel marks (circumflex, breve, horn); plus the letter d
# with stroke. Written as escapes so that this file itself stays free of such letters.
MARKS = re.compile("[\u0300\u0301\u0302\u0303\u0306\u0309\u031b\u0323]|[\u0110\u0111]")


def has_vietnamese(text: str) -> bool:
    return bool(MARKS.search(unicodedata.normalize("NFD", text)))


SUFFIXES = {".py", ".md", ".yaml", ".yml", ".j2", ".txt", ".toml", ".cff", ".json", ".csv", ".tex", ".cfg"}
SKIP = {".git", "runs", ".venv", "build", "dist", "__pycache__", "data"}


def scan(paths):
    found = []
    for base in paths:
        files = [base] if base.is_file() else base.rglob("*")
        for f in files:
            if not f.is_file() or f.suffix.lower() not in SUFFIXES or any(p in SKIP for p in f.relative_to(ROOT).parts[:-1]):
                continue
            for n, line in enumerate(f.read_text(encoding="utf-8", errors="ignore").splitlines(), 1):
                if has_vietnamese(line):
                    found.append(f"{f.relative_to(ROOT)}:{n}: {line.strip()[:80]}")
    return found


if __name__ == "__main__":
    targets = [Path(p).resolve() for p in sys.argv[1:]] or [ROOT]
    hits = scan(targets)
    if hits:
        print("Vietnamese text found (all SR4Rec text must be English):")
        print("\n".join(hits))
        sys.exit(1)
    print("No Vietnamese text found.")
