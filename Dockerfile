# syntax=docker/dockerfile:1
#
# TiaC Systems Network - ASDF Workspace
#
#  -- derived from official Ubuntu Docker image
#  -- see: https://hub.docker.com/_/ubuntu/tags
#  -- see: https://github.com/docker-library/official-images
#
#  -- support Docker multi-platform image build
#  -- see: https://docs.docker.com/build/building/multi-platform
#  -- see: https://docs.docker.com/build/building/variables/#multi-platform-build-arguments
#
#  -- TARGETPLATFORM=linux/amd64: TARGETOS=linux, TARGETARCH=amd64, TARGETVARIANT=
#  -- TARGETPLATFORM=linux/arm/v7: TARGETOS=linux, TARGETARCH=arm, TARGETVARIANT=v7
#  -- TARGETPLATFORM=linux/arm64/v8: TARGETOS=linux, TARGETARCH=arm64, TARGETVARIANT=v8
#  -- TARGETPLATFORM=linux/riscv64: TARGETOS=linux, TARGETARCH=riscv64, TARGETVARIANT=
#  -- TARGETPLATFORM=linux/ppc64le: TARGETOS=linux, TARGETARCH=ppc64le, TARGETVARIANT=
#  -- TARGETPLATFORM=linux/s390x: TARGETOS=linux, TARGETARCH=s390x, TARGETVARIANT=
#
#  -- https://patorjk.com/software/taag/#p=display&c=bash&f=Tmplr&t=ALL
#  -- https://patorjk.com/software/taag/#p=display&c=bash&f=Tmplr&t=FINAL
#  -- https://patorjk.com/software/taag/#p=display&c=bash&f=Tmplr&t=SYS
#  -- https://patorjk.com/software/taag/#p=display&c=bash&f=Big%20Chief&t=Section
#


#  -- about 20 minutes
#  ___________________________
#      ____
#      /   )
#  ---/__ /-----__---__----__-
#    /    )   /   ) (_ ` /___)
#  _/____/___(___(_(__)_(___ _
#
#

# ############################################################################
#                                                                     ┏┓┓┏┏┓
#   System maintenance with official Ubuntu Docker image              ┗┓┗┫┗┓
#                                                                     ┗┛┗┛┗┛
# ############################################################################

FROM ubuntu:noble-20241011 AS base

# overwrite Ubuntu default metadata
LABEL mantainer="Stephan Linz <stephan.linz@tiac-systems.de>"
LABEL version="unstable"

# ############################################################################

# workspace user definitions (derived from readthedocs/user to be compatible)
ARG WSUSER_HOME=/home/tsn
ARG WSUSER_NAME=tsn
ARG WSUSER_UID=1005
ARG WSUSER_GID=205

# ############################################################################

SHELL ["/bin/sh", "-ex", "-c"]

# ############################################################################

ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN=true
ENV LANG=C.UTF-8

# ############################################################################

# switch to superuser
USER root
WORKDIR /

# ############################################################################

# Install requirements
RUN apt-get --assume-yes update \
 && apt-get --assume-yes dist-upgrade \
 && apt-get --assume-yes install --no-install-recommends \
    apt-utils \
    bash \
    bash-completion \
    locales \
    software-properties-common \
    vim \
 && apt-get --assume-yes autoremove --purge \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ############################################################################

#
# System setups
#
# - setup locales for English
# - create workspace user with their UID and GID
# - make /bin/sh symlink to bash instead of dash
#   HOTFIX: dpkg-reconfigure has no effect, do it manually!
#

ENV LANG=en_US.UTF-8

RUN locale-gen en_US.UTF-8 \
 && update-locale LANG=en_US.UTF-8 \
 && locale -a \
    \
 && groupadd --gid $WSUSER_GID $WSUSER_NAME \
 && useradd -m --uid $WSUSER_UID --gid $WSUSER_GID $WSUSER_NAME \
    \
 && (echo "dash dash/sh boolean false" | debconf-set-selections) \
 && dpkg-reconfigure --frontend=readline --priority=critical dash \
 && ln -sf bash /bin/sh

SHELL ["/bin/sh", "-exo", "pipefail", "-c"]

# ############################################################################

# Set executable for main entry point
CMD ["/bin/bash"]


#  -- about 5 minutes
#  _______________________________________________________
#      __       __     _____    _____      _    _   _   _
#      / |    /    )   /    )   /    '     |   /    /  /|
#  ---/__|----\-------/----/---/__---------|--/----/| /-|-
#    /   |     \     /    /   /       ===  | /    / |/  |
#  _/____|_(____/___/____/___/_____________|/____/__/___|_
#
#

# ############################################################################
#                                                                     ┏┓┓ ┓
#   All architectures maintenance for ASDF and ASDF Plugin Manager    ┣┫┃ ┃
#                                                                     ┛┗┗┛┗┛
# ############################################################################

