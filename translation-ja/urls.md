# URL生成

- [イントロダクション](#introduction)
- [基礎](#the-basics)
    - [URL生成の基礎](#generating-basic-urls)
    - [現在のURLへのアクセス](#accessing-the-current-url)
- [名前付きルートのURL](#urls-for-named-routes)
    - [署名付きURL](#signed-urls)
- [コントローラアクションのURL](#urls-for-controller-actions)
- [デフォルト値](#default-values)

<a name="introduction"></a>
## イントロダクション

Laravelは、アプリケーションに対するURL生成の手助けする、数多くのヘルパを提供しています。これは主に、テンプレートやAPIレスポンスでリンクを構築したり、アプリケーションの他の部分へのリダイレクトレスポンスを生成したりするのに役立ちます。

<a name="the-basics"></a>
## 基礎

<a name="generating-basic-urls"></a>
### URL生成の基礎

`url`ヘルパは、アプリケーションに対する任意のURLを生成するために使用されます。生成されるURLには自動的に、現在のリクエストのスキーム（HTTP／HTTPS）とホストが使用されます。

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

`route`ヘルパは、名前付きルートへのURLを生成するために使用します。名前付きルートにより、定義したルートの実際のURLを指定せずともURLを生成できます。ですから、ルートのURLを変更しても、`route`関数の呼び出しを変更する必要はありません。例として以下のように、アプリケーションが次のルートを持っていると想像してください。

    Route::get('/post/{post}', function () {
        //
    })->name('post.show');

このルートへのURLを生成するには、次のように`route`ヘルパを使用します。

    echo route('post.show', ['post' => 1]);

    // http://example.com/post/1

[Eloquentモデル](/docs/{{version}}/eloquent)の主キーを使用するURLを生成することもよくあると思います。そのため、Eloquentモデルをパラメータ値として渡すことができます。`route`ヘルパは、そのモデルの主キーを自動的に取り出します。

    echo route('post.show', ['post' => $post]);

`route`ヘルパは、複数のパラメータを伴うルートのURLを生成するためにも使用できます。

    Route::get('/post/{post}/comment/{comment}', function () {
        //
    })->name('comment.show');

    echo route('comment.show', ['post' => 1, 'comment' => 3]);

    // http://example.com/post/1/comment/3

<a name="signed-urls"></a>
### 署名付きURL

Laravelでは名前付きルートに対し、簡単に「署名付きURL」を作成できます。このURLは「署名」ハッシュをクエリ文字列として付加し、作成されてからそのURLが変更されていないかをLaravelで確認できるようにします。署名付きURLは公にアクセスさせるルートではあるが、URL操作に対する保護レイヤが必要な場合とくに便利です。

たとえば、公の「購読終了」リンクを顧客へのメールへ用意するために、署名付きURLが使用できます。名前付きルートに対し署名URLを作成するには、`URL`ファサードの`signedRoute`メソッドを使用します。

    use Illuminate\Support\Facades\URL;

    return URL::signedRoute('unsubscribe', ['user' => 1]);

一定期間で無効になる署名URLを生成したい場合は、`temporarySignedRoute`メソッドを使用します。

    use Illuminate\Support\Facades\URL;

    return URL::temporarySignedRoute(
        'unsubscribe', now()->addMinutes(30), ['user' => 1]
    );

#### 署名付きルートリクエストの検査

送信されてきたリクエストが有効な署名を持っているかを検査するには、送信された`Request`に対して、`hasValidSignature`メソッドを呼び出します。

    use Illuminate\Http\Request;

    Route::get('/unsubscribe/{user}', function (Request $request) {
        if (! $request->hasValidSignature()) {
            abort(401);
        }

        // ...
    })->name('unsubscribe');

もしくは、`Illuminate\Routing\Middleware\ValidateSignature`ミドルウェアをそのルートへ指定します。用意していない場合、このミドルウェアをHTTPカーネルの`routeMiddleware`配列で指定してください。

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

このミドルウェアをカーネルへ登録できたら、ルートで指定できます。送信されたリクエストは有効な署名を持っていない場合、このミドルウェアは自動的に`403`エラーレスポンスを返します。

    Route::post('/unsubscribe/{user}', function (Request $request) {
        // ...
    })->name('unsubscribe')->middleware('signed');

<a name="urls-for-controller-actions"></a>
## コントローラアクションのURL

`action`関数は、指定するコントローラアクションに対するURLを生成します。

    use App\Http\Controllers\HomeController;

    $url = action([HomeController::class, 'index']);

コントローラメソッドが、ルートパラメータを受け取る場合、この関数の第２引数として渡すことができます。

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
        public function handle($request, Closure $next)
        {
            URL::defaults(['locale' => $request->user()->locale]);

            return $next($request);
        }
    }

一度`locale`パラメータに対するデフォルト値をセットしたら、`route`ヘルパを使いURLを生成する時に、値を渡す必要はもうありません。

#### URLのデフォルトとミドルウェアの優先度

URLのデフォルト値を設定すると、Laravelの暗黙的なモデルバインディングの処理を妨げる可能性があります。したがって、URLのデフォルトをLaravel自身の`SubstituteBindings`ミドルウェアの前に実行するよう設定するため、[ミドルウェアの優先度を設定する](https://laravel.com/docs/{{version}}/middleware#sorting-middleware)必要があります。それには、アプリケーションのHTTPカーネルの`$middlewarePriority`プロパティ内にある`SubstituteBindings`ミドルウェアの前にミドルウェアを確実に設置してください。

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
         \App\Http\MiddlewareSetDefaultLocaleForUrls::class,
         \Illuminate\Routing\Middleware\SubstituteBindings::class,
         // ...
    ];
