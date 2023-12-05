#!/bin/bash

echo ""
echo "Enter domain:"
read domain_name
echo ""
echo "Enter user name"
read user_name
echo ""
echo "Enter password"
read password


# Create a system user
sudo adduser $user_name --disabled-password --gecos ""

# Set a password for the user
echo "$user_name:$password" | sudo chpasswd

# Set mailbox path
sudo mkdir -p /var/mail/vhosts/$domain_name/$user_name
sudo chown -R $user_name:$user_name /var/mail/vhosts/$domain_name/$user_name
sudo chmod -R 700 /var/mail/vhosts/$domain_name/$user_name

# Add the user to the virtual mail users map
sudo sh -c "echo '$user_name@$domain_name $user_name' >> /var/mail/vhosts/virtual_mailbox_map"
sudo postmap /var/mail/vhosts/virtual_mailbox_map

echo ""
echo "Email user $user_name@$domain_name has been created succefully"
echo ""
