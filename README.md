# native-image-submodule

After cloning the repository follow the following steps to test out changes in gax.
## Step 1: Make changes in gax and install to local maven repo 
1. `cd gax-java`
2. Make changes in gax.
3. `git add .` && `git commit -m <message>`
4. git push origin main
5. In case you want to upload these changes for collaborators to use:

```build
cd $root_of_the_project
git add gax-java
git commit -m <commit>
git push origin main
```

6. Call `./gradlew publishToMavenLocal`. This will install GAX to your local maven repository.

## Step 2: (First time only) Install java-shared-dependencies with latest GAX changes
1. Ensure that java-shared-dependencies uses SNAPSHOT version of GAX.
2. Install shared-dependencies to your local maven repo by calling:

```build
cd java-shared-dependencies
mvn clean install -DskipTests
```

## Step 3: Test changes in downstream library
We will be using java-bigquery in this example.

1. `cd java-bigquery`
2. `mvn test -Pnative`