FROM debian:jessie
MAINTAINER Matt Bentley <mbentley@mbentley.net>

ENV NETATALK_VERSION 3.1.10

RUN apt-get update &&\
  apt-get install -y avahi-daemon supervisor &&\
  apt-get install -y --no-install-recommends build-essential curl libavahi-common-dev libavahi-client-dev libcrack2-dev libssl-dev libgcrypt11-dev libkrb5-dev libpam0g-dev libwrap0-dev libdb-dev libmysqlclient-dev libacl1-dev libldap2-dev tracker &&\
  mkdir -p /tmp/netatalk-${NETATALK_VERSION} &&\
  cd /tmp/netatalk-${NETATALK_VERSION} &&\
  curl "http://download.openpkg.org/components/cache/netatalk/netatalk-${NETATALK_VERSION}.tar.bz2" \
  | tar xj --directory "/tmp/netatalk-${NETATALK_VERSION}" --strip-components=1 &&\
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
  apt-get purge -y build-essential curl libavahi-common-dev libavahi-client-dev libcrack2-dev libssl-dev libgcrypt11-dev libkrb5-dev libpam0g-dev libwrap0-dev libdb-dev libmysqlclient-dev libacl1-dev libldap2-dev tracker &&\
  apt-get install -y libavahi-client3 libcrack2 libldap-2.4-2 libmysqlclient18 libwrap0 &&\
  apt-get -y autoremove &&\
  rm -rf /var/lib/apt/lists/* &&\
  cd &&\
  mkdir /var/run/dbus &&\
  rm -rf /tmp/*

RUN useradd -d /opt/timemachine -m timemachine &&\
  echo timemachine:timemachine | chpasswd

COPY afp.conf /etc/netatalk/afp.conf
COPY entrypoint.sh /entrypoint.sh
COPY supervisord.conf /etc/supervisord.conf

EXPOSE 548
VOLUME ["/opt/timemachine","/var/log/"]
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord","-c","/etc/supervisord.conf"]
