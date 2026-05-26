  [ -f ~/.bashrc ] && . ~/.bashrc

  if [[ -n "$SSH_CONNECTION" && -z "$TMUX" && $- == *i* ]]; then
    tmux new-session -d -s main 2>/dev/null
    exec tmux new-session -t main -s "main-$$" \; set-option destroy-unattached on
  fi
