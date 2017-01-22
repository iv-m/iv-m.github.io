---
title: perf_events notes
date: 2017-01-01 22:00
template: article.jade
---

Some useful commands and links related to using `perf` utility (AKA perf_events).

[[toc]]

## Links

Getting started:
* http://www.brendangregg.com/perf.html
* https://perf.wiki.kernel.org/index.php/Tutorial
* more internals: http://web.eece.maine.edu/~vweaver/projects/perf_events/

Flame graphs:

* http://www.brendangregg.com/flamegraphs.html
* python example https://github.com/nylas/nylas-perftools/blob/master/stacksampler.py
* convert from/to various trace formats: https://github.com/spiermar/node-stack-convert

## History

Highlights of `perf` features by kernel releases; only features that
personally interested me are mentioned.

2.6 series:
* 2.6.31: `perf` was created as a way to work with performance counters
* 2.6.32: `perf shed`, `perf timechart`, static tracepoints support
* 2.6.33: dynamic probes -- `perf probe`, `perf diff`, `--filter`
* 2.6.34: buildid cache, `perf lock`, python scripting
* 2.6.35: `perf trace` (but NOT strace), `perf kvm`, newt TUI
* 2.6.36: `perf report --sort cpu,comm`
* 2.6.37: --
* 2.6.38: `perf record --nodelay` (live recording), `perf stat -a -A` (per-CPU stats)
* 2.6.39: `perf top`, `perf evlist` (which events were recorded), `perf stat --filter`

3.X series:
* 3.0: `perf stat -d -d`, `--sync` (run sync() before test)
* 3.1: inverted call graph report (caller/callee, `-G`), CPU range
* 3.2: `perf top`: zoom into tasks and libs
* 3.3: --
* 3.4: `perf report --gtk`, hardware branch profiling (`perf record -b`), user and thread filtering
* 3.5: userspace probes
* 3.6: sort by source line
* 3.7: `perf trace` (strace)
* 3.8: scripts integration into report TUI (try 'r'), /sys/devices/cpu/events/
* 3.9: `--group` for evlist and report; wildcards in tracepoint system names
* 3.10: `perf mem`, weighted sampling
* 3.11: `perf report --percent-limit`
* 3.12: `perf stat --initial-delay`
* 3.13: `--max-stack` for report and top
* 3.14: `perf record --delay`
* 3.15: --
* 3.16: `perf report --children`
* 3.17: pagefault tracing in `perf trace`, IO mode for `perf timechart`
* 3.18: --
* 3.19: --

4.x series:
* 4.0: --
* 4.1: `tracefs` (/sys/kernel/tracing), `perf trace --events foo:bar --no-syscalls`, `perf trace --filter-pids [...]`
* 4.2: --
* 4.3: `perf record --exclude-perf`, `perf trace` syscall groups, Intel PT
* 4.4: eBPF integration
* 4.5: `perf stat record/report`, `perf report --call-graph`
* 4.6: `perf top --hierarchy`, improved Java support (TBD), `perf stat --per-core/--per-socket`
* 4.7: `perf trace` call stack, tracepoints with BPF, hist triggers, perf_event_max_stack, `perf record --switch-output`, `perf script --max-stack=N`
* 4.8: `perf stat --topdown`, `--stdio-color`
* 4.9: ???


## Setup

### Run perf as regular user

You'll probably end up running it as root anyway, here are couple of things
to try before that.

Allow regular users to read kernel mapping data:

    # echo 0 > /proc/sys/kernel/kptr_restrict

Or, in other words:

```bash
sudo sysctl -w kernel.kptr_restrict=0
sudo sysctl -w kernel.perf_event_paranoid=0 # or -1, if not on prod
```

Paranoia levels for perf:

     -1: Allow use of (almost) all events by all users
    >=0: Disallow raw tracepoint access by users without CAP_IOC_LOCK
    >=1: Disallow CPU event access by users without CAP_SYS_ADMIN
    >=2: Disallow kernel profiling by users without CAP_SYS_ADMIN

