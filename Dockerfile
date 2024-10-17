FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

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
    libboost-all-dev

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone

ARG GIT_USER=anonymous
ARG GIT_EMAIL=anonymous@gmail.com

# git settings
RUN git lfs install \
    && git config --global user.email $GIT_EMAIL \
    && git config --global user.name $GIT_USER \
    && git config --global init.defaultBranch main

# install miniconda
RUN curl -o ~/miniconda.sh -O https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && chmod +x ~/miniconda.sh \
    && ~/miniconda.sh -b -p ~/miniconda3 \
    && rm ~/miniconda.sh \
    && ~/miniconda3/bin/conda init bash

# RUN ~/miniconda3/bin/conda config --set auto_activate_base false

RUN echo 'export PATH="$PATH:~/miniconda3/bin"' >> ~/.bashrc \
    && echo 'export PATH="$PATH:/usr/local/cuda/bin"' >> ~/.bashrc \
    && echo 'export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64"' >> ~/.bashrc \
    && echo 'export CUDA_HOME="/usr/local/cuda"' >> ~/.bashrc

# conda
# RUN ~/miniconda3/bin/conda create -n pytorch python=3.11 -y

# RUN echo 'conda activate pytorch' >> ~/.bashrc

SHELL ["/root/miniconda3/bin/conda", "run", "-n", "base", "/bin/bash", "-c"]

RUN conda install pytorch torchvision torchaudio pytorch-cuda=12.4 -c pytorch -c nvidia

RUN conda install numpy scipy matplotlib pandas seaborn scikit-learn sympy ipython jupyter -y

# clean
RUN apt-get clean && rm -rf /var/lib/apt/lists/* && conda clean -ay

# avoid ssh key checking
RUN touch ~/.ssh/known_hosts \
    && chmod 644 ~/.ssh/known_hosts \
    && ssh-keyscan -H github.com >> ~/.ssh/known_hosts \
    && ssh-keyscan -H gitlab.com >> ~/.ssh/known_hosts \
    && ssh-keyscan -H gitee.com >> ~/.ssh/known_hosts \
    && ssh-keyscan -H hf.co >> ~/.ssh/known_hosts

# setup ssh
# COPY ssh-setup /tmp/ssh-setup
# RUN python3 /tmp/ssh-setup/ssh-setup.py \
#     && rm -rf /tmp/ssh-setup

RUN mkdir -p /data/models /data/datasets

# clone common models
# RUN git clone git@hf.co:meta-llama/Llama-3.2-1B /data/models/Llama-3.2-1B \
#     & git clone git@hf.co:meta-llama/Llama-3.2-1B-Instruct /data/models/Llama-3.2-1B-Instruct \
#     & wait

CMD ["/bin/bash", "-c", "service ssh start && /bin/bash"]
