# HTTPクライアント

- [イントロダクション](#introduction)
- [リクエストの作成](#making-requests)
    - [リクエストデータ](#request-data)
    - [ヘッダ](#headers)
    - [認証](#authentication)
    - [タイムアウト](#timeout)
    - [再試行](#retries)
    - [エラー処理](#error-handling)
    - [Guzzleオプション](#guzzle-options)
- [同時リクエスト](#concurrent-requests)
- [テスト](#testing)
    - [レスポンスのfake](#faking-responses)
    - [レスポンスの検査](#inspecting-requests)
- [イベント](#events)

<a name="introduction"></a>
## イントロダクション

Laravelは、[Guzzle HTTPクライアント](http://docs.guzzlephp.org/en/stable/)の周りに表現力豊かで最小限のAPIを提供し、他のWebアプリケーションと通信するための外部HTTPリクエストをすばやく作成できるようにします。LaravelによるGuzzleのラッパーは、最も一般的なユースケースと素晴らしい開発者エクスペリエンスに焦点を当てています。

使い始める前に、アプリケーションの依存関係としてGuzzleパッケージを確実にインストールしてください。デフォルトでLaravelはこの依存パッケージを自動的に含めます。もし、以前にパッケージを削除したことがある場合は、Composerを介して再度インストールしてください。

    composer require guzzlehttp/guzzle

<a name="making-requests"></a>
## リクエストの作成

リクエストを行うには、`Http`ファサードが提供する`get`、`post`、`put`、`patch`、`delete`メソッドを使用します。まず、外部のURLに対して基本的な`GET`リクエストを行う方法を見てみましょう。

    use Illuminate\Support\Facades\Http;

    $response = Http::get('http://example.com');

`get`メソッドは`Illuminate\Http\Client\Response`のインスタンスを返します。これは、レスポンスを調べるために使用できるさまざまなメソッドを提供します。

    $response->body() : string;
    $response->json() : array|mixed;
    $response->object() : object;
    $response->collect() : Illuminate\Support\Collection;
    $response->status() : int;
    $response->ok() : bool;
    $response->successful() : bool;
    $response->failed() : bool;
    $response->serverError() : bool;
    $response->clientError() : bool;
    $response->header($header) : string;
    $response->headers() : array;

`Illuminate\Http\Client\Response`オブジェクトはPHPの`ArrayAccess`インターフェイスも実装しており、そのレスポンスのJSONレスポンスデータへ直接アクセスできます。

    return Http::get('http://example.com/users/1')['name'];

<a name="dumping-requests"></a>
#### リクエストのダンプ

送信するリクエストインスタンスを送信して、スクリプトの実行を終了する前にダンプしたい場合は、リクエスト定義の先頭に`dd`メソッドを追加できます。

    return Http::dd()->get('http://example.com');

<a name="request-data"></a>
### リクエストデータ

もちろん、`POST`、`PUT`、`PATCH`リクエストを作成するときは、リクエストとともに追加のデータを送信するのが一般的であるため、これらのメソッドは２番目の引数としてデータの配列を受け入れます。デフォルトでデータは`application/json`コンテンツタイプを使用して送信されます。

    use Illuminate\Support\Facades\Http;

    $response = Http::post('http://example.com/users', [
        'name' => 'Steve',
        'role' => 'Network Administrator',
    ]);

<a name="get-request-query-parameters"></a>
#### GETリクエストクエリパラメータ

`GET`リクエストを行うときは、クエリ文字列をURLに直接追加するか、キー／値ペアの配列を`get`メソッドの２番目の引数として渡せます。

    $response = Http::get('http://example.com/users', [
        'name' => 'Taylor',
        'page' => 1,
    ]);

<a name="sending-form-url-encoded-requests"></a>
#### フォームURLエンコードされたリクエストの送信

`application/x-www-form-urlencoded`コンテンツタイプを使用してデータを送信する場合は、リクエストを行う前に`asForm`メソッドを呼び出す必要があります。

    $response = Http::asForm()->post('http://example.com/users', [
        'name' => 'Sara',
        'role' => 'Privacy Consultant',
    ]);

<a name="sending-a-raw-request-body"></a>
#### 素のリクエスト本文の送信

リクエストを行うときに素のリクエスト本文を指定する場合は、`withBody`メソッドを使用できます。コンテンツタイプは、メソッドの２番目の引数を介して提供できます。

    $response = Http::withBody(
        base64_encode($photo), 'image/jpeg'
    )->post('http://example.com/photo');

<a name="multi-part-requests"></a>
#### マルチパートリクエスト

ファイルをマルチパートリクエストとして送信する場合は、リクエストを行う前に`attach`メソッドを呼び出す必要があります。このメソッドは、ファイルの名前とその内容を引数に取ります。必要に応じて、ファイルのファイル名と見なす３番目の引数を指定できます。

    $response = Http::attach(
        'attachment', file_get_contents('photo.jpg'), 'photo.jpg'
    )->post('http://example.com/attachments');

ファイルの素の内容を渡す代わりに、ストリームリソースを渡すこともできます。

    $photo = fopen('photo.jpg', 'r');

    $response = Http::attach(
        'attachment', $photo, 'photo.jpg'
    )->post('http://example.com/attachments');

<a name="headers"></a>
### ヘッダ

ヘッダは、`withHeaders`メソッドを使用してリクエストに追加できます。この`withHeaders`メソッドは、キー／値ペアの配列を引数に取ります。

    $response = Http::withHeaders([
        'X-First' => 'foo',
        'X-Second' => 'bar'
    ])->post('http://example.com/users', [
        'name' => 'Taylor',
    ]);

`accept`メソッドを使って、アプリケーションがリクエストへのレスポンスとして期待するコンテンツタイプを指定できます。

    $response = Http::accept('application/json')->get('http://example.com/users');

利便性のため、`acceptJson`メソッドを使って、アプリケーションがリクエストへのレスポンスとして`application/json`コンテンツタイプを期待することを素早く指定できます。

    $response = Http::acceptJson()->get('http://example.com/users');

<a name="authentication"></a>
### 認証

基本認証のログイン情報とダイジェスト認証ログイン情報は、それぞれ`withBasicAuth`メソッドと`withDigestAuth`メソッドを使用して指定します。

    // BASIC認証
    $response = Http::withBasicAuth('taylor@laravel.com', 'secret')->post(...);

    // ダイジェスト認証
    $response = Http::withDigestAuth('taylor@laravel.com', 'secret')->post(...);

<a name="bearer-tokens"></a>
#### Bearerトークン

リクエストの`Authorization`ヘッダにBearerトークンをすばやく追加したい場合は、`withToken`メソッドを使用できます。

    $response = Http::withToken('token')->post(...);

<a name="timeout"></a>
### タイムアウト

`timeout`メソッドを使用して、レスポンスを待機する最大秒数を指定できます。

    $response = Http::timeout(3)->get(...);

指定したタイムアウトを超えると、`Illuminate\Http\Client\ConnectionException`インスタンスを投げます。

<a name="retries"></a>
### 再試行

クライアントまたはサーバのエラーが発生した場合に、HTTPクライアントがリクエストを自動的に再試行するようにしたい場合は、`retry`メソッドを使用します。`retry`メソッドは２つの引数をとります。リクエストを試行する最大回数とLaravelが試行の間に待機するミリ秒数です。

    $response = Http::retry(3, 100)->post(...);

すべてのリクエストが失敗した場合、`Illuminate\Http\Client\RequestException`インスタンスを投げます。

<a name="error-handling"></a>
### エラー処理

Guzzleのデフォルト動作とは異なり、LaravelのHTTPクライアントラッパーは、クライアントまたはサーバのエラー(サーバからの「400」および「500」レベルの応答)で例外を投げません。`successful`、`clientError`、`serverError`メソッドを使用して、これらのエラーのいずれかが返されたかどうかを判定できます。

    // ステータスコードが200以上300未満か判定
    $response->successful();

    // ステータスコードが400以上か判定
    $response->failed();

    // レスポンスに400レベルのステータスコードがあるかを判定
    $response->clientError();

    // レスポンスに500レベルのステータスコードがあるかを判定
    $response->serverError();

<a name="throwing-exceptions"></a>
#### 例外を投げる

あるレスポンスインスタンスのレスポンスステータスコードがクライアントまたはサーバのエラーを示している場合に`Illuminate\Http\Client\RequestException`のインスタンスを投げたい場合場合は、`throw`メソッドを使用します。

    $response = Http::post(...);

    // クライアントまたはサーバのエラーが発生した場合は、例外を投げる
    $response->throw();

    return $response['user']['id'];

`Illuminate\Http\Client\RequestException`インスタンスにはパブリック`$response`プロパティがあり、返ってきたレスポンスを検査できます。

`throw`メソッドは、エラーが発生しなかった場合にレスポンスインスタンスを返すので、他の操作を`throw`メソッドにチェーンできます。

    return Http::post(...)->throw()->json();

例外がなげられる前に追加のロジックを実行したい場合は、`throw`メソッドにクロージャを渡せます。クロージャを呼び出した後に、例外を自動的に投げるため、クロージャ内から例外を再発行する必要はありません。

    return Http::post(...)->throw(function ($response, $e) {
        //
    })->json();

<a name="guzzle-options"></a>
### Guzzleオプション

`withOptions`メソッドを使用して、追加の[Guzzleリクエストオプション](http://docs.guzzlephp.org/en/stable/request-options.html)を指定できます。`withOptions`メソッドは、キー／値ペアの配列を引数に取ります。

    $response = Http::withOptions([
        'debug' => true,
    ])->get('http://example.com/users');

<a name="concurrent-requests"></a>
## 同時リクエスト

複数のHTTPリクエストを同時に実行したい場合があります。言い換えれば、複数のリクエストを順番に発行するのではなく、同時にディスパッチしたい状況です。これにより、低速なHTTP APIを操作する際のパフォーマンスが大幅に向上します。

さいわいに、`pool`メソッドを使い、これを実現できます。`pool`メソッドは、`Illuminate\Http\Client\Pool`インスタンスを受け取るクロージャを引数に取り、簡単にリクエストプールにリクエストを追加してディスパッチできます。

    use Illuminate\Http\Client\Pool;
    use Illuminate\Support\Facades\Http;

    $responses = Http::pool(fn (Pool $pool) => [
        $pool->get('http://localhost/first'),
        $pool->get('http://localhost/second'),
        $pool->get('http://localhost/third'),
    ]);

    return $responses[0]->ok() &&
           $responses[1]->ok() &&
           $responses[2]->ok();

ご覧のように、各レスポンスインスタンスは、プールに追加した順でアクセスできます。必要に応じ`as`メソッドを使い、リクエストに名前を付けると、対応するレスポンスへ名前でアクセスできるようになります。

    use Illuminate\Http\Client\Pool;
    use Illuminate\Support\Facades\Http;

    $responses = Http::pool(fn (Pool $pool) => [
        $pool->as('first')->get('http://localhost/first'),
        $pool->as('second')->get('http://localhost/second'),
        $pool->as('third')->get('http://localhost/third'),
    ]);

    return $responses['first']->ok();

<a name="testing"></a>
## テスト

多くのLaravelサービスは、テストを簡単かつ表現力豊かに作成するのに役立つ機能を提供しています。LaravelのHTTPラッパーも例外ではありません。`Http`ファサードの`fake`メソッドを使用すると、リクエストが行われたときに、スタブ/ダミーレスポンスを返すようにHTTPクライアントに指示できます。

<a name="faking-responses"></a>
### レスポンスのfake

たとえば、リクエストごとに空の`200`ステータスコードレスポンスを返すようにHTTPクライアントに指示するには、引数なしで`fake`メソッドを呼びだしてください。

    use Illuminate\Support\Facades\Http;

    Http::fake();

    $response = Http::post(...);

> {note} リクエストをfakeする場合、HTTPクライアントミドルウェアは実行されません。これらのミドルウェアが正しく実行されたかのように、fakeレスポンスに対するエクスペクテーションを定義する必要があります。

<a name="faking-specific-urls"></a>
#### 特定のURLのfake

もしくは、配列を`fake`メソッドに渡すこともできます。配列のキーは、fakeしたいURLパターンとそれに関連するレスポンスを表す必要があります。`*`文字はワイルドカード文字として使用できます。FakeしないURLに対して行うリクエストは、実際に実行されます。`Http`ファサードの`response`メソッドを使用して、これらのエンドポイントのスタブ/fakeのレスポンスを作成できます。

    Http::fake([
        // GitHubエンドポイントのJSONレスポンスをスタブ
        'github.com/*' => Http::response(['foo' => 'bar'], 200, $headers),

        // Googleエンドポイントの文字列レスポンスをスタブ
        'google.com/*' => Http::response('Hello World', 200, $headers),
    ]);

一致しないすべてのURLをスタブするフォールバックURLパターンを指定する場合は、単一の`*`文字を使用します。

    Http::fake([
        // GitHubエンドポイントのJSONレスポンスをスタブ
        'github.com/*' => Http::response(['foo' => 'bar'], 200, ['Headers']),

        // 他のすべてのエンドポイントの文字列をスタブ
        '*' => Http::response('Hello World', 200, ['Headers']),
    ]);

<a name="faking-response-sequences"></a>
#### fakeレスポンスの順番

場合によっては、単一のURLが特定の順序で一連のkakeレスポンスを返すように指定する必要があります。これは、`Http::sequence`メソッドを使用してレスポンスを作成することで実現できます。

    Http::fake([
        // GitHubエンドポイントの一連のレスポンスをスタブ
        'github.com/*' => Http::sequence()
                                ->push('Hello World', 200)
                                ->push(['foo' => 'bar'], 200)
                                ->pushStatus(404),
    ]);

レスポンスシーケンス内のすべてのレスポンスが消費されると、以降のリクエストに対し、レスポンスシーケンスは例外を投げます。シーケンスが空になったときに返すデフォルトのレスポンスを指定する場合は、`whenEmpty`メソッドを使用します。

    Http::fake([
        // GitHubエンドポイントの一連の応答をスタブ
        'github.com/*' => Http::sequence()
                                ->push('Hello World', 200)
                                ->push(['foo' => 'bar'], 200)
                                ->whenEmpty(Http::response()),
    ]);

一連のレスポンスをfakeしたいが、fakeする必要がある特定のURLパターンを指定する必要がない場合は、`Http::fakeSequence`メソッドを使用します。

    Http::fakeSequence()
            ->push('Hello World', 200)
            ->whenEmpty(Http::response());

<a name="fake-callback"></a>
#### Fakeコールバック

特定のエンドポイントに対して返すレスポンスを決定するために、より複雑なロジックが必要な場合は、`fake`メソッドにクロージャを渡すことができます。このクロージャは`Illuminate\Http\Client\Request`インスタンスを受け取り、レスポンスインスタンスを返す必要があります。クロージャ内で、返すレスポンスのタイプを決定するために必要なロジックを実行できます。

    Http::fake(function ($request) {
        return Http::response('Hello World', 200);
    });

<a name="inspecting-requests"></a>
### レスポンスの検査

レスポンスをfakeする場合、アプリケーションが正しいデータまたはヘッダを送信していることを確認するために、クライアントが受信するリクエストを調べたい場合があります。これは、`Http::fake`を呼び出した後に`Http::assertSent`メソッドを呼び出し実現します。

`assertSent`メソッドは、`Illuminate\Http\Client\Request`インスタンスを受け取るクロージャを引数に受け、リクエストがエクスペクテーションに一致するかを示す論理値を返す必要があります。テストに合格するには、指定するエクスペクテーションに一致する少なくとも１つのリクエストが発行される必要があります。

    use Illuminate\Http\Client\Request;
    use Illuminate\Support\Facades\Http;

    Http::fake();

    Http::withHeaders([
        'X-First' => 'foo',
    ])->post('http://example.com/users', [
        'name' => 'Taylor',
        'role' => 'Developer',
    ]);

    Http::assertSent(function (Request $request) {
        return $request->hasHeader('X-First', 'foo') &&
               $request->url() == 'http://example.com/users' &&
               $request['name'] == 'Taylor' &&
               $request['role'] == 'Developer';
    });

必要に応じて、`assertNotSent`メソッドを使用して特定のリクエストが送信されないことを宣言できます。

    use Illuminate\Http\Client\Request;
    use Illuminate\Support\Facades\Http;

    Http::fake();

    Http::post('http://example.com/users', [
        'name' => 'Taylor',
        'role' => 'Developer',
    ]);

    Http::assertNotSent(function (Request $request) {
        return $request->url() === 'http://example.com/posts';
    });

または、`assertNothingSent`メソッドを使用して、テスト中にリクエストが送信されないことを宣言することもできます。

    Http::fake();

    Http::assertNothingSent();

<a name="events"></a>
## イベント

LaravelはHTTPリクエストを送信する過程で、3つのイベントを発行します。`RequestSending`イベントはリクエストが送信される前に発生し、`ResponseReceived`イベントは指定したリクエストに対するレスポンスを受け取った後に発行します。`ConnectionFailed`イベントは、指定したリクエストに対するレスポンスを受信できなかった場合に発行します。

`RequestSending`と`ConnectionFailed`イベントは両方とも、パブリックの`$request`プロパティを含んでおり、これを使えば`Illuminate\Http\Client\Request`インスタンスを調べられます。同様に、`ResponseReceived`イベントは、`$request`プロパティと`$response`プロパティを含んでおり、`Illuminate\Http\Client\Response`インスタンスの検査に使用できます。このイベントのイベントリスナは、`App\Providers\EventServiceProvider`サービスプロバイダで登録します。

    /**
     * アプリケーションのイベントリスナマップ
     *
     * @var array
     */
    protected $listen = [
        'Illuminate\Http\Client\Events\RequestSending' => [
            'App\Listeners\LogRequestSending',
        ],
        'Illuminate\Http\Client\Events\ResponseReceived' => [
            'App\Listeners\LogResponseReceived',
        ],
        'Illuminate\Http\Client\Events\ConnectionFailed' => [
            'App\Listeners\LogConnectionFailed',
        ],
    ];
