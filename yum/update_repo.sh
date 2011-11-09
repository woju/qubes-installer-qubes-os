#!/bin/sh


# $1 -- path to rpm dir
check_repo()
{
    if rpm --checksig $1/*.rpm | grep -v pgp > /dev/null ; then
        echo "ERROR: There are unsigned RPM packages in $1 repo:"
        echo "---------------------------------------"
        rpm --checksig $1/*.rpm | grep -v pgp 
        echo "---------------------------------------"
        echo "Sign them before proceeding."
        exit 1
    fi
}


update_repo()
{
    createrepo --update $1
}


for repo in dom0-updates installer qubes-dom0 ; do
    echo "--> Processing repo: $repo..."
    ls $repo/rpm/*.rpm 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "Empty repo, skipping..."
        continue
    fi
    if [ x$NO_SIGN != x"1" ]; then
        check_repo $repo/rpm -o $repo/repodata || continue
    fi
    update_repo $repo -o $repo/repodata
done

#yum clean metadata
