#!/bin/bash

# Créer le répertoire temporaire pour la construction
BUILD_DIR="build"
mkdir -p "$BUILD_DIR/scripts"
mkdir -p "$BUILD_DIR/root/usr/local/bin"

# Copier les fichiers
cp macos_downloader.sh "$BUILD_DIR/root/usr/local/bin/"
cp macosdownloader "$BUILD_DIR/root/usr/local/bin/"
cp postinstall "$BUILD_DIR/scripts/"

# Rendre les scripts exécutables
chmod +x "$BUILD_DIR/root/usr/local/bin/macos_downloader.sh"
chmod +x "$BUILD_DIR/root/usr/local/bin/macosdownloader"
chmod +x "$BUILD_DIR/scripts/postinstall"

# Construire le package
pkgbuild --root "$BUILD_DIR/root" \
         --scripts "$BUILD_DIR/scripts" \
         --identifier "com.smartelia.macosdownloader" \
         --version "1.0" \
         --install-location "/" \
         "macos_downloader.pkg"

# Nettoyer
rm -rf "$BUILD_DIR"

echo "Package créé avec succès: macos_downloader.pkg" 