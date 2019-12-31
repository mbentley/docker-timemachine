#!/bin/sh

# set default values
VOLUME_SIZE_LIMIT="${VOLUME_SIZE_LIMIT:-0}"
LOG_LEVEL="${LOG_LEVEL:-info}"
SET_PERMISSIONS="${SET_PERMISSIONS:-false}"
SHARE_NAME="${SHARE_NAME:-TimeMachine}"
CUSTOM_AFP_CONF="${CUSTOM_AFP_CONF:-false}"
CUSTOM_SMB_CONF="${CUSTOM_SMB_CONF:-false}"
CUSTOM_USER="${CUSTOM_USER:-false}"
TM_USERNAME="${TM_USERNAME:-timemachine}"
PASSWORD="${PASSWORD:-timemachine}"
TM_GROUPNAME="${TM_GROUPNAME:-timemachine}"
TM_UID="${TM_UID:-1000}"
TM_GID="${TM_GID:-${TM_UID}}"
WORKGROUP="${WORKGROUP:-WORKGROUP}"

# common functions
set_password() {
  # check to see what the password should be set to
  if [ "${PASSWORD}" = "timemachine" ]
  then
      echo "INFO: Using default password: timemachine"
  else
      echo "INFO: Setting password from environment variable"
  fi

  # set the password
  echo "${TM_USERNAME}":"${PASSWORD}" | chpasswd
}

samba_user_setup() {
  # set up user in Samba
  smbpasswd -L -a -n "${TM_USERNAME}"
  smbpasswd -L -e -n "${TM_USERNAME}"
  printf "%s\n%s\n" "${PASSWORD}" "${PASSWORD}" | smbpasswd -L -s "${TM_USERNAME}"
}

create_user_directory() {
  # create user directory if needed
  if [ ! -d "/opt/${TM_USERNAME}" ]
  then
    mkdir "/opt/${TM_USERNAME}"
  fi
}

# check to see if if we are using the alpine or debian base images (debian version uses AFP; alpine uses SMB)
#   this is needed because of differences in syntax for adding groups and users
if [ -z "${NETATALK_VERSION}" ]
then
  # this is the SMB version running alpine

  # set default version for timecapsule w/SMB
  MIMIC_MODEL="${MIMIC_MODEL:-TimeCapsule8,119}"

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
      addgroup -g "${TM_GID}" "${TM_GROUPNAME}"
    fi

    # check to see if user exists; if not, create it
    if id -u "${TM_USERNAME}" > /dev/null 2>&1
    then
      echo "INFO: User exists; skipping creation"
    else
      echo "INFO: User doesn't exist; creating..."
      # create the user
      adduser -u "${TM_UID}" -G "${TM_GROUPNAME}" -h "/opt/${TM_USERNAME}" -s /bin/false -D "${TM_USERNAME}"

      # set the user's password if necessary
      set_password
    fi

    # create user directory if necessary
    create_user_directory
  else
    echo "INFO: CUSTOM_USER=true; skipping user, group, and data directory creation; using pre-existing values in /etc/passwd, /etc/group, and /etc/shadow"
  fi

  # warn about ${VOLUME_SIZE_LIMIT} if set to non-zero
  if [ "${VOLUME_SIZE_LIMIT}" != "0" ]
  then
    echo "WARNING: VOLUME_SIZE_LIMIT has been set to ${VOLUME_SIZE_LIMIT} but SMB doesn't support quotas; ignoring setting"
  fi

  # write smb.conf if CUSTOM_SMB_CONF is not true
  if [ "${CUSTOM_SMB_CONF}" != "true" ]
  then
    echo "INFO: CUSTOM_SMB_CONF=false; generating /etc/samba/smb.conf..."
    echo "[global]
      server role = standalone server
      workgroup = ${WORKGROUP}
      unix password sync = yes
      idmap config * : backend = tbd
      logging = file@2
      log file = /var/log/samba/log.%m
      security = user
      load printers = no
      fruit:model = ${MIMIC_MODEL}

      [${SHARE_NAME}]
        fruit:aapl = yes
	fruit:time machine = yes
	path = /opt/${TM_USERNAME}
	valid users = ${TM_USERNAME}
	browseable = yes
	writable = yes
	kernel oplocks = no
	kernel share modes = no
	posix locking = no
	vfs objects = catia fruit streams_xattr" > /etc/samba/smb.conf
  else
    # CUSTOM_SMB_CONF was specified; make sure the file exists
    if [ -f "/etc/samba/smb.conf" ]
    then
      echo "INFO: CUSTOM_SMB_CONF=true; skipping generating smb.conf and using provided /etc/samba/smb.conf"
    else
      # there is no /etc/samba/smbp.conf; exit
      echo "ERROR: CUSTOM_SMB_CONF=true but you did not bind mount a config to /etc/samba/smb.conf; exiting."
      exit 1
    fi
  fi

  # set up user in Samba
  samba_user_setup

  # cleanup PID files
  for PIDFILE in nmbd smbd winbindd
  do
    if [ -f /run/samba/${PIDFILE}.pid ]
    then
      echo "INFO: ${PIDFILE} PID exists; removing..."
      rm -v /run/samba/${PIDFILE}.pid
    fi
  done

  # cleanup dbus PID file
  if [ -f /run/dbus.pid ]
  then
    echo "INFO: dbus PID exists; removing..."
    rm -v /run/dbus.pid
  fi

  # cleanup avahi PID file
  if [ -f /run/avahi-daemon/pid ]
  then
    echo "INFO: avahi PID exists; removing..."
    rm -v /run/avahi-daemon/pid
  fi
