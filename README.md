# check-connect
Installation and configuration scripts for asterisk connection monitoring and logging

KO4IYY
steve@ko4iyy.com

Make sure install is executable with chmod.

You can just run "sudo ./install" or "sudo bash ./install.sh"

This program will install and configure a service for Asterisk to monitor your remote connection.  If it drops, it will try and reconnect to the configured node, and will write results to a log file.  It also builds a simple html page to view the local supermon page, the remote ECR connection, and display the log file.

This file was made for and tested on a Raspberry PI4 running Archlinux, but may work on other linux platforms running Allstar to connect to other nodes; with some minor tweaks.


Run install as root or as sudo. (sudo bash install.sh)

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

	Find the line "startup_macro = *7"
	
	Add a line below it so it reads "startup_macro = *73XXXXX" [no quotes] and where XXXX is the remote node you are connecting to that you configured in step 2 of the installation program. The '3' means to create a permanent link.
