# Zimrc Configuration
This README provides an overview of the Zim modules (zmodules) configured in the .zimrc file. Each module enhances the functionality of the Zsh shell in different ways.

### Zim Modules
#### `duration-info`
* **Description**: Displays the duration of the last command in the prompt.
* **Usage**: Helps you keep track of how long commands take to execute, which can be useful for performance monitoring and optimization.
#### `zsh-users/zsh-completions`
* **Description**: Provides additional completion definitions for Zsh.
* **Options**: --fpath src
* **Usage**: Enhances the auto-completion capabilities of Zsh by adding more completion scripts for various commands and tools.
#### `zsh-users/zsh-autosuggestions`
* **Description**: Suggests commands as you type based on your command history and completions.
* **Usage**: Improves efficiency by suggesting previously used commands, reducing the amount of typing required.
#### `romkatv/powerlevel10k`
* **Description**: A theme for Zsh that emphasizes speed, flexibility, and out-of-the-box experience.
* **Options**: --use degit
* **Usage**: Provides a highly customizable and visually appealing prompt with various features like Git status, command execution time, and more.
#### `zsh-users/zsh-history-substring-search`
* **Description**: Enables searching through your command history by substring.
* **Usage**: Allows you to quickly find and reuse commands from your history by typing a part of the command.
#### `qoomon/zsh-lazyload`
* **Description**: Lazily loads Zsh plugins to improve shell startup time.
* **Options**: -s 'zsh-lazyload.plugin.zsh' -f '.'
* **Usage**: Optimizes the shell startup time by loading plugins only when they are needed.
#### `zdharma-continuum/fast-syntax-highlighting`
* **Description**: Provides syntax highlighting for Zsh commands.
* **Options**: -s 'fast-syntax-highlighting.plugin.zsh' -f '.'
* **Usage**: Enhances the readability of commands by highlighting syntax errors and command structures in real-time.
#### `zap-zsh/magic-enter`
* **Description**: Adds custom behavior to the Enter key.
* **Options**: -s 'magic-enter.plugin.zsh' -f '.'
* **Usage**: Allows you to define custom actions when pressing Enter, such as running a specific command or script.
#### `mfaerevaag/wd`
* **Description**: A command-line tool for managing directories.
* **Options**: -s 'wd.plugin.zsh' -f '.'
* **Usage**: Simplifies navigation between directories by allowing you to create shortcuts for frequently used paths.
#### `marlonrichert/zsh-autocomplete`
* **Description**: Provides fast and easy-to-use auto-completion for Zsh.
* **Options**: -s 'zsh-autocomplete.plugin.zsh' -f '.'
* **Usage**: Enhances the auto-completion experience by providing more intelligent and responsive suggestions.
#### `completion`
* **Description**: A built-in Zim module for managing completions.
* **Usage**: Ensures that all completion scripts are loaded and managed properly, providing a seamless auto-completion experience.
### How to Use
1. Install Zim: This should be handled when you use the .zshrc found in this repo. Ensure that Zim is installed and configured as your Zsh framework.
1. Run `zimfw install` to install all of the above listed modules.
1. Reload Zsh: Source your .zimrc file or restart your terminal to apply the changes; if you're using my .zshrc in this repo, simply run `newz`

By using these Zim modules, you can significantly enhance the functionality and user experience of your Zsh shell.