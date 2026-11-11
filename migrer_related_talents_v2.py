"""Migration de RelatedTalents (V2) : noms de talents separes par des virgules -> codes RULES-T_...

Usage : python migrer_related_talents_v2.py            (apercu, n'ecrit rien)
        python migrer_related_talents_v2.py --appliquer (ecrit les livres)

Un nom est rapproche par la Description du talent (Rulebook V2 + le livre lui-meme). "None" ou vide -> balise
vide "" (la balise reste, la valeur disparait). Un nom sans talent correspondant reste en texte et est signale.
"""
import glob
import re
import sys

DOSSIER = "DATABASE/WFRP2/"
appliquer = "--appliquer" in sys.argv


def lire(chemin):
    with open(chemin, encoding="utf-8") as f:
        return f.read()


def talents_du_texte(texte):
    # <Talent id="X"> ... <Description language="ENGLISH">"Nom"</Description>
    res = {}
    for m in re.finditer(r'<Talent id="([^"]+)">\s*<Description language="ENGLISH">"([^"]*)"', texte):
        res[m.group(2).strip().lower()] = m.group(1)
    return res


rulebook = talents_du_texte(lire(DOSSIER + "BOOK_RULESBOOK.Xml"))
motif = re.compile(r'<RelatedTalents>"([^"]*)"</RelatedTalents>')
total = convertis = vides = inconnus = 0
for chemin in sorted(set(glob.glob(DOSSIER + "*.Xml") + glob.glob(DOSSIER + "*.xml"))):  # Windows : meme fichier deux fois
    texte = lire(chemin)
    if "<RelatedTalents>" not in texte:
        continue
    table = dict(rulebook)
    table.update(talents_du_texte(texte))

    def remplace(m):
        global total, convertis, vides, inconnus
        total += 1
        valeur = m.group(1).strip()
        if valeur == "" or valeur.lower() == "none":
            vides += 1
            return '<RelatedTalents>""</RelatedTalents>'
        codes = []
        for nom in [n.strip() for n in valeur.split(",")]:
            code = table.get(nom.lower())
            if code is None:
                inconnus += 1
                print("  INCONNU dans %s : %r" % (chemin, nom))
                code = nom
            codes.append(code)
        convertis += 1
        return '<RelatedTalents>"%s"</RelatedTalents>' % ",".join(codes)

    nouveau = motif.sub(remplace, texte)
    if appliquer and nouveau != texte:
        with open(chemin, "w", encoding="utf-8", newline="") as f:
            f.write(nouveau)
print("balises %d : converties %d, vides (None) %d, noms sans talent %d%s" %
      (total, convertis, vides, inconnus, "" if appliquer else " (apercu, rien ecrit)"))
