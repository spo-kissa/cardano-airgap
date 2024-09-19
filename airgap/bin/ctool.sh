#!/bin/bash

CTOOL_VERSION=0.2.0

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

main() {
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

    main
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
            cardano-cli node new-counter \
                --cold-verification-key-file $HOME/cold-keys/node.vkey \
                --counter-value ${counter} \
                --operational-certificate-issue-counter-file $HOME/cold-keys/node.counter

            break

        fi

    done

    cardano-cli text-view decode-cbor \
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

            cardano-cli node issue-op-cert \
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

    main

}


governance() {
	clear
	echo
	
	echo "ガバナンスアクションIDを入力してください。"
	read -p "Govenance Action ID: " AID
	
	GAID=$(echo $AID | cut -d '#' -f 1)
	TXID=$(echo $AID | cut -d '#' -f 2)
	
	echo
	echo "ガバナンスアクションID: ${GAID}"
	echo "TxID: ${TXID}"
	
	echo
	read -p "このガバナンスへの回答を入力してください [Yes/No/Abstain/Cancel]：" Answer
	
	ANS=$(echo "${Answer:0:1}" | tr [:lower:] [:upper:])
	case $ANS in
		Y)
			VOTE="--yes"
			echo "YESに投票します。"
			;;
		N)
			VOTE="--no"
			echo "NOに投票します。"
			;;
		A)
			VOTE="--abstain"
			echo "棄権票を投票します。"
			;;
		C)
			read -n 1 -p "キャンセルします..."
			main_menu
			;;
		*)
			read -n 1 -p "不正な入力です..."
			main_menu
			;;
	esac
	
	echo
	cd $NODE_HOME
	chmod u+rwx $HOME/cold-keys
	cardano-cli conway governance vote create \
		${VOTE} \
		--governance-action-tx-id "${GAID}" \
		--governance-action-index "${TXID}" \
		--cold-verification-key-file $HOME/cold-keys/node.vkey \
		--out-file ${GAID}
	
	chmod a-rwx $HOME/cold-keys
		
	cp $NODE_HOME/${GAID} /mnt/share/
	
	clear
	echo
	echo "'share'ディレクトリに'${GAID}'ファイルを出力しました。"
	echo
	read -n 1 -p "'vote-tx.raw'を'share'ディレクトリにコピーしたら、Enterキーを押してください。" Enter
	
	clear
	echo
	
	echo "'vote-tx.raw'に署名をおこないます。"
	read -n 1 -p "よろしいですか？ > " Enter
	
	cd $NODE_HOME
	chmod u+rwx $HOME/cold-keys
	
	cp /mnt/share/vote-tx.raw $NODE_HOME/
	cardano-cli conway transaction sign \
		--tx-body-file vote-tx.raw \
		--signing-key-file $HOME/cold-keys/node.skey \
		--signing-key-file payment.skey \
		--out-file vote-tx.signed
	cp $NODE_HOME/vote-tx.signed /mnt/share/
	rm /mnt/share/vote-tx.raw
	chmod a-rwx $HOME/cold-keys
	
	echo
	echo "'vote-tx.signed'ファイルを'share'ディレクトリに出力しました。"
	echo
	echo
	read -n 1 -p "メインメニューに戻るにはEnterキーを押してください。"
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


withdrawal_stake() {

    clear

    echo "BPにて'tx.raw'を作成後、'share'ディレクトリにコピーしてください。"
    read -n 1 -p "コピーが出来たらEnterキーを押してください。" enter
    
    if [ -f /mnt/share/tx.raw ]; then

        cp /mnt/share/tx.raw $NODE_HOME/tx.raw

        cd $NODE_HOME
        cardano-cli transaction sign \
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


main_header() {

    clear

    cli_version=$(cardano-cli version | head -1 | cut -d' ' -f2)

    available_disk=$(df -h /usr | awk 'NR==2 {print $4}')

    echo
    echo -e " >> SPO JAPAN GUILD TOOL for Airgap ver$CTOOL_VERSION <<"
    echo ' -------------------------------------------------'
    echo -e " CLI: ${cli_version} | Disk残容量: ${available_disk}B"
    echo

}


wallet_menu() {

    main_header
    echo ' [1] 報酬の引き出し'
    echo ' -------------------------------'
    echo ' [q] メインメニューに戻る'
    echo
    read -n 1 -p "メニュー番号を入力してください: > " num

    case ${num} in
        1)
            withdrawal_stake
            ;;
        2)
        ;;
        q)
            main
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
    echo ' [3] ガバナンスアクション'
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
        	governance
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


upgrade() {
    return 0
}

main
