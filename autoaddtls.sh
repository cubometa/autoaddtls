#!/bin/bash

# Cubometa AutoAddTLS, version 1.1.5
# Sun, Oct 11, 2015 through Sat, Oct 17, 2015, Mon, Oct 19, 2015 through Thu, Oct 22, 2015,
# Tue, Nov 10, 2015 through Sun, Nov 15, 2015, Tue, Nov 17, 2015, Fri, Jun 10, 2016
# (c) 2015~2016 Ale Navarro (cubometa.com)

helptext() {
echo "Cubometa AutoAddTLS, version 1.1.5"
echo    "usage: ./autoaddtls.sh [--enablemod|--disablemod]"
echo -n "                       [--certfile cert.crt --certkeyfile certkey.key"
echo -n " --certchainfile certchain.pem [--tlsconffile tlsconffile.conf]"
echo    " [--tlscertdir certdirectory]]"
echo -n "                       [--hstsmaxage seconds [--hstspreload [0|1]]"
echo -n " [--hstsincludesubdomains [0|1]] [--apacheconffile"
echo " apacheconffile.conf] [--tlsconffile tlsconffile.conf]]"
echo    "       ./autoaddtls.sh [--help|-h]"

if [ $1 ]; then
    echo -n "Cubometa AutoAddTLS automates enabling and configuring TLS, HSTS"
    echo " and related settings in an Apache server."
    echo
    echo "Enabling or disabling the Apache TLS module"
    echo "--enablemod:"
    echo "    Enable the Apache TLS module."
    echo "--disablemod:"
    echo "    Disable the Apache TLS module."
    echo
    echo "Configuring the TLS certificate in Apache"
    echo "--certfile (required):"
    echo "    Specifies the path of the certificate (a .crt file)."
    echo "--certkeyfile (required):"
    echo "    Specifies the path of the certificate key (a .key file)."
    echo "--certchainfile (required):"
    echo "    Specifies the path of the certificate chain (a .pem file)."
    echo "--tlsconffile (optional):"
    echo "    Specifies the path of the Apache configuration file for the"
    echo "    TLS-enabled site (a .conf file, default:"
    echo "    /etc/apache2/sites-enabled/default-ssl.conf)."
    echo "--tlscertdir (optional):"
    echo "    Specifies the path the certificate files will be copied into (a"
    echo "    directory, default: /etc/apache2/tlscerts). If it does not exist,"
    echo "    it is created (but the parent directory has to exist)."
    echo
    echo "Enabling or disabling HSTS"
    echo "--hstsmaxage (required):"
    echo "    Specifies the number of seconds to display in the HSTS header (or"
    echo "    the value - to disable the HSTS header)."
    echo "    The site should work via HTTPS for those many seconds after each"
    echo "    response that includes this header with that value is served or"
    echo "    else the site will stop working at all for every user that"
    echo "    received the header until it expires for them, as no clear HTTP"
    echo "    requests to the site will be placed by HSTS-aware browsers for"
    echo "    that period of time. Each time such a browser receives this flag"
    echo "    in an HTTPS response, the timer is set to the received value."
    echo "    1 year is about 31536000 seconds. Setting the HSTS max-age to 0"
    echo "    is not the same as not setting the HSTS header."
    echo "--hstspreload (optional):"
    echo "    Specifies if the preload flag is set on the HSTS header. 0 means"
    echo "    no, 1 means yes (default: 0). This parameter has to be set to"
    echo "    the desired value each time the HSTS header is set, even if the"
    echo "    value does not change. Merely setting the flag is not the same as"
    echo "    signing up on a HSTS preload list, but it is probably a requisite"
    echo "    for doing so."
    echo "--hstsincludesubdomains (optional):"
    echo "    Specifies if the includeSubDomains flag is set on the HSTS"
    echo "    header. 0 means no, 1 means yes (default: 0). This parameter has"
    echo "    to be set to the desired value each time the HSTS header is set,"
    echo "    even if the value does not change."
    echo "--apacheconffile (optional):"
    echo "    Specifies the path of the general Apache configuration file (a"
    echo "    .conf file, default: /etc/apache2/apache2.conf)."
    echo "--tlsconffile (optional):"
    echo "    Specifies the path of the Apache configuration file for the"
    echo "    TLS-enabled site (a .conf file, default:"
    echo "    /etc/apache2/sites-enabled/default-ssl.conf)."
    echo
    echo "Getting help"
    echo "--help, -h:"
    echo "    Show this help text."
fi
}

