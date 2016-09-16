#!/bin/bash

# dbus
dbus-daemon --system

# avahi
avahi-daemon --no-chroot -D

# netatalk

# set password if defined (docker run -e "PASSWORD=asdf")
if [ -z "${PASSWORD}" ]
then
    echo Using default password: timemachine
else
    echo Setting password from environment variable
    echo timemachine:$PASSWORD | chpasswd
fi

# run in foreground
exec netatalk -F /etc/netatalk/afp.conf -d
