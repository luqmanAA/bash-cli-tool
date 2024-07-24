# devopsfetch

`devopsfetch` is a Bash-based CLI tool designed for system administrators to retrieve and manage various system information. It provides functionalities such as listing active ports, Docker containers, and Nginx configurations, as well as user details and log activities within a specified time range.

## Version

- **Version:** 1.0.0

## Requirements ##
Bash
netstat for port information
docker for Docker-related commands
nginx for Nginx configuratio
lastlog for user login information
journalctl for log activities

## Installation ##
Using this tool requires that some dependcies are installed to ensure that the tool works well. Run the `devopsfetch-setup.sh` script to get started.

```bash
sudo chmod +x devopsfetch-setup
sudo devopsfetch-setup
```

This installs all the required dependencies.

## Usage

The script provides several command-line options. The general syntax is:

```devopsfetch [-h] [-v] [-p PORT] [-d [CONTAINER]] [-n [DOMAIN]] [-u [USERNAME]] [-t START_TIME END_TIME]```


### Options

- **-h, --help**
  - **Description:** Display help information and exit.

- **-v**
  - **Description:** Display version information and exit.

- **-p [PORT]**
  - **Description:** List all active ports and services. If a port number is provided, detailed information about that specific port will be shown.
  - **Examples:**
    - `-p` or `--port`: Lists all active ports and services.
    - `-p 80`: Provides details of port 80.

- **-d [CONTAINER]**
  - **Description:** List all Docker images and containers. If a container ID or name is provided, detailed information about that specific container will be shown.
  - **Examples:**
    - `-d` or `--docker`: Lists all Docker images and containers.
    - `-d container_name`: Provides details of the specified Docker container.

- **-n [DOMAIN]**
  - **Description:** List all Nginx domains and their associated ports. If a domain name is provided, detailed configuration information for that specific domain will be shown.
  - **Examples:**
    - `-n` or `--nginx`: Lists all Nginx domains and ports.
    - `-n example.com`: Provides detailed configuration information for `example.com`.

- **-u [USERNAME]**
  - **Description:** List all users and their last login times. If a username is provided, detailed information about that specific user will be shown.
  - **Examples:**
    - `-u` or `--users`: Lists all users and their last login times.
    - `-u username`: Provides detailed information about the specified user.

- **-t START_TIME END_TIME**
  - **Description:** Display system activities within the specified time range. Both `START_TIME` and `END_TIME` should be provided. The format is `YYYY-MM-DD HH:MM:SS`.
  - **Examples:**
    - `-t | --time '2024-07-21 00:00:00' '2024-07-21 23:59:59'`: Displays activities between the specified start and end times.

## Examples

1. **List all active ports:**
   ```bash
   devopsfetch -p or devopsfetch --port
   ```

2. **Show details of port 22:**
   ```bash
   devopsfetch -p 22 or devopsfetch ---port 22
   ```

3. **List all active ports:**
   ```bash
   devopsfetch -p
   ```

4. **List all Docker images and containers:**
   ```bash
   devopsfetch -d or devopsfetch --docker
   ```

5. **Show details of a specific Docker container:**
   ```bash
   devopsfetch -d container_id
   ```

6. **List all Nginx domains and ports:**
   ```bash
   devopsfetch -n or devopsfetch --nginx
   ```

7. **Show configuration for example.com:**
   ```bash
   devopsfetch -n example.com
   ```

8. **List all users and their last logins:**
   ```bash
   devopsfetch -u or devopsfetch ---user
   ```

9. **Show detailed information for user alice:**
   ```bash
   devopsfetch -u alice
   ```

10. **Display activities between specific times:**
   ```bash
   devopsfetch -t '2024-07-21 00:00:00' '2024-07-21 23:59:59'
   ```


Enjoy!