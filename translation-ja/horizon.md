# Laravel Horizon

- [イントロダクション](#introduction)
- [インストール](#installation)
    - [設定](#configuration)
    - [ダッシュボードの認可](#dashboard-authorization)
- [Horizonのアップグレード](#upgrading-horizon)
- [Horizonの実行](#running-horizon)
    - [Horizonのデプロイ](#deploying-horizon)
- [タグ](#tags)
- [通知](#notifications)
- [メトリックス](#metrics)
- [失敗したジョブの削除](#deleting-failed-jobs)
- [キューのジョブのクリア](#clearing-jobs-from-queues)

<a name="introduction"></a>
## イントロダクション

Horizon（水平線、展望）は、Laravelで動作するRedisキューのための、美しいダッシュボードとコード駆動による設定を提供します。Horizonにより、ジョブのスループット、ランタイム、実行の失敗など、キューシステムのキーメトリックを簡単に監視できます。

一つのシンプルな設定ファイルにすべてのワーカ設定を保存するため、チーム全体がコラボレート可能なソースコントロール下に、設定を保持できます。

<img src="https://laravel.com/img/docs/horizon-example.png">

<a name="installation"></a>
## インストール

> {note} `queue`設定ファイルで、`redis`をキューコネクションへ確実に指定してください。

Composerを使い、LaravelプロジェクトにHorizonをインストールします。

    composer require laravel/horizon

Horizonをインストールしたら、`horizon:install` Artisanコマンドを使用し、アセットを公開します。

    php artisan horizon:install

<a name="configuration"></a>
### 設定

Horizonのアセットを公開すると、`config/horizon.php`に一番重要な設定ファイルが設置されます。この設定ファイルにより、ワーカのオプションを設置します。各オプションにはその目的が説明されていますので、ファイル全体をしっかりと確認してください。

> {note} Horizonを実行する予定の環境ごとのエントリーを`horizon`設定ファイルの`environments`部分へ確実に含めてください。

<a name="balance-options"></a>
#### バランスオプション

Horizonでは３つのバランシング戦略が選択できます。`simple`と`auto`、`false`です。`simple`戦略は設定ファイルのデフォルトで、投入されたジョブをプロセス間に均等に割り当てます。

    'balance' => 'simple',

`auto`戦略は、現在のキュー負荷に基づき、それぞれのキューへ割り当てるワーカプロセス数を調整します。たとえば、`notifications`キューに千個のジョブが溜まっており、一方で`render`キューが空の場合、Horizonは空になるまで`notifications`キューにより多くのワーカを割り当てます。`balance`オプションへ`false`を設定すると、設定にリストした順番でキューが処理される、Laravelデフォルトの振る舞いが使われます。

`auto`戦略を使う場合、Horizonがスケールアップ／ダウンで使用すべきプロセス数の最小値と最大値をコントロールするために、`minProcesses`と`maxProcesses`設定オプションを定義してください。

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

`balanceMaxShift`と`balanceCooldown`の設定値はいかに素早くHorizonをワーカの要求に合わせてスケールするかを決めるためのものです。上の例の場合、３秒毎に最大１つの新しいプロセスを生成するか、破棄します。アプリケーションの必要性を基にし、自由にこの値を調整してください。

<a name="job-trimming"></a>
#### ジョブのクリア

`horizon`設定ファイルで、現在がどのくらいの長さなのか、それと失敗したジョブをどのくらい保持しているかを分数で設定できます。デフォルトでは、現在のジョブは１時間、失敗したジョブは１週間保持されます。

    'trim' => [
        'recent' => 60,
        'failed' => 10080,
    ],

<a name="dashboard-authorization"></a>
### ダッシュボードの認可

Horizonは、`/horizon`でダッシュボードを表示します。デフォルトでは`local`環境でのみ、このダッシュボードへアクセスできます。`app/Providers/HorizonServiceProvider.php`ファイルの中に、`gate`メソッドが存在しています。この認可ゲートは**local以外**の環境における、Horizonへのアクセスをコントロールします。Horizonへのアクセスを必要に応じ制限するために、自由に変更してください。

    /**
     * Horizonゲートの登録
     *
     * このゲートはlocal以外の環境で、誰がHorizonへアクセスできるか決定している。
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

> {note} LaravelはGateへ自動的に**認証済み**ユーザーを依存注入します。IP制限のような別のHorizonセキュリティ方法をアプリケーションで提供する場合は、Horizonユーザーは「ログイン」している必要はいらないでしょう。そのため、上記の`function ($user)`を`function ($user = null)`へ変更し、Laravelに認証は必要ないと強制的に知らせてください。

<a name="upgrading-horizon"></a>
## Horizonのアップグレード

Horizonの新しいメジャーバージョンへアップグレードする場合は、注意深く[アップグレードガイド](https://github.com/laravel/horizon/blob/master/UPGRADE.md)を確認するのが重要です。

付け加えて、新しいHorizonへバージョンアップするときは、アセットを再公開する必要があります。

    php artisan horizon:publish

最新の更新状態を維持し、将来のアップデートで起きる問題を防ぐために、`composer.json`ファイルの`post-update-cmd`スクリプトへこのコマンドを追加しておくのが良いでしょう。

    {
        "scripts": {
            "post-update-cmd": [
                "@php artisan horizon:publish --ansi"
            ]
        }
    }

<a name="running-horizon"></a>
## Horizonの実行

`config/horizon.php`設定ファイルでワーカの設定を済ませたら、`horizon` Artisanコマンドを使用し、Horizonを使用開始します。このコマンド一つで、設定済みのワーカ全部を起動できます。

    php artisan horizon

Horizonプロセスを`horizon:pause` Artisanコマンドで一時停止したり、`horizon:continue`コマンドで処理を続行したりできます。

    php artisan horizon:pause

    php artisan horizon:continue

`horizo​​n：pause-supervisor`、` horizo​​n：continue-supervisor` Artisanコマンドを使用して、特定のHorizo​​nスーパーバイザー（ワーカーグループ）を一時停止、続行することもできます。

    php artisan horizon:pause-supervisor supervisor-1

    php artisan horizon:continue-supervisor supervisor-1

`horizon:status` Artisanコマンドにより、Horizonプロセスの現在の状態を確認できます。

    php artisan horizon:status

マシン上のマスタHorizonプロセスを穏やかに終了させたい場合は、`horizon:terminate` Artisanコマンドを使用します。現在処理中のジョブが完了した後に、Horizonは停止します。

    php artisan horizon:terminate

<a name="deploying-horizon"></a>
### Horizonのデプロイ

Horizonを実働サーバにデプロイする場合、`php artisan horizon`コマンドをプロセスモニタで監視し、予期せず終了した場合には再起動をかけるように設定する必要があります。サーバに新しいコードをデプロイしたときに、Horizonプロセスを停止指示する必要があります。その結果、プロセスモニタにより再起動され、コードの変更が反映されます。

<a name="installing-supervisor"></a>
#### Supervisorのインストール

SupervisorはLinuxオペレーティングシステムのプロセスモニターで、`horizon`システムが停止すると自動的に再起動してくれます。UbuntuへSupervisorをインストールするには、次のようにコマンドを入力します。

    sudo apt-get install supervisor

> {tip} Supervisorの設定を自分で行うのに圧倒されるようでしたら、[Laravel Forge](https://forge.laravel.com)の使用を考慮してください。LaravelプロジェクトのためにSupervisorを自動的にインストールし、設定します。

<a name="supervisor-configuration"></a>
#### Supervisor設定

Supervisorの設定ファイルは通常`/etc/supervisor/conf.d`へ保存されています。このディレクトリの中では、Supervisorへプロセスをどのようにモニタリングするのかを指示するために、設定ファイルをいくつでも作成できます。一例として、`horizon.conf`ファイルを作成し、`horizon`プロセスを起動・監視してみましょう。

    [program:horizon]
    process_name=%(program_name)s
    command=php /home/forge/app.com/artisan horizon
    autostart=true
    autorestart=true
    user=forge
    redirect_stderr=true
    stdout_logfile=/home/forge/app.com/horizon.log
    stopwaitsecs=3600

> {note} 一番時間がかかるジョブが消費する秒数より大きな値を`stopwaitsecs`へ必ず指定してください。そうしないと、Supervisorは処理が終了する前に、そのジョブをキルしてしまうでしょう。

<a name="starting-supervisor"></a>
#### Supervisorの起動

設定ファイルが作成できたら、Supervisor設定をを更新し、起動するために次のようにコマンドを入力します。

    sudo supervisorctl reread

    sudo supervisorctl update

    sudo supervisorctl start horizon

Supervisorの詳細については、[Supervisorドキュメント](http://supervisord.org/index.html)をお読みください。

<a name="tags"></a>
## タグ

Horizonでは、mailableやイベントブロードキャスト、通知、キューイベントリスナなどを含むジョブに「タグ」を割り付けられます。実際、ジョブへ割り付けたEloquentモデルに基づいて、ほとんどのジョブでは賢く自動的にHorizonがタグ付けします。例として、以下のジョブをご覧ください。

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
         * ビデオインスタンス
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

`id`が`1`の`App\Models\Video`インスタンスを持つジョブがキューされると、自動的に`App\Models\Video:1`タグが付けられます。HorizonはジョブのプロパティがEloquentモデルであるかを確認するからです。Eloquentモデルが見つかると、Horizonはモデルのクラス名と主キーを使用し、賢くタグ付けします。

    $video = App\Models\Video::find(1);

    App\Jobs\RenderVideo::dispatch($video);

<a name="manually-tagging"></a>
#### 手動のタグ付け

queueableオブジェクトのタグを任意に定義したい場合は、そのクラスで`tags`メソッドを定義してください。

    class RenderVideo implements ShouldQueue
    {
        /**
         * ジョブに割り付けるタグの取得
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

> **Note:** Horizonから、SlackかSMS通知を送る設定を行う場合は、[対応するドライバの動作要件](/docs/{{version}}/notifications)についても、確認する必要があります。

あるキューが長時間waitしている時に、通知を受け取りたい場合は、`Horizon::routeSlackNotificationsTo`や、`Horizon::routeSlackNotificationsTo`、`Horizon::routeSmsNotificationsTo`メソッドを利用してください。これらのメソッドは、`HorizonServiceProvider`から呼び出すのが良いでしょう。

    Horizon::routeMailNotificationsTo('example@example.com');
    Horizon::routeSlackNotificationsTo('slack-webhook-url', '#channel');
    Horizon::routeSmsNotificationsTo('15556667777');

<a name="configuring-notification-wait-time-thresholds"></a>
#### 通知wait時間のシュレッドホールド設定

何秒を「長時間」と考えるかは、`config/horizon.php`設定ファイルで指定できます。このファイルの`waits`設定オプションで、接続／キューの組み合わせごとに、長時間と判定するシュレッドホールドをコントロールできます。

    'waits' => [
        'redis:default' => 60,
        'redis:critical,high' => 90,
    ],

<a name="metrics"></a>
## メトリックス

Horizonはジョブとキューの待ち時間とスループットの情報をダッシュボードに表示します。このダッシュボードを表示するために、アプリケーションの[スケジューラ](/docs/{{version}}/scheduling)で、５分毎に`snapshot` Artisanコマンドを実行する設定を行う必要があります。

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

失敗したジョブを削除する場合は、`horizon：forget`コマンドを使用します。`horizon：forget`コマンドは、失敗したジョブのIDを唯一の引数に取ります。

    php artisan horizon:forget 5

<a name="clearing-jobs-from-queues"></a>
## キューのジョブのクリア

デフォルトのキューからすべてのジョブを削除したい場合は、`horizon：clear`　Artisanコマンドを使用し削除します。

    php artisan horizon:clear

`queue`オプションでジョブを削除するキューを指定することも可能です。

    php artisan horizon:clear --queue=emails
