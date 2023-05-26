#!/bin/bash

vercomp() {
    if [[ $1 == $2 ]]; then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2
        fi
    done

    return 0
}

cleanver() {
    echo "$1" |
        sed 's/.el[0-9]_*/-/; s/.x86_64//g; s/\.centos//; s/-\./-/g; s/-/./g;'
}

preparever() {
    echo "$1" |
        sed 's/a/1/g; s/b/2/g; s/c/3/g; s/d/4/g; s/e/5/g; s/f/6/g; s/g/7/g; s/h/8/g; s/i/9/g; s/j/10/g; s/k/11/g; s/l/12/g; s/m/13/g;' |
        sed 's/n/14/g; s/o/15/g; s/p/16/g; s/q/17/g; s/r/18/g; s/s/19/g; s/t/20/g; s/u/21/g; s/v/22/g; s/w/23/g; s/x/24/g; s/y/25/g; s/z/26/g;' |
        sed 's/\.\.*/./g'
}

testvercomp() {
    p1=$(cleanver "$1")
    p2=$(cleanver "$2")
    if [ $(echo "$p1" | grep '-' | wc -l) -gt 0 ]; then
        local IFS='-'
        arr1=($p1)
        arr2=($p2)
        for ((i=${#arr1[@]}; i<${#arr2[@]}; i++)); do
            arr1[i]=0
        done

        i=0
        for p1 in "${arr1[@]}"; do
            p2="${arr2[$i]}"
            vercomp $(preparever "$p1") $(preparever "$p2")
            case $? in
                0) op='=';;
                1) op='>';;
                2) op='<';;
            esac
            if [[ $3 == "=" ]]; then
                if [[ $op != $3 ]]; then
                    echo "fail"
                    return
                fi
            else if [[ $op != "=" ]]; then
                if [[ $op != $3 ]]; then
                    echo "fail"
                else
                    echo "pass"
                fi
                return
            fi fi
            i=$(($i + 1))
        done
    else
        vercomp $(preparever "$p1") $(preparever "$p2")
        case $? in
            0) op='=';;
            1) op='>';;
            2) op='<';;
        esac
    fi

    if [[ $op != $3 ]]; then
        echo "fail"
    else
        echo "pass"
    fi
}

sortarray() {
    for ((i=0; i <= $((${#arr[@]} - 2)); ++i)); do
        for ((j=((i + 1)); j <= ((${#arr[@]} - 1)); ++j)); do
            res=$(testvercomp "${arr[i]}" "${arr[j]}" '<')
            if [[ $res == "pass" ]]; then
                tmp=${arr[i]}
                arr[i]=${arr[j]}
                arr[j]=$tmp
            fi
        done
    done
}

lastversion() {
    p="$1"
    arr=($(grep "^$p-[0-9]" ./rpm.list | sed "s/^$p-//; s/.i686//; s/.x86_64//"))
    if [ ${#arr[@]} -gt 1 ]; then
        sortarray "${arr[0]}"
    fi
    echo ${arr[0]}
}


if [ $(grep ' - ' ./packages | wc -l) -eq 0 ]; then
    echo "Check packages skipped"
    exit 0
fi

if [ $(cat /etc/*release* 2>/dev/null | grep '\(Red Hat Enterprise Linux\|CentOS Linux\)' | wc -l) -gt 0 ]; then
    rpm -aq | sort > ./rpm.list
else if [ $(cat /etc/*release* 2>/dev/null | grep '\(Ubuntu\|debian\)' | wc -l) -gt 0 ]; then
    dpkg-query -l | grep '^\S\S\s\s' | sed 's/^....//' | sed 's/\s\s*/-/; s/\s.*//; s/:amd64//;' > ./rpm.list
else
    > ./rpm.list
fi fi

cat ./packages |
    uniq |
    while read s; do
        if [ "x$s" == "x" ]; then
            continue
        fi
        p=$(echo "$s" | sed 's/ - .*//')
        v=$(echo "$s" | sed 's/.* - //')
        w=$(lastversion "$p")
        echo -n "$p $v / $w - "
        testvercomp $v $w '<'
    done 2>./packages.log |
    tee ./packages.out |
    grep -v pass

grep 'fail$' ./packages.out >/dev/null
if [ $? != 0 ]; then
    echo "All packages are actual"
fi

grep '^kernel\( \|-uek \)' ./packages.out | grep 'pass$' >/dev/null
if [ $? == 0 ]; then
    echo "Need reboot server before update kernel"
fi
