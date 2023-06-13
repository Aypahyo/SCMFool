#! /bin/bash

# This script is a collection of helpers for me to use when working with my scm setup.
# Since a fool with a tool is still a fool, I'm calling this script scmfool.sh

setup() {
    SCMFOOL_ROOT=${SCMFOOL_ROOT:-"/home/$USER/scm"}
    SCMFOOL_TEMP=${SCMFOOL_TEMP:-"$(realpath "$(dirname "$0")/tmp")"}
    mkdir -p "$SCMFOOL_TEMP"
    rm -f "${SCMFOOL_TEMP}/pull.log"
}

selftest() {
    echo "Running selftest"
    echo "Arguments: '$*'"
    
    # Initialize exit_status
    exit_status=0

    # Check if 'svn' command exists
    if command -v svn > /dev/null 2>&1; then
        echo "svn is available"
    else
        echo "svn is not available, please install it"
        exit_status=1
    fi
    
    # Check if 'git' command exists
    if command -v git > /dev/null 2>&1; then
        echo "git is available"
    else
        echo "git is not available, please install it"
        exit_status=1
    fi

    # check if the folder SCMFOOL_TEMP exists, log its name. it is created elsewhere in the setup function
    if [ -d "$SCMFOOL_TEMP" ]; then
        echo "SCMFOOL_TEMP exists: $SCMFOOL_TEMP"
    else
        echo "SCMFOOL_TEMP does not exist: $SCMFOOL_TEMP"
        exit_status=1
    fi

    # Return the exit_status
    return $exit_status
}

pull() {
    local dir_path=$1
    local exit_status=0 # Assume success by default

    # Use a for loop to iterate over all directories in the current directory
    for item in "${dir_path}"/*; do
        if [ -d "${item}" ]; then # if it's a directory...

            # Determine the type of the repository (git or svn)
            if [ -d "${item}/.git" ]; then
                # It's a git repository
                echo "Processing git repository: ${item}" >> "${SCMFOOL_TEMP}/pull.log"
                cd "${item}" || continue
                if ! git pull >> "${SCMFOOL_TEMP}/pull.log" 2>&1; then
                    echo "Failed to update repository: ${item}" >&2
                    echo "Failed to update repository: ${item}" >> "${SCMFOOL_TEMP}/pull.log"
                    exit_status=1
                fi
                cd .. 
            elif [ -d "${item}/.svn" ]; then
                # It's a svn repository
                echo "Processing svn repository: ${item}" >> "${SCMFOOL_TEMP}/pull.log"
                cd "${item}" || continue
                if ! svn update >> "${SCMFOOL_TEMP}/pull.log" 2>&1; then
                    echo "Failed to update repository: ${item}" >&2
                    echo "Failed to update repository: ${item}" >> "${SCMFOOL_TEMP}/pull.log"
                    exit_status=1
                fi
                cd ..
            else
                # Recurse into the directory
                echo "Recursing into directory: ${item}" >> "${SCMFOOL_TEMP}/pull.log"
                if ! pull "${item}"; then
                    exit_status=1
                fi
            fi
        fi
    done

    return $exit_status
}

main() {
    setup
    command=$1
    shift # remove the command from the arguments
    case "$command" in
    "selftest")
        # call the selftest function
        selftest "$@"
        exit_status=$? # capture the return value
        ;;
    "pull")
        # call the selftest function
        pull "$SCMFOOL_ROOT"
        exit_status=$? # capture the return value
        ;;
    *)
        echo "Unknown command: $command"
        exit_status=1
        ;;
    esac
    exit $exit_status
}

main "$@"