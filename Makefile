include .env
export

# When running tools on the host, swap the Docker service hostname for localhost.
# Inside Docker the DB is reachable as 'postgres'; on the host it's 'localhost'.
LOCAL_DB_URL := $(subst @postgres:,@localhost:,$(DATABASE_URL))

# migrate up — uses the pre-configured service from docker-compose.yml
# (postgres must already be running: docker compose up -d postgres)
MIGRATE_RUN = docker run --rm --network host \
	-v $(CURDIR)/migrations:/migrations:ro \
	migrate/migrate:v4.18.3 \
	-path /migrations \
	-database "$(LOCAL_DB_URL)"

.PHONY: migrate migrate-down migrate-drop seed build run smoke

migrate:
	$(MIGRATE_RUN) up

migrate-down:
	$(MIGRATE_RUN) down 1

migrate-drop:
	$(MIGRATE_RUN) drop -f

seed:
	DATABASE_URL=$(LOCAL_DB_URL) SEEDS_DIR=seeds go run ./seeds/runner

build:
	go build -o bin/server ./cmd/server

run: build
	./bin/server

smoke:
	go run ./cmd/smoketest
