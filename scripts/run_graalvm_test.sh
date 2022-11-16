#!/bin/bash

set -e

CLIENT_LIBRARY=$1

## Get the directory of the build script
scriptDir="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
## cd to the parent directory, i.e. the root of the git repo
cd "${scriptDir}"/..

# Load classes in submodule
git submodule init
git submodule update

# GAX: Publish gax to local maven to make it available for downstream libraries
cd gax-java
#git checkout update-gax

# Read current gax version
GAX_VERSION=$( ./gradlew -q :gax:properties | grep '^version: ' | cut -d' ' -f2 )
echo $GAX_VERSION
./gradlew publishToMavenLocal

# java-shared-dependencies
cd "${scriptDir}"/..
#git checkout update-gax
pushd java-shared-dependencies/first-party-dependencies

# replace version
xmllint --shell pom.xml << EOF
setns x=http://maven.apache.org/POM/4.0.0
cd .//x:artifactId[text()="gax-bom"]
cd ../x:version
set ${GAX_VERSION}
cd ../..
cd .//x:artifactId[text()="gax-grpc"]
cd ../x:version
set ${GAX_VERSION}
save pom.xml
EOF

cd ..
mvn clean install -DskipTests

# Namespace (xmlns) prevents xmllint from specifying tag names in XPath
SHARED_DEPS_VERSION=$( sed -e 's/xmlns=".*"//' pom.xml | xmllint --xpath '/project/version/text()' - )

if [ -z "${SHARED_DEPS_VERSION}" ]; then
  echo "Version is not found in pom.xml"
  exit 1
fi


# Library
# Need to replace based on lib used
git clone "https://github.com/googleapis/google-cloud-java.git" --depth=1
pushd google-cloud-jar-parent

# Replace shared-dependencies version
xmllint --shell pom.xml << EOF
setns x=http://maven.apache.org/POM/4.0.0
cd .//x:artifactId[text()="google-cloud-shared-dependencies"]
cd ../x:version
set ${SHARED_DEPS_VERSION}
save pom.xml
EOF

echo "Modification on the shared dependencies BOM:"
git diff
echo

pushd google-cloud-java/java-"${CLIENT_LIBRARY}"

# Run native image tests
mvn clean install -DskipTests -Denforcer.skip=true
mvn test -Pnative -Denforcer.skip=true




