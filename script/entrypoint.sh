#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail


__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename "${__file}" .sh)"
__root="$(cd "$(dirname "${__dir}")" && pwd)"

# more useful tips https://kvz.io/blog/2013/11/21/bash-best-practices/

COMMAND=${1:-}

if [ "$COMMAND" = "" ];
then
  echo ""
  echo "COMMAND not specified"
  exit 1
fi

RAILS_ROOT=${RAILS_ROOT:-/app}
RAILS_PORT=${RAILS_PORT:-3000}

echo "--------------------------------------"
echo "        RAILS_ENV ${RAILS_ENV}        "
echo "--------------------------------------"


# Should be a VOLUME exposed from the container.
# The purpose is to copy assets to some place where
# the host can access them so it can serve them without
# passing through rails.
PUBLIC_PATH=${PUBLIC_PATH:-/var/www/html}

# Important trailing slash after public so it copies just the contents
# We are excluding the system folder because that is where the uploads go
# and we have those volume mapped to a different path
rsync -ahr -delete --exclude "system" "${RAILS_ROOT}/public/" "${PUBLIC_PATH}"

case "${COMMAND}" in
  server)
    mkdir -p tmp/pids
    rm -f tmp/pids/server.pid
    exec bundle exec puma -C config/puma.rb -b tcp://0.0.0.0 -p "${RAILS_PORT}"
    ;;
  jobs)
    mkdir -p tmp/pids
    exec bundle exec bin/delayed_job run
    ;;
  console)
    exec bundle exec rails console
    ;;
  shell)
    exec /bin/bash -l
    ;;
  migrate)
    exec bundle exec rake db:migrate
    ;;
  *)
    echo "ARBITRARY COMMAND"
    exec "$@"
    ;;
esac
