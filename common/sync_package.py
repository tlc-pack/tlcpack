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
__stable_build__ = "v0.7"
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


def name_with_cuda(args, package_name):
    """Update name with cuda version"""
    if args.cuda == "none":
        return package_name
    return package_name + "-cu" + "".join(args.cuda.split("."))


def get_version_tag():
    """
    Collect version strings using TVM's python/tvm/version.py.

    Return a tuple with two version strings:
    - pub_ver: includes major, minor and dev with the number of
               changes since last release, e.g. "0.8.dev1473".
    - local_ver: includes major, minor, dev and last git hash
                 e.g. "0.8.dev1473+gb7488ef47".
    """
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

    return pub_ver, local_ver


def update_libinfo(args):
    _ , local_ver = get_version_tag()

    update(
        os.path.join(args.src, "python", "tvm", "_ffi", "libinfo.py"),
        [("(?<=__version__ = \")[^\"]+", local_ver)],
        args.dry_run
    )


def update_setup(args, package_name):
    rewrites = [
        (r'(?<=name=")[^\"]+', name_with_cuda(args, package_name)),
        (r'(?<=description=")[^\"]+',
         "Tensor learning compiler binary distribution"),
        (r'(?<=url=")[^\"]+', "https://tlcpack.ai")
    ]
    update(os.path.join(args.src, "python", "setup.py"), rewrites, args.dry_run)


def update_conda(args, package_name):
    pub_ver, _ = get_version_tag()

    # create initial yaml file
    meta_yaml = os.path.join("conda", "recipe", "meta.yaml")
    with open(meta_yaml, "w") as fo:
        fo.write(open(os.path.join("conda", "recipe", "meta.in.yaml")).read())

    update(
        meta_yaml,
        [(r"(?<=default_pkg_name = ')[^\']+", package_name),
         (r"(?<=version = ')[.0-9a-z]+", pub_ver)],
        args.dry_run
    )

    update(
        os.path.join("conda", "build_config.yaml"),
        [("(?<=pkg_name: ')[^\']+", package_name)],
        args.dry_run
    )


def main():
    parser = argparse.ArgumentParser(description="Synchronize the package name and version.")
    parser.add_argument("--dry-run",
                        action="store_true",
                        help="Run the syncronization process without modifying any files.")
    parser.add_argument("--src",
                        type=str,
                        metavar="DIR_NAME",
                        default="tvm",
                        help="Set the directory in which tvm souces will be checked out. "
                             "Defaults to 'tvm'")
    parser.add_argument("--revision",
                        type=str,
                        default="origin/main",
                        help="Specify a TVM revision to build packages from. "
                             "Defaults to 'origin/main'")
    parser.add_argument("--cuda",
                        type=str,
                        default="none",
                        choices=["none", "10.0", "10.1", "10.2"],
                        help="CUDA version to be linked to the resultant binaries,"
                             "or none, to disable CUDA. Defaults to none.")
    parser.add_argument("--package-name",
                        type=str,
                        default="",
                        help="Name of the produced Python packages. Optional. "
                             "Defaults to the provided build_type.")
    parser.add_argument("build_type",
                        type=str,
                        help="Type of package to be built. Use 'tlcpack' to build the last stable "
                             "revision or 'tlcpack-nightly' build the value provided via --revision.")
    args = parser.parse_args()

    package_name = args.package_name or args.build_type

    if "nightly" not in args.build_type:
        checkout_source(args.src, __stable_build__)
    else:
        checkout_source(args.src, args.revision)

    update_libinfo(args)
    update_setup(args, package_name)
    update_conda(args, package_name)


if __name__ == "__main__":
    main()
