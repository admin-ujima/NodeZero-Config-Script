#!/bin/bash

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
SID=""
HOSTNAME="Nodezero"

# Function to display script usage
usage() {
  echo -e "${BLUE}Usage: $0 [OPTIONS]"
  echo -e "Options:"
  echo -e "  -s, --sid SID_NAME  Set the SID (e.g., KTH, UJ)"
  echo -e "  -h, --help          Display this help message${NC}"
  exit 1
}

# Check for sudo privileges
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[Error] - This script needs sudo privileges. Please run with sudo.${NC}"
  exit 1
fi

# Process command line options
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -s|--sid)
      SID="$2"
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

# Check if SID is provided
if [ -z "$SID" ]; then
  echo -e "${RED}[Error] - SID is mandatory. Use the -s option to specify the SID.${NC}"
  usage
fi

# Set the hostname
MODIFIED_HOSTNAME="${HOSTNAME}-${SID}"

echo -e "${GREEN}[INFO] -  Generated new Hostname: ${MODIFIED_HOSTNAME}${NC}"

hostnamectl set-hostname "$MODIFIED_HOSTNAME"

# Update /etc/hosts
sed -i "s/127.0.1.1.*/127.0.1.1 $MODIFIED_HOSTNAME/g" /etc/hosts
echo -e "${CYAN}[INFO] -  Updated /etc/hosts for new hostname${NC}"

# Reboot to apply changes
echo -e "${YELLOW}[REBOOT] -  Finished Hostname Modification. Rebooting in 3 Seconds...${NC}"
sleep 3
reboot
