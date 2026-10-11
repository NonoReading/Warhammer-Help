#!/bin/bash
# Test de XmlRetireLivre (06/10/2026) : un livre retire des listes puis reimporte doit redonner
# EXACTEMENT le meme export. Usage : ./verifier_retrait.sh RULES   (code du livre, ou "tous")
# Compare DATABASE_EXPORT apres --export simple et apres --retrait <livre> ; trace dans LOT_RETRAIT.txt.
cd "$(dirname "$0")" || exit 1
CODES=("$@"); [ "$1" = "tous" ] && mapfile -t CODES < <(grep -ho "<CODE_BOOK>\"[A-Z0-9]*\"" DATABASE/WFRP4/BOOK_*.Xml | tr -d '<>"' | sed "s/CODE_BOOK//g;s/\/CODE_BOOK//" | sort -u)
rm -rf TRAVAIL/VERIF/retrait_ref; mkdir -p TRAVAIL/VERIF/retrait_ref
./WarhammerHelp.exe --export
cp -r DATABASE_EXPORT/. TRAVAIL/VERIF/retrait_ref/
for c in "${CODES[@]}"; do
  echo "=== $c"
  ./WarhammerHelp.exe --retrait "$c"
  cat LOT_RETRAIT.txt
  diff -r TRAVAIL/VERIF/retrait_ref DATABASE_EXPORT >/dev/null && echo "EXPORT IDENTIQUE" || { echo "EXPORT DIFFERENT :"; diff -rq TRAVAIL/VERIF/retrait_ref DATABASE_EXPORT | head; }
done
