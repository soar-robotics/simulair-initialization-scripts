#!/bin/bash

function main() {
    ARGS=`getArgs "$@"`

    userName=`echo "$ARGS" | getNamedArg userName`
    create_client "$userName"
    echo "OK!"
}


function getArgs() {
    for arg in "$@"; do
        echo "$arg"
    done
}


function getNamedArg() {
    ARG_NAME=$1

    sed --regexp-extended --quiet --expression="
        s/^--$ARG_NAME=(.*)\$/\1/p  # Get arguments in format '--arg=value': [s]ubstitute '--arg=value' by 'value', and [p]rint
        /^--$ARG_NAME\$/ {          # Get arguments in format '--arg value' ou '--arg'
            n                       # - [n]ext, because in this format, if value exists, it will be the next argument
            /^--/! p                # - If next doesn't starts with '--', it is the value of the actual argument
            /^--/ {                 # - If next do starts with '--', it is the next argument and the actual argument is a boolean one
                # Then just repla[c]ed by TRUE
                c TRUE
            }
        }
    "
}
new_client () {
	client=$1
        {
	cat /etc/openvpn/server/client-common.txt
	echo "<ca>"
	cat /etc/openvpn/server/easy-rsa/pki/ca.crt
	echo "</ca>"
	echo "<cert>"
	sed -ne '/BEGIN CERTIFICATE/,$ p' /etc/openvpn/server/easy-rsa/pki/issued/"$client".crt
	echo "</cert>"
	echo "<key>"
	cat /etc/openvpn/server/easy-rsa/pki/private/"$client".key
	echo "</key>"
	echo "<tls-crypt>"
	sed -ne '/BEGIN OpenVPN Static key/,$ p' /etc/openvpn/server/tc.key
	echo "</tls-crypt>"
	} > ~/vpn-credentials/"$client".ovpn
}

create_client() {
    unsenitized=$1
    echo "$unsenitized"
    client=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g' <<< "$unsenitized")
    while [[ -z "$client" || -e /etc/openvpn/server/easy-rsa/pki/issued/"$client".crt ]]; do
    	echo "FAIL!"
     	exit
    done
    cd /etc/openvpn/server/easy-rsa/
    EASYRSA_CERT_EXPIRE=3650 ./easyrsa build-client-full "$client" nopass
    # Generates the custom client.ovpn
    new_client "$client"
    echo
    echo "$client added. Configuration available in:" "~/vpn-credentials/$client.ovpn"
    exit

}
main "$@"
