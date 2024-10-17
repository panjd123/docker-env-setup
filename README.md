# General Container for Develop

```bash
docker build -t base .
```

It will cost 10+ mins to build.

```bash
docker run -it --name jarden \
    -p 127.0.0.1:25486:22 \
    --gpus all \
    --restart always \
    --privileged \
    -d \
    base
```

```bash
ssh root@127.0.0.1 -p 25468
```
