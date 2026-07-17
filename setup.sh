#!/bin/bash

defaults write com.apple.finder AppleShowAllFiles YES

cp -r ./ ~/

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
~/.tmux/plugins/tpm/bin/install_plugins
