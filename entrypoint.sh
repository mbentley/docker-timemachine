#!/bin/bash

# let user know that there is a limit set
if [ ! -z "${VOLUME_SIZE_LIMIT}" ]
then
  echo "'vol size limit' will be set to ${VOLUME_SIZE_LIMIT} MB"
else
  echo "'vol size limit' will not be set; no value provided"
fi

# function to write volume size limit; if set
volume_limit_size() {
  if [ ! -z "${VOLUME_SIZE_LIMIT}" ]
  then
    echo "  # the max size of the data folder (in MB)"
    echo "  vol size limit = ${VOLUME_SIZE_LIMIT}"
  fi
}

# mkdir if needed
if [ ! -d "/etc/netatalk" ]
then
  mkdir /etc/netatalk
fi

# write afp.conf
echo "[Global]
  mimic model = TimeCapsule6,106
  log level = default:info
  log file = /dev/stdout
  zeroconf = yes

[TimeMachine]
  path = /opt/timemachine
  valid users = timemachine
  time machine = yes
$(volume_limit_size)" > /etc/netatalk/afp.conf

# set password if defined
if [ -z "${PASSWORD}" ]
then
    echo "Using default password: timemachine"
else
    echo "Setting password from environment variable"
    echo timemachine:"${PASSWORD}" | chpasswd
fi

# cleanup dbus PID file
if [ -f /var/run/dbus/pid ]
then
  echo "dbus PID exists; removing..."
  rm -v /var/run/dbus/pid
fi

# cleanup netatalk PID file
if [ -f /var/run/netatalk.pid ]
then
  echo "netatalk PID exists; removing..."
  rm -v /var/run/netatalk.pid
fi

# cleanup avahi-daemon PID file
if [ -f /var/run/avahi-daemon/pid ]
then
  echo "avahi-daemon PID exists; removing..."
  rm -v /var/run/avahi-daemon/pid
fi

# run CMD
exec "${@}"
