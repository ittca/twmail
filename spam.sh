sudo apt-get install spamassassin spamc -y

sudo systemctl enable spamassassin
sudo systemctl start spamassassin


# sudo nano /etc/spamassassin/local.cf

echo "
spamassassin unix - n n - - pipe flags=R user=spamd argv=/usr/bin/spamc -e /usr/sbin/sendmail -oi -f \${sender} \${recipient}
" >> /etc/postfix/master.cf

sudo systemctl restart postfix

echo "
header_checks = regexp:/etc/postfix/header_checks" >> /etc/postfix/main.cf

echo "/^Subject:.*SPAM\{/ FILTER spamassassin:[127.0.0.1]:10025" > /etc/postfix/header_checks

sudo systemctl restart postfix

echo "plugin {
  sieve_before = /var/mail/sieve/spam-global.sieve
}
" > /etc/dovecot/conf.d/99-spamassassin.conf

sudo mkdir /var/mail/sieve
sudo touch /var/mail/sieve/spam-global.sieve

sudo systemctl restart dovecot

# spam string to send on the email body
# XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X
