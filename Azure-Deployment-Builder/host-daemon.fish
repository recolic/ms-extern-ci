#!/usr/bin/fish
# daemon on host

# Should have permission to clone repo, read repo, download nuget package. 
# Personal-Access-Token, allow all read-only access. 
set devops_uname bensl
set devops_pswd (cat /home/recolic/scripts/ms-passwords/devops-password)
# Using GNU grep, allow basic regex. (I assume nobody place SPACE and origin/ in his branch name. )
set triggers master M365FleetAGC 'u/recolic/.*'
set webroot /var/www/html/externci

set tmpf /tmp/ms-externci-azdeploymentbuilder
test $devops_pswd = "" ; and echo "Please set devops_password" ; and exit 1

function dobuild
    set build_tag $args[1]
    sudo docker run -ti --rm -v (pwd)/..:/buildroot recolic/openxt bash /buildroot/guest-build.sh $devops_uname $devops_pswd
    and mv ../output.zip $webroot/AzDB.$build_tag.zip
end

test -d repo
    or git clone https://$devops_uname:$devops_pswd@msazure.visualstudio.com/DefaultCollection/One/_git/Azure-Deployment-Builder repo
cd repo

dobuild
while true
    # No error-crash in the loop.
    git fetch 2>&1 > $tmpf
    git reset --hard "@{upstream}"

    # dirty string processing
    for niddle in triggers
        # Each line in the hit, means a updated branch need to be built. 
        for line in (cat $tmpf | grep -E "origin/$niddle"'( |$)')
            set hit_brname (echo $line | sed 's/^.* origin\///g' | sed 's/ .*$//g')
            git checkout $hit_brname ; or continue
            set curr_hash (echo $line | sed 's/^[^\.]*\.\.\.*//g' | sed 's/ .*$//g')
            if test $curr_hash = ""
                # new branch
                set curr_hash (git rev-parse --short HEAD)
            end

            dobuild $hit_brname:$curr_hash
        end
    end

    sleep 60
end



    



# * [new branch]              u/liuyong/cmdletToCreateAccountAdmin -> origin/u/liuyong/cmdletToCreateAccountAdmin
# + 35d9e4838c6...5322513e658 u/qingche/AddModels0525 -> origin/u/qingche/AddModels0525  (forced update)
#   f9b0bf716bb..d2283f560b7  u/ricardoo/SyncDeploymentParterClusterAndAzureDbWorkflowBulkInsert -> origin/u/ricardoo/SyncDeploymentParterClusterAndAzureDbWorkflowBulkInsert

