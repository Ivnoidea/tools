#! /bin/bash
# 用于删除mvn的依赖包，减少不断增长的依赖包
# 将本文件放在 ~/.m2 下，然后执行即可
# 也可以放入crontab中，定时清理，示例如下：
# crontab -e
# 添加新任务：
#   # 每周一13点执行清理，清理日志为/tmp/clean_mvn.log
#   0 13 * * 1 cd ${HOME}/.m2 && sh clean_mvn.sh > /tmp/clean_mvn.log 2>&1

# 返回值 1: jar; 2: 依赖包（删除的单元）; 0: 其他
function findAndDel() {
    # 如果不是文件夹，返回是否jar
    if [[ -f $1 ]]; then
        if [[ $1 == *.jar ]]; then
            return 1 # 当前文件是jar
        fi

        return 0 # 当前不是jar和依赖包
    fi

    #保留版本个数，本地变量
    local remainCount=2
    # 遍历当前文件夹下的文件，按时间逆序
    for file in $(ls -t $1); do
        # 当前处理的目录，本地变量
        local curDir=$1"/"$file
        # 寻找和删除当前目录下的依赖包
        findAndDel $curDir
        ret=$? # 上一步函数调用的返回值

        # 如果当前文件是jar包，返回当前目录是依赖包
        if [[ $ret == 1 ]]; then
            return 2
        fi

        # 如果此目录是依赖包
        # 这里做了简化处理，每次都判断，避免出现预料外的case
        if [[ $ret == 2 ]]; then
            # 保留remainCount个最新版本
            if [[ $remainCount -gt 0 ]]; then
                echo "remain: "$curDir
            else
                # 删除依赖包
                echo "delete: "$curDir
                $(rm -rf $curDir)
            fi
            let remainCount--
        fi
    done

    return 0
}

# 如果参数没有传递目录，使用当前目录下指定两个目录扫描
if [ ! -n "$1" ]; then
    cleanPath=$(pwd)"/repository/com"
    echo "clean path: "$cleanPath
    findAndDel $cleanPath

    cleanPath=$(pwd)"/repository"
    echo "clean path: "$cleanPath
    findAndDel $cleanPath
else
    # 使用参数中的目录执行清理
    cleanPath=$1
    echo "clean path: "$cleanPath
    findAndDel $cleanPath
fi
