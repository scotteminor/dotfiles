#!/bin/bash


# -- This build script should be run as root.
DNF_UPDATE=1

[[ $(id -u) -eq 0 ]] && SUDO='' || SUDO='sudo'

HARDING_DATE_TIME=$(date +%Y%m%d%H%M%S)
export AUDIT_DIR="/tmp/$(hostname -s)_audit_$HARDING_DATE_TIME"
export AUDIT_LOG=$AUDIT_DIR/audit.$HARDING_DATE_TIME.log

# -- Create the audit directory
mkdir -pv $AUDIT_DIR

touch $AUDIT_LOG
echo "Audit / Hardening Started: $(date +'%y-%m-%d %H:%M:%S %:z')" >> $AUDIT_LOG

# -- US-WEST - Add 10.245.117.196 usoh3plsat3.cxloyalty.com to /etc/hosts

if [[ $DNF_UPDATE -ne 0 ]]; then
    #$SUDO yum install -y --nogpgcheck http://usoh1plsat3.cxloyalty.com/pub/katello-ca-consumer-latest.noarch.rpm
    #$SUDO yum install -y --nogpgcheck katello-ca-consumer-awsva1plsat01.cxloyalty.com-1.0-2.noarch
    #$SUDO subscription-manager remove --all
    #$SUDO subscription-manager unregister

    # -- Clwan all the repo
    $SUDO subscription-manager clean
    $SUDO subscription-manager config --rhsm.manage_repos=1

    REGION=$(aws configure get region)

    $SUDO dnf clean all

    if [[ $REGION == 'us-east-1' ]]; then
        #install -y --nogpgcheck http://awsva1plsat01.cxloyalty.com/pub/katello-ca-consumer-latest.noarch.rpm
        $SUDO dnf install -y --nogpgcheck http://usoh1plsat3.cxloyalty.com/pub/katello-ca-consumer-latest.noarch.rpm
    fi
    # -- One or the other
    #$SUDO subscription-manager register --org="cxloyalty" --activationkey="RHEL_8_AWS_Prod" --force
    #$SUDO subscription-manager register --org="cxloyalty" --activationkey="RHEL_8_AWS_NonProd" --force

    # -- Install Amazon System Manager
    $SUDO dnf install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
    $SUDO systemctl enable amazon-ssm-agent
    $SUDO systemctl start amazon-ssm-agent

    #https://rpmfind.net/linux/fedora/linux/development/rawhide/Everything/x86_64/os/Packages/r/rcs-5.10.1-10.fc42.x86_64.rpm

    # -- No reason to get an update each time it installs
    dnfOptions="--assumeyes"
    # -- Make sure tmux is installed
    $SUDO dnf install tmux "$dnfOptions"
    #$SUDO dnf install tmate "$dnfOptions"    // --??????

    $SUDO dnf install rsync "$dnfOptions"
    $SUDO dnf install vim "$dnfOptions"
    $SUDO dnf install jq "$dnfOptions"
    $SUDO dnf install nvme-cli "$dnfOptions"
    $SUDO dnf install nmap "$dnfOptions"
    $SUDO dnf install bat "$dnfOptions"
    #$SUDO dnf install tldr "$dnfOptions"
    #$SUDO dnf install btop "$dnfOptions"

    $SUDO dnf reinstall openssl "$dnfOptions"
fi

# -- replaced with GitHub
#RCS_FILE=rcs-5.10.1-3.el8.x86_64.rpm
#curl https://archive.fedoraproject.org/pub/archive/epel/8.7/Everything/x86_64/Packages/r/$RCS_FILE --output $RCS_FILE
#if [[ -f $RCS_FILE ]]; then
#  $SUDO dnf install -y $RCS_FILE
#  rm -f $RCS_FILE
#fi

#
#
#!/bin/bash

# -- Disable ctrl-alt-delete
systemctl disable --now ctrl-alt-del.target
systemctl mask --now ctrl-alt-del.target

# --  Fluentd Based Datya Collector
systemctl stop td-agent
systemctl disable td-agent

# -- Log all sudo commands
SUDO_DEFAULT=/etc/sudoers.d/01-defaults
cat <<EOT >>$SUDO_DEFAULT

# Log all sudo commands run
Defaults logfile=/var/log/sudo.log

EOT

chmod 440 $SUDO_DEFAULT

#systemctl stop firewalld
#systemctl disable firewalld
l_fwd_status=""
l_firewall_rpm_installed=$(rpm -q firewalld | wc -l)

if [ "$l_firewall_rpm_installed" -eq 0 ]; then
    [[ $DNF_UPDATE -ne 0 ]] && $SUDO dnf install firewalld -y
    $SUDO systemctl enable firewalld
    $SUDO systemctl start firewalld
else
    echo -e " -- Firewall Already Installed --"
fi

