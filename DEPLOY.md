# Guide de déploiement WordPress sur VPS Ubuntu

Ce guide vous explique comment déployer votre site WordPress sur un VPS Ubuntu avec Docker.

## 📋 Prérequis

- Un VPS Ubuntu (18.04+, 20.04, 22.04 ou 24.04)
- Un nom de domaine pointant vers votre VPS
- Accès SSH root ou sudo
- Au moins 1GB de RAM (2GB recommandé)

## 🚀 Étape 1 : Préparer votre VPS

### Connexion SSH

```bash
ssh root@votre-ip-vps
# ou
ssh votre-utilisateur@votre-ip-vps
```

### Installation de Docker et Docker Compose

```bash
# Mise à jour du système
sudo apt update && sudo apt upgrade -y

# Installation des dépendances
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Ajout du dépôt Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Installation de Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Démarrer Docker
sudo systemctl start docker
sudo systemctl enable docker

# Vérifier l'installation
docker --version
docker compose version
```

### Ajouter votre utilisateur au groupe Docker (optionnel)

```bash
sudo usermod -aG docker $USER
# Déconnectez-vous et reconnectez-vous pour appliquer
```

## 🌐 Étape 2 : Configurer votre nom de domaine

### Configuration DNS

Chez votre registrar (OVH, Gandi, Namecheap, etc.), créez ces enregistrements DNS :

```
Type    Nom             Valeur              TTL
A       @               IP.DE.VOTRE.VPS     3600
A       www             IP.DE.VOTRE.VPS     3600
```

**Vérification** (attendre 5-30 minutes pour la propagation) :
```bash
ping votre-domaine.com
ping www.votre-domaine.com
```

## 📁 Étape 3 : Déployer les fichiers sur le VPS

### Méthode 1 : Cloner depuis Git (recommandé)

```bash
# Sur votre VPS
cd /home/votre-utilisateur
git clone https://github.com/votre-username/Decouverte_WordPress.git
cd Decouverte_WordPress
```

### Méthode 2 : Copie manuelle via SCP

```bash
# Depuis votre machine locale
scp -r /chemin/vers/Decouverte_WordPress votre-utilisateur@votre-ip-vps:/home/votre-utilisateur/
```

## 🔧 Étape 4 : Configuration pour la production

### Créer le fichier de configuration production

```bash
cd /home/votre-utilisateur/Decouverte_WordPress
cp .env.example .env
nano .env
```

### Modifier le .env pour la production

```bash
# Configuration de la base de données MySQL
MYSQL_DATABASE=wordpress_prod
MYSQL_USER=wordpress_user
MYSQL_PASSWORD=MOT_DE_PASSE_FORT_ICI  # ⚠️ Changez ceci !
MYSQL_ROOT_PASSWORD=MOT_DE_PASSE_ROOT_FORT  # ⚠️ Changez ceci !

# Domaine
DOMAIN=votre-domaine.com
WORDPRESS_URL=https://votre-domaine.com

# Ports (80 et 443 pour production)
HTTP_PORT=80
HTTPS_PORT=443

# PhpMyAdmin (désactivé en production ou port non standard)
PHPMYADMIN_PORT=9999

# Mode debug WordPress (false en production)
WORDPRESS_DEBUG=false

# Email pour Let's Encrypt SSL
LETSENCRYPT_EMAIL=votre-email@example.com
```

## 🐳 Étape 5 : Utiliser la configuration production

Vous avez deux options :

### Option A : Configuration simple (sans SSL automatique)

Utilisez le `docker-compose.yml` actuel mais modifiez les ports dans `.env` :

```bash
WORDPRESS_PORT=80
PHPMYADMIN_PORT=8081
```

Lancez les containers :

```bash
docker compose up -d
```

**Accès** : http://votre-domaine.com

### Option B : Configuration complète avec Nginx + SSL Let's Encrypt (recommandé)

Utilisez le fichier `docker-compose.production.yml` fourni.

```bash
# Lancer la stack production
docker compose -f docker-compose.production.yml up -d
```

**Accès** : https://votre-domaine.com (SSL automatique)

## 🔒 Étape 6 : Sécuriser votre installation

### Pare-feu (UFW)

```bash
# Activer le pare-feu
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Vérifier le statut
sudo ufw status
```

### Désactiver PhpMyAdmin en production

Dans `.env`, commentez ou supprimez le service phpmyadmin, ou utilisez un port non standard avec restriction IP.

### Mettre à jour les clés de sécurité WordPress

Après le premier déploiement, générez des clés uniques :

1. Visitez : https://api.wordpress.org/secret-key/1.1/salt/
2. Copiez les clés
3. Ajoutez-les dans votre configuration Docker (voir docker-compose.production.yml)

## 📊 Étape 7 : Migration depuis votre environnement local

### Méthode 1 : Plugin WordPress (facile)

