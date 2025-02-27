#!/bin/bash

# Create a directory for logs if it doesn't exist
mkdir -p .logs

# Log file path
LOG_FILE=".logs/script_log_$(date +'%d.%m.%Y-%H:%M:%S').log"

# Function to strip ANSI color codes using unbuffered sed
strip_color_codes() {
    sed -ru "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g"
}

# Redirect stdout and stderr to Logfile
exec > >(stdbuf -oL tee >(strip_color_codes >> "$LOG_FILE"))
exec 2>&1


# ANSI escape codes for colors
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Default values
HOSTNAME="rtpt"

# Default XPT Token for Red Team Appliances
TOKEN="M1ID9Z47kRlbCvtgEHbY2kszJ7C0CiYkXqqgjLeNw3k"

# Function to display script usage
usage() {
echo -e "${BLUE}Usage: $0 [OPTIONS]"
echo -e "Options:"
echo -e "  -s, --sid SID_NAME  Set the SID (e.g., KTH, UJ)"
echo -e "  -d, --domain DOMAIN This is the Domain used for xplicittrust (e.g. ujima.de)"
echo -e "  -i, --index INDEX   This is the index which is part of the machine hostname"
echo -e "  -f, --file PATH     This way you can not use the interactive console and instead load a config"
echo -e "  -h, --help          Display this help message${NC}"
exit 1
}

# Function to check if xplicittrust is installed
check_xplicittrust() {
if ! command -v xtna-agent &> /dev/null; then
# Install xplicittrust
echo -e "${MAGENTA}[INFO] - xplicittrust is missing! Installing it now...${NC}"
sudo apt update
sudo apt --yes install wireguard wireguard-tools wget iptables ipset
wget https://dl.xplicittrust.com/xtna-agent_amd64.deb
sudo dpkg -i xtna-agent_amd64.deb
rm -rf xtna-agent_amd64.deb
else
echo -e "${GREEN}[DONE] - xplicittrust is already installed.${NC}"
fi
}

# Function to handle configuration from environment variables or configuration file
handle_config() {
if [ -z "$CONFIG_FILE" ]; then
echo -e "${RED}[ERROR] - The File Path is empty. This is mandatory for this mode!${NC}"
exit 1
fi

if [ -f "$CONFIG_FILE" ]; then
source "$CONFIG_FILE"
else
echo -e "${RED}[ERROR] - Config file not found: $CONFIG_FILE${NC}"
exit 1
fi
}



# setup_h3_path() {
#   # Check if the env variable H3_CLI_HOME does not exist or is empty
#   nodezero_h3_cli_home=$(sudo -iu nodezero bash -c 'echo "$H3_CLI_HOME"')
#   if [ -z "$nodezero_h3_cli_home" ]; then
#     sudo tee -a 'export H3_CLI_HOME=/home/nodezero/h3-cli' /home/nodezero/.profile
#     echo -e "${MAGENTA}[INFO] - H3_CLI_HOME was not set. It has been added!${NC}"
#   else
#     echo -e "${GREEN}[DONE] - H3_CLI_HOME is already setup!${NC}"
#   fi

#   # Check if the PATH does NOT contain /home/nodezero/h3-cli/bin
#   nodezero_path=$(sudo -iu nodezero bash -c 'echo "$PATH"')
#   if [[ ":$nodezero_path:" != *":/home/nodezero/h3-cli/bin:"* ]]; then
#     # Add /home/nodezero/h3-cli/bin to PATH
#     sudo tee -a 'export PATH="$H3_CLI_HOME/bin:$PATH"' /home/nodezero/.profile
#     echo -e "${MAGENTA}[INFO] - Added /home/nodezero/h3-cli/bin to PATH.${NC}"
#   else
#     echo -e "${GREEN}[DONE] - /home/nodezero/h3-cli/bin is already in PATH!${NC}"
#   fi
# }

# setup_h3_authentication() {
#   echo -e "${MAGENTA}[INFO] - Checking if there is H3 Authentication...${NC}"
#   chown nodezero:nodezero /tmp/.resolve_fragments_full_query.txt
#   auth_email=$(sudo -iu nodezero bash -c "h3 whoami" | jq --raw-output .email 2>/dev/null)
#   code=$?

#   if [ $code -ne 0 ] || [ "$auth_email" != "it-admin@ujima.de" ]; then
#     echo -e "${MAGENTA}[INFO] - H3 API Key was not setup! It will be added now...${NC}"

#     if [ -z "$NODEZERO_APIKEY" ]; then
#       echo -e "${RED}[ERROR] - There is no API KEY passed for Nodezero. Exiting setup procedure...${NC}"
#       exit 1
#     fi

#     /usr/bin/chmod +x /home/nodezero/h3-cli/install.sh
#     /usr/bin/chown -R nodezero:nodezero /home/nodezero/h3-cli/
#     sudo -iu nodezero bash -c "cd /home/nodezero/h3-cli;bash install.sh \"$NODEZERO_APIKEY\""
#   elif [ $code -eq 0 ] && [ -n "$NODEZERO_APIKEY" ]; then
#       echo -e "${MAGENTA}[INFO] - H3 API Key was already setup, but a Key got passed! The API Key will be updated now...${NC}"

#       # Removing default profile
#       sudo -iu nodezero bash -c "h3 delete-profile default"

