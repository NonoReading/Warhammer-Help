#!/bin/bash
# Verification avant/apres d une migration (04/10/2026) : photographie, pour TOUS les
# personnages de SAVED_CARACTERS\WFRP4, les valeurs calculees (--dump) et le texte des PDF
# (--pdf + pdftotext). Usage : ./verifier_modificateurs.sh avant   (puis modifier/compiler)
#                              ./verifier_modificateurs.sh apres   puis   diff -r TRAVAIL/VERIF/avant TRAVAIL/VERIF/apres
cd "$(dirname "$0")" || exit 1
L="${1:?label : avant ou apres}"; OUT="TRAVAIL/VERIF/$L"
rm -rf "$OUT"; mkdir -p "$OUT/pdf"
mapfile -t N < <(for d in SAVED_CARACTERS/WFRP4/*/; do ls "$d"*.xml >/dev/null 2>&1 && basename "$d"; done)
./WarhammerHelp.exe --dump "$OUT/dump" "${N[@]}"
./WarhammerHelp.exe --pdf "${N[@]}"
for n in "${N[@]}"; do
  f=$(ls -t "SAVED_CARACTERS/WFRP4/$n/"*.PDF 2>/dev/null | head -1)
  [ -n "$f" ] && /c/poppler-26.02.0/Library/bin/pdftotext.exe -layout "$f" "$OUT/pdf/$n.txt"
done
echo "${#N[@]} personnages -> $OUT"