l_fwd_status="$(systemctl is-enabled firewalld.service):$(systemctl is-active firewalld.service)"

case $l_fwd_status in

"enabled:active")
    # -- add ports needed for the backup
    for port in 1556 13720 13724 13782; do
        #echo 'Port: ' $port
        $SUDO firewall-cmd --permanent --add-port=$port/tcp
    done

    # -- Add 80, 443 and 514 to the firewall
    for port in 80 443 514; do
        $SUDO firewall-cmd --permanent --add-port=$port/tcp
    done

    # -- syslog ports
    #$SUDO firewall-cmd --permanent --add-port=514/tcp
    #$SUDO firewall-cmd --permanent --add-port=514/udp

    # -- Needed for trend
    #$SUDO firewall-cmd --permanent --add-port=443/tcp
    #$SUDO firewall-cmd --permanent --add-service=https

    # -- Needed for DUO
    #$SUDO firewall-cmd --permanent --add-port=80/tcp
    #$SUDO firewall-cmd --permanent --add-service=http

    for service in cockpit dhcpv6-client; do
        #echo 'Service: ' $service
        $SUDO firewall-cmd --permanent --remove-service=$service
    done

    $SUDO firewall-cmd --set-log-denied=all

    $SUDO firewall-cmd --reload

    # -- Stop nftables and mask nftables
    $SUDO systemctl stop nftables 
    $SUDO systemctl --now mask nftables
    ;;

*)
    echo -e " - FirewallD is not installed or not started."
    ;;

esac

# -- Check for ds_agent issues
if [[ ! -d '/opt/ds_agent/4.18.0-513.18.1.el8_9.x86_64' ]]; then
    rm -rf '/usr/lib/modules/4.18.0-513.18.1.el8_9.x86_64'
fi

# -- Update the cron.d directory and settings
for value in cron.d cron.hourly cron.daily cron.weekly cron.monthly; do
    echo -e "Changing /etc/$value"
    chown root:root /etc/$value
    chmod 600 /etc/$value
done

chmod 700 /etc/cron.d

#
# -- Alias this commands
cat <<EOF >>/etc/bashrc

alias rm='rm -i --preserve-root'
alias dd='echo "dd command is not available"'
alias chmod='chmod --preserve-root'

EOF

#
# -- SSH Updates
#
echo "Creating login notification"
cat <<EOT >/etc/issue.net

################################################################################

                            Authorized Uses Only

                            PROPRIETARY INFORMATION

  All content of this system and its associated sub-systems are PROPRIETARY
  INFORMATION and remain the sole and exclusive property of this company.

  This system may be accessed and used by authorized personnel only.

  Authorized users may only perform authorized activities and may not exceed
  the limits of such authorization. Disclosure of information found in this
  system for any unauthorized use is *STRICTLY PROHIBITED*.

  All activities on this system are subject to monitoring. Intentional misuse
  of this system   can result in disciplinary action or criminal prosecution.

################################################################################

EOT

ln -fs /etc/issue.net /etc/issue

# -- Update the message of the day
cat <<EOT >/etc/motd

Authorized users only. All activity may be monitored and reported.

EOT

chmod 644 /etc/motd

#
# -- Changes to SSH
SSH_DIR=/etc/ssh

cp -f $SSH_DIR/sshd_config $SSH_DIR/sshd_config."$HARDING_DATE_TIME"
cp -f $SSH_DIR/sshd_config "$AUDIT_DIR/sshd_config.$HARDING_DATE_TIME"

grep 'Banner' $SSH_DIR/sshd_config
if [ $? -ne 1 ]; then
    sed -i -e '/#\?Banner/{x;/^$/!d;g;}' -e 's/[^Banner]*\(Banner.*\)/\1/' $SSH_DIR/sshd_config
    sed -i '/Banner/s/^/#/' $SSH_DIR/sshd_config
fi
sed -i '/#Banner/a\Banner /etc/issue.net' $SSH_DIR/sshd_config

VAL_LOOKUP="UseDNS"
grep "$VAL_LOOKUP" $SSH_DIR/sshd_config
if [ $? -ne 1 ]; then
    sed -i -e '/#\?'$VAL_LOOKUP'/{x;/^$/!d;g;}' -e 's/[^'$VAL_LOOKUP']*\('$VAL_LOOKUP'.*\)/\1/' $SSH_DIR/sshd_config
    sed -i '/'$VAL_LOOKUP'/s/^/#/' $SSH_DIR/sshd_config
fi
# shellcheck disable=SC1003
sed -i '/#'$VAL_LOOKUP'/a\'$VAL_LOOKUP' no' $SSH_DIR/sshd_config

grep 'GSSAPIAuthentication' $SSH_DIR/sshd_config
if [ $? -ne 1 ]; then
    sed -i '/#\?GSSAPIAuthentication/{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/GSSAPIAuthentication/s/^/#/' $SSH_DIR/sshd_config
