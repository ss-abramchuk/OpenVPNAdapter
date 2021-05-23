#!/bin/bash

set -e

OPENVPN3_VERSION="release/3.6.1"

git subtree pull --prefix Sources/OpenVPN3 git@github.com:OpenVPN/openvpn3.git ${OPENVPN3_VERSION} --squash

source Sources/OpenVPN3/deps/lib-versions

git subtree pull --prefix Sources/ASIO git@github.com:chriskohlhoff/asio.git ${ASIO_VERSION} --squash
git subtree pull --prefix Sources/LZ4 git@github.com:lz4/lz4.git ${LZ4_VERSION/lz4-/v} --squash
git subtree pull --prefix Sources/mbedTLS git@github.com:ARMmbed/mbedtls.git ${MBEDTLS_VERSION} --squash
