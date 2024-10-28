#FROM openjdk:13-jdk-alpine
ARG DOCKER_IMAGE_TYPE

FROM eclipse-temurin:21-jdk AS base
RUN echo "jenkins:x:4040:7001:guest:/home/jenkins:/sbin/nologin" >> /etc/passwd && \
    mkdir /home/jenkins && chmod 777 /home/jenkins && \ 
    apt -y update && apt -y upgrade && \
    apt -y install git openssh-server zip unzip r-base-core bash curl python3-pip python3-venv

FROM base AS moobench-default
RUN echo "MooBench base image without Cloudprofiler"

FROM base AS moobench-cloudprofiler
ARG SQUASH_REPO="https://github.com/shinhyungyang/squash.git"
ARG CP_REPO="https://github.com/shinhyungyang/cloud_profiler.git"
ARG CP_INSTALL_PATH="/opt/cloud_profiler/0.3.2"

RUN apt -y install cmake pkgconf swig g++ cppzmq-dev libpapi-dev libboost-all-dev

RUN mkdir /git && mkdir /build && mkdir /build/squash /build/cp && \
    mkdir -p "${CP_INSTALL_PATH}"

RUN cd /git && \
    git clone ${SQUASH_REPO} --branch alpine --recursive --depth 1 && \
    mkdir /build/squash/build_release && cd /build/squash/build_release && \
    cmake /git/squash && make -j$(nproc) install

RUN cd /git && \
    git clone ${CP_REPO} --branch moobench-ci --depth 1 cp && \
    mkdir /build/cp/build_release && cd /build/cp/build_release && \
    cmake /git/cp -DCMAKE_INSTALL_PREFIX:PATH=${CP_INSTALL_PATH} && \
    make -j$(nproc) install && \
    bin/cp_cppbuffertest -t$(nproc)

RUN rm -rf /{git,build} /tmp/cloud*txt /tmp/md0/cloud*txt

RUN echo "MooBench base image with support for Cloudprofiler"

FROM moobench-${DOCKER_IMAGE_TYPE} AS final
