TiaC Systems Network (TSN) ASDF Workspace
=========================================

This repository contains the build configuration of the `ASDF`_ workspace,
a tool version manager, for TiaC Systems Network (TSN) as multi-arch Docker
images for Linux.

Documentation
-------------

The documentation overview is in this `readme in the project root directory
<README.md>`_.

Content
-------

Based on `Ubuntu official Docker image`_, |ubuntu-docker-tag|:

- |ubuntu-release|_
- Docker image architectures:

  - Intel/AMD x86 64-bit (``linux/amd64``): https://hub.docker.com/r/amd64/ubuntu
  - ARMv7 32-bit (``linux/arm/v7``): https://hub.docker.com/r/arm32v7/ubuntu
  - ARMv8 64-bit (``linux/arm64/v8``): https://hub.docker.com/r/arm64v8/ubuntu
  - RISC-V 64-bit (``linux/riscv64``): https://hub.docker.com/r/riscv64/ubuntu
  - IBM POWER8 (``linux/ppc64le``): https://hub.docker.com/r/ppc64le/ubuntu
  - IBM z-Systems (``linux/s390x``): https://hub.docker.com/r/s390x/ubuntu

Ubuntu system packages
**********************

- Ubuntu system package upgrade
- Ubuntu software repository management utilities
- locales for English unicode (``en_US.UTF-8``)
- locales for German unicode (``de_DE.UTF-8``)

Multiple tool version management
********************************

Based on `ASDF`_ together with the `ASDF Plugin Manager`_ all Docker images
are ready to install multiple runtime environments in different versions in
parallel into the dedicated TSN user workspace under |TSN-HOME|. The user
and group identifier, |TSN-UID| and |TSN-GID|, are derived from the original
Read-The-Docs user space to be compatible in the future in our other TSN
Docker images.

- |asdf-version|_ with:

  - |asdf-pm-version|_

References
----------

.. target-notes::

.. _`ASDF`: https://asdf-vm.com/
.. |asdf-version| replace:: ASDF :strong:`v0.14.1`
.. _`asdf-version`: https://github.com/asdf-vm/asdf/releases/tag/v0.14.1

.. _`ASDF Plugin Manager`: https://github.com/asdf-community/asdf-plugin-manager
.. |asdf-pm-version| replace:: ASDF Plugin Manager :strong:`v1.4.0`
.. _`asdf-pm-version`: https://github.com/asdf-community/asdf-plugin-manager/releases/tag/v1.4.0

.. _`Ubuntu official Docker image`: https://github.com/docker-library/official-images
.. |ubuntu-release| replace:: Ubuntu :strong:`24.04.1 LTS`
.. _`ubuntu-release`: https://hub.docker.com/_/ubuntu
.. |ubuntu-docker-tag| replace:: :strong:`ubuntu:noble-20240904.1`

.. |TSN-HOME| replace:: :code:`/home/tsn`
.. |TSN-USER| replace:: :code:`tsn`
.. |TSN-UID| replace:: :code:`UID=1005`
.. |TSN-GID| replace:: :code:`GID=205`
