

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

RECORD_ID="`curl -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=A&name=${DOMAIN_NAME}&content=${CURRENT_PUBLIC_IP}&proxied=${PROXY}&page=1&per_page=20&order=type&direction=desc&match=all" \
	-H "X-Auth-Email:${AUTH_EMAIL}" \
	-H "X-Auth-Key:${AUTH_KEY}" \
	-H "Content-Type: application/json" | jq '.result[].id' | sed 's/\"//g'`"

####################################################################################################
#                                                                                                  #
#                                          Update DDNS IP                                          #
#                                                                                                  #
####################################################################################################

if [ "${NEW_PUBLIC_IP}" = "${CURRENT_PUBLIC_IP}" ]; then
	logger --no-act -s "DDNS Updater: IP ${CURRENT_PUBLIC_IP} for ${DOMAIN_NAME} has not changed." 2>&1 | sed 's/^<[0-9]\+>//' >> ${LOG_FILE}
	exit 1
else
	curl -X PUT "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${RECORD_ID}" \
		-H "X-Auth-Email:${AUTH_EMAIL}" \
		-H "X-Auth-Key:${AUTH_KEY}" \
		-H "Content-Type: application/json" \
		--data "{\"type\":\"A\",\"name\":\"${DOMAIN_NAME}\",\"content\":\"${NEW_PUBLIC_IP}\",\"ttl\":\"${TTL}\",\"proxied\":${PROXY}}"
	echo ${NEW_PUBLIC_IP} > ${CURRENT_IP_FILE}
	logger --no-act -s "DDNS Updater: IP ${NEW_PUBLIC_IP} for ${DOMAIN_NAME} is update" 2>&1 | sed 's/^<[0-9]\+>//' >> ${LOG_FILE}
fi
