set -l yvm_commands ls list use rm help

function __yvm_get_versions
    set -l yvm_config "$XDG_CONFIG_HOME/yvm-fish"

    if test -e $yvm_config/yarn_releases
        set -l versions (cat $yvm_config/yarn_releases | awk '{ print $1 }')
        set -p versions latest

        for v in $versions
            echo $v
        end
    end
end

function __yvm_get_versions_installed
    set -l versions (find $XDG_CONFIG_HOME/yvm-fish/ -maxdepth 1 -mindepth 1 -type d | xargs -I _ basename _)

    for v in $versions
        echo $v
    end
end

complete --no-files --command yvm --condition "not __fish_seen_subcommand_from $yvm_commands" -a ls -d 'list all available yarn version, indicating which are installed and which is active'
complete --no-files --command yvm --condition "not __fish_seen_subcommand_from $yvm_commands" -a list -d 'list all available yarn version, indicating which are installed and which is active'
complete --no-files --command yvm --condition "not __fish_seen_subcommand_from $yvm_commands" -a use -d 'install yarn <version> and activate by prepending to $fish_user_paths'
complete --no-files --command yvm --condition "not __fish_seen_subcommand_from $yvm_commands" -a rm -d 'remove yarn <version> and remove from $fish_user_paths'
complete --no-files --command yvm --condition "not __fish_seen_subcommand_from $yvm_commands" -a help -d 'print help'

complete --no-files --command yvm --condition "__fish_seen_subcommand_from use " -a "(__yvm_get_versions)"
complete --no-files --command yvm --condition "__fish_seen_subcommand_from rm" -a "(__yvm_get_versions_installed)"

complete --no-files --command yvm -s h -l help -d 'print help'
complete --no-files --command yvm -s f -l force-fetch -d 'Force fetch new release data from remote'
