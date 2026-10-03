# HappySpin

Une roue de la chance pour trancher : saisis une liste de choix, fais tourner la roue, et laisse le sort décider.

Application Flutter pour **iOS**, **Android** et **web**.

## Fonctionnalités

- Ajout et suppression de choix
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
```

## Structure

| Fichier | Rôle |
| --- | --- |
| `lib/src/wheel_math.dart` | Calculs d'angle : segment sous le pointeur, rotation cible |
| `lib/src/spinning_wheel.dart` | Dessin de la roue et du pointeur |
| `lib/src/home_page.dart` | Écran principal : liste des choix, animation, résultat |
