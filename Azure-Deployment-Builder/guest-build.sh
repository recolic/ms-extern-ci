#!/bin/bash
# This script runs on guest, build the proj

nuget_uname="$1"
nuget_pswd="$2"
cd /buildroot/repo || exit $?

#######################################
echo START sync

dotnet nuget add source "https://msazure.pkgs.visualstudio.com/one/_packaging/azure-deployment-builder-Consumption/nuget/v3/index.json" --name MSAZ --username "$nuget_uname" --password "$nuget_pswd" --store-password-in-clear-text &&
openxt sync --local-repo-dir ~/nuget-local-repo --project-dir src/Microsoft/Azure/Workflows/M365FleetAGC ||
exit $?

# The noob Microsoft.Azure.Cosmos.Table packager set the version to 0.0.0.0. Fuck you. 
echo START hotfix
nuget-download-package Microsoft.Azure.Cosmos.Table 1.0.6 ~/nuget-test-repo &&
rm -rf ~/nuget-test-repo/microsoft.azure.cosmos.table/2.0.0-preview ||
exit $?

#######################################
echo START build

cd src/Microsoft/Azure/Workflows/M365FleetAGC &&
source <(openxt env --local-repo-dir ~/nuget-local-repo --project-dir . --bin-dir ~/build-output --shell bash) &&
csproj-to-5 Activities/Activities.csproj &&
csproj-to-5 Workflows/Workflows.csproj &&
dotnet build Workflows/Workflows.csproj ||
exit $?

#######################################
echo START pack

rm -f ~/build-output/net472/*.pdb &&
cp Workflows/*.xaml ~/build-output/net472/ &&
zip output.zip ~/build-output/net472/** &&
cp output.zip /buildroot/output.zip || 
exit $?

echo DONE


