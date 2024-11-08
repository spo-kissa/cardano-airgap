#!/bin/bash
# shellcheck disable=SC2162

VERSION=$1
MANUAL=1;
if [ -z "$VERSION" ]; then
    MANUAL=0
fi

h1() {
    if [ $MANUAL -eq 0 ]; then
        tput setaf 2 && echo "$1" && tput setaf 7
    else
        echo "$1"
    fi
}

h2() {
    if [ $MANUAL -eq 0 ]; then
        tput setaf 4 && echo "$1" && tput setaf 7
    else
        echo "$1"
    fi
}

generated() {
    echo "Generated binary..."
    if [ $MANUAL -eq 0 ]; then
        tput setaf 5 && echo "$1" && tput setaf 7
        tput setaf 5 && echo "$2" && tput setaf 7
        tput setaf 5 && echo "$3" && tput setaf 7
        tput setaf 5 && echo "$4" && tput setaf 7
    else
        echo "$1"
        echo "$2"
        echo "$3"
        echo "$4"
    fi
}


echo
if [ $MANUAL -eq 0 ]; then
    tput setaf 5 && echo -n "ctool.sh リリースビルド生成ツール" && tput setaf 7
fi
echo
echo
if [ $MANUAL -eq 0 ]; then
    read -p "バージョン番号を入力してください: " VERSION
fi

echo
echo "バージョン番号は、"
echo "-----------------"
h2 "${VERSION}"
echo "-----------------"
echo "で、よろしいですか？"
echo
if [ $MANUAL -eq 0 ]; then
    read -n 1
fi


empty_file() {
    if [ ! -s "$1" ]; then
        if [ $MANUAL -eq 0 ]; then
            tput setaf 2 && echo -n "${1}    [OK]" && tput setaf 7
        else
            echo -n "${1}   [OK]"
        fi
        echo
        return 0
    else
        if [ $MANUAL -eq 0 ]; then
            tput setaf 1 && echo -n "${1}   [NG]" && tput setaf 7
        else
            echo -n "${1}   [NG]"
        fi
        echo
        return 1
    fi
}

check() {
    if [ $? -eq 0 ]; then
        if [ $MANUAL -eq 0 ]; then
            tput setaf 2 && echo -n "    [OK]" && tput setaf 7
        else
            echo -n "   [OK]"
        fi
        echo
        return 0
    else
        echo
        if [ $MANUAL -eq 0 ]; then
            tput setaf 1 && echo -n "   [NG]" && tput setaf 7
        else
            echo -n "   [NG]"
        fi
        echo
        return 1
    fi
}


#
#  USB Target Release Build
#

h2 "[1/1] Start build target 'USB'..."
echo -n "Creating release directory..."
mkdir -p ./release/ && check || exit

echo -n "Copying airgap -> release..."
cp -rp ./airgap ./release/ && check || exit

echo -n "Change 'release' directory..."
cd ./release && check || exit

echo -n "Checking...Zero byte file " && empty_file "airgap/share/cnode/payment.addr"     || exit
echo -n "Checking...Zero byte file " && empty_file "airgap/share/cnode/payment.skey"     || exit
echo -n "Checking...Zero byte file " && empty_file "airgap/share/cnode/payment.vkey"     || exit
echo -n "Checking...Zero byte file " && empty_file "airgap/share/cnode/stake.addr"       || exit
echo -n "Checking...Zero byte file " && empty_file "airgap/share/cnode/stake.skey"       || exit
echo -n "Checking...Zero byte file " && empty_file "airgap/share/cnode/stake.vkey"       || exit
echo -n "Checking...Zero byte file " && empty_file "airgap/share/cold-keys/node.counter" || exit
echo -n "Checking...Zero byte file " && empty_file "airgap/share/cold-keys/node.skey"    || exit
echo -n "Checking...Zero byte file " && empty_file "airgap/share/cold-keys/node.vkey"    || exit

