FROM ubuntu:24.04

RUN apt-get update -y && apt-get install -y --no-install-recommends sudo

COPY install-dependencies.sh /tmp/install-dependencies.sh
RUN /tmp/install-dependencies.sh

