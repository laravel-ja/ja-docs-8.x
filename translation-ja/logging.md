# ログ

- [イントロダクション](#introduction)
- [設定](#configuration)
    - [ログスタックの構築](#building-log-stacks)
- [ログメッセージの記述](#writing-log-messages)
    - [指定チャンネルへの記述](#writing-to-specific-channels)
- [Monologチャンネルの上級カスタマイズ](#advanced-monolog-channel-customization)
    - [チャンネル用Monologカスタマイズ](#customizing-monolog-for-channels)
    - [Monologハンドラチャンネルの作成](#creating-monolog-handler-channels)
    - [ファクトリを用いたチャンネル生成](#creating-channels-via-factories)

<a name="introduction"></a>
## イントロダクション

アプリケーションで発生している事象を確実に捕らえるため、Laravelはログメッセージをファイルやシステムエラーログ、さらにチーム全体に知らせるためのSlack通知も可能な、堅牢なログサービスを提供しています。

そのために、Laravelは多くのパワフルなログハンドラをサポートしている、[Monolog](https://github.com/Seldaek/monolog)ライブラリーを活用しています。Laravelはそうしたハンドラの設定を簡単にできるようにし、アプリケーションのログ処理に合わせカスタマイズするため、ハンドラを多重に使ったり、マッチングできるようにしています。

<a name="configuration"></a>
## 設定

アプリケーションのログシステムの設定はすべて、`config/logging.php`設定ファイルに用意されています。このファイルはアプリケーションのログチャンネルを設定できるため、使用可能なチャンネルやその他のオプションをしっかりとレビューしてください。よく使用されるオプションを以降からレビューします。

デフォルトでは、Laravelは`stack`チャンネルをメッセージをログする場合に使用します。`stack`チャンネルは、複数のログチャンネルを一つのログチャンネルへ集結するために使用します。スタックの構築に関する詳細は、[このドキュメントで後ほど](#building-log-stacks)説明します。

<a name="configuring-the-channel-name"></a>
#### チャンネル名の設定

Monologはデフォルトで`production`や`local`のような、現在の環境と一致する「チャンネル名」でインスタンス化されます。この値を変更するには、チャンネルの設定に`name`オプションを追加してください。

    'stack' => [
        'driver' => 'stack',
        'name' => 'channel-name',
        'channels' => ['single', 'slack'],
    ],

<a name="available-channel-drivers"></a>
#### 利用可能なチャンネルドライバ

名前 | 説明
------------- | -------------
`stack` | 「マルチチャンネル」チャンネルを作成するためのラッパー機能
`single` | シングルファイル／パスベースのロガーチャンネル（`StreamHandler`）
`daily` | `RotatingFileHandler`ベースの毎日ファイルを切り替えるMonologドライバ
`slack` | `SlackWebhookHandler`ベースのMonologドライバ
`papertrail` | `SyslogUdpHandler`ベースのMonologドライバ
`syslog` | `SyslogHandler`ベースのMonologドライバ
`errorlog` | `ErrorLogHandler`ベースのMonologドライバ
`monolog` | サポートしているMonologハンドラをどれでも使用できる、Monologファクトリドライバ
`custom` | チャンネルを生成するため、指定したファクトリを呼び出すドライバ

> {tip} `monolog`と`custom`ドライバの詳細は、[上級チャンネルカスタマイズ](#advanced-monolog-channel-customization)のドキュメントを確認し、学んでください。

<a name="configuring-the-single-and-daily-channels"></a>
#### シングルファイルとディリーチャンネルの設定

`single`と`daily`チャンネルは３つ設定オプションを持っています。`bubble`、`permission`、`locking`です。

名前 | 説明 | デフォルト値
------------- | ------------- | -------------
`bubble` | 処理後に他のチャンネルへメッセージをバブルアップさせるか | `true`
`permission` | ログファイルのパーミッション | `0644`
`locking` | 書き込む前にログファイルのロックを試みる | `false`

<a name="configuring-the-papertrail-channel"></a>
#### Papertrailチャンネルの設置

`papertrail`チャンネルでは、`url`と`port`設定オプションが必要です。[Papertrail](https://help.papertrailapp.com/kb/configuration/configuring-centralized-logging-from-php-apps/#send-events-from-php-app)から、それらの値を入手できます。

<a name="configuring-the-slack-channel"></a>
#### Slackチャンネルの設定

`slack`チャンネルには、`url`設定オプションが必須です。このURLはSlackチームに対して設定されている、[incoming webhook](https://slack.com/apps/A0F7XDUAZ-incoming-webhooks)へのURLと一致させる必要があります。デフォルトでSlackは`critical`レベル以上のログのみを受け付けます。しかしながら、`logging`設定ファイルでこれを調整可能です。

<a name="building-log-stacks"></a>
### ログスタックの構築

先に説明した通り、`stack`ドライバーは、複数のチャンネルを一つのログチャンネルへまとめるために使用します。ログスタックの使用方法を説明するため、ある実働環境に対する設定例を見てみましょう。

    'channels' => [
        'stack' => [
            'driver' => 'stack',
            'channels' => ['syslog', 'slack'],
        ],

        'syslog' => [
            'driver' => 'syslog',
            'level' => 'debug',
        ],

        'slack' => [
            'driver' => 'slack',
            'url' => env('LOG_SLACK_WEBHOOK_URL'),
            'username' => 'Laravel Log',
            'emoji' => ':boom:',
            'level' => 'critical',
        ],
    ],

では、個別にこの設定を確認しましょう。最初に、`stack`チャンネルが`channels`オプションにより`syslog`と`slack`、２つのチャンネルをまとめていることに注目してください。

<a name="log-levels"></a>
#### ログレベル

上記の例で、`syslog`と`slack`チャンネル設定の中に、`level`設定オプションが存在していることに注目です。このオプションは、そのチャンネルでメッセージをログする、最低の「レベル」を定めるオプションです。Laravelのログサービスを動かしているMonologは、[RFC 5424規約](https://tools.ietf.org/html/rfc5424)で定められている全ログレベルが使用できます。**emergency**と**alert**、**critical**、**error**、**warning**、**notice**、**info**、**debug**です。

`debug`メソッドを使用し、メッセージをログしてみることを想像しましょう。

    Log::debug('An informational message.');

上記設定では、`syslog`チャンネルにより、システムログへメッセージを書き込みます。しかしながら、エラーメッセージは`critical`以上ではないため、Slackには送られません。ところが、`emergency`メッセージをログする場合、両方のチャンネルに対する最低の基準レベル以上のため、システムログとSlackの両方へ送られます。

    Log::emergency('The system is down!');

<a name="writing-log-messages"></a>
## ログメッセージの記述

`Log`[ファサード](/docs/{{version}}/facades)を使い、情報をログできます。先に説明したように、ロガーは[RFC 5424規約](https://tools.ietf.org/html/rfc5424)に定義されている、**emergency**、**alert**、**critical**、**error**、**warning**、**notice**、**info**、**debug**の８ログレベルを提供しています。

    Log::emergency($message);
    Log::alert($message);
    Log::critical($message);
    Log::error($message);
    Log::warning($message);
    Log::notice($message);
    Log::info($message);
    Log::debug($message);

ログメッセージレベルに応じたメソッドを呼び出してください。デフォルトでは、`config/logging.php`設定ファイルで定義されているデフォルトログチャンネルへ、メッセージが書き込まれます。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Models\User;
    use Illuminate\Support\Facades\Log;

    class UserController extends Controller
    {
        /**
         * 指定したユーザーのプロファイルを表示
         *
         * @param  int  $id
         * @return Response
         */
        public function showProfile($id)
        {
            Log::info('Showing user profile for user: '.$id);

            return view('user.profile', ['user' => User::findOrFail($id)]);
        }
    }

<a name="contextual-information"></a>
#### 文脈情報

ログメソッドには、文脈情報の配列を渡すことも可能です。この文脈情報は、ログメッセージに整形され、表示されます。

    Log::info('User failed to login.', ['id' => $user->id]);

<a name="writing-to-specific-channels"></a>
### 指定チャンネルへの記述

アプリケーションのデフォルトチャンネルの代わりに、別のチャンネルへメッセージをログしたい場合もあります。設定ファイルに定義してあるチャンネルを`Log`ファサードの`channel`メソッドを使い取得し、ログしてください。

    Log::channel('slack')->info('Something happened!');

複数チャンネルで構成されたログスタックをオンデマンドで生成したい場合は、`stack`メソッドを使います。

    Log::stack(['single', 'slack'])->info('Something happened!');


<a name="advanced-monolog-channel-customization"></a>
## Monologチャンネルの上級カスタマイズ

<a name="customizing-monolog-for-channels"></a>
### チャンネル用Monologカスタマイズ

既存チャンネルに対するMonologの設定方法を複雑にコントロールする必要がある場合もあり得ます。たとえば、指定したチャンネルハンドラに対し、Monologの`FormatterInterface`カスタム実装を設定したい場合です。

そのためには、チャンネルの設定で、`tap`配列を定義します。`tap`配列は、生成された後のMonologインスタンスをカスタマイズ（もしくは利用 : "`tap` into"）する機会を与える、クラスのリストを含んでいる必要があります。

    'single' => [
        'driver' => 'single',
        'tap' => [App\Logging\CustomizeFormatter::class],
        'path' => storage_path('logs/laravel.log'),
        'level' => 'debug',
    ],

チャンネルに対する`tap`オプションを定義したら、Monologインスタンスをカスタマイズするクラスを定義する準備が整いました。このクラスは`Illuminate\Log\Logger`インスタンスを受け取る、`__invoke`メソッドのみ必要です。`Illuminate\Log\Logger`インスタンスは、すべてのメソッドを裏で動作するMonologインスタンスへ送るプロキシクラスです。

    <?php

    namespace App\Logging;

    use Monolog\Formatter\LineFormatter;

    class CustomizeFormatter
    {
        /**
         * 渡されたロガーインスタンスのカスタマイズ
         *
         * @param  \Illuminate\Log\Logger  $logger
         * @return void
         */
        public function __invoke($logger)
        {
            foreach ($logger->getHandlers() as $handler) {
                $handler->setFormatter(new LineFormatter(
                    '[%datetime%] %channel%.%level_name%: %message% %context% %extra%'
                ));
            }
        }
    }

> {tip} すべての"tap"クラスは、[サービスコンテナ](/docs/{{version}}/container)により、依存解決されます。そのため、コンストラクタで要求した依存は、自動的に注入されます。

<a name="creating-monolog-handler-channels"></a>
### Monologハンドラチャンネルの作成

Monologはバラエティーに富んだ[利用可能なハンドラ](https://github.com/Seldaek/monolog/tree/master/src/Monolog/Handler)を用意しています。あるケースでは、生成したいロガーのタイプが、単に特定のハンドラを持つMonologドライバであることがあります。こうしたチャンネルは`monolog`ドライバーを使用し、生成できます。

`monolog`ドライバーを使用する場合、インスタンス化するハンドラを指定するために、`handler`設定オプションを使います。任意のコンストラクタパラメータを指定する必要がある場合は、`with`設定オプションを使用します。

    'logentries' => [
        'driver'  => 'monolog',
        'handler' => Monolog\Handler\SyslogUdpHandler::class,
        'with' => [
            'host' => 'my.logentries.internal.datahubhost.company.com',
            'port' => '10000',
        ],
    ],

<a name="monolog-formatters"></a>
#### Monologフォーマッター

`monolog`ドライバーを使用する場合、Monolog `LineFormatter`をデフォルトフォーマッターとして使用します。しかし、フォーマッターのタイプをカスタマイズする必要がある場合は、`formatter`と`formatter_with`設定オプションを使用します。

    'browser' => [
        'driver' => 'monolog',
        'handler' => Monolog\Handler\BrowserConsoleHandler::class,
        'formatter' => Monolog\Formatter\HtmlFormatter::class,
        'formatter_with' => [
            'dateFormat' => 'Y-m-d',
        ],
    ],

Monologハンドラが提供する自身のフォーマッターを使用する場合は、`formatter`設定オプションに`default`を値として指定してください。

    'newrelic' => [
        'driver' => 'monolog',
        'handler' => Monolog\Handler\NewRelicHandler::class,
        'formatter' => 'default',
    ],

<a name="creating-channels-via-factories"></a>
### ファクトリを用いたチャンネル生成

Monologのインスタンス化と設定を完全にコントロールするために、完全なカスタムチャンネルを定義したい場合は、`config/logging.php`設定ファイルで、`custom`ドライバータイプを指定してください。Monologインスンタンスを生成するために、呼び出すファクトリクラスを指定するために、`via`オプションを設定に含める必要があります。

    'channels' => [
        'custom' => [
            'driver' => 'custom',
            'via' => App\Logging\CreateCustomLogger::class,
        ],
    ],

`custom`チャンネルを設定したら、Monologインスタンスを生成するクラスを定義する準備が整いました。このクラスはMonologインスタンスを返す、`__invoke`メソッドのみ必要です。

    <?php

    namespace App\Logging;

    use Monolog\Logger;

    class CreateCustomLogger
    {
        /**
         * カスタムMonologインスタンスの生成
         *
         * @param  array  $config
         * @return \Monolog\Logger
         */
        public function __invoke(array $config)
        {
            return new Logger(...);
        }
    }
