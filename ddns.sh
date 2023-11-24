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

IP_ECHO_EXT_API(){

	echo "Checking your IP shown to httpbin..."
	CURRENT_IP=$(curl -s http://httpbin.org/ip | jq -r '.origin')
	echo "IP = $CURRENT_IP"

}

IP_ECHO_WAN_CHECK(){

	echo "Checking WAN IP address..."
	CURRENT_IP=$(ifconfig $WAN | grep 'inet' | grep -v 'inet6' | awk -F ' ' '{ print $2 }')
	echo "IP = $(CURRENT_IP)"

}


CHECK_IP(){

	#Use this when script is running on top level firewall
	#IP_ECHO_WAN_CHECK

	#Use this when script is running on NATed system
	IP_ECHO_EXT_API

}

#Check presence of needed files
# T B D

#Current IP check process
CURRNET_IP=""
echo "Locally, you were using IP = "
cat $IP_SAVE_FILE

#2023/11/24 : Clearified IP get API TBD position
#echo "Name server was using IP = "
#TBD : sub0 ip return API
#TBD : sub1 ip return API
#TBD : sub2 ip return API
#TBD : sub3 ip return API
#...

CHECK_IP
echo "Current public IP = $CURRENT_IP"
echo "$CURRENT_IP" > "$TEMP_NEW_IP_FILE"



#IP change detection process
if cmp -s "$IP_SAVE_FILE" "$TEMP_NEW_IP_FILE"; then
    IP_HAS_CHANGED=false
else
    IP_HAS_CHANGED=true
    echo "Public IP has changed"
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
