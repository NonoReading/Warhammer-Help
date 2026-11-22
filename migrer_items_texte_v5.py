# Migre les <Item name="texte libre"> des carrieres WFRP5 vers des fiches <Trapping> (code a nom + Theme).
# Familles et themes : voir trier_items_texte_v5.py (SUIVANT 1020, BIEN 1021, STATUT 1022, reste 196).
# Idempotent : une fois migres, les Item portent un code RULES-... et ne sont plus touches.
# Usage : python migrer_items_texte_v5.py --essai       (n'ecrit rien)
#         python migrer_items_texte_v5.py --appliquer   (ecrit les livres WFRP5)
import re, glob, os, sys
from xml.sax.saxutils import escape

appliquer = '--appliquer' in sys.argv
base = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'DATABASE', 'WFRP5')
fichiers = sorted(glob.glob(os.path.join(base, 'BOOK_*.Xml')))   # RULESBOOK avant TEMPLE...

THEME = {'SUIVANT': 'RULES-LAB_1020', 'BIEN': 'RULES-LAB_1021', 'STATUT': 'RULES-LAB_1022'}
THEME_DEFAUT = 'RULES-LAB_196'

import importlib.util
spec = importlib.util.spec_from_file_location('tri', os.path.join(os.path.dirname(os.path.abspath(__file__)), 'trier_items_texte_v5.py'))
# on reprend seulement les listes de mots et la regex d'argent (le module ecrit un rapport a l'import : on evite)
src = open(spec.origin, encoding='utf-8').read().split('res = OrderedDict')[0]
ns = {'__file__': spec.origin}
exec(compile(src, spec.origin, 'exec'), ns)
famille, norm, fiches = ns['famille'], ns['norm'], ns['fiches']

FORCE = {'Coach Horn': 'OBJET', 'Shipping Charts': 'OBJET', 'Rod of Office': 'STATUT'}

SPLITS = {   # textes mixtes
    '2 Barges and 4 Wagons': [('2 Barges', 'BIEN'), ('4 Wagons', 'BIEN')],
    'Barge and Crew': [('Barge', 'BIEN'), ('Crew', 'SUIVANT')],
    'Barge and Wrecker Crew': [('Barge', 'BIEN'), ('Wrecker Crew', 'SUIVANT')],
    'Patrol Boats and Crew': [('Patrol Boats', 'BIEN'), ('Crew', 'SUIVANT')],
    'Sailing Ship and Crew': [('Sailing Ship', 'BIEN'), ('Crew', 'SUIVANT')],
    'Coach and Footman': [('Coach', 'BIEN'), ('Footman', 'SUIVANT')],
    'Large Townhouse with Gardens and Servants': [('Large Townhouse with Gardens', 'BIEN'), ('Servants', 'SUIVANT')],
    'Townhouse with Servants': [('Townhouse', 'BIEN'), ('Servants', 'SUIVANT')],
    'Office and Staff': [('Office', 'BIEN'), ('Staff', 'SUIVANT')],
    'Townhouse with Discreet Back Entrance': [('Townhouse with Discreet Back Entrance', 'BIEN')],
    "'Fiefdom' of Outlaw Chiefs": [("'Fiefdom' of Outlaw Chiefs", 'SUIVANT')],
    'Boathand': [('Boathand', 'SUIVANT')],
    'Chains of Office': [('Chains of Office', 'STATUT')],
    'Seal of Office': [('Seal of Office', 'STATUT')],
    'Access to a Library': [('Access to a Library', 'STATUT')],
}

def code_de(nom):
    s = re.sub(r"[^A-Z0-9]+", '_', nom.upper().replace("'", '')).strip('_')
    return 'RULES-TRAP_' + s

def singulier(m):
    if m.endswith('ies'): return m[:-3] + 'y'
    if m.endswith('s') and not m.endswith('ss'): return m[:-1]
    return m

def morceau(nom, fam=None):
    """Un morceau simple -> (code, quantite, famille, description)."""
    mq = re.match(r'^(\d+)\s+([A-Za-z].*)$', nom)
    q = ''
    if mq and not re.match(r'^\d+d\d+', nom):
        q, nom = mq.group(1), mq.group(2)
        # singulier du dernier mot : Apprentices -> Apprentice, Warehouses -> Warehouse
        mots = nom.split(' ')
        if mots[-1].endswith('ses') or mots[-1].endswith('ies'):
            mots[-1] = mots[-1][:-1] if mots[-1].endswith('ses') else mots[-1][:-3] + 'y'
        elif mots[-1].endswith('s') and not mots[-1].endswith('ss'):
            mots[-1] = mots[-1][:-1]
        nom = ' '.join(mots)
    return nom, q

