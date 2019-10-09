#!/bin/bash

# set default values
MIMIC_MODEL="${MIMIC_MODEL:-TimeCapsule6,106}"
VOLUME_SIZE_LIMIT="${VOLUME_SIZE_LIMIT:-0}"
LOG_LEVEL="${LOG_LEVEL:-info}"
SET_PERMISSIONS="${SET_PERMISSIONS:-false}"
SHARE_NAME="${SHARE_NAME:-TimeMachine}"
CUSTOM_AFP_CONF="${CUSTOM_AFP_CONF:-false}"
CUSTOM_USER="${CUSTOM_USER:-false}"
TM_USERNAME="${TM_USERNAME:-timemachine}"
PASSWORD="${PASSWORD:-timemachine}"
TM_GROUPNAME="${TM_GROUPNAME:-timemachine}"
TM_UID="${TM_UID:-1000}"
TM_GID="${TM_GID:-${TM_UID}}"

# create custom user, group, and directories if CUSTOM_USER is not true
if [ "${CUSTOM_USER}" != "true" ]
then
  # check to see if group exists; if not, create it
  if grep -q -E "^${TM_GROUPNAME}:" /etc/group > /dev/null 2>&1
  then
    echo "INFO: Group exists; skipping creation"
  else
    echo "INFO: Group doesn't exist; creating..."
    # create the group
    groupadd -g "${TM_GID}" "${TM_GROUPNAME}"
  fi

  # check to see if user exists; if not, create it
  if id -u "${TM_USERNAME}" > /dev/null 2>&1
  then
    echo "INFO: User exists; skipping creation"
  else
    echo "INFO: User doesn't exist; creating..."
    # create the user
    useradd -u "${TM_UID}" -g "${TM_GROUPNAME}" -d "/opt/${TM_USERNAME}" -s /bin/false "${TM_USERNAME}"

    # check to see what the password should be set to
    if [ "${PASSWORD}" = "timemachine" ]
    then
        echo "Using default password: timemachine"
    else
        echo "Setting password from environment variable"
    fi

    # set the password
    echo "${TM_USERNAME}":"${PASSWORD}" | chpasswd
  fi

  # create user directory if needed
  if [ ! -d "/opt/${TM_USERNAME}" ]
  then
    mkdir "/opt/${TM_USERNAME}"
  fi
else
  echo "CUSTOM_USER=true; skipping user, group, and data directory creation; using pre-existing values in /etc/passwd, /etc/group, and /etc/shadow"
fi

# mkdir if needed
if [ ! -d "/etc/netatalk" ]
then
  mkdir /etc/netatalk
fi

# mkdir if needed
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
    path = /opt/${TM_USERNAME}
    valid users = ${TM_USERNAME}
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

# set ownership and permissions, if requested
if [ "${SET_PERMISSIONS}" = "true" ]
then
  # set the ownership of the directory time machine will use
  chown -v "${TM_USERNAME}":"${TM_GROUPNAME}" "/opt/${TM_USERNAME}"

  # change the permissions of the directory time machine will use
  chmod -v 770 "/opt/${TM_USERNAME}"
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
