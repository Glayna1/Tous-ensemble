TOUS ENSEMBLE — v1.0.4
=======================

Installation
------------
1. Copiez le dossier "TousEnsemble" dans Interface\AddOns\.
2. Redémarrez le jeu ou utilisez /reload.
3. Ouvrez l'addon avec /tousensemble ou /te.

Fonctions principales
---------------------
- Recherche et création d'activités à l'échelle du serveur entre utilisateurs de Tous ensemble.
- Inscriptions automatiques ou validation manuelle par le chef.
- Rôles Tank, Soigneur, Dégâts et Soutien.
- Invitation silencieuse par la commande /invite, compatible Ascension inter-faction.
- Profil personnalisé avec 132 portraits intégrés.
- Notifications pour les nouvelles activités, inscriptions et acceptations.
- Mini bouton déplaçable affichant le nombre de groupes visibles.
- Recherche de guilde et candidatures compatibles avec le protocole de G.B.G.
- Publication d'une annonce de guilde lorsque G.B.G n'est pas installé.
- Passerelle Dungeon Finder G.B.G pour les membres de la même guilde.

Filtre FR / All
---------------
- Une activité créée avec FR est visible dans les filtres FR et All.
- Une activité créée avec All est visible uniquement dans le filtre All.
- Le filtre choisi est sauvegardé dans le profil et s'applique également aux notifications.
- Les anciennes activités G.B.G, qui ne possèdent pas ce champ, sont considérées comme All.

Compatibilité G.B.G
-------------------
Tous ensemble est totalement autonome et peut fonctionner sans G.B.G.
Lorsqu'un personnage est dans une guilde :
- les activités créées dans Tous ensemble sont également annoncées aux utilisateurs G.B.G de la guilde ;
- les inscriptions faites depuis le Dungeon Finder de G.B.G sont reçues par le créateur Tous ensemble ;
- les activités de guilde G.B.G apparaissent dans Tous ensemble ;
- le portrait Tous ensemble est partagé avec les profils G.B.G ;
- la recherche de guilde utilise les mêmes annonces et candidatures que G.B.G.

Absence de conflit
------------------
- SavedVariables séparées : TousEnsembleDB.
- Espace global séparé : TousEnsemble.
- Canal serveur et protocole propres pour les activités hors guilde.
- Aucun fichier ni réglage de G.B.G n'est modifié.
- Si G.B.G est installé, il reste l'unique autorité pour publier l'annonce de la guilde.

Transport
---------
- Canal communautaire caché : TousEnsemble.
- Canal de recrutement compatible G.B.G : GBGRecruit.
- Les canaux sont retirés des fenêtres de discussion et rejoints automatiquement si nécessaire.
- Le trafic est fragmenté et limité pour rester compatible avec WoW 3.3.5a / Ascension.

Version
-------
1.0.4 — Fermeture par Échap et semi-transparence en combat/déplacement.
1.0.3 — Échelle minimale abaissée à 50 %.
1.0.2 — Boutons - / + fiables pour régler l’échelle au pourcent près.
1.0.1 — Correctifs d’interface, français par défaut et échelle au pourcent près.
1.0.0 — Première version autonome.

Interface
---------
- Français par défaut, indépendamment de la langue du client.
- Choix Français / English dans l’onglet Profil.
- Échelle réglable de 50 % à 125 % par pas exact de 1 %.
- L’état interne de la passerelle G.B.G n’est pas affiché dans l’en-tête.
- La touche Échap ferme la fenêtre principale et les fenêtres secondaires.
- Semi-transparence optionnelle pendant les combats et/ou les déplacements.
- Opacité réduite réglable de 20 % à 80 % par pas de 1 %.
