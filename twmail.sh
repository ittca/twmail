#!/bin/bash
# explanation dns spf
#https://mailtrap.io/blog/spf-records-explained/
#mail log
# tail -f /var/log/syslog 
# tail -n 20 /var/log/syslog
# tail -n 20 -f /var/log/syslog

echo ""
echo "Enter domain:"
read domain_name
echo ""
echo "Enter email subdomain name"
read sub_domain_email

cert_path=/etc/letsencrypt/live/$sub_domain_email.$domain_name/fullchain.pem
key_path=/etc/letsencrypt/live/$sub_domain_email.$domain_name/privkey.pem

# Install Postfix and Dovecot
sudo DEBIAN_FRONTEND=noninteractive apt install -y postfix dovecot-core dovecot-imapd dovecot-pop3d net-tools
#sudo apt install -y postfix dovecot-core dovecot-imapd dovecot-pop3d net-tools
server_ip=$(ifconfig | grep -oE 'inet (addr:)?([0-9]*\.){3}[0-9]*' | awk '{print $2}' | grep -v '127.0.0.1' | head -n1)
apt remove --purge net-tools -y


# Set the hostname for the mail server
sudo postconf -e "myhostname=$sub_domain_email.$domain_name"
sudo postconf -e "mydomain=$domain_name"

# Configure Postfix for port 587 (SMTP submission)
sudo postconf -e "smtpd_tls_cert_file=$cert_path"
sudo postconf -e "smtpd_tls_key_file=$key_path"
sudo postconf -e "smtpd_tls_security_level=may"
sudo postconf -e "smtpd_tls_auth_only=yes"
sudo postconf -e "smtpd_relay_restrictions=permit_sasl_authenticated,permit_mynetworks,reject_unauth_destination"
sudo postconf -e "inet_interfaces=all"
sudo postconf -e "inet_protocols=all"
sudo postconf -e "smtpd_sasl_type=dovecot"
sudo postconf -e "smtpd_sasl_path=private/auth"
sudo postconf -e "smtpd_sasl_authenticated_header=yes"
sudo postconf -e "smtpd_sasl_local_domain="
# Update Postfix configuration for virtual users
#sudo postconf -e "virtual_mailbox_domains=$domain_name"
sudo postconf -e "virtual_mailbox_base=/var/mail/vhosts"
sudo postconf -e "virtual_mailbox_maps=hash:/var/mail/vhosts/virtual_mailbox_map"
sudo postconf -e "virtual_minimum_uid=1000"
sudo postconf -e "virtual_uid_maps=static:5000"
sudo postconf -e "virtual_gid_maps=static:5000"

#sudo sed -i 's/^smtp\s*inet\s*n\s*-\s*y\s*-\s*-\s*smtpd/#smtp      inet  n       -       y       -       -       smtpd/' /etc/postfix/master.cf
sudo sed -i 's/^#submission/submission/' /etc/postfix/master.cf
sudo sed -i 's/^#\s*-o syslog_name=postfix\/submission/  -o syslog_name=postfix\/submission/' /etc/postfix/master.cf
sudo sed -i 's/^#\s*-o smtpd_tls_security_level=encrypt/  -o smtpd_tls_security_level=encrypt/' /etc/postfix/master.cf
sudo sed -i '/^#.*submission/,/^#.*smtps/ s/^#\s*-o smtpd_sasl_auth_enable=yes/  -o smtpd_sasl_auth_enable=yes/' /etc/postfix/master.cf
sudo sed -i 's/^#\s*-o smtpd_relay_restrictions=permit_sasl_authenticated,reject/  -o smtpd_relay_restrictions=permit_mynetworks,permit_sasl_authenticated,defer/' /etc/postfix/master.cf


