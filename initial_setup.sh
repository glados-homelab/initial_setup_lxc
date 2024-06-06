#!/bin/bash

# Update repositories
echo "Updating repositories..."
apt update && apt upgrade -y

# Install necessary packages
echo "Installing necessary packages..."
apt install vim cifs-utils -y

# Get the hostname of the container
HOSTNAME=$(hostname)

# Create a user with the same name as the hostname
echo "Creating user $HOSTNAME..."
useradd -m -s /bin/bash -G sudo $HOSTNAME

# Set the user's password to be the same as the hostname
echo "$HOSTNAME:$HOSTNAME" | chpasswd

# Grant sudo privileges to the new user
echo "Granting sudo privileges to $HOSTNAME..."
usermod -aG sudo $HOSTNAME

# Configure SSH to disable root login and allow the new user to login
echo "Configuring SSH to allow login with the new user..."
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart sshd

read -p "Do you want to mount a SMB share? (yes/no) " confirmation

if [[ "$confirmation" == "yes" ]]; then
  
    # Mount Samba share
    SAMBA_SERVER="samba_server_address" # Replace with your Samba server address
    SAMBA_SHARE="samba_share_name"      # Replace with your Samba share name
    SAMBA_USER="samba_username"         # Replace with your Samba username
    SAMBA_PASS="samba_password"         # Replace with your Samba password
    MOUNT_POINT="/mnt/samba_share"
    
    # Create mount point
    echo "Creating mount point at $MOUNT_POINT..."
    mkdir -p $MOUNT_POINT
    
    # Mount the Samba share
    echo "Mounting the Samba share..."
    echo "//$SAMBA_SERVER/$SAMBA_SHARE $MOUNT_POINT cifs username=$SAMBA_USER,password=$SAMBA_PASS,uid=$(id -u $HOSTNAME),gid=$(id -g $HOSTNAME) 0 0" >> /etc/fstab
    mount -a
else
fi

# Instruction for the user to verify SSH access
echo "Please verify SSH access to the server using the new user $HOSTNAME."

# Wait for user confirmation
read -p "Have you verified SSH access with the new user? (yes/no): " confirmation

if [[ "$confirmation" == "yes" ]]; then
    # Disable the root user by changing its shell to nologin
    echo "Disabling the root user..."
    chsh -s /usr/sbin/nologin root
    echo "The root user has been disabled."
else
    echo "Please verify SSH access with the new user before disabling the root user."
fi

echo "Initial setup completed."

# Reboot the server to apply changes
echo "Rebooting the server..."
reboot
