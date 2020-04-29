#!/usr/bin/env bash
set -o errexit
set -o nounset
set -euo pipefail
# to ignore /usr/lib/python3.7/site-packages/urllib3/connectionpool.py:851: InsecureRequestWarning: Unverified HTTPS request is being made. Adding certificate verification is strongly advised. See: https://urllib3.readthedocs.io/en/latest/advanced-usage.html#ssl-warnings
export PYTHONWARNINGS="ignore:Unverified HTTPS request"
export VAULT_TOKEN=${INITIAL_VAULT_TOKEN}
export ROLE_ID=${ROLE_ID}
DEPLOY_VIA_IP="${DEPLOY_VIA_IP:-private_ip}"
export DOCKER_REGISTRY=${DOCKER_REGISTRY}
export DOCKER_REGISTRY_SECRETS_PATH=${DOCKER_REGISTRY_SECRETS_PATH}

mkdirforfile() {
    if [ $# -lt 1 ]; then
        echo "Missing argument";
        return 1;
    fi

    for f in "$@"; do
        mkdir -p -- "$(dirname -- "$f")"
#        touch -- "$f"
    done
}

export VAULT_TOKEN=$(\
vault write -field=token auth/approle/login \
    role_id="${ROLE_ID}" \
    secret_id="$(vault write -field=secret_id -f auth/approle/role/jenkins/secret-id)" \
)


cd ${COMPOSE_FOLDER}

DOCKER_BUILDER_HOST_IP="$(vault kv get -field=build--private_ip serverConfigs/inventory)"
DOCKER_BUILDER_CERT_INFO="$(vault kv get -format=json serverConfigs/etc/build-docker-tls-certs)"
echo "${DOCKER_BUILDER_CERT_INFO}" | jq -r .data.data.TLSCert > /tmp/client.crt
echo "${DOCKER_BUILDER_CERT_INFO}" | jq -r .data.data.TLSKey > /tmp/client.key



# Usually .env would be referenced by containers to use
# & build would complain if this is missing
echo '' > .env

STAGE=build node /js/index.js
echo '==============BUILD==============='
docker-compose --log-level ERROR -H tcp://${DOCKER_BUILDER_HOST_IP}:2376 \
        --tls \
        --tlscert /tmp/client.crt \
        --tlskey /tmp/client.key \
        build

DOCKER_REGISTRY_AUTH="$(vault kv get -field=base64 serverConfigs/registry/${DOCKER_REGISTRY})"

mkdir -p ~/.docker
cat > ~/.docker/config.json <<- EOM
{
	"auths": {
		"${DOCKER_REGISTRY}": {
			"auth": "${DOCKER_REGISTRY_AUTH}"
		}
	}
}
EOM

# enrich .env with common docker-compose variables
STAGE=push node /js/index.js
echo '==============PUSH==============='
docker-compose --log-level ERROR -H tcp://${DOCKER_BUILDER_HOST_IP}:2376 \
        --tls \
        --tlscert /tmp/builder.crt \
        --tlskey /tmp/builder.key \
        push

touch .env
cp .env .--env--original
for DEPLOY_TO_ONE in ${DEPLOY_TO}
do
DEPLOY_TO_ONE=${DEPLOY_TO_ONE} STAGE=deploy node /js/index.js
DEPLOY_HOST_IP=$(vault kv get -field=${DEPLOY_TO_ONE}--${DEPLOY_VIA_IP} serverConfigs/inventory)
echo '==============PULL==============='
cat ".${DEPLOY_TO_ONE}.env" >> .env
echo -e "\nHOST_NAME=${DEPLOY_TO_ONE}" >> .env
env docker-compose -H tcp://${DEPLOY_HOST_IP}:2376  \
          --tls \
          --tlscert /tmp/client.crt \
          --tlskey /tmp/client.key \
          -f docker-compose.yml \
          pull
echo '==============UP==============='
env docker-compose -H tcp://${DEPLOY_HOST_IP}:2376  \
          --tls \
          --tlscert /tmp/client.crt \
          --tlskey /tmp/client.key \
          -f docker-compose.yml \
          up -d
\cp -r .--env--original .env
done