#!/bin/bash
# This script runs on guest, build the proj

nuget_uname="$1"
nuget_pswd="$2"
# fucking controlplane noob will boom the dotnet. DO NOT cd into it. 
cd /buildroot || exit $?
apt update && apt install -y zip || exit $?

#######################################
echo START sync

dotnet nuget add source "https://msazure.pkgs.visualstudio.com/_packaging/Official/nuget/v3/index.json" --name MSAZ --username "$nuget_uname" --password "$nuget_pswd" --store-password-in-clear-text &&
dotnet nuget add source "https://o365exchange.pkgs.visualstudio.com/_packaging/Common/nuget/v3/index.json" --name O365Core --username "$nuget_uname" --password "$nuget_pswd" --store-password-in-clear-text &&
dotnet nuget add source "https://skype.pkgs.visualstudio.com/DefaultCollection/_packaging/csc/nuget/v3/index.json" --name Skype --username "$nuget_uname" --password "$nuget_pswd" --store-password-in-clear-text &&
dotnet nuget add source "https://o365exchange.pkgs.visualstudio.com/959adb23-f323-4d52-8203-ff34e5cbeefa/_packaging/M365FleetAGC/nuget/v3/index.json" --name M365FleetAGC --username "$nuget_uname" --password "$nuget_pswd" --store-password-in-clear-text &&
openxt sync --local-repo-dir ~/nuget-local-repo --project-dir repo/sources/dev/FleetAGC/src ||
exit $?

#######################################
echo START build AzureToolkit

mv repo/sources/dev/FleetAGC/src/AzureToolKit ~ && cd ~/AzureToolKit &&
source <(openxt env --local-repo-dir ~/nuget-local-repo --project-dir . --bin-dir ~/build-output --shell bash) &&
csproj-to-5 *.csproj &&
dotnet pack ||
exit $?

echo DONE


