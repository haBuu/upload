#!/bin/sh
cd $TRAVIS_BUILD_DIR/static
npm install webpack -g
npm install
webpack
cd $TRAVIS_BUILD_DIR
mkdir files
