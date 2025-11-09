# Déploiement WordPress avec nginx existant

Ce guide est pour déployer WordPress sur un VPS qui a **déjà nginx installé**.

## 🎯 Architecture

```
Internet → nginx (système) → WordPress (Docker sur port 8083)
                           → Vos APIs Symfony (ports 8080, 8082)
```

## 📋 Étape 1 : Déployer WordPress avec Docker

### Sur votre VPS

```bash
# 1. Cloner ou copier le projet
cd /home/ubuntu
git clone https://github.com/votre-username/Decouverte_WordPress.git wordpress
cd wordpress

# 2. Copier et configurer .env
cp .env.example .env
nano .env
```

### Modifier le .env

```bash
# Base de données
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress
MYSQL_PASSWORD=UN_MOT_DE_PASSE_FORT  # ⚠️ Changez ceci !
MYSQL_ROOT_PASSWORD=UN_AUTRE_MOT_DE_PASSE  # ⚠️ Changez ceci !

# Port WordPress (choisir un port libre, ex: 8083)
WORDPRESS_PORT=8083

# PhpMyAdmin (optionnel, ou désactiver en production)
PHPMYADMIN_PORT=8084

# Debug (false en production)
WORDPRESS_DEBUG=false
```

### Lancer WordPress

```bash
docker compose up -d
```

Vérifiez que ça fonctionne :
```bash
docker compose ps
curl http://localhost:8083
```

## 📡 Étape 2 : Configurer nginx

Vous avez **deux options** :

### Option A : Sous-domaine (recommandé)

Exemple : `blog.james-johnson.fr` ou `wp.james-johnson.fr`

#### 1. Ajouter l'enregistrement DNS

Chez votre registrar, ajoutez :
```
Type A : blog → 91.134.240.112
```

#### 2. Créer la configuration nginx

```bash
sudo nano /etc/nginx/sites-available/wordpress
```

Contenu :

```nginx
server {
    listen 80;
    server_name blog.james-johnson.fr;

    # Redirection vers HTTPS (sera géré par Certbot)
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name blog.james-johnson.fr;

    # Certificats SSL (à obtenir avec Certbot - voir étape 3)
    ssl_certificate /etc/letsencrypt/live/blog.james-johnson.fr/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/blog.james-johnson.fr/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Headers de sécurité
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Taille max upload
    client_max_body_size 100M;

    # Proxy vers WordPress Docker
    location / {
        proxy_pass http://localhost:8083;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;

        # Buffers pour WordPress
        proxy_buffering off;
        proxy_request_buffering off;
    }

    # Logs
    access_log /var/log/nginx/wordpress_access.log;
    error_log /var/log/nginx/wordpress_error.log;
}
```

#### 3. Activer et obtenir le SSL

```bash
# Activer le site (sans SSL d'abord)
sudo ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Obtenir le certificat SSL
sudo certbot --nginx -d blog.james-johnson.fr

# Certbot va modifier automatiquement la config nginx
```

---

### Option B : Sous-chemin (plus simple mais moins recommandé)

Exemple : `james-johnson.fr/blog`

Ajoutez ceci dans votre fichier `/etc/nginx/sites-available/portfolio` existant, **dans le bloc server HTTPS (port 443)** :

```nginx
server {
    # ... votre config existante ...

    # WordPress sur /blog
    location /blog {
        proxy_pass http://localhost:8083;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Important pour WordPress
        proxy_redirect off;
    }

    # ... reste de votre config ...
}
```

⚠️ **Attention** : WordPress n'aime pas trop les sous-chemins, vous devrez configurer l'URL dans WordPress après installation.

---

## ✅ Étape 3 : Finaliser l'installation WordPress

### Pour un sous-domaine

1. Accédez à `https://blog.james-johnson.fr`
2. Suivez l'installation WordPress
3. Remplissez les informations du site
4. Terminé ! ✅

### Pour un sous-chemin

1. Accédez à `https://james-johnson.fr/blog`
2. Suivez l'installation
3. Après installation, configurez les URLs :
   - Connexion : `https://james-johnson.fr/blog/wp-admin`
   - Dans **Réglages → Général** :
     - Adresse web de WordPress (URL) : `https://james-johnson.fr/blog`
     - Adresse web du site (URL) : `https://james-johnson.fr/blog`

## 🔧 Commandes utiles

```bash
# Voir les containers WordPress
cd /home/ubuntu/wordpress
docker compose ps

# Voir les logs
docker compose logs -f wordpress

# Redémarrer WordPress
docker compose restart

# Arrêter WordPress
docker compose down

# Tester nginx
sudo nginx -t

# Recharger nginx
sudo systemctl reload nginx

# Voir les logs nginx
sudo tail -f /var/log/nginx/wordpress_access.log
sudo tail -f /var/log/nginx/wordpress_error.log
```

## 📊 Résumé de votre architecture

```
Port 80/443 → nginx (système)
                ├── / → Portfolio (/home/ubuntu/portfolio)
                ├── /api → Symfony API (localhost:8080)
                ├── /salon-api → Symfony API (localhost:8082)
                └── blog.james-johnson.fr → WordPress (localhost:8083)
```

## 🎯 Recommandation

Je recommande **l'Option A (sous-domaine)** car :
- ✅ Plus simple à gérer
- ✅ WordPress fonctionne mieux sur un domaine dédié
- ✅ Isolation complète de votre portfolio
- ✅ URLs plus propres

Sous-domaines possibles :
- `blog.james-johnson.fr`
- `wp.james-johnson.fr`
- `cms.james-johnson.fr`

## 🆘 Dépannage

### WordPress affiche "Error establishing a database connection"

```bash
cd /home/ubuntu/wordpress
docker compose logs db
docker compose restart db
```

### nginx ne démarre pas

```bash
sudo nginx -t  # Vérifier la syntaxe
sudo systemctl status nginx
```

### Le certificat SSL ne fonctionne pas

```bash
# Vérifier les certificats
sudo certbot certificates

# Renouveler
sudo certbot renew --dry-run
```

---

**Prochaine étape** : Quel nom de sous-domaine voulez-vous utiliser ? `blog.james-johnson.fr` ?
