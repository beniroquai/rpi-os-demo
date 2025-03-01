#!/bin/bash -eu

# Determine the base path for sub-scripts

build_scripts_root=$(dirname "$(realpath "$BASH_SOURCE")")

# Set up pretty error printing

red_fg=31
blue_fg=34
bold=1

subscript_fmt="\e[${bold};${blue_fg}m"
error_fmt="\e[${bold};${red_fg}m"
reset_fmt='\e[0m'

function report_starting {
  echo
  echo -e "${subscript_fmt}Starting: ${1}...${reset_fmt}"
}
function report_finished {
  echo -e "${subscript_fmt}Finished: ${1}!${reset_fmt}"
}
function panic {
  echo -e "${error_fmt}Error: couldn't ${1}${reset_fmt}"
  exit 1
}

# Run sub-scripts

sudo apt-get update -y -o Dpkg::Progress-Fancy=0 -o DPkg::Lock::Timeout=60

description="install base tools"
report_starting "$description"
if "$build_scripts_root"/tools/install.sh; then
  report_finished "$description"
else
  panic "$description"
fi

description="configure system locales"
report_starting "$description"
# /run/os-setup/setup.sh: line 43: /run/os-setup/localization/config.sh: Permission denied
# make sure to run chmod +x /run/os-setup/localization/config.sh
if "$build_scripts_root"/localization/config.sh; then
  source "$build_scripts_root"/localization/export-env.sh
  report_finished "$description"
else
  panic "$description"
fi

description="configure networking"
report_starting "$description"
if "$build_scripts_root"/networking/install.sh; then
  report_finished "$description"
else
  panic "$description"
fi

description="install ImSwitch"
report_starting "$description"
if "$build_scripts_root"/imswitch/install.sh; then
  report_finished "$description"
else
  panic "$description"
fi

# Note: we must install Docker before we perform Forklift container image loading (which requires
# either Docker or containerd, which is installed by Docker).
description="install Docker"
report_starting "$description"
if "$build_scripts_root"/docker/install.sh; then
  report_finished "$description"
else
  panic "$description"
fi

description="set up Forklift"
report_starting "$description"
if "$build_scripts_root"/forklift/install.sh; then
  report_finished "$description"
else
  panic "$description"
fi

description="install Cockpit"
report_starting "$description"
if "$build_scripts_root"/cockpit/install.sh; then
  report_finished "$description"
else
  panic "$description"
fi
