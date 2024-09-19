# zimrc

## Zsh Configuration (.zshrc)
This directory contains the configuration files and scripts for setting up the Zsh shell environment. Below is an overview of how everything is set up and what each part does.

## Overview
The .zshrc file is the main configuration file for Zsh. It includes various settings, aliases, environment variables, and functions to customize the shell experience. Additionally, it sources other configuration files and scripts to modularize the setup.

## Structure
1. Main Configuration (.zshrc): The primary configuration file that sets up the environment.
1. Git Aliases (git_aliases): Contains Git command aliases for convenience.
1. Ignore Files (.IGNORE_*): Files that contain sensitive or work-specific configurations that should not be committed to version control. These are local-only files that follow the same setup as the non-IGNORE files.
1. Functions Directory (functions): Contains custom functions that are autoloaded into the shell.
1. Work Functions Directory (IGNORE_functions): Contains work-specific functions that are also autoloaded.

## Detailed Setup
### Zsh Configuration
* History Settings: Configures history behavior, such as ignoring duplicate commands.
* Input/Output Settings: Sets key bindings and other input/output options.
* Zim Framework: Initializes and configures the Zim framework for managing Zsh modules.
* Powerlevel10k: Configures the Powerlevel10k prompt for a visually appealing and informative prompt.
#### Environment Variables
* PATH: Adds custom directories to the PATH environment variable.
* Homebrew: Sets up the environment for Homebrew.
* Go: Configures the Go environment.
* Editor: Sets the default editor to nvim.
#### Aliases
* General Aliases: Defines shortcuts for common commands, such as c=code and nvm="fnm".
* Git Aliases: Sources the git_aliases file to load Git command shortcuts.
#### Functions
* Autoload Functions: Adds custom functions from the functions and IGNORE_functions directories to the fpath and autoloads them.
* Ignore Files
Sensitive and Work-Specific Configurations: Sources files matching the pattern .IGNORE_* to load sensitive or work-specific configurations without committing them to version control.
#### Lazy Loading
* SDKMAN: Uses lazyload to load SDKMAN only when needed.
* Pyenv: Uses lazyload to load Pyenv only when needed.
* FNM: Uses lazyload to load [FNM](https://github.com/Schniz/fnm) only when needed.

## How to Use
1. Clone the Repository: Clone this repository to your local machine with `git clone -C ~/.config https://github.com/dhoeppne/.config.git`
1. Set Up Zsh: Ensure Zsh is installed and set as your default shell.
1. Install Dependencies: Install any required dependencies, such as [Homebrew](https://brew.sh/) and [FNM](https://github.com/Schniz/fnm?tab=readme-ov-file#installation).
1. Source the .zshrc File: link your .config zshrc to the home zshrc: `ln -s ~/.config/zshrc/.zshrc ~/.zshrc`
1. Add Sensitive Configurations: Create .IGNORE_* files for any sensitive or work-specific configurations and place them in the appropriate directory.
Example .IGNORE_* Files
.IGNORE_credentials
.IGNORE_work_zshrc
/IGNORE_functions/<functions to ignore>


By following this setup, you can maintain a clean and organized Zsh configuration that is easy to manage and extend.