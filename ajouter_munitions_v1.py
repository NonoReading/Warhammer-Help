# Ajoute les munitions aux carrieres V1 dont Trappings dit « ... and ammunition » (decide par Nono le 08/11/2026) :
# arc -> Fleches (5), arbalete -> Carreaux (5), « arc ou arbalete » -> choix Fleches / Carreaux. Fronde et tromblon restent en texte.
# Idempotent : ignore une carriere qui a deja ARROWS_5 ou BOLTS_5 dans son equipement.
# Usage : python ajouter_munitions_v1.py            (ecrit les livres WFRP1)
#         python ajouter_munitions_v1.py --essai    (n'ecrit rien, affiche les comptes)
import re, glob, os, sys
import xml.etree.ElementTree as ET

essai = '--essai' in sys.argv
base = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'DATABASE', 'WFRP1')
P = 'RULES-EQUIP_WEAPON_MISSILE_'
ARCS = (P + 'NORMAL_BOW', P + 'SHORT_BOW', P + 'LONG_BOW', P + 'ELF_BOW')
ARBALETES = (P + 'CROSSBOW', P + 'REPEATING_CROSSBOW')
FLECHES, CARREAUX = P + 'ARROWS_5', P + 'CROSSBOW_BOLTS_5'
stats = dict(carrieres=0, ajoutees=0, deja=0)

for f in sorted(glob.glob(os.path.join(base, 'BOOK_*.Xml'))):
    t = open(f, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in t else '\n'

    def career(m):
        bloc = m.group(0)
        mt = re.search(r'<Trappings>"([^"]*)"</Trappings>', bloc)
        if not mt or 'and ammunition' not in mt.group(1).lower() or '<SUBCHAPTER_ITEM>' not in bloc:
            return bloc
        stats['carrieres'] += 1
        if FLECHES in bloc or CARREAUX in bloc:
            stats['deja'] += 1
            return bloc

        def ligne(mi):
            codes = mi.group(1).split('/')
            a = any(c in ARCS for c in codes)
            b = any(c in ARBALETES for c in codes)
            if not (a or b):
                return mi.group(0)
            munition = '/'.join(([FLECHES] if a else []) + ([CARREAUX] if b else []))
            stats['ajoutees'] += 1
            return mi.group(0) + nl + '<Item name="%s">"1"</Item>' % munition

        return re.sub(r'<Item name="([^"]+)">"1"</Item>', ligne, bloc)

    nouveau = re.sub(r'<Career id="[^"]+">.*?</Career>', career, t, flags=re.S)
    if nouveau != t and not essai:
        ET.fromstring(nouveau.encode('utf-8'))   # bien forme sinon exception, rien d'ecrit
        open(f, 'w', encoding='utf-8', newline='').write(nouveau)
print(stats, '(essai : rien ecrit)' if essai else '')
