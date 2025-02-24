# Devpack for Spring® Projects

## Introduction

This prototype snap packages a command line tool to accelerate development of the Spring® projects.

## Installation

`snap install devpack-for-spring --classic`

## How it works

`devpack-for-spring` invokes [Spring Boot CLI](https://docs.spring.io/spring-boot/docs/current/reference/html/cli.html) that contains additional commands.

### snap install

` snap install` installs a snap with an offline Maven repository and configures Maven and Gradle to use it.

### list

`snap list` lists available and installed Maven repositories.

### setup-gradle

`snap setup-gradle` updates Gradle configuration to enable all installed snaps.

### setup-maven

`snap setup-maven` updates Maven configuration to enable all installed snaps.


## Sample

1. Create a project with `devpack-for-spring`

`` $ devpack-for-pring boot start ``

2. Add JPA sample code from the standard catalog using `devpack-for-spring.spring-cli`

`` devpack-for-spring boot add jpa``


_Spring is a trademark of Broadcom Inc. and/or its subsidiaries._
