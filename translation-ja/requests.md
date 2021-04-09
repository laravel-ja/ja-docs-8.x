# HTTP Requests

- [イントロダクション](#introduction)
- [リクエストの操作](#interacting-with-the-request)
    - [リクエストへのアクセス](#accessing-the-request)
    - [リクエストパスとメソッド](#request-path-and-method)
    - [リクエストヘッダ](#request-headers)
    - [リクエストIPアドレス](#request-ip-address)
    - [コンテントネゴシエーション](#content-negotiation)
    - [PSR-7リクエスト](#psr7-requests)
- [入力](#input)
    - [入力の取得](#retrieving-input)
    - [入力の存在の判定](#determining-if-input-is-present)
    - [直前の入力](#old-input)
    - [クッキー](#cookies)
    - [入力のトリムと正規化](#input-trimming-and-normalization)
- [ファイル](#files)
    - [アップロード済みファイルの取得](#retrieving-uploaded-files)
    - [アップロード済みファイルの保存](#storing-uploaded-files)
- [信頼できるプロキシの設定](#configuring-trusted-proxies)

<a name="introduction"></a>
## イントロダクション

Laravelの`Illuminate\Http\Request`クラスは、アプリケーションが処理している現在のHTTPリクエストを操作し、リクエストとともに送信される入力、クッキー、およびファイルを取得するオブジェクト指向の手段を提供しています。

<a name="interacting-with-the-request"></a>
## リクエストの操作

<a name="accessing-the-request"></a>
### リクエストへのアクセス

依存注入を使い、現在のHTTPリクエストのインスタンスを取得するには、ルートクロージャまたはコントローラメソッドで`Illuminate\Http\Request`クラスをタイプヒントする必要があります。受信リクエストインスタンスは、Laravel[サービスコンテナ](/docs/{{version}}/container)により自動的に依存注入されます。

    <?php

    namespace App\Http\Controllers;

    use Illuminate\Http\Request;

    class UserController extends Controller
    {
        /**
         * 新しいユーザーを保存
         *
         * @param  \Illuminate\Http\Request  $request
         * @return \Illuminate\Http\Response
         */
        public function store(Request $request)
        {
            $name = $request->input('name');

            //
        }
    }

前述のように、ルートクロージャで`Illuminate\Http\Request`クラスをタイプヒントすることもできます。サービスコンテナは、実行時に受信リクエストをクロージャへ自動で依存挿入します。

    use Illuminate\Http\Request;

    Route::get('/', function (Request $request) {
        //
    });

<a name="dependency-injection-route-parameters"></a>
#### 依存注入とルートパラメータ

コントローラメソッドがルートパラメータからの入力も期待している場合は、他の依存関係の後にルートパラメータをリストする必要があります。たとえば、ルートが次のように定義されているとしましょう。

    use App\Http\Controllers\UserController;

    Route::put('/user/{id}', [UserController::class, 'update']);

以下のようにコントローラメソッドを定義することで、`Illuminate\Http\Request`をタイプヒントし、`id`ルートパラメーターにアクセスできます。

    <?php

    namespace App\Http\Controllers;

    use Illuminate\Http\Request;

    class UserController extends Controller
    {
        /**
         * 指定ユーザーを更新
         *
         * @param  \Illuminate\Http\Request  $request
         * @param  string  $id
         * @return \Illuminate\Http\Response
         */
        public function update(Request $request, $id)
        {
            //
        }
    }

<a name="request-path-and-method"></a>
### リクエストパスとメソッド

`Illuminate\Http\Request`インスタンスは、`Symfony\Component\HttpFoundation\Request`クラスを拡張し、受信HTTPリクエストを調べるためのさまざまなメソッドを提供しています。以下では、もっとも重要なメソッドからいくつか説明します。

<a name="retrieving-the-request-path"></a>
#### リクエストパスの取得

`path`メソッドはリクエストのパス情報を返します。ですから、受信リクエストが`http://example.com/foo/bar`をターゲットにしている場合、`path`メソッドは`foo/bar`を返します。

    $uri = $request->path();

<a name="inspecting-the-request-path"></a>
#### リクエストパス／ルートの検査

`is`メソッドを使用すると、受信リクエストパスが特定のパターンに一致することを判定できます。このメソッドでは、ワイルドカードとして`*`文字を使用できます。

    if ($request->is('admin/*')) {
        //
    }

`routeIs`メソッドを使用して、受信リクエストが[名前付きルート](/docs/{{version}}/routing#named-routes)に一致するかを判定できます。

    if ($request->routeIs('admin.*')) {
        //
    }

<a name="retrieving-the-request-url"></a>
#### リクエストURLの取得

受信リクエストの完全なURLを取得するには、`url`または`fullUrl`メソッドを使用できます。`url`メソッドはクエリ文字列を含まないURLを返し、`fullUrl`メソッドはクエリ文字列も含みます。

    $url = $request->url();

    $urlWithQueryString = $request->fullUrl();

<a name="retrieving-the-request-method"></a>
#### リクエストメソッドの取得

`method`メソッドは、リクエストのHTTP動詞を返します。`isMethod`メソッドを使用して、HTTP動詞が特定の文字列と一致するか判定できます。

    $method = $request->method();

    if ($request->isMethod('post')) {
        //
    }

<a name="request-headers"></a>
### リクエストヘッダ

`header`メソッドを使用して、`Illuminate\Http\Request`インスタンスからリクエストヘッダを取得できます。リクエストにヘッダが存在しない場合、`null`を返します。ただし、`header`メソッドは、リクエストにヘッダが存在しない場合に返す２番目の引数をオプションとして取ります。

    $value = $request->header('X-Header-Name');

    $value = $request->header('X-Header-Name', 'default');

`hasHeader`メソッドを使用して、リクエストに特定のヘッダが含まれているか判定できます。

    if ($request->hasHeader('X-Header-Name')) {
        //
    }

便利なように、`bearerToken`メソッドを`Authorization`ヘッダからのBearerトークン取得で使用できます。そのようなヘッダが存在しない場合、空の文字列が返されます。

    $token = $request->bearerToken();

<a name="request-ip-address"></a>
### リクエストIPアドレス

`ip`メソッドを使用して、アプリケーションにリクエストを送信したクライアントのIPアドレスを取得できます。

    $ipAddress = $request->ip();

<a name="content-negotiation"></a>
### コンテントネゴシエーション

Laravelは、`Accept`ヘッダを介して受信リクエストへリクエストされたコンテンツタイプを検査するメソッドをいくつか提供しています。まず、`getAcceptableContentTypes`メソッドは、リクエストが受付可能なすべてのコンテンツタイプを含む配列を返します。

    $contentTypes = $request->getAcceptableContentTypes();

`accepts`メソッドはコンテンツタイプの配列を受け入れ、いずれかのコンテンツタイプがリクエストにより受け入れられた場合は`true`を返します。それ以外の場合は、`false`が返ります。

    if ($request->accepts(['text/html', 'application/json'])) {
        // ...
    }

`prefers`メソッドを使用して、特定のコンテンツタイプの配列のうち、リクエストで最も優先されるコンテンツタイプを決定できます。指定したコンテンツタイプのいずれもがリクエストで受け入れられない場合、`null`が返ります。

    $preferred = $request->prefers(['text/html', 'application/json']);

多くのアプリケーションはHTMLまたはJSONのみを提供するため、`expectsJson`メソッドを使用して、受信リクエストがJSONリクエストを期待しているかを手早く判定できます。

    if ($request->expectsJson()) {
        // ...
    }

<a name="psr7-requests"></a>
### PSR-7リクエスト

[PSR-7標準](https://www.php-fig.org/psr/psr-7/)は、リクエストとレスポンスを含むHTTPメッセージのインターフェイスを規定しています。Laravelリクエストの代わりにPSR-7リクエストのインスタンスを取得したい場合は、最初にいくつかのライブラリをインストールする必要があります。Laravelは*Symfony HTTP Message Bridge*コンポーネントを使用して、通常使用するLaravelのリクエストとレスポンスをPSR-7互換の実装に変換します。

    composer require symfony/psr-http-message-bridge
    composer require nyholm/psr7

これらのライブラリをインストールしたら、ルートクロージャまたはコントローラメソッドでリクエストインターフェイスをタイプヒントすることで、PSR-7リクエストを取得できます。

    use Psr\Http\Message\ServerRequestInterface;

    Route::get('/', function (ServerRequestInterface $request) {
        //
    });

> {tip} ルートまたはコントローラからPSR-7レスポンスインスタンスを返すと、自動的にLaravelレスポンスインスタンスに変換され、フレームワークによって表示されます。

<a name="input"></a>
## 入力

<a name="retrieving-input"></a>
### 入力の取得

<a name="retrieving-all-input-data"></a>
#### 全入力データの取得

`all`メソッドを使用して、受信リクエストのすべての入力データを`array`として取得できます。このメソッドは、受信リクエストがHTMLフォームからのものであるか、XHRリクエストであるかに関係なく使用できます。

    $input = $request->all();

<a name="retrieving-an-input-value"></a>
#### 単一入力値の取得

いくつかの簡単な方法を使用すれば、リクエストに使用されたHTTP動詞を気にすることなく、`Illuminate\Http\Request`インスタンスからのすべてのユーザー入力にアクセスできます。HTTP動詞に関係なく、`input`メソッドを使用してユーザー入力を取得できます。

    $name = $request->input('name');

`input`メソッドの２番目の引数としてデフォルト値を渡すことができます。指定した入力値がリクエストに存在しない場合、この値を返します。

    $name = $request->input('name', 'Sally');

配列入力を含むフォームを操作する場合は、「ドット」表記を使用して配列にアクセスします。

    $name = $request->input('products.0.name');

    $names = $request->input('products.*.name');

すべての入力値を連想配列として取得するために、引数なしで`input`メソッドを呼び出せます。

    $input = $request->input();

<a name="retrieving-input-from-the-query-string"></a>
#### クエリ文字列からの入力の取得

`input`メソッドはリクエストペイロード全体(クエリ文字列を含む)から値を取得しますが、`query`メソッドはクエリ文字列からのみ値を取得します。

    $name = $request->query('name');

指定したクエリ文字列値データが存在しない場合、このメソッドの２番目の引数を返します。

    $name = $request->query('name', 'Helen');

すべてのクエリ文字列値を連想配列として取得するために、引数なしで`query`メソッドを呼び出せます。

    $query = $request->query();

<a name="retrieving-json-input-values"></a>
#### JSON入力値の取得

JSONリクエストをアプリケーションに送信する場合、リクエストの`Content-Type`ヘッダが適切に`application/json`へ設定されている限り、`input`メソッドを介してJSONデータにアクセスできます。「ドット」構文を使用して、JSON配列内にネストされている値を取得することもできます。

    $name = $request->input('user.name');

<a name="retrieving-boolean-input-values"></a>
#### 論理入力値の取得

チェックボックスなどのHTML要素を処理する場合、アプリケーションは実際には文字列である「真の」値を受け取る可能性があります。たとえば、「true」または「on」です。使いやすいように、`boolean`メソッドを使用してこれらの値をブール値として取得できます。`boolean`メソッドは、1、"1、true、"true"、"on"、"yes"に対して`true`を返します。他のすべての値は`false`を返します:

    $archived = $request->boolean('archived');

<a name="retrieving-input-via-dynamic-properties"></a>
#### 動的プロパティを介した入力の取得

`Illuminate\Http\Request`インスタンスの動的プロパティを使用してユーザー入力にアクセスすることもできます。たとえば、アプリケーションのフォームの1つに`name`フィールドが含まれている場合、次のようにフィールドの値にアクセスできます。

    $name = $request->name;

動的プロパティを使用する場合、Laravelは最初にリクエストペイロードでパラメータの値を探します。見つからない場合、Laravelは一致したルートのパラメーターの中のフィールドを検索します。

<a name="retrieving-a-portion-of-the-input-data"></a>
#### 入力データの一部の取得

入力データのサブセットを取得する必要がある場合は、`only`メソッドと`except`メソッドを使用できます。これらのメソッドは両方とも、単一の「配列」または引数の動的リストを受け入れます。

    $input = $request->only(['username', 'password']);

    $input = $request->only('username', 'password');

    $input = $request->except(['credit_card']);

    $input = $request->except('credit_card');

> {note} `only`メソッドは、指定したすべてのキー／値ペアを返します。ただし、リクエスト中に存在しないキー／値ペアは返しません。

<a name="determining-if-input-is-present"></a>
### 入力の存在の判定

`has`メソッドを使用して、リクエストに値が存在するかを判定できます。リクエストに値が存在する場合、`has`メソッドは`true`を返します。

    if ($request->has('name')) {
        //
    }

配列が指定されると、`has`メソッドは、指定されたすべての値が存在するかどうかを判別します。

    if ($request->has(['name', 'email'])) {
        //
    }

リクエストに値が存在する場合、`whenHas`メソッドは指定するクロージャを実行します。

    $request->whenHas('name', function ($input) {
        //
    });

指定値のいずれかが存在する場合、`hasAny`メソッドは`true`を返します。

    if ($request->hasAny(['name', 'email'])) {
        //
    }

値がリクエストに存在し、空でないことを確認する場合は、`filled`メソッドを使用します。

    if ($request->filled('name')) {
        //
    }

値がリクエストに存在し、空でない場合、`whenFilled`メソッドは指定したクロージャを実行します。

    $request->whenFilled('name', function ($input) {
        //
    });

特定のキーがリクエストに含まれていないかを判定するには、`missing`メソッドを使用できます。

    if ($request->missing('name')) {
        //
    }

<a name="old-input"></a>
### 直前の入力

Laravelは、今のリクエストから次のリクエストまで入力を保持できます。この機能は、バリデーションエラーを検出した後にフォームを再入力するときに特に便利です。ただし、Laravelの[バリデーション機能](/docs/{{version}}/validation)を使用する場合、これらのセッション入力一時保持メソッドを手動で直接使用する必要がないかもしれません。Laravelに組み込まれているバリデーション機能のように、一時保持入力を自動で呼び出すからです。

<a name="flashing-input-to-the-session"></a>
#### セッションへ入力の一時保持

`Illuminate\Http\Request`クラスの`flash`メソッドは、[セッション](/docs/{{version}}/session)へ現在の入力を一時保持して、ユーザーがアプリケーションに次にリクエストするときに使用できるようにします。

    $request->flash();

`flashOnly`メソッドと`flashExcept`メソッドを使用して、リクエストデータのサブセットをセッションへ一時保持することもできます。これらの方法は、パスワードなどの機密情報をセッションから除外するのに役立ちます。

    $request->flashOnly(['username', 'email']);

    $request->flashExcept('password');

<a name="flashing-input-then-redirecting"></a>
#### 入力を一時保持後のリダイレクト

多くの場合、セッションへ入力を一時保持してから前のページにリダイレクトする必要があるため、`withInput`メソッドを使用して、リダイレクトへ簡単にチェーンで入力の一時保持を指示できます。

    return redirect('form')->withInput();

    return redirect()->route('user.create')->withInput();

    return redirect('form')->withInput(
        $request->except('password')
    );

<a name="retrieving-old-input"></a>
#### 直前の入力の取得

前のリクエストで一時保持した入力を取得するには、`Illuminate\Http\Request`のインスタンスで`old`メソッドを呼び出します。`old`メソッドは、以前に一時保持した入力データを[セッション](/docs/{{version}}/session)から取得します。

    $username = $request->old('username');

Laravelはグローバルな`old`ヘルパも提供しています。[Bladeテンプレート](/docs/{{version}}/Blade)内に古い入力を表示する場合は、`old`ヘルパを使用してフォームを再入力する方が便利です。指定されたフィールドに古い入力が存在しない場合、`null`を返します。

    <input type="text" name="username" value="{{ old('username') }}">

<a name="cookies"></a>
### クッキー

<a name="retrieving-cookies-from-requests"></a>
#### リクエストからクッキーを取得

Laravelフレームワークが作成する、すべてのクッキーは暗号化され、認証コードで署名されています。つまり、クライアントによって変更された場合、クッキーは無効と見なします。リクエストからクッキー値を取得するには、`Illuminate\Http\Request`インスタンスで`cookie`メソッドを使用します。

    $value = $request->cookie('name');

<a name="input-trimming-and-normalization"></a>
## 入力のトリムと正規化

デフォルトでは、Laravelはアプリケーションのグローバルミドルウェアスタックに`App\Http\Middleware\TrimStrings`と`App\Http\Middleware\ConvertEmptyStringsToNull`ミドルウェアを含めています。これらのミドルウェアは、`App\Http\Kernel`クラスによってグローバルミドルウェアスタックにリストされています。これらのミドルウェアは、リクエストに応じてすべての受信文字列フィールドを自動的にトリミングし、空の文字列フィールドを`null`に変換します。これにより、ルートとコントローラでのこれらの正規化について心配する必要がなくなります。

この動作を無効にしたい場合は、アプリケーションのミドルウェアスタックから２ミドルウェアを削除するため、`App\Http\Kernel`クラスの`$middleware`プロパティから２つのミドルウェアを削除してください。

<a name="files"></a>
## ファイル

<a name="retrieving-uploaded-files"></a>
### アップロード済みファイルの取得

アップロードしたファイルは、`file`メソッドまたは動的プロパティを使用して`Illuminate\Http\Request`インスタンスから取得できます。`file`メソッドは`Illuminate\Http\UploadedFile`クラスのインスタンスを返します。これは、PHPの`SplFileInfo`クラスを拡張し、ファイルを操作するさまざまなメソッドを提供しています。

    $file = $request->file('photo');

    $file = $request->photo;

`hasFile`メソッドを使用して、リクエストにファイルが存在するか判定できます。

    if ($request->hasFile('photo')) {
        //
    }

<a name="validating-successful-uploads"></a>
#### 正常なアップロードのバリデーション

ファイルが存在するかどうかを判定することに加え、`isValid`メソッドによりファイルのアップロードに問題がなかったことを確認できます。

    if ($request->file('photo')->isValid()) {
        //
    }

<a name="file-paths-extensions"></a>
#### ファイルパスと拡張子

`UploadedFile`クラスは、ファイルの完全修飾パスとその拡張子にアクセスするためのメソッドも用意しています。`extension`メソッドは、その内容に基づいてファイルの拡張子を推測しようとします。この拡張機能は、クライアントが提供した拡張子とは異なる場合があります。

    $path = $request->photo->path();

    $extension = $request->photo->extension();

<a name="other-file-methods"></a>
#### その他のファイルメソッド

他にも`UploadedFile`インスタンスで利用できるさまざまなメソッドがあります。これらのメソッドの詳細は、[クラスのAPIドキュメント](https://api.symfony.com/master/Symfony/Component/HttpFoundation/File/UploadedFile.html)を確認してください。

<a name="storing-uploaded-files"></a>
### アップロード済みファイルの保存

アップロードされたファイルを保存するには、設定済みの[ファイルシステム](/docs/{{version}}/filesystem)のいずれかを通常使用します。`UploadedFile`クラスには`store`メソッドがあり、アップロードされたファイルをディスクの１つに移動します。ディスクは、ローカルファイルシステム上の場所やAmazon S3のようなクラウドストレージの場所である可能性があります。

`store`メソッドは、ファイルシステムの設定済みルートディレクトリを基準にしてファイルを保存するパスを引数に取ります。ファイル名として機能する一意のIDが自動的に生成されるため、このパスにはファイル名を含めることはできません。

`store`メソッドは、ファイルの保存に使用するディスクの名前を第２引数にオプションとして取ります。このメソッドは、ディスクのルートを基準にしたファイルのパスを返します。

    $path = $request->photo->store('images');

    $path = $request->photo->store('images', 's3');

ファイル名を自動的に生成したくない場合は、パス、ファイル名、およびディスク名を引数として受け入れる`storeAs`メソッドが使用できます。

    $path = $request->photo->storeAs('images', 'filename.jpg');

    $path = $request->photo->storeAs('images', 'filename.jpg', 's3');

> {tip} Laravelのファイルストレージの詳細は、完全な[ファイルストレージドキュメント](/docs/{{version}}/filesystem)を確認してください。

<a name="configuring-trusted-proxies"></a>
## 信頼できるプロキシの設定

TLS/SSL証明書を末端とするロードバランサーの背後でアプリケーションを実行している場合、`url`ヘルパを使用するとアプリケーションがHTTPSリンクを生成しないことがあります。通常、これは、アプリケーションがポート80でロードバランサーからトラフィックを転送していて、安全なリンクを生成する必要があることを認識していないためです。

これを解決するには、Laravelアプリケーションに含まれている`App\Http\Middleware\TrustProxies`ミドルウェアを使用します。これにより、アプリケーションが信頼するロードバランサーまたはプロキシを手早くカスタマイズできます。信頼できるプロキシは、このミドルウェアの`$proxies`プロパティに配列としてリストする必要があります。信頼できるプロキシの設定に加え、信頼すべきプロキシ「$headers」も設定できます。

    <?php

    namespace App\Http\Middleware;

    use Fideloper\Proxy\TrustProxies as Middleware;
    use Illuminate\Http\Request;

    class TrustProxies extends Middleware
    {
        /**
         * このアプリケーションで信頼できるプロキシ
         *
         * @var string|array
         */
        protected $proxies = [
            '192.168.1.1',
            '192.168.1.2',
        ];

        /**
         * プロキシを検出するために使用すべきヘッダ
         *
         * @var int
         */
        protected $headers = Request::HEADER_X_FORWARDED_FOR | Request::HEADER_X_FORWARDED_HOST | Request::HEADER_X_FORWARDED_PORT | Request::HEADER_X_FORWARDED_PROTO;
    }

> {tip} AWS Elasticロードバランシングを使用している場合、`$headers`の値は`Request::HEADER_X_FORWARDED_AWS_ELB`である必要があります。`$headers`プロパティで使用できる定数の詳細については、[信頼の置けるプロキシ](https://symfony.com/doc/current/deployment/proxies.html)に関するSymfonyのドキュメントを確認してください。

<a name="trusting-all-proxies"></a>
#### すべてのプロキシを信頼する

Amazon AWSまたは別の「クラウド」ロードバランサープロバイダを使用している場合、実際のバランサーのIPアドレスがわからない場合があります。この場合、`*`を使用してすべてのプロキシを信頼できます。

    /**
     * このアプリケーションで信頼できるプロキシ
     *
     * @var string|array
     */
    protected $proxies = '*';
