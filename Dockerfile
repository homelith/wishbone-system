#### Installing Software ####
FROM ubuntu:18.04 AS Base
ARG INTERNAL_USER=guser
ARG PASSWORD=password
ENV INTERNAL_USER=${INTERNAL_USER}
ENV FILE_DIR=docker

# useful pkg for development
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential git locales make rsync screen sudo tmux tzdata usbutils vim wget x11-apps xorg xterm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# required pkg for running gowin ide
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y libglib2.0-0 libfontconfig1 kmod && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# required pkg for simulation
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y iverilog gtkwave && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# desktop environment
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      fonts-ipafont-gothic fonts-ipafont-mincho ibus ibus-mozc language-pack-ja language-pack-ja-base xfce4 xrdp && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
EXPOSE 3389

#### Global Settings ####
# set locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8 \
    LANGUAGE en_US:en \
    LC_ALL en_US.UTF-8
RUN cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
    && echo 'Asia/Tokyo' > /etc/timezone

# copy install scripts
RUN chmod go+rx /root
COPY ${FILE_DIR}/install.sh /root/install.sh
COPY ${FILE_DIR}/settings.sh /root/settings.sh
COPY ${FILE_DIR}/startxrdp.sh /usr/bin/startxrdp.sh
RUN chmod +x /root/install.sh

# setup window manager
RUN echo "startxfce4" > /etc/skel/.xsession

# add non-privilege user
RUN useradd -ms /bin/bash ${INTERNAL_USER} && \
    echo ${INTERNAL_USER}:${PASSWORD} | chpasswd && \
    echo "${INTERNAL_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN sudo sed -i /etc/sudoers -e "s/^Defaults\tsecure_path=.*$/#&\nDefaults\tenv_keep +=\"PATH\"/"
RUN cp /etc/skel/.xsession /home/${INTERNAL_USER}/.xsession && chown -R ${INTERNAL_USER} /home/${INTERNAL_USER}/.xsession

#### User Settings ####
USER ${INTERNAL_USER}
WORKDIR /home/${INTERNAL_USER}

# modify user .bashrc
RUN echo "source /root/settings.sh" >> /home/${INTERNAL_USER}/.bashrc

#### Finalize ####
USER root
COPY ${FILE_DIR}/entrypoint.sh /root/entrypoint.sh
ENTRYPOINT [ "bash", "/root/entrypoint.sh" ]
CMD ["/usr/bin/startxrdp.sh"]
