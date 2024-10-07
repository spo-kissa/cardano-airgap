#!/bin/bash

CTOOL_VERSION=0.3.4

COLDKEYS_DIR='$HOME/cold-keys'

# General exit handler
cleanup() {
    [[ -n $1 ]] && err=$1 || err=$?
    [[ $err -eq 0 ]] && clear
    tput cnorm # restore cursor
    [[ -n ${exit_msg} ]] && echo -e "${exit_msg}" || echo -e "SPO JAPAN GUILD TOOL for Airgap Closed!"
    tput sgr0  # turn off all attributes
    exit $err
}

trap cleanup HUP INT TERM
trap 'stty echo' EXIT

myExit() {
    exit_msg="$2"
    cleanup "$1"
}


ctool_upgrade() {

    cp /mnt/share/ctool.sh ${HOME}/bin/
    chmod 755 ${HOME}/bin/ctool.sh
    rm /mnt/share/ctool.sh

    echo "'ctool.sh'をバージョンアップしました!!"
    echo "Enterキーを押してリロードしてください"
    read wait

}

ctool_update() {
    clear
    echo "'share'ディレクトリに新しいバージョンの'ctool.sh'をコピーしてください。"
    read -n 1 -p "コピーができたらEnterキーを押下してください" enter
    if [ -f "/mnt/share/ctool.sh" ]; then

        HASH=$(sha256sum /mnt/share/ctool.sh)

        echo
        echo "以下のハッシュ値がctool.shのリリースノートなどの値と一致している事を確認してください。"
        echo ${HASH}
        echo
        if readYn "ハッシュ値に問題がなければ Y キーを押してください。それ以外の場合は N キーを押してください"; then

            echo
            cp /mnt/share/ctool.sh ${HOME}/bin/
            chmod 755 ${HOME}/bin/ctool.sh
            rm /mnt/share/ctool.sh
            echo "'ctool.sh'をバージョンアップしました!!"
            echo "Enterキーを押してリロードしてください"
            read wait
            return 1

        fi

        read -n 1 -p "戻るには何かキーを押してください" press

    else
        echo
        read -n 1 -p "'share/ctool.sh'ファイルが見つかりませんでした。" press
    fi

    main
}

check_update() {

    if [ -f /mnt/share/ctool.sh ]; then
        VERSION=$(cat /mnt/share/ctool.sh | grep CTOOL_VERSION= | head -n 1)
        VERSION_NUMBER=$(get_version_number ${VERSION:14})

        MY_VERSION_NUMBER=$(get_version_number $CTOOL_VERSION)

        VERSION_DIFF=$((VERSION_NUMBER-MY_VERSION_NUMBER))

        if (( ${VERSION_DIFF} > 0 )); then

            HASH=$(sha256sum /mnt/share/ctool.sh)

            clear
            echo
            echo_green "新しい'ctool.ch'を'share'ディレクトリ内に検出しました!!"
            echo
            echo
            echo "バージョン：${VERSION:14}"
            echo -n "ハッシュ値："
            echo_green ${HASH:0:64}
            echo
            echo "v${CTOOL_VERSION} --> v${VERSION:14}"
            echo
            if [ readYn "バージョンアップしますか？" -eq 1 ]; then
                ctool_upgrade
            fi
        fi
    fi
}


get_version_number() {
    echo "$1" | awk -F. '{printf "%2d%02d%02d", $1,$2,$3}' | bc
}

echo_red() {
    tput setaf 1 && echo -n $1 && tput setaf 7
}

echo_green() {
    tput setaf 2 && echo -n $1 && tput setaf 7
}

echo_yellow() {
    tput setaf 3 && echo -n $1 && tput setaf 7
}

echo_blue() {
    tput setaf 4 && echo -n $1 && tput setaf 7
}

echo_magenta() {
    tput setaf 5 && echo -n $1 && tput setaf 7
}


main() {
    check_update

    main_menu
}

