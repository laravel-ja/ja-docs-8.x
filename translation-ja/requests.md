# HTTPリクエスト

- [リクエストの取得](#accessing-the-request)
    - [リクエストパスとメソッド](#request-path-and-method)
    - [PSR-7リクエスト](#psr7-requests)
- [入力のトリムとノーマライゼーション](#input-trimming-and-normalization)
- [入力の取得](#retrieving-input)
    - [直前の入力](#old-input)
    - [クッキー](#cookies)
- [ファイル](#files)
    - [アップロードファイルの取得](#retrieving-uploaded-files)
    - [アップロードファイルの保存](#storing-uploaded-files)
- [信用するプロキシの設定](#configuring-trusted-proxies)

<a name="accessing-the-request"></a>
## リクエストの取得

依存注入により、現在のHTTPリクエストインスタンスを取得するには、タイプヒントで`Illuminate\Http\Request`クラスをコントローラメソッドに指定します。現在のリクエストインスタンスが、[サービスプロバイダ](/docs/{{version}}/container)により、自動的に注入されます。

    <?php

    namespace App\Http\Controllers;

    use Illuminate\Http\Request;

    class UserController extends Controller
    {
        /**
         * 新しいユーザーを保存
         *
         * @param  Request  $request
         * @return Response
         */
        public function store(Request $request)
        {
            $name = $request->input('name');

            //
        }
    }

#### 依存注入とルートパラメータ

もし、コントローラメソッドでルートパラメーターも併用したい場合は、依存の指定の後にルート引数を続けてリストしてください。たとえば次のようにルートを定義している場合：

    use App\Http\Controllers\UserController;

    Route::put('user/{id}', [UserController::class, 'update']);

次のようにコントローラメソッドの中で、まずタイプヒントで`Illuminate\Http\Request`を指定し、それからルートパラメーターの`id`へアクセスします。

    <?php

    namespace App\Http\Controllers;

    use Illuminate\Http\Request;

    class UserController extends Controller
    {
        /**
         * 指定したユーザーの更新
         *
         * @param  Request  $request
         * @param  string  $id
         * @return Response
         */
        public function update(Request $request, $id)
        {
            //
        }
    }

#### ルートクロージャでのリクエスト取得

ルートクロージャでも`Illuminate\Http\Request`をタイプヒントで指定できます。そのルートが実行されると、送信されてきたリクエストをサービスコンテナが自動的にクロージャへ渡します。

    use Illuminate\Http\Request;

    Route::get('/', function (Request $request) {
        //
    });

<a name="request-path-and-method"></a>
### リクエストパスとメソッド

`Illuminate\Http\Request`インスタンスは、`Symfony\Component\HttpFoundation\Request`クラスを拡張しており、HTTPリクエストを調べるために数多くのメソッドを提供しています。提供されている便利なメソッドをいくつか紹介しましょう。

#### リクエストURIの取得

`path`メソッドはリクエストURIを返します。もしリクエストが`http://domain.com/foo/bar`に送られたとすると、`path`メソッドは`foo/bar`を返します。

    $uri = $request->path();

`is`メソッドにより、リクエストのURIが指定されたパターンに合致するかを確認できます。このメソッドでは`*`をワイルドカードとして使用できます。

    if ($request->is('admin/*')) {
        //
    }

#### リクエストURLの取得

送信されたリクエストの完全なURLを取得する場合は、`url`か`fullUrl`メソッドを使用してください。`url`メソッドはクエリストリングを除いたURLを返し、一方の`fullUrl`メソッドはクエリストリング付きで返します。

    // クエリ文字列なし
    $url = $request->url();

    // クエリ文字列付き
    $url = $request->fullUrl();

#### リクエストメソッドの取得

`method`メソッドはリクエストのHTTP動詞を返します。また、`isMethod`メソッドを使えば、指定した文字列とHTTP動詞が一致するかを調べることができます。

    $method = $request->method();

    if ($request->isMethod('post')) {
        //
    }

<a name="psr7-requests"></a>
### PSR-7リクエスト

[PSR-7規約](https://www.php-fig.org/psr/psr-7/)は、リクエストとレスポンスを含めたHTTPメッセージのインターフェイスを規定しています。PSR-7リクエストのインスタンスを受け取りたければ、ライブラリーをいくつかインストールする必要があります。LaravelはLaravelリクエストとレスポンスをPSR-7互換の実装へ変換するために、**Symfony HTTPメッセージブリッジコンポーネント**を使用しています。

    composer require symfony/psr-http-message-bridge
    composer require nyholm/psr7

これらのライブラリをインストールし、ルートクロージャかコントローラメソッドで、リクエストインターフェイスをタイプヒントで指定すれば、PSR-7リクエストを取得できます。

    use Psr\Http\Message\ServerRequestInterface;

    Route::get('/', function (ServerRequestInterface $request) {
        //
    });

> {tip} ルートかコントローラからPSR-7レスポンスインスタンスを返せば、自動的にLaravelのレスポンスインスタンスに変換され、フレームワークにより表示されます。

<a name="input-trimming-and-normalization"></a>
## 入力のトリムとノーマライゼーション

Laravelのデフォルトグローバルミドルウェアスタックには、`TrimStrings`と`ConvertEmptyStringsToNull`ミドルウェアが含まれています。これらのミドルウェアは、`App\Http\Kernel`クラスにリストされています。これらのミドルウェアは自動的にリクエストの全入力フィールドをトリムし、それと同時に空の文字列フィールドを`null`へ変換します。これにより、ルートやコントローラで、ノーマライズについて心配する必要が無くなります。

この振る舞いを無効にするには、`App\Http\Kernel`クラスの`$middleware`プロパティからこれらのミドルウェアを削除することにより、アプリケーションのミドルウェアスタックから外してください。

<a name="retrieving-input"></a>
## 入力の取得

#### 全入力データの取得

全入力を「配列」として受け取りたい場合は、`all`メソッドを使用します。

    $input = $request->all();

#### 入力値の取得

`Illuminate\Http\Request`インスタンスのシンプルなメソッドを利用すれば、ユーザー入力のすべてにアクセスできます。リクエストのHTTP動詞に気をもむ必要はありません。HTTP動詞にかかわらず、`input`メソッドでユーザー入力を取得できます。

    $name = $request->input('name');

`input`メソッドには第2引数としてデフォルト値を指定できます。この値はリクエストに指定した入力値が存在していない場合に返されます。

    $name = $request->input('name', 'Sally');

配列での入力を含むフォームを取り扱うときは、「ドット」記法で配列へアクセスできます。

    $name = $request->input('products.0.name');

    $names = $request->input('products.*.name');

全入力値を連想配列として取得するために、引数を渡さずに`input`メソッドを呼び出すことも可能です。

    $input = $request->input();

#### クエリストリングからの入力取得

`input`メソッドは、クエリストリングも含めたリクエストペイロード全体から、値を取得するのに対し、`query`メソッドはクエリストリングからのみ値を取得します。

    $name = $request->query('name');

要求したクエリストリング値が存在しない場合、このメソッドの第２引数が返ってきます。

    $name = $request->query('name', 'Helen');

`query`メソッドに引数を渡さずに呼び出せば、連想配列ですべてのクエリストリングを取得できます。

    $query = $request->query();

#### 動的プロバティーでの入力取得

`Illuminate\Http\Request`インスタンスに対する動的プロパティとして、ユーザーインプットにアクセスすることも可能です。たとえば、アプリケーションのフォーム上に`name`フィールドがあり、入力されたフィールド値にアクセスする場合は次のように行います。

    $name = $request->name;

動的プロパティが使われた場合、Laravelは最初にリクエスト本体のパラメータ値を探します。存在していない場合、次にルートパラメータ上のフィールドを探します。

#### JSON入力値の取得

アプリケーションにJSONリクエストが送られ、`Content-Type`ヘッダプロパティに`application/json`が指定されていたら、`input`メソッドによりJSON情報へアクセスできます。JSON配列の深い要素へアクセスするために、「ドット」記法も使用できます。

    $name = $request->input('user.name');

#### 論理入力値の取得

チェックボックスのようなHTML要素を取り扱う場合、アプリケーションが「実際」に受け取る値は文字列です。たとえば、"true"とか"on"です。これらの値を論理値で受け取れると便利なため、`boolean`メソッドが用意されています。`boolean`メソッドは1、"1"、true、"true"、"on"、"yes"には、`true`を返します。それ以外の場合は、すべて`false`を返します。

    $archived = $request->boolean('archived');

#### 入力データの一部取得

入力データの一部を取得する必要があるなら、`only`や`except`メソッドが使用できます。両方のメソッドともに限定したい入力を「配列」や引数の並びとして指定します。

    $input = $request->only(['username', 'password']);

    $input = $request->only('username', 'password');

    $input = $request->except(['credit_card']);

    $input = $request->except('credit_card');

> {tip} `only` メソッドは要求したキー／値ペアを全部返しますが、リクエストに存在しない場合は、キー／値ペアを返しません。

#### 入力値の存在チェック

リクエストに値が存在するかを判定するには、`has`メソッドを使用します。`has`メソッドは、リクエストに値が存在する場合に、`true`を返します。

    if ($request->has('name')) {
        //
    }

配列を指定した場合、`has`メソッドは指定値がすべて存在するかを判定します。

    if ($request->has(['name', 'email'])) {
        //
    }

`whenHas`メソッドはリクエストに値が存在する場合に、指定コールバックを実行します。

    $request->whenHas('name', function ($input) {
        //
    });

`hasAny`メソッドは、指定した値が存在している場合に`true`を返します。

    if ($request->hasAny(['name', 'email'])) {
        //
    }

値がリクエストに存在しており、かつ空でないことを判定したい場合は、`filled`メソッドを使います。

    if ($request->filled('name')) {
        //
    }

`whenFilled`メソッドは、リクエストに値が存在し、かつ空ではない場合に、指定コールバックを実行します。

    $request->whenFilled('name', function ($input) {
        //
    });

指定したキーがリクエストに存在していないことを判定する場合は、`missing`メソッドを使います。

    if ($request->missing('name')) {
        //
    }

<a name="old-input"></a>
### 直前の入力

Laravelでは入力を次のリクエスト一回を処理するまで保存できます。これがとくに便利なのは、バリデーションにエラーがあった場合にフォームを再表示する時です。しかし、Laravelに含まれる[バリデーション機能](/docs/{{version}}/validation)を使っていれば、こうしたメソッドを自分で利用する必要はありません。組み込みバリデーション機能では自動的に利用します。

#### 入力をフラッシュデータとして保存

`Illuminate\Http\Request`クラスの`flash`メソッドは、現在の入力を[セッション](/docs/{{version}}/session)へ、アプリケーションに要求される次のユーザーリクエストの処理中だけ利用できるフラッシュデータとして保存します。

    $request->flash();

セッションへ入力の一部をフラッシュデータとして保存するには、`flashOnly`と`flashExcept`が使用できます。両メソッドは、パスワードなどの機密情報をセッションへ含めないために便利です。

    $request->flashOnly(['username', 'email']);

    $request->flashExcept('password');

#### 入力保存後にリダイレクト

入力をフラッシュデータとして保存する必要があるのは、直前のページヘリダイレクトする場合が多いでしょうから、`withInput`メソッドをリダイレクトにチェーンして簡単に、入力をフラッシュデータとして保存できます。

    return redirect('form')->withInput();

    return redirect('form')->withInput(
        $request->except('password')
    );

#### 直前のデータを取得

直前のリクエストのフラッシュデータを取得するには、`Request`インスタンスに対し`old`メソッドを使用してください。`old`メソッドは[セッション](/docs/{{version}}/session)にフラッシュデータとして保存されている入力を取り出すために役に立ちます。

    $username = $request->old('username');

Laravelでは`old`グローバルヘルパ関数も用意しています。とくに[Bladeテンプレート](/docs/{{version}}/blade)で直前の入力値を表示したい場合に、`old`ヘルパは便利です。指定した文字列の入力が存在していないときは、`null`を返します。

    <input type="text" name="username" value="{{ old('username') }}">

<a name="cookies"></a>
### クッキー

#### リクエストからクッキーを取得

Laravelフレームワークが作成するクッキーはすべて暗号化され、認証コードで署名されています。つまりクライアントにより変更されると、無効なクッキーとして取り扱います。リクエストからクッキー値を取得するには、`Illuminate\Http\Request`インスタンスに対して`cookie`メソッドを使用してください。

    $value = $request->cookie('name');

もしくは、クッキー値へアクセスするために、`Cookie`ファサードも利用できます。

    use Illuminate\Support\Facades\Cookie;

    $value = Cookie::get('name');

#### レスポンスへクッキーを付ける

送信する`Illuminate\Http\Response`インスタンスへ`cookie`メソッドを使い、クッキーを付加できます。このメソッドには、名前、値、それとこのクッキーが有効である分数を渡します。

    return response('Hello World')->cookie(
        'name', 'value', $minutes
    );

`cookie`メソッドには、あまり繁用されない、いくつかの引数を付けることもできます。そうした引数は、PHPネイティブの[setcookie](https://secure.php.net/manual/en/function.setcookie.php)メソッドの引数と、全般的に同じ目的や意味合いを持っています。

    return response('Hello World')->cookie(
        'name', 'value', $minutes, $path, $domain, $secure, $httpOnly
    );

もしくは、アプリケーションから送り出すレスポンスへアタッチするクッキーを「キュー」するために、`Cookie`ファサードが使えます。`queue`メソッドは、`Cookie`インスタンスか`Cookie`インスタンスを生成するために必要な引数を受け取ります。こうしたクッキーは、ブラウザにレスポンスが送信される前にアタッチされます。

    Cookie::queue(Cookie::make('name', 'value', $minutes));

    Cookie::queue('name', 'value', $minutes);

#### Cookieインスタンスの生成

後からレスポンスインスタンスへ付けることが可能な、`Symfony\Component\HttpFoundation\Cookie`インスタンスを生成したければ、`cookie`グローバルヘルパが使えます。このクッキーはレスポンスインスタンスへアタッチしない限り、クライアントへ送信されません。

    $cookie = cookie('name', 'value', $minutes);

    return response('Hello World')->cookie($cookie);

#### 有効時間切れクッキー

`Cookie`ファサードの`forget`メソッドにより、有効期間が切れたクッキーを削除できます。

    Cookie::queue(Cookie::forget('name'));

また、レスポンスインスタンスへ期限切れクッキーを付加することもできます。

    $cookie = Cookie::forget('name');

    return response('Hello World')->withCookie($cookie);

<a name="files"></a>
## ファイル

<a name="retrieving-uploaded-files"></a>
### アップロードファイルの取得

アップロードしたファイルへアクセスするには、`Illuminate\Http\Request`インスタンスに含まれている`file`メソッドか、動的プロパティを使用します。`file`メソッドは`Illuminate\Http\UploadedFile`クラスのインスタンスを返します。これはPHPの`SplFileInfo`クラスを拡張してあり、さまざまなファイル操作のメソッドを提供しています。

    $file = $request->file('photo');

    $file = $request->photo;

リクエスト中にファイルが存在しているかを判定するには、`hasFile`メソッドを使います。

    if ($request->hasFile('photo')) {
        //
    }

#### アップロードに成功したか確認

ファイルが存在しているかに付け加え、`isValid`メソッドで問題なくアップロードできたのかを確認できます。

    if ($request->file('photo')->isValid()) {
        //
    }

#### ファイルパスと拡張子

`UploadedFile`クラスはファイルの絶対パスと拡張子へアクセスするメソッドも提供しています。`extension`メソッドは、ファイルのコンテンツを元に拡張子を推測します。この拡張子はクライアントから提供された拡張子と異なっている可能性があります。

    $path = $request->photo->path();

    $extension = $request->photo->extension();

#### 他のファイルメソッド

他にも、たくさんのメソッドが`UploadedFile`インスタンスに存在しています。[このクラスのAPIドキュメント](https://api.symfony.com/master/Symfony/Component/HttpFoundation/File/UploadedFile.html)で、より詳細な情報が得られます。

<a name="storing-uploaded-files"></a>
### アップロードファイルの保存

アップロードファイルを保存するには、通常設定済みの[ファイルシステム](/docs/{{version}}/filesystem)の１つを使います。`UploadedFile`クラスの`store`メソッドは、ローカルにあろうが、Amazon S3のようなクラウドストレージであろうが、ディスクの１つへアップロードファイルを移動します。

`store`メソッドへは、ファイルシステムで設定したルートディレクトリからの相対位置で、どこに保存するか指定します。このパスにはファイル名を含んではいけません。保存ファイル名として一意のIDが自動的に生成されるためです。

`store`メソッドには、ファイルを保存するために使用するディスクの名前を任意の第２引数として指定もできます。メソッドはディスクルートからの相対ファイルパスを返します。

    $path = $request->photo->store('images');

    $path = $request->photo->store('images', 's3');

ファイル名を自動で生成したくない場合は、パスとファイル名、ディスク名を引数に取る、`storeAs`メソッドを使ってください。

    $path = $request->photo->storeAs('images', 'filename.jpg');

    $path = $request->photo->storeAs('images', 'filename.jpg', 's3');

<a name="configuring-trusted-proxies"></a>
## 信用するプロキシの設定

TLS／SSL証明を行うロードバランサの裏でアプリケーションが実行されている場合、アプリケーションがときどきHTTPSリンクを生成しないことに、気づくでしょう。典型的な理由は、トラフィックがロードバランサにより８０番ポートへフォワーディングされるため、セキュアなリンクを生成すべきだと判断できないからです。

これを解決するには、Laravelアプリケーションに含まれている、`App\Http\Middleware\TrustProxies`ミドルウェアを使用します。これでアプリケーションにとって信用できるロードバランサやプロキシを簡単にカスタマイズできます。信用できるプロキシをこのミドルウェアの`$proxies`プロパティへ配列としてリストしてください。信用するプロキシの設定に加え、信用できるプロキシの`$headers`も設定できます。

    <?php

    namespace App\Http\Middleware;

    use Fideloper\Proxy\TrustProxies as Middleware;
    use Illuminate\Http\Request;

    class TrustProxies extends Middleware
    {
        /**
         * このアプリケーションで信用するプロキシ
         *
         * @var string|array
         */
        protected $proxies = [
            '192.168.1.1',
            '192.168.1.2',
        ];

        /**
         * プロキシを検出するために使用するヘッダ
         *
         * @var int
         */
        protected $headers = Request::HEADER_X_FORWARDED_ALL;
    }

> {tip} AWS Elastic Load Balancingを使用している場合、`$headers`の値は`Request::HEADER_X_FORWARDED_AWS_ELB`に設定する必要があります。`$headers`で使用する内容の詳細は、Symfonyの[trusting proxies](https://symfony.com/doc/current/deployment/proxies.html)ドキュメントを参照してください。

#### 全プロキシを信用

Amazon AWSや他の「クラウド」ロードバランサプロバイダを使用している場合は、実際のバランサのIPアドレスは分かりません。このような場合、全プロキシを信用するために、`*`を使います。

    /**
     * このアプリケーションで信用するプロキシ
     *
     * @var string|array
     */
    protected $proxies = '*';
