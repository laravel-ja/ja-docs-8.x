# URL生成

- [イントロダクション](#introduction)
- [基礎](#the-basics)
    - [URLの生成](#generating-urls)
    - [現在のURLへのアクセス](#accessing-the-current-url)
- [名前付きルートのURL](#urls-for-named-routes)
    - [署名付きURL](#signed-urls)
- [コントローラアクションのURL](#urls-for-controller-actions)
- [デフォルト値](#default-values)

<a name="introduction"></a>
## イントロダクション

Laravelは、アプリケーションのURLを生成するのに役立つヘルパをいくつか提供しています。これらのヘルパは、主にテンプレートとAPIレスポンスでリンクを構築するとき、またはアプリケーションの別の部分へのリダイレクトレスポンスを生成するときに役立ちます。

<a name="the-basics"></a>
## 基礎

<a name="generating-urls"></a>
### URLの生成

`url`ヘルパは、アプリケーションの任意のURLを生成するために使用します。生成したURLは、アプリケーションが処理している現在のリクエストのスキーム(HTTPまたはHTTPS)とホストを自動的に使用します。

    $post = App\Models\Post::find(1);

    echo url("/posts/{$post->id}");

    // http://example.com/posts/1

<a name="accessing-the-current-url"></a>
### 現在のURLへのアクセス

`url`ヘルパにパスを指定しないと、`Illuminate\Routing\UrlGenerator`インスタンスが返され、現在のURLに関する情報へアクセスできます。

    // クエリ文字列を除いた現在のURL
    echo url()->current();

    // クエリ文字列を含んだ現在のURL
    echo url()->full();

    // 直前のリクエストの完全なURL
    echo url()->previous();

こうしたメソッドには、`URL`[ファサード](/docs/{{version}}/facades)を使用してもアクセスできます。

    use Illuminate\Support\Facades\URL;

    echo URL::current();

<a name="urls-for-named-routes"></a>
## 名前付きルートのURL

`route`ヘルパは、[名前付きルート](/docs/{{version}}/routing#named-routes)へのURLを生成するためにも使用できます。名前付きルートを使用すると、ルートで定義する実際のURLと結合せずにURLを生成できます。したがって、ルートのURLが変更された場合でも、`route`関数の呼び出しを変更する必要はありません。たとえば、アプリケーションに次のように定義されたルートが含まれているとします。

    Route::get('/post/{post}', function () {
        //
    })->name('post.show');

このルートへのURLを生成するには、次のように`route`ヘルパを使用します。

    echo route('post.show', ['post' => 1]);

    // http://example.com/post/1

もちろん、`route`ヘルパを使用して、複数のパラメーターを持つルートのURLを生成することもできます。

    Route::get('/post/{post}/comment/{comment}', function () {
        //
    })->name('comment.show');

    echo route('comment.show', ['post' => 1, 'comment' => 3]);

    // http://example.com/post/1/comment/3

ルートの定義パラメータに対応しない過剰な配列要素は、URLのクエリ文字列として追加されます。

    echo route('post.show', ['post' => 1, 'search' => 'rocket']);

    // http://example.com/post/1?search=rocket

<a name="eloquent-models"></a>
#### Eloquent Models

[Eloquentモデル](/docs/{{version}}/eloquent)の主キーを使用するURLを生成することもよくあると思います。そのため、Eloquentモデルをパラメータ値として渡すことができます。`route`ヘルパは、そのモデルの主キーを自動的に取り出します。

    echo route('post.show', ['post' => $post]);

<a name="signed-urls"></a>
### 署名付きURL

Laravelでは名前付きルートに対し、簡単に「署名付きURL」を作成できます。このURLは「署名」ハッシュをクエリ文字列として付加し、作成されてからそのURLが変更されていないかをLaravelで確認できるようにします。署名付きURLは公にアクセスさせるルートではあるが、URL操作に対する保護レイヤが必要な場合とくに便利です。

たとえば、公の「購読終了」リンクを顧客へのメールへ用意するために、署名付きURLが使用できます。名前付きルートに対し署名URLを作成するには、`URL`ファサードの`signedRoute`メソッドを使用します。

    use Illuminate\Support\Facades\URL;

    return URL::signedRoute('unsubscribe', ['user' => 1]);

指定する時間が経過すると期限切れになる一時的な署名付きルートURLを生成する場合は、`temporarySignedRoute`メソッドを使用します。Laravelが一時的な署名付きルートURLを検証するとき、署名付きURLにエンコードされている有効期限のタイムスタンプが経過していないことを確認します。

    use Illuminate\Support\Facades\URL;

    return URL::temporarySignedRoute(
        'unsubscribe', now()->addMinutes(30), ['user' => 1]
    );

<a name="validating-signed-route-requests"></a>
#### 署名付きルートリクエストの検査

送信されてきたリクエストが有効な署名を持っているかを検査するには、送信された`Request`に対して、`hasValidSignature`メソッドを呼び出します。

    use Illuminate\Http\Request;

    Route::get('/unsubscribe/{user}', function (Request $request) {
        if (! $request->hasValidSignature()) {
            abort(401);
        }

        // ...
    })->name('unsubscribe');

もしくは、`Illuminate\Routing\Middleware\ValidateSignature`[ミドルウェア](/docs/{{version}}/middleware)をルートに割り当てることもできます。このミドルウェアにHTTPカーネルの`routeMiddleware`配列のキーを割り当てていない場合は、割り当てる必要があります。

    /**
     * アプリケーションルートのミドルウェア
     *
     * これらのミドルウェアはグループ、もしくは個別に指定される。
     *
     * @var array
     */
    protected $routeMiddleware = [
        'signed' => \Illuminate\Routing\Middleware\ValidateSignature::class,
    ];

ミドルウェアをカーネルに登録したら、それをルートにアタッチできます。受信リクエストに有効な署名がない場合、ミドルウェアは自動的に`403`HTTPレスポンスを返します。

    Route::post('/unsubscribe/{user}', function (Request $request) {
        // ...
    })->name('unsubscribe')->middleware('signed');

<a name="urls-for-controller-actions"></a>
## コントローラアクションのURL

`action`関数は、指定するコントローラアクションに対するURLを生成します。

    use App\Http\Controllers\HomeController;

    $url = action([HomeController::class, 'index']);

コントローラメソッドがルートパラメータを受け入れる場合、関数の２番目の引数としてルートパラメータの連想配列を渡せます。

    $url = action([UserController::class, 'profile'], ['id' => 1]);

<a name="default-values"></a>
## デフォルト値

アプリケーションにより、特定のURLパラメータのデフォルト値をリクエスト全体で指定したい場合もあります。たとえば、多くのルートで`{locale}`パラメータを定義していると想像してください。

    Route::get('/{locale}/posts', function () {
        //
    })->name('post.index');

毎回`route`ヘルパを呼び出すごとに、`locale`をいつも指定するのは厄介です。そのため、現在のリクエストの間、常に適用されるこのパラメートのデフォルト値は、`URL::defaults`メソッドを使用し定義できます。現在のリクエストでアクセスできるように、[ルートミドルウェア](/docs/{{version}}/middleware#assigning-middleware-to-routes)から、このメソッドを呼び出したいかと思います。

    <?php

    namespace App\Http\Middleware;

    use Closure;
    use Illuminate\Support\Facades\URL;

    class SetDefaultLocaleForUrls
    {
        /**
         * 受信リクエストの処理
         *
         * @param  \Illuminate\Http\Request  $request
         * @param  \Closure  $next
         * @return \Illuminate\Http\Response
         */
        public function handle($request, Closure $next)
        {
            URL::defaults(['locale' => $request->user()->locale]);

            return $next($request);
        }
    }

一度`locale`パラメータに対するデフォルト値をセットしたら、`route`ヘルパを使いURLを生成する時に、値を渡す必要はもうありません。

<a name="url-defaults-middleware-priority"></a>
#### URLのデフォルトとミドルウェアの優先度

URLのデフォルト値を設定すると、Laravelの暗黙的なモデルバインディングの処理を妨げる可能性があります。したがって、URLのデフォルトをLaravel自身の`SubstituteBindings`ミドルウェアの前に実行するよう設定するため、[ミドルウェアの優先度を設定する](/docs/{{version}}/middleware#sorting-middleware)必要があります。それには、アプリケーションのHTTPカーネルの`$middlewarePriority`プロパティ内にある`SubstituteBindings`ミドルウェアの前にミドルウェアを確実に設置してください。

`$middlewarePriority`プロパティは`Illuminate\Foundation\Http\Kernel`ベースクラスで定義されています。変更するにはその定義をこのクラスからコピーし、アプリケーションのHTTPカーネルでオーバーライトしてください。

    /**
     * ミドルウェアの優先リスト
     *
     * この指定により、グローバルではないミドルウェアは常にこの順番になります。
     *
     * @var array
     */
    protected $middlewarePriority = [
        // ...
         \App\Http\Middleware\SetDefaultLocaleForUrls::class,
         \Illuminate\Routing\Middleware\SubstituteBindings::class,
         // ...
    ];
