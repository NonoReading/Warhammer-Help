# -*- coding: utf-8 -*-
"""Reduit un livre traduit (BOOK_*_FRANCAIS.Xml) aux seuls libelles traduits.

Regle : un element portant l'attribut language est garde en entier (avec ses enfants, ex.
Label/Text) ; ses ancetres sont gardes avec leurs attributs (id, name...) pour que le
chargeur retrouve a quoi se rattache chaque libelle ; tout le reste (donnees de jeu) est
retire, ainsi que les commentaires. Les feuilles directes de la racine (CODE_BOOK, BOOK,
language, VERSION...) sont gardees.

Usage : python reduire_livre_francais.py DATABASE/WFRP4/BOOK_RULESBOOK_FRANCAIS.Xml
Ecrit le fichier en place (git garde l'ancien) et verifie que les libelles sont identiques.
"""
import sys
from lxml import etree


def libelles(racine):
    """Ensemble (chemin d'ids, balise, langue, texte) de tous les elements a language."""
    res = []
    def chemin(e):
        parts = []
        while e is not None:
            parts.append(e.tag + ':' + (e.get('id') or e.get('name') or ''))
            e = e.getparent()
        return '/'.join(reversed(parts))
    for e in racine.iter():
        if isinstance(e.tag, str) and e.get('language') is not None:
            res.append((chemin(e), e.get('language'), ''.join(e.itertext())))
    return sorted(res)


def a_libelle(e):
    return e.get('language') is not None or any(isinstance(c.tag, str) and a_libelle(c) for c in e)


def reduire(e, racine):
    if e.get('language') is not None:
        return
    for c in list(e):
        if not isinstance(c.tag, str):
            e.remove(c)
        elif c.get('language') is not None or a_libelle(c):
            reduire(c, racine)
        elif not (e is racine and len(c) == 0):
            e.remove(c)


def main(chemin):
    arbre = etree.parse(chemin)
    racine = arbre.getroot()
    avant = libelles(racine)
    reduire(racine, racine)
    for e in racine.iter():
        if isinstance(e.tag, str):
            e.tail = '\n'
            if len(e):
                e.text = '\n'
    apres = libelles(racine)
    assert avant == apres, 'libelles modifies'
    contenu = etree.tostring(racine, encoding='UTF-8').decode('utf-8')
    with open(chemin, 'w', encoding='utf-8', newline='\n') as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n' + contenu)
    print(len(apres), 'libelles conserves')


if __name__ == '__main__':
    main(sys.argv[1])
