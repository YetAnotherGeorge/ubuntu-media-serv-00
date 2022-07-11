# Reset
export COLOFF='\033[0m'               # Text Reset
export COLOFFNL='\033[0m\n'           # Text Reset + NewLine

# Foregrounds
   # Regular Colors
   export Col_Black='\033[0;30m'         # Black
   export Col_Red='\033[0;31m'           # Red
   export Col_Green='\033[0;32m'         # Green
   export Col_Yellow='\033[0;33m'        # Yellow
   export Col_Blue='\033[0;34m'          # Blue
   export Col_Purple='\033[0;35m'        # Purple
   export Col_Cyan='\033[0;36m'          # Cyan
   export Col_White='\033[0;37m'         # White

   # Bold
   export Col_bBlack='\033[1;30m'        # Black
   export Col_bRed='\033[1;31m'          # Red
   export Col_bGreen='\033[1;32m'        # Green
   export Col_bYellow='\033[1;33m'       # Yellow
   export Col_bBlue='\033[1;34m'         # Blue
   export Col_bPurple='\033[1;35m'       # Purple
   export Col_bCyan='\033[1;36m'         # Cyan
   export Col_bWhite='\033[1;37m'        # White

   # Underline
   export Col_uBlack='\033[4;30m'        # Black
   export Col_uRed='\033[4;31m'          # Red
   export Col_uGreen='\033[4;32m'        # Green
   export Col_uYellow='\033[4;33m'       # Yellow
   export Col_uBlue='\033[4;34m'         # Blue
   export Col_uPurple='\033[4;35m'       # Purple
   export Col_uCyan='\033[4;36m'         # Cyan
   export Col_uWhite='\033[4;37m'        # White

   # High Intensity
   export Col_iBlack='\033[0;90m'        # Black
   export Col_iRed='\033[0;91m'          # Red
   export Col_iGreen='\033[0;92m'        # Green
   export Col_iYellow='\033[0;93m'       # Yellow
   export Col_iBlue='\033[0;94m'         # Blue
   export Col_iPurple='\033[0;95m'       # Purple
   export Col_iCyan='\033[0;96m'         # Cyan
   export Col_iWhite='\033[0;97m'        # White

   # Bold High Intensity
   export Col_biBlack='\033[1;90m'       # Black
   export Col_biRed='\033[1;91m'         # Red
   export Col_biGreen='\033[1;92m'       # Green
   export Col_biYellow='\033[1;93m'      # Yellow
   export Col_biBlue='\033[1;94m'        # Blue
   export Col_biPurple='\033[1;95m'      # Purple
   export Col_biCyan='\033[1;96m'        # Cyan
   export Col_biWhite='\033[1;97m'       # White
#
#
# Backgrounds
   # Background
   export Col_bgBlack='\033[40m'         # Black
   export Col_bgRed='\033[41m'           # Red
   export Col_bgGreen='\033[42m'         # Green
   export Col_bgYellow='\033[43m'        # Yellow
   export Col_bgBlue='\033[44m'          # Blue
   export Col_bgPurple='\033[45m'        # Purple
   export Col_bgCyan='\033[46m'          # Cyan
   export Col_bgWhite='\033[47m'         # White

   # Bold Intensity backgrounds
   export Col_bgiBlack='\033[0;100m'     # Black
   export Col_bgiRed='\033[0;101m'       # Red
   export Col_bgiGreen='\033[0;102m'     # Green
   export Col_bgiYellow='\033[0;103m'    # Yellow
   export Col_bgiBlue='\033[0;104m'      # Blue
   export Col_bgiPurple='\033[0;105m'    # Purple
   export Col_bgiCyan='\033[0;106m'      # Cyan
   export Col_bgiWhite='\033[0;107m'     # White

#
#
printf "${Col_bBlue}#${Col_bPurple}#${Col_bYellow}# ${Col_biGreen}Registered c${Col_biWhite}o${Col_biGreen}l${Col_biWhite}o${Col_biGreen}r variables. ${Col_bYellow}#${Col_bPurple}#${Col_bBlue}# ${COLOFFNL}"