#set env vars
set -o allexport; source .env; set +o allexport;

#wait until the server is ready
echo "Waiting for software to be ready ..."
sleep 30s;

docker-compose exec -T synapse register_new_matrix_user -u admin -p ${ADMIN_PASSWORD} -a -c /data/homeserver.yaml http://localhost:8008