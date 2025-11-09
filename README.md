# Projet WordPress Dockerisé

Ce projet permet de lancer rapidement un environnement WordPress complet avec Docker, incluant :
- **WordPress** (dernière version)
- **MySQL 8.0** (base de données)
- **PhpMyAdmin** (interface de gestion de base de données)

## Prérequis

- [Docker](https://docs.docker.com/get-docker/) installé
- [Docker Compose](https://docs.docker.com/compose/install/) installé

## Installation

1. **Cloner le projet** (si ce n'est pas déjà fait)
   ```bash
   git clone <url-du-repo>
   cd Decouverte_WordPress
   ```

2. **Configurer les variables d'environnement**

   Le fichier `.env` contient déjà les valeurs par défaut. Vous pouvez les modifier si nécessaire :
   ```bash
   # Optionnel : modifier le fichier .env
   nano .env
   ```

3. **Lancer les containers Docker**
   ```bash
   docker-compose up -d
   ```

   Cette commande va :
   - Télécharger les images Docker nécessaires
   - Créer et démarrer les containers
   - Créer les volumes pour persister les données

## Accès aux services

Une fois les containers démarrés, vous pouvez accéder à :

- **WordPress** : [http://localhost:8080](http://localhost:8080)
- **PhpMyAdmin** : [http://localhost:8081](http://localhost:8081)

### Premier lancement de WordPress

1. Accédez à [http://localhost:8080](http://localhost:8080)
2. Sélectionnez votre langue
3. Remplissez les informations du site :
   - Titre du site
   - Nom d'utilisateur admin
   - Mot de passe
   - Email
4. Cliquez sur "Installer WordPress"

### Accès à PhpMyAdmin

- **URL** : [http://localhost:8081](http://localhost:8081)
- **Serveur** : db
- **Utilisateur** : root
- **Mot de passe** : rootpassword (ou la valeur de `MYSQL_ROOT_PASSWORD` dans `.env`)

## Commandes utiles

### Démarrer les containers
```bash
docker-compose up -d
```

### Arrêter les containers
```bash
docker-compose down
```

### Arrêter et supprimer les volumes (⚠️ supprime les données)
```bash
docker-compose down -v
```

### Voir les logs
```bash
# Tous les services
docker-compose logs -f

# WordPress uniquement
docker-compose logs -f wordpress

# MySQL uniquement
docker-compose logs -f db
```

### Redémarrer les services
```bash
docker-compose restart
```

### Voir l'état des containers
```bash
docker-compose ps
```

## Configuration

### Ports

Les ports par défaut peuvent être modifiés dans le fichier `.env` :
- `WORDPRESS_PORT` : Port pour accéder à WordPress (défaut: 8080)
- `PHPMYADMIN_PORT` : Port pour accéder à PhpMyAdmin (défaut: 8081)

### Base de données

Les informations de connexion à la base de données sont configurées dans `.env` :
- `MYSQL_DATABASE` : Nom de la base de données
- `MYSQL_USER` : Utilisateur MySQL
- `MYSQL_PASSWORD` : Mot de passe MySQL
- `MYSQL_ROOT_PASSWORD` : Mot de passe root MySQL

## Persistance des données

Les données sont persistées dans des volumes Docker :
- `wordpress_data` : Contient tous les fichiers WordPress (thèmes, plugins, uploads)
- `db_data` : Contient la base de données MySQL

Ces volumes persistent même après l'arrêt des containers, sauf si vous utilisez `docker-compose down -v`.

## Développement de thèmes/plugins

Pour développer des thèmes ou plugins personnalisés, vous pouvez :

1. Accéder au volume WordPress :
   ```bash
   docker exec -it wordpress_app bash
   cd /var/www/html/wp-content
   ```

2. Ou monter un dossier local (modifier `docker-compose.yml`) :
   ```yaml
   wordpress:
     volumes:
       - wordpress_data:/var/www/html
       - ./themes:/var/www/html/wp-content/themes/custom
       - ./plugins:/var/www/html/wp-content/plugins/custom
   ```

## Dépannage

### Les containers ne démarrent pas
```bash
# Vérifier les logs
docker-compose logs

# Vérifier que les ports ne sont pas déjà utilisés
netstat -an | grep 8080
netstat -an | grep 8081
```

### Réinitialiser complètement l'environnement
```bash
docker-compose down -v
docker-compose up -d
```

### Permission denied
```bash
# Sur Linux, donner les bonnes permissions
sudo chown -R www-data:www-data wordpress_data/
```

## Sauvegarde

### Sauvegarder la base de données
```bash
docker exec wordpress_db mysqldump -u root -prootpassword wordpress > backup.sql
```

### Restaurer la base de données
```bash
docker exec -i wordpress_db mysql -u root -prootpassword wordpress < backup.sql
```

## Licence

Ce projet est libre d'utilisation pour vos tests et développements.
