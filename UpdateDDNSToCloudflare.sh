

#!/bin/bash

####################################################################################################
#                                                                                                  #
#                                        Global Parameters                                         #
#                                                                                                  #
####################################################################################################

NEW_PUBLIC_IP="`curl -s https://ifconfig.io || curl -s https://ipv4.icanhazip.com/`"
CURRENT_PUBLIC_IP="`cat /tmp/current_ip.txt`"
DOMAIN_NAME='Your Doamin Name'
AUTH_EMAIL='Your E-mail Address'
AUTH_KEY='You can find on cloudflare website'
ZONE_ID='You can find on cloudflare website'
TTL='300'
PROXY='true'
LOG_FILE='/var/log/UpdateDDNSToCloudflare.log'
CURRENT_IP_FILE='/tmp/current_ip.txt'

####################################################################################################
#                                                                                                  #
#                                      Setup Logger Into File                                      #
#                                                                                                  #
####################################################################################################

if [ ! -f ${LOG_FILE} ]; then
	touch ${LOG_FILE} && chmod 0600 ${LOG_FILE}
fi

####################################################################################################
#                                                                                                  #
#                                          Get Record ID                                           #
#                                                                                                  #
####################################################################################################

RECORED_ID="$(curl -X GET --url https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records \
	-H "Content-Type: application/json" \
	-H "X-Auth-Email: ${AUTH_EMAIL}" \
	-H "X-Auth-Key: ${AUTH_KEY}" | jq -r '.result[0].id')"

####################################################################################################
#                                                                                                  #
#                                          Update DDNS IP                                          #
#                                                                                                  #
####################################################################################################

if [ "${NEW_PUBLIC_IP}" = "${CURRENT_PUBLIC_IP}" ]; then
	logger --no-act -s "DDNS Updater: IP ${CURRENT_PUBLIC_IP} for ${DOMAIN_NAME} has not changed." 2>&1 | sed 's/^<[0-9]\+>//' >> ${LOG_FILE}
	exit 1
else
	curl -X PUT --url https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${RECORED_ID} \
		-H "Content-Type: application/json" \
		-H "X-Auth-Email:${AUTH_EMAIL}" \
		-H "X-Auth-Key:${AUTH_KEY}" \
		--data "{
		\"type\":\"A\",
		\"name\":\"${DOMAIN_NAME}\",
		\"content\": \"${NEW_PUBLIC_IP}\",
		\"proxied\":${PROXY},
		\"ttl\":\"${TTL}\",
		\"comment\": \"Update Domain record at $(date +%F-%H:%M:%S)\"
	}"
	echo ${NEW_PUBLIC_IP} > ${CURRENT_IP_FILE}
	logger --no-act -s "DDNS Updater: IP ${NEW_PUBLIC_IP} for ${DOMAIN_NAME} is update" 2>&1 | sed 's/^<[0-9]\+>//' >> ${LOG_FILE}
fi