FROM base AS asdf-all

# ############################################################################

#
# ASDF runtime version
# https://asdf-vm.com/
# https://github.com/asdf-vm/asdf/blob/master/CHANGELOG.md
#

# Define ASDF branch to be installed via git-clone
ENV TSN_ASDF_BRANCH=v0.14.1

#
# ASDF Plugin Manager runtime version
# https://github.com/asdf-community/asdf-plugin-manager
# https://github.com/asdf-community/asdf-plugin-manager/blob/main/CHANGELOG.md
#

# Define ASDF Plugin Manager version to be installed via ASDF
ENV TSN_ASDF_PM_VERSION=1.4.0

# ############################################################################

# Install requirements
RUN apt-get --assume-yes update \
 && apt-get --assume-yes install --no-install-recommends \
    bsdmainutils \
    coreutils \
    curl \
    git-core \
    grep \
    sed \
 && apt-get --assume-yes autoremove --purge \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ############################################################################

# switch to workspace user
USER $WSUSER_NAME
WORKDIR $WSUSER_HOME

# ############################################################################

#
# Manage multiple runtime versions with the
# ASDF version manager in workspace user space.
# https://github.com/asdf-vm/asdf
#

# Activate ASDF in current session
ENV PATH=$WSUSER_HOME/.asdf/shims:$WSUSER_HOME/.asdf/bin:$PATH

# Install and upgrade ASDF with basic plugins
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf \
              --depth 1 --branch $TSN_ASDF_BRANCH \
 && echo ". ~/.asdf/asdf.sh" \
 >> $WSUSER_HOME/.bashrc \
 && echo ". ~/.asdf/completions/asdf.bash" \
 >> $WSUSER_HOME/.bashrc \
    \
 && asdf update \
 && asdf plugin update --all \
    \
 && asdf plugin add \
         asdf-plugin-manager \
         https://github.com/asdf-community/asdf-plugin-manager.git

# Adding labels for external usage
LABEL asdf.branch=$TSN_ASDF_BRANCH

# ############################################################################

#
# ASDF Plugin Manager runtime version
#

# Install ASDF Plugin Manager, set default version and export plugin list
RUN asdf install asdf-plugin-manager $TSN_ASDF_PM_VERSION \
 && asdf global  asdf-plugin-manager $TSN_ASDF_PM_VERSION \
 && asdf reshim  asdf-plugin-manager \
    \
 && asdf local asdf-plugin-manager $TSN_ASDF_PM_VERSION \
 && asdf list  asdf-plugin-manager \
    \
 && touch $WSUSER_HOME/.plugin-versions \
 && asdf-plugin-manager export > $WSUSER_HOME/.plugin-versions

# Adding labels for external usage
LABEL asdf-plugin-manager.version=$TSN_ASDF_PM_VERSION

# ############################################################################
#
#   AMD/x86 64-bit architecture maintenance for               /||\/||\ / /|
#   ASDF and ASDF Plugin Manager                             /-||  ||/(_)~|~
#
# ############################################################################

FROM asdf-all AS asdf-amd64

# ############################################################################
#
#   ARMv7 32-bit architecture maintenance for                       /||)|\/|
#   ASDF and ASDF Plugin Manager                                   /-||\|  |
#
# ############################################################################

FROM asdf-all AS asdf-arm

# ############################################################################
#
#   ARMv8 64-bit architecture maintenance for                 /||)|\/| / /|
#   ASDF and ASDF Plugin Manager                             /-||\|  |(_)~|~
#
# ############################################################################

FROM asdf-all AS asdf-arm64

# ############################################################################
#
#   RISC-V 64-bit architecture maintenance for               |)|(`/`| // /|
#   ASDF and ASDF Plugin Manager                             |\|_)\,|/(_)~|~
#
# ############################################################################

FROM asdf-all AS asdf-riscv64

# ############################################################################
#
#   IBM POWER8 architecture maintenance for                 |)|)/` / /| | [~
#   ASDF and ASDF Plugin Manager                            | | \,(_)~|~|_[_
#
# ############################################################################

FROM asdf-all AS asdf-ppc64le

# ############################################################################
#
#   IBM z-Systems architecture maintenance for                   (`')(~)/\\/
#   ASDF and ASDF Plugin Manager                                 _).) / \//\
#
# ############################################################################

FROM asdf-all AS asdf-s390x

# ############################################################################
#                                                                  ┏┓┳┳┓┏┓┓
#   Final maintenance for ASDF and ASDF Plugin Manager             ┣ ┃┃┃┣┫┃
#                                                                  ┻ ┻┛┗┛┗┗┛
# ############################################################################

FROM asdf-${TARGETARCH} AS asdf
