#!/bin/bash

read -n 1 -p "エアギャップのパスワードをデフォルトから変更しますか？ [Yn]: " Yn


export_password() {
    while read -sp "Password: " password; do
        echo
        if [ ${#password} -lt 8 ]; then
            echo "パスワードの長さは8文字以上にしましょう!"
            continue
        fi
        read -sp "Password(確認): " repeat
        if [ "${password}" = ${repeat} ]; then
            export PASSWD=$password
            return
        else
            echo "パスワードが一致しません。"
            echo
        fi
    done
}


case $Yn in
    "" | [Yy]* )
        export_password
    ;;
    * )
        export PASSWD=airgap
    ;;
esac

export HOST_PWD=$(pwd)

echo
echo "Dockerのビルドを開始しています..."
docker compose build

