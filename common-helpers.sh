#See: https://github.com/martinburger/bash-common-helpers/blob/master/bash-common-helpers.sh
#See: https://natelandau.com/bash-scripting-utilities/

#
# SCRIPT INITIALIZATION --------------------------------------------------------
#

# cmn_init
#
# Should be called at the beginning of every shell script.
#
# Exits your script if you try to use an uninitialised variable and exits your
# script as soon as any statement fails to prevent errors snowballing into
# serious issues.
#
# Example:
# cmn_init
#
# See: http://www.davidpashley.com/articles/writing-robust-shell-scripts/
#
function cmn_init {
  # Will exit script if we would use an uninitialised variable:
  set -o nounset
  # Will exit script when a simple command (not a control structure) fails:
  set -o errexit
}

#
# PRINTING TO THE SCREEN -------------------------------------------------------
#

# cmn_echo_info message ...
#
# Writes the given messages in green letters to standard output.
#
# Example:
# cmn_echo_info "Task completed."
#
function cmn_echo_info {
  local green=$(tput setaf 2)
  local reset=$(tput sgr0)
  echo -e "${green}$@${reset}"
}

# cmn_echo_important message ...
#
# Writes the given messages in yellow letters to standard output.
#
# Example:
# cmn_echo_important "Please complete the following task manually."
#
function cmn_echo_important {
  local yellow=$(tput setaf 3)
  local reset=$(tput sgr0)
  echo -e "${yellow}$@${reset}"
}

# cmn_echo_warn message ...
#
# Writes the given messages in red letters to standard output.
#
# Example:
# cmn_echo_warn "There was a failure."
#
function cmn_echo_warn {
  local red=$(tput setaf 1)
  local reset=$(tput sgr0)
  echo -e "${red}$@${reset}"
}

#
# ERROR HANDLING ---------------------------------------------------------------
#

# cmn_die message ...
#
# Writes the given messages in red letters to standard error and exits with
# error code 1.
#
# Example:
# cmn_die "An error occurred."
#
function cmn_die {
  local red=$(tput setaf 1)
  local reset=$(tput sgr0)
  echo >&2 -e "${red}$@${reset}"
  exit 1
}

#
# AVAILABILITY OF COMMANDS AND FILES -------------------------------------------
#

# cmn_assert_command_is_available command
#
# Makes sure that the given command is available.
#
# Example:
# cmn_assert_command_is_available "ping"
#
# See: http://stackoverflow.com/a/677212/66981
#
function cmn_assert_command_is_available {
  local cmd=${1}
  type ${cmd} >/dev/null 2>&1 || cmn_die "Cancelling because required command '${cmd}' is not available."
}

# cmn_assert_file_exists file
#
# Makes sure that the given regular file exists. Thus, is not a directory or
# device file.
#
# Example:
# cmn_assert_file_exists "myfile.txt"
#
function cmn_assert_file_exists {
  local file=${1}
  if [[ ! -f "${file}" ]]; then
    cmn_die "Cancelling because required file '${file}' does not exist."
  fi
}

# cmn_assert_file_does_not_exist file
#
# Makes sure that the given file does not exist.
#
# Example:
# cmn_assert_file_does_not_exist "file-to-be-written-in-a-moment"
#
function cmn_assert_file_does_not_exist {
  local file=${1}
  if [[ -e "${file}" ]]; then
    cmn_die "Cancelling because file '${file}' exists."
  fi
}

#
# COMMON BUILDAH FUNCTIONS --------------------------------------------------------
#

# cmn_buildah_install_packages_scratch
#
# Installs packages into the scratch container from the host using buildah mounts.
# See: https://github.com/containers/buildah/issues/532
# See: https://www.informaticsmatters.com/blog/2018/05/31/smaller-containers-part-3.html
#
# Example:
# cmn_buildah_install_packages_scratch working_container "unzip tar git" 29
#
function cmn_buildah_install_packages_scratch {
  local container=${1}
  local packages=${2}
  local release_ver=${3}
  local mount=$(buildah mount $container)

  cmn_echo_info "---> Installing packages ${packages}"
  yum install ${packages} -y --installroot $mount --releasever $release_ver \
      --setopt install_weak_deps=false --setopt tsflags=nodocs \
      --setopt override_install_langs=en_US.utf8 \
    && yum clean all -y --installroot $mount --releasever $release_ver
  rm -rf "${mount}/var/cache/yum"
  rm -rf "${mount}/var/cache/dnf"
  buildah unmount $container
}
