#!/bin/bash

export PASSWD=airgap2
export HOST_PWD=$(pwd)

docker compose build
