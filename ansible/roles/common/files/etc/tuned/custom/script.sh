#!/bin/sh

. /usr/lib/tuned/functions

start() {
    echo never > /sys/kernel/mm/transparent_hugepage/defrag
    return 0
}

stop() {
    return 0
}

process $@
