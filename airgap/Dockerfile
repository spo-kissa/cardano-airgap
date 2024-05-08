FROM ubuntu:22.04

RUN apt-get update -y && apt-get upgrade -y
RUN apt-get install -y \
    git \
    jq \
    bc \
    automake \
    tmux \
    rsync \
    htop \
    curl \
    build-essential \
    pkg-config \
    libffi-dev \
    libgmp-dev \
    libssl-dev \
    libtinfo-dev \
    libsystemd-dev \
    zlib1g-dev \
    make \
    g++ \
    wget \
    libncursesw5 \
    libtool \
    autoconf \
    liblmdb-dev \
    bash \
    locales \
    locales-all

RUN locale-gen en_US.UTF-8

RUN apt-get clean -y

RUN mkdir -p $HOME/git/cardano-node2 && cd $HOME/git/cardano-node2 \
    && wget https://github.com/IntersectMBO/cardano-node/releases/download/8.9.2/cardano-node-8.9.2-linux.tar.gz \
    && tar zxvf cardano-node-8.9.2-linux.tar.gz ./bin/cardano-node ./bin/cardano-cli \
    && $(find $HOME/git/cardano-node2 -type f -name "cardano-cli") version \
    && $(find $HOME/git/cardano-node2 -type f -name "cardano-node") version \
    && cp $(find $HOME/git/cardano-node2 -type f -name "cardano-cli") /usr/local/bin/cardano-cli \
    && cardano-cli version \
    && rm -rf $HOME\git

RUN useradd -m -s /bin/bash cardano && \
    echo "cardano:airgap" | chpasswd
RUN gpasswd -a cardano sudo


COPY ./cardano/cnode/ /home/cardano/cnode/
COPY ./cardano/cold-keys/ /home/cardano/cold-keys/
COPY ./cardano/bin/ /home/cardano/bin/
RUN chown -R cardano: /home/cardano/cnode/ \
    && chown -R cardano: /home/cardano/cold-keys/ \
    && chown -R cardano: /home/cardano/bin

RUN mkdir /mnt/share && chown -R cardano: /mnt/share/

USER cardano
WORKDIR /home/cardano/

RUN echo export NODE_HOME=/home/cardano/cnode >> /home/cardano/.bashrc && \
    echo export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH" >> /home/cardano/.bashrc && \
    echo export NODE_NETWORK="--mainnet" >> /home/cardano/.bashrc && \
    echo export CARDANO_NODE_NETWORK_ID=mainnet >> /home/cardano/.bashrc && \
    echo export LANG=ja_JP.UTF-8 >> /home/cardano/.bashrc
RUN echo export PATH=/home/cardano/bin:\$PATH >> /home/cardano/.bashrc

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN . /home/cardano/.bashrc
RUN mkdir -p /home/cardano/cnode

ENTRYPOINT ["tail", "-F", "/dev/null"]
