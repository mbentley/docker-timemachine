#!/bin/sh

# set default values
LOG_LEVEL="${LOG_LEVEL:-info}"
SET_PERMISSIONS="${SET_PERMISSIONS:-false}"
SHARE_NAME="${SHARE_NAME:-TimeMachine}"
CUSTOM_AFP_CONF="${CUSTOM_AFP_CONF:-false}"
CUSTOM_SMB_CONF="${CUSTOM_SMB_CONF:-false}"
CUSTOM_USER="${CUSTOM_USER:-false}"
TM_USERNAME="${TM_USERNAME:-timemachine}"
TM_GROUPNAME="${TM_GROUPNAME:-timemachine}"
TM_UID="${TM_UID:-1000}"
TM_GID="${TM_GID:-${TM_UID}}"
VOLUME_SIZE_LIMIT="${VOLUME_SIZE_LIMIT:-0}"
WORKGROUP="${WORKGROUP:-WORKGROUP}"
EXTERNAL_CONF="${EXTERNAL_CONF:-}"
HIDE_SHARES="${HIDE_SHARES:-no}"

# common functions
set_password() {
  # check PASSWORD and PASSWORD_FILE are both not set
  if [ ! -z "${PASSWORD}" ]
  then
    if [ ! -z "${PASSWORD_FILE}" ]
    then
      echo "ERROR: PASSSWORD and PASSWORD_FILE can not both be set. Please choose 1"
      exit 1
    fi
  fi

  PASSWORD="${PASSWORD:-timemachine}"

  if [ ! -z "${PASSWORD_FILE}" ]
  then
    PASSWORD="$(cat $PASSWORD_FILE)"
  fi

  # check to see what the password should be set to
  if [ "${PASSWORD}" = "timemachine" ]
  then
      echo "INFO: Using default password: timemachine"
  else
      echo "INFO: Setting password from environment variable"
  fi

  # set the password
  printf "INFO: "
  echo "${TM_USERNAME}":"${PASSWORD}" | chpasswd
}

samba_user_setup() {
  # set up user in Samba
  printf "INFO: Samba - Created "
  smbpasswd -L -a -n "${TM_USERNAME}"
  printf "INFO: Samba - "
  smbpasswd -L -e -n "${TM_USERNAME}"
  printf "INFO: Samba - setting password\n"
  printf "%s\n%s\n" "${PASSWORD}" "${PASSWORD}" | smbpasswd -L -s "${TM_USERNAME}"
}

create_user_directory() {
  # create user directory if needed
  if [ ! -d "/opt/${TM_USERNAME}" ]
  then
    mkdir "/opt/${TM_USERNAME}"
  fi
}

createdir() {
  # create directory if needed
  if [ ! -d "${1}" ]; then
    echo "Creating ${1}"
    mkdir -p "${1}"
  fi
  if [ -n "${2}" ]; then
    chmod "${2}" "${1}"
  fi
}

create_smb_user() {
  # validate that none of the required environment variables are empty
  if [ -z "${TM_USERNAME}" ] || [ -z "${TM_GROUPNAME}" ] || [ -z "${PASSWORD}" ] || [ -z "${SHARE_NAME}" ] || [ -z "${TM_UID}" ] || [ -z "${TM_GID}" ]
  then
    echo "ERROR: Missing one or more of the following variables; unable to create user"
    echo "  Hint: Is the variable missing or not set in ${USER_FILE}?"
    echo "  TM_USERNAME=${TM_USERNAME}"
    echo "  TM_GROUPNAME=${TM_GROUPNAME}"
    echo "  PASSWORD=$(if [ -n "${PASSWORD}" ]; then printf "<value reddacted but present>";fi)"
    echo "  SHARE_NAME=${SHARE_NAME}"
    echo "  TM_UID=${TM_UID}"
    echo "  TM_GID=${TM_GID}"
    exit 1
  fi

  # create custom user, group, and directories if CUSTOM_USER is not true
  if [ "${CUSTOM_USER}" != "true" ]
  then
    # check to see if group exists; if not, create it
    if grep -q -E "^${TM_GROUPNAME}:" /etc/group > /dev/null 2>&1
    then
      echo "INFO: Group ${TM_GROUPNAME} exists; skipping creation"
    else
      echo "INFO: Group ${TM_GROUPNAME} doesn't exist; creating..."
      # create the group
      addgroup -g "${TM_GID}" "${TM_GROUPNAME}"
    fi

    # check to see if user exists; if not, create it
    if id -u "${TM_USERNAME}" > /dev/null 2>&1
    then
      echo "INFO: User ${TM_USERNAME} exists; skipping creation"
    else
      echo "INFO: User ${TM_USERNAME} doesn't exist; creating..."
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

  # write smb.conf if CUSTOM_SMB_CONF is not true
  if [ "${CUSTOM_SMB_CONF}" != "true" ]
  then
    echo "INFO: CUSTOM_SMB_CONF=false; generating [${SHARE_NAME}] section of /etc/samba/smb.conf..."
    echo "
[${SHARE_NAME}]
   fruit:aapl = yes
   fruit:time machine = yes
   fruit:time machine max size = ${VOLUME_SIZE_LIMIT}
   path = /opt/${TM_USERNAME}
   valid users = ${TM_USERNAME}
   browseable = yes
   writable = yes
   vfs objects = catia fruit streams_xattr" >> /etc/samba/smb.conf
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

  # set user permissions
  set_permissions
}

