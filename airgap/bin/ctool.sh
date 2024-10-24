#!/bin/bash

CTOOL_VERSION=0.5.91

SHARE_DIR="/mnt/share"

# General exit handler
cleanup() {
    [[ -n $1 ]] && err=$1 || err=$?
    [[ $err -eq 0 ]] && clear
    tput cnorm # restore cursor
    [[ -n ${exit_msg} ]] && echo -e "${exit_msg}" || echo -e "SPO JAPAN GUILD TOOL for Airgap Closed!"
    tput sgr0  # turn off all attributes
    exit "$err"
}

trap cleanup HUP INT TERM
trap 'stty echo' EXIT

myExit() {
    exit_msg="$2"
    cleanup "$1"
}


ctool_upgrade() {

    cp ${SHARE_DIR}/ctool.sh "${HOME}/bin/"
    chmod 755 "${HOME}/bin/ctool.sh"
    rm ${SHARE_DIR}/ctool.sh

    echo "'ctool.sh'をバージョンアップしました!!"
    pressKeyEnter "Enterキーを押してリロードしてください"

    "${HOME}/bin/ctool.sh"
    exit
    
}

ctool_update() {
    clear
    echo "'share'ディレクトリに新しいバージョンの'ctool.sh'をコピーしてください。"
    pressKeyEnter "コピーができたらEnterキーを押下してください"
    if [ -f "${SHARE_DIR}/ctool.sh" ]; then

        check_self_update

    else

        echo_red "'ctool.sh'ファイルが'share'ディレクトリに見つかりませんでした。"
        echo
        pressKeyEnter
        main

    fi

}

#
# shareディレクトリにctool.shがないかチェックする
#
check_self_update() {

    if [ -f ${SHARE_DIR}/ctool.sh ]; then
        VERSION=$(cat ${SHARE_DIR}/ctool.sh | grep CTOOL_VERSION= | head -n 1)
        VERSION_NUMBER=$(get_version_number "${VERSION:14}")

        MY_VERSION_NUMBER=$(get_version_number "$CTOOL_VERSION")

        if (( VERSION_NUMBER > MY_VERSION_NUMBER )); then

            HASH=$(sha256sum ${SHARE_DIR}/ctool.sh)

            clear
            echo
            echo_green "新しい'ctool.ch'を'share'ディレクトリ内に検出しました!!"
            echo
            echo
            echo -n "現バージョン："
            echo_yellow "v${CTOOL_VERSION}"
            echo
            echo -n "新バージョン："
            echo_yellow "v${VERSION:14}"
            echo
            echo -n "ハッシュ値："
            echo_yellow "${HASH:0:64}"
            echo
            echo
            echo
            echo_green "v${CTOOL_VERSION} -> v${VERSION:14}"
            echo
            echo
            if readYn "バージョンアップしますか？"; then
                ctool_upgrade
            fi
        else

            clear
            echo
            echo_red "'share'ディレクトリに古いバージョンの'ctool.sh'が見つかりました。"
            echo
            echo
            echo -n "現バージョン："
            echo_yellow "v${CTOOL_VERSION} (${VERSION_NUMBER})"
            echo
            echo -n "旧バージョン："
            echo_yellow "v${VERSION:14} (${MY_VERSION_NUMBER})"
            echo
            echo
            echo
            if readYn "削除しますか？"; then
                rm ${SHARE_DIR}/ctool.sh
            fi

        fi
    fi
}


COLDKEYS_DIR="${HOME}/cold-keys"
COLDKEYS_TARBALL="keys.tar.gz"
COLDKEYS_ENCFILE="${SHARE_DIR}/${COLDKEYS_TARBALL}.enc"


check_cli_update() {

    clear

}


#
# コールドキーがインストールされているかチェックします
#
check_coldkeys_exists() {
    echo "コールドキーをチェックしています..."
    keys_is_installed
    # shellcheck disable=SC2181
    if [ $? -ne 0 ]; then
        echo "暗号化済みコールドキーをチェックしています..."
        encrypted_keys_exists
        if [ $? -ne 0 ]; then
            echo "コールドキーがインポートされていません。"
            if readYn "今すぐインポートをおこないますか？"; then
                install_coldkeys
                return $?
            fi
        else
            return 0
        fi
    else
        return 0
    fi
    return 1
}

