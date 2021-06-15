#!/bin/bash
# This script runs on guest, build the proj

nuget_uname="$1"
nuget_pswd="$2"
cd /buildroot/repo || exit $?
apt update && apt install -y zip || exit $?

#######################################
echo START sync

dotnet nuget add source "https://msazure.pkgs.visualstudio.com/one/_packaging/azure-deployment-builder-Consumption/nuget/v3/index.json" --name MSAZ --username "$nuget_uname" --password "$nuget_pswd" --store-password-in-clear-text &&
openxt sync --local-repo-dir ~/nuget-local-repo --project-dir src/Microsoft/Azure/Workflows/M365FleetAGC ||
exit $?

# The noob Microsoft.Azure.Cosmos.Table packager set the version to 0.0.0.0. Fuck you. 
echo START hotfix
echo '#!/bin/sh' > /usr/bin/xcopy && 
chmod +x /usr/bin/xcopy && 
nuget-download-package Microsoft.Azure.Cosmos.Table 1.0.6 ~/nuget-local-repo &&
rm -r ~/nuget-local-repo/microsoft.azure.cosmos.table/2.* ||
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
find Workflows/ -name '*.xaml' -exec cp '{}' ~/build-output/net472/ ';' &&
zip output.zip -r ~/build-output/net472/** &&
cp output.zip /buildroot/output.zip || 
exit $?

echo DONE


