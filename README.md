# Various configurations and scripts for the most optimal<sup>TM</sup> working environment.


### General Cluster Stuff

```bash
# install claude code
curl -fsSL https://claude.ai/install.sh | bash

# install fish shell
wget https://github.com/fish-shell/fish-shell/releases/download/4.7.1/fish-4.7.1-linux-x86_64.tar.xz
tar -xvf 
```

Update your bashrc to point interactive jobs to fish:

```
tar -xvf fish-4.7.1-linux-x86_64.tar.xz
mv fish ~/.local/bin
```

Fish config

```fish
if status is-interactive
    # Commands to run in interactive sessions can go here
    alias sa='smux attach-session'
    alias sq='squeue --format="%.20i %.9P %.24j %.16u %.8T %.10M %.9l  %R"'
    alias btop='$HOME/Programs/btop/bin/btop'
    alias nvsmi='watch -n 0.1 nvidia-smi'
    alias watchq="watch -n 5 squeue --me"
end

# Fix SSH agent forwarding in tmux for fish
if set -q SSH_AUTH_SOCK; and test "$SSH_AUTH_SOCK" != "$HOME/.ssh/ssh_auth_sock"
    ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/ssh_auth_sock"
    set -gx SSH_AUTH_SOCK "$HOME/.ssh/ssh_auth_sock"
    bind alt-backspace backward-kill-path-component  # for stupid macbook shit
end


set -gx GPG_TTY (tty)
set -gx HF_HOME <SOMEWHERE SAFE ISH
set -gx HF_TOKEN <REDACTED>
set -gx SSL_CERT_DIR '/etc/ssl/certs/'
set -gx PATH $PATH <PATH_OF_EXTRA_BINS>
```



### Vim stuff
Contains a `.vimrc` and a `.vim/` folder, and a script to pull relevant plugins.
Note that this depends on having pathogen installed, which is included in the supplied `.vim/` directory.
If you do not have pathogen installed, follow the instructions [here](https://github.com/tpope/vim-pathogen).

If you're willing to overwrite all of your vim configurations, then just run `./setup_vim.sh`.
Bask in vim's glory.

Also now includes a bunch of setup scripts.

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
