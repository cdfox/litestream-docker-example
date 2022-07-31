Litestream + PocketBase Example
===========================

This repository provides an example of running PocketBase in the same
container as Litestream. It's a fork of the Litestream & Docker example
here: https://github.com/benbjohnson/litestream-docker-example

PocketBase is a Go web backend that provides APIs similar
to Firebase (realtime subscriptions). It uses sqlite as its database
and provides an Admin web interface for creating data models and viewing
and modifying the data. This is pretty nifty because, similar to Firebase, 
one can build some types of apps without needing to write any backend 
code.

Litestream provides live replication of sqlite to S3 (as well as other
storage services). It has a subprocess execution mode that makes it
easier to run a web app and the Litestream replication process
together in a single container.

Putting these two things together, you get a web backend that runs as
a single container, with data continuously backed up to S3 (which is
pretty cheap for small amounts of data). The container does not
need to have persistent storage mounted as a volume. The configuration
of data models can be done in a web interface. The single container
approach works well with services like Fly.io, where running one container
on a small compute instance is free. And to top it all off, this setup
has minimal lock-in. The data is in sqlite, it's possible to use other
storage services than S3, and the PocketBase Go application is open
source and can be extended.

The main drawbacks are that only one instance of the application can 
be running and the data must be relatively small. Both issues could
potentially be addressed by sharding the data. In addition, Litestream 
is planned to add support for live read replicas, which would allow
multiple instances of the app to work on the same data. It might 
also be possible to go pretty far with vertical scaling, i. e.,
use compute instances with a lot of CPU and memory.


## Usage

### Prerequisites

It's assumed you have an AWS account and have created an IAM user with
permissions for an S3 bucket called pocketbase-litestream-demo.

You'll need to get an access key id and secret for the IAM user and 
set them in your shell environment:

```sh
export LITESTREAM_ACCESS_KEY_ID=XXX
export LITESTREAM_SECRET_ACCESS_KEY=XXX
```


### Building & running the container

You can build the application with the following command:

```sh
docker build -t pocketbase-litestream-demo .
```

Once the image is built, you can run it with the following command. Assumes
that you have a bucket called pocketbase-litestream-demo.

```sh
docker run -i -t \
  -p 8090:8090 \
  -e REPLICA_URL=s3://pocketbase-litestream-demo/pb_data \
  -e LITESTREAM_ACCESS_KEY_ID \
  -e LITESTREAM_SECRET_ACCESS_KEY \
  pocketbase-litestream-demo
```


### Testing it out

Try stopping the container and start it again. You should that 
changes you've made to the data are persisted across restarts.

### Recovering your database

You can simulate a catastrophic disaster by stopping your container and then
deleting your database:

```
rm -rf db db-shm db-wal .db-litestream
```

When you restart the container again, it should print:

```
No database found, restoring from replica if exists
```

and then begin restoring from your replica. The visit counter on your app should
continue where it left off.

