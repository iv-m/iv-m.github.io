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

**Advice**: don't use root ZooKeeper path: '--zookeeper localhost:2181/kafka` works.

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

The Kafka REST Proxy can also be used.

## Random links

* http://research.microsoft.com/en-us/um/people/srikanth/netdb11/netdb11papers/netdb11-final12.pdf 
* https://github.com/vasilievip/jeeconf-kafka-camel-boot
* http://docs.spring.io/spring-kafka
* http://techblog.netflix.com/2016/04/kafka-inside-keystone-pipeline.html
* http://docs.oracle.com/javase/8/docs/technotes/guides/security/crypto/CryptoSpec.html
