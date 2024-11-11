#!/bin/bash

# Help display function
function show_help {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help                Displays this help."
    echo "  -v, --verbose             Full verbose mode."
    echo "  -p, --port-range <ports>  Specifies a range of ports to scan (ex: 1-1000)."
	echo
    echo "         Script Features:"
    echo "  - Target IP address: You will be prompted to enter the IP address to scan."
    echo "  - Scan speed: Choice of speed (fast, medium, slow) affecting the timeout."
    echo "  - Scan type: Standard ports or all ports."
    echo "  - Light verbose mode: Displays progress in percentage without cluttering the screen."
    echo "  - Pause and resume: Press Ctrl+Z to pause, then 'fg' to resume."
    echo "  - Stop: Press Ctrl+C to interrupt the scan."
	exit 0
}

# 1. Check options
verbose_mode=false
port_range=""
while [[ "$1" != "" ]]; do
    case $1 in
        -h | --help )          show_help
                                exit
                                ;;
        -v | --verbose )       verbose_mode=true
                                ;;
        -p | --port-range )    shift
                                port_range=$1
                                ;;
        * )                    echo "Unknown option: $1"
                                show_help
                                exit 1
    esac
    shift
done

# 2. Ask for the target IP address
read -p "Enter the target IP address: " ip

# 3. Check the validity of the IP
if ! [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid IP address."
    exit 1
fi

# 4. Check connectivity (ping)
if ! ping -c 1 $ip &> /dev/null; then
    echo "The IP address $ip is unreachable."
    exit 1
fi

# 5. Ask if the user wants verbose mode
read -p "Would you like to enable full verbose mode? (y/n, default: n): " verbose_choice
verbose_choice=${verbose_choice:-n}

if [[ $verbose_choice == "y" ]]; then
    verbose_mode=true
fi

# 5. Ask for the scan speed choice
echo "Choose the scan speed (default: medium):"
echo "1) Fast"
echo "2) Medium"
echo "3) Slow"
read -p "Your choice (1/2/3): " speed_choice
timeout_val=1  # Default value
case $speed_choice in
    1) timeout_val=0.5 ;;  # fast
    2) timeout_val=1 ;;    # medium
    3) timeout_val=3 ;;    # slow
    *) echo "Invalid choice, defaulting to medium speed." ;;
esac

# 6. Ask if the user wants to save to a file
read -p "Do you want to save the result to a file? (y/n, default: n): " save_file
save_file=${save_file:-n}

output_file=""
if [[ $save_file == "y" ]]; then
    # 7. Set the output file name
    date=$(date +%Y%m%d_%H%M%S)
    default_output="Scan_$date.txt"
    read -p "Enter the output file name (press Enter to use $default_output): " output_file
    output_file=${output_file:-$default_output}
fi

# 8. Ask for the scan type (standard ports, full scan or port range)
echo "Scan type (default: standard ports):"
echo "1) Standard ports scan"
echo "2) Full scan (all ports)"
echo "3) Manual port range (ex: 1-1000)"
read -p "Your choice (1/2/3): " scan_type

# Determine the ports to scan
if [[ $scan_type == 1 ]]; then
    ports=("${!standard_ports[@]}")
elif [[ $scan_type == 2 ]]; then
    ports=($(seq 1 65535))  # Full scan
elif [[ $scan_type == 3 ]]; then
    read -p "Enter the range of ports to scan (ex: 1-1000): " port_range
    if [[ $port_range =~ ^[0-9]+-[0-9]+$ ]]; then
        IFS='-' read -r start_port end_port <<< "$port_range"
        ports=($(seq $start_port $end_port))
    else
        echo "Invalid port range. Use the format <start>-<end>."
        exit 1
    fi
else
    ports=("${!standard_ports[@]}")  # Default: standard ports
fi

# 9. Define standard ports
declare -A standard_ports=(
    [20]="FTP-DATA" [21]="FTP" [22]="SSH" [23]="Telnet" [25]="SMTP" 
    [53]="DNS" [80]="HTTP" [110]="POP3" [119]="NNTP" [135]="MS RPC" 
    [139]="NetBIOS" [143]="IMAP" [389]="LDAP" [443]="HTTPS" 
    [445]="Microsoft-DS" [465]="SMTPS" [514]="Syslog" [993]="IMAPS" 
    [995]="POP3S" [11211]="Memcached" [1433]="MSSQL" [1521]="Oracle DB" 
    [1723]="PPTP" [1883]="MQTT" [2049]="NFS" [2375]="Docker" 
    [2376]="Docker TLS" [2483]="Oracle DB" [27017]="MongoDB" 
    [2888]="Hadoop" [3306]="MySQL" [3389]="RDP" [4567]="Galera Cluster" 
    [5432]="PostgreSQL" [5900]="VNC" [5984]="CouchDB" [5985]="WinRM HTTP" 
    [5986]="WinRM HTTPS" [6379]="Redis" [6443]="Kubernetes API" 
    [7000]="Cassandra" [7199]="Cassandra JMX" [7777]="Oracle XDB" 
    [8080]="HTTP-ALT" [8086]="InfluxDB" [8161]="Apache ActiveMQ" 
    [8443]="HTTPS-ALT" [8500]="Consul" [8888]="Multiples" [9092]="Kafka" 
    [9200]="Elasticsearch" [9418]="Git" [10000]="Webmin" 
    [11211]="Memcached" [20000]="Multiples" [27017]="MongoDB" 
    [50000]="SAP"
)

# 10. Start the scan
echo "Starting the scan for IP $ip..." 
open_ports=()
closed_ports=0

# Determine the ports to scan
if [[ $scan_type == 1 ]]; then
    ports=("${!standard_ports[@]}")
elif [[ $scan_type == 2 ]]; then
    ports=($(seq 1 65535))  # Full scan
elif [[ $scan_type == 3 ]]; then
    if [[ -z $port_range ]]; then
        echo "Please specify a range of ports."
        exit 1
    fi
    IFS='-' read -r start_port end_port <<< "$port_range"
    ports=($(seq $start_port $end_port))
else
    ports=("${!standard_ports[@]}")  # Default: standard ports
fi

# 11. Port scanning loop
total_ports=${#ports[@]}
for i in "${!ports[@]}"; do
    port=${ports[i]}
    progress=$(( (i + 1) * 100 / total_ports ))

    if [[ $verbose_mode == true ]]; then
        # Full verbose mode: display tested ports
        echo "Scanning port $port..."
    else
        # Default verbose mode: display only percentage
        echo -ne "\rProgress: $progress%"; sleep 0.1  # Update percentage without a new line
    fi

    result=$(timeout $timeout_val bash -c "echo >/dev/tcp/$ip/$port" 2>/dev/null && echo "open" || echo "closed")

    if [[ $result == "open" ]]; then
        service="${standard_ports[$port]:-Unknown}"
        echo -e "\033[32mPort $port open ($service) - standard services, to be verified.\033[0m"  # Green
        open_ports+=("$port ($service)")
    else
        ((closed_ports++))  # Increment closed ports counter without display
    fi
done

# 12. Scan summary
scan_output="Ports tested: $total_ports\nClosed ports: $closed_ports\nOpen ports: ${#open_ports[@]} (${open_ports[*]})"
echo -e "\033[37m$scan_output\033[0m"  # White
if [[ -n $output_file ]]; then
    echo -e "$scan_output" > "$output_file"
fi

# 13. End of scan
echo -e "\nScan completed."
