---
title: Vim notes
date: 2017-01-15 15:00
template: article.jade
---

[[toc]]

## List of plugins I use

* https://github.com/tpope/vim-pathogen
* https://github.com/kien/rainbow_parentheses.vim
* https://github.com/digitaltoad/vim-pug -- Jade, too
* https://github.com/kchmck/vim-coffee-script
* https://github.com/derekwyatt/vim-scala
* https://github.com/rust-lang/rust.vim.git
* https://github.com/hynek/vim-python-pep8-indent.git
* https://github.com/neovimhaskell/haskell-vim
* https://github.com/elzr/vim-json with `let g:vim_json_syntax_conceal = 0`
* https://github.com/godlygeek/tabular
* https://github.com/guns/xterm-color-table.vim `:XtermColorTable`
* https://github.com/tmux-plugins/vim-tmux.git
* https://github.com/ctrlpvim/ctrlp.vim with popup on `<Leader>e`
* https://github.com/plasticboy/vim-markdown with additional configuration.
* https://github.com/fatih/vim-go with most of the features turned off

Initializing `~/.vim/bundle` on a new machine:

```bash
xclip -o | while read repo comment; do git clone "$repo"; done
```

## Markdown configuration

```vim
let g:vim_markdown_conceal = 0
let g:vim_markdown_fenced_languages = ['bash=sh', 'java', 'python', 'html', 'javascript']
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_new_list_item_indent = 2

" by default mkdCode is String, but I find PreProc (blueish in my config) nicer
autocmd filetype markdown hi link mkdCode PreProc

" make code start and end more visible, since now the code is not all in one color
autocmd filetype markdown hi mkdCodeStart cterm=bold ctermfg=16 ctermbg=43
autocmd filetype markdown hi link mkdCodeEnd mkdCodeStart
```


## Interesting plugins to check out one day

* https://github.com/vim-syntastic/syntastic
* https://github.com/tpope/vim-surround
