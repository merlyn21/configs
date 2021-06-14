#!/bin/bash

GitVersion=$1

echo "$ProGetUrl/Erp/package/IntelKon.ERP/$GitVersion"

st=$(curl --head --silent $ProGetUrl/Erp/package/IntelKon.ERP/$GitVersion)
echo $st

status=$(echo $st | head -n 1 | grep -c 404)
echo $status

if [ "$status" == 1 ]; then
  echo "Start build .net"
  docker run --rm -v "$(pwd):/root/build" -w "/root/build" mcr.microsoft.com/dotnet/sdk:5.0-alpine dotnet publish Intelkon.Erp.Blazor.ServerSide --configuration Release -o pub -f net5.0
  rm -rf .build
  docker run --rm -v "$(pwd):/root/build" -w "/root/build/Intelkon.Erp.Blazor/client" node npm root
  res=$(echo $?)
   echo "$res - status npm root"
   if [ "$res" -ne 0 ]; then
    echo "Failed - exit"
    exit 1
   fi
  echo "Start npm install"
  docker run --rm -v "$(pwd):/root/build" -w "/root/build/Intelkon.Erp.Blazor/client" node npm install
  res=$(echo $?)
  echo "$res - status install"
  if [ "$res" -ne 0 ]; then
    echo "Failed - exit"
    exit 1
  fi
  echo "Start npm build"
  docker run --rm -v "$(pwd):/root/build" -w "/root/build/Intelkon.Erp.Blazor/client" node npm run build
  res=$(echo $?)
  echo "$res - status build"
  if [ "$res" -ne 0 ]; then
    echo "Failed - exit"
    exit 1
  fi
  echo "Build nuget"
  cp -R $(pwd)/Intelkon.Erp.Blazor.ServerSide/wwwroot/* $(pwd)/pub/wwwroot
  docker run --rm -v "$(pwd):/root/build" -w "/root/build" centeredge/nuget nuget pack erp.nuspec -Version $GitVersion -OutputDirectory publish -NoPackageAnalysis -NonInteractive -ForceEnglishOutput
  echo "Publish proget"
  docker run --rm -v "$(pwd):/root/build" -w "/root/build" centeredge/nuget nuget push publish/*.nupkg $ProGetKey -src $ProGetUrl/Erp -NonInteractive -ForceEnglishOutput
else
  echo "Packet exist: $status"
fi
