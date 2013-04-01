#!/bin/bash
#
# Author: Bertrand BENOIT <bertrand.benoit@bsquare.no-ip.org>
# Version: 1.3
# Description: check if all episodes are consecutive into a specified directory.
#
# Usage: see usage function.

#####################################################
#                General configuration.
#####################################################
path=$( which "$0" )
currentDirectory=$( dirname "$path" )
source "$currentDirectory/commonFunctions"
episodeNumberFile="/tmp/checkEpisodeNumber.tmp"

#####################################################
#                Command line management.
#####################################################
# usage : usage
function usage() {
  echo "Usage: $0 [-h|--help] --dir|--allDir <directory> [--pattern <pattern>] [--debug] [--nocolor] [--warning]"
  echo -e "-h|--help\tshow this help"
  echo -e "<directory>\tdirectory to manage (with --dir), or parent directory (with --allDir, to check ALL sub-directories !)"
  echo -e "<pattern>\tepisode files pattern (default is 'avi')"
  echo -e "--debug\t\tshow found line and links and does nothing more"
  echo -e "--nocolor\tdisable the warning color"
  echo -e "--warning\tshow warning message (more legible), and disable the warning color"
  echo -e "--checkFirst\tcheck first number which must be 1, show warning message if it is NOT the case"
  exit 1
}

