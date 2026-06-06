#!/bin/bash

# Prevent apt from opening blocking interactive prompts
export DEBIAN_FRONTEND=noninteractive

echo "========================================="
echo "    CONFIGURING YANDEX LOCAL OS MIRROR   "
echo "========================================="

# 1. Backup original sources.list file
cp /etc/apt/sources.list /etc/apt/sources.list.backup

# 2. Re-write sources.list using Yandex's official Ubuntu repository paths for speed
cat << 'EOF' > /etc/apt/sources.list
# Ubuntu 22.04 LTS Jammy (Yandex Mirror)
deb http://mirror.yandex.ru/ubuntu/ jammy main restricted universe multiverse
deb http://mirror.yandex.ru/ubuntu/ jammy-updates main restricted universe multiverse
deb http://mirror.yandex.ru/ubuntu/ jammy-backports main restricted universe multiverse
deb http://mirror.yandex.ru/ubuntu/ jammy-security main restricted universe multiverse
EOF

echo "========================================="
echo "    CONFIGURING ABRHA DOCKER MIRROR      "
echo "========================================="

# 3. Create keyrings directory and pull the specific working GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://repo.abrha.net/docker/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# 4. Write the modern docker.sources definition file pointing to Abrha
. /etc/os-release
printf '%s\n' \
"Types: deb" \
"URIs: https://repo.abrha.net/docker/ubuntu" \
"Suites: ${UBUNTU_CODENAME:-$VERSION_CODENAME}" \
"Components: stable" \
"Architectures: $(dpkg --print-architecture)" \
"Signed-By: /etc/apt/keyrings/docker.asc" > /etc/apt/sources.list.d/docker.sources

# 5. Update metadata indices combining Yandex OS packages + Abrha Docker packages
apt-get update -y

# 6. Install essential DevOps base core utilities from Yandex
apt-get install -y vim iptables-persistent bash-completion curl

# 7. Bring system distribution packages to current states
apt-get upgrade -y

echo "========================================="
echo "       INSTALLING DOCKER ENGINE          "
echo "========================================="

# 8. Install Docker packages cleanly
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "========================================="
echo "    CONFIGURING DOCKER IMAGE MIRROR     "
echo "========================================="

# 9. Create the config folder and apply your exact registry mirror rules
mkdir -p /etc/docker
cat << 'EOF' > /etc/docker/daemon.json
{
  "insecure-registries" : ["https://docker.arvancloud.ir"],
  "registry-mirrors": ["https://docker.arvancloud.ir"]
}
EOF

# 10. Clear out any residual active container registry authentication data
docker logout

# 11. Enable Docker on boot and restart the engine to apply your configurations
systemctl enable docker
systemctl restart docker

# 12. Give the 'vagrant' user permission to run Docker commands natively
usermod -aG docker vagrant

echo "========================================="
echo "     SETTING UP GHOSTTY TERMINFO        "
echo "========================================="

# 13. Fix 'xterm-ghostty' using the updated repository URL route
mkdir -p /home/vagrant/.terminfo/x/
curl -fsSL "https://raw.githubusercontent.com/ghostty-org/ghostty/main/terminfo/xterm-ghostty" -o /home/vagrant/.terminfo/x/xterm-ghostty
chown -R vagrant:vagrant /home/vagrant/.terminfo

#echo "========================================="
#echo "     CLEANUP: REVERTING REPOSITORIES     "
#echo "========================================="
#
## 14. Revert back to the pristine original OS repositories
#mv /etc/apt/sources.list.backup /etc/apt/sources.list
#
## 15. Remove the temporary docker sources layout so it leaves no trace on the host
#rm -f /etc/apt/sources.list.d/docker.sources
#
## 16. Final sync to reset metadata tables back to default status
#apt-get update -y

echo "=== System Provisioning Complete ==="