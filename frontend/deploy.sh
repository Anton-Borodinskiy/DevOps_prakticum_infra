#! /bin/bash
set -xe
sudo cp -rf sausage-store-frontend.service /etc/systemd/system/sausage-store-frontend.service
sudo rm -rf /var/www-data/dist/frontend/*

curl -u ${NEXUS_REPO_USER}:${NEXUS_REPO_PASS} -o sausage-store-${VERSION}.tar.gz ${NEXUS_REPO_URL}sausage-store/${VERSION}/sausage-store-${VERSION}.tar.gz


sudo mkdir -p /tmp/sausage-store-frontend-${VERSION}
sudo tar -xzvf sausage-store-${VERSION}.tar.gz -C /tmp/sausage-store-frontend-${VERSION}
sudo cp -rf /tmp/sausage-store-front-${VERSION}/sausage-store-${VERSION}/public_html/. /var/www-data/dist/frontend/
sudo systemctl daemon-reload
sudo systemctl restart sausage-store-frontend
