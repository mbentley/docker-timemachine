# mbentley/timemachine

docker image to run Samba or AFP (netatalk) to provide a compatible Time Machine for MacOS

## Tags

* `latest`, `afp` - AFP image based off of debian:jessie
* `smb` - SMB image based off of alpine:latest

_Warning_: I would strongly suggest migrating to the SMB image as AFP is being deprecated by Apple and I've found it to be much more stable.  I do not plan on adding any new features to the AFP based config.

To pull this image:
`docker pull mbentley/timemachine:smb`

## Example usage for SMB

Example usage with `--net=host` to allow Avahi discovery; all available environment variables set to their default values:

```
docker run -d --restart=always \
  --name timemachine \
  --net=host \
  -e CUSTOM_SMB_CONF="false" \
  -e CUSTOM_USER="false" \
  -e DEBUG_LEVEL="1" \
  -e MIMIC_MODEL="TimeCapsule8,119" \
  -e EXTERNAL_CONF="" \
  -e HIDE_SHARES="no" \
  -e TM_USERNAME="timemachine" \
  -e TM_GROUPNAME="timemachine" \
  -e TM_UID="1000" \
  -e TM_GID="1000" \
  -e PASSWORD="timemachine" \
  -e SET_PERMISSIONS="false" \
  -e SHARE_NAME="TimeMachine" \
  -e VOLUME_SIZE_LIMIT="0" \
  -e WORKGROUP="WORKGROUP" \
  -v /path/on/host/to/backup/to/for/timemachine:/opt/timemachine \
  -v timemachine-var-lib-samba:/var/lib/samba \
  -v timemachine-var-cache-samba:/var/cache/samba \
  -v timemachine-run-samba:/run/samba \
  mbentley/timemachine:smb
```

Example usage with exposing ports _without_ Avahi discovery; all available environment variables set to their default values:

```
docker run -d --restart=always \
  --name timemachine \
  --hostname timemachine \
  -p 137:137/udp \
  -p 138:138/udp \
  -p 139:139 \
  -p 445:445 \
  -e CUSTOM_SMB_CONF="false" \
  -e CUSTOM_USER="false" \
  -e DEBUG_LEVEL="1" \
  -e HIDE_SHARES="no" \
  -e EXTERNAL_CONF="" \
  -e MIMIC_MODEL="TimeCapsule8,119" \
  -e TM_USERNAME="timemachine" \
  -e TM_GROUPNAME="timemachine" \
  -e TM_UID="1000" \
  -e TM_GID="1000" \
  -e PASSWORD="timemachine" \
  -e SET_PERMISSIONS="false" \
  -e SHARE_NAME="TimeMachine" \
  -e VOLUME_SIZE_LIMIT="0" \
  -e WORKGROUP="WORKGROUP" \
  -v /path/on/host/to/backup/to/for/timemachine:/opt/timemachine \
  -v timemachine-var-lib-samba:/var/lib/samba \
  -v timemachine-var-cache-samba:/var/cache/samba \
  -v timemachine-run-samba:/run/samba \
  mbentley/timemachine:smb
```

### Tips for Automatic Discovery w/Avahi

This works best with `--net=host` so that discovery can be broadcast.  Otherwise, you will need to expose the above ports and then you must manually map the share in Finder for it to show up (open `Finder`, click `Shared`, and connect as `smb://hostname-or-ip/TimeMachine` with your TimeMachine credentials).  Using `--net=host` only works if you do not already run Samba or Avahi on the host!  See below for a workaround.

### Conflicts with Samba and/or Avahi on the Host