else
  # this is the AFP version running debian

  # set default version for timecapsule w/AFP
  MIMIC_MODEL="${MIMIC_MODEL:-TimeCapsule6,106}"

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

      # set the user's password if necessary
      set_password
    fi

    # create user directory if necessary
    create_user_directory
  else
    echo "INFO: CUSTOM_USER=true; skipping user, group, and data directory creation; using pre-existing values in /etc/passwd, /etc/group, and /etc/shadow"
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
    echo "INFO: CUSTOM_AFP_CONF=false; generating /etc/netatalk/afp.conf..."
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
  else
    # CUSTOM_AFP_CONF was specified; make sure the file exists
    if [ -f "/etc/netatalk/afp.conf" ]
    then
      echo "INFO: CUSTOM_AFP_CONF=true; skipping generating afp.conf and using provided /etc/netatalk/afp.conf"
    else
      # there is no /etc/netatalk/afp.conf; exit
      echo "ERROR: CUSTOM_AFP_CONF=true but you did not bind mount a config to /etc/netatalk/afp.conf; exiting."
      exit 1
    fi
  fi

  # cleanup dbus PID file
  if [ -f /var/run/dbus/pid ]
  then
    echo "INFO: dbus PID exists; removing..."
    rm -v /var/run/dbus/pid
  fi

  # cleanup netatalk PID file
  if [ -f /var/run/netatalk.pid ]
  then
    echo "INFO: netatalk PID exists; removing..."
    rm -v /var/run/netatalk.pid
  fi

  # cleanup avahi-daemon PID file
  if [ -f /var/run/avahi-daemon/pid ]
  then
    echo "INFO: avahi-daemon PID exists; removing..."
    rm -v /var/run/avahi-daemon/pid
  fi
fi

# common tasks
# set ownership and permissions, if requested
if [ "${SET_PERMISSIONS}" = "true" ]
then
  # set the ownership of the directory time machine will use
  chown -v "${TM_USERNAME}":"${TM_GROUPNAME}" "/opt/${TM_USERNAME}"

  # change the permissions of the directory time machine will use
  chmod -v 770 "/opt/${TM_USERNAME}"
else
  echo "INFO: SET_PERMISSIONS=false; not setting ownership and permissions"
fi

# run CMD
exec "${@}"
