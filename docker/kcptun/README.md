# README

Build kcptun docker image since <https://hub.docker.com/r/xtaci/kcptun> has not been updated for more than one year.
There are two docker image for smallest size, kcptun command has been compressed by upx also

```bash
env KCPTUN_VERSION=v20240919 ../build-docker.sh -f Dockerfile.client -p

env KCPTUN_VERSION=v20240919 ../build-docker.sh -f Dockerfile.server -p
```

I pack [su-exec](https://github.com/ncopa/su-exec) , but I do not know how to use it.
