"""Prune the old nightly build and only keep the latest one per version."""
import sys
import argparse
import subprocess
import logging
import os


def py_str(cstr):
    return cstr.decode("utf-8")


def extract_group_key_order(path):
    """Extract group key and order from name.

    Parameters
    ----------
    path : str

    Returns
    -------
    group_key : tuple
        The group the build should belong to

    order : tuple
        The order used to sort the builds.
        The higher the latest

    Note
    ----
    We make use of the naming convention of the build string.
    GIT_BUILD_STR starts by the number of commits from the latest tag.
    So the larger the number is, the more commits are applied.
    We will favor the build with more commits.
    """
    platform, name = path.split("/", 1)
    name = name[: -len(".tar.bz2")]
    py_loc = name.find("_py")
    group_key = [platform]

    if py_loc != -1:
        group_key.append(name[py_loc + 1 :])
        name = name[:py_loc]

    _, ver, build_str = name.rsplit("-", 2)

    try:
        order = [int(build_str.split("_")[0])]
    except:
        order = [0]

    dev_pos = ver.find(".dev")
    if dev_pos != -1:
        rc_pos = ver.find("rc")
        # all nightly share the same group
        group_key.append("nightly")
        # dev number as the order.
        pos = dev_pos
        if rc_pos != -1:
            pos = rc_pos
        pub_ver = [int(x) for x in ver[:pos].split(".")]
        if rc_pos != -1:
            pub_ver += [int(ver[rc_pos + 2 : dev_pos])]
        else:
            pub_ver += [int(1e9)]
        order = pub_ver + [int(ver[dev_pos + 4 :])] + order
    else:
        # stable version has its own group
        group_key.append(ver)

    return tuple(group_key), tuple(order)


def list_package_with_version(name, version):
    cmd = ["anaconda", "show", f"{name}/{version}"]
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    (out, _) = proc.communicate()
    if proc.returncode != 0:
        msg = "anaconda show error:"
        msg += py_str(out)
        logging.warning(msg)
        return []
    files = []
    for line in py_str(out).split("\n"):
        line = line.strip()
        if line.endswith("tar.bz2"):
            files.append(line.rsplit(None, 1)[-1])
    return files


def list_package_versions(name):
    cmd = ["anaconda", "show", name]
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    (out, _) = proc.communicate()
    if proc.returncode != 0:
        msg = "anaconda show error:"
        msg += py_str(out)
        logging.warning(msg)
        return []

    start_version_sec = False
    versions = []
    for line in py_str(out).split("\n"):
        line = line.strip()
        if line.startswith("Versions:"):
            start_version_sec = True
            continue
        if start_version_sec:
            if line.find("+") != -1:
                version = line.split("+")[-1].strip()
                versions.append(version)
    return versions


def list_packages(name):
    files = []
    for version in list_package_versions(name):
        for path in list_package_with_version(name, version):
            files.append((version, path))
    return files


def remove_package(args, version, path):
    cmd = ["anaconda", "remove", "--force", f"{args.name}/{version}/{path}"]
    logging.debug(cmd)
    fprune = print("remove %s" % path)
    if args.dry_run:
        return
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    (out, _) = proc.communicate()
    if proc.returncode != 0:
        msg = "anaconda remove error:"
        msg += py_str(out)
        logging.warning(msg)


def group_packages(files):
    group_map = {}
    for version, path in files:
        key, order = extract_group_key_order(path)
        if key not in group_map:
            group_map[key] = []
        group_map[key].append((order, version, path))
    return group_map


def run_prune(group_map, args):
    for key, files in group_map.items():
        print(f"Group {key}:")
        for idx, item in enumerate(reversed(sorted(files))):
            order, version, path = item
            if idx < args.keep_top:
                print("keep  %s" % path)
            else:
                remove_package(args, version, path)
        print()


def main():
    logging.basicConfig(level=logging.INFO)
    parser = argparse.ArgumentParser(
        description="Prunes older builds sorted by build str."
    )
    parser.add_argument("--keep-top", type=int, default=1)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("name", type=str)

    if "ANACONDA_API_TOKEN" not in os.environ:
        raise RuntimeError("need ANACONDA_API_TOKEN")
    args = parser.parse_args()
    files = list_packages(args.name)
    groups = group_packages(files)
    run_prune(groups, args)


if __name__ == "__main__":
    main()
