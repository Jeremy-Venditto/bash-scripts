#!/bin/bash
echo -e ${PATH//:/\\n} | awk '{print length, $0}' | sort -n | cut -f2- -d' '
