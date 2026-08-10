#!/bin/bash

apt-get update
apt-get install python3-acme python3-certbot python3-mock python3-openssl python3-pkg-resources python3-pyparsing python3-zope.interface -y

apt-get install python3-certbot-nginx nginx -y

certbot --nginx -d $1
