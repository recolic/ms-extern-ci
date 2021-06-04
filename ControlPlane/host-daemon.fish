#!/usr/bin/fish
# daemon on host

# Should have permission to clone repo, read repo, download nuget package. 
# Personal-Access-Token, allow all read-only access. 
set devops_uname bensl
set devops_pswd (cat /home/recolic/scripts/ms-passwords/devops-password)
# Using GNU grep, allow basic regex. (I assume nobody place SPACE and origin/ in his branch name. )
set triggers M365FleetAGC '.*/(recolic)|(concao)|(shuxli)|(yeqwu)|(dennisxu)|(jihyan)|(liyang3)/.*'
set webroot /var/www/html/externci

set tmpf /tmp/ms-externci-controlplane
test $devops_pswd = "" ; and echo "Please set devops_password" ; and exit 1

function dobuild
    set build_tag CP.$argv[1]
    echo "Start building $build_tag at "(date --utc) >> $webroot/$build_tag.log
    sudo docker run --rm -v (pwd)/..:/buildroot recolic/openxt bash /buildroot/guest-build.sh $devops_uname $devops_pswd | tee --append $webroot/$build_tag.log
    and mv ../output.zip $webroot/$build_tag.zip
    and echo "Successfully built $build_tag at "(date --utc) >> $webroot/$build_tag.log
    or echo "Failed to build $build_tag at "(date --utc) >> $webroot/$build_tag.log
end

test -d repo
    or git clone https://$devops_uname:$devops_pswd@o365exchange.visualstudio.com/DefaultCollection/O365%20Core/_git/ControlPlane repo
cd repo

# dobuild (git branch --show-current):(git rev-parse --short HEAD)
while true
    # No error-crash in the loop.
    git fetch 2> $tmpf
    git reset --hard "@{upstream}"

    # dirty string processing
    for niddle in $triggers
        # Each line in the hit, means a updated branch need to be built. 
        for line in (cat $tmpf | grep -E "origin/$niddle"'( |$)')
            set hit_brname (echo $line | sed 's/^.* origin\///g' | sed 's/ .*$//g')
            git checkout $hit_brname ; or continue
            set curr_hash (echo $line | sed 's/^[^\.]*\.\.\.*//g' | sed 's/ .*$//g')
            if test $curr_hash = ""
                # new branch
                set curr_hash (git rev-parse --short HEAD)
            end

            dobuild (echo $hit_brname | tr / _):$curr_hash
        end
    end

    sleep 60
end



    



# * [new branch]              u/liuyong/cmdletToCreateAccountAdmin -> origin/u/liuyong/cmdletToCreateAccountAdmin
# + 35d9e4838c6...5322513e658 u/qingche/AddModels0525 -> origin/u/qingche/AddModels0525  (forced update)
#   f9b0bf716bb..d2283f560b7  u/ricardoo/SyncDeploymentParterClusterAndAzureDbWorkflowBulkInsert -> origin/u/ricardoo/SyncDeploymentParterClusterAndAzureDbWorkflowBulkInsert