fi
sed -i '/#GSSAPIAuthentication/a\GSSAPIAuthentication no' $SSH_DIR/sshd_config

grep 'AllowTcpForwarding' $SSH_DIR/sshd_config
if [ $? -ne 1 ]; then
    sed -i '/#\?AllowTcpForwarding/{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/AllowTcpForwarding/s/^/#/' $SSH_DIR/sshd_config
fi
sed -i '/#AllowTcpForwarding/a\AllowTcpForwarding no' $SSH_DIR/sshd_config

grep 'ClientAliveCountMax' $SSH_DIR/sshd_config
if [ $? -ne 1 ]; then
    sed -i '/#\?ClientAliveCountMax/{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/ClientAliveCountMax/s/^/#/' $SSH_DIR/sshd_config
fi
sed -i '/#ClientAliveCountMax/a\ClientAliveCountMax 2' $SSH_DIR/sshd_config

grep 'ClientAliveInterval' $SSH_DIR/sshd_config
if [ $? -ne 1 ]; then
    sed -i '/#\?ClientAliveInterval/{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/ClientAliveInterval/s/^/#/' $SSH_DIR/sshd_config
fi
sed -i '/#ClientAliveInterval/a\ClientAliveInterval 900' $SSH_DIR/sshd_config

grep 'Compression' $SSH_DIR/sshd_config
if [ $? -ne 1 ]; then
    sed -i '/#\?Compression/{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/Compression/s/^/#/' $SSH_DIR/sshd_config
fi
sed -i '/#Compression/a\Compression no' $SSH_DIR/sshd_config

grep 'MaxAuthTries' $SSH_DIR/sshd_config
if [ $? -ne 1 ]; then
    sed -i '/#\?MaxAuthTries/{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/MaxAuthTries/s/^/#/' $SSH_DIR/sshd_config
fi
sed -i '/#MaxAuthTries/a\MaxAuthTries 3' $SSH_DIR/sshd_config

grep 'MaxSessions' $SSH_DIR/sshd_config
if [ $? -ne 1 ]; then
    sed -i '/#\?MaxSessions/{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/MaxSessions/s/^/#/' $SSH_DIR/sshd_config
fi
sed -i '/#MaxSessions/a\MaxSessions 5' $SSH_DIR/sshd_config

grep 'PermitTunnel' $SSH_DIR/sshd_config
if [ $? -ne 1 ]; then
    sed -i '/#\?PermitTunnel/{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/PermitTunnel/s/^/#/' $SSH_DIR/sshd_config
fi
sed -i '/#PermitTunnel/a\PermitTunnel no' $SSH_DIR/sshd_config

grep 'X11Forwarding' $SSH_DIR/sshd_config
if [ $? -ne 1 ]; then
    sed -i '/#\?X11Forwarding/{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/X11Forwarding/s/^/#/' $SSH_DIR/sshd_config
fi
sed -i '/#X11Forwarding/a\X11Forwarding no' $SSH_DIR/sshd_config

# -- enabling this will cause the user to not be able to forward the private key to the client
# -- Not recommended to be set to 'no'
#grep 'AllowAgentForwarding no' $SSH_DIR/sshd_config
#if [ $? -ne 1 ]; then
#  sed -i '/#\?AllowAgentForwarding/{x;/^$/!d;g;}' $SSH_DIR/sshd_config;
#  sed -i '/AllowAgentForwarding/s/^/#/' $SSH_DIR/sshd_config;
#fi
#sed -i '/#AllowAgentForwarding/a\AllowAgentForwarding no' $SSH_DIR/sshd_config

grep 'FingerprintHash' $SSH_DIR/sshd_config
if [ $? -ne 1 ]; then
    sed -i '/#\?FingerprintHash/{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/FingerprintHash/s/^/#/' $SSH_DIR/sshd_config
fi
echo -e "\nFingerprintHash sha256\n" >>$SSH_DIR/sshd_config

grep 'IgnoreRhosts' $SSH_DIR/sshd_config
if [ $? -ne 1 ]; then
    sed -i '/#\?IgnoreRhosts/{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/IgnoreRhosts/s/^/#/' $SSH_DIR/sshd_config
fi
sed -i '/#IgnoreRhosts/a\IgnoreRhosts yes' $SSH_DIR/sshd_config

grep 'HostbasedAuthentication' $SSH_DIR/sshd_config
if [ $? -ne 1 ]; then
    sed -i '/#\?HostbasedAuthentication/{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/HostbasedAuthentication/s/^/#/' $SSH_DIR/sshd_config
fi
sed -i '/#HostbasedAuthentication/a\HostbasedAuthentication no' $SSH_DIR/sshd_config

grep 'PermitRootLogin' $SSH_DIR/sshd_config
if [ $? -ne 1 ]; then
    sed -i '/#\?PermitRootLogin/{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/PermitRootLogin/s/^/#/' $SSH_DIR/sshd_config
