# filebotology
A bash script to autosearch for subtitles on a Synology NAS

## Requirements
  * Filebot
  * Java ARM

## Installation
  1. Instal Java for ARM architecture from here. Note that we will require Java 8; as of this writing, ver. 8 is not supported directly from Synology _Package center_ (it's stuck at ver. 7). Therefore, download and install manually from [Oracle official page] (http://www.oracle.com/technetwork/java/javase/downloads/jdk8-arm-downloads-2187472.html).
  2. Go to the _Package Center_, and install _Filebot_ from community package list.
  3. Also from the community packages, select and install _Git_ to ease the download of the script itself.
  4. Open an SSH session and checkout the script in your NAS:
   * `$ cd /volume1/git/`
   * `$ git clone https://github.com/bateman/filebotology.git`
  5. Go to the _Control Panel > Task Schedule_ and create one or two tasks for TV Shows and/or Movies, accordingly:
   * $ `/volume1/storage/script/filebotology.sh -t tv -p /volume1/video/tvshows/ >> /var/log/filebotology.log`
   * $ `/volume1/storage/script/filebotology.sh -t movies -p /volume1/video/movies/ >> /var/log/filebotology.log`
  6. Install the logrotate config for rotating the log file for the script:
   * `$ cd /etc/logrotate.d`
   * `$ ln -s /volume1/git/filebotology/fbt-logrotate filebotology`