__Note__: If you are already running Samba on your Docker host (or you're wanting to run this on your NAS), you should be aware that using `--net=host` will cause a conflict with the Samba install.  As an alternative, you can use the [`macvlan` driver in Docker](https://docs.docker.com/network/macvlan/) which will allow you to map a static IP address to your container.  If you have issues setting up Time Machine with the configuration, feel free to open an issue and I can assist - this is how I persoanlly run time machine.

1. Create a `macvlan` Docker network (assuming your local subnet is `192.168.0.0/24`, the default gateway is `192.168.0.1`, and `eth0` for the host's network interface):

    ``` bash
    $ docker network create -d macvlan --subnet=192.168.0.0/24 --gateway=192.168.0.1 -o parent=eth0 macvlan1
    ```

1. Add `--network macvlan1` and `--ip 192.168.0.x` to your `docker run` command where `192.168.0.x` is a static IP to assign to Time Machine

### Volume & File system Permissions

If you're using an external volume like in the example above, you will need to set the filesystem permissions on disk.  By default, the `timemachine` user is `1000:1000`.

Also note that if you change the `TM_USERNAME` value that it will change the data path from `/opt/timemachine` to `/opt/<value-of-TM_USERNAME>`.

Default credentials:

* Username: `timemachine`
* Password: `timemachine`

### Optional variables for SMB

| Variable | Default | Description |
| :------- | :------ | :---------- |
| `CUSTOM_SMB_CONF` | `false` | indicates that you are going to bind mount a custom config to `/etc/samba/smb.conf` if set to `true` |
| `CUSTOM_USER` | `false` | indicates that you are going to bind mount `/etc/password`, `/etc/group`, and `/etc/shadow`; and create data directories if set to `true` |
| `DEBUG_LEVEL` | `1` | sets the debug level for `nmbd` and `smbd` |
| `EXTERNAL_CONF` | _not set_ | specifies a directory in which individual variable files, ending in `.conf`, for multiple users; see [Adding Multiple Users & Shares](#adding-multiple-users--shares) for more info |
| `HIDE_SHARES` | `no` | set to `yes` if you would like only the share(s) a user can access to appear |
| `MIMIC_MODEL` | `TimeCapsule8,119` | sets the value of time machine to mimic |
| `TM_USERNAME` | `timemachine` | sets the username time machine runs as |
| `TM_GROUPNAME` | `timemachine` | sets the group name time machine runs as |
| `TM_UID` | `1000` | sets the UID of the `TM_USERNAME` user |
| `TM_GID` | `1000` | sets the GID of the `TM_GROUPNAME` group |
| `PASSWORD` | `timemachine` | sets the password for the `timemachine` user |
| `SET_PERMISSIONS` | `false` | set to `true` to have the entrypoint set ownership and permission on `/opt/timemachine` |
| `SHARE_NAME` | `TimeMachine` | sets the name of the timemachine share to TimeMachine by default |
| `VOLUME_SIZE_LIMIT` | `0` | sets the maximum size of the time machine backup; a unit can also be passed (e.g. - `1 T`). See the [Samba docs](https://www.samba.org/samba/docs/current/man-html/vfs_fruit.8.html) under the `fruit:time machine max size` section for more details |
| `WORKGROUP` | `WORKGROUP` | set the Samba workgroup name |

### Adding Multiple Users & Shares

In order to add multiple users who have their own shares, you will need to create a file for each user and put them in a directory. The file name __must__ end in `.conf` or it will not be parsed and the contents must be environment variable formatted proper and include all of the values below in the example.  Only `VOLUME_SIZE_LIMIT` can be empty if you do not want to set a quota.

#### Example `EXTERNAL_CONF` File

This is an example to create a user named `foo`.  The `EXTERNAL_CONF` variable should point to the _directory_ that contains the user definition files.  Create multiple files with different attributes to create multiple users and shares.

`foo.conf`

```
TM_USERNAME=foo
TM_GROUPNAME=foogroup
PASSWORD=foopass
SHARE_NAME=foo
VOLUME_SIZE_LIMIT="1 T"
TM_UID=1000
TM_GID=1000
```

#### Example run command for `EXTERNAL_CONF`

This run command has the necessary path to where the external user files will be mounted (set in `EXTERNAL_CONF`) and the volume mount that matches the path specified in `EXTERNAL_CONF`.

```
docker run -d --restart=always \
  --name timemachine \
  --net=host \
  -e CUSTOM_SMB_CONF="false" \
  -e CUSTOM_USER="false" \
  -e DEBUG_LEVEL="1" \
  -e MIMIC_MODEL="TimeCapsule8,119" \
  -e EXTERNAL_CONF="/users" \
  -e HIDE_SHARES="no" \
  -e TM_USERNAME="timemachine" \
  -e TM_GROUPNAME="timemachine" \
  -e TM_UID="1000" \
  -e TM_GID="1000" \
  -e PASSWORD="timemachine" \
  -e SET_PERMISSIONS="false" \
  -e SHARE_NAME="TimeMachine" \
  -e VOLUME_SIZE_LIMIT="0" \
  -e WORKGROUP="WORKGROUP" \
  -v /path/on/host/to/backup/to/for/timemachine:/opt/timemachine \
  -v timemachine-var-lib-samba:/var/lib/samba \
  -v timemachine-var-cache-samba:/var/cache/samba \
  -v timemachine-run-samba:/run/samba \
  -v /path/on/host/to/user/file/directory:/users \
  mbentley/timemachine:smb
```

### Using a password file

This is an example to using Docker secrets to pass the password via a file

`password.txt`

```
my_secret_password
```

### Example docker-compose file

The follow example shows the key values required for in your compose file.

```
version: "3.3" # or greater
services:
  timemachine:
    # ...
    environment:
      - PASSWORD_FILE=/run/secrets/password
      # ...
    secrets:
      - password

secrets:
  password:
    file: ./password.txt
```

## AFP Examples and Variables

<details><summary>Click to expand</summary>

## Example docker-compose usage for AFP

```
docker-compose -f timemachine-compose.yml up -d
```

## Example `docker run` usage for AFP

Example usage with `--net=host` to allow Avahi discovery to function:

```
docker run -d --restart=always \
  --net=host \
  --name timemachine \
  -e CUSTOM_AFP_CONF="false" \
  -e CUSTOM_USER="false" \
  -e LOG_LEVEL="info" \
  -e MIMIC_MODEL="TimeCapsule6,106" \
  -e TM_USERNAME="timemachine" \
  -e TM_GROUPNAME="timemachine" \
  -e TM_UID="1000" \
  -e TM_GID="1000" \
  -e PASSWORD="timemachine" \
  -e SET_PERMISSIONS="false" \
  -e SHARE_NAME="TimeMachine" \
  -e VOLUME_SIZE_LIMIT="0" \
  -v /path/on/host/to/backup/to/for/timemachine:/opt/timemachine \
  -v timemachine-netatalk:/var/netatalk \
  -v timemachine-logs:/var/log/supervisor \
  mbentley/timemachine:afp
```

Example usage with exposing ports _without_ Avahi discovery:

```
docker run -d --restart=always \
  --name timemachine \
  --hostname timemachine \
  -p 548:548 \
  -p 636:636 \
  -e CUSTOM_AFP_CONF="false" \
  -e CUSTOM_USER="false" \
  -e LOG_LEVEL="info" \
  -e MIMIC_MODEL="TimeCapsule6,106" \
  -e TM_USERNAME="timemachine" \
  -e TM_GROUPNAME="timemachine" \
  -e TM_UID="1000" \
  -e TM_GID="1000" \
  -e PASSWORD="timemachine" \
  -e SET_PERMISSIONS="false" \
  -e SHARE_NAME="TimeMachine" \
  -e VOLUME_SIZE_LIMIT="0" \
  -v /path/on/host/to/backup/to/for/timemachine:/opt/timemachine \
  -v timemachine-netatalk:/var/netatalk \
  -v timemachine-logs:/var/log/supervisor \
  mbentley/timemachine:afp
```

This works best with `--net=host` so that discovery can be broadcast.  Otherwise, you will need to expose the above ports and then you must manually map the share in Finder for it to show up (open `Finder`, click `Shared`, and connect as `afp://hostname-or-ip/TimeMachine` with your TimeMachine credentials).

Optional variables for AFP:

| Variable | Default | Description |
| :------- | :------ | :---------- |
| `CUSTOM_AFP_CONF` | `false` | indicates that you are going to bind mount a custom config to `/etc/netatalk/afp.conf` if set to `true` |
| `CUSTOM_USER` | `false` | indicates that you are going to bind mount `/etc/password`, `/etc/group`, and `/etc/shadow`; and create data directories if set to `true` |
| `LOG_LEVEL` | `info` | sets the netatalk log level |
| `MIMIC_MODEL` | `TimeCapsule6,106` | sets the value of time machine to mimic |
| `TM_USERNAME` | `timemachine` | sets the username time machine runs as |
| `TM_GROUPNAME` | `timemachine` | sets the group name time machine runs as |
| `TM_UID` | `1000` | sets the UID of the `TM_USERNAME` user |
| `TM_GID` | `1000` | sets the GID of the `TM_GROUPNAME` group |
| `PASSWORD` | `timemachine` | sets the password for the `timemachine` user |
| `SET_PERMISSIONS` | `false` | set to `true` to have the entrypoint set ownership and permission on `/opt/timemachine` |
| `SHARE_NAME` | `TimeMachine` | sets the name of the timemachine share to TimeMachine by default |
| `VOLUME_SIZE_LIMIT` | `0` | sets the maximum size of the time machine backup in MiB ([mebibyte](https://en.wikipedia.org/wiki/Mebibyte)) |

</details>

Thanks for [odarriba](https://github.com/odarriba) and [arve0](https://github.com/arve0) for their examples to start from.
