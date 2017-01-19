---
title: Apache Kafka notes
date: 2017-01-09 10:00
template: article.jade
---

[[toc]]

## Getting started

[Documentation] is really awesome, [quckstart] works.

[Documentation]: http://kafka.apache.org/documentation/
[quckstart]: http://kafka.apache.org/quickstart

**Advice**: don't use root ZooKeeper path: `--zookeeper localhost:2181/kafka` works.

TBD: what if we have ZK cluster? Probably the syntax is
`--zookeeper localhost:2181,localhost:2182/kafka`
(path is mentioned only once, at the very end).

## Deployment considerations

### Kafka and Zookeeper

[Netflix says scary things] --- like, kafka cluster is not really good
in surviving ZK ensemble break down. They deploy ZK cluster per kafka
cluster.

[Netflix says scary things]: TBD

### Offsets replication factor

You should increase replication factor of `__consumer_offsets`
topic to at least 3. For example:

```
offsets.topic.replication.factor=3
```

If we do, we need to make sure that when this topic
is created (e.g. when the first consumer is connected)
we have 3 alive brokers. Otherwise, we may need to
manually increase the replication factor for this
topic.

## Monitoring and management UIs

Offsets/consumers:

* https://github.com/quantifind/KafkaOffsetMonitor
* https://github.com/linkedin/Burrow

Management:

* http://www.landoop.com/blog/2016/08/kafka-topics-ui/
* https://github.com/yahoo/kafka-manager
  * https://github.com/yahoo/kafka-manager/pull/282
  * https://hub.docker.com/r/sheepkiller/kafka-manager

The Kafka REST Proxy can also be used.

## Operations notes

### Getting the list of active brokers

Somewhat ugly, but works when you need it, and you don't have
a way to compile Java code handy:

```bash
bin/zookeeper-shell.sh localhost:2181/kafka/local ls /brokers/ids \
    | tail -n1 | egrep -o '[[:digit:]]+'
```

### Managing partitions

Partitions can be reassigned manually:
* if you need to change the replication factor of the existing topic;
* if, with brokers leaving and joining the cluster, we ended up
  with uneven load distribution on brokers;
* and more!

The reassignment is done in several steps:
1. you collect the data -- how you want to do it;
1. you generate the JSON that describes the change: for each
   partition, it should have a list of brokers that replicate
   it, and the first one is the *preffered* one -- the one
   you want to become a leader;
1. you apply this change with `bin/kafka-reassign-partitions.sh --execute`;
1. you wait for this change to complete, checking the progress with
   `bin/kafka-reassign-partitions.sh --verify`;
1. you ask the cluster to actually reassign the partition
   leaders with `bin/kafka-preferred-replica-election.sh`


A simple example of putting it all together is in
[this gist](https://gist.github.com/iv-m/9504a57e19bcd8e7d3f959bb2c473fb1).
It uses `bin/kafka-reassign-partitions.sh` to generate the plan.  If we
need some special adjustments, or we want to change the replication
factor (this is done by adding more brokers) --- than we'll have to edit
this plan, either manually or with some kind of script, or just generate
the plan with a script right away.

## Random links

* http://research.microsoft.com/en-us/um/people/srikanth/netdb11/netdb11papers/netdb11-final12.pdf
* https://github.com/vasilievip/jeeconf-kafka-camel-boot
* http://docs.spring.io/spring-kafka
* http://techblog.netflix.com/2016/04/kafka-inside-keystone-pipeline.html
* http://docs.oracle.com/javase/8/docs/technotes/guides/security/crypto/CryptoSpec.html
* https://github.com/gerritjvv/kafka-fast
