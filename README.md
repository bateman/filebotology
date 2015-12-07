# filebotology
An ash script (yes, Synology boxes run ash shell through Busybox, not bash) to autosearch for subtitles on a NAS. 
This script relies on [Filebot cli] (http://www.filebot.net/cli.html) capabilities to automate the search of subtitles for your videos stored in your beloved Synology NAS.

## Requirements
  * Filebot
  * MediaInfo
  * Chromaprint
  * Java SE Embedded 8 

Please, note that, as of Filebot ver. 4.6, MediaInfo and Chromaprint must be installed as separate Synology community packages. Also, note that Chromaprint is currently in beta, so you have to enable the display of beta version in your package center.

## Installation
  1. First things first, go to Package Center ► Settings ► Trust Level: Anyone.
  2. Install _Java 8 SE Embedded_ for ARM architecture. Note that, as of this writing, ver. 8 is not supported as an official package from Synology through the _Package center_ -- the Java Manager is infact stuck at ver. 7. Therefore, you need to add a custom Package Source: go to Package Center ► Settings ► Package Sources ► Add ► Name: SynologyItalia and Location:  [http://spk.synologyitalia.com/] (http://spk.synologyitalia.com/) ► OK. After that, Java 8 should show up with other extra packages in the Community list. (*Make sure to pick the one that's right for your CPU model!* See [here] (http://forum.synology.com/wiki/index.php/What_kind_of_CPU_does_my_NAS_have) if you don't know already.)
  2. Add Package Source also for _Filebot_; go to Package Center ► Settings ► Package Sources ► Add ► Name: FileBot and Location: [https://packages.filebot.net/syno/] (https://packages.filebot.net/syno/) ► OK. Now find and install it from Community packages list.
  3. Also from the community packages, select and install _Git_ to ease the download of the script itself.
  4. Got to [www.opensubtitles.org] (www.opensubtitles.org), sign up and write down your credentials: they should either be hardcoded in the script, or passed as argument to the command line options, see next section (CLI execution) for more.
  5. Still via SSH, checkout the script in your NAS:
   * `$ cd /volume1/git/`
   * `$ git clone https://github.com/bateman/filebotology.git`
   * Then, make sure the script are executable on your system:
   * `$ chmod +x *.sh`
  6. Go to the Control Panel ► Task Scheduler (i.e., the DSM cron equivalent) and create one or two tasks for TV Shows and/or Movies, accordingly:
   * `$ /volume1/git/filebotology/filebotology.sh -u username -s secret -t tv -p /volume1/video/tvshows/`
   * `$ /volume1/git/filebotology/filebotology.sh -u username -s secret -t movies -p /volume1/video/movies/`
   * Make them run once per day (no more often than that, or you risk to be banned); make sure to not run them at the same hour:minute, so their execution won't overlap; use root as task owner.
  7. Install the logrotate config for rotating the script log (_change the logrotate options as you wish_):
   * `$ cd /etc/logrotate.d`
   * `$ ln -s /volume1/git/filebotology/fbt-logrotate filebotology`
   * to check the status do a `$ cat /var/lib/logrotate.status | grep filebot`, it will return something like this: `"/var/log/filebotology.log" 2015-3-21-12:0:0`
  8. If you want to enable error notification via email, you should properly configure ssmtp on your NAS. To do so, edit these file as follows:
   * Edit file `/etc/ssmtp/ssmtp.conf` and paste the following snippet, changing text as needed:
   ```
   root=YOUR_GMAIL_USERNAME@gmail.com
   mailhub=smtp.gmail.com:587
   hostname=YOUR_NAS_BOX_NAME
   UseTLS=YES
   UseSTARTTLS=YES
   AuthUser=YOUR_GMAIL_USERNAME (without @gmail.com)
   AuthPass=YOUR_APP-SPECIFIC_PASSWORD (you can generate one here: https://security.google.com/settings/security/apppasswords)
   FromLineOverride=YES
   ```
   * Now edit this other file `/etc/ssmtp/revaliases` (usually empty), adding this line:
   `root:YOUR_GMAIL_USERNAME@gmail.com:smtp.gmail.com:587`
   * Test that everything is working, executing from comman line: 
   `echo "ssmtp test" | ssmtp YOUR_GMAIL_USERNAME@gmail.com`

## CLI execution
To run it from the command line, excute the script with the `-h` flag to print the following help menu. Please, note that the first two options `-t` and `-p` are **mandatory**.
```
-t type     Mandatory, sets the type of media to scan. Allowed values are 'tv' and 'movie'.
-p path     Mandatory, sets the path where to look for media. No default value is set.
-u username Mandatory, sets the OpenSubtitles.org username for authenticating
-s secret   Mandatory, sets the OpenSubtitles.org secret (password) for authenticating
-l lang     Sets the two-letter code for subs language (ISO 639-1, see http://goo.gl/KXQ0x7). Default is 'en'.
-r lang     Renames subs from the three-letter code (ISO 639-2) to the two-letter one. Must match -l arg.
-e email    Sets the recipient address for enabling the notification of errors by email
-v          Enables verbose output on the console, disabled by default.
-h          Displays this help message. No further functions are performed.
```

Example: `$ filebotology.sh -v -u username -s secret -l it -r ita -t tv -p /volume1/video/tvshows`

Now, sit back and relax, it's gonna take a long while if you have a large base of videos!

## Notes
* As of ver. 1.3, entering [OpenSubitles.org] (www.opensubtitles.org) credentials has been implemented as mandatory since authenticated users have a much higher per-day limit for downloading subtitles (currently 200). This is useful, especially on first runs, where a whole lot of subs might be found. You might consider a donation of 10$/€ to become a [VIP member] (http://www.opensubtitles.org/en/support#vip) and further increase this limit. To check your daily quota, execute: `filebot -script fn:osdb.stats`
* If you don't want to supply as command line arguments your email address and your [OpenSubitles.org] (www.opensubtitles.org) credentials, you can manually edit the script, entering hard-coded values at the beginning of the file `filebotology.sh` where vars `USERNAME`, `PASSWORD` and `EMAIL` are declared as empty.
* The script currently assumes to be located at `/volume1/storage/script/`. This is because, in order to properly work when launched from the DS Task Scheduler, the script must cd to the installation folder. If you want to run it from elsewhere, make sure to edit the `$INSTALL_PATH` var in the script accordingly.
* At the moment the script is set to download subtitles only in `srt` format from [OpenSubitles.org] (www.opensubtitles.org), using hash-based matching. 
* If you are some kind of a *nix shell hacker and find some quirks in the script, keep in mind that the ash shell implementation of Busybox is somewhat limited, so not all functions normally found in a full-fledged shell are available here.
* Colors and fonts can be customized editing file `colorsformat.inc.sh`. See here for more options: http://misc.flogisoft.com/bash/tip_colors_and_formatting. Please, note that `dim` and `blink` options are not supported by Synology ash shell.
