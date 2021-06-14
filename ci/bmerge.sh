#!/bin/bash

#set -e
#uxo
#mkdir $(pwd)/.build $(pwd)/.build/Debug $(pwd)/.build/obj
#chmod 777 $(pwd)/.build

echo ${CI_COMMIT_REF_NAME}
echo ${CI_MERGE_REQUEST_TARGET_BRANCH_NAME}

git status
commit_master=$(git show-ref | grep origin/${CI_MERGE_REQUEST_TARGET_BRANCH_NAME})
commit_branch=$(git merge-base origin/${CI_COMMIT_REF_NAME} origin/${CI_MERGE_REQUEST_TARGET_BRANCH_NAME})
#git log --pretty=format:"%s " --abbrev-commit origin/master..HEAD

echo "1. Ветка для слияния перемещена на вершину ветки ${CI_MERGE_REQUEST_TARGET_BRANCH_NAME}"
echo $commit_master
echo $commit_branch
#res_top=$(git merge-base --is-ancestor origin/master origin/${CI_COMMIT_REF_NAME})
#echo $res_top
git merge-base --is-ancestor origin/${CI_MERGE_REQUEST_TARGET_BRANCH_NAME} origin/${CI_COMMIT_REF_NAME}
if [ $? -ne 0 ]; then
    echo "Failed 1 - exit"
    exit 1
fi

echo "2. Имя ветки включает номер существующей задачи"
task_name=$(echo ${CI_COMMIT_REF_NAME} | awk -F "/" '{print $2}')
res_name=$(echo ${CI_COMMIT_REF_NAME} | grep -Eic "^.+/[a-z]{2,3}-[0-9]+" || true;)
#"^[a-z]{2,3}-[0-9]+ .+" || true;)
echo $res_name
if [ $res_name == 0 ]; then
    echo "Failed - exit" 
    exit 1
else 
    echo "It is Ok"
fi


echo "3. Все коммиты в ветке включают номер задачи"
#git log --pretty=format:"%s " --abbrev-commit origin/master..HEAD
#count_right=$(git log --pretty=format:"%s " --abbrev-commit origin/master..HEAD | grep -Eic "^[a-z]{2,3}-[0-9]+ .+" || true;)
count_right=$(git log --pretty=format:"%s " --abbrev-commit origin/${CI_MERGE_REQUEST_TARGET_BRANCH_NAME}..HEAD | grep -Eic $task_name || true;)
echo $count_right
count_all=$(git log --pretty=format:"%s " --abbrev-commit origin/${CI_MERGE_REQUEST_TARGET_BRANCH_NAME}..HEAD | grep -Eic ".+" || true;)
echo $count_all
if [ "$count_right" == "$count_all" ]; then 
    echo "It is Ok"
else 
    echo "Ошибка: имя задачи в коммите не соответсвует имени задачи в ветке"
    exit 1
fi

echo "4. Нет ни одного коммита с маркером WIP (Work in progress)"
if [ $(git log --pretty=format:"%s " --abbrev-commit origin/${CI_MERGE_REQUEST_TARGET_BRANCH_NAME}..HEAD | grep -ci "WIP" || true;) == "0" ]; then 
    echo "It is Ok" 
else 
    echo "Failed - exit"
    exit 1
fi

echo "5. Проект успешно собирается (dotnet build) без ошибок и предупреждений"
res_build=$(docker run --rm -v "$(pwd):/root/build" mcr.microsoft.com/dotnet/sdk:5.0-alpine dotnet build /root/build | grep -E "Error" | egrep -co "[0]")
echo $res_build

if [ $res_build == "1" ]; then
    echo "It is Ok" 
else 
    docker run --rm -v "$(pwd):/root/build" mcr.microsoft.com/dotnet/sdk:5.0-alpine dotnet build /root/build
    echo "Failed - exit"
    exit 1
fi
