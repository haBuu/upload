#!/bin/sh
cd $TRAVIS_BUILD_DIR/front
npm install webpack -g
npm install
webpack
cd $TRAVIS_BUILD_DIR
