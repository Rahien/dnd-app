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
cp manifest.json "$dest/web/public"
cp spells.csv "$dest/web/spells.csv"
cp docker-compose.yml "$dest/docker-compose.yml"

if [ ! -d "$dest/mongodb" ]; then
    mkdir "$dest/mongodb"
fi

echo "Build completed, result stored in ./build folder. To start the project, move the ./build folder to the location of your choice, enter it and run 'docker-compose up'"
