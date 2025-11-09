# Guide rapide de déploiement WordPress sur VPS

Ce guide vous permet de déployer votre site WordPress sur un VPS Ubuntu en quelques minutes.

## 🎯 Prérequis rapides

- [ ] VPS Ubuntu avec au moins 1GB RAM
- [ ] Nom de domaine (ex: monsite.com)
- [ ] DNS configuré (voir ci-dessous)
- [ ] Accès SSH au VPS

## 📡 Configuration DNS (à faire en PREMIER)

Chez votre registrar (OVH, Gandi, Namecheap, etc.), ajoutez ces enregistrements :

```
Type    Nom    Valeur                TTL
A       @      IP.DE.VOTRE.VPS       3600
A       www    IP.DE.VOTRE.VPS       3600
```

**⏰ Attendez 5-30 minutes pour la propagation DNS**

Vérifiez avec :
```bash
ping monsite.com
```

## 🚀 Déploiement en 5 étapes

### 1️⃣ Connexion au VPS

```bash
ssh root@IP.DE.VOTRE.VPS
# ou
ssh votre-utilisateur@IP.DE.VOTRE.VPS
```

### 2️⃣ Installation de Docker (une seule fois)

```bash
# Script d'installation rapide
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Démarrer Docker
sudo systemctl start docker
sudo systemctl enable docker

# Vérifier
docker --version
```

### 3️⃣ Récupérer les fichiers du projet

**Option A : Depuis Git**
```bash
git clone https://github.com/VOTRE-USERNAME/Decouverte_WordPress.git
cd Decouverte_WordPress
```

**Option B : Upload manuel**
```bash
# Sur votre machine locale
scp -r /chemin/vers/Decouverte_WordPress votre-user@IP-VPS:/home/votre-user/

# Sur le VPS
cd /home/votre-user/Decouverte_WordPress
```

### 4️⃣ Configuration

```bash
# Copier le fichier d'environnement
cp .env.production .env

# Éditer les variables
nano .env
```

**Modifiez au minimum :**
```bash
MYSQL_PASSWORD=MotDePasseTresFort123!
MYSQL_ROOT_PASSWORD=AutreMotDePasseFort456!
DOMAIN=monsite.com
LETSENCRYPT_EMAIL=contact@monsite.com
```

Sauvegardez avec `Ctrl+O`, puis `Enter`, puis `Ctrl+X`

### 5️⃣ Lancer le script de déploiement

```bash
# Rendre le script exécutable
chmod +x setup-ssl.sh

# Lancer le script (remplacez par vos valeurs)
./setup-ssl.sh monsite.com contact@monsite.com
```

Le script va :
- ✅ Vérifier le DNS
- ✅ Démarrer WordPress et MySQL
- ✅ Obtenir le certificat SSL (HTTPS)
- ✅ Configurer nginx avec SSL
- ✅ Configurer le renouvellement automatique SSL

## ✅ Vérification

Après 2-3 minutes, ouvrez votre navigateur :

**https://monsite.com**

Vous devriez voir la page d'installation de WordPress avec le cadenas SSL (🔒) !

## 🔐 Sécurité du VPS

```bash
# Configurer le pare-feu
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Vérifier
sudo ufw status
```

## 📊 Commandes utiles

```bash
# Voir les logs
docker compose -f docker-compose.production.yml logs -f

# Redémarrer
docker compose -f docker-compose.production.yml restart

# Arrêter
docker compose -f docker-compose.production.yml down

# Voir l'état
docker compose -f docker-compose.production.yml ps
```

## 🔄 Déploiement simple (sans SSL automatique)

Si vous voulez juste tester rapidement sans SSL :

```bash
# Modifier .env
nano .env
# Mettre WORDPRESS_PORT=80

# Démarrer
docker compose up -d

# Accès : http://monsite.com (sans HTTPS)
```

## 🆘 Problèmes courants

### Le certificat SSL échoue

```
Erreur : Le domaine ne pointe pas vers ce serveur
```

**Solution :** Vérifiez que le DNS est bien configuré avec `ping monsite.com`

### Port 80 déjà utilisé

```bash
# Vérifier ce qui utilise le port
sudo lsof -i :80

# Si c'est Apache
sudo systemctl stop apache2
sudo systemctl disable apache2
```

### Erreur de connexion à la base de données

```bash
# Vérifier les logs
docker compose -f docker-compose.production.yml logs db

# Redémarrer la DB
docker compose -f docker-compose.production.yml restart db
```

## 📝 Après le déploiement

1. ✅ Terminez l'installation WordPress sur https://monsite.com
2. ✅ Connectez-vous au tableau de bord
3. ✅ Installez des plugins de sécurité (Wordfence, iThemes Security)
4. ✅ Configurez les sauvegardes (voir DEPLOY.md)
5. ✅ Installez un plugin de cache (WP Super Cache)

## 📚 Documentation complète

Pour plus de détails, consultez [DEPLOY.md](./DEPLOY.md)

## 🎉 C'est tout !

Votre site WordPress est maintenant en ligne avec HTTPS !

Questions ? Consultez la documentation complète ou ouvrez une issue.
