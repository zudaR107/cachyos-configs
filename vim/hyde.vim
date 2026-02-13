" HyDE Vim defaults (managed file).
" Location: ~/.config/vim/hyde.vim
" Put user changes in: ~/.config/vim/vimrc

let mapleader = " "

" Enable syntax highlighting and filetype support.
syntax on
filetype plugin indent on

" Line numbers.
set number
"set relativenumber

" Indentation defaults.
set tabstop=4
set shiftwidth=4
set expandtab

" Search highlighting.
set hlsearch " Use :nohlsearch to clear highlights.

" Terminal color support.
set t_Co=256

" Command-line completion menu.
set wildmenu " Use <C-n> / <C-p> to navigate.

" Load wallbash colorscheme if available.
let s:VIM_DIR = fnamemodify($MYVIMRC, ':h')
if filereadable(s:VIM_DIR . '/colors/wallbash.vim')
    colorscheme wallbash
endif
