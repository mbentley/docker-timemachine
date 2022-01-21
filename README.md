# mbentley/timemachine

docker image to run Samba or AFP (netatalk) to provide a compatible Time Machine for MacOS

## Image Tags

### Multi-arch Tags

The following tags have multi-arch support for `amd64`, `armv7l`, and `arm64` and will automatically pull the correct tag based on your system's architecture:

`latest`, `smb`

__Note__: The `afp` tag has been deprecated in terms of new feature updates and is only available for `amd64`.

### Date Specific Tags

The `smb` tags also have unique manifests that are generated daily.  These are in the format `smb-YYYYMMDD` (e.g. - `smb-20210730`) and can be viewed on [Docker Hub](https://hub.docker.com/repository/docker/mbentley/timemachine/tags?page=1&ordering=last_updated&name=smb-20).  Each one of these tags will be generated daily and is essentially a point in time snapshot of the `smb` tag's manifest that you can pin to if you wish.  Please note that these tags will remain available on Docker Hub for __6 months__ and will not receive security fixes.  You will need to update to newer tags as they are published in order to get updated images.  If you do not care about specific image digests to pin to, I would suggest just using the `smb` tag.

### Explicit Architecture Tags

These tags will explicitly pull the image for the listed architecture and are bit for bit identical to the multi-arch tags images.

#### [`amd64`](https://hub.docker.com/repository/docker/mbentley/timemachine/tags?page=1&ordering=last_updated&name=amd64)

* `latest-smb-amd64`, `smb-amd64` - SMB image based off of alpine:latest
* `afp`, `afp-amd64` - AFP image based off of debian:jessie
  * Deprecated but still available; not being regularly built - **This image may have unpatched security vulnerabilities**

#### [`armv7l`](https://hub.docker.com/repository/docker/mbentley/timemachine/tags?page=1&ordering=last_updated&name=armv7l)

* `latest-smb-armv7l`, `smb-armv7l` - SMB image based off of alpine:latest for the `armv7l` architecture

#### [`arm64`](https://hub.docker.com/repository/docker/mbentley/timemachine/tags?page=1&ordering=last_updated&name=arm64)

* `latest-smb-arm64`, `smb-arm64` - SMB image based off of alpine:latest for the `arm64` architecture

__Warning__: I would strongly suggest migrating to the SMB image as AFP is being deprecated by Apple and I've found it to be much more stable.  I do not plan on adding any new features to the AFP based config and I [switched the default image in the `latest` tag to the SMB variant on October 15, 2020](https://github.com/mbentley/docker-timemachine/issues/38).

To pull this image:
`docker pull mbentley/timemachine:smb`

## Example usage for SMB


Example usage with `--net=host` to allow Avahi discovery; all available environment variables set to their default values:

```
docker run -d --restart=always \
  --name timemachine \
  --net=host \
  -e ADVERTISED_HOSTNAME="" \
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
  -e SMB_INHERIT_PERMISSIONS="no" \
  -e SMB_NFS_ACES="yes" \
  -e SMB_METADATA="stream" \
  -e SMB_PORT="445" \
  -e SMB_VFS_OBJECTS="acl_xattr fruit streams_xattr" \
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
  -e ADVERTISED_HOSTNAME="" \
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
  -e SMB_INHERIT_PERMISSIONS="no" \
  -e SMB_NFS_ACES="yes" \
  -e SMB_METADATA="stream" \
  -e SMB_PORT="445" \
  -e SMB_VFS_OBJECTS="acl_xattr fruit streams_xattr" \
  -e VOLUME_SIZE_LIMIT="0" \
  -e WORKGROUP="WORKGROUP" \
  -v /path/on/host/to/backup/to/for/timemachine:/opt/timemachine \
  -v timemachine-var-lib-samba:/var/lib/samba \
  -v timemachine-var-cache-samba:/var/cache/samba \
  -v timemachine-run-samba:/run/samba \
  mbentley/timemachine:smb
```


### Kubernetes support
The images are also compatible with Kubernetes.
Checkout [timemachine-k3s.yaml](https://github.com/mbentley/docker-timemachine/blob/master/timemachine-k3s.yaml) as an example for running a TimeMachine backup server on a single-node [k3s](https://k3s.io) cluster running (on a Raspberry Pi 4).

### Tips for Automatic Discovery w/Avahi

This works best with `--net=host` so that discovery can be broadcast.  Otherwise, you will need to expose the above ports and then you must manually map the share in Finder for it to show up (open `Finder`, click `Shared`, and connect as `smb://hostname-or-ip/TimeMachine` with your TimeMachine credentials).  Using `--net=host` only works if you do not already run Samba or Avahi on the host!  Alternatively, you can use the `SMB_PORT` option to change the port that Samba uses.  See below for another workaround if you do not wish to change the Samba port.

### Known Issues

#### Unable to start the `armv7l` image

If you are running the `armv7l` image, you may see and error when trying to start the container:

```
s6-svscan: warning: unable to iopause: Operation not permitted
```

This is due to an issue with the `libseccomp2` package.  You have two options:

1. Disable seccomp for the container by adding the `--security-opt seccomp=unconfined` argument (this has security implications)
1. Install a backported version of `libseccomp2`:

   ```
   wget http://ftp.us.debian.org/debian/pool/main/libs/libseccomp/libseccomp2_2.5.1-1~bpo10+1_armhf.deb
   sudo dpkg -i libseccomp2_2.5.1-1~bpo10+1_armhf.deb
   ```

This issue has been observed on Raspberry Pi OS (formerly known as Raspbian) based on Debian 10 (Buster) but may also be found on other distros as they may commonly use the `libseccomp2` package version `2.3.3-4`.

#### Conflicts with Samba and/or Avahi on the Host

__Note__: If you are already running Samba/Avahi on your Docker host (or you're wanting to run this on your NAS), you should be aware that using `--net=host` will cause a conflict with the Samba/Avahi install. Raspberry Pi users: be aware that there is already an mDNS responder running on the stock Raspberry Pi OS image that will conflict with the mDNS responder in the container.

If your host is running Avahi, you can configure it to act as a reflector, and the container advertisements will be broadcast to your host network without using `--net=host`. To do this, edit the avahi config (`/etc/avahi/avahi-daemon.conf`) on the host:

* set `enable-reflector=yes`
* set `cache-entries-max=0` - this prevents issues with Apple devices reporting duplicate names and adding/incrementing numbers in their name (references: <https://blogs.thismonkey.com/?p=33> and <https://community.ui.com/questions/mdns-reflector-help-computer-name-keeps-changing/180dd51f-a5b2-465c-88c2-6e85ab03c38a#answer/4732ed77-37aa-4f30-b992-cf99752e4f6a>)

Then set the `ADVERTISED_HOSTNAME` environment variable in your container config to the mDNS hostname of your host, *without* the `.local` suffix.

As an alternative, you can use the [`macvlan` driver in Docker](https://docs.docker.com/network/macvlan/) which will allow you to map a static IP address to your container.  If you have issues setting up Time Machine with the configuration, feel free to open an issue and I can assist - this is how I persoanlly run time machine.

1. Create a `macvlan` Docker network (assuming your local subnet is `192.168.1.0/24`, the default gateway is `192.168.1.1`, and `eth0` for the host's network interface):

  ``` bash
  docker network create -d macvlan --subnet=192.168.1.0/24 --gateway=192.168.1.1 -o parent=eth0 macvlan1
  ```

  On devices such as Synology DSM, the primary network interface may be `ovs_eth0` due to the usage of Open vSwitch.  If you are unsure of your primary network interface, this command may help:

  ``` bash
  $ route | grep ^default | awk '{print $NF}'
  eth0
  ```

  The `macvlan` driver can use another network interface as the documentation states above but in cases where multiple network interfaces may exist and they might not all be connected, choosing the primary network interface is generally safe.

1. Add `--network macvlan1` and `--ip 192.168.1.x` to your `docker run` command where `192.168.1.x` is a static IP to assign to Time Machine

##### Example macvlan setup using docker-compose

```
services:
  timemachine:
    hostname: timemachine
    mac_address: "AA:BB:CC:DD:EE:FF"
    networks:
      timemachine:
        ipv4_address: 192.168.1.x

networks:
  timemachine:
    driver: macvlan
    driver_opts:
      parent: eth0
    ipam:
      config:
        - subnet: 192.168.1.0/24
          ip_range: 192.168.1.0/24
          gateway: 192.168.1.1
  ```

1. `hostname`, `mac_address`, and `ipv4_address` are optional, but can be used to control how it is configured on the network. If not defined, random values will be used.
1. This config requires [docker-compose version](https://docs.docker.com/compose/compose-file/) `1.27.0+` which implements the [compose specification](https://github.com/compose-spec/compose-spec/blob/master/spec.md).

#### Volume & File system Permissions

If you're using an external volume like in the example above, you will need to set the filesystem permissions on disk.  By default, the `timemachine` user is `1000:1000`.

The backing data store for your persistent time machine data _must_ support extended file attributes (`xattr`).  Remote file systems, such as NFS, will very likely not support `xattr`s.  See [#61](https://github.com/mbentley/docker-timemachine/issues/61) for more details.  This image will check and try to set `xattr`s to a test file in `/opt/${TM_USERNAME}` to warn the user if they are not supported but this will not prevent the image from running.

Also note that if you change the `TM_USERNAME` value that it will change the data path from `/opt/timemachine` to `/opt/<value-of-TM_USERNAME>`.

Default credentials:

* Username: `timemachine`
* Password: `timemachine`

### Optional variables for SMB

| Variable | Default | Description |
| :------- | :------ | :---------- |
| `ADVERTISED_HOSTNAME` | _not set_ | Avahi will advertise the smb services at this hostname instead of the local hostname (useful in Docker without `--net=host`) |
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
| `SET_PERMISSIONS` | `false` | set to `true` to have the entrypoint set ownership and permission on the `/opt/<username>` in the container |
| `SHARE_NAME` | `TimeMachine` | sets the name of the timemachine share to TimeMachine by default |
| `SMB_INHERIT_PERMISSIONS` | `no` | if yes, permissions for new files will be forced to match the parent folder |
| `SMB_NFS_ACES` | `yes` | value of `fruit:nfs_aces`; support for querying and modifying the UNIX mode of directory entries via NFS ACEs |
| `SMB_METADATA` | `stream` | value of `fruit:metadata`; controls where the OS X metadata stream is stored |
| `SMB_PORT` | `445` | sets the port that Samba will be available on |
| `SMB_VFS_OBJECTS` | `acl_xattr fruit streams_xattr` | value of `vfs objects` |
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

__Note__: You will need to either bind mount `/opt` or each `SHARE_NAME` directory under `/opt` for each user.

```
docker run -d --restart=always \
  --name timemachine \
  --net=host \
  -e ADVERTISED_HOSTNAME="" \
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
  -e SMB_INHERIT_PERMISSIONS="no" \
  -e SMB_NFS_ACES="yes" \
  -e SMB_METADATA="stream" \
  -e SMB_PORT="445" \
  -e SMB_VFS_OBJECTS="acl_xattr fruit streams_xattr" \
  -e VOLUME_SIZE_LIMIT="0" \
  -e WORKGROUP="WORKGROUP" \
  -v /path/on/host/to/backup/to/for/timemachine:/opt \
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
