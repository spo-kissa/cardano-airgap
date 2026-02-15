FROM debian:bookworm-slim AS base

# airgap version specifed
ENV AIRGAP_VERSION=10.5.4.0

# Cardano-Node version
ENV CNODE_VERSION=10.5.4

# Cardano-Singer version
ENV CS_VERSION=1.27.0


#
# Build Stage
#
FROM base AS builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive
RUN <<EOF
apt-get update
apt-get install -y \
    curl \
    wget
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF

# cardano-cli
RUN <<'EOF'
set -eux

mkdir -p /out

mkdir -p /home/cardano/git/cardano-node2 && cd /home/cardano/git/cardano-node2
curl -SL https://github.com/IntersectMBO/cardano-node/releases/download/${CNODE_VERSION}/cardano-node-${CNODE_VERSION}-linux.tar.gz \
 | tar -zxC /home/cardano/git/cardano-node2 ./bin/cardano-cli
mv $(find /home/cardano/git/cardano-node2 -type f -name "cardano-cli") /out/cardano-cli
/out/cardano-cli version
sleep 2
EOF

# cardano-signer
RUN <<'EOF'
set -eux
case "${TARGETARCH:-}" in
  amd64) CS_ARCH="x64" ;;
  arm64) CS_ARCH="arm64" ;;
  *) echo "unsupported TARGETARCH: ${TARGETARCH:-<empty>}" >&2; exit 1 ;;
esac
cd /home/cardano/git
wget -q https://github.com/gitmachtl/cardano-signer/releases/download/v${CS_VERSION}/cardano-signer-${CS_VERSION}_linux-${CS_ARCH}.tar.gz
tar -xzvf cardano-signer-${CS_VERSION}_linux-${CS_ARCH}.tar.gz
rm cardano-signer-${CS_VERSION}_linux-${CS_ARCH}.tar.gz
install -m 0755 ./cardano-signer /out/cardano-signer
echo Cardano-Signer Installed!
/out/cardano-signer version
sleep 2
EOF


#
# Runtime Stage
#
FROM base AS runtime

RUN <<'EOF'
set -eux

apt-get update
apt-get install -y gpg curl
apt-get clean && mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | tee /etc/apt/sources.list.d/charm.list
apt-get update && apt-get install -y \
    gum \
    jq \
    locales \
    locales-all \
    nano \
    vim \
    sudo \
    && rm -rf /var/lib/apt/lists/*

EOF

COPY --from=builder /out/cardano-cli    /usr/local/bin/cardano-cli
COPY --from=builder /out/cardano-signer /usr/local/bin/cardano-signer


RUN <<'EOF'

useradd -m -s /bin/bash cardano \
&& echo "cardano:airgap" | chpasswd \
&& gpasswd -a cardano sudo \
\
&& mkdir -p /home/cardano/cnode/ \
&& mkdir -p /home/cardano/cold-keys/ \
&& mkdir -p /home/cardano/bin/ \
&& mkdir -p /mnt/share \
&& touch /home/cardano/.sudo_as_admin_successful \
&& echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
EOF

COPY ./bin/lock-keys /home/cardano/bin/
COPY ./bin/unlock-keys /home/cardano/bin/
COPY ./bin/ctool.sh /home/cardano/bin/

RUN chmod -R 755 /home/cardano/bin/* \
 && chown -R cardano: /home/cardano/ \
 && chown -R cardano: /mnt/share/

USER cardano
ENV HOME=/home/cardano
WORKDIR /home/cardano/
ENV TERM=xterm-256color

RUN touch /home/cardano/.bashrc \
 && echo "PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >> /home/cardano/.bashrc \
 && echo export TERM=xterm-256color >> /home/cardano/.bashrc \
 && echo export NODE_HOME=/home/cardano/cnode >> /home/cardano/.bashrc \
 && echo export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH" >> /home/cardano/.bashrc \
 && echo export NODE_CONFIG=mainnet >> /home/cardano/.bashrc \
 && echo export NODE_NETWORK="--mainnet" >> /home/cardano/.bashrc \
 && echo export CARDANO_NODE_NETWORK_ID=mainnet >> /home/cardano/.bashrc \
 && echo export LANG=ja_JP.UTF-8 >> /home/cardano/.bashrc \
 && echo export PATH=${PATH}:/home/cardano/bin >> /home/cardano/.bashrc \
 && echo export SHARE=/mnt/share >> /home/cardano/.bashrc \
 && echo alias ctool="ctool.sh" >> /home/cardano/.bashrc \
 && echo alias airgap="'cd $HOME/cnode && [ -f airgap-set.tar.gz ] && tar -xOzf airgap-set.tar.gz airgap_script | bash -s verify || echo "airgap-set.tar.gz が見つかりません"'" >> /home/cardano/.bashrc

RUN chown -R cardano:cardano /home/cardano
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

ENTRYPOINT ["tail", "-F", "/dev/null"]
