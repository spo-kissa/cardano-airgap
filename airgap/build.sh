#!/bin/bash

read -n 1 -p "エアギャップのパスワードをデフォルトから変更しますか？ [Yn]" Yn

case $Yn in
    "" | [Yy]* )
        read -sp "Password: " password
        export PASSWD=$password
    ;;
    * )
        export PASSWD=airgap
    ;;
esac

export HOST_PWD=$(pwd)

docker compose build