set_permissions() {
  # set ownership and permissions, if requested
  if [ "${SET_PERMISSIONS}" = "true" ]
  then
    # set the ownership of the directory time machine will use
    printf "INFO: "
    chown -v "${TM_USERNAME}":"${TM_GROUPNAME}" "/opt/${TM_USERNAME}"

    # change the permissions of the directory time machine will use
    printf "INFO: "
    chmod -v 770 "/opt/${TM_USERNAME}"
  else
    echo "INFO: SET_PERMISSIONS=false; not setting ownership and permissions for /opt/${TM_USERNAME}"
  fi
}

# check to see if if we are using the alpine or debian base images (debian version uses AFP; alpine uses SMB)
#   this is needed because of differences in syntax for adding groups and users
if [ -z "${NETATALK_VERSION}" ]
then
  # this is the SMB version running alpine

  # set default version for timecapsule w/SMB
  MIMIC_MODEL="${MIMIC_MODEL:-TimeCapsule8,119}"

  # write smbd.service for Avahi to customize icon
  echo "<?xml version=\"1.0\" standalone='no'?><!--*-nxml-*-->
<!DOCTYPE service-group SYSTEM \"avahi-service.dtd\">

<service-group>
  <name replace-wildcards=\"yes\">%h</name>
  <service>
    <type>_smb._tcp</type>
    <port>445</port>
  </service>
  <service>
    <type>_device-info._tcp</type>
    <port>0</port>
  <txt-record>model=${MIMIC_MODEL}</txt-record>
  </service>
</service-group>" > /etc/avahi/services/smbd.service

  # write global smb.conf if CUSTOM_SMB_CONF is not true
  if [ "${CUSTOM_SMB_CONF}" != "true" ]
  then
    echo "INFO: CUSTOM_SMB_CONF=false; generating [global] section of /etc/samba/smb.conf..."
    echo "[global]
   server role = standalone server
   workgroup = ${WORKGROUP}
   unix password sync = yes
   log file = /var/log/samba/log.%m
   logging = file
   max log size = 1000
   security = user
   load printers = no
   access based share enum = ${HIDE_SHARES}
   hide unreadable = ${HIDE_SHARES}
   fruit:model = ${MIMIC_MODEL}" > /etc/samba/smb.conf
  fi

  # mkdir if needed
  createdir /var/lib/samba/private 700
  createdir /var/log/samba/cores 700

  # check to see if we should create one or many users
  if [ -z "${EXTERNAL_CONF}" ]
  then
    # EXTERNAL_CONF not set; assume we are creating one user; create user
    create_smb_user
  else
    # EXTERNAL_CONF is set; assume we are creating multiple users
    if [ ! -d "${EXTERNAL_CONF}" ]
    then
      echo "ERROR: The value of EXTERNAL_CONF should be a directory mounted inside the container; ${EXTERNAL_CONF} was not found"
      exit 1
    fi

    # loop through each user file in the EXTERNAL_CONF directory to load the variables
    for USER_FILE in "${EXTERNAL_CONF}"/*
    do
      echo "INFO: Loading values from ${USER_FILE}"
      # source the variable file
      # shellcheck disable=SC1090
      . "${USER_FILE}"

      # create the user with the specified values
      create_smb_user

      # make sure we clear any previously set variables after a loop
      unset TM_USERNAME TM_GROUPNAME PASSWORD SHARE_NAME VOLUME_SIZE_LIMIT TM_UID TM_GID
    done
  fi

  # cleanup PID files
  for PIDFILE in nmbd smbd
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
  createdir /etc/netatalk
  createdir /var/netatalk/CNID

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

  # set user permissions
  set_permissions

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

# run CMD
echo "INFO: entrypoint complete; executing '${*}'"
exec "${@}"
