#!/bin/bash

defaults write com.apple.finder AppleShowAllFiles YES

rsync -a --exclude='.git' --exclude='.git-credentials' ./ ~/

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
~/.tmux/plugins/tpm/bin/install_plugins
