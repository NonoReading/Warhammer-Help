This software written with Lazarus allows you to manage characters from Warhammer Fantasy RPG V4 (and later V5). 
The goal is to make it possible to follow the evolution of the character and to produce the most effective character sheet possible. 
It also allows you to produce breed and trade sheets in PDF format plus access to useful data. 
The program uses official and fan books "translated" into XML format as a database. 
By default the program is in English, but easily translatable and adaptable to other languages (the interface data is XML). 
There is also a database of races, professions, weapons, armor, spells. 
The program is still under development and is a tribute to this role-playing game that I really like (even if calculating XP is really complicated...) 
I started making a system to create fan books, but with AI they are able to transform a page directly into usable data in the program. 

Thanks to Cubicle 7 for this magnificent 4th edition.

## Distribution

This repository contains the source code, the schemas and a **text-free** copy of the book
data: names, numbers, codes and page numbers only. Rules text is not included, neither for the official books nor for third-party fan
supplements (their authors keep their rights). Where text is missing, the program
shows "Page N" instead. Leave `DEFAULTLICENSELESS=0` in `INI.TXT`: books you add with their
text show it, and your own images in `PICTURES` are used (`=1` is only a test mode that forces
"Page N" everywhere and ignores `PICTURES`).

* To use the descriptions, add your own books in the same XML format (see `GABARIT_LIVRE_XML.md`).
* Official illustrations are not included. `PICTURES_DEFAULT` holds original replacement
  images; put your own in `PICTURES/` or `DATABASE/WFRP4/PICTURES/`.
* Fonts: only EB Garamond (SIL OFL) is bundled. The PDF export also looks for
  `FONT/arial*.ttf` and `FONT/CaslonAntique*.ttf`; install your own copies there.

Unofficial fan project, not affiliated with or endorsed by Cubicle 7 or Games Workshop.
Warhammer and related names are trademarks of their respective owners.