echo -n "Removing 'docker-compose.yml'..."
rm -f airgap/docker-compose.yml && check || exit

echo -n "Renaming 'docker-compose.usb.yml' -> 'docker-compose.yml'..."
mv -f airgap/docker-compose.usb.yml airgap/docker-compose.yml && check || exit

echo -n "Copying directory 'airgap/bin' -> 'cardano/bin'..."
cp -r ./airgap/bin ./airgap/cardano/ && check || exit

echo -n "Create directory 'cardano/cnode' and 'cardano/cold-keys'..."
mkdir -p ./airgap/cardano/{cnode,cold-keys} && check || exit

echo -n "Creating '.sudo_as_admin_successful' file..."
touch ./airgap/cardano/.sudo_as_admin_successful && check || exit


echo -n "Create tarball 'airgap-usb-${VERSION}.tar.gz'..."
tar --exclude .DS_Store -czf "airgap-usb-${VERSION}.tar.gz" airgap && check || exit

echo "done."
echo


#
#  Standard Release Build.
#

h2 "[2/2] Start build target 'Standard'..."

echo -n "Resetting release directory..."
rm -r ./airgap && check || exit

echo -n "Copying airgap -> release..."
cp -rp ../airgap ./ && check || exit

echo -n "Checking...Zero byte file " && empty_file "airgap/share/cnode/payment.addr"     || exit
echo -n "Checking...Zero byte file " && empty_file "airgap/share/cnode/payment.skey"     || exit
echo -n "Checking...Zero byte file " && empty_file "airgap/share/cnode/payment.vkey"     || exit
echo -n "Checking...Zero byte file " && empty_file "airgap/share/cnode/stake.addr"       || exit
echo -n "Checking...Zero byte file " && empty_file "airgap/share/cnode/stake.skey"       || exit
echo -n "Checking...Zero byte file " && empty_file "airgap/share/cnode/stake.vkey"       || exit
echo -n "Checking...Zero byte file " && empty_file "airgap/share/cold-keys/node.counter" || exit
echo -n "Checking...Zero byte file " && empty_file "airgap/share/cold-keys/node.skey"    || exit
echo -n "Checking...Zero byte file " && empty_file "airgap/share/cold-keys/node.vkey"    || exit

echo -n "Removing 'docker-compose.usb.yml'..."
rm -f airgap/docker-compose.usb.yml && check || exit

echo -n "Removing 'cardano' directory..."
rm -r airgap/cardano && check || exit

echo -n "Create tarball 'airgap-${VERSION}.tar.gz'..."
tar --exclude .DS_Store -czf "airgap-${VERSION}.tar.gz" airgap && check || exit

echo "done."
echo


#
#  ctool.sh Release
#

cp ../airgap/bin/ctool.sh ./ctool.sh && check || exit

# Get ctool.sh version
CTOOL_VERSION=$(cat ./ctool.sh | grep CTOOL_VERSION= | head -n 1)
CTOOL_VERSION="${CTOOL_VERSION:14}"

echo -n "Create tarball 'ctool-${CTOOL_VERSION}.sh.tar.gz'..."
tar -czf "ctool-${CTOOL_VERSION}.sh.tar.gz" ctool.sh && check || exit

echo "done."
echo


#
# Calculate file hashsum
#

{
shasum -a 256 "airgap-${VERSION}.tar.gz"
shasum -a 256 "airgap-usb-${VERSION}.tar.gz"
shasum -a 256 "ctool.sh"
shasum -a 256 "ctool-${CTOOL_VERSION}.sh.tar.gz"
} > checksum.txt

#
# Release resource
#
echo -n "Removing temporary 'airgap' directory"
rm -r ./airgap && check || exit

echo -n "Reaved 'release' directory..."
cd .. && check || exit

generated "airgap-${VERSION}.tar.gz" "airgap-usb-${VERSION}.tar.gz" "ctool-${CTOOL_VERSION}.tar.gz" "checksum.txt"

echo "All done."