getpath() {
	if [ $# -eq 1 ]; then echo "A file must be specified for each parameter of the certificate."; exit 1; fi
	if [ "$2" == "-" ]; then echo "Files cannot be read from stdin."; exit 1; fi
	if [ "${2:0:1}" == "-" ]; then echo "A file must be specified for each parameter of the certificate."; exit 1; fi
	if [ "${2:0:1}" == "/" ]; then
		export GETPATH="$2"
	else
		export GETPATH="${PWD}/$2"
	fi
	shift
}

gethstsmaxage() {
	if [ $# -eq 1 ]; then echo "A value must be specified for the HSTS max age."; exit 1; fi
	if [[ ! "$2" =~ ^[0-9]+$ ]]; then
		if [ "$2" != "-" ]; then
			echo "The specified value for the HSTS max age must be numerical."; exit 1;
		fi
	fi
	export GETHSTSMAXAGE="$2"
	shift
}

getbit() {
	if [ $# -eq 1 ]; then echo "A value must be specified for the HSTS preload and includeSubDomains flags."; exit 1; fi
	if [ "$2" != "0" ]; then
		if [ "$2" != "1" ]; then
			echo "The specified value for the HSTS preload and includeSubDomains flags should be 0 or 1."; exit 1;
		fi
	fi
	export GETBIT="$2"
	shift
}

export ENDISTLSMODULE=0
export UPDATINGCERT=0
export HSTSCHANGES=0

while [ $# -gt 0 ]; do
	if [ "${1:0:2}" == "--" ]; then
		case "${1:2}" in
			enablemod)             export ENDISTLSMODULE=1;;
			disablemod)            export ENDISTLSMODULE=2;;
			certfile)              getpath; export CERTFILE="$GETPATH"; export UPDATINGCERT=$(($UPDATINGCERT&1));;
			certkeyfile)           getpath; export CERTKEYFILE="$GETPATH"; export UPDATINGCERT=$(($UPDATINGCERT&2));;
			certchainfile)         getpath; export CERTCHAINFILE="$GETPATH"; export UPDATINGCERT=$(($UPDATINGCERT&4));;
			tlsconffile)           getpath; export TLSCONFFILE="$GETPATH";;
			tlscertdir)            getpath; export TLSCERTDIR="$GETPATH"; export UPDATINGCERT=$(($UPDATINGCERT&16));;
			hstsmaxage)            gethstsmaxage; export HSTSMAXAGE="$GETHSTSMAXAGE"; export HSTSCHANGES=$(($HSTSCHANGES&1));;
			apacheconffile)        getpath; export APACHECONFFILE="$GETPATH";;
			hstspreload)           getbit; export HSTSPRELOAD="$GETBIT"; export HSTSCHANGES=$(($HSTSCHANGES&2));;
			hstsincludesubdomains) getbit; export HSTSINCLSUBDOMAINS="$GETBIT"; export HSTSCHANGES=$(($HSTSCHANGES&2));;
			*)                     helptext; exit 1;;
		esac
	else if [ "$1" == "-h" ]; then
		helptext 1; exit 0;
	else
		helptext; exit 1;
	fi
	fi
	shift
done

if [ $ENDISTLSMODULE -eq 1 ]; then
	echo "Enabling Apache TLS module..."
	sudo a2enmod ssl
	sudo service apache2 restart
	echo "Apache TLS module enabled."
fi

if [ $ENDISTLSMODULE -eq 2 ]; then
	echo "Disabling Apache TLS module..."
	sudo a2dismod ssl
	sudo service apache2 restart
	echo "Apache TLS module disabled."
fi

