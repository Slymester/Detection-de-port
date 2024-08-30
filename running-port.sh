#!/bin/bash

# Check if an IP address or domain is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <ip_address_or_domain>"
    exit 1
fi

ip_address=$1

# Color codes for output
GREEN="\033[32m"
RED="\033[31m"
NC="\033[0m" # No Color

# Define services and their associated ports
declare -A services_ports=(
    [ftp]=21
    [ssh]=22
    [telnet]=23
    [smtp]=25
    [dns]=53
    [http]=80
    [pop3]=110
    [imap]=143
    [https]=443
    [smb]=445
    [rdp]=3389
    [mysql]=3306
    [postgresql]=5432
    [vnc]=5900
    [ldap]=389
    [nfs]=2049
    [snmp]=161
    [irc]=6667
    [docker]=2375
    [elasticsearch]=9200
    [mongodb]=27017
    [redis]=6379
    [kafka]=9092
    [rabbitmq]=5672
)

# Function to detect the version of a service and check for vulnerabilities
get_version_and_vuln() {
    local service=$1
    local port=$2
    local version=""
    local vuln=""

    case "$service" in
        ftp)
            if command -v curl >/dev/null 2>&1; then
                version=$(curl -s "ftp://$ip_address:$port" --connect-timeout 2 | grep -i "220" | awk '{print $3}')
                [[ "$version" == "vsftpd 2.3.4" ]] && vuln="Backdoor (CVE-2011-2523)"
            else
                echo "Missing tool: curl is required to check FTP version."
            fi
            ;;
        ssh)
            if command -v ssh >/dev/null 2>&1; then
                version=$(ssh -o BatchMode=yes -o ConnectTimeout=2 $ip_address -p $port 2>&1 | grep -i "SSH-" | awk '{print $1}')
                [[ "$version" == "SSH-2.0-OpenSSH_7.2p2" ]] && vuln="Use-After-Free (CVE-2016-8858)"
            else
                echo "Missing tool: ssh is required to check SSH version."
            fi
            ;;
        smtp)
            if command -v nc >/dev/null 2>&1; then
                version=$(timeout 2 bash -c "echo | nc -w 2 $ip_address $port" 2>/dev/null | grep -i "220" | awk '{print $2, $3}')
                [[ "$version" =~ "Exim 4.87" || "$version" =~ "Exim 4.91" ]] && vuln="Remote Code Execution (CVE-2019-15846)"
            else
                echo "Missing tool: netcat (nc) is required to check SMTP version."
            fi
            ;;
        http|https)
            if command -v curl >/dev/null 2>&1; then
                version=$(curl -sI "$service://$ip_address:$port" --connect-timeout 2 | grep -i "Server:" | awk '{print $2, $3}')
                [[ "$version" =~ "Apache/2.2.34" || "$version" =~ "Apache/2.4.49" ]] && vuln="Path Traversal (CVE-2021-41773)"
            else
                echo "Missing tool: curl is required to check HTTP/HTTPS version."
            fi
            ;;
        mysql)
            if command -v mysql >/dev/null 2>&1; then
                version=$(mysql -h $ip_address -P $port -u root -e 'SELECT VERSION();' 2>/dev/null | tail -n1)
                [[ "$version" == "5.7.29" ]] && vuln="Denial of Service (CVE-2020-2574)"
            else
                echo "Missing tool: mysql is required to check MySQL version."
            fi
            ;;
        postgresql)
            if command -v psql >/dev/null 2>&1; then
                version=$(psql -h $ip_address -p $port -U postgres -c 'SELECT version();' 2>/dev/null | grep -i "PostgreSQL" | awk '{print $2}')
                [[ "$version" == "9.6.10" ]] && vuln="SQL Injection (CVE-2018-1058)"
            else
                echo "Missing tool: psql is required to check PostgreSQL version."
            fi
            ;;
        redis)
            if command -v redis-cli >/dev/null 2>&1; then
                version=$(redis-cli -h $ip_address -p $port INFO 2>/dev/null | grep -i "redis_version" | awk -F: '{print $2}')
                [[ "$version" == "5.0.5" ]] && vuln="Remote Code Execution (CVE-2019-10192)"
            else
                echo "Missing tool: redis-cli is required to check Redis version."
            fi
            ;;
        *)
            echo "No specific version detection method for $service."
            ;;
    esac

    if [ -n "$version" ]; then
        if [ -n "$vuln" ]; then
            echo -e "${RED}$service version $version (Vulnerability: $vuln)${NC}"
        else
            echo -e "${GREEN}$service version $version (No known vulnerabilities)${NC}"
        fi
    fi
}

# Loop to check each service and its port
for service in "${!services_ports[@]}"; do
    port=${services_ports[$service]}
    
    echo "Checking $service on port $port..."
    
    if timeout 1 bash -c "echo > /dev/tcp/$ip_address/$port" 2>/dev/null; then
        echo -e "${GREEN}$service is available on $ip_address:$port${NC}"
        get_version_and_vuln $service $port
    else
        echo -e "${RED}$service is not available on $ip_address:$port${NC}"
    fi

    echo "------------------------------"
done