#
# バージョン番号を数値に変換する
#
get_version_number() {
    VERSION=$1
    if (( ${#VERSION} < 5 )); then
        echo "0" | bc
    fi
    echo "$VERSION" | awk -F. '{printf "%2d%02d%02d", $1,$2,$3}' | xargs echo | bc
}

echo_red() {
    tput setaf 1 && echo -n "$1" && tput setaf 7
}

echo_green() {
    tput setaf 2 && echo -n "$1" && tput setaf 7
}

echo_yellow() {
    tput setaf 3 && echo -n "$1" && tput setaf 7
}

echo_blue() {
    tput setaf 4 && echo -n "$1" && tput setaf 7
}

echo_magenta() {
    tput setaf 5 && echo -n "$1" && tput setaf 7
}


main() {
    check_self_update
    check_coldkeys_exists
    main_menu
}

quit() {
    clear
    echo
    myExit "" ""
}

readYn() {
    if existsGum; then
        if gum confirm "${1}" --affirmative="は  い" --negative="いいえ"; then
            return 0
        fi
        return 1
    else
        # shellcheck disable=SC2162
        read -n 1 -p "${1} [Y/n]" ANS

        case $ANS in
            "" | [Yy]* )
                return 0
                ;;
            * )
                return 1
                ;;
        esac
    fi
}

pressKeyEnter() {
    if (($# == 1)); then
        # shellcheck disable=SC2162
        read -r -p "$1"
    else
        # shellcheck disable=SC2162
        read -r -p "続行するにはエンターキーを押してください: "
    fi
}

existsGum() {
    if type "gum" > /dev/null 2>&1; then
        return 0
    fi
    return 1
}


get_keys() {
    keys=(
        '/cold-keys/node.counter'
        '/cold-keys/node.skey'
        '/cold-keys/node.vkey'
        '/cnode/payment.addr'
        '/cnode/payment.skey'
        '/cnode/payment.vkey'
        '/cnode/stake.addr'
        '/cnode/stake.skey'
        '/cnode/stake.vkey'
    )
    echo "${keys[@]}"
}


#
# lib: キーファイルが全てインストールされているかどうかを返します
#
keys_is_installed() {

    unlock_keys

    IFS=' '
    keys_array=$(get_keys)
    # shellcheck disable=SC2206
    keys=($keys_array)

    for i in "${!keys[@]}"; do
        if [ ! -s "${HOME}${keys[$i]}" ]; then
            return 1
        fi
    done

    lock_keys

    return 0
}

#
# lib: 暗号化済みコールドキーがインストールされているかどうかを返します
#
encrypted_keys_exists() {

    if [ -s "${COLDKEYS_ENCFILE}" ]; then
        return 0
    fi

    return 1
}


#
# コールドキーをインストールします
#
install_coldkeys() {

    clear
    echo

    if check_coldkeys_exists; then
        echo_red "既にコールドキーはインストールされています"
        echo
        echo
        pressKeyEnter
        return 1
    fi

    if encrypted_keys_exists; then
        echo_red "既に暗号化済みコールドキーがインストールされています"
        echo
        echo
        pressKeyEnter
        return 1
    fi

    IFS=' '
    keys_array=$(get_keys)
    # shellcheck disable=SC2206
    keys=($keys_array)

    echo "'${HOST_PWD}/share'ディレクトリに以下のファイルをコピーしてください。"
    echo 
    for i in "${!keys[@]}"; do
        echo "${keys[$i]}"
    done

    while true; do
        echo
        pressKeyEnter "'share'ディレクトリにコピーが出来たらEnterキーを押下してください"
        clear

        ng=0
        err=""
        for i in "${!keys[@]}"; do
            path="$SHARE_DIR${keys[$i]}"
            if [ -f "$path" ]; then
                if [ -s "$path" ]; then
                    echo_green '[✓]'
                else
                    echo_red '[×]'
                    ((ng=ng+1))
                    err='ファイルが空です'
                fi
            else
                echo_red '[×]'
                ((ng=ng+1))
                err='ファイルが見つかりません'
            fi
            echo " ${keys[$i]} ... ${err}"
            echo
        done
        
        if [ $ng -eq 0 ]; then
            break
        fi
    done

    echo
    echo_green 'インポートの準備が整いました！'
    echo
    echo
    if readYn "インポートを開始しますか？"; then

        echo

        unlock_keys

        for i in "${!keys[@]}"; do
            src="{$SHARE_DIR}${keys[$i]}"
            dst="/home/cardano${keys[$i]}"

            echo "${src} => ${dst}"
            
            if ! cp "${src}" "${dst}"; then
                delete_coldkeys
                echo
                echo_red "ファイルのコピーに失敗しました"
                echo
                echo
                pressKeyEnter "再度お試しください"
                return 1
            fi

        done

        lock_keys

        echo
        echo "'share'フォルダのデータを削除しています..."
        rm -rf "{$SHARE_DIR}/cold-keys"
        rm -rf "{$SHARE_DIR}/cnode"

        echo
        echo_green "コールドキーのインポートが正常に完了しました！"
        echo
        echo
        if readYn "コールドキーの暗号化をおこないますか？"; then

            if ! encrypt_keys; then
                return $?
            fi

        fi
    fi

    main_menu
}


#
# KESの更新
#
reflesh_kes() {

    while true; do

        clear
        echo
        echo "■ ブロックプロデューサーノードで gtool を起動し、KESの更新を始めて下さい。"
        echo
        echo "1.BPのkes.vkeyとkes.skey をエアギャップのcnodeディレクトリにコピーしてください"
        echo 
        echo "上記の表示が出たら、以下の2つのファイルをshareディレクトリにコピーしてください"
        echo "  kes.vkey"
        echo "  kes.skey"
        echo

        pressKeyEnter "コピーが出来たらEnterキーを押してください"

        if [ -s ${SHARE_DIR}/kes.vkey ] && [ -f ${SHARE_DIR}/kes.vkey ]; then

            if [ -s ${SHARE_DIR}/kes.skey ] && [ -f ${SHARE_DIR}/kes.skey ]; then

                break

            else

                echo "kes.skeyファイルが空かファイルが見つかりません。"

            fi

        else

            echo "kes.vkeyファイルが空かファイルが見つかりません。"

        fi

        echo
        if readYn "もう一度チェックしますか？"; then
            continue;
        else
            return 1;
        fi

    done

    cp ${SHARE_DIR}/kes.vkey "${NODE_HOME}/"
    cp ${SHARE_DIR}/kes.skey "${NODE_HOME}/"

    cd "${NODE_HOME}/" && (echo_red "${HOME}ディレクトリへの移動に失敗しました" || main_menu)

    VKEY=$(sha256sum kes.vkey | cut -d ' ' -f 1)
    SKEY=$(sha256sum kes.skey | cut -d ' ' -f 1)

    echo "kes.vkey >> ${VKEY}"
    echo "kes.skey >> ${SKEY}"
    echo

    if readYn "ハッシュ値は一致していますか?"; then
        echo_red "キャンセルしました"
        return 1
    fi

    if use_coldkeys; then
        rm "${NODE_HOME}/kes.vkey"
        rm "${NODE_HOME}/kes.skey"
        return 1
    fi

    while true; do
        clear
        echo
        echo "■ カウンター番号情報"
        echo
        echo "今回更新のカウンター番号: XX"
        echo
        echo "ブロックプロデューサーノードのカウンター番号情報に表示されている、"
        echo "今回更新のカウンター番号を入力してください。"
        
        read -p "半角数字で入力してEnterキーを押してください > " counter
        echo

        echo "カウンター番号: '${counter}'"
        echo
        if readYn "上記であっていますか？"; then
        
            unlock_keys

            # shellcheck disable=SC2086
            if ! cardano-cli conway node new-counter \
                --cold-verification-key-file ${COLDKEYS_DIR}/node.vkey \
                --counter-value ${counter} \
                --operational-certificate-issue-counter-file ${COLDKEYS_DIR}/node.counter;
            then
                unuse_coldkeys
                lock_keys

                echo_red "ノードカウンターの更新に失敗しました"
                echo
                echo
                pressKeyEnter "エンターキーを押して再度お試しください"
                return 1
            fi

            lock_keys

            break

        fi

    done

    unlock_keys

    # shellcheck disable=SC2086
    cardano-cli conway text-view decode-cbor \
        --in-file  ${COLDKEYS_DIR}/node.counter \
        | grep int | head -1 | cut -d"(" -f2 | cut -d")" -f1
    
    lock_keys

    
    while true; do

        clear
        echo
        echo "■ 現在のstartKesPeriod"
        echo
        echo "現在のstartKesPeriod: XXXX"
        echo
        echo "ブロックプロデューサーノードに表示されている、"
        echo "現在のstartKesPeriod の値を入力してください。"

        
        read -p "半角数字で入力してEnterキーを押してください > " period
        echo

        echo "startKesPeriod: '${period}'"
        echo
        if readYn "上記であっていますか？"; then
        
            cd "$NODE_HOME" || (unuse_coldkeys && return 1)

            unlock_keys

            # shellcheck disable=SC2086
            if ! cardano-cli conway node issue-op-cert \
                --kes-verification-key-file kes.vkey \
                --cold-signing-key-file ${COLDKEYS_DIR}/node.skey \
                --operational-certificate-issue-counter ${COLDKEYS_DIR}/node.counter \
                --kes-period ${period} \
                --out-file node.cert;
            then
                unuse_coldkeys
                lock_keys
                echo
                echo
                echo_red "'node.cert'ファイルの生成に失敗しました"
                echo
                echo
                pressKeyEnter "再度お試しください"
                return 1
            fi

            cp "${NODE_HOME}/node.cert" "$SHARE_DIR/"
            
            unuse_coldkeys
            lock_keys

            clear
            echo
            echo "■ node.cert生成完了"
            echo
            echo "share ディレクトリに node.cert ファイルを出力しました。"
            echo "このファイルをBPのcnodeディレクトリにコピーしてください。"
            echo

            break

        fi

    done

    lock_keys

    rm $SHARE_DIR/kes.vkey
    rm $SHARE_DIR/kes.skey

    echo
    pressKeyEnter "メインメニューに戻るにはEnterキーを押してください"

    main_menu

}


#
# SPO投票
#
vote_spo() {

	clear

    cp "$SHARE_DIR/create_votetx_script" "$NODE_HOME/create_votetx_script"
    cp "$SHARE_DIR/params.json" "$NODE_HOME/params.json"
	SCRIPT_SHA=$(sha256sum "$NODE_HOME/create_votetx_script" | awk '{ print $1 }')
	
    echo 'ハッシュは以下の通りです。'
    echo -n 'ハッシュ値： '
    echo_green "$SCRIPT_SHA"
    echo
    echo
    if ! readYn '次の手順を実行しますか？'; then
        echo_red "操作をキャンセルします"
        echo
        echo
        pressKeyEnter "メニューに戻るにはエンターキーを押してください"
    fi

    
    if ! use_coldkeys; then
        return 1
    fi
    
    # shellcheck disable=SC1091
    # shellcheck disable=SC2086
    source $NODE_HOME/create_votetx_script

    unuse_coldkeys

    mkdir ${SHARE_DIR}/governance
    cp "$NODE_HOME/governance/vote-tx.signed" ${SHARE_DIR}/governance/vote-tx.signed

    rm "$NODE_HOME/governance/vote-tx.signed"
    rm "$NODE_HOME/create_votetx_script"
    rm "$NODE_HOME/params.json"
    rm "$SHARE_DIR/create_votetx_script"
    rm "$SHARE_DIR/params.json"

    echo
    echo_green "'share/governance'ディレクトリ内に、'vote-tx.signed'ファイルを出力しました。"
    echo
    echo
    pressKeyEnter "このファイルをBPに転送し、処理を続行してください"

	main_menu
}


cli_update() {
    clear

    echo "'share'ディレクトリに新しいバージョンのcardano-cliをコピーしてください。"
    pressKeyEnter "コピーができたらEnterキーを押下してください"

    if [ -f "${SHARE_DIR}/cardano-cli" ]; then

        echo '一時フォルダにコピーしています...'
        cp ${SHARE_DIR}/cardano-cli "$HOME/cardano-cli"
        chmod 755 "$HOME/cardano-cli"

        clear
        echo '■ 現在のバージョン'
        cardano-cli version
        echo
        echo '■ 新しいバージョン'
        # shellcheck disable=SC2086
        $HOME/cardano-cli version
        echo
        if readYn "バージョンアップを実行してもよろしいですか？"; then

            echo
            sudo cp "$HOME/cardano-cli" /usr/local/bin/cardano-cli
            sudo chmod 755 /usr/local/bin/cardano-cli
            echo

            rm "$HOME/cardano-cli"
            rm "${SHARE_DIR}/cardano-cli"

            pressKeyEnter "バージョンアップが完了しました！"

        fi
    else
        echo 
        pressKeyEnter -n 1 -p "'${HOST_PWD}/share/cardano-cli'が見つかりませんでした。"
    fi

    main
}


#
# プール報酬出金
#
withdrawal_stake() {

    clear

    echo
    echo "BPにて'tx.raw'を作成後、'share'ディレクトリにコピーしてください。"
    pressKeyEnter "コピーが出来たらEnterキーを押してください。"
    
    if [ ! -f "${SHARE_DIR}/tx.raw" ]; then
        echo
        echo_red "'share'ディレクトリに'tx.raw'ファイルが見つかりませんでした"
        echo
        echo
        pressKeyEnter
        return 1
    fi

    cp ${SHARE_DIR}/tx.raw "$NODE_HOME/tx.raw"

    
    if ! use_coldkeys; then
        rm "${NODE_HOME}/tx.raw"
        return 1
    fi

    cd "$NODE_HOME" || exit
    
    # shellcheck disable=SC2086
    if ! cardano-cli conway transaction sign \
        --tx-body-file tx.raw \
        --signing-key-file payment.skey \
        --signing-key-file stake.skey \
        $NODE_NETWORK \
        --out-file tx.signed;
    then
        unuse_coldkeys

        echo_red "トランザクションファイルへの署名に失敗しました"
        echo
        echo
        pressKeyEnter
        return 1
    fi

    unuse_coldkeys

    cp "${NODE_HOME}/tx.signed" "${SHARE_DIR}/tx.signed"
    rm "${NODE_HOME}/tx.signed"
    rm "${NODE_HOME}/tx.raw"
    rm "${SHARE_DIR}/tx.raw"

    echo_green "トランザクションへの署名が完了しました!"
    echo
    echo
    echo_green "'share'ディレクトリに'tx.signed'ファイルを出力しました。"
    echo
    echo
    pressKeyEnter "このファイルをBPに転送し操作を続行してください"

    main
}

#
# payment.addrへの出金
#
withdrawal_stake_to_payment() {

    clear
    echo
    echo_green "gtoolにて作成した'tx.raw'を'share'ディレクトリにコピーしてください"
    echo
    echo
    pressKeyEnter "コピーが出来たらEnterキーを押してください"

    if [ ! -f "${SHARE_DIR}/tx.raw" ]; then
        echo
        echo_red "'share'ディレクトリに'tx.raw'ファイルが見つかりませんでした"
        echo
        echo
        pressKeyEnter
        return 1
    fi

    cd "$NODE_HOME" || exit
    cp "${SHARE_DIR}/tx.raw" "${NODE_HOME}/"

    
    if ! use_coldkeys; then
        rm "${NODE_HOME}/tx.raw"
        return 1
    fi

    if ! cardano-cli conway transaction sign \
        --tx-body-file tx.raw \
        --signing-key-file payment.skey \
        --signing-key-file stake.skey \
        --mainnet \
        --out-file tx.signed;
    then
        unuse_coldkeys
        echo
        echo_red "トランザクションファイルへの署名に失敗しました"
        echo
        echo
        pressKeyEnter
        return 1
    fi

    unuse_coldkeys

    cp "${NODE_HOME}/tx.signed" "${SHARE_DIR}/"
    rm "${NODE_HOME}/tx.signed"
    rm "${NODE_HOME}/tx.raw"
    rm "${SHARE_DIR}/tx.raw"

    echo_green "トランザクションへの署名が完了しました!"
    echo
    echo
    echo_green "'share'ディレクトリに'tx.signed'ファイルを出力しました。"
    echo
    echo
    pressKeyEnter "このファイルをBPに転送し操作を続行してください"

    main
}

#
# 任意のアドレスへ出金(payment.addr)
#
withdrawal_payment() {

	clear
	echo
	echo "gtoolにて作成した'tx.raw'を'share'ディレクトリにコピーしてください"
	echo
	pressKeyEnter "コピーが出来たらEnterキーを押してください"

    if [ ! -f "${SHARE_DIR}/tx.raw" ]; then
        echo
        echo_red "'share'ディレクトリに'tx.raw'ファイルが見つかりませんでした"
        echo
        echo
        pressKeyEnter
        return 1
    fi
	
	cd "${NODE_HOME}" || exit
	cp "${SHARE_DIR}/tx.raw" "$NODE_HOME"/

    
    if ! use_coldkeys; then
        rm "${NODE_HOME}/tx.raw"
        return 1
    fi
    # shellcheck disable=SC2086
	if ! cardano-cli conway transaction sign \
            --tx-body-file tx.raw \
            --signing-key-file payment.skey \
            $NODE_NETWORK \
            --out-file tx.signed;
    then
        unuse_coldkeys
        echo
        echo_red "トランザクションファイルへの署名に失敗しました"
        echo
        echo
        pressKeyEnter
        return 1
    fi

    unuse_coldkeys

	cp "${NODE_HOME}/tx.signed" "${SHARE_DIR}/"
    rm "${NODE_HOME}/tx.signed"
    rm "${NODE_HOME}/tx.raw"
	rm "${SHARE_DIR}/tx.raw"
	
    echo_green "トランザクションへの署名が完了しました!"
    echo
    echo
    echo_green "'share'ディレクトリに'tx.signed'ファイルを出力しました。"
    echo
    echo
    pressKeyEnter "このファイルをBPに転送し操作を続行してください"
}



#
# lib: 暗号化コールドキーを使用したい時に呼び出します
#
use_coldkeys() {

    if ! keys_is_installed; then

        if ! encrypted_keys_exists; then
            echo_red "コールド暗号化キーファイルが見つかりませんでした"
            echo
        else
            if ! decrypt_keys; then
                return 1
            else
                return 0
            fi
        fi
    
    else
        return 0
    fi

    pressKeyEnter "コールドキーが見つかりませんでした"

    return 1
}

#
# lib: 暗号化コールドキーを使用した後に呼び出します
#
unuse_coldkeys() {

    
    if encrypted_keys_exists; then
        
        if check_coldkeys_exists; then
            delete_coldkeys
            return $?
        fi
    fi

    return 1
}


unlock_keys() {
    chmod u+rwx "${COLDKEYS_DIR}"
}

lock_keys() {
    chmod u-rwx "${COLDKEYS_DIR}"
}


#
# コールドキーを暗号化
#
encrypt_keys() {

    if encrypted_keys_exists; then
        echo
        echo_red "すでに暗号化済みのコールドキーが存在しています"
        echo
        pressKeyEnter
        return 1
    fi

    echo

    cd "$HOME" || exit
    unlock_keys

    if ! tar czf ${COLDKEYS_TARBALL} ./cold-keys/node.* ./cnode/payment.{addr,skey,vkey} ./cnode/stake.{addr,skey,vkey}; then
        echo
        echo_red "コールドキーの圧縮に失敗しました"
        echo
        pressKeyEnter
        echo
        return 1
    fi

    # 暗号化
    echo
    echo_green "コールドキーの暗号化に必要なパスワードを入力してください"
    echo
    echo
    if ! openssl enc -aes256 -pbkdf2 -md sha-256 -in ${COLDKEYS_TARBALL} -out ${COLDKEYS_ENCFILE}; then
        echo
        echo_red "コールドキーの暗号化に失敗しました"
        echo
        pressKeyEnter
        echo
        return 1
    fi

    if ! rm "${HOME}/${COLDKEYS_TARBALL}"; then
        echo
        echo_red "コールドキー一時圧縮ファイルの削除に失敗しました"
        echo
        pressKeyEnter
        echo
        return 1
    fi

    if ! delete_coldkeys; then
        echo
        echo_red "平文のコールドキーの削除に失敗しました"
        echo
        echo
        echo_green "コールドキーの暗号化には成功しました"
        echo
        echo
        LS=$(ls -l $COLDKEYS_ENCFILE)
        echo_green "$LS"
        echo
        return 1
    fi

    LS=$(ls -l $COLDKEYS_ENCFILE)
    echo
    echo_green "$LS"
    echo

    return 0
}

delete_coldkeys() {

    cd "$HOME" || exit

    unlock_keys

    if ! rm ./cold-keys/node.* ./cnode/payment.{addr,skey,vkey} ./cnode/stake.{addr,skey,vkey}; then
        echo
        echo_red "コールドキーの削除に失敗しました"
        echo
        echo
        pressKeyEnter "再度お試しください"
        echo
        return 1
    fi

    return 0
}

#
# コールドキーを復号化
#  引数1: 何か指定すると元の暗号化ファイルを消さない
#
decrypt_keys() {

    if [ ! -s ${COLDKEYS_ENCFILE} ]; then
        echo_red "暗号化キーファイルが見つかりませんでした"
        echo
        echo
        pressKeyEnter
        return 1 
    fi

    cd "$HOME" || exit

    # 復号化
    echo "暗号化済みコールドキーが見つかりました!"
    echo
    echo_green "コールドキーの復号化に必要なパスワードを入力してください"
    echo
    echo
    
    if ! openssl enc -d -aes256 -pbkdf2 -md sha-256 -in "${COLDKEYS_ENCFILE}" -out "${HOME}/${COLDKEYS_TARBALL}"; then
        echo
        echo_red "コールドキーの復号化に失敗しました"
        echo
        echo
        pressKeyEnter "メニューに戻るにはエンターキーを押してください"
        return 1
    fi

    unlock_keys

    # 展開
    if ! tar xf ${COLDKEYS_TARBALL}; then
        echo
        echo_red "コールドキーの展開に失敗しました"
        echo
        echo
        pressKeyEnter "メニューに戻るにはエンターキーを押してください"
        echo
        rm -f "${HOME}/${COLDKEYS_TARBALL}"
        return 1
    fi

    lock_keys

    rm "${HOME}/${COLDKEYS_TARBALL}"
    rm "${COLDKEYS_ENCFILE}"

    return 0
}


#
# メインヘッダーを描画します
#
main_header() {

    clear

    cli_version=$(cardano-cli version | head -1 | cut -d' ' -f2)

    available_disk=$(df -h /usr | awk 'NR==2 {print $4}')

    has_keys="NO"
    emoji_keys=""
    
    if keys_is_installed; then
        has_keys="YES"
        emoji_keys=":unlock:"
    else
        if encrypted_keys_exists; then
            has_keys="ENCRYPT"
            emoji_keys=":lock:"
        fi
    fi

    if existsGum; then
        gum style --foreground 4 --border double --align center --width 60 --margin "0 1" --padding "1 2" \
            'SPO JAPAN GUILD TOOL for Airgap' "v${CTOOL_VERSION}"
        
        echo -n " {{ Bold \"CLL:\" }} {{ Color \"3\" \"\" \"${cli_version}\" }}" | gum format --type template
        echo -n " | {{ Bold \"Disk残容量:\" }} {{ Color \"3\" \"\" \"${available_disk}B\" }}" | gum format --type template
        echo -n " | {{ Bold \"Kyes:\" }} {{ Color \"3\" \"\" \"${has_keys}\" }}" | gum format --type template
        echo -n "${emoji_keys}" | gum format --type emoji
    else
        echo
        echo -n " >> SPO JAPAN GUILD TOOL for Airgap " && echo_green "ver${CTOOL_VERSION}" && echo " <<"
        echo ' ---------------------------------------------------------------------'
        echo -n " CLI: " && echo_yellow "${cli_version}" && echo -n " | Disk残容量: " && echo_yellow "${available_disk}B" && echo -n " | Keys: " && echo_yellow "${has_keys}"
        echo
        echo
    fi
}


settings_menu() {

    main_header
    if existsGum; then
        menu=$(gum choose --limit 1 --height 10 --header "===== 各種設定 =====" "1. キーをインポート" "2. cardao-cliバージョンアップ" "3. ctoolバージョンアップ" "4. キー暗号化" "5. キー復号化" "h. ホームへ戻る" "q. 終了")
        echo " $menu"
        menu=${menu:0:1}
    else
        echo ' -------------------------------------------------'
        echo ' >> 各種設定'
        echo ' -------------------------------------------------'
        echo ' [1] キーをインポート'
        echo ' --------------------------------'
        echo ' [2] cardao-cliバージョンアップ'
        echo ' [3] ctoolバージョンアップ'
        echo ' --------------------------------'
        echo ' [4] キー暗号化'
        echo ' [5] キー復号化'
        echo ' --------------------------------'
        echo ' [h] ホームへ戻る  [q] 終了'
        echo
        # shellcheck disable=SC2162
        read -n 1 -p "メニュー番号を入力してください: > " menu
    fi

    case ${menu} in
        1)
            install_coldkeys
            ;;
        2)
            cli_update
            ;;
        3)
            ctool_update
            ;;
        4)
            clear
            if encrypt_keys; then
                echo_green "コールドキーを暗号化しました"
                echo
                pressKeyEnter
            fi
            settings_menu
            ;;
        5)
            clear
            if decrypt_keys; then
                echo_green "コールドキーを復号化しました"
                echo
                pressKeyEnter
            fi
            settings_menu
            ;;
        h)
            main_menu
            ;;
        q)
            echo
            myExit
            ;;
        *)
            settings_menu
            ;;
    esac
    settings_menu
}