def traiter(nom):
    """Retourne une liste [(code, quantite, famille, description)] pour un texte libre."""
    fam = FORCE.get(nom) or famille(nom)
    if nom == 'None':
        return []
    if nom in SPLITS:
        out = []
        for n, f in SPLITS[nom]:
            n2, q = morceau(n)
            out.append((code_de(n2), q, f, n2))
        return out
    if fam == 'ARGENT':
        m = re.match(r'^(\d+)\s+(GC|Shillings)$', nom)
        if m:
            u = 'GC' if m.group(2) == 'GC' else 'SB'
            return [('RULES-TRAP_MONEY_' + u, m.group(1), 'ARGENT', 'Gold Crowns' if u == 'GC' else 'Silver Shillings')]
        # quantite = entier seulement (regle du moteur) : montant avec des / unite = une fiche par texte
        return [(code_de(nom), '', 'ARGENT', nom)]
    if fam == 'COMPOSE':
        if nom.startswith('Sling Bag containing '):
            out = [(code_de('Sling Bag'), '', 'OBJET', 'Sling Bag')]
            for part in nom[len('Sling Bag containing '):].split(' and '):
                mq = re.match(r'^(\d+d?\d*)\s+(different sets of )?(.*)$', part)
                q, p = (mq.group(1), mq.group(3)) if mq else ('', part)
                if q and not q.isdigit():          # « 1d10 Bandages » : pas de quantite entiere
                    q, p = '', part
                out.append((code_de(p), q, 'OBJET', p))
            return out
        if '(' in nom and ' or ' in nom.split('(')[1]:      # « Assistant (Student or Servant) » : un seul suivant
            return [(code_de(nom), '', 'SUIVANT', nom)]
        alts = [morceau(a.strip()) for a in nom.split(' or ')]
        fams = [famille(n) for n, q in alts]
        f0 = next((f for f in fams if f != 'OBJET'), 'OBJET')
        return [('/'.join(code_de(n) for n, q in alts), '', f0, ' / '.join(n for n, q in alts))]
    n2, q = morceau(nom)
    return [(code_de(n2), q, fam if fam != 'OBJET' else 'OBJET', n2)]

existants = set()
for f in fichiers:
    t = open(f, encoding='utf-8', errors='replace').read()
    existants.update(re.findall(r'<Trapping id="([^"]+)"', t))
    existants.update(re.findall(r'<Armor id="([^"]+)"', t))
    existants.update(re.findall(r'<Weapon id="([^"]+)"', t))

nouvelles = {}   # code -> (famille, description, fichier)
n_lignes = 0
contenus = {}
for f in fichiers:
    t = open(f, encoding='utf-8', newline='').read()
    def remplace(m):
        global n_lignes
        nom, niv = m.group(1), m.group(2)
        n_lignes += 1
        morceaux = traiter(nom)
        lignes = []
        for code, q, fam, desc in morceaux:
            for c in code.split('/'):
                if c not in existants and c not in nouvelles:
                    d = desc if '/' not in code else c[len('RULES-TRAP_'):].replace('_', ' ').title()
                    nouvelles[c] = (fam, d, f)
            attr = ' quantite="%s"' % q if q else ''
            lignes.append('<Item name="%s"%s>"%s"</Item>' % (code, attr, niv))
        return '\n'.join(lignes) + '\n  <!-- ' + nom.replace('--', '-') + ' -->'
    nouveau = re.sub(r'<Item name="((?!RULES-)[^"]+)">"(\d+)"</Item>', remplace, t)
    contenus[f] = nouveau

# fiches nouvelles : dans le livre ou elles sont utilisees si DATA_TRAPPING y existe, sinon dans le Rulebook
rulesbook = [f for f in fichiers if f.endswith('BOOK_RULESBOOK.Xml')][0]
par_fichier = {}
for c, (fam, d, f) in sorted(nouvelles.items()):
    cible = f if '</DATA_TRAPPING>' in contenus[f] else rulesbook
    par_fichier.setdefault(cible, []).append(
        '<Trapping id="%s">\n<Description language="ENGLISH">"%s"</Description>\n<Theme>"%s"</Theme>\n</Trapping>'
        % (c, escape(d), THEME.get(fam, THEME_DEFAUT)))
for f, l in par_fichier.items():
    contenus[f] = contenus[f].replace('</DATA_TRAPPING>', '\n'.join(l) + '\n</DATA_TRAPPING>', 1)

print('lignes migrees :', n_lignes, '| fiches nouvelles :', len(nouvelles))
from collections import Counter
print(Counter(v[0] for v in nouvelles.values()))
if appliquer:
    for f, t in contenus.items():
        open(f, 'w', encoding='utf-8', newline='').write(t)
    print('livres ecrits')
else:
    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'RAPPORT_TRAPPINGS_V5_MIGRATION.txt'), 'w', encoding='utf-8') as o:
        for c, (fam, d, f) in sorted(nouvelles.items()):
            o.write('%-10s %-55s %s\n' % (fam, c, d))
    print('essai : RAPPORT_TRAPPINGS_V5_MIGRATION.txt')
