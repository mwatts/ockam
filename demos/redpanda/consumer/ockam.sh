#!/usr/bin/env bash
set -e
set -m
set -x

ockam identity create 
ockam project enroll $OCKAM_TICKET 
ockam node create
ockam kafka-consumer create \
  --project-route /ip4/127.0.0.1/tcp/6000/secure/api
exec "$@" 