# twmail
email server  for servers, it needs a domain to work with

version 1.1 

This version is expecting to have already a domain for the email using nginx and already with ssl
tested with ubuntu vps
Not production ready, but its working


nginx           ok
postfix         ok
dovecot         ok
spf             ok
dkim            ok
_dmarc          ok
spamassassin    ok

to install directly use the command 

curl -LO https://raw.githubusercontent.com/ittca/twmail/main/twmail.sh && sh twmail.sh
