#!/bin/bash

ESC=$(printf '\033')

printf "${ESC}[31m%s${ESC}[m" "コールドキーへのアクセス制限を解除します。"
echo

chmod u+rwx $HOME/cold-keys

ls -l $HOME | grep cold-keys


printf "${ESC}[32m%s${ESC}[m" "アクセス制限を解除しました。"
echo
printf "${ESC}[31m%s${ESC}[m" "必要な作業が終了したら必ずアクセス制限を戻してください。"
echo
printf "${ESC}[31m%s${ESC}[m" "./lock-keys.sh"
echo

