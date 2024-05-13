#!/bin/bash
#https://github.com/cisagov/postfix-docker/blob/develop/src/docker-entrypoint.sh


#generate confifunction
function generate_configs () {
  #put in the env variables
  echo "Generate postfix configurations for ${SERVER_HOSTNAME}"
  envsubst '\$SERVER_HOSTNAME \$SERVER_IP' < src/postfix/main.cf > /etc/postfix/main.cf
  envsubst '\$SERVER_HOSTNAME \$SERVER_IP' < src/opendkim/opendkim.conf > /etc/opendkim.conf

  # generate opendkim
  echo "Generate opendkim configurations for ${SERVER_HOSTNAME}"
  mkdir -p /etc/opendkim/keys
  chown -R opendkim:opendkim /etc/opendkim
  mkdir -p "/etc/opendkim/keys/${SERVER_HOSTNAME}"
  opendkim-genkey -b 2048 -d ${SERVER_HOSTNAME} -D /etc/opendkim/keys/${SERVER_HOSTNAME} -s default -v
  envsubst '\$SERVER_HOSTNAME \$SERVER_IP' < src/opendkim/trusted.hosts > /etc/opendkim/trusted.hosts 
  # Change Permission for the keys
  #add keytable
  
  echo "default._domainkey.$user_hostname    $user_hostname:default:/etc/opendkim/keys/$user_hostname/default.private" | sudo tee /etc/opendkim/key.table > /dev/null

  chown opendkim:opendkim /etc/opendkim/keys/${SERVER_HOSTNAME}/default.private
  edit_signing_table

 # generate opendmarc
  echo "Generate opendmarc configurations for ${SERVER_HOSTNAME}"
  envsubst '\$SERVER_HOSTNAME \$SERVER_IP' < src/opendmarc/opendmarc.conf > /etc/opendmarc.conf 
  mkdir -p "/etc/opendmarc"
  echo "localhost" > /etc/opendmarc/ignore.hosts
  chown -R opendmarc:opendmarc /etc/opendmarc

  # configure dovecot
  echo "Generating dovecot configurations for ${SERVER_HOSTNAME}"
  envsubst '\$SERVER_HOSTNAME \$SERVER_IP' < src/dovecot/dovecot.conf > /etc/dovecot/dovecot.conf

  # create a file marking the configuration as completed for this domain
  echo "All configurations generated for ${SERVER_HOSTNAME}"

  mkdir /var/spool/postfix/opendkim/ 
  mkdir /var/spool/postfix/opendmarc/ 
  chown -R opendkim:opendkim /var/spool/postfix/opendkim
  chown -R opendmarc:opendmarc /var/spool/postfix/opendmarc

}

function edit_signing_table (){
    #Edit signing.table
    echo "*@$SERVER_HOSTNAME default._domainkey.$SERVER_HOSTNAME" | sudo tee /etc/opendkim/signing.table > /dev/null
    echo "*@*.$SERVER_HOSTNAME default._domainkey.$SERVER_HOSTNAME" | sudo tee /etc/opendkim/signing.table > /dev/null

}

# Check if running script is running as root
function check_root () {
    if [[ $(id -u) != "0" ]]; then
        echo "Error: Script must be run as root or with sudo!"
        exit 1
    fi
}


function output_keys (){
    echo "-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-"
    echo "Place the following output as the DKIM key in your DNS server, note that formatting may differ depending on DNS provider"
    cat /etc/opendkim/keys/$SERVER_HOSTNAME/default.txt | awk -F'"' '{print $2}' | tr -d '[:space:]'
    echo "Add this as a new TXT record where the Record name is default._domainkey.$SERVER_HOSTNAME"
    echo "File as is:"
    cat /etc/opendkim/keys/$SERVER_HOSTNAME/default.txt

    echo

    echo "Place the following output as the DMARC key in your DNS server"
    echo "v=DMARC1; p=reject; rua=mailto:mailarchive@$SERVER_HOSTNAME"
    echo "Add this as a new TXT record where the Record name is _dmarc.$SERVER_HOSTNAME"
    echo

    echo "Place the following output as the MX (Mailserver) value in your DNS server"
    echo "10 $SERVER_HOSTNAME"
    echo "Add this as a new MX record where the Record name is $SERVER_HOSTNAME"

    echo "Add an SPF record"
    public_ip=$(curl -s ifconfig.me) && echo "v=spf1 mx ip4:$SERVER_IP -all" 
    echo "Add this as a new TXT record where the Record name is $SERVER_HOSTNAME"

    echo "-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-"
   
}

function generate_users () {
  echo "Generating users and passwords:"
  echo "--------------------------------------------"
  while IFS=" " read -r username password || [ -n "$username" ]; do
    if [ -z "$password" ]; then
      password=$(diceware -d-)
      echo -e "$username\t$password"
    else
      echo -e "$username\t<set by secrets file>"
    fi
    adduser "$username" --quiet --disabled-password --shell /usr/sbin/nologin --gecos "" --force-badname || true
    echo "$username:$password" | chpasswd || true
  done
  echo "--------------------------------------------"
}

if [ "$1" = 'postfix' ]; then

  check_root

  echo "Starting mail server with:"
  echo "  SERVER_HOSTNAME=${SERVER_HOSTNAME}"
  echo "  RELAY_IP=${SERVER_IP}"

  # check to see if the configuration was completed for this domain
  if [[ ! -f conf_gen_done.txt ]] || [[ $(< conf_gen_done.txt) != "${SERVER_HOSTNAME}" ]]; then
    generate_configs
    echo "${SERVER_HOSTNAME}" > conf_gen_done.txt
  else
    echo "Configurations already generated for ${SERVER_HOSTNAME}, preserving."
  fi

  # generate the users from the secrets
  grep -v '^#\|^$' src/user.txt | generate_users

  # postfix needs fresh copies of files in its chroot jail
  cp /etc/{hosts,localtime,nsswitch.conf,resolv.conf,services} /var/spool/postfix/etc/

 
  opendmarc
  opendkim
  dovecot
  echo "DKIM DNS entry:"
  output_keys

  exec "$@"
fi

exec "$@"



