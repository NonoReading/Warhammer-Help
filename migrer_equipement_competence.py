#!/usr/bin/env python3
"""Equipement de depart des carrieres V4 / V5 : les jokers d'armes (RULES-COMB_BASE_*, ...) deviennent le
code de la competence de combat (RULES-COMP_MELEE__BASIC, ...). Le moteur propose alors toutes les armes de
cette competence (chargearme.pas ArmeDeLaFamille). Les jokers RULES-COMB_* et RULES-PROJ_* (n'importe quelle
arme) ne sont PAS touches ici.

Usage : python migrer_equipement_competence.py            (compte seulement)
        python migrer_equipement_competence.py --ecrire   (modifie les livres)
Ne touche que les balises <Item name="..."> ; remplacement binaire, encodage et fins de ligne conserves.
"""
import glob
import re
import sys

CORRESPONDANCE = {
    b'COMB_BASE_*': b'COMP_MELEE__BASIC',
    b'COMB_CAVAL_*': b'COMP_MELEE__CAVALRY',
    b'COMB_2M_*': b'COMP_MELEE__TWO_HANDED',
    b'COMB_ENTRA_*': b'COMP_RANGED__ENTANGLING',
    b'PROJ_LANC_*': b'COMP_RANGED__THROWING',
    b'PROJ_POUDRE_*': b'COMP_RANGED__BLACKPOWDER',
}
MOTIF_ITEM = re.compile(rb'(<Item name=")([^"]*)(")')
MOTIF_JOKER = re.compile(rb'(?<![A-Z0-9_])(' + b'|'.join(re.escape(k) for k in CORRESPONDANCE) + rb')')


def remplacer_nom(m):
    nom = MOTIF_JOKER.sub(lambda j: CORRESPONDANCE[j.group(1)], m.group(2))
    return m.group(1) + nom + m.group(3)


def main():
    ecrire = '--ecrire' in sys.argv
    total = 0
    for chemin in sorted(glob.glob('DATABASE/WFRP4/*.Xml') + glob.glob('DATABASE/WFRP5/*.Xml')):
        with open(chemin, 'rb') as f:
            donnees = f.read()
        nb = [0]

        def compte(m):
            neuf = remplacer_nom(m)
            if neuf != m.group(0):
                nb[0] += 1
            return neuf

        neuf = MOTIF_ITEM.sub(compte, donnees)
        if nb[0]:
            print(f'{chemin} : {nb[0]} ligne(s)')
            total += nb[0]
            if ecrire:
                with open(chemin, 'wb') as f:
                    f.write(neuf)
    print(f'Total : {total} ligne(s) {"modifiee(s)" if ecrire else "a modifier"}')


if __name__ == '__main__':
    main()
