#! /bin/bash

for x in * ; do
    echo =============================================================
    echo
    echo Dumping: $x
    echo
    gunzip -c $x | dcmdump -
done
