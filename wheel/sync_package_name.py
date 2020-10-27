# Synchronize version with the tvm version
import os
import re
import argparse


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


def main():
    parser = argparse.ArgumentParser(description="Synchronize the package name.")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--src", type=str, default="tvm")
    parser.add_argument("name", type=str)
    args = parser.parse_args()

    rewrites = [
        (r'(?<=name=")[^\"]+', args.name),
        (r'(?<=description=")[^\"]+',
         "Tensor learning compiler binary distribution"),
        (r'(?<=url=")[^\"]+', "https://tlcpack.ai")
    ]
    update(os.path.join(args.src, "python", "setup.py"), rewrites, args.dry_run)

if __name__ == "__main__":
    main()
