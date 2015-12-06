#!/bin/sh

##
# Author: 	bateman
# Date: 	Jan. 28, 2015
# Rev:		Dec. 06, 2015
# Ver:		1.3.1 beta
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
# opensubtitles.org username and password, may be hardcoded or supplied as opt arguments
USERNAME=""
PASSWORD=""
# email address to send error notification to
EMAIL=""

# loads color env vars for stdout colors
source ./colorsformat.inc.sh


# print help instructions
print_help() {
		printf "\nHelp documentation for ${BOLD}$SCRIPT ${NC}\n\n"
		printf "The following command line options are recognized:\n"
		printf "\t ${BOLD}-t type ${NC}\t -- ${UNDER}Mandatory${NC}, sets the type of media to scan. Allowed values are 'tv' or 'movie'.\n"
		printf "\t ${BOLD}-p path ${NC}\t -- ${UNDER}Mandatory${NC}, sets the path where to look for media.\n"
		printf "\t ${BOLD}-u username ${NC}\t -- ${UNDER}Mandatory${NC}, sets the OpenSubtitles.org username for authenticating.\n"
		printf "\t ${BOLD}-s secret ${NC}\t -- ${UNDER}Mandatory${NC}, sets the OpenSubtitles.org secret (password) for authenticating.\n"
		printf "\t ${BOLD}-l lang ${NC}\t -- Sets the two-letter code for subs language (default arg is 'en').\n"
		printf "\t ${BOLD}-r lang ${NC}\t -- Renames subs replacing 3-letter code with 2-letter one (e.g, from 'eng' to 'en'). Must match -l arg.\n"
		printf "\t ${BOLD}-v ${NC}\t\t -- Enables verbose output on the console, disabled by default.\n"
		printf "\t ${BOLD}-e ${NC}\t\t -- Sets the recipient address for enabling the notification of errors by email.\n"
		printf "\t ${BOLD}-h ${NC}\t\t -- Displays this help message. No further functions are performed.\n\n"
		printf "Example: ${BOLD}$SCRIPT -u bateman -s secret -t tv -p /volume1/video/tvshows ${NC}\n\n"
		exit 1
}

# redefine an echo function depending on verbose switch 
print() {
	local level=$1
        local code=$GREEN # default is "NOTICE"
        if [ "${level}" = 'ERROR' ]; then
		code=$RED
	elif [ "${level}" = 'INFO' ]; then
		code=$CYAN
	fi
	
	if [ "${VERBOSE}" == 'on' ]; then
		printf "${code}[${level}]${NC}: " | tee -a $LOG
		echo $2 | tee -a $LOG
	else
		printf "${code}[${level}]${NC}: "
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
	
	print "NOTICE" "Start finding missing subtitles in $LANG2 from $MEDIAPATH at $(date +"%Y-%m-%d %H-%M-%S")."
	filebot -script fn:suball -get-missing-subtitles $DB --lang $LANG2 --format $FORMAT $MEDIAPATH $VERB_CMD | tee -a $LOG
	if [ "$?" == 0 ]; then
		print "NOTICE" "Done with finding missing subs at $(date +"%Y-%m-%d %H-%M-%S")."
	else
	        print "ERROR" "Something went wrong, filebot error code $?"
	fi
}

# rename to chosen format
rename_subs_in_path() {
	if [ "${LANG3}" != "" ]; then
		print "NOTICE" "Start renaming subtitles from $LANG3 to $LANG2 in $MEDIAPATH at $(date +"%Y-%m-%d %H-%M-%S")."
		filebot -r -script fn:replace --def "e=.$LANG3.srt" "r=.$LANG2.srt" $MEDIAPATH $VERB_CMD | tee -a $LOG
		if [ "$?" == 0 ]; then
			print "NOTICE" "Done with renaming subs at $(date +"%Y-%m-%d %H-%M-%S")."
		else
			print "ERROR" "Something went wrong, filebot error code $?"
		fi 
	fi
}

