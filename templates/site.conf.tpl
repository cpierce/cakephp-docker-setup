server {
    listen 80;
    server_name {{HOSTNAME}};

    # Redirect all HTTP requests to HTTPS
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name {{HOSTNAME}};

    ssl_certificate /etc/ssl/certs/{{HOSTNAME}}.pem;
    ssl_certificate_key /etc/ssl/private/{{HOSTNAME}}-key.pem;

    # Log files for Debug
    error_log  /var/log/nginx/error.log error;
    access_log /var/log/nginx/access.log;

    root /var/www/html/webroot;
    index index.php index.html index.htm;

    sendfile off;

    client_max_body_size 15M;

    # deny access to git folder
	location ~ /.git/ {
		deny all;
	}

	# deny access to .htaccess files
	location ~ /\.ht {
		deny all;
	}

	location / {
		try_files $uri $uri/ /index.php?$args;
	}

    location ~ /\. {
            return 403;
    }

    location ~* \.php {
        try_files $uri =404;
        fastcgi_pass app:9000;
        fastcgi_index index.php;
        fastcgi_read_timeout 240s;
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

}
