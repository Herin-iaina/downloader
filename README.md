# macOS Downloader

Un outil de téléchargement automatisé pour macOS avec interface graphique.

## Description

macOS Downloader est un outil qui permet de télécharger et d'installer automatiquement des fichiers depuis un serveur spécifié. L'application affiche une interface graphique pour informer l'utilisateur de la progression du téléchargement.

## Prérequis

- macOS 10.13 ou supérieur
- Droits administrateur pour l'installation
- Au moins 20 Go d'espace disque disponible
- Connexion Internet active

## Installation

### Méthode 1 : Installation via le package

1. Téléchargez le fichier `macos_downloader.pkg`
2. Double-cliquez sur le fichier pour lancer l'installation
3. Suivez les instructions de l'assistant d'installation

### Méthode 2 : Installation manuelle

1. Copiez le fichier `macos_downloader.sh` dans `/usr/local/bin/`
2. Rendez le script exécutable :
   ```bash
   sudo chmod +x /usr/local/bin/macos_downloader.sh
   ```

## Utilisation

### Lancer le téléchargement

```bash
macosdownloader start
```

### Lancer le téléchargement en arrière-plan

```bash
macosdownloader --detach
```
Cette commande exécute le téléchargement en arrière-plan et continue même si la connexion est interrompue. Les logs sont disponibles dans `/var/log/macos_downloader.log`.

### Désinstaller l'application

```bash
macosdownloader --uninstall
```

### Afficher l'aide

```bash
macosdownloader --help
```

## Utilisation via Apple Remote Desktop (ARD)

### Installation à distance

1. Dans Apple Remote Desktop, sélectionnez les ordinateurs cibles
2. Utilisez la commande "Copier" pour transférer le fichier `macos_downloader.pkg`
3. Exécutez la commande suivante sur les ordinateurs cibles :
   ```bash
   installer -pkg /chemin/vers/macos_downloader.pkg -target /
   ```

### Déploiement automatisé

Pour déployer et exécuter automatiquement sur plusieurs machines :

1. Créez un script de déploiement :
   ```bash
   #!/bin/bash
   installer -pkg /chemin/vers/macos_downloader.pkg -target /
   /usr/local/bin/macosdownloader --detach
   ```

2. Dans ARD, utilisez la fonction "Exécuter une commande" pour lancer le script

### Commandes ARD utiles

Pour vérifier l'installation :
```bash
ls -l /usr/local/bin/macosdownloader
```

Pour vérifier les logs :
```bash
cat /var/log/macos_downloader.log
```

Pour désinstaller à distance :
```bash
/usr/local/bin/macosdownloader --uninstall
```

### Bonnes pratiques ARD

1. Testez d'abord sur un petit groupe de machines
2. Vérifiez les logs après le déploiement
3. Utilisez les groupes ARD pour organiser les déploiements
4. Planifiez les déploiements en dehors des heures de pointe
5. Surveillez l'utilisation du réseau pendant le déploiement

## Fonctionnalités

- Interface graphique de progression
- Téléchargement automatique des fichiers
- Décompression automatique des archives ZIP
- Vérification des prérequis (espace disque, permissions)
- Journalisation des opérations

## Fichiers de log

Les logs sont stockés dans :
```
/var/log/macos_downloader.log
```

## Configuration

Le script utilise les paramètres suivants (modifiables dans le script) :

- `SERVER_URL` : URL du serveur de téléchargement
- `TEMP_DIR` : Répertoire temporaire pour les téléchargements
- `LOG_FILE` : Emplacement du fichier de log (`/var/log/macos_downloader.log`)

## Dépannage

Si vous rencontrez des problèmes :

1. Vérifiez les logs dans `/var/log/macos_downloader.log`
2. Assurez-vous d'avoir les droits administrateur
3. Vérifiez votre connexion Internet
4. Assurez-vous d'avoir suffisamment d'espace disque (20 Go minimum)

## Support

Pour toute question ou problème, veuillez contacter le support IT.

## Licence

© 2024 Smartelia. Tous droits réservés. 