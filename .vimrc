if has("syntax")
	syntax on
endif

execute pathogen#infect()

set background=dark

" Vim jumps to last position when editing a file 
if has("autocmd")
	au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif

" Vim loads indentation rules and plugins according to detected filetype
if has("autocmd")
	filetype plugin indent on
endif

autocmd Filetype python setlocal ts=4 sw=4 sts=0 expandtab

set nocompatible
set showcmd
set showmatch
set ignorecase
set smartcase
set incsearch
set autowrite
set hidden
set mouse=a
set number
set clipboard+=unnamed
set hlsearch

noremap ; l
noremap l k
noremap k j
noremap j h

colorscheme elflord
