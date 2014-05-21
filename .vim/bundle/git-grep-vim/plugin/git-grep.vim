let g:gitgrepprg="git\\ grep\\ -n -i"

function! GitFind(args)
    tabnew
    exec "silent! Git ls-tree --full-tree -r HEAD --name-only --full-name"
    botright copen
    exec "redraw!"
endfunction

function! GitGrep(args)
    tabnew
    let grepprg_bak=&grepprg
    exec "set grepprg=" . g:gitgrepprg
    execute "silent! grep '" . a:args . "'"
    botright copen
    let &grepprg=grepprg_bak
    exec "redraw!"
endfunction

function! GitGrepAdd(args)
    let grepprg_bak=&grepprg
    exec "set grepprg=" . g:gitgrepprg
    execute "silent! grepadd '" . a:args . "'"
    botright copen
    let &grepprg=grepprg_bak
    exec "redraw!"
endfunction

function! LGitGrep(args)
    tabnew
    let grepprg_bak=&grepprg
    exec "set grepprg=" . g:gitgrepprg
    execute "silent! lgrep " . a:args
    botright lopen
    let &grepprg=grepprg_bak
    exec "redraw!"
endfunction


command! -nargs=* -complete=file GitGrep call GitGrep(<q-args>)
command! -nargs=* -complete=file GitGrepAdd call GitGrepAdd(<q-args>)
command! -nargs=* -complete=file LGitGrep call LGitGrep(<q-args>)
command! -nargs=* -complete=file LGitGrepAdd call LGitGrepAdd(<q-args>)
command! -nargs=* -complete=file GitFind call GitFind(<q-args>)
