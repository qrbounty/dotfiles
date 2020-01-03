#!/bin/bash
#
# This is a setup script for my systems.
#
# TODO: OSX install tasks
# TODO: Custom git repos
#




###  References  ###
# https://serverfault.com/questions/144939/multi-select-menu-in-bash-script


###  Variables  ###
dotfile_repo="https://www.github.com/qrbounty/dotfiles.git"
text_bar="============================================================================="

### Dependency Installation Variables ###
declare -a debian_packages=("git" "python3" "vim" "lxde")

declare -a pip3_packages=("yara")

###  Functions  ###
# Usage: "if os darwin; then ..." or "if linux gnu; then ..."
# Purpose: Quick check for os-specific functionality.
# Source: Modified fromhttps://stackoverflow.com/questions/394230/how-to-detect-the-os-from-a-bash-script 
os () { [[ $OSTYPE == *$1* ]]; }
distro () { [[ $(cat /etc/*-release | grep -w NAME | cut -d= -f2 | tr -d '"') == *$1* ]]; }
linux () { 
  case "$OSTYPE" in
    *linux*|*hurd*|*msys*|*cygwin*|*sua*|*interix*) sys="gnu";;
    *bsd*|*darwin*) sys="bsd";;
  esac
  [[ "${sys}" == "$1" ]];
}

# Usage: "if exists <app>; then ..." or "if ! exists..."
# Purpose: A quick check to see if a program is installed. Not 100% reliable because it relies on $PATH
# Source: https://stackoverflow.com/questions/592620/how-to-check-if-a-program-exists-from-a-bash-script
exists() { command -v "$1" >/dev/null 2>&1; }

# Usage: "try command 'Worked!'"
# Purpose: A more customizable variant of the claw "yell, die, try"
# Source: https://stackoverflow.com/questions/1378274/in-a-bash-script-how-can-i-exit-the-entire-script-if-a-certain-condition-occurs
fmt() { printf "\n$text_bar\n$(date +'%H:%M:%S'):"; }
err() { printf "$(fmt) $@\n" >&2; exit 1; }
yay() { printf "$@\n"; }
log() { printf "$(fmt) $@\n"; }
try() { "$1" && yay "$2" || err "Failure at $1"; }

apt_packages() { 
  # TODO: Install each one in a loop, to better enable status tracking
  sudo apt-get update
  for package in "${debian_packages[@]}"; do
    sudo apt-get install -y $package; 
  done
}

pip3_packages() { 
  for package in "${pip3_packages[@]}"; do
    pip3 install $package;
  done 
}


config(){ /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME $@; }
dotfile_copy(){
  git clone --bare $DOTFILE_REPO $HOME/.cfg
  mkdir -p .config-backup
  config checkout
  if [ $? = 0 ]; then
    echo "Checked out config.";
  else
    echo "Backing up pre-existing dot files.";
    config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv $HOME/{} $HOME/.config-backup/{}
  fi;
  config checkout
  config config status.showUntrackedFiles no
}


###  Main  ###
echo $text_bar
echo "Bootstrap Script Version Zero"
echo $text_bar

if os darwin; then
  log "Detected OS: Darwin"
  if ! exists brew; then
    log "Brew installed... This is where I'd install other programs, IF I HAD ANY!"
  else
    log "Installing Brew..."
  fi 
elif linux gnu; then
  log "Detected OS: Linux"
  if distro "Debian" || distro "Kali"; then
    log "Installing system packages..."
    try apt_packages "System updated and packages installed"
    log "Installing pip3 packages..."
    try pip3_packages "Custom python packages installed"
  fi
  if distro "Kali"; then
    log "Detected Kali, installing Kali specific packages..."
  fi
  if exists git; then
    log "Grabbing dotfiles. Conflicts will be saved to .config-backup"
    try dotfile_copy "Dotfile repo cloned."
  else
    err "git not detected, cannot gather dotfiles."
  fi
fi