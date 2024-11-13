#!/bin/bash

# Запрос ввода токена регистрации
read -p "Введите токен регистрации GitLab Runner (например, glrt-t3_iTc9_ktyrw7Z8ZYoszts): " REGISTRATION_TOKEN

# Запрос ввода Docker-образа
read -p "Введите Docker-образ (например, alpine:latest), или нажмите Enter для использования alpine:latest по умолчанию: " DOCKER_IMAGE
DOCKER_IMAGE=${DOCKER_IMAGE:-alpine:latest}

# Запрос ввода описания Runner
read -p "Введите описание Runner, или нажмите Enter для использования 'my-runner' по умолчанию: " RUNNER_DESCRIPTION
RUNNER_DESCRIPTION=${RUNNER_DESCRIPTION:-my-runner}

# Остальные переменные
CI_SERVER_URL="http://gitlab:80"
RUNNER_EXECUTOR="docker"
DOCKER_PRIVILEGED="true"

# Создание директорий
sudo mkdir -p /srv/gitlab-runner/config
sudo touch /srv/gitlab-runner/config/config.toml
sudo chmod 600 /srv/gitlab-runner/config/config.toml

# Создание файла docker-compose-gitlab-runner.yml
cat <<EOF > docker-compose-gitlab-runner.yml
services:
  gitlab-runner:
    image: gitlab/gitlab-runner:latest
    container_name: gitlab-runner
    restart: always
    volumes:
      - /srv/gitlab-runner/config:/etc/gitlab-runner
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - CI_SERVER_URL=$CI_SERVER_URL
      - REGISTRATION_TOKEN=$REGISTRATION_TOKEN
      - RUNNER_DESCRIPTION=$RUNNER_DESCRIPTION
      - RUNNER_EXECUTOR=$RUNNER_EXECUTOR
      - DOCKER_IMAGE=$DOCKER_IMAGE
      - DOCKER_PRIVILEGED=$DOCKER_PRIVILEGED
      - DOCKER_VOLUMES=/var/run/docker.sock:/var/run/docker.sock
    networks:
      - gitlab-network

networks:
  gitlab-network:
    external: true
EOF

# Запуск GitLab Runner
if sudo docker compose -f docker-compose-gitlab-runner.yml up -d; then
    echo "GitLab Runner успешно запущен."
else
    echo "УПС, что-то пошло не так при запуске GitLab Runner."
    exit 1
fi

# Регистрация GitLab Runner
if sudo docker exec -it gitlab-runner bash -c "
gitlab-runner register \
  --non-interactive \
  --url $CI_SERVER_URL \
  --registration-token $REGISTRATION_TOKEN \
  --executor $RUNNER_EXECUTOR \
  --docker-image $DOCKER_IMAGE \
  --description $RUNNER_DESCRIPTION \
  --docker-privileged=$DOCKER_PRIVILEGED \
  --docker-volumes /var/run/docker.sock:/var/run/docker.sock
"; then
    echo "GitLab Runner успешно зарегистрирован."
else
    echo "УПС, что-то пошло не так при регистрации GitLab Runner."
    exit 1
fi

echo "GitLab Runner успешно настроен и зарегистрирован."
