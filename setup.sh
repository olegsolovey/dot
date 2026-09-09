#!/bin/bash

defaults write com.apple.finder AppleShowAllFiles YES

rsync -a --exclude='.git' --exclude='.git-credentials' ./ ~/

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# install_plugins reads TMUX_PLUGIN_MANAGER_PATH from the running server.
# A server started before ~/.tmux.conf existed will not have it set.
tmux start-server
tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "$HOME/.tmux/plugins/"
~/.tmux/plugins/tpm/bin/install_plugins
tmux source-file "$HOME/.tmux.conf"
