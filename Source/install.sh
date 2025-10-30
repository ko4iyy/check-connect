#!/bin/bash
        ##################################
        ####  2025 -  KO4IYY          ####
        ####         Steve Clay       ####
        ####       steve@ko4iyy.com   ####
        ####          V 1.7           ####
        ####  Installation to test    ####
        ####  if asterisk is conected ####
        ####  to your remote node.    ####
        ####  Used for East Coast     ####
        ####  Reflector connection    ####
        ####  via Raspberry Pi        ####
        ##################################
# Check if running as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root." >&2
  exit 1
fi

echo "Running as root, continuing..."

for i in {1..10}; do echo "" >> $settmp; done

make_script(){
    echo "
        #!/bin/bash

        ##################################
        ####  2025 -  KO4IYY          ####
        ####         Steve Clay       ####
        ####       steve@ko4iyy.com   ####
        ####          V 1.7           ####
        ####  Simple script to check  ####
        ####  if asterisk is conected ####
        ####  to your remote node.    ####
        ####  Used for East Coast     ####
        ####  Reflector connection    ####
        ####  via Raspberry Pi        ####
        ##################################

        MYSITE="$mynode"
        REMSITE="$remnode" # TX ECR Node (current connection)
        LOGFILE="/srv/http/checkConnect.log"   # I use this to display a refreshed logfile on the web page to keep an eye on disconnects/reconnects.
        LOGRECONLY="$logdetail"

# You shouldn't have to change anything below
#############################################
touch "$LOGFILE"

# Sets up a tmp log file to reorganize so newer entries are on top
tmpLog="/tmp/chkTemp"

# Get status of our connection

CHK=$(asterisk -rx "rpt nodes "$MYSITE"" | grep -c "$REMSITE")



case "$LOGRECONLY" in

        0)
            # Write to the log file every time this scipt is run
            echo "#############################"  | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
            date "+%m-%d-%Y %H:%M:%S" | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
            echo "Checking if connected to hub node "$REMSITE"" | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"

            if [ "$CHK" = "0" ]
            then
                echo "#############################" | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
                echo "Attempting to RECONNECT to $REMSITE...." | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
                echo "You are DISCONNECTED from hub node "$REMSITE"" | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
                date "+%m-%d-%Y %H:%M:%S" | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
                echo "#############################" | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
                echo " " | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
                asterisk -rx "rpt cmd "$MYSITE" ilink 3 "$REMSITE""
            else
                echo "You are already connected to $REMSITE." | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
            fi
            ;;
        1)
            # Write to the log file only when disconnected
            if [ "$CHK" = "0" ]
           then
                echo "#############################" | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
                echo "Attempting to RECONNECT to $REMSITE...." | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
                echo "You are DISCONNECTED from hub node "$REMSITE"" | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
                date "+%m-%d-%Y %H:%M:%S" | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
                echo "#############################" | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
                echo " " | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
                asterisk -rx "rpt cmd "$MYSITE" ilink 3 "$REMSITE""
            fi
            ;;
        *)
            ;;
esac" > /var/spool/cron/check_connect.sh

}

make_cron(){
    
            cron_file="/etc/cron.d/0hourly"
            if grep -qF "$runint * * * * /var/spool/cron/check_connect.sh" "$cron_file"; then
                echo "Cron job exists."
            else
                echo "$runint * * * * /var/spool/cron/check_connect.sh" >> "$cron_file"
            fi
}

make_html(){
    touch /srv/http/index.html
    filename="/srv/http/index.html"
    datetime=$(date +"%Y%m%d_%H%M%S")

    # Extract name and extension
    name="${filename%.*}"
    ext="${filename##*.}"

    # New filename with datetime appended
    newfilename="${name}_${datetime}.${ext}"
    mv "$filename" "$newfilename"

    echo "
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        <title>ECR Node</title>
        <style>
            body, html {
            margin: 0;
            padding: 0;
            height: 100%;
            }
            .frame {
            width: 100%;
            border: none;
            }
            #top-frame {
            overflow:  scroll;
            height: 25%;
            }
            #bottom-frame {
            overflow:  scroll;
            height: 50%;
            }
            #log-frame {
            overflow:  scroll;
            height: 50%;
            border: 1px solid #ccc;
            frameborder="1";
            }
        </style>
        </head>
        <body>
        <iframe
            id="top-frame"
            class="frame"
            src="http://"$my_ip"/supermon/link.php?nodes="$mynode"">
        </iframe>
        <iframe
            id="bottom-frame"
            class="frame"
            src="https://ecrhub.hamcolo.com/live/">
        </iframe>
        <iframe
            id="log-frame"
            class="frame"
            src="checkConnect.log">
        </iframe>
        <script>
                function refreshIframe() {
                const iframe = document.getElementById('log-frame');
                const timestamp = new Date().getTime();
                iframe.src = 'checkConnect.log?t=' + timestamp;
                }

                setInterval(refreshIframe, 60000);
        </script>
        </body>
        </html>" > /srv/http/index.html

}

