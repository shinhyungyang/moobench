#FROM openjdk:13-jdk-alpine
FROM eclipse-temurin:21-jdk

USER root
RUN echo "jenkins:x:4040:7001:guest:/home/jenkins:/sbin/nologin" >> /etc/passwd && \
    mkdir /home/jenkins && chmod 777 /home/jenkins && \ 
    apt -y update && apt -y upgrade && \
    apt -y install git openssh-server zip unzip r-base-core bash curl python3-pip python3-venv

RUN apt -y install libboost-all-dev cmake cppzmq-dev g++ libpapi-dev pkgconf swig

RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

RUN systemctl enable ssh
RUN useradd -m -s /bin/bash sya
RUN echo "sya:insecure_password" | chpasswd

EXPOSE 22

ENTRYPOINT ['systemctl', 'start', 'ssh']
