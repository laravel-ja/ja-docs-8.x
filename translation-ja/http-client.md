# HTTPクライアント

- [イントロダクション](#introduction)
- [リクエスト作成](#making-requests)
    - [リクエストデータ](#request-data)
    - [ヘッダ](#headers)
    - [認証](#authentication)
    - [タイムアウト](#timeout)
    - [リトライ](#retries)
    - [エラー処理](#error-handling)
    - [Guzzleオプション](#guzzle-options)
- [テスト](#testing)
    - [レスポンスのFake](#faking-responses)
    - [レスポンスの調査](#inspecting-requests)

<a name="introduction"></a>
## イントロダクション

他のWebアプリケーションと連携を取る、送信HTTPリクエストを簡単に作成できるよう、Laravelは小さくて読み書きしやすい[Guzzle HTTPクライアント](http://docs.guzzlephp.org/en/stable/)のAPIを提供しています。LaravelのGuzzleラッパーはもっとも繁用されるユースケースと開発者が素晴らしい体験をできることに重点を置いています。

取り掛かる前に、アプリケーションの依存パッケージとしてGuzzleパッケージをインストールする必要があります。Laravelはデフォルトとしてこの依存パッケージを含んでいます。

    composer require guzzlehttp/guzzle

<a name="making-requests"></a>
## リクエスト作成

リクエストを作成するには、`get`、`post`、`put`、`patch`、`delete`メソッドを使用します。最初に基本となる`GET`リクエストをどのように作成するのか見てみましょう。

    use Illuminate\Support\Facades\Http;

    $response = Http::get('http://test.com');

`get`メソッドは`Illuminate\Http\Client\Response`のインスタンスを返します。これはレスポンスを調べるために使用できるさまざまなメソッドを持っています。

    $response->body() : string;
    $response->json() : array|mixed;
    $response->status() : int;
    $response->ok() : bool;
    $response->successful() : bool;
    $response->failed() : bool;
    $response->serverError() : bool;
    $response->clientError() : bool;
    $response->header($header) : string;
    $response->headers() : array;

`Illuminate\Http\Client\Response`オブジェクトは、レスポンス上のJSONレスポンスデータへ直接アクセスできるように、PHPの`ArrayAccess`インターフェイスも実装しています。

    return Http::get('http://test.com/users/1')['name'];

<a name="request-data"></a>
### リクエストデータ

もちろん、`POST`、`PUT`、`PATCH`を使用する場合は、リクエストと追加のデータを一緒に送るのが一般的です。そのため、これらのメソッドは第２引数にデータの配列を受け取ります。データはデフォルトで`application/json`コンテンツタイプを使用して送信されます。

    $response = Http::post('http://test.com/users', [
        'name' => 'Steve',
        'role' => 'Network Administrator',
    ]);

<a name="get-request-query-parameters"></a>
#### GETリクエストのクエリパラメータ

`GET`リクエストの作成時はクエリ文字列をURLに直接追加するか、キー／値ペアの配列を第２引数として`get`メソッドに渡します。

    $response = Http::get('http://test.com/users', [
        'name' => 'Taylor',
        'page' => 1,
    ]);

<a name="sending-form-url-encoded-requests"></a>
#### URLエンコードされたリクエストのフォーム送信

`application/x-www-form-urlencoded`コンテンツタイプを使用してデータを送信したい場合は、リクエストを作成する前に`asForm`メソッドを呼び出す必要があります。

    $response = Http::asForm()->post('http://test.com/users', [
        'name' => 'Sara',
        'role' => 'Privacy Consultant',
    ]);

<a name="sending-a-raw-request-body"></a>
#### リクエスト本体をそのまま送信する

リクエスト作成時に、リクエストの本体をそのまま指定したい場合は、`withBody`メソッドを使います。

    $response = Http::withBody(
        base64_encode($photo), 'image/jpeg'
    )->post('http://test.com/photo');

<a name="multi-part-requests"></a>
#### マルチパートリクエスト

ファイルをマルチパートリクエストとして送信したい場合は、リクエストを作成する前に`attach`メソッドを呼び出す必要があります。このメソッドはファイル名と、その内容を引数に受け取ります。オプションとして第３引数に、ファイルのファイル名と想定できる文字列を指定できます。

    $response = Http::attach(
        'attachment', file_get_contents('photo.jpg'), 'photo.jpg'
    )->post('http://test.com/attachments');

ファイルのコンテンツ内容をそのまま渡す代わりに、ストリームリソースも指定できます。

    $photo = fopen('photo.jpg', 'r');

    $response = Http::attach(
        'attachment', $photo, 'photo.jpg'
    )->post('http://test.com/attachments');

<a name="headers"></a>
### ヘッダ

`withHeaders`メソッドで、リクエストにヘッダを追加できます。この`withHeaders`メソッドは、キー／値ペアの配列を引数に取ります。

    $response = Http::withHeaders([
        'X-First' => 'foo',
        'X-Second' => 'bar'
    ])->post('http://test.com/users', [
        'name' => 'Taylor',
    ]);

<a name="authentication"></a>
### 認証

`withBasicAuth`と`withDigestAuth`メソッドを使うと、Basic認証やDigest認証に使用する認証データを指定できます。

    // Basic認証
    $response = Http::withBasicAuth('taylor@laravel.com', 'secret')->post(...);

    // Digest認証
    $response = Http::withDigestAuth('taylor@laravel.com', 'secret')->post(...);

<a name="bearer-tokens"></a>
#### Bearerトークン

手早く`Authorization` bearerトークンをリクエストのヘッダに追加したい場合は、`withToken`メソッドを使います。

    $response = Http::withToken('token')->post(...);

<a name="timeout"></a>
### タイムアウト

`timeout`メソッドはレスポンスを待つ最大秒数を指定するために使用します。

    $response = Http::timeout(3)->get(...);

指定したタイムアウト時間が過ぎたら、`Illuminate\Http\Client\ConnectionExceptionのインスタンスが投げられます。

<a name="retries"></a>
### リトライ

クライアントかサーバでエラーが発生したときに、HTTPクライアントへそのリクエストを自動的に再試行させたい場合は、`retry`メソッドを使います。`retry`メソッドは２つの引数を取ります。試行回数と、次に試みるまでLaravelに待たせるミリ秒です。

    $response = Http::retry(3, 100)->post(...);

リクエストに全部失敗したら、`Illuminate\Http\Client\RequestException`のインスタンスが投げられます。

<a name="error-handling"></a>
### エラー処理

Guzzleのデフォルト動作と異なり、LaravelのHTTPクライアントラッパーはクライアントの例外を投げたり、サーバからの`400`と`500`レベルのレスポンスとしてエラーレスポンスを返したりしません。こうしたエラーが発生したかは`successful`、`clientError`、`serverError`メソッドで判定できます。

    // ステータスコードが２００以上、３００より小さいレスポンスであったかを判定
    $response->successful();

    // ステータスコードが４００より大きいかを判定
    $response->failed();

    // ステータスコードが４００レベルのレスポンスであったかを判定
    $response->clientError();

    // ステータスコードが５００レベルのレスポンスであったかを判定
    $response->serverError();

<a name="throwing-exceptions"></a>
#### 例外を投げる

レスポンスインスタンスを受け取り、そのレスポンスがクライアントかサーバエラーであった場合に、`Illuminate\Http\Client\RequestException`のインスタンスを投げる場合は、`throw`メソッドを使います。

    $response = Http::post(...);

    // クライアントかサーバエラーが発生したため例外を投げる
    $response->throw();

    return $response['user']['id'];

`Illuminate\Http\Client\RequestException`インスタンスはパブリックの`$response`プロパティを持ち、返されたレスポンスを調査できるようになっています。

`throw`メソッドはエラーが起きていない場合にレスポンスインスタンスを返すため、別の操作を続けて記述できます。

    return Http::post(...)->throw()->json();

例外が投げられる前に追加ロジックを実行したい場合、クロージャを`throw`メソッドに渡すことができます。クロージャが呼び出された後、その例外は自動的に投げられるため、クロージャ内から例外を再度投げる必要はありません。

    return Http::post(...)->throw(function ($response, $e) {
        //
    })->json();

<a name="guzzle-options"></a>
### Guzzleオプション

`withOptions`メソッドを使用し、[Guzzleリクエストオプション](http://docs.guzzlephp.org/en/stable/request-options.html)を追加指定できます。`withOptions`メソッドはキー／値ペアの配列を引数に取ります。

    $response = Http::withOptions([
        'debug' => true,
    ])->get('http://test.com/users');

<a name="testing"></a>
## テスト

多くのLaravelサービスは簡単に記述的なテストが書ける機能を提供していますが、HTTPラッパーも例外ではありません。`Http`ファサードの`fake`メソッドで、リクエストが作成されるときに、スタブ／ダミーのレスポンスを返すようにHTTPクライアントに支持できます。

<a name="faking-responses"></a>
### レスポンスのFake

たとえば、すべてのリクエストに`200`ステータスコードを持つ空のレスポンスをHTTPクライアントから返したい場合は、`fake`メソッドを引数なしで呼びます。

    use Illuminate\Support\Facades\Http;

    Http::fake();

    $response = Http::post(...);

> {note} リクエストをFakeする時、HTTPクライアントミドルウェアは実行されません。Fakeするレスポンスでこうしたミドルウェアが正しく実行されたかのように、エクスペクションを定義する必要があります。

<a name="faking-specific-urls"></a>
#### 特定URLのFake

`fake`メソッドに配列を渡すこともできます。配列のキーはfakeするURLパターンを表し、値はレスポンスです。`*`文字はワイルドカードとして使えます。FakeしないURLに対するリクエストは、実際に実行されます。エンドポイントに対するスタブ／fakeを組み立てるために、`response`メソッドを使います。

    Http::fake([
        // GitHubエンドポイントに対するJSONレスポンスをスタブ
        'github.com/*' => Http::response(['foo' => 'bar'], 200, ['Headers']),

        // Googleエンドポイントに対する文字列レスポンスをスタブ
        'google.com/*' => Http::response('Hello World', 200, ['Headers']),
    ]);

一致しないURLをすべてスタブするフォールバックURLパターンを指定する場合は、`*`文字だけを使います。

    Http::fake([
        // GitHubエンドポイントに対するJSONレスポンスをスタブ
        'github.com/*' => Http::response(['foo' => 'bar'], 200, ['Headers']),

        // その他すべてのエンドポイントに対して文字列レスポンスをスタブ
        '*' => Http::response('Hello World', 200, ['Headers']),
    ]);

<a name="faking-response-sequences"></a>
#### 一連のレスポンスのFake

特定の順番で一連のfakeレスポンスを一つのURLに対して指定する必要がある場合もときどきあります。このレスポンスを組み立てるには、`Http::sequence`メソッドを使用します。

    Http::fake([
        // GitHubエンドポイントに対して一連のレスポンスをスタブ
        'github.com/*' => Http::sequence()
                                ->push('Hello World', 200)
                                ->push(['foo' => 'bar'], 200)
                                ->pushStatus(404),
    ]);

一連のレスポンスを全部返し終えると、そのエンドポイントに対する以降のリクエストには例外が投げられます。このとき例外を発生させる代わりに特定のレスポンスを返すように指定したい場合は、`whenEmpty`メソッドを使用します。

    Http::fake([
        // GitHubエンドポイントに対して一連のレスポンスをスタブ
        'github.com/*' => Http::sequence()
                                ->push('Hello World', 200)
                                ->push(['foo' => 'bar'], 200)
                                ->whenEmpty(Http::response()),
    ]);

順番のあるレスポンスをfakeしたいが、fakeする特定のURLパターンを指定する必要がなければ、`Http::fakeSequence`メソッドを使います。

    Http::fakeSequence()
            ->push('Hello World', 200)
            ->whenEmpty(Http::response());

<a name="fake-callback"></a>
#### コールバックのFake

特定のエンドポイントでどんなレスポンスを返すか決めるために、より複雑なロジックが必要な場合は、`fake`メソッドへコールバックを渡してください。このコールバックは`Illuminate\Http\Client\Request`のインスタンスを受け取るので、レスポンスインスタンスを返してください。

    Http::fake(function ($request) {
        return Http::response('Hello World', 200);
    });

<a name="inspecting-requests"></a>
### レスポンスの調査

レスポンスをfakeしているとまれに、自分のアプリケーションが正しいデータやヘッダを送っていることを確認するため、クライアントが受け取るリクエストを調べたくなります。これを行うには、`Http::fake`を呼び出したあとに`Http::assertSent`メソッドを呼び出します。

`assertSent`メソッドは`Illuminate\Http\Client\Request`インスタンスを受け取るコールバックを引数に取り、そのリクエストが期待通りであったかを示す論理値をそのコールバックから返します。テストにパスするには、指定した期待に合致する最低一つのリクエストが発送されている必要があります。

    Http::fake();

    Http::withHeaders([
        'X-First' => 'foo',
    ])->post('http://test.com/users', [
        'name' => 'Taylor',
        'role' => 'Developer',
    ]);

    Http::assertSent(function ($request) {
        return $request->hasHeader('X-First', 'foo') &&
               $request->url() == 'http://test.com/users' &&
               $request['name'] == 'Taylor' &&
               $request['role'] == 'Developer';
    });

必要であれば`assertNotSent`メソッドを用い、指定するリクエストが送信されなかった事をアサートすることもできます。

    Http::fake();

    Http::post('http://test.com/users', [
        'name' => 'Taylor',
        'role' => 'Developer',
    ]);

    Http::assertNotSent(function (Request $request) {
        return $request->url() === 'http://test.com/posts';
    });

もしくは、リクエストがまったく送信されないことをアサートしたい場合には、`assertNothingSent`メソッドを使用してください。

    Http::fake();

    Http::assertNothingSent();
