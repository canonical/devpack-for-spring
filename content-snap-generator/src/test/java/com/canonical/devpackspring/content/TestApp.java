/*
 * This file is part of Devpack for Spring® snap.
 *
 * Copyright 2025 Canonical Ltd.
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License version 3, as published by the
 * Free Software Foundation.
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License version 3, as published by the
 * Free Software Foundation.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 */
package com.canonical.devpackspring.content;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.yaml.snakeyaml.Yaml;

public final class TestApp {

    @Test
    public void testGenerateManifest(@TempDir Path testDir) throws IOException {
        String manifest = """
                content-snaps:
                  content-for-spring-boot-33:
                    upstream: https://github.com/spring-projects/spring-boot
                    version: 3.3.2
                    channel: latest/edge
                    mount: /maven-repo
                    oss-eol: 2025-12-31
                    name: content-for-spring-boot-33
                    summary:  Rebuild of Spring® Boot Framework sources v3.4.x
                    description: |
                      Rebuild of Spring® Boot Framework sources v3.4.x

                      Spring is a trademark of Broadcom Inc. and/or its subsidiaries.
                    license: Apache-2.0
                    build-jdk: openjdk-17-jdk-headless
                    lts: false
                  
                  content-for-spring-boot-34:
                    upstream: https://github.com/spring-projects/spring-boot
                    version: 3.4.2
                    channel: latest/edge
                    mount: /maven-repo
                    oss-eol: 2025-12-31
                    name: content-for-spring-boot-34
                    summary:  Rebuild of Spring® Boot Framework sources v3.4.x
                    description: |
                      Rebuild of Spring® Boot Framework sources v3.4.x

                      Spring is a trademark of Broadcom Inc. and/or its subsidiaries.
                    license: Apache-2.0
                    build-jdk: openjdk-17-jdk-headless
                    lts: false
                """;
        Path testManifest = testDir.resolve("manifest.yaml");
        Files.writeString(testManifest, manifest);
        App.main(new String[]{"-m", testManifest.toString(), "-d", testDir.toString(), "-t", "src/test/resources/com/canonical/devpackspring/content"});

        Path contentSnapPath = testDir.resolve("content-for-spring-boot-34");
        Path snapcraftYaml = contentSnapPath.resolve("snap/snapcraft.yaml");
        Path testFile = contentSnapPath.resolve("test.file");

        assertThat(snapcraftYaml.toFile()).exists();
        assertThat(testFile.toFile()).exists();

        Yaml yaml = new Yaml();

        Map<String, Object> ret = yaml.load(Files.readString(snapcraftYaml));
        assertThat(ret.get("version")).isEqualTo("3.4.2");
        assertThat(ret.get("name")).isEqualTo("content-for-spring-boot-34");

        contentSnapPath = testDir.resolve("content-for-spring-boot-33");
        snapcraftYaml = contentSnapPath.resolve("snap/snapcraft.yaml");
        assertThat(snapcraftYaml.toFile()).exists();
        ret = yaml.load(Files.readString(snapcraftYaml));
        assertThat(ret.get("version")).isEqualTo("3.3.2");
        assertThat(ret.get("name")).isEqualTo("content-for-spring-boot-33");
    }

    @Test
    @Disabled
    void testBuildSnap(@TempDir Path testDir) throws IOException, InterruptedException {
        Path contentSnapPath = testDir.resolve("content-for-spring-boot-34");
        testGenerateManifest(testDir);
        Process snapcraft = new ProcessBuilder("snapcraft").directory(contentSnapPath.toFile()).inheritIO().start();
        int ret = snapcraft.waitFor();
        assertThat(ret).isEqualTo(0);
        Path builtSnapPath = contentSnapPath.resolve("content-for-spring-boot-34_3.4.2_amd64.snap");
        assertThat(builtSnapPath.toFile()).exists();
    }

}
