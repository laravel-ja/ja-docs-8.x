# Eloquent：利用の開始

- [イントロダクション](#introduction)
- [モデル定義](#defining-models)
    - [Eloquentモデル規約](#eloquent-model-conventions)
    - [デフォルト属性値](#default-attribute-values)
- [モデルの取得](#retrieving-models)
    - [コレクション](#collections)
    - [結果の分割](#chunking-results)
    - [上級のサブクエリ](#advanced-subqueries)
- [１モデル／集計の取得](#retrieving-single-models)
    - [集計の取得](#retrieving-aggregates)
- [モデルの追加と更新](#inserting-and-updating-models)
    - [Inserts](#inserts)
    - [Updates](#updates)
    - [複数代入](#mass-assignment)
    - [他の生成メソッド](#other-creation-methods)
- [モデル削除](#deleting-models)
    - [ソフトデリート](#soft-deleting)
    - [ソフトデリート済みモデルのクエリ](#querying-soft-deleted-models)
- [複製モデル](#replicating-models)
- [クエリスコープ](#query-scopes)
    - [グローバルスコープ](#global-scopes)
    - [ローカルスコープ](#local-scopes)
- [モデルの比較](#comparing-models)
- [イベント](#events)
    - [クロージャの使用](#events-using-closures)
    - [オブザーバ](#observers)
    - [イベントのミュート](#muting-events)

<a name="introduction"></a>
## イントロダクション

Eloquent ORMはLaravelに含まれている、美しくシンプルなアクティブレコードによるデーター操作の実装です。それぞれのデータベーステーブルは関連する「モデル」と結びついています。モデルによりテーブル中のデータをクエリできますし、さらに新しいレコードを追加することもできます。

使用開始前に`config/database.php`を確実に設定してください。データベースの詳細は[ドキュメント](/docs/{{version}}/database#configuration)で確認してください。

<a name="defining-models"></a>
## モデル定義

開始するには、まずEloquentモデルを作成しましょう。通常モデルは`app\Models`ディレクトリ下に置きますが、`composer.json`ファイルでオートロードするように指定した場所であれば、どこでも自由に設置できます。すべてのEloquentモデルは、`Illuminate\Database\Eloquent\Model`を拡張する必要があります。

モデルを作成する一番簡単な方法は`make:model` [Artisanコマンド](/docs/{{version}}/artisan)を使用することです。

    php artisan make:model Flight

モデル作成時に[データベースマイグレーション](/docs/{{version}}/migrations)も生成したければ、`--migration`か`-m`オプションを使ってください。

    php artisan make:model Flight --migration

    php artisan make:model Flight -m

ファクトリやシーダ、コントローラなど、さまざまな他のクラスはモデル生成時に生成できます。さらに、これらのオプションを組み合わせ、一度に複数のクラスを生成できます。

    php artisan make:model Flight --factory
    php artisan make:model Flight -f

    php artisan make:model Flight --seed
    php artisan make:model Flight -s

    php artisan make:model Flight --controller
    php artisan make:model Flight -c

    php artisan make:model Flight -mfsc

<a name="eloquent-model-conventions"></a>
### Eloquentモデル規約

では`flights`データベーステーブルに情報を保存し、取得するために使用する`Flight`モデルクラスを例として見てください。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Flight extends Model
    {
        //
    }

#### テーブル名

`Flight`モデルにどのテーブルを使用するか、Eloquentに指定していない点に注目してください。他の名前を明示的に指定しない限り、クラス名を複数形の「スネークケース」にしたものが、テーブル名として使用されます。今回の例で、Eloquentは`Flight`モデルを`flights`テーブルに保存します。`AirTrafficController`モデルの場合は、`air_traffic_controllers`テーブルに保存します。

モデルに`table`プロパティを定義することでテーブル名を自分で指定できます：

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Flight extends Model
    {
        /**
         * モデルと関連しているテーブル
         *
         * @var string
         */
        protected $table = 'my_flights';
    }

#### 主キー

Eloquentはさらにテーブルの主キーが`id`というカラム名であると想定しています。この規約をオーバーライドする場合は、protectedの`primaryKey`プロパティを定義してください。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Flight extends Model
    {
        /**
         * テーブルの主キー
         *
         * @var string
         */
        protected $primaryKey = 'flight_id';
    }

さらに、Eloquentは主キーを自動増分される整数値であるとも想定しています。つまり、デフォルト状態で主キーは自動的に`int`へキャストされます。自動増分ではない、もしくは整数値ではない主キーを使う場合、モデルにpublicの`$incrementing`プロパティを用意し、`false`をセットしてください。

    <?php

    class Flight extends Model
    {
        /**
         * IDが自動増分されるか
         *
         * @var bool
         */
        public $incrementing = false;
    }

主キーが整数でない場合は、モデルのprotectedの`$keyType`プロパティへ`string`値を設定してください。

    <?php

    class Flight extends Model
    {
        /**
         * 自動増分IDの「タイプ」
         *
         * @var string
         */
        protected $keyType = 'string';
    }

#### タイムスタンプ

デフォルトでEloquentはデータベース上に存在する`created_at`(作成時間)と`updated_at`(更新時間)カラムを自動的に更新します。これらのカラムの自動更新をEloquentにしてほしくない場合は、モデルの`$timestamps`プロパティを`false`に設定してください。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Flight extends Model
    {
        /**
         * モデルのタイムスタンプを更新するかの指示
         *
         * @var bool
         */
        public $timestamps = false;
    }

タイムスタンプのフォーマットをカスタマイズする必要があるなら、モデルの`$dateFormat`プロパティを設定してください。このプロパティはデータベースに保存される日付属性のフォーマットを決めるために使用されると同時に、配列やJSONへシリアライズする時にも使われます。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Flight extends Model
    {
        /**
         * モデルの日付カラムの保存フォーマット
         *
         * @var string
         */
        protected $dateFormat = 'U';
    }

タイムスタンプを保存するカラム名をカスタマイズする必要がある場合、モデルに`CREATED_AT`と`UPDATED_AT`定数を設定してください。

    <?php

    class Flight extends Model
    {
        const CREATED_AT = 'creation_date';
        const UPDATED_AT = 'last_update';
    }

#### データベース接続

Eloquentモデルはデフォルトとして、アプリケーションに設定されているデフォルトのデータベース接続を使用します。モデルで異なった接続を指定したい場合は、`$connection`プロパティを使用します。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Flight extends Model
    {
        /**
         * モデルで使用するコネクション名
         *
         * @var string
         */
        protected $connection = 'connection-name';
    }

<a name="default-attribute-values"></a>
### デフォルト属性値

あるモデルの属性にデフォルト値を指定したい場合は、そのモデルに`$attributes`プロパティを定義してください。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Flight extends Model
    {
        /**
         * 属性に対するモデルのデフォルト値
         *
         * @var array
         */
        protected $attributes = [
            'delayed' => false,
        ];
    }

<a name="retrieving-models"></a>
## モデルの取得

モデルと[対応するデータベーステーブル](/docs/{{version}}/migrations#writing-migrations)を作成したら、データベースからデータを取得できるようになりました。各Eloquentモデルは、対応するデータベーステーブルへすらすらとクエリできるようにしてくれる[クエリビルダ](/docs/{{version}}/queries)だと考えてください。例を見てください。

    <?php

    $flights = App\Models\Flight::all();

    foreach ($flights as $flight) {
        echo $flight->name;
    }

#### 制約の追加

Eloquentの`all`メソッドはモデルテーブルの全レコードを結果として返します。Eloquentモデルは[クエリビルダ](/docs/{{version}}/queries)としても動作しますのでクエリに制約を付け加えることもでき、結果を取得するには`get`メソッドを使用します。

    $flights = App\Models\Flight::where('active', 1)
                   ->orderBy('name', 'desc')
                   ->take(10)
                   ->get();

> {tip} Eloquentモデルはクエリビルダですから、[クエリビルダ](/docs/{{version}}/queries)で使用できる全メソッドを確認しておくべきでしょう。Eloquentクエリでどんなメソッドも使用できます。

#### モデルのリフレッシュ

`fresh`と`refresh`メソッドを使用し、モデルをリフレッシュできます。`fresh`メソッドはデータベースからモデルを再取得します。既存のモデルインスタンスは影響を受けません。

    $flight = App\Models\Flight::where('number', 'FR 900')->first();

    $freshFlight = $flight->fresh();

`refresh`メソッドは、データベースから取得したばかりのデータを使用し、既存のモデルを再構築します。

    $flight = App\Models\Flight::where('number', 'FR 900')->first();

    $flight->number = 'FR 456';

    $flight->refresh();

    $flight->number; // "FR 900"

<a name="collections"></a>
### コレクション

複数の結果を取得する`all`や`get`のようなEloquentメソッドは、`Illuminate\Database\Eloquent\Collection`インスタンスを返します。`Collection`クラスはEloquent結果を操作する[多くの便利なクラス](/docs/{{version}}/eloquent-collections#available-methods)を提供しています。

    $flights = $flights->reject(function ($flight) {
        return $flight->cancelled;
    });

このコレクションは配列のようにループさせることもできます。

    foreach ($flights as $flight) {
        echo $flight->name;
    }

<a name="chunking-results"></a>
### 結果の分割

数千のEloquentレコードを処理する必要がある場合は`chunk`コマンドを利用してください。`chunk`メソッドはEloquentモデルの「塊(chunk)」を取得し、引数の「クロージャ」に渡します。`chunk`メソッドを使えば大きな結果を操作するときのメモリを節約できます。

    Flight::chunk(200, function ($flights) {
        foreach ($flights as $flight) {
            //
        }
    });

最初の引数には「チャンク（塊）」ごとにいくつのレコードを処理するかを渡します。２番めの引数にはクロージャを渡し、そのデータベースからの結果をチャンクごとに処理するコードを記述します。クロージャへ渡されるチャンクを取得するたびに、データベースクエリは実行されます。

#### カーソルの使用

`cursor`メソッドにより、ひとつだけクエリを実行するカーソルを使用し、データベース全体を繰り返し処理できます。大量のデータを処理する場合、`cursor`メソッドを使用すると、大幅にメモリ使用量を減らせるでしょう。

    foreach (Flight::where('foo', 'bar')->cursor() as $flight) {
        //
    }

`cursor`は`Illuminate\Support\LazyCollection`インスタンスを返します。[レイジーコレクション](/docs/{{version}}/collections#lazy-collections)により、Laravelの典型的なコレクションで使用可能なメソッドを使用しながらも、一度に１つのモデルだけをメモリへロードします。

    $users = App\Models\User::cursor()->filter(function ($user) {
        return $user->id > 500;
    });

    foreach ($users as $user) {
        echo $user->id;
    }

<a name="advanced-subqueries"></a>
### 上級のサブクエリ

#### SELECTのサブクエリ

１回のクエリで関連テーブルから情報を取得する上級サブクエリもEloquentはサポートしています。例として、フライト（`flights`）と目的地（`destinations`）テーブルを想像してください。`flights`テーブルは、フライトの目的地への到着時間を意味する`arrived_at`カラムを持っています。

`select`と`addSelect`で利用できるサブクエリの機能を使えば全`destinations`と、一番早く目的地へ到着するのフライト名を１回のクエリで取得できます。

    use App\Models\Destination;
    use App\Models\Flight;

    return Destination::addSelect(['last_flight' => Flight::select('name')
        ->whereColumn('destination_id', 'destinations.id')
        ->orderBy('arrived_at', 'desc')
        ->limit(1)
    ])->get();

#### サブクエリのオーダー

さらに、クエリビルダの`orderBy`関数もサブクエリをサポートしています。この機能を使い、ラストフライトが目的地へいつ到着するかに基づいて全目的地をソートしてみましょう。今回も、これによりデータベースに対し１回のクエリしか実行されません。

    return Destination::orderByDesc(
        Flight::select('arrived_at')
            ->whereColumn('destination_id', 'destinations.id')
            ->orderBy('arrived_at', 'desc')
            ->limit(1)
    )->get();

<a name="retrieving-single-models"></a>
## １モデル／集計の取得

指定したテーブルの全レコードを取得することに加え、`find`や`first`、`firstWhere`を使い１レコードだけを取得できます。モデルのコレクションの代わりに、これらのメソッドは１モデルインスタンスを返します。

    // 主キーで指定したモデル取得
    $flight = App\Models\Flight::find(1);

    // クエリ条件にマッチした最初のモデル取得
    $flight = App\Models\Flight::where('active', 1)->first();

    // クエリ条件にマッチした最初のモデル取得の短縮記法
    $flight = App\Models\Flight::firstWhere('active', 1);

また、主キーの配列を`find`メソッドに渡し、呼び出すこともできます。一致したレコードのコレクションが返されます。

    $flights = App\Models\Flight::find([1, 2, 3]);

最初の結果が見つからない場合に、他のクエリやアクションの結果を取得したい場合もあると思います。`firstOr`メソッドは見つかった最初の結果を返すか、クエリ結果が見つからなかった場合にはコールバックを実行します。コールバックの結果は`firstOr`メソッドの結果になります。

    $model = App\Models\Flight::where('legs', '>', 100)->firstOr(function () {
            // ...
    });

`firstOr`メソッドは、取得したいカラムの配列を引数に指定できます。

    $model = App\Models\Flight::where('legs', '>', 100)
                ->firstOr(['id', 'legs'], function () {
                    // ...
                });

#### Not Found例外

モデルが見つからない時に、例外を投げたい場合もあります。これはとくにルートやコントローラの中で便利です。`findOrFail`メソッドとクエリの最初の結果を取得する`firstOrFail`メソッドは、該当するレコードが見つからない場合に`Illuminate\Database\Eloquent\ModelNotFoundException`例外を投げます。

    $model = App\Models\Flight::findOrFail(1);

    $model = App\Models\Flight::where('legs', '>', 100)->firstOrFail();

この例外がキャッチされないと自動的に`404`HTTPレスポンスがユーザーに送り返されます。これらのメソッドを使用すればわざわざ明確に`404`レスポンスを返すコードを書く必要はありません。

    Route::get('/api/flights/{id}', function ($id) {
        return App\Models\Flight::findOrFail($id);
    });

<a name="retrieving-aggregates"></a>
### 集計の取得

もちろん[クエリビルダ](/docs/{{version}}/queries)が提供している`count`、`sum`、`max`や、その他の[集計関数](/docs/{{version}}/queries#aggregates)を使用することもできます。これらのメソッドは完全なモデルインスタンスではなく、最適なスカラー値を返します。

    $count = App\Models\Flight::where('active', 1)->count();

    $max = App\Models\Flight::where('active', 1)->max('price');

<a name="inserting-and-updating-models"></a>
## モデルの追加と更新

<a name="inserts"></a>
### Inserts

モデルから新しいレコードを作成するには新しいインスタンスを作成し、`save`メソッドを呼び出します。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Models\Flight;
    use Illuminate\Http\Request;

    class FlightController extends Controller
    {
        /**
         * 新しいflightインスタンスの生成
         *
         * @param  Request  $request
         * @return Response
         */
        public function store(Request $request)
        {
            // リクエストのバリデート処理…

            $flight = new Flight;

            $flight->name = $request->name;

            $flight->save();
        }
    }

この例では、受信したHTTPリクエストの`name`パラメーターを`App\Models\Flight`モデルインスタンスの`name`属性に代入しています。`save`メソッドが呼ばれると新しいレコードがデータベースに挿入されます。`save`が呼び出された時に`created_at`と`updated_at`タイムスタンプは自動的に設定されますので、わざわざ設定する必要はありません。

<a name="updates"></a>
### Updates

`save`メソッドはデータベースですでに存在するモデルを更新するためにも使用されます。モデルを更新するにはまず取得する必要があり、更新したい属性をセットしてそれから`save`メソッドを呼び出します。この場合も`updated_at`タイムスタンプは自動的に更新されますので、値を指定する手間はかかりません。

    $flight = App\Models\Flight::find(1);

    $flight->name = 'New Flight Name';

    $flight->save();

#### 複数モデル更新

指定したクエリに一致する複数のモデルに対し更新することもできます。以下の例では`active`で到着地(`destination`)が`San Diego`の全フライトに遅延(`delayed`)のマークを付けています。

    App\Models\Flight::where('active', 1)
              ->where('destination', 'San Diego')
              ->update(['delayed' => 1]);

`update`メソッドは更新したいカラムと値の配列を受け取ります。

> {note} Eloquentの複数モデル更新を行う場合、更新モデルに対する`saving`、`saved`、`updating`、`updated`モデルイベントは発行されません。その理由は複数モデル更新を行う時、実際にモデルが取得されるわけではないからです。

#### 属性変化の判定

モデル内部の状態が変化したかを判定し、ロード時のオリジナルな状態からどのように変化したかを調べるため、Eloquentは`isDirty`、`isClean`、`wasChanged`メソッドを提供しています。

`isDirty`メソッドはロードされたモデルから属性に変化があったかを判定します。特定の属性に変化があったかを調べるために、属性名を渡し指定できます。`isClean`メソッドは`isDirty`の反対の働きをし、同様に属性をオプショナルな引数として渡すことができます。

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

`wasChanged`メソッドは現在のリクエストサイクル中、最後にモデルが保存されたときから属性に変化があったかを判定します。特定の属性が変化したかを調べるために、属性名を渡すことも可能です。

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

`getOriginal`メソッドはモデルのロード後にどんな変更がされているかにかかわらず、モデルのオリジナルな属性を含む配列を返します。特定の属性のオリジナル値を取得するために属性名を指定できます。

    $user = User::find(1);

    $user->name; // John
    $user->email; // john@example.com

    $user->name = "Jack";
    $user->name; // Jack

    $user->getOriginal('name'); // John
    $user->getOriginal(); // オリジナルな属性の配列

<a name="mass-assignment"></a>
### 複数代入

一行だけで新しいモデルを保存するには、`create`メソッドが利用できます。挿入されたモデルインスタンスが、メソッドから返されます。しかし、これを利用する前に、Eloquentモデルはデフォルトで複数代入から保護されているため、モデルへ`fillable`か`guarded`属性のどちらかを設定する必要があります。

複数代入の脆弱性はリクエストを通じて予期しないHTTPパラメーターが送られた時に起き、そのパラメーターはデータベースのカラムを予期しないように変更してしまうでしょう。たとえば悪意のあるユーザーがHTTPパラメーターで`is_admin`パラメーターを送り、それがモデルの`create`メソッドに対して渡されると、そのユーザーは自分自身を管理者(administrator)に昇格できるのです。

ですから最初に複数代入したいモデルの属性を指定してください。モデルの`$fillable`プロパティで指定できます。たとえば、`Flight`モデルの複数代入で`name`属性のみ使いたい場合です。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class Flight extends Model
    {
        /**
         * 複数代入する属性
         *
         * @var array
         */
        protected $fillable = ['name'];
    }

複数代入する属性を指定したら、新しいレコードをデータベースに挿入するため、`create`が利用できます。`create`メソッドは保存したモデルインスタンスを返します。

    $flight = App\Models\Flight::create(['name' => 'Flight 10']);

すでに存在するモデルインスタンスへ属性を指定したい場合は、`fill`メソッドを使い、配列で指定してください。

    $flight->fill(['name' => 'Flight 22']);

#### 複数代入とJSONカラム

JSONカラムを割り当てるときは、各カラムの複数代入可能なキーをモデルの`$fillable`配列で指定する必要があります。セキュリティのため、Laravelは`guarded`プロパティ使用時のネストしたJSON属性の更新をサポートしていません。

    /**
     * 複数代入する属性
     *
     * @var array
     */
    $fillable = [
        'options->enabled',
    ];

#### 複数代入の許可

全属性を複数代入可能にする場合は、`$guarded`プロパティに空の配列を定義します。

    /**
     * 複数代入しない属性
     *
     * @var array
     */
    protected $guarded = [];

<a name="other-creation-methods"></a>
### 他の生成メソッド

#### `firstOrCreate`/ `firstOrNew`

他にも属性の複数代入可能な生成メソッドが２つあります。`firstOrCreate`と`firstOrNew`です。`firstOrCreate`メソッドは指定されたカラム／値ペアでデータベースレコードを見つけようします。モデルがデータベースで見つからない場合は、最初の引数が表す属性、任意の第２引数があればそれが表す属性も同時に含む、レコードが挿入されます。

`firstOrNew`メソッドも`firstOrCreate`のように指定された属性にマッチするデータベースのレコードを見つけようとします。しかしモデルが見つからない場合、新しいモデルインスタンスが返されます。`firstOrNew`が返すモデルはデータベースに保存されていないことに注目です。保存するには`save`メソッドを呼び出す必要があります。

    // nameでフライトを取得するか、存在しなければ作成する
    $flight = App\Models\Flight::firstOrCreate(['name' => 'Flight 10']);

    // nameでフライトを取得するか、存在しなければ指定されたname、delayed、arrival_timeを含め、インスタンス化する
    $flight = App\Models\Flight::firstOrCreate(
        ['name' => 'Flight 10'],
        ['delayed' => 1, 'arrival_time' => '11:30']
    );

    // nameで取得するか、インスタンス化する
    $flight = App\Models\Flight::firstOrNew(['name' => 'Flight 10']);

    // nameで取得するか、name、delayed、arrival_time属性でインスタンス化する
    $flight = App\Models\Flight::firstOrNew(
        ['name' => 'Flight 10'],
        ['delayed' => 1, 'arrival_time' => '11:30']
    );

#### `updateOrCreate`

また、既存のモデルを更新するか、存在しない場合は新しいモデルを作成したい状況も存在します。これを一度に行うため、Laravelでは`updateOrCreate`メソッドを提供しています。`firstOrCreate`メソッドと同様に、`updateOrCreate`もモデルを保存するため、`save()`を呼び出す必要はありません。

    // OaklandからSan Diego行きの飛行機があれば、料金へ９９ドルを設定する
    // 一致するモデルがなければ、作成する
    $flight = App\Models\Flight::updateOrCreate(
        ['departure' => 'Oakland', 'destination' => 'San Diego'],
        ['price' => 99, 'discounted' => 1]
    );

１つのクエリで複数の"upserts（update+insert：更新か挿入）"を実行する場合は、代わりに`upsert`メソッドを使用してください。メソッドの最初の引数は挿入または更新する値で構成し、２番目の引数は関連したテーブル内のレコードを一意に識別するカラムのリストです。３番目、メソッド最後の引数はデータベースに一致するレコードが、すでに存在している場合に更新する必要があるカラムの配列です。モデルでタイムスタンプが有効になっている場合、`upsert`メソッドは`created_at`と`updated_at`タイムスタンプを自動的にセットします。

    App\Models\Flight::upsert([
        ['departure' => 'Oakland', 'destination' => 'San Diego', 'price' => 99],
        ['departure' => 'Chicago', 'destination' => 'New York', 'price' => 150]
    ], ['departure', 'destination'], ['price']);

> {note} SQL Serverを除くすべてのデータベースでは、`upsert`メソッドの２番目の引数のカラムに"primary"か"unique"のインデックスが必要です。

<a name="deleting-models"></a>
## モデル削除

モデルを削除するには、モデルに対し`delete`メソッドを呼び出します。

    $flight = App\Models\Flight::find(1);

    $flight->delete();

#### キーによる既存モデルの削除

上記の例では`delete`メソッドを呼び出す前に、データベースからモデルを取得しています。しかしモデルの主キーが分かっている場合は、明示的にモデルを取得せずとも`destroy`メソッドで削除できます。さらに、引数に主キーを一つ指定できるだけでなく、`destroy`メソッドは主キーの配列や、主キーの[コレクション](/docs/{{version}}/collections)を引数に指定することで、複数のキーを指定できます。

    App\Models\Flight::destroy(1);

    App\Models\Flight::destroy(1, 2, 3);

    App\Models\Flight::destroy([1, 2, 3]);

    App\Models\Flight::destroy(collect([1, 2, 3]));

> {note} `destroy`メソッドは個別にモデルをロードし、`delete`メソッドを呼び出します。そのため、`deleting`と`deleted`イベントが発行されます。

#### クエリによるモデル削除

一連のモデルに対する削除文を実行することもできます。次の例はactiveではない印を付けられたフライトを削除しています。複数モデル更新と同様に、複数削除は削除されるモデルに対するモデルイベントを発行しません。

    $deletedRows = App\Models\Flight::where('active', 0)->delete();

> {note} 複数削除文をEloquentにより実行する時、削除対象モデルに対する`deleting`と`deleted`モデルイベントは発行されません。なぜなら、削除文の実行時に、実際にそのモデルが取得されるわけではないためです。

<a name="soft-deleting"></a>
### ソフトデリート

本当にデータベースからレコードを削除する方法に加え、Eloquentはモデルの「ソフトデリート」も行えます。モデルがソフトデリートされても実際にはデータベースのレコードから削除されません。代わりにそのモデルへ`deleted_at`属性がセットされ、データベースへ書き戻されます。モデルの`deleted_at`の値がNULLでない場合、ソフトデリートされています。モデルのソフトデリートを有効にするには、モデルに`Illuminate\Database\Eloquent\SoftDeletes`トレイトを使います。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;
    use Illuminate\Database\Eloquent\SoftDeletes;

    class Flight extends Model
    {
        use SoftDeletes;
    }

> {tip} `SoftDeletes`トレイトは自動的に`deleted_at`属性を`DateTime`/`Carbon`インスタンスへ変換します。

データベーステーブルにも`deleted_at`カラムを追加する必要があります。Laravel[スキーマビルダ](/docs/{{version}}/migrations)にはこのカラムを作成するメソッドが存在しています。

    public function up()
    {
        Schema::table('flights', function (Blueprint $table) {
            $table->softDeletes();
        });
    }

    public function down()
    {
        Schema::table('flights', function (Blueprint $table) {
            $table->dropSoftDeletes();
        });
    }

これでモデルに対し`delete`メソッドを使用すれば、`deleted_at`カラムに現在の時間がセットされます。ソフトデリートされたモデルに対しクエリがあっても、削除済みのモデルはクエリ結果に含まれません。

指定されたモデルインスタンスがソフトデリートされているかを確認するには、`trashed`メソッドを使います。

    if ($flight->trashed()) {
        //
    }

<a name="querying-soft-deleted-models"></a>
### ソフトデリート済みモデルのクエリ

#### ソフトデリート済みモデルも含める

前述のようにソフトデリートされたモデルは自動的にクエリの結果から除外されます。しかし結果にソフトデリート済みのモデルを含めるように強制したい場合は、クエリに`withTrashed`メソッドを使ってください。

    $flights = App\Models\Flight::withTrashed()
                    ->where('account_id', 1)
                    ->get();

`withTrashed`メソッドは[リレーション](/docs/{{version}}/eloquent-relationships)のクエリにも使えます。

    $flight->history()->withTrashed()->get();

#### ソフトデリート済みモデルのみの取得

`onlyTrashed`メソッドによりソフトデリート済みのモデル**のみ**を取得できます。

    $flights = App\Models\Flight::onlyTrashed()
                    ->where('airline_id', 1)
                    ->get();

#### ソフトデリートの解除

時にはソフトデリート済みのモデルを「未削除」に戻したい場合も起きます。ソフトデリート済みモデルを有効な状態に戻すには、そのモデルインスタンスに対し`restore`メソッドを使ってください。

    $flight->restore();

複数のモデルを手っ取り早く未削除に戻すため、クエリに`restore`メソッドを使うこともできます。他の「複数モデル」操作と同様に、この場合も復元されるモデルに対するモデルイベントは、発行されません。

    App\Models\Flight::withTrashed()
            ->where('airline_id', 1)
            ->restore();

`withTrashed`メソッドと同様、`restore`メソッドは[リレーション](/docs/{{version}}/eloquent-relationships)に対しても使用できます。

    $flight->history()->restore();

#### モデルの完全削除

データベースからモデルを本当に削除する場合もあるでしょう。データベースからソフトデリート済みモデルを永久に削除するには`forceDelete`メソッドを使います。

    // １モデルを完全に削除する
    $flight->forceDelete();

    // 関係するモデルを全部完全に削除する
    $flight->history()->forceDelete();

<a name="replicating-models"></a>
## 複製モデル

`replicate`メソッドを用いて、あるモデルインスタンスの未保存なコピーを作成できます。これは共通の同じ属性をたくさん持つモデルインスタンスを作成したい場合にとくに便利です。

    $shipping = App\Models\Address::create([
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

グローバルスコープにより、指定したモデルの**全**クエリに対して、制約を付け加えることができます。Laravel自身の[ソフトデリート](#soft-deleting)機能は、「削除されていない」モデルをデータベースから取得するためにグローバルスコープを使用しています。独自のグローバルスコープを書くことにより、特定のモデルのクエリに制約を確実に、簡単に、便利に指定できます。

#### グローバルスコープの記述

グローバルスコープは簡単に書けます。`Illuminate\Database\Eloquent\Scope`インターフェイスを実装したクラスを定義します。このインターフェイスは、`apply`メソッドだけを実装するように要求しています。`apply`メソッドは必要に応じ、`where`制約を追加します。

    <?php

    namespace App\Scopes;

    use Illuminate\Database\Eloquent\Builder;
    use Illuminate\Database\Eloquent\Model;
    use Illuminate\Database\Eloquent\Scope;

    class AgeScope implements Scope
    {
        /**
         * Eloquentクエリビルダへ適用するスコープ
         *
         * @param  \Illuminate\Database\Eloquent\Builder  $builder
         * @param  \Illuminate\Database\Eloquent\Model  $model
         * @return void
         */
        public function apply(Builder $builder, Model $model)
        {
            $builder->where('age', '>', 200);
        }
    }

> {tip} クエリのSELECT節にカラムを追加するグローバルスコープの場合は、`select`の代わりに`addSelect`メソッドを使用してください。これにより、クエリの存在するSELECT節を意図せずに置き換えてしまうのを防げます。

#### グローバルスコープの適用

モデルにグローバルスコープを適用するには、そのモデルの`booted`メソッドをオーバライドし、`addGlobalScope`メソッドを呼び出します。

    <?php

    namespace App\Models;

    use App\Scopes\AgeScope;
    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * モデルの「初期起動」メソッド
         *
         * @return void
         */
        protected static function booted()
        {
            static::addGlobalScope(new AgeScope);
        }
    }

スコープを追加した後から、`User::all()`は以下のクエリを生成するようになります。

    select * from `users` where `age` > 200

#### クロージャによるグローバルスコープ

Eloquentではクロージャを使ったグローバルスコープも定義できます。独立したクラスを使うだけの理由がない、簡単なスコープを使いたい場合、とくに便利です。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Builder;
    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * モデルの「初期起動」メソッド
         *
         * @return void
         */
        protected static function booted()
        {
            static::addGlobalScope('age', function (Builder $builder) {
                $builder->where('age', '>', 200);
            });
        }
    }

#### グローバルスコープの削除

特定のクエリからグローバルスコープを削除した場合は、`withoutGlobalScope`メソッドを使います。唯一の引数として、クラス名を受けます。

    User::withoutGlobalScope(AgeScope::class)->get();

もしくは、クロージャを使用し、グローバルスコープを定義している場合は：

    User::withoutGlobalScope('age')->get();

複数、もしくは全部のグローバルスコープを削除したい場合も、`withoutGlobalScopes`メソッドが使えます。

    // 全グローバルスコープの削除
    User::withoutGlobalScopes()->get();

    // いくつかのグローバルスコープの削除
    User::withoutGlobalScopes([
        FirstScope::class, SecondScope::class
    ])->get();

<a name="local-scopes"></a>
### ローカルスコープ

ローカルスコープによりアプリケーション全体で簡単に再利用可能な、一連の共通制約を定義できます。たとえば、人気のある(popular)ユーザーを全員取得する必要が、しばしばあるとしましょう。スコープを定義するには、`scope`を先頭につけた、Eloquentモデルのメソッドを定義します。

スコープはいつもクエリビルダインスタンスを返します。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * 人気のあるユーザーだけに限定するクエリスコープ
         *
         * @param  \Illuminate\Database\Eloquent\Builder  $query
         * @return \Illuminate\Database\Eloquent\Builder
         */
        public function scopePopular($query)
        {
            return $query->where('votes', '>', 100);
        }

        /**
         * アクティブなユーザーだけに限定するクエリスコープ
         *
         * @param  \Illuminate\Database\Eloquent\Builder  $query
         * @return \Illuminate\Database\Eloquent\Builder
         */
        public function scopeActive($query)
        {
            return $query->where('active', 1);
        }
    }

#### ローカルスコープの利用

スコープが定義できたらモデルのクエリ時にスコープメソッドを呼び出せます。しかし、メソッドを呼び出すときは`scope`プレフィックスをつけないでください。さまざまなスコープをチェーンでつなぎ呼び出すこともできます。例を見てください。

    $users = App\Models\User::popular()->active()->orderBy('created_at')->get();

`or`クエリ操作により、複数のEloquentモデルスコープを組み合わせるには、クロージャのコールバックを使用する必要があります。

    $users = App\Models\User::popular()->orWhere(function (Builder $query) {
        $query->active();
    })->get();

しかし、上記は手間がかかるため、Laravelはクロージャを使用せずにスコープをスラスラとチェーンできるように、"higher order" `orWhere`メソッドを用意しています。

    $users = App\Models\User::popular()->orWhere->active()->get();

#### 動的スコープ

引数を受け取るスコープを定義したい場合もあるでしょう。スコープにパラメーターを付けるだけです。スコープパラメーターは`$query`引数の後に定義しする必要があります。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * 指定したタイプのユーザーだけを含むクエリのスコープ
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

これでスコープを呼び出すときにパラメーターを渡せます。

    $users = App\Models\User::ofType('admin')->get();

<a name="comparing-models"></a>
## モデルの比較

時に２つのモデルが「同じ」であるかを判定する必要が起きるでしょう。`is`メソッドは２つのモデルが、同じ主キー、テーブル、データベース接続を持っているかを確認します。

    if ($post->is($anotherPost)) {
        //
    }

`belongsTo`、`hasOne`、`morphTo`、`morphOne`リレーションを使う場合、`is`メソッドも使用できます。このメソッドはモデルを取得するクエリを発行せずに関連するモデルを比較したい場合、とくに便利です。

    if ($post->author()->is($user)) {
        //
    }

<a name="events"></a>
## イベント

Eloquentモデルは多くのイベントを発行します。`creating`、`created`、`updating`、`updated`、`saving`、`saved`、`deleting`、`deleted`、`restoring`、`restored`、`retrieved`のメソッドを利用し、モデルのライフサイクルのさまざまな時点をフックできます。イベントにより特定のモデルクラスが保存されたり、アップデートされたりするたびに簡単にコードを実行できるようになります。各イベントは、コンストラクタによりモデルのインスタンスを受け取ります。

データベースから既存のモデルを取得した時に`retrieved`イベントは発行されます。新しいアイテムが最初に保存される場合、`creating`と`created`イベントが発行されます。既存モデルを更新し`save`メソッドを呼び出すと、`updating`と`updated`イベントが発行されます。モデルが生成・更新される時は`saving`と`saved`イベントが発行されます。

> {note} Eloquentの複数モデル更新・削除を行う場合、影響を受けるモデルに対する`saved`、`updated`、`deleting`モデルイベントは発行されません。その理由は複数モデル更新・削除を行う時、実際にモデルが取得されるわけではないからです。

使用するには、Eloquentモデルに`$dispatchesEvents`プロパティを定義します。これにより、Eloquentモデルのライフサイクルのさまざまな時点を皆さん自身の[イベントクラス](/docs/{{version}}/events)へマップします。

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

Eloquentイベントの定義とマップができたら、[イベントリスナ](/docs/{{version}}/events#defining-listeners)を使用し、イベントを処理できます。

<a name="events-using-closures"></a>
### クロージャの使用

カスタムイベントクラスを使用する代わりに、さまざまなモデルイベントが発行されたときに実行されるクロージャを登録できます。通常はモデルの`booted`メソッドで、これらのクロージャを登録すべきでしょう。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;

    class User extends Model
    {
        /**
         * モデルの「初期起動」メソッド
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

必要に応じて、モデルイベントを登録する際に[キュー投入可能な無名イベントリスナ](/docs/{{{version}}/events#queueable-anonymous-event-listeners)を利用できます。これは、[キュー](/docs/{{{version}}/queues)を使ってモデルイベントリスナを実行するようにLaravelに指示します。

    use function Illuminate\Events\queueable;

    static::created(queueable(function ($user) {
        //
    }));

<a name="observers"></a>
### オブザーバ

#### オブザーバの定義

特定のモデルに対し、多くのイベントをリスニングしている場合、全リスナのグループに対するオブザーバを一つのクラスの中で使用できます。オブザーバクラスは、リッスンしたいEloquentイベントに対応する名前のメソッドを持ちます。これらのメソッドは、唯一の引数としてモデルを受け取ります。`make:observer`　Artisanコマンドで、新しいオブザーバクラスを簡単に生成できます。

    php artisan make:observer UserObserver --model=User

このコマンドは、`App/Observers`ディレクトリへ新しいオブザーバを設置します。このディレクトリが存在しなければ、Artisanが作成します。真新しいオブザーバは、次の通りです。

    <?php

    namespace App\Observers;

    use App\Models\User;

    class UserObserver
    {
        /**
         * Userの"created"イベントを処理
         *
         * @param  \App\Models\User  $user
         * @return void
         */
        public function created(User $user)
        {
            //
        }

        /**
         * Userの"updated"イベントを処理
         *
         * @param  \App\Models\User  $user
         * @return void
         */
        public function updated(User $user)
        {
            //
        }

        /**
         * Userの"deleted"イベントを処理
         *
         * @param  \App\Models\User  $user
         * @return void
         */
        public function deleted(User $user)
        {
            //
        }

        /**
         * Userの"forceDeleted"イベントを処理
         *
         * @param  \App\Models\User  $user
         * @return void
         */
        public function forceDeleted(User $user)
        {
            //
        }
    }

オブザーバを登録するには、監視したいモデルに対し、`observe`メソッドを使用します。サービスプロバイダの一つの、`boot`メソッドで登録します。以下の例では、`AppServiceProvider`でオブザーバを登録しています。

    <?php

    namespace App\Providers;

    use App\Observers\UserObserver;
    use App\Models\User;
    use Illuminate\Support\ServiceProvider;

    class AppServiceProvider extends ServiceProvider
    {
        /**
         * 全アプリケーションサービスの登録
         *
         * @return void
         */
        public function register()
        {
            //
        }

        /**
         * 全アプリケーションサービスの初期起動
         *
         * @return void
         */
        public function boot()
        {
            User::observe(UserObserver::class);
        }
    }

<a name="muting-events"></a>
### イベントのミュート

モデルが発行させたすべてのイベントを一時的に「ミュート」したい場合があります。`withoutEvents`メソッドで可能です。`withoutEvents`メソッドは引数として唯一クロージャを受け付けます。クロージャ内で実行するコードはモデルイベントを発行しません。たとえば、次の例はモデルイベントを発生せずに`App\Models\User`インスタンスを取得し削除します。指定したクロージャが返す値はすべて、`withoutEvents`メソッドがそのまま返します。

    use App\Models\User;

    $user = User::withoutEvents(function () use () {
        User::findOrFail(1)->delete();

        return User::find(2);
    });

#### イベント無しに１つのモデルを保存

どんなイベントも発行させずに特定のモデルを「保存」したい場合もあるでしょう。`saveQuietly`メソッドを使ってください。

    $user = User::findOrFail(1);

    $user->name = 'Victoria Faith';

    $user->saveQuietly();
