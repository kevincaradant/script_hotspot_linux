# SCRIPT_HOTSPOT_LINUX
You want a real hotspot ( compatible android - linux - mac - windows )  and not just a simple hotspot AD-Hoc , this script is for you and really simple to use   

## HOW CAN I START ?
Clone the repository : `git clone https://github.com/kevincaradant/script_hotspot_linux.git`  
Launch the script sh : `sudo sh install_hotspot.sh`   
Follow question during the process and that all.   

If you want use alias (start_hotspot / stop hotspot) or service , you will be able to restart the computer after the installation with the script   
   
## START AND STOP THE HOTSPOT   
   
When the computer is starting, the hotspot is volontary desactivated   
To activate it , write : `service wifi_access_point start` or `service wifi_access_point start_hotspot` (alias)   
To desactivate it , write : `service wifi_access_point stop` or `service wifi_access_point stop_hotspot` (alias)   

