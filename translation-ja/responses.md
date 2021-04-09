# HTTPレスポンス

- [レスポンスの生成](#creating-responses)
    - [ヘッダの付加](#attaching-headers-to-responses)
    - [クッキーの付加](#attaching-cookies-to-responses)
    - [クッキーと暗号化](#cookies-and-encryption)
- [リダイレクト](#redirects)
    - [名前付きルートへのリダイレクト](#redirecting-named-routes)
    - [コントローラアクションへのリダイレクト](#redirecting-controller-actions)
    - [外部ドメインへのリダイレクト](#redirecting-external-domains)
    - [一時保持データを保存するリダイレクト](#redirecting-with-flashed-session-data)
- [他のレスポンスタイプ](#other-response-types)
    - [Viewレスポンス](#view-responses)
    - [JSONレスポンス](#json-responses)
    - [Fileダウンロード](#file-downloads)
    - [Fileレスポンス](#file-responses)
- [レスポンスマクロ](#response-macros)

<a name="creating-responses"></a>
## レスポンスの生成

<a name="strings-arrays"></a>
#### 文字列と配列

当然ながらすべてのルートやコントローラは、ユーザーのブラウザに対し、何らかのレスポンスを返す必要があります。Laravelはレスポンスを返すためにさまざまな手段を用意しています。一番基本的なレスポンスは、ルートかコントローラから文字列を返します。フレームワークが自動的に、文字列を完全なHTTPレスポンスへ変換します。

    Route::get('/', function () {
        return 'Hello World';
    });

ルートやコントローラから文字列を返す他に、配列も返せます。フレームワークは自動的に、配列をJSONレスポンスへ変換します。

    Route::get('/', function () {
        return [1, 2, 3];
    });

> {tip} [Eloquentコレクション](/docs/{{version}}/eloquent-collections)も返せることを知っていますか？　自動的にJSONへ変換されます。試してください！

<a name="response-objects"></a>
#### レスポンスオブジェクト

通常、皆さんは単純な文字列や配列をルートアクションから返すだけじゃありませんよね。代わりに、`Illuminate\Http\Response`インスタンスか[ビュー](/docs/{{version}}/views)を返したいですよね。

完全な`Response`インスタンスを返せば、レスポンスのHTTPステータスコードやヘッダをカスタマイズできます。`Response`インスタンスは、`Symfony\Component\HttpFoundation\Response`クラスを継承しており、HTTPレスポンスを構築するためにさまざまなメソッドを提供しています。

    Route::get('/home', function () {
        return response('Hello World', 200)
                      ->header('Content-Type', 'text/plain');
    });

<a name="eloquent-models-and-collections"></a>
#### Eloquentモデルとコレクション

[Eloquent ORM](/docs/{{version}}/eloquent)モデルとコレクションをルートとコントローラから直接返すこともできます。これを行うと、Laravelはモデルの[非表示属性](/docs/{{version}}/eloquent-serialization#hiding-attributes-from-json)を尊重しながら、モデルやコレクションをJSONレスポンスへ自動的に変換します。

    use App\Models\User;

    Route::get('/user/{user}', function (User $user) {
        return $user;
    });

<a name="attaching-headers-to-responses"></a>
### レスポンスへのヘッダ付加

レスポンスインスタンスをスラスラと構築できるように、ほとんどのレスポンスメソッドはチェーンとしてつなげられることを覚えておきましょう。たとえば、ユーザーにレスポンスを送り返す前に、`header`メソッドでいくつかのヘッダを追加できます。

    return response($content)
                ->header('Content-Type', $type)
                ->header('X-Header-One', 'Header Value')
                ->header('X-Header-Two', 'Header Value');

もしくは、`withHeaders`メソッドで、レスポンスへ追加したいヘッダの配列を指定します。

    return response($content)
                ->withHeaders([
                    'Content-Type' => $type,
                    'X-Header-One' => 'Header Value',
                    'X-Header-Two' => 'Header Value',
                ]);

<a name="cache-control-middleware"></a>
#### キャッシュコントロール・ミドルウェア

ルートグループへ`Cache-Control`ヘッダを簡単に指定できるよう、Laravelは`cache.headers`を用意しています。ディレクティブのリストの中で`etag`が指定されていると、レスポンスコンテンツのMD5ハッシュが、ETag識別子へ自動的にセットされます。

    Route::middleware('cache.headers:public;max_age=2628000;etag')->group(function () {
        Route::get('/privacy', function () {
            // ...
        });

        Route::get('/terms', function () {
            // ...
        });
    });

<a name="attaching-cookies-to-responses"></a>
### レスポンスへのクッキー付加

`cookie`メソッドを使用して、発信`Illuminate\Http\Response`インスタンスへクッキーを添付できます。Cookieが有効であると見なされる名前、値、および分数をメソッドへ渡す必要があります。

    return response('Hello World')->cookie(
        'name', 'value', $minutes
    );

`cookie`メソッドはさらに、使用機会が少ない引数をいくつか受け付けます。これらの引数は、全般的にPHPネイティブの[setcookie](https://secure.php.net/manual/en/function.setcookie.php)メソッドに指定する引数と、同じ目的、同じ意味合いを持っています。

    return response('Hello World')->cookie(
        'name', 'value', $minutes, $path, $domain, $secure, $httpOnly
    );

クッキーが送信レスポンスとともに確実に送信したいが、そのレスポンスのインスタンスがまだない場合は、`Cookie`ファサードを使用して、送信時にレスポンスへ添付するためにそのクッキーを「キュー」へ投入できます。`queue`メソッドは、クッキーインスタンスの作成に必要な引数をとります。こうしたクッキーは、ブラウザへ送信される前に送信レスポンスへ添付します。

    use Illuminate\Support\Facades\Cookie;

    Cookie::queue('name', 'value', $minutes);

<a name="generating-cookie-instances"></a>
#### クッキーインスタンスの生成

後ほどレスポンスインスタンスへアタッチできる`Symfony\Component\HttpFoundation\Cookie`インスタンスを生成したい場合は、グローバルな`cookie`ヘルパを使用します。このCookieは、レスポンスインスタンスへ添付しない限り、クライアントに返送されません。

    $cookie = cookie('name', 'value', $minutes);

    return response('Hello World')->cookie($cookie);

<a name="expiring-cookies-early"></a>
#### クッキーの早期期限切れ

送信レスポンスの`withoutCookie`メソッドを介してクッキーを期限切れにすることにより、そのクッキーを削除できます。

    return response('Hello World')->withoutCookie('name');

送信レスポンスのインスタンスがまだない場合は、`Cookie`ファサードの`queue`メソッドを使用してCookieを期限切れにすることができます。

    Cookie::queue(Cookie::forget('name'));

<a name="cookies-and-encryption"></a>
### クッキーと暗号化

Laravelにより生成されるクッキーは、クライアントにより変更されたり、読まれたりされないようにデフォルトで暗号化され、署名されます。アプリケーションで生成する特定のクッキーで暗号化を無効にしたい場合は、`app/Http/Middleware`ディレクトリ中に存在する、`App\Http\Middleware\EncryptCookies`ミドルウェアの`$except`プロパティで指定してください。

    /**
     * 暗号化しないクッキー名
     *
     * @var array
     */
    protected $except = [
        'cookie_name',
    ];

<a name="redirects"></a>
## リダイレクト

リダイレクトのレスポンスは`Illuminate\Http\RedirectResponse`クラスのインスタンスであり、ユーザーを他のURLへリダイレクトさせるために必要なしっかりとしたヘッダを含んでいます。`RedirectResponse`インスタンスを生成するにはさまざまな方法があります。一番簡単な方法は、グローバルな`redirect`ヘルパを使う方法です。

    Route::get('/dashboard', function () {
        return redirect('home/dashboard');
    });

送信したフォームが無効な場合など、ユーザーを以前の場所にリダイレクトしたい場合があります。これは、グローバルな`back`ヘルパ関数を使用して行うことができます。この機能は[セッション](/docs/{{version}}/session)を利用するため、`back`関数を呼び出すルートが`web`ミドルウェアグループを使用していることを確認してください。

    Route::post('/user/profile', function () {
        // レスポンスのバリデーション処理…

        return back()->withInput();
    });

<a name="redirecting-named-routes"></a>
### 名前付きルートへのリダイレクト

`redirect`ヘルパを引数無しで呼ぶと、`Illuminate\Routing\Redirector`インスタンスが返され、`Redirector`インスタンスのメソッドが呼び出せるようになります。たとえば、名前付きルートに対する`RedirectResponse`を生成したい場合は、`route`メソッドが使えます。

    return redirect()->route('login');

ルートにパラメーターがある場合は、`route`メソッドの第２引数として渡してください。

    // /profile/{id}のURIを持つルートの場合

    return redirect()->route('profile', ['id' => 1]);

<a name="populating-parameters-via-eloquent-models"></a>
#### Eloquentモデルによる、パラメータの埋め込み

Eloquentモデルの"ID"をルートパラメーターとしてリダイレクトする場合は、モデルをそのまま渡してください。IDは自動的にとり出されます。

    //  /profile/{id}のURIを持つルートの場合

    return redirect()->route('profile', [$user]);

ルートパラメータへ配置する値をカスタマイズする場合は、ルートパラメータ定義(`/profile/{id:slug}`)でカラムを指定するか、Eloquentモデルの`getRouteKey`メソッドをオーバーライドします。

    /**
     * モデルのルートキー値の取得
     *
     * @return mixed
     */
    public function getRouteKey()
    {
        return $this->slug;
    }

<a name="redirecting-controller-actions"></a>
### コントローラアクションへのリダイレクト

[コントローラアクション](/docs/{{version}}/controllers)に対するリダイレクトを生成することもできます。そのためには、コントローラとアクションの名前を`action`メソッドに渡してください。

    use App\Http\Controllers\UserController;

    return redirect()->action([UserController::class, 'index']);

コントローラルートにパラメーターが必要ならば、`action`メソッドの第２引数として渡してください。

    return redirect()->action(
        [UserController::class, 'profile'], ['id' => 1]
    );

<a name="redirecting-external-domains"></a>
### 外部ドメインへのリダイレクト

アプリケーション外のドメインへリダイレクトする必要がときどき起きます。このためには`away`メソッドを呼び出してください。これは`RedirectResponse`を生成しますが、URLエンコードを追加せず、バリデーションも検証も行いません。

    return redirect()->away('https://www.google.com');

<a name="redirecting-with-flashed-session-data"></a>
### フラッシュデータを保存するリダイレクト

新しいURLへリダイレクトし、[セッションへフラッシュデータを保存する](/docs/{{version}}/session#flash-data)のは、一度にまとめて行われる典型的な作業です。典型的な使い方は、あるアクションが実行成功した後に、実効成功メッセージをフラッシュデータとしてセッションに保存する場合でしょう。これに便利なように、`RedirectResponse`インスタンスを生成し、メソッドチェーンを一つだけさっと書けば、データをセッションへ保存できるようになっています。

    Route::post('/user/profile', function () {
        // …

        return redirect('dashboard')->with('status', 'Profile updated!');
    });

ユーザーを新しいページヘリダイレクトした後、[セッション](/docs/{{version}}/session)へ保存したフラッシュデータのメッセージを取り出して、表示します。たとえば、[Blade記法](/docs/{{version}}/blade)を使ってみましょう。

    @if (session('status'))
        <div class="alert alert-success">
            {{ session('status') }}
        </div>
    @endif

<a name="redirecting-with-input"></a>
#### 入力と共にリダイレクト

ユーザーを新しい場所にリダイレクトする前に、`RedirectResponse`インスタンスが提供する`withInput`メソッドを使用して、現在のリクエストの入力データをセッションへ一時保存できます。これは通常、ユーザーがバリデーションエラーに遭遇した場合に行います。入力をセッションに一時保存したら、次のリクエスト中で簡単に[取得](/docs/{{version}}/requests#retrieveing-old-input)してフォームを再入力できます。

    return back()->withInput();

<a name="other-response-types"></a>
## 他のレスポンスタイプ

`response`ヘルパは、他のタイプのレスポンスインスタンスを生成するために便利です。`response`ヘルパが引数なしで呼び出されると、`Illuminate\Contracts\Routing\ResponseFactory`[契約](/docs/{{version}}/contracts)が返されます。この契約はレスポンスを生成するための、さまざまなメソッドを提供しています。

<a name="view-responses"></a>
### Viewレスポンス

レスポンスのステータスやヘッダをコントロールしながらも、レスポンス内容として[ビュー](/docs/{{version}}/views)を返す必要がある場合は、`view`メソッドを使用してください。

    return response()
                ->view('hello', $data, 200)
                ->header('Content-Type', $type);

もちろん、カスタムHTTPステータスコードやカスタムヘッダを渡す必要がない場合は、グローバルな`view`ヘルパ関数が使用できます。

<a name="json-responses"></a>
### JSONレスポンス

`json`メソッドは自動的に`Content-Type`ヘッダを`application/json`にセットし、同時に指定された配列を`json_encode` PHP関数によりJSONへ変換します。

    return response()->json([
        'name' => 'Abigail',
        'state' => 'CA',
    ]);

JSONPレスポンスを生成したい場合は、`json`メソッドと`withCallback`メソッドを組み合わせてください。

    return response()
                ->json(['name' => 'Abigail', 'state' => 'CA'])
                ->withCallback($request->input('callback'));

<a name="file-downloads"></a>
### Fileダウンロード

`download`メソッドを使用して、ユーザーのブラウザに対し、指定パスのファイルをダウンロードするように強制するレスポンスを生成できます。`download`メソッドは、メソッドの引数の２番目にファイル名を取ります。これにより、ユーザーがファイルをダウンロードするときに表示するファイル名が決まります。最後に、HTTPヘッダの配列をメソッドの３番目の引数として渡すこともできます。

    return response()->download($pathToFile);

    return response()->download($pathToFile, $name, $headers);

> {note} ファイルダウンロードを管理しているSymfony HttpFoundationクラスは、ASCIIのダウンロードファイル名を指定するよう要求しています。

<a name="streamed-downloads"></a>
#### ストリームダウンロード

特定の操作の文字列レスポンスを、操作の内容をディスクに書き込まずにダウンロード可能なレスポンスへ変換したい場合もあるでしょう。このシナリオでは、`streamDownload`メソッドを使用します。このメソッドは、コールバック、ファイル名、およびオプションのヘッダ配列を引数に取ります。

    use App\Services\GitHub;

    return response()->streamDownload(function () {
        echo GitHub::api('repo')
                    ->contents()
                    ->readme('laravel', 'laravel')['contents'];
    }, 'laravel-readme.md');

<a name="file-responses"></a>
### Fileレスポンス

`file`メソッドは、ダウンロードする代わりに、ブラウザへ画像やPDFのようなファイルを表示するために使用します。このメソッドは第1引数にファイルパス、第2引数にヘッダの配列を指定します。

    return response()->file($pathToFile);

    return response()->file($pathToFile, $headers);

<a name="response-macros"></a>
## レスポンスマクロ

さまざまなルートやコントローラで再利用できるカスタムレスポンスを定義する場合は、`Response`ファサードで`macro`メソッドを使用してください。通常、このメソッドは、`App\Providers\AppServiceProvider`サービスプロバイダなど、アプリケーションの[サービスプロバイダ](/docs/{{version}}/providers)の１つの`boot`メソッドから呼び出す必要があります。

    <?php

    namespace App\Providers;

    use Illuminate\Support\Facades\Response;
    use Illuminate\Support\ServiceProvider;

    class AppServiceProvider extends ServiceProvider
    {
        /**
         * 全アプリケーションサービスの初期起動処理
         *
         * @return void
         */
        public function boot()
        {
            Response::macro('caps', function ($value) {
                return Response::make(strtoupper($value));
            });
        }
    }

`macro`関数は、最初の引数に名前を受け入れ、２番目の引数にクロージャを取ります。マクロのクロージャは、`ResponseFactory`実装または`response`ヘルパからマクロ名を呼び出すときに実行されます。

    return response()->caps('foo');
