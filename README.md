# AutoAddTLS
Cubometa AutoAddTLS automates enabling and configuring TLS, HSTS and related settings in an Apache server.
The current version, version 1.1.5, should work correctly on recent Linux operating systems which have Apache 2 installed.

## Features
* Enable and disable the Apache SSL/TLS module.
* Install a new TLS certificate.
* Enable, modify or disable the HSTS header (including `includeSubDomains` and `preload`).

## Projected features
* Modify parts of the HSTS header.
* Enable, modify and disable the HPKP header.
* Remove an installed TLS certificate.
* Redirect (301) HTTP requests to HTTPS for browsers that accept it.
