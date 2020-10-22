"""Prune the old nightly build and only keep the latest one per version."""
import sys
import argparse
import subprocess
import logging
import os


def py_str(cstr):
    return cstr.decode("utf-8")


def extract_key_order(name):
    """Extract group key and order from name.

    Parameters
    ----------
    name : str

    Returns
    -------
    key : str
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
    key, name = name.split("/", 1)
    order = name[: -len(".tar.bz2")]
    py_loc = order.find("_py")
    key = (key, order[py_loc:])
    order = order[:py_loc]
    order = order.rsplit("-", 1)[-1]
    order = order.split("_")
    try:
        order[0] = int(order[0])
    except:
        order.insert(0, 0)
    order = tuple(order)
    return key, order


def list_packages(name, version):
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


def remove_package(args, path):
    cmd = ["anaconda", "remove", "--force", f"{args.name}/{args.version}/{path}"]
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
    for name in files:
        key, order = extract_key_order(name)
        if key not in group_map:
            group_map[key] = []
        group_map[key].append((order, name))
    return group_map


def run_prune(group_map, args):
    for key, files in group_map.items():
        for idx, item in enumerate(reversed(sorted(files))):
            if idx < args.keep_top:
                print("keep  %s" % item[1])
            else:
                remove_package(args, item[1])
        print()


def main():
    logging.basicConfig(level=logging.INFO)
    parser = argparse.ArgumentParser(description="Prunes older builds sorted by build str.")
    parser.add_argument("--version", type=str)
    parser.add_argument("--keep-top", type=int, default=1)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("name", type=str)

    if "ANACONDA_API_TOKEN" not in os.environ:
        raise RuntimeError("need ANACONDA_API_TOKEN")
    args = parser.parse_args()
    files = list_packages(args.name, args.version)
    groups = group_packages(files)
    run_prune(groups, args)


if __name__ == "__main__":
    main()
