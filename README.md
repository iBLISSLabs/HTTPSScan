# HTTPSScan
Shell script for testing the SSL/TLS Protocols

Check for SSL/TLS Vulnerabilities:

* SSLv2 (CVE-2011-1473) (CVE-2016-0800)
* TLS CRIME (CVE-2012-4929)
* RC4 (CVE-2013-2566)
* Heartbleed (CVE-2014-0160) 
* Poodle (CVE-2014-3566)
* FREAK (CVE-2015-0204)
* Logjam (CVE-2015-4000)
* Weak Ciphers

Cygwin dependencies:
* ncurses 

Usage:

bash httpsscan.sh [target] or [targets file] -p [port] [option]

Options:

all, --all,

ssl2, --ssl2

crime, --crime

rc4, --rc4

heartbleed, --heartbleed

poodle, --poodle

freak, --freak

null, --null

weak40, --weak40

weak56, --weak56

forward, --forward

[![asciicast](https://asciinema.org/a/vOgmfqvS0bGlZ5BJU7AbLZGw3.png)](https://asciinema.org/a/vOgmfqvS0bGlZ5BJU7AbLZGw3)