# checks that at least mandatory opt args have been provided correctly
check_args_consistency() {
	if [ "${MEDIATYPE}" == "" ]; then
		print "ERROR" "-t option argument is missing."
		print_help
	elif [ "${MEDIAPATH}" == "" ]; then
		print "ERROR" "-p option argument is missing."
		print_help
	fi
}

# checks that opensubtitles credentials have been provided and are working
check_osdb_credentials() {
	if [ "${USERNAME}" == "" ] || [ "${PASSWORD}" == "" ]; then
		print "ERROR" "OpenSubtitle.org credentials have not been provided. Please register here: http://www.opensubtitles.org/en/newuser"
		exit 2
	fi
	# now check credentials are working
	print "NOTICE" "Logging in OpenSubtitles.org..."
	echo -e "${USERNAME}\n""${PASSWORD}\n" | filebot -script fn:configure > /dev/null
	if [ "$?" == 0 ]; then
		print "NOTICE" "Authentication OK!"
	elif [ "$?" == 1 ]; then
		print "ERROR" "401 Unauthorized: Please check your credentials, error code $?"
		if [ "${EMAIL}" != "" ]; then
			print "INFO" "Sending error notification by email"
			send_email "401 Unauthorized: Please check your credentials, error code $?"
		fi
		exit 2
	elif [ "$?" > 1 ]; then
		print "ERROR" "Something went wrong, filebot error code $?"
 		if [ "${EMAIL}" != "" ]; then
 			print "INFO" "Sending error notification by email"
			send_email "Something went wrong, filebot error code $?"
		fi
		exit 2
	fi        
}

# send email via ssmtp
send_email() {
    local emailfile="/tmp/fb-email.txt"
    local body=$1
    echo "To: $EMAIL" > $emailfile
    echo "From: filebotology@noreply" >> $emailfile
    echo "Subject: filebotology error notification" >> $emailfile
    echo -e "\n$body" >> $emailfile
    ssmtp $EMAIL < $emailfile
}

# check for at least one option to be present
if [ -z "$1" ]; then
	print_help
fi

# parse args
while getopts "t:p:u:s:l:r:e:vh" FLAG; do
	case $FLAG in
		t ) MEDIATYPE=$OPTARG
			if [ "${MEDIATYPE}" != 'tv' ] && [ "${MEDIATYPE}" != 'movie' ]; then 
				print "ERROR" "-t option has wrong argument." #>&2
				print_help
			fi;;
		p ) MEDIAPATH=$OPTARG
			if [ ! -d "${MEDIAPATH}" ]; then
				print "ERROR" "Directory ${MEDIAPATH} does not exist."
				exit 2
			fi;;
		u ) USERNAME=$OPTARG;;
		s ) PASSWORD=$OPTARG;;
		e ) EMAIL=$OPTARG;; 
		l ) LANG2=$(echo "$OPTARG" | tr '[A-Z]' '[a-z]');; # to lower case
		r ) LANG3=$(echo "$OPTARG" | tr '[A-Z]' '[a-z]');; # to lower case
		v ) VERBOSE='on'
			print "INFO" "Entering verbose mode, messages will appear in both console and log file.";;
		h ) print_help;;
		\?) #unrecognized option - show help
			printf "INFO" "Use $SCRIPT -h to see the help documentation." 
			exit 2;;
		: ) print "ERROR" "Missing option argument for -$OPTARG"
			exit 2;;
		* ) printf "ERROR" "Unimplemented option: -$OPTARG" 
			exit 2;;
		esac
done
shift $((OPTIND-1))  #This tells getopts to move on to the next argument.
### end getopts code ###

### main instruction set to process files ###
if [ $VERBOSE = "on" ]; then
	exec 2>&1 # redirects stderr to stdout
else
	exec 2>&1 1>>$LOG # redirects stderr to stdout, both to LOG file
fi

check_args_consistency
check_osdb_credentials
get_missing_subs
rename_subs_in_path
### end main ###

exit 0
