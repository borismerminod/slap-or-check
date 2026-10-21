# Claque ou Check — Document de game design

**Genre** : hypercasual, réflexe et lecture
**Plateforme visée** : mobile (portrait), une main
**Thème** : la recherche d'emploi qui énerve
**Pitch** : ils arrivent un par un avec leurs phrases toutes faites. Toi, tu réponds avec la main.

---

## 1. Principe du jeu

Le joueur contrôle un stickman, vu de dos au premier plan, dans un couloir d'open space en 3D. Des personnages (stickmen simples, couleurs variées) avancent vers lui un par un, chacun avec une phrase affichée dans une bulle de dialogue.

Avant que le personnage arrive à sa hauteur, le joueur doit choisir :

| Geste | Action | Animation |
|---|---|---|
| **Swipe gauche** | **Claque** | Le joueur arme le bras et frappe ; le personnage s'envole (« PAF ! », secousse de l'écran) |
| **Swipe droite** | **Check** | Les deux lèvent la main, tape dans la main (« CHECK ! ») ; le personnage repart content |
| Aucun geste | Laissé passer | Le personnage bouscule le joueur et passe |

Les phrases « bateau » (langue de bois du recrutement) méritent une claque. Les phrases qui donnent de vraies informations méritent un check.

### Exemples de phrases

| Claque (bateau) | Check (vraie info) |
|---|---|
| « Pas de salaire mais nous certifions les compétences ! » | « Salaire : 100k à 120k » |
| « Ici, on est une famille » | « Réponse sous 7 jours, promis » |
| « Poste junior, 10 ans d'expérience » | « Télétravail au choix ! » |
| « Rejoins une équipe dynamique » | « Un seul entretien » |
| « Process en six entretiens » | « Voici pourquoi tu n'es pas retenu » |
| « Babyfoot et fruits frais ! » | « Mutuelle prise à 100 % » |
| « Stage non payé, très formateur » | « 35 h, heures sup payées » |

Phrases « cultes » (rares, toujours bateau) : « Ravi d'annoncer que j'ai été ravi d'annoncer », « Ce que mon chat m'a appris sur le leadership »

**Contraintes d'écriture** : 6 à 7 mots maximum à haute vitesse. Personnages, entreprises et réseaux inventés, aucun logo ni nom réel.

---

## 2. Règle du jour

Chaque niveau commence par une carte « Règle du jour » qui dit explicitement ce qu'il faut claquer et checker.

- Règle standard : *« Claque les phrases bateau. Check les vraies infos. »*
- Elle rend le jugement **vérifiable** plutôt que subjectif : une erreur paraît juste au joueur, puisqu'il connaissait la règle.
- Elle sert de support aux variations (mode inversé, double règle…).

---

## 3. Boucle de jeu

1. Carte « Règle du jour ».
2. Un personnage quitte la file (visible au fond du couloir) et marche vers le joueur.
3. Le joueur lit la bulle et swipe. Au swipe, le personnage accélère jusqu'au joueur et l'animation se joue.
4. Retour d'information immédiat (message, onomatopée, variation de la jauge).
5. Personnage suivant, jusqu'à la fin de la file.

Le **temps de réaction** est représenté par la **distance** : plus le niveau est rapide, plus le personnage marche vite.

---

## 4. Victoire, défaite et jauge de Moral

Les « 3 essais » sont remplacés par une **jauge de Moral** (0 à 100), cohérente avec le thème : la recherche d'emploi use.

| Événement | Effet (valeurs de départ, à équilibrer) |
|---|---|
| Départ du niveau | 70 |
| Temps qui passe | −0,8 par seconde |
| Bonne réaction | +5 |
| Série de 5 bonnes réactions | +8 bonus |
| Mauvaise réaction | −22 |
| Personne laissée passer | −14 |

- **Victoire** : arriver au bout de la file avec un Moral supérieur à 0.
- **Défaite** : Moral à 0, on recommence le niveau.
- **Étoiles** : selon le Moral restant (3 étoiles à partir de 60, 2 à partir de 30, 1 sinon).
- **Écran de fin** : statistiques (bonnes réactions, erreurs, laissés passer) et rappel des dernières erreurs avec la réponse attendue.


---

## 5. Progression des niveaux

Niveaux courts (45 à 90 secondes). La difficulté joue sur la vitesse de marche et l'ajout de briques, plus que sur la longueur de la file.

| Niveau | Nom | Personnes | Vitesse | Briques introduites |
|---|---|---|---|---|
| 1 à 3 | Premier jour | 10 | Lente | Aucune |
| 4 à 7 | Les relous | 14 | Moyenne | Le Relou |
| 8 à 10 | Recruteurs coriaces | 16 | Moyenne | Vrai Gentil, Recruteur coriace |
| 11+ | Salon de l'emploi | 20 | Rapide | Bulle brouillée, Influenceur, Bonus café |
| Bonus | Mode inversé | 12 | Moyenne | Mode inversé |
| Tous les 10 | Boss | — | — | Le Gourou |

