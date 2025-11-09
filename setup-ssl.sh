#!/bin/bash

# Script de configuration SSL pour WordPress en production
# Usage: ./setup-ssl.sh votre-domaine.com votre-email@example.com

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction d'affichage
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérification des arguments
if [ "$#" -ne 2 ]; then
    print_error "Usage: $0 <domaine> <email>"
    echo "Exemple: $0 example.com admin@example.com"
    exit 1
fi

DOMAIN=$1
EMAIL=$2

print_info "Configuration SSL pour le domaine: $DOMAIN"
print_info "Email Let's Encrypt: $EMAIL"

# Vérification que le domaine pointe vers ce serveur
print_info "Vérification DNS..."
SERVER_IP=$(curl -s ifconfig.me)
DOMAIN_IP=$(dig +short $DOMAIN | tail -n1)

if [ "$SERVER_IP" != "$DOMAIN_IP" ]; then
    print_warning "Le domaine $DOMAIN ne pointe pas vers ce serveur ($SERVER_IP)"
    print_warning "IP actuelle du domaine: $DOMAIN_IP"
    read -p "Voulez-vous continuer quand même? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Créer les dossiers nécessaires
print_info "Création des dossiers..."
mkdir -p nginx/conf.d
mkdir -p certbot/conf
mkdir -p certbot/www

# Créer la configuration nginx temporaire (sans SSL)
print_info "Création de la configuration nginx temporaire..."
cat > nginx/conf.d/wordpress.conf << EOF
# Configuration HTTP temporaire pour obtenir le certificat SSL
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN} www.${DOMAIN};

    # Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # Temporaire: proxy vers WordPress
    location / {
        proxy_pass http://wordpress:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Vérifier si .env existe
if [ ! -f .env ]; then
    print_warning "Le fichier .env n'existe pas. Copie de .env.example..."
    cp .env.example .env
    print_warning "Veuillez modifier .env avec vos informations avant de continuer!"
    exit 1
fi

# Mettre à jour .env avec le domaine
print_info "Mise à jour du fichier .env..."
sed -i "s/^DOMAIN=.*/DOMAIN=${DOMAIN}/" .env
sed -i "s/^LETSENCRYPT_EMAIL=.*/LETSENCRYPT_EMAIL=${EMAIL}/" .env
sed -i "s/^HTTP_PORT=.*/HTTP_PORT=80/" .env
sed -i "s/^HTTPS_PORT=.*/HTTPS_PORT=443/" .env

# Démarrer les services (sans SSL)
print_info "Démarrage des containers (sans SSL)..."
docker compose -f docker-compose.production.yml up -d wordpress db nginx

# Attendre que nginx soit prêt
print_info "Attente du démarrage de nginx..."
sleep 10

# Obtenir le certificat SSL
print_info "Obtention du certificat SSL Let's Encrypt..."
docker compose -f docker-compose.production.yml run --rm certbot certonly \
    --webroot \
    --webroot-path /var/www/certbot \
    --email ${EMAIL} \
    --agree-tos \
    --no-eff-email \
    -d ${DOMAIN} \
    -d www.${DOMAIN}

if [ $? -ne 0 ]; then
    print_error "Échec de l'obtention du certificat SSL"
    print_error "Vérifiez que votre domaine pointe bien vers ce serveur"
    exit 1
fi

print_info "Certificat SSL obtenu avec succès!"

# Créer la configuration nginx finale (avec SSL)
print_info "Création de la configuration nginx finale avec SSL..."
sed "s/VOTRE_DOMAINE/${DOMAIN}/g" nginx/conf.d/wordpress.conf.template > nginx/conf.d/wordpress.conf

# Redémarrer nginx pour appliquer la nouvelle configuration
print_info "Redémarrage de nginx avec SSL..."
docker compose -f docker-compose.production.yml restart nginx

# Démarrer certbot pour le renouvellement automatique
print_info "Démarrage du service de renouvellement automatique SSL..."
docker compose -f docker-compose.production.yml up -d certbot

print_info "╔════════════════════════════════════════════════════════╗"
print_info "║                 CONFIGURATION TERMINÉE                 ║"
print_info "╚════════════════════════════════════════════════════════╝"
echo ""
print_info "Votre site WordPress est accessible à:"
print_info "  → https://${DOMAIN}"
print_info "  → https://www.${DOMAIN}"
echo ""
print_info "Le certificat SSL sera renouvelé automatiquement tous les 90 jours"
echo ""
print_info "Commandes utiles:"
echo "  - Voir les logs: docker compose -f docker-compose.production.yml logs -f"
echo "  - Redémarrer: docker compose -f docker-compose.production.yml restart"
echo "  - Arrêter: docker compose -f docker-compose.production.yml down"
echo ""
print_warning "N'oubliez pas de:"
echo "  1. Terminer l'installation WordPress sur https://${DOMAIN}"
echo "  2. Configurer le pare-feu (ufw allow 80/tcp && ufw allow 443/tcp)"
echo "  3. Configurer les sauvegardes automatiques"
