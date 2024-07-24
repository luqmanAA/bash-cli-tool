#!/bin/bash

# A basic boilerplate for a CLI tool using Bash

# Version declaration:
version="1.0.0"

function show_help() {
cat << EOF
Usage: ${0##*/} [-h] [-v] [-o OUTFILE] [FILE]...
This is a CLI tool.
    -h, --help                          Display this help and exit
    -p, --port                          List all active ports and services
    -p, --port <port_number>            Provide details of the provided port
    -d, --docker                        List all Docker images and containers
    -d, --docker <container id/name>    Provide detailed information about a specific container
    -n, --nginx                         List all Nginx domains and their ports 
    -n, --nginx <domain_name>           Provide detailed configuration information for a specific domain 
    -u, --users                         List all users and their last logins
    -u, --users <username>              Provide detailed information for a specific user 
    -t, --time                          Display activities within a specified time range
    -v                                  Display version information and exit
EOF
}

# Function to process and display port information
process_ports() {
    local filter="$1"  # Can be empty string for all ports or a specific port
    local header="PORT SERVICE USER"  # Header to print
    
    # Print headers
    printf '%-10s %-20s %-10s\n' $header
    
    # Process netstat output with optional filter
    sudo netstat -tulnp | awk -v filter="$filter" 'NR>2 && ($4 ~ ":"filter"$" || filter == "") {
        split($4, host, ":")
        split($7, name, "/")
        if (name[2] != "" && host[length(host)] != "") {
            sub(/:$/, "", name[2])
            cmd = "ps -o user= -p " name[1]
            cmd | getline user
            close(cmd)
            gsub(/^ +| +$/, "", user)  # Remove leading and trailing whitespace from user
            printf "%-10s %-20s %-10s\n", host[length(host)], name[2], user
        }
    }'
}

# Function to display all active ports and services
list_active_ports() {
    process_ports ""
}

# Function to display detailed information about a specific port
show_port_details() {
    local port="$1"
    process_ports "$port" "PORT SERVICE USER"
}

# Function to display all docker images and containers
list_docker_images_and_containers() {
    echo "Docker Images"
    echo "----------------------------------------"
    sudo docker image ls

    echo "Docker Containers"
    echo "----------------------------------------"
    sudo docker ps
}

show_docker_container_details() {
    local identifier="$1"
    sudo docker inspect $identifier
}

list_nginx_domains_and_ports() {
    # Print header
    printf '%-10s %-40s %-20s %-30s\n' 'PORT' 'DOMAIN' 'CONFIG FILE' 'PROXY'

    # Find all server blocks and extract relevant information
    sudo grep -R "server {" /etc/nginx/ | while read -r server_block; do
        config_file=$(echo $server_block | awk -F':' '{print $1}')
        server_line=$(echo $server_block | awk -F':' '{print $2}')
        
        # Extract domain names and ports
        domain=$(grep -A10 -B10 "server {" "$config_file" | grep "server_name" | awk '{print $2}')
        port=$(grep -A10 -B10 "server {" "$config_file" | grep "listen" | awk '{print $2}')
        proxy=$(grep -A10 -B10 "server {" "$config_file" | grep "proxy_pass" | awk '{print $2}')

        # Clean up port value by removing unwanted characters
        port=$(echo "$port" | tr -d ',;' | xargs)  # Remove commas and semicolons, trim spaces
        domain=$(echo "$domain" | tr -d ',;' | xargs)  # Remove commas and semicolons, trim spaces
        proxy=$(echo "$proxy" | tr -d ';' | xargs)  # Remove semicolons, trim spaces

        if [ -n "$domain" ] && [ "$domain" != "server_name" ] && [ "$port" != "listen" ]; then
            printf "%-10s %-40s %-20s %-30s\n" "$port" "$domain" "$config_file" "$proxy"
        fi

    done
}

show_nginx_domain_details() {
    search_domain=$1

    # Print header
    printf '%-10s %-40s %-20s\n' 'PORT' 'DOMAIN' 'CONFIG FILE'

    # Find all server blocks and extract relevant information
    sudo grep -R "server {" /etc/nginx/ | while read -r server_block; do
        config_file=$(echo $server_block | awk -F':' '{print $1}')
        server_line=$(echo $server_block | awk -F':' '{print $2}')

        # Extract domain names and ports
        domain=$(grep -A10 -B10 "server {" "$config_file" | grep "server_name" | awk '{print $2}')
        port=$(grep -A10 -B10 "server {" "$config_file" | grep "listen" | awk '{print $2}')

        # Clean up port value by removing unwanted characters
        port=$(echo "$port" | tr -d ',;' | xargs)  # Remove commas and semicolons, trim spaces

        if [[ "$domain" == *"$search_domain"* ]] && [ -n "$domain" ] && [ "$domain" != "server_name" ] && [ "$port" != "listen" ]; then
            printf "%-10s %-40s %-20s\n" "$port" "$domain" "$config_file"
        fi
    done
}

list_user_last_login(){
    # Print header
    printf '%-15s %-20s\n' 'USER' 'LAST LOGIN'

    # Loop through each user with UID >= 1000
    awk -F: '$3 >= 1000 {print $1}' /etc/passwd | while read user; do
        # Get the last login information
        lastlog_output=$(lastlog -u "$user" 2>/dev/null)
        
        # Extract relevant details (skip the header line)
        echo "$lastlog_output" | awk 'NR>1 {printf "%-15s %-30s\n", "'$user'", $4" "$5" "$6" "$7" "$8}'
    done

}

