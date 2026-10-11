# -*- coding: utf-8 -*-
"""Ajoute au Rulebook francais les libelles presents en anglais et absents du francais.
Usage : python ajouter_traductions_manquantes.py <fichier_traductions_trapping> (une ligne par TRAP, dans l'ordre)
Les traductions hors Trapping sont dans AUTRES ci-dessous. Idempotent."""
import sys
from lxml import etree

EN = 'DATABASE/WFRP4/BOOK_RULESBOOK.Xml'
FR = 'DATABASE/WFRP4/BOOK_RULESBOOK_FRANCAIS.Xml'

AUTRES = {
 ('RULES-COMPLANG_MOOT', 'Description'): 'Langue (mootien)',
 ('RULES-COMPSAVOIR_RANALD', 'Description'): 'Savoir (Ranald)',
 ('RULES-T0REG', 'Description'): 'Régénération',
 ('RULES-T0REG', 'Explanation'): "La créature est capable de guérison extraordinaire, pouvant même faire repousser des membres sectionnés.\nAu début de chaque Round, si elle a plus de 0 Blessures, elle régénère 1d10 Blessures. S’il lui reste 0 Blessures, elle régénère une seule Blessure sur un jet de 1d10 de 8+.\nSi elle obtient un 10 pour régénérer, elle régénère aussi entièrement une Blessure critique, perdant tous les malus et États associés.\nToute Blessure critique ou Blessure causée par le Feu ne peut pas être régénérée et doit être notée séparément.",
 ('RULES-T0024/RULES-T0105', 'Description'): 'Claquer le fouet ou Nomade',
 ('RULES-T0080_DECEIVER', 'Description'): 'Invocation (Le Trompeur)',
 ('RULES-T0080_GAMESTER', 'Description'): 'Invocation (Le Joueur)',
 ('RULES-T0080_NIGHTPROWLER', 'Description'): 'Invocation (Le Rôdeur nocturne)',
 ('RULES-T0080_PROTECTOR', 'Description'): 'Invocation (Le Protecteur)',
 ('RULES-T0088_DARK', 'Description'): 'Magie des Arcanes (Magie noire)',
 ('RULES-T0092_FERM', 'Description'): 'Maître artisan (Fermier)',
 ('RULES-T0136_BOURG', 'Description'): 'Savoir-vivre (Citadins)',
 ('RULES-T0136_RANALD', 'Description'): 'Savoir-vivre (Ranaldiens)',
 ('RULES-T0136_TAAL', 'Description'): 'Savoir-vivre (Taal)',
 ('RULES-NATION_EMPIRE', 'Description'): 'Empire',
 ('RULES-ARCAN_11', 'Description'): 'Effrayant',
 ('RULES-ARCAN_11', 'Explanation'): "Vous enveloppant de magie, vous devenez effrayant et intimidant. Vous gagnez Peur 1. Pour chaque +3 DR, vous pouvez augmenter votre valeur de Peur de un.",
}


def chaine(e):
    res = []
    x = e.getparent()
    while x is not None and x.getparent() is not None:
        res.append(x)
        x = x.getparent()
    return list(reversed(res))


def trouve_ou_cree(parent, tag, ident):
    for c in parent:
        if isinstance(c.tag, str) and c.tag == tag and c.get('id') == ident:
            return c
    c = etree.SubElement(parent, tag)
    if ident is not None:
        c.set('id', ident)
    return c


def main(fichier_trap):
    trap = [l.rstrip('\n') for l in open(fichier_trap, encoding='utf-8') if l.strip()]
    en = etree.parse(EN).getroot()
    arbre = etree.parse(FR)
    fr = arbre.getroot()
    ajoutes = 0
    for e in en.iter():
        if not isinstance(e.tag, str) or e.get('language') is None:
            continue
        ancetres = chaine(e)
        if not ancetres:
            continue
        direct = ancetres[-1]
        ident = direct.get('id')
        cle = (ident, e.tag)
        if direct.tag == 'Trapping' and e.tag == 'Description':
            n = int(ident.rsplit('_', 1)[1])
            texte = trap[n - 1]
        elif cle in AUTRES:
            texte = AUTRES[cle]
        else:
            continue
        cur = fr
        for a in ancetres:
            cur = trouve_ou_cree(cur, a.tag, a.get('id'))
        if any(c.tag == e.tag and c.get('language') == 'FRANCAIS' for c in cur):
            continue
        n = etree.SubElement(cur, e.tag)
        n.set('language', 'FRANCAIS')
        n.text = '"' + texte + '"'
        ajoutes += 1
    # libelle d'interface : emplacement d'armure "Any"
    for t in fr.iter('Text'):
        if t.get('name') == 'RULES-ARMOL_ANY':
            break
        if t.get('name') == 'RULES-ARMOL_LEG':
            n = etree.Element('Text')
            n.set('name', 'RULES-ARMOL_ANY')
            n.text = '"Quelconque"'
            t.addnext(n)
            ajoutes += 1
            break
    for e in fr.iter():
        if isinstance(e.tag, str):
            e.tail = '\n'
            if len(e) and not (e.text or '').strip():
                e.text = '\n'
    contenu = etree.tostring(fr, encoding='UTF-8').decode('utf-8')
    with open(FR, 'w', encoding='utf-8', newline='\n') as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n' + contenu)
    print(ajoutes, 'libelles ajoutes')


if __name__ == '__main__':
    main(sys.argv[1])
