#!/usr/bin/env bash
# LinDrv 0.1.316 BETA
# Universal Linux Driver Installer
# Credits: chrizss.dev

SUPPORTED_DISTROS=(
  "ubuntu 18.04"
  "fedora 36"
  "opensuse 15.0"
  "arch 2022.08.05"
  "linux mint 20"
  "kali 2021.4"
)

function get_distro_info {
  local name="" version=""
  if [ -f /etc/os-release ]; then
    name=$(grep -E '^NAME=' /etc/os-release | sed 's/NAME=\"\?//; s/\"$//; s/\\"//g; s/\\n//g' | tr '[:upper:]' '[:lower:]')
    version=$(grep -E '^VERSION_ID=' /etc/os-release | sed 's/VERSION_ID=\"\?//; s/\"$//; s/\\"//g; s/\\n//g' | tr '[:upper:]' '[:lower:]')
  fi
  echo "$name" "$version"
}

function is_supported {
  local distro_name="$1"
  local distro_version="$2"

  for entry in "${SUPPORTED_DISTROS[@]}"; do
    local dist=$(echo "$entry" | awk '{print $1}')
    local ver=$(echo "$entry" | awk '{print $2}')
    if [[ "$distro_name" == *"$dist"* ]]; then
      # Simple lexicographical compare
      if [[ "$distro_version" >= "$ver" ]]; then
        return 0
      fi
    fi
  done

  return 1
}

function install_drivers {
  local distro_name="$1"

  if [[ "$distro_name" == *"ubuntu"* ]] || [[ "$distro_name" == *"linux mint"* ]]; then
    sudo apt update && sudo apt install -y linux-headers-$(uname -r) firmware-linux firmware-linux-nonfree
  elif [[ "$distro_name" == *"fedora"* ]]; then
    sudo dnf install -y kernel-devel kernel-headers
  elif [[ "$distro_name" == *"opensuse"* ]]; then
    sudo zypper install -y kernel-devel kernel-firmware
  elif [[ "$distro_name" == *"arch"* ]]; then
    sudo pacman -Sy linux-headers linux-firmware --noconfirm
  elif [[ "$distro_name" == *"kali"* ]]; then
    sudo apt update && sudo apt install -y linux-headers-$(uname -r) firmware-linux firmware-linux-nonfree
  else
    echo "No installation commands found for this distro."
  fi
}

function check_existing_drivers {
  declare -A checks
  checks=(
    ["GPU firmware"]="/lib/firmware/amdgpu"
    ["Wi-Fi firmware"]="/lib/firmware/ath10k"
    ["Intel firmware"]="/lib/firmware/intel"
  )

  for label in "${!checks[@]}"; do
    if [ -e "${checks[$label]}" ]; then
      echo "$label: FOUND"
    else
      echo "$label: NOT FOUND"
    fi
  done
}

function main_menu {
  while true; do
    CHOICE=$(whiptail --title "LinDrv 0.1.316 BETA" \
      --menu "Select an option:" 15 60 3 \
      "1" "Check existing drivers" \
      "2" "Install recommended drivers" \
      "3" "Quit" 3>&1 1>&2 2>&3)

    exitstatus=$?
    if [ $exitstatus -ne 0 ]; then
      break
    fi

    case $CHOICE in
      1)
        RESULT=$(check_existing_drivers)
        whiptail --title "Driver Check" --msgbox "${RESULT}" 20 60
        ;;
      2)
        install_drivers "$DISTRO_NAME"
        whiptail --title "Installation" --msgbox "Installation complete." 8 50
        ;;
      3)
        break
        ;;
      *)
        break
        ;;
    esac
  done
}

DISTRO_INFO=( $(get_distro_info) )
DISTRO_NAME="${DISTRO_INFO[0]}"
DISTRO_VERSION="${DISTRO_INFO[1]}"

if ! is_supported "$DISTRO_NAME" "$DISTRO_VERSION"; then
  whiptail --title "LinDrv 0.1.316 BETA" --msgbox "Unsupported distro or version.\n\nSupported:\nUbuntu 18.04+\nFedora 36+\nopenSUSE Leap 15.0+\nArch 2022.08.05+\nLinux Mint 20+\nKali 2021.4+" 15 60
  exit 1
fi

main_menu
