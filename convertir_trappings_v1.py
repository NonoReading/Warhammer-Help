# Convertit <Trappings> des carrieres V1 en <SUBCHAPTER_ITEM> (codes EquipmentV1, "A/B" = choix).
# Trappings reste en texte (comme en V2). Idempotent : ignore les carrieres qui ont deja le bloc.
# Usage : python convertir_trappings_v1.py            (ecrit les livres WFRP1)
#         python convertir_trappings_v1.py --essai    (n'ecrit rien, affiche les comptes)
import re, glob, os, sys
from xml.sax.saxutils import escape
import xml.etree.ElementTree as ET

essai = '--essai' in sys.argv
base = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'DATABASE', 'WFRP1')
fichiers = sorted(glob.glob(os.path.join(base, 'BOOK_*.Xml')))

def norm(s):
    s = s.lower().strip()
    s = re.sub(r'\(.*?\)', '', s)
    s = re.sub(r'[^a-z0-9\' -]', ' ', s)
    return re.sub(r'\s+', ' ', s).strip()

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

def mots(s):
    return ' '.join(sorted(s.split()))
cat_mots = {}
for k, v in cat.items():
    cat_mots.setdefault(mots(k), v)
cat_colle = {}
for k, v in cat.items():
    cat_colle.setdefault(k.replace(' ', '').replace('-', ''), v)

# alias valides par Nono (08/11/2026)
ALIAS = {'dagger': 'dagger knife', 'knife': 'dagger knife', 'club': 'wooden club',
         'leather jack': 'leather jacket', 'sling bag': 'slingbag',
         'tool bag': "artisan's trade tools", 'flask': 'flask leather',
         'bow': 'normal bow', 'leather armor': 'leather jerkin', 'helmet': 'pot helmet',
         'horse': 'riding horse', 'staff': 'quarter staff',
         # alias valides par Nono (08/11/2026, suite 50)
         'chain shirt': 'mail shirt', 'two handed sword': 'two-handed sword',
         'knuckle-duster': 'knuckle duster', 'throwing dagger': 'throwing knife',
         'concealed dagger': 'dagger knife', 'garrote': 'garrotter',
         'yards of rope': 'rope',
         # alias valides par Nono (09/11/2026)
         'long sword': 'sword', 'axe': 'hand axe', 'cudgel': 'wooden club', 'helm': 'pot helmet',
         # alias valides par Nono (09/11/2026, suite 55)
         'handgun': 'dwarf handgun', 'full helm': "knight's helm", 'leather helmet': 'pot helmet'}
HAND_WEAPON = ('RULES-EQUIP_WEAPON_MELEE_SWORD/RULES-EQUIP_WEAPON_MELEE_HAND_AXE/'
               'RULES-EQUIP_WEAPON_MELEE_MACE')

def cherche(txt):
    """Retourne (code, quantite) ou (None, 1)."""
    txt = re.sub(r'\s+-\s+(?!\d+ yards?)\D.*$', '', txt)   # remarque apres un tiret (« Lance - cavalry only »)
    n = norm(txt)
    n = re.sub(r'^(left|right)[- ]hand(ed)?\s+', '', n)    # qualificatif de main
    n = re.sub(r'^metal\s+', '', n)
    q = 1
    m = re.match(r'^(\d+)\s+(.*)$', n)           # quantite fixe seulement (pas de des)
    if m: q, n = int(m.group(1)), m.group(2)
    if re.match(r'^pairs? of\s+', n): q = 2             # « Pair of X » = 2 objets
    n = re.sub(r'^(a|an|one|pairs? of)\s+', '', n)
    # complement de poudre / munitions : l objet reste, le complement est ignore
    n = re.sub(r'\s+(with\s+)?(powder\s+)?(and\s+)?(ammunition|ammo)(\s+for\s+\d+\s+shots)?$', '', n)
    my = re.search(r'\s*-\s*(\d+) yards?$', n)
    if my: q, n = int(my.group(1)), n[:my.start()]      # « Rope - 10 yards » = corde x 10
    if n == 'hand weapon': return HAND_WEAPON, q
    for c in (n, singulier(n)):
        if c in cat: return cat[c], q
    a = ALIAS.get(n) or ALIAS.get(singulier(n))
    if a and a in cat: return cat[a], q
    for c in (n, singulier(n)):                     # memes mots dans un autre ordre
        if mots(c) in cat_mots: return cat_mots[mots(c)], q
    for c in (n, singulier(n)):                     # meme nom avec ou sans espace (Breastplate / Breast Plate)
        if c.replace(' ', '').replace('-', '') in cat_colle: return cat_colle[c.replace(' ', '').replace('-', '')], q
    return None, 1

