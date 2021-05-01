""" Synchronize name and the tvm version """
import os
import re
import subprocess
import argparse


# Modify the following two settings during release
# -----------------------------------------------------------
# Tag used for stable build.
# We need to use a tag after v0.7 to enable windows build
# switch to a stable tag after v0.8
__stable_build__ = "7b11b921720e0d79ba63182f2bce4b703824c7b7"
# -----------------------------------------------------------

def py_str(cstr):
    return cstr.decode("utf-8")


def checkout_source(src, tag):
    def run_cmd(cmd):
        proc = subprocess.Popen(
            cmd, cwd=src, stdout=subprocess.PIPE, stderr=subprocess.STDOUT
        )
        (out, _) = proc.communicate()
        if proc.returncode != 0:
            msg = "git error: %s" % cmd
            msg += py_str(out)
            raise RuntimeError(msg)

    run_cmd(["git", "checkout", "-f", tag])
    run_cmd(["git", "submodule", "update"])
    print("git checkout %s" % tag)


def update(file_name, rewrites, dry_run=False):
    update = []
    need_update = False
    for l in open(file_name):
        for pattern, target in rewrites:
            result = re.findall(pattern, l)
            if result and result[0] != target:
                l = re.sub(pattern, target, l)
                need_update = True
                print("%s: %s -> %s" % (file_name, result[0], target))
                break

        update.append(l)

    if need_update and not dry_run:
        with open(file_name, "w") as output_file:
            for l in update:
                output_file.write(l)


def name_with_cuda(args):
    """Update name with cuda version"""
    if args.cuda == "none":
        return args.name
    return args.name + "-cu" + "".join(args.cuda.split("."))


def update_setup(args):
    rewrites = [
        (r'(?<=name=")[^\"]+', name_with_cuda(args)),
        (r'(?<=description=")[^\"]+',
         "Tensor learning compiler binary distribution"),
        (r'(?<=url=")[^\"]+', "https://tlcpack.ai")
    ]
    update(os.path.join(args.src, "python", "setup.py"), rewrites, args.dry_run)


def update_conda(args):
    version_py = os.path.join("tvm", "version.py")
    libversion = {"__file__": version_py}
    exec(
        compile(open(version_py, "rb").read(), version_py, "exec"),
        libversion,
        libversion,
    )
    pub_ver = libversion["__version__"]
    local_ver = pub_ver

    if "git_describe_version" in libversion:
        pub_ver, local_ver = libversion["git_describe_version"]()

    # create initial yaml file
    meta_yaml = os.path.join("conda", "recipe", "meta.yaml")
    with open(meta_yaml, "w") as fo:
        fo.write(open(os.path.join("conda", "recipe", "meta.in.yaml")).read())

    update(
        meta_yaml,
        [(r"(?<=default_pkg_name = ')[^\']+", args.name),
         (r"(?<=version = ')[.0-9a-z]+", pub_ver)],
        args.dry_run
    )

    update(
        os.path.join("conda", "build_config.yaml"),
        [("(?<=pkg_name: ')[^\']+", args.name)],
        args.dry_run
    )


def main():
    parser = argparse.ArgumentParser(description="Synchronize the package name and version.")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--src", type=str, default="tvm")
    parser.add_argument("--cuda", type=str, default="none",
                        choices=["none", "10.0", "10.1", "10.2"])
    parser.add_argument("name", type=str)
    args = parser.parse_args()

    if "nightly" not in args.name:
        checkout_source(args.src, __stable_build__)
    else:
        checkout_source(args.src, "origin/main")

    update_setup(args)
    update_conda(args)


if __name__ == "__main__":
    main()
