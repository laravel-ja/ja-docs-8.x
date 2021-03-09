# タスクスケジュール

- [イントロダクション](#introduction)
- [スケジュール定義](#defining-schedules)
    - [Artisanコマンドのスケジュール](#scheduling-artisan-commands)
    - [キュー投入するジョブのスケジュール](#scheduling-queued-jobs)
    - [シェルコマンドのスケジュール](#scheduling-shell-commands)
    - [繰り返しのスケジュールオプション](#schedule-frequency-options)
    - [タイムゾーン](#timezones)
    - [タスク多重起動の停止](#preventing-task-overlaps)
    - [単一サーバ上でのタスク実行](#running-tasks-on-one-server)
    - [バックグランドタスク](#background-tasks)
    - [メンテナンスモード](#maintenance-mode)
- [スケジュールの実行](#running-the-scheduler)
    - [スケジュールをローカルで実行](#running-the-scheduler-locally)
- [タスク出力](#task-output)
- [タスクフック](#task-hooks)

<a name="introduction"></a>
## イントロダクション

以前は、サーバでスケジュールする必要のあるタスクごとにcron設定エントリを作成する必要がありました。しかしながら、タスクスケジュールがソース管理されないため、これはすぐに苦痛になる可能性があります。既存のcronエントリを表示したり、エントリを追加したりするには、サーバへSSHで接続する必要がありました。

Laravelのコマンドスケジューラは、サーバ上でスケジュールするタスクを管理するための新しいアプローチを提供しています。スケジューラを使用すると、Laravelアプリケーション自体の中でコマンドスケジュールを流暢かつ表現力豊かに定義できます。スケジューラを使用する場合、サーバに必要なcronエントリは１つだけです。タスクスケジュールは、`app/Console/Kernel.php`ファイルの`schedule`メソッドで定義されます。手を付けるのに役立つように、メソッド内に簡単な例が定義されています。

<a name="defining-schedules"></a>
## スケジュール定義

スケジュールするすべてのタスクは、アプリケーションの`App\Console\Kernel`クラスの`schedule`メソッドで定義します。はじめに、例を見てみましょう。この例では、毎日深夜に呼び出されるようにクロージャをスケジュールします。クロージャ内で、データベースクエリを実行してテーブルをクリアします。

    <?php

    namespace App\Console;

    use Illuminate\Console\Scheduling\Schedule;
    use Illuminate\Foundation\Console\Kernel as ConsoleKernel;
    use Illuminate\Support\Facades\DB;

    class Kernel extends ConsoleKernel
    {
        /**
         * アプリケーションで提供するArtisanコマンド
         *
         * @var array
         */
        protected $commands = [
            //
        ];

        /**
         * アプリケーションのコマンド実行スケジュール定義
         *
         * @param  \Illuminate\Console\Scheduling\Schedule  $schedule
         * @return void
         */
        protected function schedule(Schedule $schedule)
        {
            $schedule->call(function () {
                DB::table('recent_users')->delete();
            })->daily();
        }
    }

クロージャを使用したスケジュールに加えて、[呼び出し可能なオブジェクト](https://secure.php.net/manual/en/language.oop5.magic.php#object.invoke)をスケジュールすることもできます。呼び出し可能なオブジェクトは、`__invoke`メソッドを含む単純なPHPクラスです。

    $schedule->call(new DeleteRecentUsers)->daily();

スケジュールしたタスクの概要と、次に実行がスケジュールされている時間を表示したい場合は、`schedule:list` Artisanコマンドを使用します。

```nothing
php artisan schedule:list
```

<a name="scheduling-artisan-commands"></a>
### Artisanコマンドのスケジュール

クロージャのスケジュールに加えて、[Artisanコマンド](/docs/{{version}}/artisan)およびシステムコマンドをスケジュールすることもできます。たとえば、`command`メソッドを使用して、コマンドの名前またはクラスのいずれかを使用してArtisanコマンドをスケジュールできます。

コマンドのクラス名を使用してArtisanコマンドをスケジュールする場合、コマンドが呼び出されたときにコマンドに提供する必要がある追加のコマンドライン引数の配列を渡せます。

    use App\Console\Commands\SendEmailCommand;

    $schedule->command('emails:send Taylor --force')->daily();

    $schedule->command(EmailsCommand::class, ['Taylor', '--force'])->daily();

<a name="scheduling-queued-jobs"></a>
### キュー投入するジョブのスケジュール

[キュー投入するジョブ](/docs/{{version}}/queues)をスケジュールするには、`job`メソッドを使います。このメソッドを使うと、ジョブをキューに入れるためのクロージャを自前で作成する`call`メソッドを使わずとも、ジョブをスケジュール実行できます。

    use App\Jobs\Heartbeat;

    $schedule->job(new Heartbeat)->everyFiveMinutes();

オプションの２番目と３番目の引数を`job`メソッドに指定して、ジョブのキューに入れるために使用するキュー名とキュー接続を指定できます。

    use App\Jobs\Heartbeat;

    // "sqs"接続の"heartbeats"キューにジョブをディスパッチ
    $schedule->job(new Heartbeat, 'heartbeats', 'sqs')->everyFiveMinutes();

<a name="scheduling-shell-commands"></a>
### シェルコマンドのスケジュール

オペレーティングシステムでコマンドを実行するためには`exec`メソッドを使います。

    $schedule->exec('node /home/forge/script.js')->daily();

<a name="schedule-frequency-options"></a>
### 繰り返しのスケジュールオプション

指定間隔で実行するようにタスクを設定する方法の例をいくつか見てきました。しかし、タスクに割り当てることができるタスクスケジュールの間隔は他にもたくさんあります。

メソッド  | 説明
------------- | -------------
`->cron('* * * * *');`  |  カスタムcronスケジュールでタスクを実行
`->everyMinute();`  |  毎分タスク実行
`->everyTwoMinutes();`  |  ２分毎にタスク実行
`->everyThreeMinutes();`  |  ３分毎にタスク実行
`->everyFourMinutes();`  |  ４分毎にタスク実行
`->everyFiveMinutes();`  |  ５分毎にタスク実行
`->everyTenMinutes();`  |  １０分毎にタスク実行
`->everyFifteenMinutes();`  |  １５分毎にタスク実行
`->everyThirtyMinutes();`  |  ３０分毎にタスク実行
`->hourly();`  |  毎時タスク実行
`->hourlyAt(17);`  |  １時間ごと、毎時１７分にタスク実行
`->everyTwoHours();`  |  ２時間毎にタスク実行
`->everyThreeHours();`  |  ３時間毎にタスク実行
`->everyFourHours();`  |  ４時間毎にタスク実行
`->everySixHours();`  |  ６時間毎にタスク実行
`->daily();`  |  毎日深夜１２時に実行
`->dailyAt('13:00');`  |  毎日13:00に実行
`->twiceDaily(1, 13);`  |  毎日1:00と13:00時に実行
`->weekly();`  |  毎週日曜日の00:00にタスク実行
`->weeklyOn(1, '8:00');`  |  毎週月曜日の8:00時に実行
`->monthly();`  |  毎月１日の00:00にタスク実行
`->monthlyOn(4, '15:00');`  |  毎月4日の15:00に実行
`->twiceMonthly(1, 16, '13:00');`  |  毎月１日と１６日の13:00にタスク実行
`->lastDayOfMonth('15:00');` |  毎月最終日の15:00時に実行
`->quarterly();` |  四半期の初日の00:00にタスク実行
`->yearly();`  |  毎年１月１日の00:00にタスク実行
`->yearlyOn(6, 1, '17:00');`  |  毎年６月１日の17:00にタスク実行
`->timezone('America/New_York');` | タスクのタイムゾーンを設定

これらの方法を追加の制約と組み合わせてると、特定の曜日にのみ実行する、さらに細かく調整したスケジュールを作成できます。たとえば、毎週月曜日に実行するようにコマンドをスケジュールできます。

    // 週に１回、月曜の13:00に実行
    $schedule->call(function () {
        //
    })->weekly()->mondays()->at('13:00');

    // ウィークエンドの8時から17時まで１時間ごとに実行
    $schedule->command('foo')
              ->weekdays()
              ->hourly()
              ->timezone('America/Chicago')
              ->between('8:00', '17:00');

追加のスケジュール制約のリストを以下にリストします。

メソッド  | 説明
------------- | -------------
`->weekdays();`  |  ウィークデーのみに限定
`->weekends();`  |  ウィークエンドのみに限定
`->sundays();`  |  日曜だけに限定
`->mondays();`  |  月曜だけに限定
`->tuesdays();`  |  火曜だけに限定
`->wednesdays();`  |  水曜だけに限定
`->thursdays();`  |  木曜だけに限定
`->fridays();`  |  金曜だけに限定
`->saturdays();`  |  土曜だけに限定
`->days(array|mixed);`  |  特定の日にちだけに限定
`->between($startTime, $endTime);`  |  開始と終了時間間にタスク実行を制限
`->unlessBetween($startTime, $endTime);`  |  開始と終了時間間にタスクを実行しないよう制限
`->when(Closure);`  |  クロージャの戻り値が`true`の時のみに限定
`->environments($env);`  |  指定の環境でのみタスク実行を限定

<a name="day-constraints"></a>
#### 曜日の限定

`days`メソッドはタスクを週の指定した曜日に実行するように制限するために使用します。たとえば、日曜日と水曜日に毎時コマンドを実行するようにスケジュールするには次のように指定します。

    $schedule->command('emails:send')
                    ->hourly()
                    ->days([0, 3]);

または、タスクを実行する日を定義するときに、`Illuminate\Console\Scheduling\Schedule`クラスで使用可能な定数を使用することもできます。

    use Illuminate\Console\Scheduling\Schedule;

    $schedule->command('emails:send')
                    ->hourly()
                    ->days([Schedule::SUNDAY, Schedule::WEDNESDAY]);

<a name="between-time-constraints"></a>
#### 時間制限

`between`メソッドは一日の時間に基づき、実行時間を制限するために使用します。

    $schedule->command('emails:send')
                        ->hourly()
                        ->between('7:00', '22:00');

同じように、`unlessBetween`メソッドは、その時間にタスクの実行を除外するために使用します。

    $schedule->command('emails:send')
                        ->hourly()
                        ->unlessBetween('23:00', '4:00');

<a name="truth-test-constraints"></a>
#### 論理テスト制約

`when`メソッドを使用して、特定の論理テストの結果に基づいてタスクの実行を制限できます。言い換えると、指定するクロージャが`true`を返す場合、他の制約条件がタスクの実行を妨げない限り、タスクは実行されます。

    $schedule->command('emails:send')->daily()->when(function () {
        return true;
    });

`skip`メソッドは`when`をひっくり返したものです。`skip`メソッドへ渡したクロージャが`true`を返した時、スケジュールタスクは実行されません。

    $schedule->command('emails:send')->daily()->skip(function () {
        return true;
    });

`when`メソッドをいくつかチェーンした場合は、全部の`when`条件が`true`を返すときのみスケジュールされたコマンドが実行されます。

<a name="environment-constraints"></a>
#### 環境制約

`environments`メソッドは、指定する環境でのみタスクを実行するために使用できます（`APP_ENV`[環境変数](/docs/{{version}}/configuration#environment-configuration)で定義されます。）

    $schedule->command('emails:send')
                ->daily()
                ->environments(['staging', 'production']);

<a name="timezones"></a>
### タイムゾーン

`timezone`メソッドを使い、タスクのスケジュールをどこのタイムゾーンとみなすか指定できます。

    $schedule->command('report:generate')
             ->timezone('America/New_York')
             ->at('2:00')

スケジュールされたすべてのタスクに同じタイムゾーンを繰り返し割り当てる場合は、`App\Console\Kernel`クラスで`scheduleTimezone`メソッドを定義することをお勧めします。このメソッドは、スケジュールされたすべてのタスクに割り当てる必要があるデフォルトのタイムゾーンを返す必要があります。

    /**
     * スケジュールされたイベントで使用するデフォルトのタイムゾーン取得
     *
     * @return \DateTimeZone|string|null
     */
    protected function scheduleTimezone()
    {
        return 'America/Chicago';
    }

> {note} タイムゾーンの中には夏時間を取り入れているものがあることを忘れないでください。夏時間の切り替えにより、スケジュールしたタスクが２回実行されたり、まったくされないことがあります。そのため、可能であればタイムゾーンによるスケジュールは使用しないことを推奨します。

<a name="preventing-task-overlaps"></a>
### タスク多重起動の防止

デフォルトでは以前の同じジョブが起動中であっても、スケジュールされたジョブは実行されます。これを防ぐには、`withoutOverlapping`メソッドを使用してください。

    $schedule->command('emails:send')->withoutOverlapping();

この例の場合、`emails:send` [Artisanコマンド](/docs/{{version}}/artisan)は実行中でない限り毎分実行されます。`withoutOverlapping`メソッドは指定したタスクの実行時間の変動が非常に大きく、予想がつかない場合にとくに便利です。

必要であれば、「重起動の防止(without overlapping)」ロックを期限切れにするまでに、何分間経過させるかを指定できます。時間切れまでデフォルトは、２４時間です。

    $schedule->command('emails:send')->withoutOverlapping(10);

<a name="running-tasks-on-one-server"></a>
### 単一サーバ上でのタスク実行

> {note} この機能を利用するには、アプリケーションのデフォルトのキャッシュドライバとして`database`、`memcached`、`dynamodb`、`redis`キャッシュドライバを使用している必要があります。さらに、すべてのサーバが同じ中央キャッシュサーバと通信している必要があります。

アプリケーションのスケジューラを複数のサーバで実行する場合は、スケジュールしたジョブを単一のサーバでのみ実行するように制限できます。たとえば、毎週金曜日の夜に新しいレポートを生成するスケジュールされたタスクがあるとします。タスクスケジューラが3つのワーカーサーバで実行されている場合、スケジュールされたタスクは3つのサーバすべてで実行され、レポートを3回生成してしまいます。これは良くありません！

タスクをサーバひとつだけで実行するように指示するには、スケジュールタスクを定義するときに`onOneServer`メソッドを使用します。このタスクを最初に取得したサーバが、同じタスクを同じCronサイクルで他のサーバで実行しないように、ジョブにアトミックなロックを確保します。

    $schedule->command('report:generate')
                    ->fridays()
                    ->at('17:00')
                    ->onOneServer();

<a name="background-tasks"></a>
### バックグランドタスク

デフォルトでは、同時にスケジュールされた複数のタスクは、`schedule`メソッドで定義された順序に基づいて順番に実行されます。長時間実行されるタスクがある場合、これにより、後続のタスクが予想よりもはるかに遅く開始される可能性があります。タスクをすべて同時に実行できるようにバックグラウンドで実行する場合は、`runInBackground`メソッドを使用できます。

    $schedule->command('analytics:report')
             ->daily()
             ->runInBackground();

> {note} `runInBackground`メソッドは`command`か`exec`メソッドにより、タスクをスケジュールするときにのみ使用してください。

<a name="maintenance-mode"></a>
### メンテナンスモード

アプリケーションが[メンテナンスモード](/docs/{{version}}/configuration#maintenance-mode)の場合、アプリケーションのスケジュールされたタスクは実行されません。これは、タスクがそのサーバで実行している未完了のメンテナンスに干渉することを望まないためです。ただし、メンテナンスモードでもタスクを強制的に実行したい場合は、タスクを定義するときに`evenInMaintenanceMode`メソッドを呼び出すことができます。

    $schedule->command('emails:send')->evenInMaintenanceMode();

<a name="running-the-scheduler"></a>
## スケジューラの実行

スケジュールするタスクを定義する方法を学習したので、サーバで実際にタスクを実行する方法について説明しましょう。`schedule:run` Artisanコマンドは、スケジュールしたすべてのタスクを評価し、サーバの現在の時刻に基づいてタスクを実行する必要があるかどうかを判断します。

したがって、Laravelのスケジューラを使用する場合、サーバに１分ごとに`schedule:run`コマンドを実行する単一のcron設定エントリを追加するだけで済みます。サーバにcronエントリを追加する方法がわからない場合は、[Laravel Forge](https://forge.laravel.com)などのcronエントリを管理できるサービスの使用を検討してください。

    * * * * * cd /path-to-your-project && php artisan schedule:run >> /dev/null 2>&1

<a name="running-the-scheduler-locally"></a>
## スケジュールをローカルで実行

通常、ローカル開発マシンにスケジューラのcronエントリを追加することはありません。代わりに、`schedule:work` Artisanコマンドを使用できます。このコマンドはフォアグラウンドで実行し、コマンドを終了するまで１分ごとにスケジューラーを呼び出します。

    php artisan schedule:work

<a name="task-output"></a>
## タスク出力

Laravelスケジューラはスケジュールしたタスクが生成する出力を取り扱う便利なメソッドをたくさん用意しています。最初に`sendOutputTo`メソッドを使い、後ほど内容を調べられるようにファイルへ出力してみましょう。

    $schedule->command('emails:send')
             ->daily()
             ->sendOutputTo($filePath);

出力を指定したファイルに追加したい場合は、`appendOutputTo`メソッドを使います。

    $schedule->command('emails:send')
             ->daily()
             ->appendOutputTo($filePath);

`emailOutputTo`メソッドを使用して、選択した電子メールアドレスへ出力を電子メールで送信できます。タスクの出力をメールで送信する前に、Laravelの[メールサービス](/docs/{{version}}/mail)を設定する必要があります。

    $schedule->command('report:generate')
             ->daily()
             ->sendOutputTo($filePath)
             ->emailOutputTo('taylor@example.com');

スケジュールしたArtisanまたはシステムコマンドが、ゼロ以外の終了コードで終了した場合にのみ出力を電子メールで送信する場合は、`emailOutputOnFailure`メソッドを使用します。

    $schedule->command('report:generate')
             ->daily()
             ->emailOutputOnFailure('taylor@example.com');

> {note} `emailOutputTo`、 `emailOutputOnFailure`、`sendOutputTo`、`appendOutputTo`メソッドは、`command`と`exec`メソッドに対してどれか一つしか指定できません。

<a name="task-hooks"></a>
## タスクフック

`before`および`after`メソッドを使用して、スケジュール済みのタスクを実行する前後に実行するコードを指定できます。

    $schedule->command('emails:send')
             ->daily()
             ->before(function () {
                 // タスクが実行されようとしている
             })
             ->after(function () {
                 // タスクが実行された
             });

`onSuccess`メソッドと`onFailure`メソッドを使用すると、スケジュールされたタスクが成功または失敗した場合に実行されるコードを指定できます。失敗は、スケジュールされたArtisanまたはシステムコマンドがゼロ以外の終了コードで終了したことを示します。

    $schedule->command('emails:send')
             ->daily()
             ->onSuccess(function () {
                 // タスク成功時…
             })
             ->onFailure(function () {
                 // タスク失敗時…
             });

コマンドから出力を利用できる場合は、フックのクロージャの定義で`$output`引数として`Illuminate\Support\Stringable`インスタンスを型指定することで、`after`、`onSuccess`、または`onFailure`フックでアクセスできます。

    use Illuminate\Support\Stringable;

    $schedule->command('emails:send')
             ->daily()
             ->onSuccess(function (Stringable $output) {
                 // タスク成功時…
             })
             ->onFailure(function (Stringable $output) {
                 // タスク失敗時…
             });

<a name="pinging-urls"></a>
#### URLへのPing

`pingBefore`メソッドと`thenPing`メソッドを使用すると、スケジューラーはタスクの実行前または実行後に、指定するURLに自動的にpingを実行できます。このメソッドは、[Envoyer](https://envoyer.io)などの外部サービスに、スケジュールされたタスクが実行を開始または終了したことを通知するのに役立ちます。

    $schedule->command('emails:send')
             ->daily()
             ->pingBefore($url)
             ->thenPing($url);

`pingBeforeIf`および`thenPingIf`メソッドは、特定の条件が`true`である場合にのみ、特定のURLにpingを実行するために使用します。

    $schedule->command('emails:send')
             ->daily()
             ->pingBeforeIf($condition, $url)
             ->thenPingIf($condition, $url);

`pingOnSuccess`メソッドと`pingOnFailure`メソッドは、タスクが成功または失敗した場合にのみ、特定のURLにpingを実行するために使用します。失敗は、スケジュールされたArtisanまたはシステムコマンドがゼロ以外の終了コードで終了したことを示します。

    $schedule->command('emails:send')
             ->daily()
             ->pingOnSuccess($successUrl)
             ->pingOnFailure($failureUrl);

すべてのpingメソッドにGuzzle HTTPライブラリが必要です。Guzzleは通常、デフォルトですべての新しいLaravelプロジェクトにインストールされますが、誤って削除した場合は、Composerパッケージマネージャーを使用してプロジェクトへ自分でGuzzleをインストールできます。

    composer require guzzlehttp/guzzle
