# Configure some Pi settings
sudo raspi-config nonint do_browser firefox
sudo raspi-config nonint do_wayland W1
sudo raspi-config nonint do_net_names 0
sudo raspi-config nonint do_vnc 0
sudo raspi-config nonint do_vnc_resolution "1280x720"

# Install a few apps
sudo apt install xrdp vim htop curl git screen x11-apps kate

#S etup static IP
sudo nmcli connection add   type ethernet ifname end0 con-name end0-static   ipv4.method manual   ipv4.addresses 192.168.2.2/24   ipv4.gateway 192.168.2.1   ipv4.dns "8.8.8.8 1.1.1.1"   autoconnect yes
sudo nmcli connection up end0-static

# Revert to legacy VNC authentication/password
printf 'Encryption=PreferOn\nAuthentication=VncAuth\n' | sudo tee -a /root/.vnc/config.d/vncserver-x11
printf "cpsvip42\ncpsvip42\n\n" | sudo vncpasswd -legacy -service
sudo systemctl restart vncserver-x11-serviced

# Install backup scripts
cd
git clone https://github.com/seamusdemora/RonR-RPi-image-utils.git
sudo install --mode=755 RonR-RPi-image-utils/image-* /usr/local/sbin/
rm -r RonR-RPi-image-utils/

# download noVNC and create self-signed cert
cd /usr/local/
sudo git clone https://github.com/novnc/noVNC.git
cd noVNC
sudo openssl req -x509 -nodes -newkey rsa:2048   -keyout novnc.pem -out novnc.pem   -days 3650 -subj "/CN=raspberrypi"

# Create and start noVNC service
sudo printf "[Unit]
Description=noVNC Proxy
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/noVNC/utils/novnc_proxy \
    --vnc localhost:5900 \
    --cert /usr/local/noVNC/novnc.pem \
    --ssl-only \
    --listen 443
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target>" > /etc/systemd/system/novnc.service
sudo systemctl daemon-reload
sudo systemctl enable novnc
sudo systemctl start novnc

# Build ROS2 Kilted Kaiju on Raspberry Pi OS--Debian Trixie 13.3 (Based off of instructions found in https://forums.raspberrypi.com/viewtopic.php?t=361746)
sudo apt install -y git colcon python3-rosdep2 vcstool wget python3-flake8-docstrings python3-pip python3-pytest-cov python3-flake8-blind-except python3-flake8-builtins python3-flake8-class-newline python3-flake8-comprehensions python3-flake8-deprecated python3-flake8-import-order python3-flake8-quotes python3-pytest-repeat python3-pytest-rerunfailures python3-vcstools libx11-dev libxrandr-dev libasio-dev libtinyxml2-dev lttng-tools
mkdir -p ~/ros2_kilted/src
cd ~/ros2_kilted
vcs import --input https://raw.githubusercontent.com/ros2/ros2/kilted/ros2.repos src
sudo rm /etc/ros/rosdep/sources.list.d/20-default.list
sudo apt upgrade -y
sudo rosdep init
rosdep update
rosdep install --from-paths src --ignore-src --rosdistro kilted -y --skip-keys "fastcdr rti-connext-dds-7.3.0 urdfdom_headers python3-vcstool python3-pyqt5 python3-sip python3-qt5-bindings"
colcon build --symlink-install
printf "\nalias ros2_local_setup=\"source /home/pi/ros2_kilted/install/local_setup.bash\"\nexport PATH=\"\$PATH:/home/pi/ros2_kilted/install/bin\"\n" >> ~/.bashrc # create setup alias and ros2 bin to PATH
rm -rf logs/* build/ src/ # Remove up build files

# Build and install HELICS
sudo apt install -y libzmq3-dev 
cd
git clone https://github.com/GMLC-TDC/HELICS
cd HELICS/
git checkout v3.6.1
mkdir build
cd build 
cmake ..
make -j4
sudo make install
rm -rf ~/HELICS # Remove build files
cd

# Build and install GridLab-D
cd
git clone https://github.com/gridlab-d/gridlab-d.git
cd gridlab-d
git submodule update --init
mkdir cmake-build
cd cmake-build
cmake -DGLD_USE_HELICS=ON -DCMAKE_BUILD_TYPE=Release -G "CodeBlocks - Unix Makefiles" ..
sudo cmake --build . -j4 --target install
rm -rf ~/gridlab-d # Remove build files

# Clean up home dir and create backup image at /media/backup.img
rm -rf ~/.cache/* ~/.vscode-server/ ~/*.log ~/.copilot/ ~/.config/chromium/ ~/.config/mozilla
sudo rm -rf /var/cache/* /var/logs/* /var/backups/*
sudo image-backup --initial /media/backup.img
