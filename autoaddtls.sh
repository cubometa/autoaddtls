#!/bin/bash

# Cubometa AutoAddTLS, version 1.0
# Sun, Oct 11, 2015 through Sat, Oct 17, 2015, Mon, Oct 19, 2015 through Thu, Oct 22, 2015
# (c) 2015 Ale Navarro (cubometa.com)

helptext() {
	echo "Cubometa AutoAddTLS, version 1.0"
	echo -n "usage: ./autoaddtls.sh [--enablemod] [--certfile cert.crt --certkeyfile certkey.key"
	echo " --certchainfile certchain.pem [--tlsconffile conffile.conf] [--tlscertdir certdirectory]]"
	echo "       ./autoaddtls.sh [--help|-h]"

	if [ $1 ]; then
		echo "Cubometa AutoAddTLS automates enabling and configuring TLS, HSTS and related settings in an Apache server."
		echo
		echo "Enabling the Apache TLS module"
		echo "--enablemod: Enable the Apache TLS module."
		echo
		echo "Configuring the TLS certificate in Apache"
		echo "--certfile      (required): Specifies the path of the certificate (a .crt file)."
		echo "--certkeyfile   (required): Specifies the path of the certificate key (a .key file)."
		echo "--certchainfile (required): Specifies the path of the certificate chain (a .pem file)."
		echo "--tlsconffile   (optional): Specifies the path of the Apache configuration file for the TLS-enabled site"
		echo "                            (a .conf file, default: /etc/apache2/sites-available/default-ssl.conf)."
		echo "--tlscertdir    (optional): Specifies the path the certificate files will be saved into. It will be"
		echo "                            created if it doesn't exist (a directory, default: /etc/apache2/tlscerts)."
		echo
		echo "Getting help"
		echo "--help, -h: Show this help text."
	fi
}

getpath() {
	if [ $# -eq 1 ]; then echo "A file must be specified for each parameter of the certificate."; exit 1; fi
	if [ "$2" == "-" ]; then echo "Files cannot be read from stdin."; exit 1; fi
	if [ "${2:0:1}" == "-" ]; then echo "A file must be specified for each parameter of the certificate."; exit 1; fi
	export GETPATH="$2"
	shift
}

export ENABLETLSMODULE=0
export UPDATINGCERT=0

while [ $# -gt 0 ]; do
	if [ "${1:0:2}" == "--" ]; then
		case "${1:2}" in
			enablemod)     export ENABLETLSMODULE=1;;
			certfile)      getpath; export CERTFILE="$GETPATH"; export UPDATINGCERT=$(($UPDATINGCERT&1));;
			certkeyfile)   getpath; export CERTKEYFILE="$GETPATH"; export UPDATINGCERT=$(($UPDATINGCERT&2));;
			certchainfile) getpath; export CERTCHAINFILE="$GETPATH"; export UPDATINGCERT=$(($UPDATINGCERT&4));;
			tlsconffile)   getpath; export TLSCONFFILE="$GETPATH"; export UPDATINGCERT=$(($UPDATINGCERT&8));;
			tlscertdir)    getpath; export TLSCERTDIR="$GETPATH"; export UPDATINGCERT=$(($UPDATINGCERT&16));;
			*)             helptext; exit 1;;
		esac
	else if [ "$1" == "-h" ]; then
		helptext 1; exit 0;
	else
		helptext; exit 1;
	fi
	fi
	shift
done

if [ $ENABLETLSMODULE -eq 1 ]; then
	echo "Enabling Apache TLS module..."
	sudo a2enmod ssl
	sudo service apache2 restart
	echo "Apache TLS module enabled."
fi

if [ $UPDATINGCERT -ne 0 ]; then
	if [ $UPDATINGCERT -ne 31 ]; then
		echo "The certificate file, the certificate key file and the certificate chain file all have to be provided."
		exit 1
	fi
		
	echo "Certificate file: $CERTFILE \(" `which $CERTFILE` "\)"
	echo "Certificate key file: $CERTKEYFILE \(" `which $CERTKEYFILE` "\)"
	echo "Certificate chain file: $CERTCHAINFILE \(" `which $CERTCHAINFILE` "\)"
	
	if [ ! $TLSCONFFILE ]; then
		export TLSCONFFILE="/etc/apache2/sites-available/default-ssl.conf"
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
	
	sed "s/SSLCertificateFile(.*)/SSLCertificateFile ${CONFCERTFILE//\//\\/}/g" $TLSCONFFILE
	sed "s/SSLCertificateKeyFile(.*)/SSLCertificateKeyFile ${CONFCERTKEYFILE//\//\\/}/g" $TLSCONFFILE
	sed "s/SSLCertificateChainFile(.*)/SSLCertificateChainFile ${CONFCERTCHAINFILE//\//\\/}/g" $TLSCONFFILE
	echo "Modifying the Apache TLS configuration file $TLSCONFFILE with the certificate"
fi
