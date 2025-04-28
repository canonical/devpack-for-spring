# Devpack for Spring® Projects

## Introduction

This snap packages a command line tool to accelerate development of Spring® projects.

## Installation

`snap install devpack-for-spring --classic`

## How it works

`devpack-for-spring` invokes [Spring Boot CLI](https://docs.spring.io/spring-boot/docs/current/reference/html/cli.html) that contains additional commands.

Devpack for Spring provides prebuilt binaries of Spring Project libraries as snaps. They are configured to be used with Gradle and Maven builds.

List installed and available offline libraries:

```
$ devpack-for-spring snap list
```


Install available libraries:

```
$ devpack-for-spring snap install
```


Remove the installed libraries:

```
$ devpack-for-spring snap remove
```



`devpack-for-spring` can run pre-configured build plugins.


List the plugins configured in `devpack-for-spring`:

```
devpack-for-spring list-plugins
```


Run this command in the project root to format the project source code:

```
$ devpack-for-spring plugin format
```


The Rockcraft plugin allows you to create a build container for the project - an OCI image that contains the build toolchain and project dependencies. The plugin needs the Rockcraft snap installed:

```
snap install rockcraft --classic
```

`devpack-for-spring` includes Rockcraft plugin functionality to store dependencies offline:

```
$ devpack-for-spring plugin dependencies
```

The output is stored in `target/build-rock/dependencies/` for Maven and `build/build-rock/dependencies/` for Gradle.

The Rockcraft plugin generates a chiselled build image - an OCI image that includes a headless JDK, the build system (Gradle or Maven), and project dependencies.

The image can be uploaded to the local Docker daemon with:

```
$ devpack-for-spring plugin rockcraft push-build-rock
```

The image name is build-<your-project-name>:

The build image is a chiselled Ubuntu by default with slices for openjdk, busybox, and git.
It provides a minimal set of dependencies to build the project:

```
$ docker run -v `pwd`:`pwd` --user $(id -u):$(id -g) --env PEBBLE=/tmp <your-build-rock>:latest exec build `pwd` --no-daemon
```

Visual Studio Code provides an extension to develop inside [devcontainers](https://containers.dev/) - images that contain all the tools necessary to develop the application. The extension adds a Visual Studio Code server to the image and runs it.

To run a Visual Studio Code server, we will need to use an Ubuntu base for your rock. The Rockcraft plugin allows you to do it by adding a `build-rock/rockcraft.yaml` file that contains the overrides for the default build container:

```
name: build-demo-dev
base: ubuntu@24.04

environment:
  JAVA_HOME: /usr/lib/jvm/java-21-openjdk-${CRAFT_ARCH_BUILD_FOR}

parts:
  dependencies:
    plugin: nil
    stage-packages:
        - openjdk-21-jdk
    override-build: craftctl default
```

To use the buildRockcraft extension in the build.gradle we will also need to add the plugin:

```
plugins {
   id("io.github.rockcrafters.rockcraft") version "1.1.0"
...
}

buildRockcraft {
    rockcraftYaml =  "build-rock/rockcraft.yaml"
}
```

A future version of `devpack-for-spring` will allow you to do it with a single command.

To use the build rock as a devcontainer in Visual Studio Code, add the following .devcontainer.json to your project:
```
{
    "image" :  "<your-build-rock-image>:latest",
    "containerUser": "ubuntu"
}
```

`devpack-for-spring` can deploy your application in the chiselled ROCK container.

To build the chiselled runtime image of the Spring Boot application run:

```
$ devpack-for-spring plugin rockcraft build-rock
```

To push the image to the local docker daemon, execute:

```
$ devpack-for-spring plugin rockcraft push-rock
```

The image is tagged <your-project-name>:latest,<your-project-name>:<your-project-version>.
