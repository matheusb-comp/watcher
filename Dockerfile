# Use an official Golang runtime as a parent image
FROM golang:1.10

# Install the 'at' command, start the daemon, and make a link to PID 1 STDOUT
RUN apt-get update && \
  apt-get install -y at && \
  service atd start

# Set the working directory to $GOPATH/src/watcher
WORKDIR /go/src/watcher

# Get the latest release of glide (Go package manager)
RUN curl https://glide.sh/get | sh

# Copy the dependencies file of the watcher package
COPY watcher/glide* ./

# Install the vendor dependencies (from glide.lock)
RUN glide install

# Copy the watcher source code (TODO: Should we just use the binary?)
COPY watcher/* ./
# Create the binary executable
RUN go install

# Change the working dir to root's home
WORKDIR /root

# Copy the scripts we are interested in running
COPY start.sh watcherWrapper.sh ./

# Set the entrypoint of the image to start.sh
ENTRYPOINT ["/bin/bash", "-c", "/root/start.sh"]

# Add Tini
# ENV TINI_VERSION v0.18.0
# ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
# RUN chmod +x /tini
# ENTRYPOINT ["/tini", "--"]
# Run your program under Tini
# CMD ["tail", "-f", "/var/log/watcher.log"]
