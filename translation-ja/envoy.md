# Laravel Envoy

- [イントロダクション](#introduction)
    - [インストール](#installation)
- [タスク記述](#writing-tasks)
    - [準備](#setup)
    - [変数](#variables)
    - [ストーリー](#stories)
    - [複数サーバ](#multiple-servers)
- [タスク実行](#running-tasks)
    - [タスク実行の確認](#confirming-task-execution)
- [通知](#notifications)
    - [Slack](#slack)
    - [Discord](#discord)
    - [Telegram](#telegram)

<a name="introduction"></a>
## イントロダクション

[Laravel Envoy](https://github.com/laravel/envoy)（使節）はリモートサーバ間で共通のタスクを実行するために、美しく最小限の記法を提供します。デプロイやArtisanコマンドなどのタスクをBlade記法により簡単に準備できます。EnvoyはMacとLinuxのオペレーションシステムのみサポートしています。

<a name="installation"></a>
### インストール

最初にEnvoyをComposerの`global require`コマンドでインストールします。

    composer global require laravel/envoy

グローバルComposerライブラリは、ときどきパッケージバージョンのコンフリクトを起こすため、`composer global require`コマンドの代替として、`cgr`の使用を考慮してください。`cgr`ライブラリのインストール方法は、[GitHubで見つけられます](https://github.com/consolidation-org/cgr)。

> {note} `envoy`コマンドを端末で実行するときに`envoy`の実行ファイルが見つかるように`$HOME/.config/composer/vendor/bin`、もしくは`$HOME/.composer/vendor/bin`ディレクトリに実行パスを通しておくのを忘れないでください。

<a name="updating-envoy"></a>
#### Envoyの更新

インストールしたEnvoyをアップデートするためにも、Composerを使用します。`composer global update`コマンドの実行により、インストール済みのグローバルComposerパッケージがすべてアップデートされます。

    composer global update

<a name="writing-tasks"></a>
## タスク記述

Envoyの全タスクはプロジェクトルートの`Envoy.blade.php`ファイルの中で定義します。最初に例を見てください。

    @servers(['web' => ['user@192.168.1.1']])

    @task('foo', ['on' => 'web'])
        ls -la
    @endtask

見ての通り、`@servers`の配列をファイルの最初で定義し、タスク定義の`on`オプションでそれらのサーバを参照できるようにしています。`@servers`ディレクティブは常に一行で指定してください。`@task`定義の中には、タスクが実行されるときにサーバで実行するBASHコードを記述します。

サーバのIPアドレスを`127.0.0.1`にすることで、強制的にスクリプトをローカルで実行できます。

    @servers(['localhost' => '127.0.0.1'])

<a name="setup"></a>
### 準備

タスクを実行する前に、PHPコードを評価する必要がある場合もあります。変数を宣言するために`@setup`ディレクティブを使用し、他のタスクが実行される前に通常のPHPを動作させます。

    @setup
        $now = new DateTime();

        $environment = isset($env) ? $env : "testing";
    @endsetup

タスク実行前に他のPHPライブラリを読み込む必要がある場合は、`Envoy.blade.php`ファイルの先頭で、`@include`ディレティブを使用してください。

    @include('vendor/autoload.php')

    @task('foo')
        # ...
    @endtask

ストーリーやタスクを取り込むため、他のEnvoyファイルをインポートすることもできます。インポートすればそれらのファイルのタスクをこのファイルで定義しているかのように実行できます。`@import`ディレクティブは`Envoy.blade.php`ファイルの先頭で指定してください。

    @import('package/Envoy.blade.php')

<a name="variables"></a>
### 変数

必要であれば、コマンドラインを使い、Envoyタスクへオプション値を渡すことができます。

    envoy run deploy --branch=master

オプションへはBladeの"echo"記法により、タスク中からアクセスできます。`if`文も使用できますし、タスク内で繰り返しも可能です。例として`git pull`コマンドを実行する前に、`$branch`の存在を確認してみましょう。

    @servers(['web' => '192.168.1.1'])

    @task('deploy', ['on' => 'web'])
        cd site

        @if ($branch)
            git pull origin {{ $branch }}
        @endif

        php artisan migrate
    @endtask

<a name="stories"></a>
### ストーリー

ストーリーにより、選択した小さなタスクを大きなタスクにまとめることができます。名前を付け、一連のタスクを一つにまとめます。一例としてタスク名をリストすることにより、`deploy`ストーリーを定義し、`git`と`composer`タスクを実行してみます。

    @servers(['web' => '192.168.1.1'])

    @story('deploy')
        git
        composer
    @endstory

    @task('git')
        git pull origin master
    @endtask

    @task('composer')
        composer install
    @endtask

ストーリーを書き上げたら、通常のタスクと同じように実行します。

    envoy run deploy

<a name="multiple-servers"></a>
### 複数サーバ

Envoyでは、複数のサーバに渡りタスクを実行するのも簡単です。最初に追加のサーバを`@servers`ディレクティブで指定してください。各サーバには一意な名前を割り当ててください。追加サーバを定義したら、タスクの`on`配列にサーバをリストするだけです。

    @servers(['web-1' => '192.168.1.1', 'web-2' => '192.168.1.2'])

    @task('deploy', ['on' => ['web-1', 'web-2']])
        cd site
        git pull origin {{ $branch }}
        php artisan migrate
    @endtask

<a name="parallel-execution"></a>
#### 並列実行

デフォルトでタスクは各サーバで順番に実行されます。つまり最初のサーバで実行を終えたら、次のサーバで実行されます。タスクを複数サーバで並列実行したい場合は、タスク宣言に`parallel`オプションを追加してください。

    @servers(['web-1' => '192.168.1.1', 'web-2' => '192.168.1.2'])

    @task('deploy', ['on' => ['web-1', 'web-2'], 'parallel' => true])
        cd site
        git pull origin {{ $branch }}
        php artisan migrate
    @endtask

<a name="running-tasks"></a>
## タスク実行

`Envoy.blade.php`ファイルのタスクやストーリーを実行するには、実行したいタスクかストーリーの名前を指定し、Envoyの`run`コマンドを実行します。Envoyはタスクを実行し、タスク実行中にサーバからの出力を表示します。

    envoy run deploy

<a name="confirming-task-execution"></a>
### タスク実行の確認

サーバ上の特定タスク実行前に、確認のプロンプトを出したい場合は、タスク宣言で`confirm`ディレクティブを追加してください。このオプションは、破壊的な操作を行う場合にとくに便利です。

    @task('deploy', ['on' => 'web', 'confirm' => true])
        cd site
        git pull origin {{ $branch }}
        php artisan migrate
    @endtask

<a name="notifications"></a>
## 通知

<a name="slack"></a>
### Slack

Envoyは各タスク実行後の、[Slack](https://slack.com)への通知もサポートしています。`@slack`ディレクティブは、SlackフックURLとチャンネル名を引数に取ります。WebフックURLは、Slackコントロールパネルで"Incoming WebHooks"統合を作成することにより、作成されます。WebフックURL全体を`@slack`ディレクティブへ渡してください。

    @finished
        @slack('webhook-url', '#bots')
    @endfinished

チャンネル引数には以下のどちらかを指定します。

<div class="content-list" markdown="1">
- チャンネルに通知するには： `#channel`
- ユーザーに通知するには： `@user`
</div>

<a name="discord"></a>
### Discord

Envoyは各タスク実行後の、[Discord](https://discord.com)への通知もサポートしています。`@discord`ディレクティブは、DiscordフックURLとメッセージを引数に取ります。Server Settingで"Webhook"を作成し、どのチャンネルにポストするのかを選べば、WebフックURLが取得できます。WebフックURL全体を`@discode`ディレクティブへ渡してください。

    @finished
        @discord('discord-webhook-url')
    @endfinished

<a name="telegram"></a>
### Telegram

Envoyは各タスク終了後に[Telegram](https://telegram.org)への通知送信もサポートしています。`@telegram`ディレクティブはTelegram Bot IDとチャットIDを引数に取ります。[BotFather](https://t.me/botfather)を使用して新しいBotを作成し、Bot IDを取得できます。[@username_to_id_bot](https://t.me/username_to_id_bot)を使用し、有効なチャットIDを取得できます。Bot IDとチャットID全体を`@telegram`ディレクティブへ渡してください。

    @finished
        @telegram('<bot-id>','<chat-id>')
    @endfinished
