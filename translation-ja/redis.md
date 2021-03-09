# Redis

- [イントロダクション](#introduction)
- [設定](#configuration)
    - [クラスタ](#clusters)
    - [Predis](#predis)
    - [phpredis](#phpredis)
- [Redisの操作](#interacting-with-redis)
    - [トランザクション](#transactions)
    - [パイプラインコマンド](#pipelining-commands)
- [Pub／Sub](#pubsub)

<a name="introduction"></a>
## イントロダクション

[Redis](https://redis.io)は、オープンソースの高度なキー／値保存域です。[文字列](https://redis.io/topics/data-types#strings), [ハッシュ](https://redis.io/topics/data-types#hashes), [リスト](https://redis.io/topics/data-types#lists), [セット](https://redis.io/topics/data-types#sets), and [ソート済みセット](https://redis.io/topics/data-types#sorted-sets).を含めることができるため、データ構造サーバと呼ばれることがあります。

LaravelでRedisを使い始める前に、PECLにより[phpredis](https://github.com/phpredis/phpredis)PHP拡張機能をインストールして使用することを推奨します。この拡張機能は、「ユーザーフレンドリー」なPHPパッケージに比べてインストールは複雑ですが、Redisを多用するアプリケーションのパフォーマンスが向上する可能性があります。[Laravel Sail](/docs/{{version}}/sale)を使用している場合、この拡張機能はアプリケーションのDockerコンテナにはじめからインストールしてあります。

phpredis拡張機能をインストールできない場合は、Composerを介して`predis/predis`パッケージをインストールしてください。PredisはすべてPHPで記述されたRedisクライアントであり、追加の拡張機能は必要ありません。

```bash
composer require predis/predis
```

<a name="configuration"></a>
## 設定

`config/database.php`設定ファイルによりアプリケーションのRedis設定を設定します。このファイル内に、アプリケーションで使用するRedisサーバを含む`redis`配列があります。

    'redis' => [

        'client' => env('REDIS_CLIENT', 'phpredis'),

        'default' => [
            'host' => env('REDIS_HOST', '127.0.0.1'),
            'password' => env('REDIS_PASSWORD', null),
            'port' => env('REDIS_PORT', 6379),
            'database' => env('REDIS_DB', 0),
        ],

        'cache' => [
            'host' => env('REDIS_HOST', '127.0.0.1'),
            'password' => env('REDIS_PASSWORD', null),
            'port' => env('REDIS_PORT', 6379),
            'database' => env('REDIS_CACHE_DB', 1),
        ],

    ],

設定ファイルで定義する各Redisサーバは、Redis接続を表す単一のURLを定義しない限り、名前、ホスト、およびポートを指定する必要があります。

    'redis' => [

        'client' => env('REDIS_CLIENT', 'phpredis'),

        'default' => [
            'url' => 'tcp://127.0.0.1:6379?database=0',
        ],

        'cache' => [
            'url' => 'tls://user:password@127.0.0.1:6380?database=1',
        ],

    ],

<a name="configuring-the-connection-scheme"></a>
#### 接続スキームの構成

RedisクライアントはRedisサーバへ接続するとき、デフォルトで`tcp`スキームを使用します。しかし、Redisサーバの設定配列で`scheme`設定オプションを指定すれば、TLS/SSL暗号化を使用できます。

    'redis' => [

        'client' => env('REDIS_CLIENT', 'phpredis'),

        'default' => [
            'scheme' => 'tls',
            'host' => env('REDIS_HOST', '127.0.0.1'),
            'password' => env('REDIS_PASSWORD', null),
            'port' => env('REDIS_PORT', 6379),
            'database' => env('REDIS_DB', 0),
        ],

    ],

<a name="clusters"></a>
### クラスタ

アプリケーションがRedisサーバのクラスタを利用する場合は、Redis設定の`clusters`キー内で使用するクラスタを定義してください。この設定キーはデフォルトでは存在しないため、アプリケーションの`config/database.php`設定ファイル内で作成する必要があります。

    'redis' => [

        'client' => env('REDIS_CLIENT', 'phpredis'),

        'clusters' => [
            'default' => [
                [
                    'host' => env('REDIS_HOST', 'localhost'),
                    'password' => env('REDIS_PASSWORD', null),
                    'port' => env('REDIS_PORT', 6379),
                    'database' => 0,
                ],
            ],
        ],

    ],

デフォルトでクラスタは、クライアント側のシャーディングをノード間で実行し、ノードをプールして大量の利用可能なRAMを作成できるようにします。ただし、クライアント側のシャーディングはフェイルオーバーを処理しません。したがって、これは主に、別のプライマリデータストアから利用できる一時的にキャッシュされたデータに適しています。

クライアント側のシャーディングの代わりにネイティブなRedisクラスタリングを使用する場合は、アプリケーションの`config/database.php`設定ファイル内で`options.cluster`設定値を`redis`に設定してください。

    'redis' => [

        'client' => env('REDIS_CLIENT', 'phpredis'),

        'options' => [
            'cluster' => env('REDIS_CLUSTER', 'redis'),
        ],

        'clusters' => [
            // ...
        ],

    ],

<a name="predis"></a>
### Predis

アプリケーションがPredisパッケージを介してRedisを操作するようにする場合は、`REDIS_CLIENT`環境変数の値を確実に`predis`へ設定してください。

    'redis' => [

        'client' => env('REDIS_CLIENT', 'predis'),

        // 残りのRedis設定…
    ],

デフォルトの`host`、`port`、`database`、`password`サーバ設定オプションに加えて、PredisはRedisサーバごとに追加の[接続パラメータ](https://github.com/nrk/predis/wiki/Connection-Parameters)定義をサポートしますアプリケーションの`config/database.php`設定ファイルのRedisサーバ設定でそれらを追加してください。

    'default' => [
        'host' => env('REDIS_HOST', 'localhost'),
        'password' => env('REDIS_PASSWORD', null),
        'port' => env('REDIS_PORT', 6379),
        'database' => 0,
        'read_write_timeout' => 60,
    ],

<a name="the-redis-facade-alias"></a>
#### Redisファサードのエイリアス

Laravelの`config/app.php`設定ファイルには、フレームワークが登録するすべてのクラスエイリアスを定義する`aliases`配列があります。便宜上、Laravelが提供する[ファサード](/docs/{{version}}/facades)ごとのエイリアスエントリを持っています。ただし、`Redis`エイリアスは、phpredis拡張機能が提供する`Redis`クラス名と競合するため無効になっています。Predisクライアントを使用していて、このエイリアスを有効にしたい場合は、アプリケーションの`config/app.php`設定ファイルでエイリアスをアンコメントしてください。

<a name="phpredis"></a>
### phpredis

デフォルトでは、Laravelはphpredis拡張機能を使用してRedisと通信します。LaravelがRedisとの通信に使用するクライアントは、`redis.client`設定オプションの値で決まります。これは通常、`REDIS_CLIENT`環境変数の値を反映します。

    'redis' => [

        'client' => env('REDIS_CLIENT', 'phpredis'),

        // 残りのRedis設定…
    ],

デフォルトの`host`、`port`、`database`、`password`サーバ設定オプションに加えて、phpredisは次の追加の接続パラメータをサポートしています。`name`、`persistent`、`prefix`、`read_timeout`、`try_interval`、`timeout`、`context`です。`config/database.php`設定ファイルのRedisサーバ設定へ、こうしたオプションを追加指定できます。

    'default' => [
        'host' => env('REDIS_HOST', 'localhost'),
        'password' => env('REDIS_PASSWORD', null),
        'port' => env('REDIS_PORT', 6379),
        'database' => 0,
        'read_timeout' => 60,
        'context' => [
            // 'auth' => ['username', 'secret'],
            // 'stream' => ['verify_peer' => false],
        ],
    ],

<a name="interacting-with-redis"></a>
## Redisの操作

`Redis`[ファサード](/docs/{{version}}/facades)でさまざまなメソッドを呼び出すことで、Redisを操作できます。`Redis`ファサードは動的メソッドをサポートしています。つまり、ファサードで[Redisコマンド](https://redis.io/commands)を呼び出すと、コマンドが直接Redisに渡されます。この例では、`Redis`ファサードで`get`メソッドを呼び出すことにより、Redisの`GET`コマンドを呼び出しています。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use Illuminate\Support\Facades\Redis;

    class UserController extends Controller
    {
        /**
         * 指定ユーザーのプロファイル表示
         *
         * @param  int  $id
         * @return \Illuminate\Http\Response
         */
        public function show($id)
        {
            return view('user.profile', [
                'user' => Redis::get('user:profile:'.$id)
            ]);
        }
    }

上記のように、`Redis`ファサードで任意のRedisコマンドを呼び出すことができます。Laravelはマジックメソッドを使用してコマンドをRedisサーバへ渡します。Redisコマンドが引数を必要とする場合は、それらをファサードの対応するメソッドへ渡す必要があります。

    use Illuminate\Support\Facades\Redis;

    Redis::set('name', 'Taylor');

    $values = Redis::lrange('names', 5, 10);

または、`Redis`ファサードの`command`メソッドを使用してサーバにコマンドを渡すこともできます。このメソッドは、コマンドの名前を最初の引数、値の配列を２番目の引数に取ります。

    $values = Redis::command('lrange', ['name', 5, 10]);

<a name="using-multiple-redis-connections"></a>
#### 複数のRedis接続の使用

アプリケーションの`config/database.php`設定ファイルでは、複数のRedis接続／サーバが定義できます。`Redis`ファサードの`connection`メソッドを使用して、特定のRedis接続への接続を取得できます。

    $redis = Redis::connection('connection-name');

デフォルトのRedis接続のインスタンスを取得するには、引数なしで`connection`メソッドを呼び出してください。

    $redis = Redis::connection();

<a name="transactions"></a>
### トランザクション

`Redis`ファサードの`transaction`メソッドは、Redisのネイティブ`MULTI`および`EXEC`コマンドの便利なラッパーを提供します。`transaction`メソッドは、唯一の引数にクロージャを取ります。このクロージャはRedis接続インスタンスを受け取り、このインスタンスで必要なコマンドを発行できます。クロージャ内で発行したすべてのRedisコマンドは、単一のアトミックトランザクションとして実行します。

    use Illuminate\Support\Facades\Redis;

    Redis::transaction(function ($redis) {
        $redis->incr('user_visits', 1);
        $redis->incr('total_visits', 1);
    });

> {note} Redisトランザクションを定義する場合、Redis接続から値を取得できません。トランザクションは単一のアトミック操作として実行し、クロージャ全体がコマンドの実行を完了するまで、操作は実行されないことに注意してください。

#### Luaスクリプト

`eval`メソッドは、単一のアトミック操作で複数のRedisコマンドを実行する別のメソッドです。ただし、`eval`メソッドには、その操作中にRedisキー／値を対話し調べられる利点があります。Redisスクリプトは、[Luaプログラミング言語](https://www.lua.org)で記述します。

`eval`メソッドは最初は少し怖いかもしれませんが、壁を超えるために基本的な例を見てみましょう。`eval`メソッドは引数をいくつか取ります。まず、Luaスクリプトを(文字列として)メソッドへ渡す必要があります。次に、スクリプトが操作するキーの数を(整数として)渡す必要があります。第三に、それらのキーの名前を渡す必要があります。最後に、スクリプト内でアクセスする必要があるその他の追加の引数を渡します。

この例では、カウンターを増分し、その新しい値を検査し、最初のカウンターの値が５より大きい場合は、２番目のカウンターを増分します。最後に、最初のカウンターの値を返します。

    $value = Redis::eval(<<<'LUA'
        local counter = redis.call("incr", KEYS[1])

        if counter > 5 then
            redis.call("incr", KEYS[2])
        end

        return counter
    LUA, 2, 'first-counter', 'second-counter');

> {note} Redisスクリプトの詳細には、[Redisドキュメント](https://redis.io/commands/eval)を参照してください。

<a name="pipelining-commands"></a>
### パイプラインコマンド

数十のRedisコマンドを実行する必要が起きることもあるでしょう。毎コマンドごとにRedisサーバへネットワークトリップする代わりに、`pipeline`メソッドを使用できます。`pipeline`メソッドは、Redisインスタンスを受け取るクロージャを１つ引数に取ります。このRedisインスタンスですべてのコマンドを発行すると、サーバへのネットワークトリップを減らすため、すべてのコマンドを一度にRedisサーバへ送信します。コマンドは、発行した順序で実行されます。

    use Illuminate\Support\Facades\Redis;

    Redis::pipeline(function ($pipe) {
        for ($i = 0; $i < 1000; $i++) {
            $pipe->set("key:$i", $i);
        }
    });

<a name="pubsub"></a>
## Pub／Sub

Laravelは、Redisの`publish`および`subscribe`コマンドへの便利なインターフェイスを提供しています。これらのRedisコマンドを使用すると、特定の「チャンネル」でメッセージをリッスンできます。別のアプリケーションから、または別のプログラミング言語を使用してメッセージをチャンネルに公開し、アプリケーションとプロセス間の簡単な通信を可能にすることができます。

まず、`subscribe`メソッドを使用してチャンネルリスナを設定しましょう。`subscribe`メソッドを呼び出すとプロセスは長時間実行され続けるため、このメソッド呼び出しは[Artisanコマンド](/docs/{{version}}/artisan)内に配置します。

    <?php

    namespace App\Console\Commands;

    use Illuminate\Console\Command;
    use Illuminate\Support\Facades\Redis;

    class RedisSubscribe extends Command
    {
        /**
         * consoleコマンドの名前と使用方法
         *
         * @var string
         */
        protected $signature = 'redis:subscribe';

        /**
         * コンソールコマンドの説明
         *
         * @var string
         */
        protected $description = 'Subscribe to a Redis channel';

        /**
         * consoleコマンドの実行
         *
         * @return mixed
         */
        public function handle()
        {
            Redis::subscribe(['test-channel'], function ($message) {
                echo $message;
            });
        }
    }

これで、`publish`メソッドを使用してチャンネルへメッセージを発行できます。

    use Illuminate\Support\Facades\Redis;

    Route::get('/publish', function () {
        // ...

        Redis::publish('test-channel', json_encode([
            'name' => 'Adam Wathan'
        ]));
    });

<a name="wildcard-subscriptions"></a>
#### ワイルドカードサブスクリプション

`psubscribe`メソッドを使用すると、ワイルドカードチャンネルをサブスクライブできます。これは、すべてのチャンネルのすべてのメッセージをキャッチするのに役立ちます。チャンネル名は、引数に渡たすクロージャの２番目の引数へ渡されます。

    Redis::psubscribe(['*'], function ($message, $channel) {
        echo $message;
    });

    Redis::psubscribe(['users.*'], function ($message, $channel) {
        echo $message;
    });