quit() {
    clear
    echo
    myExit
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
        read -n 1 -p "'share'ディレクトリにコピーが出来たらEnterキーを押下してください" enter
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

    main_menu
}


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

        read -n 1 -p "コピーが出来たらEnterキーを押してください" enter

        if [ -s /mnt/share/kes.vkey ] && [ -f /mnt/share/kes.vkey ]; then

            if [ -s /mnt/share/kes.skey ] && [ -f /mnt/share/kes.skey ]; then

                break

            else

                echo "kes.skeyファイルが空かファイルが見つかりません。"

            fi

        else

            echo "kes.vkeyファイルが空かファイルが見つかりません。"

        fi

        echo
        read -n 1 -p "再度チェックするにはEnterキーを押下してください。> " enter

    done

    cp /mnt/share/kes.vkey $NODE_HOME/
    cp /mnt/share/kes.skey $NODE_HOME/

    rm /mnt/share/kes.vkey
    rm /mnt/share/kes.skey

    cd $NODE_HOME

    VKEY=$(sha256sum kes.vkey | cut -d ' ' -f 1)
    SKEY=$(sha256sum kes.skey | cut -d ' ' -f 1)

    echo "kes.vkey >> ${VKEY}"
    echo "kes.skey >> ${SKEY}"
    echo

    read -n 1 -p "ハッシュ値が一致している事を確認してください > " enter 

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
        
            chmod u+rwx $HOME/cold-keys
            cardano-cli conway node new-counter \
                --cold-verification-key-file $HOME/cold-keys/node.vkey \
                --counter-value ${counter} \
                --operational-certificate-issue-counter-file $HOME/cold-keys/node.counter

            break

        fi

    done

    cardano-cli conway text-view decode-cbor \
        --in-file  $HOME/cold-keys/node.counter \
        | grep int | head -1 | cut -d"(" -f2 | cut -d")" -f1

    
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
        
            cd $NODE_HOME

            cardano-cli conway node issue-op-cert \
                --kes-verification-key-file kes.vkey \
                --cold-signing-key-file $HOME/cold-keys/node.skey \
                --operational-certificate-issue-counter $HOME/cold-keys/node.counter \
                --kes-period ${period} \
                --out-file node.cert
            
            chmod a-rwx $HOME/cold-keys

            cp $NODE_HOME/node.cert /mnt/share/

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

    echo
    read -n 1 -p "メインメニューに戻るにはEnterキーを押してください > " enter

    main_menu

}


vote_spo() {

	clear

    cp /mnt/share/create_votetx_script $NODE_HOME/create_votetx_script
    cp /mnt/share/params.json $NODE_HOME/params.json
	SCRIPT_SHA=$(sha256sum $NODE_HOME/create_votetx_script | awk '{ print $1 }')
	
    echo 'ハッシュは以下の通りです。'
    echo -n 'ハッシュ値： '
    echo_green $SCRIPT_SHA
    echo
    echo
    echo '次の手順を実行しますか？'
    echo ' [1] はい   [2] キャンセル'
    echo
    read -n 1 -p '>' num
    case $num in
        1)
            source $NODE_HOME/create_votetx_script
            ;;
        2)
            govenance_menu
            ;;
        *)
            vote_spo
            ;;
    esac

    mkdir /mnt/share/governance
    cp $NODE_HOME/governance/vote-tx.signed /mnt/share/governance/vote-tx.signed

    read -n 1 -p "'share/governance'ディレクトリ内に、'vote-tx.signed'ファイルを出力しました。"

	main_menu
}


cli_update() {
    clear

    echo "'share'ディレクトリに新しいバージョンのcardano-cliをコピーしてください。"
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
        if readYn "バージョンアップを実行してもよろしいですか？"; then

            echo
            sudo cp $HOME/cardano-cli /usr/local/bin/cardano-cli
            sudo chmod 755 /usr/local/bin/cardano-cli
            echo

            rm $HOME/cardano-cli
            rm /mnt/share/cardano-cli

            read -n 1 -p "バージョンアップが完了しました！" press

        fi
    else
        echo 
        read -n 1 -p "'${HOST_PWD}/share/cardano-cli'が見つかりませんでした。" press
    fi

    main
}


