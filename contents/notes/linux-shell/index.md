---
title: (Linux) shell tips
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

```bash
#!/bin/sh

exec urxvt -e mosh "${1:-gd-ws}" \
    --server='systemd-run --scope --user mosh-server new' \
    -- tmux att
```

Explaining this command would make a nice article `;)`[^smF]

[^smF]: it's classy to render smile in Fira Mono when you
        can do smth like ;).

## Entering docker container without docker

`docker exec` executes command within the container cgroup;
if this cgroup has hard CPU and/or RAM limitations, this
may affect your production code. If you have root access
to the box, you can use `nsenter` instead:

```bash
nsenter --target $PID --mount --uts --ipc --net --pid
```

`$PID` here is the process ID of one of the processes running
in the container, as seen from the host.

Example:

```
$ sudo nsenter --target 10372  --mount --uts --ipc --net --pid cat /proc/self/cgroup | head -n3
11:cpu,cpuacct:/
10:pids:/user.slice/user-500.slice/session-1.scope
9:memory:/
```
```
$ docker exec 2b341597dbf7 cat /proc/self/cgroup | head -n3
11:cpu,cpuacct:/init.scope/system.slice/docker-2b341597dbf7d223f820c1be8edc7c78c394b0f447547f4679f4926e36d07060.scope
10:pids:/init.scope/system.slice/docker-2b341597dbf7d223f820c1be8edc7c78c394b0f447547f4679f4926e36d07060.scope
9:memory:/init.scope/system.slice/docker-2b341597dbf7d223f820c1be8edc7c78c394b0f447547f4679f4926e36d07060.scope
```

## Environment variables of a running process

You can get them from `/proc/$PID/environ`. Variables are NULL-separated. For example:

```
# cat /proc/`pgrep dockerd`/environ | xargs -0L1
LANG=ru_RU.UTF-8
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
NOTIFY_SOCKET=/run/systemd/notify
OPTIONS=
DOCKER_STORAGE_OPTIONS=
```

## Find matching line, and extract the matching part

There is `-o` switch in `grep` for that exactly.

```
$ amixer get Master | egrep -o '[0-9]{1,3}?%'
100%
100%
```

## Parsing comma-separated string into a bash array

```bash
parse_array () { local IFS=','; read -a "$1" < <(echo "$2"); }
```

This takes two arguments -- name and content, and sets global
variable with the given name to an array parsed from comma-separated
contents. For example:

```bash
keys="host,port,service name,comment"
parse_array the_array "$keys"
for x in "${the_array[@]}"; do
    echo "$x"
done
```

This prints:

    host
    port
    service name
    comment

## When you're too lazy to explain everything

http://explainshell.com/
