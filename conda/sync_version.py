# Synchronize version with the tvm version
import os

def main():
    version_py = os.path.join("tvm", "version.py")
    libversion = {"__file__": version_py}
    exec(compile(open(version_py, "rb").read(), version_py, "exec"), libversion, libversion)
    libversion["update"](
        os.path.join("conda", "recipe", "meta.yaml"),
        "(?<=version = ')[.0-9a-z]+",
        libversion["__version__"],
    )

if __name__ == "__main__":
    main()