# Configure Dovecot for port 993 (IMAP secure)
sudo sed -i '/^  inet_listener imap {/,/^  }/ {
    s/^/#/
}' /etc/dovecot/conf.d/10-master.conf
sudo sed -i '/^ *inet_listener imaps {/,/^ *}/{ 
    s/^ *# *port = 993/    port = 993/
    s/^ *# *ssl = yes/    ssl = yes/
}' /etc/dovecot/conf.d/10-master.conf
sudo sed -i '/^  inet_listener pop3 {/,/^  }/ {
    s/^/#/
}' /etc/dovecot/conf.d/10-master.conf
sudo sed -i '/^ *inet_listener pop3s {/,/^ *}/{ 
    s/^ *# *port = 995/    port = 995/
    s/^ *# *ssl = yes/    ssl = yes/
}' /etc/dovecot/conf.d/10-master.conf
sudo sed -i '/^ *inet_listener submission {/,/^ *}/{ 
    s/^ *# *port = 587/    port = 587/
}' /etc/dovecot/conf.d/10-master.conf


# sudo sed -i 's/#ssl_listen.*/ssl_listen = imap:\/\/:993/' /etc/dovecot/conf.d/10-ssl.conf
sudo sed -i 's/ssl = yes/ssl = required/' /etc/dovecot/conf.d/10-ssl.conf
sudo sed -i "s|^ssl_cert = </etc/dovecot/private/dovecot.pem|ssl_cert = <$cert_path|" /etc/dovecot/conf.d/10-ssl.conf
sudo sed -i "s|^ssl_key = </etc/dovecot/private/dovecot.key|ssl_key = <$key_path|" /etc/dovecot/conf.d/10-ssl.conf
sudo sed -i 's/^#ssl_cipher_list = ALL:!kRSA:!SRP:!kDHd:!DSS:!aNULL:!eNULL:!EXPORT:!DES:!3DES:!MD5:!PSK:!RC4:!ADH:!LOW@STRENGTH/ssl_cipher_list = ALL:!kRSA:!SRP:!kDHd:!DSS:!aNULL:!eNULL:!EXPORT:!DES:!3DES:!MD5:!PSK:!RC4:!ADH:!LOW@STRENGTH/' /etc/dovecot/conf.d/10-ssl.conf
sudo sed -i 's/^#ssl_min_protocol = TLSv1.2/ssl_min_protocol = TLSv1.2/' /etc/dovecot/conf.d/10-ssl.conf



sudo sed -i '/^  unix_listener \/var\/spool\/postfix\/private\/auth {/,/    mode = 0666/ s/^  #}//' /etc/dovecot/conf.d/10-master.conf
sudo sed -i '/^  unix_listener \/var\/spool\/postfix\/private\/auth {/,/    mode = 0666/ s/^  #}//' /etc/dovecot/conf.d/10-master.conf
sudo sed -i '/^  unix_listener \/var\/spool\/postfix\/private\/auth {/,/    mode = 0666/ s/^  #\}//' /etc/dovecot/conf.d/10-master.conf
sudo sed -i '/^  unix_listener \/var\/spool\/postfix\/private\/auth {/,/    mode = 0666/ s/^  #}//' /etc/dovecot/conf.d/10-master.conf
sudo sed -i '/^  unix_listener \/var\/spool\/postfix\/private\/auth {/,/    mode = 0666/ s/^  #}//;/^  unix_listener \/var\/spool\/postfix\/private\/auth {/,/    mode = 0666/ s/^  #}//' /etc/dovecot/conf.d/10-master.conf
sudo sed -i 's/^  #unix_listener \/var\/spool\/postfix\/private\/auth {/  unix_listener \/var\/spool\/postfix\/private\/auth {/' /etc/dovecot/conf.d/10-master.conf
sudo sed -i '/^  unix_listener \/var\/spool\/postfix\/private\/auth {/ {n;s/^  #  mode = 0666/    mode = 0666/}' /etc/dovecot/conf.d/10-master.conf
sudo sed -i '/  unix_listener \/var\/spool\/postfix\/private\/auth {/,/  #}/ s/^  #/  /' /etc/dovecot/conf.d/10-master.conf

# Define variables
VMAIL_USER="vmail"
VMAIL_GROUP="vmail"
MAIL_STORAGE="/var/mail/vhosts"

# Create vmail group if it doesn't exist
if ! getent group "$VMAIL_GROUP" >/dev/null; then
    sudo groupadd -r "$VMAIL_GROUP"
fi

# Create vmail user if it doesn't exist
if ! id -u "$VMAIL_USER" >/dev/null 2>&1; then
    sudo useradd -r -g "$VMAIL_GROUP" -d "$MAIL_STORAGE" -s /sbin/nologin "$VMAIL_USER"
