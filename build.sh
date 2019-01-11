#!/bin/bash

set -e

export ZBAR_NAME="zbar-0.10"
export OPTIMIZE="-Os"
export WASM_DIR="node_modules/opencv/build"
export ZBAR_DIR="node_modules/zbar"
export LDFLAGS="${OPTIMIZE}"
export CFLAGS="${OPTIMIZE}"
export CPPFLAGS="${OPTIMIZE}"

echo "============================================="
echo "Compiling wasm opencv"
echo "============================================="
(
  if [ ! -d $WASM_DIR ]; then
    python make.py
  fi
)

echo "============================================="
echo "Compiling zbar"
echo "============================================="
(
  if [ ! -d $ZBAR_DIR ]; then
    mkdir -p $ZBAR_DIR
    tar zxvf zbar-0.10.tar.gz -C $ZBAR_DIR
    cd ${ZBAR_DIR}/${ZBAR_NAME}
    emconfigure ./configure --without-x --without-jpeg \
		--without-imagemagick --without-npapi --without-gtk \
		--without-python --without-qt --without-xshm --disable-video \
		--disable-pthread

    emmake make
  fi
)

echo "============================================="
echo "Compiling wasm bindings"
echo "============================================="
(
  emcc \
    --bind \
    ${OPTIMIZE} \
    -s AGGRESSIVE_VARIABLE_ELIMINATION=0 -s NO_DYNAMIC_EXECUTION=0 -s NO_FILESYSTEM=0\
    -s ERROR_ON_UNDEFINED_SYMBOLS=0 \
    -s TOTAL_MEMORY=134217728 \
    -s ALLOW_MEMORY_GROWTH=1 \
    -s ASSERTIONS=0 -s SAFE_HEAP=0 \
    -s MODULARIZE=1 \
    -s 'EXPORT_NAME="detect"' \
    --std=c++11 \
    -I node_modules/opencv/include \
    -I node_modules/opencv/modules/core/include \
    -I node_modules/opencv/modules/imgproc/include \
    -I node_modules/opencv/build \
    -I node_modules/zbar/${ZBAR_NAME}/include \
    -o ./detect.js \
    -x c++ \
    detect.cpp \
    node_modules/opencv/build/lib/libopencv_core.a \
    node_modules/opencv/build/lib/libopencv_imgproc.a \
    node_modules/opencv/build/3rdparty/lib/libzlib.a \
    node_modules/zbar/${ZBAR_NAME}/zbar/*.o node_modules/zbar/${ZBAR_NAME}/zbar/*/*.o
)
echo "============================================="
echo "Compiling wasm bindings done"
echo "============================================="

echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "Did you update your docker image?"
echo "Run \`docker pull trzeci/emscripten\`"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
