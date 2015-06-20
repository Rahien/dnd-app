#!/bin/bash
dest=$1

rm -fr "dist"
rm -fr "$dest/main.rb"
rm -fr "$dest/public"
ember build
cp main.rb "$dest/main.rb"
cp -r dist "$dest/public"
