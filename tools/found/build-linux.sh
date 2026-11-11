#!/usr/bin/env bash
# Build the cp312 manylinux wheel inside quay.io/pypa/manylinux_2_28_<arch>.
# Run from the repository root with PLATFORM (x86_64 or aarch64) and
# OR_TOOLS_PATCH set. The repaired wheel lands in ./wheelhouse.
set -euxo pipefail
: "${PLATFORM:?}" "${OR_TOOLS_PATCH:?}"

dnf -y install git patch which pkgconfig autoconf libtool make gcc-c++ \
  openssl-devel pcre2-devel zlib-devel unzip zip
git config --global --add safe.directory '*'

PYROOT=/opt/python/cp312-cp312
"${PYROOT}/bin/python" -m venv /tmp/venv
# shellcheck source=/dev/null
source /tmp/venv/bin/activate
# SWIG is pinned: v9.15's wrappers do not compile with SWIG 4.4 or newer.
pip install -U pip setuptools wheel virtualenv absl-py mypy mypy-protobuf \
  numpy pandas typing-extensions immutabledict auditwheel "swig==4.3.1"

cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_DEPS=ON -DBUILD_PYTHON=ON -DPython3_ROOT_DIR="${PYROOT}" \
  -DBUILD_TESTING=OFF -DBUILD_SAMPLES=OFF -DBUILD_EXAMPLES=OFF
cmake --build build --target python_package -j"$(nproc)"

mkdir -p wheelhouse
LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}:${PWD}/build/lib64:${PWD}/build/lib" \
  python -m auditwheel repair --plat "manylinux_2_28_${PLATFORM}" \
  build/python/dist/*.whl -w wheelhouse
deactivate

"${PYROOT}/bin/python" -m venv /tmp/smoke
/tmp/smoke/bin/pip install wheelhouse/*.whl
cd /tmp && /tmp/smoke/bin/python /project/tools/found/smoke.py