user_info() {
  local USERNAME="$1"

  # Check if the user exists
  if ! id "$USERNAME" &>/dev/null; then
    echo "User '$USERNAME' does not exist."
    return 1
  fi

  # User Information
  echo -e "\nUser Information:"
  printf "%-20s: %s\n" "Username" "$USERNAME"
  printf "%-20s: %s\n" "User ID" "$(id -u "$USERNAME")"
  printf "%-20s: %s\n" "Group ID" "$(id -g "$USERNAME")"
  printf "%-20s: %s\n" "Groups" "$(id -G "$USERNAME")"
  printf "%-20s: %s\n" "Home Directory" "$(getent passwd "$USERNAME" | cut -d: -f6)"
  printf "%-20s: %s\n" "Shell" "$(getent passwd "$USERNAME" | cut -d: -f7)"

  # Last Login Info
  echo -e "\nLast Login Info:"
  printf "%-20s %-15s %-15s %-15s %-15s\n" "Username" "Port" "From" "Last Login" "Days Ago"
  lastlog -u "$USERNAME" | awk 'NR>1 {printf "%-20s %-15s %-15s %-15s %-15s\n", $1, $2, $3, $4, $5}'

  # Processes Owned by User
  echo -e "\nProcesses Owned by User:"
  ps -u "$USERNAME" --format=pid,comm,etime --sort=etime | awk 'NR==1 {printf "%-10s %-25s %-15s\n", "PID", "Command", "Elapsed Time"} NR>1 {printf "%-10s %-25s %-15s\n", $1, $2, $3}'

  # Total Files and Directories Owned by User
  echo -e "\nTotal Files and Directories Owned by User:"
  file_count=$(find /home/"$USERNAME" -type f -user "$USERNAME" 2>/dev/null | wc -l)
  dir_count=$(find /home/"$USERNAME" -type d -user "$USERNAME" 2>/dev/null | wc -l)

  printf "%-20s %-10s\n" "Files" "$file_count"
  printf "%-20s %-10s\n" "Directories" "$dir_count"
}

show_activity_in_time_range(){
 
    # Add default time if not provided
    if [[ "$start_time" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        start_time="$start_time 00:00:00"
    fi

    if [[ "$end_time" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        end_time="$end_time 23:59:59"
    fi


    {
    echo -e "Displaying activities from $start_time to $end_time...\n"
    # Print header
    printf "%-19s %-30s %s\n" "TIMESTAMP" "SERVICE" "MESSAGE"

    # Print the log entries
    journalctl --since "$start_time" --until "$end_time" | \
    awk '{ 
        timestamp = $1 " " $2 " " $3
        service = $5
        message = substr($0, index($0, $6)) # Extract message starting from $6
        printf "%-19s %-30s %s\n", timestamp, service, message
    }'
    } | less
}

if [[ $# -eq 0 ]]; then
    show_help
    exit 0
fi


while [[ "$1" != "" ]]; do
    case $1 in
    -h | --help)
        show_help
        exit 0
        ;;
    -v)  echo "Version: $version"
        exit 0
        ;;
    -p | --port )
        shift
        if [[ -z "$1" || "$1" =~ ^- ]]; then
            # No port number provided, use list_active_ports
            set -- "$1"
            list_active_ports
            exit 0
        elif [[ -n "$1" ]]; then
            # Port number provided, use show_port_details
            show_port_details "$1"
            exit 0
        fi
        ;;
    -d | --docker )
        shift
        if [[ -z "$1" || "$1" =~ ^- ]]; then
            # No container name/id provided, use list_docker_images_and_containers
            set -- "$1"
            list_docker_images_and_containers
            exit 0
        elif [[ -n "$1" ]]; then
            # Container name/id provided number provided, use show_docker_container_details
            show_docker_container_details "$1"
            exit 0
        fi
        ;;
    -n | --nginx )
        shift
        if [[ -z "$1" || "$1" =~ ^- ]]; then
            # No domain provided, use list_nginx_domains_and_ports
            set -- "$1"
            list_nginx_domains_and_ports
            exit 0
        elif [[ -n "$1" ]]; then
            # Domain  provided, use show_nginx_domain_details
            show_nginx_domain_details "$1"
            exit 0
        fi
        ;;
    -u | --users )
        shift
        if [[ -z "$1" || "$1" =~ ^- ]]; then
            # No username provided, use list_user_last_login
            set -- "$1"
            list_user_last_login
            exit 0
        elif [[ -n "$1" ]]; then
            # Username  provided, use user_info
            user_info "$1"
            exit 0
        fi
        ;;
    -t | --time )
        shift
        if [[ -z "$1" || "$1" =~ ^- ]]; then
            echo "Usage: $0 <start-time> <end-time>"
            echo "Example: $0 2024-07-21  2024-07-21"
            exit 1
        fi

        start_time="$1"
        shift

        if [[ -z "$1" || "$1" =~ ^- ]]; then
            echo "Usage: $0 <start-time> <end-time>"
            echo "Example: $0 '2024-07-21 15:00:00' '2024-07-21 23:59:59' or 2024-07-21 2024-07-22"
            exit 1
        fi

        end_time="$1"
        shift

        # Call a function or perform actions based on the times
        show_activity_in_time_range "$start_time" "$end_time"
        exit 0
        ;;
    *)
        echo "Error: Invalid option $1"
        show_help
        exit 1
        ;;
    esac
    shift
done