while true; do
    clear
    echo "=============================="
    echo " Check Connect Settings Menu"
    echo "=============================="
    echo "1) Enter your node number"
    echo "2) Enter the remote node number"
    echo "3) Log file detail"
    echo "4) Frequency of check"
    echo "5) Install service"
    echo "6) Exit"
    echo "=============================="
    read -p "Choose an option [1-6]: " choice


    case "$choice" in
        1)  #Configure local node
            line_number=1
            while true; do
               read -p "Enter your node number: " mynode
               
            if [[ "$mynode" =~ ^[0-9]+$ ]]; then
               echo "Local node will be set to $mynode."
            else
                echo "Invalid input. Please enter a valid number."
            fi

            done
            sleep 1
            ;;
        2)  # Configure remote node
            line_number=2
            while true; do
               read -p "Enter the remote node number: " remnode
               
            if [[ "$remnode" =~ ^[0-9]+$ ]]; then
               echo "Remote node will be set to $remnode."
            else
                echo "Invalid input. Please enter a valid number."
            fi

            done
            sleep 1
            ;;
        3)  # Log file detail set up
            line_number=3
            while true; do
               logdetail=""
               read -p "Write to log file every check (1) or just when disconnected (0)?: " logdetail
               
               if [[ "$logdetail" =~ ^[0-1]+$ ]]; then
                    echo "Log detail is will be set to $logdetail"
               else
                    echo "Invalid input. Please enter 0 or 1."
               fi

            done
            sleep 1
            ;;
        4)  # Script run interval
            line_number=4
            while true; do
               read -p "What interval, in minutes, should the connection check run? " runint
                              
               if [[ "$runint" =~ ^[0-9]+$ ]]; then
                    echo "Script will be configured to run every $runint minute(s)"
               else
                    echo "Invalid input. Please enter a valid number."
               fi
            
            done
            sleep 1
            ;;    
        5)  # Run the installation
            mkdir /var/spool/cron
            mkdir /srv/http
            
            echo "Your node will be configured as $mynode"
            echo "The remote node will be configured as $remnode"
            echo "The cron job will run every $runint minutes"

            if $logdetail = 1; then
                echo "The cron will write to the log file only"
                echo "for disconnects and reconnect attempts."
            else
                echo "The cron will write to the log file"
                echo "every time the cron job is run."
            fi
            echo " "

            read -r -n 1 key

            # Check if Enter was pressed (i.e., key is empty)
            if [[ -z "$key" ]]; then
                echo "Continuing..."

            else
                echo "installation cancelled."
                sleep 2
                break

            fi

            echo "Creating run script..."
            make_script
            sleep 4
            echo "Done."
            sleep 1

            echo "Setting up cron job..."
            make_cron
            sleep 2
            echo "Done."
            sleep 1

            echo "Setting up log file..."
            touch /srv/http/checkConnect.log
            chmod 766 /srv/http/checkConnect.log
            sleep 2
            echo "Done."
            sleep 1

            echo "Creating custom web page..."
            my_ip=ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1
            make_html
            sleep 2
            echo "Done."
            ;;
                
        6)
            echo "Exiting..."
            echo "Make sure to edit /etc/asterisk/rpt.conf"
            echo "Find line    ;startup_macro = *7      around line 435 or so."
            echo "Add line below for the node you want to connect when asterisk starts or when server reboots:"
            echo "startup_macro = *73XXXXX "
            echo "Where XXXXX is the node you are connecting to."
            echo " "
            echo " "
            echo "Reboot when finished."

            read -p "Press Enter to continue."
            
            break
            ;;
        *)
            echo "Invalid option. Try again."
            sleep 1
            ;;
    esac
done