fi
sed -i '/#PermitRootLogin/a\PermitRootLogin no' $SSH_DIR/sshd_config

grep 'PermitEmptyPasswords' $SSH_DIR/sshd_config
if [ $? -ne 1 ]; then
    sed -i '/#\?PermitEmptyPasswords/{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/PermitEmptyPasswords/s/^/#/' $SSH_DIR/sshd_config
fi
sed -i '/#PermitEmptyPasswords/a\PermitEmptyPasswords no' $SSH_DIR/sshd_config

grep 'PermitUserEnvironment' $SSH_DIR/sshd_config
if [ $? -ne 1 ]; then
    sed -i '/#\?PermitUserEnvironment/{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/PermitUserEnvironment/s/^/#/' $SSH_DIR/sshd_config
fi
sed -i '/#PermitUserEnvironment/a\PermitUserEnvironment no' $SSH_DIR/sshd_config

grep 'AllowUsers' $SSH_DIR/sshd_config
if [ $? -ne 1 ]; then
    sed -i '/#\?AllowUsers/{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/AllowUsers/s/^/#/' $SSH_DIR/sshd_config
fi

grep 'Protocol' $SSH_DIR/sshd_config
if [ $? -ne 1 ]; then
    sed -i '/#Protocol/{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/Protocol/s/^/#/' $SSH_DIR/sshd_config
fi
sed -i '/#ListenAddress ::/a\Protocol 2' $SSH_DIR/sshd_config

grep 'PubkeyAuthentication' $SSH_DIR/sshd_config
if [ $? -ne 1 ]; then
    sed -i '/#\?PubkeyAuthentication/{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/PubkeyAuthentication/s/^/#/' $SSH_DIR/sshd_config
fi
sed -i '/#PubkeyAuthentication/a\PubkeyAuthentication yes' $SSH_DIR/sshd_config

grep 'PasswordAuthentication' $SSH_DIR/sshd_config
if [ $? -ne 1 ]; then
    sed -i '/#\?PasswordAuthentication/{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/PasswordAuthentication/s/^/#/' $SSH_DIR/sshd_config
fi
sed -i '/#PasswordAuthentication/a\PasswordAuthentication no' $SSH_DIR/sshd_config

grep 'GatewayPorts' $SSH_DIR/sshd_config
if [ $? -ne 1 ]; then
    sed -i '/#\?GatewayPorts/{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/GatewayPorts/s/^/#/' $SSH_DIR/sshd_config
fi
sed -i '/#GatewayPorts/a\GatewayPorts no' $SSH_DIR/sshd_config

grep "LogLevel" $SSH_DIR/sshd_config
if [[ $? -ne 1 ]]; then
    sed -i '/#\?LogLevel/{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/LogLevel/s/^/#/' $SSH_DIR/sshd_config
fi
sed -i '/#LogLevel/a\LogLevel INFO' $SSH_DIR/sshd_config

# -- Add these MAC types
#echo -e "\nMACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256\n" >> $SSH_DIR/sshd_config

grep 'MACs ' $SSH_DIR/sshd_config
if [ $? -ne 1 ]; then
    sed -i '/#\?MACs /{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/MACs /s/^/#/' $SSH_DIR/sshd_config
    sed -i '/#MACs /a\MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-512' $SSH_DIR/sshd_config
else
    echo -e "MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-512" >>$SSH_DIR/sshd_config
fi
#sed -i '/#MACs /a\MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-512' $SSH_DIR/sshd_config

grep 'KexAlgorithms ' $SSH_DIR/sshd_config
if [ $? -ne 1 ]; then
    sed -i '/#\?KexAlgorithms /{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/KexAlgorithms /s/^/#/' $SSH_DIR/sshd_config
fi
kexAlgorithms='curve25519-sha256,curve25519-sha256@libssh.org,ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,diffie-hellman-group-exchange-sha256,diffie-hellman-group14-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha1,diffie-hellman-group14-sha1'
sed -i '/#KexAlgorithms /a\KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp521' $SSH_DIR/sshd_config
#sed -i '/#KexAlgorithms /a\KexAlgorithms ${kexAlgorithms}' $SSH_DIR/sshd_config

#sed -i '/# Ciphers /a\Ciphers aes256-gcm@openssh.com,aes256-ctr' $SSH_DIR/sshd_config
grep 'Ciphers ' $SSH_DIR/sshd_config
if [[ $? -ne 1 ]]; then
    sed -i '/#\?Ciphers /{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/Ciphers /s/^/#/' $SSH_DIR/sshd_config
fi
sed -i '/# Ciphers /a\Ciphers aes128-ctr,aes192-ctr,aes256-ctr' $SSH_DIR/sshd_config
#sed -i '/# Ciphers /a\Ciphers aes256-gcm@openssh.com,aes256-ctr' $SSH_DIR/sshd_config

