# アップグレードガイド

- [7.xから8.0へのアップグレード](#upgrade-8.0)

<a name="high-impact-changes"></a>
## 重要度の高い変更

<div class="content-list" markdown="1">
- [モデルファクトリ](#model-factories)
- [キュー`retryAfter`メソッド](#queue-retry-after-method)
- [キュー`timeoutAt`プロパティ](#queue-timeout-at-property)
- [キュー`allOnQueue`／`allOnConnection`](#queue-allOnQueue-allOnConnection)
- [ペジネーションデフォルト](#pagination-defaults)
- [シーダとファクトリの名前空間](#seeder-factory-namespaces)
</div>

<a name="medium-impact-changes"></a>
## 重要度が中程度の変更

<div class="content-list" markdown="1">
- [PHP 7.3.0 Required](#php-7.3.0-required)
- [失敗したジョブテーブルのバッチサポート](#failed-jobs-table-batch-support)
- [メンテナンスモードアップデート](#maintenance-mode-updates)
- [`php artisan down --message`オプション](#artisan-down-message)
- [`assertExactJson`メソッド](#assert-exact-json-method)
</div>

<a name="upgrade-8.0"></a>
## 7.xから8.0へのアップグレード

<a name="estimated-upgrade-time-15-minutes"></a>
#### アップグレード見積もり時間：１５分

> {note} 私達は、互換性を失う可能性がある変更を全部ドキュメントにしようとしています。しかし、変更点のいくつかは、フレームワークの明確ではない部分で行われているため、一部の変更が実際にアプリケーションに影響を与えてしまう可能性があります。

<a name="php-7.3.0-required"></a>
### 動作条件：PHP7.3.0

**影響の可能性： 中程度**

新しく必要なPHPの最低バージョンが7.3.0になりました。

<a name="updating-dependencies"></a>
### 依存パッケージのアップデート

`composer.json`ファイル中に指定されている以下のパッケージ依存を更新してください。

<div class="content-list" markdown="1">
- `guzzlehttp/guzzle`を`^7.0.1`へ
- `facade/ignition`を`^2.3.6`へ
- `laravel/framework`を`^8.0`へ
- `laravel/ui`を`^3.0`へ
- `nunomaduro/collision`を`^5.0`へ
- `phpunit/phpunit`を`^9.0`へ
</div>

以下のファーストパーティパッケージは、Laravel8をサポートするために、新しくメジャーバージョンになりました。該当するパッケージを使用している場合、アップグレードを行う前に、各アップグレードガイドを読んでください。

<div class="content-list" markdown="1">
- [Horizon v5.0](https://github.com/laravel/horizon/blob/master/UPGRADE.md)
- [Passport v10.0](https://github.com/laravel/passport/blob/master/UPGRADE.md)
- [Socialite v5.0](https://github.com/laravel/socialite/blob/master/UPGRADE.md)
- [Telescope v4.0](https://github.com/laravel/telescope/blob/master/UPGRADE.md)
</div>

さらに、Laravelインストーラを`composer create-project`とLaravel Jetstreamをサポートするためにアップデートしました。4.0より古いインストーラは２０２０年の１０月以降動作停止します。グローバルインストーラを`^4.0`へすぐにアップデートしてください。

最後にアプリケーションで使用してる、その他のサードパーティパッケージを調べ、Laravel8をサポートしているバージョンを確実に使用しているかを検証してください。

<a name="collections"></a>
### コレクション

<a name="the-isset-method"></a>
#### `isset`メソッド

**影響の可能性： 低い**

典型的なPHPの動作と整合性をとるため、`Illuminate\Support\Collection`の`offsetExists`メソッドは`array_key_exists`の代わりに`isset`を使用するように変更しました。これにより値が`null`のコレクションアイテムを扱う際の挙動に変化が生じる可能性があります。

    $collection = collect([null]);

    // Laravel7.x - true
    isset($collection[0]);

    // Laravel8.x - false
    isset($collection[0]);

<a name="database"></a>
### Database

<a name="seeder-factory-namespaces"></a>
#### シーダとファクトリの名前空間

**影響の可能性： 高い**

シーダとファクトリは名前空間になりました。これらの変更に対応するには、`Database\Seeders`名前空間をシードクラスに追加します。さらに、以前の`database/seeds`ディレクトリの名前を`database/seeders`に変更する必要があります：

    <?php

    namespace Database\Seeders;

    use App\Models\User;
    use Illuminate\Database\Seeder;

    class DatabaseSeeder extends Seeder
    {
        /**
         * アプリケーションのデータベースの初期値設定
         *
         * @return void
         */
        public function run()
        {
            ...
        }
    }

`laravel/legacy-factories`パッケージを使用する場合は、ファクトリクラスを変更する必要はありません。ただし、ファクトリをアップグレードする場合は、それらのクラスに`Database\Factories`名前空間を追加する必要があります。

次に、`composer.json`ファイルで、`autoload`セクションから`classmap`ブロックを削除し、新しい名前空間クラス・ディレクトリマッピングを追加します。

    "autoload": {
        "psr-4": {
            "App\\": "app/",
            "Database\\Factories\\": "database/factories/",
            "Database\\Seeders\\": "database/seeders/"
        }
    },

<a name="eloquent"></a>
### Eloquent

<a name="model-factories"></a>
#### モデルファクトリ

**影響の可能性： 高い**

Laravelの[モデルファクトリ](/docs/{{version}}/database-testing＃creating-factories)機能は、クラスをサポートするように完全に書き直されており、Laravel7.xスタイルのファクトリとは互換性がありません。ただし、アップグレードプロセスを簡単にするために、新しい`laravel/legacy-factories`パッケージが作成され、Laravel 8.xで既存のファクトリを続けて使用できます。このパッケージはComposerでインストールできます。

    composer require laravel/legacy-factories

<a name="the-castable-interface"></a>
#### `Castable`インターフェイス

**影響の可能性： 低い**

`Castable`インターフェイスの`castUsing`メソッドは、引数の配列を引数に取るように更新されました。このインターフェイスを実装している場合は、それに応じて実装を更新する必要があります。

    public static function castUsing(array $arguments);

<a name="increment-decrement-events"></a>
#### Increment／Decrementイベント

**影響の可能性： 低い**

Eloquentモデルインスタンスで`increment`または` decrement`メソッドの実行時に"update"と"save"で適切な関連モデルイベントが発行されるようになりました。

<a name="events"></a>
### イベント

<a name="the-dispatcher-contract"></a>
#### `Dispatcher`契約

**影響の可能性： 低い**

`Illuminate\Contracts\Events\Dispatcher`契約の`listen`メソッドを変更し、`$listener`プロパティをオプションにしました。この変更は、リフレクションを介して処理されるイベントタイプの自動検出をサポートするために行いました。このインターフェイスを自分で実装している場合は、対応する実装を更新する必要があります。

    public function listen($events, $listener = null);

<a name="framework"></a>
### フレームワーク

<a name="maintenance-mode-updates"></a>
#### メンテナンスモードアップデート

**影響の可能性： 状況による**

Laravel8.xでは[メンテナンスモード](/docs/{{version}}/configuration＃maintenance-mode)機能が改善されています。メンテナンスモードテンプレートの事前レンダリングをサポートし、メンテナンスモード中にエンドユーザーがエラーに遭遇する可能性が少なくなりました。ただし、これをサポートするには、以降を`public/index.php`ファイルに追加しなくてはなりません。これらの行は既存の`LARAVEL_START`定数の定義直下に配置してください。

    define('LARAVEL_START', microtime(true));

    if (file_exists(__DIR__.'/../storage/framework/maintenance.php')) {
        require __DIR__.'/../storage/framework/maintenance.php';
    }

<a name="artisan-down-message"></a>
#### `php artisan down --message`オプション

**影響の可能性： 中程度**

`php artisan down`コマンドの` --message`オプションを削除しました。別の方法として、選択したメッセージで[メンテナンスモードビューの事前レンダリング]（/docs/{{version}}/configuration＃maintenance-mode）の使用を検討してください。

<a name="php-artisan-serve-no-reload-option"></a>
#### The `php artisan serve --no-reload` Option

**影響の可能性： 低い**

`php artisanserve`コマンドに` --no-reload`オプションを追加しました。これにより、環境ファイルの変更が検出されたときにサーバをリロードしないように組み込みサーバに指示できます。このオプションは主にCI環境でLaravelDuskテストを実行するときに役立ちます。

<a name="manager-app-property"></a>
#### `$app`プロパティマネージャー

**影響の可能性： 低い**

以前非推奨になった `Illuminate\Support\Manager`クラスの`$app`プロパティを削除しました。このプロパティに依存している場合は、代わりに`$container`プロパティを使用してください。

<a name="the-elixir-helper"></a>
#### `elixir`ヘルパ

**影響の可能性： 低い**

以前に非推奨にした、`elixir`ヘルパを削除しました。このメソッドをまだ使用しているアプリケーションは、[Laravel Mix](https://github.com/JeffreyWay/laravel-mix)にアップグレードすることをお勧めします

<a name="mail"></a>
### メール

<a name="the-sendnow-method"></a>
#### `sendNow`メソッド

**影響の可能性： 低い**

以前非推奨にした、`sendNow`メソッドを削除しました。代わりに、`send`メソッドを使用してください。

<a name="pagination"></a>
### ペジネーション

<a name="pagination-defaults"></a>
#### ペジネーションデフォルト

**影響の可能性： 高い**

ペジネータは、デフォルトのスタイルに[Tailwind CSSフレームワーク](https://tailwindcss.com)を使用するようにしました。Bootstrapを使い続けるには、以降のメソッド呼び出しをアプリケーションの`AppServiceProvider`の`boot`メソッドに追加してください。

    use Illuminate\Pagination\Paginator;

    Paginator::useBootstrap();

<a name="queue"></a>
### キュー

<a name="queue-retry-after-method"></a>
#### `retryAfter`メソッド

**影響の可能性： 高い**

Laravelの他の機能との整合性を保つため、キュー投入したジョブ、メーラ、通知、リスナの`retryAfter`メソッドと`retryAfter`プロパティは、`backoff`に改名しました。アプリケーションの関連クラスで、このメソッドとプロパティの名前を変更してください。

<a name="queue-timeout-at-property"></a>
#### `timeoutAt`プロパティ

**影響の可能性： 高い**

キュー投入したジョブ、通知、リスナの`timeoutAt`プロパティの名前を`retryUntil`へ改名しました。アプリケーションの関連クラスで、このプロパティの名前を変更してください。

<a name="queue-allOnQueue-allOnConnection"></a>
#### `allOnQueue()`／`allOnConnection()`メソッド

**Likelihood Of Impact: High**

他のディスパッチメソッドとの一貫性を保つため、ジョブチェーンで使用されていた`allOnQueue()`メソッドと`allOnConnection()`メソッドを削除しました。代わりに、`onQueue()`メソッドと`onConnection()`メソッドを使用してください。これらのメソッドは、`dispatch`メソッドを呼び出す前に呼び出す必要があります。

    ProcessPodcast::withChain([
        new OptimizePodcast,
        new ReleasePodcast
    ])->onConnection('redis')->onQueue('podcasts')->dispatch();

この変更は、 `withChain`メソッドを使用するコードにのみ影響することに注意してください。グローバルな`dispatch()`ヘルパを使用している場合でも、`allOnQueue()`と`allOnConnection()`は引き続き使用できます。

<a name="failed-jobs-table-batch-support"></a>
#### 失敗したジョブテーブルのバッチサポート

**影響の可能性： 状況による**

Laravel8.xの[ジョブのバッチ処理](/docs/{{version}}/queues＃job-batching)機能を使用する場合は、`failed_jobs`データベーステーブルを更新する必要があります。最初に、新しい`uuid`列をテーブルに追加してください。

    use Illuminate\Database\Schema\Blueprint;
    use Illuminate\Support\Facades\Schema;

    Schema::table('failed_jobs', function (Blueprint $table) {
        $table->string('uuid')->after('id')->nullable()->unique();
    });

次に、`queue`設定ファイル内の`failed.driver`設定オプションを`database-uuids`に更新してください。

さらに、既存の失敗したジョブに対し、UUIDを生成できます。

    DB::table('failed_jobs')->whereNull('uuid')->cursor()->each(function ($job) {
        DB::table('failed_jobs')
            ->where('id', $job->id)
            ->update(['uuid' => (string) Illuminate\Support\Str::uuid()]);
    });

<a name="routing"></a>
### ルーティング

<a name="automatic-controller-namespace-prefixing"></a>
#### コントローラ名前空間の自動プレフィクス

**影響の可能性： 状況による**

以前のLaravelリリースでは、`RouteServiceProvider`クラスに`App\Http\Controllers`の値を持つ`$namespace`プロパティが存在していました。このプロパティの値は、コントローラルート定義とコントローラルートURL生成時に、`action`ヘルパを呼び出す際などに自動的にプレフィックスを付けるために使われていました。

Laravel8では、このプロパティをデフォルトで`null`に設定しています。これにより、コントローラのルート宣言でPHP標準callable構文を使用できるようになり、多くのIDEでコントローラクラスへのジャンプがより良くサポートされます。

    use App\Http\Controllers\UserController;

    // PHPのcallable記法
    Route::get('/users', [UserController::class, 'index']);

    // 文字列記法の使用
    Route::get('/users', 'App\Http\Controllers\UserController@index');

ほとんどの場合、`RouteServiceProvider`には以前の値の`$namespace`プロパティが含まれているため、アップグレードしているアプリケーションには影響がありません。しかし、新しいLaravelプロジェクトを作成し、アプリケーションをアップグレードした場合は、この重大な変更に遭遇するでしょう。

もとの自動プレフィクス付きコントローラルーティングを使い続けたい場合は、`RouteServiceProvider`内の `$namespace`プロパティの値を設定し、`boot`メソッド内のルート登録を`$namespace`プロパティを使用するように変更します。

    class RouteServiceProvider extends ServiceProvider
    {
        /**
         * アプリケーションの"home"ルートのパス
         *
         * ログイン後にユーザーをリダイレクトするため、Laravel認証が使用する
         *
         * @var string
         */
        public const HOME = '/home';

        /**
         * 指定されている場合、コントローラルートへ自動的に適用される名前空間
         *
         * さらに、URLジェネレータのルート名前空間としてセット
         *
         * @var string
         */
        protected $namespace = 'App\Http\Controllers';

        /**
         * ルートモデル結合、パターンフィルタなどを定義
         *
         * @return void
         */
        public function boot()
        {
            $this->configureRateLimiting();

            $this->routes(function () {
                Route::middleware('web')
                    ->namespace($this->namespace)
                    ->group(base_path('routes/web.php'));

                Route::prefix('api')
                    ->middleware('api')
                    ->namespace($this->namespace)
                    ->group(base_path('routes/api.php'));
            });
        }

        /**
         * アプリケーションのレート制限の設定
         *
         * @return void
         */
        protected function configureRateLimiting()
        {
            RateLimiter::for('api', function (Request $request) {
                return Limit::perMinute(60);
            });
        }
    }

<a name="scheduling"></a>
### スケジュール

<a name="the-cron-expression-library"></a>
#### `cron-expression`ライブラリ

**影響の可能性： 低い**

Laravelの依存パッケージである`dragonmantank/cron-expression`が、`2.x`から`3.x`へ更新されました。これにより、`cron-expression`ライブラリと直接操作していない限り、アプリケーションが壊れるような変化は起こらないはずです。このライブラリを直接やりとりする場合は、[変更ログ](https://github.com/dragonmantank/cron-expression/blob/master/CHANGELOG.md)を確認してください。

<a name="session"></a>
### セッション

<a name="the-session-contract"></a>
#### `Session`契約

**影響の可能性： 低い**

`IlluminateContracts\Session\SessionSession` 契約に新しい`pull`メソッドを追加しました。自分で実装している場合は、これに合わせて実装を更新してください。

    /**
     * 指定キーの値を取得し、次に削除
     *
     * @param  string  $key
     * @param  mixed  $default
     * @return mixed
     */
    public function pull($key, $default = null);

<a name="testing"></a>
### テスト

<a name="decode-response-json-method"></a>
#### `decodeResponseJson`メソッド

**影響の可能性： 低い**

`Illuminate\Testing\TestResponse`クラスに属する`decodeResponseJson`メソッドは、引数を取らなくなりました。代わりに`json`メソッドの使用を検討してください。

<a name="assert-exact-json-method"></a>
#### `assertExactJson`メソッド

**影響の可能性： 中程度**

`assertExactJson`メソッドは、比較する配列の数値キーが一致し、同じ順序であることを必要とするようになりました。配列の数値キーの順序を同じにすることなく、JSONを配列と比較したい場合は代わりに`assertSimilarJson`メソッドが使用できます。

<a name="validation"></a>
### バリデーション

<a name="database-rule-connections"></a>
### データベースルールの接続

**影響の可能性： 低い**

`unique` および `exists` ルールはクエリを実行する際に、Eloquentモデルで指定した(モデルの`getConnectionName`メソッドによりアクセスした)接続名を尊重するようになりました。

<a name="miscellaneous"></a>
### その他

`laravel/laravel`の[GitHubリポジトリ](https://github.com/laravel/laravel)で、変更を確認することを推奨します。これらの変更は必須でありませんが、皆さんのアプリケーションではファイルの同期を保つほうが良いでしょう。変更のいくつかは、このアップグレードガイドで取り扱っていますが、設定ファイルやコメントなどの変更は取り扱っていません。変更は簡単に[GitHubの比較ツール](https://github.com/laravel/laravel/compare/7.x...master)で閲覧でき、みなさんにとって重要な変更を選択できます。
