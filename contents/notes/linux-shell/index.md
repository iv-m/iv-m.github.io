---
title: Shell commands notes, mostly linux
date: 2017-01-04 11:00
template: article.jade
---

Mini-notes related to linux command line.

## Grepping mans

Here's piece of `man git-log | xxd`:

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