withdrawal_stake() {

    clear

    echo "BPにて'tx.raw'を作成後、'share'ディレクトリにコピーしてください。"
    read -n 1 -p "コピーが出来たらEnterキーを押してください。" enter
    
    if [ -f /mnt/share/tx.raw ]; then

        cp /mnt/share/tx.raw $NODE_HOME/tx.raw

        cd $NODE_HOME
        cardano-cli conway transaction sign \
            --tx-body-file tx.raw \
            --signing-key-file payment.skey \
            --signing-key-file stake.skey \
            $NODE_NETWORK \
            --out-file tx.signed
        cd -

        cp $NODE_HOME/tx.signed /mnt/share/tx.signed
        rm /mnt/share/tx.raw

        echo "トランザクションへの署名が完了しました!"
        read -n 1 -p "'share'ディレクトリに'tx.signed'ファイルを出力しました。" enter

    else

        read -n 1 -p "'share'ディレクトリに'tx.raw'ファイルが見つかりません。" enter

    fi

    wallet_menu

}


withdrawal_payment() {

	clear
	
	echo
	echo "gtoolにて作成した'tx.raw'を'share'ディレクトリにコピーしてください"
	echo
	read -n 1 -p "コピーが出来たらEnterキーを押してください" enter
	
	cd $NODE_HOME
	cp /mnt/share/tx.raw $NODE_HOME/
	cardano-cli conway transaction sign \
  		--tx-body-file tx.raw \
  		--signing-key-file payment.skey \
  		$NODE_NETWORK \
  		--out-file tx.signed
	cp $NODE_HOME/tx.signed /mnt/share/
	rm /mnt/share/tx.raw
	
	echo
	echo
	read -n 1 -p "'tx.signed'を'share'ディレクトリに出力しました"
}


main_header() {

    clear

    cli_version=$(cardano-cli version | head -1 | cut -d' ' -f2)

    available_disk=$(df -h /usr | awk 'NR==2 {print $4}')

    echo
    echo -n " >> SPO JAPAN GUILD TOOL for Airgap " && echo_green "ver${CTOOL_VERSION}" && echo " <<"
    echo ' -------------------------------------------------'
    echo -n " CLI: " && echo_yellow "${cli_version}" && echo -n " | Disk残容量: " && echo_yellow "${available_disk}B"
    echo
    echo

}


govenance_menu() {

    clear
    echo '------------------------------------------------------------'
    echo '>> ガバナンス(登録・投票)'
    echo '------------------------------------------------------------'
    echo '[1] SPO投票'
    echo '-------------------'
    echo '[b] 戻る'
    echo
    echo 'メニュー番号を入力してください : '

    read -n 1 -p '>' num

    case ${num} in
        1)
            vote_spo
            ;;
        b)
            main_menu
            ;;
        *)
            govenance_menu
            ;;
    esac
}


wallet_menu() {

    main_header
    echo_magenta '■ プール報酬出金(stake.addr)'
    echo
    echo ' [1] 任意のアドレス(ADAHandle)へ出金'
    echo ' [2] payment.addrへの出金'
    echo
    echo_magenta '■ プール資金出金(payment.addr)'
    echo
    echo ' -------------------------------'
    echo ' [3] 任意のアドレス(ADAHandle)へ出金'
    echo
    echo '--------------------------------'
    echo '[h] ホームへ戻る　[q] 終了'
    read -n 1 -p "メニュー番号を入力してください: > " num

    case ${num} in
        1)
            withdrawal_stake
            ;;
        2)
        	read -n 1 -p "未実装です。" enter
        	wallet_menu
        	;;
        3)
        	withdrawal_payment
        	;;
        q)
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
    echo ' [1] ウォレット操作'
    echo ' [2] KES更新'
    echo ' [3] ガバナンス(登録・投票)'
    echo ' -------------------------------'
    echo ' [5] 初期設定'
    echo ' [6] cardao-cliバージョンアップ'
    echo ' [7] ctoolバージョンアップ'
    echo ' -------------------------------'
    echo ' [q] 終了'
    echo
    read -n 1 -p "メニュー番号を入力してください: > " menu

    case ${menu} in
        1)
            wallet_menu
            ;;
        2)
            reflesh_kes
            ;;
        3)
        	govenance_menu
        	;;
        5)
            install
            ;;
        6)
            cli_update
            ;;
        7)
            ctool_update
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
