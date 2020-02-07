#!/bin/bash
#
# Author: Bertrand BENOIT <bertrand.benoit@bsquare.no-ip.org>
# Version: 2.0
# Description: checks all episodes of a directory, and shows consecutive sequences.
#              An option allows to request the same on all sub-directories of a directory.
#
# Usage: see usage function.

#####################################################
#                General configuration.
#####################################################
export CATEGORY="checkEpisodes"

currentDir=$( dirname "$( command -v "$0" )" )
export GLOBAL_CONFIG_FILE="$currentDir/default.conf"
export CONFIG_FILE="${HOME:-/home/$( whoami )}/.config/checkEpisodes.conf"

[ -s "$SCRIPTS_COMMON_PATH" ] && . "$SCRIPTS_COMMON_PATH"

checkAndSetConfig "file.episodeNumber" "$CONFIG_TYPE_OPTION"
episodeNumberFile="$LAST_READ_CONFIG"

checkAndSetConfig "limit.episodeNumber" "$CONFIG_TYPE_OPTION"
GREATER_EPISODE_NUMBER="$LAST_READ_CONFIG"

checkAndSetConfig "patterns.removeMatchingParts" "$CONFIG_TYPE_OPTION"
REMOVE_FILENAME_MATCHING_PARTS="$LAST_READ_CONFIG"

checkAndSetConfig "options.default.checkFirstNumber" "$CONFIG_TYPE_OPTION"
checkFirstNumber="$LAST_READ_CONFIG"

checkAndSetConfig "options.default.showAllNumber" "$CONFIG_TYPE_OPTION"
showAllNumber="$LAST_READ_CONFIG"

checkAndSetConfig "options.default.color" "$CONFIG_TYPE_OPTION"
color="$LAST_READ_CONFIG"

#####################################################
#                Command line management.
#####################################################
# usage : usage
function usage() {
  echo "Usage: $0 --dir|--allDir <directory> [--checkFirst] [--showAllNumber] [--nocolor] [--debug] [-h|--help]"
  echo -e "<directory>\tdirectory to manage (with --dir), or parent directory (with --allDir, to check all its sub-directories)"
  echo -e "--checkFirst\tcheck first number which must be 1, show warning message if it is NOT the case"
  echo -e "--showAllNumber\tshow found number, in addition to missing ones (can be verbose)"
  echo -e "--nocolor\tdisable the warning color"
  echo -e "--debug\t\tshow found episode number"
  echo -e "-h|--help\tshow this help"
}

