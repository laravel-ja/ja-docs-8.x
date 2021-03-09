# Laravel Telescope

- [イントロダクション](#introduction)
- [インストレーション](#installation)
    - [ローカルのみへインストール](#local-only-installation)
    - [設定](#configuration)
    - [データの刈り込み](#data-pruning)
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

Telescope（テレスコープ：望遠鏡）は、ローカルLaravel開発環境の素晴らしい道連れになります。Telescopeは、アプリケーションが受信するリクエスト、例外、ログエントリ、データベースクエリ、キュー投入したジョブ、メール、通知、キャッシュ操作、スケジュール済みタスク、変数ダンプなどに関する眼力を与えてくれます。

<img src="/img/telescope.png" width="100%">

<a name="installation"></a>
## インストレーション

Composerパッケージマネージャーで、TelescopeをLaravelプロジェクトへインストールできます。

    composer require laravel/telescope

Telescopeをインストールしたら、`telescope:install`　Artisanコマンドを使用してアセットをリソース公開します。Telescopeをインストールした後は、Telescopeのデータを格納するために必要なテーブルを作成するために、`migrate`コマンドも実行する必要があります。

    php artisan telescope:install

    php artisan migrate

<a name="migration-customization"></a>
#### マイグレーションのカスタマイズ

Telescopeのデフォルトのマイグレーションを使用しない場合は、アプリケーションの`App\Providers\AppServiceProvider`クラスの`register`メソッドで`Telescope::ignoreMigrations`メソッドを呼び出す必要があります。`php artisan vendor:publish --tag=telescope-migrations`のコマンドで、デフォルトのマイグレーションをエクスポートできます。

<a name="local-only-installation"></a>
### ローカルのみへインストール

ローカル開発を支援するためにのみTelescopeの使用を計画している場合は、`--dev`フラグを使用してTelescopeをインストールしてください。

    composer require laravel/telescope --dev

    php artisan telescope:install

    php artisan migrate

`telescope:install`を実行した後に、アプリケーションの`config/app.php`設定ファイルから`TelescopeServiceProvider`サービスプロバイダの登録を削除する必要があります。代わりに、Telescopeのサービスプロバイダを`App\Providers\AppServiceProvider`クラスの`register`メソッドへ手動で登録します。プロバイダを登録する前に、現在の環境が`local`であることを確認してください。

    /**
     * 全アプリケーションサービスの登録
     *
     * @return void
     */
    public function register()
    {
        if ($this->app->environment('local')) {
            $this->app->register(\Laravel\Telescope\TelescopeServiceProvider::class);
            $this->app->register(TelescopeServiceProvider::class);
        }
    }

最後に、`composer.json`ファイルに以下を追加して、Telescopeパッケージが[自動検出](/docs/{{version}}/packages#package-discovery)されないようにする必要もあります。

    "extra": {
        "laravel": {
            "dont-discover": [
                "laravel/telescope"
            ]
        }
    },

<a name="configuration"></a>
### 設定

Telescopeのアセットをリソース公開すると、そのプライマリ設定ファイルは`config/telescope.php`へ配置されます。この設定ファイルを使用すると、[ワッチャーオプション](#available-watchers)を設定できます。各設定オプションにはその目的が説明されているため、このファイルを徹底的に調べてください。

望むのであれば、`enabled`設定オプションを使用し、Telescopeのデータ収集全体を無効にできます。

    'enabled' => env('TELESCOPE_ENABLED', true),

<a name="data-pruning"></a>
### データの刈り込み

データの刈り込みを行わないと、`telescope_entries`テーブルにレコードがあっという間に溜まります。これを軽減するに、`telescope:prune` Artisanコマンドを[スケジュール](/docs/{{version}}/scheduleing)して毎日実行する必要があります。

    $schedule->command('telescope:prune')->daily();

デフォルトでは、２４時間を過ぎているすべてのエンティティが削除されます。Telescopeデータをどの期間保持するかを指定するために、コマンド呼び出し時に`hours`オプションが使えます。

    $schedule->command('telescope:prune --hours=48')->daily();

<a name="dashboard-authorization"></a>
### ダッシュボードの認可

Telescopeダッシュボードには、`/telescope`ルートでアクセスできます。デフォルトでは、このダッシュボードにアクセスできるのは`local`環境のみです。`app/Providers/TelescopeServiceProvider.php`ファイル内に、[承認ゲート](/docs/{{version}}/authentication#gates)の定義があります。この認証ゲートは、**非ローカル**環境でのTelescopeへのアクセスを制御します。Telescopeの設置へのアクセスを制限するために、必要に応じてこのゲートを自由に変更できます。

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

Telescopeが記録したデータは、`App\Providers\TelescopeServiceProvider`クラスで定義されている`filter`クロージャを介してフィルタリングできます。デフォルトでは、このクロージャは、`local`環境のすべてのデータと、例外、失敗したジョブ、スケジュール済みタスク、および他のすべての環境の監視対象のデータをタグ付きで記録します。

    use Laravel\Telescope\IncomingEntry;
    use Laravel\Telescope\Telescope;

    /**
     * 全アプリケーションサービスの登録
     *
     * @return void
     */
    public function register()
    {
        $this->hideSensitiveRequestDetails();

        Telescope::filter(function (IncomingEntry $entry) {
            if ($this->app->environment('local')) {
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

`filter`クロージャは個々のエントリのデータをフィルタリングしますが、`filterBatch`メソッドを使用して、特定のリクエストまたはコンソールコマンドのすべてのデータをフィルタリングするクロージャを登録できます。クロージャが`true`を返す場合、すべてのエントリはTelescopeによって記録されます。

    use Illuminate\Support\Collection;
    use Laravel\Telescope\Telescope;

    /**
     * 全アプリケーションサービスの登録
     *
     * @return void
     */
    public function register()
    {
        $this->hideSensitiveRequestDetails();

        Telescope::filterBatch(function (Collection $entries) {
            if ($this->app->environment('local')) {
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

Telescopeでは、「タグ」でエントリを検索できます。多くの場合、タグは、Telescopeがエントリに自動的に追加するEloquentモデルクラス名または認証済みユーザーIDです。場合によっては、独自のカスタムタグをエントリに添付することもできます。これを実現するために、`Telescope::tag`メソッドが使用できます。`tag`メソッドはクロージャを引数に取り、タグの配列を返す必要があります。クロージャが返すタグは、Telescopeがエントリに自動的に添付するタグとマージされます。通常、`App\Providers\TelescopeServiceProvider`クラスの`register`メソッド内で`tag`メソッドを呼び出す必要があります。

    use Laravel\Telescope\IncomingEntry;
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
            return $entry->type === 'request'
                        ? ['status:'.$entry->content['response_status']]
                        : [];
        });
     }

<a name="available-watchers"></a>
## 利用可能なワッチャー

Telescopeの「ワッチャー」は、リクエストまたはコンソールコマンドが実行されると、アプリケーションデータを収集します。`config/telescope.php`設定ファイル内で有効にしたいワッチャーのリストをカスタマイズできます。

    'watchers' => [
        Watchers\CacheWatcher::class => true,
        Watchers\CommandWatcher::class => true,
        ...
    ],

いくつかのワッチャーには、追加のカスタマイズオプションを用意しています。

    'watchers' => [
        Watchers\QueryWatcher::class => [
            'enabled' => env('TELESCOPE_QUERY_WATCHER', true),
            'slow' => 100,
        ],
        ...
    ],

<a name="batch-watcher"></a>
### Batchワッチャー

Batchワッチャーは、ジョブや接続情報など、キュー投入した[バッチ](/docs/{{version}}/queues#job-batching)に関する情報を記録します。

<a name="cache-watcher"></a>
### Cacheワッチャー

Cacheワッチャーは、キャッシュキーのヒット、不一致、削除時にデータを記録します。

<a name="command-watcher"></a>
### Commandワッチャー

Commandワッチャーは、Artisanコマンドが実行されるたびに、引数、オプション、終了コード、および出力を記録します。ワッチャーによる記録から特定のコマンドを除外したい場合は、`config/telescope.php`ファイル内の`ignore`オプションでコマンドを指定できます。

    'watchers' => [
        Watchers\CommandWatcher::class => [
            'enabled' => env('TELESCOPE_COMMAND_WATCHER', true),
            'ignore' => ['key:generate'],
        ],
        ...
    ],

<a name="dump-watcher"></a>
### Dumpワッチャー

Dumpワッチャーは、変数ダンプをTelescopeに記録して表示します。Laravelを使用すると、変数をグローバルな`dump`関数を使用してダンプできます。ダンプを記録するには、ブラウザで[Dumpワッチャー]タブを開いている必要があります。開いていない場合、ワッチャーはダンプを無視します。

<a name="event-watcher"></a>
### Eventワッチャー

Eventワッチャーは、アプリケーションがディスパッチした[イベント](/docs/{{version}}/events)のペイロード、リスナ、およびブロードキャストデータを記録します。Laravelフレームワークの内部イベントをEventワッチャーは無視します。

<a name="exception-watcher"></a>
### Exceptionワッチャー

Exceptionワッチャーは、アプリケーション投げた報告可能（reportable）な例外のデータとスタックトレースを記録します。

<a name="gate-watcher"></a>
### Gateワッチャー

Gateワッチャーは、アプリケーションによる[ゲートとポリシー](/docs/{{version}}/authentication)チェックのデータと結果を記録します。ワッチャーによる記録から特定のアビリティを除外したい場合は、`config/telescope.php`ファイルの`ignore_abilities`オプションで指定できます。

    'watchers' => [
        Watchers\GateWatcher::class => [
            'enabled' => env('TELESCOPE_GATE_WATCHER', true),
            'ignore_abilities' => ['viewNova'],
        ],
        ...
    ],

<a name="job-watcher"></a>
### Jobワッチャー

Jobワッチャーは、アプリケーションがディスパッチした[ジョブ](/docs/{{version}}/queues)のデータとステータスを記録します。

<a name="log-watcher"></a>
### Logワッチャー

Logワッチャーは、アプリケーションが書き混んだ[ログデータ](/docs/{{version}}/logging)を記録します。

<a name="mail-watcher"></a>
### Mailワッチャー

Mailワッチャーを使用すると、アプリケーションから送信した[メール](/docs/{{version}}/mail)のブラウザ内プレビューと関連するデータを表示できます。メールを `.eml`ファイルとしてダウンロードすることもできます。

<a name="model-watcher"></a>
### Modelワッチャー

Modelワッチャーは、Eloquent[モデルイベント](/docs/{{version}}/eloquent#events)がディスパッチされるたびにモデルの変更を記録します。ワッチャーの`events`オプションを使用して、記録するモデルイベントを指定できます。

    'watchers' => [
        Watchers\ModelWatcher::class => [
            'enabled' => env('TELESCOPE_MODEL_WATCHER', true),
            'events' => ['eloquent.created*', 'eloquent.updated*'],
        ],
        ...
    ],

特定のリクエスト中にハイドレートされたモデルの数を記録する場合は、`hydrations`オプションを有効にします。

    'watchers' => [
        Watchers\ModelWatcher::class => [
            'enabled' => env('TELESCOPE_MODEL_WATCHER', true),
            'events' => ['eloquent.created*', 'eloquent.updated*'],
            'hydrations' => true,
        ],
        ...
    ],

<a name="notification-watcher"></a>
### Notificationワッチャー

Notificationワッチャーは、アプリケーションから送信されたすべての[通知](/docs/{{version}}/notifications)を記録します。通知によって電子メールがトリガーされ、メールワッチャーが有効になっている場合、その電子メールはワッチャー画面でプレビューすることもできます。

<a name="query-watcher"></a>
### Queryワッチャー

Queryワッチャーは、アプリケーションが実行するすべてのクエリの素のSQL、バインディング、および実行時間を記録します。ワッチャーは、100ミリ秒より遅いクエリへ`slow`というタグを付けます。ウォッチャーの`slow`オプションを使用して、低速クエリのしきい値をカスタマイズできます。

    'watchers' => [
        Watchers\QueryWatcher::class => [
            'enabled' => env('TELESCOPE_QUERY_WATCHER', true),
            'slow' => 50,
        ],
        ...
    ],

<a name="redis-watcher"></a>
### Redisワッチャー

Redisワッチャーは、アプリケーションが実行したすべての[Redis](/docs/{{version}}/redis)コマンドを記録します。キャッシュにRedisを使用している場合、キャッシュコマンドもRedisワッチャーは記録します。

<a name="request-watcher"></a>
### Requestワッチャー

Requestワッチャーは、アプリケーションが処理してリクエストに関連したリクエスト、ヘッダ、セッション、およびレスポンスデータを記録します。`size_limit`(キロバイト単位)オプションを使用して、記録するレスポンスデータを制限できます。

    'watchers' => [
        Watchers\RequestWatcher::class => [
            'enabled' => env('TELESCOPE_REQUEST_WATCHER', true),
            'size_limit' => env('TELESCOPE_RESPONSE_SIZE_LIMIT', 64),
        ],
        ...
    ],

<a name="schedule-watcher"></a>
### Scheduleワッチャー

Scheduleワッチャーは、アプリケーションが実行した[スケジュール済みタスク](/docs/{{version}}/Scheduling)のコマンドと出力を記録します。

<a name="view-watcher"></a>
### Viewワッチャー

Viewワッチャーは、ビューのレンダリング時に使用する[ビュー](/docs/{{version}}/views)の名前、パス、データ、および「コンポーザ」を記録します。

<a name="displaying-user-avatars"></a>
## ユーザーアバターの表示

Telescopeダッシュボードでは、特定のエントリが保存されたときに認証されていたユーザーのユーザーアバターが表示されます。デフォルトでTelescopeはGravatarWebサービスを使用してアバターを取得します。ただし、`App\Providers\TelescopeServiceProvider`クラスにコールバックを登録することで、アバターのURLをカスタマイズもできます。コールバックはユーザーのIDとメールアドレスを受け取り、ユーザーのアバター画像のURLを返す必要があります。

    use App\Models\User;
    use Laravel\Telescope\Telescope;

    /**
     * 全アプリケーションサービスの登録
     *
     * @return void
     */
    public function register()
    {
        // ...

        Telescope::avatar(function ($id, $email) {
            return '/avatars/'.User::find($id)->avatar_path;
        });
    }
