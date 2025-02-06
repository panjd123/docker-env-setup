# General Container for Develop

```bash
docker build -t panjd123/pytorch-dev .
```

It will cost 10+ mins to build.

```bash
docker pull panjd123/pytorch-dev
````

```bash
docker run -it --name jarden \
    -p 127.0.0.1:25486:22 \
    --gpus all \
    --restart always \
    --privileged \
    -d \
    panjd123/pytorch-dev
```

```bash
python3 ./ssh_setup/ssh_setup.py --init
python3 ./ssh_setup/ssh_setup.py --install jarden

ssh root@127.0.0.1 -p 25486
```
