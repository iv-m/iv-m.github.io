---
title: Heatmaps for all!
date: 2017-01-01 16:00
template: draft.jade
---

Heatmaps are awesome: in many cases, using color to represent an extra
dimension allows to get pretty serious insight of what's really
happening. But how do I create a heatmap from some randomly formatted
data? Below, I'll present you a couple of ways.

## The Data

Currently, I work on a Solr-based search service for one of the US
e-retailers, and of course I'm interested in its performance. I can
easiliy gather the response times from the services -- from various
testbeds, or production -- in form of the application logs, where a
relevant message may look like this:


```
2017-01-01 13:42:33,559 INFO [..skip..] - Client request: /search?keyword=denim%20shirt, response time: 57 ms, found=73, stage=1
```

Let's extract the repsonse times and build some heatmaps! For the
experiment, I'm taking response times for the few minutes after the
application startup, with all the cache warming disabled. This way,
we'll be able to see how performance changes as JVM and Solr caches
are warming.

## trace2heatmap.pl

[Brendan Gregg] once created a very simpe, easy to use perl script
to build heat maps from traces gathered with [various tools], most
notably [perf][perf-bg], and made it available
[on github](https://github.com/brendangregg/HeatMap).

[Brendan Gregg]: http://www.brendangregg.com
[various tools]: http://www.brendangregg.com/HeatMaps/latency.html
[perf-bg]: http://www.brendangregg.com/blog/2014-07-01/perf-heat-maps.html

While this tool is usually presented with something hardcore like
`perf` or `iosnoop` as the data source, it's in fact quite generic.
The input format is simple: just two space-separated numbers per
line, the timestamp and the latency (or whatever you want to map):

```
$ tail -n 5 ~/tmp/responses.dat
1483264686092 108
1483264686142 48
1483264686182 38
1483264686203 18
1483264686798 592
```

To parse the dates from logs and convert them to unix time, I had to
write some ugly python code, but that was not hard. In just a couple of
minutes of coding, and dozen more minutes for playing with
`trace2heatmap.pl` parameters, I came up with the following command:

```
$ trace2heatmap.pl --grid --unitstime ms --unitslatency ms \
    --stepsec 5 --rows 100 --maxlat 1500 --boxsize 4 \
    --title 'Search response time -- warmup' \
    ~/tmp/responses.dat > heatmap-warmup.svg
```

And it procuced the following SVG:

<object data="heatmap-warmup.svg" type="image/svg+xml"></object>

The cool feature of this heatmap is that it is interactive: it shows
some metadata for the cell under the pointer in a status line it has.

