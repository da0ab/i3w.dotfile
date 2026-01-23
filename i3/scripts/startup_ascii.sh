#!/bin/bash
clear
neofetch
TODAY=$(date +"%A, %d %B %Y")
echo "$TODAY" | toilet -f mono12 -F metal -w 300
