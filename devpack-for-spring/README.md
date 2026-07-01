# Devpack for Spring® Projects

## Introduction

`devpack-for-spring` is a command line tool for developing and packaging Spring® projects. It automates environment setup, build plugins configuration and offline library management.

## Installation

`snap install devpack-for-spring --classic`

## How it works

Setup development environment:

```
$ devpack-for-spring setup [options]
```

This command installs a selection of `apt` and `snap` packages listed in the [`setup-configuration.yaml`](setup-configuration.yaml) file.
You can override the default configuration by creating a custom file at `$HOME/.config/devpack-for-spring/setup-configuration.yaml` or by setting the `SPRING_CLI_SETUP_COMMANDS_CONFIGURATION` environment variable to your file's path.
By default, the command launches an interactive menu. Selecting an item will install it, and deselecting it will uninstall it.

The following options are supported:
- `--add <list>`: A comma-separated list of software items to install. Using this option runs the setup command in headless (non-interactive) mode. This option is mutually exclusive with `--file`.
- `--file <path>`: Path to a YAML file containing a list of software items to install in headless mode. This option is mutually exclusive with `--add`.
- `--save <path>`: Path to save the list of installed software (defaults to `$HOME/.config/devpack-for-spring/installed_config.yaml`).
- `--save-only`: Do not update the host system, only save the install file.
- `--uninstall`: A flag to uninstall unselected software items. In interactive mode, this removes any unchecked software. In headless mode, it uninstalls any software listed in the configuration file that is not specified in `--add` or `--file`.
- `--retry`: Retry failing commands.
<br>
<br>
Create a new Spring Boot Project:

```
$ devpack-for-spring boot start
```

Devpack for Spring provides prebuilt binaries of Spring Project libraries as snaps. They are configured to be used with Gradle and Maven builds.

List installed and available offline libraries:

```
$ devpack-for-spring libraries
```


Install available libraries:

```
$ devpack-for-spring add-library
```


Remove the installed libraries:

```
$ devpack-for-spring remove-library
```

### Run build plugins

`devpack-for-spring` can run pre-configured build plugins.


List the plugins configured in `devpack-for-spring`:

```
devpack-for-spring plugins
```


Run this command in the project root to format the project source code:

```
$ devpack-for-spring run format
```

See [BuildPlugins](https://github.com/canonical/devpack-for-spring-cli/blob/main/BuildPlugins.md) for more information.

#### Rockcraft plugin

The Rockcraft plugin allows you to create a build container for the project - an OCI image that contains the build toolchain and project dependencies. The plugin needs the Rockcraft snap installed:

```
snap install rockcraft --classic
```

`devpack-for-spring` includes Rockcraft plugin functionality to store dependencies offline:

```
$ devpack-for-spring run dependencies
```

The output is stored in `target/build-rock/dependencies/` for Maven and `build/build-rock/dependencies/` for Gradle.

The Rockcraft plugin generates a chiselled build image - an OCI image that includes a headless JDK, the build system (Gradle or Maven), and project dependencies.

The image can be uploaded to the local Docker daemon with:

```
$ devpack-for-spring run rockcraft push-build-rock
```

The image name is `build-<your-project-name>`:

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
$ devpack-for-spring run rockcraft build-rock
```

To push the image to the local docker daemon, execute:

```
$ devpack-for-spring run rockcraft push-rock
```

The image is tagged `<your-project-name>:latest`,`<your-project-name>:<your-project-version>`.

## Limitations/Known issues

- The 'run' command for Gradle projects supports only Gradle 8.4 and up.
- The 'run' command requires the Gradle project to be configurable.
- The 'run dependencies' command includes Rockcraft plugin dependencies.
- The 'run dependencies' command depends on the jar task.
- The rock export assumes Java 21 by default if the project toolchain settings are not configured.