#
#
# 0-- Added 2026-02-25 - RHEL8_Lockdown
grep 'MaxStartups ' $SSH_DIR/sshd_config
if [[ $? -ne 1 ]]; then
    sed -i '/#\?MaxStartups /{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/MaxStartups /s/^/#/' $SSH_DIR/sshd_config
fi
sed -i '/#MaxStartups /a\MaxStartups 10:30:60' $SSH_DIR/sshd_config

#grep 'LoginGraceTime ' $SSH_DIR/sshd_config
#if [[ $? -ne 1 ]]; then
#    sed -i '/#\?LoginGraceTime /{x;/^$/!d;g;}' $SSH_DIR/sshd_config
#    sed -i '/LoginGraceTime /s/^/#/' $SSH_DIR/sshd_config
#fi
#sed -i '/#LoginGraceTime /a\LoginGraceTime 60' $SSH_DIR/sshd_config

#
#grep 'UsePAM ' $SSH_DIR/sshd_config
#if [[ $? -ne 1 ]]; then
#    sed -i '/#\?UsePAM /{x;/^$/!d;g;}' $SSH_DIR/sshd_config
#    sed -i '/UsePAM /s/^/#/' $SSH_DIR/sshd_config
#fi
#sed -i '/#UsePAM /a\UsePAM yes' $SSH_DIR/sshd_config
#sed -i '/#UsePAM /a\UsePAM no' $SSH_DIR/sshd_config

#
#grep 'ChallengeResponseAuthentication ' $SSH_DIR/sshd_config
#if [[ $? -ne 1 ]]; then
#    sed -i '/#\?ChallengeResponseAuthentication /{x;/^$/!d;g;}' $SSH_DIR/sshd_config
#    sed -i '/ ChallengeResponseAuthentication /s/^/#/' $SSH_DIR/sshd_config
#fi
#sed -i '/#ChallengeResponseAuthentication /a\ChallengeResponseAuthentication no' $SSH_DIR/sshd_config

#
chmod 600 $SSH_DIR/sshd_config
chown root:root $SSH_DIR/sshd_config

