#!/usr/bin/env python3
"""Prune older tags for given new ones."""
import os
import logging
import argparse
import subprocess


def py_str(cstr):
    return cstr.decode("utf-8")


def run_cmd(cmd):
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    (out, _) = proc.communicate()
    if proc.returncode != 0:
        msg = "cmd error %s: " % cmd
        msg += py_str(out)
        raise RuntimeError(msg)
    return py_str(out)


def extract_order(tag):
    """Extract group key and order from tag.

    Parameters
    ----------
    tag : str
        The tag

    Returns
    -------
    order : tuple
        The order used to sort the builds.
        The higher the latest
    """
    ver = tag[1:] if tag.startswith("v") else tag
    plus_pos = ver.find("+")
    if plus_pos != -1:
        ver = ver[:plus_pos]

    temp_ver = 2048
    sub_pos = ver.find("-t")
    if sub_pos != -1:
        ver = ver[:sub_pos]
        try:
            temp_ver = int(ver[sub_pos + 1])
        except:
            temp_ver = 0

    dev_pos = ver.find(".dev")
    dev_ver = 0
    if dev_pos != -1:
        dev_ver = int(ver[dev_pos + 4 :])
        ver = ver[:dev_pos]

    pub_ver = [int(x) for x in ver.split(".")]
    return tuple(pub_ver + [dev_ver, temp_ver])


def list_images(prefix):
    images = {}
    for line in run_cmd(["docker", "image", "ls"]).split("\n")[1:]:
        if not line:
            continue
        arr = line.split()
        name = arr[0]
        tag = arr[1]
        if not name.startswith(prefix) or tag == "latest":
            continue
        order = extract_order(tag)
        if name in images:
            images[name].append((tag, order))
        else:
            images[name] = [(tag, order)]
    return images


def run_prune(args, images):
    remove_list = []
    for name, tags in images.items():
        print("Group %s:" % name)
        for idx, item in enumerate(reversed(sorted(tags, key=lambda x: x[1]))):
            tag, _ = item
            if idx < args.keep_top:
                print("keep  %s:%s" % (name, tag))
            else:
                print("remove  %s:%s" % (name, tag))
                remove_list.append((name, tag))
        print()
    return remove_list


def delete_images(remove_list, dry_run):
    rm_list = ["%s:%s" % (name, tag) for name, tag in remove_list]
    if not dry_run:
        out = run_cmd(["docker", "image", "rm"] + rm_list)

    if remove_list:
        print("Finish deleting %d tags" % len(remove_list))


def main():
    logging.basicConfig(level=logging.WARNING)
    parser = argparse.ArgumentParser(description="Prune CI docker images by version.")
    parser.add_argument("--keep-top", type=int, default=1)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--prefix", type=str, default="tlcpack")

    args = parser.parse_args()
    images = list_images(args.prefix)
    remove_list = run_prune(args, images)
    if remove_list:
        delete_images(remove_list, args.dry_run)


if __name__ == "__main__":
    main()
