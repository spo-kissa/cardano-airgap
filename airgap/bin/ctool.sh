#!/bin/bash

CTOOL_VERSION=0.0.2

COLDKEYS_DIR='$HOME/cold-keys'

# General exit handler
cleanup() {
    [[ -n $1 ]] && err=$1 || err=$?
    [[ $err -eq 0 ]] && clear
    tput cnorm # restore cursor
    [[ -n ${exit_msg} ]] && echo -e "¥n${exit_msg}¥n" || echo -e "¥nSPO JAPAN GUILD TOOL Closed!¥n"
    tput sgr0  # turn off all attributes
    exit $err
}

trap cleanup HUP INT TERM
trap 'stty echo' EXIT

myExit() {
    exit_msg="$2"
    cleanup "$1"
}

quit() {
    clear
    echo
    echo "SPO JAPAN GUILD TOOL Closed!"
    echo
    exit
}

readYn() {
    read -n 1 -p "${1} [Y/n]" ANS

    case $ANS in
        "" | [Yy]* )
            return 0
            ;;
        * )
            return 1
            ;;
    esac
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
}


install() {
    clear

    get_keys
    keys=$1

    echo "'${HOST_PWD}/share'ディレクトリに以下のファイルをコピーしてください。"
    echo 
    for key in ${keys[@]}; do
        echo $key
    done

    while true; do
        echo
        read -n 1 -p "コピーが出来たらEnterキーを押下してください" enter
        clear

        ng=0
        err=""
        for key in ${keys[@]}; do
            path="/mnt/share${key}"
            if [ -f $path ]; then
                if [ -s $path ]; then
                    echo -n '[✓]'
                else
                    echo -n '[×]'
                    let ng=$ng+1
                    err='ファイルが空です'
                fi
            else
                echo -n '[×]'
                let ng=$ng+1
                err='ファイルが見つかりません'
            fi
            echo " ${key} ... ${err}"
        done
        
        if [ $ng -eq 0 ]; then
            break
        fi
    done

    echo
    echo 'インポートの準備が整いました！'
    if readYn "インポートを開始しますか？"; then

        echo

        for key in ${keys[@]}; do
            src="/mnt/share${key}"
            dst="/home/cardano${key}"

            echo "${src} => ${dst}"
            cp ${src} ${dst}

        done

        echo
        echo 'shareフォルダのデータを削除しています...'
        rm -rf /mnt/share/cold-keys
        rm -rf /mnt/share/cnode

        echo 
        read -n 1 -p 'コールドキーのインポートが正常に完了しました！' enter

    fi

    main
}

cli_update() {
    clear

    echo "'${HOST_PWD}/share'ディレクトリに新しいバージョンのcardano-cliをコピーしてください。"
    read -n 1 -p "コピーができたらEnterキーを押下してください" enter

    if [ -f "/mnt/share/cardano-cli" ]; then

        echo '一時フォルダにコピーしています...'
        cp /mnt/share/cardano-cli $HOME/cardano-cli
        chmod 755 $HOME/cardano-cli

        clear
        echo '■ 現在のバージョン'
        cardano-cli version
        echo
        echo '■ 新しいバージョン'
        $HOME/cardano-cli version
        echo
        if readYn "バージョンアップをおこなってもよろしいですか？"; then

            echo
            sudo cp $HOME/cardano-cli /usr/local/bin/cardano-cli
            echo

            rm $HOME/cardano-cli
            rm /mnt/share/cardano-cli

        fi
    else
        echo 
        read -n 1 -p "'${HOST_PWD}/share/cardano-cli'が見つかりませんでした。" press
    fi

    main
}


main() {

    clear

    cli_version=$(cardano-cli version | head -1 | cut -d' ' -f2)

    available_disk=$(df -h /usr | awk 'NR==2 {print $4}')

    echo
    echo -e " >> SPO JAPAN GUILD TOOL for Airgap ver$CTOOL_VERSION <<"
    echo ' -------------------------------------------------'
    echo -e " CLI:${cli_version} | Disk残容量:${available_disk}"
    echo
    echo ' [1] ウォレット操作'
    echo ' [2] KES更新'
    echo ' -------------------------------'
    echo ' [3] 初期設定'
    echo ' [4] cardao-cliバージョンアップ'
    echo ' [5] ctoolバージョンアップ'
    echo ' -------------------------------'
    echo ' [q] 終了'
    echo
    read -n 1 -p "メニュー番号を入力してください: > " menu

    case ${menu} in
        1)
        echo ”ウォレット操作”
        ;;
        2)
        echo "KES更新"
        ;;
        3)
        install
        ;;
        4)
        cli_update
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


upgrade() {
    return 0
}

main