if [ $UPDATINGCERT -ne 0 ]; then
	if [ $(($UPDATINGCERT&7)) -ne 7 ]; then
		echo "The certificate file, the certificate key file and the certificate chain file all have to be provided."
		exit 1
	fi
		
	echo "Certificate file: $CERTFILE"
	echo "Certificate key file: $CERTKEYFILE"
	echo "Certificate chain file: $CERTCHAINFILE"
	
	if [ ! $APACHECONFFILE ]; then
		export APACHECONFFILE="/etc/apache2/apache2.conf"
	fi
	echo "Apache configuration file: $APACHECONFFILE"
	
	if [ ! $TLSCONFFILE ]; then
		export TLSCONFFILE="/etc/apache2/sites-enabled/default-ssl.conf"
	fi
	echo "TLS configuration file: $TLSCONFFILE"
	
	if [ ! $TLSCERTDIR ]; then
		export TLSCERTDIR="/etc/apache2/tlscerts"
	fi
	echo "TLS certificate directory: $TLSCERTDIR"
	
	if [ ! -f "$CERTFILE" ]; then
		echo "Certificate file $CERTFILE does not exist or is not a regular file."
		export CERTFILES_CHECKFAIL=1
	fi
	
	if [ ! -f "$CERTKEYFILE" ]; then
		echo "Certificate key file $CERTKEYFILE does not exist or is not a regular file."
		export CERTFILES_CHECKFAIL=1
	fi
	
	if [ ! -f "$CERTCHAINFILE" ]; then
		echo "Certificate chain file $CERTCHAINFILE does not exist or is not a regular file."
		export CERTFILES_CHECKFAIL=1
	fi

	if [ ! -r "$CERTFILE" ]; then
		echo "Certificate file $CERTFILE is not readable."; export CERTFILES_CHECKFAIL=1;
	fi
	
	if [ ! -r "$CERTKEYFILE" ]; then
		echo "Certificate key file $CERTKEYFILE is not readable."; export CERTFILES_CHECKFAIL=1;
	fi
	
	if [ ! -r "$CERTCHAINFILE" ]; then
		echo "Certificate chain file $CERTCHAINFILE is not readable."; export CERTFILES_CHECKFAIL=1;
	fi
	
	if [ $CERTFILES_CHECKFAIL ]; then
		echo "Exiting due to previous errors"
		exit 1
	fi
	
	export CONFCERTFILE="${TLSCERTDIR}/`basename $CERTFILE`";
	export CONFCERTKEYFILE="${TLSCERTDIR}/`basename $CERTKEYFILE`";
	export CONFCERTCHAINFILE="${TLSCERTDIR}/`basename $CERTCHAINFILE`";
	
	if [ ! -d "$TLSCERTDIR" ]; then
		mkdir $TLSCERTDIR
	fi
	chmod 644 $TLSCERTDIR
	
	mv $CERTFILE $CONFCERTFILE
	echo "Moving certificate file $CERTFILE to $CONFCERTFILE"
	chmod 644 $CONFCERTFILE
	
	mv $CERTKEYFILE $CONFCERTKEYFILE
	echo "Moving certificate key file $CERTKEYFILE to $CONFCERTKEYFILE"
	chmod 600 $CONFCERTKEYFILE
	
	mv $CERTCHAINFILE $CONFCERTCHAINFILE
	echo "Moving certificate chain file $CERTCHAINFILE to $CONFCERTCHAINFILE"
	chmod 644 $CONFCERTCHAINFILE
	
	sed -i "" "s/SSLCertificateFile(.*)/SSLCertificateFile ${CONFCERTFILE//\//\\/}/g" $TLSCONFFILE
	sed -i "" "s/SSLCertificateKeyFile(.*)/SSLCertificateKeyFile ${CONFCERTKEYFILE//\//\\/}/g" $TLSCONFFILE
	sed -i "" "s/SSLCertificateChainFile(.*)/SSLCertificateChainFile ${CONFCERTCHAINFILE//\//\\/}/g" $TLSCONFFILE
	echo "Modifying the Apache TLS configuration file $TLSCONFFILE with the certificate"
fi

if [ $HSTSCHANGES -ne 0 ]; then
	if [ $HSTSCHANGES -eq 2 ]; then
		echo "The HSTS includeSubdomains and HSTS preload require setting an HSTS max-age."; exit 1;
	fi
	
	if [ $HSTSCHANGES -eq 3 ]; then
		if [ $HSTSMAXAGE == "-" ]; then
			echo "Cannot set HSTS includeSubdomains or HSTS preload if removing the HSTS header."; exit 1;
		fi
	fi

	if [ ! $TLSCONFFILE ]; then
		export TLSCONFFILE="/etc/apache2/sites-enabled/default-ssl.conf"
	fi
	echo "TLS configuration file: $TLSCONFFILE"
	
	if [ ! `grep -q "LoadModule headers_module" $APACHECONFFILE` ]; then
		echo "LoadModule headers_module /usr/lib/apache2/modules/mod_headers.so" >> "$APACHECONFFILE"
	fi
	if [ ! `grep -q "LoadModule rewrite_module" $APACHECONFFILE` ]; then
		echo "LoadModule rewrite_module /usr/lib/apache2/modules/mod_rewrite.so" >> "$APACHECONFFILE"
	fi
	
	if [ $HSTSINCLSUBDOMAINS -eq 1 ]; then
		export HSTSINCLSUBDOMAINSCONF="; includeSubDomains"
	fi
	if [ $HSTSPRELOAD -eq 1 ]; then
		export HSTSPRELOADCONF="; preload"
	fi

	if [ `grep -q "Header always set Strict-Transport-Security" $TLSCONFFILE` ]; then
		sed -i "" "/Header always set Strict-Transport-Security/D"
	fi
	
	if [ $HSTSMAXAGE != "-" ]; then
		echo "Header always set Strict-Transport-Security \"max-age=${HSTSMAXAGE}${HSTSINCLSUBDOMAINSCONF}${HSTSPRELOADCONF}\"" >> $TLSCONFFILE
	fi
fi
