FROM nvidia/cuda:12.6.2-cudnn-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN yes | unminimize

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    gdb \
    git \
    curl \
    wget \
    unzip \
    ca-certificates \
    sudo \
    tzdata \
    openssh-server \
    openssh-client \
    nano \
    htop \
    net-tools \
    openjdk-11-jdk \
    nodejs \
    npm \
    screen \
    python3 \
    python3-pip \
    python3-virtualenv \
    git-lfs \
    libopenblas-dev \
    liblapack-dev \
    libboost-all-dev \
    lsof \
    rsync

# setup rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone

ARG GIT_USER=panjd123
ARG GIT_EMAIL=1747366367@qq.com

# git settings
RUN git lfs install \
    && git config --global user.email $GIT_EMAIL \
    && git config --global user.name $GIT_USER \
    && git config --global init.defaultBranch main \
    && git config --global core.editor "nano" \
    && git config --global pull.rebase false

# install miniconda
RUN curl -o ~/miniconda.sh -O https://repo.anaconda.com/miniconda/Miniconda3-py311_24.9.2-0-Linux-x86_64.sh \
    && chmod +x ~/miniconda.sh \
    && ~/miniconda.sh -b -p ~/miniconda3 \
    && rm ~/miniconda.sh \
    && ~/miniconda3/bin/conda init bash

RUN echo 'export PATH="$PATH:~/miniconda3/bin"' >> ~/.bashrc \
    && echo 'export PATH="$PATH:/usr/local/cuda/bin"' >> ~/.bashrc \
    && echo 'export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64"' >> ~/.bashrc \
    && echo 'export CUDA_HOME="/usr/local/cuda"' >> ~/.bashrc

SHELL ["/root/miniconda3/bin/conda", "run", "-n", "base", "/bin/bash", "-c"]

RUN pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

RUN conda install numpy scipy matplotlib pandas seaborn scikit-learn sympy ipython jupyter transformers -y

# clean
RUN apt-get clean && rm -rf /var/lib/apt/lists/* && conda clean -ay

# setup ssh
# COPY ssh_setup /tmp/ssh_setup
# RUN python3 /tmp/ssh_setup/ssh_setup.py \
#     && rm -rf /tmp/ssh_setup

RUN mkdir -p /data/models /data/datasets

CMD ["/bin/bash", "-c", "service ssh start && /bin/bash"]
