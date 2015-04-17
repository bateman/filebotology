#!/bin/sh

##
# TODO: 
#	customize languages for renaming
#       add comments
#
# Author: 	bateman
# Date: 	Jan. 28, 2015
# Rev:		Apr. 17, 2015
# Ver:		0.5
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
# subs format is fixed to srt
FORMAT="srt"
# log location is fixed; if edited, fbt-logrotate config file must be edited accordingly
LOG="/var/log/filebotology.log"
# verbose switch, default off
VERBOSE="off"


# print help instructions
print_help() {
        printf "Help documentation $SCRIPT\n\n"
        printf "Basic usage:\n"
        printf "Command line switches are mandatory. The following switches are recognized.\n"
        printf "\t -t type \t --Sets the type of media to scan. Allowed values are 'tv' or 'movie'.\n"
        printf "\t -p path \t --Sets the path where to look for media. No default value is set.\n"
	printf "\t -l lang \t --Sets the two-letter code for subs language (default is EN).\n\n"
	printf "\t -v \t\t --Enables verbose output on the console, disabled by default.\n\n"
        printf "\t -h \t\t --Displays this help message. No further functions are performed.\n\n"
        printf "Example: $SCRIPT -t tv -p /volume1/video/tvshows\n"
        exit 1
}

# redefine an echo function depending on verbose switch 
print() {
	if [ "${VERBOSE}" == 'on' ]; then
		$STR_OUT="$1 | tee /dev/fd/3"
	else
		$STR_OUT=$1 
	fi
	echo $STR_OUT
}

# get new or missing subs
get_missing_subs() {
	if [ "${MEDIATYPE}" == 'tv' ]; then
		DB=""
	elif [ "${MEDIATYPE}" == 'movie' ]; then
	        DB="--db TheMovieDB"
	fi
	print "Finding missing subtitles from $MEDIAPATH\n"
	filebot -script fn:suball -get-missing-subtitles $DB --lang $LANG --format $FORMAT $MEDIAPATH
        print "\n--- Done with missing subs at $(date +"%Y-%m-%d %H-%M-%S") ---\n"
}

# rename to chosen format
rename_subs_in_path() {
	print "Renaming new subtitles in $MEDIAPATH\n"
	filebot -r -script fn:replace --def "e=.ita.srt" "r=.$LANG.srt" $MEDIAPATH
	printf "\n---- Done with renaming subs at $(date +"%Y-%m-%d %H-%M-%S") ---\n" 
}

#Check the number of arguments. If none are passed, print help and exit.
NUMARGS=$#
if [ $NUMARGS -lt 2 ]; then
	printf "Wrong number of arguments, provided $NUMARGS, resquested 2.\n"
	printf "Please, note that -p and -l arguments are mandatory. \n\n"
	print_help;
fi

# parse args
while getopts "t:p:l:vh" FLAG; do
	case $FLAG in
		t) MEDIATYPE=$OPTARG;;
		p) MEDIAPATH=$OPTARG;;
		l) LANG=$OPTARG;;
		v) VERBOSE='on';;
		h) print_help;;
		\?) #unrecognized option - show help
	            printf "Use $SCRIPT -h to see the help documentation.\n"
		    exit 2;;
        esac
done
shift $((OPTIND-1))  #This tells getopts to move on to the next argument.
### end getopts code ###

### main instruction set to process files ###
exec 3>&1 1>>${LOG} 2>&1 # redirects stdout and stderr to the log file
get_missing_subs $MEDIATYPE $MEDIAPATH
rename_subs_in_path $MEDIATYPE $MEDIAPATH
### end main ###

exit 0
