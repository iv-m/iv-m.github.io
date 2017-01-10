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

[Netflix says scary things] --- like, kafka cluster is not really good
in surviving ZK ensemble break down. They deploy ZK cluster per kafka
cluster.

[Netflix says scary things]: TBD

## Monitoring and management UIs

* https://github.com/quantifind/KafkaOffsetMonitor
* http://www.landoop.com/blog/2016/08/kafka-topics-ui/
* https://github.com/yahoo/kafka-manager


## Random links

* http://research.microsoft.com/en-us/um/people/srikanth/netdb11/netdb11papers/netdb11-final12.pdf 
* https://github.com/vasilievip/jeeconf-kafka-camel-boot
* http://docs.spring.io/spring-kafka
