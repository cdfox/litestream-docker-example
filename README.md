Litestream + PocketBase Example
===========================

This repository provides an example of running 
[PocketBase](https://pocketbase.io/) in the same
container as [Litestream](https://litestream.io/). 
It's a fork of the Litestream & Docker example
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
approach works well with services like [Fly.io](https://fly.io/), where running one container
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

Go ahead and follow the link PocketBase prints to the terminal
to open the admin UI. Create an admin user.

Now, create a collection, add a field to it, and create a few
records. 

Try stopping the container and start it again. If you refresh
the admin page, you should remain logged in and continue to 
see the records you just created.

### Downloading the database

You can download a copy of the database, if, for example, you 
wanted to inspect it locally or port the data to another web 
application/framework:

```sh
litestream restore -o data.db s3://pocketbase-litestream-demo/pb_data
```

### Deploy with Fly.io


Create a Fly.io account: https://fly.io/app/sign-in

Install flyctl: https://fly.io/docs/getting-started/installing-flyctl/

Next, log in on the terminal:
```sh
fly auth login
```

Now run the launch command, which will take you through
some setup steps. When it asks, skip deploying for now
(it would fail at this point because we haven't set up secrets).

```sh
fly launch
```

In the generated `fly.toml`, set
```yaml
  internal_port = 8090
```
and add
```yaml
[env]
  REPLICA_URL = "s3://pocketbase-litestream-demo/pb_data"
```

Next, set secrets needed for S3 access:

```sh
fly secrets set LITESTREAM_ACCESS_KEY_ID=XXX
fly secrets set LITESTREAM_SECRET_ACCESS_KEY=XXX
```

Now, we are ready to deploy:

```sh
fly deploy
```

If all goes well, after a minute or so the monitoring
will rpeort success. Then you can open the site in
a browser:

```sh
fly open
```

You'll get a 404, which is expected. Add `"/_"` to the
end of the URL to get to the admin UI. 