#       # Adding new profile with api key
#       /usr/bin/chmod +x /home/nodezero/h3-cli/install.sh
#       /usr/bin/chown -R nodezero:nodezero /home/nodezero/h3-cli/
#       sudo -iu nodezero bash -c "cd /home/nodezero/h3-cli;bash install.sh \"$NODEZERO_APIKEY\""

#       echo -e "${GREEN}[DONE] - H3 API Key has been updated!${NC}"
#   else
#     echo -e "${GREEN}[DONE] - H3 API Key was already setup!${NC}"
#   fi
# }

setup_h3_runner() {
# Setup required env variables
#setup_h3_path

# Check if Nodezero API Key exists else handle steps
#setup_h3_authentication

echo -e "${YELLOW}[INFO] - Starting runner checkup...${NC}"

# Check if H3 runner is already set up
rm -rf /tmp/.resolve_fragments*
runner_name=$(/home/nodezero/h3-cli/bin/h3 runners | jq --raw-output .name 2>/dev/null)
code=$?

echo -e "${YELLOW}[DEBUG] - Runner Name: $runner_name, Code: $code${NC}"

if [ $code -eq 0 ] && [ "$runner_name" = "$MODIFIED_HOSTNAME" ]; then
echo -e "${RED}[DONE] - H3 runner with the name $MODIFIED_HOSTNAME is already set up. If you want a additional runner change the INDEX${NC}"
exit 1
fi

# H3 runner is not set up, set it up with API key
echo -e "${MAGENTA}[INFO] - H3 runner is not set up. Setting it up with API key...${NC}"

bash /home/nodezero/h3-cli/easy_install.sh "$NODEZERO_APIKEY" "$MODIFIED_HOSTNAME"

echo -e "${GREEN}[DONE] - H3 runner set up successfully.${NC}"
}

# Function to process command line options
process_options() {
while [[ "$#" -gt 0 ]]; do
case $1 in
    -s|--sid)
    SID="$2"
    shift 2
    ;;
    -i|--index)
    SID="$2"
    shift 2
    ;;
    -d|--domain)
    DOMAIN="$2"
    shift 2
    ;;
    -h|--help)
    usage
    ;;
    *)
    echo -e "${RED}[ERROR] - Unknown option: $1${NC}"
    usage
    ;;
esac
done
}

# Check for sudo privileges
if [ "$EUID" -ne 0 ]; then
echo -e "${RED}[ERROR] - This script needs sudo privileges. Please run with sudo.${NC}"
exit 1
fi

# Check if the non-interactive config file based approach want to be used
if [ "$1" == "-f" ] || [ "$1" == "--file" ]; then
CONFIG_FILE="$2"
# Handle configuration from file directly
handle_config
# This shifts the input arguments 2 places to the left
shift 2
else
# Enter the loop to process command line options
process_options "$@"
fi

# Check if SID is provided
if [ -z "$SID" ]; then
echo -e "${RED}[ERROR] - SID is mandatory. Use the -s option to specify the SID.${NC}"
usage
fi

# Check if xplicittrust token is provided
if [ -z "$INDEX" ]; then
echo -e "${RED}[ERROR] - INDEX is mandatory. Use the -i option to specify the Index of the Machine.${NC}"
usage
fi

# Check if xplicittrust domain is provided
if [ -z "$DOMAIN" ]; then
echo -e "${RED}[ERROR] - DOMAIN is mandatory. Use the -d option to specify the XplicitTrust Domain to register to.${NC}"
usage
fi

# Sanitize SID and HOSTNAME from any trailing linebreaks
HOSTNAME=$(echo "$HOSTNAME" | tr -d '\r\n')
INDEX=$(echo "$INDEX" | tr -d '\r\n')
SID=$(echo "$SID" | tr -d '\r\n' | tr '[:upper:]' '[:lower:]')
DOMAIN=$(echo "$DOMAIN" | tr -d '\r\n')

# Set the hostname
MODIFIED_HOSTNAME="${SID}-${HOSTNAME}-${INDEX}"

echo -e "${GREEN}[DONE] - Generated new Hostname: ${MODIFIED_HOSTNAME}${NC}"

sudo hostnamectl set-hostname "$MODIFIED_HOSTNAME"

hostname_res=$?

if [ ! $hostname_res -eq 0 ]; then
echo -e "${RED}[ERROR] - Something went wrong when setting hostname!${NC}"
exit 1
fi

# Update /etc/hosts
sudo sed -i "s/127.0.1.1.*/127.0.1.1 $MODIFIED_HOSTNAME/g" /etc/hosts
echo -e "${CYAN}[INFO] - Updated /etc/hosts for new hostname${NC}"

# Setup h3 system
setup_h3_runner

# Check if xplicittrust is already installed and otherwise install it
check_xplicittrust

# Run xtna-util with configured values
sudo xtna-util -domain "$DOMAIN" -token "$TOKEN"

# Save the exit code in a variable
xtna_exit_code=$?

if [ $xtna_exit_code -eq 0 ];then
echo -e "${CYAN}[INFO] - The xplicittrust connection has been established!${NC}"
else
echo -e "${RED}[ERROR] - Something went wrong, when trying to establish connection to XplicitTrust...Probably the Token expired!${NC}"
exit 1
fi

# Reboot to apply changes
echo -e "${YELLOW}[REBOOT] - Finished Hostname Modification. Rebooting in 10 Seconds...${NC}"
sleep 10
reboot
