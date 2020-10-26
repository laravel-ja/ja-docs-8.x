# Laravel Telescope

- [イントロダクション](#introduction)
- [インストレーション](#installation)
    - [設定](#configuration)
    - [データの刈り込み](#data-pruning)
    - [マイグレーションのカスタマイズ](#migration-customization)
    - [ダッシュボードの認可](#dashboard-authorization)
- [Telescopeのアップグレード](#upgrading-telescope)
- [フィルタリング](#filtering)
    - [エンティティ](#filtering-entries)
    - [バッチ](#filtering-batches)
- [タグ付け](#tagging)
- [利用可能なワッチャー](#available-watchers)
    - [Batchワッチャー](#batch-watcher)
    - [Cacheワッチャー](#cache-watcher)
    - [Commandワッチャー](#command-watcher)
    - [Dumpワッチャー](#dump-watcher)
    - [Eventワッチャー](#event-watcher)
    - [Exceptionワッチャー](#exception-watcher)
    - [Gateワッチャー](#gate-watcher)
    - [Jobワッチャー](#job-watcher)
    - [Logワッチャー](#log-watcher)
    - [Mailワッチャー](#mail-watcher)
    - [Modelワッチャー](#model-watcher)
    - [Notificationワッチャー](#notification-watcher)
    - [Queryワッチャー](#query-watcher)
    - [Redisワッチャー](#redis-watcher)
    - [Requestワッチャー](#request-watcher)
    - [Scheduleワッチャー](#schedule-watcher)
    - [Viewワッチャー](#view-watcher)
- [ユーザーアバターの表示](#displaying-user-avatars)

<a name="introduction"></a>
## イントロダクション

Laravel TelescopeはLaravelフレームワークのエレガントなデバッグアシスタントです。Telescopeはアプリケーションへ送信されたリクエスト、例外、ログエンティティ、データクエリ、キュージョブ、メール、通知、キャッシュ操作、スケジュールされたタスク、さまざまなダンプなどを提示します。TelescopeはLaravelローカル開発環境における、素晴らしいコンパニオンです。

<img src="/img/telescope.png" width="100%">

<a name="installation"></a>
## インストレーション

LaravelプロジェクトへTelescopeをインストールするには、Composerを使用します。

    composer require laravel/telescope

Telescopeをインストールしたら、`telescope:install` Artisanコマンドを使用し、アセットをリソース公開してください。Telescopeのインストールが終わったら、`migrate`コマンドも実行する必要があります。

    php artisan telescope:install

    php artisan migrate

<a name="installing-only-in-specific-environments"></a>
### 特定の環境でのみのインストレーション

Telescopeをローカル環境でのみ使用する場合は、`--dev`フラグを付けてインストールします。

    composer require laravel/telescope --dev

`telescope:install`実行後、`app`設定ファイルから`TelescopeServiceProvider`サービスプロバイダの登録を削除する必要があります。`app`設定ファイルで登録する代わりに、このサービスプロバイダを`AppServiceProvider`の`register`メソッドで登録してください。

    /**
     * 全アプリケーションサービスの登録
     *
     * @return void
     */
    public function register()
    {
        if ($this->app->isLocal()) {
            $this->app->register(\Laravel\Telescope\TelescopeServiceProvider::class);
            $this->app->register(TelescopeServiceProvider::class);
        }
    }

また、`composer.json`へ以下の内容を追加することにより、Telescopeが[自動検出](/docs/{{version}}/packages#package-discovery)されるのを防げます。

    "extra": {
        "laravel": {
            "dont-discover": [
                "laravel/telescope"
            ]
        }
    },

<a name="migration-customization"></a>
### マイグレーションのカスタマイズ

Telescopeのデフォルトマイグレーションに従わない場合、`AppServiceProvider`の`register`メソッドの中で、`Telescope::ignoreMigrations`メソッドを呼び出す必要があります。`php artisan vendor:publish --tag=telescope-migrations`コマンドを使い、デフォルトマイグレーションをエクスポートすることもできます。

<a name="configuration"></a>
### 設定

Telescopeのアセットをリソース公開すると、主となる設定ファイルが`config/telescope.php`へ設置されます。この設定ファイルでワッチャーのオプションや、説明をコメントで記述している各種の設定オプションを調整できます。そのため、このファイルを全部読んでください。

望むのであれば、`enabled`設定オプションを使用し、Telescopeのデータ収集全体を無効にできます。

    'enabled' => env('TELESCOPE_ENABLED', true),

<a name="data-pruning"></a>
### データの刈り込み

データを刈り込まないと、`telescope_entries`テーブルへとても早くレコードが集積してしまいます。これを軽減するために、`telescope:prune` Artisanコマンドを毎日実行するように、スケジュールすべきでしょう。

    $schedule->command('telescope:prune')->daily();

デフォルトでは、24時間を過ぎているすべてのエンティティが削除されます。Telescopeデータをどの期間保持するかを指定するために、コマンド呼び出し時に`hours`オプションが使えます。

    $schedule->command('telescope:prune --hours=48')->daily();

<a name="dashboard-authorization"></a>
### ダッシュボードの認可

Telescopeはデフォルトで、ダッシュボードを`/telescope`で表示します。デフォルトでは`local`環境からのみ、このダッシュボードへアクセスできます。`app/Providers/TelescopeServiceProvider.php`ファイルの中に、`gate`メソッドが存在しています。この認可ゲートで、Telescopeの**local以外**でのアクセスをコントロールできます。Telescopeに対するアクセスを宣言する必要に応じ、このゲートを自由に変更してください。

    /**
     * Telescopeゲートの登録
     *
     * このゲートはlocal以外の環境で、誰がTelescopeへアクセスできるかを決定している。
     *
     * @return void
     */
    protected function gate()
    {
        Gate::define('viewTelescope', function ($user) {
            return in_array($user->email, [
                'taylor@laravel.com',
            ]);
        });
    }

> {note} 実行環境では、`APP_ENV`環境変数を必ず`production`に変更してください。それ以外の値の場合、Telescopeインストールは一般公開されます。

<a name="upgrading-telescope"></a>
## Telescopeのアップグレード

新しいメジャーバージョンのTelescopeへアップグレードするときは、[アップグレードガイド](https://github.com/laravel/telescope/blob/master/UPGRADE.md)を注意深く読むことが重要です。

また、Telescopを新しいバージョンへアップグレードするときは、Telescopeのアセットを必ず再リソース公開してください。

    php artisan telescope:publish

アセットを最新状態に保ち、将来のアップデートで起きる問題を防ぐために、アプリケーションの`composer.json`ファイルの`post-update-cmd`スクリプトへ`telescope:publish`コマンドを追加しておくのが良いでしょう。

    {
        "scripts": {
            "post-update-cmd": [
                "@php artisan telescope:publish --ansi"
            ]
        }
    }

<a name="filtering"></a>
## フィルタリング

<a name="filtering-entries"></a>
### エンティティ

`TelescopeServiceProvider`の中で登録されている`filter`コールバックにより、Telescopeが保存するデータをフィルタリングできます。デフォルトでは、このコールバックは`local`環境、例外、失敗したジョブ、スケジュール済みタスク、他の全環境においてモニター対象とタグ付けされたデータを記録します。

    /**
     * 全アプリケーションサービスの登録
     *
     * @return void
     */
    public function register()
    {
        $this->hideSensitiveRequestDetails();

        Telescope::filter(function (IncomingEntry $entry) {
            if ($this->app->isLocal()) {
                return true;
            }

            return $entry->isReportableException() ||
                $entry->isFailedJob() ||
                $entry->isScheduledTask() ||
                $entry->hasMonitoredTag();
        });
    }

<a name="filtering-batches"></a>
### バッチ

`fileter`コールバックで個別のエンティティのデータをフィルタリングできますが、指定したリクエストやコンソールコマンドの全データをフィルタリングするコールバックを`filterBatch`メソッドにより登録できます。コールバックが`true`を返すと、Telescopeによりすべてのエンティティが保存されます。

    use Illuminate\Support\Collection;

    /**
     * 全アプリケーションサービスの登録
     *
     * @return void
     */
    public function register()
    {
        $this->hideSensitiveRequestDetails();

        Telescope::filterBatch(function (Collection $entries) {
            if ($this->app->isLocal()) {
                return true;
            }

            return $entries->contains(function ($entry) {
                return $entry->isReportableException() ||
                    $entry->isFailedJob() ||
                    $entry->isScheduledTask() ||
                    $entry->hasMonitoredTag();
                });
        });
    }

<a name="tagging"></a>
## タグ付け

Telescopeでは「タグ」により検索を登録できます。タグはEloquentモデルクラス名や認証済みユーザーのIDが多いでしょうが、Telescopeは自動的にエントリーを登録します。まれに、独自のカスタムタグエントリーを追加する必要も起きるでしょう。その場合は、`Telescope::tag`メソッドを使用してください。`tag`メソッドはタグの配列を返すコールバックを引数に取ります。コールバックから返されたタグは、Telescopeが自動的にエントリーに追加したタグとマージされます。`tag`メソッドは、`TelescopeServiceProvider`の中で呼び出してください。

    use Laravel\Telescope\Telescope;

    /**
     * 全アプリケーションサービスの登録
     *
     * @return void
     */
    public function register()
    {
        $this->hideSensitiveRequestDetails();

        Telescope::tag(function (IncomingEntry $entry) {
            if ($entry->type === 'request') {
                return ['status:'.$entry->content['response_status']];
            }

            return [];
        });
     }

<a name="available-watchers"></a>
## 利用可能なワッチャー

Telescopeのワッチャーは、リクエストやコマンドが実行されると、アプリケーションデータを収集します。`config/telescope.php`設定ファイルで、ワッチャーのリストを有効にすることにより、カスタマイズできます。

    'watchers' => [
        Watchers\CacheWatcher::class => true,
        Watchers\CommandWatcher::class => true,
        ...
    ],

いくつかのワッチャーには、追加のカスタマイズオプションが用意されています。

    'watchers' => [
        Watchers\QueryWatcher::class => [
            'enabled' => env('TELESCOPE_QUERY_WATCHER', true),
            'slow' => 100,
        ],
        ...
    ],

<a name="batch-watcher"></a>
### Batchワッチャー

batchワッチャーは、ジョブや接続の情報を含む、キュー投入されたバッチの情報を記録します。

<a name="cache-watcher"></a>
### Cacheワッチャー

Cacheワッチャーは、キャッシュキーのヒット、不一致、削除時にデータを記録します。

<a name="command-watcher"></a>
### Commandワッチャー

Commandワッチャーは、Artisanコマンドが実行されたときの引数、オプション、終了コード、出力コードを記録します。このワッチャーの対象から特定のコマンドを外したい場合は、`config/telescope.php`ファイルの`ignore`オプションの中で、除外するコマンドを指定してください。

    'watchers' => [
        Watchers\CommandWatcher::class => [
            'enabled' => env('TELESCOPE_COMMAND_WATCHER', true),
            'ignore' => ['key:generate'],
        ],
        ...
    ],

<a name="dump-watcher"></a>
### Dumpワッチャー

Dumpワッチャーは、Telescope中の変数のダンプを記録し、表示します。Laravelを使ってるなら、グローバル`dump`関数を使用し変数をダンプできます。記録される時点でDumpワッチャータブは、ブラウザで開かれていなければなりません。開かれてなければ、ワッチャーはダンプを無視します。

<a name="event-watcher"></a>
### Eventワッチャー

Eventワッチャーは、アプリケーションで発行されたすべてのイベントのペイロード（本体）、リスナ、ブロードキャストデータを記録します。Eventワッチャーは、Laravelフレームワーク内部のイベントを無視します。

<a name="exception-watcher"></a>
### Exceptionワッチャー

Exceptionワッチャーはアプリケーションで投げられた、reportableな全例外のデータとスタックトレースを記録します。

<a name="gate-watcher"></a>
### Gateワッチャー

Gateワッチャーは、アプリケーションのゲートとポリシーチェックによる、データと結果を記録します。特定のアビリティをこのワッチャーで記録されないようにしたい場合は、`config/telescope.php`ファイルの`ignore_abilities`オプションで指定してください。

    'watchers' => [
        Watchers\GateWatcher::class => [
            'enabled' => env('TELESCOPE_GATE_WATCHER', true),
            'ignore_abilities' => ['viewNova'],
        ],
        ...
    ],

<a name="job-watcher"></a>
### Jobワッチャー

Jobワッチャーは、アプリケーションでディスパッチされた全ジョブのデータと状態を記録します。

<a name="log-watcher"></a>
### Logワッチャー

Logワッチャーは、アプリケーションにより書き出されたすべてのログデータを記録します。

<a name="mail-watcher"></a>
### Mailワッチャー

Mailワッチャーにより、メールのプレビューに加え、関連するデータをブラウザで確認できます。さらに、`.eml`ファイルとしてメールをダウンロードできます。

<a name="model-watcher"></a>
### Modelワッチャー

Modelワッチャーは、Eloquentの`created`、`updated`、`restored`、`deleted`イベントがディスパッチされた時点のモデルの変更を記録します。このワッチャーの`events`オプションにより、どのモデルイベントを記録するかを指定できます。

    'watchers' => [
        Watchers\ModelWatcher::class => [
            'enabled' => env('TELESCOPE_MODEL_WATCHER', true),
            'events' => ['eloquent.created*', 'eloquent.updated*'],
        ],
        ...
    ],

<a name="notification-watcher"></a>
### Notificationワッチャー

Notificationワッチャーは、アプリケーションにより送信された全通知を記録します。通知がメールを送信し、Mailワッチャーが有効になっていれば、Mailワッチャー画面によりプレビューも利用できます。

<a name="query-watcher"></a>
### Queryワッチャー

Queryワッチャーは、アプリケーションにより実行された全クエリのSQL文とバインド、実行時間を記録します。このワッチャーは、100msよりも遅いクエリを`slow`としてタグ付けします。ワッチャーの`slow`オプションにより、このスロークエリの判定時間をカスタマイズできます。

    'watchers' => [
        Watchers\QueryWatcher::class => [
            'enabled' => env('TELESCOPE_QUERY_WATCHER', true),
            'slow' => 50,
        ],
        ...
    ],

<a name="redis-watcher"></a>
### Redisワッチャー

Redisワッチャーはアプリケーションで実行された全Redisコマンドを記録します。Redisをキャッシュで利用する場合、キャッシュコマンドもRedisワッチャーにより記録されます。

<a name="request-watcher"></a>
### Requestワッチャー

Requestワッチャーはアプリケーションにより処理された全リクエスト、ヘッダ、セッション、レスポンスデータを記録します。`size_limit`オプションによりKB単位でレスポンデータを制限できます。

    'watchers' => [
        Watchers\RequestWatcher::class => [
            'enabled' => env('TELESCOPE_REQUEST_WATCHER', true),
            'size_limit' => env('TELESCOPE_RESPONSE_SIZE_LIMIT', 64),
        ],
        ...
    ],

<a name="schedule-watcher"></a>
### Scheduleワッチャー

Scheduleワッチャーは、アプリケーションで実行された全スケジュール済みタスクのコマンドと出力を記録します。

<a name="view-watcher"></a>
### Viewワッチャー

Viewワッチャーはビュー名、パス、データ、ビューをレンダリングしたときの「コンポーサ」を記録します。

<a name="displaying-user-avatars"></a>
## ユーザーアバターの表示

Telescopeダッシュボードは与えられたエントリーが保存されている時、ログインしているユーザーのアバターを表示します。TelescopeはデフォルトでGravatar Webサービスを使用してアバターを取得します。しかし、`TelescopeSeerviceProvider`でコールバックを登録すれば、アバターのURLをカスタマイズできます。コールバックにはユーザーのIDとメールアドレスが渡されますので、ユーザーのアバターイメージのURLを返す必用があります。

    use App\Models\User;
    use Laravel\Telescope\Telescope;

    /**
     * 全アプリケーションサービスの登録
     *
     * @return void
     */
    public function register()
    {
        Telescope::avatar(function ($id, $email) {
            return '/avatars/'.User::find($id)->avatar_path;
        });
    }
