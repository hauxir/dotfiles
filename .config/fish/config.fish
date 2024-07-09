if status is-interactive
  base16-tomorrow-night
end

if test -e ~/.config/.env
	envsource ~/.config/.env
end

set -gx PATH $PATH ./node_modules/.bin
