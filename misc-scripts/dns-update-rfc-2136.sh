#! /bin/sh

set -euo pipefail

STARTDATE=$(date -Iseconds)
HOST=$(hostname)
HOSTNAME=$(hostname)

DNS_SERVER="dns.omgpwned.net"
ZONE="omgpwned.net"
TTL="3600"

if [[ ! $HOSTNAME =~ $ZONE ]]; then
    HOSTNAME="$HOSTNAME.$ZONE"
fi

if ! command -v curl &> /dev/null
then
    echo "curl could not be found"
    exit 1
fi

if ! command -v jq &> /dev/null
then
    echo "jq could not be found"
    exit 1
fi


if ! command -v nsupdate &> /dev/null
then
    echo "nsupdate could not be found"
    exit 1
fi

if [[ ! -f /etc/letsencrypt/creds.ini ]]; then
    echo "digital ocean credentials file not found"
    exit 1
fi


echo $HOSTNAME

IPV4_IP=$(ip -4 addr show eth0 | grep "scope global" | grep -Po '(?<=inet )[\d.]+')
IPV6_IP=$(ip -6 addr show eth0 | grep "scope global" | grep -Po '(?<=inet6 )[\dabcedf:]+')
EXT_IP=$(curl -ks --ipv4 ifconfig.me)

DO_TOKEN=$(cat /etc/letsencrypt/creds.ini | sed 's/dns_digitalocean_token = //')
curl -ks -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $DO_TOKEN" "https://api.digitalocean.com/v2/domains/$ZONE/records" | jq -r '.domain_records[] | "\(.id) \(.name) \(.type) \(.data)"'  > do_records.tmp

update_int() {
    local recordType=$1
    local sysAddr=$2
    [[ $recordType = "A" ]] && local ipType="IPv4" || local ipType="IPv6"
    
    echo "Internal Processing of $ipType ($recordType) Started..."

    local filename="./$recordType-update.$STARTDATE.dns"
    local dnsResponse=$(dig $recordType +short @$DNS_SERVER "$HOSTNAME")

    echo "Address from System: $([[ ! -z "$dnsResponse" ]] && echo $dnsResponse || echo 'Empty')"
    echo "System Address: $sysAddr"
    
    if [[ -z $dnsResponse ]] || [[ $dnsResponse != $sysAddr ]]; then
        echo "$ipType addresses do not match, writing update file"
        cat <<EOF > "$filename"

server $DNS_SERVER
zone $ZONE
$([[ ! -z $dnsResponse ]] && echo "update delete $HOSTNAME. $recordType")
update add $HOSTNAME. $TTL $recordType $sysAddr
show
send

EOF
        nsupdate "$filename" > /dev/null
    else
        echo "$ipType addresses match, no update performed"
    fi

    echo "Internal Processing of $ipType ($recordType) Complete"
}

update_ext() {
    local recordType=$1
    local sysAddr=$2
    [[ $recordType = "A" ]] && local ipType="IPv4" || local ipType="IPv6"

    local doRecord=$(grep "$HOST $recordType " do_records.tmp)

    echo "External Processing of $ipType ($recordType) Started..."
    echo "DO Record: [$doRecord]"

    if [[ -n "$doRecord" ]]; then 
        local doRecordId=$(echo $doRecord | awk '{print $1}')
        local doRecordIp=$(echo $doRecord | awk '{print $4}')
    fi

    

    if [[ -z ${doRecordId+x} ]]; then
        echo "no Record found, sending creation"
        curl -ks -X POST -H "Content-Type: application/json" \
                -H "Authorization: Bearer $DO_TOKEN" \
                -d "{\"type\":\"$recordType\",\"data\":\"$sysAddr\",\"name\":\"$HOST\",\"ttl\":$TTL}" \
                "https://api.digitalocean.com/v2/domains/$ZONE/records" > /dev/null

        echo "$recordType record for ($HOSTNAME) created and set to $sysAddr"

    elif [[ $doRecordIp != $sysAddr ]]; then
        echo "Record mismatch found, sending update"
        curl -ks -X PUT -H "Content-Type: application/json" \
              -H "Authorization: Bearer $DO_TOKEN" \
              -d "{\"type\":\"$recordType\",\"data\":\"$sysAddr\"}" \
              "https://api.digitalocean.com/v2/domains/$ZONE/records/$doRecordId" > /dev/null
        
        echo "$recordType record for $doRecordId ($HOSTNAME) updated and set to $sysAddr"
    else
        echo "record found and matched, no update performed"        
    fi

    echo "External Processing of $ipType ($recordType) Complete"
}


update_int "A" $IPV4_IP
update_int "AAAA" $IPV6_IP

update_ext "A" $EXT_IP
update_ext "AAAA" $IPV6_IP