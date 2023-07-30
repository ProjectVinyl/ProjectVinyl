FROM ubuntu:jammy
USER root
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
RUN apt-get update && apt-get -y install \
        curl apt-transport-https wget git gpg build-essential \
        tzdata rbenv python3-pip ffmpeg nodejs libpq-dev \
    && pip3 install yt-dlp 2> /dev/null

RUN wget -O ruby-build-2023-124.tar.gz https://github.com/rbenv/ruby-build/archive/refs/tags/v20230124.tar.gz \
    && tar -xzf ruby-build-2023-124.tar.gz \
    && PREFIX=/usr/local ./ruby-build-20230124/install.sh \
    && rm ruby-build-2023-124.tar.gz \
    && rm -rf ruby-build-20230124

RUN useradd -m projectvinyl -s /usr/bin/bash
USER projectvinyl
WORKDIR /home/projectvinyl
RUN echo 'eval "$(rbenv init - bash)"' >> ~/.bashrc \
    && rbenv install 2.6.3 \
    && rbenv local 2.6.3

WORKDIR /home/projectvinyl/ProjectVinyl
COPY ./Gemfile ./Gemfile
COPY ./Gemfile.lock ./Gemfile.lock
RUN eval "$(rbenv init - bash)" && bundle install

WORKDIR /home/projectvinyl/ProjectVinyl
