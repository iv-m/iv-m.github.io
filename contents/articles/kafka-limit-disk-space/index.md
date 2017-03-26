---
title: 'Apache Kafka: how to limit the disk space'
date: 2017-02-26 18:00
template: article.jade
---

Sometimes it is desirable to put an upper bound on how much space
[Apache Kafka] can use. But it turns out that this is not as trivial
as one might imagine --- for me, it took several iterations to find
the correct settings. The details below.

[Apache Kafka]: http://kafka.apache.org

## Step Zero: admit you have a problem

All the messages Kafka broker receives are written to *commit logs* ---
essentially, files on the file system.

What happens when logs fill all the available disk space? That's simple
and somewhat predictable: the broker exits immediately, and you
see 'No space left on device' error in one of the last lines of its logs.

In fact, this looks like the very right thing to do: other brokers
(which hopefully have more space on their drives) will take the
responsibilities of this one, and all the system will continue going
without loosing any data. Of course, operator intervention is required
to bring the broker back up, after making some space available to it.

This became a problem for me when I was running some quick performance
tests against a Kafka cluster. Kafka is *fast*, so I had to throw quite
a lot of data into it to see how it behaves under the load --- and it
turned out that disk space of my test machines are rather limited.

## Step One: naive first try

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

In fact, Kafka splits log for each replica into segments: it writes new
messages to the last of them, and when the current segment reaches the
certain size, it creates the next one and starts writing incoming
messages there. Kafka also does not delete messages one by one; instead,
it removes the whole segment if it sees that all of the messages in it
are not fresh enough to save them.

From our disk-space-concerned point of view, this means that, in
addition to the disk space for all the "fresh enough" messages, we also
need disk space for at least one segment for every replica -- before
Kafka comes to delete the oldest segment, a whole new segment of the
fresh messages will probably be written.  This additional space is
considerable: the default segment size is 1GiB (2^30^ bytes precisely),
and each broker usually handles several replicas of several topics.

What this gives? Under serious space constrains it may make sense for
you to reduce the segment size (property `log.segment.bytes`, say,
tenfold. For single topic with a few partitions (12 partitions totally,
distributed evenly across 3 brokers) I did not notice any performance
impact.

So, can we go and set `log.segment.bytes` to, say, `107374182`, and then
get back to what we were doing?

NOT REALLY.

## How it really really works: periodic check

The segments are not deleted at the very moment the broker has a right
to do it: it would be impractical and certainly hit the performance to
check if there is anything to delete on every incoming message. Instead,
broker runs a periodic task that looks for segments to delete every so
often.

The frequency of the check is controlled by server property named
`log.retention.check.interval.ms`, which default value is 300000 -- 5
minutes. This more than enough (or, more precisely, small enough to be
ok) for the usual settings when you are storing last 168 hours (7 days)
of messages, but for my tests that was just too big, and I reduced the
check period to 20 seconds. Did this finally work for me?

NOT REALLY.

## How it really really really works: delete delay

Since December 2012 and [KAFKA-636], the periodic check does not really
delete the segments: instead, it marks the segment for deletion by
renaming the file (it adds `.deleted` suffix) and schedules the actual
deletion to happen `log.segment.delete.delay.ms` milliseconds later (the
default delay is 60 seconds). Why this is needed is not entirely clear
for me, but it has to do with the fact that file deletion could happen
concurrently with reading, which led to certain corner-case bugs; but it
would be bad for performance to bring the deletion under the read lock.

[KAFKA-636]: https://issues.apache.org/jira/browse/KAFKA-636

I've read through some code and decided that we have a very low chance
of hitting these corner-case bug under Linux, where file deletion is
actually and unlinking operation that removes the entry from the
directory, and actual deletion will not happen until the last file
descriptor to this file is closed -- so I boldly reduced that delay from
60 seconds to one. Did this do the job for me?

Well, looks like it.

## Wrapping up

I found it really interesting that despite the fact that I've read
through the documentation, and the fact that the documentation is
awesome, and the fact that the way Kafka code works makes a lot of sense
when you understand it, I still had to take several iterations before I
found all the relevant settings I had to alter. Here is the subset of
the final configuration of my test cluster:

```jproperties
log.retention.hours=24
log.retention.bytes=1073741824
log.segment.bytes=107374182
log.retention.check.interval.ms=20000
log.segment.delete.delay.ms=1000
```
