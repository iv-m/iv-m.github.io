#!/bin/bash

[ -r "$HOME/bin/use_anaconda" ] && . use_anaconda 3

NOTEBOOK="Numba_vs_Numpy_-_some_sums.ipynb"
METADATA='---
title: "Numba vs Numpy: some sums"
date: 2018-03-28
template: article.jade
---'

rm -rf index*


jupyter nbconvert \
    --to markdown \
    --output=index.md \
    --NbConvertApp.output_files_dir=. \
    "$NOTEBOOK"

# Drop level-1 header(s)
sed -i -e '/^# /d' -i index.md

echo "$METADATA
$(cat index.md)

You can download the full notebook [here]($NOTEBOOK)." > index.md
