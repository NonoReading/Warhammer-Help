# Trie a blanc les <Item name="..."> en texte libre des carrieres WFRP5 (n'ecrit RIEN dans les livres).
# Famille : ARGENT / SUIVANT / BIEN / STATUT / MIXTE (a trancher) / COMPOSE (a decouper) / OBJET.
# Pour OBJET, cherche une fiche existante (Description identique) dans les livres WFRP5.
# Usage : python trier_items_texte_v5.py        (ecrit RAPPORT_TRAPPINGS_V5_TRI.txt)
import re, glob, os
from collections import OrderedDict

base = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'DATABASE', 'WFRP5')
fichiers = sorted(glob.glob(os.path.join(base, 'BOOK_*.Xml')))

def norm(s):
    s = re.sub(r'\(.*?\)', '', s.lower())
    return re.sub(r'\s+', ' ', re.sub(r"[^a-z0-9' ]", ' ', s)).strip()

# fiches existantes : Description -> code
fiches = {}
for f in fichiers:
    t = open(f, encoding='utf-8', errors='replace').read()
    for m in re.finditer(r'<(Trapping|Armour|Armor|Weapon|Equipment)\w* id="([^"]+)">(.*?)</\1\w*>', t, re.S):
        d = re.search(r'<Description language="ENGLISH">"([^"]+)"', m.group(3))
        if d:
            fiches.setdefault(norm(d.group(1)), m.group(2))

RX_ARGENT = re.compile(r'^(\d+(d\d+)?\s+(GC|Shillings|Pennies)|(Stolen )?(Jewellery|Goods) worth\b|\d+\s*GC)', re.I)
MOTS = OrderedDict([
    ('STATUT', ['Degree', 'Letter of', 'Papers', 'Seal of', 'Symbol of Rank', 'Calling Card', 'Orders',
                'Badge', 'Chains of Office', 'Respect of', 'Access to a Library', 'None']),
    ('SUIVANT', ['Apprentice', 'Assistant', 'Aide', 'Servant', 'Subordinate', 'Pamphleteer', 'Patron', 'Informer',
                 'Follower', 'Herb Gatherer', 'Herald', 'Bailiff', 'Squire', 'Trusty Second', 'Boathand', 'Minions',
                 'Couriers', 'Fence Contact', 'Tax Collectors', 'Staff', 'Crew', 'Troupe', 'Squad', 'Unit of',
                 'Gang', 'Ring of', 'Band of', 'Outlaw Chiefs', 'Trained Animal', 'Vicious Dog', 'Footman', 'Regiment', 'Religious Order', 'River Runners']),
    ('BIEN', ['Abbey', 'Temple', 'Study', 'Office', 'Lodgings', 'Shop', 'Inn or', 'Townhouse', 'Cottage', 'Hut',
              'Hiding Place', 'Lair', 'Warehouse', 'Estate', 'Fiefdom', 'Province', 'Residence', 'Loft',
              'Printing Press', 'Guild', 'Workshop', 'Library', 'Barge', 'Boat', 'Wagon', 'Coach', 'Fleet',
              'Horses', 'Mews', 'Wardrobe', 'Ship']),
])

def famille(nom):
    if RX_ARGENT.search(nom): return 'ARGENT'
    if 'containing' in nom: return 'COMPOSE'
    ci = [f for f, l in MOTS.items() if any(k.lower() in nom.lower() for k in l)]
    if len(ci) > 1 or ' and Crew' in nom or 'with Servants' in nom or 'Garden' in nom or 'Back Entrance' in nom:
        return 'MIXTE'
    if ' or ' in nom: return 'COMPOSE'
    return ci[0] if ci else 'OBJET'

def quantite(nom):
    m = re.match(r'^(\d+)\s+([A-Za-z].*)$', nom)
    return (int(m.group(1)), m.group(2)) if m else (1, nom)

res = OrderedDict((k, []) for k in ('ARGENT', 'SUIVANT', 'BIEN', 'STATUT', 'MIXTE', 'COMPOSE', 'OBJET_AVEC_FICHE', 'OBJET_SANS_FICHE'))
total = 0
for f in fichiers:
    t = open(f, encoding='utf-8', errors='replace').read()
    for m in re.finditer(r'<Item name="([^"R][^"]*|R[^U][^"]*)">"(\d+)"</Item>', t):
        nom, niv = m.group(1), m.group(2)
        total += 1
        fam = famille(nom)
        if fam == 'OBJET':
            q, n2 = quantite(nom)
            code = fiches.get(norm(n2)) or fiches.get(norm(n2.rstrip('s')))
            fam = 'OBJET_AVEC_FICHE' if code else 'OBJET_SANS_FICHE'
            res[fam].append('%s (niv %s)%s' % (nom, niv, ' -> ' + code if code else ''))
        else:
            res[fam].append('%s (niv %s)' % (nom, niv))

with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'RAPPORT_TRAPPINGS_V5_TRI.txt'), 'w', encoding='utf-8') as o:
    o.write('TRI A BLANC des Item en texte libre WFRP5 : %d lignes\n\n' % total)
    for k, l in res.items():
        o.write('== %s : %d ==\n' % (k, len(l)))
        for x in sorted(set(l)):
            o.write('  %s\n' % x)
        o.write('\n')
print(total, {k: len(v) for k, v in res.items()})
