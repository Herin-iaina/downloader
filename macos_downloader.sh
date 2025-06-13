#!/bin/bash

# Configuration
SERVER_URL="http://172.17.18.149:5001"
TEMP_DIR="/var/tmp"
LOG_FILE="/var/tmp/macos_installer_client.log"
APP_NAME="macOS downloader"
PROGRESS_WINDOW_ID=""

# Fonction pour afficher une boîte de dialogue (version compatible)
show_dialog() {
    local title="$1"
    local message="$2"
    local type="$3"  # info, warning, error
    
    # Utiliser une approche plus basique pour la compatibilité
    if [ "$type" = "stop" ]; then
        echo "ERREUR: $message" >&2
    else
        echo "INFO: $message"
    fi
}

# Fonction pour créer la fenêtre de progression
create_progress_window() {
    if command -v osascript >/dev/null 2>&1; then
        PROGRESS_WINDOW_ID=$(osascript <<EOF 2>/dev/null
        tell application "System Events"
            set progressWindow to display dialog "Message de l'IT :

Un processus de téléchargement est en cours.
Merci de ne pas éteindre votre Mac pendant cette opération.

Le processus se terminera automatiquement." with title "$APP_NAME" with icon note buttons {"OK"} default button "OK" giving up after 3600
            return id of progressWindow
        end tell
EOF
        )
    fi
}

# Fonction pour mettre à jour la fenêtre de progression
update_progress() {
    local message="$1"
    local progress="$2"
    
    echo "Progression ($progress%): $message"
    
    if [ -n "$PROGRESS_WINDOW_ID" ] && command -v osascript >/dev/null 2>&1; then
        osascript <<EOF 2>/dev/null || true
        tell application "System Events"
            set progressWindow to window id $PROGRESS_WINDOW_ID
            set description of progressWindow to "Message de l'IT :

$message

Progression: $progress%

Merci de ne pas éteindre votre Mac pendant cette opération."
        end tell
EOF
    fi
}

# Fonction pour fermer la fenêtre de progression
close_progress_window() {
    if [ -n "$PROGRESS_WINDOW_ID" ] && command -v osascript >/dev/null 2>&1; then
        osascript <<EOF 2>/dev/null || true
        tell application "System Events"
            close window id $PROGRESS_WINDOW_ID
        end tell
EOF
    fi
}

# Fonction de logging
log() {
    local level=$1
    shift
    local message="$*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$LOG_FILE"
}

# Vérification des prérequis
check_prerequisites() {
    log "INFO" "Vérification des prérequis..."
    update_progress "Vérification des prérequis..." "0"
    
    # Vérifier si le dossier de destination est accessible en écriture
    if [ ! -w "$TEMP_DIR" ]; then
        log "ERROR" "Le dossier $TEMP_DIR n'est pas accessible en écriture"
        return 1
    fi

    # Vérifier l'espace disque disponible (20 GB minimum)
    local required_space=$((20 * 1024 * 1024))  # 20 GB en KB
    local available_space=$(df -k "$TEMP_DIR" | awk 'NR==2 {print $4}')
    
    if [ "$available_space" -lt "$required_space" ]; then
        log "ERROR" "Espace insuffisant: $((available_space/1024/1024))GB disponible, 20GB requis"
        return 1
    fi

    # Vérifier si unzip est installé
    if ! command -v unzip &> /dev/null; then
        log "ERROR" "unzip n'est pas installé"
        return 1
    fi

    update_progress "Prérequis vérifiés avec succès" "10"
    return 0
}