governance_menu() {

    main_header
    if existsGum; then
        menu=$(gum choose --limit 1 --height 8 --header "===== ガバナンス(登録・投票) =====" "1. SPO投票" "h. ホームへ戻る" "q. 終了")
        echo " $menu"
        menu=${menu:0:1}
    else
        echo ' ------------------------------------------------------------'
        echo ' >> ガバナンス(登録・投票)'
        echo ' ------------------------------------------------------------'
        echo ' [1] SPO投票'
        echo ' --------------------------------'
        echo ' [h] ホームへ戻る  [q] 終了'
        echo
        # shellcheck disable=SC2162
        read -n 1 -p ' メニュー番号を入力してください :> ' menu
    fi
    case ${menu} in
        1)
            vote_spo
            ;;
        h)
            main_menu
            ;;
        q)
            echo
            myExit
            ;;
        *)
            governance_menu
            ;;
    esac
}


wallet_menu() {

    main_header
    if existsGum; then
        menu=$(gum choose --limit 1 --height 8 --header "===== ウォレット操作 =====" "1. プール報酬(stake.addr)任意のアドレス(ADAHandle)へ出金" "2. プール報酬(stake.addr)payment.addrへの出金" "3. プール資金(payment.addr)任意のアドレス(ADAHandle)へ出金" "h. ホームへ戻る" "q. 終了")
        echo " $menu"
        menu=${menu:0:1}
    else
        echo ' -------------------------------------------------'
        echo ' >> ウォレット操作'
        echo ' -------------------------------------------------'
        echo -n " "
        echo_magenta ' ■ プール報酬出金(stake.addr)'
        echo
        echo ' [1] 任意のアドレス(ADAHandle)へ出金'
        echo ' [2] payment.addrへの出金'
        echo
        echo -n " "
        echo_magenta ' ■ プール資金出金(payment.addr)'
        echo
        echo ' --------------------------------'
        echo ' [3] 任意のアドレス(ADAHandle)へ出金'
        echo
        echo ' --------------------------------'
        echo ' [h] ホームへ戻る  [q] 終了'
        echo
        # shellcheck disable=SC2162
        read -n 1 -p "メニュー番号を入力してください: > " menu
    fi

    case ${menu} in
        1)
            withdrawal_stake
            wallet_menu
            ;;
        2)
        	withdrawal_stake_to_payment
        	wallet_menu
        	;;
        3)
        	withdrawal_payment
            wallet_menu
        	;;
        q)
            echo
            myExit
            ;;
        h)
        	main_menu
        	;;
        *)
            echo
            echo '番号が不正です...'
            sleep 1
            wallet_menu
            ;;
    esac
}


main_menu() {

    main_header
    if existsGum; then
        menu=$(gum choose --limit 1 --height 8 --header "===== メインメニュー =====" "1. ウォレット操作" "2. KES更新" "3. ガバナンス(登録・投票)" "s. 各種設定" "q. 終了")
        echo " $menu"
        menu=${menu:0:1}
    else
        echo ' [1] ウォレット操作'
        echo ' [2] KES更新'
        echo ' --------------------------------'
        echo ' [3] ガバナンス(登録・投票)'
        echo ' --------------------------------'
        echo ' [s] 各種設定'
        echo ' --------------------------------'
        echo ' [q] 終了'
        echo
        # shellcheck disable=SC2162
        read -n 1 -p "メニュー番号を入力してください: > " menu
    fi

    case ${menu} in
        1)
            wallet_menu
            ;;
        2)
            reflesh_kes
            ;;
        3)
        	governance_menu
        	;;
        s)
            settings_menu
            ;;
        q)
            quit
            ;;
        *)
            echo
            echo '番号が不正です...'
            sleep 1
            main
            ;;
    esac
}


main
