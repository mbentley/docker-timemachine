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
  -e PASSWORD=timemachine \
  -e VOLUME_SIZE_LIMIT=1024000 \
  -v /opt/timemachine:/opt/timemachine \
  -v timemachine-logs:/var/log/supervisor \
  mbentley/timemachine:latest
```

This works best with `--net=host` so that discovery can be broadcast.  Otherwise, just expose port 548 (`-p 548:548`) and then you must manually map the drive for it to show up.

Default credentials:
  * Username: `timemachine`
  * Password: `timemachine`

Optional variables:
  * `PASSWORD` - sets the password for the `timemachine` user (default - `timemachine`)
  * `VOLUME_SIZE_LIMIT` - sets the maximum size of the time machine backup (default - no limit)

If you're using an external volume like in the example above, you may need to set the filesystem permissions on disk.  By default, the `timemachine` user is `1000:1000`.

Thanks for [odarriba](https://github.com/odarriba) and [arve0](https://github.com/arve0) for their examples to start from.
