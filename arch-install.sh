#!/bin/bash

#     __                         _   __            ___ __  __
# __ / /__ _______ __ _  __ __  | | / /__ ___  ___/ (_) /_/ /____
#/ // / -_) __/ -_)  ' \/ // /  | |/ / -_) _ \/ _  / / __/ __/ _ \
#\___/\__/_/  \__/_/_/_/\_, /   |___/\__/_//_/\_,_/_/\__/\__/\___/
#                      /___/

#Jeremy Venditto
#https://github.com/jeremy-venditto
#https://jeremyvenditto.info

# My Arch Linux Install
#----------------------------------------------------

	#########################
	### Script Automation ###
	#########################

function AUTOMATED_ALL {
read -r -p "Automate Script? [Y/n] " input ; case $input in
    [yY][eE][sS]|[yY]) AUTOMATED=YES ;;
    [nN][oO]|[nN]) AUTOMATED=NO      ;; *) echo "Invalid input...";exit 1;;esac
}
function AUTOMATED_DESKTOP {
echo 'hi'
}
function AUTOMATED_LAPTOP {
echo 'hi'
}
function AUTOMATED_VM {
cat ~/jeremy-venditto/automated_vm.txt << 'EOF'
y
n
n
y
y
n
EOF
~/jeremy-venditto/automated_vm.txt | ~/jeremy-venditto/arch-install.sh
#automated answers
#printf '%s\n' y | arch-install.sh
}


function DISKS_PARTITIONS {

# View Disks before modifying
lsblk
# Select Installation Hard Disk
read -rp "INSTALL DRIVE: " -e -i /dev/ INSTALL_DRIVE
#cfdisk $INSTALL_DRIVE

read -r -p "Coninue with disk formatting? [Y/n] " input ; case $input in
    [yY][eE][sS]|[yY])

# Partition Drive (manual as of now)
cfdisk $INSTALL_DRIVE # Make this automated



# Create EFI Partition (not mounted)
read -rp "EFI PARTITION: " -e -i /dev/ EFI_PART
echo $EFI_PART > efi.txt # EFI_PART variable is lost after arch-chroot
mkfs.fat -F32 $EFI_PART > /dev/null
echo "EFI Partition created on $EFI_PART"

# Create Swap Partition
read -rp "SWAP PARTITION: " -e -i /dev/ SWAP_PART
echo $SWAP_PART > swap.txt # SWAP_PART variable is lost after arch-chroot
mkswap $SWAP_PART && swapon $SWAP_PART
if [[ -z $SWAP_PART ]]; then echo "SWAP file set up on (edit me)"; else echo "SWAP space set up on $SWAP_PART";fi
        ## SWAPFILE
#allocate -l 3G /swapfile
#chmod 600 /swapfile
#mkswap /swapfile
#swapon /swapfile
#echo '/swapfile none swap sw 0 0' >> /etc/fstab
#free -m


# Create Root Partition mounted to /mnt
read -rp "ROOT PARTITION: " -e -i /dev/ ROOT_PART
mkfs.ext4 $ROOT_PART
mount $ROOT_PART /mnt > /dev/null
echo "ROOT PARTITION mounted on $ROOT_PART"

# Create Home Partition mounted to /mnt/home
read -rp "HOME PARTITION: " -e -i /dev/ HOME_PART
mkfs.ext4 $HOME_PART
mkdir -p /mnt/home
mount $HOME_PART /mnt/home > /dev/null

# Assign Computer Hostname to system
read -rp "Machine Hostname: " HOSTNAME
echo $HOSTNAME > hostname.txt

echo
echo "Install Drive: $INSTALL_DRIVE"
echo "EFI Partiton: $EFI_PART"
echo "SWAP Partition: $SWAP_PART"
echo "Root Partition: $ROOT_PART"
echo "Home Partition: $HOME_PART"
echo "Hostname: $HOSTNAME"
;;
    [nN][oO]|[nN]) echo "No"      ;; *) echo "Invalid input...";exit 1;;esac

}



        ###############################################
        ### Arch ISO environment before arch-chroot ###
        ###############################################

