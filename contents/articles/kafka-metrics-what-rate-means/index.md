---
title: "Kafka metrics: what does 'rate' mean"
date: 2017-06-20 10:00
template: draft.jade
---

Both Kafka servers and clients expose a number of [metrics] that are
indispensable for monitoring. But when you see a metric like 'average request
size', or 'request rate', what does that really mean? Let's explore.

[metrics]: http://kafka.apache.org/documentation.html#monitoring

## A question of frameworks

Kafka brokers use two frameworks for metrics reporting: Yammer
metrics (which are now [Code Hale metrics], but Kafka still
uses the older version of the artifact), and Kafka's own
metrics framework, which lives in `org.apache.kafka.common.metrics`
package. Clients (at least, the new producer and new consumer)
use the latter only.

[Code Hale metrics]: http://metrics.dropwizard.io/

Here we'll look onto the Kafka Metrics.

TBD:
* we are interested in clients
* note that to some of the metrics this is not applicable (which?)

TBD: it all begins with `Metrics` class.

## Metrics, Measurables and all the rest

The Kafka metrics framework, just as expected, provides an entity named
[Metric]. Metric is *"a named, numerical measurement"* -- which is
expressed in the code as clear as possible^[Here and below, for sake of
brevity, I'm stripping the javadocs from the interfaces.]:

```java
public interface Metric {
    public MetricName metricName();
    public double value();
}
```

[Metric]: TBD

`Metric` is the public interface for the world: `MetricsReporter`
(the pluggable reporting interface I already mentioned) works with
`KafkaMetric`, which is *the* `Metric` implementation; both `Producer`
and `Consumer` have a method that allows to grab all their metrics:

```java
public Map<MetricName, ? extends Metric> metrics() { ... }
```

Internally the things look somewhat different. The metrics
framework is build around [Measurable] -- just *"a measurable
quantity"*, with even simpler interface:

```java
public interface Measurable {
    public double measure(MetricConfig config, long now); 
}
```

[Measurable]: TBD

If you have a `Measurable`, you can get its value, and that's it;
for that, `Measurable` is given a `MetricConfig` (we'll take a look
at it later) and the current timestamp -- so that the 
`Measurable` does not have to refer to the system clock in case 
needs it, which saves a few CPU cycles.

The `Measurable`s are sometimes used directly, to transform any
getter into a metric. Here is, for example, how `ConsumerCoordinator`
exports the number of partitions assigned to it:

```java
Measurable numParts =
    new Measurable() {
        public double measure(MetricConfig config, long now) {
            return subscriptions.assignedPartitions().size();
        }
    };
```

But more often `Measurable` is paired with another simple interface,
`Stat` -- a quantity *"that is computed off the stream of updates"*:

```java
public interface Stat {
    public void record(MetricConfig config, double value, long timeMs);
}
```

There are two kinds of `Stat`:
* `MeasurableStat` -- a simple value that implements both 
  `Stat` and `Measurable`;
* `CompoundStat`  that encloses several `Measurable`s,
   like a histogram with various percentiles.

The stats are are associated with [Sensors], which is *"a handle to
record numerical measurements as they occur"*. That is, you `add` one or
more stats to a `Sensor`, and then use one of its overloaded `record`
methods to write the value when it's measured. The canonical example
from the javadocs shows a sensor that records the message size, and two
metrics, which measure maximal and average size of the message:

```java
    // on initialization, associate the metrics with the sensor
    sensor.add(new MetricName(...), new Max());
    sensor.add(new MetricName(...), new Avg());

    // later, every time a message is received:
    sensor.record(messageSize);
```

[Sensors]: TBD

Wow, that was a lot of things! Let's go through it once again:
* there are sensors -- when you have a value, you record it
  into a sensor;
* sensors are associated with stats -- when a value is recorded
  into a sensor, the sensor records it to all the stats it knows;
* stats do some magic, and convert this series of recorded
  values into a single value (rate, average, maximum...);
* that value is exposed as a `Measurable`;
* the `Measurable` is wrapped into `KafkaMetric`, with
  the metric name and some other metadata;
* the metric is exposed:
    * from `Producer` and `Consumer` to the client code;
    * via JMX to anyone who wants to read it;
    * to `MetricReporter`s, so that they could report it;
      in various way;
* all this is managed by `Metrics` class.

I do hope now it's clear enough.
