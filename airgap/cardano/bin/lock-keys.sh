#!/bin/bash

ESC=$(printf '\033')

printf "${ESC}[31m%s${ESC}[m" "コールドキーへのアクセス制限を設定します。"
echo

chmod a-rwx $HOME/cold-keys

ls -l $HOME | grep cold-keys

printf "${ESC}[32m%s${ESC}[m" "アクセス制限を設定しました。"
echo