Check out this [stackexchange question](http://unix.stackexchange.com/questions/14227/do-i-need-root-admin-permissions-to-run-userspace-perf-tool-perf-events-ar).

### Increasing stack size limit

Requires linux *and* linux-tools 4.7+

The default stack size limit is 127, which is definitely not enough for
most of the Java frameworks and servlet containers -- for example, on our
Spring Boot + Jetty + Emedded Solr app I've seen the stacks of length
169, which is, in fact, quite moderate.

Increasing the limit in kernel:

    sysctl -w kernel.perf_event_max_stack=1024

`perf script` will often need this limit to be set explicitly:

    perf script --max-stack=1024 [...]

This will increase the size of some in-kernel buffers and `perf` utility
memory usage, so it's good idea to be carefull with it in
memory-constraint environments.

### A couple of checks:

    less /sys/kernel/debug/tracing/available_events
    papi_native_avail
    perf list

### Kernel configuration

Relevant kernel options include:

* CONFIG_DEBUG_INFO for in-kernel stack traces;
* CONFIG_PERF_EVENTS;
* CONFIG_TRACEPOINTS:
  - CONFIG_FTRACE and CONFIG_FUNCTION_TRACER;
  - CONFIG_FTRACE and CONFIG_ENABLE_DEFAULT_TRACERS;
  - CONFIG_KPROBE_EVENT
  - CONFIG_FTRACE_SYSCALLS -- enables `syscalls:*` tracepoints, which are
    convenient sometimes, are rumored to incur runtime overhead, so are
    disabled in some distributions by default; this can be worked via
    `raw_syscalls:*`, sometimes with `perf trace`, sometimes with
    filters.

## Some commands

I don't want to repeat http://www.brendangregg.com/perf.html#OneLiners,
but commands I keep forgetting just have to be here.

Trigger on every n-th data cache miss:

```bash
perf record –e L1-dcache-load-miss -c $n $command
```

Profiler, correct direction:

``` bash
perf record -g $command
perf report -g 'graph,0.5,caller'
```

Don't forget max-stack if you redefined it:

     sudo perf script --max-stack=1024

## Java and Node

### Netflix way

Start here: http://techblog.netflix.com/2015/07/java-in-flames.html

1.8u60+ + `-XX:+PreserveFramePointer`

`-XX:InlineSmallCode=500` can help if you are totally lost, and disabling
inlining is too brutal.

### From the kernel source

Initial patches:
* https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/commit/?id=9b07e27f88b9cd785cdb23f9a2231c12521dda94
* https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/commit/?id=209045adc2bbdb2b315fa5539cec54d01cd3e7db
* https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/commit/?id=598b7c6919c7bbcc1243009721a01bc12275ff3e

There is JMTI agent for Java in the kernel source.

### Same, but for node

V8 support: https://chromium.googlesource.com/v8/v8/+/82e95f597b3563e3c1947d760ba138f67d45bf6a

```bash
sudo perf record -k mono -F99 -g node --perf-prof $script
sudo perf inject -j -i perf.data -o perf.data.jitted
sudo perf script --max-stack=1024 -i perf.data.jitted \
   | stackcollapse-perf.pl | flamegraph.pl --colors js > flamegraph.svg
```

Note that `perf inject` creates a ton of small elf files in the local
directory (one per compiled function).

```
$ ls -lh jitted* | head -n 4
-rw-r--r-- 2 root root 1008 янв  6 21:15 jitted-21146-0.so
-rw-r--r-- 2 root root  768 янв  6 21:15 jitted-21146-10000.so
-rw-r--r-- 2 root root  784 янв  6 21:15 jitted-21146-10001.so
-rw-r--r-- 2 root root  768 янв  6 21:15 jitted-21146-10002.so
$ ls -l jitted* | wc -l
15231
```

Also, `perf.data.jitted` is much bigger than `perf.data` (maybe that's because
I've got not so many samples):

```
-rw------- 1 root root 471K янв  6 21:14 perf.data
-rw------- 1 root root 4,2M янв  6 21:15 perf.data.jitted
```

### Node, older way

[Custom object dump](https://codereview.chromium.org/2167553002/) video: https://asciinema.org/a/9bu72wh7cf09rns1bc7qhk01h

```
perf record -- node --perf-basic-prof --print-code --redirect-code-traces /tmp/fib.js
perf report --objdump=$HOME/src/chr/v8/tools/objdump-v8
```

## Profiling with in-kernel summaries

One day I'd like to try this out. Maybe when our production will get closer to 4.9 kernels.

[BPF Compiler Collection](https://github.com/iovisor/bcc) includes the following tools:
* `tools/profile.py` for Linux 4.9+
* `tools/old/profile.py` for Linux 4.6-4.8
