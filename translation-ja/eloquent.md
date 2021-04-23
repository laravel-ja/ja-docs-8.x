# Eloquentの準備

- [イントロダクション](#introduction)
- [モデルクラスの生成](#generating-model-classes)
- [Eloquentモデルの規約](#eloquent-model-conventions)
    - [テーブル名](#table-names)
    - [主キー](#primary-keys)
    - [主キータイムスタンプ](#timestamps)
    - [データベース接続](#database-connections)
    - [デフォルト属性値](#default-attribute-values)
- [モデルの取得](#retrieving-models)
    - [コレクション](#collections)
    - [結果の分割](#chunking-results)
    - [ルーズなストリーミング結果](#streaming-results-lazily)
    - [カーソル](#cursors)
    - [上級サブクエリ](#advanced-subqueries)
- [単一モデル/集計の取得](#retrieving-single-models)
    - [モデルの取得／生成](#retrieving-or-creating-models)
    - [集計の取得](#retrieving-aggregates)
- [モデルの挿入と更新](#inserting-and-updating-models)
    - [挿入](#inserts)
    - [更新](#updates)
    - [複数代入](#mass-assignment)
    - [更新／挿入](#upserts)
- [モデルの削除](#deleting-models)
    - [ソフトデリート](#soft-deleting)
    - [ソフトデリート済みモデルのクエリ](#querying-soft-deleted-models)
- [モデルの複製](#replicating-models)
- [クエリスコープ](#query-scopes)
    - [グローバルスコープ](#global-scopes)
    - [ローカルスコープ](#local-scopes)
- [モデルの比較](#comparing-models)
- [イベント](#events)
    - [クロージャの使用](#events-using-closures)
    - [オブザーバー](#observers)
    - [イベントのミュート](#muting-events)

<a name="introduction"></a>
## イントロダクション

Laravelには、データベースとの対話を楽しくするオブジェクトリレーショナルマッパー(ORM)であるEloquentが含まれています。Eloquentを使用する場合、各データベーステーブルには対応する「モデル」があり、そのテーブルとの対話に使用します。Eloquentモデルでは、データベーステーブルからレコードを取得するだけでなく、テーブルへのレコード挿入、更新、削除も可能です。

> {tip} 使い始める前に、必ずアプリケーションの`config/database.php`設定ファイルで、データベース接続を設定してください。データベース設定の詳細は、[データベース設定のドキュメント](/docs/{{version}}/database#configuration)で確認してください。

<a name="generating-model-classes"></a>
## モデルクラスの生成

使用を開始するには、Eloquentモデルを作成しましょう。モデルは通常`app\Models`ディレクトリにあり、`Illuminate\Database\Eloquent\Model`クラスを拡張します。`make:model` [Artisanコマンド](/docs/{{version}}/artisan)を使用して、新しいモデルを生成します。

    php artisan make:model Flight

モデルの生成時に[データベースマイグレーション](/docs/{{version}}/migrations)も生成する場合は、`--migration`または`-m`オプションを使用します。

    php artisan make:model Flight --migration

モデルを生成するとき、ファクトリ、シーダ、コントローラなど、他のさまざまなタイプのクラスを同時に生成できます。さらにこれらのオプションを組み合わせて、一度に複数のクラスを作成できます。

```bash
# モデルとFlightFactoryクラスを生成
php artisan make:model Flight --factory
php artisan make:model Flight -f

# モデルとFlightSeederクラスを生成
php artisan make:model Flight --seed
php artisan make:model Flight -s

# モデルとFlightControllerクラスを生成
php artisan make:model Flight --controller
php artisan make:model Flight -c

# モデルとマイグレーション、ファクトリ、シーダ、およびコントローラを生成
php artisan make:model Flight -mfsc

# ピボットモデルを生成
php artisan make:model Member --pivot
```

<a name="eloquent-model-conventions"></a>
## Eloquentモデルの規約

`make:model`コマンドで生成されたモデルは、`app/Models`ディレクトリに配置します。基本的なモデルクラスを調べて、Eloquentの主要な規約をいくつか説明しましょう。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Flight extends Model
    {
        //
    }

<a name="table-names"></a>
### テーブル名

上記の例をちょっと見て、どのデータベーステーブルが`Flight`モデルに対応するかをEloquentに知らせていないことにお気づきかもしれません。別の名前を明示的に指定しない限り、クラスの複数形の「スネークケース」をテーブル名として使用します。したがって、この場合、Eloquentは`Flight`モデルが`flights`テーブルにレコードを格納し、`AirTrafficController`モデルは`air_traffic_controllers`テーブルにレコードを格納すると想定できます。

モデルの対応するデータベーステーブルがこの規約に適合しない場合は、モデルに`table`プロパティを定義してモデルのテーブル名を自分で指定できます。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Flight extends Model
    {
        /**
         * モデルに関連付けるテーブル
         *
         * @var string
         */
        protected $table = 'my_flights';
    }

<a name="primary-keys"></a>
### 主キー

Eloquentは、各モデルの対応するデータベーステーブルに`id`という名前の主キーカラムがあることも想定しています。必要に応じて、モデルのprotected `$primaryKey`プロパティを定義して、主キーとして機能する別のカラムを指定できます。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Flight extends Model
    {
        /**
         * テーブルに関連付ける主キー
         *
         * @var string
         */
        protected $primaryKey = 'flight_id';
    }

さらに、Eloquentは、主キーが増分整数値であることも想定しています。これは、Eloquentが主キーを自動的に整数にキャストすることを意味します。非インクリメントまたは非数値の主キーを使用する場合は、モデルにpublicの`$incrementing`プロパティを定義し、`false`をセットする必要があります。

    <?php

    class Flight extends Model
    {
        /**
         * モデルのIDを自動増分するか
         *
         * @var bool
         */
        public $incrementing = false;
    }

モデルの主キーが整数でない場合は、モデルにprotectedな`$keyType`プロパティを定義する必要があります。このプロパティの値は`string`にする必要があります。

    <?php

    class Flight extends Model
    {
        /**
         * 自動増分IDのデータ型
         *
         * @var string
         */
        protected $keyType = 'string';
    }

<a name="composite-primary-keys"></a>
#### 「コンポジット」主キー

Elomequentは、それぞれのモデルがその主キーとして役立つことができる、少なくとも１つの一意に識別される「ID」を持つ必要があります。Eloquentモデルは「コンポジット」主キーをサポートしていません。しかし、テーブルの一意に識別される主キーに加えて、データベーステーブルに追加のマルチカラム、ユニークなインデックスを追加することができます。

<a name="timestamps"></a>
### 主キータイムスタンプ

デフォルトでEloquentは、モデルと対応するデータベーステーブルに、`created_at`カラムと`updated_at`カラムが存在していると想定します。Eloquentはモデルが作成または更新されるときに、これらの列の値を自動的にセットします。これらのカラムがEloquentによって自動的に管理されないようにする場合は、モデルに`$timestamps`プロパティを定義し、`false`値をセットします。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Flight extends Model
    {
        /**
         * モデルにタイムスタンプを付けるか
         *
         * @var bool
         */
        public $timestamps = false;
    }

モデルのタイムスタンプのフォーマットをカスタマイズする必要がある場合は、モデルに`$dateFormat`プロパティを設定します。このプロパティはモデルが配列やJSONへシリアル化されるときに、日付属性がデータベースに格納される方法とその形式を決定します。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Flight extends Model
    {
        /**
         * モデルの日付カラムの保存用フォーマット
         *
         * @var string
         */
        protected $dateFormat = 'U';
    }

タイムスタンプの保存に使用するカラム名をカスタマイズする必要がある場合は、モデルに`CREATED_AT`および`UPDATED_AT`定数を定義してください。

    <?php

    class Flight extends Model
    {
        const CREATED_AT = 'creation_date';
        const UPDATED_AT = 'updated_date';
    }

<a name="database-connections"></a>
### データベース接続

デフォルトですべてのEloquentモデルは、アプリケーション用に設定したデフォルトのデータベース接続を使用します。特定のモデルと対話するときに別の接続を使用する必要がある場合は、モデルに`$connection`プロパティを定義する必要があります。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Flight extends Model
    {
        /**
         * このモデルが使用するデータベース接続
         *
         * @var string
         */
        protected $connection = 'sqlite';
    }

<a name="default-attribute-values"></a>
### デフォルト属性値

デフォルトでは、新しくインスタンス化するモデルインスタンスに属性値は含まれません。モデルの属性の一部にデフォルト値を定義したい場合は、モデルに`$attributes`プロパティを定義できます。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Flight extends Model
    {
        /**
         * モデルの属性のデフォルト値
         *
         * @var array
         */
        protected $attributes = [
            'delayed' => false,
        ];
    }

<a name="retrieving-models"></a>
## モデルの取得

モデルと[それと関連するデータベーステーブル](/docs/{{version}}/migrations#writing-migrations)を作成したら、データベースからデータを取得する準備が整いました。各Eloquentモデルは、モデルに関連付けたデータベーステーブルを流暢にクエリできる強力な[クエリビルダ](/docs/{{version}}/querys)と考えることができます。モデルの`all`メソッドは、モデルに関連付けたデータベーステーブルからすべてのレコードを取得します。

    use App\Models\Flight;

    foreach (Flight::all() as $flight) {
        echo $flight->name;
    }

<a name="building-queries"></a>
#### クエリの作成

Eloquentの`all`メソッドは、モデルのテーブルにあるすべての結果を返します。しかし、各Eloquentモデルは[クエリビルダ](/docs/{{version}}/クエリ)として機能するため、クエリに制約を追加してから`get`メソッドを呼び出し、結果を取得することもできます。

    $flights = Flight::where('active', 1)
                   ->orderBy('name')
                   ->take(10)
                   ->get();

> {tip} Eloquentモデルはクエリビルダであるため、Laravelの[クエリビルダ](/docs/{{version}}/querys)が提供するすべてのメソッドを確認する必要があります。Eloquentでクエリを作成するときは、それらすべてのメソッドを使用できます。

<a name="refreshing-models"></a>
#### モデルのリフレッシュ

データベースから取得したEloquentモデルのインスタンスがすでにある場合は、`fresh`メソッドと`refresh`メソッドを使用してモデルを「更新」できます。`fresh`メソッドは、データベースからモデルを再取得します。既存のモデルインスタンスは影響を受けません。

    $flight = Flight::where('number', 'FR 900')->first();

    $freshFlight = $flight->fresh();

`refresh`メソッドは、データベースからの新しいデータを使用して既存のモデルを再ハイドレートします。さらに、ロードしたすべてのリレーションも更新されます。

    $flight = Flight::where('number', 'FR 900')->first();

    $flight->number = 'FR 456';

    $flight->refresh();

    $flight->number; // "FR 900"

<a name="collections"></a>
### コレクション

これまで見てきたように、`all`や`get`のようなEloquentメソッドは、データベースから複数のレコードを取得します。ただし、これらのメソッドはプレーンなPHP配列を返しません。代わりに、`Illuminate\Database\Eloquent\Collection`のインスタンスが返されます。

Eloquent `Collection`クラスはLaravelの基本`Illuminate\Support\Collection`クラスを拡張し、データコレクションを操作するために[さまざまな便利なメソッド](/docs/{{version}}/collections#available-methods)を提供しています。たとえば、`reject`メソッドを使用して、呼び出されたクロージャの結果に基づいてコレクションからモデルを削除できます。

```php
$flights = Flight::where('destination', 'Paris')->get();

$flights = $flights->reject(function ($flight) {
    return $flight->cancelled;
});
```

Laravelの基本コレクションクラスによって提供されるメソッドに加えて、Eloquentコレクションクラスは、Eloquentコレクション操作に特化した[いくつかの追加メソッド](/docs/{{version}}/eloquent-collections#available-methods)も提供しています。

LaravelのコレクションはすべてPHPのiterableなインターフェイスを実装しているため、コレクションを配列のようにループ処理できます。

```php
foreach ($flights as $flight) {
    echo $flight->name;
}
```

<a name="chunking-results"></a>
### 結果の分割

`all`または`get`メソッドを使用して数万のEloquentレコードを読み込もうとすると、アプリケーションのメモリを不足させる可能性があります。これらのメソッドを使用する代わりに、`chunk`メソッドを使用して、多数のモデルをより効率的に処理してください。

`chunk`メソッドは、Eloquentモデルのサブセットを取得し、それらをクロージャに渡して処理します。Eloquentモデルの現在のチャンクのみ一度に取得されるため、`chunk`メソッドを使用すると大量のモデルを操作するときに、メモリ使用量が大幅に削減できます。

```php
use App\Models\Flight;

Flight::chunk(200, function ($flights) {
    foreach ($flights as $flight) {
        //
    }
});
```

`chunk`メソッドに渡す最初の引数は、「チャンク」ごとに受信するレコード数です。２番目の引数として渡すクロージャは、データベースから取得したチャンクごとに呼び出されます。レコードのチャンクを取得しクロージャへ渡すために、毎回データベースクエリを実行します。

結果を反復処理するときに、更新するカラムに基づいて`chunk`メソッドの結果をフィルタリングする場合は、`chunkById`メソッドを使用する必要があります。こうしたシナリオで`chunk`メソッドを使用すると、一貫性が無く予期しない結果を生じる可能性があります。内部的に`chunkById`メソッドは常に、前のチャンクの最後のモデルよりも大きい`id`カラムを持つモデルを取得します。

```php
Flight::where('departed', true)
    ->chunkById(200, function ($flights) {
        $flights->each->update(['departed' => false]);
    }, $column = 'id');
```

<a name="streaming-results-lazily"></a>
### ルーズなストリーミング結果

`lazy`メソッドは、裏でチャンク単位でクエリを実行するという意味で、[`chunk`メソッド](#chunking-results)と同様に動作します。しかし、`lazy`メソッドは、各チャンクをそのままコールバックへ渡すのではなく、フラット化したEloquentモデルの[`LazyCollection`](/docs/{{version}}/collections#lazy-collections)を返すので、結果を単一のストリームとして操作できます。

```php
use App\Models\Flight;

foreach (Flight::lazy() as $flight) {
    //
}
```

もし、`lazy`メソッドの結果を、結果の反復処理中に更新されるカラムに基づいてフィルタリングするのであれば、`lazyById`メソッドを使うべきです。内部的には、`lazyById`メソッドは、`id`カラムが前のチャンクの最後のモデルよりも大きいモデルを常に取得します。

```php
Flight::where('departed', true)
    ->lazyById(200, $column = 'id')
    ->each->update(['departed' => false]);
```

<a name="cursors"></a>
### カーソル

`lazy`メソッドと同様に、`cursor`メソッドを使用すると、何万ものEloquentモデルのレコードを反復処理する際に、アプリケーションのメモリ消費量を大幅に削減できます。

`cursor`メソッドは単一のデータベースクエリのみを実行します。ただし、個々のEloquentモデルは、実際の繰り返し処理までハイドレートされません。したがって、カーソルを反復処理している間、常に１つのEloquentモデルのみがメモリに保持されます。

> {note} `cursor`メソッドは一度に１つのEloquentモデルしかメモリに保持しないため、リレーションをEagerロードできません。リレーションシップをEagerロードする必要がある場合は、代わりに [`lazy`メソッド](#streaming-results-lazily) の使用を検討してください。

内部的には、`cursor`メソッドはPHPの[ジェネレータ](https://www.php.net/manual/en/language.generators.overview.php)を使ってこの機能を実装しています。

```php
use App\Models\Flight;

foreach (Flight::where('destination', 'Zurich')->cursor() as $flight) {
    //
}
```

`cursor`は`Illuminate\Support\LazyCollection`インスタンスを返します。[レイジーコレクション](/docs/{{version}}/collections#lazy-collections)を使用すると、一度に1つのモデルのみをメモリにロードしながら、一般的なLaravelコレクションで使用できる多くのコレクションメソッドを使用できます。

```php
use App\Models\User;

$users = User::cursor()->filter(function ($user) {
    return $user->id > 500;
});

foreach ($users as $user) {
    echo $user->id;
}
```

`cursor`メソッドは、通常のクエリよりもはるかに少ないメモリしか使用しませんが（一度に１つのEloquentモデルをメモリ内に保持するだけです）、それでも最終的にはメモリが不足するでしょう。これは、[PHPのPDOドライバが、素のクエリ結果をすべてバッファに内部的にキャッシュしているため](https://www.php.net/manual/en/mysqlinfo.concepts.buffering.php)です。非常に多くのEloquentレコードを扱う場合には、代わりに[`lazy`メソッド](#streaming-results-lazily)の使用を検討してください。

<a name="advanced-subqueries"></a>
### 上級サブクエリ

<a name="subquery-selects"></a>
#### サブクエリのSELECT

Eloquentは、高度なサブクエリサポートも提供します。これにより、単一のクエリで関連するテーブルから情報を取得できます。たとえば、フライトの「目的地」のテーブルと目的地への「フライト」のテーブルがあるとします。`flights`テーブルには、フライトが目的地に到着した時刻を示す`arrived_at`列が含まれています。

クエリビルダの`select`メソッドと`addSelect`メソッドで使用できるサブクエリ機能を使用すると、1つのクエリを使用して、すべての`destinations`とその目的地に最近到着したフライトの名前を選択できます。

    use App\Models\Destination;
    use App\Models\Flight;

    return Destination::addSelect(['last_flight' => Flight::select('name')
        ->whereColumn('destination_id', 'destinations.id')
        ->orderByDesc('arrived_at')
        ->limit(1)
    ])->get();

<a name="subquery-ordering"></a>
#### サブクエリの順序

さらに、クエリビルダの`orderBy`関数はサブクエリをサポートします。フライトの例を引き続き使用すると、この機能を使用して、最後のフライトが目的地へ到着した日時に基づいて、すべての目的地を並べ替えることができます。繰り返しますが、これは単一のデータベースクエリの実行中に実行できます。

    return Destination::orderByDesc(
        Flight::select('arrived_at')
            ->whereColumn('destination_id', 'destinations.id')
            ->orderByDesc('arrived_at')
            ->limit(1)
    )->get();

<a name="retrieving-single-models"></a>
## 単一モデル/集計の取得

特定のクエリに一致するすべてのレコードを取得することに加えて、`find`、`first`、または`firstWhere`メソッドを使用して単一のレコードを取得することもできます。モデルのコレクションを返す代わりに、これらのメソッドは単一のモデルインスタンスを返します。

    use App\Models\Flight;

    // 主キーでモデルを取得
    $flight = Flight::find(1);

    // クエリの制約に一致する最初のモデルを取得
    $flight = Flight::where('active', 1)->first();

    // クエリの制約に一致する最初のモデルを取得する別の記法
    $flight = Flight::firstWhere('active', 1);

クエリの最初の結果を取得したり、結果が見つからない場合は他のアクションを実行したい場合があります。`firstOr`メソッドは、クエリに一致する最初の結果を返すか、結果が見つからない場合は、指定されたクロージャを実行します。クロージャが返す値は、`firstOr`メソッドの結果と見なされます。

    $model = Flight::where('legs', '>', 3)->firstOr(function () {
        // ...
    });

<a name="not-found-exceptions"></a>
#### Not Found例外

モデルが見つからない場合は、例外を投げたい場合があります。これは、ルートやコントローラでとくに役立ちます。`findOrFail`メソッドと`firstOrFail`メソッドは、クエリの最初の結果を取得します。ただし、結果が見つからない場合は、`Illuminate\Database\Eloquent\ModelNotFoundException`を投げます。

    $flight = Flight::findOrFail(1);

    $flight = Flight::where('legs', '>', 3)->firstOrFail();

`ModelNotFoundException`をキャッチしない場合は、404 HTTPレスポンスをクライアントへ自動的に返送します。

    use App\Models\Flight;

    Route::get('/api/flights/{id}', function ($id) {
        return Flight::findOrFail($id);
    });

<a name="retrieving-or-creating-models"></a>
### モデルの取得／生成

`firstOrCreate`メソッドは、指定したカラムと値のペアを使用してデータベースレコードを見つけようとします。モデルがデータベースで見つからない場合は、最初の配列引数をオプションの２番目の配列引数とマージした結果の属性を含むレコードが挿入されます。

`firstOrNew`メソッドは`firstOrCreate`のように、指定された属性に一致するデータベース内のレコードを見つけようとします。ただし、モデルが見つからない場合は、新しいモデルインスタンスが返されます。`firstOrNew`によって返されるモデルは、まだデータベースに永続化されていないことに注意してください。永続化するには、手動で`save`メソッドを呼び出す必要があります。

    use App\Models\Flight;

    // 名前でフライトを取得するか、存在しない場合は作成する
    $flight = Flight::firstOrCreate([
        'name' => 'London to Paris'
    ]);

    // 名前でフライトを取得するか、name、delayed、arrival_time属性を使用してフライトを作成します。
    $flight = Flight::firstOrCreate(
        ['name' => 'London to Paris'],
        ['delayed' => 1, 'arrival_time' => '11:30']
    );

    // 名前でフライトを取得するか、新しいFlightインスタンスをインスタンス化
    $flight = Flight::firstOrNew([
        'name' => 'London to Paris'
    ]);

    // 名前でフライトを取得するか、name、delayed、arrival_time属性を使用してインスタンス化
    $flight = Flight::firstOrNew(
        ['name' => 'Tokyo to Sydney'],
        ['delayed' => 1, 'arrival_time' => '11:30']
    );

<a name="retrieving-aggregates"></a>
### 集計の取得

Eloquentモデルを操作するときは、Laravel [クエリビルダ](/docs/{{version}}/querys)が提供する`count`、`sum`、`max`、およびその他の[集計メソッド](/docs/{{version}}/queryes#aggregates)を使用することもできます。ご想像のとおり、これらのメソッドは、Eloquentモデルインスタンスの代わりにスカラー値を返します。

    $count = Flight::where('active', 1)->count();

    $max = Flight::where('active', 1)->max('price');

<a name="inserting-and-updating-models"></a>
## モデルの挿入と更新

<a name="inserts"></a>
### 挿入

もちろん、Eloquentを使用する状況は、データベースからモデルを取得する必要がある場合だけに限りません。新しいレコードを挿入する必要もあるでしょう。うれしいことに、Eloquentはこれをシンプルにします。データベースへ新しいレコードを挿入するには、新しいモデルインスタンスをインスタンス化し、モデルに属性をセットする必要があります。次に、モデルインスタンスで`save`メソッドを呼び出します。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Models\Flight;
    use Illuminate\Http\Request;

    class FlightController extends Controller
    {
        /**
         * 新しいフライトをデータベースに保存
         *
         * @param  \Illuminate\Http\Request  $request
         * @return \Illuminate\Http\Response
         */
        public function store(Request $request)
        {
            // リクエストのバリデーション処理…

            $flight = new Flight;

            $flight->name = $request->name;

            $flight->save();
        }
    }

この例では、受信HTTPリクエストの`name`フィールドを`App\Models\Flight`モデルインスタンスの`name`属性に割り当てます。`save`メソッドを呼び出すと、レコードがデータベースに挿入されます。モデルの`created_at`および`updated_at`タイムスタンプは、`save`メソッドが呼び出されたときに自動的に設定されるため、手動で設定する必要はありません。

もしくは、`create`メソッドを使用して、単一のPHPステートメントにより、新しいモデルを「保存」することもできます。`create`メソッドは、その挿入したモデルインスタンスを返します。

    use App\Models\Flight;

    $flight = Flight::create([
        'name' => 'London to Paris',
    ]);

ただし、`create`メソッドを使用する前に、モデルクラスで`fillable`または`guarded`プロパティを指定する必要があります。すべてのEloquentモデルはデフォルトで複数代入の脆弱性から保護されているため、こうしたプロパティが必須なのです。複数代入の詳細については、[複数代入のドキュメント](#mass-assignment)を参照してください。

<a name="updates"></a>
### 更新

`save`メソッドを使用して、データベースにすでに存在するモデルを更新することもできます。モデルを更新するには、モデルを取得して、更新する属性をセットする必要があります。次に、モデルの`save`メソッドを呼び出します。この場合も、`updated_at`タイムスタンプを自動的に更新するため、手動で値を設定する必要はありません。

    use App\Models\Flight;

    $flight = Flight::find(1);

    $flight->name = 'Paris to London';

    $flight->save();

<a name="mass-updates"></a>
#### 複数更新

特定のクエリに一致するモデルに対して更新を実行することもできます。この例では、「アクティブ（`active`）」で`destination`が`San Diego`のすべてのフライトが遅延（delayed）としてマークされます。

    Flight::where('active', 1)
          ->where('destination', 'San Diego')
          ->update(['delayed' => 1]);

`update`メソッドは、更新する必要のあるカラムを表すカラム名と値のペアの配列を引数に取ります。

> {note} Eloquentを介して一括更新を発行する場合、更新されたモデルに対して、`saving`、`saved`、`updating`、`updated`モデルイベントは発生しません。これは一括更新を実行する場合に、モデルが実際には取得されないからです。

<a name="examining-attribute-changes"></a>
#### 属性の変更の判断

Eloquentでは、`isDirty`、`isClean`、`wasChanged`メソッドを提供しており、モデルの内部状態を調べ、モデルが最初に取得されたときからその属性がどのように変更されたかを判別できます。

`isDirty`メソッドは、モデルが取得されてからモデルの属性のいずれかが変更されたかどうかを判別します。特定の属性名を`isDirty`メソッドに渡し、その属性がダーティであるかどうかを判断できます。`isClean`は、モデルが取得されてから属性が変更されていないことを判別します。このメソッドもオプションとして属性を引数に指定できます。

    use App\Models\User;

    $user = User::create([
        'first_name' => 'Taylor',
        'last_name' => 'Otwell',
        'title' => 'Developer',
    ]);

    $user->title = 'Painter';

    $user->isDirty(); // true
    $user->isDirty('title'); // true
    $user->isDirty('first_name'); // false

    $user->isClean(); // false
    $user->isClean('title'); // false
    $user->isClean('first_name'); // true

    $user->save();

    $user->isDirty(); // false
    $user->isClean(); // true

`wasChanged`メソッドは現在のリクエストサイクル内で、モデルの最後の保存時に、属性に変更が起きたかを判別します。必要に応じ属性名を渡して、その属性に変更が発生したか確認できます。

    $user = User::create([
        'first_name' => 'Taylor',
        'last_name' => 'Otwell',
        'title' => 'Developer',
    ]);

    $user->title = 'Painter';

    $user->save();

    $user->wasChanged(); // true
    $user->wasChanged('title'); // true
    $user->wasChanged('first_name'); // false

`getOriginal`メソッドは、モデル取得後の変更操作と関係なく、モデルの元の属性を含む配列を返します。必要に応じて、特定の属性名を渡し、その属性の元の値を取得できます。

    $user = User::find(1);

    $user->name; // John
    $user->email; // john@example.com

    $user->name = "Jack";
    $user->name; // Jack

    $user->getOriginal('name'); // John
    $user->getOriginal(); // 元の属性の配列

<a name="mass-assignment"></a>
### 複数代入

`create`メソッドを使用して、単一PHPステートメントで新しいモデルを「保存」できます。挿入したモデルインスタンスが、このメソッドにより返されます。

    use App\Models\Flight;

    $flight = Flight::create([
        'name' => 'London to Paris',
    ]);

ただし、`create`メソッドを使用する前に、モデルクラスで`fillable`または`guarded`プロパティを指定する必要があります。すべてのEloquentモデルはデフォルトで複数代入の脆弱性から保護されているため、こうしたプロパティが必須になります。

複数代入の脆弱性は、ユーザーから予期していないHTTPリクエストフィールドを渡され、そのフィールドがデータベース内の予想外のカラムを変更する場合に発生します。たとえば、悪意のあるユーザーがHTTPリクエストを介して`is_admin`パラメータを送信し、それがモデルの`create`メソッドに渡されて、ユーザーが自分自身を管理者に格上げする場合が考えられます。

したがって、Eloquentを使い始めるには、複数代入可能にするモデル属性を定義する必要があります。これは、モデルの`$fillable`プロパティを使用して行います。たとえば、`Flight`モデルの`name`属性を一括割り当て可能にしましょう。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Flight extends Model
    {
        /**
         * 複数代入可能な属性
         *
         * @var array
         */
        protected $fillable = ['name'];
    }

複数代入可能な属性を指定したら、`create`メソッドを使用してデータベースに新しいレコードを挿入できます。`create`メソッドは、新しく作成したモデルインスタンスを返します。

    $flight = Flight::create(['name' => 'London to Paris']);

モデルインスタンスがすでにある場合は、`fill`メソッドを使用して、属性の配列をセットできます。

    $flight->fill(['name' => 'Amsterdam to Frankfurt']);

<a name="mass-assignment-json-columns"></a>
#### 一括割り当てとJSONカラム

JSONカラムへ代入するときは、各カラムの複数代入可能キーをモデルの`$fillable`配列で指定する必要があります。セキュリティのため、Laravelは`guarded`プロパティを使用する場合のネストしたJSON属性の更新をサポートしていません。

    /**
     * 複数代入可能な属性
     *
     * @var array
     */
    protected $fillable = [
        'options->enabled',
    ];

<a name="allowing-mass-assignment"></a>
#### 複数代入の許可

すべての属性を一括割り当て可能にしたい場合は、モデルの`$guarded`プロパティを空の配列として定義します。モデルの保護を解除する場合は、Eloquentの`fill`、`create`、および`update`メソッドに渡たす配列へいちいち特別な注意を払う必要があります。

    /**
     * 複数代入不可能な属性
     *
     * @var array
     */
    protected $guarded = [];

<a name="upserts"></a>
### 更新／挿入

既存のモデルを更新する時に、一致するモデルが存在しない場合は、新しいモデルを作成したい場合もあるでしょう。`firstOrCreate`メソッドと同様に、`updateOrCreate`メソッドはモデルを永続化するため、手動で`save`メソッドを呼び出す必要はありません。

以下の例では、`Oakland`の「出発（`departure`）」場所と`San Diego`の「目的地（`destination`）」でフライトが存在する場合、その「価格（`price`）」カラムと「割引（`discounted`）」カラムが更新されます。該当するフライトが存在しない場合は、最初の引数配列を２番目の引数配列とマージした結果の属性を持つ新しいフライトが作成されます。

    $flight = Flight::updateOrCreate(
        ['departure' => 'Oakland', 'destination' => 'San Diego'],
        ['price' => 99, 'discounted' => 1]
    );

1つのクエリで複数の「アップサート」を実行する場合は、代わりに「アップサート」メソッドを使用する必要があります。メソッドの最初の引数は、挿入または更新する値で構成され、2番目の引数は、関連付けられたテーブル内のレコードを一意に識別するカラムをリストします。メソッドの最後で３番目の引数は、一致するレコードがデータベースですでに存在する場合に更新する必要があるカラムの配列です。モデルのタイムスタンプが有効になっている場合、`upsert`メソッドは`created_at`と`updated_at`のタイムスタンプを自動的に設定します。

    Flight::upsert([
        ['departure' => 'Oakland', 'destination' => 'San Diego', 'price' => 99],
        ['departure' => 'Chicago', 'destination' => 'New York', 'price' => 150]
    ], ['departure', 'destination'], ['price']);

> {note} SQLServerを除くすべてのデータベースシステムでは、`upsert`メソッドに提供される2番目の引数のカラムに「プライマリ」または「一意の」インデックスが必要です。

<a name="deleting-models"></a>
## モデルの削除

モデルを削除するには、モデルインスタンスで`delete`メソッドを呼び出してください。

    use App\Models\Flight;

    $flight = Flight::find(1);

    $flight->delete();

モデルに関連しているすべてのデータベースレコードを削除するには、`truncate`メソッドを呼びだせます。`truncate`操作は、モデルの関連テーブルの自動増分IDをリセットします。

    Flight::truncate();

<a name="deleting-an-existing-model-by-its-primary-key"></a>
#### 主キーによる既存のモデルの削除

上記の例では、`delete`メソッドを呼び出す前にデータベースからモデルを取得しています。しかし、モデルの主キーがわかっている場合は、`destroy`メソッドを呼び出して、モデルを明示的に取得せずにモデルを削除できます。`destroy`メソッドは、単一の主キーを受け入れることに加えて、複数の主キー、主キーの配列、または主キーの[コレクション](/docs/{{version}}/collections)を引数に取ります。

    Flight::destroy(1);

    Flight::destroy(1, 2, 3);

    Flight::destroy([1, 2, 3]);

    Flight::destroy(collect([1, 2, 3]));

> {note} `destroy`メソッドは各モデルを個別にロードし、`delete`メソッドを呼び出して、`deleting`イベントと`deleted`イベントが各モデルに適切にディスパッチされるようにします。

<a name="deleting-models-using-queries"></a>
#### クエリを使用したモデルの削除

もちろん、Eloquentクエリを作成して、クエリの条件に一致するすべてのモデルを削除することもできます。この例では、非アクティブとしてマークされているすべてのフライトを削除します。一括更新と同様に、一括削除では、削除されたモデルのモデルイベントはディスパッチされません。

    $deletedRows = Flight::where('active', 0)->delete();

> {note} Eloquentを介して一括削除ステートメントを実行すると、削除されたモデルに対して`deleting`および`deleted`モデルイベントがディスパッチされません。これは、deleteステートメントの実行時にモデルが実際には取得されないためです。

<a name="soft-deleting"></a>
### ソフトデリート

Eloquentは、データベースから実際にレコードを削除するだけでなく、モデルを「ソフトデリート」することもできます。モデルがソフト削除されても、実際にはデータベースから削除されません。代わりに、モデルに「deleted_at」属性がセットされ、モデルを「削除」した日時が保存されます。モデルのソフト削除を有効にするには、「Illuminate\Database\Eloquent\SoftDeletes」トレイトをモデルに追加します。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;
    use Illuminate\Database\Eloquent\SoftDeletes;

    class Flight extends Model
    {
        use SoftDeletes;
    }

> {tip} SoftDeletes`トレイトは、`deleted_at`属性を`DateTime`/`Carbon`インスタンスに自動的にキャストします。

データベーステーブルに`deleted_at`カラムを追加する必要があります。Laravel[スキーマビルダ](/docs/{{version}}/migrations)はこのカラムを作成するためのヘルパメソッドを用意しています。

    use Illuminate\Database\Schema\Blueprint;
    use Illuminate\Support\Facades\Schema;

    Schema::table('flights', function (Blueprint $table) {
        $table->softDeletes();
    });

    Schema::table('flights', function (Blueprint $table) {
        $table->dropSoftDeletes();
    });

これで、モデルの`delete`メソッドを呼び出すと、`deleted_at`列が現在の日付と時刻に設定されます。ただし、モデルのデータベースレコードはテーブルに残ります。ソフト削除を使用するモデルをクエリすると、ソフト削除されたモデルはすべてのクエリ結果から自動的に除外されます。

特定のモデルインスタンスがソフト削除されているかを判断するには、`trashed`メソッドを使用します。

    if ($flight->trashed()) {
        //
    }

<a name="restoring-soft-deleted-models"></a>
#### ソフト削除したモデルの復元

ソフト削除したモデルを「削除解除」したい場合もあるでしょう。ソフト削除したモデルを復元するには、モデルインスタンスの`restore`メソッドを呼び出します。`restore`メソッドは、モデルの`deleted_at`カラムを`null`にセットします。

    $flight->restore();

クエリで`restore`メソッドを使用して、複数のモデルを復元することもできます。繰り返しますが、他の「複数」操作と同様に、これは復元されたモデルのモデルイベントをディスパッチしません。

    Flight::withTrashed()
            ->where('airline_id', 1)
            ->restore();

`restore`メソッドは、[リレーション]](/docs/{{version}}/eloquent-relationships)のクエリを作成するときにも使用できます。

    $flight->history()->restore();

<a name="permanently-deleting-models"></a>
#### モデルの完全な削除

データベースからモデルを本当に削除する必要が起きる場合もあるでしょう。`forceDelete`メソッドを使用して、データベーステーブルからソフト削除されたモデルを完全に削除できます。

    $flight->forceDelete();

Eloquentリレーションクエリを作成するときに、`forceDelete`メソッドを使用することもできます。

    $flight->history()->forceDelete();

<a name="querying-soft-deleted-models"></a>
### ソフトデリート済みモデルのクエリ

<a name="including-soft-deleted-models"></a>
#### ソフト削除モデルを含める

上記のように、ソフト削除したモデルはクエリ結果から自動的に除外されます。ただし、クエリで`withTrashed`メソッドを呼び出すことにより、ソフト削除したモデルをクエリの結果に含められます。

    use App\Models\Flight;

    $flights = Flight::withTrashed()
                    ->where('account_id', 1)
                    ->get();

`withTrashed`メソッドは、[リレーション](/docs/{{version}}/eloquent-relationships)クエリを作成するときにも呼び出すことができます。

    $flight->history()->withTrashed()->get();

<a name="retrieving-only-soft-deleted-models"></a>
#### ソフト削除モデルのみを取得する

`onlyTrashed`メソッドは、ソフト削除したモデル**のみ**取得します。

    $flights = Flight::onlyTrashed()
                    ->where('airline_id', 1)
                    ->get();

<a name="replicating-models"></a>
## モデルの複製

`replicate`メソッドを使用して、既存のモデルインスタンスの未保存のコピーを作成できます。この方法は、同じ属性を多く共有するモデルインスタンスがある場合にとくに役立ちます。

    use App\Models\Address;

    $shipping = Address::create([
        'type' => 'shipping',
        'line_1' => '123 Example Street',
        'city' => 'Victorville',
        'state' => 'CA',
        'postcode' => '90001',
    ]);

    $billing = $shipping->replicate()->fill([
        'type' => 'billing'
    ]);

    $billing->save();

<a name="query-scopes"></a>
## クエリスコープ

<a name="global-scopes"></a>
### グローバルスコープ

グローバルスコープを使用すると、特定のモデルのすべてのクエリに制約を追加できます。Laravel独自の[ソフトデリート](#soft-deleting)機能は、グローバルスコープを利用してデータベースから「削除していない」モデルのみを取得します。独自のグローバルスコープを作成すれば、指定したモデルですべてのクエリが同じ制約を受けるようにする、便利で簡単な方法が利用できます。

<a name="writing-global-scopes"></a>
#### グローバルスコープの作成

グローバルスコープの作成は簡単です。まず、`Illuminate\Database\Eloquent\Scope`インターフェイスの実装クラスを定義します。Laravelには、スコープクラスを配置する決まった場所がないため、このクラスは任意のディレクトリへ自由に配置できます。

`Scope`インターフェイスでは、`apply`という１つのメソッドを実装する必要があります。`apply`メソッドは、必要に応じて`where`制約または他のタイプの句をクエリに追加できます。

    <?php

    namespace App\Scopes;

    use Illuminate\Database\Eloquent\Builder;
    use Illuminate\Database\Eloquent\Model;
    use Illuminate\Database\Eloquent\Scope;

    class AncientScope implements Scope
    {
        /**
         * 指定のEloquentクエリビルダにスコープを適用
         *
         * @param  \Illuminate\Database\Eloquent\Builder  $builder
         * @param  \Illuminate\Database\Eloquent\Model  $model
         * @return void
         */
        public function apply(Builder $builder, Model $model)
        {
            $builder->where('created_at', '<', now()->subYears(2000));
        }
    }

> {tip} グローバルスコープがクエリのSELECT句にカラムを追加する場合は、`select`の代わりに`addSelect`メソッドを使用する必要があります。これにより、クエリの既存のselect句が意図せず置き換えられるのを防ぐことができます。

<a name="applying-global-scopes"></a>
#### グローバルスコープの適用

モデルにグローバルスコープを割り当てるには、モデルの`booted`メソッドをオーバーライドし、モデルの`addGlobalScope`メソッドを呼び出す必要があります。`addGlobalScope`メソッドは、スコープのインスタンスだけを引数に取ります。

    <?php

    namespace App\Models;

    use App\Scopes\AncientScope;
    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * モデルの「起動」メソッド
         *
         * @return void
         */
        protected static function booted()
        {
            static::addGlobalScope(new AncientScope);
        }
    }

上記の例のスコープを`App\Models\User`モデルに追加した後、`User::all()`メソッドを呼び出すと、次のSQLクエリが実行されます。

```sql
select * from `users` where `created_at` < 0021-02-18 00:00:00
```

<a name="anonymous-global-scopes"></a>
#### 匿名のグローバルスコープ

Eloquenはクロージャを使用してグローバルスコープを定義することもできます。クロージャを使用してグローバルスコープを定義する場合は、`addGlobalScope`メソッドの第一引数に自分で選択したスコープ名を指定する必要があります。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Builder;
    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * モデルの「起動」メソッド
         *
         * @return void
         */
        protected static function booted()
        {
            static::addGlobalScope('ancient', function (Builder $builder) {
                $builder->where('created_at', '<', now()->subYears(2000));
            });
        }
    }

<a name="removing-global-scopes"></a>
#### グローバルスコープの削除

特定のクエリのグローバルスコープを削除する場合は、`withoutGlobalScope`メソッドを使用できます。このメソッドは、グローバルスコープのクラス名だけを引数に取ります。

    User::withoutGlobalScope(AncientScope::class)->get();

もしくは、クロージャを使用してグローバルスコープを定義した場合は、グローバルスコープへ指定した文字列名を渡す必要があります。

    User::withoutGlobalScope('ancient')->get();

クエリのグローバルスコープのいくつか、またはすべてを削除したい場合は、`withoutGlobalScopes`メソッドを使用できます。

    // すべてのグローバルスコープを削除
    User::withoutGlobalScopes()->get();

    // グローバルスコープの一部を削除
    User::withoutGlobalScopes([
        FirstScope::class, SecondScope::class
    ])->get();

<a name="local-scopes"></a>
### ローカルスコープ

ローカルスコープを使用すると、アプリケーション全体で簡単に再利用できる、共通のクエリ制約を定義できます。たとえば、「人気がある（popular）」と思われるすべてのユーザーを頻繁に取得する必要があるとしましょう。スコープを定義するには、Eloquentモデルメソッドの前に`scope`を付けます。

スコープは常にクエリビルダインスタンスを返す必要があります。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * 人気のあるユーザーのみを含むようにクエリのスコープを設定
         *
         * @param  \Illuminate\Database\Eloquent\Builder  $query
         * @return \Illuminate\Database\Eloquent\Builder
         */
        public function scopePopular($query)
        {
            return $query->where('votes', '>', 100);
        }

        /**
         * アクティブユーザーのみを含むようにクエリのスコープを設定
         *
         * @param  \Illuminate\Database\Eloquent\Builder  $query
         * @return \Illuminate\Database\Eloquent\Builder
         */
        public function scopeActive($query)
        {
            return $query->where('active', 1);
        }
    }

<a name="utilizing-a-local-scope"></a>
#### ローカルスコープの利用

スコープを定義したら、モデルをクエリするときにスコープメソッドを呼び出すことができます。ただし、メソッドを呼び出すときに`scope`プレフィックスを含めないでください。さまざまなスコープに呼び出しをチェーンすることもできます。

    use App\Models\User;

    $users = User::popular()->active()->orderBy('created_at')->get();

`or`クエリ演算子を介して複数のEloquentモデルスコープを組み合わせるには、正しい[論理グループ化](/docs/{{version}}/queries#logical-grouping)を実現するためにクロージャを使用する必要のある場合があります。

    $users = User::popular()->orWhere(function (Builder $query) {
        $query->active();
    })->get();

ただし、これは面倒な場合があるため、Laravelは、クロージャを使用せずにスコープを流暢にチェーンできる「高次」の「orWhere」メソッドを提供しています。

    $users = App\Models\User::popular()->orWhere->active()->get();

<a name="dynamic-scopes"></a>
#### 動的スコープ

パラメータを受け入れるスコープを定義したい場合もあるでしょう。使用するには、スコープメソッドの引数にパラメータを追加するだけです。スコープパラメータは、`$query`パラメータの後に定義する必要があります。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * 特定のタイプのユーザーのみを含むようにクエリのスコープを設定
         *
         * @param  \Illuminate\Database\Eloquent\Builder  $query
         * @param  mixed  $type
         * @return \Illuminate\Database\Eloquent\Builder
         */
        public function scopeOfType($query, $type)
        {
            return $query->where('type', $type);
        }
    }

期待される引数をスコープメソッドの引数へ追加したら、スコープ呼び出し時に引数を渡すことができます。

    $users = User::ofType('admin')->get();

<a name="comparing-models"></a>
## モデルの比較

２つのモデルが「同じ」であるかを判定する必要がある場合があるでしょう。２つのモデルに同じ主キー、テーブル、およびデータベース接続があるかどうかを手早く検証するために、`is`と`isNot`メソッドを使用できます。

    if ($post->is($anotherPost)) {
        //
    }

    if ($post->isNot($anotherPost)) {
        //
    }

`is`と`isNot`メソッドは、`belongsTo`、`hasOne`、`morphTo`、`morphOne`[リレーション](/docs/{{version}}/eloquent-relationships)を使用するときにも利用できます。このメソッドはそのモデルを取得するためにクエリを発行せず、関連モデルと比較したい場合、特に役立ちます。

    if ($post->author()->is($user)) {
        //
    }

<a name="events"></a>
## イベント

Eloquentモデルはいくつかのイベントをディスパッチし、モデルのライフサイクルの以下の瞬間をフックできるようにしています。：`retrieved`、`creating`、`created`、`updating`、`updated`、`saving`、`saved`、`deleting`、`deleted`、`restoring`、`restored`、`replicating`。

`retrieved`イベントは、既存のモデルをデータベースから取得したときにディスパッチします。新しいモデルをはじめて保存するときは、`creating`イベントと`created`イベントをディスパッチします。`updating`／`updated`イベントは、既存のモデルを変更し、`save`メソッドが呼び出されたときにディスパッチします。`saving`／`saved`イベントは、モデルを作成または更新したときにディスパッチします。モデルの属性に変化がない場合でも、ディスパッチします。

モデルイベントのリッスンを開始するには、Eloquentモデルで`$dispatchesEvents`プロパティを定義します。このプロパティは、Eloquentモデルのライフサイクルのさまざまなポイントを独自の[イベントクラス](/docs/{{version}}/events)にマップします。各モデルイベントクラスはコンストラクターにより、影響を受けるモデルのインスタンスを引数に受け取ります。

    <?php

    namespace App\Models;

    use App\Events\UserDeleted;
    use App\Events\UserSaved;
    use Illuminate\Foundation\Auth\User as Authenticatable;

    class User extends Authenticatable
    {
        use Notifiable;

        /**
         * モデルのイベントマップ
         *
         * @var array
         */
        protected $dispatchesEvents = [
            'saved' => UserSaved::class,
            'deleted' => UserDeleted::class,
        ];
    }

Eloquentイベントを定義してマッピングした後は、そのイベントを処理するために[イベントリスナ](https://laravel.com/docs/{{version}}/events#defining-listeners)を使用します。

> {note} Eloquentを介して一括更新または削除クエリを発行する場合、影響を受けるモデルに対して、`saved`、`updated`、`deleting`、`deleted`モデルイベントをディスパッチしません。これは、一括更新または一括削除を実行するときにモデルを実際に取得しないためです。

<a name="events-using-closures"></a>
### クロージャの使用

カスタムイベントクラスを使用する代わりに、さまざまなモデルイベントがディスパッチされたときに実行するクロージャを登録できます。通常、これらのクロージャはモデルの「booted」メソッドで登録する必要があります。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * モデルの「起動」メソッド
         *
         * @return void
         */
        protected static function booted()
        {
            static::created(function ($user) {
                //
            });
        }
    }

必要に応じて、モデルイベントを登録するときに、[キュー投入可能な匿名イベントリスナ](/docs/{{version}}/events#queuable-anonymous-event-listeners)を利用できます。これにより、アプリケーションの[キュー](/docs/{{version}}/queues)を使用し、バックグラウンドでモデルイベントリスナを実行するようにLaravelに指示できます。

    use function Illuminate\Events\queueable;

    static::created(queueable(function ($user) {
        //
    }));

<a name="observers"></a>
### オブザーバ

<a name="defining-observers"></a>
#### オブザーバーの定義

特定のモデルで多くのイベントをリッスンしている場合は、オブザーバーを使用してすべてのリスナを1つのクラスにグループ化できます。オブザーバークラスは、リッスンするEloquentイベントを反映するメソッド名を持っています。これらの各メソッドは、唯一影響を受けるモデルを引数に取ります。`make:observer` Artisanコマンドは、新しいオブザーバークラスを作成するもっとも簡単な方法です。

    php artisan make:observer UserObserver --model=User

このコマンドは、新しいオブザーバーを`App/Observers`ディレクトリに配置します。このディレクトリが存在しない場合は、Artisanが作成します。新しいオブザーバーは以下のようになります。

    <?php

    namespace App\Observers;

    use App\Models\User;

    class UserObserver
    {
        /**
         * ユーザーの"created"イベントの処理
         *
         * @param  \App\Models\User  $user
         * @return void
         */
        public function created(User $user)
        {
            //
        }

        /**
         * ユーザーの"updated"イベントの処理
         *
         * @param  \App\Models\User  $user
         * @return void
         */
        public function updated(User $user)
        {
            //
        }

        /**
         * ユーザーの"deleted"イベントの処理
         *
         * @param  \App\Models\User  $user
         * @return void
         */
        public function deleted(User $user)
        {
            //
        }

        /**
         * ユーザーの"forceDeleted"イベントの処理
         *
         * @param  \App\Models\User  $user
         * @return void
         */
        public function forceDeleted(User $user)
        {
            //
        }
    }

オブザーバーを登録するには、監視するモデルで`observe`メソッドを呼び出す必要があります。アプリケーションの`App\Providers\EventServiceProvider`サービスプロバイダの`boot`メソッドにオブザーバーを登録できます。

    use App\Models\User;
    use App\Observers\UserObserver;

    /**
     * アプリケーションの全イベントの登録
     *
     * @return void
     */
    public function boot()
    {
        User::observe(UserObserver::class);
    }

<a name="observers-and-database-transactions"></a>
#### オブザーバとデータベーストランザクション

データベーストランザクション内でモデルを作成している場合、データベーストランザクションがコミットされた後にのみイベントハンドラを実行するようにオブザーバへ指示したい場合があるでしょう。これを実現するには、オブザーバで`$afterCommit`プロパティを定義します。データベーストランザクションが進行中でなければ、イベントハンドラは直ちに実行されます。

    <?php

    namespace App\Observers;

    use App\Models\User;

    class UserObserver
    {
        /**
         * すべてのトランザクションがコミットされた後にイベントを処理
         *
         * @var bool
         */
        public $afterCommit = true;

        /**
         * ユーザーの"created"イベントを処理
         *
         * @param  \App\Models\User  $user
         * @return void
         */
        public function created(User $user)
        {
            //
        }
    }

<a name="muting-events"></a>
### イベントのミュート

モデルによって発生したすべてのイベントを一時的に「ミュート」したい場合も起きるでしょう。これは、`withoutEvents`メソッドを使用して可能です。`withoutEvents`メソッドは、クロージャを唯一の引数に取ります。このクロージャ内で実行されたコードは、モデルイベントをディスパッチしません。たとえば、次の例では、モデルイベントをディスパッチせずに、`App\Models\User`インスタンスをフェッチして削除します。クロージャが返す値はすべて、`withoutEvents`メソッドが返します。

    use App\Models\User;

    $user = User::withoutEvents(function () use () {
        User::findOrFail(1)->delete();

        return User::find(2);
    });

<a name="saving-a-single-model-without-events"></a>
#### イベントなしの単一モデル保存

イベントをディスパッチせずに、特定のモデルを「保存」したい場合があります。その場合は、`saveQuietly`メソッドを使用してください。

    $user = User::findOrFail(1);

    $user->name = 'Victoria Faith';

    $user->saveQuietly();
