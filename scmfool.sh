#! /bin/bash

# This script is a collection of helpers for me to use when working with my scm setup.
# Since a fool with a tool is still a fool, I'm calling this script scmfool.sh

setup() {
    SCMFOOL_DEBUG=${SCMFOOL_DEBUG:-"false"}
    SCMFOOL_ROOT=${SCMFOOL_ROOT:-"/home/$USER/scm"}
    SCMFOOL_TEMP=${SCMFOOL_TEMP:-"$(realpath "$(dirname "$0")/tmp")"}
    mkdir -p "$SCMFOOL_TEMP"
    rm -f "${SCMFOOL_TEMP}/pull.log"

    #do not actually set SCM_FOOLF_LINTER_NOT_HAPPY to true.
    #this allows the inter to think the call could be legitimate
    #downstream it removes a bunch of warnings about unreachable code
    SCMFOOL_LINTER_NOT_HAPPY=${SCMFOOL_LINTER_NOT_HAPPY:-"false"}
    # if SCMFOOL_LINTER_NOT_HAPPY is true, then call the linter_rechability_ignorer function
    if [[ $SCMFOOL_LINTER_NOT_HAPPY == true ]]; then
        linter_rechability_ignorer "foo"
    fi
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

linter_rechability_ignorer() {
    # This function is used to ignore unreachable code warnings from the linter
    # It is used to ignore the linter warning about "Command appears to be unreachable" SC2317
    # The functions are reachable through an array, but the linter doesn't know that, so here they are added to allow the linter to ignore them
    if is_git "$1"; then
        git_pull "$1"
    fi
    if is_svn "$1"; then
        svn_update "$1"
    fi
}

is_git() {
    if [[ $SCMFOOL_DEBUG == true ]]; then echo "testing for git: $1"; fi
    [ -d "${1}/.git" ]
}

is_svn() {
    if [[ $SCMFOOL_DEBUG == true ]]; then echo "testing for svn: $1"; fi
    [ -d "${1}/.svn" ]
}

git_pull() {
    local item=$1
    echo "Processing git repository: ${item}" >> "${SCMFOOL_TEMP}/pull.log"
    pushd "${item}" || return 1
    if ! git pull >> "${SCMFOOL_TEMP}/pull.log" 2>&1; then
        echo "Failed to update repository: ${item}" >&2
        echo "Failed to update repository: ${item}" >> "${SCMFOOL_TEMP}/pull.log"
        return 1
    fi
    popd || return 1
}

svn_update() {
    local item=$1
    echo "Processing svn repository: ${item}" >> "${SCMFOOL_TEMP}/pull.log"
    pushd "${item}" || return 1
    if ! svn update >> "${SCMFOOL_TEMP}/pull.log" 2>&1; then
        echo "Failed to update repository: ${item}" >&2
        echo "Failed to update repository: ${item}" >> "${SCMFOOL_TEMP}/pull.log"
        return 1
    fi
    popd || return 1
}

execute_scm_action() {
    local dir_path=$1
    read -ra is_functions <<< "$2"
    read -ra action_functions <<< "$3"
    local exit_status=0

    if [[ $SCMFOOL_DEBUG == true ]]; then
        echo "is_functions: ${is_functions[*]}"
        echo "action_functions: ${action_functions[*]}"
    fi
    
    if [[ $SCMFOOL_DEBUG == true ]]; then
        for index in "${!is_functions[@]}"; do
            echo "Pair $index : ${is_functions[index]}, ${action_functions[index]}"
        done
    fi

    # Use a for loop to iterate over all directories in the current directory
    for item in "${dir_path}"/*; do
        if [ -d "${item}" ]; then 
            local found_scm=false

            # Iterate over SCM types
            for index in "${!is_functions[@]}"; do
                local is_scm=${is_functions[index]}
                local scm_action=${action_functions[index]}

                if [[ $SCMFOOL_DEBUG == true ]]; then echo "Trying: $is_scm on $item, paired action $scm_action"; fi

                # Check if the directory is of the SCM type
                if ${is_scm} "${item}"; then
                    if [[ $SCMFOOL_DEBUG == true ]]; then echo "$is_scm for $item was true, executing action $scm_action"; fi
                    if ! ${scm_action} "${item}"; then
                        exit_status=1
                    fi
                    # Mark that we've found an SCM type
                    found_scm=true
                    # Break the loop as we've found the SCM type
                    break
                fi
            done

            # If no SCM type was found, recurse into the directory
            if ! $found_scm; then
                if [[ $SCMFOOL_DEBUG == true ]]; then echo "Recursing into directory: $item"; fi
                echo "Recursing into directory: ${item}" >> "${SCMFOOL_TEMP}/pull.log"
                if ! execute_scm_action "${item}" "${is_functions[*]}" "${action_functions[*]}"; then
                    exit_status=1
                fi
            fi
        fi
    done

    return $exit_status
}

is_functions=(is_git is_svn)
action_functions=(git_pull svn_update)

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
        execute_scm_action "$SCMFOOL_ROOT" "${is_functions[*]}" "${action_functions[*]}"
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