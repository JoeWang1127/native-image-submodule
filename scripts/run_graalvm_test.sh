#!/bin/bash

CLIENT_LIBRARY=$1

## Get the directory of the build script
scriptDir="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
## cd to the parent directory, i.e. the root of the git repo
cd "${scriptDir}"/..
pwd
# Publish gax to local maven to make it available for downstream libraries
#cd gax-java
#./gradlew publishToMavenLocal
#
#cd "${scriptDir}"/..
#cd java-shared-dependencies
#mvn clean install -DskipTests
#
## Namespace (xmlns) prevents xmllint from specifying tag names in XPath
#SHARED_DEPS_VERSION=$( sed -e 's/xmlns=".*"//' pom.xml | xmllint --xpath '/project/version/text()' - )
#
#if [ -z "${SHARED_DEPS_VERSION}" ]; then
#  echo "Version is not found in pom.xml"
#  exit 1
#fi
#
#cd "${scriptDir}"/"${CLIENT_LIBRARY}"

#mvn clean install -DskipTests
#mvn test -Pnative




