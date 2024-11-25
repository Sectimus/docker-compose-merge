#!/bin/bash
#
 # Author:  Amelia Magee (Sectimus @ github)
 # Found a bug? https://github.com/Sectimus/docker-compose-merge/issues
#
printf -v usage "$(basename "$0") [-a|--auto] [-p <arg>...] [output]
$(basename "$0") [-h|--help]

flags:
    -h, --help\t\tShow this help text
    -p, --project\tManually specify project paths, latter takes precedence
    -a  --auto,\t\tBuild git hooks for repositories on specified project paths to auto rebuild the compose file
args:
    output\t\tSpecifies an output file. (default: \"./docker-compose.yml\")
"

#----------------------------------Hardcoded Values------------------------------------#



tempdir="/tmp/docker-compose.merge"
defaultMasterCompose="./docker-compose.yml"
# default project paths to always be included (must be a directory, and must contain at least one docker-compose.yml file)
declare -a projects=(
    #"./project1"
    #"./project2/foo"
    #"../../project3/bar"
)



#--------------------------------------------------------------------------------------#

# Check if docker compose is available
if command -v docker compose &> /dev/null
then
    command="docker compose"
else
    command="docker-compose"
fi

expandedCommand="$(readlink -f ${0})"
# expand project paths for easier debugging
for i in "${!projects[@]}"; do
    projects[$i]=$(readlink -f ${projects[$i]})
done

auto=0

build_compose_file () {
    # ensure the main compose file is valid
    if [[ -z "${masterCompose}" ]]; then
        masterCompose=$(readlink -f "${defaultMasterCompose}")
    fi

    # allow docker-compose to expand the correct relative values before joining
    mkdir -p $tempdir

    printf "\033[1;34mExpanding Values\033[0m\n"
    alternateFileArgs=""
    for i in "${!projects[@]}"; do 
        
        # Check if the path is a file
        if [ -f "${projects[$i]}" ]; then
            dockerfileselector="${projects[$i]}";
            # Check if the path is a directory
        else
            dockerfileselector="${projects[$i]}/docker-compose.yml";
        fi

        $command -f "${dockerfileselector}" config > $tempdir/$i.yml

        # echo --------------------------------
        # echo !DEBUG!
        # echo $command
        # echo "${dockerfileselector}"
        # echo $tempdir/$i.yml
        # echo --------------------------------

        alternateFileArgs="${alternateFileArgs} -f $tempdir/$i.yml"
        printf "Expanded relative values for project: %s to %s\n" "${projects[$i]}", "$tempdir/$i.yml"
    done
    printf "\033[1;34mMerging\033[0m\n"
    $command --project-directory . \
        -p 'docker-compose-merge' \
        $alternateFileArgs \
        config > $masterCompose
    printf "Master docker compose file located at \033[1;32m%s\033[0m\n" "$masterCompose"
}

create_git_hooks() {
    # create the actual hooks themselves
    hooksLocation="./docker-compose-merge.hooks.d"
    expandedHooksLocation="$(readlink -f ${hooksLocation})"

    command="\"$expandedCommand\""
    for i in "${!projects[@]}"; do 
        command="$command -p \"${projects[$i]}\""
    done
    command="$command \"$masterCompose\""

    declare -a hooks=(
        'post-merge'
        'post-checkout'
    )

    printf "\033[1;34mBinding hooks to: \"\033[0m\033[0m%s\033[1;34m\"\033[1;34m...\033[0m\n" "${command//[$'\t\r\n']}"
    for i in "${!hooks[@]}"; do 
        echo -e "#!/bin/bash\n\n${command}" > "$expandedHooksLocation/${hooks[$i]}"
        printf "Created $expandedHooksLocation/${hooks[$i]}\n"
    done

    printf "\033[1;34mProviding execute permissions required for hooks...\033[0m\n"
    for i in "${!hooks[@]}"; do 
        sudo chmod +x "$expandedHooksLocation/${hooks[$i]}"
    done

    # link them
    printf "\033[1;34mLinking hooks to projects...\033[0m\n"
    for i in "${!projects[@]}"; do 
        (cd "${projects[$i]}" && git config --local core.hooksPath "$expandedHooksLocation"/)
        printf "\033[1;34mLinked hooks to repo: \033[0m%s\n" "${projects[$i]}"
    done
}
unexpandedCommandWithParams="$0 $@"
printf "\033[1m$unexpandedCommandWithParams\033[0m\n"

while [[ $# -gt 0 ]]; do
    options=$2
    case "$1" in
    -a | --auto)
        auto=1
        shift
        ;;
    -p | --project)
        for option in $options
        do
            case "$option" in
                *)
                    option="$(readlink -f $option)"
                    # only add the project if it doesn't already exist 
                    if [[ ! " ${projects[*]} " =~ " ${option} " ]]; then
                        projects+=("$option")
                    fi
                    ;;
            esac
        done
        shift
        shift
        ;;
    -d | --docker)
        masterCompose="/code/docker-compose.yml"
        shift
        ;;
    -h | --help | help)
        echo "$usage"
        exit
        ;;
    -* | --*)
        echo "Unknown option: $1" >&2
        echo "$usage" >&2
        exit 2
        ;;
    *)
        echo $1;
        masterCompose=$(readlink -f "$1")
        shift
        ;;
    esac
done
shift $((OPTIND - 1))

build_compose_file

if [[ "$auto" -eq 1 ]]; then
    create_git_hooks
fi

printf "\033[1;32mDone!\033[0m\n"