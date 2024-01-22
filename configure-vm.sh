#!/bin/bash

# Create a directory for logs if it doesn't exist
mkdir -p .logs

# Log file path
LOG_FILE=".logs/script_log_$(date +'%d.%m.%Y-%H:%M:%S').log"

# Function to strip color codes
strip_color_codes() {
  sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g"
}

# Redirect stdout to the log file with color codes stripped
exec > >(strip_color_codes | tee -a "$LOG_FILE")

# Redirect stderr to the log file without affecting stdout, also with color codes stripped
exec 2> >(strip_color_codes | tee -a "$LOG_FILE" >&2)


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
HOSTNAME="Nodezero"

# Function to display script usage
usage() {
  echo -e "${BLUE}Usage: $0 [OPTIONS]"
  echo -e "Options:"
  echo -e "  -s, --sid SID_NAME  Set the SID (e.g., KTH, UJ)"
  echo -e "  -d, --domain DOMAIN This is the Domain used for xplicittrust (e.g. ujima.de)"
  echo -e "  -t, --token TOKEN   This is the token to register to the xplicittrust console"
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
    wget https://dl.xplicittrust.com/xtna-agent_amd64.deb -P ~/Downloads
    sudo dpkg -i ~/Downloads/xtna-agent_amd64.deb
  else
    echo -e "${GREEN}[INFO] - xplicittrust is already installed.${NC}"
  fi
}

# Function to handle configuration from environment variables or configuration file
handle_config() {
  if [ -n "$CONFIG_FILE" ]; then
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

# TODO! This is not finished yet
# Function to check and set up H3 runner
setup_h3_runner() {
  # Check if H3 runner is already set up
  if h3-cli runner status | grep -q "Runner is set up"; then
    echo -e "${GREEN}[INFO] - H3 runner is already set up.${NC}"
    return
  fi
  # H3 runner is not set up, set it up with API key
  echo -e "${MAGENTA}[INFO] - H3 runner is not set up. Setting it up with API key...${NC}"

  echo -e "${GREEN}[INFO] - H3 runner set up successfully.${NC}"
}

# Function to process command line options
process_options() {
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -s|--sid)
        SID="$2"
        shift 2
        ;;
      -d|--domain)
        DOMAIN="$2"
        shift 2
        ;;
      -t|--token)
        TOKEN="$2"
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

# Set the hostname
MODIFIED_HOSTNAME="${HOSTNAME}-${SID}"

echo -e "${GREEN}[INFO] - Generated new Hostname: ${MODIFIED_HOSTNAME}${NC}"

hostnamectl set-hostname "$MODIFIED_HOSTNAME"

# Update /etc/hosts
sed -i "s/127.0.1.1.*/127.0.1.1 $MODIFIED_HOSTNAME/g" /etc/hosts
echo -e "${CYAN}[INFO] - Updated /etc/hosts for new hostname${NC}"

# Check if xplicittrust is already installed and otherwise install it
check_xplicittrust

# Run xtna-util with configured values
sudo xtna-util -domain "$DOMAIN" -token "$TOKEN"

# Reboot to apply changes
echo -e "${YELLOW}[REBOOT] - Finished Hostname Modification. Rebooting in 3 Seconds...${NC}"
sleep 3
reboot
