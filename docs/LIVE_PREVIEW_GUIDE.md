# Guide Aperçu Temps Réel, Émulateur Android & Audit Visuel (M11)

> **Rappel important** : Ce guide concerne le lancement et l'inspection de **l'application native Flutter réelle** (`mobile/`). Le tableau de bord HTML (`docs/preview/index.html`) est un outil de documentation et de galerie de captures ; il ne remplace jamais l'application Flutter.

## 1. Lancement Rapide de l'Application Réelle

### Option recommandée sur ce poste Windows (Microsoft Edge en direct)
```powershell
.\scripts\launch_preview.ps1 -Target edge -Port 8080
```
Ou directement :
```powershell
cd mobile
C:\flutter\bin\flutter.bat run -d edge --web-port 8080
```

### Lancement sur appareil Android physique ou émulateur (dès qu'un appareil est connecté)
```powershell
cd mobile
C:\flutter\bin\flutter.bat run -d android
```

---

## 2. Débogage & Hot Reload

```powershell
.\scripts\debug_preview.ps1 -Target edge -Port 8080
```
Dans la console interactive Flutter :
- **`r`** : **Hot Reload** (injecte vos modifications Dart en ~1s sans perdre l'état).
- **`R`** : **Hot Restart** (redémarre l'application depuis zéro).
- **`p`** : Affiche les bordures/grilles de mise en page pour inspecter espacements et alignements.
- **`v`** : Ouvre **Flutter DevTools** dans le navigateur (arbre de widgets, réseau, mémoire).

---

## 3. Configuration de l'Émulateur Android (AVD)

Lors de l'audit système de ce poste :
- `flutter devices` ne détecte aucun émulateur ni téléphone Android (`windows` et `edge` uniquement).
- Les composants SDK nécessaires (`C:\Android\sdk\emulator`, `cmdline-tools`, `system-images\android-36\google_apis_playstore\x86_64`) sont présents, **mais** :
  1. `systeminfo` indique `Virtualisation activée dans le microprogramme : Non` (VT-x désactivé dans le BIOS/UEFI).
  2. Le pilote `aehd` est arrêté (`WIN32_EXIT_CODE : 31`), `emulator-check accel` retourne code `6`.
  3. L'espace libre sur `C:` (~3,1 Go) est juste pour un AVD API 36 complet (~6–10 Go requis).

### Étapes pour activer l'émulateur Android sur cette machine :
1. Redémarrer le PC → entrer dans le BIOS/UEFI → activer **Intel Virtualization Technology (VT-x)**.
2. Libérer au moins **10 Go** sur le lecteur `C:`.
3. Exécuter dans un terminal Administrateur :
   ```powershell
   & "C:\Android\sdk\extras\google\Android_Emulator_Hypervisor_Driver\silent_install.bat"
   ```
4. Créer et démarrer l'AVD Pixel API 36 :
   ```powershell
   & "C:\Android\sdk\cmdline-tools\latest\bin\avdmanager.bat" create avd -n yitte_pixel_36 -k "system-images;android-36;google_apis_playstore;x86_64" -d pixel_6
   & "C:\Android\sdk\emulator\emulator.exe" -avd yitte_pixel_36
   ```
5. Vérifier et lancer :
   ```powershell
   C:\flutter\bin\flutter.bat devices
   cd mobile && C:\flutter\bin\flutter.bat run
   ```

---

## 4. Installation de l'APK sur Téléphone Android Physique

1. Sur le téléphone Android : **Paramètres → À propos du téléphone → Numéro de build** (appuyer 7 fois) → **Options pour les développeurs → Débogage USB**.
2. Brancher le câble USB et autoriser l'empreinte RSA sur le téléphone.
3. Vérifier la détection et installer le dernier APK Debug :
   ```powershell
   C:\Android\sdk\platform-tools\adb.exe devices
   C:\Android\sdk\platform-tools\adb.exe install -r "mobile\build\app\outputs\flutter-apk\app-debug.apk"
   ```
   *(Ou pour la version Release : `mobile\build\app\outputs\flutter-apk\app-release.apk`, ou copie manuelle du fichier `.apk` sur le téléphone pour installation locale).*

---

## 5. Tableau de Bord de Suivi & Galerie des Captures (Navigateur)

```powershell
node scripts\serve_audit_dashboard.mjs
```
Puis ouvrir **http://127.0.0.1:4173/** dans Edge/Chrome.

Pour régénérer automatiquement toutes les captures mobiles (`390×844` @2x) depuis l'application Flutter réelle :
```powershell
cd mobile && C:\flutter\bin\flutter.bat build web --no-tree-shake-icons && cd ..
node scripts\capture_screenshots.mjs
```
