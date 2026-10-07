# HappySpin

[![CI/CD](https://github.com/qnope/happyspin/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/qnope/happyspin/actions/workflows/ci-cd.yml)

**Essayer en ligne : https://qnope.github.io/HappySpin/**

Une roue de la chance pour trancher : saisis une liste de choix, fais tourner la roue, et laisse le sort décider.

Application Flutter pour **iOS**, **Android** et **web**.

## Fonctionnalités

- Plusieurs listes de choix : création, changement, renommage et suppression depuis le titre
- Listes sauvegardées sur l'appareil (stockage local du navigateur sur le web)
- Ajout, renommage et suppression de choix ; couleur de chaque choix au choix (nuancier ou code hexadécimal)
- Roue colorée qui se redessine à chaque modification
- Animation de rotation avec décélération, tirage uniforme
- Affichage du choix gagnant
- Mise en page adaptée au mobile et aux grands écrans, thème clair et sombre

## Lancer le projet

```sh
flutter pub get
flutter run                # appareil ou simulateur connecté
flutter run -d chrome      # web
```

## Tests

```sh
flutter analyze
flutter test

# Tests d'intégration (nécessite chromedriver sur le port 4444)
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart -d web-server --browser-name=chrome
```

## CI/CD

Le workflow `.github/workflows/ci-cd.yml` tourne sur chaque PR et chaque push sur `main` :

- analyse, format et tests unitaires
- tests d'intégration dans Chrome
- builds Android (APK en artefact), iOS (sans signature) et web
- sur `main`, déploiement du build web sur GitHub Pages si tout est vert

## Structure

| Fichier | Rôle |
| --- | --- |
| `lib/src/wheel_math.dart` | Calculs d'angle : segment sous le pointeur, rotation cible |
| `lib/src/spinning_wheel.dart` | Dessin de la roue et du pointeur |
| `lib/src/choice_lists.dart` | Listes de choix et leur sauvegarde sur l'appareil |
| `lib/src/home_page.dart` | Écran principal : listes et choix, animation, résultat |
