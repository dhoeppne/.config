# .config
My config files for local dev. This setup allows me to clone this repo to whatever computer I need, and get my setup working immediately.

## Getting setup
Clone this repo with
`git clone -C ~/.config https://github.com/dhoeppne/.config.git`
and then run `ln -s ~/.config/zshrc/.zshrc ~/.zshrc` to point your .zshrc to the one found in the config repo. Restart your shell and voila! Everything _should_ be setup.

For an explanation of each dotfile, see the associated README in its respective directory.