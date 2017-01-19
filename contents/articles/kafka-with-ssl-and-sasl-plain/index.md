---
title: "First steps in securing Apache Kafka: SSL and SASL/PLAIN"
date: 2017-01-18 20:00
template: draft.jade
---

In this article, we'll take a quick look onto configuring
a more secured installation of Apache Kafka: we'll
enable the network communication encryption with SSL
and simple authentication with SASL/PLAIN. We'll use
Kafka 0.10.1.0 build with Scala 2.11.

## SSL

The [kafka documentation] has a good and comprehensive section
about configuring the SSL. The only problem is that I want
everything more automated -- I don't want to be prompted
for passwords (let the passwords be generated!) or certificate
DNAME details.

[kafka documentation]: http://kafka.apache.org/documentation/#security_ssl

So, we need to go through the same steps while adding enough
options to each command so that the process is not interactive.

### Creating SSL authority

To make a self-signed certificate (and that's what we're about
to do) we need an SSL authority certificate and key to sign it.


```bash
openssl req -new -x509 \
    -keyout cakey.pem -out ca.pem -days 3650 \
    -passout pass:ougieceiphego \
    -subj "/C=US/O=My Awesome Organization/OU=Middleware Team/CN=My Cool Authority"
```

There are 3 parameters you will not want to hardcode:
* subject base (`/C=US/O=My Awesome Organization/OU=Middleware Team`)
  is the first thing you will want to change --- you probably
  don't work for My Awesome Organization in its Middleware Team;
  you may hardcode it in your scripts though;
* password: I have it generated and saved to file, so actually password
  argument looks like `-passout "pass:$(cat CApassword.txt)"`;
* subject CN -- in fact, in my scripts, this is the script parameter.

I doubt that subject actually affects anything -- that's your
private CA, so you can write almost anything here. But I prefer
to give it good names anyway, in the same spirit in which I give
descriptive names to my variables.

As the result, you'll have the following:
* `ca.pem` --- the Certificate Authority certificate. Publish it
  the way you want, there is nothing secret in it;
* `cakey.pem` -- the certificate key. It is needed only to sign
  the certificates. You should keep it secure it you don't want
  everybody to be able to sign certificates with your freshly
  generated authority.
* you'll also have the most security sensitive thing: the password
  for the key. You can't use a key without a password. So,
  * don't loose the password;
  * store it securely.

### Trust store

When authority certificates is generated, we can create a trust store
--- a keystore Java programs will use to validate our certificates.

```bash
keytool -keystore truststore.jks -alias CARoot -noprompt \
    -import -file ca.pem -storepass chooruanguchi
```

As the result you'll have a Java keystore file named
`truststore.jks`, which will be used by both servers
and clients that will have to validate the certificates
signed by our authority.

Again, we have a password here --- the value of the `-storepass`
option. It will be required to open the keystore. And again,
it's better to generate the password and save it to a file.
On tmpfs. In a secure location of your file system. While
no one is looking into your monitor. ~~In a basement with
a heavy steel door, locked from the inside.~~


### Creating the server key

The same precautions regarding the passwords apply here.

First, we need to generate the key:

```bash
keytool -genkey -noprompt \
    -dname 'CN="my.broker.host.name", OU="Middleware Tam", O="My Awesome Organization", C=US' \
    -alias broker \
    -keystore broker.jks \
    -storepass ierayaekoinot \
    -keypass ierayaekoinot \
    -validity 3650 \
    -keyalg RSA
```

As the result, you'll have a keystore file named `broker.jks`,
with a freshly-generated but unsigned keys.

The notes about `-subj` above also apply to `-dname` here, as this
is almost the same thing, only the format is different.

You may note that I'm reusing password fo `-storepass` and `-keypass`.
Well, we'll have only one key in this keystore, so I see no need
in additional security different passwords may provide.

Now, we can sign the key with our authority:

```bash
# import authority key into our keystore:
keytool -keystore broker.jks -alias CARoot -noprompt -import -file ca.pem -storepass ierayaekoinot

# create a certificate signing request:
keytool -keystore broker.jks -alias broker -certreq -file ./broker.req -storepass ierayaekoinot

# sign the request:
openssl x509 -req -CAcreateserial \
    -CA ca.pem -CAkey cakey.pem  -passin pass:ougieceiphego \
    -in ./broker.req -out ./broker.signed \
    -days 3650

# import the signed certificate into our keystore:
keytool -keystore broker.jks -alias broker -import -file ./broker.signed -storepass ierayaekoinot
```

As the result, you'll have two new files, `broker.reg` with the signing
request, and `broker.signed` with the signed certificate. For our
purposes, these files are temporary; you can safely delete them.

### Configuring the broker

Let's say you have the simple single-node Kafka installation,
like the one described in [Kafka quckstart]. Let's upgrade
it to use SSL!

[Kafka quckstart]: http://kafka.apache.org/quickstart

First, shut your producers, consumers and brokers down.

Edit your 'server.properties'. Modify a line describing listeners:

```jproperties
listeners=SSL://:9093
```

