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

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.StandardCopyOption;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.StringTokenizer;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.commons.text.StringSubstitutor;
import org.yaml.snakeyaml.Yaml;


public final class App {

    private static final String CONTENT_SNAPS = "content-snaps";
    private static final Log LOG = LogFactory.getLog(App.class);

    private App() {

    }

    private static Set<ContentSnap> loadSnaps(String path) throws IOException {
        Yaml yaml = new Yaml();
        HashSet<ContentSnap> snapList = new HashSet<ContentSnap>();
        byte[] manifest = Files.readAllBytes(Path.of(path));
        try (InputStream is = new ByteArrayInputStream(manifest)) {
            Map<String, Object> raw = yaml.load(is);
            @SuppressWarnings("unchecked")
            Map<String, Object> snaps = (Map<String, Object>) raw.get(CONTENT_SNAPS);
            if (snaps == null) {
                throw new IOException("Manifest does not contain 'content-snaps' tag");
            }
            for (var name : snaps.keySet()) {
                @SuppressWarnings("unchecked")
                var data = (Map<String, Object>) snaps.get(name);
                if (data.get("tool") instanceof Boolean b && b) {
                    LOG.info("Skipping " + data.get("name"));
                    continue;
                }
                var snap = (Map<String, String>) snaps.get(name);
                snapList.add(new ContentSnap(snap.get("name"), snap.get("version"), snap.get("summary"),
                        snap.get("description"), snap.get("upstream"), snap.get("license"),
                        snap.getOrDefault("build-jdk", "openjdk-17-jdk-headless"),
                        snap.getOrDefault("extra-command", "")));
            }
        }
        return snapList;
    }

    private static void writeContentSnap(ContentSnap snap, Path destination, Path templates) throws IOException {
        LOG.info("Writing content snap " + snap.name + " version " + snap.version);
        Path source = templates.resolve(snap.name);
        if (!source.toFile().exists()) {
            LOG.info("source " + source + " not found, trying common");
            source = templates.resolve("common");
        }

        if (!source.toFile().exists()) {
            throw new IOException("Common template " + source.toFile() + " does not exist.");
        }

        final var snapDestination = destination.resolve(snap.name());
        snapDestination.toFile().mkdirs();
        final var root = source;
        final var replacer = new StringSubstitutor(snap.getReplacements());
        var visitor = new SimpleFileVisitor<Path>() {

            @Override
            public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
                Path relative = root.relativize(file);
                Path target = snapDestination.resolve(relative);
                target.toFile().getParentFile().mkdirs();
                var fileName = file.toFile().getName();
                if (fileName.endsWith(".yaml.template")) {
                    var content = replacer.replace(Files.readString(file));
                    fileName = fileName.substring(0, fileName.lastIndexOf('.'));
                    var snapcraftYaml = target.getParent().resolve(fileName);
                    Files.writeString(snapcraftYaml, content);
                }
                else {
                    LOG.info("Copy from " + file + " to " + target);
                    Files.copy(file, target, StandardCopyOption.REPLACE_EXISTING);
                }
                return FileVisitResult.CONTINUE;
            }
        };

        Files.walkFileTree(root, visitor);
    }

    public static void main(String[] args) throws IOException {

        Options options = new Options();
        Option installOption = Option.builder("m")
                .longOpt("manifest")
                .argName("manifest")
                .hasArg()
                .required()
                .desc("content snap manifest")
                .build();
        options.addOption(installOption);

        Option destination = Option.builder("d")
                .longOpt("destination")
                .argName("directory")
                .hasArg()
                .required(false)
                .desc("Generate snaps in <destination> directory")
                .build();
        options.addOption(destination);

        Option templates = Option.builder("t")
                .longOpt("template-directory")
                .argName("directory")
                .hasArg()
                .required(true)
                .desc("Directory with content snap templates")
                .build();
        options.addOption(templates);

        CommandLineParser parser = new DefaultParser();
        try {
            CommandLine cmd = parser.parse(options, args);
            if (cmd.hasOption("m")) {
                String manifest = cmd.getOptionValue("m");
                Set<ContentSnap> snaps = loadSnaps(manifest);
                for (ContentSnap snap : snaps) {
                    writeContentSnap(snap, Path.of(cmd.getOptionValue("d", "content")), Path.of(cmd.getOptionValue("t")));
                }
            }
            else {
                throw new ParseException("Missing -m, print help");
            }
        }
        catch (ParseException ex) {
            HelpFormatter formatter = new HelpFormatter();
            formatter.printHelp("generate", options);
            System.exit(-1);
        }
    }

    record ContentSnap(String name, String version, String summary, String description, String upstream, String license,
                       String build_jdk, String extra_command) {

        public Map<String, String> getReplacements() {

            Map<String, String> map = new HashMap<String, String>();
            map.put("name", this.name);
            map.put("version", this.version);
            map.put("summary", this.summary);
            map.put("description", multiLineDescription(this.description));
            map.put("upstream", this.upstream);
            map.put("license", this.license);
            map.put("build-jdk", this.build_jdk);
            map.put("extra-command", this.extra_command);
            return map;
        }

        public String multiLineDescription(String str) {
            StringBuilder output = new StringBuilder();
            StringTokenizer tk = new StringTokenizer(str, "\n");
            while (tk.hasMoreTokens()) {
                output.append("  ").append(tk.nextToken());
            }
            return output.toString();
        }

        @Override
        public int hashCode() {
            return this.name.hashCode();
        }

        @Override
        public boolean equals(Object other) {
            if (other == null) {
                return false;
            }
            if (other instanceof ContentSnap otherSnap) {
                return this.name.equals(otherSnap.name);
            }
            return false;
        }
    }

}
