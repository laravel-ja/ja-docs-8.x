# HTTPレスポンス

- [レスポンスの生成](#creating-responses)
    - [ヘッダの付加](#attaching-headers-to-responses)
    - [クッキーの付加](#attaching-cookies-to-responses)
    - [クッキーと暗号化](#cookies-and-encryption)
- [リダイレクト](#redirects)
    - [名前付きルートへのリダイレクト](#redirecting-named-routes)
    - [コントローラアクションへのリダイレクト](#redirecting-controller-actions)
    - [外部ドメインへのリダイレクト](#redirecting-external-domains)
    - [フラッシュデータを保存するリダイレクト](#redirecting-with-flashed-session-data)
- [他のレスポンスタイプ](#other-response-types)
    - [Viewレスポンス](#view-responses)
    - [JSONレスポンス](#json-responses)
    - [Fileダウンロード](#file-downloads)
    - [Fileレスポンス](#file-responses)
- [レスポンスマクロ](#response-macros)

<a name="creating-responses"></a>
## レスポンスの生成

#### 文字列と配列

当然ながらすべてのルートやコントローラは、ユーザーのブラウザーに対し、何らかのレスポンスを返す必要があります。Laravelはレスポンスを返すためにさまざまな手段を用意しています。一番基本的なレスポンスは、ルートかコントローラから文字列を返します。フレームワークが自動的に、文字列を完全なHTTPレスポンスへ変換します。

    Route::get('/', function () {
        return 'Hello World';
    });

ルートやコントローラから文字列を返す他に、配列も返せます。フレームワークは自動的に、配列をJSONレスポンスへ変換します。

    Route::get('/', function () {
        return [1, 2, 3];
    });

> {tip} [Eloquentコレクション](/docs/{{version}}/eloquent-collections)も返せることを知っていますか？　自動的にJSONへ変換されます。試してください！

#### レスポンスオブジェクト

通常、皆さんは単純な文字列や配列をルートアクションから返すだけじゃありませんよね。代わりに、`Illuminate\Http\Response`インスタンスか[ビュー](/docs/{{version}}/views)を返したいですよね。

完全な`Response`インスタンスを返せば、レスポンスのHTTPステータスコードやヘッダをカスタマイズできます。`Response`インスタンスは、`Symfony\Component\HttpFoundation\Response`クラスを継承しており、HTTPレスポンスを構築するためにさまざまなメソッドを提供しています。

    Route::get('home', function () {
        return response('Hello World', 200)
                      ->header('Content-Type', 'text/plain');
    });

<a name="attaching-headers-to-responses"></a>
#### ヘッダの付加

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

#### キャッシュコントロール・ミドルウェア

ルートグループへ`Cache-Control`ヘッダを簡単に指定できるよう、Laravelは`cache.headers`を用意しています。ディレクティブのリストの中で`etag`が指定されていると、レスポンスコンテンツのMD5ハッシュが、ETag識別子へ自動的にセットされます。

    Route::middleware('cache.headers:public;max_age=2628000;etag')->group(function () {
        Route::get('privacy', function () {
            // ...
        });

        Route::get('terms', function () {
            // ...
        });
    });

<a name="attaching-cookies-to-responses"></a>
#### クッキーの付加

レスポンスインスタンスの`cookie`メソッドで、レスポンスへ簡単にクッキーを付加できます。たとえば、`cookie`メソッドでクッキーを生成し、レスポンスインスタンスへ、さっと付加してみましょう。

    return response($content)
                    ->header('Content-Type', $type)
                    ->cookie('name', 'value', $minutes);

`cookie`メソッドは、さらに使用機会が少ない引数をいくつか受け付けます。これらの引数は、全般的にPHPネイティブの[setcookie](https://secure.php.net/manual/en/function.setcookie.php)メソッドに指定する引数と、同じ目的、同じ意味合いを持っています。

    ->cookie($name, $value, $minutes, $path, $domain, $secure, $httpOnly)

もしくは、アプリケーションから送り出すレスポンスへアタッチするクッキーを「キュー」するために、`Cookie`ファサードが使えます。`queue`メソッドは、`Cookie`インスタンスか`Cookie`インスタンスを生成するために必要な引数を受け取ります。こうしたクッキーは、ブラウザにレスポンスが送信される前にアタッチされます。

    Cookie::queue(Cookie::make('name', 'value', $minutes));

    Cookie::queue('name', 'value', $minutes);

<a name="cookies-and-encryption"></a>
#### クッキーと暗号化

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

    Route::get('dashboard', function () {
        return redirect('home/dashboard');
    });

たとえば送信されたフォーム内容にエラーがある場合など、直前のページヘユーザーをリダイレクトさせたい場合もあります。グローバルな`back`ヘルパ関数を使ってください。この機能は[セッション](/docs/{{version}}/session)を利用しているため、`back`関数を使用するルートは`web`ミドルウェアグループに属しているか、セッションミドルウェアが適用されることを確認してください。

    Route::post('user/profile', function () {
        // レスポンスのバリデーション処理…

        return back()->withInput();
    });

<a name="redirecting-named-routes"></a>
### 名前付きルートへのリダイレクト

`redirect`ヘルパを引数無しで呼ぶと、`Illuminate\Routing\Redirector`インスタンスが返され、`Redirector`インスタンスのメソッドが呼び出せるようになります。たとえば、名前付きルートに対する`RedirectResponse`を生成したい場合は、`route`メソッドが使えます。

    return redirect()->route('login');

ルートにパラメーターがある場合は、`route`メソッドの第２引数として渡してください。

    // profile/{id}のURIへのリダイレクト

    return redirect()->route('profile', ['id' => 1]);

#### Eloquentモデルによる、パラメータの埋め込み

Eloquentモデルの"ID"をルートパラメーターとしてリダイレクトする場合は、モデルをそのまま渡してください。IDは自動的にとり出されます。

    // profile/{id}のURIへのリダイレクト

    return redirect()->route('profile', [$user]);

ルートパラメータに埋め込む値をカスタマイズしたい場合は、ルートパラメータ定義でカラムを指定するか（`profile/{id:slug}`）、Eloquentモデルの`getRouteKey`メソッドをオーバーライドします。

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

[コントローラアクション](/docs/{{version}}/controllers)に対するリダイレクトを生成することもできます。そのためには、コントローラとアクションの名前を`action`メソッドに渡してください。Laravelの`RouteServiceProvider`により、ベースのコントローラ名前空間が自動的に設定されるため、コントローラの完全名前空間名を指定する必要がないことを覚えておいてください。

    return redirect()->action('HomeController@index');

コントローラルートにパラメーターが必要ならば、`action`メソッドの第２引数として渡してください。

    return redirect()->action(
        'UserController@profile', ['id' => 1]
    );

<a name="redirecting-external-domains"></a>
### 外部ドメインへのリダイレクト

アプリケーション外のドメインへリダイレクトする必要がときどき起きます。このためには`away`メソッドを呼び出してください。これは`RedirectResponse`を生成しますが、URLエンコードを追加せず、バリデーションも検証も行いません。

    return redirect()->away('https://www.google.com');

<a name="redirecting-with-flashed-session-data"></a>
### フラッシュデータを保存するリダイレクト

新しいURLへリダイレクトし、[セッションへフラッシュデータを保存する](/docs/{{version}}/session#flash-data)のは、一度にまとめて行われる典型的な作業です。典型的な使い方は、あるアクションが実行成功した後に、実効成功メッセージをフラッシュデータとしてセッションに保存する場合でしょう。これに便利なように、`RedirectResponse`インスタンスを生成し、メソッドチェーンを一つだけさっと書けば、データをセッションへ保存できるようになっています。

    Route::post('user/profile', function () {
        // ユーザープロフィールの更新処理…

        return redirect('dashboard')->with('status', 'Profile updated!');
    });

ユーザーを新しいページヘリダイレクトした後、[セッション](/docs/{{version}}/session)へ保存したフラッシュデータのメッセージを取り出して、表示します。たとえば、[Blade記法](/docs/{{version}}/blade)を使ってみましょう。

    @if (session('status'))
        <div class="alert alert-success">
            {{ session('status') }}
        </div>
    @endif

<a name="other-response-types"></a>
## 他のレスポンスタイプ

`response`ヘルパは、他のタイプのレスポンスインスタンスを生成するために便利です。`response`ヘルパが引数なしで呼び出されると、`Illuminate\Contracts\Routing\ResponseFactory`[契約](/docs/{{version}}/contracts)が返されます。この契約はレスポンスを生成するための、さまざまなメソッドを提供しています。

<a name="view-responses"></a>
### Viewレスポンス

レスポンスのステータスやヘッダをコントロールしながらも、レスポンス内容として[ビュー](/docs/{{version}}/views)を返す必要がある場合は、`view`メソッドを使用してください。

    return response()
                ->view('hello', $data, 200)
                ->header('Content-Type', $type);

もちろん、カスタムHTTPステータスコードやヘッダの指定が不必要であれば、シンプルにグローバル`view`ヘルパ関数を使用することもできます。

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

`download`メソッドは指定したパスのファイルをダウンロードように、ブラウザへ強要するレスポンスを生成するために使用します。`download`メソッドはファイル名を第２引数として受け取り、ユーザーがダウンロードするファイル名になります。第３引数にHTTPヘッダの配列を渡すこともできます。

    return response()->download($pathToFile);

    return response()->download($pathToFile, $name, $headers);

    return response()->download($pathToFile)->deleteFileAfterSend();

> {note} ファイルダウンロードを管理しているSymfony HttpFoundationクラスは、ASCIIのダウンロードファイル名を指定するよう要求しています。

#### ストリームダウンロード

操作するコンテンツをディスクへ書き込まずに、指定した操作の文字列レスポンスをダウンロード可能なレスポンスへ変えたい場合もあります。そうしたシナリオでは、`streamDownload`メソッドを使用します。このメソッドは引数として、コールバック、ファイル名、それにオプションとしてヘッダの配列を受け取ります。

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

いろいろなルートやコントローラで、再利用するためのカスタムレスポンスを定義したい場合は`Response`ファサードの`macro`メソッドが使用できます。たとえば、[サービスプロバイダ](/docs/{{version}}/providers)の`boot`メソッドで定義します。

    <?php

    namespace App\Providers;

    use Illuminate\Support\Facades\Response;
    use Illuminate\Support\ServiceProvider;

    class ResponseMacroServiceProvider extends ServiceProvider
    {
        /**
         * アプリケーションのレスポンスマクロ登録
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

`macro`メソッドは登録名を第１引数、クロージャを第２引数に取ります。マクロのクロージャは`ResponseFactory`の実装か`response`ヘルパに対し、登録名を呼び出すことで実行されます。

    return response()->caps('foo');
