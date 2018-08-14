#!/bin/bash

# set default values
MIMIC_MODEL="${MIMIC_MODEL:-TimeCapsule6,106}"
VOLUME_SIZE_LIMIT="${VOLUME_SIZE_LIMIT:-0}"
LOG_LEVEL="${LOG_LEVEL:-info}"
PASSWORD="${PASSWORD:-timemachine}"

# mkdir if needed
if [ ! -d "/etc/netatalk" ]
then
  mkdir /etc/netatalk
fi

# write afp.conf
echo "[Global]
  mimic model = ${MIMIC_MODEL}
  log level = default:${LOG_LEVEL}
  log file = /dev/stdout
  zeroconf = yes

[TimeMachine]
  path = /opt/timemachine
  valid users = timemachine
  time machine = yes
  # the max size of the data folder (in MB)
  vol size limit = ${VOLUME_SIZE_LIMIT}" > /etc/netatalk/afp.conf

# set password if defined
if [ "${PASSWORD}" = "timemachine" ]
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
