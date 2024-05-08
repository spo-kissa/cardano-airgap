#!/bin/bash

NODE_HOME=/home/cardano/cnode
SHARE_TX=0

ESC=$(printf '\033')

if [ -f /mnt/share/tx.raw ]; then
  printf "${ESC}[32m%s${ESC}[m" "tx.raw ファイルを ${NODE_HOME}/ ディレクトリにコピーしています。"
  echo
	cp /mnt/share/tx.raw $NODE_HOME/tx.raw
  SHARE_TX=1
fi

cd $NODE_HOME

if [ ! -f tx.raw ]; then
  printf "${ESC}[31m%s${ESC}[m" "tx.raw ファイルが見つかりません！"
  echo
  exit 1
fi

cardano-cli transaction sign \
  --tx-body-file tx.raw \
  --signing-key-file payment.skey \
  --signing-key-file stake.skey \
  --mainnet \
  --out-file tx.signed

echo $0
printf "${ESC}[32m%s${ESC}[m" "トランザクションファイルに署名しました！"
echo

if [ "$SHARE_TX" -eq "1" ]; then
  printf "${ESC}[32m%s${ESC}[m" "tx.signedファイルを /mnt/share/ ディレクトリにコピーしています"
  echo
  cp $NODE_HOME/tx.signed /mnt/share/tx.signed
fi

