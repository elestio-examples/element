set -o allexport; source .env; set +o allexport;

nginx_conf="/opt/elestio/nginx/conf.d/${DOMAIN}.conf"

sed -i '/#error_log \/var\/log\/nginx\/error_log;/a \
\
location ~ ^\/_matrix|\/_synapse\/client) { \
    proxy_pass http:\/\/172.17.0.1:8008; \
    proxy_set_header X-Forwarded-For $remote_addr; \
    proxy_set_header X-Forwarded-Proto $scheme; \
    proxy_set_header Host $host; \
    client_max_body_size 50M; \
    proxy_http_version 1.1; \
}' "$nginx_conf"

docker exec elestio-nginx nginx -s reload;