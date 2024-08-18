# syntax=docker/dockerfile:1

FROM ghcr.io/imagegenius/baseimage-ubuntu:noble

# set version label
ARG BUILD_DATE
ARG VERSION
ARG PAPERCUT_VERSION=24.0.3.69939
LABEL build_version="ImageGenius Version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="hydazz"

# environment settings
ENV MYSQL_CONNECTOR_VERSION=9.0.0 \
    HOME=/papercut

RUN \
  echo "**** install runtime packages ****" && \
  apt-get update && \
  apt-get install --no-install-recommends -y \
    curl \
    cpio \
    sudo \
    cups && \
  echo "**** install MySQL connector ****" && \
  curl -o \
    /tmp/mysql.tar.gz -L \
    "https://cdn.mysql.com/Downloads/Connector-J/mysql-connector-j-${MYSQL_CONNECTOR_VERSION}.tar.gz" && \
  tar xf \
    /tmp/mysql.tar.gz -C \
    /tmp && \
  echo "**** setup papercut ****" && \
  useradd -U -s /bin/bash papercut && \
  mkdir -p /papercut && \
  chown papercut:papercut /papercut && \
  PAPERCUT_MAJOR_VERSION="$(echo ${PAPERCUT_VERSION} | cut -d'.' -f1).x" && \
  curl -o \
    /tmp/pcmf-setup.sh -L \
    "https://cdn1.papercut.com/web/products/ng-mf/installers/mf/${PAPERCUT_MAJOR_VERSION}/pcmf-setup-${PAPERCUT_VERSION}.sh" && \
  chmod +x /tmp/pcmf-setup.sh && \
  s6-setuidgid papercut /tmp/pcmf-setup.sh --non-interactive && \
  /papercut/MUST-RUN-AS-ROOT && \
  /etc/init.d/papercut stop && \
  /etc/init.d/papercut-web-print stop && \
  mv /tmp/mysql-connector-j-${MYSQL_CONNECTOR_VERSION}/mysql-connector-j-${MYSQL_CONNECTOR_VERSION}.jar /papercut/server/lib-ext/ && \
  mkdir -p /defaults/data/ && \
  for i in data/conf custom logs data/backups; do \
    mv /papercut/server/${i} /defaults/${i}; \
  done && \
  echo "**** cleanup ****" && \
  apt-get autoremove -y && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 9191 9192 9193
VOLUME /config
