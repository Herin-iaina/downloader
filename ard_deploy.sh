#!/bin/bash

# Script de déploiement pour Apple Remote Desktop
# Ce script doit être placé dans le même dossier que macos_downloader.pkg

# Vérifier si le package existe
if [ ! -f "macos_downloader.pkg" ]; then
    echo "Erreur: macos_downloader.pkg non trouvé dans le répertoire courant"
    exit 1
fi

# Vérifier si l'installation est nécessaire
if [ -f "/usr/local/bin/macosdownloader" ]; then
    echo "macOS Downloader est déjà installé. Mise à jour en cours..."
    /usr/local/bin/macosdownloader --uninstall
fi

# Installer le package
echo "Installation de macOS Downloader..."
installer -pkg "macos_downloader.pkg" -target /

# Vérifier l'installation
if [ -f "/usr/local/bin/macosdownloader" ]; then
    echo "Installation réussie"
    
    # Démarrer le téléchargement
    echo "Démarrage du téléchargement..."
    /usr/local/bin/macosdownloader start
    
    # Vérifier les logs
    echo "Vérification des logs..."
    if [ -f "/var/tmp/macos_installer_client.log" ]; then
        echo "Dernières lignes du log :"
        tail -n 5 "/var/tmp/macos_installer_client.log"
    else
        echo "Aucun fichier de log trouvé"
    fi
else
    echo "Erreur: Installation échouée"
    exit 1
fi

exit 0 