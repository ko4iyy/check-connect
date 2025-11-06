# check-connect V2.0
Installation and configuration scripts for asterisk connection monitoring and logging

This has been tested and works with ASL2 and ASL3

KO4IYY
steve@ko4iyy.com

Make sure install is executable with chmod. (i.e. sudo chmod 755 ./install)

Just run "sudo ./install"

This program will install and configure a service for Asterisk to monitor your remote connection.  If it drops, it will try and reconnect to the configured node, and will write results to a log file.  

This file was made for and tested on a Raspberry PI4 running Archlinux and a Raspberry PI5 running ASL3, but may work on other linux platforms running Allstar to connect to other nodes; with some minor tweaks.


Run install as root or as sudo. (sudo ./install)

Run down the menu items in order

1 - Enter the numerical value for you Allstar node

2 - Enter the numerical value of the Allstar node you are connecting to

3 - Enter a 0 or 1 for log details:

	0 will write to the log every time the check is done.
	
	1 will only write to the log when it detects a disconnect and tries to reconnect.
	
4 - Enter a numerical value in minutes you want the check to run.

5 - Once all information is configured in 1-4 above, this will automate the installation and cron schedule for the check.

6 - Exit


Note that one more manual change is needed to /etc/asterisk/rpt.conf:

	For ASL2, use:
            Find line    ;startup_macro = *7      around line 435 or so in the startup_macro section.
            Add line below for the node you want to connect when asterisk starts or when server reboots:
            startup_macro = *73XXXXX 
            Where XXXXX is the node you are connecting to.
             
            For ASL3, use:
            Find line    ;;; Your node settings here ;;;  
            Add line below for the node you want to connect when asterisk starts or when server reboots:
            startup_macro = *813XXXXX 
            Where XXXXX is the node you are connecting to.
             
             
            Reboot when finished.

Files created/modified:
	/etc/cron.d/0hourly
	/var/log/check_config.log
	/var/spool/check_config.sh


You can modify /var/spool/check_config.sh post installation to tweak or change your desired site settings.

If you change your site in rpt.conf (813XXXXX) startup_macro, you will need to modify /var/spool/check_config.sh to match.  
check_config.sh will override the startup_macro in rpt.conf when it is called.