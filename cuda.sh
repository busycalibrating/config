#/bin/bash

# Installation guide can be found here:
# https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html

# Warning - probably out of date by now!
echo Installing cuda 11.4.2
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin
sudo mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget https://developer.download.nvidia.com/compute/cuda/11.4.2/local_installers/cuda-repo-ubuntu2004-11-4-local_11.4.2-470.57.02-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu2004-11-4-local_11.4.2-470.57.02-1_amd64.deb
sudo apt-key add /var/cuda-repo-ubuntu2004-11-4-local/7fa2af80.pub
sudo apt-get update
sudo apt-get -y install cuda

echo
echo Add the following to PATH in /etc/environment:
echo \t/usr/local/cuda-11.4/bin
echo Make sure to logout to see any changes. Continue...
read null


echo Go to https://developer.nvidia.com/rdp/cudnn-download to download CUDNN, and install with $ sudo dpkg -i libcudnn...
sudo apt install -y libfreeimage-dev
