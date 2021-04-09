# ファサード

- [イントロダクション](#introduction)
- [いつファサードを使うか](#when-to-use-facades)
    - [ファサード対依存注入](#facades-vs-dependency-injection)
    - [ファサード対ヘルパ関数](#facades-vs-helper-functions)
- [ファサードの仕組み](#how-facades-work)
- [リアルタイムファサード](#real-time-facades)
- [ファサードクラスリファレンス](#facade-class-reference)

<a name="introduction"></a>
## イントロダクション

Laravelのドキュメント全体を通して、「ファサード」を介してLaravelの機能を操作するコード例を紹介しています。ファサードは、アプリケーションの[サービスコンテナ](/docs/{{version}}/container)で使用可能なクラスに対して「静的な」インターフェイスを提供します。Laravelは、Laravelのほとんどすべての機能へのアクセスを提供する多くのファサードを提供しています。

Laravelファサードは、サービスコンテナ内の基礎となるクラスへの「静的プロキシ」として機能し、従来の静的メソッドよりもテスト容易性と柔軟性を維持しながら、簡潔で表現力豊かな構文という利点を提供しています。ファサードが内部でどのように機能するかを完全に理解していなくても、まったく問題ありません。流れに沿って、Laravelについて学び続けてください。

Laravelのファサードはすべて、`Illuminate\Support\Facades`名前空間で定義します。したがって、次のようなファサードに簡単にアクセスできます。

    use Illuminate\Support\Facades\Cache;
    use Illuminate\Support\Facades\Route;

    Route::get('/cache', function () {
        return Cache::get('key');
    });

Laravelのドキュメント全体を通じ、コード例の多くでファサードを使用して、フレームワークのさまざまな機能を紹介しています。

<a name="helper-functions"></a>
#### ヘルパ関数

ファサードを補完するため、Laravelはさまざまなグローバルな「ヘルパ機能」を提供し、Laravel機能の一般的な操作をより簡単にしています。使用する可能性のある一般的なヘルパ関数には、`view`、`response`、`url`、`config`などがあります。Laravelが提供する各ヘルパ機能は、対応する機能とともにドキュメント化しています。関数の完全なリストは、専用の[ヘルパドキュメント](/docs/{{version}}/helpers)内にあります。

たとえば、`Illuminate\Support\Facades\Response`ファサードを使用してJSONレスポンスを生成する代わりに、単に`response`関数を使用することもできます。ヘルパ関数はグローバルに利用できるため、使用するためにクラスをインポートする必要はありません。

    use Illuminate\Support\Facades\Response;

    Route::get('/users', function () {
        return Response::json([
            // ...
        ]);
    });

    Route::get('/users', function () {
        return response()->json([
            // ...
        ]);
    });

<a name="when-to-use-facades"></a>
## いつファサードを使うか

ファサードには多くの利点があります。これらは、手動で挿入または設定する必要のある長いクラス名を覚えていなくても、Laravelの機能を使用できるようにする簡潔で覚えやすい構文を提供しています。さらに、PHPの動的メソッドを独自に使用しているため、テストが簡単です。

ただし、ファサードを使用する場合は注意が必要です。ファサードの主な危険性は、クラスの「スコープクリープ」です。ファサードは非常に使いやすく、依存注入を必要としないため、１つのクラスで多くのファサードを使用するのは簡単で、クラスを成長させ続けてしまいがちです。依存注入を使用していれば、大きなコンストラクタによりクラスが大きくなりすぎていることを示す視覚的なフィードバックにより、これが起きる可能性は低減されます。したがって、ファサードを使用するときは、クラスのサイズに特に注意して、クラスの責任範囲が狭くなるようにしてください。クラスが大きくなりすぎている場合は、クラスを複数の小さなクラスに分割することを検討してください。

<a name="facades-vs-dependency-injection"></a>
### ファサード対依存注入

依存注入の主な利点の１つは、注入するクラスの実装を交換できることです。これは、モックまたはスタブを挿入して、さまざまなメソッドがスタブで呼び出されたことを表明できるため、テスト中に役立ちます。

通常、真に静的なクラスメソッドをモックまたはスタブすることはできません。ただし、ファサードは動的メソッドを使用して、サービスコンテナが解決するオブジェクトへのメソッド呼び出しをプロキシするため、挿入するクラスインスタンスをテストするのと同様に、実際にはファサードをテストできます。たとえば、次のルートがあるとします。

    use Illuminate\Support\Facades\Cache;

    Route::get('/cache', function () {
        return Cache::get('key');
    });

Laravelのファサードテストメソッドを使用して、次のテストを記述し、期待する引数で`Cache::get`メソッドを呼び出すことを確認できます。

    use Illuminate\Support\Facades\Cache;

    /**
     * 基本的な機能テストの例
     *
     * @return void
     */
    public function testBasicExample()
    {
        Cache::shouldReceive('get')
             ->with('key')
             ->andReturn('value');

        $response = $this->get('/cache');

        $response->assertSee('value');
    }

<a name="facades-vs-helper-functions"></a>
### ファサード対ヘルパ関数

Laravelには、ファサードに加えて、ビューの生成、イベントの発生、ジョブのディスパッチ、HTTP応答の送信などの一般的なタスクを実行できるさまざまな「ヘルパ」関数が含まれています。これらのヘルパ関数の多くは、対応するファサードと同じ機能を実行します。たとえば、このファサード呼び出しとヘルパ呼び出しは同等です。

    return Illuminate\Support\Facades\View::make('profile');

    return view('profile');

ファサードとヘルパ機能の間に実際的な違いはまったくありません。ヘルパ関数を使用する場合でも、対応するファサードとまったく同じようにテストできます。たとえば、次のルートがあるとします。

    Route::get('/cache', function () {
        return cache('key');
    });

内部的には、`cache`ヘルパは`Cache`ファサードの基礎となるクラスで`get`メソッドを呼び出します。したがって、ヘルパ関数を使用している場合でも、次のテストを記述して、期待した引数でメソッドが呼び出されたことを確認できます。

    use Illuminate\Support\Facades\Cache;

    /**
     * 基本的な機能テストの例
     *
     * @return void
     */
    public function testBasicExample()
    {
        Cache::shouldReceive('get')
             ->with('key')
             ->andReturn('value');

        $response = $this->get('/cache');

        $response->assertSee('value');
    }

<a name="how-facades-work"></a>
## ファサードの仕組み

Laravelアプリケーションのファサードは、コンテナからのオブジェクトに対するアクセスを提供するクラスです。この作業を行うメカニズムは、`Facade`クラスにあります。Laravelのファサード、および作成したカスタムファサードは、基本の`Illuminate\Support\Facades\Facade`クラスを拡張します。

`Facade`基本クラスは`__callStatic()`マジックメソッドを利用して、ファサードへの呼び出しをコンテナが解決するオブジェクトへの呼び出しへと延期します。下の例では、Laravelキャッシュシステムが呼び出されます。このコードを一瞥すると、静的な`get`メソッドが`Cache`クラスで呼び出されていると思われるかもしれません。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use Illuminate\Support\Facades\Cache;

    class UserController extends Controller
    {
        /**
         * 特定のユーザーのプロファイルを表示
         *
         * @param  int  $id
         * @return Response
         */
        public function showProfile($id)
        {
            $user = Cache::get('user:'.$id);

            return view('profile', ['user' => $user]);
        }
    }

ファイルの上部近くで、`Cache`ファサードを「インポート」していることに注意してください。このファサードは、`Illuminate\Contracts\Cache\Factory`インターフェイスの基盤となる実装にアクセスするためのプロキシとして機能します。ファサードを使用して行う呼び出しはすべて、Laravelのキャッシュサービスの基盤となるインスタンスに渡されます。

その`Illuminate\Support\Facades\Cache`クラスを見ると、静的メソッド`get`がないことがわかります。

    class Cache extends Facade
    {
        /**
         * コンポーネントの登録名を取得
         *
         * @return string
         */
        protected static function getFacadeAccessor() { return 'cache'; }
    }

代わりに、`Cache`ファサードは基本の`Facade`クラスを拡張し、メソッド`getFacadeAccessor()`を定義します。このメソッドの仕事は、サービスコンテナ結合名を返すことです。ユーザーが`Cache`ファサードの静的メソッドを参照すると、Laravelは[サービスコンテナ](/docs/{{version}}/container)で`cache`結合を依存解決し、リクエストされたメソッド(この場合は`get`)をそのオブジェクトに対して実行します。

<a name="real-time-facades"></a>
## リアルタイムファサード

リアルタイムファサードを使用すると、アプリケーション内の任意のクラスをファサードであるかのように扱うことができます。これをどのように使用できるかを説明するために、最初にリアルタイムファサードを使用しないコードを調べてみましょう。たとえば、`Podcast`モデルに`publish`メソッドがあるとしましょう。ただし、ポッドキャストを公開するには、`Publisher`インスタンスを挿入する必要があります。

    <?php

    namespace App\Models;

    use App\Contracts\Publisher;
    use Illuminate\Database\Eloquent\Model;

    class Podcast extends Model
    {
        /**
         * ポッドキャストを公開
         *
         * @param  Publisher  $publisher
         * @return void
         */
        public function publish(Publisher $publisher)
        {
            $this->update(['publishing' => now()]);

            $publisher->publish($this);
        }
    }

パブリッシャーの実装をメソッドに注入すると、注入されたパブリッシャーをモックできるため、メソッドを分離して簡単にテストできます。ただし、`publish`メソッドを呼び出すたびに、常にパブリッシャーインスタンスを渡す必要があります。リアルタイムのファサードを使用すると、`Publisher`インスタンスを明示的に渡す必要がなく、同じテスト容易性を維持できます。リアルタイムのファサードを生成するには、インポートするクラスの名前空間の前に`Facades`を付けます。

    <?php

    namespace App\Models;

    use Facades\App\Contracts\Publisher;
    use Illuminate\Database\Eloquent\Model;

    class Podcast extends Model
    {
        /**
         * ポッドキャストを公開
         *
         * @return void
         */
        public function publish()
        {
            $this->update(['publishing' => now()]);

            Publisher::publish($this);
        }
    }

リアルタイムファサードを使用する場合、パブリッシャーの実装は`Facades`プレフィックスの後に表示されるインターフェイスまたはクラス名の部分を使用してサービスコンテナが依存解決します。テスト時には、Laravelの組み込みファサードテストヘルパを使用して、このメソッド呼び出しをモックできます。

    <?php

    namespace Tests\Feature;

    use App\Models\Podcast;
    use Facades\App\Contracts\Publisher;
    use Illuminate\Foundation\Testing\RefreshDatabase;
    use Tests\TestCase;

    class PodcastTest extends TestCase
    {
        use RefreshDatabase;

        /**
         * テスト例
         *
         * @return void
         */
        public function test_podcast_can_be_published()
        {
            $podcast = Podcast::factory()->create();

            Publisher::shouldReceive('publish')->once()->with($podcast);

            $podcast->publish();
        }
    }

<a name="facade-class-reference"></a>
## ファサードクラスリファレンス

以下に、すべてのファサードとその基礎となるクラスを示します。これは、特定のファサードルートのAPIドキュメントをすばやく掘り下げるための便利なツールです。該当する[サービスコンテナ結合](/docs/{{version}}/container)キーがある場合は内容に含めています。

ファサード  |  クラス  |  サービスコンテナ結合キー
------------- | ------------- | -------------
App  |  [Illuminate\Foundation\Application](https://laravel.com/api/{{version}}/Illuminate/Foundation/Application.html)  |  `app`
Artisan  |  [Illuminate\Contracts\Console\Kernel](https://laravel.com/api/{{version}}/Illuminate/Contracts/Console/Kernel.html)  |  `artisan`
Auth  |  [Illuminate\Auth\AuthManager](https://laravel.com/api/{{version}}/Illuminate/Auth/AuthManager.html)  |  `auth`
Auth (Instance)  |  [Illuminate\Contracts\Auth\Guard](https://laravel.com/api/{{version}}/Illuminate/Contracts/Auth/Guard.html)  |  `auth.driver`
Blade  |  [Illuminate\View\Compilers\BladeCompiler](https://laravel.com/api/{{version}}/Illuminate/View/Compilers/BladeCompiler.html)  |  `blade.compiler`
Broadcast  |  [Illuminate\Contracts\Broadcasting\Factory](https://laravel.com/api/{{version}}/Illuminate/Contracts/Broadcasting/Factory.html)  |  &nbsp;
Broadcast (Instance)  |  [Illuminate\Contracts\Broadcasting\Broadcaster](https://laravel.com/api/{{version}}/Illuminate/Contracts/Broadcasting/Broadcaster.html)  |  &nbsp;
Bus  |  [Illuminate\Contracts\Bus\Dispatcher](https://laravel.com/api/{{version}}/Illuminate/Contracts/Bus/Dispatcher.html)  |  &nbsp;
Cache  |  [Illuminate\Cache\CacheManager](https://laravel.com/api/{{version}}/Illuminate/Cache/CacheManager.html)  |  `cache`
Cache (Instance)  |  [Illuminate\Cache\Repository](https://laravel.com/api/{{version}}/Illuminate/Cache/Repository.html)  |  `cache.store`
Config  |  [Illuminate\Config\Repository](https://laravel.com/api/{{version}}/Illuminate/Config/Repository.html)  |  `config`
Cookie  |  [Illuminate\Cookie\CookieJar](https://laravel.com/api/{{version}}/Illuminate/Cookie/CookieJar.html)  |  `cookie`
Crypt  |  [Illuminate\Encryption\Encrypter](https://laravel.com/api/{{version}}/Illuminate/Encryption/Encrypter.html)  |  `encrypter`
DB  |  [Illuminate\Database\DatabaseManager](https://laravel.com/api/{{version}}/Illuminate/Database/DatabaseManager.html)  |  `db`
DB (Instance)  |  [Illuminate\Database\Connection](https://laravel.com/api/{{version}}/Illuminate/Database/Connection.html)  |  `db.connection`
Event  |  [Illuminate\Events\Dispatcher](https://laravel.com/api/{{version}}/Illuminate/Events/Dispatcher.html)  |  `events`
File  |  [Illuminate\Filesystem\Filesystem](https://laravel.com/api/{{version}}/Illuminate/Filesystem/Filesystem.html)  |  `files`
Gate  |  [Illuminate\Contracts\Auth\Access\Gate](https://laravel.com/api/{{version}}/Illuminate/Contracts/Auth/Access/Gate.html)  |  &nbsp;
Hash  |  [Illuminate\Contracts\Hashing\Hasher](https://laravel.com/api/{{version}}/Illuminate/Contracts/Hashing/Hasher.html)  |  `hash`
Http  |  [Illuminate\Http\Client\Factory](https://laravel.com/api/{{version}}/Illuminate/Http/Client/Factory.html)  |  &nbsp;
Lang  |  [Illuminate\Translation\Translator](https://laravel.com/api/{{version}}/Illuminate/Translation/Translator.html)  |  `translator`
Log  |  [Illuminate\Log\LogManager](https://laravel.com/api/{{version}}/Illuminate/Log/LogManager.html)  |  `log`
Mail  |  [Illuminate\Mail\Mailer](https://laravel.com/api/{{version}}/Illuminate/Mail/Mailer.html)  |  `mailer`
Notification  |  [Illuminate\Notifications\ChannelManager](https://laravel.com/api/{{version}}/Illuminate/Notifications/ChannelManager.html)  |  &nbsp;
Password  |  [Illuminate\Auth\Passwords\PasswordBrokerManager](https://laravel.com/api/{{version}}/Illuminate/Auth/Passwords/PasswordBrokerManager.html)  |  `auth.password`
Password (Instance)  |  [Illuminate\Auth\Passwords\PasswordBroker](https://laravel.com/api/{{version}}/Illuminate/Auth/Passwords/PasswordBroker.html)  |  `auth.password.broker`
Queue  |  [Illuminate\Queue\QueueManager](https://laravel.com/api/{{version}}/Illuminate/Queue/QueueManager.html)  |  `queue`
Queue (Instance)  |  [Illuminate\Contracts\Queue\Queue](https://laravel.com/api/{{version}}/Illuminate/Contracts/Queue/Queue.html)  |  `queue.connection`
Queue (Base Class)  |  [Illuminate\Queue\Queue](https://laravel.com/api/{{version}}/Illuminate/Queue/Queue.html)  |  &nbsp;
Redirect  |  [Illuminate\Routing\Redirector](https://laravel.com/api/{{version}}/Illuminate/Routing/Redirector.html)  |  `redirect`
Redis  |  [Illuminate\Redis\RedisManager](https://laravel.com/api/{{version}}/Illuminate/Redis/RedisManager.html)  |  `redis`
Redis (Instance)  |  [Illuminate\Redis\Connections\Connection](https://laravel.com/api/{{version}}/Illuminate/Redis/Connections/Connection.html)  |  `redis.connection`
Request  |  [Illuminate\Http\Request](https://laravel.com/api/{{version}}/Illuminate/Http/Request.html)  |  `request`
Response  |  [Illuminate\Contracts\Routing\ResponseFactory](https://laravel.com/api/{{version}}/Illuminate/Contracts/Routing/ResponseFactory.html)  |  &nbsp;
Response (Instance)  |  [Illuminate\Http\Response](https://laravel.com/api/{{version}}/Illuminate/Http/Response.html)  |  &nbsp;
Route  |  [Illuminate\Routing\Router](https://laravel.com/api/{{version}}/Illuminate/Routing/Router.html)  |  `router`
Schema  |  [Illuminate\Database\Schema\Builder](https://laravel.com/api/{{version}}/Illuminate/Database/Schema/Builder.html)  |  &nbsp;
Session  |  [Illuminate\Session\SessionManager](https://laravel.com/api/{{version}}/Illuminate/Session/SessionManager.html)  |  `session`
Session (Instance)  |  [Illuminate\Session\Store](https://laravel.com/api/{{version}}/Illuminate/Session/Store.html)  |  `session.store`
Storage  |  [Illuminate\Filesystem\FilesystemManager](https://laravel.com/api/{{version}}/Illuminate/Filesystem/FilesystemManager.html)  |  `filesystem`
Storage (Instance)  |  [Illuminate\Contracts\Filesystem\Filesystem](https://laravel.com/api/{{version}}/Illuminate/Contracts/Filesystem/Filesystem.html)  |  `filesystem.disk`
URL  |  [Illuminate\Routing\UrlGenerator](https://laravel.com/api/{{version}}/Illuminate/Routing/UrlGenerator.html)  |  `url`
Validator  |  [Illuminate\Validation\Factory](https://laravel.com/api/{{version}}/Illuminate/Validation/Factory.html)  |  `validator`
Validator (Instance)  |  [Illuminate\Validation\Validator](https://laravel.com/api/{{version}}/Illuminate/Validation/Validator.html)  |  &nbsp;
View  |  [Illuminate\View\Factory](https://laravel.com/api/{{version}}/Illuminate/View/Factory.html)  |  `view`
View (Instance)  |  [Illuminate\View\View](https://laravel.com/api/{{version}}/Illuminate/View/View.html)  |  &nbsp;
