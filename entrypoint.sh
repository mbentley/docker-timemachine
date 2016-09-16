#!/bin/bash

# set password if defined
if [ -z "${PASSWORD}" ]
then
    echo "Using default password: timemachine"
else
    echo "Setting password from environment variable"
    echo timemachine:$PASSWORD | chpasswd
fi

# run CMD
exec "${@}"