Also, add the following lines -- e.g. at the end:

```jproperties
# keystore location and password
ssl.keystore.location=/path/to/broker.jks
ssl.keystore.password=ierayaekoinot
ssl.key.password=ierayaekoinot

# truststore location and password
ssl.truststore.location=/path/to/truststore.jks
ssl.truststore.password=chooruanguchi

# a setting recommended by the documentation
ssl.secure.random.implementation=SHA1PRNG

# explicitly state that we don't validate client certificates:
ssl.client.auth=none

# make broker use SSL for inter-broker communication;
# without this, we'll have to add a PLAINTEXT listener
# to the 'listeners' line above
security.inter.broker.protocol=SSL
```

That's it! You can start the broker with usual

```bash
bin/kafka-server-start.sh config/server-ssl.properties
```

### Configuring the console clients

The simplest way to test this broker is with the console producer
and consumer. To pass the additional properties into the `Producer`
and `Consumer` constructor, you can put them into a property file.
Here is the minimum of what we need to connect to our broker:

```jproperties
security.protocol=SSL
ssl.truststore.location=/path/to/truststore.jks
ssl.truststore.password=chooruanguchi
```

Then, you can start the console producer:

```bash
bin/kafka-console-producer.sh --broker-list  SSL://localhost:9093 --topic test \
    --producer.config ssl/client-ssl.properties
```

and consumer:

```bash
bin/kafka-console-consumer.sh --bootstrap-server SSL://localhost:9093 \
    --topic test --from-beginning \
    --consumer.config ssl/client-ssl.properties
```

And... it works!


## SASL

Comparing to SSL, SASL is pretty simple. One thing to know is that
PLAIN mechanism passes the passwords in plain text, so it can be
securely used only over SSL. Well, that's how we were planning
to do it `;)`.

### JAAS configuration

SASL is implemented via [JAAS], and JAAS configuration is specified
in system properties --- `-Djava.security.auth.login.config=/path/to/jaas.conf`.
To add this property to either Kafka server or the console
producer and consumer, we can use `KAFKA_OPTS` variable, like this:

```
KAFKA_OPTS='-Djava.security.auth.login.config=/path/to/jaas.conf' bin/kafka_start_server.sh ...
```

[JAAS]: https://docs.oracle.com/javase/8/docs/technotes/guides/security/jaas/JAASRefGuide.html

The JAAS configuration themselves are also simple. For server:

```
KafkaServer {
    org.apache.kafka.common.security.plain.PlainLoginModule required
    username="admin"
    password="ol1eigheeN4eg"
    user_admin="ol1eigheeN4eg"
    user_iv="Starch+relief9relief";
};
```

This creates two users, `admin` and `iv`, and configures the broker
to use `admin` user.

For client, it's even simpler:

```
KafkaClient {
    org.apache.kafka.common.security.plain.PlainLoginModule required
    username="iv"
    password="Starch+relief9relief";
};
```

Just configure client to use `iv` user.

### Adjusting broker settings

Again, we have to change the listeners line:

```jproperties
listeners=SASL_SSL://:9093
```

Also, we need to configure SSL in the same way it was configured
above. We need to change `security.inter.broker.protocol` and
add three more lines:


```jproperties
sasl.enabled.mechanisms=PLAIN
sasl.mechanism=PLAIN

security.inter.broker.protocol=SASL_SSL
sasl.mechanism.inter.broker.protocol=PLAIN
```

When you're done, you can start the broker:

```bash
KAFKA_OPTS='-Djava.security.auth.login.config=ssl/server.jaas.conf' bin/kafka-server-start.sh config/server-sasl.properties
```

### Console clients settings

Wen need JAAS configuration from the above; also, you need to
update the property file:

```jproperties
security.protocol=SASL_SSL
sasl.mechanism=PLAIN
ssl.truststore.location=/path/to/truststore.jks
ssl.truststore.password=chooruanguchi
```

Now, it's easy to start the producer:

```bash
KAFKA_OPTS='-Djava.security.auth.login.config=ssl/iv.jaas.conf' bin/kafka-console-producer.sh \
    --broker-list  SSL://localhost:9093 --topic test --producer.config ssl/client-sasl.properties
```

and the consumer:

```bash
KAFKA_OPTS='-Djava.security.auth.login.config=ssl/iv.jaas.conf' bin/kafka-console-consumer.sh \
    --bootstrap-server SASL_SSL://localhost:9093 \
    --topic test --from-beginning \
    --consumer.config ssl/client-sasl.properties
```

Tools that work via broker will need the security configuration, too:

```bash
KAFKA_OPTS='-Djava.security.auth.login.config=ssl/iv.jaas.conf' bin/kafka-consumer-groups.sh \
    --bootstrap-server SSL_SASL://localhost:19093 \
    --command-config ssl/client-sasl.properties \
    --list
```

## What's left?

Zookeeper of course. Securing a zookeeper installation is surely out of
scope of this article, and Kafka is merely a client to it.

TODO: Play ACLs FTW?
