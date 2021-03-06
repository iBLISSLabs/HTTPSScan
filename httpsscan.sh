#!/usr/bin/env bash

# Script to test the most security flaws on a target SSL/TLS.
# Author:  Alexos (alexos at alexos dot org)
# Date:    03-05-2015
# Version: 1.0
#
# Modified 2015-07-06 by Ryan Whitworth (me @ ryanwhitworth dot com)
#       * Added online function to bail early if host is offline
#       * Removed two false positives showing for some hosts
#       * Cygwin has no tput installed by default, so sending errors to /dev/null when not found (solution: install ncurses)
#
# Modified 2017-08-31 by Thiago França (thiago.dfranca@gmail.com)
#        * Added function to read targets in file
#        * Added -p parameter to scan any ports (-p 443,8443)

# References:
# OWASP Testing for Weak SSL/TLS Ciphers, Insufficient Transport Layer Protection
# https://www.owasp.org/index.php/Testing_for_Weak_SSL/TLS_Ciphers,_Insufficient_Transport_Layer_Protection_%28OTG-CRYPST-001%29
# CVE-2011-1473
# https://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2011-1473
# CVE-2012-4929
# https://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2012-4929
# CVE-2013-2566
# https://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2013-2566
# CVE-2014-0160
# https://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2014-0160
# CVE-2014-3566
# https://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2014-3566
# CVE-2015-0204
# https://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2015-0204
# CVE-2015-4000
# https://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2015-4000
# CVE-2016-0888
# https://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2016-0800
# Forward Secrecy
# http://blog.ivanristic.com/2013/06/ssl-labs-deploying-forward-secrecy.html
# Patching the SSL/TLS on Nginx and Apache Webservers
# http://alexos.org/2014/01/configurando-a-seguranca-do-ssl-no-apache-ou-nginx/

#Special Contributors

#afbsd
#Ryan Whitworth (me @ ryanwhitworth dot com)
#Thiago França (thiago.dfranca @ gmail dot com)
#Willian Mayan ( willian.mayan @ ibliss dot com dot br)


#----------------------------------------------------------------------------------------------------------------------------------
# Releases: 1.8
# - Help
# - Selecionar somente uma vulnerabilidade para teste ou modo all
#----------------------------------------------------------------------------------------------------------------------------------
VERSION=2.0

function Help {
echo "-------------------------------"
echo "Use: ./httpsscan TARGET_FILE -p TARGET_PORTs OP"
echo "Ex: $0 /tmp/hosts -p 443 ssl2"
echo "Ex: $0 /tmp/hosts -p 443,4443 ssl2"
echo -e "OP:
        all, --all, a
        ssl2, --ssl2
        crime, --crime
        rc4, --rc4
        heartbleed, --heartbleed
        poodle, --poodle
        freak, --freak
        null, --null
        weak40, --weak40
        weak56, --weak56
        forward, --forward"
}

clear

echo ":::    ::::::::::::::::::::::::::::::::::  ::::::::  ::::::::  ::::::::     :::    ::::    ::: "
echo ":+:    :+:    :+:        :+:    :+:    :+::+:    :+::+:    :+::+:    :+:  :+: :+:  :+:+:   :+: "
echo "+:+    +:+    +:+        +:+    +:+    +:++:+       +:+       +:+        +:+   +:+ :+:+:+  +:+ "
echo "+#++:++#++    +#+        +#+    +#++:++#+ +#++:++#+++#++:++#+++#+       +#++:++#++:+#+ +:+ +#+ "
echo "+#+    +#+    +#+        +#+    +#+              +#+       +#++#+       +#+     +#++#+  +#+#+# "
echo "#+#    #+#    #+#        #+#    #+#        #+#    #+##+#    #+##+#    #+##+#     #+##+#   #+#+ "
echo "###    ###    ###        ###    ###        ########  ########  ######## ###     ######    #### "
echo "V. $VERSION by iBLISS Labs                                                       "