def items_de(trappings):
    items = []
    for part in [p.strip() for p in trappings.split(';') if p.strip()]:
        alts = [a.strip() for a in re.split(r'\s+or\s+', part)]
        res = [cherche(a) for a in alts]
        if all(c for c, _ in res):
            codes = '/'.join(c for c, _ in res)
            qs = [q for _, q in res]
            qte = None
            if len(set(qs)) > 1: qte = '/'.join(str(q) for q in qs)
            elif qs[0] > 1: qte = str(qs[0])
            items.append((codes, qte, True))
        else:
            items.append((part, None, False))
    return items

if '--cordes' in sys.argv:
    # Pose quantite="N" sur la corde des carrieres dont les Trappings disent « Rope - N yards ».
    n_c = 0
    for f in fichiers:
        t = open(f, encoding='utf-8', newline='').read()
        def car(m):
            global n_c
            bloc = m.group(0)
            my = re.search(r'Rope\s*-\s*(\d+) yards?', bloc)
            if not my: return bloc
            nb = bloc.replace('<Item name="RULES-EQUIP_MISC_TOOLS_ROPE_YARD">',
                              '<Item name="RULES-EQUIP_MISC_TOOLS_ROPE_YARD" quantite="%s">' % my.group(1), 1)
            if nb != bloc: n_c += 1
            return nb
        nouveau = re.sub(r'<Career id="[^"]+">.*?</Career>', car, t, flags=re.S)
        if nouveau != t and not essai:
            ET.fromstring(nouveau.encode('utf-8'))
            open(f, 'w', encoding='utf-8', newline='').write(nouveau)
    print(n_c, 'cordes avec quantite', '(essai)' if essai else '')
    sys.exit(0)