# Téléchargement et décompression d'un fichier
download_file() {
    local filename=$1
    # URL encode le nom du fichier
    local encoded_filename=$(echo "$filename" | sed 's/ /%20/g')
    local url="${SERVER_URL}/files/${encoded_filename}"
    local destination="${TEMP_DIR}/${filename}"
    
    log "INFO" "Téléchargement de $filename..."
    update_progress "Téléchargement de $filename..." "20"
    
    # Supprimer l'ancien fichier/dossier s'il existe
    if [ -e "$destination" ]; then
        rm -rf "$destination"
        log "INFO" "Ancien fichier/dossier supprimé: $destination"
    fi
    
    # Créer le dossier parent si nécessaire
    local parent_dir=$(dirname "$destination")
    mkdir -p "$parent_dir"
    
    # Télécharger le fichier avec curl
    if curl -L -o "$destination" "$url" 2>>"$LOG_FILE"; then
        log "INFO" "Fichier téléchargé avec succès: $filename"
        update_progress "Fichier téléchargé avec succès: $filename" "50"
        
        # Si c'est un fichier zip, le décompresser
        if [[ "$filename" == *.zip ]]; then
            log "INFO" "Décompression de $filename..."
            update_progress "Décompression de $filename..." "75"
            
            local extract_dir="${TEMP_DIR}/$(basename "$filename" .zip)"
            
            # Supprimer le dossier de destination s'il existe
            if [ -d "$extract_dir" ]; then
                rm -rf "$extract_dir"
            fi
            
            # Décompresser le fichier
            if unzip -q "$destination" -d "$TEMP_DIR"; then
                log "INFO" "Fichier décompressé avec succès dans $extract_dir"
                update_progress "Décompression terminée" "90"
                
                # Supprimer le fichier zip après décompression
                rm -f "$destination"
                log "INFO" "Fichier zip supprimé: $filename"
            else
                log "ERROR" "Erreur lors de la décompression de $filename"
                return 1
            fi
        fi
        return 0
    else
        log "ERROR" "Erreur lors du téléchargement de $filename"
        return 1
    fi
}

# Téléchargement de tous les fichiers
download_all_files() {
    # Obtenir la liste des fichiers
    local files_json
    files_json=$(curl -s "${SERVER_URL}/files")
    
    if [ $? -ne 0 ]; then
        log "ERROR" "Erreur lors de la récupération de la liste des fichiers"
        return 1
    fi
    
    # Extraire les noms de fichiers du JSON en préservant les espaces
    local files
    files=$(echo "$files_json" | grep -o '"name":"[^"]*"' | sed 's/"name":"//g' | sed 's/"//g')
    
    if [ -z "$files" ]; then
        log "WARNING" "Aucun fichier trouvé sur le serveur"
        return 1
    fi
    
    log "INFO" "Téléchargement des fichiers..."
    
    # Télécharger chaque fichier
    local success=true
    while IFS= read -r filename; do
        if [ -n "$filename" ]; then
            if ! download_file "$filename"; then
                success=false
                break
            fi
        fi
    done <<< "$files"
    
    if $success; then
        log "INFO" "Tous les fichiers ont été téléchargés avec succès"
        update_progress "Installation terminée avec succès" "100"
        return 0
    else
        return 1
    fi
}

# Fonction principale
main() {
    # Vérifier si le script est exécuté en tant que root
    if [ "$(id -u)" != "0" ]; then
        echo "Ce script doit être exécuté en tant que root (sudo)"
        exit 1
    fi

    log "INFO" "Démarrage de l'installation"
    
    # Créer la fenêtre de progression
    create_progress_window
    
    # Vérifier les prérequis
    if ! check_prerequisites; then
        log "ERROR" "Les prérequis ne sont pas satisfaits"
        close_progress_window
        exit 1
    fi
    
    # Créer le dossier temporaire si nécessaire
    mkdir -p "$TEMP_DIR"
    chmod 777 "$TEMP_DIR"
    
    # Télécharger tous les fichiers
    if ! download_all_files; then
        log "ERROR" "Échec du téléchargement des fichiers"
        close_progress_window
        exit 1
    fi
    
    log "INFO" "Installation terminée avec succès"
    
    # Attendre un peu avant de fermer la fenêtre
    sleep 2
    close_progress_window
}

# Exécuter le script principal
main