if [ -d $SSH_DIR/ssh_config.d ]; then
    chmod 644 $SSH_DIR/ssh_config.d/*.conf
    chown root:root $SSH_DIR/ssh_config.d/*
    echo "Changing permissions"
else
    echo "Directory not found"
fi

###. Regenerate RSA / ED25519 Host Keys ###############

#rm -f $SSH_DIR/ssh_host_*
find $SSH_DIR ! -name 'ssh_host_rsa*' ! -name 'ssh_host_ed25519*' -name 'ssh_host_*' -type f -exec rm -f {} \;
#ssh-keygen -t rsa -b 4096 -f $SSH_DIR/ssh_host_rsa_key -N ""
#ssh-keygen -t ed25519 -f $SSH_DIR/ssh_host_ed25519_key -N ""
#ssh-keygen -t ecdsa -b 521 -f $SSH_DIR/ssh_host_ecdsa_key -N ""

chown root:ssh_keys $SSH_DIR/ssh_host_*_key
chmod 600 $SSH_DIR/ssh_host_*_key
chmod 644 $SSH_DIR/ssh_host_*_key.pub

# -- this shouldn't be in the file
grep 'ssh_host_dsa_key' $SSH_DIR/sshd_config
if [ $? -ne 1 ]; then
    sed -i '/#\?ssh_host_dsa_key/{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/ssh_host_dsa_key/s/^/#/' $SSH_DIR/sshd_config
fi

grep 'ssh_host_ecdsa_key' $SSH_DIR/sshd_config
if [ $? -ne 1 ]; then
    sed -i '/#\?ssh_host_ecdsa_key/{x;/^$/!d;g;}' $SSH_DIR/sshd_config
    sed -i '/ssh_host_ecdsa_key/s/^/#/' $SSH_DIR/sshd_config
fi

[[ -f "$SSH_DIR/ssh_host_ed25519_key" ]] && chmod 640 "$SSH_DIR/ssh_host_ed25519_key"
[[ -f "$SSH_DIR/ssh_host_rsa_key" ]] && chmod 640 "$SSH_DIR/ssh_host_rsa_key"

###  Disable Small Diffie-Hellman Key Size  #############

cp -f $SSH_DIR/moduli $SSH_DIR/moduli."$HARDING_DATE_TIME"
[[ -d $AUDIT_DIR ]] && cp -f $SSH_DIR/moduli $AUDIT_DIR/moduli."$HARDING_DATE_TIME"

awk '$5 >= 3071' $SSH_DIR/moduli >$SSH_DIR/moduli.safe
mv -f $SSH_DIR/moduli.safe $SSH_DIR/moduli

chmod 640 $SSH_DIR/moduli

####  Restrict key exchange, cipher and MAC algorithms  ####

CRYPTO_POLICY_DIR=/etc/crypto-policies/back-ends/
cp $CRYPTO_POLICY_DIR/opensshserver.config $CRYPTO_POLICY_DIR/opensshserver.config."$HARDING_DATE_TIME"
[[ -d $AUDIT_DIR ]] && cp $CRYPTO_POLICY_DIR/opensshserver.config $AUDIT_DIR/opensshserver.config."$HARDING_DATE_TIME"

echo -e "CRYPTO_POLICY='-oCiphers=chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr -oMACs=hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com -oGSSAPIKexAlgorithms=gss-curve25519-sha256- -oKexAlgorithms=curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256 -oHostKeyAlgorithms=ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-256,rsa-sha2-512 -oPubkeyAcceptedKeyTypes=ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-256,rsa-sha2-512'" >$CRYPTO_POLICY_DIR/opensshserver.config

#### Restart SSH Service ####

systemctl restart sshd

#######################################
# -- Fix ansible account
ANSIBLE_HOME=/home/svc_ansible
$SUDO chown svc_ansible: $ANSIBLE_HOME/.ssh -R
grep 'svc_ansible@usoh2plans1.cxloyalty.com' $ANSIBLE_HOME/.ssh/authorized_keys
#if [ $? -ne 0 ]; then
if [ "$(grep 'svc_ansible@usoh2plans1.cxloyalty.com' $ANSIBLE_HOME/.ssh/authorized_keys)" -ne 0 ]; then
    $SUDO echo -e "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQConbaVW0TLV3CGsV4wW3k665r8vkm8V50Whpn0HIHJwyr8nH0RI4LT8HrFQAt3Bc9+cxanfG2+GPPcssXw046VJWlwgKk62Qj1eDVAFCH/qqq3Mq93wcJq+EH2RPI81hyh9QdA0saZmVJg24Ttt6zVcHPjIshvl0Io7QSpXJ+7dteaQVBmseStRHsw2EIT+XBHgnvAPW82dQKjyLKc5jWU6Xq72lMU0FtgtB9zH32NtRb7PA69VyHeB46oBmJRDFIZsgsuGSxugsKVUfgYXylx+KFKTo+XkdDifn7A73dbA+2m3Qrk6EzmWk+WWvothMvgcKSVgE7SxkYFO1vI19CV svc_ansible@usoh2plans1.cxloyalty.com" >>$ANSIBLE_HOME/.ssh/authorized_keys
fi
$SUDO chage -m 0 -M 99999 -I -1 -E -1 svc_ansible

###############################
# -- Update firewalld
# -- NOTE:  Might want to move these changes to the firewalld.d directory and files.

FIREWALL_DIR=/etc/firewalld
FIREWALL_FILE=$FIREWALL_DIR/firewalld.conf

if [ -f $FIREWALL_FILE ]; then
    $SUDO cp $FIREWALL_FILE $FIREWALL_FILE."$HARDING_DATE_TIME"
    $SUDO cp $FIREWALL_FILE $AUDIT_DIR/$FIREWALL_FILE.$HARDING_DATE_TIME

    $SUDO grep 'LogDenied=off' $FIREWALL_FILE
    if [ $? -ne 1 ]; then
        $SUDO sed -i '/#\?LogDenied=/{x;/^$/!d;g;}' $FIREWALL_FILE
        $SUDO sed -i '/LogDenied=/s/^/#/' $FIREWALL_FILE
    fi

    $SUDO sed -i '/#LogDenied=/a\LogDenied=all' $FIREWALL_FILE
    echo -e "\n\n\t $FIREWALL_FILE Updated \n\n"
    $SUDO grep 'LogDenied' $FIREWALL_FILE
    echo -e "\n\n"
else
    echo -e "\n\n\t $FIREWALL_FILE is NOT found \n\n"
fi

# -- Reload the firewall
$SUDO systemctl restart firewalld

# -- Add firewall dropped logs to rsyslog
# -- Update firewall-drops
cat <<EOT >/etc/rsyslog.d/01-firewall-dropped.conf
#
# -- /etc/rsyslog.d/01-firewall-dropped.conf
#

template(name="firewalld_log" type="string" string="/var/log/firewalld-dropped.log")

  if ( \$msg contains "_DROP" or
       \$msg contains '_REJECT' )
        then {
          action(type="omfile" dynaFile="firewalld_log")
          stop
        }

#vim: tabstop=4 shiftwidth=4 softtabstop=4 expandtab:


EOT

echo "Generating additional logs..."
cat <<EOT >/etc/rsyslog.d/CIS.conf
#
# -- CIS Hardening Requirments
#

#$FileCreateMode 0640
create 0644 root root

auth /var/log/secure
kern.* /var/log/messages
daemon.* /var/log/messages
syslog.* /var/log/messages

#vim: tabstop=4 shiftwidth=4 softtabstop=4 expandtab:
EOT

chmod 600 /etc/rsyslog.d/CIS.conf

# -- Reload the rsyslog
$SUDO systemctl stop rsyslog syslog.socket &&
    $SUDO systemctl start rsyslog

# -- Install AWS CLI
[[ ! -d ~/.aws ]] && $SUDO mkdir ~/.aws
$SUDO curl -sS "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
$SUDO mkdir ~/aws-cli
printf "\n .. Extracting awscliv2.zip .. \n"
$SUDO unzip -qqn awscliv2.zip -d ~/aws-cli
printf " .. Installing aws-cli .. \n"
$SUDO ~/aws-cli/aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
if [[ $? -eq 0 ]]; then
    $SUDO rm -rf ~/aws-cli
    $SUDO rm -f awscliv2.zip
fi
$SUDO aws --version

# -- Install AWS Alias
$SUDO mkdir -pv ~/.aws/cli
$SUDO wget --no-check-certificate https://raw.githubusercontent.com/awslabs/awscli-aliases/refs/heads/master/alias

# -- == CIS 3.5 Ensure WLAN disabled
# -- disable Wireless interface
$SUDO nmcli radio all off

# -- update at and cron settings
# -- open cron.sh

# -- Update logrotate settinns
# -- open logrotate.sh

# -- Update security/limits
# -- open limits.sh

# -- Update sysctl settings
#-- open sysctl.sh

# -- Update disable services settings
# -- open modprobe.sh

stop

###################################################################

# -- CIS 4.1.2.2 Ensure audit logs are not autom. deleted
# -- /etc/audit/auditd.conf
AUDITD_DIR="/etc/audit"

grep 'max_log_file_action' $AUDITD_DIR/auditd.conf
if [ $? -ne 1 ]; then
    sed -i '/#\?max_log_file_action/{x;/^$/!d;g;}' $AUDITD_DIR/auditd.conf
    sed -i '/max_log_file_action/s/^/#/' $AUDITD_DIR/auditd.conf
fi
sed -i '/#max_log_file_action/a\max_log_file_action = keep_logs' $AUDITD_DIR/auditd.conf

# - ?????????????????????????????????????????????????????????????????????????????????????
# --??? - Not sure this is what we want --- ?????????
#
# -- CIS 4.1.2.3 Ensure system is dis. when logs are full
grep 'admin_space_left_action' $AUDITD_DIR/auditd.conf
if [ $? -ne 1 ]; then
    sed -i '/#\?admin_space_left_action/{x;/^$/!d;g;}' $AUDITD_DIR/auditd.conf
    sed -i '/admin_space_left_action/s/^/#/' $AUDITD_DIR/auditd.conf
fi
sed -i '/#admin_space_left_action/a\admin_space_left_action = halt' $AUDITD_DIR/auditd.conf

#
#
#
RULES_DIR="$AUDITD_DIR/rules.d"
grep '/var/run/utmp' $RULES_DIR/audit.rules
if [ $? -ne 1 ]; then
    sed -i '/#\?\/var\/run\/utmp/{x;/^$/!d;g;}' $RULES_DIR/audit.rules
    sed -i '/\/var\/run\/utmp/s/^/#/' $RULES_DIR/audit.rules
    sed -i '/#\?\/var\/run\/utmp/a\-w \/var\/run\/utmp -p wa -k session' $RULES_DIR/audit.rules
else
    echo -e "\n-w /var/run/utmp -p wa -k session" >>$RULES_DIR/audit.rules
fi

grep '/var/log/wtmp' $RULES_DIR/audit.rules
if [ $? -ne 1 ]; then
    sed -i '/#\?\/var\/log\/wtmp/{x;/^$/!d;g;}' $RULES_DIR/audit.rules
    sed -i '/\/var\/log\/wtmp/s/^/#/' $RULES_DIR/audit.rules
    sed -i '/#\?\/var\/log\/wtmp/a\-w \/var\/log\/wtmp -p wa -k logins' $RULES_DIR/audit.rules
else
    echo -e "\n-w /var/log/wtmp -p wa -k logins" >>$RULES_DIR/audit.rules
fi

grep '/var/log/btmp' $RULES_DIR/audit.rules
if [ $? -ne 1 ]; then
    sed -i '/#\?\/var\/log\/btmp/{x;/^$/!d;g;}' $RULES_DIR/audit.rules
    sed -i '/\/var\/log\/btmp/s/^/#/' $RULES_DIR/audit.rules
    sed -i '/#\?\/var\/log\/btmp/a\-w \/var\/log\/btmp -p wa -k logins' $RULES_DIR/audit.rules
else
    echo -e "\n-w /var/log/btmp -p wa -k logins" >>$RULES_DIR/audit.rules
fi

#
# -- CIS 1.1.21 Ensure sticky bit set on all world-writeable dirs
files=$(find / -type d \( -perm -0002 -a ! -perm -1000 \) -print 2>/dev/null)
for file in $files; do
    echo "File: $file"
    chmod 1777 "$file"
done

#
SYSTEMD_DIR="/etc/systemd"

# -- == CIS 4.2.1.4 Ensure logging is configured
JOURNALD_CONF="$SYSTEMD_DIR/journald.conf"

cp -f $JOURNALD_CONF $AUDIT_DIR/journald.conf."$HARDING_DATE_TIME"

grep "ForwardToSyslog=" $JOURNALD_CONF
if [ $? -ne 1 ]; then
    sed -i '/#\?ForwardToSyslog/{x;/^$/!d;g;}' $JOURNALD_CONF
    sed -i '/ForwardToSyslog/s/^/#/' $JOURNALD_CONF
    sed -i '/#ForwardToSyslog=/a\ForwardToSyslog=yes' $JOURNALD_CONF
else
    echo -e "\nForwardToSyslog=yes" >>$JOURNALD_CONF
fi

grep "Compress=" $JOURNALD_CONF
if [[ $? -ne 1 ]]; then
    sed -i '/#\?Compress/{x;/^$/!d;g;}' $JOURNALD_CONF
    sed -i '/Compress/s/^/#/' $JOURNALD_CONF
    sed -i '/#Compress=/a\Compress=yes' $JOURNALD_CONF
else
    echo -e "\nCompress=yes" >>$JOURNALD_CONF
fi

grep "Storage=" $JOURNALD_CONF
if [[ $? -ne 1 ]]; then
    sed -i '/#\?Storage/{x;/^$/!d;g;}' $JOURNALD_CONF
    sed -i '/Storage/s/^/#/' $JOURNALD_CONF
    sed -i '/#Storage=/a\Storage=persistent' $JOURNALD_CONF
else
    echo -e "\nStoage=persistent" >>$JOURNALD_CONF
fi

#
# -- == CIS 5.1.2-7 Ensure perms for crontab files
chmod 600 /etc/anacrontab

# -- set immutable files
#$SUDO chattr +i /etc/passwd
#$SUDO chattr +i /etc/shadow

#
# -- == CIS 5.5.5 Ensure default user umask 027
cat <<EOT >/etc/profile.d/set_umask.sh

# -- default umask
umask 027

EOT

#
# -- == CIS 5.5.2 Ensure sys accounts are secured
accounts="$(grep -E -v "^\+" /etc/passwd | awk -F: '($1!="root" && $1!="sync" && $1!="shutdown" \
 && $1!="halt" && $3<1000 && $7!="/sbin/nologin") {print $1}')"

for system_account in $accounts; do
    echo -e "\n Setting $system_account to /sbin/nologin"
    usermod -s /sbin/nologin "$system_account"
done

root_password=$(openssl rand -base64 20)
$SUDO echo "$root_password" | passwd --stdin root
$SUDO passwd -u root
$SUDO passwd -S root
$SUDO passwd -l root

#
# -- == CIS 6.1.11 Ensure no unowned files exist
uo_files="$(df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -nouser)"
for file in $uo_files; do
    chown root "$file"
done

# -- == CIS 6.1.12 Ensure no ungrouped files exist
ug_files="$(df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -nogroup)"
for group in $ug_files; do
    chgrp root "$group"
done

# -- Make all the /var/log files readable by anyone
find /var/log/ -type f ! -perm 644 -exec sudo chmod 644 {} \;
find /var/log/ -type d ! -perm 755 -exec sudo chmod 755 {} \;

#
# -- update the server to latest patches
if [[ $DNF_UPDATE -ne 0 ]]; then
    $SUDO dnf update --assumeyes
    $SUDO dnf remove --assumeyes --oldinstallonly --setopt installonly_limit=3 kernel

    # -- Check to see if system needs updates
    $SUDO dnf -q check-update
fi

# -- Find any files that have not owner or nogroup
$SUDO find / -path /proc -prune -nouser -o -nogroup -ls

# -- set user and group default to root
$SUDO find / -path /proc -prune -nouser -exec chown root {} \;
$SUDO find / -path /proc -prune -nogroup -exec chgrp root {} \;

##############################

openssl s_client -connect github.com:443 --showcerts

#
# -- Reboot the server and login with your user id
reboot

# -- Expand the /opt volume
# -- https://docs.aws.amazon.com/ebs/latest/userguide/recognize-expanded-volume-linux.html
#  1.  From the AWS console locate the /dev/xvdc disk for the instanace
#  2.  Change size to 100GB
#  3.  ssh into instance
#  4.  lsblk (shows you nvme connected as /opt)
#  5.  growpart /dev/<nvme>1                # Grow the first partition on the device
#  6.  xfs_growfs -d /opt
