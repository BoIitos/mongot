load("@rules_cc//cc:cc_binary.bzl", "cc_binary")

cc_binary(
    name = "mongot_vecsim",
    srcs = ["mongot_vecsim.c"],
    copts = [
        "-O3",
        "-DNDEBUG",
    ] + select({
        "//bazel/platforms:is_linux_aarch64": ["-march=armv8.2-a+dotprod+sve"],
        "//bazel/platforms:is_macos_aarch64": ["-march=armv8.2-a+dotprod"],
        "//conditions:default": [],
    }),
    linkshared = True,
    linkstatic = False,
    # No CC toolchain on macOS x86_64; dependents must select() this out.
    target_compatible_with = select({
        "//bazel/platforms:is_macos_x86_64": ["@platforms//:incompatible"],
        "//conditions:default": [],
    }),
    visibility = ["//visibility:public"],
)

# Windows x86_64 build of the same library, cross-compiled with llvm-mingw.
# Must be built on a Linux x86_64 host (native Linux or WSL2). Bundled into
# //deploy:mongot-community-windows as lib/mongot_vecsim.dll, where
# Similarity.java finds it next to bin/.
genrule(
    name = "mongot_vecsim_windows_x86_64",
    srcs = ["mongot_vecsim.c"],
    outs = ["windows_x86_64/mongot_vecsim.dll"],
    cmd = " ".join([
        "$(location @llvm_mingw_linux_x86_64//:bin/x86_64-w64-mingw32-clang)",
        "-std=c11",
        "-O3",
        "-DNDEBUG",
        "-shared",
        # Reproducible output: no link timestamp in the PE header.
        "-Wl,--no-insert-timestamp",
        "-o $@",
        "$(location mongot_vecsim.c)",
    ]),
    exec_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    tools = [
        "@llvm_mingw_linux_x86_64//:all_files",
        "@llvm_mingw_linux_x86_64//:bin/x86_64-w64-mingw32-clang",
    ],
    visibility = ["//visibility:public"],
)
