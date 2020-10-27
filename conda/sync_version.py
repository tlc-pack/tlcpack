# Synchronize version with the tvm version
import os


def main():
    version_py = os.path.join("tvm", "version.py")
    libversion = {"__file__": version_py}
    exec(
        compile(open(version_py, "rb").read(), version_py, "exec"),
        libversion,
        libversion,
    )
    pub_ver = libversion["__version__"]

    if "git_describe_version" in libversion:
        pub_ver, _ = libversion["git_describe_version"]()

    libversion["update"](
        os.path.join("conda", "recipe", "meta.yaml"),
        "(?<=version = ')[.0-9a-z]+",
        pub_ver,
    )


if __name__ == "__main__":
    main()