function ARCH_ISO {

# Initial ISO install.. manual intervention is required for this step as of now

# Check if using EFI Mode
echo 'Checking if system is booted in EFI mode'
ls /sys/firmware/efi/efivars
if [[ -e "/sys/firmware/efi/efivars" ]]; then
echo "EFI MODE = YES";else
echo "EFI MODE = NO" && echo "Exiting script.. please check your settings"
exit 1;fi

# Check Internet Connection
#ip link && read # add prompt
echo 'Checking Internet Connection'
ping -c 1 -q archlinux.org > /dev/null 2>&1
if [[ $? = 0 ]]; then echo 'Internet = Yes'; else echo 'Internet = No';fi
		#ping -c 3 archlinux.org
		#iplink # if UP okay if DOWN then exit script
		#wifi? #wifi-menu
# Set Network Time Protocol
echo 'Setting Network Time Protocol'
timedatectl set-ntp true

# Set Disk/Partitions
DISKS_PARTITIONS
read -r -p "Are the Partitions Correct? [Y/n] " input ; case $input in
    [yY][eE][sS]|[yY]) echo "Yes" > /dev/null ;;
    [nN][oO]|[nN]) DISKS_PARTITIONS ;; *) echo "Invalid input...";exit 1;;esac

# Install System
echo 'Installing base system'
pacstrap -i /mnt base linux linux-firmware sudo nano curl
echo 'System Installed'

# Generate File System Table
echo 'Generating File System Table'
genfstab -U -p /mnt > /mnt/etc/fstab
#genfstab -U -p /mnt > /mnt/etc/fstab
echo "created /etc/fstab"

# Move files into /mnt so we can use them later
mv arch-install.sh /mnt/
echo "Install Script moved to /mnt"
# Moving lost user input variables so we can use them again
mv efi.txt /mnt/
mv hostname.txt /mnt/
#mv swap.txt /mnt/

# Chroot into system
echo "Chrooting into system"
arch-chroot /mnt /bin/bash /arch-install.sh -a
}

        #############################################
        ### Arch ISO enviroment after arch-chroot ###
        #############################################

# Chrooting into /mnt stopped the script, so I needed another function

function ISO_AFTER_CHROOT {

#SWAP_PART=$(cat swap.txt)
EFI_PART=$(cat efi.txt)
HOSTNAME=$(cat hostname.txt)
#Chrooting into /mnt stopped the script. so here we are with another function

echo 'Generating locales'
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo 'locales generated'
echo 'Setting Time Zone'
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc --utc
echo 'Time Zone Configured'

# Set Hostname
echo 'Creating Hostname'
echo $HOSTNAME > /etc/hostname
echo "127.0.1.1 localhost.localdomain $USERHOSTNAME" > /etc/hosts
echo "Hostname set as $USERHOSTNAME"

# Update and Install NetworkManager, Grub and EfiBootMgr
echo 'Updating System'
pacman -Sy
echo 'Installing NetworkManager Grub and EfiBootMgr'
pacman -S networkmanager grub efibootmgr --noconfirm
systemctl enable NetworkManager
echo 'NetworkManager has been enabled'

# Set Root Password
echo;echo 'set root password...'
passwd

# Create User
echo 'Creating User'
USERUSERNAME="arch-user"
useradd -m -g users -G wheel -s /bin/bash $USERUSERNAME
echo;echo 'Set User Password'
passwd $USERUSERNAME
echo 'User Creation Complete'
  # Add user to wheel group for sudo privlidges
  echo 'Adding user to wheel group'
  echo "%wheel ALL=(ALL:ALL) ALL" | sudo EDITOR='tee -a' visudo

# EFI
echo 'Creating EFI partition'
mkdir /boot/efi
mount $EFI_PART /boot/efi
echo 'EFI partition created and mounted on /boot/efi'
#lsblk # to check if everything is mounted correctly

# Grub Bootloader
echo 'Installing grub'
grub-install --target=x86_64-efi --efi-directory=/boot/efi --removable && echo 'Grub installed..'
echo 'Creating Grub Config file'
grub-mkconfig -o /boot/grub/grub.cfg
echo 'Grub Config created'


# add cron job here or something to boot script at next login
mv /arch-install.sh /home/$USERUSERNAME/ && chown arch-user /home/arch-user/arch-install.sh
echo
echo 'You may now reboot your system'
echo 'Run this script again at next boot'
}