Principe : **une brique est introduite seule** sur un niveau, puis combinée aux autres.

---

## 6. Système de contenu

Pour éviter que le joueur mémorise les phrases au lieu de les lire :

- **Grand réservoir de phrases** classées bateau / vraie info, tirées au hasard à chaque partie.
- **Phrases cultes** rares, comme récompenses comiques.
- **Piste d'évolution** : phrases assemblées à partir de fragments (ex. « Poste junior » + « 8 ans d'expérience exigés »), où c'est la combinaison qui est bateau. Le nombre de phrases possibles devient très grand.
- Contenu séparé du code (fichier de données), pour pouvoir en ajouter sans toucher au jeu.

---

## 7. Briques de gameplay

### 7.1 Personnages spéciaux (présents dans la maquette)

Chaque personnage spécial est **reconnaissable visuellement** et annoncé dans sa bulle.

| Brique | Signe distinctif | Comportement |
|---|---|---|
| **Le Relou** | Casquette rouge | S'il est laissé passer, il se remet dans la file un peu plus loin |
| **Le Recruteur coriace** | Plus grand, cravate | Il encaisse : il faut 2 bonnes réactions d'affilée (il recule puis revient) |
| **L'Influenceur** | Lunettes noires, téléphone | Le checker par erreur fait arriver 2 de ses abonnés dans la file |
| **Le Vrai Gentil** | Fleur à la boutonnière | Rare, marche lentement ; le checker donne +20 de Moral |

Principe commun : **les erreurs ont des conséquences visibles dans la file**, pas seulement un chiffre qui baisse.

### 7.2 Modificateurs de niveau (présents dans la maquette)

| Brique | Effet |
|---|---|
| **Bulle brouillée** | La phrase ne devient lisible qu'à mi-chemin (« l'algorithme charge ») |
| **Bonus café** | Apparaît par moments ; le toucher ralentit la marche pendant 5 secondes |
| **Mode inversé** | La règle s'inverse : check le bateau, claque le concret |

### 7.3 Briques prévues (hors maquette)

| Brique | Idée |
|---|---|
| **Styles de coup** | Claque, gros coup de poing, poisson, CV roulé : cosmétiques à débloquer |
| **Arrivées groupées** | Deux personnages côte à côte, chacun sa bulle, à traiter dans l'ordre |
| **Swipe haut : esquiver** | 3e catégorie (pub, spam) à introduire vers le niveau 10 |
| **Appui long : bloquer** | Geste réservé aux boss |
| **Double règle** | Deux conditions à vérifier en même temps |
| **Boss « Le Gourou »** | Enchaîne plusieurs phrases ; chaque bonne réponse lui retire un point de vie |
| **Décors** | Open space, salon de l'emploi, visio : changent la vitesse et le ton |
| **Mode infini** | La file sans fin, avec classement |
| **Posts en icônes** | Les phrases deviennent des pictogrammes à très haute vitesse |

---

## 8. Rétention et monétisation

- **Étoiles** par niveau, à collectionner.
- **Pub récompensée** sur l'écran de défaite : +50 de Moral pour continuer, une fois par niveau.
- **Cosmétiques** : styles de coup, tenues du personnage joueur, onomatopées.
- **Mode infini** et classement après le premier boss.
- Piste acquisition : une version courte du jeu en **playable ad** (format HTML5 diffusé par les régies publicitaires).

---

## 9. Choix technique pour le POC

| Option | Avantages | Limites |
|---|---|---|
| **Three.js + TypeScript** | Réalisable presque entièrement par Claude, test immédiat par lien, itérations rapides, réutilisable en playable ad | Pas un moteur complet ; publication mobile via un emballage (Capacitor) |
| **Godot** | Vrai moteur, scènes en texte écrites par Claude, export mobile natif | Test du ressenti en local ; écosystème pub moins mûr |
| **Unity** | Standard du secteur, attendu par les éditeurs hypercasual | Beaucoup de manipulations dans l'éditeur ; Claude ne peut ni compiler ni tester |

Recommandation actuelle : valider le plaisir de jeu avec la maquette web, puis choisir le moteur du POC selon l'objectif (publication autonome ou démarchage d'éditeurs).

---

## 10. Questions ouvertes

- Distance de départ et vitesse de marche : a-t-on le temps de lire la bulle ?
- Position de la caméra : par-dessus l'épaule, ou vue subjective ?
- La claque a-t-elle assez de « punch », ou faut-il un vrai gros coup plus appuyé ?
- Équilibrage de la jauge de Moral (valeurs du tableau 4 non testées).
- Objectif du projet : publication autonome, éditeur, ou projet de formation ?
