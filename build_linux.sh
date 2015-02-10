#!/bin/sh

rm -f logstash-forwarder_0.3.1_amd64.deb
make clean
go clean
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 make deb
