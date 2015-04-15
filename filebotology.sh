#!/bin/sh

##
# TODO: add logging on-off switch
#	customize languages
#       add comments
#
# Author: 	bateman
# Date: 	Jan. 28, 2015
# Rev:		Apr. 14, 2015
# Ver:		0.3.1
## 

#Set Script Name variable
SCRIPT="filebotology.sh"

# set default vars
MEDIAPATH=""
MEDIATYPE=""
LOG="/var/log/filebotology.log"
LANG="it"
FORMAT="srt"

# print help instructions
print_help() {
        printf "Help documentation $SCRIPT\n\n"
        printf "Basic usage:\n"
        printf "Command line switches are mandatory. The following switches are recognized.\n"
        printf "\t -t type \t --Sets the type of media to scan. Allowed values are 'tv' or 'movie'.\n"
        printf "\t -p path \t --Sets the path where to look for media. No default value is set.\n"
        printf "\t -h \t\t --Displays this help message. No further functions are performed.\n\n"
        printf "Example: $SCRIPT -t tv -p /volume1/video/tvshows\n"
        exit 1
}

# get new or missing subs
get_missing_subs() {
	if [ "${MEDIATYPE}" == 'tv' ]; then
		DB=""
	elif [ "${MEDIATYPE}" == 'movie' ]; then
	        DB="--db TheMovieDB"
	fi
	printf "Finding missing subtitles from $MEDIAPATH\n"
	filebot -script fn:suball -get-missing-subtitles $DB --lang $LANG --format $FORMAT $MEDIAPATH
	printf "Done\n"
        printf "\n------------------------\n" >> $LOG
}

# rename to chosen format
rename_subs_in_path() {
	printf "Renaming new subtitles in $MEDIAPATH\n"
	filebot -r -script fn:replace --def "e=.ita.srt" "r=.it.srt" $MEDIAPATH
	printf "Done\n"
	printf "\n------------------------\n" >> $LOG
}

#Check the number of arguments. If none are passed, print help and exit.
NUMARGS=$#
if [ $NUMARGS -lt 2 ]; then
	printf "Wrong number of arguments, provided $NUMARGS resquested 2.\n\n"
	print_help;
fi

# parse args
while getopts "t:p:h" FLAG; do
	case $FLAG in
		t) MEDIATYPE=$OPTARG;;
		p) MEDIAPATH=$OPTARG;;
		h) print_help;;
		\?) #unrecognized option - show help
	            printf "Use $SCRIPT -h to see the help documentation.\n"
		    exit 2;;
        esac
done
shift $((OPTIND-1))  #This tells getopts to move on to the next argument.
### end getopts code ###

### main instruction set to process files ###
get_missing_subs $MEDIATYPE $MEDIAPATH
rename_subs_in_path $MEDIATYPE $MEDIAPATH
### end main ###

exit 0
