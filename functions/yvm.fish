set -g yvm_fish 0.7.0

function yvm -a cmd -d "yarn version manager"
    set -l options (fish_opt -s h -l help) (fish_opt -s v -l version) (fish_opt -s f -l force-fetch)
    argparse $options -- $argv

    if test -n "$_flag_h"
        _yvm_help
        return 0
    end

    if test -n "$_flag_v"
        echo "$yvm_fish"
        return 0
    end

    set -q XDG_CONFIG_HOME
    or set XDG_CONFIG_HOME ~/.config
    set -g yvm_config $XDG_CONFIG_HOME/yvm-fish
    set -q yarn_releases_url
    or set -g yarn_releases_url "https://d236jo9e8rrdox.cloudfront.net/yarn-releases"

    if not test -d $yvm_config
        command mkdir -p $yvm_config
    end

    switch "$cmd"
        case ls list
            set -e argv[1]
            _yvm_ls $argv "$_flag_f"
        case use
            set -e argv[1]
            _yvm_use $argv "$_flag_f"
        case rm
            set -e argv[1]
            _yvm_rm $argv "$_flag_f"
        case "help"
            _yvm_help
        case \*
            echo "yvm: unknown flag or command \"$cmd\""
            _yvm_help
            return 1
    end
end

function _yvm_get_releases
    set -l options (fish_opt -s f -l force-fetch)
    argparse $options -- $argv

    set -q yvm_last_updated
    or set -g yvm_last_updated 0
    set -l releases "$yvm_config/yarn_releases"

    if test -n "$_flag_f"
        or test ! -e $releases -o (math (command date +%s) - $yvm_last_updated) -gt 120
        # DOCUMENT
        echo "Fetching releases from $yarn_releases_url" >&2

        command curl -s $yarn_releases_url \
            | tr ',' '\n'\
 | awk -F'":"' '
                {
                  version;
                  gsub(/"/, "", $2)
                  if ($1 ~ /name/ ) { version = $2 }
                  if ($1 ~ /tarball/) { gsub(/v/, "", version); print version, $2 }
                }
            ' >$releases 2>/dev/null

        if test ! -s "$releases"
            echo "yvm: couldn't fetch releases -- is \"$yarn_releases_url\" a valid host?" >&2
            return 1
        end

        set -g yvm_last_updated (command date +%s)
    end

    echo $releases
end

function _yvm_use
    set -l options (fish_opt -s f -l force-fetch)
    argparse $options -- $argv

    set -l releases (_yvm_get_releases "$_flag_f")

    set -l version_to_install (string trim "$argv")

    if test $version_to_install = "latest"
        set version_to_install (cat $releases | head -n 1 | awk '{ print $1 }')
    end

    if not test (grep "^$version_to_install" $releases)
        echo "Version $version_to_install not found. Consider running \"yvm ls\" and check that the version is correct."
        return 1
    end

    if not test -d "$yvm_config/$version_to_install"
        set -l url (cat $releases | grep $version_to_install | awk '{ print $2 }')

        echo "fetching $url..." >&2

        set -l temp_dir (command mktemp -d -t "yvm-yarn-$version_to_install-XXXXXXXXXXXXX")
        set -l temp_file (command mktemp "yvm-yarn-$version_to_install-tarball-XXXXXXXXXX")

        if not command curl -L --fail --progress-bar $url -o $temp_file 2>/dev/null
            command rm -rf $temp_dir
            command rm $temp_file

            echo "Couldn't download the tarball from url:"
            echo "$url"
            echo "Are you offline?"
            return 1
        end

        command mkdir -p "$yvm_config/$version_to_install/"

        command tar -xzf $temp_file -C $temp_dir

        set -l yarn_pkg_path (find $temp_dir -maxdepth 1 -mindepth 1 -type d)
        command mv $yarn_pkg_path/* "$yvm_config/$version_to_install/"

        command rm -r $temp_dir
        command rm $temp_file
    end

    if not test -d "$yvm_config/$version_to_install/"
        echo "Failed to install yarn version \"$version_to_install\", but curl didn't error. Please report this bug."
        return 1
    end

    if not test -e "$yvm_config/$version_to_install/bin/yarn.js"
        echo "Yarn was installed but there is no yarn.js in \"$yvm_config/$version_to_install/bin/yarn.js\"."
        echo "This yarn version is either really old, and exports for example a kpm.js, or it's a version that needs be built from source."
        echo ""
        echo "Note that the yarn version is not removed from \"$yvm_config/\", but it's also not prepended to \$fish_user_paths. It's advised to use \"yvm rm\" to remove the version again."
        return 1
    end

    if test -s "$yvm_config/version"
        read -l last <"$yvm_config/version"

        if set -l i (contains -i -- "$yvm_config/$last/bin" $fish_user_paths)
            set -e fish_user_paths[$i]
        end
    end

    echo $version_to_install >$yvm_config/version

    if not contains -- "$yvm_config/$version_to_install/bin" $fish_user_paths
        set -U fish_user_paths "$yvm_config/$version_to_install/bin" $fish_user_paths
    end
end

function _yvm_rm
    set -l options (fish_opt -s f -l force-fetch)
    argparse $options -- $argv

    set -l releases (_yvm_get_releases "$_flag_f")

    set -l yarn_version $argv[1]
    read -l active_version <"$yvm_config/version"

    if test $yarn_version = "latest"
        set yarn_version (cat $releases | head -n 1 | awk '{ print $1 }')
    end

    if test -n "$active_version"
        echo "" >"$yvm_config/version"
    end

    if set -l i (contains -i -- "$yvm_config/$yarn_version/bin" $fish_user_paths)
        set -e fish_user_paths[$i]
    end

    if not test -d "$yvm_config/$yarn_version/"
        echo "No version \"$yarn_version\" found on file system in \"$yvm_config/$yarn_version/\""
    else
        rm -r "$yvm_config/$yarn_version/"
    end

    return 0
end

function _yvm_ls
    set -l options (fish_opt -s f -l force-fetch)
    argparse $options -- $argv

    set -l releases (_yvm_get_releases "$_flag_f")
    set -l yarn_version

    if test -f "$yvm_config/version"
        read yarn_version <"$yvm_config/version"
    end

    # https://github.com/jorgebucaran/fish-cookbook#how-do-i-read-from-a-file-in-fish
    while read -la release
        set -l parts (string split " " $release)
        set -l release_version $parts[1]
        set -l is_installed 0

        if test -d "$yvm_config/$release_version"
            set is_installed 1
        end

        echo -n $release_version

        if test "$is_installed" -eq 1
            echo -n \t "installed"
        end

        if test -n $yarn_version
            and test "$yarn_version" = "$release_version"
            echo -n \t "active"
        end

        echo \t
    end <$releases
end

function _yvm_help
    echo "usage: yvm help/--help/-h   Show this help"
    echo "       yvm --version        Show the current version of yvm"
    echo "       yvm use <version>    Download <version> and modify PATH to use it."
    echo "                            Needs to be the exact version from ls."
    echo "       yvm ls/list          List all versions including if they're installed and/or active"
    echo "       yvm rm               Remove specified version from file system and PATH."
    echo "                            Needs to be the exact version from ls."
    echo "       -f/--force-fetch     Force fetch the releases from remote before \"use\" or \"ls\""
    echo "                            Release data is cached for 120 seconds"
    echo ""
    echo "examples:"
    echo "       yvm use 1.17.3"
    echo "       yvm use latest"
    echo "       yvm ls"
    echo "       yvm ls -f"
    echo ""
    echo "Important:"
    echo "       Does not support old versions exporting kpm.js, nor versions that need to be"
    echo "       built from source."
end
