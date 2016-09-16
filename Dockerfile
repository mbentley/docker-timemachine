FROM debian:sid
MAINTAINER Matt Bentley <mbentley@mbentley.net>

#RUN apt-get update && apt-get install -y netatalk avahi-daemon && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y avahi-daemon && rm -rf /var/lib/apt/lists/*

ENV NETATALK_VERSION 3.1.7

RUN apt-get update &&\
  apt-get install -y --no-install-recommends curl tracker build-essential libavahi-common-dev libavahi-client-dev libcrack2-dev libssl-dev libgcrypt11-dev libkrb5-dev libpam0g-dev libwrap0-dev libdb-dev libmysqlclient-dev libacl1-dev libldap2-dev &&\
  mkdir -p "/usr/src/netatalk/netatalk-${NETATALK_VERSION}" &&\
  cd "/usr/src/netatalk/netatalk-${NETATALK_VERSION}" &&\
  curl "http://download.openpkg.org/components/cache/netatalk/netatalk-${NETATALK_VERSION}.tar.bz2" \
  | tar xj --directory "/usr/src/netatalk/netatalk-${NETATALK_VERSION}" --strip-components=1 &&\
  ./configure \
    --with-init-style=debian-sysv \
    --with-cracklib \
    --with-acls \
    --enable-fhs \
    --enable-krbV-uam \
    --with-pam-confdir=/etc/pam.d \
    --with-dbus-sysconf-dir=/etc/dbus-1/system.d \
    --with-tracker-pkgconfig-version=0.16 &&\
  make &&\
  make install &&\
  apt-get -y autoremove &&\
  apt-get -y clean &&\
  rm -rf /var/lib/apt/lists/* &&\
  rm -rf /tmp/*

RUN useradd -d /backup -m timemachine &&\
  echo timemachine:timemachine | chpasswd

RUN mkdir /var/run/dbus

COPY afp.conf /etc/netatalk/afp.conf
COPY entrypoint.sh /entrypoint.sh

VOLUME ["/backup"]
EXPOSE 548
CMD ["/entrypoint.sh"]
