#!/bin/bash

set -x

# Invoke without cloning:
# curl -fsSL https://raw.githubusercontent.com/olegsolovey/dot/master/ubuntu-22.sh | bash -s -- -g <github-token>

usage() {
  echo "Usage: $0 -g <github-token>"
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
rsync -a --exclude='.git' --exclude='.git-credentials' dot/ ~/ && \
rm -rf dot && \
#
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
~/.tmux/plugins/tpm/bin/install_plugins
# vimrc
wget -O - https://raw.githubusercontent.com/olegsolovey/vimrc/master/install.sh | bash && \

source ~/.bashrc

if [[ -n "$TMUX" ]]; then
  tmux source-file ~/.tmux.conf
fi

git clone git@github.com:xai-org/xai.git --single-branch --branch main --recursive ~/workspace/xai

