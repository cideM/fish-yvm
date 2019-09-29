# TODO: List which versions are installed
# TODO: Store currently installed version
# TODO: install
set -g yvm_fish 0.0.1

function yvm -a cmd -d "yarn version manager"
    set -q XDG_CONFIG_HOME; or set XDG_CONFIG_HOME ~/.config
    set -g yvm_config $XDG_CONFIG_HOME/yvm-fish
    set -q yarn_releases_url; or set -g yarn_releases_url "https://d236jo9e8rrdox.cloudfront.net/yarn-releases"

    if not test -d $yvm_config
        command mkdir -p $yvm_config
    end

    switch "$cmd"
      case ls list
        set -e argv[1]
        _yvm_ls
      case ""
        echo HELLo
      case \*
          echo "yvm: unknown flag or command \"$cmd\"" >&2
          _yvm_help >&2
          return 1
    end
end

function _yvm_ls
  # Fetch a JSON blob with all releases
  # | split it by ',' so we have one line per ,
  # | split each line by ':', so we have key value pairs (plus lots of noise).
  #   Get the value if the key matches /name/. Gives us the version in "name":"0.1.0"
  # | Remove the quotes
  # Should print a list of all releases like so
  # 1.12.0
  # pre-release
  # 1.10.0
  # 0.1.0

  set -l tags (                        \
    curl -s $yarn_releases_url         \
    | tr ',' '\n'                      \
    | awk -F: '$1 ~ /name/ {print $2}' \
    | tr '"' ' '                       \
    | string trim -l -r                \
    )

  set -l index (cat $yvm_config/index)

  echo $index

  for t in $tags
    set -l out $t

    if test -n $index; and test "$index" = "$t"
      set -a out "currently used"
    end

    echo (string join \t $out)
  end
end

function _yvm_help
    echo "usage: yvm --help           Show this help"
    echo "       yvm --version        Show the current version of yvm"
    echo "       yvm use <version>    Download <version> and modify PATH to use it"
    echo "examples:"
    echo "       yvm use 12"
    echo "       yvm use latest"
    echo "       yvm ls"
end
