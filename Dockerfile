# Use the Go image to build our application.
FROM alpine as builder

RUN apk add unzip

# Download static build of Pocketbase
ADD https://github.com/pocketbase/pocketbase/releases/download/v0.3.2/pocketbase_0.3.2_linux_amd64.zip /tmp/pocketbase.zip
RUN unzip /tmp/pocketbase.zip pocketbase -d /usr/local/bin

# Download the static build of Litestream directly into the path & make it executable.
# This is done in the builder and copied as the chmod doubles the size.
ADD https://github.com/benbjohnson/litestream/releases/download/v0.3.8/litestream-v0.3.8-linux-amd64-static.tar.gz /tmp/litestream.tar.gz
RUN tar -C /usr/local/bin -xzf /tmp/litestream.tar.gz

# This starts our final image; based on alpine to make it small.
FROM alpine

# You can optionally set the replica URL directly in the Dockerfile.
# ENV REPLICA_URL=s3://BUCKETNAME/db

# Copy executable & Litestream from builder.
COPY --from=builder /usr/local/bin/pocketbase /usr/local/bin/pocketbase
COPY --from=builder /usr/local/bin/litestream /usr/local/bin/litestream

RUN apk add bash

# Notify Docker that the container wants to expose a port.
EXPOSE 8090

# Copy Litestream configuration file & startup script.
COPY etc/litestream.yml /etc/litestream.yml
COPY scripts/run.sh /scripts/run.sh

CMD [ "/scripts/run.sh" ]

