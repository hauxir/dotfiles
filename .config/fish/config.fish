# Path to your oh-my-fish.
set fish_path $HOME/.oh-my-fish

# Theme
set fish_theme robbyrussell

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-fish/plugins/*)
# Custom plugins may be added to ~/.oh-my-fish/custom/plugins/
set fish_plugins django gi ndenv emoji-clock node pyenv extract percol python tmux

# Path to your custom folder (default path is $FISH/custom)
#set fish_custom $HOME/dotfiles/oh-my-fish

# Load oh-my-fish configuration.
. $fish_path/oh-my-fish.fish

if test -f ~/.autojump/etc/profile.d/autojump.fish; . ~/.autojump/etc/profile.d/autojump.fish; end
eval sh $HOME/.config/base16-shell/base16-tomorrow.dark.sh
