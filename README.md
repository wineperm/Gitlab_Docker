# Инструкция по установке и настройке GitLab с использованием Docker

Эта инструкция описывает процесс установки и настройки [GitLab с использованием Docker](https://github.com/wineperm/Gitlab_Docker/blob/main/README.md#установка-gitlab), а также установки и регистрации GitLab Runner. Установка GitLab Runner может быть выполнена как на [отдельном сервере](https://github.com/wineperm/Gitlab_Docker/blob/main/README.md#установка-gitlab-runner), так и с помощью [скрипта в Docker контейнере](https://github.com/wineperm/Gitlab_Docker/blob/main/README.md#создание-gitlab-runner-в-docker). Кроме того, приводится процедура [генерации самоподписанного SSL-сертификата](https://github.com/wineperm/Gitlab_Docker/blob/main/README.md#создание-файла-конфигурации-opensslcnf) для обеспечения безопасного соединения.

## Установка Docker

Для установки Docker выполните следующие команды:

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sh ./get-docker.sh
```

## Установка GitLab 

### Создание файла `docker-compose.yml`

Создайте файл `docker-compose.yml` со следующим содержимым:

```yaml
services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    container_name: gitlab
    restart: always
    hostname: "51.250.72.68" # Замените на ваш IP
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://51.250.72.68' # Замените на ваш IP
      GITLAB_ROOT_PASSWORD: "yourpassword1" # Замените на ваш пароль
    ports:
      - "80:80"
      - "443:443"
      - "2222:22" # Измененный порт для SSH
    volumes:
      - "/srv/gitlab/config:/etc/gitlab"
      - "/srv/gitlab/logs:/var/log/gitlab"
      - "/srv/gitlab/data:/var/opt/gitlab"
    shm_size: "256m"  
#    networks: # Раскомментируй блок, если runner будет на том же хосте, что и GitLab, в docker-контейнере.
#      - gitlab-network
#
#networks:
#  gitlab-network:
#    driver: bridge
#    name: gitlab-network
```

**Примечание:** Замените `51.250.72.68` на ваш IP-адрес и `yourpassword1` на ваш пароль.

## Установка GitLab Runner

### Скачивание бинарного файла для вашей системы

```bash
sudo curl -L --output /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64
```

### Предоставление прав на выполнение

```bash
sudo chmod +x /usr/local/bin/gitlab-runner
```

### Создание пользователя GitLab Runner

```bash
sudo useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash
```

### Установка и запуск как сервиса

```bash
sudo gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
sudo gitlab-runner start
```

### Регистрация GitLab Runner

```bash
gitlab-runner register --url http://51.250.72.68 --token glrt-t3_RVwTMVpEKMx9t-QeDbUk
```

**Примечание:** Замените `51.250.72.68` на ваш IP-адрес и `glrt-t3_RVwTMVpEKMx9t-QeDbUk` на ваш токен.

### Запуск GitLab Runner

```bash
gitlab-runner run
```

## Создание/установка/регистрация GitLab Runner в Docker на другом хосте, что GitLab. 

```
wget https://raw.githubusercontent.com/wineperm/Gitlab_Docker/main/setup-gitlab-runner.sh && chmod +x setup-gitlab-runner.sh
```

### Создание скрипта `setup-gitlab-runner.sh`

Создайте файл `setup-gitlab-runner.sh` со следующим содержимым:

```bash
#!/bin/bash

# Проверка наличия Docker и установка если его нет.
if ! command -v docker &> /dev/null; then
    echo "Docker не установлен. Устанавливаем Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    if sh ./get-docker.sh; then
        echo "Docker успешно установлен."
    else
        echo "УПС, что-то пошло не так при установке Docker."
        exit 1
    fi
else
    echo "Docker уже установлен."
fi

# Запрос ввода IP-адреса и токена регистрации
read -p "Введите IP-адрес вашего сервера GitLab (например, http://51.250.72.68/): " CI_SERVER_URL
read -p "Введите токен регистрации GitLab Runner (например, glrt-t3_iTc9_ktyrw7Z8ZYoszts): " REGISTRATION_TOKEN

# Запрос ввода Docker-образа
read -p "Введите Docker-образ (например, alpine:latest), или нажмите Enter для использования alpine:latest по умолчанию: " DOCKER_IMAGE
DOCKER_IMAGE=${DOCKER_IMAGE:-alpine:latest}

# Запрос ввода описания Runner
read -p "Введите описание Runner, или нажмите Enter для использования 'my-runner' по умолчанию: " RUNNER_DESCRIPTION
RUNNER_DESCRIPTION=${RUNNER_DESCRIPTION:-my-runner}

# Остальные переменные
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
```

### Предоставление прав на выполнение скрипта

```bash
sudo chmod +x setup-gitlab-runner.sh
```

### Запуск скрипта

```bash
./setup-gitlab-runner.sh
```

Этот скрипт автоматизирует процесс установки и настройки GitLab Runner в Docker. Следуйте инструкциям на экране для ввода необходимых данных.


## Создание/установка/регистрация GitLab Runner в Docker на том же хосте, что и Gitlab.

```
wget https://raw.githubusercontent.com/wineperm/Gitlab_Docker/main/setup-gitlab-runner-hosts.sh && chmod +x setup-gitlab-runner-hosts.sh
```

### Создание скрипта `setup-gitlab-runner-hosts.sh`

Создайте файл `setup-gitlab-runner-hosts.sh` со следующим содержимым:

```
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
```

### Предоставление прав на выполнение скрипта

```bash
sudo chmod +x setup-gitlab-runner-hosts.sh
```

### Запуск скрипта

```bash
./setup-gitlab-runner-hosts.sh
```

Этот скрипт автоматизирует процесс установки и настройки GitLab Runner в Docker на том же хосте, что и сервер GitLab. Следуйте инструкциям на экране для ввода необходимых данных.

-------------------------

## Получение пароля root (действителен 24 часа)

Для получения начального пароля root выполните следующие команды:

1. Откройте консоль контейнера GitLab:

   ```bash
   sudo docker exec -it gitlab /bin/bash
   ```

2. Получите начальный пароль root:

   ```bash
   cat /etc/gitlab/initial_root_password
   ```

## Изменение пароля

Для изменения пароля root выполните следующие команды:

1. Откройте консоль контейнера GitLab:

   ```bash
   sudo docker exec -it gitlab /bin/bash
   ```

2. Запустите консоль Rails:

   ```bash
   gitlab-rails console -e production
   ```

3. Найдите пользователя с ID 1:

   ```ruby
   user = User.where(id: 1).first
   ```

4. Установите новый пароль:

   ```ruby
   user.password = 'new_password'
   ```

5. Подтвердите новый пароль:

   ```ruby
   user.password_confirmation = 'new_password'
   ```

6. Сохраните изменения:

   ```ruby
   user.save!
   ```

7. Выйдите из консоли Rails:

   ```ruby
   exit
   ```

## Генерация сертификата

### Создание файла конфигурации `openssl.cnf`

Создайте файл `openssl.cnf` со следующим содержимым:

```ini
[req]
distinguished_name = req_distinguished_name
req_extensions = req_ext
x509_extensions = v3_ca
prompt = no

[req_distinguished_name]
C = US
ST = State
L = City
O = Organization
OU = Unit
CN = 51.250.72.68

[req_ext]
subjectAltName = @alt_names

[v3_ca]
subjectAltName = @alt_names
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[alt_names]
DNS.1 = 51.250.72.68
```

**Примечание:** Замените `51.250.72.68` на ваш IP-адрес.

### Генерация приватного ключа

```bash
openssl genpkey -algorithm RSA -out gitlab.key -aes256
```

### Генерация запроса на подпись сертификата (CSR)

```bash
openssl req -new -key gitlab.key -out gitlab.csr -config openssl.cnf
```

### Подпись CSR с помощью приватного ключа для создания самоподписанного сертификата

```bash
openssl x509 -req -days 365 -in gitlab.csr -signkey gitlab.key -out gitlab.crt -extensions v3_ca -extfile openssl.cnf
```

### Копирование сертификата в системное хранилище

```bash
sudo cp gitlab.crt /usr/local/share/ca-certificates/gitlab.crt
```

### Обновление системных сертификатов

```bash
sudo update-ca-certificates
```

Эта инструкция поможет вам установить и настроить GitLab с использованием Docker, а также установить и зарегистрировать GitLab Runner. Кроме того, она описывает процесс генерации самоподписанного SSL-сертификата для обеспечения безопасного соединения.