debug=0
allDir=0
while [ "${1:-}" != "" ]; do
  if [ "$1" == "--debug" ]; then
    debug=1
  elif [ "$1" == "--nocolor" ]; then
    color=0
  elif [ "$1" == "--checkFirst" ]; then
    checkFirstNumber=1
  elif [ "$1" == "--showAllNumber" ]; then
    showAllNumber=1
  elif [ "$1" == "--dir" ]; then
    shift
    directory="$1"
  elif [ "$1" == "--allDir" ]; then
    shift
    directory="$1"
    allDir=1
  elif [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage && exit 0
  else
    usage
    errorMessage "Unknown parameter '$1'"
  fi

  shift
done

# Ensures needed variables are defined.
[ -z "${directory:-}" ] && usage && errorMessage "You must specify the directory to manage."
[ ! -d "$directory" ] && usage && errorMessage "The specified directory '$directory' does not exist."

#####################################################
#                Functions.
#####################################################
# Usage: extractEpisodeNumber <fileName>
#  <fileName>: string corresponding to a [file]Name/Label to manage
# Returns the episode number.
function extractEpisodeNumber() {
  # Important: starts to remove the extension of the file which can contain number, but
  #  considering it should starts by a letter.
  local _name="${1%.[a-zA-Z]*}" _result=""

  _result=$( removeAllSpecifiedPartsFromString "$_name" "$REMOVE_FILENAME_MATCHING_PARTS" "1" \
            |sed -e 's/^.*[Ss]\([0-9][0-9]*\)[ ]*[Ee]\([0-9][0-9-]*\)[^0-9]*$/\1/g;' )

  _result=$( extractNumberSequence "$_result" |sed -e 's/^0*//g;')

  [ "$debug" -eq 1 ] && printf "Extracted number sequence from name '%b' => '%b'" "$_name" "$_result" >&2

  # Returns the formatted [file]Name/Label.
  echo "$_result"
}

# usage : showEpisode <episode number> <position> <warning>
# <position>: 1 for first, 2 for next, 0 otherwise.
# <warning>: 1 if this is a warning (shown in red), 0 otherwise.
function showEpisode() {
  local _episodeNumber="$1" _position="$2" _warning="${3:-}"

  # Prefixs if needed.
  [ "$_position" -ne 1 ] && echo -ne " . "

  # Enhances text if needed.
  if [ "$_warning" -eq 1 ]; then
    [ $color -eq 1 ] && echo -ne "\033[31m\033[4m" || echo -ne "*"
  fi

  # Shows episode number.
  echo -ne "$_episodeNumber"

  # Enhances text if needed.
  if [ "$_warning" -eq 1 ]; then
    [ $color -eq 1 ] && echo -ne "\033[0m" || echo -ne "*"
  fi

  # Enhances text if needed.
  [ "$_position" -eq 2 ] && echo -ne "\n"

  return 0
}

# usage: checkDirectory <directory>
function checkDirectory() {
  local _directory="$1"

  currentNumber=-1

  # Extracts episode number of files an outputs them in a temporary file.
  rm -f "$episodeNumberFile"
  while IFS= read -r filePath; do
    fileName=$( basename "$filePath" )
    episodeNumber=$( extractEpisodeNumber "$fileName" )
    isCompoundedNumber "$episodeNumber" && echo "$episodeNumber" >> "$episodeNumberFile" && continue
    echo "" && warning "Unable to extract (single or compounded) episode number from '$fileName' (result: $episodeNumber)"
  done < <(find "$_directory" -maxdepth 1 -type f |grep -v "directory.lock" |grep -e "\/[^/]*[0-9][^/]*$")

  # Ensures there is result.
  [ ! -f "$episodeNumberFile" ] && warning "No episode found." && return 0

  # Ensures the first number is 1 (or a compounded number beginning with 1).
  if [ $checkFirstNumber -eq 1 ]; then
    firstNumber=$( sort -n "$episodeNumberFile" |head -n 1 |sed -e "s/^\([^-]*\)-.*$/\1/;" )
    [ "$( grep -ce "^[0]*1"<<<"$firstNumber" )" -lt 1 ] && warning "first number is NOT 1 ($firstNumber)"
  fi

  # Works on episode number of the temporary file.
  moreThanOneEpisode=0
  while IFS= read -r episodeNumberRaw; do
    # Prints information if in debug mode.
    [ "$debug" -eq 1 ] && echo -ne " [found episode number '$episodeNumberRaw'] "

    # Manages potential '-' into episode number(s), taking the last one.
    if [ "$( grep -ce "-" <<< "$episodeNumberRaw")" -eq 0 ]; then
      # It is a simple number.
      lastEpisodeNumber=""
      episodeNumber="$episodeNumberRaw"
    else
      # It is a compounded number.
      firstEpisodeNumber=$( sed -e "s/^\([0-9]*\)-.*$/\1/;" <<< "$episodeNumberRaw" )
      lastEpisodeNumber=$( sed -e "s/^.*-\([0-9]*\)$/\1/;" <<< "$episodeNumberRaw" )
      # In any case, register the first episode number, the last one
      #  will be manage at end of this loop.
      episodeNumber="$firstEpisodeNumber"
    fi

    # safe-guard.
    [ "$episodeNumber" -gt "$GREATER_EPISODE_NUMBER" ] && echo "" && warning "Ignoring too big episode number $episodeNumber ..." && continue

    # Updates the current episode number.
    if [ "$currentNumber" -eq -1 ]; then
      currentNumber="${lastEpisodeNumber:-$episodeNumber}"
      showEpisode "$episodeNumberRaw" 1 0
      continue
    elif [ "$currentNumber" -ge "$episodeNumber" ]; then
      # Continues if the current episode number has already been managed (if there is several
      #  files having the same number for instance).
      continue
    fi

    # Defines there is more than one found episode.
    moreThanOneEpisode=1

    # Performs check.
    awaitedNumber=$((currentNumber + 1))
    currentNumber=$awaitedNumber
    if [ "$awaitedNumber" -lt "$episodeNumber" ]; then
      # Shows each missing episode number.
      while [ "$currentNumber" -lt "$episodeNumber" ]; do
        showEpisode "$currentNumber" 0 1
        currentNumber=$((currentNumber + 1))
      done
    fi

    [ "$showAllNumber" -eq 1 ] && showEpisode "$episodeNumberRaw" 0 0

    # Updates to last episode number, in case of compounded number.
    if [ -n "$lastEpisodeNumber" ]; then
      currentNumber="$lastEpisodeNumber"
    fi
  done < <(sort -n "$episodeNumberFile")

  # Shows the last episode number if any, "none" otherwise.
  if [ "$currentNumber" -eq -1 ]; then
    warning "No episode found."
  else
    if [ "$moreThanOneEpisode" -eq 1 ] && [ -z "$lastEpisodeNumber" ]; then
      # Shows the last episode (if not the only one, which has already been shown).
      [ "$showAllNumber" -eq 0 ] && showEpisode "$currentNumber" 2 0 || echo ""
    else
      # Moves to next line.
      echo ""
    fi
  fi

  return 0
}

#####################################################
#                Instructions.
#####################################################
# Checks if all directories must be checked.
if [ $allDir -eq 0 ]; then
  checkDirectory "$directory"
else
  # Works on any found sub-directories.
  while IFS= read -r subDir; do
    subDirName=$( echo "$subDir" |sed -e 's/\/mnt\/[^\/]*\///' )
    writeMessageSL "Checking $subDirName: "
    checkDirectory "$subDir"
  done < <(find "$directory" -maxdepth 1 -type d |grep -v "^$directory\$" |sort)
fi
