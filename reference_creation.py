"""Test de non-regression de WinCreation (V2, V4, V5).

  python reference_creation.py figer      cree les personnages de reference (graine fixe) et garde leurs releves
  python reference_creation.py comparer   refait les memes personnages et compare avec la reference

Chaque personnage est cree par WarhammerHelp.exe --creer (memes boutons Hasard que le joueur, WH_GRAINE fixe le
hasard), puis releve par --dump et --dumppdf. Les releves sont dans TRAVAIL\\REFERENCE\\ref (figer) ou
TRAVAIL\\REFERENCE\\nouveau (comparer). INI.TXT est remis comme avant a la fin.
"""
import difflib
import os
import shutil
import subprocess
import sys

DOSSIER = os.path.dirname(os.path.abspath(__file__))
EXE = os.path.join(DOSSIER, 'WarhammerHelp.exe')
INI = os.path.join(DOSSIER, 'INI.TXT')
GRAINE = '20261026'

# (version, ethnie, carriere, nom)
CAS = [
    ('WFRP2', 'RULES-RACE_HUMAN', 'RULES-CARE_ARTISAN', 'REF2 Humain Artisan'),
    ('WFRP2', 'RULES-RACE_DWARF', 'RULES-CARE_ARTISAN', 'REF2 Nain Artisan'),
    ('WFRP2', 'RULES-RACE_HALFLING', 'RULES-CARE_AGITATOR', 'REF2 Halfling Agitateur'),
    ('WFRP4', 'RULES-RACE_HUM', 'RULES-WORK_ARTISAN', 'REF4 Humain Artisan'),
    ('WFRP4', 'RULES-RACE_DWAR', 'RULES-WORK_ARTISAN', 'REF4 Nain Artisan'),
    ('WFRP4', 'RULES-RACE_HALF', 'RULES-WORK_AGITATOR', 'REF4 Halfling Agitateur'),
    ('WFRP5', 'RULES-RACE_HUM', 'RULES-WORK_APOTHECARY', 'REF5 Humain Apothicaire'),
    ('WFRP5', 'RULES-RACE_DWAR', 'RULES-WORK_ENGINEER', 'REF5 Nain Ingenieur'),
    ('WFRP5', 'RULES-RACE_HALF', 'RULES-WORK_LAWYER', 'REF5 Halfling Juriste'),
]


def lire(chemin):
    with open(chemin, 'r', encoding='utf-8', errors='replace', newline='') as f:
        return f.read()


def ecrire(chemin, texte):
    with open(chemin, 'w', encoding='utf-8', newline='') as f:
        f.write(texte)


def regle_version(ini, version):
    lignes = ini.split('\n')
    for i, ligne in enumerate(lignes):
        if ligne.startswith('VERSION='):
            fin = '\r' if ligne.endswith('\r') else ''
            lignes[i] = 'VERSION=' + version + fin
    return '\n'.join(lignes)


def lance(args, extra_env=None):
    env = dict(os.environ)
    if extra_env:
        env.update(extra_env)
    subprocess.run([EXE] + args, cwd=DOSSIER, env=env, timeout=600,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def releves(sortie):
    os.makedirs(sortie, exist_ok=True)
    ini_initial = lire(INI)
    try:
        for version in ('WFRP2', 'WFRP4', 'WFRP5'):
            ecrire(INI, regle_version(ini_initial, version))
            for v, ethnie, carriere, nom in CAS:
                if v != version:
                    continue
                # un perso du meme nom (figeage ou essai precedent) ferait refuser l'enregistrement
                shutil.rmtree(os.path.join(DOSSIER, 'SAVED_CARACTERS', version, nom), ignore_errors=True)
                creer = os.path.join(DOSSIER, 'CREER.txt')
                if os.path.exists(creer):
                    os.remove(creer)
                lance(['--creer', ethnie, carriere, nom], {'WH_GRAINE': GRAINE})
                if os.path.exists(creer):
                    shutil.copyfile(creer, os.path.join(sortie, nom + '.creer.txt'))
                else:
                    ecrire(os.path.join(sortie, nom + '.creer.txt'), 'PAS DE CREER.txt\n')
                lance(['--dump', sortie, nom])
                lance(['--dumppdf', sortie, nom])
    finally:
        ecrire(INI, ini_initial)


def compare(ref, nouveau):
    differences = 0
    for nom in sorted(os.listdir(ref)):
        autre = os.path.join(nouveau, nom)
        if not os.path.exists(autre):
            print('MANQUE  ' + nom)
            differences += 1
            continue
        a = lire(os.path.join(ref, nom)).splitlines()
        b = lire(autre).splitlines()
        if a != b:
            differences += 1
            print('DIFFERENT  ' + nom)
            for ligne in list(difflib.unified_diff(a, b, 'ref', 'nouveau', lineterm='', n=0))[:12]:
                print('    ' + ligne)
    print('%d fichier(s) differents sur %d' % (differences, len(os.listdir(ref))))
    return differences


def main():
    base = os.path.join(DOSSIER, 'TRAVAIL', 'REFERENCE')
    mode = sys.argv[1] if len(sys.argv) > 1 else ''
    if mode == 'figer':
        shutil.rmtree(os.path.join(base, 'ref'), ignore_errors=True)
        releves(os.path.join(base, 'ref'))
        print('Reference figee dans ' + os.path.join(base, 'ref'))
    elif mode == 'comparer':
        shutil.rmtree(os.path.join(base, 'nouveau'), ignore_errors=True)
        releves(os.path.join(base, 'nouveau'))
        sys.exit(1 if compare(os.path.join(base, 'ref'), os.path.join(base, 'nouveau')) else 0)
    else:
        print(__doc__)


main()
