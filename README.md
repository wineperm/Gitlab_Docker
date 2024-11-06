# Gitlab_Docker
=================
Install Docker
-----------------

```
curl -fsSL https://get.docker.com -o get-docker.sh
sh ./get-docker.sh
```

----------------
Install Gitlab
----------------
```docker-compose.yml```

```services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    container_name: gitlab
    restart: always
    hostname: 'gitlab.example.com'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        # Add any other gitlab.rb configuration here, each on its own line
        external_url 'https://89.169.142.63'
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
root password 24 hours
-------------------
```sudo docker exec -it gitlab /bin/bash```
```cat /etc/gitlab/initial_root_password```

-------------------
changing the password
-------------------
```sudo docker exec -it gitlab /bin/bash```
```gitlab-rails console -e production```
```user = User.where(id: 1).first```
```user.password = 'new_password'```
```user.password_confirmation = 'new_password'```
```user.save!```
exit

------------------
installing ranner linux
------------------
# Download the binary for your system
```sudo curl -L --output /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64```

# Give it permission to execute
```sudo chmod +x /usr/local/bin/gitlab-runner```

# Create a GitLab Runner user
```sudo useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash```

# Install and run as a service
```sudo gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner```
```sudo gitlab-runner start```

-----------------
certificate
-----------------
openssl.cnf

```
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

# Генерация приватного ключа
```openssl genpkey -algorithm RSA -out gitlab.key -aes256```

# Генерация запроса на подпись сертификата (CSR)
```openssl req -new -key gitlab.key -out gitlab.csr -config openssl.cnf```

# Подпись CSR с помощью приватного ключа для создания самоподписанного сертификата
```openssl x509 -req -days 365 -in gitlab.csr -signkey gitlab.key -out gitlab.crt -extensions v3_ca -extfile openssl.cnf```

```sudo cp gitlab.crt /usr/local/share/ca-certificates/gitlab.crt```

```sudo update-ca-certificates```













    

