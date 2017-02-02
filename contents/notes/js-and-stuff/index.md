---
title: Node, JS, this blog...
date: 2017-01-06 11:00
template: article.jade
---

[[toc]]

## Slides with remark

https://github.com/gnab/remark

I've [tried it] and liked it. To convert slides to PDF, just
print to PDF from Chrome -- also, some cropping may be needed.

[tried it]: https://github.com/iv-m/iv-m.github.io/tree/remark

Animating remark (thanks to http://www.partage-it.com/animez-vos-presentations-remark-js/ --- in French):

```css
.remark-fading { z-index: 9; }
.remark-slide-container {transition: opacity 0.5s ease-out;opacity: 0;}
.remark-visible {transition: opacity 0.5s ease-out;opacity: 1;}
```

## Diagrams with mermaid

http://knsv.github.io/mermaid/

There is a [gitbook plugin for mermaid] that renders them on server-side. So
does [pandoc filter for mermaid].  Can I steal the code from there? Is it ok to
use phantomjs in the rendering process? Should I use PNG or SVG?

Too many questions.

[gitbook plugin for mermaid]: https://github.com/JozoVilcek/gitbook-plugin-mermaid
[pandoc filter for mermaid]: https://github.com/raghur/mermaid-filter

## More for markdown-it

* https://github.com/markdown-it/markdown-it-container
* https://github.com/waylonflinn/markdown-it-katex

## d3.js

Good place to start: http://mikemcdearmon.com/portfolio/techposts/charting-libraries-using-d3
