#!/bin/bash
dest=$1

ember build
rm -fr "$dest/*"
cp main.rb "$dest/main.rb"
cp -r dist "$dest/public"
