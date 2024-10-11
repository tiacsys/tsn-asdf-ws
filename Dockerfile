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

# ############################################################################
#
# Base system maintenance with official Ubuntu Docker image
#
# ############################################################################

FROM ubuntu:noble-20240904.1 AS base

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

# create workspace user with their UID and GID
RUN groupadd --gid $WSUSER_GID $WSUSER_NAME
RUN useradd -m --uid $WSUSER_UID --gid $WSUSER_GID $WSUSER_NAME

# ############################################################################

# System dependencies
RUN apt-get --assume-yes update
RUN apt-get --assume-yes dist-upgrade
RUN apt-get --assume-yes install --no-install-recommends \
    apt-utils \
    bash \
    bash-completion \
    software-properties-common \
    vim
RUN apt-get --assume-yes autoremove --purge
RUN apt-get clean

# ############################################################################

# make /bin/sh symlink to bash instead of dash:
RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN dpkg-reconfigure --frontend=readline --priority=critical dash

# HOTFIX: The construct above has no effect, do it manually!
RUN ln -sf bash /bin/sh

SHELL ["/bin/sh", "-exo", "pipefail", "-c"]

# ############################################################################

# Localization dependencies
RUN apt-get --assume-yes install --no-install-recommends \
      locales

# Setup locales for German
RUN locale-gen de_DE.UTF-8
RUN update-locale LANG=de_DE.UTF-8
ENV LANG=de_DE.UTF-8
RUN locale -a

# Setup locales for English
RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8
RUN locale -a

# ############################################################################

# Set executable for main entry point
CMD ["/bin/bash"]

# ############################################################################

# switch to workspace user
USER $WSUSER_NAME
WORKDIR $WSUSER_HOME

# ############################################################################
#
# All architectures maintenance for ASDF and ASDF Plugin Manager
#
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

# switch to superuser
USER root
WORKDIR /

# ############################################################################

# Install requirements
RUN apt-get --assume-yes install --no-install-recommends \
    bsdmainutils \
    coreutils \
    curl \
    git-core \
    grep \
    sed
RUN apt-get --assume-yes autoremove --purge
RUN apt-get clean

# ############################################################################

# switch to workspace user
USER $WSUSER_NAME
WORKDIR $WSUSER_HOME

# ############################################################################

#
# Manage multiple runtime versions with the
# ASDF version manager in workspace user space.
#

# Install ASDF
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --depth 1 --branch $TSN_ASDF_BRANCH
RUN echo ". ~/.asdf/asdf.sh" >> $WSUSER_HOME/.bashrc
RUN echo ". ~/.asdf/completions/asdf.bash" >> $WSUSER_HOME/.bashrc

# Activate ASDF in current session
ENV PATH=$WSUSER_HOME/.asdf/shims:$WSUSER_HOME/.asdf/bin:$PATH

# Install ASDF plugins
RUN asdf plugin add asdf-plugin-manager https://github.com/asdf-community/asdf-plugin-manager.git

# Adding labels for external usage
LABEL asdf.branch=$TSN_ASDF_BRANCH

# Upgrade ASDF version manager
# https://github.com/asdf-vm/asdf
RUN asdf update
RUN asdf plugin update --all

# ############################################################################

#
# ASDF Plugin Manager runtime version
#

# Install ASDF Plugin Manager
RUN asdf install asdf-plugin-manager $TSN_ASDF_PM_VERSION && \
    asdf global  asdf-plugin-manager $TSN_ASDF_PM_VERSION && \
    asdf reshim  asdf-plugin-manager

# Adding labels for external usage
LABEL asdf-plugin-manager.version=$TSN_ASDF_PM_VERSION

# Set default ASDF Plugin Manager version
RUN asdf local asdf-plugin-manager $TSN_ASDF_PM_VERSION
RUN asdf list  asdf-plugin-manager

# Export initial list of ASDF plugins
RUN touch $WSUSER_HOME/.plugin-versions
RUN asdf-plugin-manager export > $WSUSER_HOME/.plugin-versions

# ############################################################################
#
# AMD/x86 64-bit architecture maintenance for ASDF and ASDF Plugin Manager
#
# ############################################################################

FROM asdf-all AS asdf-amd64

# ############################################################################
#
# ARMv7 32-bit architecture maintenance for ASDF and ASDF Plugin Manager
#
# ############################################################################

FROM asdf-all AS asdf-arm

# ############################################################################
#
# ARMv8 64-bit architecture maintenance for ASDF and ASDF Plugin Manager
#
# ############################################################################

FROM asdf-all AS asdf-arm64

# ############################################################################
#
# RISC-V 64-bit architecture maintenance for ASDF and ASDF Plugin Manager
#
# ############################################################################

FROM asdf-all AS asdf-riscv64

# ############################################################################
#
# IBM POWER8 architecture maintenance for ASDF and ASDF Plugin Manager
#
# ############################################################################

FROM asdf-all AS asdf-ppc64le

# ############################################################################
#
# IBM z-Systems architecture maintenance for ASDF and ASDF Plugin Manager
#
# ############################################################################

FROM asdf-all AS asdf-s390x

# ############################################################################
#
# Final maintenance for ASDF and ASDF Plugin Manager
#
# ############################################################################

FROM asdf-${TARGETARCH} AS asdf

# ############################################################################

#
# ASDF runtime version
#

RUN asdf version
RUN asdf list

# ############################################################################

#
# ASDF Plugin Manager runtime version
#

RUN asdf-plugin-manager version
RUN asdf-plugin-manager list
