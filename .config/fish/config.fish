if status is-interactive
  base16-tomorrow-night
end

if test -e ~/.config/.env
	sourceenv ~/.config/.env
end
