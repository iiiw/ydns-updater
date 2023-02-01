#!/usr/bin/env bash

# YDNS updater script
# Copyright (C) 2023 iiiw <git@iiiw.dev>
# Based on the original YDNS Bash Updater Script (https://github.com/ydns/bash-updater):
# Copyright (C) 2013-2017 TFMT UG (haftungsbeschränkt) <support@ydns.io>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.	If not, see <http://www.gnu.org/licenses/>.

readonly VERSION='0.1.0'

function usage() {
	echo 'YDNS Updater'
	echo ''
	echo "Usage: $0 [options]"
	echo ''
	echo 'Available options:'
	echo '	-h      Display usage'
	echo '	-u URL  Provide update URL (may be repeated)'
	echo '	-v      Enable verbose output'
	echo '	-V      Display version'
}

if ! command -v curl >/dev/null 2>&1; then
	err 'Missing dependency cURL. Aborting.'
	exit 1
fi

function err() {
	echo -e "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

function msg() {
	[[ $VERBOSE -eq 0 ]] && return
	echo -e "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*"
}

function update_ip() {
	[[ "$1" ]] || return 6
	curl --fail --silent "$1" >/dev/null
}

function version() {
	echo "YDNS Updater version $VERSION"
}

VERBOSE=0
declare -a update_urls

while getopts ':hu:vV' opt; do
	case $opt in
		h)
			usage; exit 0
			;;
		u)
			update_urls+=("$OPTARG")
			;;
		v)
			VERBOSE=1
			;;
		V)
			version; exit 0
			;;
		:)
			err "Please supply an argument to -${OPTARG}"
			usage; exit 1
			;;
		"?")
			err "Invalid option: -${OPTARG}"
			usage; exit 1
			;;
	esac
done

if (( ${#update_urls[@]} == 0 )); then
	# Try to get URLs from config file
	update_file="${XDG_CONFIG_HOME:-$HOME/.config}/ydns/update_urls"

	if [[ -f "$update_file" ]]; then
		IFS=$'\n' read -d '' -r -a update_urls < "$update_file"
	else
		err 'Not enough arguments.'
		usage; exit 1
	fi
fi

# Retrieve current public IP address
if ! CURRENT_IP="$(curl --fail --silent https://ydns.io/api/v1/ip)" \
    || [[ -z "$CURRENT_IP" ]]; then
	err 'Unable to retrieve current public IP address.'
	exit 1
fi

msg "Current IP: $CURRENT_IP"

# Get last known IP address that was stored locally
LAST_IP=''
LAST_IP_FILE='/tmp/ydns-last-ip'

if [[ -f "$LAST_IP_FILE" ]]; then
	LAST_IP="$(head -n 1 $LAST_IP_FILE)"
fi

if [[ "$CURRENT_IP" == "$LAST_IP" ]]; then
	msg 'Not updating YDNS host: IP address unchanged.'
	exit 0
fi

# IP has changed, update local file and remote host
echo "$CURRENT_IP" > "$LAST_IP_FILE"

for url in "${update_urls[@]}"; do
	if update_ip "$url"; then
		msg "YDNS host updated successfully.
Update URL: $url
Current IP: $CURRENT_IP"
	else
		err "YDNS host update for $url failed."
		exit 1
	fi
done
