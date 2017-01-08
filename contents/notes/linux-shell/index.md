---
title: Shell tips
date: 2017-01-04 11:00
template: article.jade
---

Command-line (unix shell) tips. Some may be bash- or linux-specific.

[[toc]]

## Grepping mans

Here's a piece of `man git-log | xxd`:

    00000a0: 2020 5f08 675f 0869 5f08 7420 5f08 6c5f    _.g_.i_.t _.l_
    00000b0: 086f 5f08 6720 5b3c 6f70 7469 6f6e 733e  .o_.g [<options>
    00000c0: 5d20 5b3c 7265 7669 7369 6f6e 2072 616e  ] [<revision ran
    00000d0: 6765 3e5d 205b 5b2d 2d5d 203c 7061 7468  ge>] [[--] <path
    00000e0: 3e2e 2e2e 5d0a 0a0a 4408 4445 0845 5308  >...]...D.DE.ES.

`08` is a backspace char --- which means terminal will display this,
but grep won't find it: it needs a help for yet another command,
`col`:


```bash
$ man git-log | col -b | grep 'git log' | head -n 1
    git log [<options>] [<revision range>] [[--] <path>...]
```

## mosh + tmux + systemd

Systemd-logind kills user processes when the session is over.
To overcome this, I've created the following one-line script
in my `~/bin`.

```
#!/bin/sh

exec urxvt -e mosh "${1:-gd-ws}" \
    --server='systemd-run --scope --user mosh-server new' \
    -- tmux att
```

Explaining this command would make a nice article `;)`[^smF]

[^smF]: it's classy to render smile in Fira Mono when you
        can do smth like ;).

## When you're too lazy to explain everything

http://explainshell.com/
