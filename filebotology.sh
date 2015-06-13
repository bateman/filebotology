#!/bin/sh

##
# Author: 	bateman
# Date: 	Jan. 28, 2015
# Rev:		Jun. 13, 2015
# Ver:		1.2
## 

#Set Script Name variable
SCRIPT="filebotology.sh"

# set default vars
# video location
MEDIAPATH=""
# video type, either 'tv' or 'movie'
MEDIATYPE=""
# two-letter code for subs language, see http://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
LANG2="en"
# three-letter code for same language, LANG2 and LANG3 must always match when -r argument is passed
LANG3=""
# subs format is fixed to srt
FORMAT="srt"
# log location is fixed; if edited, fbt-logrotate config file must be edited accordingly
LOG="/var/log/filebotology.log"
# verbose switch, default off
VERBOSE="off"

# loads color env vars for stdout colors
source ./colors.inc.sh

# print help instructions
print_help() {
		printf "\nHelp documentation for ${CYAN}$SCRIPT ${NC}\n\n"
		printf "The following command line options are recognized, -t and -p are mandatory.\n"
		printf "\t ${YELLOW}-t ${PURPLE}type ${NC}\t -- Mandatory, sets the type of media to scan. Allowed values are 'tv' or 'movie'.\n"
		printf "\t ${YELLOW}-p ${PURPLE}path ${NC}\t -- Mandatory, sets the path where to look for media.\n"
		printf "\t ${YELLOW}-l ${PURPLE}lang ${NC}\t -- Sets the two-letter code for subs language (default arg is 'en').\n"
		printf "\t ${YELLOW}-r ${PURPLE}lang ${NC}\t -- Renames subs replacing 3-letter code with 2-letter one (e.g, from 'eng' to 'en'). Must match -l arg.\n"
		printf "\t ${YELLOW}-v ${NC}\t\t -- Enables verbose output on the console, disabled by default.\n"
		printf "\t ${YELLOW}-h ${NC}\t\t -- Displays this help message. No further functions are performed.\n\n"
		printf "Example: ${CYAN}$SCRIPT -t tv -p /volume1/video/tvshows ${NC}\n\n"
		exit 1
}

# redefine an echo function depending on verbose switch 
print() {
	level=$1
        code=$GREEN # default is "NOTICE"
        if [ "${level}" = 'ERROR' ]; then
		code=$RED
	elif [ "${level}" = 'INFO' ]; then
		code=$CYAN
	fi
	
	if [ "${VERBOSE}" == 'on' ]; then
		printf "${code}[${level}]: ${NC}" | tee -a $LOG
		echo $2 | tee -a $LOG
	else
		printf "${code}[${level}]: ${NC}"
		echo $2 
	fi
}

# get new or missing subs
get_missing_subs() {
	if [ "${MEDIATYPE}" == 'tv' ]; then
		DB=""
	elif [ "${MEDIATYPE}" == 'movie' ]; then
		DB="--db TheMovieDB"
	fi
	
	print "--- Start finding missing subtitles in $LANG2 from $MEDIAPATH at $(date +"%Y-%m-%d %H-%M-%S"). ---"
	filebot -script fn:suball -get-missing-subtitles $DB --lang $LANG2 --format $FORMAT $MEDIAPATH $VERB_CMD | tee -a $LOG
	print "--- Done with missing subs at $(date +"%Y-%m-%d %H-%M-%S"). ---"
}

# rename to chosen format
rename_subs_in_path() {
	if [ "${LANG3}" != "" ]; then
		print "---- Start renaming subtitles from $LANG3 to $LANG2 in $MEDIAPATH at $(date +"%Y-%m-%d %H-%M-%S"). ---"
		filebot -r -script fn:replace --def "e=.$LANG3.srt" "r=.$LANG2.srt" $MEDIAPATH $VERB_CMD | tee -a $LOG
		print "---- Done with renaming subs at $(date +"%Y-%m-%d %H-%M-%S"). ---" 
	fi
}

# parse args
while getopts "t:p:l:r:vh" FLAG; do
	case $FLAG in
		t ) MEDIATYPE=$OPTARG
			if [ "${MEDIATYPE}" != "tv" ] && [ "${MEDIATYPE}" != "movie" ]; then 
				print "ERROR" "-t option either is missing or has wrong argument." #>&2
				print_help
			fi;;
		p ) MEDIAPATH=$OPTARG
			if [ "${MEDIAPATH}" == "" ]; then
				print "ERROR" "-p option argument is missing." #>&2
				print_help
			fi;;
		l ) LANG2=$(echo "$OPTARG" | tr '[A-Z]' '[a-z]');; # to lower case
		r ) LANG3=$(echo "$OPTARG" | tr '[A-Z]' '[a-z]');; # to lower case
		v ) VERBOSE='on'
			print "INFO" "Entering verbose mode, messages will appear in both console and log file.";;
		h ) print_help;;
		\?) #unrecognized option - show help
			printf "INFO" "Use $SCRIPT -h to see the help documentation." #>&2
			exit 2;;
		: ) print "ERROR" "Missing option argument for -$OPTARG" #>&2
			exit 2;;
		* ) printf "ERROR" "Unimplemented option: -$OPTARG" #>&2
			exit 2;;
		esac
done
shift $((OPTIND-1))  #This tells getopts to move on to the next argument.
### end getopts code ###

### main instruction set to process files ###
if [ $VERBOSE = "on" ]; then
	exec 2>&1 # redirects stderr to to stdout
else
	exec 2>&1 1>>$LOG # redirects stderr to stdout, both to LOG file
fi
get_missing_subs $MEDIATYPE $MEDIAPATH
rename_subs_in_path $MEDIATYPE $MEDIAPATH
### end main ###

exit 0
