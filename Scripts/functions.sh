function apply_patches()
{
    DEP_SRC_DIR=$1
    DEP_PATCH_DIR=$2
    
    CURRENT_DIR=$(pwd)

    pushd ${CURRENT_DIR}

    cd /tmp

    for file in ${CURRENT_DIR}/${DEP_PATCH_DIR}/*.patch; do
        echo Applying patch: $file
        git apply --directory ${CURRENT_DIR}/${DEP_SRC_DIR} --unsafe-path $file
    done

    popd
}

function reverse_patches()
{
    DEP_SRC_DIR=$1
    DEP_PATCH_DIR=$2
    
    CURRENT_DIR=$(pwd)

    pushd ${CURRENT_DIR}

    cd /tmp

    for file in ${CURRENT_DIR}/${DEP_PATCH_DIR}/*.patch; do
        echo Reverse patch: $file
        git apply --reverse --directory ${CURRENT_DIR}/${DEP_SRC_DIR} --unsafe-path $file
    done

    popd
}
