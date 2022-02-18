---
title: "Colon colon: just when you thought you knew Python"
date: 2017-12-11
template: article.pug
---

For a simple scripting language Python bears more then enough brain-exploding
magic, like metaclasses and descriptors. But what if a simple language
construct, in a simple code, just makes you stop and say *"WAT?"*.
That's exactly what happened to me when I saw this: `x = x[::-1]`.
What does *that* mean? Let's take a quick look.

## The Docs

The "official" definition how subscriptions work in Python can, with certain
luck, be found in [Python docs]:

> `s[i:j:k]`  slice of `s` from `i` to `j` with step `k`

And a note below says:

> If `i` or `j` are omitted or None, they become “end” values (which end
> depends on the sign of `k`).

[Python docs]: https://docs.python.org/2.7/library/stdtypes.html#sequence-types-str-unicode-list-tuple-bytearray-buffer-xrange


So, with `x[::-1]` we are taking the whole `x` (similarly to `x[:]`), but
with step `-1` -- which means, we are having `x` reversed.

## The Examples

Let's try it:

```python
>>> [1, 2, 3][::-1]
[3, 2, 1]
>>> ('answer', 42)[::-1]
(42, 'answer')
>>> 'foo bar'[::-1]
'rab oof'
```

What I also have to notice is that this construct (unlike, e.g., [reversed]
builtin) preserves the type of its argument: for tuple, you get tuple,
and for string, you get string. This is often convenient.

## The End

Well, the more you learn...
