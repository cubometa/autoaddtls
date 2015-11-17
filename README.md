# AutoAddTLS
Cubometa AutoAddTLS automates enabling and configuring TLS, HSTS and related settings in an Apache server.
The current version, version 1.1.3, should work correctly on recent Linux operating systems which have Apache 2 installed.

## Features
* Enable the Apache SSL/TLS module.
* Install a new TLS certificate.
* Enable the HSTS header (including `includeSubDomains` and `preload`).

## Projected features
* Modify and disable the HSTS header.
* Enable, modify and disable the HPKP header.
* Disable the Apache SSL/TLS module.
* Remove an installed TLS certificate.
* Redirect (301) HTTP requests to HTTPS for browsers that accept it.
