# Episodes number checker version 2.0.0

This is a free GNU/Bash tool allowing to check all episodes of a specified directory, and show missing numbers.
Some options allow to show found numbers in addition (can be verbose), and to work on all sub-directories of a specified directory.

This script uses my [scripts-common](https://github.com/bertrand-benoit/scripts-common) project, you can find on GitHub.

## First time you clone this repository
After the first time you clone this repository, you need to initialize git submodule:
```bash
git submodule init
git submodule update
```

This way, [scripts-common](https://github.com/bertrand-benoit/scripts-common) project will be available and you can use this tool.

## Configuration files
This tools uses the configuration file feature of the [scripts-common](https://github.com/bertrand-benoit/scripts-common) project.

The global configuration file, called **default.conf**, is in the root directory of this repository.
It contains default configuration for this tool, and should NOT be edited.

You can/should create your own configuration file **~/.config/checkEpisodes.conf** and override any value you want to adapt to your needs.

### User configuration file sample
This is a example of an user configuration file
```bash
# Default options values.
options.default.showAllNumber=1
options.default.color=0

# Maximal value allowed for episode number.
limit.episodeNumber=100

# List of regular expressions of parts to remove from file name,
#  separated by | character.
# These regular expressions are used with sed, with -E option,
#  and case insensitive.
# You can check the man of sed for more information about writing such expressions.
patterns.removeMatchingParts="^[0-9][0-9]*_|[(.[][12][90][0-9][0-9][].)]|[([][0-9][0-9]*\/[0-9][0-9]*\/[12][90][0-9][0-9][])]|[([][0-9][0-9]*\/[0-9][0-9]*\/[12][90][0-9][0-9][])]|[0-9]{2,4}[-/][0-9]{2}[-/][0-9]{2}|[[_][A-F0-9]{8,}[]_-]|1920[xX*]1080|1280[xX*]720|1024[xX*]768|848[xX*]480|856[xX*]480|720[xX*]400|640[xX*]480|[xX*hH]264|1080p|720p|[.]720$|480p|H264|8-*bits*|10-*bits*|&amp;|MP[2-5]|v[1-9]|s[0-9]{1,}[Ep._x ]{1,}|[. ]{1}[0-1][0-9]?x{1}|aison[ \t]*|épisode|et|Warehouse.13|Station.19|[[_][a-z0-9. ]{8,}[]_]|amb3r"
```

## Usage
```bash
Usage: ./checkEpisodes.sh --dir|--allDir <directory> [--checkFirst] [--showAllNumber] [--nocolor] [--debug] [-h|--help]
<directory>	directory to manage (with --dir), or parent directory (with --allDir, to check all its sub-directories)
--checkFirst	check first number which must be 1, show warning message if it is NOT the case
--showAllNumber	show found number, in addition to missing ones (can be verbose)
--nocolor	disable the warning color
--debug		show found episode number
-h|--help	show this help
```

## Samples
Check missing episodes from a specified directory:
```bash
  ./checkEpisodes.sh --dir /path/to/my/episodes/directory
```

Check missing episodes from a specified directory, and warn if first found episode is not number 1:
```bash
  ./checkEpisodes.sh --dir /path/to/my/episodes/directory --checkFirst
```

Check missing and found episodes from a specified directory:
```bash
  ./checkEpisodes.sh --dir /path/to/my/episodes/directory --showAllNumber
```

Check missing and found episodes from all sub-directories of a specified directory:
```bash
  ./checkEpisodes.sh --allDir /path/to/my/episodes/rootdirectory --showAllNumber
```

Check missing episodes from a specified directory, and warn if first found episode is not number 1, with no color (for instance, it can be interesting if launched on a NAS):
```bash
  ./checkEpisodes.sh --dir /path/to/my/episodes/directory --checkFirst --nocolor
```

## Contributing
Don't hesitate to [contribute](https://opensource.guide/how-to-contribute/) or to contact me if you want to improve the project.
You can [report issues or request features](https://github.com/bertrand-benoit/episodesChecker/issues) and propose [pull requests](https://github.com/bertrand-benoit/episodesChecker/pulls).

## Versioning
The versioning scheme we use is [SemVer](http://semver.org/).

## Authors
[Bertrand BENOIT](mailto:contact@bertrand-benoit.net)

## License
This project is under the GPLv3 License - see the [LICENSE](LICENSE) file for details
