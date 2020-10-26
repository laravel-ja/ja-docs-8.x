# ミドルウェア

- [イントロダクション](#introduction)
- [ミドルウェア定義](#defining-middleware)
- [ミドルウェア登録](#registering-middleware)
    - [グローバルミドルウェア](#global-middleware)
    - [ルートへの結合](#assigning-middleware-to-routes)
    - [ミドルウェアグループ](#middleware-groups)
    - [ミドルウェアの優先付け](#sorting-middleware)
- [ミドルウェアパラメーター](#middleware-parameters)
- [終了処理ミドルウェア](#terminable-middleware)

<a name="introduction"></a>
## イントロダクション

ミドルウェアはアプリケーションへ送信されたHTTPリクエストをフィルタリングする、便利なメカニズムを提供します。たとえば、アプリケーションのユーザーが認証されているかを確認するミドルウェアがLaravelに用意されています。ユーザーが認証されていなければ、このミドルウェアはユーザーをログインページへリダイレクトします。反対にそのユーザーが認証済みであれば、そのリクエストがアプリケーションのその先へ進むことを許可します。

認証の他にも多彩なタスクを実行するミドルウェアを書くことができます。たとえばCORSミドルウェアは、アプリケーションから返されるレスポンス全部に正しいヘッダを追加することに責任を持つでしょう。ログミドルウェアはアプリケーションにやってきたリクエスト全部をログすることに責任を負うでしょう。

認証やCSRF保護などLaravelには多くのミドルウェアが用意されています。これらのミドルウェアは全部、`app/Http/Middleware`ディレクトリに設置されています。

<a name="defining-middleware"></a>
## ミドルウェア定義

新しいミドルウェアを作成するには、`make:middleware` Artisanコマンドを使います。

    php artisan make:middleware CheckAge

このコマンドにより、`CheckAge`クラスが、`app/Http/Middleware`ディレクトリ中に生成されます。このミドルウェアで、ageに２００歳以上が指定された場合のみ、アクセスを許してみましょう。そうでなければ、ユーザーを`home`のURIへリダイレクトします。

    <?php

    namespace App\Http\Middleware;

    use Closure;

    class CheckAge
    {
        /**
         * 送信されてきたリクエストの処理
         *
         * @param  \Illuminate\Http\Request  $request
         * @param  \Closure  $next
         * @return mixed
         */
        public function handle($request, Closure $next)
        {
            if ($request->age <= 200) {
                return redirect('home');
            }

            return $next($request);
        }
    }

ご覧の通り、`age`が`200`以下の場合、ミドルウェアはHTTPリダイレクトをクライアントへ返します。そうでなければ、リクエストはパスし、アプリケーションの先へ進めます。ミドルウェアのチェックに合格し、アプリケーションの先へリクエストを通すには、`$request`を渡し`$next`コールバックを呼び出します。

ミドルウェアを把握する一番良い方法は、HTTPリクエストがアプリケーションに届くまでに通過する、数々の「レイヤー（層）」なのだと考えることです。それぞれのレイヤーは、リクエストを通過させるかどうかテストし、場合により完全に破棄することさえできます。

> {tip} すべてのミドルウェアは、[サービスコンテナ](/docs/{{version}}/container)により、依存解決されます。そのため、ミドルウェアのコンストラクタに、必要な依存をタイプヒントで指定できます。

<a name="before-after-middleware"></a>
#### Before／Afterミドルウェア

ミドルウェアがリクエストの前、後に実行されるかは、そのミドルウェアの組み方により決まります。次のミドルウェアはアプリケーションによりリクエストが処理される**前**に実行されます。

    <?php

    namespace App\Http\Middleware;

    use Closure;

    class BeforeMiddleware
    {
        public function handle($request, Closure $next)
        {
            // アクションを実行…

            return $next($request);
        }
    }

一方、次のミドルウェアはアプリケーションによりリクエストが処理された**後**にタスクを実行します。

    <?php

    namespace App\Http\Middleware;

    use Closure;

    class AfterMiddleware
    {
        public function handle($request, Closure $next)
        {
            $response = $next($request);

            // アクションを実行…

            return $response;
        }
    }

<a name="registering-middleware"></a>
## ミドルウェア登録

<a name="global-middleware"></a>
### グローバルミドルウェア

あるミドルウェアをアプリケーションの全HTTPリクエストで実行したい場合は、`app/Http/Kernel.php`クラスの`$middleware`プロパティへ追加してください。

<a name="assigning-middleware-to-routes"></a>
### ミドルウェアをルートへ登録

特定のルートのみに対しミドルウェアを指定したい場合は、先ず`app/Http/Kernel.php`ファイルでミドルウェアの短縮キーを登録します。デフォルト状態でこのクラスは、Laravelに含まれているミドルウェアのエントリーを`$routeMiddleware`プロパティに持っています。ミドルウェアを追加する方法は、選んだキー名と一緒にリストへ付け加えます。

    // App\Http\Kernelクラスの中

    protected $routeMiddleware = [
        'auth' => \App\Http\Middleware\Authenticate::class,
        'auth.basic' => \Illuminate\Auth\Middleware\AuthenticateWithBasicAuth::class,
        'bindings' => \Illuminate\Routing\Middleware\SubstituteBindings::class,
        'cache.headers' => \Illuminate\Http\Middleware\SetCacheHeaders::class,
        'can' => \Illuminate\Auth\Middleware\Authorize::class,
        'guest' => \App\Http\Middleware\RedirectIfAuthenticated::class,
        'signed' => \Illuminate\Routing\Middleware\ValidateSignature::class,
        'throttle' => \Illuminate\Routing\Middleware\ThrottleRequests::class,
        'verified' => \Illuminate\Auth\Middleware\EnsureEmailIsVerified::class,
    ];

HTTPカーネルへミドルウェアを定義し終えたら、ルートに対しミドルウェアを指定する、`middleware`メソッドを使ってください。

    Route::get('admin/profile', function () {
        //
    })->middleware('auth');

ルートに複数のミドルウェアを定義することもできます。

    Route::get('/', function () {
        //
    })->middleware('first', 'second');

ミドルウェアを指定する時に、完全なクラス名を指定することもできます。

    use App\Http\Middleware\CheckAge;

    Route::get('admin/profile', function () {
        //
    })->middleware(CheckAge::class);

ルートグループに対してミドルウェアを指定する場合、そのグループ内の個別のルートに対して適用を除外する必要も起きるでしょう。`withoutMiddleware`メソッドを使用してください。

    use App\Http\Middleware\CheckAge;

    Route::middleware([CheckAge::class])->group(function () {
        Route::get('/', function () {
            //
        });

        Route::get('admin/profile', function () {
            //
        })->withoutMiddleware([CheckAge::class]);
    });

`withoutMiddleware`メソッドはルートミドルウエアからのみ削除でき、[グローバルミドルウェア](#global-middleware)には適用されません。

<a name="middleware-groups"></a>
### ミドルウェアグループ

多くのミドルウェアを一つのキーによりまとめ、ルートへ簡単に指定できるようにしたくなることもあります。HTTPカーネルの`$middlewareGroups`プロパティにより可能です。

WebのUIとAPIルートへ適用できる、一般的なミドルウェアを含んだ、`web`と`api`ミドルウェアグループをLaravelは最初から用意しています。

    /**
     * アプリケーションのミドルウェアグループ
     *
     * @var array
     */
    protected $middlewareGroups = [
        'web' => [
            \App\Http\Middleware\EncryptCookies::class,
            \Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse::class,
            \Illuminate\Session\Middleware\StartSession::class,
            \Illuminate\View\Middleware\ShareErrorsFromSession::class,
            \App\Http\Middleware\VerifyCsrfToken::class,
            \Illuminate\Routing\Middleware\SubstituteBindings::class,
        ],

        'api' => [
            'throttle:60,1',
            'auth:api',
        ],
    ];

ミドルウェアグループは、個別のミドルウェアと同じ記法を使い、ルートやコントローラへ結合します。再度説明しますと、ミドルウェアグループは一度に多くのミドルウエアを簡単に、より便利に割り付けるための方法です。

    Route::get('/', function () {
        //
    })->middleware('web');

    Route::group(['middleware' => ['web']], function () {
        //
    });

    Route::middleware(['web', 'subscribed'])->group(function () {
        //
    });

> {tip} `RouteServiceProvider`により、`routes/web.php`ファイルでは、`web`ミドルウェアグループが自動的に適用されます。

<a name="sorting-middleware"></a>
### ミドルウェアの優先付け

まれに、特定の順番でミドルウェアを実行する必要が起き得ますが、ルートへミドルウェアを指定する時に順番をコントロールできません。このような場合、`app/Http/Kernel.php`ファイルの`$middlewarePriority`プロパティを使用し、ミドルウェアの優先度を指定できます。

    /**
     * ミドルウェアの優先順リスト
     *
     * グローバルではないミドルウェアを常に指定順に強要する
     *
     * @var array
     */
    protected $middlewarePriority = [
        \Illuminate\Session\Middleware\StartSession::class,
        \Illuminate\View\Middleware\ShareErrorsFromSession::class,
        \Illuminate\Contracts\Auth\Middleware\AuthenticatesRequests::class,
        \Illuminate\Routing\Middleware\ThrottleRequests::class,
        \Illuminate\Session\Middleware\AuthenticateSession::class,
        \Illuminate\Routing\Middleware\SubstituteBindings::class,
        \Illuminate\Auth\Middleware\Authorize::class,
    ];

<a name="middleware-parameters"></a>
## ミドルウェアパラメータ

ミドルウェアは追加のカスタムパラメーターを受け取ることができます。たとえば指定されたアクションを実行する前に、与えられた「役割(role)」を持った認証ユーザーであるかをアプリケーションで確認する必要がある場合、役割名を追加の引数として受け取る`CheckRole`を作成できます。

追加のミドルウェアパラメーターは、ミドルウェアの`$next`引数の後に渡されます。

    <?php

    namespace App\Http\Middleware;

    use Closure;

    class CheckRole
    {
        /**
         * リクエストフィルターを実行
         *
         * @param  \Illuminate\Http\Request  $request
         * @param  \Closure  $next
         * @param  string  $role
         * @return mixed
         */
        public function handle($request, Closure $next, $role)
        {
            if (! $request->user()->hasRole($role)) {
                // リダイレクト処理…
            }

            return $next($request);
        }

    }

ミドルウェアパラメーターはルート定義時に指定され、ミドルウェア名とパラメーターを`:`で区切ります。複数のパラメーターはカンマで区切ります。

    Route::put('post/{id}', function ($id) {
        //
    })->middleware('role:editor');

<a name="terminable-middleware"></a>
## 終了処理ミドルウェア

ミドルウェアは場合により、HTTPレスポンスを送った後に、何か作業する必要が起きます。ミドルウェアに`terminate`メソッドを定義しWebサーバがFastCGIを使用している場合、レスポンスがブラウザへ送られた後に自動的に呼び出されます。

    <?php

    namespace Illuminate\Session\Middleware;

    use Closure;

    class StartSession
    {
        public function handle($request, Closure $next)
        {
            return $next($request);
        }

        public function terminate($request, $response)
        {
            // セッションデーターの保存…
        }
    }

`terminate`メソッドはリクエストとレスポンスの両方を受け取ります。終了処理可能なミドルウェアを定義したら、`app/Http/Kernel.php`ファイルでルートのリスト、もしくはグローバルミドルウェアのリストへ追加してください。

ミドルウェアの`terminate`メソッド呼び出し時に、Laravelは[サービスコンテナ](/docs/{{version}}/container)から真新しいミドルウェアのインスタンスを依存解決します。`handle`と`terminate`メソッドの呼び出しで同一のミドルウェアインスタンスを使用したい場合は、コンテナの`singleton`メソッドを使用し、ミドルウェアを登録してください。通常、`AppServiceProvider.php`の`register`メソッドの中で登録します。

    use App\Http\Middleware\TerminableMiddleware;

    /**
     * 全アプリケーションサービスの登録
     *
     * @return void
     */
    public function register()
    {
        $this->app->singleton(TerminableMiddleware::class);
    }
