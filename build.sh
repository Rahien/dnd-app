#!/bin/bash
dest="build"
if [ ! -d "$dest" ]; then
		mkdir "$dest"
fi

rm -fr "dist"
rm -fr "$dest/main.rb"
rm -fr "$dest/Gemfile"
rm -fr "$dest/spells.csv"
rm -fr "$dest/public"
rm -fr "$dest/environment"
rm -fr "$dest/certificates"
rm -fr "$dest/docker-compose.yml"

ember build

cp main.rb "$dest/main.rb"
cp Gemfile "$dest/Gemfile"
cp environment "$dest/environment"
cp -r dist "$dest/public"
cp -r certificates "$dest/certificates"
cp spells.csv "$dest/spells.csv"
cp docker-compose.yml "$dest/docker-compose.yml"
