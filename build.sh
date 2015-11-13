#!/bin/bash
dest="build"
if [ ! -d "$dest" ]; then
		mkdir "$dest"
fi

rm -fr "dist"
rm -fr "$dest/web"
rm -fr "$dest/environment"
rm -fr "$dest/docker-compose.yml"

ember build

mkdir "$dest/web"
cp main.rb "$dest/web/main.rb"
cp Gemfile "$dest/web/Gemfile"
cp environment "$dest/environment"
cp -r dist "$dest/web/public"
cp -r certificates "$dest/web/certificates"
cp spells.csv "$dest/web/spells.csv"
cp docker-compose.yml "$dest/docker-compose.yml"

if [ ! -d "$dest/couchdb" ]; then
    mkdir "$dest/couchdb"
fi
