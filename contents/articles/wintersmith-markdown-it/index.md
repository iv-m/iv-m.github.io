---
title: Switching to markdown-it
date: 2017-01-04 15:00
template: article.jade
---

I've switched from [marked] to [markdown-it] for this site.
Here are some hows and whys.

[marked]: https://github.com/chjj/marked
[markdown-it]: https://github.com/markdown-it/markdown-it

## What, again?

Yes, the second officially published article is about configuring this
site, and yes, I do feel that I spend to much time for the
configuration. But listen, it's the New Year Holidays here, so consider
this my approach to rest. Also, I felt like I really need a table of
contents for some of my [pales of notes](/notes.html).

## Getting started

The switching itself is as straightforward as it can be:

1. Install the plugin with `npm`:


```bash
  npm install --save wintersmith-markdown-it
```

2. Configure wintersmith to use it:


```diff
   "plugins": [
+    "./node_modules/wintersmith-markdown-it/",
     "./plugins/hacks.coffee"
   ],
```

Then, the fun begins.


## Getting back some useful features

One interesting consequence of the fact that I'm using github
pages with Wintersmith is that I have the build results
versioned, too (in the `master` branch), so I can use `git diff`
to see how exactly the rendering changed. When experimenting
with markup, templates or, like in this case, rendering
pipeline, this becomes really handy.

After enabling markdown-it plugin, I noticed some
minor differences in HTML markup, but I mostly liked them.
There were also a few features missing. I was able
to get some of them back by enabling certain markdown-it
options in `config.json`:


```javascript
 "markdown-it": {
   "settings": {
     "html": true,
     "linkify": true,
     "typographer": true
   }
 }
```

* `html` allows direct html insertions into markdown -- I use it already
  in one of the drafts to insert SVG with an `<object>` tag;
* `linkify` detects links in texts and converts them to HTML links;
* `typographer` inserts nice dashes and quotes, seems useful;

Also, links like `[about page](../about.md)` are not converted to point to the
corresponding generated HTML anymore. That's sad, but I can live with it ---
so far, I'm ok with  writing `about.html` directly.

One more thing is that markdown-it does not add `id` attribute to headers
out-of-the-box. Luckily, there is an awesome plugin for that:
[markdown-it-anchor]. It can also add an anchor link to every header,
which I find nice to have (hint: hover a header to see what I mean).

[markdown-it-anchor]: https://github.com/valeriangalliat/markdown-it-anchor

## Neat stuff

*[abbrs]: abbreviations with <abbr> tag

Markdown-it has tons of plugins. Some provide text effects: ~~Strike through~~,
~sub~scripts, ^super^scripts, abbrs, unicode emoji like :smile: or
:white_check_mark:, and more. There are also footnotes^[like this one].
I've also added the [markdown-it-table-of-contents] plugin, which
integrates nicely with [markdown-it-anchor] and can put a table
of contents into the document:

[markdown-it-table-of-contents]: https://github.com/Oktavilla/markdown-it-table-of-contents

[[toc]]

Oh yeah, TOC in the end. I feel like rebel. Let's also conclude the
article with header:

### That's it!
