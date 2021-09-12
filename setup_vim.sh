#!/bin/bash
cp -r ./.vim* ~/

git clone https://github.com/preservim/nerdtree.git ~/.vim/bundle/nerdtree
git clone --recursive https://github.com/davidhalter/jedi-vim.git ~/.vim/bundle/jedi-vim
git clone --depth=1 https://github.com/vim-syntastic/syntastic.git ~/.vim/bundle/syntastic
git clone https://github.com/khaveesh/vim-fish-syntax.git ~/.vim/bundle/vim-fish-syntax