#----------------------------------------------------
function USERSPACE_SHELL {
#Install Everything else


			##############
			### PROMPT ###
			##############

PS3='Please enter your choice: '
options=("Laptop" "Desktop" "Virtual Machine" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Laptop")
	    MACHINE="LAPTOP"
#	    if [[ $AUTOMATED=YES ]];then AUTOMATED_LAPTOP;fi
            break
            ;;
        "Desktop")
	    MACHINE="DESKTOP"
#           if [[ $AUTOMATED=YES ]];then AUTOMATED_DESKTOP;fi
            break
            ;;
        "Virtual Machine")
	    MACHINE="VIRTUAL"
#           if [[ $AUTOMATED=YES ]];then AUTOMATED_VM;fi
            break
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

			##################
			### ESSENTIALS ###
			##################

# Install git and build tools
sudo pacman -S git autoconf make gcc perl fakeroot automake --noconfirm

# Make folder named jeremy-venditto in the home folder
mkdir -p ~/jeremy-venditto && cd ~/jeremy-venditto

# Clone repos
git clone https://github.com/jeremy-venditto/bash-scripts
git clone https://github.com/jeremy-venditto/dotfiles
git clone https://github.com/jeremy-venditto/wallpaper

			##################
			#### PACKAGES ####
			##################

## Enable Multilib repository
sudo sed -i '94s!#Include = /etc/pacman.d/mirrorlist!Include = /etc/pacman.d/mirrorlist!' /etc/pacman.conf
sudo pacman -Syyu
## Get Fastest Mirrors
sudo reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist
## Install Packages
	#Packages for all machine types
#sudo pacman -S - < ~/jeremy-venditto/dotfiles/.resources/NEW_pacman_full --noconfirm
sudo pacman -S lightdm lightdm-gtk-greeter-settings xorg awesome xterm terminator exa ufw firefox --noconfirm
        #Install yay AUR helper
git clone https://aur.archlinux.org/yay
cd yay && makepkg -si --noconfirm
        #Install machine specific packages
if [[ $MACHINE = "DESKTOP" ]]; then sudo pacman -S - < ~/jeremy-venditto/dotfiles/.resources/pacman_desktop.txt --noconfirm
yay -S - < ~/jeremy-venditto/dotfiles/.resources/aur_desktop.txt --noconfirm;fi
if [[ $MACHINE = "LAPTOP" ]]; then sudo pacman -S - < ~/jeremy-venditto/dotfiles/.resources/pacman_laptop.txt --noconfirm
yay -S - < ~/jeremy-venditto/dotfiles/.resources/aur_laptop.txt --noconfirm;fi
if [[ $MACHINE = "VIRTUAL" ]]; then sudo pacman -S - < ~/jeremy-venditto/dotfiles/.resources/pacman_vm.txt --noconfirm
yay -S - < ~/jeremy-venditto/dotfiles/.resources/aur_vm.txt --noconfirm;fi


			###################
			### EDIT CONFIG ###
			###################

# Move config files
    #files
