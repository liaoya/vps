# README

Build kcptun docker image since <https://hub.docker.com/r/xtaci/kcptun> has not been updated for more than one year.
There are two docker image for smallest size, kcptun command has been compressed by upx also

```bash
export ALPINE_BASE=docker.io/library/alpine:3.22.1@sha256:4bcff63911fcb4448bd4fdacec207030997caf25e9bea4045fa6c8c44de311d1
export KCPTUN_VERSION=v20250730
../build-docker.sh -f Dockerfile.client -p
../build-docker.sh -f Dockerfile.server -p
```

I pack [su-exec](https://github.com/ncopa/su-exec) , but I do not know how to use it.
