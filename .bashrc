alias build_config="~/workspace/repos/configment/tools/build.sh"
alias ls="ls -la"

export EDITOR=vim

source ~/.git-completion.bash

# Main git completions (prior to git 2.30, you an use _git instead of __git_main)
alias g="git"
__git_complete g __git_main

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/osolovey/inference-platform/ranking/ml/centralkitchen/masterchef/store/google-cloud-sdk/path.bash.inc' ]; then . '/home/osolovey/inference-platform/ranking/ml/centralkitchen/masterchef/store/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/osolovey/inference-platform/ranking/ml/centralkitchen/masterchef/store/google-cloud-sdk/completion.bash.inc' ]; then . '/home/osolovey/inference-platform/ranking/ml/centralkitchen/masterchef/store/google-cloud-sdk/completion.bash.inc'; fi

