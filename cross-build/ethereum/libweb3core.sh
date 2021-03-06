#!/bin/bash
# configures, cross-compiles and installs Ethereum's libweb3core (https://github.com/ethereum/libweb3core)
# @author: Anthony Cros

# ===========================================================================
set -e
SCRIPT_DIR=$(dirname $0) && ([ -n "$SETUP" ] && ${SETUP?}) || source ${SCRIPT_DIR?}/setup.sh $*
COMPONENT=${LIBWEB3CORE?}
cd_clone ${LIBWEB3CORE_BASE_DIR?} ${LIBWEB3CORE_WORK_DIR?}
export_cross_compiler && sanity_check_cross_compiler


# ===========================================================================
# configuration:

section_configuring ${COMPONENT?}
set_cmake_paths "${JSONCPP?}:${BOOST?}:${LEVELDB?}:cryptopp:${GMP?}"

# ---------------------------------------------------------------------------
# remove warnings-as-errors as workaround for unmerged pull request
# See https://github.com/ethereum/libweb3core/pull/44

generic_hack \
  ${LIBWEB3CORE_WORK_DIR?}/libdevcore/CMakeLists.txt \
  'BEGIN{printf("STRING(REGEX REPLACE \"-Werror\" \"\" CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS})\n\n")}1'


# ---------------------------------------------------------------------------
# configuration hack to remove miniupnp (optional and broken at the moment)

generic_hack \
  ${LIBWEB3CORE_WORK_DIR?}/libp2p/CMakeLists.txt \
  '!/Miniupnpc/'


# ---------------------------------------------------------------------------
cmake \
   . \
  -G "Unix Makefiles" \
  -DCMAKE_VERBOSE_MAKEFILE=true \
  -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE?} \
  -DFATDB=OFF \
  -DMINIUPNPC=OFF \
  -DGUI=OFF \
  -DETHASHCL=OFF \
  -DEVMJIT=OFF \
  -DSOLIDITY=OFF  \
  -DTESTS=OFF \
  -DTOOLS=OFF \
  -DUtils_SCRYPT_LIBRARY=${LIBSCRYPT_LIBRARY?} \
  -DUtils_SECP256K1_LIBRARY=${SECP256K1_LIBRARY?}
return_code $?


# ===========================================================================
# cross-compile:

section_cross_compiling ${COMPONENT?}
make -j 8
return_code $?


# ===========================================================================
# install:

section_installing ${COMPONENT?}
backup_potential_install_dir ${LIBWEB3CORE_INSTALL_DIR?}
make DESTDIR="${LIBWEB3CORE_INSTALL_DIR?}" install
return_code $?

# homogenization
ln -s ${LIBWEB3CORE_INSTALL_DIR?}/usr/local/lib     ${LIBWEB3CORE_INSTALL_DIR?}/lib
ln -s ${LIBWEB3CORE_INSTALL_DIR?}/usr/local/include ${LIBWEB3CORE_INSTALL_DIR?}/include

# ===========================================================================

section "done" ${COMPONENT?}
tree ${LIBWEB3CORE_INSTALL_DIR?}


# ===========================================================================
