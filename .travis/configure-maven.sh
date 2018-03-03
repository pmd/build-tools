#!/bin/bash
set -ev

# remember the current directory
SOURCE_HOME=$PWD

cd $HOME

echo "MAVEN_OPTS='-Xms1g -Xmx1g'" > .mavenrc
mkdir -p .m2
cp $SOURCE_HOME/.travis/travis-settings.xml .m2/settings.xml
