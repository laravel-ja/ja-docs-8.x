# Redis

- [イントロダクション](#introduction)
    - [設定](#configuration)
    - [Predis](#predis)
    - [PhpRedis](#phpredis)
- [Redisの操作](#interacting-with-redis)
    - [パイプラインコマンド](#pipelining-commands)
- [publish／subscribe](#pubsub)

<a name="introduction"></a>
## イントロダクション

[Redis](https://redis.io)はオープンソースの進歩的なキー／値保存システムです。キーに[文字列](https://redis.io/topics/data-types#strings)、[ハッシュ](https://redis.io/topics/data-types#hashes)、[リスト](https://redis.io/topics/data-types#lists)、[セット](https://redis.io/topics/data-types#sets)、[ソート済みセット](https://redis.io/topics/data-types#sorted-sets)が使用できるため、データ構造サーバとしてよく名前が上がります。

LaravelでRedis使用するには、PECLを使用して[PhpRedis](https://github.com/phpredis/phpredis) PHP拡張をインストールすることを推奨します。インストール方法は複雑ですが、Redisをヘビーユースするアプリケーションではより良いパフォーマンスが得られます

もしくは、Composerで`predis/predis`パッケージをインストールすることもできます。

    composer require predis/predis

<a name="configuration"></a>
### 設定

アプリケーションのRedis設定は`config/database.php`ファイルにあります。このファイルの中に`redis`配列があり、アプリケーションで使用されるRadisサーバの設定を含んでいます。

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

デフォルトのサーバ設定は、開発時には十分でしょう。しかしご自由に自分の環境に合わせてこの配列を変更してください。Redis接続を表すシングルURLを定義していない場合、各Redisサーバの名前、ホスト、ポートの指定が必要です。

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
#### 接続スキームの設定

デフォルトでRedisサーバへの接続に、`tcp`スキームをRedisクライアントは使用します。しかし、Redisサーバ接続設定の`scheme`設定オプションを指定すれば、TLS／SSL暗号化を使用できます。

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

<a name="configuring-clusters"></a>
#### クラスタ設定

アプリケーションでRedisサーバのクラスタを使用している場合は、Redis設定の`clusters`キーで定義する必要があります。

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

デフォルトでクラスタはノード間のクライアントサイドシェアリングを実行し、ノードをプールし、利用可能な大きいRAMを作成できるようにします。しかしながら、クライアントサイドシェアリングはフェイルオーバーを処理しません。そのため、他のプライマリデータ保存域からのキャッシュデータを使用できるようにするため適しています。ネイティブなRedisクラスタリングを使用したい場合は、Redis設置の`options`キーでこれを指定してください。

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

Predis拡張を使用するには、`REDIS_CLIENT`環境変数を`phpredis`から`predis`へ変更します。

    'redis' => [

        'client' => env('REDIS_CLIENT', 'predis'),

        // 残りのRedis設定…
    ],

デフォルトの`host`、`port`、`database`、`password`オプションに加え、Predisは各Redisサーバに対する[接続パラメータ](https://github.com/nrk/predis/wiki/Connection-Parameters)を定義する機能をサポートしています。これらの追加設定オプションを使うには、`config/database.php`設定ファイルのRedisサーバ設定へ追加してください。

    'default' => [
        'host' => env('REDIS_HOST', 'localhost'),
        'password' => env('REDIS_PASSWORD', null),
        'port' => env('REDIS_PORT', 6379),
        'database' => 0,
        'read_write_timeout' => 60,
    ],

<a name="phpredis"></a>
### PhpRedis

PhpRedis拡張は、`config/database.php`の中で`REDIS_CLIENT`環境変数のデフォルトとして設定されています。

    'redis' => [

        'client' => env('REDIS_CLIENT', 'phpredis'),

        // 残りのRedis設定…
    ],

`Redis`ファサードエイリアスに加えPhpRedis拡張を使用する予定であれば、Redisクラスとの衝突を避けるために、`RedisManager`のような他の名前にリネームする必要があります。app.php`設定ファイルのエイリアスセクションで行えます。

    'RedisManager' => Illuminate\Support\Facades\Redis::class,

デフォルトの`host`、`port`、`database`、`password`オプションに加え、PhpRedisは`persistent`、`prefix`、`read_timeout`、`timeout`、`context`追加オプションをサポートしています。`config/database.php`設定ファイル中のRedisサーバ設定に、これらのオプションを追加してください。

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

<a name="the-redis-facade"></a>
#### Redisファサード

Redis PHP拡張自身と名前が衝突するのを避けるため、`app`設定ファイルの`aliases`配列から`Illuminate\Support\Facades\Redis`ファサードエイリアスを削除かリネームする必要があります。一般的には、このエイリアスを完全に取り除き、Redis PHP拡張を使用するときに完全なクラス名を指定することで、ファサードを参照するに留めるべきです。

<a name="interacting-with-redis"></a>
## Redisの操作

`Redis`[ファサード](/docs/{{version}}/facades)のバラエティー豊かなメソッドを呼び出し、Redisを操作できます。`Redis`ファサードは動的メソッドをサポートしています。つまりファサードでどんな[Redisコマンド](https://redis.io/commands)でも呼び出すことができ、そのコマンドは直接Redisへ渡されます。以下の例ではRedisの`GET`コマンドを`Redis`ファサードの`get`メソッドで呼び出しています。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use Illuminate\Support\Facades\Redis;

    class UserController extends Controller
    {
        /**
         * 指定ユーザーのプロフィール表示
         *
         * @param  int  $id
         * @return Response
         */
        public function showProfile($id)
        {
            $user = Redis::get('user:profile:'.$id);

            return view('user.profile', ['user' => $user]);
        }
    }

前記の通り、`Redis`ファサードでどんなRedisコマンドでも呼び出すことができます。Laravelはmagicメソッドを使いコマンドをRedisサーバへ送りますので、Redisコマンドで期待されている引数を渡してください。

    Redis::set('name', 'Taylor');

    $values = Redis::lrange('names', 5, 10);

サーバにコマンドを送る別の方法は`command`メソッドを使う方法です。最初の引数にコマンド名、第２引数に値の配列を渡します。

    $values = Redis::command('lrange', ['name', 5, 10]);

<a name="using-multiple-redis-connections"></a>
#### 複数のRedis接続の使用

Redisインスタンスを`Redis::connection`メソッドの呼び出しで取得できます。

    $redis = Redis::connection();

これによりデフォルトのRedisサーバのインスタンスが取得できます。さらに、Redis設定で定義した、特定のサーバやクラスタを取得するために、`connection`メソッドへ接続名やクラスタ名を渡すこともできます。

    $redis = Redis::connection('my-connection');

<a name="pipelining-commands"></a>
### パイプラインコマンド

サーバに対し多くのコマンドを送る必要がある場合はパイプラインを使うべきでしょう。`pipeline`メソッドは引数をひとつだけ取り、Redisインスタンスを取る「クロージャ」です。このRedisインスタンスは全コマンドをサーバへストリーミングするので、良いパフォーマンスが得られます。

    Redis::pipeline(function ($pipe) {
        for ($i = 0; $i < 1000; $i++) {
            $pipe->set("key:$i", $i);
        }
    });

<a name="pubsub"></a>
## publish／subscribe

さらにLaravelは、Redisの`publish`と`subscribe`コマンドの便利なインターフェイスも提供しています。これらのRedisコマンドは、指定した「チャンネル」のメッセージをリッスンできるようにしてくれます。他のアプリケーションからこのチャンネルにメッセージを公開するか、他の言語を使うこともでき、これによりアプリケーション／プロセス間で簡単に通信できます。

最初に`subscribe`メソッドでRedisを経由するチャンネルのリスナを準備します。`subscribe`メソッドは長時間動作するプロセスですので、このメソッドは[Artisanコマンド](/docs/{{version}}/artisan)の中で呼び出します。

    <?php

    namespace App\Console\Commands;

    use Illuminate\Console\Command;
    use Illuminate\Support\Facades\Redis;

    class RedisSubscribe extends Command
    {
        /**
         * コンソールコマンドの名前と使用法
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
         * コンソールコマンドの実行
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

これで`publish`メソッドを使いチャンネルへメッセージを公開できます。

    Route::get('publish', function () {
        // Route logic...

        Redis::publish('test-channel', json_encode(['foo' => 'bar']));
    });

<a name="wildcard-subscriptions"></a>
#### ワイルドカード購入

`psubscribe`メソッドでワイルドカードチャネルに対し購入できます。全チャンネルの全メッセージを補足するために便利です。`$channel`名は指定するコールバック「クロージャ」の第２引数として渡されます。

    Redis::psubscribe(['*'], function ($message, $channel) {
        echo $message;
    });

    Redis::psubscribe(['users.*'], function ($message, $channel) {
        echo $message;
    });
