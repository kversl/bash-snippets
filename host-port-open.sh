#!/bin/bash

# test if host:port is open:  192.168.1.1:80
$(echo > /dev/tcp/192.168.1.1/80) >/dev/null 2>&1 && echo "It's up" || echo "It's down"
