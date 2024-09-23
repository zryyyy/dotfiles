# command
alias c="clear"
alias sb="source ~/.bashrc"

# navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~="cd ~"
alias -- -="cd -"

# git
alias gs="git status"
alias ga="git add"
alias gb="git branch"
alias gc="git commit"
alias gd="git diff"
alias gp="git push"
alias gm="git commit -m"
alias gl="git log"
alias glg="git log --all --graph --decorate --abbrev-commit --pretty=online"
alias gaa="git add ."
alias gcm="git commit -m"
gac() {
  git add .
  git commit -m "$1"
}
gcp() {
  git commit -m "$1"
  git push
}
gacp() {
  git add .
  git commit -m "$1"
  git push
}

# npm
alias ni="npm install"
alias nci="npm ci"
alias nrs="npm run start"
alias nrd="npm run dev"
alias nrb="npm run build"
alias nrp="npm run preview"
alias nrt="npm run test"
alias nrl="npm run lint"

# other
# Get week number
alias week='date +%V'
# Recursively delete `.DS_Store` files
alias cleanup="find . -type f -name '*.DS_Store' -ls -delete"
# Reload the shell (i.e. invoke as a login shell)
alias reload="exec ${SHELL} -l"
# Print each PATH entry on a separate line
alias path="echo -e ${PATH//:/\\n}"