if '--rattrapage' in sys.argv:
    # Reprend les Item en texte libre des blocs deja convertis et les remplace par un code si le catalogue
    # (alias compris) le reconnait. Ne touche ni aux codes, ni aux munitions, ni aux choix existants.
    from xml.sax.saxutils import unescape
    n_ok = 0
    for f in fichiers:
        t = open(f, encoding='utf-8', newline='').read()
        def item(m):
            global n_ok
            nom = unescape(m.group(1), {'&quot;': '"'})
            if nom.startswith('RULES-') or m.group(2): return m.group(0)
            alts = [a.strip() for a in re.split(r'\s+or\s+', nom)]
            res = [cherche(a) for a in alts]
            if not all(c for c, _ in res): return m.group(0)
            vus = []                                     # alternatives identiques : une seule
            for r in res:
                if r[0] not in [v[0] for v in vus]: vus.append(r)
            res = vus
            qs = [q for _, q in res]
            qte = '/'.join(str(q) for q in qs) if len(set(qs)) > 1 else (str(qs[0]) if qs[0] > 1 else None)
            n_ok += 1
            print(f.split(os.sep)[-1], ':', nom, '->', '/'.join(c for c, _ in res), qte or '')
            attr = ' quantite="%s"' % qte if qte else ''
            return '<Item name="%s"%s>' % ('/'.join(c for c, _ in res), attr)
        nouveau = re.sub(r'<Item name="([^"]*)"( quantite="[^"]*")?>(?="1"</Item>)', item, t)
        if nouveau != t and not essai:
            ET.fromstring(nouveau.encode('utf-8'))
            open(f, 'w', encoding='utf-8', newline='').write(nouveau)
    print(n_ok, 'elements rattrapes', '(essai)' if essai else '')

    # 2e passe : decoupe sur les virgules (hors parentheses) un Item libre dont au moins une partie est reconnue.
    def coupe(nom):
        parts, cur, prof = [], '', 0
        for ch in nom:
            if ch == '(': prof += 1
            elif ch == ')': prof = max(0, prof - 1)
            if ch == ',' and prof == 0: parts.append(cur); cur = ''
            else: cur += ch
        parts.append(cur)
        return [p.strip() for p in parts if p.strip()]
    n_cut = 0
    for f in fichiers:
        t = open(f, encoding='utf-8', newline='').read()
        nl = '\r\n' if '\r\n' in t else '\n'
        def item2(m):
            global n_cut
            nom = unescape(m.group(1), {'&quot;': '"'})
            if nom.startswith('RULES-') or m.group(2) or ',' not in nom: return m.group(0)
            parts = coupe(nom)
            if len(parts) < 2: return m.group(0)
            if ':' in nom or 'at least' in nom: return m.group(0)     # descriptions de rang (serviteurs, biens de valeur minimale)
            if any(re.match(r'(?i)(pairs? of|one) ', p) for p in parts): return m.group(0)   # « paire » = 2, « one barbed » = precision
            res = items_de('; '.join(parts))     # chaque partie : code ou texte libre
            if not any(c for _, _, c in res): return m.group(0)
            n_cut += 1
            print(f.split(os.sep)[-1], ':', nom[:70], '->', [(n[-28:] if c else 'TXT') for n, _, c in res])
            out = []
            for n, q, c in res:
                attr = ' quantite="%s"' % q if q else ''
                out.append('<Item name="%s"%s>"1"</Item>' % (escape(n, {'"': '&quot;'}), attr))
            return nl.join(out)
        nouveau = re.sub(r'<Item name="([^"]*)"( quantite="[^"]*")?>"1"</Item>', item2, t)
        if nouveau != t and not essai:
            ET.fromstring(nouveau.encode('utf-8'))
            open(f, 'w', encoding='utf-8', newline='').write(nouveau)
    print(n_cut, 'elements decoupes', '(essai)' if essai else '')
    sys.exit(0)

stats = dict(carrieres=0, converties=0, items=0, codes=0, libres=0, deja=0, ignorees=0)
for f in fichiers:
    t = open(f, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in t else '\n'

    def career(m):
        bloc = m.group(0)
        mt = re.search(r'<Trappings>"([^"]*)"</Trappings>' + nl, bloc)
        if not mt: return bloc
        stats['carrieres'] += 1
        if '<SUBCHAPTER_ITEM>' in bloc:
            stats['deja'] += 1; return bloc
        tr = mt.group(1)
        if tr.strip().lower() in ('none', 'aucun en particulier') or (len(tr) > 160 and ';' not in tr):   # prose = ignoree, liste a points-virgules = convertie
            stats['ignorees'] += 1; return bloc
        items = items_de(tr)
        if not items: return bloc
        out = '<SUBCHAPTER_ITEM>' + nl
        for nom, qte, code in items:
            attr = ' quantite="%s"' % qte if qte else ''
            out += '<Item name="%s"%s>"1"</Item>%s' % (escape(nom, {'"': '&quot;'}), attr, nl)
            stats['items'] += 1
            stats['codes' if code else 'libres'] += 1
        out += '</SUBCHAPTER_ITEM>' + nl
        stats['converties'] += 1
        return bloc[:mt.end()] + out + bloc[mt.end():]

    nouveau = re.sub(r'<Career id="[^"]+">.*?</Career>', career, t, flags=re.S)
    if nouveau != t and not essai:
        ET.fromstring(nouveau.encode('utf-8'))   # bien forme sinon exception, rien d'ecrit
        open(f, 'w', encoding='utf-8', newline='').write(nouveau)
print(stats, '(essai : rien ecrit)' if essai else '')
