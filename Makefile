.PHONY: help up down restart ps logs logs-wp logs-db shell shell-db backup clean status

# Couleurs pour l'affichage
BLUE=\033[0;34m
GREEN=\033[0;32m
NC=\033[0m # No Color

help: ## Affiche cette aide
	@echo "$(BLUE)WordPress Docker - Commandes disponibles :$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""

up: ## Démarre les containers (docker compose up -d)
	@echo "$(BLUE)Démarrage des containers WordPress...$(NC)"
	docker compose up -d
	@echo "$(GREEN)✓ Containers démarrés$(NC)"
	@make ps

down: ## Arrête les containers
	@echo "$(BLUE)Arrêt des containers...$(NC)"
	docker compose down
	@echo "$(GREEN)✓ Containers arrêtés$(NC)"

restart: ## Redémarre les containers
	@echo "$(BLUE)Redémarrage des containers...$(NC)"
	docker compose restart
	@echo "$(GREEN)✓ Containers redémarrés$(NC)"
	@make ps

ps: ## Affiche l'état des containers (formaté)
	@echo "$(BLUE)État des containers WordPress :$(NC)"
	@docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

logs: ## Affiche les logs de tous les containers
	docker compose logs -f

logs-wp: ## Affiche les logs de WordPress uniquement
	docker compose logs -f wordpress

logs-db: ## Affiche les logs de MySQL uniquement
	docker compose logs -f db

shell: ## Ouvre un shell dans le container WordPress
	docker compose exec wordpress bash

shell-db: ## Ouvre un shell MySQL
	docker compose exec db mysql -u root -p$(MYSQL_ROOT_PASSWORD) $(MYSQL_DATABASE)

backup: ## Sauvegarde la base de données
	@echo "$(BLUE)Sauvegarde de la base de données...$(NC)"
	@mkdir -p backups
	@docker compose exec db mysqldump -u root -p$(MYSQL_ROOT_PASSWORD) $(MYSQL_DATABASE) > backups/backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "$(GREEN)✓ Sauvegarde créée dans backups/$(NC)"

restore: ## Restaure la dernière sauvegarde (make restore FILE=backups/backup.sql)
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make restore FILE=backups/backup_YYYYMMDD_HHMMSS.sql"; \
		exit 1; \
	fi
	@echo "$(BLUE)Restauration de $(FILE)...$(NC)"
	@docker compose exec -T db mysql -u root -p$(MYSQL_ROOT_PASSWORD) $(MYSQL_DATABASE) < $(FILE)
	@echo "$(GREEN)✓ Base de données restaurée$(NC)"

status: ## Affiche des informations détaillées
	@echo "$(BLUE)=== Status WordPress Docker ===$(NC)"
	@echo ""
	@echo "$(GREEN)Containers :$(NC)"
	@docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
	@echo ""
	@echo "$(GREEN)Utilisation ressources :$(NC)"
	@docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" $(shell docker compose ps -q)

clean: ## Supprime les containers et volumes (⚠️ DESTRUCTIF)
	@echo "$(BLUE)⚠️  ATTENTION : Cela va supprimer tous les containers ET les données !$(NC)"
	@read -p "Êtes-vous sûr ? (y/N) " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker compose down -v; \
		echo "$(GREEN)✓ Containers et volumes supprimés$(NC)"; \
	else \
		echo "Annulé"; \
	fi

install: ## Premier lancement (copie .env et démarre)
	@if [ ! -f .env ]; then \
		echo "$(BLUE)Copie de .env.example vers .env...$(NC)"; \
		cp .env.example .env; \
		echo "$(GREEN)✓ Fichier .env créé$(NC)"; \
		echo ""; \
		echo "⚠️  Pensez à modifier .env avec vos paramètres !"; \
		echo "Ensuite, lancez: make up"; \
	else \
		echo ".env existe déjà"; \
		make up; \
	fi

# Par défaut, affiche l'aide
.DEFAULT_GOAL := help
