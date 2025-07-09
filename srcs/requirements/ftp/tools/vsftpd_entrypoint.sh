#!/bin/bash
set -ex

# Create the vsftpd configuration file from a template
cat << EOF > /etc/vsftpd.conf
# This is the critical part: listen on IPv4, not IPv6.
listen=YES
listen_ipv6=NO

# Run in the foreground to keep the container alive
background=NO

# Disable anonymous login
anonymous_enable=NO

# Allow local users to log in
local_enable=YES

# Allow FTP commands which change the filesystem
write_enable=YES

# Default umask for created files
local_umask=022

# Display directory messages
dirmessage_enable=YES

# Use local time
use_localtime=YES

# Enable logging
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES

# Jail local users to their home directory
chroot_local_user=YES
allow_writeable_chroot=YES

# Configure passive mode
pasv_enable=YES
pasv_min_port=21000
pasv_max_port=21010
pasv_address=${DOMAIN_NAME}

# User control
userlist_enable=YES
userlist_file=/etc/vsftpd.userlist
userlist_deny=NO
secure_chroot_dir=/var/run/vsftpd/empty
EOF

# Add the user to the userlist if not already present
# This prevents the user from being added every time the container restarts.
grep -qxF "${FTP_USER}" /etc/vsftpd.userlist || echo "${FTP_USER}" >> /etc/vsftpd.userlist

# vsftpd requires a secure, empty, non-writable directory for the chroot jail.
mkdir -p /var/run/vsftpd/empty

# Start vsftpd in the foreground using exec to replace the shell process
exec /usr/sbin/vsftpd /etc/vsftpd.conf
