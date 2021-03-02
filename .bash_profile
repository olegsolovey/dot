export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"

# The next line updates PATH for the Google Cloud SDK.
if [ -f /Users/osolovey/bin/google-cloud-sdk/path.bash.inc ]; then
  source '/Users/osolovey/bin/google-cloud-sdk/path.bash.inc'
fi

# The next line enables shell command completion for gcloud.
if [ -f /Users/osolovey/bin/google-cloud-sdk/completion.bash.inc ]; then
  source '/Users/osolovey/bin/google-cloud-sdk/completion.bash.inc'
fi

source ~/.bashrc
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"

alias ls='ls -la'
alias gce='git clone $git_expresso --recursive --single-branch --branch master .'
alias subl='/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl'

export  git_expresso='https://github.sc-corp.net/Snapchat/expresso.git'
