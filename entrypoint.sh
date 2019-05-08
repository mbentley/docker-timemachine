#!/bin/bash

# set default values
MIMIC_MODEL="${MIMIC_MODEL:-TimeCapsule6,106}"
VOLUME_SIZE_LIMIT="${VOLUME_SIZE_LIMIT:-0}"
LOG_LEVEL="${LOG_LEVEL:-info}"
PASSWORD="${PASSWORD:-timemachine}"
SET_PERMISSIONS="${SET_PERMISSIONS:-false}"
SHARE_NAME="${SHARE_NAME:-TimeMachine}"
CUSTOM_AFP_CONF="${CUSTOM_AFP_CONF:-false}"

# mkdir if needed
if [ ! -d "/etc/netatalk" ]
then
  mkdir /etc/netatalk
fi

if [ ! -d "/var/netatalk/CNID" ]
then
  mkdir /var/netatalk/CNID
fi


# write afp.conf if CUSTOM_AFP_CONF is not true
if [ "${CUSTOM_AFP_CONF}" != "true" ]
then
  echo -n "CUSTOM_AFP_CONF=false; generating /etc/netatalk/afp.conf..."
  echo "[Global]
    mimic model = ${MIMIC_MODEL}
    log level = default:${LOG_LEVEL}
    log file = /dev/stdout
    zeroconf = yes

  [${SHARE_NAME}]
    path = /opt/timemachine
    valid users = timemachine
    time machine = yes
    # the max size of the data folder (in MiB)
    vol size limit = ${VOLUME_SIZE_LIMIT}" > /etc/netatalk/afp.conf
    echo "done"
else
  # CUSTOM_AFP_CONF was specified; make sure the file exists
  if [ -f "/etc/netatalk/afp.conf" ]
  then
    echo "CUSTOM_AFP_CONF=true; skipping generating afp.conf and using provided /etc/netatalk/afp.conf"
  else
    # there is no /etc/netatalk/afp.conf; exit
    echo "CUSTOM_AFP_CONF=true but you did not bind mount a config to /etc/netatalk/afp.conf; exiting."
    exit 1
  fi
fi

# set password if defined
if [ "${PASSWORD}" = "timemachine" ]
then
    echo "Using default password: timemachine"
else
    echo "Setting password from environment variable"
    echo timemachine:"${PASSWORD}" | chpasswd
fi

# set ownership and permissions, if requested
if [ "${SET_PERMISSIONS}" = "true" ]
then
  # set the ownership of /opt/timemachine
  chown -v timemachine:timemachine /opt/timemachine
  # change the permissions of /opt/timemachine
  chmod -v 770 /opt/timemachine
else
  echo "SET_PERMISSIONS=false; not setting ownership and permissions"
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
