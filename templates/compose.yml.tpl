services:

  # PHP App
  app:
    build:
      context: .
      dockerfile: config/docker/dockerfile
    container_name: {{PROJECT_NAME}}-php_app
    restart: unless-stopped
    tty: true
    environment:
      SERVICE_NAME: app
      SERVICE_TAGS: dev
    working_dir: /var/www/html
    volumes:
      - ./:/var/www/html
      - ./config/docker/custom.ini:/usr/local/etc/php/conf.d/custom.ini
    networks:
      - dev

  # NGINX Service
  nginx:
    image: nginx:alpine
    container_name: {{PROJECT_NAME}}-nginx
    restart: unless-stopped
    tty: true
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./:/var/www/html
      - ./config/docker/conf.d/:/etc/nginx/conf.d/
      - ./config/docker/certs/{{HOSTNAME}}.pem:/etc/ssl/certs/{{HOSTNAME}}.pem
      - ./config/docker/certs/{{HOSTNAME}}-key.pem:/etc/ssl/private/{{HOSTNAME}}-key.pem
    depends_on:
      - app
      - mailcatcher
    networks:
      - dev

  # MySQL Service
  db:
    image: mysql:8.4
    container_name: {{PROJECT_NAME}}-db
    restart: unless-stopped
    tty: true
    ports:
      - "3306:3306"
    volumes:
      - db-data:/var/lib/mysql
      - ./config/docker/init.sql:/docker-entrypoint-initdb.d/init.sql
    environment:
      MYSQL_DATABASE: my_app
      MYSQL_ROOT_PASSWORD: root
      MYSQL_USER: my_app
      MYSQL_PASSWORD: secret
    networks:
      - dev

  # MailCatcher Service
  mailcatcher:
    container_name: {{PROJECT_NAME}}-mailcatcher
    restart: unless-stopped
    image: chrislpierce/mailcatcher:latest
    ports:
      - "1025:1025"
      - "1080:1080"
    networks:
      - dev

#Volumes
volumes:
  db-data:
    external: false

#Docker Networks
networks:
  dev:
      name: dev
      external: true
