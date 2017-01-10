---
title: Kafka in minkube
date: 2017-01-09 15:00
template: article.jade
---

[[toc]]

## Getting started with k8s

In the older times, there were [hypercube and docker-based solution],
but no one does that anymore. Also, `minikube` uses `localkube`
internally, so there must be a way.

[hypercube and docker-based solution]: https://github.com/kubernetes/community/blob/master/contributors/devel/local-cluster/docker.md

So, we're going with `minikube`:

* update VirtualBox (kvm driver does not work on my machine (yet:question:))
* install [minikube](https://github.com/kubernetes/minikube/releases)

```
curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.14.0/minikube-linux-amd64 \
    && chmod +x minikube
```

* install `kubectl`
  * I've chosen to start with [Google Cloud SDK](https://cloud.google.com/sdk/docs/quickstart-linux)
  * `gcloud components install kubectl`
  * create symlinks in `~/bin`

* test the installation

```bash
kubectl run hello-minikube --image=gcr.io/google_containers/echoserver:1.4 --port=8080
kubectl expose deployment hello-minikube --type=NodePort
kubectl get pod
curl $(minikube service hello-minikube --url)
# check it out, then cleanup:
kubectl delete deployment hello-minikube
```

## Various commands

Just tried them out:

```bash
minikube ssh
kubectl get pods
kubectl get svc
vboxmanage list vms
vboxmanage showvminfo minikube | less
```

## Deploying kafka: fist try

From https://github.com/CloudTrackInc/kubernetes-kafka

### ZooKeeper

```bash
# Create the service and the pod:
kubectl create -f zoo-service.yaml
kubectl create -f zoo-rc.yaml

# Expose the service for testing
kubectl expose svc kafka-zoo-svc --port=2181 --type=NodePort --name kafka-zoo-svc-ext

# Get the exposed ZK URL
minikube service --format="{{.IP}}:{{.Port}}" kafka-zoo-svc-ext

# Test with the shell script from Kafka distribution
rlwrap bin/zookeeper-shell.sh $(minikube service --format="{{.IP}}:{{.Port}}" kafka-zoo-svc-ext)
```

There is property `spec.ports[*].nodePort` of the service,
but IDK how to get it from `kubectl get -o template`. It is
visible via `kubectl get -o yaml` though. For example:

```
$ kubectl get -o yaml svc | grep nodePort
    - nodePort: 31189
```

### Kafka

Change to chroot:

```diff
           - name: KAFKA_ZOOKEEPER_CONNECT
-            value: kafka-zoo-svc:2181
+            value: kafka-zoo-svc:2181/kafka1
           - name: KAFKA_CREATE_TOPICS
```

Because I love ZK chroots! With the image I use, if you do THAT, you'll have
to create the corresponding ZK node. For example, type this into ZK shell:

```
create kafka1 ''
```

Start everything:


```bash
kubectl create -f kafka-service.yam
kubectl create -f kafka-rc.yaml
```

### First testing

Pretend we're in docker: run the following on two tabs of your terminal:

```bash
eval $(minikube docker-env)
docker ps
docker exec -ti \
    $(docker ps --no-trunc --format "{{.ID}}:{{.Command}}" | grep kubernetes-start | head -n1 | cut -d: -f1) \
    bash -i
# in the container
cd /opt/kafka*
```

On the first one, run consumer (we use old image for testing, new consumer does not work there):

    bin/kafka-console-consumer.sh --zookeeper kafka-zoo-svc:2181/kafka1 --topic demo-topic --from-beginning

For the new consumer, you'll need to specify bootstrap severs instead:

    bin/kafka-console-consumer.sh --bootstrap-server kafka:9092 --from-beginning --topic demo-topic

On the second one, run producer:

    bin/kafka-console-producer.sh --broker-list kafka:9092 --topic demo-topic --sync

Just type some messages (each line is a message) --- they will appear on the consumer.

You can work with topics:

    bin/kafka-topics.sh --zookeeper kafka-zoo-svc:2181/kafka1 --list
    bin/kafka-topics.sh --zookeeper kafka-zoo-svc:2181/kafka1 --describe --topic demo-topic

Test with a separate deployed image:

    kubectl run -i -t test2 --image=cloudtrackinc/kubernetes-kafka:latest --command -- tail -f /dev/null

`tailf` does not work -- there is no such command in most of the images.

## When you're done with it

```
minikube stop
vboxmanage list runningvms  # oh it's gone...
```
