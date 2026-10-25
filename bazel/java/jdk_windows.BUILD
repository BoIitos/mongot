load("@rules_pkg//pkg:mappings.bzl", "pkg_files", "strip_prefix")

# Windows JDK, packaged as bin/jdk/ of //deploy:mongot-community-windows.
pkg_files(
    name = "jdk",
    srcs = glob(
        ["**"],
        exclude = [
            "BUILD.bazel",
            "WORKSPACE",
            "MODULE.bazel",
            "MODULE.bazel.lock",
            # Not needed at runtime; jmods alone is ~80 MB.
            "demo/**",
            "include/**",
            "jmods/**",
            "man/**",
        ],
    ),
    prefix = "jdk",
    strip_prefix = strip_prefix.from_pkg(),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "java",
    srcs = ["bin/java.exe"],
    visibility = ["//visibility:public"],
)
