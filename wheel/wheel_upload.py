"""Update the wheels page, prune old nightly builds if necessary."""
import github3
import os
import logging
import argparse
import subprocess


def upload(args):
    gh = github3.login(token=os.environ["GITHUB_TOKEN"])
    repo = gh.repository(*args.repo.split("/"))
    release = repo.release_from_tag(args.tag)
    name = os.path.basename(args.path)
    content_bytes = open(args.path, "rb").read()

    for asset in release.assets():
        if asset.name == name:
            if not args.dry_run:
                asset.delete()
                print(f"Remove duplicated file {name}")
    print(f"Start to upload {args.path} to {args.repo}, this can take a while...")
    if not args.dry_run:
        release.upload_asset("application/octet-stream", name, content_bytes)
    print(f"Finish uploading {args.path}")


def main():
    logging.basicConfig(level=logging.INFO)
    parser = argparse.ArgumentParser(description="Upload wheel as an asset of a tag.")
    parser.add_argument("--tag", type=str)
    parser.add_argument("--repo", type=str, default="tlc-pack/tlcpack")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("path", type=str)

    if "GITHUB_TOKEN" not in os.environ:
        raise RuntimeError("need GITHUB_TOKEN")
    args = parser.parse_args()
    upload(args)


if __name__ == "__main__":
    main()
