#!/usr/bin/env bash

# dotfiles dir
dotfiles="$HOME/.dotfiles"
# vim bundles directory
vim_bundles="$HOME/vimfiles/bundle"
# dir to link files to
link_dir="$dotfiles/link"
cache_dir="$HOME/.cache"
zplug="$HOME/.zplug"
zplug_repo=https://git.io/zplug
zplug_target=~/.zplug/zplug

# detect OS
OS="$(uname -s)"

function iHeader()     { echo -e "\033[1m$@\033[0m";  }
function iStep()       { echo -e "  \033[1;33m➜\033[0m $@"; }
function iFinishStep() { echo -e "  \033[1;32m✔\033[0m $@"; }
function iGood()       { echo -e "    \033[1;32m✔\033[0m $@"; }
function iBad()        { echo -e "    \033[1;31m✖\033[0m $@"; }

if [[ ! "$SHELL" =~ zsh ]]; then
    iBad "Please run this script using Zsh shell"
    exit 1
fi

iHeader "Starting bootstrap install made by https://github.com/pgilad"

iStep "Creating Cache dir - $cache_dir"
if [[ ! -d "$cache_dir" ]]; then
    mkdir -p "$cache_dir"
    iGood "$cache_dir created"
else
    iBad "$cache_dir already exists"
fi

iStep "Checking that zplug exists"
if [[ ! -d "$zplug" ]]; then
    echo "Should zplug be installed to $zplug ?"
    select result in Yes No; do
        if [[ "$result" == "Yes" ]]; then
            curl -fLo "$zplug_target" --create-dirs $zplug_repo
            iGood "zplug installed"
        fi
        break
    done
else
    iBad "$zplug already exists"
fi

# Ubuntu-only stuff
if [[ "$OS" =~ ^Linux ]]; then
    iHeader "Running Linux Setup"
    # specify the sudoers filename
    sudoers_file=sudoers-dotfiles
    # sudoers file location
    sudoers_src=$dotfiles/install/ubuntu/$sudoers_file
    # sudoers dest
    sudoers_dest=/etc/sudoers.d/$sudoers_file
    # copy sudoers to sudoers.d
    if [[ ! -e "$sudoers_dest" || "$sudoers_dest" -ot "$sudoers_src" ]]; then
        iStep "Setting up sudo account for easier installing"
        visudo -cf "$sudoers_src" >/dev/null &&
            sudo cp "$sudoers_src" "$sudoers_dest" &&
            sudo chmod 0440 "$sudoers_dest" &&
            echo "File $sudoers_dest updated." ||
            echo "Error updating $sudoers_dest file."
    fi
    iFinishStep "Linux installation complete"
fi

iHeader "Running vim setup"
# make vim bundles dir
if [[ ! -d "$vim_bundles" ]]; then
    iStep "Creating vim bundles directory at $vim_bundles"
    mkdir -p "$vim_bundles"
fi
iFinishStep "Vim Installation Complete"

iHeader "Creating symlinks"
for filename in "$link_dir/"*(D); do
    baseFile="$(basename "$filename")"
    iStep "Handling file: $baseFile"
    if [[ ! -e ~/"$baseFile" ]]; then
        ln -sf "$filename" ~/"$baseFile" && iGood "Symlink created: ~/$baseFile"
    else
        iBad "Symlink skipped, file exists: ~/$baseFile"
    fi
done
iFinishStep "Symlinking complete"

# OSX-only stuff.
if [[ "$OS" =~ ^Darwin ]]; then
    iHeader "Running OSX setup"
    # Install Homebrew.
    if [[ ! -x "$(command -v brew)" ]]; then
        iStep "Installing Homebrew"
        # install homebrew
        ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
    fi
    brew update
    brew upgrade --all
    brew tap Homebrew/bundle
    scriptPath=$(dirname "$0")
    brew bundle --file="$scriptPath/Brewfile"
    iFinishStep "OSX installation complete"
fi

echo -e "\n"
iFinishStep "Installation complete!"
unset iHeader iStep iGood iBad iFinishStep