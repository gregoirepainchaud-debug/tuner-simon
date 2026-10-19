# Accords Simon — tuner dédié

App iPhone native (SwiftUI) pour accorder les pianos de Simon Tremblay quand
Grégoire le remplace : elle charge l'un des 14 accords décodés de son fichier
CyberTuner (Palais Montcalm et Grand Théâtre de Québec), mesure le **partiel de
référence** propre à chaque note et chaque accord, et affiche l'écart sur une
barre −30 à +30 cents à échelle non linéaire (le centre ±1 cent occupe la moitié
de la barre, vert seulement à ±0,1 cent). Pitch limité à 440-444 Hz, défaut
enregistrable par accord.

Distribution : GitHub Actions compile un `.ipa` non signé, publié dans la
Release `v1` avec un `apps.json` — source SideStore :
`https://github.com/gregoirepainchaud-debug/tuner-simon/releases/download/v1/apps.json`

Spec complète : voir le dossier projet (SPEC.md) chez Grégoire.
Données : `TunerSimon/tunings.json` (généré depuis le décodage du .rcta).
