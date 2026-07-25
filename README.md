# Tous ensemble

**Tous ensemble** est un addon World of Warcraft 3.3.5a / Project Ascension permettant de créer, découvrir et rejoindre des activités à l’échelle du serveur, avec ou sans guilde.

Version actuelle : **1.0.4**

## Fonctions principales

- Recherche et création d’activités à l’échelle du serveur entre utilisateurs de Tous ensemble.
- Inscriptions automatiques ou validation manuelle par le chef.
- Rôles Tank, Soigneur, Dégâts et Soutien.
- Invitation silencieuse via `/invite`, compatible Ascension inter-faction.
- Profil personnalisé avec portraits.
- Notifications pour les nouvelles activités, inscriptions et acceptations.
- Mini bouton déplaçable affichant le nombre de groupes visibles.
- Recherche de guilde et candidatures compatibles avec le protocole de G.B.G.
- Passerelle bidirectionnelle avec le Dungeon Finder G.B.G pour les membres de la même guilde.
- Fonctionnement autonome : G.B.G n’est pas requis.

## FR / All

- Une activité marquée **FR** est visible dans les filtres **FR** et **All**.
- Une activité marquée **All** est visible uniquement dans **All**.
- Le filtre choisi est sauvegardé dans le profil et s’applique aussi aux notifications.
- Les anciennes activités G.B.G sans indication de langue sont considérées comme **All**.

## Interface

- Français par défaut, indépendamment de la langue du client.
- Choix Français / English dans le profil.
- Échelle réglable de **50 % à 125 %**, par pas de **1 %** avec boutons `-` et `+`.
- `Échap` ferme la fenêtre principale et les fenêtres secondaires.
- Semi-transparence optionnelle en combat et/ou pendant les déplacements.
- Opacité réduite réglable de **20 % à 80 %**, par pas de **1 %**.
- L’état interne de la passerelle G.B.G n’est pas affiché dans l’en-tête.

## Compatibilité G.B.G

Tous ensemble possède ses propres SavedVariables, son espace global et son protocole serveur. Aucun fichier ni réglage de G.B.G n’est modifié.

Quand G.B.G est présent :

- les activités Tous ensemble peuvent être annoncées aux membres de la guilde utilisant G.B.G ;
- les inscriptions G.B.G sont reçues par le créateur Tous ensemble ;
- les activités de guilde G.B.G apparaissent dans Tous ensemble ;
- le portrait de profil peut être partagé ;
- la recherche de guilde utilise les annonces et candidatures compatibles G.B.G.

## Installation

1. Placez le dossier `TousEnsemble` dans `World of Warcraft/Interface/AddOns/`.
2. Redémarrez le jeu ou utilisez `/reload`.
3. Ouvrez l’addon avec `/tousensemble` ou `/te`.

## Version 1.0.4

- Fermeture de l’interface avec `Échap`.
- Semi-transparence en combat.
- Semi-transparence pendant les déplacements.
- Opacité réduite réglable précisément de 20 % à 80 %.
- Transition douce entre opacité normale et réduite.

## Auteur

**Glayna**
