---
title: "Kafka metrics: what does 'rate' mean"
date: 2017-06-20 10:00
template: draft.pug
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

Here we'll look onto the Kafka Metrics -- they are more interesting,
less known, and clients use Kafka metrics only. But please be aware
some of the things written below are not applicable to *all* of
the broker metrics.

## Quick overview

Let say we want to measure, for example, various message size metrics:
average, maximum size, and so on. For that,

* we need an instance of `Metrics` class that will manage everything;
* from `Metrics` we'll get a *sensor*; for every message, we will 
  *record* its size to the sensor;
* sensors are associated with *stats* (such as `Avg` or `Max`) --
  when a value is recorded into a sensor, the sensor records it to all
  the stats it knows;
* stats do some magic and convert this series of recorded
  values into a single value (rate, average, maximum...);
* that value is exposed as a *measurable*;
* the *measurable* is wrapped into a *metric*, with
  the metric name and some other metadata;
* the metrics are exposed:
    * from `Producer` and `Consumer` to the client code;
    * via JMX to anyone who wants to read it;
    * to pluggable *metric reporters*, so that they could report
      them in various ways;

Let's take a look at this at a bit more detail.

## Metrics, Measurables and Stats

When you read the metrics, you deal with an entity that
is named, quite expectedly, [Metric]. Metric is *"a named, numerical
measurement"* -- which is expressed in the code as clear as
possible^[Here and below, for sake of brevity, I'm stripping the
javadocs from the interfaces.]:

```java
public interface Metric {
    public MetricName metricName();
    public double value();
}
```

[Metric]: TBD

`Metric` is the public interface for those who *consume* the metrics:
`MetricsReporter` (the pluggable reporting interface I already
mentioned) works with `KafkaMetric`, which is *the* `Metric`
implementation; both `Producer` and `Consumer` have a method that allows
to grab all their metrics:

```java
public Map<MetricName, ? extends Metric> metrics() { ... }
```

If you want to *expose( values, things look somewhat different. At
the core, there is a thing that's even simpler thing than `Metric` 
-- [Measurable]:

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

The `Measurable` is sometimes used directly, to transform any
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
* `MeasurableStat` -- a simple combination of `Measurable` and `Stat`
  that calculates one value based on the series that is recorded into
  it; `Avg` and `Max` are probably most common examples of such stats.
* `CompoundStat` that exposes several `Measurable`s, like a histogram
  with various percentiles.

Probably the simplest `MeasurableStat` is `Total`, which calculates
the sum of the values that are recorded into it:

```java
public class Total implements MeasurableStat {
    private double total = 0.0;

    public void record(MetricConfig config, double value, long now) {
        this.total += value;
    }

    public double measure(MetricConfig config, long now) {
        return this.total;
    }
}
```

The actual [Total] is a bit more elaborate, but essentially the same.

[Total]: TBD

If on every event you record `1.0` instead of the actual value,
the `Total`, obviously, provides the count of the events.
But there is another way to achieve this: let's create a new
`MeasurableStat` that ignores the value and adds `1.0` every time 
its `record` method is called:

```java
public class TotalCount implements MeasurableStat {
    private long count = 0;

    public void record(MetricConfig config, double value, long now) {
        ++this.count;
    }

    public double measure(MetricConfig config, long now) {
        return (double) this.count;
    }
}
```

With this, we can add both of them into a single *sensor*, decoupling
the fact that we are calculating both total value and total count
from the code that records the event.

[Sensor]: TBD-SENSOR

[Sensor] is *"a handle to record numerical measurements as they occur"*.
At the initialization time, you `add` one or more stats to a `Sensor`:

```java
    Sensor sensor = metrics.sensor(...);
    sensor.add(new MetricName(...), new Total());
    sensor.add(new MetricName(...), new TotalCount());
```

Then, when a value is measured (e.g. when the message is handled) you
use one of the sensor's overloaded `record` methods to write the value:

```java
    sensor.record(messageSize);
```

`Total` will add `messageSize` to its value every time `sensor::recrod`
is called, while `TotalCount` will add `1`.

# Sampling

`Total` and `TotalCount` share one very interesting property: they
accumulate the value for the entire lifetime of the process. This is
hardly useful for more common kinds of metrics, like response time
metrics or request rates: you are probably more interested in
values that are "instantaneous" in some sense than in average
values since the last service restart.

Probably, the most straighforward solution would be to use a kind of
sliding window, either time-based or event-based: store last N recorded
values or recorded values for last N seconds, and evaluate metric based
on these values. The problem with this approach is that it's hardly
effective if you have thousands, or even millions of events every second
-- and Kafka sometimes can show such messages rate.

So, in Kafka metrics, this "sliding window" (virtually) moves across
a series of *samples*, which group events together.

When a value is recored, it
is used to *update* an *intermediate* value in the *current sample*.

When the current sample becomes too old, the oldest sample is
discarded, and a new one is created and becomes current.

In other words, the 



>  A SampledStat records a single scalar value measured over one or more samples. Each sample is recorded over a
>  configurable window. The window can be defined by number of events or elapsed time (or both, if both are given the
>  window is complete when *either* the event count or elapsed time criterion is met).
>
>  All the samples are combined to produce the measurement. When a window is complete the oldest sample is cleared and
>  recycled to begin recording the next sample.
