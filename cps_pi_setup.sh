# Configure some Pi settings
sudo raspi-config nonint do_browser firefox
sudo raspi-config nonint do_wayland W1
sudo raspi-config nonint do_vnc 0
sudo raspi-config nonint do_vnc_resolution "1280x720"

# Install a few apps
sudo apt install xrdp vim htop curl git screen x11-apps kate

#S etup static IP
sudo nmcli connection add   type ethernet ifname eth0 con-name eth0-static   ipv4.method manual   ipv4.addresses 192.168.2.2/24   ipv4.gateway 192.168.2.1   ipv4.dns "8.8.8.8 1.1.1.1"   autoconnect yes
sudo nmcli connection up eth0-static

# Revert to legacy VNC authentication/password
printf 'Encryption=PreferOn\nAuthentication=VncAuth\n' | sudo tee -a /root/.vnc/config.d/vncserver-x11
printf "cpsvip42\ncpsvip42\n\n" | sudo vncpasswd -legacy -service
sudo systemctl restart vncserver-x11-serviced

# Install backup scripts
git clone https://github.com/seamusdemora/RonR-RPi-image-utils.git
sudo install --mode=755 RonR-RPi-image-utils/image-* /usr/local/sbin/
rm -r RonR-RPi-image-utils/
