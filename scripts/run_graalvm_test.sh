#!/bin/bash

set -e

CLIENT_LIBRARY=$1
export GOOGLE_CLOUD_PROJECT=mpeddada-tf-25868
gcloud config set project "$GOOGLE_CLOUD_PROJECT"
gcloud config list

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

# cd into shared-dependencies parent directory
cd ..

mvn clean install -DskipTests

# Namespace (xmlns) prevents xmllint from specifying tag names in XPath
SHARED_DEPS_VERSION=$( sed -e 's/xmlns=".*"//' pom.xml | xmllint --xpath '/project/version/text()' - )

if [ -z "${SHARED_DEPS_VERSION}" ]; then
  echo "Version is not found in pom.xml"
  exit 1
fi


# Library
# Clone monorepo libraries or cd into handwritten libraries in the submodule
if [[ $CLIENT_LIBRARY == "orgpolicy" ]]; then
  git clone "https://github.com/googleapis/google-cloud-java.git" --depth=1
  pushd google-cloud-java/google-cloud-jar-parent
else
  # Move to submodule parent directory and cd into library directory
  cd ..
  pushd java-"${CLIENT_LIBRARY}"
fi

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

if [[ $CLIENT_LIBRARY == "orgpolicy" ]]; then
  popd
  pushd google-cloud-java/java-"${CLIENT_LIBRARY}"
fi

# Run native image tests
mvn clean install -DskipTests -Denforcer.skip=true
java --version
mvn test -Pnative -Denforcer.skip=true




