# キャッシュ

- [設定](#configuration)
    - [ドライバ事前要件](#driver-prerequisites)
- [キャッシュの使用法](#cache-usage)
    - [キャッシュインスタンスの取得](#obtaining-a-cache-instance)
    - [キャッシュからアイテム取得](#retrieving-items-from-the-cache)
    - [キャッシュへアイテム保存](#storing-items-in-the-cache)
    - [キャッシュからのアイテム削除](#removing-items-from-the-cache)
    - [cacheヘルパ](#the-cache-helper)
- [キャッシュタグ](#cache-tags)
    - [タグ付けしたキャッシュアイテムの保存](#storing-tagged-cache-items)
    - [タグ付けしたキャッシュアイテムへのアクセス](#accessing-tagged-cache-items)
    - [タグ付けしたキャッシュアイテムの削除](#removing-tagged-cache-items)
- [アトミックロック](#atomic-locks)
    - [ドライバ動作要件](#lock-driver-prerequisites)
    - [ロック管理](#managing-locks)
    - [プロセス間のロック管理](#managing-locks-across-processes)
- [カスタムキャッシュドライバの追加](#adding-custom-cache-drivers)
    - [ドライバープログラミング](#writing-the-driver)
    - [ドライバ登録](#registering-the-driver)
- [イベント](#events)

<a name="configuration"></a>
## 設定

Laravelは読み書きしやすい、多くのキャッシュシステムに対する統一したAPIを提供します。キャッシュの設定は、`config/cache.php`で指定します。アプリケーション全体のデフォルトとして使用するキャッシュドライバをこのファイルの中で指定します。[Memcached](https://memcached.org)や[Redis](https://redis.io)など、人気のあるキャッシュシステムをLaravelは最初からサポートしています。

キャッシュ設定ファイルは、さまざまな他のオプションも含んでいます。コメントで説明してありますので、よく読んで確認してください。Laravelのデフォルトとして、`file`キャッシュドライバが設定されています。ファイルシステムへオブジェクトをシリアライズして保存します。大きなアプリケーションではMemecachedやAPCのような、より堅牢なドライバを使うことを推奨します。複数のドライバを使用するキャッシュ設定も可能です。

<a name="driver-prerequisites"></a>
### ドライバ事前要件

#### データベース

データベースをキャッシュドライバに使用する場合、キャッシュアイテムを構成するテーブルを用意する必要があります。このテーブルの「スキーマ」を定義するサンプルを見てください。

    Schema::create('cache', function ($table) {
        $table->string('key')->unique();
        $table->text('value');
        $table->integer('expiration');
    });

> {tip} 正確なスキーマのマイグレーションを生成するために、`php artisan cache:table` Artisanコマンドを使用することもできます。

#### Memcached

Memcachedキャッシュを使用する場合は、[Memcached PECLパッケージ](https://pecl.php.net/package/memcached)をインストールする必要があります。全Memcachedサーバは、`config/cache.php`設定ファイルにリストしてください。

    'memcached' => [
        [
            'host' => '127.0.0.1',
            'port' => 11211,
            'weight' => 100
        ],
    ],

さらに、UNIXソケットパスへ、`host`オプションを設定することもできます。これを行うには`port`オプションに`0`を指定してください。

    'memcached' => [
        [
            'host' => '/var/run/memcached/memcached.sock',
            'port' => 0,
            'weight' => 100
        ],
    ],

#### Redis

LaravelでRedisを使う前にPECLでPhpRedis PHP拡張、もしくはComposerで`predis/predis`パッケージ(~1.0）のどちらかをインストールしておく必要があります。

Redisの設定についての詳細は、[Laravelドキュメントページ](/docs/{{version}}/redis#configuration)を読んでください。

<a name="cache-usage"></a>
## キャッシュの使用法

<a name="obtaining-a-cache-instance"></a>
### キャッシュインスタンスの取得

`Illuminate\Contracts\Cache\Factory`と`Illuminate\Contracts\Cache\Repository`[契約](/docs/{{version}}/contracts)は、Laravelのキャッシュサービスへのアクセスを提供します。`Factory`契約は、アプリケーションで定義している全キャッシュドライバへのアクセスを提供します。`Repository`契約は通常、`cache`設定ファイルで指定している、アプリケーションのデフォルトキャッシュドライバの実装です。

しかし、このドキュメント全体で使用している、`Cache`ファサードも利用できます。`Cache`ファサードは裏で動作している、Laravelキャッシュ契約の実装への便利で簡潔なアクセスを提供しています。

    <?php

    namespace App\Http\Controllers;

    use Illuminate\Support\Facades\Cache;

    class UserController extends Controller
    {
        /**
         * アプリケーションの全ユーザーリストの表示
         *
         * @return Response
         */
        public function index()
        {
            $value = Cache::get('key');

            //
        }
    }

#### 複数のキャッシュ保存先へのアクセス

`Cache`ファサードの`store`メソッドを使い、さまざまなキャッシュ保存域へアクセスできます。`store`メソッドに渡すキーは、`cache`設定ファイルの`stores`設定配列にリストしている保存域の一つです。

    $value = Cache::store('file')->get('foo');

    Cache::store('redis')->put('bar', 'baz', 600); // １０分間

<a name="retrieving-items-from-the-cache"></a>
### キャッシュからアイテム取得

`Cache`ファサードの`get`メソッドは、キャッシュからアイテムを取得するために使用します。アイテムがキャッシュに存在していない場合は、`null`が返されます。アイテムが存在していない時に返したい、カスタムデフォルト値を`get`メソッドの第２引数として渡すこともできます。

    $value = Cache::get('key');

    $value = Cache::get('key', 'default');

デフォルト値として「クロージャ」を渡すこともできます。キャッシュに指定したアイテムが存在していない場合、「クロージャ」の結果が返されます。クロージャを渡すことで、データベースや外部サービスからデフォルト値を取得するのを遅らせることができます。

    $value = Cache::get('key', function () {
        return DB::table(...)->get();
    });

#### アイテムの存在確認

`has`メソッドで、キャッシュにアイテムが存在しているかを調べることができます。このメソッドは、値が`null`の場合、`false`を返します。

    if (Cache::has('key')) {
        //
    }

#### 値の増減

`increment`と`decrement`メソッドはキャッシュの整数アイテムの値を調整するために使用します。両方のメソッドともそのアイテムの値をどのくらい増減させるかの増分をオプションの第２引数に指定できます。

    Cache::increment('key');
    Cache::increment('key', $amount);
    Cache::decrement('key');
    Cache::decrement('key', $amount);

#### 取得不可時更新

キャッシュからアイテムを取得しようとして、指定したアイテムが存在しない場合は、デフォルト値を保存したい場合もあるでしょう。たとえば、全ユーザーをキャッシュから取得しようとし、存在していない場合はデータベースから取得しキャッシュへ追加したい場合です。`Cache::remember`メソッドを使用します。

    $value = Cache::remember('users', $seconds, function () {
        return DB::table('users')->get();
    });

キャッシュに存在しない場合、`remember`メソッドに渡された「クロージャ」が実行され、結果がキャッシュに保存されます。

`rememberForever`メソッドでアイテムをキャッシュから取得するか、できない場合は永久に保存できます。

    $value = Cache::rememberForever('users', function () {
        return DB::table('users')->get();
    });

#### 取得後削除

キャッシュからアイテムを取得した後に削除したい場合は、`pull`メソッドを使用します。`get`メソッドと同様にキャッシュにアイテムが存在していない場合は、`null`が返ります。

    $value = Cache::pull('key');

<a name="storing-items-in-the-cache"></a>
### キャッシュへアイテム保存

`Cache`ファサードの`put`メソッドにより、キャッシュにアイテムを保存できます。

    Cache::put('key', 'value', $seconds);

`put`メソッドに保存期間を渡さない場合、そのアイテムは無期限に保存されます。

    Cache::put('key', 'value');

どのくらいでアイテムが無効になるかを秒数で指定する代わりに、キャッシュされたアイテムの有効期限を示す`DateTime`インスタンスを渡すこともできます。

    Cache::put('key', 'value', now()->addMinutes(10));

#### 非存在時保存

`add`メソッドはキャッシュに保存されていない場合のみ、そのアイテムを保存します。キャッシュへ実際にアイテムが追加された場合は`true`が返ってきます。そうでなければ`false`が返されます。

    Cache::add('key', 'value', $seconds);

#### アイテムを永遠に保存

`forever`メソッドはそのアイテムをキャッシュへ永遠に保存します。こうした値は有効期限が切れないため、`forget`メソッドを使用し、削除する必要があります。

    Cache::forever('key', 'value');

> {tip} Memcachedドライバーを使用する場合、キャッシュが最大値に達すると、"forever"を指定したアイテムも削除されます。

<a name="removing-items-from-the-cache"></a>
### キャッシュからのアイテム削除

`forget`メソッドでキャッシュからアイテムを削除します。

    Cache::forget('key');

０か負数を指定し、アイテムを削除することもできます。

    Cache::put('key', 'value', 0);

    Cache::put('key', 'value', -5);

キャッシュ全体をクリアしたい場合は`flush`メソッドを使います。

    Cache::flush();

> {note} `flush`メソッドは、キャッシュのプレフィックスを考慮せずに、キャッシュから全アイテムを削除します。他のアプリケーションと共有するキャッシュを削除するときは、利用を熟考してください。

<a name="the-cache-helper"></a>
### Cacheヘルパ

`Cache`ファサードや[キャッシュ契約](/docs/{{version}}/contracts)の利用に加え、グローバルな`cache`関数を使用し、キャッシュ経由でデータを取得および保存することもできます。`cache`関数を文字列引数だけで呼び出すと、指定したキーの値を返します。

    $value = cache('key');

関数へキー／値ペアの配列と有効時間を指定した場合は、指定した時間まで値をキャッシュへ保存します。

    cache(['key' => 'value'], $seconds);

    cache(['key' => 'value'], now()->addMinutes(10));

`cache`関数を引数無しで呼び出すと、Illuminate\Contracts\Cache\Factory`の実装インスタンスが返されます。これを使い他のキャッシュメソッドも呼び出せます。

    cache()->remember('users', $seconds, function () {
        return DB::table('users')->get();
    });

> {tip} テストでグローバルの`cache`関数の呼び出し時は、[ファサードのテスト](/docs/{{version}}/mocking#mocking-facades)と同様に`Cache::shouldReceive`メソッドを使用できます。

<a name="cache-tags"></a>
## キャッシュタグ

> {note} キャッシュタグは`file`、`dynamodb`、`database`キャッシュドライバ使用時は使用できません。また"forever"として保存しているキャッシュに複数のタグを使用する場合は、`memcached`のような古いレコードを自動的にパージするドライバで良いパフォーマンスが出ます。

<a name="storing-tagged-cache-items"></a>
### タグ付きキャッシュアイテムの保存

キャッシュタグにより関連するアイテムにタグを付け、そのタグを指定することで割り付けたキャッシュ値へ一度にアクセスできます。たとえば、タグ付けしたキャッシュにアクセスし、キャッシュへ値を`put`してみましょう。

    Cache::tags(['people', 'artists'])->put('John', $john, $seconds);

    Cache::tags(['people', 'authors'])->put('Anne', $anne, $seconds);

<a name="accessing-tagged-cache-items"></a>
### タグ付けしたキャッシュアイテムへのアクセス

タグ付けしたキャッシュアイテムを取得するには、`tags`メソッドへ渡した同じ順番でタグのリストを渡します。それから、`get`メソッドを取得したいキーで呼び出します。

    $john = Cache::tags(['people', 'artists'])->get('John');

    $anne = Cache::tags(['people', 'authors'])->get('Anne');

<a name="removing-tagged-cache-items"></a>
### タグ付けしたアイテムの削除

タグやタグのリストを割り付けたアイテムすべてを削除できます。たとえば次の文は、`people`か `authors`、もしくは両方のタグ付けしたキャッシュをすべて削除します。

    Cache::tags(['people', 'authors'])->flush();

制約により、この文は`authors`のタグづけしたキャッシュだけを削除するため、`Anne`は削除されますが`John`はされません。

    Cache::tags('authors')->flush();

<a name="atomic-locks"></a>
## アトミックロック

> {note} この機能を利用するには、アプリケーションで`memcached`、`dynamodb`、`redis`、`database`、`array`のどれかをデフォルトキャッシュドライバに使用する必用があります。更に、すべてのサーバから同じ中央キャッシュサーバへ通信できる必用もあります。

<a name="lock-driver-prerequisites"></a>
### ドライバ事前要件

#### データベース

`database`キャッシュドライバを使用する場合は、キャッシュロックを含むテーブルを準備する必用があります。以下にテーブルの`Schema`定義の例を紹介します。

    Schema::create('cache_locks', function ($table) {
        $table->string('key')->primary();
        $table->string('owner');
        $table->integer('expiration');
    });

<a name="managing-locks"></a>
### ロック管理

アトミックロックにより競合状態を心配することなく、分散型のロック操作を実現できます。たとえば、[Laravel Forge](https://forge.laravel.com)では、一度に１つのリモートタスクを１つのサーバで実行するために、アトミックロックを使用しています。ロックを生成し、管理するには`Cache::lock`メソッドを使用します。

    use Illuminate\Support\Facades\Cache;

    $lock = Cache::lock('foo', 10);

    if ($lock->get()) {
        // １０秒間ロックを獲得する

        $lock->release();
    }

`get`メソッドは、クロージャも引数に取ります。クロージャ実行後、Laravelは自動的にロックを解除します。

    Cache::lock('foo')->get(function () {
        // 無期限のロックを獲得し、自動的に開放する
    });

リクエスト時にロックが獲得できないときに、指定秒数待機するようにLaravelに指示できます。指定制限時間内にロックが獲得できなかった場合は、`Illuminate\Contracts\Cache\LockTimeoutException`が投げられます。

    use Illuminate\Contracts\Cache\LockTimeoutException;

    $lock = Cache::lock('foo', 10);

    try {
        $lock->block(5);

        // 最大５秒待機し、ロックを獲得
    } catch (LockTimeoutException $e) {
        // ロックを獲得できなかった
    } finally {
        optional($lock)->release();
    }

    Cache::lock('foo', 10)->block(5, function () {
        // 最大５秒待機し、ロックを獲得
    });

<a name="managing-locks-across-processes"></a>
### プロセス間のロック管理

あるプロセスでロックを獲得し、他のプロセスで開放したい場合もあります。たとえば、Webリクエストでロックを獲得し、そのリクエストから起動したキュー済みジョブの最後で、ロックを開放したい場合です。そのようなシナリオでは、ジョブで渡されたトークンを使い、ロックを再インスタンス化できるように、ロックを限定する「所有者(owner)のトークン」をキューするジョブへ渡す必要があります。

    // コントローラ側
    $podcast = Podcast::find($id);

    $lock = Cache::lock('foo', 120);

    if ($result = $lock->get()) {
        ProcessPodcast::dispatch($podcast, $lock->owner());
    }

    // ProcessPodcastジョブ側
    Cache::restoreLock('foo', $this->owner)->release();

現在の所有者にかかわらず、ロックを開放したい場合は、`forceRelease`メソッドを使用します。

    Cache::lock('foo')->forceRelease();

<a name="adding-custom-cache-drivers"></a>
## カスタムキャッシュドライバの追加

<a name="writing-the-driver"></a>
### ドライバープログラミング

カスタムキャッシュドライバを作成するには、`Illuminate\Contracts\Cache\Store`[契約](/docs/{{version}}/contracts)を最初に実装する必要があります。そのため、MongoDBキャッシュドライバは、以下のような実装になるでしょう。

    <?php

    namespace App\Extensions;

    use Illuminate\Contracts\Cache\Store;

    class MongoStore implements Store
    {
        public function get($key) {}
        public function many(array $keys) {}
        public function put($key, $value, $seconds) {}
        public function putMany(array $values, $seconds) {}
        public function increment($key, $value = 1) {}
        public function decrement($key, $value = 1) {}
        public function forever($key, $value) {}
        public function forget($key) {}
        public function flush() {}
        public function getPrefix() {}
    }

これらのメソッドをMongoDB接続を用い、実装するだけです。各メソッドをどのように実装するかの例は、フレームワークの`Illuminate\Cache\MemcachedStore`のソースコードを参照してください。実装を完了したら、ドライバを登録します。

    Cache::extend('mongo', function ($app) {
        return Cache::repository(new MongoStore);
    });

> {tip} カスタムキャッシュドライバーをどこに設置するか迷っているなら、`app`ディレクトリ下に`Extensions`の名前空間で作成できます。しかし、Laravelはアプリケーション構造を強制していませんので、自分の好みに合わせてアプリケーションを自由に構築できることを忘れないでください。

<a name="registering-the-driver"></a>
### ドライバ登録

Laravelにカスタムキャッシュドライバを登録するには、`Cache`ファサードの`extend`メソッドを使います。新しくインストールしたLaravelに含まれている、デフォルトの`App\Providers\AppServiceProvider`の`boot`メソッドで、`Cache::extend`を呼び出せます。もしくは、拡張を設置するために自身のサービスプロバイダを作成することもできます。`config/app.php`プロバイダ配列に、そのプロバイダを登録し忘れないようにしてください。

    <?php

    namespace App\Providers;

    use App\Extensions\MongoStore;
    use Illuminate\Support\Facades\Cache;
    use Illuminate\Support\ServiceProvider;

    class CacheServiceProvider extends ServiceProvider
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
            Cache::extend('mongo', function ($app) {
                return Cache::repository(new MongoStore);
            });
        }
    }

`extend`メソッドの最初の引数はドライバ名です。これは`config/cache.php`設定ファイルの、`driver`オプションと対応します。第２引数は、`Illuminate\Cache\Repository`インスタンスを返すクロージャです。クロージャには、[サービスコンテナ](/docs/{{version}}/container)インスタンスの`$app`インスタンスが渡されます。

拡張を登録したら、`config/cache.php`設定ファイルの`driver`オプションへ、拡張の名前を登録してください。

<a name="events"></a>
## イベント

全キャッシュ操作に対してコードを実行するには、キャッシュが発行する[イベント](/docs/{{version}}/events)を購読する必要があります。通常、イベントリスナは`EventServiceProvider`の中へ設置します。

    /**
     * アプリケーションのイベントリスナ
     *
     * @var array
     */
    protected $listen = [
        'Illuminate\Cache\Events\CacheHit' => [
            'App\Listeners\LogCacheHit',
        ],

        'Illuminate\Cache\Events\CacheMissed' => [
            'App\Listeners\LogCacheMissed',
        ],

        'Illuminate\Cache\Events\KeyForgotten' => [
            'App\Listeners\LogKeyForgotten',
        ],

        'Illuminate\Cache\Events\KeyWritten' => [
            'App\Listeners\LogKeyWritten',
        ],
    ];
