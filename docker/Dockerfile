#FROM openjdk:13-jdk-alpine
FROM eclipse-temurin:21-jdk
ARG BUILD_CP

RUN echo "jenkins:x:4040:7001:guest:/home/jenkins:/sbin/nologin" >> /etc/passwd && \
    mkdir /home/jenkins && chmod 777 /home/jenkins && \ 
    apt -y update && apt -y upgrade && \
    apt -y install git openssh-server zip unzip r-base-core bash curl python3-pip python3-venv

RUN if [[ -z "${BUILD_CP}" ]] ; then echo "No argument provided" ; else echo "BUILD_CP=${BUILD_CP}" ; fi
