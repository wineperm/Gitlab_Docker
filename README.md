# Gitlab_Docker
=================
Install Docker
-----------------
sudo apt update
sudo apt install curl software-properties-common ca-certificates apt-transport-https -y
wget -O- https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor | sudo tee /etc/apt/keyrings/docker.gpg > /dev/null
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable"| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
apt-cache policy docker-ce
sudo apt install docker-ce -y
sudo systemctl status docker

Install Gitlab
----------------
docker-compose.yml

services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    container_name: gitlab
    restart: always
    hostname: 'gitlab.example.com'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        # Add any other gitlab.rb configuration here, each on its own line
        external_url 'https://89.169.142.63'
      GITLAB_ROOT_PASSWORD: '12345679aA'  # Задайте здесь ваш пароль
    ports:
      - '80:80'
      - '443:443'
      - '2222:22'  # Измененный порт для SSH
    volumes:
      - '/srv/gitlab/config:/etc/gitlab'
      - '/srv/gitlab/logs:/var/log/gitlab'
      - '/srv/gitlab/data:/var/opt/gitlab'
    shm_size: '256m'

-------------------
changing the password
-------------------
sudo docker exec -it gitlab /bin/bash
gitlab-rails console -e production
user = User.where(id: 1).first
user.password = 'new_password'
user.password_confirmation = 'new_password'
user.save!
exit


    

