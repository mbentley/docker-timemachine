FROM alpine:latest
MAINTAINER Matt Bentley <mbentley@mbentley.net>

# install samba and supervisor; create supporting directories
RUN apk add --no-cache avahi avahi-compat-libdns_sd avahi-tools dbus samba-common-tools samba-server supervisor &&\
  mkdir /var/log/supervisor &&\
  mkdir /opt/timemachine &&\
  touch /etc/samba/lmhosts &&\
  rm /etc/samba/smb.conf &&\
  rm /etc/avahi/services/*.service

# copy in necessary supporting config files
COPY supervisord.smb.conf /etc/supervisord.conf
COPY entrypoint.sh /

VOLUME ["/var/log","/var/lib/samba","/var/cache/samba","/run/samba"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord","-c","/etc/supervisord.conf"]
