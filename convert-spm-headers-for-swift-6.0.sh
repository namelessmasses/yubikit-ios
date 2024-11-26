#!/bin/bash

for header in `find Yubikit/Yubikit/SPMHeaderLinks -name \*.h`; do
    echo "Converting $header"
    sed -i 's/.*/#import "&"/g' $header
done