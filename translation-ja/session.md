# HTTPセッション

- [イントロダクション](#introduction)
    - [設定](#configuration)
    - [ドライバの事前要件](#driver-prerequisites)
- [セッションの使用](#using-the-session)
    - [データ取得](#retrieving-data)
    - [データ保存](#storing-data)
    - [フラッシュデータ](#flash-data)
    - [データ削除](#deleting-data)
    - [セッションIDの再生成](#regenerating-the-session-id)
- [セッションのブロック](#session-blocking)
- [カスタムセッションドライバの追加](#adding-custom-session-drivers)
    - [ドライバの実装](#implementing-the-driver)
    - [ドライバの登録](#registering-the-driver)

<a name="introduction"></a>
## イントロダクション

HTTP駆動のアプリケーションはステートレスのため、リクエスト間に渡りユーザーに関する情報を保存するセッションが提供されています。Laravelは記述的で統一されたAPIを使えるさまざまなバックエンドのセッションを用意しています。人気のある[Memcached](https://memcached.org)や[Redis](https://redis.io)、データベースも始めからサポートしています。

<a name="configuration"></a>
### 設定

セッションの設定は`config/session.php`にあります。このファイルのオプションには詳しくコメントがついていますので確認してください。ほとんどのアプリケーションでうまく動作できるように、Laravelは`file`セッションドライバをデフォルトとして設定しています。

セッションドライバ(`driver`)はリクエスト毎のセッションデータをどこに保存するかを決めます。Laravelには最初から素晴らしいドライバが用意されています。

<div class="content-list" markdown="1">
- `file` - セッションは`storage/framework/sessions`に保存されます。
- `cookie` - セッションは暗号化され安全なクッキーに保存されます。
- `database` - セッションはリレーショナルデータベースへ保存されます。
- `memcached`／`redis` - セッションはスピードの早いキャッシュベースの保存域に保存されます。
- `array` - セッションはPHPの配列として保存されるだけで、リクエスト間で継続しません。
</div>

> {tip} セッションデータを持続させないため、arrayドライバは通常[テスト](/docs/{{version}}/testing)時に使用します。

<a name="driver-prerequisites"></a>
### ドライバの事前要件

<a name="database"></a>
#### データベース

`database`セッションドライバを使う場合、セッションアイテムを含むテーブルを作成する必要があります。以下にこのテーブル宣言のサンプル「スキーマ」を示します。

    Schema::create('sessions', function ($table) {
        $table->string('id')->unique();
        $table->foreignId('user_id')->nullable();
        $table->string('ip_address', 45)->nullable();
        $table->text('user_agent')->nullable();
        $table->text('payload');
        $table->integer('last_activity');
    });

`session:table` Artisanコマンドを使えば、このマイグレーションが生成できます。

    php artisan session:table

    php artisan migrate

<a name="redis"></a>
#### Redis

RedisセッションをLaravelで使用する前に、PECLによりPhpRedis PHP拡張、もしくはComposerで`predis/predis`パッケージ(~1.0)をインストールする必要があります。Redis設定の詳細は、[Laravelのドキュメント](/docs/{{version}}/redis#configuration)をご覧ください。

> {tip} `session`設定ファイルでは、`connection`オプションで、どのRedis接続をセッションで使用するか指定します。

<a name="using-the-session"></a>
## セッションの使用

<a name="retrieving-data"></a>
### データ取得

Laravelでセッションを操作するには、主に２つの方法があります。グローバルな`session`ヘルパを使用する方法と、コントローラメソッドにタイプヒントで指定できる`Request`インスタンスを経由する方法です。最初は`Request`インスタンスを経由する方法を見てみましょう。コントローラのメソッドに指定した依存インスタンスは、Laravelの[サービスコンテナにより](/docs/{{version}}/container)、自動的に注入されることを覚えておきましょう。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use Illuminate\Http\Request;

    class UserController extends Controller
    {
        /**
         * 指定されたユーザーのプロフィールを表示
         *
         * @param  Request  $request
         * @param  int  $id
         * @return Response
         */
        public function show(Request $request, $id)
        {
            $value = $request->session()->get('key');

            //
        }
    }

`get`メソッドでセッションから値を取り出すとき、第２引数にデフォルト値も指定できます。このデフォルト値は、セッションに指定したキーが存在していなかった場合に、返されます。`get`メソッドのデフォルト値に「クロージャ」を渡した場合に、要求したキーが存在しなければ、その「クロージャ」が実行され、結果が返されます。

    $value = $request->session()->get('key', 'default');

    $value = $request->session()->get('key', function () {
        return 'default';
    });

<a name="the-global-session-helper"></a>
#### sessionグローバルヘルパ

グローバルな`session` PHP関数で、セッションからデータを出し入れすることもできます。`session`ヘルパが文字列ひとつだけで呼び出されると、そのセッションキーに対する値を返します。ヘルパがキー／値ペアの配列で呼び出されると、それらの値はセッションへ保存されます。

    Route::get('home', function () {
        // セッションから一つのデータを取得する
        $value = session('key');

        // デフォルト値を指定する場合
        $value = session('key', 'default');

        // セッションへ一つのデータを保存する
        session(['key' => 'value']);
    });

> {tip} セッションをHTTPリクエストインスタンスを経由する場合と、グローバルな`session`ヘルパを使用する場合では、実践上の違いがあります。どんなテストケースであろうとも使用可能な、`assertSessionHas`メソッドを利用して、どちらの手法も[テスト可能](/docs/{{version}}/testing)です。

<a name="retrieving-all-session-data"></a>
#### 全セッションデータの取得

セッション中の全データを取得する場合は、`all`メソッドを使います。

    $data = $request->session()->all();

<a name="determining-if-an-item-exists-in-the-session"></a>
#### セッション中のアイテム存在を確認

セッションへ値が存在するか調べたい場合は、`has`メソッドを使います。その値が存在し、`null`でない場合は`true`が返ります。

    if ($request->session()->has('users')) {
        //
    }

セッション中に、たとえ値が`null`であろうとも存在していることを確認したい場合は、`exists`メソッドを使います。`exists`メソッドは、値が存在していれば`true`を返します。

    if ($request->session()->exists('users')) {
        //
    }

<a name="storing-data"></a>
### データ保存

セッションへデータを保存する場合、通常`put`メソッドか、`session`ヘルパを使用します。

    // リクエストインスタンス経由
    $request->session()->put('key', 'value');

    // グローバルヘルパ使用
    session(['key' => 'value']);

<a name="pushing-to-array-session-values"></a>
#### 配列セッション値の追加

`push`メソッドは新しい値を配列のセッション値へ追加します。たとえば`user.teams`キーにチーム名の配列が含まれているなら、新しい値を次のように追加できます。

    $request->session()->push('user.teams', 'developers');

<a name="retrieving-deleting-an-item"></a>
#### 取得後アイテムを削除

`pull`メソッド一つで、セッションからアイテムを取得後、削除できます。

    $value = $request->session()->pull('key', 'default');

<a name="flash-data"></a>
### フラッシュデータ

次のリクエスト間だけセッションにアイテムを保存したいことがあります。`flash`メソッドを使ってください。`flash`メソッドは現在と直後のHTTPリクエストの間だけ、セッションにデータを保存し、それ以降は削除します。フラッシュデータは主にステータスメッセージなど、持続しない情報に便利です。

    $request->session()->flash('status', 'Task was successful!');

フラッシュデータをその先のリクエストまで持続させたい場合は、`reflash`メソッドを使い、全フラッシュデータを次のリクエストまで持続させられます。特定のフラッシュデータのみ持続させたい場合は、`keep`メソッドを使います。

    $request->session()->reflash();

    $request->session()->keep(['username', 'email']);

<a name="deleting-data"></a>
### データ削除

`forget`メソッドでセッションからデータを削除できます。セッションから全データを削除したければ、`flush`メソッドが使用できます。

    // １キーを削除
    $request->session()->forget('key');

    // 複数キーを削除
    $request->session()->forget(['key1', 'key2']);

    $request->session()->flush();

<a name="regenerating-the-session-id"></a>
### セッションIDの再生成

セッションIDの再生成は多くの場合、悪意のあるユーザーからの、アプリケーションに対する[session fixation](https://owasp.org/www-community/attacks/Session_fixation)攻撃を防ぐために行います。

[Laravel Jetstream](https://jetstream.laravel.com)（[和訳](/jetstream/1.0/ja/introduction.html)）を使用していれば、認証中にセッションIDは自動的に再生成されます。しかし、セッションIDを任意に再生成する必要があるのでしたら、`regenerate`メソッドを使ってください。

    $request->session()->regenerate();

<a name="session-blocking"></a>
## セッションのブロック

> {note} セッションのブロックを使用するには、[アトミックロック](/docs/{{version}}/cache#atomic-locks)をサポートするキャッシュドライバを使用する必用があります。現在、`memcached`、`dynamodb`、`redis`、`database`のキャッシュドライバがサポートしています。さらに、`cookie`セッションドライバは使用できません。

Laravelはデフォルトで同じセッションを使用するリクエストを同時に実行できます。そのため、たとえばJavaScript HTTPライブラリを使用してアプリケーションに2つのHTTPリクエストを送信すると、両方が同時に実行されます。多くのアプリケーションでは、これは問題ではありません。ただし、セッションデータの損失は、両方がセッションにデータを書き込む２つの異なるアプリケーションエンドポイントに、同時要求を行うアプリケーションの小さなサブセットで発生する可能性があります。

これを軽減するために、Laravelでは特定のセッションの同時リクエストを制限できる機能を提供します。開始するには、`block`メソッドをルート定義にチェーンするだけです。 この例では、`/profile`エンドポイントの受信リクエストがセッションロックを取得します。このロックが保持されている間、同じセッションIDを共有する`/profile`または`/order`エンドポイントへの受信リクエストは、最初のリクエストの実行が完了するのを待ってから、実行を続行します。

    Route::post('/profile', function () {
        //
    })->block($lockSeconds = 10, $waitSeconds = 10)

    Route::post('/order', function () {
        //
    })->block($lockSeconds = 10, $waitSeconds = 10)

`block`メソッドは２つのオプションの引数を取ります。`block`メソッドの最初の引数は、セッションロックを解放する前に保持する最大秒数です。もちろん、リクエストがこの時間より前に実行終了した場合、ロックをより早く解放します。

`block`メソッドの２番目の引数は、セッションロックを取得するときにリクエストが待つ秒数です。リクエストが指定秒数内にセッションロックを取得できない場合、`Illuminate\Contracts\Cache\LockTimoutException`が投げられます。

両引数のどちらも渡さない場合、ロックを最大１０秒間取得し、リクエストはロックを取得するまで最大１０秒間待ちます。

    Route::post('/profile', function () {
        //
    })->block()

<a name="adding-custom-session-drivers"></a>
## カスタムセッションドライバの追加

<a name="implementing-the-driver"></a>
#### ドライバの実装

カスタムセッションドライバでは、`SessionHandlerInterface`を実装してください。このインターフェイスには実装する必要のある、シンプルなメソッドが数個含まれています。MongoDBの実装をスタブしてみると、次のようになります。

    <?php

    namespace App\Extensions;

    class MongoSessionHandler implements \SessionHandlerInterface
    {
        public function open($savePath, $sessionName) {}
        public function close() {}
        public function read($sessionId) {}
        public function write($sessionId, $data) {}
        public function destroy($sessionId) {}
        public function gc($lifetime) {}
    }

> {tip} こうした拡張を含むディレクトリをLaravelでは用意していません。お好きな場所に設置してください。上記の例では、`Extension`ディレクトリを作成し、`MongoSessionHandler`ファイルを設置しています。

これらのメソッドの目的を読んだだけでは理解しづらいため、それぞれのメソッドを簡単に見てみましょう。

<div class="content-list" markdown="1">
- `open`メソッドは通常ファイルベースのセッション保存システムで使われます。Laravelは`file`セッションドライバを用意していますが、皆さんはこのメソッドに何も入れる必要はないでしょう。空のスタブのままで良いでしょう。実際、PHPが実装するように要求しているこのメソッドは、下手なインターフェイスデザインなのです。
- `close`メソッドも`open`と同様に通常は無視できます。ほどんどのドライバでは必要ありません。
- `read`メソッドは指定された`$sessionId`と紐付いたセッションデータの文字列バージョンを返します。取得や保存時にドライバ中でデータをシリアライズしたり、他のエンコード作業を行ったりする必要はありません。Laravelがシリアライズを行います。
- `write`メソッドはMongoDBやDynamoなどの持続可能なストレージに、`$sessionId`に紐付け指定した`$data`文字列を書き出します。ここでも、シリアリズを行う必要はまったくありません。Laravelがすでに処理しています。
- `destroy`メソッドは持続可能なストレージから`$sessionId`に紐付いたデータを取り除きます。
- `gc`メソッドは指定したUNIXタイムスタンプの`$lifetime`よりも古い前セッションデータを削除します。自前で破棄するMemcachedやRedisのようなシステムでは、このメソッドは空のままにしておきます。
</div>

<a name="registering-the-driver"></a>
#### ドライバの登録

ドライバを実装したら、フレームワークへ登録する準備が整いました。Laravelのセッションバックエンドへドライバを追加するには、`Session`[ファサード](/docs/{{version}}/facades)の`extend`メソッドを呼び出します。[サービスプロバイダ](/docs/{{version}}/providers)の`boot`メソッドから、`extend`メソッドを呼び出してください。既存の`AppServiceProvider`か真新しく作成し、呼び出してください。

    <?php

    namespace App\Providers;

    use App\Extensions\MongoSessionHandler;
    use Illuminate\Support\Facades\Session;
    use Illuminate\Support\ServiceProvider;

    class SessionServiceProvider extends ServiceProvider
    {
        /**
         * 全アプリケーションサービスの登録
         *
         * @return void
         */
        public function register()
        {
            //
        }

        /**
         * 全アプリケーションサービスの初期起動
         *
         * @return void
         */
        public function boot()
        {
            Session::extend('mongo', function ($app) {
                // Return implementation of SessionHandlerInterface...
                return new MongoSessionHandler;
            });
        }
    }

セッションドライバを登録したら、`config/session.php`設定ファイルで`mongo`ドライバが使用できます。
