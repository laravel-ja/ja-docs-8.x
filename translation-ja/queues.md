# キュー

- [イントロダクション](#introduction)
    - [接続 対 キュー](#connections-vs-queues)
    - [ドライバの注意と事前要件](#driver-prerequisites)
- [ジョブの生成](#creating-jobs)
    - [ジョブクラスの生成](#generating-job-classes)
    - [クラスの構造](#class-structure)
    - [一意なジョブ](#unique-jobs)
- [ジョブミドルウェア](#job-middleware)
    - [レート制限](#rate-limiting)
    - [ジョブのオーバーラップの防止](#preventing-job-overlaps)
    - [例外による利用制限](#throttling-exceptions)
- [ジョブのディスパッチ](#dispatching-jobs)
    - [ディスパッチの遅延](#delayed-dispatching)
    - [同期ディスパッチ](#synchronous-dispatching)
    - [ジョブとデータベーストランザクション](#jobs-and-database-transactions)
    - [ジョブチェーン](#job-chaining)
    - [キューと接続のカスタマイズ](#customizing-the-queue-and-connection)
    - [最大試行回数／タイムアウト値の指定](#max-job-attempts-and-timeout)
    - [エラー処理](#error-handling)
- [ジョブバッチ](#job-batching)
    - [Batchableジョブの定義](#defining-batchable-jobs)
    - [パッチのディスパッチ](#dispatching-batches)
    - [バッチへのジョブ追加](#adding-jobs-to-batches)
    - [バッチの検査](#inspecting-batches)
    - [バッチのキャンセル](#cancelling-batches)
    - [バッチの失敗](#batch-failures)
    - [バッチの整理](#pruning-batches)
- [クロージャのキュー投入](#queueing-closures)
- [キューワーカの実行](#running-the-queue-worker)
    - [`queue:work`コマンド](#the-queue-work-command)
    - [キューの優先度](#queue-priorities)
    - [キューワーカと開発](#queue-workers-and-deployment)
    - [ジョブの有効期限とタイムアウト](#job-expirations-and-timeouts)
- [Supervisor設定](#supervisor-configuration)
- [失敗したジョブの処理](#dealing-with-failed-jobs)
    - [ジョブ失敗の後片付け](#cleaning-up-after-failed-jobs)
    - [失敗したジョブの再試行](#retrying-failed-jobs)
    - [見つからないモデルの無視](#ignoring-missing-models)
    - [失敗したジョブイベント](#failed-job-events)
- [キューからのジョブクリア](#clearing-jobs-from-queues)
- [ジョブイベント](#job-events)

<a name="introduction"></a>
## イントロダクション

Webアプリケーションの構築中に、アップロードされたCSVファイルの解析や保存など、通常のWebリクエスト中に実行するのでは時間がかかりすぎるタスクが発生する場合があります。幸運なことに、Laravelを使用すると、バックグラウンドで処理したい仕事をキューへ投入するジョブクラスが簡単に作成できます。時間のかかるタスクをキューに移動することで、アプリケーションはWebリクエストに驚異的な速度でレスポンスし、顧客により良いユーザーエクスペリエンスを提供できます。

Laravelキューは異なったキューバックエンド間に統一したキューのAPIを提供します。[Amazon SQS](https://aws.amazon.com/sqs/)、[Redis](https://redis.io)、もしくはリレーショナルデータベースでさえ使えます。

Laravelのキュー設定オプションは、アプリケーションの`config/queue.php`設定ファイルへ保存します。このファイルには、データベース、[Amazon SQS](https://aws.amazon.com/sqs/), [Redis](https://redis.io), [Beanstalkd](https://beanstalkd.github.io/)ドライバを含む、フレームワークが用意しているキュードライバの各接続設定が含まれています。また、キューに投入されたジョブを破棄する `null` キュードライバも含まれています。

> {tip} Laravelは、Redisを利用したキュー用の美しいダッシュボードと設定システムであるHorizo​​nも提供しています。詳細は、完全な[Horizo​​nドキュメント](/docs/{{version}}/horizo​​n)を確認してください。

<a name="connections-vs-queues"></a>
### 接続 対 キュー

Laravelキューを使い始める前に、「接続」と「キュー」の違いを理解することが重要です。`config/queue.php`設定ファイルには、`connections`設定配列があります。このオプションは、Amazon SQS、Beanstalk、Redisなどのバックエンドキューサービスへの接続を定義します。ただし、特定のキュー接続には複数の「キュー」があり、キューに投入するジョブの異なるスタックまたはパイルと考えられます。

`queue`設定ファイルの各接続設定例には`queue`属性が含まれていることに注意してください。これは、ジョブが特定の接続に送信されるときにジョブがディスパッチされるデフォルトのキューです。つまり、ディスパッチ先のキューを明示的に定義せずにジョブをディスパッチすると、ジョブは接続設定の`queue`属性で定義されているキューへ配置されます。

    use App\Jobs\ProcessPodcast;

    // このジョブは、デフォルト接続のデフォルトキューに送信される
    ProcessPodcast::dispatch();

    // このジョブは、デフォルトの接続の"emails"キューに送信される
    ProcessPodcast::dispatch()->onQueue('emails');

あるアプリケーションでは、ジョブを複数のキューにプッシュする必要がなく、代わりに１つの単純なキューを使用するのが好まれるでしょう。しかし、ジョブを複数のキューにプッシュすることで、ジョブの処理方法に優先順位を付けたりセグメント化したりしたいアプリケーションで特に役立ちます。Laravelキューワーカは、優先度で処理するキューを指定できるためです。たとえば、ジョブを「高`high`」キューにプッシュする場合、より高い処理優先度を与えたワーカを実行します。

    php artisan queue:work --queue=high,default

<a name="driver-prerequisites"></a>
### ドライバの注意と事前要件

<a name="database"></a>
#### データベース

`database`キュードライバを使用するには、ジョブを保持するためのデータベーステーブルが必要です。このテーブルを作成するマイグレーションを生成するには、`queue:table` Artisanコマンドを実行します。マイグレーションを作成したら、`migrate`コマンドを使用してデータベースをマイグレーションします。

    php artisan queue:table

    php artisan migrate

<a name="redis"></a>
#### Redis

`redis`キュードライバを使用するには、`config/database.php`設定ファイルでRedisデータベース接続を設定する必要があります。

**Redisクラスタ**

Redisキュー接続でRedisクラスタを使用する場合、キュー名に[キーハッシュタグ](https://redis.io/topics/cluster-spec#keys-hash-tags)を含める必要があります。これは、特定のキューのすべてのRedisキーが同じハッシュスロットに配置されるようにするために必要です。

    'redis' => [
        'driver' => 'redis',
        'connection' => 'default',
        'queue' => '{default}',
        'retry_after' => 90,
    ],

**ブロッキング**

Redisキューを使用する場合は、`block_for`設定オプションを使用して、ワーカループを反復処理し、Redisデータベースを再ポーリングする前に、ドライバがジョブが使用可能になるまで待機する時間を指定します。

キューの負荷に基づいてこの値を調整する方が、Redisデータベースを継続的にポーリングして新しいジョブを探すよりも効率的です。たとえば、値を「５」に設定して、ジョブが使用可能になるのを待つまで、ドライバが５秒間ブロックする必要があることを示すことができます。

    'redis' => [
        'driver' => 'redis',
        'connection' => 'default',
        'queue' => 'default',
        'retry_after' => 90,
        'block_for' => 5,
    ],

> {note} `block_for`を`0`に設定すると、ジョブが使用可能になるまでキューワーカが無期限にブロックします。これにより、次のジョブが処理されるまで、`SIGTERM`などのシグナルが処理されなくなります。

<a name="other-driver-prerequisites"></a>
#### その他のドライバの事前要件

以下にリストしたキュードライバには、次の依存パッケージが必要です。これらの依存パッケージは、Composerパッケージマネージャーを介してインストールできます。

<div class="content-list" markdown="1">
- Amazon SQS: `aws/aws-sdk-php ~3.0`
- Beanstalkd: `pda/pheanstalk ~4.0`
- Redis: `predis/predis ~1.0` もしくはphpredis PHP拡張
</div>

<a name="creating-jobs"></a>
## ジョブの生成

<a name="generating-job-classes"></a>
### ジョブクラスの生成

デフォルトでは、アプリケーションのすべてのqueueableジョブは、`app/Jobs`ディレクトリに保存します。`app/Jobs`ディレクトリが存在しない場合でも、`make:job` Artisanコマンドを実行すると作成されます。

    php artisan make:job ProcessPodcast

生成されたクラスは`Illuminate\Contracts\Queue\ShouldQueue`インターフェイスを実装し、そのジョブをキューに投入する必要があり、非同期で実行することをLaravelに示します。

> {tip} ジョブスタブは[スタブのリソース公開](/docs/{{version}}/artisan#stub-customization)を使用してカスタマイズできます

<a name="class-structure"></a>
### クラスの構造

ジョブクラスは非常に単純で、ジョブがキューにより処理されるときに通常呼び出す`handle`メソッドのみを持ちます。手始めに、ジョブクラスの例を見てみましょう。この例では、ポッドキャスト公開サービスを管理していて、アップロードされたポッドキャストファイルを公開する前に必要な処理があるのだと仮定してください。

    <?php

    namespace App\Jobs;

    use App\Models\Podcast;
    use App\Services\AudioProcessor;
    use Illuminate\Bus\Queueable;
    use Illuminate\Contracts\Queue\ShouldQueue;
    use Illuminate\Foundation\Bus\Dispatchable;
    use Illuminate\Queue\InteractsWithQueue;
    use Illuminate\Queue\SerializesModels;

    class ProcessPodcast implements ShouldQueue
    {
        use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

        /**
         * ポッドキャストインスタンス
         *
         * @var \App\Models\Podcast
         */
        protected $podcast;

        /**
         * 新しいジョブインスタンスの生成
         *
         * @param  App\Models\Podcast  $podcast
         * @return void
         */
        public function __construct(Podcast $podcast)
        {
            $this->podcast = $podcast;
        }

        /**
         * ジョブの実行
         *
         * @param  App\Services\AudioProcessor  $processor
         * @return void
         */
        public function handle(AudioProcessor $processor)
        {
            // アップロードされたポッドキャストを処理…
        }
    }

この例では、[Eloquentモデル](/docs/{{version}}/eloquent)をキュー投入するジョブのコンストラクタへ直接渡すことができたことに注意してください。ジョブが使用している`SerializesModels`トレイトにより、Eloquentモデルとそれらのロード済みリレーションは、ジョブの処理時に正常にシリアル化および非シリアル化されます。

キュー投入するジョブがコンストラクタでEloquentモデルを受け入れる場合、モデルの識別子のみがキューにシリアル化されます。ジョブが実際に処理されると、キューシステムは、完全なモデルインスタンスとそのロード済みリレーションをデータベースから自動的に再取得します。モデルのシリアル化に対するこのアプローチにより、はるかに小さなジョブペイロードをキュードライバに送信できます。

<a name="handle-method-dependency-injection"></a>
#### `handle`メソッドの依存注入

`handle`メソッドは、ジョブがキューにより処理されるときに呼び出されます。そのジョブの`handle`メソッドで依存関係をタイプヒントできることに注意してください。Laravel[サービスコンテナ](/docs/{{version}}/container)は、これらの依存関係を自動的に依存注入します。

コンテナが依存関係を`handle`メソッドへ依存注入する方法を完全に制御したい場合は、コンテナの`bindMethod`メソッドを使用します。`bindMethod`メソッドは、ジョブとコンテナを受け取るコールバックを受け入れます。コールバック内で、必要に応じて`handle`メソッドを自由に呼び出すことができます。通常、このメソッドは、`App\Providers\AppServiceProvider`[サービスプロバイダ](/docs/{{version}}/provider)の`boot`メソッドから呼び出す必要があります。

    use App\Jobs\ProcessPodcast;
    use App\Services\AudioProcessor;

    $this->app->bindMethod([ProcessPodcast::class, 'handle'], function ($job, $app) {
        return $job->handle($app->make(AudioProcessor::class));
    });

> {note} 素の画像の内容などあｊのバイナリデータは、キュー投入するジョブへ渡す前に、`base64_encode`関数を介して渡す必要があります。そうしないと、ジョブがキューに配置されたときにJSONへ適切にシリアル化されない可能性があります。

<a name="handling-relationships"></a>
#### リレーションの処理

ロード済みリレーションもシリアル化されるため、シリアル化結果のジョブ文字列が非常に大きくなる場合があります。リレーションがシリアル化されないようにするために、プロパティ値を設定するときにモデルで`withoutRelations`メソッドを呼び出すことができます。このメソッドは、ロード済みリレーションを持たないモデルのインスタンスを返します。

    /**
     * 新しいジョブインスタンスの生成
     *
     * @param  \App\Models\Podcast  $podcast
     * @return void
     */
    public function __construct(Podcast $podcast)
    {
        $this->podcast = $podcast->withoutRelations();
    }

<a name="unique-jobs"></a>
### 一意なジョブ

> {note} 一意なジョブには、[ロック](/docs/{{version}}/cache#atomic-locks)をサポートするキャッシュドライバが必要です。現在、`memcached`、`redis`、`dynamodb`、`database`、`file`、`array`キャッシュドライバはアトミックロックをサポートしています。また、一意なジョブの制約は、バッチ内のジョブには適用されません。

特定のジョブの１つのインスタンスのみを確実にキューで常に存在させたい場合があります。これを行うには、ジョブクラスに`ShouldBeUnique`インターフェイスを実装します。このインターフェイスでは、クラスへ追加のメソッドを定義する必要はありません。

    <?php

    use Illuminate\Contracts\Queue\ShouldQueue;
    use Illuminate\Contracts\Queue\ShouldBeUnique;

    class UpdateSearchIndex implements ShouldQueue, ShouldBeUnique
    {
        ...
    }

上記の例では、`UpdateSearchIndex`ジョブは一意になります。したがって、ジョブの別のインスタンスがすでにキューにあり、処理が完了していない場合、ジョブはディスパッチされません。

場合によっては、ジョブを一意にする特定の「キー」を定義したり、それを超えるとジョブが一意でなくなるタイムアウトを指定したりすることができます。これを行うには、ジョブクラスで`uniqueId`および`uniqueFor`プロパティまたはメソッドを定義します。

    <?php

    use App\Product;
    use Illuminate\Contracts\Queue\ShouldQueue;
    use Illuminate\Contracts\Queue\ShouldBeUnique;

    class UpdateSearchIndex implements ShouldQueue, ShouldBeUnique
    {
        /**
         * 製品インスタンス
         *
         * @var \App\Product
         */
        public $product;

        /**
         * ジョブの一意のロックが解放されるまでの秒数
         *
         * @var int
         */
        public $uniqueFor = 3600;

        /**
         * ジョブの一意のID
         *
         * @return string
         */
        public function uniqueId()
        {
            return $this->product->id;
        }
    }

上記の例では、`UpdateSearchIndex`ジョブは製品IDによって一意になります。したがって、同じ製品IDを持つジョブの新しいディスパッチは、既存のジョブが処理を完了するまで無視されます。さらに、既存のジョブが１時間以内に処理されない場合、一意のロックが解放され、同じ一意のキーを持つ別のジョブをキューにディスパッチできます。

<a name="keeping-jobs-unique-until-processing-begins"></a>
#### 処理が開始されるまでジョブを一意に保つ

ジョブが処理を完了した後、または再試行にすべて失敗した後、一意のジョブは「ロック解除」されるのがデフォルト動作です。ただし、ジョブが処理される直前にロックを解除したい場合もあるでしょう。これを実現するには、ジョブで「`ShouldBeUnique`契約ではなく`ShouldBeUniqueUntilProcessing`契約を実装する必要があります。

    <?php

    use App\Product;
    use Illuminate\Contracts\Queue\ShouldQueue;
    use Illuminate\Contracts\Queue\ShouldBeUniqueUntilProcessing;

    class UpdateSearchIndex implements ShouldQueue, ShouldBeUniqueUntilProcessing
    {
        // ...
    }

<a name="unique-job-locks"></a>
#### 一意なジョブロック

`ShouldBeUnique`ジョブがディスパッチされると、裏でLaravelは`uniqueId`キーを使用して[ロック](/docs/{{version}}/cache#atomic-locks)を取得しようとします。ロックが取得されていない場合、ジョブはディスパッチされません。このロックは、ジョブが処理を完了するか、再試行にすべて失敗すると解放されます。Laravelはデフォルトのキャッシュドライバを使用してこのロックを取得するのがデフォルト動作です。ただし、ロックを取得するために別のドライバを使用する場合は、使用するキャッシュドライバを返す`uniqueVia`メソッドを定義します。

    use Illuminate\Support\Facades\Cache;

    class UpdateSearchIndex implements ShouldQueue, ShouldBeUnique
    {
        ...

        /**
         * 一意のジョブロックのキャッシュドライバを取得
         *
         * @return \Illuminate\Contracts\Cache\Repository
         */
        public function uniqueVia()
        {
            return Cache::driver('redis');
        }
    }

> {tip} ジョブの同時処理を制限するだけでよい場合は、代わりに[`WithoutOverlapping`](/docs/{{version}}/queues#preventing-job-overlaps)ジョブミドルウェアを使用してください。

<a name="job-middleware"></a>
## ジョブミドルウェア

ジョブミドルウェアを使用すると、キュー投入するジョブの実行にカスタムロジックをラップして、ジョブ自体の定型コードを減らせます。例として、LaravelのRedisレート制限機能を利用して、５秒ごとに１つのジョブのみを処理できるようにする次の「handle」メソッドを考えてみましょう。

    use Illuminate\Support\Facades\Redis;

    /**
     * ジョブの実行
     *
     * @return void
     */
    public function handle()
    {
        Redis::throttle('key')->block(0)->allow(1)->every(5)->then(function () {
            info('Lock obtained...');

            // ジョブを処理…
        }, function () {
            // ロックの取得失敗

            return $this->release(5);
        });
    }

このコードは有効ですが、`handle`メソッドの実装は、Redisのレート制限ロジックが散らかっているため、ノイズが多くなります。さらに、このレート制限ロジックは、レート制限する他のジョブでも重複。

handleメソッドでレート制限を行う代わりに、レート制限を処理するジョブミドルウェアを定義できます。Laravelにはジョブミドルウェアのデフォルトの場所が存在ないため、アプリケーションのどこにでもジョブミドルウェアを配置できます。この例では、ミドルウェアを`app/Jobs/Middleware`ディレクトリに配置します。

    <?php

    namespace App\Jobs\Middleware;

    use Illuminate\Support\Facades\Redis;

    class RateLimited
    {
        /**
         * キュー投入したジョブの処理
         *
         * @param  mixed  $job
         * @param  callable  $next
         * @return mixed
         */
        public function handle($job, $next)
        {
            Redis::throttle('key')
                    ->block(0)->allow(1)->every(5)
                    ->then(function () use ($job, $next) {
                        // ロック取得

                        $next($job);
                    }, function () use ($job) {
                        // ロックの取得失敗

                        $job->release(5);
                    });
        }
    }

ご覧のとおり、[routeミドルウェア](/docs/{{version}}/middleware)のように、ジョブミドルウェアは処理中のジョブと、ジョブの処理を続行するために呼び出す必要のあるコールバックを受け取ります。

ジョブミドルウェアを作成したら、ジョブの`middleware`メソッドから返すことで、ジョブにアタッチできます。このメソッドは、`make:job` Artisanコマンドによってスカフォールドされたジョブには存在しないため、手動でジョブクラスへ追加する必要があります。

    use App\Jobs\Middleware\RateLimited;

    /**
     * このジョブを通過させるミドルウェアを取得
     *
     * @return array
     */
    public function middleware()
    {
        return [new RateLimited];
    }

<a name="rate-limiting"></a>
### レート制限

独自のレート制限ジョブミドルウェアを作成する方法を示したばかりですが、実際には、Laravelはレート制限ジョブに利用できるレート制限ミドルウェアが含まれています。[ルートのレートリミッタ](/docs/{{version}}/routing#defining-rate-limiters)と同様に、ジョブのレートリミッタは`RateLimiter`ファサードの`for`メソッドを使用して定義します。

たとえば、プレミアム顧客には制限を課さずに、一般ユーザーには１時間に１回データをバックアップできるようにしたい場合があると思います。これを実現するには、`AppServiceProvider`の`boot`メソッドで`RateLimiter`を定義します。

    use Illuminate\Cache\RateLimiting\Limit;
    use Illuminate\Support\Facades\RateLimiter;

    /**
     * 全アプリケーションサービスの初期起動処理
     *
     * @return void
     */
    public function boot()
    {
        RateLimiter::for('backups', function ($job) {
            return $job->user->vipCustomer()
                        ? Limit::none()
                        : Limit::perHour(1)->by($job->user->id);
        });
    }

上記の例では、１時間ごとのレート制限を定義しました。しかし、`perMinute`メソッドを使用して、分に基づいたレート制限も簡単に定義できます。さらに、レート制限の`by`メソッドへ任意の値を渡せます。この値は、顧客ごとにレート制限をセグメント化するために最もよく使用されます。

    return Limit::perMinute(50)->by($job->user->id);

レート制限を定義したら、`Illuminate\Queue\Middleware\RateLimited`ミドルウェアを使用してレートリミッターをバックアップジョブにアタッチできます。ジョブがレート制限を超えるたびに、このミドルウェアは、レート制限期間に基づいて適切な遅延でジョブをキューに戻します。

    use Illuminate\Queue\Middleware\RateLimited;

    /**
     * このジョブを通過させるミドルウェアを取得
     *
     * @return array
     */
    public function middleware()
    {
        return [new RateLimited('backups')];
    }

レート制限したジョブをキューに戻すと、ジョブの「試行`attempts`」の総数は増加します。それに応じて、ジョブクラスの`tries`プロパティと`maxExceptions`プロパティを調整することをお勧めします。または、[`retryUntil`メソッド](#time-based-attempts)を使用して、ジョブが試行されなくなるまでの時間を定義することもできます。

> {tip} Redisを使用している場合は、`Illuminate\Queue\Middleware\RateLimitedWithRedis`ミドルウェアを使用できます。これは、Redis用に微調整されており、基本的なレート制限ミドルウェアよりも効率的です。

<a name="preventing-job-overlaps"></a>
### ジョブのオーバーラップの防止

Laravelには、任意のキーに基づいてジョブの重複を防ぐことができる`Illuminate\Queue\Middleware\WithoutOverlapping`ミドルウェアが含まれています。これは、キュー投入したジョブが、一度に１つのジョブによってのみ変更する必要があるリソースを変更している場合に役立ちます。

たとえば、ユーザーのクレジットスコアを更新するキュー投入するジョブがあり、同じユーザーIDのクレジットスコア更新ジョブが重複しないようにしたいとします。これを実現するには、ジョブの`middleware`メソッドで`WithoutOverlapping`ミドルウェアを返してください。

    use Illuminate\Queue\Middleware\WithoutOverlapping;

    /**
     * このジョブが通過するミドルウェアを取得
     *
     * @return array
     */
    public function middleware()
    {
        return [new WithoutOverlapping($this->user->id)];
    }

重複するジョブはすべてキューに戻されます。リリースしたジョブが再試行するまでに経過する必要のある秒数を指定することもできます。

    /**
     * このジョブが通過するミドルウェアを取得
     *
     * @return array
     */
    public function middleware()
    {
        return [(new WithoutOverlapping($this->order->id))->releaseAfter(60)];
    }

重複するジョブをすぐに削除して再試行しないようにする場合は、`dontRelease`メソッドを使用します。

    /**
     * このジョブが通過するミドルウェアを取得
     *
     * @return array
     */
    public function middleware()
    {
        return [(new WithoutOverlapping($this->order->id))->dontRelease()];
    }

`WithoutOverlapping`ミドルウェアはLaravelのアトミックロック機能により動作します。時々、ジョブは予期せずに失敗したり、ロックが解放されないような原因でタイムアウトしたりすることがあります。そのため、`expireAfter`メソッドを使用して、ロックの有効期限を明示的に定義することができます。たとえば、以下の例では、ジョブが処理を開始してから３分後に`WithoutOverlapping`ロックを解除するようにLaravelへ指示します。

    /**
     * このジョブが通過するミドルウェアを取得
     *
     * @return array
     */
    public function middleware()
    {
        return [(new WithoutOverlapping($this->order->id))->expireAfter(180)];
    }

> {note} `WithoutOverlapping`ミドルウェアには、[ロック](/docs/{{version}}/cache#atomic-locks)をサポートするキャッシュドライバが必要です。現在、`memcached`、`redis`、`dynamodb`、`database`、`file`、`array`キャッシュドライバはアトミックロックをサポートしています。

<a name="throttling-exceptions"></a>
### 例外による利用制限

Laravelは、例外をスロットルすることができる`Illuminate\Queue\Middleware\ThrottlesExceptions`ミドルウェアを用意しています。ジョブが指定した回数の例外を投げると、それ以降のジョブの実行は指定時間間隔が経過するまで延期されます。このミドルウェアは、不安定なサードパーティのサービスとやり取りするジョブで特に有効です。

例えば、キュー投入したジョブがサードパーティのAPIとやりとりして、例外を投げるようになったとします。例外をスロットルするには、ジョブの `middleware` メソッドから`ThrottlesExceptions`というミドルウェアを返します。通常、このミドルウェアは、[時間ベースの試行](#time-based-attempts)を実装したジョブと組み合わせて使用します。

    use Illuminate\Queue\Middleware\ThrottlesExceptions;

    /**
     * ジョブがパスする必要のあるミドルウェアの取得
     *
     * @return array
     */
    public function middleware()
    {
        return [new ThrottlesExceptions(10, 5)];
    }

    /**
     * ジョブがタイムアウトする時間を決定
     *
     * @return \DateTime
     */
    public function retryUntil()
    {
        return now()->addMinutes(30);
    }

このミドルウェアが受け取る最初のコンストラクタ引数は、スロットルされる前にジョブが投げることができる例外の数で、２番目のコンストラクタ引数は、ジョブがスロットルされた後に再度試行されるまでの時間数です。上記のコード例では、ジョブが５分以内に１０回例外を投げた場合は、もう一度ジョブを試みる前に５分間待ちます。

ジョブが例外を投げ、例外のしきい値にまだ達していない場合、ジョブは通常すぐに再試行されます。ただし、ミドルウェアをジョブに接続するときに、`backoff`メソッドを呼び出すことで、ジョブを遅らせる必要がある数分を指定できます。

    use Illuminate\Queue\Middleware\ThrottlesExceptions;

    /**
     * ジョブがパスする必要のあるミドルウェアの取得
     *
     * @return array
     */
    public function middleware()
    {
        return [(new ThrottlesExceptions(10, 5))->backoff(5)];
    }

内部的には、このミドルウェアはLaravelのキャッシュシステムを使用してレート制限を実装し、ジョブのクラス名をキャッシュ「キー」として利用します。ジョブにミドルウェアを添付するときに`by`メソッドを呼び出し、このキーを上書きできます。これは、同じサードパーティのサービスと対話するジョブが複数のジョブを持っている場合に役立ち、それらに共通のスロットル「バケット」を共有できます。

    use Illuminate\Queue\Middleware\ThrottlesExceptions;

    /**
     * ジョブがパスする必要のあるミドルウェアの取得
     *
     * @return array
     */
    public function middleware()
    {
        return [(new ThrottlesExceptions(10, 10))->by('key')];
    }

> {tip} Redisを使用している場合は、Redis用に細かく調整され、基本的な例外スロットリングミドルウェアよりも効率的な、`Illuminate\Queue\Middleware\ThrottlesExceptionsWithRedis`ミドルウェアを使用できます。

<a name="dispatching-jobs"></a>
## ジョブのディスパッチ

ジョブクラスを作成したら、ジョブ自体で`dispatch`メソッドを使用してディスパッチできます。`dispatch`メソッドに渡した引数は、ジョブのコンストラクタに渡されます。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Jobs\ProcessPodcast;
    use App\Models\Podcast;
    use Illuminate\Http\Request;

    class PodcastController extends Controller
    {
        /**
         * 新しいポッドキャストの保存
         *
         * @param  \Illuminate\Http\Request  $request
         * @return \Illuminate\Http\Response
         */
        public function store(Request $request)
        {
            $podcast = Podcast::create(...);

            // ...

            ProcessPodcast::dispatch($podcast);
        }
    }

条件付きでジョブをディスパッチする場合は、`dispatchIf`メソッドと`dispatchUnless`メソッドが使用できます。

    ProcessPodcast::dispatchIf($accountActive, $podcast);

    ProcessPodcast::dispatchUnless($accountSuspended, $podcast);

<a name="delayed-dispatching"></a>
### ディスパッチの遅延

ジョブをキューワーカによりすぐに処理できないように指定する場合は、ジョブをディスパッチするときに`delay`メソッドを使用します。たとえば、ジョブがディスパッチされてから１０分後まで処理にされないように指定してみましょう。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Jobs\ProcessPodcast;
    use App\Models\Podcast;
    use Illuminate\Http\Request;

    class PodcastController extends Controller
    {
        /**
         * 新しいポッドキャストの保存
         *
         * @param  \Illuminate\Http\Request  $request
         * @return \Illuminate\Http\Response
         */
        public function store(Request $request)
        {
            $podcast = Podcast::create(...);

            // ...

            ProcessPodcast::dispatch($podcast)
                        ->delay(now()->addMinutes(10));
        }
    }

> {note} Amazon SQSキューサービスの最大遅延時間は１５分です。

<a name="dispatching-after-the-response-is-sent-to-browser"></a>
#### レスポンスがブラウザに送信された後のディスパッチ

別の方法として、`dispatchAfterResponse`メソッドは、HTTPレスポンスがユーザーのブラウザへ送信されるまでジョブのディスパッチを遅らせます。これにより、キュー投入したジョブがまだ実行されている場合でも、ユーザーはアプリケーションの使用を開始できます。これは通常、電子メールの送信など、約１秒かかるジョブにのみ使用する必要があります。これは現在のHTTPリクエスト内で処理されるため、この方法でディスパッチされたジョブを処理するためにキューワーカを実行する必要はありません。

    use App\Jobs\SendNotification;

    SendNotification::dispatchAfterResponse();

クロージャを「ディスパッチ`dispatch`」し、`afterResponse`メソッドを`dispatch`ヘルパにチェーンしても、HTTPレスポンスがブラウザに送信された後にクロージャを実行できます。

    use App\Mail\WelcomeMessage;
    use Illuminate\Support\Facades\Mail;

    dispatch(function () {
        Mail::to('taylor@example.com')->send(new WelcomeMessage);
    })->afterResponse();

<a name="synchronous-dispatching"></a>
### 同期ディスパッチ

ジョブをすぐに（同期して）ディスパッチする場合は、`dispatchSync`メソッドを使用します。この方法を使用する場合、ジョブはキューに入らず、現在のプロセス内ですぐに実行されます。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Jobs\ProcessPodcast;
    use App\Models\Podcast;
    use Illuminate\Http\Request;

    class PodcastController extends Controller
    {
        /**
         * 新しいポッドキャストの保存
         *
         * @param  \Illuminate\Http\Request  $request
         * @return \Illuminate\Http\Response
         */
        public function store(Request $request)
        {
            $podcast = Podcast::create(...);

            // ポッドキャストの生成

            ProcessPodcast::dispatchSync($podcast);
        }
    }

<a name="jobs-and-database-transactions"></a>
### ジョブとデータベーストランザクション

データベーストランザクション内でジョブをディスパッチすることはまったく問題ありませんが、実際にジョブが正常に実行できるよう特別な注意を払う必要があります。トランザクション内でジョブをディスパッチする場合、トランザクションがコミットされる前にジョブがワーカによって処理される可能性があります。これが発生した場合、データベーストランザクション中にモデルまたはデータベースレコードに加えた更新は、データベースにまだ反映されていない可能性があります。さらに、トランザクション内で作成されたモデルまたはデータベースレコードは、データベースに存在しない可能性があります。

幸いに、Laravelはこの問題を回避する方法をいくつか提供しています。まず、キュー接続の設定配列で`after_commit`接続オプションを設定できます。

    'redis' => [
        'driver' => 'redis',
        // ...
        'after_commit' => true,
    ],

`after_commit`オプションが`true`の場合、データベーストランザクション内でジョブをディスパッチできます。ただし、Laravelは、開いているすべてのデータベーストランザクションがコミットされるまで待機してから、実際にジョブをディスパッチします。もちろん、現在開いているデータベーストランザクションがない場合、ジョブはすぐにディスパッチされます。

トランザクション中に発生した例外のためにトランザクションがロールバックされた場合、そのトランザクション中にディスパッチされたディスパッチされたジョブは破棄されます。

> {tip} `after_commit`設定オプションを`true`に設定すると、開いているすべてのデータベーストランザクションがコミットされた後、キュー投入したイベントリスナ、メーラブル、通知、およびブロードキャストイベントもディスパッチされます。

<a name="specifying-commit-dispatch-behavior-inline"></a>
#### コミットディスパッチ動作をインラインで指定

`after_commit`キュー接続設定オプションを`true`に設定しない場合でも、開いているすべてのデータベーストランザクションがコミットされた後に特定のジョブをディスパッチする必要があることを示すことができます。これを実現するには、`afterCommit`メソッドをディスパッチ操作にチェーンします。

    use App\Jobs\ProcessPodcast;

    ProcessPodcast::dispatch($podcast)->afterCommit();

同様に、`after_commit`設定オプションが`true`に設定されている場合でも、開いているデータベーストランザクションがコミットするのを待たずに、特定のジョブをすぐにディスパッチする必要があることを示すことができます。

    ProcessPodcast::dispatch($podcast)->beforeCommit();

<a name="job-chaining"></a>
### ジョブチェーン

ジョブチェーンを使用すると、プライマリジョブが正常に実行された後から順番に実行する必要があるキュー投入するジョブのリストを指定できます。シーケンス内の１つのジョブが失敗した場合は、残りのジョブを実行しません。キュー投入するジョブチェーンを実行するには、`Bus`ファサードが提供する`chain`メソッドを使用します。Laravelのコマンドバスは、キュー投入するジョブのディスパッチをその上で構築している、下位レベルのコンポーネントです。

    use App\Jobs\OptimizePodcast;
    use App\Jobs\ProcessPodcast;
    use App\Jobs\ReleasePodcast;
    use Illuminate\Support\Facades\Bus;

    Bus::chain([
        new ProcessPodcast,
        new OptimizePodcast,
        new ReleasePodcast,
    ])->dispatch();

ジョブクラスインスタンスをチェーンすることに加えて、クロージャをチェーンすることもできます。

    Bus::chain([
        new ProcessPodcast,
        new OptimizePodcast,
        function () {
            Podcast::update(...);
        },
    ])->dispatch();

> {note} ジョブ内で`$this->delete()`メソッドを使用してジョブを削除しても、チェーンしたジョブの処理が妨げられることはありません。チェーンは、チェーン内のジョブが失敗した場合にのみ実行を停止します。

<a name="chain-connection-queue"></a>
#### チェーン接続とキュー

チェーンジョブに使用する接続とキューを指定する場合は、`onConnection`メソッドと`onQueue`メソッドを使用します。キュー投入する各ジョブに別の接続／キューが明示的に指定されない限り、これらのメソッドでチェーンに対し指定するキュー接続とキュー名を使用します。

    Bus::chain([
        new ProcessPodcast,
        new OptimizePodcast,
        new ReleasePodcast,
    ])->onConnection('redis')->onQueue('podcasts')->dispatch();

<a name="chain-failures"></a>
#### チェーンの失敗

ジョブをチェーンする場合、`catch`メソッドを使用して、チェーン内のジョブが失敗した場合に呼び出すクロージャを指定できます。指定するコールバックは、ジョブの失敗の原因となった`Throwable`インスタンスを受け取ります。

    use Illuminate\Support\Facades\Bus;
    use Throwable;

    Bus::chain([
        new ProcessPodcast,
        new OptimizePodcast,
        new ReleasePodcast,
    ])->catch(function (Throwable $e) {
        // チェーン内のジョブが失敗
    })->dispatch();

<a name="customizing-the-queue-and-connection"></a>
### キューと接続のカスタマイズ

<a name="dispatching-to-a-particular-queue"></a>
#### 特定のキューへのディスパッチ

ジョブを他のキューに投入することで、キュー投入したジョブを「分類」し、さまざまなキューに割り当てるワーカの数に優先度を付けることもできます。これは、キュー設定ファイルで定義している他のキュー「接続」にジョブを投入するのではなく、同じ接続内の特定のキューにのみプッシュすることに注意してください。キューを指定するには、ジョブをディスパッチするときに`onQueue`メソッドを使用します。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Jobs\ProcessPodcast;
    use App\Models\Podcast;
    use Illuminate\Http\Request;

    class PodcastController extends Controller
    {
        /**
         * 新しいポッドキャストの保存
         *
         * @param  \Illuminate\Http\Request  $request
         * @return \Illuminate\Http\Response
         */
        public function store(Request $request)
        {
            $podcast = Podcast::create(...);

            // ポッドキャストの生成

            ProcessPodcast::dispatch($podcast)->onQueue('processing');
        }
    }

または、ジョブのコンストラクタ内で`onQueue`メソッドを呼び出して、ジョブのキューを指定することもできます。

    <?php

    namespace App\Jobs;

     use Illuminate\Bus\Queueable;
     use Illuminate\Contracts\Queue\ShouldQueue;
     use Illuminate\Foundation\Bus\Dispatchable;
     use Illuminate\Queue\InteractsWithQueue;
     use Illuminate\Queue\SerializesModels;

    class ProcessPodcast implements ShouldQueue
    {
        use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

        /**
         * 新しいジョブインスタンスの生成
         *
         * @return void
         */
        public function __construct()
        {
            $this->onQueue('processing');
        }
    }

<a name="dispatching-to-a-particular-connection"></a>
#### 特定の接続へのディスパッチ

アプリケーションが複数のキュー接続と対話する場合は、`onConnection`メソッドを使用してジョブをプッシュする接続を指定できます。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Jobs\ProcessPodcast;
    use App\Models\Podcast;
    use Illuminate\Http\Request;

    class PodcastController extends Controller
    {
        /**
         * 新しいポッドキャストの保存
         *
         * @param  \Illuminate\Http\Request  $request
         * @return \Illuminate\Http\Response
         */
        public function store(Request $request)
        {
            $podcast = Podcast::create(...);

            // ポッドキャストの生成

            ProcessPodcast::dispatch($podcast)->onConnection('sqs');
        }
    }

`onConnection`メソッドと`onQueue`メソッドをチェーンして、ジョブの接続とキューを指定できます。

    ProcessPodcast::dispatch($podcast)
                  ->onConnection('sqs')
                  ->onQueue('processing');

または、ジョブのコンストラクター内で`onConnection`メソッドを呼び出すことにより、ジョブの接続を指定することもできます。

    <?php

    namespace App\Jobs;

     use Illuminate\Bus\Queueable;
     use Illuminate\Contracts\Queue\ShouldQueue;
     use Illuminate\Foundation\Bus\Dispatchable;
     use Illuminate\Queue\InteractsWithQueue;
     use Illuminate\Queue\SerializesModels;

    class ProcessPodcast implements ShouldQueue
    {
        use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

        /**
         * 新しいジョブインスタンスの生成
         *
         * @return void
         */
        public function __construct()
        {
            $this->onConnection('sqs');
        }
    }

<a name="max-job-attempts-and-timeout"></a>
### 最大試行回数／タイムアウト値の指定

<a name="max-attempts"></a>
#### 最大試行回数

キュー投入したジョブの１つでエラーが発生した場合、そのジョブが無期限に再試行し続けることを普通は望まないでしょう。したがって、Laravelは、ジョブを試行できる回数または期間を指定するさまざまな方法を提供しています。

ジョブを試行できる最大回数を指定する１つの方法は、Artisanコマンドラインの`--tries`スイッチを使用することです。これは、処理中のジョブが試行する可能性のあるより具体的な回数を指定しない限り、ワーカが処理するすべてのジョブに適用します。

    php artisan queue:work --tries=3

ジョブが最大試行回数を超えると、「失敗した」ジョブと見なされます。失敗したジョブの処理の詳細は、[失敗したジョブのドキュメント](#dealing-with-failed-jobs)を参照してください。

ジョブクラス自体でジョブを試行できる最大回数を定義することで、より詳細なアプローチをとることもできます。ジョブで最大試行回数が指定されている場合、コマンドラインで指定する`--tries`値よりも優先されます。

    <?php

    namespace App\Jobs;

    class ProcessPodcast implements ShouldQueue
    {
        /**
         * ジョブを試行する回数。
         *
         * @var int
         */
        public $tries = 5;
    }

<a name="time-based-attempts"></a>
#### 時間ベースの試行

ジョブが失敗するまでに試行できる回数を定義する代わりに、ジョブをそれ以上実行しない時間を定義することもできます。これにより、特定の時間枠内でジョブを何度も試行できます。ジョブを試行しないタイムアウトを定義するには、ジョブクラスに`retryUntil`メソッドを追加します。このメソッドは`DateTime`インスタンスを返す必要があります:

    /**
     * ジョブがタイムアウトする時間を決定
     *
     * @return \DateTime
     */
    public function retryUntil()
    {
        return now()->addMinutes(10);
    }

> {tip} [キュー投入済みイベントリスナ](/docs/{{version}}/events#queued-event-listeners)で`tries`プロパティまたは`retryUntil`メソッドを定義することもできます。

<a name="max-exceptions"></a>
#### 最大例外数

あるジョブを何度も試行してもよいが、所定の数の未処理の例外が発生した場合には失敗するように指定したい場合があるかもしれません。(`release`メソッドによって直接解放されるのではなく、所定の数の未処理の例外が発生した場合。)これを実現するには、ジョブクラスに `maxExceptions`プロパティを定義します。

    <?php

    namespace App\Jobs;

    use Illuminate\Support\Facades\Redis;

    class ProcessPodcast implements ShouldQueue
    {
        /**
         * ジョブを試行する回数。
         *
         * @var int
         */
        public $tries = 25;

        /**
         * 失敗する前に許可する未処理の例外の最大数
         *
         * @var int
         */
        public $maxExceptions = 3;

        /**
         * ジョブの実行
         *
         * @return void
         */
        public function handle()
        {
            Redis::throttle('key')->allow(10)->every(60)->then(function () {
                // ロックを取得し、ポッドキャストを処理する
            }, function () {
                // ロックを獲得できなかった
                return $this->release(10);
            });
        }
    }

この例では、アプリケーションがRedisロックを取得できない場合、ジョブは１０秒間解放され、最大２５回再試行され続けます。ただし、ジョブによって３つの未処理の例外がスローされると、ジョブは失敗します。

<a name="timeout"></a>
#### タイムアウト

> {note} ジョブのタイムアウトを指定するには、`pcntl` PHP拡張機能をインストールする必要があります。

多くの場合、キュー投入したジョブにかかると予想されるおおよその時間をあなたは知っています。このため、Laravelでは「タイムアウト」値も指定できます。ジョブがタイムアウト値で指定する秒数より長く処理されている場合、ジョブを処理しているワーカはエラーで終了します。通常、ワーカは[サーバで設定したプロセスマネージャ](#supervisor-configuration)によって自動的に再起動されます。

ジョブを実行できる最大秒数は、Artisanコマンドラインの`--timeout`スイッチを使用して指定できます。

    php artisan queue:work --timeout=30

ジョブが継続的にタイムアウトして最大試行回数を超えた場合、失敗としてマークされます。

また、ジョブクラス自体でジョブの実行を許可する最大秒数を定義することもできます。ジョブでタイムアウトが指定されている場合、コマンドラインで指定されているタイムアウトよりも優先されます。

    <?php

    namespace App\Jobs;

    class ProcessPodcast implements ShouldQueue
    {
        /**
         * タイムアウトになる前にジョブを実行できる秒数
         *
         * @var int
         */
        public $timeout = 120;
    }

ソケットや送信HTTP接続などのＩ／Ｏブロッキングプロセスが、指定するタイムアウトを尊重しない場合があります。したがって、これらの機能を使用するときは、常にAPIを使用してタイムアウトを指定するようにしてください。たとえば、Guzzleを使用する場合は、常に接続を指定し、タイムアウト値をリクエストする必要があります。

<a name="error-handling"></a>
### エラー処理

ジョブの処理中に例外が投げられた場合、ジョブは自動的にキューへ解放されるため、再試行できます。ジョブは、アプリケーションで許可されている最大回数試行されるまで解放され続けます。最大試行回数は、`queue:work`　Artisanコマンドで使用される`--tries`スイッチによって定義されます。または、最大試行回数をジョブクラス自体で定義することもできます。キューワーカの実行の詳細は、[以下で見つかります](#running-the-queue-worker)。

<a name="manually-releasing-a-job"></a>
#### 手動でジョブを解放

後で再試行できるように、ジョブを手動でキューへ戻したい場合があります。これは、`release`メソッドを呼び出すことで実現できます。

    /**
     * ジョブの実行
     *
     * @return void
     */
    public function handle()
    {
        // ...

        $this->release();
    }

デフォルトでは、`release`メソッドはジョブをキューへ戻し、すぐに処理します。ただし、整数を`release`メソッドに渡すことで、その指定する秒数が経過するまでジョブを処理しないようにキューへ指示できます。

    $this->release(10);

<a name="manually-failing-a-job"></a>
#### 手動でジョブを失敗させる

場合によっては、ジョブを「失敗した」として手動でマークする必要があります。これには、`fail`メソッドを呼び出してください。

    /**
     * ジョブの実行
     *
     * @return void
     */
    public function handle()
    {
        // ...

        $this->fail();
    }

キャッチした例外が原因でジョブを失敗としてマークしたい場合は、例外を`fail`メソッドへ渡せます。

    $this->fail($exception);

> {tip} 失敗したジョブの詳細は、[ジョブの失敗の処理に関するドキュメント](#dealing-with-failed-jobs)を確認してください。

<a name="job-batching"></a>
## ジョブバッチ

Laravelのジョブバッチ機能を使用すると、ジョブのバッチを簡単に実行し、ジョブのバッチの実行が完了したときに何らかのアクションを実行できます。利用を開始する前に、データベースマイグレーションを作成して、完了率などのジョブバッチに関するメタ情報を含むテーブルを作成する必要があります。このマイグレーションは、`queue:batches-table` Artisanコマンドを使用して生成できます。

    php artisan queue:batches-table

    php artisan migrate

<a name="defining-batchable-jobs"></a>
### Batchableジョブの定義

バッチ可能なジョブを定義するには、通常どおり[キュー可能なジョブを作成](#creating-jobs)する必要があります。ただし、ジョブクラスに`Illuminate\Bus\Batchable`トレイトを追加する必要があります。このトレイトは、ジョブを実行している現在のバッチを取得するために使用する`batch`メソッドへのアクセスを提供します。

    <?php

    namespace App\Jobs;

    use Illuminate\Bus\Batchable;
    use Illuminate\Bus\Queueable;
    use Illuminate\Contracts\Queue\ShouldQueue;
    use Illuminate\Foundation\Bus\Dispatchable;
    use Illuminate\Queue\InteractsWithQueue;
    use Illuminate\Queue\SerializesModels;

    class ImportCsv implements ShouldQueue
    {
        use Batchable, Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

        /**
         * ジョブの実行
         *
         * @return void
         */
        public function handle()
        {
            if ($this->batch()->cancelled()) {
                // バッチがキャンセルされたかどうかを判定

                return;
            }

            // CSVファイルの一部をインポート…
        }
    }

<a name="dispatching-batches"></a>
### パッチのディスパッチ

ジョブのバッチをディスパッチするには、`Bus`ファサードの`batch`メソッドを使用する必要があります。もちろん、バッチ処理は、完了コールバックと組み合わせるとき、主に役立ちます。したがって`then`、`catch`、`finally`メソッドを使用して、バッチの完了コールバックを定義できます。これらの各コールバックは、呼び出されたときに`Illuminate\Bus\Batch`インスタンスを受け取ります。以下の例では、CSVファイルから指定する数の行をそれぞれ処理するジョブのバッチをキューに入れていると仮定します。

    use App\Jobs\ImportCsv;
    use Illuminate\Bus\Batch;
    use Illuminate\Support\Facades\Bus;
    use Throwable;

    $batch = Bus::batch([
        new ImportCsv(1, 100),
        new ImportCsv(101, 200),
        new ImportCsv(201, 300),
        new ImportCsv(301, 400),
        new ImportCsv(401, 500),
    ])->then(function (Batch $batch) {
        // すべてのジョブが正常に完了
    })->catch(function (Batch $batch, Throwable $e) {
        // バッチジョブの失敗をはじめて検出
    })->finally(function (Batch $batch) {
        // バッチの実行が終了
    })->dispatch();

    return $batch->id;

バッチのIDは、`$batch->id`プロパティを介してアクセスでき、ディスパッチ後のバッチに関する情報を[Laravelコマンドバスに照会](#inspecting-batches)するために使用できます。

<a name="naming-batches"></a>
#### 名前付きバッチ

LaravelHorizo​​nやLaravelTelescopeなどの一部のツールは、バッチに名前が付けられている場合、バッチのよりユーザーフレンドリーなデバッグ情報を提供します。バッチに任意の名前を割り当てるには、バッチを定義するときに`name`メソッドを呼び出すことができます。

    $batch = Bus::batch([
        // ...
    ])->then(function (Batch $batch) {
        // すべてのジョブが正常に完了
    })->name('Import CSV')->dispatch();

<a name="batch-connection-queue"></a>
#### バッチ接続とキュー

バッチ処理されたジョブに使用する接続とキューを指定する場合は、`onConnection`メソッドと`onQueue`メソッドを使用できます。バッチ処理するすべてのジョブは、同じ接続とキュー内で実行する必要があります。

    $batch = Bus::batch([
        // ...
    ])->then(function (Batch $batch) {
        // すべてのジョブが正常に完了
    })->onConnection('redis')->onQueue('imports')->dispatch();

<a name="chains-within-batches"></a>
#### バッチ内のチェーン

配列内に配置することにより、バッチ内で一連の[ジョブチェーン](#job-chaining)を定義できます。たとえば、２つのジョブチェーンを並行して実行し、両方のジョブチェーンの処理が終了したときにコールバックを実行するとしましょう。

    use App\Jobs\ReleasePodcast;
    use App\Jobs\SendPodcastReleaseNotification;
    use Illuminate\Bus\Batch;
    use Illuminate\Support\Facades\Bus;

    Bus::batch([
        [
            new ReleasePodcast(1),
            new SendPodcastReleaseNotification(1),
        ],
        [
            new ReleasePodcast(2),
            new SendPodcastReleaseNotification(2),
        ],
    ])->then(function (Batch $batch) {
        // ...
    })->dispatch();

<a name="adding-jobs-to-batches"></a>
### バッチへのジョブ追加

バッチ処理するジョブ内からそのバッチへジョブを追加できると便利です。このパターンは、Webリクエスト中にディスパッチするのに時間がかかりすぎるだろう何千ものジョブをバッチ処理する必要がある場合に役立ちます。したがって、代わりに、バッチをより多くのジョブとハイドレイトする「ローダー」ジョブを最初のバッチとしてディスパッチすることを推奨します。

    $batch = Bus::batch([
        new LoadImportBatch,
        new LoadImportBatch,
        new LoadImportBatch,
    ])->then(function (Batch $batch) {
        // すべてのジョブが正常に完了
    })->name('Import Contacts')->dispatch();

この例では、`LoadImportBatch`ジョブを使用して、追加のジョブでバッチをハイドレイトします。これを実現するために、ジョブの`batch`メソッドを介してアクセスできるバッチインスタンスで`add`メソッドを使用できます。

    use App\Jobs\ImportContacts;
    use Illuminate\Support\Collection;

    /**
     * ジョブの実行
     *
     * @return void
     */
    public function handle()
    {
        if ($this->batch()->cancelled()) {
            return;
        }

        $this->batch()->add(Collection::times(1000, function () {
            return new ImportContacts;
        }));
    }

> {note} 同じバッチに属するジョブ内からのみ、バッチにジョブを追加できます。

<a name="inspecting-batches"></a>
### バッチの検査

バッチ完了コールバックに渡される`Illuminate\Bus\Batch`インスタンスは、特定のジョブのバッチを操作および検査をサポートするために、さまざまなプロパティとメソッドを用意しています。

    // バッチのUUID
    $batch->id;

    // バッチの名前(該当する場合)
    $batch->name;

    // バッチに割り当てたジョブの数
    $batch->totalJobs;

    // キューにより処理されていないジョブの数
    $batch->pendingJobs;

    // 失敗したジョブの数
    $batch->failedJobs;

    // これまでに処理したジョブの数
    $batch->processedJobs();

    // バッチの完了率(0-100)
    $batch->progress();

    // バッチの実行が終了したかを判定
    $batch->finished();

    // バッチの実行をキャンセル
    $batch->cancel();

    // バッチがキャンセルされたかを判定
    $batch->cancelled();

<a name="returning-batches-from-routes"></a>
#### ルートからバッチを返す

すべての`Illuminate\Bus\Batch`インスタンスはJSONシリアル化可能です。つまり、アプリケーションのルートの1つから直接それらを返し、完了の進行状況など、バッチに関する情報を含むJSONペイロードを取得できます。これにより、バッチの完了の進行状況に関する情報をアプリケーションのUIに表示するのに便利です。

IDでバッチを取得するには、`Bus`ファサードの`findBatch`メソッドを使用します。

    use Illuminate\Support\Facades\Bus;
    use Illuminate\Support\Facades\Route;

    Route::get('/batch/{batchId}', function (string $batchId) {
        return Bus::findBatch($batchId);
    });

<a name="cancelling-batches"></a>
### バッチのキャンセル

特定のバッチの実行をキャンセルする必要が起きることもあるでしょう。これは、`Illuminate\Bus\Batch`インスタンスで`cancel`メソッドを呼び出すことで実行できます。

    /**
     * ジョブの実行
     *
     * @return void
     */
    public function handle()
    {
        if ($this->user->exceedsImportLimit()) {
            return $this->batch()->cancel();
        }

        if ($this->batch()->cancelled()) {
            return;
        }
    }

前例でお気づきかもしれませんが、バッチ中のジョブは通常、`handle`メソッドの開始時にバッチがキャンセルされたか確認する必要があります。

    /**
     * ジョブの実行
     *
     * @return void
     */
    public function handle()
    {
        if ($this->batch()->cancelled()) {
            return;
        }

        // 処理を続ける…
    }

<a name="batch-failures"></a>
### バッチの失敗

バッチ処理されたジョブが失敗すると、`catch`コールバック(割り当てられている場合)が呼び出されます。このコールバックは、バッチ内で失敗した最初のジョブに対してのみ呼び出されます。

<a name="allowing-failures"></a>
#### 失敗の許可

バッチ内のジョブが失敗すると、Laravelは自動的にバッチを「キャンセル済み」としてマークします。必要に応じて、この動作を無効にして、ジョブの失敗によってバッチがキャンセル済みとして自動的にマークされないようにすることができます。これは、バッチのディスパッチ中に`allowFailures`メソッドを呼び出すことで実現できます。

    $batch = Bus::batch([
        // ...
    ])->then(function (Batch $batch) {
        // すべてのジョブが正常に完了
    })->allowFailures()->dispatch();

<a name="retrying-failed-batch-jobs"></a>
#### 失敗したバッチジョブの再試行

便利なように、Laravelは`queue:retry-batch` Artisanコマンドを用意しており、特定のバッチで失敗したすべてのジョブを簡単に再試行できます。`queue:retry-batch`コマンドは、失敗したジョブを再試行する必要があるバッチのUUIDを引数に取ります。

```bash
php artisan queue:retry-batch 32dbc76c-4f82-4749-b610-a639fe0099b5
```

<a name="pruning-batches"></a>
### バッチの整理

整理しないと、`job_batches`テーブルにレコードがあっという間に蓄積されます。これを軽減するには、`queue:prune-batches` Artisanコマンドを毎日実行するように[スケジュール](/docs/{{version}}/scheduling)する必要があります。

    $schedule->command('queue:prune-batches')->daily();

デフォルトでは、完了してから２４時間以上経過したすべてのバッチが整理されます。バッチデータを保持する時間を決定するためにコマンド呼び出し時に`hours`オプションを使用できます。たとえば、次のコマンドは４８時間以上前に終了したすべてのバッチを削除します。

    $schedule->command('queue:prune-batches --hours=48')->daily();

時々、`jobs_batches` テーブルに、ジョブが失敗して再試行も成功しなかったバッチなど、正常に完了しなかったバッチのバッチレコードが蓄積されることがあります。`queue:prune-batches`コマンドで`unfinished`オプションを使って、こうした未完了のバッチレコードを削除するように指示できます。

    $schedule->command('queue:prune-batches --hours=48 --unfinished=72')->daily();

<a name="queueing-closures"></a>
## クロージャのキュー投入

ジョブクラスをキューにディスパッチする代わりに、クロージャをディスパッチすることもできます。これは、現在のリクエストサイクルの外で実行する必要がある迅速で単純なタスクに最適です。クロージャをキューにディスパッチする場合、クロージャのコードコンテンツは暗号で署名されているため、転送中に変更することはできません。

    $podcast = App\Podcast::find(1);

    dispatch(function () use ($podcast) {
        $podcast->publish();
    });

`catch`メソッドを使用して、キューで[設定した再試行](#max-job-attempts-and-timeout)をすべて使い果たしても、キュー投入したクロージャが正常に完了しなかった場合に実行する必要があるクロージャを提供できます。

    use Throwable;

    dispatch(function () use ($podcast) {
        $podcast->publish();
    })->catch(function (Throwable $e) {
        // このジョブは失敗
    });

<a name="running-the-queue-worker"></a>
## キューワーカの実行

<a name="the-queue-work-command"></a>
### `queue:work`コマンド

Laravelは、キューワーカを開始し、キューに投入された新しいジョブを処理するArtisanコマンドを用意しています。`queue:work` Artisanコマンドを使用してワーカを実行します。`queue:work`コマンドを開始すると、手動で停止するか、ターミナルを閉じるまで実行され続けることに注意してください。

    php artisan queue:work

> {tip} `queue:work`プロセスをバックグラウンドで永続的に実行し続けるには、[Supervisor](#supervisor-configuration)などのプロセスモニタを使用して、キューワーカの実行が停止しないようにする必要があります。

キューワーカは長期間有効なプロセスであり、起動した時点のアプリケーションの状態をメモリに保存することを忘れないでください。その結果、起動後にコードベースの変更に気付くことはありません。したがって、デプロイメントプロセス中で、必ず[キューワーカを再起動](#queue-workers-and-deployment)してください。さらに、アプリケーションによって作成または変更された静的状態は、ジョブ間で自動的にリセットされないことに注意してください。

もしくは、`queue:listen`コマンドを実行することもできます。`queue:listen`コマンドを使用する場合、更新されたコードをリロードしたり、アプリケーションの状態をリセットしたりするときに、ワーカを手動で再起動する必要はありません。ただし、このコマンドは`queue:work`コマンドよりも大幅に効率が低くなります。

    php artisan queue:listen

<a name="running-multiple-queue-workers"></a>
#### 複数のキューワーカの実行

複数のワーカをキューへ割り当ててジョブを同時に処理するには、複数の`queue:work`プロセスを開始するだけです。これは、ターミナルの複数のタブを介してローカルで実行することも、プロセスマネージャーの設定設定を使用して本番環境で実行することもできます。[スーパーバイザーを使用する場合](#supervisor-configuration)、`numprocs`設定値が使用できます。

<a name="specifying-the-connection-queue"></a>
#### 接続とキューの指定

ワーカが使用するキュー接続を指定することもできます。`work`コマンドに渡される接続名は、`config/queue.php`設定ファイルで定義されている接続の1つに対応している必要があります。

    php artisan queue:work redis

特定の接続の特定のキューのみを処理することで、キューワーカをさらにカスタマイズできます。たとえば、すべてのメールを`redis`キュー接続の`emails`キューで処理する場合、次のコマンドを発行して、そのキューのみを処理するワーカを起動できます。

    php artisan queue:work redis --queue=emails

<a name="processing-a-specified-number-of-jobs"></a>
#### 指定数ジョブの処理

`--once`オプションを使用して、キューから１つのジョブのみを処理するようにワーカに指示できます。

    php artisan queue:work --once

`--max-jobs`オプションを使用して、指定する数のジョブを処理してから終了するようにワーカに指示できます。このオプションは、[Supervisor](#supervisor-configuration)と組み合わせると便利な場合があります。これにより、ワーカは、指定する数のジョブを処理した後に自動的に再起動され、蓄積された可能性のあるメモリが解放されます。

    php artisan queue:work --max-jobs=1000

<a name="processing-all-queued-jobs-then-exiting"></a>
#### キュー投入したすべてのジョブを処理後に終了

`--stop-when-empty`オプションを使用して、すべてのジョブを処理してから正常に終了するようにワーカに指示できます。このオプションは、Dockerコンテナ内のLaravelキューを処理するときに、キューが空になった後にコンテナをシャットダウンする場合に役立ちます。

    php artisan queue:work --stop-when-empty

<a name="processing-jobs-for-a-given-number-of-seconds"></a>
#### 指定秒数のジョブの処理

`--max-time`オプションを使用して、指定する秒数の間ジョブを処理してから終了するようにワーカに指示できます。このオプションは、[Supervisor](#supervisor-configuration)と組み合わせると便利な場合があります。これにより、ジョブを一定時間処理した後、ワーカが自動的に再起動され、蓄積された可能性のあるメモリが解放されます。

    // ジョブを1時間処理してから終了
    php artisan queue:work --max-time=3600

<a name="worker-sleep-duration"></a>
#### ワーカのスリープ期間

ジョブがキューで使用可能になると、ワーカはジョブの処理を遅延なく処理し続けます。ただし、`sleep`オプションは、使用可能な新しいジョブがない場合にワーカが「スリープ」する秒数を決定します。スリープ中、ワーカは新しいジョブを処理しません。ジョブは、ワーカが再びウェイクアップした後に処理されます。

    php artisan queue:work --sleep=3

<a name="resource-considerations"></a>
#### リソースに関する検討事項

デーモンキューワーカは、各ジョブを処理する前にフレームワークを「再起動」しません。したがって、各ジョブが完了した後、重いリソースを解放する必要があります。たとえば、GDライブラリを使用して画像操作を行っている場合は、画像の処理が完了したら、`imagedestroy`を使用してメモリを解放する必要があります。

<a name="queue-priorities"></a>
### キューの優先度

キューの処理方法に優先順位を付けたい場合があります。たとえば、`config/queue.php`設定ファイルで、デフォルト`queue`を`redis`接続の`low`に設定できます。ただし、次のように、ジョブを`high`優先度キューに投入したい場合もあるでしょう。

    dispatch((new Job)->onQueue('high'));

`low`キューのジョブを続行する前に、すべての`high`キュージョブが処理されていることを確認するワーカを開始するには、キュー名のコンマ区切りリストを`work`コマンドに渡します。

    php artisan queue:work --queue=high,low

<a name="queue-workers-and-deployment"></a>
### キューワーカと開発

キューワーカは存続期間の長いプロセスであるため、再起動しない限り、コードの変更が反映されることはありません。したがって、キューワーカを使用してアプリケーションをデプロイする最も簡単な方法は、デプロイメントプロセス中にワーカを再起動することです。`queue:restart`コマンドを発行することにより、すべてのワーカを正常に再起動できます。

    php artisan queue:restart

このコマンドは、既存のジョブが失われないように、現在のジョブの処理が終了した後、すべてのキューワーカに正常に終了するように指示します。`queue:restart`コマンドを実行するとキューワーカが終了するため、[Supervisor](#supervisor-configuration)などのプロセスマネージャを実行して、キューワーカを自動的に再起動する必要があります。

> {tip} キューは[キャッシュ](/docs/{{version}}/cache)を使用して再起動シグナルを保存するため、この機能を使用する前に、アプリケーションに対してキャッシュドライバが適切に設定されていることを確認する必要があります。

<a name="job-expirations-and-timeouts"></a>
### ジョブの有効期限とタイムアウト

<a name="job-expiration"></a>
#### ジョブの有効期限

`config/queue.php`設定ファイルで、各キュー接続ごとに`retry_after`オプションが定義されています。このオプションは、処理中のジョブを再試行する前にキュー接続が待機する秒数を指定します。たとえば、`retry_after`の値が`90`に設定されている場合、ジョブが解放または削除されずに９０秒間処理されていれば、ジョブはキューに解放されます。通常、`retry_after`値は、ジョブが処理を完了するのに合理的にかかる最大秒数に設定する必要があります。

> {note} `retry_after`値を含まない唯一のキュー接続はAmazon SQSです。SQSは、AWSコンソール内で管理している[Default Visibility Timeout](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/AboutVT.html)に基づいてジョブを再試行します。

<a name="worker-timeouts"></a>
#### ワーカタイムアウト

`queue:work` Artisanコマンドは`--timeout`オプションを用意しています。ジョブがタイムアウト値で指定する秒数より長く処理されている場合、ジョブを処理しているワーカはエラーで終了します。通常、ワーカは[サーバで構築済みのプロセスマネージャ](#supervisor-configuration)によって自動的に再起動されます。

```bash
php artisan queue:work --timeout=60
```

`retry_after`設定オプションと`--timeout` CLIオプションは異なりますが、ジョブが失われないように、またジョブが１回だけ正常に処理されるように連携して機能します。

> {note} `--timeout`値は、常に`retry_after`設定値より少なくとも数秒短くする必要があります。これにより、フリーズしたジョブを処理しているワーカは、ジョブが再試行される前に常に終了します。`--timeout`オプションが`retry_after`設定値よりも長い場合、ジョブは２回処理される可能性があります。

<a name="supervisor-configuration"></a>
## Supervisor設定

本番環境では、`queue:work`プロセスを実行し続ける手段が必要です。`queue:work`プロセスは、ワーカタイムアウトの超過や、`queue:restart`コマンドの実行など、さまざまな理由で実行を停止する場合があります。

このため、`queue:work`プロセスが終了したことを検出し、自動的に再起動できるプロセスモニタを構築する必要があります。さらに、プロセスモニタを使用すると、同時に実行する`queue:work`プロセスの数を指定できます。Supervisorは、Linux環境で一般的に使用されるプロセスモニタであり、以下のドキュメントでその設定方法について説明します。

<a name="installing-supervisor"></a>
#### Supervisorのインストール

SupervisorはLinuxオペレーティングシステムのプロセスモニターであり、落ちた場合に`queue:work`プロセスを自動的に再起動します。UbuntuにSupervisorをインストールするには、次のコマンドを使用します。

    sudo apt-get install supervisor

> {tip} 自分でSupervisorを設定および管理するのが難しいと思われる場合は、[Laravel Forge](https://forge.laravel.com)の使用を検討してください。これにより、本番LaravelプロジェクトのSupervisorが自動的にインストールおよび設定されます。

<a name="configuring-supervisor"></a>
#### Supervisorの設定

Supervisor設定ファイルは通常、`/etc/supervisor/conf.d`ディレクトリに保管されます。このディレクトリ内に、プロセスの監視方法をSupervisorに指示する設定ファイルをいくつでも作成できます。たとえば、`queue:work`プロセスを開始および監視する`laravel-worker.conf`ファイルを作成してみましょう。

```ini
[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /home/forge/app.com/artisan queue:work sqs --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=forge
numprocs=8
redirect_stderr=true
stdout_logfile=/home/forge/app.com/worker.log
stopwaitsecs=3600
```

この例中の`numprocs`ディレクティブは、スーパーバイザーへ８つの`queue:work`プロセスを実行し、それらすべてを監視し、失敗した場合は自動的に再起動するように指示します。必要なキュー接続とワーカオプションを反映するように、設定の`command`ディレクティブを変更する必要があります。

> {note} `stopwaitsecs`の値が、最も長く実行されるジョブが消費する秒数よりも大きいことを確認する必要があります。そうしないと、Supervisorは処理が完了する前にジョブを強制終了する可能性があります。

<a name="starting-supervisor"></a>
#### Supervisorの起動

設定ファイルを作成したら、以下のコマンドを使用して、Supervisor設定を更新し、プロセスを開始できます。

```bash
sudo supervisorctl reread

sudo supervisorctl update

sudo supervisorctl start laravel-worker:*
```

Supervisorの詳細は、[Supervisorのドキュメント](http://supervisord.org/index.html)を参照してください。

<a name="dealing-with-failed-jobs"></a>
## 失敗したジョブの処理

キュー投入したジョブが失敗することがあります。心配しないでください、物事は常に計画通りに進むとは限りません！Laravelには、[ジョブを試行する最大回数を指定する](#max-job-attempts-and-timeout)ための便利な方法が含まれています。ジョブがこの試行回数を超えると、`failed_jobs`データベーステーブルに挿入されます。もちろん、そのテーブルがまだ存在しない場合は、作成する必要があります。`failed_jobs`テーブルのマイグレーションを作成するには、`queue:failed-table`コマンドを使用します。

    php artisan queue:failed-table

    php artisan migrate

[キューワーカ](#running-the-queue-worker)プロセスを実行する場合、`queue:work`コマンドの`--tries`スイッチを使用してジョブを試行する最大回数を指定できます。`--tries`オプションの値を指定しない場合、ジョブは１回だけ、またはジョブクラスの`$tries`プロパティで指定する回数だけ試行されます。

    php artisan queue:work redis --tries=3

`--backoff`オプションを使用して、例外が発生したジョブを再試行する前にLaravelが待機する秒数を指定できます。デフォルトでは、ジョブはすぐにキューに戻され、再試行されます。

    php artisan queue:work redis --tries=3 --backoff=3

例外が発生したジョブを再試行する前にLaravelが待機する秒数をジョブごとに設定したい場合は、ジョブクラスに`backoff`プロパティを定義することで設定できます。

    /**
     * ジョブを再試行する前に待機する秒数
     *
     * @var int
     */
    public $backoff = 3;

ジョブのバックオフ時間を決定するために複雑なロジックが必要な場合は、ジョブクラスで`backoff`メソッドを定義します。

    /**
    * ジョブを再試行する前に待機する秒数を計算
    *
    * @return int
    */
    public function backoff()
    {
        return 3;
    }

`backoff`メソッドからバックオフ値の配列を返すことで、「指数バックオフ」を簡単に設定できます。この例では、再試行の遅​​延は、最初の再試行で１秒、２回目の再試行で５秒、３回目の再試行で１０秒になります。

    /**
    * ジョブを再試行する前に待機する秒数を計算
    *
    * @return array
    */
    public function backoff()
    {
        return [1, 5, 10];
    }

<a name="cleaning-up-after-failed-jobs"></a>
### ジョブ失敗後の片付け

特定のジョブが失敗した場合、ユーザーにアラートを送信するか、ジョブによって部分的に完了したアクションを元に戻すことができます。これを実現するために、ジョブクラスで`failed`メソッドを定義できます。ジョブの失敗の原因となった`Throwable`インスタンスは、`failed`メソッドへ渡されます。

    <?php

    namespace App\Jobs;

    use App\Models\Podcast;
    use App\Services\AudioProcessor;
    use Illuminate\Bus\Queueable;
    use Illuminate\Contracts\Queue\ShouldQueue;
    use Illuminate\Queue\InteractsWithQueue;
    use Illuminate\Queue\SerializesModels;
    use Throwable;

    class ProcessPodcast implements ShouldQueue
    {
        use InteractsWithQueue, Queueable, SerializesModels;

        /**
         * ポッドキャストインスタンス
         *
         * @var \App\Podcast
         */
        protected $podcast;

        /**
         * 新しいジョブインスタンスの生成
         *
         * @param  \App\Models\Podcast  $podcast
         * @return void
         */
        public function __construct(Podcast $podcast)
        {
            $this->podcast = $podcast;
        }

        /**
         * ジョブの実行
         *
         * @param  \App\Services\AudioProcessor  $processor
         * @return void
         */
        public function handle(AudioProcessor $processor)
        {
            // Process uploaded podcast...
        }

        /**
         * ジョブの失敗を処理
         *
         * @param  \Throwable  $exception
         * @return void
         */
        public function failed(Throwable $exception)
        {
            // ユーザーへ失敗を通知するなど…
        }
    }

<a name="retrying-failed-jobs"></a>
### 失敗したジョブの再試行

`failed_jobs`データベーステーブルに挿入されたすべての失敗したジョブを表示するには、`queue:failed` Artisanコマンドを使用します。

    php artisan queue:failed

`queue:failed`コマンドは、ジョブID、接続、キュー、失敗時間、およびジョブに関するその他の情報を一覧表示します。ジョブIDは、失敗したジョブを再試行するために使用できます。たとえば、IDが「5」の失敗したジョブを再試行するには、次のコマンドを発行します。

    php artisan queue:retry 5

必要に応じて、複数のIDまたはID範囲(数値IDを使用する場合)をコマンドへ渡せます。

    php artisan queue:retry 5 6 7 8 9 10

    php artisan queue:retry --range=5-10

指定するキューの失敗したジョブをすべて再試行することもできます。

    php artisan:retry --queue=name

失敗したすべてのジョブを再試行するには、`queue:retry`コマンドを実行し、IDとして`all`を渡します。

    php artisan queue:retry all

失敗したジョブを削除したい場合は、`queue:forget`コマンドを使用します。

    php artisan queue:forget 5

> {tip} [Horizo​​n](/docs/{{version}}/horizo​​n)を使用する場合は、`queue:forget`コマンドの代わりに`horizo​​n:forget`コマンドを使用して失敗したジョブを削除する必要があります。

失敗したすべてのジョブを`failed_jobs`テーブルから削除するには、`queue:flush`コマンドを使用します。

    php artisan queue:flush

<a name="ignoring-missing-models"></a>
### 見つからないモデルの無視

Eloquentモデルをジョブに挿入すると、モデルは自動的にシリアル化されてからキューに配置され、ジョブの処理時にデータベースから再取得されます。ただし、ジョブがワーカによる処理を待機している間にモデルが削除された場合、ジョブは`ModelNotFoundException`で失敗する可能性があります。

利便性のため、ジョブの`deleteWhenMissingModels`プロパティを`true`に設定することで、モデルが見つからないジョブを自動的に削除できます。このプロパティが`true`に設定されている場合、Laravelは例外を発生させることなく静かにジョブを破棄します。

    /**
     * モデルが存在しなくなった場合は、ジョブを削除
     *
     * @var bool
     */
    public $deleteWhenMissingModels = true;

<a name="failed-job-events"></a>
### 失敗したジョブイベント

ジョブが失敗したときに呼び出されるイベントリスナを登録する場合は、`Queue`ファサードの`failing`メソッドを使用できます。たとえば、Laravelに含まれている`AppServiceProvider`の`boot`メソッドからこのイベントにクロージャをアタッチできます。

    <?php

    namespace App\Providers;

    use Illuminate\Support\Facades\Queue;
    use Illuminate\Support\ServiceProvider;
    use Illuminate\Queue\Events\JobFailed;

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
         * 全アプリケーションサービスの初期起動処理
         *
         * @return void
         */
        public function boot()
        {
            Queue::failing(function (JobFailed $event) {
                // $event->connectionName
                // $event->job
                // $event->exception
            });
        }
    }

<a name="clearing-jobs-from-queues"></a>
## キューからのジョブクリア

> {tip} [Horizo​​n](/docs/{{version}}/horizo​​n)を使用する場合は、`queue:clear`コマンドの代わりに`horizo​​n:clear`コマンドを使用してキューからジョブをクリアする必要があります。

デフォルト接続のデフォルトキューからすべてのジョブを削除する場合は、`queue:clear`Artisanコマンドを使用して削除します。

    php artisan queue:clear

特定の接続とキューからジョブを削除するために、`connection`引数と`queue`オプションを指定することもできます。

    php artisan queue:clear redis --queue=emails

> {note} キューからのジョブのクリアは、SQS、Redis、およびデータベースキュードライバでのみ使用できます。さらに、SQSメッセージの削除プロセスには最長６０秒かかるため、キューをクリアしてから最長６０秒後にSQSキューに送信されたジョブも削除される可能性があります。

<a name="job-events"></a>
## ジョブイベント

`Queue`[ファサード](/docs/{{version}}/facades)の`before`および`after`メソッドを使用して、キュー投入したジョブが処理される前または後に実行するコールバックを指定できます。これらのコールバックは、ダッシュボードの追加のログまたは増分統計を実行する絶好の機会です。通常、これらのメソッドは、[サービスプロバイダ](/docs/{{version}}/provider)の`boot`メソッドから呼び出す必要があります。たとえば、Laravelが用意している`AppServiceProvider`を使用できます。

    <?php

    namespace App\Providers;

    use Illuminate\Support\Facades\Queue;
    use Illuminate\Support\ServiceProvider;
    use Illuminate\Queue\Events\JobProcessed;
    use Illuminate\Queue\Events\JobProcessing;

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
         * 全アプリケーションサービスの初期起動処理
         *
         * @return void
         */
        public function boot()
        {
            Queue::before(function (JobProcessing $event) {
                // $event->connectionName
                // $event->job
                // $event->job->payload()
            });

            Queue::after(function (JobProcessed $event) {
                // $event->connectionName
                // $event->job
                // $event->job->payload()
            });
        }
    }

`Queue`[ファサード](/docs/{{version}}/facades)で`looping`メソッドを使用して、ワーカがキューからジョブをフェッチしようとする前に実行するコールバックを指定できます。たとえば、クロージャを登録して、以前に失敗したジョブによって開いたままになっているトランザクションをロールバックすることができます。

    use Illuminate\Support\Facades\DB;
    use Illuminate\Support\Facades\Queue;

    Queue::looping(function () {
        while (DB::transactionLevel() > 0) {
            DB::rollBack();
        }
    });
