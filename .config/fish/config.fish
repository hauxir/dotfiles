if status is-interactive
  base16-tomorrow-night
end

if test -e ~/.config/.env
	envsource ~/.config/.env
end

set -gx PATH $PATH ./node_modules/.bin

# Set default editor
set -gx EDITOR nvim
set -gx VISUAL nvim

# Better history search with arrow keys
bind \e\[A history-search-backward
bind \e\[B history-search-forward
