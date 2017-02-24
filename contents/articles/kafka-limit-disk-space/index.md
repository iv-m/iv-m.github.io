---
title: 'Apache Kafka: how limit the disk space'
date: 2017-02-07
template: draft.jade
---

Sometimes it is desirable to put an upper bound on how much space
[Apache Kafka] can use. But it turns out that this is not as trivial
as one might imagine --- for me, it took several iterations to find
the correct settings. The details below.

[Apache Kafka]: http://kafka.apache.org

## The problem background

All the messages Kafka broker receives are written to *commit logs* ---
essentially, files on the file system.

What happens when logs fill all the available disk space? That's simple
and somewhat predictable: the broker exits immediately, and you
see 'No space left on device' error in one of the last lines of its logs.

This is, apparently, the right thing to do: other brokers (which hopefully
have more space on their drives) will take the responsibilities of this
one, and all the system will continue going without data loss. Of course,
operator intervention is required to bring the broker back up, after
making some space available to it.

I faced this when I was testing a performance of a Kafka cluster. Kafka
is *fast*, so I had to throw quite a lot of data into it to see how
it behaves under the load. And this is the moment when disk space became
a problem.

## First step

Kafka broker has two basic parameters that define the logs retention:
time-based `log.retention.hours` and volume-based `log.retention.bytes`.
When both are defined, they are combined on "whichever comes first"
basis: the message can be deleted if they are older than
`log.retention.hours` **OR** they are more than `log.retention.bytes`
behind the last message. In other words, a message is safe from
the purging if it's **both** younger than  `log.retention.hours`
and no more than `log.retention.bytes` behind the last message.

So, can you just set `log.retention.bytes` (which is not set
by default) and live happily ever after?

NOT REALLY.

## How it really works: segments

In fact, Kafka splits log for each partition into segments:
it writes to the last of them, and when it reaches the certain
size, it creates the next one and starts writing incoming
messages there.

When Kafka considers deleting a segment, ...

## How it really really works: periodic checks

## How it really really really works: delete delay

https://issues.apache.org/jira/browse/KAFKA-636

## Wrapping up

```jproperties
log.retention.hours=168
log.retention.bytes=1073741824
log.segment.bytes=107374182
log.retention.check.interval.ms=20000
log.segment.delete.delay.ms=1000
```
