# Laravel Horizon

- [イントロダクション](#introduction)
- [インストール](#installation)
    - [設定](#configuration)
    - [バランス戦略](#balancing-strategies)
    - [ダッシュボードの認可](#dashboard-authorization)
- [Horizonのアップグレード](#upgrading-horizon)
- [Horizonの実行](#running-horizon)
    - [Horizonのデプロイ](#deploying-horizon)
- [タグ](#tags)
- [通知](#notifications)
- [メトリクス](#metrics)
- [失敗したジョブの削除](#deleting-failed-jobs)
- [キューのジョブをクリア](#clearing-jobs-from-queues)

<a name="introduction"></a>
## イントロダクション

> {tip} Laravel Horizo​​nを掘り下げる前に、Laravelの基本的な[キューサービス](/docs/{{version}}/queues)をよく理解しておく必要があります。Horizo​​nは、Laravelが提供する基本的なキュー機能にまだ慣れていない場合は混乱してしまう可能性がある追加機能であり、Laravelのキューを拡張します。

Laravel Horizo​​nは、Laravelを利用した[Redisキュー](/docs/{{version}}/queues)に美しいダッシュボードとコード駆動型の設定を提供します。Horizo​​nを使用すると、ジョブのスループット、ランタイム、ジョブの失敗など、キューシステムの主要なメトリックを簡単に監視できます。

Horizo​​nを使用する場合、すべてのキューワーカ設定は単一の単純な設定ファイルへ保存します。バージョン管理されたファイルでアプリケーションのワーカ設定を定義することにより、アプリケーションのデプロイ時に、キューワーカを簡単にスケーリングや変更できます。

<img src="https://laravel.com/img/docs/horizon-example.png">

<a name="installation"></a>
## インストール

> {note} Laravel Horizo​​nは、[Redis](https://redis.io)を使用してキューを使用する必要があります。したがって、アプリケーションの`config/queue.php`設定ファイルでキュー接続が`redis`に設定されていることを確認する必要があります。

Composerパッケージマネージャーを使用して、Horizo​​nをプロジェクトにインストールします。

    composer require laravel/horizon

Horizo​​nをインストールした後、`horizo​​n:install` Artisanコマンドを使用してアセット公開します。

    php artisan horizon:install

<a name="configuration"></a>
### 設定

Horizo​​nのアセットを公開すると、そのプライマリ設定ファイルは`config/horizo​​n.php`へ設置されます。この設定ファイルでアプリケーションのキューワーカオプションを設定できます。各設定オプションにはその目的の説明が含まれているため、このファイルを徹底的に調べてください。

<a name="environments"></a>
#### 環境

インストール後に、よく理解する必要のある主要なHorizo​​n設定オプションは、`environments`設定オプションです。この設定オプションは、アプリケーションを実行する環境の配列であり、各環境のワーカプロセスオプションを定義します。デフォルトのこのエントリは`production`環境と`local`環境です。ただし、環境は必要に応じ自由に追加できます。

    'environments' => [
        'production' => [
            'supervisor-1' => [
                'maxProcesses' => 10,
                'balanceMaxShift' => 1,
                'balanceCooldown' => 3,
            ],
        ],

        'local' => [
            'supervisor-1' => [
                'maxProcesses' => 3,
            ],
        ],
    ],

Horizo​​nを起動すると、アプリケーションを実行する環境のワーカープロセス設定オプションが使用されます。通常、環境は`APP_ENV`[環境変数](/docs/{{version}}/configuration#determining-the-current-environment)の値によって決定されます。たとえば、デフォルトの`local` Horizo​​n環境は、３つのワーカープロセスを開始し、各キューに割り当てられたワーカプロセスの数のバランスを自動的にとるように設定されています。デフォルトの`production`環境は、最大１０個のワーカプロセスを開始し、各キューに割り当てられたワーカプロセスの数のバランスを自動的にとるように設定されています。

> {note} `horizo​​n`設定ファイルの`environments`部分に、Horizonを実行する予定の各[環境](/docs/{{version}}/configuration#environment-configuration)のエントリを確実に指定してください。

<a name="supervisors"></a>
#### スーパーバイザ

Horizo​​nのデフォルトの設定ファイルでわかるように。各環境には、１つ以上の「スーパーバイザ（supervisor）」を含めることができます。デフォルトでは、設定ファイルはこのスーパーバイザを`supervisor-1`として定義します。ただし、スーパーバイザには自由に名前を付けることができます。各スーパーバイザは、基本的にワーカプロセスのグループを「監視」する責任があり、キュー間でワーカプロセスのバランスを取ります。

特定の環境で実行する必要があるワーカプロセスの新しいグループを定義する場合は、指定環境にスーパーバイザを追加します。アプリケーションが使用する特定のキューへ他のバランス戦略やワーカープロセス数を指定することもできます。

<a name="default-values"></a>
#### デフォルト値

Horizo​​nのデフォルト設定ファイル内に、`defaults`設定オプションがあります。この設定オプションにアプリケーションの[スーパーバイザ](#supervisors)のデフォルト値を指定します。スーパーバイザのデフォルト設定値は、各環境のスーパーバイザの設定にマージされるため、スーパーバイザを定義するときに不必要な繰り返しを回避できます。

<a name="balancing-strategies"></a>
### バランス戦略

Laravelのデフォルトのキューシステムとは異なり、Horizo​​nでは３つのワーカーバランス戦略(`simple`、`auto`、`false`)から選択できます。設定ファイルのデフォルトである`simple`戦略は、受信ジョブをワーカープロセス間で均等に分割します。

    'balance' => 'simple',

`auto`戦略は、キューの現在のワークロードに基づいて、キューごとのワーカープロセスの数を調整します。たとえば、`render`キューが空のときに`notifications`キューに1,000の保留中のジョブがある場合、Horizo​​nはキューが空になるまで`notifications`キューにさらに多くのワーカを割り当てます。

`auto`戦略を使用する場合、`minProcesses`および`maxProcesses`設定オプションを定義して、Horizo​​nがスケールアップおよびスケールダウンするワーカープロセスの最小数と最大数を制御します。

    'environments' => [
        'production' => [
            'supervisor-1' => [
                'connection' => 'redis',
                'queue' => ['default'],
                'balance' => 'auto',
                'minProcesses' => 1,
                'maxProcesses' => 10,
                'balanceMaxShift' => 1,
                'balanceCooldown' => 3,
                'tries' => 3,
            ],
        ],
    ],

`balanceMaxShift`と`balanceCooldown`の設定値は、Horizo​​nがワーカの需要を満たすためにどれだけ迅速にスケーリングするかを決定します。上記の例では、３秒ごとに最大１つの新しいプロセスが作成または破棄されます。アプリケーションのニーズに基づいて、必要に応じてこれらの値を自由に調整できます。

`balance`オプションを`false`へ設定している場合、デフォルトのLaravel動作が使用され、設定にリストされている順序でキューを処理します。

<a name="dashboard-authorization"></a>
### ダッシュボードの認可

Horizo​​nは、`/horizo​​n`のURIでダッシュボードを公開します。デフォルトでは、このダッシュボードにアクセスできるのは`local`環境のみです。ただし、`app/Providers/Horizo​​nServiceProvider.php`ファイル内には、[認可ゲート](/docs/{{version}}/authentication#gates)の定義があります。この認証ゲートは、**非ローカル**環境でのHorizo​​nへのアクセスを制御します。必要に応じてこのゲートを自由に変更して、Horizo​​nインストールへのアクセスを制限できます。

    /**
     * Horizonゲートの登録
     *
     * このゲートは、非ローカル環境で誰がHorizo​​nにアクセスできるかを決定します。
     *
     * @return void
     */
    protected function gate()
    {
        Gate::define('viewHorizon', function ($user) {
            return in_array($user->email, [
                'taylor@laravel.com',
            ]);
        });
    }

<a name="alternative-authentication-strategies"></a>
#### その他の認証戦略

Laravelは認証済みユーザーをゲートクロージャへ自動的に依存挿入することを忘れないでください。アプリケーションがIP制限などの別の方法でHorizo​​nセキュリティを提供する場合、Horizo​​nユーザーは「ログイン」する必要がない場合もあります。したがって、Laravelの認証を必要としないようにするには、上記の`function($user)`クロージャ引数を`function($user=null)`に変更する必要があります。

<a name="upgrading-horizon"></a>
## Horizonのアップグレード

Horizo​​nの新しいメジャーバージョンにアップグレードするときは、[アップグレードガイド](https://github.com/laravel/horizo​​n/blob/master/UPGRADE.md)を注意深く確認することが重要です。さらに、新しいHorizo​​nバージョンにアップグレードするときは、Horizo​​nのアセットを再公開する必要があります。

    php artisan horizon:publish

アセットを最新の状態に保ち、将来の更新で問題が発生しないようにするには、アプリケーションの`composer.json`ファイルの`post-update-cmd`スクリプトに`horizo​​n:publish`コマンドを追加します。

    {
        "scripts": {
            "post-update-cmd": [
                "@php artisan horizon:publish --ansi"
            ]
        }
    }

<a name="running-horizon"></a>
## Horizonの実行

アプリケーションの`config/horizo​​n.php`設定ファイルでスーパーバイザとワーカを設定したら、`horizo​​n` Artisanコマンドを使用してHorizo​​nを起動できます。この単一のコマンドは、現在の環境用に設定されたすべてのワーカプロセスを開始します。

    php artisan horizon

`horizo​​n:pause`と`horizo​​n:continue` Artisanコマンドで、Horizo​​nプロセスを一時停止したり、ジョブの処理を続行するように指示したりできます。

    php artisan horizon:pause

    php artisan horizon:continue

`horizo​​n:pause-supervisor`と`horizo​​n:continue-supervisor` Artisanコマンドを使用して、特定のHorizo​​n[スーパーバイザ](#supervisors)を一時停止／続行することもできます。

    php artisan horizon:pause-supervisor supervisor-1

    php artisan horizon:continue-supervisor supervisor-1

`horizo​​n:status` Artisanコマンドを使用して、Horizo​​nプロセスの現在のステータスを確認できます。

    php artisan horizon:status

`horizo​​n:terminate` Artisanコマンドを使用して、Horizo​​nプロセスを正常に終了できます。現在処理されているジョブがすべて完了してから、Horizo​​nは実行を停止します。

    php artisan horizon:terminate

<a name="deploying-horizon"></a>
### Horizonのデプロイ

Horizo​​nをアプリケーションの実際のサーバにデプロイする準備ができたら、`php artisan horizo​​n`コマンドを監視するようにプロセスモニタを設定し、予期せず終了した場合は再起動する必要があります。心配ありません。以下からプロセスモニタのインストール方法について説明します。

アプリケーションのデプロイメントプロセス中で、Horizo​​nプロセスへ終了するように指示し、プロセスモニターによって再起動され、コードの変更を反映するようにする必要があります。

    php artisan horizon:terminate

<a name="installing-supervisor"></a>
#### Supervisorのインストール

SupervisorはLinuxオペレーティングシステムのプロセスモニタであり、実行が停止すると`horizon`プロセスを自動的に再起動してくれます。UbuntuにSupervisorをインストールするには、次のコマンドを使用できます。Ubuntuを使用していない場合は、オペレーティングシステムのパッケージマネージャーを使用してSupervisorをインストールしてください。

    sudo apt-get install supervisor

> {tip} 自分でSupervisorを設定するのが難しいと思われる場合は、[Laravel Forge](https://forge.laravel.com)の使用を検討してください。これにより、LaravelプロジェクトのSupervisorは自動的にインストールおよび設定されます。

<a name="supervisor-configuration"></a>
#### Supervisor設定

Supervisor設定ファイルは通常、サーバの`/etc/supervisor/conf.d`ディレクトリ内に保管されます。このディレクトリ内に、プロセスの監視方法をスSupervisorに指示する設定ファイルをいくつでも作成できます。たとえば、`horizo​​n`プロセスを開始および監視する`horizo​​n.conf`ファイルを作成しましょう。

    [program:horizon]
    process_name=%(program_name)s
    command=php /home/forge/example.com/artisan horizon
    autostart=true
    autorestart=true
    user=forge
    redirect_stderr=true
    stdout_logfile=/home/forge/example.com/horizon.log
    stopwaitsecs=3600

> {note} `stopwaitsecs`の値が、最も長く実行されているジョブにより消費される秒数よりも大きいことを確認する必要があります。そうしないと、Supervisorは、処理が完了する前にジョブを強制終了する可能性があります。

<a name="starting-supervisor"></a>
#### Supervisorの開始

設定ファイルを作成したら、以下のコマンドを使用して、Supervisor設定を更新し、監視対象プロセスを開始できます。

    sudo supervisorctl reread

    sudo supervisorctl update

    sudo supervisorctl start horizon

> {tip} Supervisorの実行の詳細は、[Supervisorのドキュメント](http://supervisord.org/index.html)を参照してください。

<a name="tags"></a>
## タグ

Horizo​​nを使用すると、メール可能、ブロードキャストイベント、通知、キュー投入するイベントリスナなどのジョブに「タグ」を割り当てることができます。実際、Horizo​​nは、ジョブに関連付けられているEloquentモデルに応じて、ほとんどのジョブにインテリジェントかつ自動的にタグを付けます。たとえば、以下のジョブを見てみましょう。

    <?php

    namespace App\Jobs;

    use App\Models\Video;
    use Illuminate\Bus\Queueable;
    use Illuminate\Contracts\Queue\ShouldQueue;
    use Illuminate\Foundation\Bus\Dispatchable;
    use Illuminate\Queue\InteractsWithQueue;
    use Illuminate\Queue\SerializesModels;

    class RenderVideo implements ShouldQueue
    {
        use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

        /**
         * Videoインスタンス
         *
         * @var \App\Models\Video
         */
        public $video;

        /**
         * 新しいジョブインスタンスの生成
         *
         * @param  \App\Models\Video  $video
         * @return void
         */
        public function __construct(Video $video)
        {
            $this->video = $video;
        }

        /**
         * ジョブの実行
         *
         * @return void
         */
        public function handle()
        {
            //
        }
    }

このジョブが`id`属性は`1`の`App\Models\Video`インスタンスでキューに投入されると、タグ`App\Models\Video:1`が自動的に付けられます。これは、Horizo​​nがジョブのプロパティでEloquentモデルを検索するためです。Eloquentモデルが見つかった場合、Horizo​​nはモデルのクラス名と主キーを使用してジョブにインテリジェントにタグを付けます。

    use App\Jobs\RenderVideo;
    use App\Models\Video;

    $video = Video::find(1);

    RenderVideo::dispatch($video);

<a name="manually-tagging-jobs"></a>
#### ジョブに手動でタグ付ける

Queueableオブジェクトの１つにタグを手動で定義する場合は、クラスに`tags`メソッドを定義します。

    class RenderVideo implements ShouldQueue
    {
        /**
         * ジョブに割り当てるタグを取得
         *
         * @return array
         */
        public function tags()
        {
            return ['render', 'video:'.$this->video->id];
        }
    }

<a name="notifications"></a>
## 通知

> {note} SlackまたはSMS通知を送信するようにHorizo​​nを設定する場合は、[関連する通知チャネルの前提条件](/docs/{{version}}/notifys)を確認する必要があります。

キューの１つに長い待機時間があったときに通知を受け取りたい場合は、`Horizo​​n::routeMailNotificationsTo`、`Horizo​​n::routeSlackNotificationsTo`、および`Horizo​​n::routeSmsNotificationsTo`メソッドが使用できます。これらのメソッドは、アプリケーションの`App\Providers\Horizo​​nServiceProvider`の`boot`メソッドから呼び出せます。

    /**
     * 全アプリケーションサービスの初期起動処理
     *
     * @return void
     */
    public function boot()
    {
        parent::boot();

        Horizon::routeSmsNotificationsTo('15556667777');
        Horizon::routeMailNotificationsTo('example@example.com');
        Horizon::routeSlackNotificationsTo('slack-webhook-url', '#channel');
    }

<a name="configuring-notification-wait-time-thresholds"></a>
#### 待機通知の時間のしきい値の設定

アプリケーションの`config/horizo​​n.php`設定ファイル内で「長時間待機」と見なす秒数を設定できます。このファイル内の`waits`設定オプションを使用すると、各接続/キューの組み合わせの長時間待機しきい値を制御できます。

    'waits' => [
        'redis:default' => 60,
        'redis:critical,high' => 90,
    ],

<a name="metrics"></a>
## メトリクス

Horizo​​nには、ジョブとキューの待機時間とスループットに関する情報を提供するメトリックダッシュボードが含まれています。このダッシュボードにデータを表示するには、アプリケーションの[スケジューラ](/docs/{{version}}/scheduleing)で５分ごとにHorizo​​nの`snapshot` Artisanコマンドを実行するように設定する必要があります。

    /**
     * アプリケーションのコマンドスケジュールの定義
     *
     * @param  \Illuminate\Console\Scheduling\Schedule  $schedule
     * @return void
     */
    protected function schedule(Schedule $schedule)
    {
        $schedule->command('horizon:snapshot')->everyFiveMinutes();
    }

<a name="deleting-failed-jobs"></a>
## 失敗したジョブの削除

失敗したジョブを削除したい場合は、`horizo​​n:forget`コマンドを使用します。`horizo​​n:forget`コマンドは、失敗したジョブのIDを唯一の引数に取ります。

    php artisan horizon:forget 5

<a name="clearing-jobs-from-queues"></a>
## キューのジョブをクリア

アプリケーションのデフォルトキューからすべてのジョブを削除する場合は、`horizo​​n:clear` Artisanコマンドを使用して削除します。

    php artisan horizon:clear

特定のキューからジョブを削除するために`queue`オプションが指定できます。

    php artisan horizon:clear --queue=emails
