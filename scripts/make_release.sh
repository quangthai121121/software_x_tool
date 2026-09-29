#!/usr/bin/env bash
# Assemble a clean, self-contained copy of the SR4Rec software (code + docs only, no paper,
# no data/weights/checkpoints/runs) into release/, ready to be pushed as its own git repository.
#
# release/ is generated on demand and is gitignored: never commit it inside this research repo.
# Usage: bash scripts/make_release.sh
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
OUT="release"

rm -rf "$OUT"
mkdir -p "$OUT"

# Directories: copied whole (git-ignored large content such as examples/*/images or *.pth
# weights is never present in a tracked checkout, so a plain copy stays small).
for d in src tests docs scripts examples; do
    cp -R "$d" "$OUT/$d"
done
# The release does not ship its own copy of make_release.sh, nor the scripts that exist only to
# build the SoftwareX paper's tables, figures and Appendix C validation check (they read runs/ and
# write into paper/, which this research repo keeps but the release does not).
rm -f "$OUT/scripts/make_release.sh" "$OUT/scripts/make_paper_assets.py" \
      "$OUT/scripts/make_qualitative_figure.py" "$OUT/scripts/check_sr_fidelity.py"

mkdir -p "$OUT/.github"
cp -R .github/. "$OUT/.github/"

# Top-level project files.
for f in README.md LICENSE CITATION.cff codemeta.json CHANGELOG.md CODE_OF_CONDUCT.md \
         CONTRIBUTING.md DATA_AND_MODEL_LICENSES.md pyproject.toml requirements.lock \
         .gitignore .pre-commit-config.yaml .zenodo.json; do
    cp "$f" "$OUT/$f"
done

# Drop anything that slipped in despite the source folders being clean (macOS junk, caches).
find "$OUT" -name ".DS_Store" -delete
find "$OUT" -name "__pycache__" -type d -prune -exec rm -rf {} +

echo "Wrote a release copy to $OUT/ ($(du -sh "$OUT" | cut -f1))"
echo "Next: cd $OUT && git init && git add -A && git commit -m 'SR4Rec vX.Y.Z' && git remote add origin <url> && git push -u origin main"
