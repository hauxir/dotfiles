NAME=unite-source-repo-files
.PHONY: doc

doc: check_vim_helpfile $(NAME).txt

$(NAME).txt:
	vim-helpfile README.md > doc/$(NAME).txt

check_vim_helpfile:
	-@which vim-helpfile >/dev/null 2>&1



