#!/bin/sh


#Configuration
WAN="igc0"
DD_SCRIPT_PATH="$PWD"
TEMP_NEW_IP_FILE="$DD_SCRIPT_PATH/newip.txt"
IP_SAVE_FILE="$DD_SCRIPT_PATH/currentip.txt"


#NS specific
NS1_API_KEY="YOUR_KEY"
ZONE="YOUR_DOMAIN.com"
DOMAIN="SUB_DOMAIN"

#Functions
NS1_A_RECORD_UPDATE() {
    local current_ip=$1
    local zone=$2
    local domain=$3
    local nsone_api_key=$4

    local response=$(curl -s -S -X POST -H "X-NSONE-Key: $nsone_api_key" -d "{\"answers\": [{\"answer\": [\"$current_ip\"]}], \"ttl\": 3600}" "https://api.nsone.net/v1/zones/$zone/$domain.$zone/A" 2>&1)

    echo "$(date): $response" >> $DD_SCRIPT_PATH/log.txt
}


#Check presence of needed files
# T B D

#Current IP check process
echo "You were using ip "
cat $IP_SAVE_FILE
CURRENT_IP=$(ifconfig $WAN | grep 'inet' | grep -v 'inet6' | awk -F ' ' '{ print $2 }')
echo "Current WAN IP = $CURRENT_IP"
echo "$CURRENT_IP" > "$TEMP_NEW_IP_FILE"



#IP change detection process
if cmp -s "$IP_SAVE_FILE" "$TEMP_NEW_IP_FILE"; then
    IP_HAS_CHANGED=false
else
    IP_HAS_CHANGED=true
    echo "WAN IP has changed"
fi




#IP update process
if [ "$IP_HAS_CHANGED" = "true" ]; then
    echo "Requesting POST to NS1..."
    echo "$(date): Request POST for IP : $CURRENT_IP" >> $DD_SCRIPT_PATH/log.txt

    NS1_A_RECORD_UPDATE "$CURRENT_IP" "$ZONE" "$DOMAIN" "$NS1_API_KEY"

    echo "$CURRENT_IP" > "$IP_SAVE_FILE"

else
    echo "IP has not changed."
fi



#Post Process
rm $TEMP_NEW_IP_FILE
