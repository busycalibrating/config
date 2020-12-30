# Various configurations and scripts for the most optimal<sup>TM</sup> working environment.
### Vim stuff
Contains a `.vimrc` and a `.vim/` folder, and a script to pull relevant plugins.
Note that this depends on having pathogen installed, which is included in the supplied `.vim/` directory.
If you do not have pathogen installed, follow the instructions [here](https://github.com/tpope/vim-pathogen).

If you're willing to overwrite all of your vim configurations, then just run `./setup_vim.sh`.
Bask in vim's glory.

#### Nice features

- NerdTree: run by typing `:NERDTree` into the vim cmd prompt. Gives you a filetree that you can open other
    files with. Highlight an `s` to split horizontally, or `i` for vertical.
- Jedi: All python stuff. I disabled a bunch of annoying default stuff. The useful things I find are pressing `K` 
    when your cursor is over a function opening parenthesis, or object. This opens up the docstring. 
    Additionally, when you type a dot (typically when accessing module attributes, class attributes, etc.),
    you can press `<ctrl> + <space>` to list all of the relevant attributes.
- Syntastic: Useful for basic syntax checking. It normally defaults to doing this every time you save a file,
    but screw that. I save every time I change a character. I instead use the keyboard shortcuts:
    `<ctrl> + w -> E` (i.e. press ctrl + w first, let go, then press E) to run the syntax check, and then
    `<ctrl> + w -> R` to clear the syntax check. Remember that the syntax check is applied to only the saved
    file, so make sure to save your changes.
