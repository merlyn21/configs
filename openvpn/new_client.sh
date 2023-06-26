#!/bin/bash

file_c="/opt/openvpn/count"

countf=`cat $file_c`
count=$(($countf+1))
`echo $count > $file_c`
echo $count

email="$1"

name=`echo "$email" | awk -F@ '{print $1}'`
namef="${name}_${count}"

echo $name
echo $email
echo $namef

docker-compose run --rm openvpn easyrsa build-client-full $namef nopass
docker-compose run --rm openvpn ovpn_getclient $namef > $namef.ovpn


if [ -f $namef.ovpn ]; then
  if [ -s $namef.ovpn ]; then

    sed -i -e "s/1194 tcp/443 tcp/g" $namef.ovpn
    echo "$namef.ovpn" >> journal.log
    python3 sendfile.py "$email" "$namef.ovpn"
    mv $namef.ovpn ./ovpn

  else
    echo "File's size is null"
  fi
else
  echo "File not found"
fi
