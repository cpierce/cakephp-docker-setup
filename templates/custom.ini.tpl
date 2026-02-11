max_execution_time = 3600
memory_limit = 256M

post_max_size = 256M
upload_max_filesize = 256M

html_errors = On
display_errors = On

short_open_tag = On

cgi.fix_pathinfo = Off

sendmail_path = /usr/bin/env catchmail -f no-reply@{{DOMAIN}}

xdebug.mode = debug,develop
xdebug.start_with_request = yes
xdebug.client_host = host.docker.internal
xdebug.client_port = 9003
xdebug.cli_color = 1

; sane limits
xdebug.var_display_max_depth = 5
xdebug.var_display_max_children = 256
xdebug.var_display_max_data = 1024
