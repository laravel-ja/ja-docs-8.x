# ディレクトリ構造

- [イントロダクション](#introduction)
- [プロジェクトディレクトリ](#the-root-directory)
    - [appディレクトリ](#the-root-app-directory)
    - [bootstrapディレクトリ](#the-bootstrap-directory)
    - [configディレクトリ](#the-config-directory)
    - [databaseディレクトリ](#the-database-directory)
    - [publicディレクトリ](#the-public-directory)
    - [resourcesディレクトリ](#the-resources-directory)
    - [routesディレクトリ](#the-routes-directory)
    - [storageディレクトリ](#the-storage-directory)
    - [testsディレクトリ](#the-tests-directory)
    - [vendorディレクトリ](#the-vendor-directory)
- [Appディレクトリ](#the-app-directory)
    - [Broadcastingディレクトリ](#the-broadcasting-directory)
    - [Consoleディレクトリ](#the-console-directory)
    - [Eventsディレクトリ](#the-events-directory)
    - [Exceptionsディレクトリ](#the-exceptions-directory)
    - [Httpディレクトリ](#the-http-directory)
    - [Jobsディレクトリ](#the-jobs-directory)
    - [Listenersディレクトリ](#the-listeners-directory)
    - [Mailディレクトリ](#the-mail-directory)
    - [The `Models` Directory](#the-models-directory)
    - [Notificationsディレクトリ](#the-notifications-directory)
    - [Policiesディレクトリ](#the-policies-directory)
    - [Providersディレクトリ](#the-providers-directory)
    - [Rulesディレクトリ](#the-rules-directory)

<a name="introduction"></a>
## イントロダクション

Laravelのデフォルトアプリケーション構造はアプリケーションの大小にかかわらず、素晴らしいスタートを切ってもらえることを意図しています。アプリケーションは皆さんのお好みに応じ、自由に体系立ててください。クラスがComposerによりオートローディングできるならば、Laravelはクラスをどこに配置するか強制することはまずありません。

<a name="the-root-directory"></a>
## プロジェクトディレクトリ

<a name="the-root-app-directory"></a>
#### appディレクトリ

`app`ディレクトリは、アプリケーションのコアコードを配置します。このフォルダの詳細は、この後に説明します。しかし、アプリケーションのほとんど全部のクラスは、このディレクトリの中に設定されることを覚えておいてください。

<a name="the-bootstrap-directory"></a>
#### bootstrapディレクトリ

`bootstrap`フォルダは、フレームワークの初期処理を行う`app.php`ファイルを含んでいます。その中の`cache`ディレクトリは、初期処理のパフォーマンスを最適化するため、フレームワークが生成するルートやサービスのキャッシュファイルが保存されるフォルダです。

<a name="the-config-directory"></a>
#### configディレクトリ

`config`ディレクトリは名前が示す通り、アプリケーションの全設定ファイルが設置されています。全ファイルに目を通し、設定可能なオプションに慣れ親しんでおくのは良い考えでしょう。

<a name="the-database-directory"></a>
#### databaseディレクトリ

`database`フォルダはデータベースのマイグレーションとモデルファクトリ、初期値設定（シーディング）を配置します。ご希望であれば、このディレクトリをSQLiteデータベースの設置場所としても利用できます。

<a name="the-public-directory"></a>
#### publicディレクトリ

`public`ディレクトリには、アプリケーションへの全リクエストの入り口となり、オートローディングを設定する`index.php`ファイルがあります。また、このディレクトリにはアセット（画像、JavaScript、CSSなど）を配置します。

<a name="the-resources-directory"></a>
#### resourcesディレクトリ

`resources`ディレクトリはCSS、JavaScriptなどのビューやアセットの元ファイルで構成されています。また、すべての言語ファイルも配置します。

<a name="the-routes-directory"></a>
#### routesディレクトリ

ディレクトリはアプリケーションの全ルート定義により構成されています。デフォルトでは、`web.php`、`api.php`、`console.php`、`channels.php`ファイルが含まれています。

`web.php`ファイルは、`RouteServiceProvider`の`web`ミドルウェアグループに属するルートで構成します。このミドルウェアは、セッションステート、CSRF保護、クッキーの暗号化機能を提供しています。もしアプリケーションがステートレスではなく、RESTフルなAPIを提供しないのであれば、すべてのルートは`web.php`ファイルの中で定義されることになるでしょう。

`api.php`ファイルは、`RouteServiceProvider`の`api`ミドルウェアグループに属するルートで構成します。このミドルウェアはアクセス回数制限を提供しています。このファイル中で定義されるルートは、ステートレスであることを意図しています。つまり、これらのルートを通るアプリケーションに対するリクエストは、セッションステートにアクセスする必要がないように、トークンを使って認証されることを意図しています。

`console.php`ファイルは、クロージャベースの全コンソールコマンドを定義する場所です。それぞれのコマンドのIOメソッドと連携するシンプルなアプローチを提供するコマンドインスタンスと、各クロージャは結合します。厳密に言えば、このファイルでHTTPルートは定義していないのですが、コンソールベースのエントリポイントを定義しているという点で、ルート定義なのです。

`channels.php`ファイルはアプリケーションでサポートする、全ブロードキャストチャンネルを登録する場所です。

<a name="the-storage-directory"></a>
#### storageディレクトリ

`storage`ディレクトリにはコンパイルされたBladeテンプレート、ファイルベースのセッション、ファイルキャッシュなど、フレームワークにより生成されるファイルが保存されます。このフォルダは`app`、`framework`、`logs`ディレクトリに分かれています。`app`ディレクトリはアプリケーションにより生成されるファイルを保存するために利用します。`framework`ディレクトリはフレームワークが生成するファイルやキャッシュに利用されます。最後の`logs`ディレクトリはアプリケーションのログファイルが保存されます。

`storage/app/public`ディレクトリにはプロファイルのアバターなどのようなユーザーにより生成され、外部からアクセスされるファイルが保存されます。`public/storage`がこのディレクトリを指すように、シンボリックリンクを張る必要があります。リンクは、`php artisan storage:link`コマンドを使い生成できます。

<a name="the-tests-directory"></a>
#### testsディレクトリ

`tests`ディレクトリには皆さんの自動テストを配置します。サンプルの[PHPUnit](https://phpunit.de/)テストが最初に含まれています。各テストクラスはサフィックスとして`Test`を付ける必要があります。テストは`phpunit`か、`php vendor/bin/phpunit`コマンドにより実行できます。

<a name="the-vendor-directory"></a>
#### vendorディレクトリ

`vendor`ディレクトリには、[Composer](https://getcomposer.org)による依存パッケージが配置されます。

<a name="the-app-directory"></a>
## appディレクトリ

アプリケーションの主要な部分は、`app`ディレクトリ内に配置します。このディレクトリはデフォルトで、`App`名前空間のもとに置かれており、[PSR-4オートローディング規約](https://www.php-fig.org/psr/psr-4/)を使い、Composerがオートロードしています。

`app`ディレクトリは多様なサブディレクトリを持っています。`Console`、`Http`、`Providers`などです。`Console`と`Http`ディレクトリは、アプリケーションの「コア」へAPIを提供していると考えてください。HTTPプロトコルとCLIは両方共にアプリケーションと相互に関係するメカニズムですが、実際のアプリケーションロジックではありません。言い換えれば、これらはアプリケーションに指示を出す、２つの方法に過ぎません。`Console`ディレクトリは全Artisanコマンドで構成され、一方の`Http`ディレクトリはコントローラやフィルター、リクエストにより構成されています。

クラス生成のための`make` Artisanコマンドを使用することで、さまざまなディレクトリが`app`ディレクトリ内に作成されます。たとえば、`app/Jobs`ディレクトリは、ジョブクラスを生成する`make:job` Artisanコマンドを実行するまで存在していません。

> {tip} Artisanコマンドにより、`app`ディレクトリ下にたくさんのクラスが生成されます。使用可能なコマンドを確認するには、`php artisan list make`コマンドをターミナルで実行してください。

<a name="the-broadcasting-directory"></a>
#### Broadcastingディレクトリ

`Broadcasting`ディレクトリは、アプリケーションの全ブロードキャストチャンネルクラスで構成します。これらのクラスは、`make:channel`コマンドで生成されます。このディレクトリはデフォルトでは存在しませんが、最初にチャンネルを生成したときに作成されます。チャンネルについての詳細は、[イベントブロードキャスト](/docs/{{version}}/broadcasting)のドキュメントで確認してください。

<a name="the-console-directory"></a>
#### Consoleディレクトリ

`Console`ディレクトリは、アプリケーションの全カスタムArtisanコマンドで構成します。これらのコマンドクラスは`make:command`コマンドにより生成されます。コンソールカーネルもこのディレクトリ内にあり、カスタムArtisanコマンドや、[タスクのスケジュール](/docs/{{version}}/scheduling)を登録します。

<a name="the-events-directory"></a>
#### Eventsディレクトリ

このディレクトリはデフォルトで存在していません。`event:generate`か`make:event` Artisanコマンド実行時に作成されます。`Events`ディレクトリは、[イベントクラス](/docs/{{version}}/events)を設置する場所です。イベントは特定のアクションが起きたことをアプリケーションの別の部分へ知らせるために使われ、柔軟性と分離性を提供しています。

<a name="the-exceptions-directory"></a>
#### Exceptionsディレクトリ

`Exceptions`ディレクトリはアプリケーションの例外ハンドラで構成します。また、アプリケーションから投げる例外を用意するにも適した場所でしょう。例外のログやレンダー方法をカスタマイズしたい場合は、このディレクトリの`Handler`クラスを修正してください。

<a name="the-http-directory"></a>
#### Httpディレクトリ

`Http`ディレクトリはコントローラ、ミドルウェア、フォームリクエストを設置します。アプリケーションへのリクエストを処理するロジックは、ほぼすべてこのディレクトリ内に設置します。

<a name="the-jobs-directory"></a>
#### Jobsディレクトリ

このディレクトリはデフォルトで存在していません。`make:job` Artisanコマンドを実行すると作成されます。`Jobs`ディレクトリはアプリケーションの[キュー投入可能なジョブ](/docs/{{version}}/queues)を置いておく場所です。`Jobs`はアプリケーションによりキューに投入されるか、もしくは現在のリクエストサイクル中に同期的に実行されます。現在のリクエストサイクル中に同期的に実行するジョブは、[コマンドパターン](https://en.wikipedia.org/wiki/Command_pattern)を実装しているため、時に「コマンド」と呼ばれることがあります。

<a name="the-listeners-directory"></a>
#### Listenersディレクトリ

このディレクトリはデフォルトで存在していません。`event:generate`か`make:listener` Artisanコマンドを実行すると、作成されます。`Listeners`ディレクトリには、[events](/docs/{{version}}/events)イベントを処理するクラスを設置します。イベントリスナはイベントインスタンスを受け取り、発行されたイベントへ対応するロジックを実行します。たとえば、`UserRegistered`（ユーザー登録）イベントは、`SendWelcomeEmail`（ウェルカムメール送信）リスナにより処理されることになるでしょう。

<a name="the-mail-directory"></a>
#### Mailディレクトリ

このディレクトリはデフォルトでは存在していません。`make:mail` Artisanコマンドを実行すると、作成されます。`Mail`ディレクトリは、アプリケーションから送信されるメールを表す全クラスで構成します。メールオブジェクトにより、`Mail::send`メソッドを使用して送られるメールを組み立てるロジックをすべて、１つのシンプルなクラスへカプセル化できます。

<a name="the-models-directory"></a>
#### Modelsディレクトリ

`Models`ディレクトリはすべてのEloquentモデルクラスで構成します。Laravelが持っているEloquent ORMは、データベースを操作するための美しくシンプルなActiveRecordの実装を提供しています。各データベーステーブルには、そのテーブルを操作するために使用する、対応した「モデル」があります。モデルを使用するとテーブルのデータをクエリしたり、テーブルに新しいレコードを挿入したりできます。

<a name="the-notifications-directory"></a>
#### Notificationsディレクトリ

このディレクトリはデフォルトでは存在していません。`make:notification` Artisanコマンドを実行すると作成されます。`Notifications`ディレクトリは、アプリケーションから送られる全「業務上」の通知、たとえばアプリケーションの中でイベントが発生したことを知らせるシンプルな通知などで構成します。Laravelの通知機能は、メール、Slack、SMS、データベースへの保存などのように、さまざまなドライバに対する通知の送信を抽象化しています。

<a name="the-policies-directory"></a>
#### Policiesディレクトリ

このディレクトリはデフォルトでは存在していません。`make:policy` Artisanコマンドを実行すると、作成されます。`Policies`ディレクトリにはアプリケーションの認可ポリシークラスを設置します。ポリシーは、リソースに対し指定したアクションをユーザーが実行できるかを決定します。詳細は、[認可のドキュメント](/docs/{{version}}/authorization)をご覧ください。

<a name="the-providers-directory"></a>
#### Providersディレクトリ

`Providers`ディレクトリは、アプリケーションの全[サービスプロバイダ](/docs/{{version}}/providers)により構成します。サービスプロバイダは、サービスをコンテナと結合、イベントの登録、もしくはアプリケーションへやってくるリクエストを処理するために必要な用意をするタスクを実行するなど、アプリケーションの事前準備を行います。

インストール直後のアプリケーションでも、このディレクトリは多くのプロパイダーを含んでいます。必要に応じて、自分のプロバイダを自由に追加してください。

<a name="the-rules-directory"></a>
#### Rulesディレクトリ

このディレクトリは、デフォルトでは存在していません。`make:rule` Artisanコマンドを実行すると、作成されます。`Rules`ディレクトリは、アプリケーションが使用するバリデーションルールオブジェクトで構成します。ルールは複雑なバリデーションロジックをシンプルなオブジェクトへカプセル化するために使用します。詳細は、[バリデーションのドキュメント](/docs/{{version}}/validation)で確認してください。
