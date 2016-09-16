mbentley/timemachine
====================

docker image to run netatalk (compatible Time Machine for OS X)
based off of debian:jessie

To pull this image:
`docker pull mbentley/timemachine`

Example usage:
`docker run -d --net=host --name timemachine mbentley/timemachine`

This works best with `--net=host` so that discovery can be broadcast.  Otherwise, just expose port 548 (`-p 548:548`) and then you must manually map the drive for it to show up.

Default credentials:
  * Username: `timemachine`
  * Password: `timemachine`

Optionally, you can change the default password via the `PASSWORD` environment variable.
