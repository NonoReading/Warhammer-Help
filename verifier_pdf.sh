#!/bin/bash
# Verification avant/apres d un decoupage du PDF (09/10/2026) : pour TOUS les personnages de
# SAVED_CARACTERS\WFRP4, genere le PDF (--pdf), puis range le texte (pdftotext) ET le rendu des pages
# (pdftoppm, PNG 70 dpi : traits et cadres compris, ce que le texte seul ne voit pas).
# Usage : ./verifier_pdf.sh avant   (puis modifier/compiler)   ./verifier_pdf.sh apres
#         diff -r TRAVAIL/VERIF_PDF/avant TRAVAIL/VERIF_PDF/apres && echo IDENTIQUE
cd "$(dirname "$0")" || exit 1
L="${1:?label : avant ou apres}"; OUT="TRAVAIL/VERIF_PDF/$L"
rm -rf "$OUT"; mkdir -p "$OUT"
P=/c/poppler-26.02.0/Library/bin
mapfile -t N < <(for d in SAVED_CARACTERS/WFRP4/*/; do ls "$d"*.xml >/dev/null 2>&1 && basename "$d"; done)
./WarhammerHelp.exe --pdf "${N[@]}"
for n in "${N[@]}"; do
  f=$(ls -t "SAVED_CARACTERS/WFRP4/$n/"*.PDF 2>/dev/null | head -1)
  [ -z "$f" ] && continue
  $P/pdftotext.exe -layout "$f" "$OUT/$n.txt"
  $P/pdftoppm.exe -r 70 -png "$f" "$OUT/$n"
done
echo "${#N[@]} personnages -> $OUT"
