# Laravel Sanctum

- [イントロダクション](#introduction)
    - [仕組み](#how-it-works)
- [インストール](#installation)
- [設定](#configuration)
    - [デフォルトモデルのオーバーライド](#overriding-default-models)
- [APIトークン認証](#api-token-authentication)
    - [APIトークンの発行](#issuing-api-tokens)
    - [トークンのアビリティ](#token-abilities)
    - [ルートの保護](#protecting-routes)
    - [トークンの削除](#revoking-tokens)
- [SPA認証](#spa-authentication)
    - [設定](#spa-configuration)
    - [認証](#spa-authenticating)
    - [ルートの保護](#protecting-spa-routes)
    - [プライベートブロードキャストチャンネルの認可](#authorizing-private-broadcast-channels)
- [モバイルアプリケーション認証](#mobile-application-authentication)
    - [APIトークンの発行](#issuing-mobile-api-tokens)
    - [ルートの保護](#protecting-mobile-api-routes)
    - [トークンの削除](#revoking-mobile-api-tokens)
- [テスト](#testing)

<a name="introduction"></a>
## イントロダクション

Laravel Sanctum（サンクタム、聖所）は、SPA(シングルページアプリケーション)、モバイルアプリケーション、およびシンプルなトークンベースのAPIに軽い認証システムを提供します。Sanctumを使用すればアプリケーションの各ユーザーは、自分のアカウントに対して複数のAPIトークンを生成できます。これらのトークンには、そのトークンが実行できるアクションを指定するアビリティ／スコープが付与されることもあります。

<a name="how-it-works"></a>
### 仕組み

LaravelSanctumは、２つの別々の問題を解決するために存在します。ライブラリを深く掘り下げる前に、それぞれについて説明しましょう。

<a name="how-it-works-api-tokens"></a>
#### APIトークン

１つ目にSanctumは、OAuthの複雑さなしに、ユーザーにAPIトークンを発行するために使用できるシンプルなパッケージです。この機能は、「パーソナルアクセストークン」を発行するGitHubやその他のアプリケーションに触発されています。たとえば、アプリケーションの「アカウント設定」に、ユーザーが自分のアカウントのAPIトークンを生成できる画面があるとします。Sanctumを使用して、これらのトークンを生成および管理できます。これらのトークンは通常、非常に長い有効期限(年)がありますが、ユーザーはいつでも手動で取り消すことができます。

Laravel Sanctumは、ユーザーAPIトークンを単一のデータベーステーブルに保存し、有効なAPIトークンを含む必要がある`Authorization`ヘッダを介して受信HTTPリクエストを認証することでこの機能を提供します。

<a name="how-it-works-spa-authentication"></a>
#### SPA認証

２つ目にSanctumは、Laravelを利用したAPIと通信する必要があるシングルページアプリケーション(SPA)を認証する簡単な方法を提供するために存在します。これらのSPAは、Laravelアプリケーションと同じリポジトリに存在する場合もあれば、Vue　CLIまたはNext.jsアプリケーションを使用して作成されたSPAなど、完全に別個のリポジトリである場合もあります。

この機能のために、Sanctumはいかなる種類のトークンも使用しません。代わりに、SanctumはLaravelの組み込みのクッキーベースのセッション認証サービスを使用します。通常、SanctumはLaravelの「web」認証ガードを利用してこれを実現します。これにより、CSRF保護、セッション認証の利点が提供できるだけでなく、XSSを介した認証資格情報の漏洩を保護します。

Sanctumは、受信リクエストが自身のSPAフロントエンドから発信された場合にのみクッキーを使用して認証を試みます。Sanctumが受信HTTPリクエストを調べるとき、最初に認証クッキーをチェックし、存在しない場合は、Sanctumは有効なAPIトークンの`Authorization`ヘッダを調べます。

> {tip} SanctumをAPIトークン認証のみ、またはSPA認証のみに使用することはまったく問題ありません。Sanctumを使用しているからといって、Sanctumが提供する両方の機能を使用する必要があるわけではありません。

<a name="installation"></a>
## インストール

Laravel Sanctumは、Composerパッケージマネージャーを介してインストールできます。

    composer require laravel/sanctum

次に、`vendor:publish` Artisanコマンドを使用してSanctum設定ファイルと移行ファイルをリソース公開する必要があります。`sanctum`設定ファイルは、アプリケーションの`config`ディレクトリに配置されます。

    php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"

最後に、データベースのマイグレーションを実行する必要があります。Sanctumは、APIトークンを格納するための1つのデータベーステーブルを作成します。

    php artisan migrate

次に、Sanctumを使用してSPAを認証する場合は、Sanctumのミドルウェアをアプリケーションの`app/Http/Kernel.php`ファイル内の`api`ミドルウェアグループに追加する必要があります。

    'api' => [
        \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
        'throttle:api',
        \Illuminate\Routing\Middleware\SubstituteBindings::class,
    ],

<a name="migration-customization"></a>
#### マイグレーションのカスタマイズ

Sanctumのデフォルトマイグレーションを使用しない場合は、`App\Providers\AppServiceProvider`クラスの`register`メソッドで`Sanctum::ignoreMigrations`メソッドを呼び出す必要があります。次のコマンドを実行して、デフォルトマイグレーションをエクスポートできます。`php artisan vendor:publish --tag=sanctum-migrations`

<a name="configuration"></a>
## 設定

<a name="overriding-default-models"></a>
### デフォルトモデルのオーバーライド

通常は必須ではありませんが、Sanctumが内部で使用する`PersonalAccessToken`モデルを自由に拡張できます。

    use Laravel\Sanctum\PersonalAccessToken as SanctumPersonalAccessToken;

    class PersonalAccessToken extends SanctumPersonalAccessToken
    {
        // ...
    }

次に、Sanctumが提供する`usePersonalAccessTokenModel`メソッドを使用して、カスタムモデルを使用するようにSanctumに指示します。通常、このメソッドは、アプリケーションのサービスプロバイダの1つの`boot`メソッドで呼び出す必要があります。

    use App\Models\Sanctum\PersonalAccessToken;
    use Laravel\Sanctum\Sanctum;

    /**
     * 全アプリケーションサービスの初期起動処理
     *
     * @return void
     */
    public function boot()
    {
        Sanctum::usePersonalAccessTokenModel(PersonalAccessToken::class);
    }

<a name="api-token-authentication"></a>
## APIトークン認証

> {tip} 独自のファーストパーティSPAを認証するためにAPIトークンを使用しないでください。代わりに、Sanctumの組み込みの[SPA認証機能](#spa-authentication)を使用してください。

<a name="issuing-api-tokens"></a>
### APIトークンの発行

Sanctumを使用すると、アプリケーションへのAPIリクエストの認証に使用できるAPIトークン／パーソナルアクセストークンを発行できます。APIトークンを使用してリクエストを行う場合、トークンは「Bearer」トークンとして「Authorization」ヘッダに含める必要があります。

ユーザーへのトークンの発行を開始するには、ユーザーモデルで`Laravel\Sanctum\HasApiTokens`トレイトを使用する必要があります。

    use Laravel\Sanctum\HasApiTokens;

    class User extends Authenticatable
    {
        use HasApiTokens, HasFactory, Notifiable;
    }

トークンを発行するには、`createToken`メソッドを使用します。`createToken`メソッドは`Laravel\Sanctum\NewAccessToken`インスタンスを返します。APIトークンは、データベースに保存する前にSHA-256ハッシュを使用してハッシュしますが、`NewAccessToken`インスタンスの`plainTextToken`プロパティを使用してトークンのプレーンテキスト値にアクセスできます。トークンが作成された直後に、この値をユーザーに表示する必要があります。

    use Illuminate\Http\Request;

    Route::post('/tokens/create', function (Request $request) {
        $token = $request->user()->createToken($request->token_name);

        return ['token' => $token->plainTextToken];
    });

`HasApiTokens`トレイトが提供する`tokens`　Eloquentリレーションを使用して、ユーザーのすべてのトークンにアクセスできます。

    foreach ($user->tokens as $token) {
        //
    }

<a name="token-abilities"></a>
### トークンのアビリティ

Sanctumでは、トークンに「アビリティ」を割り当てることができます。アビリティはOAuthの「スコープ」と同様の目的を果たします。能力の文字列配列を`createToken`メソッドの２番目の引数として渡すことができます。

    return $user->createToken('token-name', ['server:update'])->plainTextToken;

Sanctumが認証した受信リクエストを処理する場合、`tokenCan`メソッドを使用して、トークンに特定の機能があるかを判定できます。

    if ($user->tokenCan('server:update')) {
        //
    }

<a name="first-party-ui-initiated-requests"></a>
#### ファーストパーティのUIが開始したリクエスト

利便性のため、受信認証リクエストがファーストパーティSPAからのものであり、Sanctumの組み込み[SPA認証](#spa-authentication)を使用している場合、`tokenCan`メソッドは常に`true`を返します。

しかし、これは必ずしもアプリケーションがユーザーにアクションの実行を許可する必要があるわけではありません。通常、アプリケーションの [承認ポリシー](/docs/{{version}}}/authorization#creating-policies) は、トークンがアビリティの実行を許可されているかどうかを判断し、ユーザーインスタンス自身がアクションの実行を許可すべきかどうかをチェックします。

たとえば、サーバを管理するアプリケーションを想像してみると、これはトークンがサーバの更新を許可されていること、**および**サーバがユーザーに属していることを確認する必要があることを意味します。

```php
return $request->user()->id === $server->user_id &&
       $request->user()->tokenCan('server:update')
```

最初は、`tokenCan`メソッドを呼び出して、ファーストパーティのUIが開始したリクエストに対して常に`true`を返すことは、奇妙に思えるかもしれません。ただ、APIトークンが利用可能であり、`tokenCan`メソッドにより検査できると常に想定できるため便利です。このアプローチを採用することで、リクエストがアプリケーションのUIからトリガーされたのか、APIのサードパーティコンシューマーの1つによって開始されたのかを気にすることなく、アプリケーションの承認ポリシー内で常に`tokenCan`メソッドを呼び出すことができます。

<a name="protecting-routes"></a>
### ルートの保護

すべての受信リクエストを認証する必要があるようにルートを保護するには、`routes/web.php`および`routes/api.php`ルートファイル内の保護されたルートに`sanctum`認証ガードをアタッチする必要があります。このガードは、受信リクエストがステートフルなクッキー認証済みリクエストとして認証されるか、リクエストがサードパーティからのものである場合は有効なAPIトークンヘッダを含むことを保証します。

アプリケーションの`routes/web.php`ファイル内のルートを`sanctum`ガードを使用して認証することを推奨する理由を疑問に思われるかもしれません。Sanctumは、最初にLaravelの一般的なセッション認証クッキーを使用して受信リクエストの認証を試みます。そのクッキーが存在しない場合、Sanctumはリクエストの`Authorization`ヘッダのトークンを使用してリクエストの認証を試みます。さらに、Sanctumを使用してすべてのリクエストを認証すると、現在認証されているユーザーインスタンスで常に`tokenCan`メソッドを呼び出すことができます。

    use Illuminate\Http\Request;

    Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
        return $request->user();
    });

<a name="revoking-tokens"></a>
### トークンの削除

`Laravel\Sanctum\HasApiTokens`トレイトが提供する`tokens`リレーションを使用してデータベースからトークンを削除することにより、トークンを「取り消す」ことができます。

    // 全トークンの削除
    $user->tokens()->delete();

    // 現在のリクエストの認証に使用されたトークンを取り消す
    $request->user()->currentAccessToken()->delete();

    // 特定のトークンを取り消す
    $user->tokens()->where('id', $tokenId)->delete();

<a name="spa-authentication"></a>
## SPA認証

Sanctumは、Laravelを利用したAPIと通信する必要があるシングルページアプリケーション(SPA)を認証する簡単な手段を提供するためにも存在しています。これらのSPAは、Laravelアプリケーションと同じリポジトリに存在する場合もあれば、完全に別個のリポジトリである場合もあります。

この機能のために、Sanctumはいかなる種類のトークンも使用しません。代わりに、SanctumはLaravelの組み込みクッキーベースのセッション認証サービスを使用します。この認証へのアプローチは、CSRF保護、セッション認証の利点を提供するだけでなく、XSSを介した認証資格情報の漏洩から保護します。

> {note} 認証するには、SPAとAPIが同じトップレベルドメインを共有している必要があります。ただし、それらは異なるサブドメインに配置されるかもしれません。

<a name="spa-configuration"></a>
### 設定

<a name="configuring-your-first-party-domains"></a>
#### ファーストパーティドメインの設定

まず、SPAがリクエストを行うドメインを設定する必要があります。これらのドメインは、`sanctum`設定ファイルの`stateful`設定オプションを使用して構成します。この設定は、APIにリクエストを行うときにLaravelセッションクッキーを使用して「ステートフル」な認証を維持するドメインを決定します。

> {note} ポートを含むURL（例：`127.0.0.1:8000`）を介してアプリケーションにアクセスしている場合は、ドメインにポート番号を含める必要があります。

<a name="sanctum-middleware"></a>
#### Sanctumミドルウェア

次に、Sanctumのミドルウェアを`app/Http/Kernel.php`ファイル内の`api`ミドルウェアグループに追加する必要があります。このミドルウェアは、SPAからの受信リクエストがLaravelのセッションクッキーを使用して認証できるようにすると同時に、サードパーティまたはモバイルアプリケーションからのリクエストがAPIトークンを使用して認証できるようにする役割を果たします。

    use Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful;

    'api' => [
        EnsureFrontendRequestsAreStateful::class,
        'throttle:api',
        \Illuminate\Routing\Middleware\SubstituteBindings::class,
    ],

<a name="cors-and-cookies"></a>
#### CORSとクッキー

別のサブドメインで実行されるSPAからのアプリケーションでの認証に問題がある場合は、CORS(クロスオリジンリソースシェアリング)またはセッションクッキー設定を誤って設定している可能性があります。

アプリケーションのCORS設定が、値が`True`の`Access-Control-Allow-Credentials`ヘッダを返しているか確認する必要があります。これは、アプリケーションの`config/cors.php`設定ファイル内の`supports_credentials`オプションを`true`に設定することで実現できます。

さらに、アプリケーションのグローバルな`axios`インスタンスで`withCredentials`オプションを有効にする必要があります。通常、これは`resources/js/bootstrap.js`ファイルで実行する必要があります。フロントエンドからHTTPリクエストを行うためにAxiosを使用していない場合は、独自のHTTPクライアントで同等の構成を実行する必要があります。

    axios.defaults.withCredentials = true;

最後に、アプリケーションのセッションクッキードメイン設定で、ルートドメインのサブドメインを確実にサポートしてください。これを実現するには、アプリケーションの`config/session.php`設定ファイル内でドメインの先頭に`.`を付けます。

    'domain' => '.domain.com',

<a name="spa-authenticating"></a>
### 認証

<a name="csrf-protection"></a>
#### CSRF保護

SPAを認証するには、SPAの「ログイン」ページで最初に`/sanctum/csrf-cookie`エンドポイントにリクエストを送信して、アプリケーションのCSRF保護を初期化する必要があります。

    axios.get('/sanctum/csrf-cookie').then(response => {
        // ログイン…
    });

このリクエスト中に、Laravelは現在のCSRFトークンを含む`XSRF-TOKEN`クッキーをセットします。このトークンは、後続のリクエストへ`X-XSRF-TOKEN`ヘッダで渡す必要があります。これは、AxiosやAngular HttpClientなどの一部のHTTPクライアントライブラリでは自動的に行います。JavaScript　HTTPライブラリで値が設定されていない場合は、このルートで設定された`XSRF-TOKEN`クッキーの値と一致するように`X-XSRF-TOKEN`ヘッダを手動で設定する必要があります。

<a name="logging-in"></a>
#### ログイン

CSRF保護を初期化したら、Laravelアプリケーションの`/login`ルートに`POST`リクエストを行う必要があります。この`/login`ルートは[手動で実装](/docs/{{version}}/authentication#authenticating-users)するか、または[Laravel　Fortify](/docs/{{version}}/fortify)のようなヘッドレス認証パッケージを使用します。

ログインリクエストが成功すると、認証され、アプリケーションのルートへの後続リクエストは、Laravelアプリケーションがクライアントに発行したセッションクッキーを介して自動的に認証されます。さらに、アプリケーションはすでに`/sanctum/csrf-cookie`ルートにリクエストを送信しているため、JavaScript HTTPクライアントが`XSRF-TOKEN`クッキーの値を`X-XSRF-TOKEN`ヘッダで送信する限り、後続のリクエストは自動的にCSRF保護を受けます。

もちろん、アクティビティがないためにユーザーのセッションが期限切れになった場合、Laravelアプリケーションへの後続のリクエストは401か419HTTPエラー応答を受け取る可能性があります。この場合、ユーザーをSPAのログインページにリダイレクトする必要があります。

> {note} 独自の`/login`エンドポイントを自由に作成できます。ただし、標準の[Laravelが提供するセッションベースの認証サービス](/docs/{{version}}/authentication#authenticating-users)を使用してユーザーを認証していることを確認する必要があります。通常、これは`web`認証ガードを使用することを意味します。

<a name="protecting-spa-routes"></a>
### ルートの保護

すべての受信リクエストを認証する必要があるようにルートを保護するには、`routes/api.php`ファイル内のAPIルートに`sanctum`認証ガードを指定する必要があります。このガードは、受信リクエストがSPAからのステートフル認証済みリクエストとして認証されるか、リクエストがサードパーティからのものである場合は有効なAPIトークンヘッダを含むことを保証します。

    use Illuminate\Http\Request;

    Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
        return $request->user();
    });

<a name="authorizing-private-broadcast-channels"></a>
### プライベートブロードキャストチャンネルの認可

SPAが[プライベート/プレゼンスブロードキャストチャネル](/docs/{{version}}/Broadcasting#authorizing-channels)による認証の必要がある場合は、`routes/api.php`ファイル内で`Broadcast::routes`メソッドを呼び出しす必要があります。

    Broadcast::routes(['middleware' => ['auth:sanctum']]);

次に、Pusherの許可リクエストを成功させるために、[Laravel　Echo](/docs/{{version}}/Broadcasting#installing-laravel-echo)を初期化するときにカスタムPusher `authorizer`を提供する必要があります。これにより、アプリケーションは、[クロスドメインリクエスト用に適切に設定した](#cors-and-cookies)`axios`インスタンスを使用するようにPusherを構成できます。

    window.Echo = new Echo({
        broadcaster: "pusher",
        cluster: process.env.MIX_PUSHER_APP_CLUSTER,
        encrypted: true,
        key: process.env.MIX_PUSHER_APP_KEY,
        authorizer: (channel, options) => {
            return {
                authorize: (socketId, callback) => {
                    axios.post('/api/broadcasting/auth', {
                        socket_id: socketId,
                        channel_name: channel.name
                    })
                    .then(response => {
                        callback(false, response.data);
                    })
                    .catch(error => {
                        callback(true, error);
                    });
                }
            };
        },
    })

<a name="mobile-application-authentication"></a>
## モバイルアプリケーション認証

Sanctumトークンを使用して、APIに対するモバイルアプリケーションのリクエストを認証することもできます。モバイルアプリケーションリクエストを認証するプロセスは、サードパーティのAPIリクエストを認証するプロセスと似ています。ただし、APIトークンの発行方法にはわずかな違いがあります。

<a name="issuing-mobile-api-tokens"></a>
### APIトークンの発行

利用開始するには、ユーザーの電子メール/ユーザー名、パスワード、およびデバイス名を受け入れるルートを作成し、それらの資格情報を新しいSanctumトークンと交換します。このエンドポイントに付けられた「デバイス名」は情報提供を目的としたものであり、任意の値にすることができます。一般に、デバイス名の値は、「Nuno'siPhone12」などのユーザーが認識できる名前である必要があります。

通常、モバイルアプリケーションの「ログイン」画面からトークンエンドポイントにリクエストを送信します。エンドポイントはプレーンテキストのAPIトークンを返します。このトークンは、モバイルデバイスに保存され、追加のAPIリクエストを行うために使用されます。

    use App\Models\User;
    use Illuminate\Http\Request;
    use Illuminate\Support\Facades\Hash;
    use Illuminate\Validation\ValidationException;

    Route::post('/sanctum/token', function (Request $request) {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
            'device_name' => 'required',
        ]);

        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        return $user->createToken($request->device_name)->plainTextToken;
    });

モバイルアプリケーションがトークンを使用してアプリケーションにAPIリクエストを行う場合、`Authorization`ヘッダのトークンを`Bearer`トークンとして渡す必要があります。

> {tip} モバイルアプリケーションのトークンを発行するときに、[トークンのアビリティ](#token-abilities)を自由に指定することもできます。

<a name="protecting-mobile-api-routes"></a>
### ルートの保護

前述の通り、ルートに`sanctum`認証ガードを指定することにより、すべての受信リクエストが認証済みであるようにルートを保護できます。

    Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
        return $request->user();
    });

<a name="revoking-mobile-api-tokens"></a>
### トークンの削除

ユーザーがモバイルデバイスに発行したAPIトークンを取り消すことができるようにするには、WebアプリケーションのUIで「アカウント設定」部分で「取り消す」ボタンと一緒に名前をリストしてください。ユーザーが「取り消す」ボタンをクリックしたら、データベースからトークンを削除できます。`Laravel\Sanctum\HasApiTokens`トレイトによって提供される`tokens`リレーションを介して、ユーザーのAPIトークンにアクセスできることを忘れないでください。

    // すべてのトークンを取り消す
    $user->tokens()->delete();

    // 特定のトークンを取り消す
    $user->tokens()->where('id', $tokenId)->delete();

<a name="testing"></a>
## テスト

テスト中に、`Sanctum::actingAs`メソッドを使用して、ユーザーを認証し、トークンに付与するアビリティを指定できます。

    use App\Models\User;
    use Laravel\Sanctum\Sanctum;

    public function test_task_list_can_be_retrieved()
    {
        Sanctum::actingAs(
            User::factory()->create(),
            ['view-tasks']
        );

        $response = $this->get('/api/task');

        $response->assertOk();
    }

トークンにすべてのアビリティを付与したい場合は、`actingAs`メソッドへ指定するアビリティリストに`*`を含める必要があります。

    Sanctum::actingAs(
        User::factory()->create(),
        ['*']
    );
