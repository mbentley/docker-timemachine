mbentley/timemachine
====================

docker image to run netatalk (compatible Time Machine for OS X)
based off of debian:jessie

To pull this image:
`docker pull mbentley/timemachine`

Example usage:
```
docker run -d --restart=always \
  --net=host \
  --name timemachine \
  -v /opt/timemachine:/opt/timemachine \
  -v timemachine-logs:/var/log/supervisor \
  mbentley/timemachine:latest
```

This works best with `--net=host` so that discovery can be broadcast.  Otherwise, just expose port 548 (`-p 548:548`) and then you must manually map the drive for it to show up.

Default credentials:
  * Username: `timemachine`
  * Password: `timemachine`

Optionally, you can change the default password via the `PASSWORD` environment variable.

If you're using an external volume like in the example above, you may need to set the filesystem permissions on disk.  By default, the `timemachine` user is `1000:1000`.
