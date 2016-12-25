---
title: First article, or how this site started
date: 2016-12-25 17:30
template: article.jade
---

Hi there!

Now, when I ductaped together quite a bit of infrastructure,
it's time to write something **for real**. I'd also like to describe
how and what was done, and how I feel about it.

## So, do you want a blog?

They say that most of programmers are optimistic, and also tend to
search for technical solutions for non-technical problems. So here I am,
thinkining: "Maybe if tooling around my blog is awesome and convenient
enough, I'll finally start writing stuff." Well, maybe. It did not work
for last two or three attempts, but that's certainly not because I just
was lazy and could not come up with something interesting to write --
that was because *the tooling was not awesome enough*. 100% sure it was
that.

So, let's build something neat.

## So, do you want a blog?

Well, not exactly. It should be more like a place to dump some stuff I'd
like to share, then come back and fix, then come back and rewrite...

## So, do you want a blog?

Let's see. I want to write some stuff. Locally, in my Vim, as it's the
most convinent way of writing.  Preferably using some neat markup, like
markdown.

I want to commit what's written to git. I'm fond of git. I'm a git
junky. When I'm editing something, I simply need my doze of version
control to be productive.

Then, I want to publish it nicely, with certain meta-information added
for me by, say, robots. But I want to manually check stuff before it
goes to production.

## How do I get there?

First [github pages]. The tutorial is very straghtforward, and I walked
it throgh some time ago, leaving it with a simple `index.html` saying
"Under construction".  The main outcome was: I can put some pages into
the master branch of a particular repository, and then push it to
`origin` -- and these pages immediately become my site,
http://iv-m.github.io.

[github pages]: https://pages.github.com/

Then, [Wintersmith] -- a static website generator based on `node.js`.
Wintersmith was really easy to start with, and seems pretty
customizable, so I think I'll stick to it for some time. It uses
[jade] (whcih was [renamed to pugs], but renamed version is
in beta) as the default template engine, which I find interesting.
I've always liked haml-like markup (pythonist in me?), but
never dared to use it in non-toy projects. Well, we'll see.

Why Wintersmith? Frontend all gone `node` now, so I need something
node-based if I want to use all the cool stuff. Also,
I don't feel like building my own static site generator
from separate components (like markdown renderer and templating
engine) using a general-purpose build system. Other than that,
the choice of Wintersmith out of all the node-base static site
generators was almost arbitrary.

[Wintersmith]: http://wintersmith.io/
[jade]: http://jade-lang.com
[renamed to pugs]: https://github.com/pugjs/pug/issues/2184

## Commands and details

I'd like to use a separate git branch for sources -- let's name it
`src`. Then, I can commit one of the build results to `master` and
push it to publish the update.

Let's create the branch:

```bash
git checkout --orphan src
vim .gitignore
vim README.md
git add .
git commit -a
git push --set-upstream origin src
```

Then let's create new `npm` project:

```bash
npm init
```

After answering all the questions, let's add Wintersmith to our
dependencies:

```bash
npm install --save wintersmith
```

Also, let's add an `npm` script for the "enhanced bash" to
[`package.json`](https://github.com/iv-m/iv-m.github.io/blob/src/package.json):

```javascript
  "scripts": {
    [...]
    "bash": "bash -i"
  },

```

Now, it's time to init the Wintersmith blog:

```bash
npm run bash
# and, in that enhanced bash:
wintersmith new tmp
```

Why so hard? I don't want to install things globally with `npm`.
My system is RPM-based, so I stick to RPM when it's about global
packages. With this setup, I can copy the generated files and
merge my `project.json` with the generated one in less than a minute,
and then surprise -- I don't need the global `wintersmith` any more,
it'll leave in `node_modules` happily ever after.

Ok, now it's time to clean the stuff up.  One thing I did not expect is
how complex default Wintersmith template actually is. It really has a
lot of features; I had to be really cruel to it's CSS and markup,
removing the things I did not use or understand.  In just three hours,
I've got something more or less usable, and, what's more important, it's
totally **mine**.

The last bit to setup is publishing. I already have `build`
directory (where Wintersmith puts the generated site) in my
`.gitignore`, so I'll just go and use it for some git magic:

```bash
rm -rf ./build
git worktree add build master
```

Now I have `mater` branch checked out in the `build` directory. If
I run `wintersmith build`, wintersmith will update the files
*right there*. Like this:

```bash
rm -rf ./build/*  # keeps .git there
wintersmith build
```

I even have an npm script for that.

I can use `git diff`  to check the effect of my changes -- that is, to
check how the generated HTMLs have changed -- and when I commit and push
*in that directory*, I actually update the `master` branch -- and my
site, thanks to the Github magic.

Now I have a small script for commiting there, which includes
shortlog of the commit of `src` branch into the commit message.
But that's beyond the basic setup.

## Kind of conclusion

If you're reading this, it seems to work -- at least, I
have something I'm not terribly ashamed of, and I can build up
from here:
* mess with [wintersmith-tag plugin] to see if it suits me better
  then the default paginator -- probably learn from both of them
  and make something of my own;
* switch to CSS preprocessor (probably [SaaS]);
* get how code syntax highliting really works, select another theme;
* generally, just play with technologies I'm not usually working
  with (npm, SaaS, CoffeeScript, pugsjs and what not).
* see if I can employ github for comments.

[SaaS]: http://sass-lang.com/

There is still an open question if it'll work for me, but that only time
will show.
