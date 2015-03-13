set nocompatible

" Pathogen
call pathogen#infect()
call pathogen#helptags()

let mapleader=","

set statusline=%<\ %n:%f\ %m%r%y%=%-35.(line:\ %l\ of\ %L,\ col:\ %c%V\ (%P)%)
filetype plugin indent on

syntax on
set completeopt-=preview
set autoindent
set backspace=indent,eol,start     "allow backspacing over everything in insert mode
set copyindent                     "copy indentation on auto-indenting
set cursorline
set expandtab
set hidden                         "hide buffers instead of forcing to save and close
set history=1000
set hlsearch
set ignorecase
set incsearch
set list                           "enable listchars
set listchars=tab:>.,trail:.,extends:#,nbsp:.    "show whitespace and tabs
set nobackup                       "use git, swp files are for losers 
set noswapfile                     "the '90s want their swap files back
set number
set shiftround                     "use multiples of shiftwidth when shifting with < and >
set shiftwidth=4
set showmatch
set smartcase                      "ignore case if search pattern is all lowercase, case-sensitive otherwise
set softtabstop=4
set title
set undolevels=1000                "love me dem undos
set visualbell
set wildignore=*.swp,*.bak,*pyc,*class,*.o,*.obj,*.git
set wrap

" colorscheme settings
set background=dark
let base16colorspace=256  " Access colors present in 256 colorspace
colorscheme base16-tomorrow
set t_Co=256

set shell=bash

" remap : to ; in normal mode
nnoremap ; :
" use Q to format text
vmap Q gq
nmap Q gpap

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

" unite 
nnoremap <leader>t :Unite file_rec/async<cr>
nnoremap <leader>g :Unite grep:.<cr>
nnoremap <leader>y :Unite history/yanks<cr>
nnoremap <leader>b :Unite -quick-match buffer<cr>

" 'easy' split navigation
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l

" 'turn off' search
nmap <silent> ,/ :nohlsearch<CR>

au FileType python setl shiftwidth=4 tabstop=4

let g:jedi#popup_on_dot = 0
let g:jedi#completions_command = "<C-Space>"

"CWD to the dir of the file we are opening
cd %:p:h

"CWD to the root of repo when opening file inside repo
let g:gitroot=system("git rev-parse --show-toplevel")
silent! cd `=gitroot`

if v:shell_error == 0
  "search git repo instead of directory if inside a repo
  map <leader>t :Unite repo_files<CR>i
  "git grep when pressing ,g in a repo
  map <leader>g :Unite vcs_grep/git<CR>i
endif

"Run neomake when writing files
autocmd! BufWritePost * Neomake
""
"Let Eclim play nice with YCM
let g:EclimCompletionMethod = 'omnifunc'
