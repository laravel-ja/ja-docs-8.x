# Laravel Envoy

- [イントロダクション](#introduction)
- [インストール](#installation)
- [タスクの記述](#writing-tasks)
    - [タスク定義](#defining-tasks)
    - [複数サーバ](#multiple-servers)
    - [準備](#setup)
    - [変数](#variables)
    - [ストーリー](#stories)
    - [完了フック](#completion-hooks)
- [タスク実行](#running-tasks)
    - [タスク実行の確認](#confirming-task-execution)
- [通知](#notifications)
    - [Slack](#slack)
    - [Discord](#discord)
    - [Telegram](#telegram)

<a name="introduction"></a>
## イントロダクション

[Laravel Envoy](https://github.com/laravel/envoy)は、リモートサーバ上で実行する一般的なタスクを実行するためのツールです。[blade](/docs/{{version}}/blade)スタイルの構文を使用し、デプロイやArtisanコマンドなどのタスクを簡単に設定できます。現在、EnvoyはMacおよびLinuxオペレーティングシステムのみをサポートしています。ただし、Windowsサポートは[WSL2](https://docs.microsoft.com/en-us/windows/wsl/install-win10)を使用して実現できます。

<a name="installation"></a>
## インストール

まず、Composerパッケージマネージャーを使用してEnvoyをプロジェクトにインストールします。

    composer require laravel/envoy --dev

Envoyがインストールされると、Envoyバイナリはアプリケーションの`vendor/bin`ディレクトリで利用できるようになります。

    php vendor/bin/envoy

<a name="writing-tasks"></a>
## タスクの記述

<a name="defining-tasks"></a>
### タスク定義

タスクはEnvoyの基本的な設定要素です。タスクには、呼び出されたときにリモートサーバで実行する必要があるシェルコマンドを定義します。たとえば、アプリケーションのすべてのキューワーカーサーバで`php artisan queue:restart`コマンドを実行するタスクを定義できます。

すべてのEnvoyタスクは、アプリケーションのルートにある`Envoy.blade.php`ファイルで定義する必要があります。開始時に使えるサンプルを以下に示します。

```bash
@servers(['web' => ['user@192.168.1.1'], 'workers' => ['user@192.168.1.2']])

@task('restart-queues', ['on' => 'workers'])
    cd /home/user/example.com
    php artisan queue:restart
@endtask
```

ご覧のとおり、ファイルの先頭で`@servers`配列を定義しており、タスク宣言の`on`オプションを使用してこれらのサーバを参照できます。`@servers`宣言は常に1行に配置する必要があります。`@task`宣言内に、タスクが呼び出されたときにサーバ上で実行する必要のあるシェルコマンドを配置する必要があります。

<a name="local-tasks"></a>
#### ローカルタスク

サーバのIPアドレスを`127.0.0.1`として指定することにより、ローカルコンピューターでスクリプトを強制的に実行できます。

```bash
@servers(['localhost' => '127.0.0.1'])
```

<a name="importing-envoy-tasks"></a>
#### Envoyタスクのインポート

`@import`ディレクティブを使用すると、他のEnvoyファイルをインポートして、それらのストーリーとタスクを自身へ追加できます。ファイルをインポートすると、そのファイルに含まれるタスクを、自身のEnvoyファイルで定義されているかのように実行できます。

```bash
@import('vendor/package/Envoy.blade.php')
```

<a name="multiple-servers"></a>
### 複数サーバ

Envoyを使用すると、複数のサーバ間でタスクを簡単に実行できます。まず、`@servers`宣言にサーバを追加します。各サーバには一意の名前を割り当てる必要があります。追加のサーバを定義したら、タスクの`on`配列へ各サーバをリストします。

```bash
@servers(['web-1' => '192.168.1.1', 'web-2' => '192.168.1.2'])

@task('deploy', ['on' => ['web-1', 'web-2']])
    cd /home/user/example.com
    git pull origin {{ $branch }}
    php artisan migrate --force
@endtask
```

<a name="parallel-execution"></a>
#### 並列実行

デフォルトでは、タスクは各サーバで順次実行されます。つまり、タスクは、２番目のサーバでの実行に進む前に、最初のサーバでの実行を終了します。複数のサーバ間でタスクを並行して実行する場合は、タスク宣言に`parallel`オプションを追加します。

```bash
@servers(['web-1' => '192.168.1.1', 'web-2' => '192.168.1.2'])

@task('deploy', ['on' => ['web-1', 'web-2'], 'parallel' => true])
    cd /home/user/example.com
    git pull origin {{ $branch }}
    php artisan migrate --force
@endtask
```

<a name="setup"></a>
### 準備

Envoyタスクを実行する前に、任意のPHPコードを実行する必要がある場合があります。`@setup`ディレクティブを使用して、タスクの前に実行する必要があるPHPコードブロックを定義できます。

```php
@setup
    $now = new DateTime;
@endsetup
```

タスクを実行する前に他のPHPファイルをリクエストする必要がある場合は、`Envoy.blade.php`ファイルの先頭にある`@include`ディレクティブを使用できます。

```bash
@include('vendor/autoload.php')

@task('restart-queues')
    # ...
@endtask
```

<a name="variables"></a>
### 変数

必要に応じて、Envoyを呼び出すときにコマンドラインで引数を指定することにより、Envoyタスクに引数を渡すことができます。

    php vendor/bin/envoy run deploy --branch=master

Bladeの「エコー（echo）」構文を使用して、タスク内のオプションにアクセスできます。タスク内でBladeの`if`ステートメントとループを定義することもできます。例として`git pull`コマンドを実行する前に、`$branch`変数の存在を確認してみましょう。

```bash
@servers(['web' => ['user@192.168.1.1']])

@task('deploy', ['on' => 'web'])
    cd /home/user/example.com

    @if ($branch)
        git pull origin {{ $branch }}
    @endif

    php artisan migrate --force
@endtask
```

<a name="stories"></a>
### ストーリー

ストーリーは、一連のタスクを１つの便利な名前でグループ化します。たとえば、`deploy`ストーリーは、その定義内にタスク名をリストすることにより、`update-code`および`install-dependencies`タスクを実行できます。

```bash
@servers(['web' => ['user@192.168.1.1']])

@story('deploy')
    update-code
    install-dependencies
@endstory

@task('update-code')
    cd /home/user/example.com
    git pull origin master
@endtask

@task('install-dependencies')
    cd /home/user/example.com
    composer install
@endtask
```

ストーリーを作成したら、タスクの呼び出しと同じ方法でストーリーを呼び出せます。

    php vendor/bin/envoy run deploy

<a name="completion-hooks"></a>
### 完了フック

タスクとストーリーが終了すると、いくつかのフックが実行されます。Envoyがサポートしているフックタイプは`@after`、`@error`、`@success`、`@finished`です。これらのフック内のすべてのコードはPHPとして解釈され、ローカルで実行されます。タスクが操作するリモートサーバ上では実行されません。

好きなようにこれらのフックを好きなだけ定義できます。それらはEnvoyスクリプトに現れる順序で実行されます。

<a name="completion-after"></a>
#### `@after`

各タスクの実行の後、Envoyスクリプト中で登録したすべての`@after`フックが実行されます。`@after`フックは、実行したタスクの名前を受け取ります。

```php
@after
    if ($task === 'deploy') {
        // ...
    }
@endafter
```

<a name="completion-error"></a>
#### `@error`

すべてのタスクが失敗した（ステータスコードが`0`より大きかった）場合、Envoyスクリプトに登録されているすべての`@error`フックが実行されます。`@error`フックは実行したタスクの名前を受け取ります。

```php
@error
    if ($task === 'deploy') {
        // ...
    }
@enderror
```

<a name="completion-success"></a>
#### `@success`

すべてのタスクがエラーなしで実行された場合は、Envoyスクリプトで登録したすべての`@success`フックが実行されます。

```bash
@success
    // ...
@endsuccess
```

<a name="completion-finished"></a>
#### `@finished`

すべてのタスクが実行された後(終了ステータスに関係なく)、すべての`@finished`フックが実行されます。`@finished`フックは`null`か`0`以上の`integer`を終了したタスクのステータスコードとして受け取ります。

```bash
@finished
    if ($exitCode > 0) {
        // １つのタスクにエラーがあった
    }
@endfinished
```

<a name="running-tasks"></a>
## タスク実行

アプリケーションの`Envoy.blade.php`ファイルで定義されているタスクまたはストーリーを実行するには、Envoyの`run`コマンドを実行し、実行するタスクまたはストーリーの名前を渡します。Envoyはタスクを実行し、タスクの実行中にリモートサーバからの出力を表示します。

    php vendor/bin/envoy run deploy

<a name="confirming-task-execution"></a>
### タスク実行の確認

サーバで特定のタスクを実行する前に確認を求めるプロンプトを表示する場合は、タスク宣言に`confirm`ディレクティブを追加します。このオプションは、破壊的な操作で特に役立ちます。

```bash
@task('deploy', ['on' => 'web', 'confirm' => true])
    cd /home/user/example.com
    git pull origin {{ $branch }}
    php artisan migrate
@endtask
```

<a name="notifications"></a>
## 通知

<a name="slack"></a>
### Slack

Envoyは、各タスクの実行後に[Slack](https://slack.com)への通知送信をサポートしています。`@slack`ディレクティブは、SlackフックURLとチャネル/ユーザー名を受け入れます。Slackのコントロールパネルで"Incoming WebHooks"統合を作成し、WebフックURLを取得してください。

`@slack`ディレクティブに指定する最初の引数に、WebフックURL全体を渡す必要があります。`@slack`ディレクティブの２番目の引数は、チャネル名(`#channel`)またはユーザー名(`@user`)です。

    @finished
        @slack('webhook-url', '#bots')
    @endfinished

デフォルトでEnvoy の通知は、実行したタスクを説明するメッセージを通知チャネルに送信します。しかし、`@slack` ディレクティブに第三引数を渡すことで、このメッセージを自分のカスタムメッセージで上書きすることができます。

    @finished
        @slack('webhook-url', '#bots', 'Hello, Slack.')
    @endfinished

<a name="discord"></a>
### Discord

Envoyは、各タスクの実行後の[Discord](https://discord.com)への通知送信もサポートしています。`@discord`ディレクティブは、DiscordフックのURLとメッセージを受け入れます。サーバ設定で"Webhook"を作成し、Webフックが投稿するチャンネルを選択することで、WebフックURLを取得できます。WebフックURL全体を`@discord`ディレクティブに渡す必要があります。

    @finished
        @discord('discord-webhook-url')
    @endfinished

<a name="telegram"></a>
### Telegram

Envoyは、各タスクの実行後の[Telegram](https://telegram.org)への通知送信もサポートしています。`@telegram`ディレクティブは、TelegramボットIDとチャットIDを受け入れます。[BotFather](https://t.me/botfather)を使用して新しいボットを作成することにより、ボットIDを取得できます。[@username_to_id_bot](https://t.me/username_to_id_bot)を使用して有効なチャットIDを取得できます。ボットIDとチャットID全体を`@telegram`ディレクティブに渡す必要があります。

    @finished
        @telegram('bot-id','chat-id')
    @endfinished
