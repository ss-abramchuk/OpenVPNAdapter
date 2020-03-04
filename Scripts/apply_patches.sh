#!/bin/bash

set -e

. functions.sh

ASIO_SRC_DIR="../Sources/ASIO"
ASIO_PATCH_DIR="../Sources/OpenVPN3/deps/asio/patches"

MBEDTLS_SRC_DIR="../Sources/mbedTLS"
MBEDTLS_PATCH_DIR="../Sources/OpenVPN3/deps/mbedtls/patches"

if [ "$1" = "--reverse" ]; then
    reverse_patches ${ASIO_SRC_DIR} ${ASIO_PATCH_DIR}
    reverse_patches ${MBEDTLS_SRC_DIR} ${MBEDTLS_PATCH_DIR}
else
    apply_patches ${ASIO_SRC_DIR} ${ASIO_PATCH_DIR}
    apply_patches ${MBEDTLS_SRC_DIR} ${MBEDTLS_PATCH_DIR}
fi
