# Docker-based distribution of p4c

Minimal Docker image with the open source P4 compiler (p4c) that includes the
following backends:

* `p4c-bm-ss`: BMv2 simple_switch backend;
* `p4c-graphs`: graphs generator.

This image was created to facilitate the compilation of P4 programs distributed
with the ONOS SDN controller, but you can use it without ONOS.

To obtain the image:

    docker pull opennetworking/p4c:<tag>

## Tags

The image comes in two tags:

* `opennetworking/p4c:latest` Updated daily and built from the master branch of
  the [p4lang/p4c][p4c] repository;
* `opennetworking/p4c:stable` Built using an arbitrarily selected p4c commit that
  produces outputs known to work well with the ONOS development and testing
  environment.
* `opennetworking/p4c:stable-20210108` Built using a p4c commit from 2021-01-08 that
  supports `@p4runtime_translation` annotations.

## Status [![Build Status](https://github.com/opennetworkinglab/p4c-docker/actions/workflows/main.yml/badge.svg)](https://github.com/opennetworkinglab/p4c-docker/actions/workflows/main.yml)

Images are built daily using [Github Actions][GH Actions] and pushed to 
[Docker Hub][Docker Hub].

[GH Actions]: https://github.com/features/actions
[Docker Hub]: https://hub.docker.com/r/opennetworking/p4c
[p4c]: https://github.com/p4lang/p4c
