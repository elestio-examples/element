#set env vars
set -o allexport; source .env; set +o allexport;

mkdir -p ./matrix

echo 'vm.overcommit_memory = 1' >> /etc/sysctl.conf && sysctl -p

cat << EOT > ./matrix/federation.json
{ "m.server": "${DOMAIN}:443" }
EOT

cat << 'EOF' > ./element-config.json
{
    "default_server_config": {
        "m.homeserver": {
            "base_url": "https://${DOMAIN}:8448",
            "server_name": "${DOMAIN}"
        },
        "m.identity_server": {
            "base_url": "https://vector.im"
        }
    },
    "brand": "Element",
    "integrations_ui_url": "https://scalar.vector.im/",
    "integrations_rest_url": "https://scalar.vector.im/api",
    "integrations_widgets_urls": [
        "https://scalar.vector.im/_matrix/integrations/v1",
        "https://scalar.vector.im/api",
        "https://scalar-staging.vector.im/_matrix/integrations/v1",
        "https://scalar-staging.vector.im/api",
        "https://scalar-staging.riot.im/scalar/api"
    ],
    "hosting_signup_link": "https://element.io/matrix-services?utm_source=element-web&utm_medium=web",
    "bug_report_endpoint_url": "https://element.io/bugreports/submit",
    "uisi_autorageshake_app": "element-auto-uisi",
    "showLabsSettings": true,
    "piwik": {
        "url": "https://piwik.riot.im/",
        "siteId": 1,
        "policyUrl": "https://element.io/cookie-policy"
    },
    "roomDirectory": {
        "servers": [
            "matrix.org",
            "gitter.im",
            "libera.chat"
        ]
    },
    "enable_presence_by_hs_url": {
        "https://matrix.org": false,
        "https://matrix-client.matrix.org": false
    },
    "terms_and_conditions_links": [
        {
            "url": "https://element.io/privacy",
            "text": "Privacy Policy"
        },
        {
            "url": "https://element.io/cookie-policy",
            "text": "Cookie Policy"
        }
    ],
    "hostSignup": {
      "brand": "Element Home",
      "cookiePolicyUrl": "https://element.io/cookie-policy",
      "domains": [
          "matrix.org"
      ],
      "privacyPolicyUrl": "https://element.io/privacy",
      "termsOfServiceUrl": "https://element.io/terms-of-service",
      "url": "https://ems.element.io/element-home/in-app-loader"
    },
    "sentry": {
        "dsn": "https://029a0eb289f942508ae0fb17935bd8c5@sentry.matrix.org/6",
        "environment": "develop"
    },
    "posthog": {
        "projectApiKey": "phc_Jzsm6DTm6V2705zeU5dcNvQDlonOR68XvX2sh1sEOHO",
        "apiHost": "https://posthog.element.io"
    },
    "features": {
        "feature_spotlight": true
    },
    "map_style_url": "https://api.maptiler.com/maps/streets/style.json?key=fU3vlMsMn4Jb6dnEIFsx"
}
EOF


sleep 30;

docker run --rm -v "./synapse:/data" -e SYNAPSE_SERVER_NAME=${DOMAIN} -e SYNAPSE_REPORT_STATS=yes matrixdotorg/synapse:latest generate

sleep 30;

registration_shared_secret=$(cat ./synapse/homeserver.yaml | grep registration_shared_secret: | awk  '{ print $2 }');
echo $registration_shared_secret

macaroon_secret_key=$(cat ./synapse/homeserver.yaml | grep macaroon_secret_key: | awk  '{ print $2 }');
echo $macaroon_secret_key

form_secret=$(cat ./synapse/homeserver.yaml | grep form_secret: | awk  '{ print $2 }');
echo $form_secret

cat /dev/null > ./synapse/homeserver.yaml


cat << EOT > /opt/app/synapse/homeserver.yaml
modules:
server_name: "${DOMAIN}"
pid_file: /data/homeserver.pid
presence:
listeners:
  - port: 8008
    tls: false
    type: http
    x_forwarded: true

    resources:
      - names: [client, federation]
        compress: false

manhole_settings:
limit_remote_rooms:
templates:
retention:
caches:
  per_cache_factors:
database:
  name: psycopg2
  args:
    user: synapse
    password: ${ADMIN_PASSWORD}
    database: synapse
    host: postgres
    cp_min: 5
    cp_max: 10

log_config: "/data/${DOMAIN}.log.config"
media_store_path: "/data/media_store"
url_preview_accept_language:
oembed:
registration_shared_secret: $registration_shared_secret
account_threepid_delegates:
metrics_flags:
report_stats: true
room_prejoin_state:
macaroon_secret_key: $macaroon_secret_key
form_secret: $form_secret
signing_key_path: "/data/${DOMAIN}.signing.key"
old_signing_keys:
trusted_key_servers:
  - server_name: "matrix.org"
saml2_config:
  sp_config:
  user_mapping_provider:
    config:
oidc_providers:
cas_config:
sso:
password_config:
   policy:
ui_auth:
email:
push:
user_directory:
stats:
opentracing:
redis:
background_updates:
enable_registration: true
enable_registration_captcha: false
enable_registration_without_verification: true

EOT