# Gitlab_Docker

=================

## Установка Docker

-----------------

Для установки Docker выполните следующие команды:

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sh ./get-docker.sh
```

----------------

## Установка Gitlab

----------------

### Создание файла `docker-compose.yml`

Создайте файл `docker-compose.yml` со следующим содержимым:

```yaml
services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    container_name: gitlab
    restart: always
    hostname: '89.169.142.63' # Замените на ваш IP
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://89.169.142.63' # Замените на ваш IP
        gitlab_rails['initial_root_password'] = 'yourpassword1' # Замените на ваш пароль
    ports:
      - '80:80'
      - '443:443'
      - '2222:22'  # Измененный порт для SSH
    volumes:
      - '/srv/gitlab/config:/etc/gitlab'
      - '/srv/gitlab/logs:/var/log/gitlab'
      - '/srv/gitlab/data:/var/opt/gitlab'
    shm_size: '256m'
```

-------------------

### Получение пароля root (действителен 24 часа)

1. Откройте консоль контейнера GitLab:

    ```bash
    sudo docker exec -it gitlab /bin/bash
    ```

2. Получите начальный пароль root:

    ```bash
    cat /etc/gitlab/initial_root_password
    ```

### Изменение пароля

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

------------------

## Установка GitLab Runner

------------------

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

-----------------

## Генерация сертификата

-----------------

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
CN = 89.169.142.63

[req_ext]
subjectAltName = @alt_names

[v3_ca]
subjectAltName = @alt_names
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[alt_names]
DNS.1 = 89.169.142.63
```

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

-----------------
