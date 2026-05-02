#! /usr/bin/env bash

cat README.md | sed -e '
/^\#\# Options/,/^\#\# Examples/ {//!d;}
/^\#\# Options/ r OPTIONS.csv
'
