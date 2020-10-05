# Laravel Sanctum

- [イントロダクション](#introduction)
    - [動作の仕組み](#how-it-works)
- [インストール](#installation)
- [APIトークン認証](#api-token-authentication)
    - [APIトークン発行](#issuing-api-tokens)
    - [トークンのアビリティ](#token-abilities)
    - [ルート保護](#protecting-routes)
    - [トークン破棄](#revoking-tokens)
- [SPA認証](#spa-authentication)
    - [設定](#spa-configuration)
    - [認証](#spa-authenticating)
    - [ルート保護](#protecting-spa-routes)
    - [プライベートブロードキャストチャンネルの認証](#authorizing-private-broadcast-channels)
- [モバイルアプリの認証](#mobile-application-authentication)
    - [APIトークン発行](#issuing-mobile-api-tokens)
    - [ルート保護](#protecting-mobile-api-routes)
    - [トークン破棄](#revoking-mobile-api-tokens)
- [テスト](#testing)

<a name="introduction"></a>
## イントロダクション

Laravel Sanctum（サンクタム：聖所）はSPA（Single Page Applications）やモバイルアプリケーションのための、シンプルでトークンベースのAPIを使った羽のように軽い認証システムです。Sanctumはアプリケーションのユーザーのアカウントごとに、複数のAPIトークンを生成できます。これらのトークンには、実行可能なアクションを限定する能力（アビリティ）／スコープを与えられます。

<a name="how-it-works"></a>
### 動作の仕組み

Laravel Sanctumは、2つの別個の問題を解決するために存在します。

#### APIトークン

１つ目はOAuthの煩雑さなしにユーザーへAPIトークンを発行するためのシンプルなパッケージの提供です。たとえば、ユーザーがAPIトークンを自分のアカウントへ生成すると想像してください。アプリケーションへ「アカウント設定」ページを用意するでしょう。こうしたトークンを生成し、管理するためにSanctumが使われます。こうしたトークンへは通常数年にも渡る、とても長い有効期間を指定します。しかし、ユーザー自身はいつでも破棄可能です。

この機能を実現するため、Laravel Sanctumは一つのデータベーステーブルへユーザーのAPIトークンを保存しておき、受信したリクエストが`Authorization`ヘッダに有効なAPIトークンを含んでいるかにより認証します。

#### SPA認証

２つ目の存在理由は、Laravelが提供するAPIを使用し通信する必要があるシングルページアプリケーション(SPA)へ、シンプルな認証方法を提供するためです。こうしたSPAはLaravelアプリケーションと同じリポジトリにあっても、まったく別のリポジトリに存在していてもかまいません。たとえばSPAがVue CLIを使用して生成された場合などです。

Sanctumはこの機能の実現のためにトークンは一切使用しません。代わりにLaravelへ組み込まれているクッキーベースのセッション認証サービスを使用します。これにより、XSSによる認証情報リークに対する保護と同時に、CSRF保護・セッションの認証を提供しています。皆さんのSPAのフロントエンドから送信されるリクエストに対し、Sanctumはクッキーだけを使用して認証を確立しようとします。

> {tip} APIトークン認証だけを使う場合、もしくはSPA認証だけを使う場合のどちらにもSanctumは適しています。Sanctumが２つの機能を提供していても、両方共に使う必要はありません。

<a name="installation"></a>
## インストール

Laravel SanctumはComposerでインストールします。

    composer require laravel/sanctum

次に、`vendor:publish` Artisanコマンドを使用して、Sanctumの設定とマイグレーションをリソース公開します。`sanctum`設定ファイルが`config`ディレクトリに設置されます。

    php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"

最後に、データベースマイグレーションを実行してください。SanctumはAPIトークンを保存しておくデータベースを１つ作成します。

    php artisan migrate

SPAの認証のためにSanctumを活用しようと計画している場合は、`app/Http/Kernel.php`ファイル中の`api`ミドルウェアグループへ、Sanctumのミドルウェアを追加します。

    use Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful;

    'api' => [
        EnsureFrontendRequestsAreStateful::class,
        'throttle:api',
        \Illuminate\Routing\Middleware\SubstituteBindings::class,
    ],

#### マイグレーションのカスタマイズ

Sanctumのデフォルトマイグレーションを使用しない場合は、`AppServiceProvider`の`register`メソッドの中で、`Sanctum::ignoreMigrations`を必ず呼び出してください。デフォルトマイグレーションは、`php artisan vendor:publish --tag=sanctum-migrations`を使えばエクスポートできます。

<a name="api-token-authentication"></a>
## APIトークン認証

> {tip} 皆さん自身のファーストパーティSPAを認証するためにAPIトークンを決して利用してはいけません。代わりに、Sanctumの組み込み[SPA認証](#spa-authentication)を使用してください。

<a name="issuing-api-tokens"></a>
### APIトークン発行

APIリクエスト認証に使用するため、APIトークン／パーソナルアクセストークンをSanctumは発行します。APIトークンを利用するリクエストを作成する場合は、`Bearer`トークンとして`Authorization`ヘッダにトークンを含める必要があります。

ユーザーにトークンを発行開始するには、Userモデルで`HasApiTokens`トレイトを使用してください。

    use Laravel\Sanctum\HasApiTokens;

    class User extends Authenticatable
    {
        use HasApiTokens, HasFactory, Notifiable;
    }

トークンを発行するには、`createToken`メソッドを使用します。この`createToken`メソッドは`Laravel\Sanctum\NewAccessToken`インスタンスを返します。APIトークンはデータベースへ格納される前に、SHA-256を使いハッシュされますが、`NewAccessToken`インスタンスの`plainTextToken`プロパティにより、平文の値へアクセスできます。トークンを生成したら、ユーザーへこの値をすぐに表示しなくてはなりません。

    $token = $user->createToken('token-name');

    return $token->plainTextToken;

そのユーザーのトークンすべてにアクセスするには、`HasApiTokens`トレイトが提供する`tokens` Eloquentリレーションを使用します。

    foreach ($user->tokens as $token) {
        //
    }

<a name="token-abilities"></a>
### トークンのアビリティ

OAuthの「スコープ」と同じように、Sanctumは「アビリティ（能力）」をトークンへ割り付けられます。`createToken`メソッドの第２引数として、アビリティの文字列の配列を渡してください。

    return $user->createToken('token-name', ['server:update'])->plainTextToken;

Sanctumにより認証されたリクエストを処理するとき、そのトークンが特定のアビリティを持っているかを`tokenCan`メソッドで判定できます。

    if ($user->tokenCan('server:update')) {
        //
    }

> {tip} 利便性のため、`tokenCan`メソッドは受信認証済みリクエストがファーストパーティSPAから送信されたとき、もしくはSanctumの組み込み[SPA認証](#spa-authentication)を使用している場合は常に`true`を返します。

<a name="protecting-routes"></a>
### ルート保護

受信リクエストをすべて認証済みに限定し、ルートを保護する場合は、`routes/api.php`ファイル中のAPIルートに対して`sanctum`認証ガードを指定する必要があります。このガードは受信リクエストが認証済みであると保証します。そのリクエストが皆さん自身のSPAからのステートフルな認証済みであるか、もしくはサードパーティからのリクエストの場合は有効なAPIトークンのヘッダを持っているかのどちらか一方であるか確認します。

    Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
        return $request->user();
    });

<a name="revoking-tokens"></a>
### トークン破棄

データベースから削除し、トークンを「破棄」するには、`HasApiTokens`トレイトが提供している`tokens`リレーションを使用します。

    // 全トークンの破棄
    $user->tokens()->delete();

    // このユーザーの現在のトークンを取り消す
    $request->user()->currentAccessToken()->delete();

    // 特定トークンの破棄
    $user->tokens()->where('id', $id)->delete();

<a name="spa-authentication"></a>
## SPA認証

Laravelを使ったAPIと通信する必要があるシングルページアプリケーション(SPA)へ、シンプルな認証方法を提供するためにSanctumを開発しました。こうしたSPAはLaravelアプリケーションと同じリポジトリにあっても、もしくはVue CLIを使用して生成したSPAのように、まったく別のリポジトリに存在していてもかまいません。

Sanctumはこの機能の実現のためにトークンは一切使用しません。代わりにLaravelへ組み込まれているクッキーベースのセッション認証サービスを使用します。これにより、XSSによる認証情報リークに対する保護と同時に、CSRF保護・セッションの認証を提供しています。皆さんのSPAのフロントエンドから送信されるリクエストに対し、Sanctumはクッキーだけを使用して認証を確立しようとします。

> {note} 認証するために、SPAとAPIは同じトップレベルドメインである必要があります。しかしながら、別のサブドメインに設置することは可能です。

<a name="spa-configuration"></a>
### 設定

#### ファーストパーティドメインの設定

最初に、どのドメインから皆さんのSPAがリクエストを作成するのか設定する必要があります。`sanctum`設定ファイルの`stateful`設定オプションを利用してこのドメインを指定します。この設定を元にして皆さんのAPIへリクエストを作成するときに、Laravelのセッションクッキーを使用することで「ステートフル」な認証を維持する必要があるドメインを判断します。

> {note} ポート（`127.0.0.1：8000`）を含むURLによりアプリケーションにアクセスする場合は、ドメインにポート番号を含める必要があります。

#### Sanctumミドルウェア

次に、`app/Http/Kernel.php`ファイル中の`api`ミドルウェアグループへ、Sanctumのミドルウェアを追加する必要があります。このミドルウェアは皆さんのSPAから受信するリクエストが、Laravelのセッションクッキーを使用して確実に認証できるようにする責任を負っています。同時に、サードパーティやモバイルアプリからのリクエストに対し、APIトークンを使用した認証ができるようにしています。

    use Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful;

    'api' => [
        EnsureFrontendRequestsAreStateful::class,
        'throttle:api',
        \Illuminate\Routing\Middleware\SubstituteBindings::class,
    ],

<a name="cors-and-cookies"></a>
#### CORSとクッキー

別のサブドメイン上のSPAからの認証でアプリケーションにトラブルが起きているのであれば、CORS(Cross-Origin Resource Sharing)かセッションクッキーの設定を間違えたのでしょう。

アプリケーションのCORS設定で、`Access-Control-Allow-Credentials`ヘッダに`True`の値を返すため、アプリケーションの`cors`設定ファイル中の`supports_credentials`オプションを`true`にしてください。

さらに、グローバル`axios`インスタンス上で、`withCredentials`オプションを有効にしているかも確認してください。通常、これは`resources/js/bootstrap.js`ファイルで実行されるべきです。

    axios.defaults.withCredentials = true;

最後に、アプリケーションのセッションクッキードメイン設定で、ルートドメイン下の全サブドメインをサポートしているかを確認する必要があります。`session`設定ファイル中で、`.`にドメイン名を続ければ指定できます。

    'domain' => '.domain.com',

<a name="spa-authenticating"></a>
### 認証

皆さんのSPAを認証するには、SPAのログインページで最初に`/sanctum/csrf-cookie`ルートへのリクエストを作成し、アプリケーションのCSRF保護を初期化しなくてはなりません。

    axios.get('/sanctum/csrf-cookie').then(response => {
        // ログイン処理…
    });

このリクエスト中にLaravelは現在のCSRFトークンを持つ`XSRF-TOKEN`クッキーをセットします。このトークンは続くリクエストで`X-XSRF-TOKEN`ヘッダに渡さなければなりません。AxiosとAngular HttpClientは自動的にこれを処理します。

CSRF保護の初期化後、通常Laravelでは`/login`であるルートへ`POST`リクエストを送る必要があります。この`login`ルートは`laravel/jetstream`[認証スカフォールド](/docs/{{version}}/authentication#introduction)が提供しています。

ログインリクエストに成功するとユーザーは認証され、Laravelのバックエンドがクライアントへ発行しているセッションクッキーにより、APIルートに対する以降のリクエストも自動的に認証されます。

> {tip} `/login`エンドポイントは自由に書けます。ただし標準的な、[Laravelが提供する認証サービスベースのセッション](/docs/{{version}}/authentication#authenticating-users)をユーザー認証で確実に使用してください。

<a name="protecting-spa-routes"></a>
### ルート保護

受信リクエストをすべて認証済みに限定し、ルートを保護する場合は、`routes/api.php`ファイル中のAPIルートに対して`sanctum`認証ガードを指定する必要があります。このガードは受信リクエストが認証済みであると保証します。そのリクエストが皆さん自身のSPAからのステートフルな認証済みであるか、もしくはサードパーティからのリクエストの場合は有効なAPIトークンのヘッダを持っているかのどちらか一方であるか確認します。

    Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
        return $request->user();
    });

<a name="authorizing-private-broadcast-channels"></a>
### プライベートブロードキャストチャンネルの認証

SPAで[プライベート／プレゼンスブロードキャストチャンネル](/docs/{{version}}/broadcasting#authorizing-channels)を使った認証が必要な場合は、`routes/api.php`ファイルの中で`Broadcast::routes`メソッドを呼び出す必要があります。

    Broadcast::routes(['middleware' => ['auth:sanctum']]);

次に、Pusherの認証リクエストを成功させるため、[Laravel Echo](/docs/{{version}}/broadcasting#installing-laravel-echo)の初期化時に、カスタムPusher `authorizer`を用意する必要があります。これにより、アプリケーションが[確実にクロスドメインのリクエストを処理できるように設定した](#cors-and-cookies)`axios`インスタンスをPusherが使用するように設定できます。

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
## モバイルアプリの認証

あなた自身のAPIに対するモバイルアプリのリクエストを認証するために、Sanctumトークンを使用できます。モバイルアプリのリクエストに対する認証手順は、サードパーティAPIリクエストに対する認証と似ています。しかし、APIトークンの発行方法に多少の違いがあります。

<a name="issuing-mobile-api-tokens"></a>
### APIトークン発行

まずはじめに、ユーザーのメールアドレス／ユーザー名、パスワード、デバイス名を受け取るルートを作成し、次にこうした認証情報を元に新しいSanctumトークンを受け取ります。このエンドポイントは平文のSanctumトークンを返し、それはモバイルデバイス上に保存され、それ以降のAPIリクエストを作成するために利用されます。

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

モバイルデバイスが、アプリケーションへのAPIリクエストを作成するためにトークンを使用するときは、`Bearer`トークンとして`Authorization`ヘッダへ渡します。

> {tip} モバイルアプリケーションに対してトークンを発行するときにも、自由に[トークンのアビリティ](#token-abilities)を指定できます。

<a name="protecting-mobile-api-routes"></a>
### ルート保護

以前に説明した通り、ルートへ`sanctum`認証ガードを指定することで、受信リクエストをすべて認証済み必須にし、ルートを保護できます。通常、`routes/api.php`ファイルでこのガードを指定したルートを定義します。

    Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
        return $request->user();
    });

<a name="revoking-mobile-api-tokens"></a>
### トークン破棄

モバイルデバイスに対して発行されたAPIトークンをユーザーが破棄できるようにするため、WebアプリケーションのUIで「アカウント設定」のようなページに一覧表示し、「破棄」ボタンを用意する必要があります。ユーザーが「破棄」ボタンをクリックしたら、データベースからトークンを削除します。`HasApiTokens`トレイトが提供する`tokens`リレーションにより、そのユーザーのAPIトークンへアクセスできるのを覚えておきましょう。

    // 全トークンの破棄
    $user->tokens()->delete();

    // 特定トークンの破棄
    $user->tokens()->where('id', $id)->delete();

<a name="testing"></a>
## テスト

テストをする時は、`Sanctum::actingAs`メソッドでユーザーを認証し、トークンにアビリティを許可する指定を行えます。

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

トークンに全アビリティを許可したい場合は、`actingAs`メソッドへ`*`を含めたアビリティリストを指定します。

    Sanctum::actingAs(
        User::factory()->create(),
        ['*']
    );