fi

# Create mail storage directory if it doesn't exist
if [ ! -d "$MAIL_STORAGE" ]; then
    sudo mkdir -p "$MAIL_STORAGE"
fi


# Set ownership to vmail user and group
sudo chown -R "$VMAIL_USER":"$VMAIL_GROUP" "$MAIL_STORAGE"

# Set appropriate permissions
sudo chmod -R 0700 "$MAIL_STORAGE"

# Set specific permissions for Dovecot
sudo chmod -R 0700 /etc/dovecot
sudo chmod 0600 /etc/dovecot/dovecot.conf

# sudo touch /var/mail/vhosts/virtual_mailbox_map

# postmap /var/mail/vhosts/virtual_mailbox_map

echo "vmail user and group created. Mail storage directory and permissions set."

# spf
apt install postfix-policyd-spf-python -y

echo "
policyd-spf_time_limit = 3600
smtpd_recipient_restrictions =
  permit_mynetworks,
  permit_sasl_authenticated,
  reject_unauth_destination,
  check_policy_service unix:private/policyd-spf" >> /etc/postfix/main.cf

echo "
policyd-spf  unix -   n   n   -   0   spawn
  user=policyd-spf argv=/usr/bin/policyd-spf" >> /etc/postfix/master.cf

#opendkim 
sudo apt-get install opendkim opendkim-tools -y

sudo opendkim-genkey -t -s $sub_domain_email -d chatdamor.pt

sudo mv $sub_domain_email.private /etc/postfix/dkim.key
sudo mv $sub_domain_email.txt /etc/postfix/dkim.txt


sudo postconf -e "milter_default_action=accept"
sudo postconf -e "milter_protocol=6"
sudo postconf -e "smtpd_milters=inet:localhost:8891"
sudo postconf -e "non_smtpd_milters=inet:localhost:8891"
sudo sed -i 's/^Socket[[:space:]]*local:\/run\/opendkim\/opendkim\.sock/#&/' /etc/opendkim.conf
sudo sed -i 's/^#Socket[[:space:]]*inet:8891@localhost/Socket\t\t\tinet:8891@localhost/' /etc/opendkim.conf


echo "
KeyTable            refile:/etc/opendkim/key.table
SigningTable        refile:/etc/opendkim/signing.table" >> /etc/opendkim.conf

mkdir /etc/opendkim
sudo touch /etc/opendkim/signing.table
sudo touch /etc/opendkim/key.table
sudo chown -R opendkim:opendkim /etc/opendkim
sudo chmod -R 640 /etc/opendkim

echo "restarting opendkim"
sudo systemctl restart opendkim

# sudo nano /lib/systemd/system/opendkim.service
# Restart=always
# RestartSec=3
# sudo systemctl daemon-reload
# sudo systemctl restart opendkim

echo "restarting postfix..."
sudo systemctl restart postfix
echo "restarting dovecot..."
sudo systemctl restart dovecot
sudo systemctl status postfix
sudo systemctl status dovecot
sudo systemctl status opendkim


# DNS records
echo "\nDNS records\n"
echo -e "\e[32m@    A    $server_ip\n"
echo -e "$sub_domain_email    A    $server_ip\n"
echo -e "@    MX    10    $sub_domain_email.$domain_name\n"
first_output=$(grep "$sub_domain_email._domainkey" /etc/postfix/dkim.txt | awk '{print $1,$3}')
second_output=$(sed -n 's/^.*"\(.*\)".*$/\1/; s/;\s*/; /g; s/ //g; p' /etc/postfix/dkim.txt | tr -d '\n')
echo -e "$first_output $second_output\n"
echo -e "@    TXT    v=spf1 a mx ip4:$server_ip\n"
echo -e "_dmarc    TXT    v=DMARC1; p=none; pct=100; fo=1; rua=mailto:support@$domain_name\e[0m\n"


#mail log
# tail -f /var/log/syslog 
# tail -n 20 /var/log/syslog
# tail -n 20 -f /var/log/syslog
# lsof -i -P -n | grep LISTEN
# netstat  -antp   # 110 143 25

sudo cp /etc/aliases.dist /etc/aliases
echo "root:   support@$domain_name" > /etc/aliases
sudo newaliases
