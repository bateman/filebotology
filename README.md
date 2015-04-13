# filebotology
An ash script (yes, Synolgy boxes run ash shell not bash) to autosearch for subtitles on a Synology NAS. This script relies on [Filebot cli] (http://www.filebot.net/cli.html) capabilities to automate the search of subtitles for your videos stored in your beloved Synology NAS.

## Requirements
  * Filebot
  * Java SE Embedded 8 

## Installation
  1. Instal Java 8 SE Embedded for ARM architecture. Note that, as of this writing, ver. 8 is not supported directly from Synology _Package center_ (it's stuck at ver. 7). Therefore, you need to add the following custom package repository [http://packages.pcloadletter.co.uk] (http://packages.pcloadletter.co.uk) to the package center. After that, Java 8 should show up with other extra packages in the Community list. (*Make sure to pick the one that's right for your CPU model!* See [here] (http://forum.synology.com/wiki/index.php/What_kind_of_CPU_does_my_NAS_have) if you don't know)
  2. Go to the _Package Center_, and install _Filebot_ from community package list.
  3. Also from the community packages, select and install _Git_ to ease the download of the script itself.
  4. Open an SSH session and checkout the script in your NAS:
   * `$ cd /volume1/git/`
   * `$ git clone https://github.com/bateman/filebotology.git`
  5. Go to the _Control Panel > Task Scheduler_ (i.e., the DSM cron equivalent) and create one or two tasks for TV Shows and/or Movies, accordingly:
   * `$ /volume1/git/filebotology.sh -t tv -p /volume1/video/tvshows/ >> /var/log/filebotology.log`
   * `$ /volume1/git/filebotology.sh -t movies -p /volume1/video/movies/ >> /var/log/filebotology.log`
   * Choose how often they run; make sure to not run them at the same minute, so their execution won't overlap;
  6. Install the logrotate config for rotating the script log (_change the logrotate options as you wish_):
   * `$ cd /etc/logrotate.d`
   * `$ ln -s /volume1/git/filebotology/fbt-logrotate filebotology`
   * to check the status do a `$ cat /var/lib/logrotate.status | grep filebot`, it will return something like this: `"/var/log/filebotology.log" 2015-3-21-12:0:0`

## Language
At the moment the script is set to download Italian subtitles in srt format from OpenSubitles.org and TheMovieDB, using hash-based matching. Until I add a command line switch to select desired language(s), you will have to edit the script by hand. Look for the instruction `LANG=it` at line 23 and change it to your country's two letters code.

## CLI execution
To run it from the command line,  excute the script with the -h flag to print the following help menu.
```
-t tv|movie      sets the type of media to scan. Allowed values are 'tv' or 'movie'.
-p path          sets the path where to look for media. No default value is set.
-h               displays this help message. No further functions are performed.
```

Example: `$ filebotology.sh -t tv -p /volume1/video/tvshows`
