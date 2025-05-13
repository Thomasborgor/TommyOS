#!/bin/bash

# Check if a file was provided
if [ -z "$1" ]; then
    echo "Usage: $0 filename"
    exit 1
fi

# Use xxd with options to dump raw hex (no addresses or ASCII), then remove newlines
xxd -p "$1" | tr -d '\n'
echo
