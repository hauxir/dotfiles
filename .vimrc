set nocompatible

" Pathogen
call pathogen#infect()
call pathogen#helptags()

let mapleader=","

set statusline=%<\ %n:%f\ %m%r%y%=%-35.(line:\ %l\ of\ %L,\ col:\ %c%V\ (%P)%)

syntax on                          " syntax highlighting
set title                          " set title of screen to name of file
set visualbell                     " no bell noises
set wrap                           " break lines when too long
set number                         " show linenumbers
set cursorline                     " highlight current line
set shell=bash

set completeopt-=preview           " disable preview buffer when using autocompletion
set hidden                         " hide buffers instead of forcing to save and close

filetype plugin indent on          " filetype based indentation
set autoindent                     " when creating a new line indent it the same as the previous one
set copyindent                     " copy indentation on auto-indenting

set backspace=indent,eol,start     " allow backspacing over everything in insert mode

set hlsearch                       " highlight results when searching
set ignorecase                     " case insensitive search
set incsearch                      " incremental search
set smartcase                      " ignore case if search pattern is all lowercase, case-sensitive otherwise

set list                           " enable listchars
set listchars=tab:>.,trail:.,extends:#,nbsp:.    " show whitespace and tabs

set shiftround                     " use multiples of shiftwidth when shifting with < and >
set shiftwidth=4                   " 4 spaces per shift
set expandtab                      " use spaces instead of tabs
set softtabstop=4                  " 4 spaces per tab

set nobackup                       " git takes care of my backups
set noswapfile                     " no swap files, use git
set wildignore=*.swp,*.bak,*pyc,*class,*.o,*.obj,*.git " ignore these in file-open suggestions

set undolevels=1000                " love me dem undos
set history=1000                   " and dat history

" colorscheme settings
let base16colorspace=256  " access colors present in 256 colorspace
colorscheme base16-tomorrow
set background=dark
set t_Co=256 " force vim to use 256 colors

" do you even hjkl bro
map <up> <nop>
map <down> <nop>
map <left> <nop>
map <right> <nop>

" go down/up a row in vim, rather than a line of text
nnoremap j gj
nnoremap k gk

" fold/unfold with space in normal and visual mode
nnoremap <silent> <Space> za
vnoremap <silent> <Space> zf

" 'easy' split navigation
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l

" python indentation
au FileType python setl shiftwidth=4 tabstop=4

" CWD to the dir of the file we are opening
cd %:p:h

" CWD to the root of repo when opening file inside repo
let g:gitroot=system("git rev-parse --show-toplevel")
silent! cd `=gitroot`

" unite
" fuzzy search and open files from dir and subdirs using ,t
nnoremap <leader>t :Unite file_rec/async<cr>
" grep dir and subdirs recursively using ,g
nnoremap <leader>g :Unite grep:.<cr>
if v:shell_error == 0
  " use git repo for fuzzy search if inside git repo
  map <leader>t :Unite repo_files<CR>i
  " use git grep instead instead of grep if inside a repo
  map <leader>g :Unite vcs_grep/git<CR>i
endif

" run neomake when writing files
autocmd! BufWritePost * Neomake

" let Eclim play nice with YCM
let g:EclimCompletionMethod = 'omnifunc'
