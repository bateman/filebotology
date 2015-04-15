# filebotology
An ash script (yes, Synolgy boxes run ash shell not bash) to autosearch for subtitles on a Synology NAS. This script relies on [Filebot cli] (http://www.filebot.net/cli.html) capabilities to automate the search of subtitles for your videos stored in your beloved Synology NAS.

## Requirements
  * Filebot
  * Java SE Embedded 8 

## Installation
  1. First things first, go to Package Center ► Settings ► Trust Level: Anyone.
  2. Instal Java 8 SE Embedded for ARM architecture. Note that, as of this writing, ver. 8 is not supported as an official package from Synology through the _Package center_ -- the Java Manager is infact stuck at ver. 7. Therefore, you need to add a custom Package Source: go to Package Center ► Settings ► Package Sources ► Add ► Name: SynologyItalia and Location:  [http://spk.synologyitalia.com/] (http://spk.synologyitalia.com/) ► OK. After that, Java 8 should show up with other extra packages in the Community list. (*Make sure to pick the one that's right for your CPU model!* See [here] (http://forum.synology.com/wiki/index.php/What_kind_of_CPU_does_my_NAS_have) if you don't know already.)
  2. Add Package Source also for _Filebot_; go to Package Center ► Settings ► Package Sources ► Add ► Name: FileBot and Location: [https://packages.filebot.net/syno/] (https://packages.filebot.net/syno/) ► OK. Now find and install it from Community packages list.
  3. Also from the community packages, select and install _Git_ to ease the download of the script itself.
  4. Got to [www.opensubtitles.org] (www.opensubtitles.org) and sign up; now open an SSH session, and run the following from command line:
   * `filebot -script fn:configure` and enter your credentials
   * if you forget, you'll get this error message in the log/console as a reminder: `CmdlineException: OpenSubtitles: Please enter your login details by calling "filebot -script fn:configure"`
  5. Still via SSH, checkout the script in your NAS:
   * `$ cd /volume1/git/`
   * `$ git clone https://github.com/bateman/filebotology.git`
  6. Go to the Control Panel ► Task Scheduler (i.e., the DSM cron equivalent) and create one or two tasks for TV Shows and/or Movies, accordingly:
   * `$ /volume1/git/filebotology/filebotology.sh -t tv -p /volume1/video/tvshows/ >> /var/log/filebotology.log`
   * `$ /volume1/git/filebotology/filebotology.sh -t movies -p /volume1/video/movies/ >> /var/log/filebotology.log`
   * Choose how often they run; make sure to not run them at the same minute, so their execution won't overlap; use root as task owner.
  7. Install the logrotate config for rotating the script log (_change the logrotate options as you wish_):
   * `$ cd /etc/logrotate.d`
   * `$ ln -s /volume1/git/filebotology/fbt-logrotate filebotology`
   * to check the status do a `$ cat /var/lib/logrotate.status | grep filebot`, it will return something like this: `"/var/log/filebotology.log" 2015-3-21-12:0:0`

## Language
At the moment the script is set to download subtitles in srt format only from [OpenSubitles.org] (www.opensubtitles.org), using hash-based matching. 

## CLI execution
To run it from the command line, excute the script with the `-h` flag to print the following help menu. Please, note that the first two options `-t` and `-p` are mandatory.
```
-t type      Sets the type of media to scan. Allowed values are 'tv' or 'movie'.
-p path      Sets the path where to look for media. No default value is set.
-l language  Sets the two-letter code for subs language (ISO 639-1, see http://goo.gl/KXQ0x7). Default is 'en'.
-h           Displays this help message. No further functions are performed.
```

Example: `$ filebotology.sh -l it -t tv -p /volume1/video/tvshows`

Now, sit back and relax, it's gonna take a long while if you have a large base of videos!
