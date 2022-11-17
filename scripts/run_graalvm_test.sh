#!/bin/bash

set -e

CLIENT_LIBRARY=$1

# Get the directory of the build script
scriptDir="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

# cd to the parent directory, i.e. the root of the git submodule repository
cd "${scriptDir}"/..

# Load classes in submodule
git submodule init
git submodule update

# GAX: Publish gax to local maven
cd gax-java
GAX_VERSION=$( ./gradlew -q :gax:properties | grep '^version: ' | cut -d' ' -f2 )
echo "**** GAX version ****"
echo $GAX_VERSION
./gradlew publishToMavenLocal

# java-shared-config: Build project
cd "${scriptDir}"/..
cd java-shared-config
mvn clean install -DskipTests

# Install java-shared-dependencies
cd "${scriptDir}"/..
pushd java-shared-dependencies/first-party-dependencies
cd ..
mvn clean install -DskipTests

# Go to library's directory
cd "${scriptDir}"/..
pushd google-cloud-java/java-"${CLIENT_LIBRARY}"

# Run native image tests
mvn clean install -DskipTests -Denforcer.skip=true
mvn test -Pnative -Denforcer.skip=true




