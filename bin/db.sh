#!/usr/bin/env bash
# db.sh up|down|psql|redis - throwaway local dev databases in Docker
# Ports bind to 127.0.0.1 only. Data lives in named volumes.
set -euo pipefail

PG=dev-postgres
RD=dev-redis

case "${1:-up}" in
  up)
    docker start $PG 2> /dev/null ||
      docker run -d --name $PG --restart unless-stopped \
        -p 127.0.0.1:5432:5432 \
        -e POSTGRES_USER=dev -e POSTGRES_PASSWORD=dev -e POSTGRES_DB=app \
        -v dev-pgdata:/var/lib/postgresql/data postgres:18 > /dev/null
    docker start $RD 2> /dev/null ||
      docker run -d --name $RD --restart unless-stopped \
        -p 127.0.0.1:6379:6379 redis:8 > /dev/null
    echo "postgres: dev/dev@localhost:5432/app   redis: localhost:6379"
    ;;
  down) docker stop $PG $RD > /dev/null 2>&1 || true ;;
  rm) docker rm -f $PG $RD > /dev/null 2>&1 || true ;;
  psql) docker exec -it $PG psql -U dev app ;;
  redis) docker exec -it $RD redis-cli ;;
  *)
    echo "Usage: db.sh up|down|rm|psql|redis"
    exit 1
    ;;
esac
