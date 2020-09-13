#! /bin/bash

tmpfile=$(mktemp)

cat 日本語用語統一.txt | tr -d ' ' | gawk -f scripts/find-synonyms.awk > $tmpfile

# echo 以下の文字列と正規表現が含まれているか確認します。

# cat $tmpfile

if grep -n -f $tmpfile translation-ja/*.md
then
    echo
    echo 類似表現が含まれています。

    rm $tmpfile

    exit 1
fi

rm $tmpfile

exit 0
