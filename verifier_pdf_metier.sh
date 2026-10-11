#!/bin/bash
# Verification avant/apres d une modification de pdfmetier.pas ou pdfrace.pas (11/10/2026) : genere
# le PDF de TOUTES les carrieres et de TOUTES les races (--pdfmetier), puis range le texte
# (pdftotext) et le rendu (pdftoppm, PNG 70 dpi) de chacun, et retire les PDF de SAVED_CARACTERS.
# Usage : ./verifier_pdf_metier.sh avant   (modifier/compiler)   ./verifier_pdf_metier.sh apres
#         diff -r TRAVAIL/VERIF_PDF_METIER/avant TRAVAIL/VERIF_PDF_METIER/apres && echo IDENTIQUE
cd "$(dirname "$0")" || exit 1
L="${1:?label : avant ou apres}"; OUT="TRAVAIL/VERIF_PDF_METIER/$L"
rm -rf "$OUT"; mkdir -p "$OUT"
P=/c/poppler-26.02.0/Library/bin
V=$(grep -m1 '^VERSION=' INI.TXT | cut -d= -f2 | tr -d '\r '); V=${V:-WFRP4}
D="SAVED_CARACTERS/$V"
mkdir -p TRAVAIL/PDF_TMP; rm -f TRAVAIL/PDF_TMP/*
./WarhammerHelp.exe --pdfmetier
mv "$D"/*.PDF TRAVAIL/PDF_TMP/ 2>/dev/null
n=0
for f in TRAVAIL/PDF_TMP/*.PDF; do
  b=$(basename "$f" .PDF)
  $P/pdftotext.exe -layout "$f" "$OUT/$b.txt"
  $P/pdftoppm.exe -r 70 -png "$f" "$OUT/$b"
  n=$((n+1))
done
echo "$n PDF -> $OUT"