mv ~/jeremy-venditto/dotfiles/.bash_profile /~
mv ~/jeremy-venditto/dotfiles/.bashrc ~/
mv ~/jeremy-venditto/dotfiles/.profile ~/
mv ~/jeremy-venditto/dotfiles/.xinitrc ~/
mv ~/jeremy-venditto/dotfiles/.xprofile ~/
sudo mv ~/jeremy-venditto/dotfiles/usr/share/pixmaps/* /usr/share/pixmaps/
    #directories
mv ~/jeremy-venditto/dotfiles/.config/ ~/
mv ~/jeremy-venditto/dotfiles/.local/ ~/
    #wallpaper directory? default is ~/
mv ~/jeremy-venditto/wallpaper/ ~/

## Screen Resolution for virtual machines
if [[ $MACHINE = VIRTUAL ]]; then
echo "xrandr --output Virtual-1 --primary --mode 1024x768 --rate 60" > ~/screen-normal.sh
echo "xrandr --output Virtual-1 --primary --mode 1920x1080 --rate 60" > ~/screen-full.sh
chmod +x ~/screen-normal.sh ~/screen-full.sh;fi

		# Services

# Enable UFW firewall
sudo ufw enable && sudo systemctl enable --now ufw

# Enable LightDM
sudo systemctl enable lightdm

# Change LightDM settings
if [[ $MACHINE = DESKTOP ]]; then sudo cp ~/jeremy-venditto/dotfiles/etc/lightdm/lightdm-gtk-greeter.conf_desktop /etc/lightdm/lightdm-gtk-greeter.conf;fi
if [[ $MACHINE = LAPTOP ]]; then sudo cp ~/jeremy-venditto/dotfiles/etc/lightdm/lightdm-gtk-greeter.conf_laptop /etc/lightdm/lightdm-gtk-greeter.conf;fi
if [[ $MACHINE = VIRTUAL ]]; then sudo cp ~/jeremy-venditto/dotfiles/etc/lightdm/lightdm-gtk-greeter.conf_vm /etc/lightdm/lightdm-gtk-greeter.conf;fi

# Change Nitrogen Settings
if [[ $MACHINE = DESKTOP ]]; then sed -i "/DIRS=/c\DIRS=/home/"$USER"/files/wallpaper/1920x1080" ~/.config/nitrogen/nitrogen.cfg;fi
if [[ $MACHINE = LAPTOP ]]; then sed -i "/DIRS=/c\DIRS=/home/"$USER"/files/wallpaper/1920x1080" ~/.config/nitrogen/nitrogen.cfg;fi
if [[ $MACHINE = VIRTUAL ]]; then sed -i "/DIRS=/c\DIRS=/home/"$USER"/wallpaper/1920x1080" ~/.config/nitrogen/nitrogen.cfg;fi

# Change Grub Wallpaper
#sudo sed -i "/#GRUB_BACKGROUND=/c\GRUB_BACKGROUND=/home/"$USER"/wallpaper/grub/004-1024x768" /etc/default/grub
#sudo cp ~/wallpaper/grub/004-1024-768.png /usr/share/pixmaps/grub.png
sudo cp ~/jeremy-venditto/dotfiles/usr/share/pixmaps/grub.png /usr/share/pixmaps/
sudo sed -i "/#GRUB_BACKGROUND=/c\GRUB_BACKGROUND=/usr/share/pixmaps/grub.png" /etc/default/grub

# Enable nano syntax highlighting
~/jeremy-venditto/bash-scripts/nano-syntax-highlighting.sh

### install dmenu
cd ~/.config/dmenu && sudo make install

echo 'script complete'
}



						#~~~############~~~#
						#~~ SCRIPT START ~~#
						#~~~############~~~#



# Flags
while getopts ":a" option; do
   case $option in
      a) # Finish Part 1 script after chroot
         ISO_AFTER_CHROOT
         exit;;
esac
done


# AUTOMATED PROMPT
AUTOMATED_ALL

### MAIN PROMPT ####
PS3='Please enter your choice: '
options=("Arch ISO Environment" "Userspace Shell" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Arch ISO Environment")
            ARCH_ISO
            break
            ;;
        "Userspace Shell")
            USERSPACE_SHELL
            break
            ;;
#        "Part 3")
#            part_3
#            break
#            ;;
#        "Part 4")
#            part_4
#            rm -rf ~/jeremy-venditto
#            break
#            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

#### TO DO #####
# Make wallpaper directory switcher script
# Enable sudo privlidges in tty
