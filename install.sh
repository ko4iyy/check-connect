#!/bin/bash

# Check if running as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root." >&2
  exit 1
fi

echo "Running as root, continuing..."

settmp=$(mktemp)
for i in {1..10}; do echo "" >> $settmp; done

make_script(){
    echo "
        #!/bin/bash

        ##################################
        ####  2025 -  KO4IYY          ####
        ####         Steve Clay       ####
        ####       steve@ko4iyy.com   ####
        ####          V 1.5           ####
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
        touch /tmp/chkTemp
        tmpLog="/tmp/chkTemp"

        # set up log file and configure settings

        if [ "$LOGRECONLY" = "0" ]
        then
                echo "#############################"  | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
                date "+%m-%d-%Y %H:%M:%S" | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
                CHK=""
                echo "Checking if connected to hub node "$REMSITE"" | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
                CHK=$(asterisk -rx "rpt nodes "$MYSITE"" | grep -c "$REMSITE")

                if [ "$CHK" = "0" ]
                then
                        echo "Reconnecting to $REMSITE...." | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
                        asterisk -rx "rpt cmd "$MYSITE" ilink "$REMSITE""
                else
                        echo "You are already connected to $REMSITE." | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
                fi

                echo "#############################" | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"

        else
                CHK=""
                CHK=$(asterisk -rx "rpt nodes "$MYSITE"" | grep -c "$REMSITE")

                if [ "$CHK" = "0" ]
                then
                        echo "#############################" | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
                        date "+%m-%d-%Y %H:%M:%S" | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
                        echo "You are DISCONNECTED to hub node "$REMSITE"" | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
                        echo "Attempting to RECONNECT to $REMSITE...." | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
                        asterisk -rx "rpt cmd "$mynode" ilink 3 "$REMSITE""
                        CHK=$(asterisk -rx "rpt nodes "$MYSITE"" | grep -c "$REMSITE")

                        if [ "$CHK" = "1" ]
                        then
                                echo "Reconnect successful. Your node "$MYSITE" is now connected to ECR node "$REMSITE"." | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
                        else
                                echo "Reconnect unsuccessful.  I will retry next time this file is called." | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
                        fi

                        echo "#############################" | cat - "$LOGFILE" > "$tmpLog" && mv "$tmpLog" "$LOGFILE"
                
                fi

        fi" > /var/spool/cron/check_connect.sh

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
               echo "Local node will be set to $mynode."
               total_lines=$(wc -l < "$settmp")

            if [[ "$mynode" =~ ^[0-9]+$ ]]; then
                if (( line_number <= total_lines )); then
                    # Line exists — replace it
                    sed -i "${line_number}s/.*/$mynode/" "$settmp"
                    break
                else
                    # Line doesn't exist — append blank lines and the new line
                    while (( total_lines < line_number - 1 )); do
                        echo "" >> "$settmp"
                        ((total_lines++))
                        echo "$mynode" >> "$settmp"
                    done
                    break
                fi
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
               echo "Remote node will be set to $remnode."
               total_lines=$(wc -l < "$settmp")

            if [[ "$remnode" =~ ^[0-9]+$ ]]; then
                if (( line_number <= total_lines )); then
                    # Line exists — replace it
                    sed -i "${line_number}s/.*/$remnode/" "$settmp"
                    break
                else
                    # Line doesn't exist — append blank lines and the new line
                    while (( total_lines < line_number - 1 )); do
                        echo "" >> "$settmp"
                        ((total_lines++))
                        echo "$remnode" >> "$settmp"
                    done
                    break
                fi
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
               total_lines=$(wc -l < "$settmp")
                
                if [[ "$logdetail" =~ ^[0-9]+$ ]]; then
                    if [[ "$logdetail" == "0" || "$logdetail" == "1" ]]; then
                        if (( line_number <= total_lines )); then
                            # Line exists — replace it
                            sed -i "${line_number}s/.*/$logdetail/" "$settmp"
                            break
                        else
                            # Line doesn't exist — append blank lines and the new line
                            while (( total_lines < line_number - 1 )); do
                                echo "" >> "$settmp"
                                ((total_lines++))
                                echo "$logdetail" >> "$settmp"
                            done
                            break
                        fi
                    else
                        echo "Invalid input. Please enter 0 or 1."
                    fi
                else
                    echo "Invalid input. Please enter a valid number."
                fi

            done
            sleep 1
            ;;
        4)  # Script run interval
            line_number=4
            while true; do
               read -p "What interval, in minutes, should the connection check run? " runint
               echo "Script will be configured to run every $runint minute(s)"
               total_lines=$(wc -l < "$settmp")

            if (( line_number <= total_lines )); then
                # Line exists — replace it
                sed -i "${line_number}s/.*/$runint/" "$settmp"
                break
            else
                # Line doesn't exist — append blank lines and the new line
                while (( total_lines < line_number - 1 )); do
                    echo "" >> "$settmp"
                    ((total_lines++))
                    echo "$runint" >> "$settmp"
                done
                break
            fi

            done
            sleep 1
            ;;    
        5)  # Run the installation
            mkdir /var/spool/cron
            mkdir /srv/http
            
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

            rm $settmp
            break
            ;;
        *)
            echo "Invalid option. Try again."
            sleep 1
            ;;
    esac
done

