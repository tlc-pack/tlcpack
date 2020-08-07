import os
import tempfile
import argparse

patch = """
diff --git a/python/setup.py b/python/setup.py
index 682589ef5..9fd5b0363 100644
--- a/python/setup.py
+++ b/python/setup.py
@@ -150,9 +150,9 @@ def get_package_data_files():
     return ['relay/std/prelude.rly', 'relay/std/core.rly']


-setup(name='tvm',
+setup(name='tlcpack{CUDA}',
       version=__version__,
-      description="TVM: An End to End Tensor IR/DSL Stack for Deep Learning Systems",
+      description="TLCPack: Tensor learning compiler binary distribution",
       zip_safe=False,
       install_requires=[
         'numpy',
"""

parser = argparse.ArgumentParser()
parser.add_argument("--cuda", choices=["none", "10.0", "10.1", "10.2"],
                    help="CUDA version", default="none")
args = parser.parse_args()

fd, tmp_file = tempfile.mkstemp()
with open(tmp_file, 'w') as fout:
    if args.cuda == "none":
        fout.write(patch.format(CUDA=""))
    else:
        cuda = "-cu" + args.cuda.replace(".", "")
        fout.write(patch.format(CUDA=cuda))

# apply the patch
cmd = "git apply {}".format(tmp_file)
os.system(cmd)

os.remove(tmp_file)
