#!/bin/bash

# Initialize the path to root of LE-AliDNS
export LEALIDNS_ACTION=renew-all
export LEALIDNS_ROOT=$(cd `dirname $0`; pwd)/

# Load configuration
source ${LEALIDNS_ROOT}actions/load-config.sh

declare WRITE_LOG_TARGET=$CFG_LOG_FILE

write_log() {

    echo $1;
    echo $1 >> $WRITE_LOG_TARGET;
}

if [[ "$CFG_ON_START" != "" && -x $CFG_ON_START ]]; then
    write_log "Executing hook[before-cert] ${CFG_ON_START}...";
    $CFG_ON_START
fi

if [[ "$CFG_NO_AUTO_UPGRADE" == "on" ]]; then
    ARG_NO_AUTO_UPGRADE="--no-bootstrap --no-self-upgrade"
    write_log "Turned off certbot aoto-updates.";
fi

if [[ "$CFG_ACME_VERSION" == "v2" ]]; then
    USE_CUSTOM_SERVER="--server https://acme-v02.api.letsencrypt.org/directory"
    CHALLENGE_METHOD=dns-01
    write_log "Using ACMEv2 protocol.";
else
    CHALLENGE_METHOD=dns
    write_log "Using ACMEv1 protocol.";
fi

write_log "Renew task started at $(date '+%Y-%m-%d %H:%M:%S')";

# The path to list file of DNS record id
export RECORD_ID_LIST_FILE=./dns-records

rm -f $RECORD_ID_LIST_FILE

mkdir ${LEALIDNS_ROOT}domains -p

if [[ "$LEALIDNS_FORCE" == "1" ]]; then
ARG_FORCE="--force-renewal"
fi

if [[ "$LEALIDNS_DRY_RUN" != "1" ]]
then
    CERTBOT_RESULT=$($CFG_CERTBOT_ROOT/$CFG_CERTBOT_CMD renew \
        --manual \
        --manual-public-ip-logging-ok \
        $USE_CUSTOM_SERVER \
        --preferred-challenges $CHALLENGE_METHOD \
        $ARG_FORCE \
        --agree-tos \
        --email $CFG_EMAIL \
        --rsa-key-size $CFG_RSA_KEY_SIZE \
        $CFG_ON_NEW_CERT \
        $ARG_NO_AUTO_UPGRADE \
        --manual-auth-hook ${LEALIDNS_ROOT}actions/create-dns-record.sh \
        --manual-cleanup-hook ${LEALIDNS_ROOT}actions/clean-dns-record.sh)
else
    echo $CFG_CERTBOT_ROOT/$CFG_CERTBOT_CMD renew \
        --manual \
        --manual-public-ip-logging-ok \
        $USE_CUSTOM_SERVER \
        --preferred-challenges $CHALLENGE_METHOD \
        $ARG_FORCE \
        --agree-tos \
        --email $CFG_EMAIL \
        --rsa-key-size $CFG_RSA_KEY_SIZE \
        $CFG_ON_NEW_CERT \
        $ARG_NO_AUTO_UPGRADE \
        --manual-auth-hook ${LEALIDNS_ROOT}actions/create-dns-record.sh \
        --manual-cleanup-hook ${LEALIDNS_ROOT}actions/clean-dns-record.sh
fi;

write_log "Details: $CERTBOT_RESULT";

sh ${LEALIDNS_ROOT}actions/clean-dns-record.sh

if [[ "$CFG_ON_END" != "" && -x $CFG_ON_END ]]; then
    write_log "Executing hook[after-cert] ${CFG_ON_END}...";
    $CFG_ON_END
fi;
