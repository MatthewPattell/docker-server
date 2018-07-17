#!/usr/bin/env bash

# add permission to run scripts files

for FILE in /scripts/*.sh; do
    chmod 764 $FILE
done
