name: Deploy to Production Server
on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://{{DOMAIN}}

    steps:
      - name: Checkout repository
        uses: actions/checkout@v6

      - name: CakePHP Deploy
        uses: shivammathur/setup-php@v2
        with:
            php-version: '8.3'
            extensions: intl, mbstring, simplexml, pdo, pdo_mysql, mysql, igbinary

      - name: Install packages and run post-install scripts
        run: composer install --no-dev --no-interaction --no-progress

      - name: Replace Secrets in config.php
        run: |
          sed -i "s|{{DB_HOST}}|${{ secrets.DB_HOST }}|g" ./config/app_local.php
          sed -i "s|{{DB_USERNAME}}|${{ secrets.DB_USERNAME }}|g" ./config/app_local.php
          sed -i "s|{{DB_PASSWORD}}|${{ secrets.DB_PASSWORD }}|g" ./config/app_local.php
          sed -i "s|{{DB_DATABASE}}|${{ secrets.DB_DATABASE }}|g" ./config/app_local.php
          sed -i "s|{{SES_USERNAME}}|${{ secrets.SES_USERNAME }}|g" ./config/app_local.php
          sed -i "s|{{SES_PASSWORD}}|${{ secrets.SES_PASSWORD }}|g" ./config/app_local.php

      - name: Setup SSH Keys
        run: |
          sudo apt-get update
          sudo apt-get install -y openssh-client rsync
          mkdir -p ~/.ssh
          chmod 700 ~/.ssh
          ssh-keyscan -H ${{ vars.DEPLOY_HOST }} >> ~/.ssh/known_hosts
          echo "${{ secrets.DEPLOY_KEY }}" > ~/.ssh/id_ed25519
          chmod 600 ~/.ssh/id_ed25519

      - name: Deploy application to server
        run: |
          rsync -avz --delete --exclude='.env' --exclude='vendor/' . runner@${{ vars.DEPLOY_HOST }}:~/${{ vars.DEPLOY_DIR }}_stage
          ssh runner@${{ vars.DEPLOY_HOST }} 'cd ~/${{ vars.DEPLOY_DIR }}_stage && composer install --no-dev'
          ssh runner@${{ vars.DEPLOY_HOST }} 'sudo rsync -avz --chown=www-data:www-data --delete --exclude=".git/" --exclude="logs/" --exclude="tmp/" ~/${{ vars.DEPLOY_DIR }}_stage/ /var/www/${{ vars.DEPLOY_DIR }}'
          ssh runner@${{ vars.DEPLOY_HOST }} 'rm -rf ~/${{ vars.DEPLOY_DIR }}_stage'
          ssh runner@${{ vars.DEPLOY_HOST }} 'sudo /var/www/${{ vars.DEPLOY_DIR }}/bin/cake cache clear_all'
