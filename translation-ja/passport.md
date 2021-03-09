# Laravel Passport

- [イントロダクション](#introduction)
    - [Passportか？Sanctumか？？](#passport-or-sanctum)
- [インストール](#installation)
    - [Passportのデプロイ](#deploying-passport)
    - [マイグレーションのカスタマイズ](#migration-customization)
    - [Passportのアップグレード](#upgrading-passport)
- [設定](#configuration)
    - [クライアントシークレットハッシュ](#client-secret-hashing)
    - [トークン持続時間](#token-lifetimes)
    - [デフォルトモデルのオーバーライド](#overriding-default-models)
- [アクセストークンの発行](#issuing-access-tokens)
    - [クライアント管理](#managing-clients)
    - [トークンのリクエスト](#requesting-tokens)
    - [トークンのリフレッシュ](#refreshing-tokens)
    - [トークンの破棄](#revoking-tokens)
    - [トークンの破棄](#purging-tokens)
- [PKCEを使った認可コードグラント](#code-grant-pkce)
    - [クライアント生成](#creating-a-auth-pkce-grant-client)
    - [トークンのリクエスト](#requesting-auth-pkce-grant-tokens)
- [パスワードグラントのトークン](#password-grant-tokens)
    - [パスワードグラントクライアントの作成](#creating-a-password-grant-client)
    - [トークンのリクエスト](#requesting-password-grant-tokens)
    - [全スコープの要求](#requesting-all-scopes)
    - [ユーザープロバイダのカスタマイズ](#customizing-the-user-provider)
    - [ユーザー名フィールドのカスタマイズ](#customizing-the-username-field)
    - [パスワードバリデーションのカスタマイズ](#customizing-the-password-validation)
- [暗黙のグラントトークン](#implicit-grant-tokens)
- [クライアント認証情報グラントトークン](#client-credentials-grant-tokens)
- [パーソナルアクセストークン](#personal-access-tokens)
    - [パーソナルアクセスクライアントの作成](#creating-a-personal-access-client)
    - [パーソナルアクセストークンの管理](#managing-personal-access-tokens)
- [ルート保護](#protecting-routes)
    - [ミドルウェアによる保護](#via-middleware)
    - [アクセストークンの受け渡し](#passing-the-access-token)
- [トークンのスコープ](#token-scopes)
    - [スコープの定義](#defining-scopes)
    - [デフォルトスコープ](#default-scope)
    - [トークンへのスコープ割り付け](#assigning-scopes-to-tokens)
    - [スコープのチェック](#checking-scopes)
- [APIをJavaScriptで利用](#consuming-your-api-with-javascript)
- [イベント](#events)
- [テスト](#testing)

<a name="introduction"></a>
## イントロダクション

LaravelPassportは、Laravelアプリケーションに完全なOAuth2サーバ実装を数分で提供します。Passportは、Andy MillingtonとSimon Hampがメンテナンスしている[League OAuth2 server](https://github.com/thephpleague/oauth2-server)の上に構築されています。

> {note} このドキュメントは、皆さんがOAuth2に慣れていることを前提にしています。OAuth2について知らなければ、この先を続けて読む前に、一般的な[用語](https://oauth2.thephpleague.com/terminology/)とOAuth2の機能について予習してください。

<a name="passport-or-sanctum"></a>
### Passportか？Sanctumか？？

始める前に、アプリケーションがLaravel Passport、もしくは[Laravel Sanctum](/docs/{{version}}/sanctum)のどちらがより適しているかを検討することをお勧めします。アプリケーションが絶対にOAuth2をサポートする必要がある場合は、Laravel　Passportを使用する必要があります。

しかし、シングルページアプリケーションやモバイルアプリケーションを認証したり、APIトークンを発行したりする場合は、[Laravel Sanctum](/docs/{{version}}/sanctum)を使用する必要があります。Laravel SanctumはOAuth2をサポートしていません。ただし、はるかにシンプルななAPI認証開発エクスペリエンスを提供します。

<a name="installation"></a>
## インストール

Composerパッケージマネージャにより、Passportをインストールすることからはじめましょう。

    composer require laravel/passport

Passportの[サービスプロバイダ](/docs/{{version}}/provider)は独自のデータベースマイグレーションディレクトリを登録しているため、パッケージのインストール後にデータベースをマイグレーションする必要があります。Passportのマイグレーションにより、アプリケーションがOAuth2クライアントとアクセストークンを保存するために必要なテーブルが作成されます。

    php artisan migrate

次に、`passport:install` Artisanコマンドを実行する必要があります。このコマンドは、安全なアクセストークンを生成するために必要な暗号化キーを作成します。さらに、このコマンドは、アクセストークンの生成に使用される「個人アクセス」および「パスワード許可」クライアントを作成します。

    php artisan passport:install

> {tip} 自動増分整数の代わりに、Passportの`Client`モデルの主キー値としてUUIDを使用したい場合は、[`uuids`オプション](#client-uuids)を使いPassportをインストールしてください。

`passport:install`コマンドを実行し終えたら、`Laravel\Passport\HasApiTokens`トレイトを`App\Models\User`モデルへ追加してください。このトレイトは認証済みユーザーのトークンとスコープを調べられるように、モデルへ数個のヘルパメソッドを提供します。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Factories\HasFactory
    use Illuminate\Foundation\Auth\User as Authenticatable;
    use Illuminate\Notifications\Notifiable;
    use Laravel\Passport\HasApiTokens;

    class User extends Authenticatable
    {
        use HasApiTokens, HasFactory, Notifiable;
    }

次に、`App\Providers\AuthServiceProvider`の`boot`メソッド内で`Passport::routes`メソッドを呼び出す必要があります。このメソッドは、アクセストークンを発行し、アクセストークン、クライアント、およびパーソナルアクセストークンを取り消すために必要なルートを登録します。

    <?php

    namespace App\Providers;

    use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;
    use Illuminate\Support\Facades\Gate;
    use Laravel\Passport\Passport;

    class AuthServiceProvider extends ServiceProvider
    {
        /**
         * アプリケーションのポリシーのマップ
         *
         * @var array
         */
        protected $policies = [
            'App\Models\Model' => 'App\Policies\ModelPolicy',
        ];

        /**
         * 全認証／認可サービスの登録
         *
         * @return void
         */
        public function boot()
        {
            $this->registerPolicies();

            Passport::routes();
        }
    }

最後に、アプリケーションの`config/auth.php`設定ファイルで、`api`認証ガードの`driver`オプションを`passport`に設定する必要があります。これにより、受信APIリクエストを認証するときにPassportの`TokenGuard`を使用するようにアプリケーションに指示します。

    'guards' => [
        'web' => [
            'driver' => 'session',
            'provider' => 'users',
        ],

        'api' => [
            'driver' => 'passport',
            'provider' => 'users',
        ],
    ],

<a name="client-uuids"></a>
#### クライアントUUID

`--uuids`オプションを指定して`passport:install`コマンドを実行することもできます。このオプションは、Passportの`Client`モデルの主キー値として整数を自動増分する代わりにUUIDを使用することをPassportに指示します。`--uuids`オプションを指定して`passport:install`コマンドを実行すると、Passportのデフォルトのマイグレーションを無効にするための追加の手順が表示されます。

    php artisan passport:install --uuids

<a name="deploying-passport"></a>
### Passportのデプロイ

Passportをアプリケーションのサーバに初めてデプロイするときは、`passport:keys`コマンドを実行する必要があります。このコマンドは、アクセストークンを生成するためにPassportが必要とする暗号化キーを生成します。生成されたキーは通常、ソース管理しません。

    php artisan passport:keys

必要に応じて、Passportのキーをロードするパスを定義できます。これを実現するには、`Passport::loadKeysFrom`メソッドを使用できます。通常、このメソッドは、アプリケーションの`App\Providers\AuthServiceProvider`クラスの`boot`メソッドから呼び出す必要があります。

    /**
     * 全認証／認可の登録
     *
     * @return void
     */
    public function boot()
    {
        $this->registerPolicies();

        Passport::routes();

        Passport::loadKeysFrom(__DIR__.'/../secrets/oauth');
    }

<a name="loading-keys-from-the-environment"></a>
#### 環境からキーのロード

または、`vendor:publish` Artisanコマンドを使用してPassportの設定ファイルをリソース公開することもできます。

    php artisan vendor:publish --tag=passport-config

設定ファイルをリソース公開した後、環境変数として定義することにより、アプリケーションの暗号化キーをロードできます。

```bash
PASSPORT_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
<private key here>
-----END RSA PRIVATE KEY-----"

PASSPORT_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----
<public key here>
-----END PUBLIC KEY-----"
```

<a name="migration-customization"></a>
### マイグレーションのカスタマイズ

Passportのデフォルトのマイグレーションを使用しない場合は、`App\Providers\AppServiceProvider`クラスの`register`メソッドで`Passport::ignoreMigrations`メソッドを呼び出す必要があります。`vendor:publish` Artisanコマンドを使用してデフォルトのマイグレーションをエクスポートできます。

    php artisan vendor:publish --tag=passport-migrations

<a name="upgrading-passport"></a>
### Passportのアップグレード

Passportの新しいメジャーバージョンにアップグレードするときは、[アップグレードガイド](https://github.com/laravel/passport/blob/master/UPGRADE.md)を注意深く確認することが重要です。

<a name="configuration"></a>
## 設定

<a name="client-secret-hashing"></a>
### クライアントシークレットハッシュ

データベースに保存するときにクライアントのシークレットをハッシュする場合は、`App\Providers\AuthServiceProvider`クラスの`boot`メソッドで`Passport::hashClientSecrets`メソッドを呼び出す必要があります。

    use Laravel\Passport\Passport;

    Passport::hashClientSecrets();

有効にすると、すべてのクライアントシークレットは、作成した直後のみユーザーへ表示されます。平文テキストのクライアントシークレット値がデータベースに保存されることはないため、シークレットの値が失われた場合にその値を回復することはできません。

<a name="token-lifetimes"></a>
### トークン持続時間

デフォルトでは、Passportは１年後に有効期限が切れる長期アクセストークンを発行します。より長い／短いトークン有効期間を設定したい場合は、`tokensExpireIn`、`refreshTokensExpireIn`、`personalAccessTokensExpireIn`メソッドを使用します。これらのメソッドは、アプリケーションの`App\Providers\AuthServiceProvider`クラスの`boot`メソッドで呼び出す必要があります。

    /**
     * 全認証／認可の登録
     *
     * @return void
     */
    public function boot()
    {
        $this->registerPolicies();

        Passport::routes();

        Passport::tokensExpireIn(now()->addDays(15));
        Passport::refreshTokensExpireIn(now()->addDays(30));
        Passport::personalAccessTokensExpireIn(now()->addMonths(6));
    }

> {note} Passportのデータベーステーブルの`expires_at`カラムは読み取り専用であり、表示のみを目的としています。トークンを発行するとき、Passportは署名および暗号化されたトークン内に有効期限情報を保存します。トークンを無効にする必要がある場合は、[取り消す](#revoking-tokens)必要があります。

<a name="overriding-default-models"></a>
### デフォルトモデルのオーバーライド

独自のモデルを定義し、対応するPassportモデルを拡張することにより、Passportにより内部的に使用されるモデルを自由に拡張できます。

    use Laravel\Passport\Client as PassportClient;

    class Client extends PassportClient
    {
        // ...
    }

モデルを定義した後、`Laravel\Passport\Passport`クラスを介してカスタムモデルを使用するようにPassportに指示します。通常、アプリケーションの`App\Providers\AuthServiceProvider`クラスの`boot`メソッドでカスタムモデルをPassportへ知らせる必要があります。

    use App\Models\Passport\AuthCode;
    use App\Models\Passport\Client;
    use App\Models\Passport\PersonalAccessClient;
    use App\Models\Passport\Token;

    /**
     * 全認証／認可の登録
     *
     * @return void
     */
    public function boot()
    {
        $this->registerPolicies();

        Passport::routes();

        Passport::useTokenModel(Token::class);
        Passport::useClientModel(Client::class);
        Passport::useAuthCodeModel(AuthCode::class);
        Passport::usePersonalAccessClientModel(PersonalAccessClient::class);
    }

<a name="issuing-access-tokens"></a>
## アクセストークンの発行

認証コードを介してOAuth2を使用することは、OAuth2を扱う時にほとんどの開発者が精通している方法です。認証コードを使用する場合、クライアントアプリケーションはユーザーをサーバにリダイレクトし、そこでユーザーはクライアントへアクセストークンを発行するリクエストを承認または拒否します。

<a name="managing-clients"></a>
### クライアント管理

あなたのアプリケーションのAPIと連携する必要のある、アプリケーションを構築しようとしている開発者たちは、最初に「クライアント」を作成することにより、彼らのアプリケーションを登録しなくてはなりません。通常、アプリケーションの名前と、許可のリクエストをユーザーが承認した後に、アプリケーションがリダイレクトされるURLにより、登録情報は構成されます。

<a name="the-passportclient-command"></a>
#### `passport:client`コマンド

クライアントを作成する一番簡単な方法は、`passport:client` Artisanコマンドを使うことです。このコマンドは、OAuth2の機能をテストするため、皆さん自身のクライアントを作成する場合に使用できます。`client`コマンドを実行すると、Passportはクライアントに関する情報の入力を促し、クライアントIDとシークレットを表示します。

    php artisan passport:client

**リダイレクトURL**

クライアントに複数のリダイレクトURLを許可する場合は、`passport:client`コマンドでURLの入力を求められたときに、カンマ区切りのリストを使用して指定してください。カンマを含むURLは、URLエンコードする必要があります。

```bash
http://example.com/callback,http://examplefoo.com/callback
```

<a name="clients-json-api"></a>
#### JSON API

アプリケーションのユーザーは`client`コマンドを利用できないため、Passportはクライアントの作成に使用できるJSON APIを提供します。これにより、クライアントを作成、更新、および削除するためにコントローラを手動でコーディングする手間が省けます。

しかし、ユーザーにクライアントを管理してもらうダッシュボードを提供するために、PassportのJSON APIと皆さんのフロントエンドを結合する必要があります。以降から、クライアントを管理するためのAPIエンドポイントをすべて説明します。エンドポイントへのHTTPリクエスト作成をデモンストレートするため利便性を考慮し、[Axios](https://github.com/mzabriskie/axios)を使用していきましょう。

JSON APIは`web`と`auth`ミドルウェアにより保護されています。そのため、みなさん自身のアプリケーションからのみ呼び出せます。外部ソースから呼び出すことはできません。

<a name="get-oauthclients"></a>
#### `GET /oauth/clients`

このルートは認証されたユーザーの全クライアントを返します。ユーザーのクライアントの全リストは、主にクライアントを編集、削除する場合に役立ちます。

    axios.get('/oauth/clients')
        .then(response => {
            console.log(response.data);
        });

<a name="post-oauthclients"></a>
#### `POST /oauth/clients`

このルートは新クライアントを作成するために使用します。これには２つのデータが必要です。クライアントの名前（`name`）と、リダイレクト（`redirect`）のURLです。`redirect`のURLは許可のリクエストが承認されるか、拒否された後のユーザーのリダイレクト先です。

クライアントを作成すると、クライアントIDとクライアントシークレットが発行されます。これらの値はあなたのアプリケーションへリクエストし、アクセストークンを取得する時に使用されます。クライアント作成ルートは、新しいクライアントインスタンスを返します。

    const data = {
        name: 'Client Name',
        redirect: 'http://example.com/callback'
    };

    axios.post('/oauth/clients', data)
        .then(response => {
            console.log(response.data);
        })
        .catch (response => {
            // レスポンス上のエラーのリスト
        });

<a name="put-oauthclientsclient-id"></a>
#### `PUT /oauth/clients/{client-id}`

このルートはクライアントを更新するために使用します。それには２つのデータが必要です。クライアントの`name`と`redirect`のURLです。`redirect`のURLは許可のリクエストが承認されるか、拒否され後のユーザーのリダイレクト先です。このルートは更新されたクライアントインスタンスを返します。

    const data = {
        name: 'New Client Name',
        redirect: 'http://example.com/callback'
    };

    axios.put('/oauth/clients/' + clientId, data)
        .then(response => {
            console.log(response.data);
        })
        .catch (response => {
            // レスポンス上のエラーのリスト
        });

<a name="delete-oauthclientsclient-id"></a>
#### `DELETE /oauth/clients/{client-id}`

このルートはクライアントを削除するために使用します。

    axios.delete('/oauth/clients/' + clientId)
        .then(response => {
            //
        });

<a name="requesting-tokens"></a>
### トークンのリクエスト

<a name="requesting-tokens-redirecting-for-authorization"></a>
#### 許可のリダイレクト

クライアントが作成されると、開発者はクライアントIDとシークレットを使用し、あなたのアプリケーションへ許可コードとアクセストークンをリクエストするでしょう。まず、API利用側アプリケーションは以下のように、あなたのアプリケーションの`/oauth/authorize`ルートへのリダイレクトリクエストを作成する必要があります。

    use Illuminate\Http\Request;
    use Illuminate\Support\Str;

    Route::get('/redirect', function (Request $request) {
        $request->session()->put('state', $state = Str::random(40));

        $query = http_build_query([
            'client_id' => 'client-id',
            'redirect_uri' => 'http://third-party-app.com/callback',
            'response_type' => 'code',
            'scope' => '',
            'state' => $state,
        ]);

        return redirect('http://passport-app.com/oauth/authorize?'.$query);
    });

> {tip} `/oauth/authorize`ルートは、すでに`Passport::routes`メソッドが定義づけていることを覚えておいてください。このルートを自分で定義する必要はありません。

<a name="approving-the-request"></a>
#### リクエストの承認

許可のリクエストを受け取ると、Passportはユーザーがその許可のリクエストを承認するか、拒絶するかのテンプレートを自動的に表示します。ユーザーが許可した場合、API利用側アプリケーションが指定した`redirect_uri`へリダイレクトします。`redirect_uri`は、クライアントを作成した時に指定した`redirect`のURLと一致する必要があります。

承認画面をカスタマイズする場合は、`vendor:publish` Artisanコマンドを使用してPassportのビューをリソース公開します。公開したビューは、`resources/views/vendor/passport`ディレクトリに配置されます。

    php artisan vendor:publish --tag=passport-views

ファーストパーティ製クライアントにより認可中のような場合、認可プロンプトをとばしたい場合もあり得ます。[`Client`モデルを拡張し](#overriding-default-models)、`skipsAuthorization`メソッドを定義することで実現できます。`skipsAuthorization`がクライアントは認証済みとして`true`を返すと、そのユーザーをすぐに`redirect_uri`へリダイレクトで戻します。

    <?php

    namespace App\Models\Passport;

    use Laravel\Passport\Client as BaseClient;

    class Client extends BaseClient
    {
        /**
         * クライアントが認可プロンプトを飛ばすべきか決める
         *
         * @return bool
         */
        public function skipsAuthorization()
        {
            return $this->firstParty();
        }
    }

<a name="requesting-tokens-converting-authorization-codes-to-access-tokens"></a>
#### 許可コードからアクセストークンへの変換

ユーザーが承認リクエストを承認すると、ユーザーは利用側アプリケーションにリダイレクトされます。利用側はまず、リダイレクトの前に保存した値に対して`state`パラメーターを確認する必要があります。状態パラメータが一致する場合、利用側はアプリケーションへ`POST`リクエストを発行してアクセストークンをリクエストする必要があります。リクエストには、ユーザーが認証リクエストを承認したときにアプリケーションが発行した認証コードを含める必要があります。

    use Illuminate\Http\Request;
    use Illuminate\Support\Facades\Http;

    Route::get('/callback', function (Request $request) {
        $state = $request->session()->pull('state');

        throw_unless(
            strlen($state) > 0 && $state === $request->state,
            InvalidArgumentException::class
        );

        $response = Http::asForm()->post('http://passport-app.com/oauth/token', [
            'grant_type' => 'authorization_code',
            'client_id' => 'client-id',
            'client_secret' => 'client-secret',
            'redirect_uri' => 'http://third-party-app.com/callback',
            'code' => $request->code,
        ]);

        return $response->json();
    });

この`/oauth/token`ルートは、`access_token`、`refresh_token`、`expires_in`属性を含むJSONレスポンスを返します。`expires_in`属性は、アクセストークンが無効になるまでの秒数を含んでいます。

> {tip} `/oauth/authorize`ルートと同様に、`/oauth/token`ルートは`Passport::routes`メソッドによって定義されます。このルートを手動で定義する必要はありません。

<a name="tokens-json-api"></a>
#### JSON API

Passportには、承認済みアクセストークンを管理するためのJSON APIも含んでいます。これを独自のフロントエンドと組み合わせ、アクセストークンを管理するダッシュボードをユーザーへ提供できます。便宜上、[Axios](https://github.com/mzabriskie/axios)をエンドポイントへのHTTPリクエストを生成するデモンストレーションのため使用しています。JSON APIは`web`と`auth`ミドルウェアにより保護されているため、自身のアプリケーションからのみ呼び出しできます。

<a name="get-oauthtokens"></a>
#### `GET /oauth/tokens`

このルートは、認証されたユーザーが作成した、承認済みアクセストークンをすべて返します。これは主に取り消すトークンを選んでもらうため、ユーザーの全トークンを一覧リスト表示するのに便利です。

    axios.get('/oauth/tokens')
        .then(response => {
            console.log(response.data);
        });

<a name="delete-oauthtokenstoken-id"></a>
#### `DELETE /oauth/tokens/{token-id}`

このルートは、認証済みアクセストークンと関連するリフレッシュトークンを取り消すために使います。

    axios.delete('/oauth/tokens/' + tokenId);

<a name="refreshing-tokens"></a>
### トークンのリフレッシュ

アプリケーションが短期間のアクセストークンを発行する場合、ユーザーはアクセストークンが発行されたときに提供された更新トークンを利用して、アクセストークンを更新する必要があります。

    use Illuminate\Support\Facades\Http;

    $response = Http::asForm()->post('http://passport-app.com/oauth/token', [
        'grant_type' => 'refresh_token',
        'refresh_token' => 'the-refresh-token',
        'client_id' => 'client-id',
        'client_secret' => 'client-secret',
        'scope' => '',
    ]);

    return $response->json();

この`/oauth/token`ルートは、`access_token`、`refresh_token`、`expires_in`属性を含むJSONレスポンスを返します。`expires_in`属性は、アクセストークンが無効になるまでの秒数を含んでいます。

<a name="revoking-tokens"></a>
### トークンの取り消し

`Laravel\Passport\TokenRepository`の`revokeAccessToken`メソッドを使用してトークンを取り消すことができます。`Laravel\Passport\RefreshTokenRepository`の`revokeRefreshTokensByAccessTokenId`メソッドを使用して、トークンの更新トークンを取り消すことができます。これらのクラスは、Laravelの[サービスコンテナ](/docs/{{version}}/container)を使用して解決できます。

    use Laravel\Passport\TokenRepository;
    use Laravel\Passport\RefreshTokenRepository;

    $tokenRepository = app(TokenRepository::class);
    $refreshTokenRepository = app(RefreshTokenRepository::class);

    // アクセストークンの取り消し
    $tokenRepository->revokeAccessToken($tokenId);

    // そのトークンのリフレッシュトークンを全て取り消し
    $refreshTokenRepository->revokeRefreshTokensByAccessTokenId($tokenId);

<a name="purging-tokens"></a>
### トークンの破棄

トークンが取り消されたり期限切れになったりした場合は、データベースからトークンを削除することを推奨します。Passportに含まれている`passport:purge` Artisanコマンドでこれを実行できます。

    # 無効・期限切れのトークンと認可コードを破棄する
    php artisan passport:purge

    # 無効なトークンと認可コードのみ破棄する
    php artisan passport:purge --revoked

    # 期限切れのトークンと認可コードのみ破棄する
    php artisan passport:purge --expired

また、アプリケーションの`App\Console\Kernel`クラスで[ジョブの実行スケジュール](/docs/{{version}}/scheduleing)を設定して、スケジュールに従ってトークンを自動的に整理することもできます。

    /**
     * アプリケーションのコマンドスケジュール定義
     *
     * @param  \Illuminate\Console\Scheduling\Schedule  $schedule
     * @return void
     */
    protected function schedule(Schedule $schedule)
    {
        $schedule->command('passport:purge')->hourly();
    }

<a name="code-grant-pkce"></a>
## PKCEを使った認可コードグラント

"Proof Key for Code Exchange" (PKCE)を使用する認可コードグラントは、シングルページアプリケーションやネイティブアプリケーションが、APIへアクセスするための安全な認証方法です。このグラントはクライアントの秘密コードを十分な機密を保ち保存できないか、もしくは認可コード横取り攻撃の危険を軽減する必要がある場合に、必ず使用すべきです。アクセストークンのために認可コードを交換するときに、クライアントの秘密コードを「コードベリファイヤ(code verifier)」と「コードチャレンジ(code challenge)」のコンピネーションに置き換えます。

<a name="creating-a-auth-pkce-grant-client"></a>
### クライアント生成

アプリケーションがPKCEでの認証コードグラントを介してトークンを発行する前に、PKCE対応のクライアントを作成する必要があります。これは、`passport:client` Artisanコマンドと`--public`オプションを使用して行えます。

    php artisan passport:client --public

<a name="requesting-auth-pkce-grant-tokens"></a>
### トークンのリクエスト

<a name="code-verifier-code-challenge"></a>
#### コードベリファイヤとコードチャレンジ

この認可グラントではクライアント秘密コードが提供されないため、開発者はトークンを要求するためにコードベリファイヤとコードチャレンジのコンビネーションを生成する必要があります。

コードベリファイアは、[RFC 7636 仕様](https://tools.ietf.org/html/rfc7636)で定義されているように、文字、数字、`"-"`、`"."`、`"_"`、`"~"`文字を含む４３文字から１２８文字のランダムな文字列でなければなりません。


コードチャレンジはURL／ファイルネームセーフな文字をBase64エンコードしたものである必要があります。文字列終端の`'='`文字を削除し、ラインブレイクやホワイトスペースを含まず、その他はそのままにします。

    $encoded = base64_encode(hash('sha256', $code_verifier, true));

    $codeChallenge = strtr(rtrim($encoded, '='), '+/', '-_');

<a name="code-grant-pkce-redirecting-for-authorization"></a>
#### 許可のリダイレクト

クライアントが生成できたら、アプリケーションから認可コードとアクセストークンをリクエストするために、クライアントIDと生成したコードベリファイヤ、コードチャレンジを使用します。最初に、認可要求側のアプリケーションは、あなたのアプリケーションの`/oauth/authorize`ルートへのリダイレクトリクエストを生成する必要があります。

    use Illuminate\Http\Request;
    use Illuminate\Support\Str;

    Route::get('/redirect', function (Request $request) {
        $request->session()->put('state', $state = Str::random(40));

        $request->session()->put(
            'code_verifier', $code_verifier = Str::random(128)
        );

        $codeChallenge = strtr(rtrim(
            base64_encode(hash('sha256', $code_verifier, true))
        , '='), '+/', '-_');

        $query = http_build_query([
            'client_id' => 'client-id',
            'redirect_uri' => 'http://third-party-app.com/callback',
            'response_type' => 'code',
            'scope' => '',
            'state' => $state,
            'code_challenge' => $codeChallenge,
            'code_challenge_method' => 'S256',
        ]);

        return redirect('http://your-app.com/oauth/authorize?'.$query);
    });

<a name="code-grant-pkce-converting-authorization-codes-to-access-tokens"></a>
#### 許可コードからアクセストークンへの変換

ユーザーが認可リクエストを承認すると、認可要求側のアプリケーションへリダイレクで戻されます。認可要求側では認可コードグラントの規約に従い、リダイレクトの前に保存しておいた値と、`state`パラメータを検証する必要があります。

stateパラメータが一致したら、要求側はアクセストークンをリクエストするために、あなたのアプリケーションへ`POST`リクエストを発行する必要があります。そのリクエストは最初に生成したコードベリファイヤと同時に、ユーザーが認可リクエストを承認したときにあなたのアプリケーションが発行した認可コードを持っている必要があります。

    use Illuminate\Http\Request;
    use Illuminate\Support\Facades\Http;

    Route::get('/callback', function (Request $request) {
        $state = $request->session()->pull('state');

        $codeVerifier = $request->session()->pull('code_verifier');

        throw_unless(
            strlen($state) > 0 && $state === $request->state,
            InvalidArgumentException::class
        );

        $response = Http::asForm()->post('http://passport-app.com/oauth/token', [
            'grant_type' => 'authorization_code',
            'client_id' => 'client-id',
            'redirect_uri' => 'http://third-party-app.com/callback',
            'code_verifier' => $codeVerifier,
            'code' => $request->code,
        ]);

        return $response->json();
    });

<a name="password-grant-tokens"></a>
## パスワードグラントのトークン

OAuth2パスワードグラントにより、モバイルアプリケーションなどの他のファーストパーティクライアントは、電子メールアドレス／ユーザー名とパスワードを使用してアクセストークンを取得できます。これにより、ユーザーがOAuth2認証コードのリダイレクトフロー全体を実行しなくても、ファーストパーティクライアントにアクセストークンを安全に発行できます。

<a name="creating-a-password-grant-client"></a>
### パスワードグラントクライアントの作成

アプリケーションがパスワードグラントを介してトークンを発行する前に、パスワードグラントクライアントを作成する必要があります。これは、`--password`オプションを指定した`passport:client` Artisanコマンドを使用して行えます。**すでに`passport:install`コマンドを実行している場合は、次のコマンドを実行する必要はありません:**

    php artisan passport:client --password

<a name="requesting-password-grant-tokens"></a>
### トークンのリクエスト

パスワードグラントクライアントを作成したら、ユーザーのメールアドレスとパスワードを指定し、`/oauth/token`ルートへ`POST`リクエストを発行することで、アクセストークンをリクエストできます。このルートは、`Passport::routes`メソッドが登録しているため、自分で定義する必要がないことを覚えておきましょう。リクエストに成功すると、サーバから`access_token`と`refresh_token`のJSONレスポンスを受け取ります。

    use Illuminate\Support\Facades\Http;

    $response = Http::asForm()->post('http://passport-app.com/oauth/token', [
        'grant_type' => 'password',
        'client_id' => 'client-id',
        'client_secret' => 'client-secret',
        'username' => 'taylor@laravel.com',
        'password' => 'my-password',
        'scope' => '',
    ]);

    return $response->json();

> {tip} アクセストークンはデフォルトで、長期間有効であることを記憶しておきましょう。ただし、必要であれば自由に、[アクセストークンの最長持続時間を設定](#configuration)できます。

<a name="requesting-all-scopes"></a>
### 全スコープの要求

パスワードグラント、またはクライアント認証情報グラントを使用時は、あなたのアプリケーションでサポートする全スコープを許可するトークンを発行したいと考えるかと思います。`*`スコープをリクエストすれば可能です。`*`スコープをリクエストすると、そのトークンインスタンスの`can`メソッドは、いつも`true`を返します。このスコープは`password`か`client_credentials`グラントを使って発行されたトークのみに割り付けるのが良いでしょう。

    use Illuminate\Support\Facades\Http;

    $response = Http::asForm()->post('http://passport-app.com/oauth/token', [
        'grant_type' => 'password',
        'client_id' => 'client-id',
        'client_secret' => 'client-secret',
        'username' => 'taylor@laravel.com',
        'password' => 'my-password',
        'scope' => '*',
    ]);

<a name="customizing-the-user-provider"></a>
### ユーザープロバイダのカスタマイズ

アプリケーションが複数の[認証ユーザープロバイダ](/docs/{{version}}/authentication#introduction)を使用している場合は、`artisan passport:client --password`コマンドを介してクライアントを作成する時に、`--provider`オプションを指定することで、パスワードグラントクライアントが使用するユーザープロバイダを指定できます。指定するプロバイダ名は、アプリケーションの`config/auth.php`設定ファイルで定義している有効なプロバイダと一致する必要があります。次に、[ミドルウェアを使用してルートを保護](#via-middleware)して、ガードの指定するプロバイダのユーザーのみが許可されるようにすることができます。

<a name="customizing-the-username-field"></a>
### ユーザー名フィールドのカスタマイズ

パスワードグラントを使用して認証する場合、Passportは認証可能なモデルの`email`属性を「ユーザー名」として使用します。ただし、モデルで`findForPassport`メソッドを定義することにより、この動作をカスタマイズできます。

    <?php

    namespace App\Models;

    use Illuminate\Foundation\Auth\User as Authenticatable;
    use Illuminate\Notifications\Notifiable;
    use Laravel\Passport\HasApiTokens;

    class User extends Authenticatable
    {
        use HasApiTokens, Notifiable;

        /**
         * 指定されたユーザー名のユーザーインスタンスを見つける
         *
         * @param  string  $username
         * @return \App\Models\User
         */
        public function findForPassport($username)
        {
            return $this->where('username', $username)->first();
        }
    }

<a name="customizing-the-password-validation"></a>
### パスワードバリデーションのカスタマイズ

パスワードガードを使用して認証している場合、Passportは指定されたパスワードを確認するためにモデルの`password`属性を使用します。もし、`password`属性を持っていないか、パスワードのバリデーションロジックをカスタマイズしたい場合は、モデルの`validateForPassportPasswordGrant`メソッドを定義してください。

    <?php

    namespace App\Models;

    use Illuminate\Foundation\Auth\User as Authenticatable;
    use Illuminate\Notifications\Notifiable;
    use Illuminate\Support\Facades\Hash;
    use Laravel\Passport\HasApiTokens;

    class User extends Authenticatable
    {
        use HasApiTokens, Notifiable;

        /**
         * Passportパスワードグラントのために、ユーザーのパスワードをバリデート
         *
         * @param  string  $password
         * @return bool
         */
        public function validateForPassportPasswordGrant($password)
        {
            return Hash::check($password, $this->password);
        }
    }

<a name="implicit-grant-tokens"></a>
## 暗黙のグラントトークン

暗黙的なグラントは、認証コードグラントに似ています。ただし、トークンは認証コードを交換せずにクライアントへ返します。このグラントは、クライアントの利用資格情報を安全に保存できないJavaScriptまたはモバイルアプリケーションで最も一般的に使用します。このグラントを有効にするには、アプリケーションの`App\Providers\AuthServiceProvider`クラスの`boot`メソッドで`enableImplicitGrant`メソッドを呼び出します。

    /**
     * 全認証／認可の登録
     *
     * @return void
     */
    public function boot()
    {
        $this->registerPolicies();

        Passport::routes();

        Passport::enableImplicitGrant();
    }

暗黙グラントが有効になると、開発者はクライアントIDを使用してアプリケーションにアクセストークンをリクエストできます。利用側アプリケーションは、次のようにアプリケーションの`/oauth/authorize`ルートにリダイレクトリクエストを行う必要があります。

    use Illuminate\Http\Request;

    Route::get('/redirect', function (Request $request) {
        $request->session()->put('state', $state = Str::random(40));

        $query = http_build_query([
            'client_id' => 'client-id',
            'redirect_uri' => 'http://third-party-app.com/callback',
            'response_type' => 'token',
            'scope' => '',
            'state' => $state,
        ]);

        return redirect('http://your-app.com/oauth/authorize?'.$query);
    });

> {tip} `/oauth/authorize`ルートは、すでに`Passport::routes`メソッドが定義づけていることを覚えておいてください。このルートを自分で定義する必要はありません。

<a name="client-credentials-grant-tokens"></a>
## クライアント認証情報グラントトークン

クライアント認証情報グラントはマシンーマシン間の認証に最適です。たとえば、APIによりメンテナンスタスクを実行する、定期実行ジョブに使用できます。

アプリケーションがクライアント利用資格情報グラントを介してトークンを発行する前に、クライアント利用資格情報グラントクライアントを作成する必要があります。これは、`passport:client` Artisanコマンドの`--client`オプションを使用して行うことができます。

    php artisan passport:client --client

次に、このグラントタイプを使用するために、`app/Http/Kernel.php`ファイルの`$routeMiddleware`へ、`CheckClientCredentials`ミドルウェアを追加する必要があります。

    use Laravel\Passport\Http\Middleware\CheckClientCredentials;

    protected $routeMiddleware = [
        'client' => CheckClientCredentials::class,
    ];

それから、ルートへこのミドルウェアを指定します。

    Route::get('/orders', function (Request $request) {
        ...
    })->middleware('client');

ルートへのアクセスを特定のスコープに制限するには、`client`ミドルウェアをルートに接続するときに、必要なスコープのコンマ区切りのリストを指定できます。

    Route::get('/orders', function (Request $request) {
        ...
    })->middleware('client:check-status,your-scope');

<a name="retrieving-tokens"></a>
### トークンの取得

このグラントタイプを使用してトークンを取得するには、`oauth/token`エンドポイントにリクエストを送信します。

    use Illuminate\Support\Facades\Http;

    $response = Http::asForm()->post('http://passport-app.com/oauth/token', [
        'grant_type' => 'client_credentials',
        'client_id' => 'client-id',
        'client_secret' => 'client-secret',
        'scope' => 'your-scope',
    ]);

    return $response->json()['access_token'];

<a name="personal-access-tokens"></a>
## パーソナルアクセストークン

ときどき、あなたのユーザーが典型的なコードリダイレクションフローに従うのではなく、自分たち自身でアクセストークンを発行したがることもあるでしょう。あなたのアプリケーションのUIを通じて、ユーザー自身のトークンを発行を許可することにより、あなたのAPIをユーザーに経験してもらう事ができますし、全般的なアクセストークン発行するシンプルなアプローチとしても役立つでしょう。

<a name="creating-a-personal-access-client"></a>
### パーソナルアクセスクライアントの作成

アプリケーションがパーソナルアクセストークンを発行する前に、パーソナルアクセスクライアントを作成する必要があります。これを行うには、`--personal`オプションを指定して`passport:client` Artisanコマンドを実行します。すでに`passport:install`コマンドを実行している場合は、次のコマンドを実行する必要はありません。

    php artisan passport:client --personal

パーソナルアクセスクライアントを制作したら、クライアントIDと平文シークレット値をアプリケーションの`.env`ファイルに設定してください。

```bash
PASSPORT_PERSONAL_ACCESS_CLIENT_ID="client-id-value"
PASSPORT_PERSONAL_ACCESS_CLIENT_SECRET="unhashed-client-secret-value"
```

<a name="managing-personal-access-tokens"></a>
### パーソナルアクセストークンの管理

パーソナルアクセスクライアントを作成したら、`App\Models\User`モデルインスタンスで`createToken`メソッドを使用して特定のユーザーにトークンを発行できます。`createToken`メソッドは、最初の引数にトークン名、２番目の引数にオプションの[スコープ](#token-scopes)の配列を取ります。

    use App\Models\User;

    $user = User::find(1);

    // スコープ無しのトークンを作成する
    $token = $user->createToken('Token Name')->accessToken;

    // スコープ付きのトークンを作成する
    $token = $user->createToken('My Token', ['place-orders'])->accessToken;

<a name="personal-access-tokens-json-api"></a>
#### JSON API

Passportにはパーソナルアクセストークンを管理するためのJSON APIも含まれています。ユーザーにパーソナルアクセストークンを管理してもらうダッシュボードを提供するため、APIと皆さんのフロントエンドを結びつける必要があるでしょう。以降から、パーソナルアクセストークンを管理するためのAPIエンドポイントをすべて説明します。利便性を考慮し、エンドポイントへのHTTPリクエスト作成をデモンストレートするために、[Axios](https://github.com/mzabriskie/axios)を使用していきましょう。

JSON APIは`web`と`auth`ミドルウェアにより保護されています。そのため、みなさん自身のアプリケーションからのみ呼び出せます。外部ソースから呼び出すことはできません。

<a name="get-oauthscopes"></a>
#### `GET /oauth/scopes`

このルートはあなたのアプリケーションで定義した、全[スコープ](#token-scopes)を返します。このルートを使い、ユーザーがパーソナルアクセストークンに割り付けたスコープをリストできます。

    axios.get('/oauth/scopes')
        .then(response => {
            console.log(response.data);
        });

<a name="get-oauthpersonal-access-tokens"></a>
#### `GET /oauth/personal-access-tokens`

このルートは認証中のユーザーが作成したパーソナルアクセストークンをすべて返します。ユーザーがトークンの編集や取り消しを行うため、全トークンをリストするために主に使われます。

    axios.get('/oauth/personal-access-tokens')
        .then(response => {
            console.log(response.data);
        });

<a name="post-oauthpersonal-access-tokens"></a>
#### `POST /oauth/personal-access-tokens`

このルートは新しいパーソナルアクセストークンを作成します。トークンの名前(`name`)と、トークンに割り付けるスコープ(`scope`)の、２つのデータが必要です。

    const data = {
        name: 'Token Name',
        scopes: []
    };

    axios.post('/oauth/personal-access-tokens', data)
        .then(response => {
            console.log(response.data.accessToken);
        })
        .catch (response => {
            // レスポンス上のエラーのリスト
        });

<a name="delete-oauthpersonal-access-tokenstoken-id"></a>
#### `DELETE /oauth/personal-access-tokens/{token-id}`

このルートはパーソナルアクセストークンを取り消すために使用します。

    axios.delete('/oauth/personal-access-tokens/' + tokenId);

<a name="protecting-routes"></a>
## ルート保護

<a name="via-middleware"></a>
### ミドルウェアによる保護

Passportは、受信リクエストのアクセストークンを検証する[認証グラント](/docs/{{version}}/authentication#adding-custom-guards)を用意しています。`passport`ドライバを使用するように`api`ガードを設定したら、有効なアクセストークンを必要とするルートで`auth:api`ミドルウェアを指定するだけで済みます。

    Route::get('/user', function () {
        //
    })->middleware('auth:api');

<a name="multiple-authentication-guards"></a>
#### 複数認証ガード

アプリケーションの認証でたぶんまったく異なるEloquentモデルを使用する、別々のタイプのユーザーを認証する場合、それぞれのユーザープロバイダタイプごとにガード設定を定義する必用があるでしょう。これにより特定ユーザープロバイダ向けのリクエストを保護できます。例として`config/auth.php`設定ファイルで以下のようなガード設定を行っているとしましょう。

    'api' => [
        'driver' => 'passport',
        'provider' => 'users',
    ],

    'api-customers' => [
        'driver' => 'passport',
        'provider' => 'customers',
    ],

以下のルートは受信リクエストを認証するため`customers`ユーザープロバイダを使用する`api-customers`ガードを使用します。

    Route::get('/customer', function () {
        //
    })->middleware('auth:api-customers');

> {tip} Passportを使用する複数ユーザープロバイダ利用の詳細は、[パスワードグラントのドキュメント](#customizing-the-user-provider)を調べてください。

<a name="passing-the-access-token"></a>
### アクセストークンの受け渡し

Passportにより保護されているルートを呼び出す場合、あなたのアプリケーションのAPI利用者は、リクエストの`Authorization`ヘッダとして、アクセストークンを`Bearer`トークンとして指定する必要があります。Guzzle HTTPライブラリを使う場合を例として示します。

    use Illuminate\Support\Facades\Http;

    $response = Http::withHeaders([
        'Accept' => 'application/json',
        'Authorization' => 'Bearer '.$accessToken,
    ])->get('https://passport-app.com/api/user');

    return $response->json();

<a name="token-scopes"></a>
## トークンのスコープ

スコープは、あるアカウントにアクセスする許可がリクエストされたとき、あなたのAPIクライアントに限定された一連の許可をリクエストできるようにします。たとえば、eコマースアプリケーションを構築している場合、全API利用者へ発注する許可を与える必要はないでしょう。代わりに、利用者へ注文の発送状況にアクセスできる許可を与えれば十分です。言い換えれば、スコープはアプリケーションユーザーに対し、彼らの代理としてのサードパーティアプリケーションが実行できるアクションを制限できるようにします。

<a name="defining-scopes"></a>
### スコープの定義

APIのスコープは、アプリケーションの`App\Providers\AuthServiceProvider`クラスの`boot`メソッドの`Passport::tokensCan`メソッドを使用して定義できます。`tokensCan`メソッドは、スコープ名とスコープの説明の配列を引数に取ります。スコープの説明は任意で、承認画面でユーザーに表示されます。

    /**
     * 全認証／承認サービスの登録
     *
     * @return void
     */
    public function boot()
    {
        $this->registerPolicies();

        Passport::routes();

        Passport::tokensCan([
            'place-orders' => 'Place orders',
            'check-status' => 'Check order status',
        ]);
    }

<a name="default-scope"></a>
### デフォルトスコープ

クライアントが特定のスコープをリクエストしない場合は、`setDefaultScope`メソッドを使用して、デフォルトのスコープをトークンへアタッチするようにPassportサーバを設定できます。通常、このメソッドは、アプリケーションの`App\Providers\AuthServiceProvider`クラスの`boot`メソッドから呼び出す必要があります。

    use Laravel\Passport\Passport;

    Passport::tokensCan([
        'place-orders' => 'Place orders',
        'check-status' => 'Check order status',
    ]);

    Passport::setDefaultScope([
        'check-status',
        'place-orders',
    ]);

<a name="assigning-scopes-to-tokens"></a>
### トークンへのスコープ割り付け

<a name="when-requesting-authorization-codes"></a>
#### 許可コードのリクエスト時

許可コードグラントを用い、アクセストークンをリクエストする際、利用者は`scope`クエリ文字列パラメータとして、希望するスコープを指定する必要があります。`scope`パラメータはスコープを空白で区切ったリストです。

    Route::get('/redirect', function () {
        $query = http_build_query([
            'client_id' => 'client-id',
            'redirect_uri' => 'http://example.com/callback',
            'response_type' => 'code',
            'scope' => 'place-orders check-status',
        ]);

        return redirect('http://passport-app.com/oauth/authorize?'.$query);
    });

<a name="when-issuing-personal-access-tokens"></a>
#### パーソナルアクセストークン発行時

`App\Models\User`モデルの`createToken`メソッドを使用してパーソナルアクセストークンを発行している場合は、メソッドの２番目の引数に目的のスコープの配列を渡すことができます。

    $token = $user->createToken('My Token', ['place-orders'])->accessToken;

<a name="checking-scopes"></a>
### スコープのチェック

Passportには、指定されたスコープが許可されているトークンにより、送信されたリクエストが認証されているかを確認するために使用できる、2つのミドルウエアが用意されています。これを使用するには、`app/Http/Kernel.php`ファイルの`$routeMiddleware`プロパティへ、以下のミドルウェアを追加してください。

    'scopes' => \Laravel\Passport\Http\Middleware\CheckScopes::class,
    'scope' => \Laravel\Passport\Http\Middleware\CheckForAnyScope::class,

<a name="check-for-all-scopes"></a>
#### 全スコープの確認

`scopes`ミドルウェアをルートに割り当てて、受信リクエストのアクセストークンがリストするスコープをすべて持っていることを確認できます。

    Route::get('/orders', function () {
        // アクセストークンは"check-status"と"place-orders"、両スコープを持っている
    })->middleware(['auth:api', 'scopes:check-status,place-orders']);

<a name="check-for-any-scopes"></a>
#### 一部のスコープの確認

`scope`ミドルウエアは、リストしたスコープのうち、**最低１つ**を送信されてきたリクエストのアクセストークンが持っていることを確認するため、ルートへ指定します。

    Route::get('/orders', function () {
        // アクセストークンは、"check-status"か"place-orders"、どちらかのスコープを持っている
    })->middleware(['auth:api', 'scope:check-status,place-orders']);

<a name="checking-scopes-on-a-token-instance"></a>
#### トークンインスタンスでのスコープチェック

アクセストークンの認証済みリクエストがアプリケーションに入力された後でも、認証済みの`App\Models\User`インスタンスで`tokenCan`メソッドを使用して、トークンに特定のスコープがあるかどうかを確認できます。

    use Illuminate\Http\Request;

    Route::get('/orders', function (Request $request) {
        if ($request->user()->tokenCan('place-orders')) {
            //
        }
    });

<a name="additional-scope-methods"></a>
#### その他のスコープメソッド

`scopeIds`メソッドは定義済みの全ID／名前の配列を返します。

    use Laravel\Passport\Passport;

    Passport::scopeIds();

`scopes`メソッドは定義済みの全スコープを`Laravel\Passport\Scope`のインスタンスの配列として返します。

    Passport::scopes();

`scopesFor`メソッドは、指定したID／名前に一致する`Laravel\Passport\Scope`インスタンスの配列を返します。

    Passport::scopesFor(['place-orders', 'check-status']);

指定したスコープが定義済みであるかを判定するには、`hasScope`メソッドを使います。

    Passport::hasScope('place-orders');

<a name="consuming-your-api-with-javascript"></a>
## APIをJavaScriptで利用

API構築時にJavaScriptアプリケーションから、自分のAPIを利用できたらとても便利です。このAPI開発のアプローチにより、世界中で共有されるのと同一のAPIを自身のアプリケーションで使用できるようになります。自分のWebアプリケーションやモバイルアプリケーション、サードパーティアプリケーション、そしてさまざまなパッケージマネージャ上で公開するSDKにより、同じAPIが使用されます。

通常、皆さんのAPIをJavaScriptアプリケーションから使用しようとするなら、アプリケーションに対しアクセストークンを自分で送り、それを毎回リクエストするたび、一緒にアプリケーションへ渡す必要があります。しかし、Passportにはこれを皆さんに変わって処理するミドルウェアが用意してあります。必要なのは`app/Http/Kernel.php`ファイル中の、`web`ミドルウェアグループに対し、`CreateFreshApiToken`ミドルウェアを追加することだけです。

    'web' => [
        // 他のミドルウェア…
        \Laravel\Passport\Http\Middleware\CreateFreshApiToken::class,
    ],

> {note} ミドルウェアの指定の中で、`CreateFreshApiToken`ミドルウェアは確実に最後へリストしてください。

このミドルウェアは、送信レスポンスに`laravel_token`クッキーを添付します。このクッキーには、PassportがJavaScriptアプリケーションからのAPIリクエストを認証するために使用する暗号化されたJWTが含まれています。JWTの有効期間は、`session.lifetime`設定値と同じです。これで、ブラウザは後続のすべてのリクエストでクッキーを自動的に送信するため、アクセストークンを明示的に渡さなくても、アプリケーションのAPIにリクエストを送信できます。

    axios.get('/api/user')
        .then(response => {
            console.log(response.data);
        });

<a name="customizing-the-cookie-name"></a>
#### クッキー名のカスタマイズ

必要に応じて、`Passport::cookie`メソッドを使用して`laravel_token`クッキーの名前をカスタマイズできます。通常、このメソッドは、アプリケーションの`App\Providers\AuthServiceProvider`クラスの`boot`メソッドから呼び出す必要があります。

    /**
     * 全認証／認可の登録
     *
     * @return void
     */
    public function boot()
    {
        $this->registerPolicies();

        Passport::routes();

        Passport::cookie('custom_name');
    }

<a name="csrf-protection"></a>
#### CSRF保護

この認証方法を使用する場合、リクエストのヘッダに有効なCSRFトークンを確実に含める必要があります。デフォルトのLaravel JavaScriptスカフォールドはAxiosインスタンスを含み、同一オリジンリクエスト上に`X-XSRF-TOKEN`ヘッダを送るために、暗号化された`XSRF-TOKEN`クッキーを自動的に使用します。

> {tip} `X-XSRF-TOKEN`の代わりに`X-CSRF-TOKEN`ヘッダを送る方法を取る場合は、`csrf_token()`により提供される復元したトークンを使用する必要があります。

<a name="events"></a>
## イベント

Passportは、アクセストークンと更新トークンを発行するときにイベントを発行します。これらのイベントを使用して、データベース内の他のアクセストークンを整理または取り消すことができます。必要に応じて、アプリケーションの`App\Providers\EventServiceProvider`クラスでこうしたイベントへリスナを指定できます。

    /**
     * アプリケーションのイベントリスナマッピング
     *
     * @var array
     */
    protected $listen = [
        'Laravel\Passport\Events\AccessTokenCreated' => [
            'App\Listeners\RevokeOldTokens',
        ],

        'Laravel\Passport\Events\RefreshTokenCreated' => [
            'App\Listeners\PruneOldTokens',
        ],
    ];

<a name="testing"></a>
## テスト

Passportの`actingAs`メソッドは、現在認証中のユーザーを指定すると同時にスコープも指定します。`actingAs`メソッドの最初の引数はユーザーのインスタンスで、第２引数はユーザートークンに許可するスコープ配列を指定します。

    use App\Models\User;
    use Laravel\Passport\Passport;

    public function test_servers_can_be_created()
    {
        Passport::actingAs(
            User::factory()->create(),
            ['create-servers']
        );

        $response = $this->post('/api/create-server');

        $response->assertStatus(201);
    }

Passportの`actingAsClient`メソッドは、現在認証中のクライアントを指定すると同時にスコープも指定します。`actingAsClient`メソッドの最初の引数はクライアントインスタンスで、第２引数はクライアントのトークンへ許可するスコープの配列です。

    use Laravel\Passport\Client;
    use Laravel\Passport\Passport;

    public function test_orders_can_be_retrieved()
    {
        Passport::actingAsClient(
            Client::factory()->create(),
            ['check-status']
        );

        $response = $this->get('/api/orders');

        $response->assertStatus(200);
    }
