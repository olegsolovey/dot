#!/bin/bash
set -x

# Invoke without cloning:
# curl -fsSL https://raw.githubusercontent.com/olegsolovey/dot/master/ubuntu-22.sh | bash -s -- -g <github-token> -p <password>

usage() {
  echo "Usage: $0 -s <sc-corp-token> -g <github-token>"
  echo "  -g  Git token for github.com"
  exit 1
}

GH_TOKEN=""

while getopts "g:" opt; do
  case $opt in
    g) GH_TOKEN="$OPTARG" ;;
    *) usage ;;
  esac
done

if [[ -z "$GH_TOKEN" ]]; then
  echo "Error: all arguments are required."
  usage
fi

#
# git credentials
cat << EOF > ~/.git-credentials
https://olegsolovey:${GH_TOKEN}@github.com
EOF
git config --global credential.helper "store --file=$HOME/.git-credentials"
#
# dot
git clone https://github.com/olegsolovey/dot.git && \
rsync -a --exclude='.git' dot/ ~/ && \
rm -rf dot && \
#
# vimrc
wget -O - https://raw.githubusercontent.com/olegsolovey/vimrc/master/install.sh | bash && \

source ~/.bashrc