debug=0
color=1
warningMessage=0
checkFirstNumber=0
allDir=0
pattern="avi"
while [ "$1" != "" ]; do
  if [ "$1" == "--debug" ]; then
    debug=1
  elif [ "$1" == "--nocolor" ]; then
    color=0
  elif [ "$1" == "--warning" ]; then
    warningMessage=1
    color=0
  elif [ "$1" == "--checkFirst" ]; then
    checkFirstNumber=1
    color=0
  elif [ "$1" == "--dir" ]; then
    shift
    directory="$1"
  elif [ "$1" == "--allDir" ]; then
    shift
    directory="$1"
    allDir=1
  elif [ "$1" == "--pattern" ]; then
    shift
    pattern="$1"
  elif [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage;
  else
    echo "Unknown parameter '$1'"
    usage;
  fi

  shift
done

# Ensures needed variables are defined.
[ -z "$directory" ] && echo "Must defined the directory to manage." && usage
[ ! -d "$directory" ] && echo "Directory '$directory' not found. Exiting" && usage

#####################################################
#                Functions.
#####################################################
# usage : showEpisode <episode number> <position> <warning>
# # <position>: 1 for first, 2 for next, 0 otherwise.
# <warning>: 1 if this is a warning (shown in red), 0 otherwise.
function showEpisode() {
  # Prefixs if needed.
  if [ $2 -ne 1 ]; then
    echo -ne " . "
  fi

  # Enhances text if needed.
  if [ $3 -eq 1 ]; then
    if [ $color -eq 1 ]; then
      echo -ne "\033[31m\033[4m"
    else
      [ $warningMessage -eq 1 ] && echo -ne "WARNING "
      echo -ne "*"
    fi
  fi

  # Shows episode number.
  echo -ne "$1"

  # Enhances text if needed.
  if [ $3 -eq 1 ]; then
    if [ $color -eq 1 ]; then
      echo -ne "\033[0m"
    else
      echo -ne "*"
    fi
  fi

  # Enhances text if needed.
  if [ $2 -eq 2 ]; then
    echo -ne "\n"
  fi
}

# usage: checkDirectory <directory>
function checkDirectory() {
  local _directory="$1"

  currentNumber=-1

  # Extracts episode number of files an outputs them in a temporary file.
  rm -f "$episodeNumberFile"
  for filePathRaw in $( find "$_directory" -maxdepth 1 -type f |grep -v "directory.lock" |grep -e "\/[^/]*[0-9][^/]*$" |sed -e 's/[ ]/€/g;' ); do
    filePath=$( echo "$filePathRaw" |sed -e 's/€/ /g;' )
    fileName=$( basename "$filePath" )
    episodeNumber=$( extractEpisodeNumber "$fileName" )
    # TODO: add filename in file, and extracts it after that, to improve debug info
    isCompoundedNumber "$episodeNumber" && echo "$episodeNumber" >> "$episodeNumberFile" && continue
    echo "WARNING: Unable to extract (single or compounded) episode number from '$fileName' (result: $episodeNumber)"
  done

  # Ensures there is result.
  [ ! -f "$episodeNumberFile" ] && echo "none" && return 0

  # Ensures the first number is 1 (or a compounded number beginning with 1).
  if [ $checkFirstNumber -eq 1 ]; then
    firstNumber=$( cat $episodeNumberFile |sort -n |head -n 1 |sed -e "s/^\([^-]*\)-.*$/\1/;" )
    [ $( echo "$firstNumber" |grep -ce "^[0]*1" ) -lt 1 ] && echo "WARNING: first number is NOT 1 ($firstNumber)"
  fi

  # Works on episode number of the temporary file.
  moreThanOneEpisode=0
  for episodeNumberRaw in $( cat $episodeNumberFile |sort -n ); do
    # Prints information if in debug mode.
    if [ $debug = 1 ]; then
      echo -e "episodeNumber '$episodeNumberRaw'"
    fi

    # Manages potential '-' into episode number(s), taking the last one.
    lastEpisodeNumber=$( echo $episodeNumberRaw |grep "-" |sed -e "s/.*-\([0-9]*\)/\1/;" )
    if [ ! -z $lastEpisodeNumber ]; then
      episodeNumber=$lastEpisodeNumber
    else
      episodeNumber=$episodeNumberRaw
    fi

    # safe-guard.
    [ $episodeNumber -gt 650 ] && echo "WARNING: Ignoring too big episode number $episodeNumber ..." && continue

    # Updates the current episode number.
    if [ $currentNumber -eq -1 ]; then
        currentNumber=$episodeNumber
        showEpisode $episodeNumberRaw 1 0

      continue
    elif [ $currentNumber -ge $episodeNumber ]; then
      # Continues if the current episode number has already been managed (if there is several
      #  files having the same number for instance).
      continue
    fi

    # Defines there is more than one found episode.
    moreThanOneEpisode=1

    # Checks if there was a '-'.
    if [ ! -z $lastEpisodeNumber ]; then
      showEpisode $episodeNumberRaw 0 0
      currentNumber=$lastEpisodeNumber
      continue
    fi

    # Performs check.
    awaitedNumber=$( expr $currentNumber + 1 )
    currentNumber=$awaitedNumber
    if [ $awaitedNumber -lt $episodeNumber ]; then
      # Shows each missing episode number.
      while [ $currentNumber -lt $episodeNumber ]; do
        showEpisode $currentNumber 0 1
        currentNumber=$( expr $currentNumber + 1 )
      done
    fi
  done

  # Shows the last episode number if any, "none" otherwise.
  if [ $currentNumber -eq -1 ]; then
    echo "none."
  else
    if [ $moreThanOneEpisode -eq 1 ] && [ -z "$lastEpisodeNumber" ]; then
      # Shows the last episode (if not the only one, which has already been shown).
      showEpisode $currentNumber 2 0
    else
      # Moves to next line.
      echo ""
    fi
  fi
}

#####################################################
#                Instructions.
#####################################################
# Checks if all directories must be checked.
if [ $allDir -eq 0 ]; then
  checkDirectory "$directory"
else
  # Works on any found sub-directories.
  for subDirRaw in $( find "$directory" -maxdepth 1 -type d |grep -v "^$directory\$" |sed -e 's/[ \t]/€/g;' |sort ); do
    subDir=$( echo "$subDirRaw" |sed -e 's/€/ /g;' )
    subDirName=$( echo "$subDir" |sed -e 's/\/mnt\/[^\/]*\///' )
    echo -ne "Checking $subDirName: "
    checkDirectory "$subDir"
  done
fi
