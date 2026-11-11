# Rapport (lecture seule) : Trappings V1 -> objets EquipmentV1 reconnus.
# Usage : python rapport_trappings_v1.py   (ecrit RAPPORT_TRAPPINGS_V1.txt)
import re, glob, os

base = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'DATABASE', 'WFRP1')
fichiers = sorted(glob.glob(os.path.join(base, 'BOOK_*.Xml')))

def norm(s):
    s = s.lower().strip()
    s = re.sub(r'\(.*?\)', '', s)
    s = re.sub(r'[^a-z0-9\' -]', ' ', s)
    s = re.sub(r'\s+', ' ', s).strip()
    return s

def singulier(s):
    if s.endswith('ies'): return s[:-3] + 'y'
    if s.endswith('ves'): return s[:-3] + 'f'
    if s.endswith('s') and not s.endswith('ss'): return s[:-1]
    return s

cat = {}
for f in fichiers:
    t = open(f, encoding='utf-8', errors='replace').read()
    for m in re.finditer(r'<EquipmentV1 id="([^"]+)">\s*<Description language="ENGLISH">"([^"]+)"', t):
        cat.setdefault(norm(m.group(2)), m.group(1))
        cat.setdefault(singulier(norm(m.group(2))), m.group(1))

# alias SURS (meme objet, autre ecriture) et alias A VALIDER (choix de ma part)
ALIAS_SURS = {'dagger': 'dagger knife', 'knife': 'dagger knife', 'club': 'wooden club',
              'rope': 'rope', 'hand axe': 'hand axe', 'flask': 'flask leather',
              'leather jack': 'leather jacket', 'sling bag': 'slingbag',
              'tool bag': 'artisan\'s trade tools'}
ALIAS_A_VALIDER = {'bow': 'normal bow','helmet': 'pot helmet',
                   'leather armor': 'leather jerkin', 'horse': 'riding horse',
                   'staff': 'quarter staff'}
a_valider_vus = {}

def cherche(txt):
    n = norm(txt)
    n = re.sub(r'^(\d*d\d+( x \d+)?|\d+|a|an|one|pair of|pairs of)\s+', '', n)
    n = re.sub(r'^(pairs? of)\s+', '', n)
    n = re.sub(r'\s+and ammunition$', '', n)
    n = re.sub(r'\s*-\s*\d+ yards?$', '', n)
    n = re.sub(r'\s+and \d*[a-z]* ?shots? of powder.*$', '', n)
    for c in (n, singulier(n)):
        if c in cat: return cat[c]
    a = ALIAS_SURS.get(n) or ALIAS_SURS.get(singulier(n))
    if a and a in cat: return cat[a]
    if n == 'hand weapon':
        # choix a la creation : liste de branches "A/B/C" (comme la V4)
        return 'RULES-EQUIP_WEAPON_MELEE_SWORD/RULES-EQUIP_WEAPON_MELEE_HAND_AXE/RULES-EQUIP_WEAPON_MELEE_MACE'
    if n in ALIAS_A_VALIDER:
        a_valider_vus[n] = a_valider_vus.get(n, 0) + 1
        return 'A_VALIDER:' + n
    return None

total = ok = 0
carrieres = ok_complete = 0
non_reconnus = {}
lignes = []
for f in fichiers:
    t = open(f, encoding='utf-8', errors='replace').read()
    for m in re.finditer(r'<Career id="([^"]+)">.*?<Trappings>"([^"]*)"</Trappings>', t, re.S):
        cid, tr = m.group(1), m.group(2)
        if tr.strip().lower() == 'none' or len(tr) > 160:
            lignes.append('%s | %s | (ignore : none ou texte long)' % (os.path.basename(f), cid))
            continue
        carrieres += 1
        complet = True
        for part in [p.strip() for p in tr.split(';') if p.strip()]:
            alts = [a.strip() for a in re.split(r'\s+or\s+', part)]
            codes = [cherche(a) for a in alts]
            total += 1
            if all(codes):
                ok += 1
            else:
                complet = False
                non_reconnus[part] = non_reconnus.get(part, 0) + 1
        ok_complete += complet
        lignes.append('%s | %s | %s' % (os.path.basename(f), cid, 'COMPLET' if complet else 'PARTIEL'))

sortie = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'RAPPORT_TRAPPINGS_V1.txt')
with open(sortie, 'w', encoding='utf-8') as o:
    o.write('Catalogue : %d noms. Elements : %d, reconnus : %d. Carrieres : %d, 100%% reconnues : %d\n\n'
            % (len(cat), total, ok, carrieres, ok_complete))
    o.write('A VALIDER (nom du livre -> occurrences ; proposition) :\n')
    for k, v in sorted(a_valider_vus.items(), key=lambda x: -x[1]):
        o.write('%3d  %s -> %s\n' % (v, k, ALIAS_A_VALIDER[k]))
    o.write('\n')
    o.write('NON RECONNUS (occurrences) :\n')
    for k, v in sorted(non_reconnus.items(), key=lambda x: -x[1]):
        o.write('%3d  %s\n' % (v, k))
    o.write('\nPAR CARRIERE :\n' + '\n'.join(lignes) + '\n')
print('Catalogue %d noms ; elements %d, reconnus %d ; carrieres %d, completes %d'
      % (len(cat), total, ok, carrieres, ok_complete))
