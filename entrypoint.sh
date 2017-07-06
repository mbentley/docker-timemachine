#!/bin/bash

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
