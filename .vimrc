set nocompatible
set shell=/bin/bash
filetype off

execute pathogen#infect()

" Vim5 and later versions support syntax highlighting. Uncommenting the next
" line enables syntax highlighting by default.
if has("syntax")
        syntax on
endif


" If using a dark background within the editing area and syntax highlighting
" turn on this option as well
set background=dark

" Uncomment the following to have Vim jump to the last position when
" reopening a file
if has("autocmd")
        au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif

" Uncomment the following to have Vim load indentation rules and plugins
" according to the detected filetype.
if has("autocmd")
        filetype plugin indent on
endif

"autocmd BufNewFile,BufRead *.g4 set syntax=antlr4

" The following are commented out as they cause vim to behave a lot
" differently from regular Vi. They are highly recommended though.
if $COLORTERM == 'gnome-terminal'
        set t_Co=256
endif

set nocompatible
set showcmd             " Show (partial) command in status line.
set showmatch           " Show matching brackets.
set ignorecase          " Do case insensitive matching
set smartcase           " Do smart case matching
set incsearch           " Incremental search
set autowrite           " Automatically save before commands like :next and :make
set hidden              " Hide buffers when they are abandoned
set mouse=a             " Enable mouse usage (all modes)
set number              " Enable line numbering
set clipboard+=unnamed  " Set clipboard to default linux one"
set hlsearch

" Remap keys: shift navigation to the right:
noremap ; l
noremap l k
noremap k j
noremap j h

" set smarttab
"""""""""""""""""""""""""
" Indent guiding
"""""""""""""""""""""""""
let g:indent_guides_start_level=2
let g:indent_guides_guide_size=1
let g:indent_guides_auto_colors = 0

autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd      guibg=grey      ctermbg=grey
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven  guibg=darkgrey  ctermbg=darkgrey

" autocmd VimEnter * IndentGuidesEnable

filetype plugin indent on
" show existing tab with 4 spaces width
set tabstop=4
" when indenting with '>', use 4 spaces width
set shiftwidth=4
" " On pressing tab, insert 4 spaces
set softtabstop=4

" filetype plugin indent on " show existing tab with 4 spaces width
"set tabstop=2 shiftwidth=2 expandtab
set et

set guifont=Droid\ Sans\ Mono
colorscheme elflord
"colorscheme wwdc16

highlight ColorColumn ctermbg=darkgrey
set colorcolumn=120
" Source a global configuration file if available
if filereadable("/etc/vim/vimrc.local")
        source /etc/vim/vimrc.local
endif

" Jedi config
let jedi#show_call_signatures = 0

" Syntastic
let g:syntastic_mode_map = { 'mode': 'passive', 'active_filetypes': [],'passive_filetypes': [] }
nnoremap <C-w>E :SyntasticCheck<CR>
nnoremap <C-w>R :SyntasticReset<CR>
