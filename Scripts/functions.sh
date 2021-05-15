function apply_patches()
{
    DEP_SRC_DIR=$1
    DEP_PATCH_DIR=$2
    
    CURRENT_DIR=$(pwd)

    pushd ${CURRENT_DIR}

    cd /tmp

    for FILE in ${CURRENT_DIR}/${DEP_PATCH_DIR}/*.patch; do
        echo Applying patch: $FILE
        git apply --directory ${CURRENT_DIR}/${DEP_SRC_DIR} --unsafe-path $FILE
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

    REVERSED_PATCHES=$(ls -1 ${CURRENT_DIR}/${DEP_PATCH_DIR}/*.patch | sort -r)

    for FILE in $REVERSED_PATCHES; do
        echo Reverse patch: $FILE
        git apply --reverse --directory ${CURRENT_DIR}/${DEP_SRC_DIR} --unsafe-path $FILE
    done

    popd
}
