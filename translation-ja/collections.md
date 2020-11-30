# コレクション

- [イントロダクション](#introduction)
    - [コレクション生成](#creating-collections)
    - [コレクションの拡張](#extending-collections)
- [利用可能なメソッド](#available-methods)
- [Higher Order Message](#higher-order-messages)
- [レイジーコレクション](#lazy-collections)
    - [イントロダクション](#lazy-collection-introduction)
    - [レイジーコレクションの生成](#creating-lazy-collections)
    - [Enumerable契約](#the-enumerable-contract)
    - [レイジーコレクションメソッド](#lazy-collection-methods)

<a name="introduction"></a>
## イントロダクション

`Illuminate\Support\Collection`クラスは配列データを操作するための、書きやすく使いやすいラッパーです。以下の例をご覧ください。配列から新しいコレクションインスタンスを作成するために`collect`ヘルパを使用し、各要素に対し`strtoupper`を実行し、それから空の要素を削除しています。

    $collection = collect(['taylor', 'abigail', null])->map(function ($name) {
        return strtoupper($name);
    })
    ->reject(function ($name) {
        return empty($name);
    });

ご覧の通り、`Collection`クラスは裏にある配列をマップ操作してから要素削除するメソッドをチェーンでスムーズにつなげてくれます。つまり元のコレクションは不変であり、すべての`Collection`メソッドは新しい`Collection`インスタンスを返します。

<a name="creating-collections"></a>
### コレクション生成

上記の通り`collect`ヘルパは指定された配列を元に、新しい`Illuminate\Support\Collection`インスタンスを返します。ですからコレクションの生成も同様にシンプルです。

    $collection = collect([1, 2, 3]);

> {tip} [Eloquent](/docs/{{version}}/eloquent)クエリの結果は、常に`Collection`インスタンスを返します。

<a name="extending-collections"></a>
### コレクションの拡張

実行時に`Collection`クラスメソッドを追加できるように、コレクションは「マクロ使用可能」です。例として、`Collection`クラスへ`toUpper`メソッドを追加してみましょう。

    use Illuminate\Support\Collection;
    use Illuminate\Support\Str;

    Collection::macro('toUpper', function () {
        return $this->map(function ($value) {
            return Str::upper($value);
        });
    });

    $collection = collect(['first', 'second']);

    $upper = $collection->toUpper();

    // ['FIRST', 'SECOND']

通常、[サービスプロバイダ](/docs/{{version}}/providers)の中で、コレクションマクロを定義します。

<a name="available-methods"></a>
## 利用可能なメソッド

このドキュメントの残りで、`Collection`クラスで使用できる各メソッドを解説します。これらのメソッドは、すべて裏の配列をスラスラと操作するためにチェーンで繋げられることを覚えておきましょう。また、ほとんどのメソッドは新しい`Collection`インスタンスを返しますので、必要であればコレクションのオリジナルコピーを利用できるように変更しません。

<style>
    #collection-method-list > p {
        column-count: 3; -moz-column-count: 3; -webkit-column-count: 3;
        column-gap: 2em; -moz-column-gap: 2em; -webkit-column-gap: 2em;
    }

    #collection-method-list a {
        display: block;
    }
</style>

<div id="collection-method-list" markdown="1">

[all](#method-all)
[average](#method-average)
[avg](#method-avg)
[chunk](#method-chunk)
[chunkWhile](#method-chunkwhile)
[collapse](#method-collapse)
[collect](#method-collect)
[combine](#method-combine)
[concat](#method-concat)
[contains](#method-contains)
[containsStrict](#method-containsstrict)
[count](#method-count)
[countBy](#method-countBy)
[crossJoin](#method-crossjoin)
[dd](#method-dd)
[diff](#method-diff)
[diffAssoc](#method-diffassoc)
[diffKeys](#method-diffkeys)
[dump](#method-dump)
[duplicates](#method-duplicates)
[duplicatesStrict](#method-duplicatesstrict)
[each](#method-each)
[eachSpread](#method-eachspread)
[every](#method-every)
[except](#method-except)
[filter](#method-filter)
[first](#method-first)
[firstWhere](#method-first-where)
[flatMap](#method-flatmap)
[flatten](#method-flatten)
[flip](#method-flip)
[forget](#method-forget)
[forPage](#method-forpage)
[get](#method-get)
[groupBy](#method-groupby)
[has](#method-has)
[implode](#method-implode)
[intersect](#method-intersect)
[intersectByKeys](#method-intersectbykeys)
[isEmpty](#method-isempty)
[isNotEmpty](#method-isnotempty)
[join](#method-join)
[keyBy](#method-keyby)
[keys](#method-keys)
[last](#method-last)
[macro](#method-macro)
[make](#method-make)
[map](#method-map)
[mapInto](#method-mapinto)
[mapSpread](#method-mapspread)
[mapToGroups](#method-maptogroups)
[mapWithKeys](#method-mapwithkeys)
[max](#method-max)
[median](#method-median)
[merge](#method-merge)
[mergeRecursive](#method-mergerecursive)
[min](#method-min)
[mode](#method-mode)
[nth](#method-nth)
[only](#method-only)
[pad](#method-pad)
[partition](#method-partition)
[pipe](#method-pipe)
[pipeInto](#method-pipeinto)
[pluck](#method-pluck)
[pop](#method-pop)
[prepend](#method-prepend)
[pull](#method-pull)
[push](#method-push)
[put](#method-put)
[random](#method-random)
[reduce](#method-reduce)
[reject](#method-reject)
[replace](#method-replace)
[replaceRecursive](#method-replacerecursive)
[reverse](#method-reverse)
[search](#method-search)
[shift](#method-shift)
[shuffle](#method-shuffle)
[skip](#method-skip)
[skipUntil](#method-skipuntil)
[skipWhile](#method-skipwhile)
[slice](#method-slice)
[some](#method-some)
[sort](#method-sort)
[sortBy](#method-sortby)
[sortByDesc](#method-sortbydesc)
[sortDesc](#method-sortdesc)
[sortKeys](#method-sortkeys)
[sortKeysDesc](#method-sortkeysdesc)
[splice](#method-splice)
[split](#method-split)
[splitIn](#method-splitin)
[sum](#method-sum)
[take](#method-take)
[takeUntil](#method-takeuntil)
[takeWhile](#method-takewhile)
[tap](#method-tap)
[times](#method-times)
[toArray](#method-toarray)
[toJson](#method-tojson)
[transform](#method-transform)
[union](#method-union)
[unique](#method-unique)
[uniqueStrict](#method-uniquestrict)
[unless](#method-unless)
[unlessEmpty](#method-unlessempty)
[unlessNotEmpty](#method-unlessnotempty)
[unwrap](#method-unwrap)
[values](#method-values)
[when](#method-when)
[whenEmpty](#method-whenempty)
[whenNotEmpty](#method-whennotempty)
[where](#method-where)
[whereStrict](#method-wherestrict)
[whereBetween](#method-wherebetween)
[whereIn](#method-wherein)
[whereInStrict](#method-whereinstrict)
[whereInstanceOf](#method-whereinstanceof)
[whereNotBetween](#method-wherenotbetween)
[whereNotIn](#method-wherenotin)
[whereNotInStrict](#method-wherenotinstrict)
[whereNotNull](#method-wherenotnull)
[whereNull](#method-wherenull)
[wrap](#method-wrap)
[zip](#method-zip)

</div>

<a name="method-listing"></a>
## メソッド一覧

<style>
    #collection-method code {
        font-size: 14px;
    }

    #collection-method:not(.first-collection-method) {
        margin-top: 50px;
    }
</style>

<a name="method-all"></a>
#### `all()` {#collection-method .first-collection-method}

`all`メソッドはコレクションの裏の配列表現を返します。

    collect([1, 2, 3])->all();

    // [1, 2, 3]

<a name="method-average"></a>
#### `average()` {#collection-method}

[`avg`](#method-avg)メソッドのエイリアスです。

<a name="method-avg"></a>
#### `avg()` {#collection-method}

`avg`メソッドは、指定したキーの[平均値](https://ja.wikipedia.org/wiki/%E5%B9%B3%E5%9D%87)を返します。

    $average = collect([['foo' => 10], ['foo' => 10], ['foo' => 20], ['foo' => 40]])->avg('foo');

    // 20

    $average = collect([1, 1, 2, 4])->avg();

    // 2

<a name="method-chunk"></a>
#### `chunk()` {#collection-method}

`chunk`メソッドはコレクションを指定したサイズで複数の小さなコレクションに分割します。

    $collection = collect([1, 2, 3, 4, 5, 6, 7]);

    $chunks = $collection->chunk(4);

    $chunks->all();

    // [[1, 2, 3, 4], [5, 6, 7]]

このメソッドはとくに[Bootstrap](https://getbootstrap.com/docs/4.1/layout/grid)のようなグリッドシステムを[ビュー](/docs/{{version}}/views)で操作する場合に便利です。[Eloquent](/docs/{{version}}/eloquent)モデルのコレクションがあり、グリッドで表示しようとしているところを想像してください。

    @foreach ($products->chunk(3) as $chunk)
        <div class="row">
            @foreach ($chunk as $product)
                <div class="col-xs-4">{{ $product->name }}</div>
            @endforeach
        </div>
    @endforeach

<a name="method-chunkwhile"></a>
#### `chunkWhile()` {#collection-method}

`chunkWhile`メソッドはコレクションを指定したコールバックの評価に基づいた複数の小さなコレクションへ分割します。

    $collection = collect(str_split('AABBCCCD'));

    $chunks = $collection->chunkWhile(function ($current, $key, $chunk) {
        return $current === $chunk->last();
    });

    $chunks->all();

    // [['A', 'A'], ['B', 'B'], ['C', 'C', 'C'], ['D']]

<a name="method-collapse"></a>
#### `collapse()` {#collection-method}

`collapse`メソッドは、配列のコレクションをフラットな一次コレクションに展開します。

    $collection = collect([[1, 2, 3], [4, 5, 6], [7, 8, 9]]);

    $collapsed = $collection->collapse();

    $collapsed->all();

    // [1, 2, 3, 4, 5, 6, 7, 8, 9]

<a name="method-combine"></a>
#### `combine()` {#collection-method}

`combine`メソッドは、コレクションの値をキーとして、他の配列かコレクションの値を結合します。

    $collection = collect(['name', 'age']);

    $combined = $collection->combine(['George', 29]);

    $combined->all();

    // ['name' => 'George', 'age' => 29]

<a name="method-collect"></a>
#### `collect()` {#collection-method}

`collect`メソッドは、コレクション中の現在のアイテムを利用した、新しい`Collection`インスタンスを返します。

    $collectionA = collect([1, 2, 3]);

    $collectionB = $collectionA->collect();

    $collectionB->all();

    // [1, 2, 3]

`collect`メソッドは、[レイジーコレクション](#lazy-collections)を通常の`Collection`インスタンスへ変換するのにとくに便利です。

    $lazyCollection = LazyCollection::make(function () {
        yield 1;
        yield 2;
        yield 3;
    });

    $collection = $lazyCollection->collect();

    get_class($collection);

    // 'Illuminate\Support\Collection'

    $collection->all();

    // [1, 2, 3]

> {tip} `collect`メソッドは`Enumerable`のインスタンスがあり、それをレイジーコレクションでなくする必要がある場合、とくに便利です。`collect()`は`Enumerable`契約の一部であり、`Collection`インスタンスを取得するため安全に使用できます。

<a name="method-concat"></a>
#### `concat()` {#collection-method}

`concat`メソッドは、指定した「配列」やコレクションの値を元のコレクションの最後に追加します。

    $collection = collect(['John Doe']);

    $concatenated = $collection->concat(['Jane Doe'])->concat(['name' => 'Johnny Doe']);

    $concatenated->all();

    // ['John Doe', 'Jane Doe', 'Johnny Doe']

<a name="method-contains"></a>
#### `contains()` {#collection-method}

`contains`メソッドは指定したアイテムがコレクションに含まれているかどうかを判定します。

    $collection = collect(['name' => 'Desk', 'price' => 100]);

    $collection->contains('Desk');

    // true

    $collection->contains('New York');

    // false

さらに`contains`メソッドにはキー／値ペアを指定することもでき、コレクション中に指定したペアが存在するかを確認できます。

    $collection = collect([
        ['product' => 'Desk', 'price' => 200],
        ['product' => 'Chair', 'price' => 100],
    ]);

    $collection->contains('product', 'Bookcase');

    // false

最後に、`contains`メソッドにはコールバックを渡すこともでき、独自のテストを行えます。

    $collection = collect([1, 2, 3, 4, 5]);

    $collection->contains(function ($value, $key) {
        return $value > 5;
    });

    // false

`contains`メソッドは、アイテムを「緩く」比較します。つまり、ある整数の文字列とその整数値は等値として扱います。「厳密」な比較を行いたい場合は、[`containsStrict`](#method-containsstrict)メソッドを使ってください。

<a name="method-containsstrict"></a>
#### `containsStrict()` {#collection-method}

このメソッドは、[`contains`](#method-contains)メソッドと使用方法は同じです。しかし、「厳密」な値の比較を行います。

> {tip} [Eloquentコレクション](/docs/{{version}}/eloquent-collections#method-contains)の使用時は、このメソッドの振る舞いは変わります。

<a name="method-count"></a>
#### `count()` {#collection-method}

`count`メソッドはコレクションのアイテム数を返します。

    $collection = collect([1, 2, 3, 4]);

    $collection->count();

    // 4

<a name="method-countBy"></a>
#### `countBy()` {#collection-method}

`countBy`メソッドはコレクションに出現する値をカウントします。デフォルトでこのメソッドは、出現するすべての要素をカウントします。

    $collection = collect([1, 2, 2, 2, 3]);

    $counted = $collection->countBy();

    $counted->all();

    // [1 => 1, 2 => 3, 3 => 1]

`countBy`へコールバックを渡した場合は、カスタム値の全アイテムをカウントします。

    $collection = collect(['alice@gmail.com', 'bob@yahoo.com', 'carlos@gmail.com']);

    $counted = $collection->countBy(function ($email) {
        return substr(strrchr($email, "@"), 1);
    });

    $counted->all();

    // ['gmail.com' => 2, 'yahoo.com' => 1]

<a name="method-crossjoin"></a>
#### `crossJoin()` {#collection-method}

`crossJoin`メソッドはコレクションの値と、指定した配列かコレクション間の値を交差接続し、可能性のある全順列の直積を返します。

    $collection = collect([1, 2]);

    $matrix = $collection->crossJoin(['a', 'b']);

    $matrix->all();

    /*
        [
            [1, 'a'],
            [1, 'b'],
            [2, 'a'],
            [2, 'b'],
        ]
    */

    $collection = collect([1, 2]);

    $matrix = $collection->crossJoin(['a', 'b'], ['I', 'II']);

    $matrix->all();

    /*
        [
            [1, 'a', 'I'],
            [1, 'a', 'II'],
            [1, 'b', 'I'],
            [1, 'b', 'II'],
            [2, 'a', 'I'],
            [2, 'a', 'II'],
            [2, 'b', 'I'],
            [2, 'b', 'II'],
        ]
    */

<a name="method-dd"></a>
#### `dd()` {#collection-method}

`dd`メソッドはコレクションアイテムをダンプし、スクリプトの実行を停止します。

    $collection = collect(['John Doe', 'Jane Doe']);

    $collection->dd();

    /*
        Collection {
            #items: array:2 [
                0 => "John Doe"
                1 => "Jane Doe"
            ]
        }
    */

スクリプトの実行を止めたくない場合は、[`dump`](#method-dump)メソッドを代わりに使用してください。

<a name="method-diff"></a>
#### `diff()` {#collection-method}

`diff`メソッドはコレクションと、他のコレクションか一次元「配列」を値にもとづき比較します。このメソッドは指定されたコレクションに存在しない、オリジナルのコレクションの値を返します。

    $collection = collect([1, 2, 3, 4, 5]);

    $diff = $collection->diff([2, 4, 6, 8]);

    $diff->all();

    // [1, 3, 5]

> {tip} [Eloquentコレクション](/docs/{{version}}/eloquent-collections#method-contains)の使用時は、このメソッドの振る舞いは変わります。

<a name="method-diffassoc"></a>
#### `diffAssoc()` {#collection-method}

`diffAssoc`メソッドはコレクションと、他のコレクションかキー／値形式のPHP配列を比較します。このメソッドは指定したコレクションに含まれない、オリジナルコレクション中のキー／値ペアを返します。

    $collection = collect([
        'color' => 'orange',
        'type' => 'fruit',
        'remain' => 6,
    ]);

    $diff = $collection->diffAssoc([
        'color' => 'yellow',
        'type' => 'fruit',
        'remain' => 3,
        'used' => 6,
    ]);

    $diff->all();

    // ['color' => 'orange', 'remain' => 6]

<a name="method-diffkeys"></a>
#### `diffKeys()` {#collection-method}

`diffKeys`メソッドはコレクションと、他のコレクションか一次元「配列」をキーで比較します。このメソッドは指定したコレクションに存在しない、オリジナルコレクション中のキー／値ペアを返します。

    $collection = collect([
        'one' => 10,
        'two' => 20,
        'three' => 30,
        'four' => 40,
        'five' => 50,
    ]);

    $diff = $collection->diffKeys([
        'two' => 2,
        'four' => 4,
        'six' => 6,
        'eight' => 8,
    ]);

    $diff->all();

    // ['one' => 10, 'three' => 30, 'five' => 50]

<a name="method-dump"></a>
#### `dump()` {#collection-method}

`dump`メソッドはコレクションアイテムをダンプします。

    $collection = collect(['John Doe', 'Jane Doe']);

    $collection->dump();

    /*
        Collection {
            #items: array:2 [
                0 => "John Doe"
                1 => "Jane Doe"
            ]
        }
    */

コレクションをダンプした後にスクリプトを停止したい場合は、代わりに[`dd`](#method-dd)メソッドを使用してください。

<a name="method-duplicates"></a>
#### `duplicates()` {#collection-method}

`duplicates`メソッドはコレクション中の重複値を返します。

    $collection = collect(['a', 'b', 'a', 'c', 'b']);

    $collection->duplicates();

    // [2 => 'a', 4 => 'b']

コレクションが配列やオブジェクトを含む場合は、値の重複を調べたい属性のキーを渡せます。

    $employees = collect([
        ['email' => 'abigail@example.com', 'position' => 'Developer'],
        ['email' => 'james@example.com', 'position' => 'Designer'],
        ['email' => 'victoria@example.com', 'position' => 'Developer'],
    ])

    $employees->duplicates('position');

    // [2 => 'Developer']

<a name="method-duplicatesstrict"></a>
#### `duplicatesStrict()` {#collection-method}

このメソッドの使い方は[`duplicates`](#method-duplicates)メソッドと同じですが、すべての値に「厳密な」比較が行われます。

<a name="method-each"></a>
#### `each()` {#collection-method}

`each`メソッドはコレクションのアイテムを繰り返しで処理し、コールバックに各アイテムを渡します。

    $collection->each(function ($item, $key) {
        //
    });

アイテム全体への繰り返しを停止したい場合は、`false`をコールバックから返してください。

    $collection->each(function ($item, $key) {
        if (/* 条件 */) {
            return false;
        }
    });

<a name="method-eachspread"></a>
#### `eachSpread()` {#collection-method}

`eachSpread`メソッドはコレクションのアイテムに対し、指定したコールバックへネストしたアイテム値をそれぞれ渡し、繰り返し処理します。

    $collection = collect([['John Doe', 35], ['Jane Doe', 33]]);

    $collection->eachSpread(function ($name, $age) {
        //
    });

アイテムに対する繰り返しを停止したい場合は、コールバックから`false`を返します。

    $collection->eachSpread(function ($name, $age) {
        return false;
    });

<a name="method-every"></a>
#### `every()` {#collection-method}

`every`メソッドは、コレクションの全要素が、指定したテストをパスするか判定するために使用します。

    collect([1, 2, 3, 4])->every(function ($value, $key) {
        return $value > 2;
    });

    // false

コレクションが空の場合、`every`はtrueを返します。

    $collection = collect([]);

    $collection->every(function ($value, $key) {
        return $value > 2;
    });

    // true

<a name="method-except"></a>
#### `except()` {#collection-method}

`except`メソッドは、キーにより指定したアイテム以外の全コレクション要素を返します。

    $collection = collect(['product_id' => 1, 'price' => 100, 'discount' => false]);

    $filtered = $collection->except(['price', 'discount']);

    $filtered->all();

    // ['product_id' => 1]

`except`の正反対の機能は、[only](#method-only)メソッドです。

> {tip} [Eloquentコレクション](/docs/{{version}}/eloquent-collections#method-contains)の使用時は、このメソッドの振る舞いは変わります。

<a name="method-filter"></a>
#### `filter()` {#collection-method}

`filter`メソッドは指定したコールバックでコレクションをフィルタリングします。テストでtrueを返したアイテムだけが残ります。

    $collection = collect([1, 2, 3, 4]);

    $filtered = $collection->filter(function ($value, $key) {
        return $value > 2;
    });

    $filtered->all();

    // [3, 4]

コールバックを指定しない場合、コレクションの全エンティティの中で、`false`として評価されるものを削除します。

    $collection = collect([1, 2, 3, null, false, '', 0, []]);

    $collection->filter()->all();

    // [1, 2, 3]

`filter`の逆の動作は、[reject](#method-reject)メソッドを見てください。

<a name="method-first"></a>
#### `first()` {#collection-method}

`first`メソッドは指定された真偽テストをパスしたコレクションの最初の要素を返します。

    collect([1, 2, 3, 4])->first(function ($value, $key) {
        return $value > 2;
    });

    // 3

`first`メソッドに引数を付けなければ、コレクションの最初の要素を取得できます。コレクションが空なら`null`を返します。

    collect([1, 2, 3, 4])->first();

    // 1

<a name="method-first-where"></a>
#### `firstWhere()` {#collection-method}

`firstWhere`メソッドはコレクションの中から、最初の指定したキー／値ペアの要素を返します。

    $collection = collect([
        ['name' => 'Regena', 'age' => null],
        ['name' => 'Linda', 'age' => 14],
        ['name' => 'Diego', 'age' => 23],
        ['name' => 'Linda', 'age' => 84],
    ]);

    $collection->firstWhere('name', 'Linda');

    // ['name' => 'Linda', 'age' => 14]

比較演算子を指定し、`firstWhere`メソッドを呼び出すこともできます。

    $collection->firstWhere('age', '>=', 18);

    // ['name' => 'Diego', 'age' => 23]

[where](#method-where)メソッドと同様に、`firstWhere`メソッドへ一つの引数を渡せます。その場合、`firstWhere`メソッドは、指定したアイテムキー値が「真と見なせる」最初のアイテムを返します。

    $collection->firstWhere('age');

    // ['name' => 'Linda', 'age' => 14]

<a name="method-flatmap"></a>
#### `flatMap()` {#collection-method}

`flatMap`メソッドはそれぞれの値をコールバックへ渡しながら、コレクション全体を繰り返し処理します。コールバックでは自由にアイテムの値を変更し、それを返します。その値へ更新した新しいコレクションを作成します。配列は一次元になります。

    $collection = collect([
        ['name' => 'Sally'],
        ['school' => 'Arkansas'],
        ['age' => 28]
    ]);

    $flattened = $collection->flatMap(function ($values) {
        return array_map('strtoupper', $values);
    });

    $flattened->all();

    // ['name' => 'SALLY', 'school' => 'ARKANSAS', 'age' => '28'];

<a name="method-flatten"></a>
#### `flatten()` {#collection-method}

`flatten`メソッドは多次元コレクションを一次元化します。

    $collection = collect(['name' => 'taylor', 'languages' => ['php', 'javascript']]);

    $flattened = $collection->flatten();

    $flattened->all();

    // ['taylor', 'php', 'javascript'];

このメソッドでは、いくつ配列の次元を減らすかを引数で指定できます。

    $collection = collect([
        'Apple' => [
            ['name' => 'iPhone 6S', 'brand' => 'Apple'],
        ],
        'Samsung' => [
            ['name' => 'Galaxy S7', 'brand' => 'Samsung'],
        ],
    ]);

    $products = $collection->flatten(1);

    $products->values()->all();

    /*
        [
            ['name' => 'iPhone 6S', 'brand' => 'Apple'],
            ['name' => 'Galaxy S7', 'brand' => 'Samsung'],
        ]
    */

上記の例で、`flatten`を次元の指定なしで呼び出すと、ネスト配列をフラットにしますので、結果は`['iPhone 6S', 'Apple', 'Galaxy S7', 'Samsung']`になります。次元を指定すると、配列のネストをそのレベルに制約し、減らします。

<a name="method-flip"></a>
#### `flip()` {#collection-method}

`flip`メソッドはコレクションのキーと対応する値を入れ替えます。

    $collection = collect(['name' => 'taylor', 'framework' => 'laravel']);

    $flipped = $collection->flip();

    $flipped->all();

    // ['taylor' => 'name', 'laravel' => 'framework']

<a name="method-forget"></a>
#### `forget()` {#collection-method}

`forget`メソッドはキーによりコレクションのアイテムを削除します。

    $collection = collect(['name' => 'taylor', 'framework' => 'laravel']);

    $collection->forget('name');

    $collection->all();

    // ['framework' => 'laravel']

> {note} 他のコレクションメソッドとは異なり、`forget`は更新された新しいコレクションを返しません。呼び出しもとのコレクションを更新します。

<a name="method-forpage"></a>
#### `forPage()` {#collection-method}

`forPage`メソッドは指定されたページ番号を表すアイテムで構成された新しいコレクションを返します。このメソッドは最初の引数にページ番号、２つ目の引数としてページあたりのアイテム数を受け取ります。

    $collection = collect([1, 2, 3, 4, 5, 6, 7, 8, 9]);

    $chunk = $collection->forPage(2, 3);

    $chunk->all();

    // [4, 5, 6]

<a name="method-get"></a>
#### `get()` {#collection-method}

`get`メソッドは指定されたキーのアイテムを返します。キーが存在していない場合は`null`を返します。

    $collection = collect(['name' => 'taylor', 'framework' => 'laravel']);

    $value = $collection->get('name');

    // taylor

オプションとして第２引数にデフォルト値を指定することもできます。

    $collection = collect(['name' => 'taylor', 'framework' => 'laravel']);

    $value = $collection->get('foo', 'default-value');

    // default-value

デフォルト値にコールバックを渡すこともできます。指定したキーが存在していなかった場合、コールバックの結果が返されます。

    $collection->get('email', function () {
        return 'default-value';
    });

    // default-value

<a name="method-groupby"></a>
#### `groupBy()` {#collection-method}

`groupBy`メソッドは指定したキーによりコレクションのアイテムをグループにまとめます。

    $collection = collect([
        ['account_id' => 'account-x10', 'product' => 'Chair'],
        ['account_id' => 'account-x10', 'product' => 'Bookcase'],
        ['account_id' => 'account-x11', 'product' => 'Desk'],
    ]);

    $grouped = $collection->groupBy('account_id');

    $grouped->all();

    /*
        [
            'account-x10' => [
                ['account_id' => 'account-x10', 'product' => 'Chair'],
                ['account_id' => 'account-x10', 'product' => 'Bookcase'],
            ],
            'account-x11' => [
                ['account_id' => 'account-x11', 'product' => 'Desk'],
            ],
        ]
    */

文字列で`key`を指定する代わりに、コールバックを渡すことができます。コールバックはグループとしてまとめるキーの値を返す必要があります。

    $grouped = $collection->groupBy(function ($item, $key) {
        return substr($item['account_id'], -3);
    });

    $grouped->all();

    /*
        [
            'x10' => [
                ['account_id' => 'account-x10', 'product' => 'Chair'],
                ['account_id' => 'account-x10', 'product' => 'Bookcase'],
            ],
            'x11' => [
                ['account_id' => 'account-x11', 'product' => 'Desk'],
            ],
        ]
    */

配列として、複数のグルーピング基準を指定できます。各配列要素は多次元配列の対応するレベルへ適用されます。

    $data = new Collection([
        10 => ['user' => 1, 'skill' => 1, 'roles' => ['Role_1', 'Role_3']],
        20 => ['user' => 2, 'skill' => 1, 'roles' => ['Role_1', 'Role_2']],
        30 => ['user' => 3, 'skill' => 2, 'roles' => ['Role_1']],
        40 => ['user' => 4, 'skill' => 2, 'roles' => ['Role_2']],
    ]);

    $result = $data->groupBy([
        'skill',
        function ($item) {
            return $item['roles'];
        },
    ], $preserveKeys = true);

    /*
    [
        1 => [
            'Role_1' => [
                10 => ['user' => 1, 'skill' => 1, 'roles' => ['Role_1', 'Role_3']],
                20 => ['user' => 2, 'skill' => 1, 'roles' => ['Role_1', 'Role_2']],
            ],
            'Role_2' => [
                20 => ['user' => 2, 'skill' => 1, 'roles' => ['Role_1', 'Role_2']],
            ],
            'Role_3' => [
                10 => ['user' => 1, 'skill' => 1, 'roles' => ['Role_1', 'Role_3']],
            ],
        ],
        2 => [
            'Role_1' => [
                30 => ['user' => 3, 'skill' => 2, 'roles' => ['Role_1']],
            ],
            'Role_2' => [
                40 => ['user' => 4, 'skill' => 2, 'roles' => ['Role_2']],
            ],
        ],
    ];
    */

<a name="method-has"></a>
#### `has()` {#collection-method}

`has`メソッドは指定したキーがコレクションに存在しているかを調べます。

    $collection = collect(['account_id' => 1, 'product' => 'Desk', 'amount' => 5]);

    $collection->has('product');

    // true

    $collection->has(['product', 'amount']);

    // true

    $collection->has(['amount', 'price']);

    // false

<a name="method-implode"></a>
#### `implode()` {#collection-method}

`implode`メソッドはコレクションのアイテムを結合します。引数はコレクションのアイテムのタイプにより異なります。 コレクションに配列化オブジェクトが含まれている場合は、接続したい属性のキーと値の間にはさみたい「糊」の役割の文字列を指定します。

    $collection = collect([
        ['account_id' => 1, 'product' => 'Desk'],
        ['account_id' => 2, 'product' => 'Chair'],
    ]);

    $collection->implode('product', ', ');

    // Desk, Chair

コレクションが文字列か数値を含んでいるだけなら、メソッドには「糊」の文字列を渡すだけで済みます。

    collect([1, 2, 3, 4, 5])->implode('-');

    // '1-2-3-4-5'

<a name="method-intersect"></a>
#### `intersect()` {#collection-method}

`intersect`メソッドは、指定した「配列」かコレクションに存在していない値をオリジナルコレクションから取り除きます。結果のコレクションには、オリジナルコレクションのキーがリストされます。

    $collection = collect(['Desk', 'Sofa', 'Chair']);

    $intersect = $collection->intersect(['Desk', 'Chair', 'Bookcase']);

    $intersect->all();

    // [0 => 'Desk', 2 => 'Chair']

> {tip} [Eloquentコレクション](/docs/{{version}}/eloquent-collections#method-contains)の使用時は、このメソッドの振る舞いは変わります。

<a name="method-intersectbykeys"></a>
#### `intersectByKeys()` {#collection-method}

`intersectByKeys`メソッドは、指定した配列かコレクションに含まれないキーの要素をオリジナルコレクションから削除します。

    $collection = collect([
        'serial' => 'UX301', 'type' => 'screen', 'year' => 2009,
    ]);

    $intersect = $collection->intersectByKeys([
        'reference' => 'UX404', 'type' => 'tab', 'year' => 2011,
    ]);

    $intersect->all();

    // ['type' => 'screen', 'year' => 2009]

<a name="method-isempty"></a>
#### `isEmpty()` {#collection-method}

`isEmpty`メソッドはコレクションが空の場合に`true`を返します。そうでなければ`false`を返します。

    collect([])->isEmpty();

    // true

<a name="method-isnotempty"></a>
#### `isNotEmpty()` {#collection-method}

`isNotEmpty`メソッドは、コレクションが空でない場合に`true`を返します。空であれば`false`を返します。

    collect([])->isNotEmpty();

    // false

<a name="method-join"></a>
#### `join()` {#collection-method}

`join`メソッドは、コレクションの値を文字列で結合します。

    collect(['a', 'b', 'c'])->join(', '); // 'a, b, c'
    collect(['a', 'b', 'c'])->join(', ', ', and '); // 'a, b, and c'
    collect(['a', 'b'])->join(', ', ' and '); // 'a and b'
    collect(['a'])->join(', ', ' and '); // 'a'
    collect([])->join(', ', ' and '); // ''

<a name="method-keyby"></a>
#### `keyBy()` {#collection-method}

`keyBy`メソッドは指定したキーをコレクションのキーにします。複数のアイテムが同じキーを持っている場合、新しいコレクションには最後のアイテムが含まれます。

    $collection = collect([
        ['product_id' => 'prod-100', 'name' => 'Desk'],
        ['product_id' => 'prod-200', 'name' => 'Chair'],
    ]);

    $keyed = $collection->keyBy('product_id');

    $keyed->all();

    /*
        [
            'prod-100' => ['product_id' => 'prod-100', 'name' => 'Desk'],
            'prod-200' => ['product_id' => 'prod-200', 'name' => 'Chair'],
        ]
    */

もしくは、コールバックをメソッドへ渡すこともできます。コールバックからコレクションのキーの値を返してください。

    $keyed = $collection->keyBy(function ($item) {
        return strtoupper($item['product_id']);
    });

    $keyed->all();

    /*
        [
            'PROD-100' => ['product_id' => 'prod-100', 'name' => 'Desk'],
            'PROD-200' => ['product_id' => 'prod-200', 'name' => 'Chair'],
        ]
    */

<a name="method-keys"></a>
#### `keys()` {#collection-method}

`keys`メソッドはコレクションの全キーを返します。

    $collection = collect([
        'prod-100' => ['product_id' => 'prod-100', 'name' => 'Desk'],
        'prod-200' => ['product_id' => 'prod-200', 'name' => 'Chair'],
    ]);

    $keys = $collection->keys();

    $keys->all();

    // ['prod-100', 'prod-200']

<a name="method-last"></a>
#### `last()` {#collection-method}

`last`メソッドは指定したテストをパスしたコレクションの最後のアイテムを返します。

    collect([1, 2, 3, 4])->last(function ($value, $key) {
        return $value < 3;
    });

    // 2

または`last`メソッドを引数無しで呼び出し、コレクションの最後の要素を取得することもできます。コレクションが空の場合、`null`が返ります。

    collect([1, 2, 3, 4])->last();

    // 4

<a name="method-macro"></a>
#### `macro()` {#collection-method}

staticの`macro`メソッドで、実行時に`Collection`クラスへメソッドを追加できます。詳細は、[コレクションの拡張](#extending-collections)ドキュメントを参照してください。

<a name="method-make"></a>
#### `make()` {#collection-method}

staticの`make`メソッドは、新しいコレクションインスタンスを生成します。[コレクションの生成](#creating-collections)セクションを参照してください。

<a name="method-map"></a>
#### `map()` {#collection-method}

`map`メソッドコレクション全体を繰り返しで処理し、指定したコールバックから値を返します。コールバックで自由にアイテムを更新し値を返せます。更新したアイテムの新しいコレクションが作成されます。

    $collection = collect([1, 2, 3, 4, 5]);

    $multiplied = $collection->map(function ($item, $key) {
        return $item * 2;
    });

    $multiplied->all();

    // [2, 4, 6, 8, 10]

> {note} 他のコレクションと同様に`map`は新しいコレクションインスタンスを返します。呼び出し元のコレクションは変更しません。もしオリジナルコレクションを変更したい場合は[`transform`](#method-transform)メソッドを使います。

<a name="method-mapinto"></a>
#### `mapInto()` {#collection-method}

`mapInto()`メソッドはコレクションを繰り返し処理します。指定したクラスの新しいインスタンスを生成し、コンストラクタへ値を渡します。

    class Currency
    {
        /**
         * 新しい通貨インスタンスの生成
         *
         * @param  string  $code
         * @return void
         */
        function __construct(string $code)
        {
            $this->code = $code;
        }
    }

    $collection = collect(['USD', 'EUR', 'GBP']);

    $currencies = $collection->mapInto(Currency::class);

    $currencies->all();

    // [Currency('USD'), Currency('EUR'), Currency('GBP')]

<a name="method-mapspread"></a>
#### `mapSpread()` {#collection-method}

`mapSpread`メソッドは指定したコールバックへ、コレクションのネストしたアイテム値をそれぞれ渡し、繰り返し処理します。値を変更した新しいコレクションを形成するために、コールバックで好きなようにアイテムを変更し、値を返してください。

    $collection = collect([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);

    $chunks = $collection->chunk(2);

    $sequence = $chunks->mapSpread(function ($even, $odd) {
        return $even + $odd;
    });

    $sequence->all();

    // [1, 5, 9, 13, 17]

<a name="method-maptogroups"></a>
#### `mapToGroups()` {#collection-method}

`mapToGroups`メソッドは、指定したコールバックにより、コレクションアイテムを分類します。コールバックはキー／値ペアを一つ含む連想配列を返す必要があります。

    $collection = collect([
        [
            'name' => 'John Doe',
            'department' => 'Sales',
        ],
        [
            'name' => 'Jane Doe',
            'department' => 'Sales',
        ],
        [
            'name' => 'Johnny Doe',
            'department' => 'Marketing',
        ]
    ]);

    $grouped = $collection->mapToGroups(function ($item, $key) {
        return [$item['department'] => $item['name']];
    });

    $grouped->all();

    /*
        [
            'Sales' => ['John Doe', 'Jane Doe'],
            'Marketing' => ['Johnny Doe'],
        ]
    */

    $grouped->get('Sales')->all();

    // ['John Doe', 'Jane Doe']

<a name="method-mapwithkeys"></a>
#### `mapWithKeys()` {#collection-method}

`mapWithKeys`メソッドはコレクション全体を反復処理し、指定したコールバックへ各値を渡します。コールバックからキー／値ペアを一つ含む連想配列を返してください。

    $collection = collect([
        [
            'name' => 'John',
            'department' => 'Sales',
            'email' => 'john@example.com',
        ],
        [
            'name' => 'Jane',
            'department' => 'Marketing',
            'email' => 'jane@example.com',
        ]
    ]);

    $keyed = $collection->mapWithKeys(function ($item) {
        return [$item['email'] => $item['name']];
    });

    $keyed->all();

    /*
        [
            'john@example.com' => 'John',
            'jane@example.com' => 'Jane',
        ]
    */

<a name="method-max"></a>
#### `max()` {#collection-method}

`max`メソッドは、指定したキーの最大値を返します。

    $max = collect([['foo' => 10], ['foo' => 20]])->max('foo');

    // 20

    $max = collect([1, 2, 3, 4, 5])->max();

    // 5

<a name="method-median"></a>
#### `median()` {#collection-method}

`median`メソッドは、指定したキーの[中央値](https://ja.wikipedia.org/wiki/%E4%B8%AD%E5%A4%AE%E5%80%A4)を返します。

    $median = collect([['foo' => 10], ['foo' => 10], ['foo' => 20], ['foo' => 40]])->median('foo');

    // 15

    $median = collect([1, 1, 2, 4])->median();

    // 1.5

<a name="method-merge"></a>
#### `merge()` {#collection-method}

`merge`メソッドは、指定した配列かコレクションをオリジナルコレクションへマージします。指定した配列の文字列キーが、オリジナルコレクションの文字列キーと一致する場合、オリジナルコレクションの値は指定アイテムの値でオーバーライトされます。

    $collection = collect(['product_id' => 1, 'price' => 100]);

    $merged = $collection->merge(['price' => 200, 'discount' => false]);

    $merged->all();

    // ['product_id' => 1, price' => 200, 'discount' => false]

指定したアイテムのキーが数値の場合、コレクションの最後に追加されます。

    $collection = collect(['Desk', 'Chair']);

    $merged = $collection->merge(['Bookcase', 'Door']);

    $merged->all();

    // ['Desk', 'Chair', 'Bookcase', 'Door']

<a name="method-mergerecursive"></a>
#### `mergeRecursive()` {#collection-method}

`mergeRecursive`メソッドはオリジナルのコレクションに対し、指定した配列かコレクションを再帰的にマージします。指定したアイテムの文字列キーがオリジナルコレクションのものと一致したら、それらのキーに対する値を配列へマージします。これを再帰的に行います。

    $collection = collect(['product_id' => 1, 'price' => 100]);

    $merged = $collection->mergeRecursive(['product_id' => 2, 'price' => 200, 'discount' => false]);

    $merged->all();

    // ['product_id' => [1, 2], 'price' => [100, 200], 'discount' => false]

<a name="method-min"></a>
#### `min()` {#collection-method}

`min`メソッドは、指定したキーの最小値を返します。

    $min = collect([['foo' => 10], ['foo' => 20]])->min('foo');

    // 10

    $min = collect([1, 2, 3, 4, 5])->min();

    // 1

<a name="method-mode"></a>
#### `mode()` {#collection-method}

`mode`メソッドは、指定したキーの[最頻値](https://ja.wikipedia.org/wiki/%E6%9C%80%E9%A0%BB%E5%80%A4)を返します。

    $mode = collect([['foo' => 10], ['foo' => 10], ['foo' => 20], ['foo' => 40]])->mode('foo');

    // [10]

    $mode = collect([1, 1, 2, 4])->mode();

    // [1]

<a name="method-nth"></a>
#### `nth()` {#collection-method}

`nth`メソッドは指定数値間隔で要素を含む、新しいコレクションを生成します。

    $collection = collect(['a', 'b', 'c', 'd', 'e', 'f']);

    $collection->nth(4);

    // ['a', 'e']

オプションとして第２引数にオフセットを渡せます。

    $collection->nth(4, 1);

    // ['b', 'f']

<a name="method-only"></a>
#### `only()` {#collection-method}

`only`メソッドは、コレクション中の指定したアイテムのみを返します。

    $collection = collect(['product_id' => 1, 'name' => 'Desk', 'price' => 100, 'discount' => false]);

    $filtered = $collection->only(['product_id', 'name']);

    $filtered->all();

    // ['product_id' => 1, 'name' => 'Desk']

`only`の正反対の機能は、 [except](#method-except)メソッドです。

> {tip} [Eloquentコレクション](/docs/{{version}}/eloquent-collections#method-contains)の使用時は、このメソッドの振る舞いは変わります。

<a name="method-pad"></a>
#### `pad()` {#collection-method}

`pad`メソッドは、配列が指定したサイズに達するまで、指定値で配列を埋めます。このメソッドは[array_pad](https://secure.php.net/manual/ja/function.array-pad.php) PHP関数のような動作をします。

先頭を埋めるためには、サイズに負数を指定します。配列サイズ以下のサイズ値を指定した場合は、埋め込みを行いません。

    $collection = collect(['A', 'B', 'C']);

    $filtered = $collection->pad(5, 0);

    $filtered->all();

    // ['A', 'B', 'C', 0, 0]

    $filtered = $collection->pad(-5, 0);

    $filtered->all();

    // [0, 0, 'A', 'B', 'C']

<a name="method-partition"></a>
#### `partition()` {#collection-method}

`partition`メソッドは指定したテストの合否に要素を分け、結果を`list` PHP関数で受け取ります。

    $collection = collect([1, 2, 3, 4, 5, 6]);

    list($underThree, $equalOrAboveThree) = $collection->partition(function ($i) {
        return $i < 3;
    });

    $underThree->all();

    // [1, 2]

    $equalOrAboveThree->all();

    // [3, 4, 5, 6]

<a name="method-pipe"></a>
#### `pipe()` {#collection-method}

`pipe`メソッドはコレクションを指定したコールバックに渡し、結果を返します。

    $collection = collect([1, 2, 3]);

    $piped = $collection->pipe(function ($collection) {
        return $collection->sum();
    });

    // 6

<a name="method-pipeinto"></a>
#### `pipeInto()` {#collection-method}

`pipeInto`メソッドは、指定クラスの新しいインスタンスを生成し、コレクションをコンストラクターに渡します。

    class ResourceCollection
    {
        /**
         * コレクションインスタンス
         */
        public $collection;

        /**
         * 新しいResourceCollectionインスタンスの生成
         *
         * @param  Collection  $resource
         * @return void
         */
        public function __construct(Collection $collection)
        {
            $this->collection = $collection;
        }
    }

    $collection = collect([1, 2, 3]);

    $resource = $collection->pipeInto(ResourceCollection::class);

    $resource->collection->all();

    // [1, 2, 3]

<a name="method-pluck"></a>
#### `pluck()` {#collection-method}

`pluck`メソッドは指定したキーの全コレクション値を取得します。

    $collection = collect([
        ['product_id' => 'prod-100', 'name' => 'Desk'],
        ['product_id' => 'prod-200', 'name' => 'Chair'],
    ]);

    $plucked = $collection->pluck('name');

    $plucked->all();

    // ['Desk', 'Chair']

さらに、コレクションのキー項目も指定できます。

    $plucked = $collection->pluck('name', 'product_id');

    $plucked->all();

    // ['prod-100' => 'Desk', 'prod-200' => 'Chair']

`pluck`メソッドは、「ドット」記法を使ったネストしている値の取得もサポートしています。

    $collection = collect([
        [
            'speakers' => [
                'first_day' => ['Rosa', 'Judith'],
                'second_day' => ['Angela', 'Kathleen'],
            ],
        ],
    ]);

    $plucked = $collection->pluck('speakers.first_day');

    $plucked->all();

    // ['Rosa', 'Judith']

重複するキーが存在している場合は、最後に一致した要素が結果のコレクションへ挿入されます。

    $collection = collect([
        ['brand' => 'Tesla',  'color' => 'red'],
        ['brand' => 'Pagani', 'color' => 'white'],
        ['brand' => 'Tesla',  'color' => 'black'],
        ['brand' => 'Pagani', 'color' => 'orange'],
    ]);

    $plucked = $collection->pluck('color', 'brand');

    $plucked->all();

    // ['Tesla' => 'black', 'Pagani' => 'orange']

<a name="method-pop"></a>
#### `pop()` {#collection-method}

`pop`メソッドはコレクションの最後のアイテムを削除し、返します。

    $collection = collect([1, 2, 3, 4, 5]);

    $collection->pop();

    // 5

    $collection->all();

    // [1, 2, 3, 4]

<a name="method-prepend"></a>
#### `prepend()` {#collection-method}

`prepend`メソッドはアイテムをコレクションの最初に追加します。

    $collection = collect([1, 2, 3, 4, 5]);

    $collection->prepend(0);

    $collection->all();

    // [0, 1, 2, 3, 4, 5]

また、第２引数に追加するアイテムのキーを指定できます。

    $collection = collect(['one' => 1, 'two' => 2]);

    $collection->prepend(0, 'zero');

    $collection->all();

    // ['zero' => 0, 'one' => 1, 'two' => 2]

<a name="method-pull"></a>
#### `pull()` {#collection-method}

`pull`メソッドはキーによりアイテムを削除し、そのアイテムを返します。

    $collection = collect(['product_id' => 'prod-100', 'name' => 'Desk']);

    $collection->pull('name');

    // 'Desk'

    $collection->all();

    // ['product_id' => 'prod-100']

<a name="method-push"></a>
#### `push()` {#collection-method}

 `push`メソッドはコレクションの最後にアイテムを追加します。

    $collection = collect([1, 2, 3, 4]);

    $collection->push(5);

    $collection->all();

    // [1, 2, 3, 4, 5]

<a name="method-put"></a>
#### `put()` {#collection-method}

`put`メソッドは指定したキーと値をコレクションにセットします。

    $collection = collect(['product_id' => 1, 'name' => 'Desk']);

    $collection->put('price', 100);

    $collection->all();

    // ['product_id' => 1, 'name' => 'Desk', 'price' => 100]

<a name="method-random"></a>
#### `random()` {#collection-method}

`random`メソッドはコレクションからランダムにアイテムを返します。

    $collection = collect([1, 2, 3, 4, 5]);

    $collection->random();

    // 4 - (ランダムに取得)

オプションとして、`random`にいくつのアイテムをランダムに取得するかを整数値で渡せます。受け取りたい数のアイテム数を明確に指定した場合、その数のコレクションのアイテムがいつも返されます。

    $random = $collection->random(3);

    $random->all();

    // [2, 4, 5] - (ランダムに取得)

要求されたアイテム数がコレクションに足りない場合、このメソッドは`InvalidArgumentException`を投げます。

<a name="method-reduce"></a>
#### `reduce()` {#collection-method}

`reduce`メソッドは繰り返しの結果を次の繰り返しに渡しながら、コレクションを単一値へ減らします。

    $collection = collect([1, 2, 3]);

    $total = $collection->reduce(function ($carry, $item) {
        return $carry + $item;
    });

    // 6

最初の繰り返しの`$carry`の値は`null`です。しかし初期値を設定したい場合は、`reduce`の第２引数に渡してください。

    $collection->reduce(function ($carry, $item) {
        return $carry + $item;
    }, 4);

    // 10

<a name="method-reject"></a>
#### `reject()` {#collection-method}

`reject`メソッドは指定したコールバックを使用し、コレクションをフィルタリングします。コールバックはコレクションの結果からアイテムを取り除く場合に`true`を返します。

    $collection = collect([1, 2, 3, 4]);

    $filtered = $collection->reject(function ($value, $key) {
        return $value > 2;
    });

    $filtered->all();

    // [1, 2]

`reject`メソッドの逆の働きについては、[`filter`](#method-filter)メソッドを読んでください。

<a name="method-replace"></a>
#### `replace()` {#collection-method}

`replace`メソッドは、`merge`メソッドと似た振る舞いを行います。文字列キーに一致したアイテムをオーバーライドするのは同じですが、`replace`メソッドは数値キーに一致するコレクション中のアイテムもオーバーライドします。

    $collection = collect(['Taylor', 'Abigail', 'James']);

    $replaced = $collection->replace([1 => 'Victoria', 3 => 'Finn']);

    $replaced->all();

    // ['Taylor', 'Victoria', 'James', 'Finn']

<a name="method-replacerecursive"></a>
#### `replaceRecursive()` {#collection-method}

このメソッドは`replace`と似た動作をしますが、配列を再帰的に下り、次元の低い値も同様に置換します。

    $collection = collect(['Taylor', 'Abigail', ['James', 'Victoria', 'Finn']]);

    $replaced = $collection->replaceRecursive(['Charlie', 2 => [1 => 'King']]);

    $replaced->all();

    // ['Charlie', 'Abigail', ['James', 'King', 'Finn']]

<a name="method-reverse"></a>
#### `reverse()` {#collection-method}

`reverse`メソッドはオリジナルのキーを保ったまま、コレクションのアイテムの順番を逆にします。

    $collection = collect(['a', 'b', 'c', 'd', 'e']);

    $reversed = $collection->reverse();

    $reversed->all();

    /*
        [
            4 => 'e',
            3 => 'd',
            2 => 'c',
            1 => 'b',
            0 => 'a',
        ]
    */

<a name="method-search"></a>
#### `search()` {#collection-method}

`search`メソッドは指定した値でコレクションをサーチし、見つけたキーを返します。アイテムが見つからない場合は`false`を返します。

    $collection = collect([2, 4, 6, 8]);

    $collection->search(4);

    // 1

検索は「緩い」比較で行われます。つまり、整数値を持つ文字列は、同じ値の整数に等しいと判断されます。「厳格」な比較を行いたい場合は`true`をメソッドの第２引数に渡します。

    $collection->search('4', true);

    // false

別の方法としてサーチのコールバックを渡し、テストをパスした最初のアイテムを取得することもできます。

    $collection->search(function ($item, $key) {
        return $item > 5;
    });

    // 2

<a name="method-shift"></a>
#### `shift()` {#collection-method}

`shift`メソッドはコレクションから最初のアイテムを削除し、その値を返します。

    $collection = collect([1, 2, 3, 4, 5]);

    $collection->shift();

    // 1

    $collection->all();

    // [2, 3, 4, 5]

<a name="method-shuffle"></a>
#### `shuffle()` {#collection-method}

`shuffle`メソッドはコレクションのアイテムをランダムにシャッフルします。

    $collection = collect([1, 2, 3, 4, 5]);

    $shuffled = $collection->shuffle();

    $shuffled->all();

    // [3, 2, 5, 1, 4] - (ランダムに生成される)

<a name="method-skip"></a>
#### `skip()` {#collection-method}

`skip`メソッドは、指定した数のアイテムを飛ばした新しいコレクションを返します。

    $collection = collect([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

    $collection = $collection->skip(4);

    $collection->all();

    // [5, 6, 7, 8, 9, 10]

<a name="method-skipuntil"></a>
#### `skipUntil()` {#collection-method}

`skipUntil`メソッドは指定コールバックが`true`を返すまでアイテムをスキップし、それからコレクションの残りのアイテムを返します。

    $collection = collect([1, 2, 3, 4]);

    $subset = $collection->skipUntil(function ($item) {
        return $item >= 3;
    });

    $subset->all();

    // [3, 4]

もしくはシンプルに値を`skipUntil`メソッドへ渡すこともでき、その場合は指定した値が見つかるまでアイテムをスキップします。

    $collection = collect([1, 2, 3, 4]);

    $subset = $collection->skipUntil(3);

    $subset->all();

    // [3, 4]

> {note} 指定した値が見つからないか、コールバックが`true`を返さなかった場合、`skipUntil`メソッドは空のコレクションを返します。

<a name="method-skipwhile"></a>
#### `skipWhile()` {#collection-method}

`skipWhile`メソッドは指定コールバックが`true`を返す間アイテムをスキップし、それからコレクション残りのアイテムを返します。

    $collection = collect([1, 2, 3, 4]);

    $subset = $collection->skipWhile(function ($item) {
        return $item <= 3;
    });

    $subset->all();

    // [4]

> {note} コールバックが`true`を返さなかった場合、`skipWhile`メソッドは空のコレクションを返します。

<a name="method-slice"></a>
#### `slice()` {#collection-method}

`slice`メソッドは指定したインデックスからコレクションを切り分けます。

    $collection = collect([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

    $slice = $collection->slice(4);

    $slice->all();

    // [5, 6, 7, 8, 9, 10]

切り分ける数を制限したい場合は、メソッドの第２引数で指定してください。

    $slice = $collection->slice(4, 2);

    $slice->all();

    // [5, 6]

sliceメソッドはデフォルトでキー値を保持したまま返します。オリジナルのキーを保持したくない場合は、[`values`](#method-values)メソッドを使えば、インデックスし直されます。

<a name="method-some"></a>
#### `some()` {#collection-method}

[`contains`](#method-contains)メソッドのエイリアスです。

<a name="method-sort"></a>
#### `sort()` {#collection-method}

`sort`メソッドはコレクションをソートします。ソート済みコレクションはオリジナル配列のキーを保持しますので、以下の例では、[`values`](#method-values)メソッドにより、連続した数字のインデックスにするためリセットしています。

    $collection = collect([5, 3, 1, 2, 4]);

    $sorted = $collection->sort();

    $sorted->values()->all();

    // [1, 2, 3, 4, 5]

より高度なソートを行いたい場合は`sort`にコールバックを渡し、自分のアルゴリズムを実行できます。コレクションの`sort`メソッドが裏で呼び出している[`uasort`](http://php.net/manual/en/function.uasort.php#refsect1-function.usort-parameters)のPHPドキュメントを参照してください。

> {tip} ネストした配列やオブジェクトのコレクションのソートは、[`sortBy`](#method-sortby)と[`sortByDesc`](#method-sortbydesc)メソッドを参照してください。

<a name="method-sortby"></a>
#### `sortBy()` {#collection-method}

`sortBy`メソッドは指定したキーでコレクションをソートします。ソート済みコレクションはオリジナル配列のキーを保持しますので、以下の例では、[`values`](#method-values)メソッドにより、連続した数字のインデックスにするためリセットしています。

    $collection = collect([
        ['name' => 'Desk', 'price' => 200],
        ['name' => 'Chair', 'price' => 100],
        ['name' => 'Bookcase', 'price' => 150],
    ]);

    $sorted = $collection->sortBy('price');

    $sorted->values()->all();

    /*
        [
            ['name' => 'Chair', 'price' => 100],
            ['name' => 'Bookcase', 'price' => 150],
            ['name' => 'Desk', 'price' => 200],
        ]
    */

このメソッドは第２引数に、[ソートフラグ](https://www.php.net/manual/en/function.sort.php)を受け取ります。

    $collection = collect([
        ['title' => 'Item 1'],
        ['title' => 'Item 12'],
        ['title' => 'Item 3'],
    ]);

    $sorted = $collection->sortBy('title', SORT_NATURAL);

    $sorted->values()->all();

    /*
        [
            ['title' => 'Item 1'],
            ['title' => 'Item 3'],
            ['title' => 'Item 12'],
        ]
    */

もしくは、コレクションの値をどのようにソートするかを決める独自のコールバックを渡します。

    $collection = collect([
        ['name' => 'Desk', 'colors' => ['Black', 'Mahogany']],
        ['name' => 'Chair', 'colors' => ['Black']],
        ['name' => 'Bookcase', 'colors' => ['Red', 'Beige', 'Brown']],
    ]);

    $sorted = $collection->sortBy(function ($product, $key) {
        return count($product['colors']);
    });

    $sorted->values()->all();

    /*
        [
            ['name' => 'Chair', 'colors' => ['Black']],
            ['name' => 'Desk', 'colors' => ['Black', 'Mahogany']],
            ['name' => 'Bookcase', 'colors' => ['Red', 'Beige', 'Brown']],
        ]
    */

<a name="method-sortbydesc"></a>
#### `sortByDesc()` {#collection-method}

このメソッドの使い方は[`sortBy`](#method-sortby)と同じで、コレクションを逆順にソートします。

<a name="method-sortdesc"></a>
#### `sortDesc()` {#collection-method}

このメソッドは[`sort`](#method-sort)メソッドの逆順でコレクションをソートします。

    $collection = collect([5, 3, 1, 2, 4]);

    $sorted = $collection->sortDesc();

    $sorted->values()->all();

    // [5, 4, 3, 2, 1]

`sort`と異なり、コールバックを引数として`sortDesc`渡せません。コールバックを使用する場合は、[`sort`](#method-sort)を使用し、比較を逆にしてください。

<a name="method-sortkeys"></a>
#### `sortKeys()` {#collection-method}

`sortKeys`メソッドは、内部の連想配列のキーにより、コレクションをソートします。

    $collection = collect([
        'id' => 22345,
        'first' => 'John',
        'last' => 'Doe',
    ]);

    $sorted = $collection->sortKeys();

    $sorted->all();

    /*
        [
            'first' => 'John',
            'id' => 22345,
            'last' => 'Doe',
        ]
    */

<a name="method-sortkeysdesc"></a>
#### `sortKeysDesc()` {#collection-method}

このメソッドは、[`sortKeys`](#method-sortkeys)メソッドと使い方は同じですが、逆順にコレクションをソートします。

<a name="method-splice"></a>
#### `splice()` {#collection-method}

`splice`メソッドは指定したインデックスからアイテムをスライスし、削除し、返します。

    $collection = collect([1, 2, 3, 4, 5]);

    $chunk = $collection->splice(2);

    $chunk->all();

    // [3, 4, 5]

    $collection->all();

    // [1, 2]

結果の塊の大きさを限定するために、第２引数を指定できます。

    $collection = collect([1, 2, 3, 4, 5]);

    $chunk = $collection->splice(2, 1);

    $chunk->all();

    // [3]

    $collection->all();

    // [1, 2, 4, 5]

さらに、コレクションから削除したアイテムに置き換える、新しいアイテムを第３引数に渡すこともできます。

    $collection = collect([1, 2, 3, 4, 5]);

    $chunk = $collection->splice(2, 1, [10, 11]);

    $chunk->all();

    // [3]

    $collection->all();

    // [1, 2, 10, 11, 4, 5]

<a name="method-split"></a>
#### `split()` {#collection-method}

`split`メソッドは、コレクションを指定数のグループへ分割します。

    $collection = collect([1, 2, 3, 4, 5]);

    $groups = $collection->split(3);

    $groups->all();

    // [[1, 2], [3, 4], [5]]

<a name="method-splitin"></a>
#### `splitIn()` {#collection-method}

`splitIn`メソッドは、コレクションを指定された数のグループに分割します。最終グループ以外を完全に埋め、残りを最終グループに割り当てます。

    $collection = collect([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

    $groups = $collection->splitIn(3);

    $groups->all();

    // [[1, 2, 3, 4], [5, 6, 7, 8], [9, 10]]

<a name="method-sum"></a>
#### `sum()` {#collection-method}

`sum`メソッドはコレクションの全アイテムの合計を返します。

    collect([1, 2, 3, 4, 5])->sum();

    // 15

コレクションがネストした配列やオブジェクトを含んでいる場合、どの値を合計するのを決めるためにキーを指定してください。

    $collection = collect([
        ['name' => 'JavaScript: The Good Parts', 'pages' => 176],
        ['name' => 'JavaScript: The Definitive Guide', 'pages' => 1096],
    ]);

    $collection->sum('pages');

    // 1272

さらに、コレクションのどの項目を合計するのかを決めるためにコールバックを渡すこともできます。

    $collection = collect([
        ['name' => 'Chair', 'colors' => ['Black']],
        ['name' => 'Desk', 'colors' => ['Black', 'Mahogany']],
        ['name' => 'Bookcase', 'colors' => ['Red', 'Beige', 'Brown']],
    ]);

    $collection->sum(function ($product) {
        return count($product['colors']);
    });

    // 6

<a name="method-take"></a>
#### `take()` {#collection-method}

`take`メソッドは指定したアイテム数の新しいコレクションを返します。

    $collection = collect([0, 1, 2, 3, 4, 5]);

    $chunk = $collection->take(3);

    $chunk->all();

    // [0, 1, 2]

アイテム数に負の整数を指定した場合はコレクションの最後から取得します。

    $collection = collect([0, 1, 2, 3, 4, 5]);

    $chunk = $collection->take(-2);

    $chunk->all();

    // [4, 5]

<a name="method-takeuntil"></a>
#### `takeUntil()` {#collection-method}

`takeUntil`メソッドは、指定のコールバックが`true`を返すまでコレクションのアイテムを返します。

    $collection = collect([1, 2, 3, 4]);

    $subset = $collection->takeUntil(function ($item) {
        return $item >= 3;
    });

    $subset->all();

    // [1, 2]

`takeUntil`メソッドにはシンプルに値を渡すこともでき、その指定値が見つかるまでアイテムを返します。

    $collection = collect([1, 2, 3, 4]);

    $subset = $collection->takeUntil(3);

    $subset->all();

    // [1, 2]

> {note} 指定値が見つからない、もしくはコールバックが`true`を返さない場合、`takeUntil`メソッドはコレクションの全アイテムを返します。

<a name="method-takewhile"></a>
#### `takeWhile()` {#collection-method}

`takeWhile`メソッドは、指定のコールバックが`false`を返すまでコレクションのアイテムを返します。

    $collection = collect([1, 2, 3, 4]);

    $subset = $collection->takeWhile(function ($item) {
        return $item < 3;
    });

    $subset->all();

    // [1, 2]

> {note} コールバックが`false`を返さない場合、`takeWhile`メソッドはコレクション中の全アイテムを返します。

<a name="method-tap"></a>
#### `tap()` {#collection-method}

`tap`メソッドは、指定されたコールバックへコレクションを渡します。コレクション自身に影響を与えることなく、その時点のコレクション内容を利用するために使用します。

    collect([2, 4, 3, 1, 5])
        ->sort()
        ->tap(function ($collection) {
            Log::debug('Values after sorting', $collection->values()->all());
        })
        ->shift();

    // 1

<a name="method-times"></a>
#### `times()` {#collection-method}

静的`times`メソッドは指定回数コールバックを呼び出すことで、新しいコレクションを生成します。

    $collection = Collection::times(10, function ($number) {
        return $number * 9;
    });

    $collection->all();

    // [9, 18, 27, 36, 45, 54, 63, 72, 81, 90]

このメソッドはファクトリと組み合わせ、[Eloquent](/docs/{{version}}/eloquent)モデルを生成する場合に便利です。

    $categories = Collection::times(3, function ($number) {
        return Category::factory()->create(['name' => "Category No. $number"]);
    });

    $categories->all();

    /*
        [
            ['id' => 1, 'name' => 'Category No. 1'],
            ['id' => 2, 'name' => 'Category No. 2'],
            ['id' => 3, 'name' => 'Category No. 3'],
        ]
    */

<a name="method-toarray"></a>
#### `toArray()` {#collection-method}

`toArray`メソッドはコレクションをPHPの「配列」へ変換します。コレクションの値が[Eloquent](/docs/{{version}}/eloquent)モデルの場合は、そのモデルが配列に変換されます。

    $collection = collect(['name' => 'Desk', 'price' => 200]);

    $collection->toArray();

    /*
        [
            ['name' => 'Desk', 'price' => 200],
        ]
    */

> {note} `toArray`は、ネストした`Arrayable`インスタンスのオブジェクトすべてを配列へ変換します。裏の配列をそのまま取得したい場合は、代わりに[`all`](#method-all)メソッドを使用してください。

<a name="method-tojson"></a>
#### `toJson()` {#collection-method}

`toJson`メソッドはコレクションをシリアライズ済みのJSON文字へ変換します。

    $collection = collect(['name' => 'Desk', 'price' => 200]);

    $collection->toJson();

    // '{"name":"Desk","price":200}'

<a name="method-transform"></a>
#### `transform()` {#collection-method}

`transform`メソッドはコレクションを繰り返し処理し、コレクションの各アイテムに指定したコールバックを適用します。コレクション中のアイテムはコールバックから返される値に置き換わります。

    $collection = collect([1, 2, 3, 4, 5]);

    $collection->transform(function ($item, $key) {
        return $item * 2;
    });

    $collection->all();

    // [2, 4, 6, 8, 10]

> {note} 他のコレクションメソッドとは異なり、`transform`はコレクション自身を更新します。代わりに新しいコレクションを生成したい場合は、 [`map`](#method-map)メソッドを使用してください。

<a name="method-union"></a>
#### `union()` {#collection-method}

`union`メソッドは指定した配列をコレクションへ追加します。すでにコレクションにあるキーが、オリジナル配列に含まれている場合は、オリジナルコレクションの値が優先されます。

    $collection = collect([1 => ['a'], 2 => ['b']]);

    $union = $collection->union([3 => ['c'], 1 => ['b']]);

    $union->all();

    // [1 => ['a'], 2 => ['b'], 3 => ['c']]

<a name="method-unique"></a>
#### `unique()` {#collection-method}

`unique`メソッドはコレクションの重複を取り除いた全アイテムを返します。ソート済みのコレクションはオリジナルの配列キーを保っています。下の例では[`values`](#method-values)メソッドで連続した数字のインデックスにするためリセットしています。

    $collection = collect([1, 1, 2, 2, 3, 4, 2]);

    $unique = $collection->unique();

    $unique->values()->all();

    // [1, 2, 3, 4]

ネストした配列やオブジェクトを取り扱いたい場合は、一意であることを決めるキーを指定する必要があります。

    $collection = collect([
        ['name' => 'iPhone 6', 'brand' => 'Apple', 'type' => 'phone'],
        ['name' => 'iPhone 5', 'brand' => 'Apple', 'type' => 'phone'],
        ['name' => 'Apple Watch', 'brand' => 'Apple', 'type' => 'watch'],
        ['name' => 'Galaxy S6', 'brand' => 'Samsung', 'type' => 'phone'],
        ['name' => 'Galaxy Gear', 'brand' => 'Samsung', 'type' => 'watch'],
    ]);

    $unique = $collection->unique('brand');

    $unique->values()->all();

    /*
        [
            ['name' => 'iPhone 6', 'brand' => 'Apple', 'type' => 'phone'],
            ['name' => 'Galaxy S6', 'brand' => 'Samsung', 'type' => 'phone'],
        ]
    */

アイテムが一意であるかを決めるコールバックを渡すこともできます。

    $unique = $collection->unique(function ($item) {
        return $item['brand'].$item['type'];
    });

    $unique->values()->all();

    /*
        [
            ['name' => 'iPhone 6', 'brand' => 'Apple', 'type' => 'phone'],
            ['name' => 'Apple Watch', 'brand' => 'Apple', 'type' => 'watch'],
            ['name' => 'Galaxy S6', 'brand' => 'Samsung', 'type' => 'phone'],
            ['name' => 'Galaxy Gear', 'brand' => 'Samsung', 'type' => 'watch'],
        ]
    */

`unique`メソッドは、アイテムの判定に「緩い」比較を使用します。つまり、同じ値の文字列と整数値は等しいと判定します。「厳密」な比較でフィルタリングしたい場合は、[`uniqueStrict`](#method-uniquestrict)メソッドを使用してください。

> {tip} [Eloquentコレクション](/docs/{{version}}/eloquent-collections#method-contains)の使用時は、このメソッドの振る舞いは変わります。

<a name="method-uniquestrict"></a>
#### `uniqueStrict()` {#collection-method}

このメソッドは、[`unique`](#method-unique)と同じ使用方法です。しかし、全値は「厳密」に比較されます。

<a name="method-unless"></a>
#### `unless()` {#collection-method}

`unless`メソッドは最初の引数が`true`と評価されない場合、コールバックを実行します。

    $collection = collect([1, 2, 3]);

    $collection->unless(true, function ($collection) {
        return $collection->push(4);
    });

    $collection->unless(false, function ($collection) {
        return $collection->push(5);
    });

    $collection->all();

    // [1, 2, 3, 5]

`unless`の逆の動作は、[`when`](#method-when)メソッドです。

<a name="method-unlessempty"></a>
#### `unlessEmpty()` {#collection-method}

[`whenNotEmpty`](#method-whennotempty)メソッドのエイリアスです。

<a name="method-unlessnotempty"></a>
#### `unlessNotEmpty()` {#collection-method}

[`whenEmpty`](#method-whenempty)メソッドのエイリアスです。

<a name="method-unwrap"></a>
#### `unwrap()` {#collection-method}

staticの`unwrap`メソッドは適用可能な場合、指定値からコレクションの元になっているアイテムを返します。

    Collection::unwrap(collect('John Doe'));

    // ['John Doe']

    Collection::unwrap(['John Doe']);

    // ['John Doe']

    Collection::unwrap('John Doe');

    // 'John Doe'

<a name="method-values"></a>
#### `values()` {#collection-method}

`values`メソッドはキーをリセット後、連続した整数にした新しいコレクションを返します。

    $collection = collect([
        10 => ['product' => 'Desk', 'price' => 200],
        11 => ['product' => 'Desk', 'price' => 200],
    ]);

    $values = $collection->values();

    $values->all();

    /*
        [
            0 => ['product' => 'Desk', 'price' => 200],
            1 => ['product' => 'Desk', 'price' => 200],
        ]
    */

<a name="method-when"></a>
#### `when()` {#collection-method}

`when`メソッドは、メソッドの第１引数が`true`に評価される場合、コールバックを実行します。

    $collection = collect([1, 2, 3]);

    $collection->when(true, function ($collection) {
        return $collection->push(4);
    });

    $collection->when(false, function ($collection) {
        return $collection->push(5);
    });

    $collection->all();

    // [1, 2, 3, 4]

`when`の逆の動作は、[`unless`](#method-unless)メソッドです。

<a name="method-whenempty"></a>
#### `whenEmpty()` {#collection-method}

`whenEmpty`メソッドは、コレクションが空の場合に、指定したコールバックを実行します。

    $collection = collect(['michael', 'tom']);

    $collection->whenEmpty(function ($collection) {
        return $collection->push('adam');
    });

    $collection->all();

    // ['michael', 'tom']


    $collection = collect();

    $collection->whenEmpty(function ($collection) {
        return $collection->push('adam');
    });

    $collection->all();

    // ['adam']


    $collection = collect(['michael', 'tom']);

    $collection->whenEmpty(function ($collection) {
        return $collection->push('adam');
    }, function ($collection) {
        return $collection->push('taylor');
    });

    $collection->all();

    // ['michael', 'tom', 'taylor']

`whenEmpty`の逆の動作は、[`whenNotEmpty`](#method-whennotempty)メソッドです。

<a name="method-whennotempty"></a>
#### `whenNotEmpty()` {#collection-method}

`whenNotEmpty`メソッドは、コレクションが空でない場合に、指定したコールバックを実行します。

    $collection = collect(['michael', 'tom']);

    $collection->whenNotEmpty(function ($collection) {
        return $collection->push('adam');
    });

    $collection->all();

    // ['michael', 'tom', 'adam']


    $collection = collect();

    $collection->whenNotEmpty(function ($collection) {
        return $collection->push('adam');
    });

    $collection->all();

    // []


    $collection = collect();

    $collection->whenNotEmpty(function ($collection) {
        return $collection->push('adam');
    }, function ($collection) {
        return $collection->push('taylor');
    });

    $collection->all();

    // ['taylor']

`whenNotEmpty`の逆の動作は、[`whenEmpty`](#method-whenempty)メソッドです。

<a name="method-where"></a>
#### `where()` {#collection-method}

`where`メソッドは指定したキー／値ペアでコレクションをフィルタリングします。

    $collection = collect([
        ['product' => 'Desk', 'price' => 200],
        ['product' => 'Chair', 'price' => 100],
        ['product' => 'Bookcase', 'price' => 150],
        ['product' => 'Door', 'price' => 100],
    ]);

    $filtered = $collection->where('price', 100);

    $filtered->all();

    /*
        [
            ['product' => 'Chair', 'price' => 100],
            ['product' => 'Door', 'price' => 100],
        ]
    */

`where`メソッドはアイテム値の確認を「緩く」比較します。つまり、同じ値の文字列と整数値は、同値と判断します。「厳格」な比較でフィルタリングしたい場合は、[`whereStrict`](#method-wherestrict)メソッドを使ってください。

第２引数に比較演算子をオプションとして渡すこともできます。

    $collection = collect([
        ['name' => 'Jim', 'deleted_at' => '2019-01-01 00:00:00'],
        ['name' => 'Sally', 'deleted_at' => '2019-01-02 00:00:00'],
        ['name' => 'Sue', 'deleted_at' => null],
    ]);

    $filtered = $collection->where('deleted_at', '!=', null);

    $filtered->all();

    /*
        [
            ['name' => 'Jim', 'deleted_at' => '2019-01-01 00:00:00'],
            ['name' => 'Sally', 'deleted_at' => '2019-01-02 00:00:00'],
        ]
    */

<a name="method-wherestrict"></a>
#### `whereStrict()` {#collection-method}

このメソッドの使用法は、[`where`](#method-where)メソッドと同じです。しかし、値の比較はすべて「厳格」な比較で行われます。

<a name="method-wherebetween"></a>
#### `whereBetween()` {#collection-method}

`whereBetween`メソッドは、指定した範囲でコレクションをフィルタリングします。

    $collection = collect([
        ['product' => 'Desk', 'price' => 200],
        ['product' => 'Chair', 'price' => 80],
        ['product' => 'Bookcase', 'price' => 150],
        ['product' => 'Pencil', 'price' => 30],
        ['product' => 'Door', 'price' => 100],
    ]);

    $filtered = $collection->whereBetween('price', [100, 200]);

    $filtered->all();

    /*
        [
            ['product' => 'Desk', 'price' => 200],
            ['product' => 'Bookcase', 'price' => 150],
            ['product' => 'Door', 'price' => 100],
        ]
    */

<a name="method-wherein"></a>
#### `whereIn()` {#collection-method}

`whereIn`メソッドは指定された配列に含まれる値／キーにより、コレクションをフィルタリングします。

    $collection = collect([
        ['product' => 'Desk', 'price' => 200],
        ['product' => 'Chair', 'price' => 100],
        ['product' => 'Bookcase', 'price' => 150],
        ['product' => 'Door', 'price' => 100],
    ]);

    $filtered = $collection->whereIn('price', [150, 200]);

    $filtered->all();

    /*
        [
            ['product' => 'Desk', 'price' => 200],
            ['product' => 'Bookcase', 'price' => 150],
        ]
    */

`whereIn`メソッドはアイテム値のチェックを「緩く」比較します。つまり同じ値の文字列と整数値は同値と判定します。「厳密」な比較でフィルタリングしたい場合は、[`whereInStrict`](#method-whereinstrict)メソッドを使ってください。

<a name="method-whereinstrict"></a>
#### `whereInStrict()` {#collection-method}

このメソッドの使い方は、[`whereIn`](#method-wherein)メソッドと同じです。違いは全値を「厳密」に比較することです。

<a name="method-whereinstanceof"></a>
#### `whereInstanceOf()` {#collection-method}

`whereInstanceOf`メソッドは、コレクションを指定したクラスタイプによりフィルタリングします。

    use App\Models\User;
    use App\Models\Post;

    $collection = collect([
        new User,
        new User,
        new Post,
    ]);

    $filtered = $collection->whereInstanceOf(User::class);

    $filtered->all();

    // [App\Models\User, App\Models\User]

<a name="method-wherenotbetween"></a>
#### `whereNotBetween()` {#collection-method}

`whereNotBetween`メソッドは、指定された範囲でコレクションをフィルタリングします。

    $collection = collect([
        ['product' => 'Desk', 'price' => 200],
        ['product' => 'Chair', 'price' => 80],
        ['product' => 'Bookcase', 'price' => 150],
        ['product' => 'Pencil', 'price' => 30],
        ['product' => 'Door', 'price' => 100],
    ]);

    $filtered = $collection->whereNotBetween('price', [100, 200]);

    $filtered->all();

    /*
        [
            ['product' => 'Chair', 'price' => 80],
            ['product' => 'Pencil', 'price' => 30],
        ]
    */

<a name="method-wherenotin"></a>
#### `whereNotIn()` {#collection-method}

`whereNotIn`メソッドは、指定した配列中のキー／値を含まないコレクションをフィルタリングします。

    $collection = collect([
        ['product' => 'Desk', 'price' => 200],
        ['product' => 'Chair', 'price' => 100],
        ['product' => 'Bookcase', 'price' => 150],
        ['product' => 'Door', 'price' => 100],
    ]);

    $filtered = $collection->whereNotIn('price', [150, 200]);

    $filtered->all();

    /*
        [
            ['product' => 'Chair', 'price' => 100],
            ['product' => 'Door', 'price' => 100],
        ]
    */

`whereNotIn`メソッドは、値を「緩く」比較します。つまり、同じ値の文字列と整数は、同値と判定されます。「厳密」にフィルタリングしたい場合は、[`whereNotInStrict`](#method-wherenotinstrict)メソッドを使用します。

<a name="method-wherenotinstrict"></a>
#### `whereNotInStrict()` {#collection-method}

このメソッドは、[`whereNotIn`](#method-wherenotin)と使い方は同じですが、全値の比較が「厳密」に行われる点が異なります。

<a name="method-wherenotnull"></a>
#### `whereNotNull()` {#collection-method}

`whereNotNull`メソッドは、指定したキーがNULL値ではないアイテムを抜き出します。

    $collection = collect([
        ['name' => 'Desk'],
        ['name' => null],
        ['name' => 'Bookcase'],
    ]);

    $filtered = $collection->whereNotNull('name');

    $filtered->all();

    /*
        [
            ['name' => 'Desk'],
            ['name' => 'Bookcase'],
        ]
    */

<a name="method-wherenull"></a>
#### `whereNull()` {#collection-method}

`whereNull`メソッドは、指定したキーがNULL値のアイテムを抜き出します

    $collection = collect([
        ['name' => 'Desk'],
        ['name' => null],
        ['name' => 'Bookcase'],
    ]);

    $filtered = $collection->whereNull('name');

    $filtered->all();

    /*
        [
            ['name' => null],
        ]
    */


<a name="method-wrap"></a>
#### `wrap()` {#collection-method}

staticの`wrap`メソッドは適用可能であれば、指定値をコレクションでラップします。

    $collection = Collection::wrap('John Doe');

    $collection->all();

    // ['John Doe']

    $collection = Collection::wrap(['John Doe']);

    $collection->all();

    // ['John Doe']

    $collection = Collection::wrap(collect('John Doe'));

    $collection->all();

    // ['John Doe']

<a name="method-zip"></a>
#### `zip()` {#collection-method}

`zip`メソッドは指定した配列の値と、対応するインデックスのオリジナルコレクションの値をマージします。

    $collection = collect(['Chair', 'Desk']);

    $zipped = $collection->zip([100, 200]);

    $zipped->all();

    // [['Chair', 100], ['Desk', 200]]

<a name="higher-order-messages"></a>
## Higher Order Message

コレクションで繁用するアクションを手短に実行できるよう、"higher order messages"をサポートしました。[`average`](#method-average)、[`avg`](#method-avg)、[`contains`](#method-contains)、[`each`](#method-each)、[`every`](#method-every)、[`filter`](#method-filter)、[`first`](#method-first)、[`flatMap`](#method-flatmap)、[`groupBy`](#method-groupby)、[`keyBy`](#method-keyby)、[`map`](#method-map)、[`max`](#method-max)、[`min`](#method-min)、[`partition`](#method-partition)、[`reject`](#method-reject)、[`skipUntil`](#method-skipuntil)、[`skipWhile`](#method-skipwhile)、[`some`](#method-some)、[`sortBy`](#method-sortby)、[`sortByDesc`](#method-sortbydesc)、[`sum`](#method-sum)、[`unique`](#method-unique)、[`takeUntil`](#method-takeuntil)、[`takeWhile`](#method-takewhile)コレクションメソッドでhigher order messageが使用できます。

各higher order messageへは、コレクションインスタンスの動的プロパティとしてアクセスできます。例として、コレクション中の各オブジェクトメソッドを呼び出す、`each` higher order messageを使用してみましょう。

    $users = User::where('votes', '>', 500)->get();

    $users->each->markAsVip();

同様に、ユーザーのコレクションに対し、「投票(votes)」の合計数を求めるために、`sum` higher order messageを使用できます。

    $users = User::where('group', 'Development')->get();

    return $users->sum->votes;

<a name="lazy-collections"></a>
## レイジーコレクション

<a name="lazy-collection-introduction"></a>
### イントロダクション

> {note} Laravelのレイジーコレクションを学ぶ前に、[PHPジェネレータ](https://www.php.net/manual/ja/language.generators.overview.php)に慣れるために時間を取ってください。

すでに強力な`Collection`クラスを補足するために、`LazyCollection`クラスはPHPの[PHPジェネレータ](https://www.php.net/manual/ja/language.generators.overview.php)を活用しています。巨大なデータセットをメモリ使用を抑えて利用する目的のためです。

たとえば、アプリケーションで数ギガバイトのログを処理する必要があり、ログを解析するためにLaravelのコレクションメソッドを活用するとしましょう。ファイル全体をメモリへ一度で読み込む代わりに、レイジーコレクションなら毎回ファイルの小さな部分だけをメモリに保持するだけで済みます。

    use App\Models\LogEntry;
    use Illuminate\Support\LazyCollection;

    LazyCollection::make(function () {
        $handle = fopen('log.txt', 'r');

        while (($line = fgets($handle)) !== false) {
            yield $line;
        }
    })->chunk(4)->map(function ($lines) {
        return LogEntry::fromLines($lines);
    })->each(function (LogEntry $logEntry) {
        // ログエントリーの処理…
    });

もしくは、10,000個のEloquentモデルを繰り返し処理する必要があると想像してください。今までのLaravelコレクションでは、一度に10,000個のEloquentモデルすべてをメモリーにロードする必要がありました。

    $users = App\Models\User::all()->filter(function ($user) {
        return $user->id > 500;
    });

しかし、クエリビルダの`cursor`メソッドは、`LazyCollection`インスタンスを返します。これによりデータベースに対し１つのクエリを実行するだけでなく、一度に１つのEloquentモデルをメモリにロードするだけで済みます。この例では、各ユーザーを個別に繰り返し処理するまで`filter`コールバックは実行されず、大幅にメモリ使用量を減らせます。

    $users = App\Models\User::cursor()->filter(function ($user) {
        return $user->id > 500;
    });

    foreach ($users as $user) {
        echo $user->id;
    }

<a name="creating-lazy-collections"></a>
### レイジーコレクションの生成

レイジーコレクションインスタンスを生成するには、コレクションの`make`メソッドへPHPジェネレータ関数を渡します。

    use Illuminate\Support\LazyCollection;

    LazyCollection::make(function () {
        $handle = fopen('log.txt', 'r');

        while (($line = fgets($handle)) !== false) {
            yield $line;
        }
    });

<a name="the-enumerable-contract"></a>
### Enumerable契約

`Collection`クラスのほとんどすべてのメソッドが、`LazyCollection`クラス上でも利用できます。両クラスは`Illuminate\Support\Enumerable`契約を実装しており、以下のメソッドを定義しています。

<div id="collection-method-list" markdown="1">

[all](#method-all)
[average](#method-average)
[avg](#method-avg)
[chunk](#method-chunk)
[chunkWhile](#method-chunkwhile)
[collapse](#method-collapse)
[collect](#method-collect)
[combine](#method-combine)
[concat](#method-concat)
[contains](#method-contains)
[containsStrict](#method-containsstrict)
[count](#method-count)
[countBy](#method-countBy)
[crossJoin](#method-crossjoin)
[dd](#method-dd)
[diff](#method-diff)
[diffAssoc](#method-diffassoc)
[diffKeys](#method-diffkeys)
[dump](#method-dump)
[duplicates](#method-duplicates)
[duplicatesStrict](#method-duplicatesstrict)
[each](#method-each)
[eachSpread](#method-eachspread)
[every](#method-every)
[except](#method-except)
[filter](#method-filter)
[first](#method-first)
[firstWhere](#method-first-where)
[flatMap](#method-flatmap)
[flatten](#method-flatten)
[flip](#method-flip)
[forPage](#method-forpage)
[get](#method-get)
[groupBy](#method-groupby)
[has](#method-has)
[implode](#method-implode)
[intersect](#method-intersect)
[intersectByKeys](#method-intersectbykeys)
[isEmpty](#method-isempty)
[isNotEmpty](#method-isnotempty)
[join](#method-join)
[keyBy](#method-keyby)
[keys](#method-keys)
[last](#method-last)
[macro](#method-macro)
[make](#method-make)
[map](#method-map)
[mapInto](#method-mapinto)
[mapSpread](#method-mapspread)
[mapToGroups](#method-maptogroups)
[mapWithKeys](#method-mapwithkeys)
[max](#method-max)
[median](#method-median)
[merge](#method-merge)
[mergeRecursive](#method-mergerecursive)
[min](#method-min)
[mode](#method-mode)
[nth](#method-nth)
[only](#method-only)
[pad](#method-pad)
[partition](#method-partition)
[pipe](#method-pipe)
[pluck](#method-pluck)
[random](#method-random)
[reduce](#method-reduce)
[reject](#method-reject)
[replace](#method-replace)
[replaceRecursive](#method-replacerecursive)
[reverse](#method-reverse)
[search](#method-search)
[shuffle](#method-shuffle)
[skip](#method-skip)
[slice](#method-slice)
[some](#method-some)
[sort](#method-sort)
[sortBy](#method-sortby)
[sortByDesc](#method-sortbydesc)
[sortKeys](#method-sortkeys)
[sortKeysDesc](#method-sortkeysdesc)
[split](#method-split)
[sum](#method-sum)
[take](#method-take)
[tap](#method-tap)
[times](#method-times)
[toArray](#method-toarray)
[toJson](#method-tojson)
[union](#method-union)
[unique](#method-unique)
[uniqueStrict](#method-uniquestrict)
[unless](#method-unless)
[unlessEmpty](#method-unlessempty)
[unlessNotEmpty](#method-unlessnotempty)
[unwrap](#method-unwrap)
[values](#method-values)
[when](#method-when)
[whenEmpty](#method-whenempty)
[whenNotEmpty](#method-whennotempty)
[where](#method-where)
[whereStrict](#method-wherestrict)
[whereBetween](#method-wherebetween)
[whereIn](#method-wherein)
[whereInStrict](#method-whereinstrict)
[whereInstanceOf](#method-whereinstanceof)
[whereNotBetween](#method-wherenotbetween)
[whereNotIn](#method-wherenotin)
[whereNotInStrict](#method-wherenotinstrict)
[wrap](#method-wrap)
[zip](#method-zip)

</div>

> {note} `shift`、`pop`、`prepend`などのように、コレクションを変異させるメソッドは、`LazyCollection`クラスでは使用**できません**。

<a name="lazy-collection-methods"></a>
### レイジーコレクションメソッド

`Enumerable`契約で定義しているメソッドに加え、`LazyCollection`クラス契約は以下のメソッドを含んでいます。

<a name="method-tapEach"></a>
#### `tapEach()` {#collection-method}

`each`メソッドはコレクション中の各アイテムに対し、指定したコールバックを即時に呼び出しますが、`tapEach`メソッドはリストから一つずつアイテムを抜き出し、指定したコールバックを呼び出します。

    $lazyCollection = LazyCollection::times(INF)->tapEach(function ($value) {
        dump($value);
    });

    // 何もダンプされない

    $array = $lazyCollection->take(3)->all();

    // 1
    // 2
    // 3

<a name="method-remember"></a>
#### `remember()` {#collection-method}

`remember`メソッドは扱った値を覚え、それらを再度扱う場合でも再取得しない新しいレイジーコレクションを返します。

    $users = User::cursor()->remember();

    // まだ、クエリは実行されない

    $users->take(5)->all();

    // クエリが実行され、最初の５つのユーザーがデータベースよりハイドレートされる

    $users->take(20)->all();

    // 最初の５ユーザーはコレクションキャッシュから、残りはデータベースからハイドレートされる
