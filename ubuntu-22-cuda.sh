#!/bin/bash

# Invoke without cloning:
# curl -fsSL https://raw.githubusercontent.com/olegsolovey/dot/master/ubuntu-22-cuda.sh | bash -s -- -s <sc-corp-token> -g <github-token> -p <password>

usage() {
  echo "Usage: $0 -s <sc-corp-token> -g <github-token> -p <user-password>"
  echo "  -s  Git token for github.sc-corp.net"
  echo "  -g  Git token for github.com"
  echo "  -p  Password for user ${USER}"
  exit 1
}

SC_TOKEN=""
GH_TOKEN=""
USER_PASS=""

while getopts "s:g:p:" opt; do
  case $opt in
    s) SC_TOKEN="$OPTARG" ;;
    g) GH_TOKEN="$OPTARG" ;;
    p) USER_PASS="$OPTARG" ;;
    *) usage ;;
  esac
done

if [[ -z "$SC_TOKEN" || -z "$GH_TOKEN" || -z "$USER_PASS" ]]; then
  echo "Error: all three arguments are required."
  usage
fi

sudo apt-get update && \
sudo apt-get install -y \
  build-essential \
  apt-transport-https \
  ca-certificates \
  bash-completion \
  python3.12-venv \
  python-is-python3 \
  git \
  nvtop \
  unzip \
  vim \
  tmux \
  libssl-dev \
  libffi-dev \
  libbz2-dev \
  python3-dev && \

#
# git credentials
cat << EOF > ~/.git-credentials
https://osolovey:${SC_TOKEN}@github.sc-corp.net
https://olegsolovey:${GH_TOKEN}@github.com
EOF
git config --global credential.helper "store --file=$HOME/.git-credentials"
#
# dot
git clone https://github.com/olegsolovey/dot.git && \
cp dot/.bashrc dot/.gitconfig dot/.tmux.conf ~/ &&
rm -rf dot && \
#
# vimrc
wget -O - https://raw.githubusercontent.com/olegsolovey/vimrc/master/install.sh | bash && \
#
# gpu driver
curl -L https://storage.googleapis.com/compute-gpu-installation-us/installer/latest/cuda_installer.pyz --output cuda_installer.pyz && \
sudo python3 cuda_installer.pyz install_driver
# await until restarts
sudo python3 cuda_installer.pyz install_driver
#
# install cuda ubuntu 22
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
sudo mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600

wget https://developer.download.nvidia.com/compute/cuda/12.9.0/local_installers/cuda-repo-ubuntu2204-12-9-local_12.9.0-575.51.03-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu2204-12-9-local_12.9.0-575.51.03-1_amd64.deb

sudo cp /var/cuda-repo-ubuntu2204-12-9-local/cuda-*-keyring.gpg /usr/share/keyrings/

sudo apt-get update
sudo apt-get -y install cuda-toolkit-12-9

#
cat << EOF >> ~/.bashrc
export PATH=${PATH}:/usr/local/cuda-12.9/bin
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/cuda-12.9/lib64
EOF
source ~/.bashrc
#
# docker
curl -fsSL https://get.docker.com -o get-docker.sh && \
sh get-docker.sh
sudo usermod -aG docker ${USER}
echo "${USER}:${USER_PASS}" | sudo chpasswd
su - ${USER}
gcloud auth configure-docker