1. **Sur votre site local**, installez le plugin **All-in-One WP Migration**
2. Allez dans `All-in-One WP Migration > Export`
3. Téléchargez le fichier
4. **Sur votre VPS**, installez le même plugin
5. Allez dans `All-in-One WP Migration > Import`
6. Importez le fichier

### Méthode 2 : Manuelle (avancé)

#### Exporter la base de données locale

```bash
# Sur votre machine locale
docker exec wordpress_db mysqldump -u wordpress -pwordpress wordpress > backup.sql
```

#### Copier les fichiers WordPress

```bash
# Exporter le volume WordPress
docker cp wordpress_app:/var/www/html ./wordpress_files

# Copier vers le VPS
scp -r wordpress_files votre-utilisateur@votre-ip-vps:/tmp/
scp backup.sql votre-utilisateur@votre-ip-vps:/tmp/
```

#### Importer sur le VPS

```bash
# Sur le VPS - Importer les fichiers
docker cp /tmp/wordpress_files/. wordpress_app:/var/www/html

# Importer la base de données
docker exec -i wordpress_db mysql -u root -p${MYSQL_ROOT_PASSWORD} wordpress_prod < /tmp/backup.sql
```

#### Mettre à jour les URLs

```bash
# Connexion à la base de données
docker exec -it wordpress_db mysql -u root -p${MYSQL_ROOT_PASSWORD} wordpress_prod

# Remplacer les URLs
UPDATE wp_options SET option_value = 'https://votre-domaine.com' WHERE option_name = 'siteurl';
UPDATE wp_options SET option_value = 'https://votre-domaine.com' WHERE option_name = 'home';
exit;
```

## 🔄 Commandes utiles sur le VPS

### Voir les logs

```bash
docker compose logs -f
docker compose logs -f wordpress
```

### Redémarrer les services

```bash
docker compose restart
```

### Arrêter les services

```bash
docker compose down
```

### Mettre à jour WordPress

```bash
docker compose pull
docker compose up -d
```

### Sauvegardes automatiques

Créez un script de sauvegarde :

```bash
nano /home/votre-utilisateur/backup-wordpress.sh
```

```bash
#!/bin/bash
BACKUP_DIR="/home/votre-utilisateur/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Sauvegarde de la base de données
docker exec wordpress_db mysqldump -u root -p${MYSQL_ROOT_PASSWORD} wordpress_prod > $BACKUP_DIR/db_$DATE.sql

# Sauvegarde des fichiers WordPress
docker exec wordpress_app tar -czf /tmp/wp_files_$DATE.tar.gz -C /var/www/html .
docker cp wordpress_app:/tmp/wp_files_$DATE.tar.gz $BACKUP_DIR/

# Garder seulement les 7 dernières sauvegardes
find $BACKUP_DIR -type f -mtime +7 -delete

echo "Sauvegarde terminée : $DATE"
```

Rendre le script exécutable :

```bash
chmod +x /home/votre-utilisateur/backup-wordpress.sh
```

Ajouter au cron (tous les jours à 2h du matin) :

```bash
crontab -e
# Ajouter cette ligne :
0 2 * * * /home/votre-utilisateur/backup-wordpress.sh
```

## 🐛 Dépannage

### Les containers ne démarrent pas

```bash
docker compose logs
```

### WordPress affiche "Error establishing a database connection"

Vérifiez les variables d'environnement dans `.env` et redémarrez :

```bash
docker compose down
docker compose up -d
```

### Erreur de permissions

```bash
docker exec wordpress_app chown -R www-data:www-data /var/www/html
```

### Vérifier l'état des containers

```bash
docker compose ps
docker stats
```

## 📈 Optimisations production

### 1. Activer le cache

Installez le plugin **WP Super Cache** ou **W3 Total Cache**

### 2. Optimiser les images

Plugin : **Smush** ou **ShortPixel**

### 3. Utiliser un CDN

Services : Cloudflare (gratuit), BunnyCDN, etc.

### 4. Limiter les ressources Docker

Éditez `docker-compose.production.yml` pour ajouter des limites :

```yaml
services:
  wordpress:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
```

## 🎯 Checklist de déploiement

- [ ] Docker installé sur le VPS
- [ ] Nom de domaine configuré (DNS)
- [ ] Fichier `.env` configuré avec mots de passe forts
- [ ] Pare-feu configuré (ports 80, 443, 22)
- [ ] SSL activé (Let's Encrypt)
- [ ] Migration des données effectuée
- [ ] URLs mises à jour dans la base de données
- [ ] Sauvegardes automatiques configurées
- [ ] PhpMyAdmin désactivé ou sécurisé
- [ ] WordPress mis à jour
- [ ] Plugins de sécurité installés (Wordfence, iThemes Security)

## 🔗 Ressources utiles

- [Documentation Docker](https://docs.docker.com/)
- [WordPress.org](https://wordpress.org/)
- [Let's Encrypt](https://letsencrypt.org/)

---

Bon déploiement ! 🚀
