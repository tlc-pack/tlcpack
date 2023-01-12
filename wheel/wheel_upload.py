
"""Update the wheels page, prune old nightly builds if necessary."""
import github3
from github3.exceptions import ConnectionError
import os
import logging
import argparse
import subprocess


def upload(args, path):
    gh = github3.login(token=os.environ["GITHUB_TOKEN"])
    repo = gh.repository(*args.repo.split("/"))
    release = repo.release_from_tag(args.tag)
    name = os.path.basename(path)
    content_bytes = open(path, "rb").read()

    for asset in release.assets():
        if asset.name == name:
            if not args.dry_run:
                asset.delete()
                print(f"Remove duplicated file {name}")
    print(f"Start to upload {path} to {args.repo}, this can take a while...")

    for retry_counter in range(args.timeout_retry + 1):
        try:
            if not args.dry_run:
                release.upload_asset("application/octet-stream", name, content_bytes)
            break
        except ConnectionError:
            print(f"upload failed due to time out retry... retry_counter={retry_counter}")
            if retry_counter == args.timeout_retry:
                raise RuntimeError(f"Failed to upload after {retry_counter} retries")
    print(f"Finish uploading {path}")


def main():
    logging.basicConfig(level=logging.WARNING)
    parser = argparse.ArgumentParser(description="Upload wheel as an asset of a tag.")
    parser.add_argument("--tag", type=str)
    parser.add_argument("--repo", type=str, default="tlc-pack/tlcpack")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--timeout-retry", type=int, default=5)
    parser.add_argument("path", type=str)

    if "GITHUB_TOKEN" not in os.environ:
        raise RuntimeError("need GITHUB_TOKEN")
    args = parser.parse_args()
    if os.path.isdir(args.path):
        for name in os.listdir(args.path):
            if name.endswith(".whl"):
                upload(args, os.path.join(args.path, name))
    else:
        upload(args, args.path)

if __name__ == "__main__":
    main()
