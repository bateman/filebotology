#!/bin/sh

##
# Author: 	bateman
# Date: 	Jan. 28, 2015
# Rev:		Apr. 19, 2015
# Ver:		1.0
## 

#Set Script Name variable
SCRIPT="filebotology.sh"

# set default vars
# video location
MEDIAPATH=""
# video type, either 'tv' or 'movie'
MEDIATYPE=""
# two-letter code for subs language, see http://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
LANG="en"
# three-letter code for same language, LANG and LANG3 must always match when -r argument is passed
LANG3=""
# subs format is fixed to srt
FORMAT="srt"
# log location is fixed; if edited, fbt-logrotate config file must be edited accordingly
LOG="/var/log/filebotology.log"
# verbose switch, default off
VERBOSE="off"


# print help instructions
print_help() {
		printf "Help documentation $SCRIPT\n\n"
		printf "The following command line options are recognized, -t and -p are mandatory.\n"
		printf "\t -t type \t -- Mandatory, sets the type of media to scan. Allowed values are 'tv' or 'movie'.\n"
		printf "\t -p path \t -- Mandatory, sets the path where to look for media.\n"
		printf "\t -l lang \t -- Sets the two-letter code for subs language (default arg is 'en').\n"
		printf "\t -r lang \t -- Renames subs replacing 3-letter code with 2-letter one (e.g, from 'eng' to 'en'). Must match -l arg.\n"
		printf "\t -v \t\t -- Enables verbose output on the console, disabled by default.\n"
		printf "\t -h \t\t -- Displays this help message. No further functions are performed.\n\n"
		printf "Example: $SCRIPT -t tv -p /volume1/video/tvshows\n"
		exit 1
}

# redefine an echo function depending on verbose switch 
print() {
	if [ "${VERBOSE}" == 'on' ]; then
		echo $1 | tee /dev/fd/3
	else
		echo $1 
	fi
}

# get new or missing subs
get_missing_subs() {
	if [ "${MEDIATYPE}" == 'tv' ]; then
		DB=""
	elif [ "${MEDIATYPE}" == 'movie' ]; then
		DB="--db TheMovieDB"
	fi
	print "--- Start finding missing subtitles in $LANG from $MEDIAPATH at $(date +"%Y-%m-%d %H-%M-%S"). ---"
	filebot -script fn:suball -get-missing-subtitles $DB --lang $LANG --format $FORMAT $MEDIAPATH  # FIXME #8 output not appearing in console w/ -v
	print "--- Done with missing subs at $(date +"%Y-%m-%d %H-%M-%S"). ---"
}

# rename to chosen format
rename_subs_in_path() {
	if [ "${LANG3}" != "" ]; then
		print "---- Start renaming subtitles from $LANG3 to $LANG in $MEDIAPATH at $(date +"%Y-%m-%d %H-%M-%S"). ---"
		filebot -r -script fn:replace --def "e=.$LANG3.srt" "r=.$LANG.srt" $MEDIAPATH # FIXME #8 output not appearing in console w/ -v
		print "---- Done with renaming subs at $(date +"%Y-%m-%d %H-%M-%S"). ---" 
	fi
}

#Check the number of arguments. At least -t and -p must be passed (2), with their arguments (2)
#Otherwise, print help and exit
NUMARGS=$#
if [ $NUMARGS -lt 4 ]; then
	printf "\nERROR: Wrong number of arguments, provided $((NUMARGS / 2)), requested at least 2.\n\n" >&2
	print_help
fi

# parse args
while getopts "t:p:l:r:vh" FLAG; do
	case $FLAG in
		t ) MEDIATYPE=$OPTARG
			if [ "${MEDIATYPE}" != "tv" ] && [ "${MEDIATYPE}" != "movie" ]; then 
				echo "\nERROR: -t option either is missing or has wrong argument.\n\n" >&2
				print_help
			fi;;
		p ) MEDIAPATH=$OPTARG
			if [ "${MEDIAPATH}" == "" ]; then
				echo "\nERROR: -p option argument is missing.\n\n" >&2
				print_help
			fi;;
		l ) LANG=$(echo "$OPTARG" | tr '[A-Z]' '[a-z]');; # to lower case
		r ) LANG3=$(echo "$OPTARG" | tr '[A-Z]' '[a-z]');; # to lower case
		v ) VERBOSE='on'
			printf "Entering verbose mode, messages will appear in both console and log file.\n";;
		h ) print_help;;
		\?) #unrecognized option - show help
			printf "Use $SCRIPT -h to see the help documentation.\n" >&2
			exit 2;;
		: ) printf "Missing option argument for -$OPTARG" >&2
			exit 2;;
		* ) printf "Unimplemented option: -$OPTARG" >&2
			exit 2;;
		esac
done
shift $((OPTIND-1))  #This tells getopts to move on to the next argument.
### end getopts code ###

### main instruction set to process files ###
exec 3>&1 1>>${LOG} 2>&1 # redirects stdout and stderr to the log file, binds fd 3 to stdout
get_missing_subs $MEDIATYPE $MEDIAPATH
rename_subs_in_path $MEDIATYPE $MEDIAPATH
### end main ###

exit 0
