#!/bin/bash

# Validate not sudo
user_id=`id -u`
if [ $user_id -eq 0 -a -z "$RUNNER_ALLOW_RUNASROOT" ]; then
    echo "Must not run interactively with sudo"
    exit 1
fi

# Run
shopt -s nocasematch

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# Wait for docker to start
if [ ! -z "$RUNNER_WAIT_FOR_DOCKER_IN_SECONDS" ]; then
    if [ "$RUNNER_WAIT_FOR_DOCKER_IN_SECONDS" -gt 0 ]; then
        echo "Waiting for docker to be ready."
        for i in $(seq "$RUNNER_WAIT_FOR_DOCKER_IN_SECONDS"); do
            if docker ps > /dev/null 2>&1; then
                echo "Docker is ready."
                break
            fi
            "$DIR"/safe_sleep.sh 1
        done
    fi
fi

updateFile="update.finished"
"$DIR"/bin/Runner.Listener run $*
returnCode=$?
if [[ $returnCode == 0 ]]; then
    echo "Runner listener exit with 0 return code, stop the service, no retry needed."
    exit 0
elif [[ "$ACTIONS_RUNNER_RETURN_VERSION_DEPRECATED_EXIT_CODE" == "1" && $returnCode -eq 7 ]]; then
    echo "Runner listener exit with deprecated version exit code: ${returnCode}."
    exit "$returnCode"
elif [[ $returnCode == 1 ]]; then
    echo "Runner listener exit with terminated error, stop the service, no retry needed."
    exit 0
elif [[ $returnCode == 2 ]]; then
    echo "Runner listener exit with retryable error, re-launch runner in 5 seconds."
    "$DIR"/safe_sleep.sh 5
    exit 2
elif [[ $returnCode == 3 ]]; then
    # Wait for 30 seconds or for flag file to exists for the runner update process finish
    echo "Runner listener exit because of updating, re-launch runner after successful update"
    for i in {0..30}; do
        if test -f "$updateFile"; then
            echo "Update finished successfully."
            rm "$updateFile"
            break
        fi
        "$DIR"/safe_sleep.sh 1
    done
    exit 2
elif [[ $returnCode == 4 ]]; then
    # Wait for 30 seconds or for flag file to exists for the ephemeral runner update process finish
    echo "Runner listener exit because of updating, re-launch runner after successful update"
    for i in {0..30}; do
        if test -f "$updateFile"; then
            echo "Update finished successfully."
            rm "$updateFile"
            break
        fi
        "$DIR"/safe_sleep.sh 1
    done
    exit 2
elif [[ $returnCode == 5 ]]; then
    echo "Runner listener exit with Session Conflict error, stop the service, no retry needed."
    exit 0
else
    echo "Exiting with unknown error code: ${returnCode}"
    exit 0
fi
# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Echo all arguments to stderr.
#
function echo_err() {
  echo "-*- $*" 1>&2
}
if [[ -z "${LIBDOT_DIR}" ]]; then
  echo_err "LIBDOT_DIR: required variable not set"
  exit 1
fi
READLINK="${LIBDOT_DIR}/bin/readlink"
READLINK="$("${READLINK}" -f -- "${READLINK}")"
LIBDOT_DIR="$("${READLINK}" -f -- "${LIBDOT_DIR}")"
LIBDOT_BIN_DIR="${LIBDOT_DIR}/bin"
LIBAPPS_DIR="$("${READLINK}" -f -- "${LIBDOT_DIR}/..")"
BIN_DIR="$(dirname "$("${READLINK}" -f -- "$0")")"
: "${LIBDOT_SEARCH_PATH:=${LIBAPPS_DIR}}"
PATH="${LIBDOT_BIN_DIR}:${PATH}"
# Find a file in the LIBDOT_SEARCH_PATH.
function search_file() {
  local filename="$1"
  local IFS=":"
  for dir in $LIBDOT_SEARCH_PATH; do
    local dir=$(eval "echo $dir")
    if [ -e "$dir/$filename" ]; then
      echo "$dir/$filename"
      return
    fi
  done
  echo_err "$filename not found in $LIBDOT_SEARCH_PATH"
}
# See <https://github.com/kward/shflags>.
source "$(search_file "libdot/bin/shflags")"
# Run a command, exiting if it returns a non-zero exit code.
#
# If you intend to capture the output of a command this should be used
# immediately AFTER running running the command.
function insist() {
  local err=$?
  if [ ! -z "$1" ]; then
    "$@"
    err=$?
  fi
  if [ $err != 0 ]; then
    if [ -z "$1" ]; then
      echo_err "Command returned exit code: $err"
    else
      echo_err "Command $* returned exit code: $err"
    fi
    exit $err
  fi
}
# Compute a relative path for a given absolute path.
#
#   get_relative_path <source_dir> [<pwd>]
#
# If <pwd> is not provided, the return value will be relative to the present
# working directory.
#
function get_relative_path() {
  local source_dir="$(readlink -fm "$1")"
  local pwd="$(readlink -fm "$2")"
  if [ -z "$pwd" ]; then
    pwd="$(readlink -f "$(pwd)")/"
  fi
  # First, find the common prefix
  local common_dirs="$source_dir"
  # Keep removing directories from the end of the candidate until it is a
  # prefix of the pwd.
  while [[ "$common_dirs" != "/" && \
    "$(starts_with "$pwd" "$common_dirs")" == "no" ]]; do
    common_dirs="$(readlink -fm $common_dirs/..)"
  done
  if [ "$common_dirs" == "/" ]; then
    # If the only shared directory is "/", then just return the source
    # directory.
    echo "$source_dir"
    return
  fi
  # Return value starts with everything after the common directories.
  local rv="${source_dir:$((${#common_dirs} + 1))}"
  # Then prepend a "../" for every directory that we have to backtrack from
  # pwd to get to the common directory.
  local uncommon_dirs="${pwd:${#common_dirs}}"
  uncommon_dirs="${uncommon_dirs##/}"
  uncommon_dirs="${uncommon_dirs%%/}"
  if [ ! -z "$uncommon_dirs" ]; then
    while [[ "$uncommon_dirs" != "." && "$uncommon_dirs" != "/" ]]; do
      rv="../$rv"
      uncommon_dirs="$(dirname $uncommon_dirs)"
    done
  fi
  if [ -z "$rv" ]; then
    rv="$(pwd)"
  fi
  local home="$(readlink -fm "$HOME")"
  if [ "$pwd" !=  "$home" ]; then
    # Check to see if it's shorter to express the path relative to $HOME
    local fromhome="~/$(get_relative_path "$source_dir" "$home")"
    if [ ${#fromhome} -le ${#rv} ]; then
      echo "$fromhome"
      return
    fi
  fi
  echo "$rv"
}
# Read a value from a manifest.json file.
#
#   get_key_value <key> <manifest_file>
#
# This only works on manifest files that have one key per line.
#
function get_manifest_key_value() {
  local key="$1"
  local file="$2"
  local line="$(grep "\"$key\":" "$file")"
  echo "$(expr "$line" : '.*\":[[:space:]]*\"\([^\"]*\)')"
}
function echo_changelog() {
  local key="$1"
  local file="${2:-../doc/ChangeLog.md}"
  if [ -z "$key" ]; then
    head -n1 "$file"
  elif [ "$key" = "version" ]; then
    head -n1 "$file" | cut -f1 -d',' | sed -e 's/[ #]//g'
  elif [ "$key" = "date" ]; then
    head -n1 "$file" | cut -f2 -d',' | sed -e 's/ //g'
  else
    echo_err "Unknown key: $key"
    return 1
  fi
}

