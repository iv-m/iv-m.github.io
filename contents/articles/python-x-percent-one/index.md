---
title: "Division by 1: just when you thought you knew Python"
date: 2017-12-29
template: article.jade
---

To the hard people that came from ruthless land of C, many things in
Python look like craziness. But years passed, and I'm at home
here you just see... `x % 1`.

Why would anyone do that? In production code?

## The Docs

The [Python documentation] gives a bit of clue regarding possible uses
of such expression:

>  The arguments may be floating point numbers, e.g., `3.14 % 0.7` equals
>  `0.34` (since `3.14` equals `4 * 0.7 + 0.34`.)

And later on:

>  the absolute value of the result is strictly smaller than the absolute
>  value of the second operand.

[Python documentation]: https://docs.python.org/2/reference/expressions.html#binary-arithmetic-operations

So, contrary to my C-fostered intuition, the dividend does not have to be
integer. The modulo operator for `x % y` in this case returns such number that
`x = r * y + (x % y)` for the largest possible *integer* `r` (well, for
negative numbers it's a bit more complicated, but the idea is the same).

This means that when you take modulo by `1` what you get is... right,
the *fractional part* of `x`. And in much more concise way then usual
`math.modf`.

## The Examples

Let's try this:

```python
>>> x = 3.14
>>> x % .7
0.3400000000000003
>>> x % 1
0.14000000000000012
```

As you see, this works *almost* as in docs. Well, that's floating point
arithmetic for you =).

## The End

Well, the more you learn...