if [ $# -ne 4 ]; then
   echo Usage: $0 TARGET_FILE -p TARGET_PORTs OP
   echo "Ex: $0 /tmp/targets -p 443 ssl2"
   echo "Ex: $0 /tmp/targets -p 443,4443 ssl2"
   Help
   exit
fi
TARGET_PORTS="$3"; PORTS=`echo $TARGET_PORTS | sed -e 's/,/ /g'`
OP=$4
red=`tput setaf 1 2>/dev/null`
green=`tput setaf 2 2>/dev/null`
reset=`tput sgr0 2>/dev/null`
timeout_bin=`which timeout 2>/dev/null`


function ssl2() {
echo
echo "${red}==> ${reset} Checking SSLv2 (CVE-2011-1473) (CVE-2016-0800)"
for HOST in `cat $1`; do
   for PORT in ${PORTS[@]}; do
      TARGET=$HOST:$PORT

ssl="`echo 'Q' | ${timeout_bin:+$timeout_bin 5} openssl s_client -ssl2 -connect "$TARGET" 2>/dev/null`"

proto=`echo "$ssl" | grep '^ *Protocol *:' | awk '{ print $3 }'`
cipher=`echo "$ssl" | grep '^ *Cipher *:' | awk '{ print $3 }'`

echo -e "\n Checking $HOST:$PORT... \n"

if [ "$cipher" = '' ]; then
        echo '${green}Not vulnerable.${reset} Failed to establish SSLv2 connection.'
else
        echo "${red}Vulnerable!${reset}  SSLv2 connection established using $proto/$cipher"
fi
  done
done
}

function crime {
echo
echo "${red}==> ${reset} Checking CRIME (CVE-2012-4929)"
for HOST in `cat $1`; do
   for PORT in ${PORTS[@]}; do
      TARGET=$HOST:$PORT

ssl="`echo 'Q' | ${timeout_bin:+$timeout_bin 5} openssl s_client -connect "$TARGET" 2>/dev/null`"
compr=`echo "$ssl" |grep 'Compression: ' | awk '{ print $2 } '`

echo -e "\n Checking $HOST:$PORT... \n"

if [ "$compr" = 'NONE' ] || [ "$compr" = "" ]; then
        echo '${green}Not vulnerable.${reset} TLS Compression is not enabled.'
else
        echo "${red}Vulnerable!${reset} Connection established using $compr compression."
fi
  done
done
}

function rc4 {
echo
echo "${red}==> ${reset} Checking RC4 (CVE-2013-2566)"
for HOST in `cat $1`; do
   for PORT in ${PORTS[@]}; do
      TARGET=$HOST:$PORT

ssl="`echo 'Q' | ${timeout_bin:+$timeout_bin 5} openssl s_client -cipher RC4 -connect "$TARGET" 2>/dev/null`"
proto=`echo "$ssl" | grep '^ *Protocol *:' | awk '{ print $3 }'`
cipher=`echo "$ssl" | grep '^ *Cipher *:' | awk '{ print $3 }'`

echo -e "\n Checking $HOST:$PORT... \n"

if [ "$cipher" = '' ]; then
echo '${green}Not vulnerable.${reset} Failed to establish RC4 connection.'
else
echo "${red}Vulnerable!${reset} Connection established using $proto/$cipher"
fi
   done
done

}

function heartbleed {
echo
echo "${red}==> ${reset} Checking Heartbleed (CVE-2014-0160)"
for HOST in `cat $1`; do
   for PORT in ${PORTS[@]}; do
      TARGET=$HOST:$PORT

ssl="`echo "QUIT"|openssl s_client -connect "$TARGET" -tlsextdebug 2>&1|grep 'server extension "heartbeat" (id=15)' || echo safe 2>/dev/null`"

echo -e "\n Checking $HOST:$PORT... \n"

if [ "$ssl" = 'safe' ]; then
        echo 'The host is ${green}not vulnerable${reset} to Heartbleed attack.'
else
        echo "${red}Vulnerable!${reset} The host is vulnerable to Heartbleed attack."
fi
   done
done
}

function poodle {
echo
echo "${red}==> ${reset} Checking Poodle (CVE-2014-3566)"

for HOST in `cat $1`; do
   for PORT in ${PORTS[@]}; do
      TARGET=$HOST:$PORT
      
ssl="`echo 'Q' | ${timeout_bin:+$timeout_bin 5} openssl s_client -ssl3 -connect "$TARGET" 2>/dev/null`"

proto=`echo "$ssl" | grep '^ *Protocol *:' | awk '{ print $3 }'`
cipher=`echo "$ssl" | grep '^ *Cipher *:' | awk '{ print $3 }'`

echo -e "\n Checking $HOST:$PORT... \n"

if [ "$cipher" = '0000'  -o  "$cipher" = '(NONE)' ] || [ "$cipher" = "" ]; then
        echo '${green}Not vulnerable.${reset}  Failed to establish SSLv3 connection.'
else
        echo "${red}Vulnerable!${reset} SSLv3 connection established using $proto/$cipher"
fi
   done
done
}

function freak {
echo
echo "${red}==> ${reset} Checking FREAK (CVE-2015-0204)"
for HOST in `cat $1`; do
   for PORT in ${PORTS[@]}; do
      TARGET=$HOST:$PORT
      
ssl="`echo 'Q' | ${timeout_bin:+$timeout_bin 5} openssl s_client -cipher EXPORT -connect "$TARGET" 2>/dev/null`"
cipher=`echo "$ssl" | grep '^ *Cipher *:' | awk '{ print $3 }'`

echo -e "\n Checking $HOST:$PORT... \n"

if [ "$cipher" = '' ]; then
         echo '${green}Not vulnerable.${reset}  Failed to establish connection with an EXPORT cipher.'
else
         echo "${red}Vulnerable!${reset} Connection established using $cipher"
fi
   done
done
}

function null {
echo
echo "${red}==> ${reset}Checking NULL Cipher"
for HOST in `cat $1`; do
   for PORT in ${PORTS[@]}; do
      TARGET=$HOST:$PORT

ssl="`echo 'Q' | ${timeout_bin:+$timeout_bin 5} openssl s_client -cipher NULL -connect "$TARGET" 2>/dev/null`"
cipher=`echo "$ssl" | grep '^ *Cipher *:' | awk '{ print $3 }'`

echo -e "\n Checking $HOST:$PORT... \n"

if [ "$cipher" = '' ]; then
         echo '${green}Not vulnerable.${reset} Failed to establish connection with a NULL cipher.'
else
         echo "${red}Vulnerable!${reset} Connection established using $cipher"
fi
   done
done
}


function weak40 {
echo
echo "${red}==> ${reset} Checking Weak Ciphers"
for HOST in `cat $1`; do
   for PORT in ${PORTS[@]}; do
      TARGET=$HOST:$PORT

ssl="`echo 'Q' | ${timeout_bin:+$timeout_bin 5} openssl s_client -cipher EXPORT40 -connect "$TARGET" 2>/dev/null`"

cipher=`echo "$ssl" | grep '^ *Cipher *:' | awk '{ print $3 }'`

echo -e "\n Checking $HOST:$PORT... \n"

if [  "$cipher" = '' ]; then
        echo '${green}Not vulnerable.${reset} Failed to establish connection with 40 bit cipher.'
else
        echo "${red}Vulnerable!${reset} Connection established using 40 bit cipher"
fi
   done
done
}


function weak56 {
echo
echo "${red}==> ${reset} Checking Weak Ciphers"
for HOST in `cat $1`; do
   for PORT in ${PORTS[@]}; do
      TARGET=$HOST:$PORT

ssl="`echo 'Q' | ${timeout_bin:+$timeout_bin 5} openssl s_client -cipher EXPORT56 -connect "$TARGET" 2>/dev/null`"

cipher=`echo "$ssl" | grep '^ *Cipher *:' | awk '{ print $3 }'`

echo -e "\n Checking $HOST:$PORT... \n"

if [  "$cipher" = '' ]; then
        echo '${green}Not vulnerable.${reset} Failed to establish connection with 56 bit cipher.'
else
        echo "${red}Vulnerable!${reset} Connection established using 56 bit cipher"
fi
   done
done
}

function forward {
echo
echo "${red}==> ${reset}Checking Forward Secrecy"
for HOST in `cat $1`; do
   for PORT in ${PORTS[@]}; do
      TARGET=$HOST:$PORT

ssl="`echo 'Q' | ${timeout_bin:+$timeout_bin 5} openssl s_client -cipher 'ECDH:DH' -connect "$TARGET" 2>/dev/null`"

proto=`echo "$ssl" | grep '^ *Protocol *:' | awk '{ print $3 }'`
cipher=`echo "$ssl" | grep '^ *Cipher *:' | awk '{ print $3 }'`

echo -e "\n Checking $HOST:$PORT... \n"

if [ "$cipher" = ''  -o  "$cipher" = '(NONE)' ]; then
        echo 'Forward Secrecy is not enabled.'
else
        echo "Enabled! Established using $proto/$cipher"
fi
   done
done
}

function online() {
for HOST in `cat $1`; do
   for PORT in ${PORTS[@]}; do
      TARGET=$HOST:$PORT
      
ssl="`echo Q | openssl s_client -connect "$TARGET" 2>/dev/null | wc -l`"
if [ "$ssl" -lt 5 ]; then
        echo "Host $TARGET is unreachable."
        exit -1
fi
   done
done
}


#----------------------------------------------------------------------------------------------------------------------------------

echo
echo [*] Analyzing SSL/TLS Vulnerabilities...
echo
echo Generating Report...Please wait
online $1

#New function calls:
case $4 in
        "--help"|"help")
                Help;;
        "all"|"--all"|"a")
                ssl2 $1
                crime $1
                rc4 $1
                heartbleed $1
                poodle $1
                freak $1
                null $1
                weak40 $1
                weak56 $1
                forward $1
        ;;
        "ssl2"|"--ssl2")
                ssl2 $1
        ;;
        "crime"|"--crime")
                crime $1
        ;;
        "rc4"|"--rc4")
                rc4 $1
        ;;
        "heartbleed"|"--heartbleed")
                heartbleed $1
        ;;
        "poodle"|"--poodle")
                poodle $1
        ;;
        "freak"|"--freak")
                freak $1
        ;;
        "null"|"--null")
                null $1
        ;;
        "weak40"|"--weak40")
                weak40 $1
        ;;
        "weak56"|"--weak56")
                weak56 $1
        ;;
        "forward"|"--forward")
                forward $1
        ;;
        *)
                echo -e "${red}Parameter invalid, check --help${reset}"

esac
echo
#----------------------------------------------------------------------------------------------------------------------------------

#echo
#echo [*] Checking Preferred Server Ciphers
#sslscan $HOST:$PORT > $LOGFILE
#cat $LOGFILE| sed '/Prefered Server Cipher(s):/,/^$/!d' | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g"
#rm $LOGFILE
#echo [*] done
