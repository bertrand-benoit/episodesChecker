#!/bin/bash
#
# Author: Bertrand BENOIT <bertrand.benoit@bsquare.no-ip.org>
# Version: 1.2
# Description: check if all episodes are consecutive into a specified directory.
#
# Usage: see usage function.

#####################################################
#                Defines functions.
#####################################################
# usage : usage
function usage() {
  echo "Usage: $0 [-h|--help] --dir <directory> [--pattern <pattern>] [--debug] [--nocolor]"
  echo -e "-h|--help\tshow this help"
  echo -e "<directory>\tdirectory to manage"
  echo -e "<pattern>\tepisode files pattern (default is 'avi')"
  echo -e "--debug\tshow found line and links and does nothing more"
  echo -e "--nocolor\tdisable the warning color"
  exit 0
}

# usage : showEpisode <episode number> <position> <warning>
# <position>: 1 for first, 2 for last, 0 otherwise.
# <warning>: 1 if this is a warning (shown in red), 0 otherwise.
function showEpisode() {
  # Prefixs if needed.
  if [ $2 -ne 1 ]; then
    echo -ne " . "
  fi

  # Enhances text if needed.
  if [ $3 -eq 1 ]; then
    if [ $color -eq 1 ]; then
      echo -ne "\033[31m\033[4m"
    else
      echo -ne "*"
    fi
  fi

  # Shows episode number.
  echo -ne "$1"

  # Enhances text if needed.
  if [ $3 -eq 1 ]; then
    if [ $color -eq 1 ]; then
      echo -ne "\033[0m"
    else
      echo -ne "*"
    fi
  fi

  # Enhances text if needed.
  if [ $2 -eq 2 ]; then
    echo -ne "\n"
  fi
}

#####################################################
#                Command line management.
#####################################################
debug=0
color=1
pattern="avi"
while [ "$1" != "" ]; do
  if [ "$1" == "--debug" ]; then
    debug=1
  elif [ "$1" == "--nocolor" ]; then
    color=0
  elif [ "$1" == "--dir" ]; then
    shift
    directory="$1"
  elif [ "$1" == "--pattern" ]; then
    shift
    pattern="$1"
  elif [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage;
  else
    echo "Unknown parameter '$1'"
    usage;
  fi

  shift
done

# Ensures needed variables are defined.
if [ -z "$directory" ]; then
  echo "Must defined the directory to manage."
  usage;
  exit 1
fi

#####################################################
#                Defines variables.
#####################################################
currentNumber=-1


#####################################################
#                Performs checks.
#####################################################
# For each corresponding file.
# Algorithm:
#  - ls + grep -> gets files corresponding to pattern, one per line
#  - first sed -> attempts extracting episode number (do not allow a dot before the episode number)
#  - seconc grep -> removes each line which has something else than a number
#  - sort numerically
moreThanOneEpisode=0
for episodeNumberRaw in $( find "$directory" -type f |grep -v "directory.lock" |grep -re "[0-9]" |sed -e 's/H264//g;s/.*[^0-9.[-]\([0-9][0-9]*[-]*[0-9][0-9]*\)[^]a-fA-F0-9].*/\1/g;' |grep -v "[^0-9-]" |sort -n ); do

  # Prints information if in debug mode.
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
  [ $episodeNumber -gt 600 ] && echo "Ignoring too big episode number $episodeNumber ..." && continue

  # Updates the current episode number.
  if [ $currentNumber -eq -1 ]; then
      currentNumber=$episodeNumber
      showEpisode $currentNumber 1 0

    continue
  elif [ $currentNumber -ge $episodeNumber ]; then
    # Continues if the current episode number has already been managed (if there is several
    #  files having the same number for instance).
    continue
  fi

  # Defines there is more than one found episode.
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
    # Shows the last episode (if not the only one, which has already been shown).
    showEpisode $currentNumber 2 0
  else
    # Moves to next line.
    echo ""
  fi
fi
