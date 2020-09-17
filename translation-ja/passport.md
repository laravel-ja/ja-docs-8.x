# Laravel Passport

- [イントロダクション](#introduction)
- [Passportのアップグレード](#upgrading)
- [インストール](#installation)
    - [フロントエンド・クイックスタート](#frontend-quickstart)
    - [Passportのデプロイ](#deploying-passport)
    - [マイグレーションのカスタマイズ](#migration-customization)
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

Laravelでは古典的なログインフォームによる認証は、簡単に実行できるようになっています。では、APIに関してはどうでしょうか？通常APIでは、ユーザーの認証にトークンを使用し、リクエスト間のセッション状態は保持されません。Laravelアプリケーションのために、完全なOAuth2サーバの実装を提供するLaravel Passportを使えば、短時間で簡単にAPI認証ができます。Passportは、Andy MillingtonとSimon Hampによりメンテナンスされている、[League OAuth2サーバ](https://github.com/thephpleague/oauth2-server)上に構築しています。

> {note} このドキュメントは、皆さんがOAuth2に慣れていることを前提にしています。OAuth2について知らなければ、この先を続けて読む前に、一般的な[用語](https://oauth2.thephpleague.com/terminology/)とOAuth2の機能について予習してください。

<a name="upgrading"></a>
## Passportのアップグレード

Passportの新しいメジャーバーションへアップグレードする場合は、注意深く[アップグレードガイド](https://github.com/laravel/passport/blob/master/UPGRADE.md)をレビューしてください。

<a name="installation"></a>
## インストール

Composerパッケージマネージャにより、Passportをインストールすることからはじめましょう。

    composer require laravel/passport

Passportサービスプロバイダはフレームワークに対し、自身のマイグレーションディレクトリを登録します。そのためにパッケージインストール後、データベースのマイグレーションを実行する必要があります。Passportのマイグレーションは、アプリケーションで必要となる、クライアントとアクセストークンを保存しておくテーブルを作成します。

    php artisan migrate

次に、`passport:install`コマンドを実行します。このコマンドは安全なアクセストークンを生成するのに必要な暗号キーを作成します。さらにアクセストークンを生成するために使用する、「パーソナルアクセス」クライアントと「パスワードグラント」クライアントも作成します。

    php artisan passport:install

> {tip} 自動増分整数の代わりに、Passportの`Client`モデルの主キー値としてUUIDを使用したい場合は、[`uuids`オプション](#client-uuids)を使いPassportをインストールしてください。

`passport:install`コマンドを実行し終えたら、`Laravel\Passport\HasApiTokens`トレイトを`App\Models\User`モデルへ追加してください。このトレイトは認証済みユーザーのトークンとスコープを調べられるように、モデルへ数個のヘルパメソッドを提供します。

    <?php

    namespace App\Models;

    use Illuminate\Foundation\Auth\User as Authenticatable;
    use Illuminate\Notifications\Notifiable;
    use Laravel\Passport\HasApiTokens;

    class User extends Authenticatable
    {
        use HasApiTokens, Notifiable;
    }

次に、`AuthServiceProvider`の`boot`メソッドから、`Passport::routes`メソッドを呼び出す必要があります。このメソッドはアクセストークンの発行、アクセストークンの失効、クライアントとパーソナルアクセストークンの管理のルートを登録します。

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

最後に、`config/auth.php`設定ファイル中で、ガードの`api`認証の`driver`オプションを`passport`へ変更します。これにより、認証のAPIリクエストが送信された時に、パスポートの`TokenGuard`を使用するように、アプリケーションへ指示します。

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

`passport:install`コマンドは`--uuids`オプションを指定して実行できます。このフラグはPassportへ`Client`モデルの主キー値として自動増分整数の代わりにUUIDを使用することを指示します。`--uuids`オプションを付けて`passport:install`コマンドを実行したら、Passportのデフォルトマイグレーションの無効化に関して追加の指示が与えられます。

    php artisan passport:install --uuids

<a name="frontend-quickstart"></a>
### フロントエンド・クイックスタート

> {note} パスポートVueコンポーネントを使用するには、[Vue](https://vuejs.org) JavaScriptフレームワークを使用する必要があります。コンポーネントはBootstrap CSSフレームワークを使用しています。皆さんがこれらのツールを使用しない場合でも、フロントエンド実装の参考として、これらのコンポーネントは役立つでしょう。

パスポートは皆さんのユーザーへ、クライアントとパーソナルアクセストークンを作成するために使用するJSON APIを初めから提供しています。しかし、こうしたAPIに関連するフロントエンドをコーディングするには時間を要します。そこで、Passportは実装例、もしくは実装の開始地点として役立ててもらうため、[Vue](https://vuejs.org)コンポーネントも用意しています。

Passport Vueコンポーネントをリソース公開するには、`vendor:publish` Artisanコマンドを使用します。

    php artisan vendor:publish --tag=passport-components

リソース公開されたコンポーネントは、`resources/js/components`ディレクトリへ設置されます。リソース公開したコンポーネントは、`resources/js/app.js`ファイルで登録してください。

    Vue.component(
        'passport-clients',
        require('./components/passport/Clients.vue').default
    );

    Vue.component(
        'passport-authorized-clients',
        require('./components/passport/AuthorizedClients.vue').default
    );

    Vue.component(
        'passport-personal-access-tokens',
        require('./components/passport/PersonalAccessTokens.vue').default
    );

> {note} バージョン5.7.19以前のLaravelでは、コンポーネントを登録する時にコンソールエラーが出る時に、`.default`を追加します。この変更については、[Laravel Mix v4.0.0リリースノート](https://github.com/JeffreyWay/laravel-mix/releases/tag/v4.0.0)で説明がなされています。

コンポーネントを登録したら、アセットを再コンパイルするため`npm run dev`を確実に実行してください。アセットの再コンパイルが済んだら、クライアントとパーソナルアクセストークンを作成し始めるために、アプリケーションのテンプレートへコンポーネントを指定しましょう。

    <passport-clients></passport-clients>
    <passport-authorized-clients></passport-authorized-clients>
    <passport-personal-access-tokens></passport-personal-access-tokens>

<a name="deploying-passport"></a>
### Passportのデプロイ

Passportを実働サーバへ最初にデプロイするとき、`passport:keys`コマンドを実行する必要があるでしょう。このコマンドは、Passportがアクセストークンを生成するために必要な、暗号化キーを生成するコマンドです。生成されたキーは、通常ソースコントロールには含めません。

    php artisan passport:keys

必要があれば、Passportのキーを読み込むパスを定義できます。`Passport::loadKeysFrom`メソッドを使用します。

    /**
     * 全認証／認可の登録
     *
     * @return void
     */
    public function boot()
    {
        $this->registerPolicies();

        Passport::routes();

        Passport::loadKeysFrom('/secret-keys/oauth');
    }

さらに、`php artisan vendor:publish --tag=passport-config`により、Passportの設定ファイルをリソース公開することもできます。これにより、環境変数から暗号化キーをロードするためのオプションを提供しています。

    PASSPORT_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
    <private key here>
    -----END RSA PRIVATE KEY-----"

    PASSPORT_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----
    <public key here>
    -----END PUBLIC KEY-----"

<a name="migration-customization"></a>
### マイグレーションのカスタマイズ

Passportのデフォルトマイグレーションを使用しない場合、`AppServiceProvider`の`register`メソッドで`Passport::ignoreMigrations`メソッドを呼び出す必用があります。`php artisan vendor:publish --tag=passport-migrations`により、デフォルトマイグレーションをエクスポートできます。

<a name="configuration"></a>
## 設定

<a name="client-secret-hashing"></a>
### クライアントシークレットハッシュ

クライアントのシークレットをデータベース保存時にハッシュ化したい場合は、`AppServiceProvider`の`boot`メソッドで`Passport::hashClientSecrets`メソッドを呼び出す必用があります。

    Passport::hashClientSecrets();

一度有効にすると、すべてのクライアントのシークレットはクライアント作成時に一度だけ表示されます。データベースには平文のクライアントシークレット値はまったく保存されないため、失われたら回復は不可能です。

<a name="token-lifetimes"></a>
### トークン持続時間

Passportはデフォルトで、一年間有効な長期間持続するアクセストークンを発行します。トークンの持続時間をもっと短くしたい場合は、`tokensExpireIn`と`refreshTokensExpireIn`、`personalAccessTokensExpireIn`メソッドを使ってください。これらのメソッドは、`AuthServiceProvider`の`boot`メソッドから呼び出してください。

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

> {note} Passportデータベーステーブルの `expires_at`カラムは読み取り専用で、表示目的のみです。トークン発行時にPassportは、署名暗号化されたトークン内へ有効期限情報を格納します。トークンを無効にする必要がある場合は、トークンを取り消す必要があります。

<a name="overriding-default-models"></a>
### デフォルトモデルのオーバーライド

Passportが内部で使用するモデルは自由に拡張できます。

    use Laravel\Passport\Client as PassportClient;

    class Client extends PassportClient
    {
        // ...
    }

それから、`Passport`クラスを通して、カスタムモデルを指示します。

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

OAuth2で認可コードを使いこなせるかは、どの程度開発者がOAuth2に慣れているかによります。認可コードを使用する時、クライアントアプリケーションはそのクライアントに対するアクセストークン発行のリクエストが許可されようと、拒絶されようと、あなたのサーバにそのユーザーをリダイレクトします。

<a name="managing-clients"></a>
### クライアント管理

あなたのアプリケーションのAPIと連携する必要のある、アプリケーションを構築しようとしている開発者たちは、最初に「クライアント」を作成することにより、彼らのアプリケーションを登録しなくてはなりません。通常、アプリケーションの名前と、許可のリクエストをユーザーが承認した後に、アプリケーションがリダイレクトされるURLにより、登録情報は構成されます。

#### `passport:client`コマンド

クライアントを作成する一番簡単な方法は、`passport:client` Artisanコマンドを使うことです。このコマンドは、OAuth2の機能をテストするため、皆さん自身のクライアントを作成する場合に使用できます。`client`コマンドを実行すると、Passportはクライアントに関する情報の入力を促し、クライアントIDとシークレットを表示します。

    php artisan passport:client

**リダイレクトURL**

クライアントに対するリダイレクトURLを複数許可したければ、`passport:client`コマンドで入力を促された時にURLをカンマで区切り指定します。

    http://example.com/callback,http://examplefoo.com/callback

> {note} カンマを含んでいるURLは、エンコードしてください。

#### JSON API

皆さんのアプリのユーザーは`client`コマンドを使用できないわけですから、Passportはクライアント作成のJSON APIを提供しています。これにより、クライアントを作成、更新、削除するコントローラをわざわざコードする手間を省略できます。

しかし、ユーザーにクライアントを管理してもらうダッシュボードを提供するために、PassportのJSON APIと皆さんのフロントエンドを結合する必要があります。以降から、クライアントを管理するためのAPIエンドポイントをすべて説明します。エンドポイントへのHTTPリクエスト作成をデモンストレートするため利便性を考慮し、[Axios](https://github.com/mzabriskie/axios)を使用していきましょう。

JSON APIは`web`と`auth`ミドルウェアにより保護されています。そのため、みなさん自身のアプリケーションからのみ呼び出せます。外部ソースから呼び出すことはできません。

> {tip} クライアント管理のフロントエンドを自分で実装したくなければ、[フロントエンド・クイックスタート](#frontend-quickstart)を使い、短時間で完全に機能するフロントエンドを用意できます。

#### `GET /oauth/clients`

このルートは認証されたユーザーの全クライアントを返します。ユーザーのクライアントの全リストは、主にクライアントを編集、削除する場合に役立ちます。

    axios.get('/oauth/clients')
        .then(response => {
            console.log(response.data);
        });

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

#### `DELETE /oauth/clients/{client-id}`

このルートはクライアントを削除するために使用します。

    axios.delete('/oauth/clients/' + clientId)
        .then(response => {
            //
        });

<a name="requesting-tokens"></a>
### トークンのリクエスト

#### 許可のリダイレクト

クライアントが作成されると、開発者はクライアントIDとシークレットを使用し、あなたのアプリケーションへ許可コードとアクセストークンをリクエストするでしょう。まず、API利用側アプリケーションは以下のように、あなたのアプリケーションの`/oauth/authorize`ルートへのリダイレクトリクエストを作成する必要があります。

    Route::get('/redirect', function (Request $request) {
        $request->session()->put('state', $state = Str::random(40));

        $query = http_build_query([
            'client_id' => 'client-id',
            'redirect_uri' => 'http://example.com/callback',
            'response_type' => 'code',
            'scope' => '',
            'state' => $state,
        ]);

        return redirect('http://your-app.com/oauth/authorize?'.$query);
    });

> {tip} `/oauth/authorize`ルートは、すでに`Passport::routes`メソッドが定義づけていることを覚えておいてください。このルートを自分で定義する必要はありません。

#### リクエストの承認

許可のリクエストを受け取ると、Passportはユーザーがその許可のリクエストを承認するか、拒絶するかのテンプレートを自動的に表示します。ユーザーが許可した場合、API利用側アプリケーションが指定した`redirect_uri`へリダイレクトします。`redirect_uri`は、クライアントを作成した時に指定した`redirect`のURLと一致する必要があります。

許可の承認ページをカスタマイズしたい場合は、`vendor:publish` Artisanコマンドを使い、Passportのビューを公開することでリソースを用意する必要があります。リソース公開されたビューは、`resources/views/vendor/passport`へ設置されます。

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

#### 許可コードからアクセストークンへの変換

ユーザーが許可リクエストを承認したら、API使用側アプリケーションへリダイレクトされます。使用側は最初に、リダイレクトする前に保存していた値と、`state`パラメータを確認する必要があります。stateパラメータが一致したら、使用側はあなたのアプリケーションへアクセストークンをリクエストするための`POST`リクエストを送信する必要があります。そのリクエストには、ユーザーが許可リクエストを承認した時にあなたのアプリケーションが発行した、許可コードを含める必要があります。この例として、Guzzle HTTPライブラリで`POST`リクエストを作成してみましょう。

    Route::get('/callback', function (Request $request) {
        $state = $request->session()->pull('state');

        throw_unless(
            strlen($state) > 0 && $state === $request->state,
            InvalidArgumentException::class
        );

        $http = new GuzzleHttp\Client;

        $response = $http->post('http://your-app.com/oauth/token', [
            'form_params' => [
                'grant_type' => 'authorization_code',
                'client_id' => 'client-id',
                'client_secret' => 'client-secret',
                'redirect_uri' => 'http://example.com/callback',
                'code' => $request->code,
            ],
        ]);

        return json_decode((string) $response->getBody(), true);
    });

この`/oauth/token`ルートは、`access_token`、`refresh_token`、`expires_in`属性を含むJSONレスポンスを返します。`expires_in`属性は、アクセストークンが無効になるまでの秒数を含んでいます。

> {tip} `/oauth/authorize`ルートと同様に、`/oauth/token`ルートは`Passport::routes`メソッドが定義しています。このルートを自分で定義する必要はありません。デフォルトでこのルートは、`ThrottleRequests`ミドルウェアの設定を利用し、アクセス回数制限されています。

#### JSON API

Passportには、承認済みアクセストークンを管理するためのJSON APIも含んでいます。これを独自のフロントエンドと組み合わせ、アクセストークンを管理するダッシュボードをユーザーへ提供できます。便宜上、[Axios](https://github.com/mzabriskie/axios)をエンドポイントへのHTTPリクエストを生成するデモンストレーションのため使用しています。JSON APIは`web`と`auth`ミドルウェアにより保護されているため、自身のアプリケーションからのみ呼び出しできます。

#### `GET /oauth/tokens`

このルートは、認証されたユーザーが作成した、承認済みアクセストークンをすべて返します。これは主に取り消すトークンを選んでもらうため、ユーザーの全トークンを一覧リスト表示するのに便利です。

    axios.get('/oauth/tokens')
        .then(response => {
            console.log(response.data);
        });

#### `DELETE /oauth/tokens/{token-id}`

このルートは、認証済みアクセストークンと関連するリフレッシュトークンを取り消すために使います。

    axios.delete('/oauth/tokens/' + tokenId);

<a name="refreshing-tokens"></a>
### トークンのリフレッシュ

アプリケーションが短い有効期限のアクセストークンを発行している場合に、ユーザーはアクセストークンを発行する時に提供しているリフレッシュトークンを使用し、アクセストークンをリフレッシュする必要が起きます。以下はGuzzle HTTPライブラリを使用し、トークンをリフレッシュする例です。

    $http = new GuzzleHttp\Client;

    $response = $http->post('http://your-app.com/oauth/token', [
        'form_params' => [
            'grant_type' => 'refresh_token',
            'refresh_token' => 'the-refresh-token',
            'client_id' => 'client-id',
            'client_secret' => 'client-secret',
            'scope' => '',
        ],
    ]);

    return json_decode((string) $response->getBody(), true);

この`/oauth/token`ルートは、`access_token`、`refresh_token`、`expires_in`属性を含むJSONレスポンスを返します。`expires_in`属性は、アクセストークンが無効になるまでの秒数を含んでいます。

<a name="revoking-tokens"></a>
### トークンの取り消し

`TokenRepository`の`revokeAccessToken`メソッドを利用し、トークンを取り消せます。トークンのリフレッシュトークンの取り消しは`RefreshTokenRepository`の`revokeRefreshTokensByAccessTokenId`メソッドを使います。

    $tokenRepository = app('Laravel\Passport\TokenRepository');
    $refreshTokenRepository = app('Laravel\Passport\RefreshTokenRepository');

    // アクセストークンの取り消し
    $tokenRepository->revokeAccessToken($tokenId);

    // そのトークンのリフレッシュトークンを全て取り消し
    $refreshTokenRepository->revokeRefreshTokensByAccessTokenId($tokenId);

<a name="purging-tokens"></a>
### トークンの破棄

トークンが無効、もしくは期限切れになったら、データベースから一掃する必要があります。Passportはこのためのコマンドを用意しています。

    # 無効・期限切れのトークンと認可コードを破棄する
    php artisan passport:purge

    # 無効なトークンと認可コードのみ破棄する
    php artisan passport:purge --revoked

    # 期限切れのトークンと認可コードのみ破棄する
    php artisan passport:purge --expired

スケジュールに従い自動的にトークンを整理するため、コンソールの`Kernel`クラスで[スケジュール済みジョブ](/docs/{{version}}/scheduling)として設定することも可能です。

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

PKCEを使用した認可コードグラントを通じトークンを発行する前に、PKCE可能なクライアントを生成する必要があります。`passport:client`コマンドを`--public`オプション付きで実行してください。

    php artisan passport:client --public

<a name="requesting-auth-pkce-grant-tokens"></a>
### トークンのリクエスト

#### コードベリファイヤとコードチャレンジ

この認可グラントではクライアント秘密コードが提供されないため、開発者はトークンを要求するためにコードベリファイヤとコードチャレンジのコンビネーションを生成する必要があります。

コードベリファイヤは[RFC 7636仕様](https://tools.ietf.org/html/rfc7636)で定義されている通り、４３から１２８文字の文字、数字、`"-"`、`"."`、`"_"`、`"~"`を含んだランダムな文字列の必要があります。

コードチャレンジはURL／ファイルネームセーフな文字をBase64エンコードしたものである必要があります。文字列終端の`'='`文字を削除し、ラインブレイクやホワイトスペースを含まず、その他はそのままにします。

    $encoded = base64_encode(hash('sha256', $code_verifier, true));

    $codeChallenge = strtr(rtrim($encoded, '='), '+/', '-_');

#### 許可のリダイレクト

クライアントが生成できたら、アプリケーションから認可コードとアクセストークンをリクエストするために、クライアントIDと生成したコードベリファイヤ、コードチャレンジを使用します。最初に、認可要求側のアプリケーションは、あなたのアプリケーションの`/oauth/authorize`ルートへのリダイレクトリクエストを生成する必要があります。

    Route::get('/redirect', function (Request $request) {
        $request->session()->put('state', $state = Str::random(40));

        $request->session()->put('code_verifier', $code_verifier = Str::random(128));

        $codeChallenge = strtr(rtrim(
            base64_encode(hash('sha256', $code_verifier, true))
        , '='), '+/', '-_');

        $query = http_build_query([
            'client_id' => 'client-id',
            'redirect_uri' => 'http://example.com/callback',
            'response_type' => 'code',
            'scope' => '',
            'state' => $state,
            'code_challenge' => $codeChallenge,
            'code_challenge_method' => 'S256',
        ]);

        return redirect('http://your-app.com/oauth/authorize?'.$query);
    });

#### 許可コードからアクセストークンへの変換

ユーザーが認可リクエストを承認すると、認可要求側のアプリケーションへリダイレクで戻されます。認可要求側では認可コードグラントの規約に従い、リダイレクトの前に保存しておいた値と、`state`パラメータを検証する必要があります。

stateパラメータが一致したら、要求側はアクセストークンをリクエストするために、あなたのアプリケーションへ`POST`リクエストを発行する必要があります。そのリクエストは最初に生成したコードベリファイヤと同時に、ユーザーが認可リクエストを承認したときにあなたのアプリケーションが発行した認可コードを持っている必要があります。

    Route::get('/callback', function (Request $request) {
        $state = $request->session()->pull('state');

        $codeVerifier = $request->session()->pull('code_verifier');

        throw_unless(
            strlen($state) > 0 && $state === $request->state,
            InvalidArgumentException::class
        );

        $response = (new GuzzleHttp\Client)->post('http://your-app.com/oauth/token', [
            'form_params' => [
                'grant_type' => 'authorization_code',
                'client_id' => 'client-id',
                'redirect_uri' => 'http://example.com/callback',
                'code_verifier' => $codeVerifier,
                'code' => $request->code,
            ],
        ]);

        return json_decode((string) $response->getBody(), true);
    });

<a name="password-grant-tokens"></a>
## パスワードグラントのトークン

OAuth2のパスワードグラントはモバイルアプリケーションのような、その他のファーストパーティクライアントへ、メールアドレス／ユーザー名とパスワードを使ったアクセストークンの取得を提供します。これによりOAuth2のAuthorization Codeリダイレクトフローに完全に従うことをユーザーへ要求せずとも、アクセストークンを安全に発行できます。

<a name="creating-a-password-grant-client"></a>
### パスワードグラントクライアントの作成

パスワードグラントにより、あなたのアプリケーションがトークンを発行する前に、パスワードグラントクライアントを作成する必要があります。それには、`passport:client`コマンドで`--password`を使用してください。すでに`passport:install`コマンドを実行済みの場合、このコマンドを実行する必要はありません。

    php artisan passport:client --password

<a name="requesting-password-grant-tokens"></a>
### トークンのリクエスト

パスワードグラントクライアントを作成したら、ユーザーのメールアドレスとパスワードを指定し、`/oauth/token`ルートへ`POST`リクエストを発行することで、アクセストークンをリクエストできます。このルートは、`Passport::routes`メソッドが登録しているため、自分で定義する必要がないことを覚えておきましょう。リクエストに成功すると、サーバから`access_token`と`refresh_token`のJSONレスポンスを受け取ります。

    $http = new GuzzleHttp\Client;

    $response = $http->post('http://your-app.com/oauth/token', [
        'form_params' => [
            'grant_type' => 'password',
            'client_id' => 'client-id',
            'client_secret' => 'client-secret',
            'username' => 'taylor@laravel.com',
            'password' => 'my-password',
            'scope' => '',
        ],
    ]);

    return json_decode((string) $response->getBody(), true);

> {tip} アクセストークンはデフォルトで、長期間有効であることを記憶しておきましょう。ただし、必要であれば自由に、[アクセストークンの最長持続時間を設定](#configuration)できます。

<a name="requesting-all-scopes"></a>
### 全スコープの要求

パスワードグラント、またはクライアント認証情報グラントを使用時は、あなたのアプリケーションでサポートする全スコープを許可するトークンを発行したいと考えるかと思います。`*`スコープをリクエストすれば可能です。`*`スコープをリクエストすると、そのトークンインスタンスの`can`メソッドは、いつも`true`を返します。このスコープは`password`か`client_credentials`グラントを使って発行されたトークのみに割り付けるのが良いでしょう。

    $response = $http->post('http://your-app.com/oauth/token', [
        'form_params' => [
            'grant_type' => 'password',
            'client_id' => 'client-id',
            'client_secret' => 'client-secret',
            'username' => 'taylor@laravel.com',
            'password' => 'my-password',
            'scope' => '*',
        ],
    ]);

<a name="customizing-the-user-provider"></a>
### ユーザープロバイダのカスタマイズ

アプリケーションが[認証ユーザープロバイダ](/docs/{{version}}/authentication#introduction)を複数使用している場合、`artisan passport:client --password`コマンドによりクライアントを制作する時に、`--provider`オプションによりパスワードグランツクライアントで使用するユーザープロバイダを指定します。指定プロバイダ名は`config/auth.php`設定ファイルで定義した有効なプロバイダと一致している必用があります。次に、[ミドルウェアを使用してルートを保護]（＃via-middleware）して、ガードの指定したプロバイダのユーザーのみ認証するようにします。

<a name="customizing-the-username-field"></a>
### ユーザー名フィールドのカスタマイズ

パスワードグラントを使用する認証を行う場合、Passportはモデルの`email`属性をユーザー名（"username"）として利用します。しかし、モデルの`findForPassport`メソッドを定義することで、この振る舞いをカスタマイズできます。

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

暗黙のグラントは認可コードのグラントと似ています。違いは認可コードの交換をせずにクライアントへトークンが返されることです。一般的にこのグラントは、JavaScriptやモバイルアプリケーションでクライアントの認証情報を安全に保存できない場合に使用します。このグラントを有効にするには、`AuthServiceProvider`で`enableImplicitGrant`メソッドを呼び出します。

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

グラントを有効にしたら、開発者はあなたのアプリケーションからのアクセストークンをリクエストするために、クライアントIDを使うことになるでしょう。使用側アプリケーションは、あなたのアプリケーションの`/oauth/authorize`ルートへのリダイレクトリクエストを生成する必要があります。例を確認してください。

    Route::get('/redirect', function (Request $request) {
        $request->session()->put('state', $state = Str::random(40));

        $query = http_build_query([
            'client_id' => 'client-id',
            'redirect_uri' => 'http://example.com/callback',
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

クライアント認証情報グラントによりトークンを発行する前に、クライアント認証情報グラントクライアントを生成する必要があります。`passport:client`コマンドで、`--client`オプションを使用してください。

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

スコープを指定しアクセスを制限するには、ルートへ`client`ミドルウェアを指定する時に、カンマ区切りで指定します。

    Route::get('/orders', function (Request $request) {
        ...
    })->middleware('client:check-status,your-scope');

### トークンの取得

このグラントタイプを使うトークンを取得するため、`oauth/token`エンドポイントへリクエストを送ります。

    $guzzle = new GuzzleHttp\Client;

    $response = $guzzle->post('http://your-app.com/oauth/token', [
        'form_params' => [
            'grant_type' => 'client_credentials',
            'client_id' => 'client-id',
            'client_secret' => 'client-secret',
            'scope' => 'your-scope',
        ],
    ]);

    return json_decode((string) $response->getBody(), true)['access_token'];

<a name="personal-access-tokens"></a>
## パーソナルアクセストークン

ときどき、あなたのユーザーが典型的なコードリダイレクションフローに従うのではなく、自分たち自身でアクセストークンを発行したがることもあるでしょう。あなたのアプリケーションのUIを通じて、ユーザー自身のトークンを発行を許可することにより、あなたのAPIをユーザーに経験してもらう事ができますし、全般的なアクセストークン発行するシンプルなアプローチとしても役立つでしょう。

<a name="creating-a-personal-access-client"></a>
### パーソナルアクセスクライアントの作成

あなたのアプリケーションでパーソナルアクセストークンを発行する前に、パーソナルアクセスクライアントを作成する必要があります。`--personal`オプションを付け、`passport:client`コマンドを実行すれば、作成できます。`passport:install`コマンドを実行済みの場合、このコマンドを実行する必要はありません。

    php artisan passport:client --personal

パーソナルアクセスクライアントを制作したら、クライアントIDと平文シークレット値をアプリケーションの`.env`ファイルに設定してください。

    PASSPORT_PERSONAL_ACCESS_CLIENT_ID=client-id-value
    PASSPORT_PERSONAL_ACCESS_CLIENT_SECRET=unhashed-client-secret-value

<a name="managing-personal-access-tokens"></a>
### パーソナルアクセストークンの管理

パーソナルアクセスクライアントを作成したら、`User`モデルインスタンスの`createToken`メソッドを使用し、指定ユーザーに対しトークンを発行することができるようになります。`createToken`メソッドは最初の引数として、トークンの名前を受け付けます。任意の第２引数として、[スコープ](#token-scopes)の配列を指定できます。

    $user = App\Models\User::find(1);

    // スコープ無しのトークンを作成する
    $token = $user->createToken('Token Name')->accessToken;

    // スコープ付きのトークンを作成する
    $token = $user->createToken('My Token', ['place-orders'])->accessToken;

#### JSON API

Passportにはパーソナルアクセストークンを管理するためのJSON APIも含まれています。ユーザーにパーソナルアクセストークンを管理してもらうダッシュボードを提供するため、APIと皆さんのフロントエンドを結びつける必要があるでしょう。以降から、パーソナルアクセストークンを管理するためのAPIエンドポイントをすべて説明します。利便性を考慮し、エンドポイントへのHTTPリクエスト作成をデモンストレートするために、[Axios](https://github.com/mzabriskie/axios)を使用していきましょう。

JSON APIは`web`と`auth`ミドルウェアにより保護されています。そのため、みなさん自身のアプリケーションからのみ呼び出せます。外部ソースから呼び出すことはできません。

> {tip} パーソナルアクセストークンのフロントエンドを自分自身で実装したくない場合は、[フロントエンドクイックスタート](#frontend-quickstart)を使用して、短時間に完全な機能を持つフロントエンドを用意できます。

#### `GET /oauth/scopes`

このルートはあなたのアプリケーションで定義した、全[スコープ](#token-scopes)を返します。このルートを使い、ユーザーがパーソナルアクセストークンに割り付けたスコープをリストできます。

    axios.get('/oauth/scopes')
        .then(response => {
            console.log(response.data);
        });

#### `GET /oauth/personal-access-tokens`

このルートは認証中のユーザーが作成したパーソナルアクセストークンをすべて返します。ユーザーがトークンの編集や取り消しを行うため、全トークンをリストするために主に使われます。

    axios.get('/oauth/personal-access-tokens')
        .then(response => {
            console.log(response.data);
        });

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

#### `DELETE /oauth/personal-access-tokens/{token-id}`

このルートはパーソナルアクセストークンを取り消すために使用します。

    axios.delete('/oauth/personal-access-tokens/' + tokenId);

<a name="protecting-routes"></a>
## ルート保護

<a name="via-middleware"></a>
### ミドルウェアによる保護

Passportは送信されてきたリクエスト上のアクセストークンをバリデートする、[認証ガード](/docs/{{version}}/authentication#adding-custom-guards)を用意しています。`passport`ドライバを`api`ガードで使うように設定すれば、あとはアクセストークンをバリデートしたいルートに、`auth:api`ミドルウェアを指定するだけです。

    Route::get('/user', function () {
        //
    })->middleware('auth:api');

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

    $response = $client->request('GET', '/api/user', [
        'headers' => [
            'Accept' => 'application/json',
            'Authorization' => 'Bearer '.$accessToken,
        ],
    ]);

<a name="token-scopes"></a>
## トークンのスコープ

スコープは、あるアカウントにアクセスする許可がリクエストされたとき、あなたのAPIクライアントに限定された一連の許可をリクエストできるようにします。たとえば、eコマースアプリケーションを構築している場合、全API利用者へ発注する許可を与える必要はないでしょう。代わりに、利用者へ注文の発送状況にアクセスできる許可を与えれば十分です。言い換えれば、スコープはアプリケーションユーザーに対し、彼らの代理としてのサードパーティアプリケーションが実行できるアクションを制限できるようにします。

<a name="defining-scopes"></a>
### スコープの定義

`AuthServiceProvider`の`boot`メソッドの中で、`Passport::tokensCan`メソッドを用い、皆さんのAPIのスコープを定義できます。`tokenCan`メソッドはスコープ名とスコープの説明の配列を引数に取ります。スコープの説明はお望み通りに記述でき、許可の承認ページでユーザーに表示されます。

    use Laravel\Passport\Passport;

    Passport::tokensCan([
        'place-orders' => 'Place orders',
        'check-status' => 'Check order status',
    ]);

<a name="default-scope"></a>
### デフォルトスコープ

クライアントが特定のスコープを要求しない場合は、`setDefaultScope`メソッドを使用しそのトークンにデフォルトスコープを付加するように、Passportサーバを設定できます。通常、このメソッドは`AuthServiceProvider`の`boot`メソッドで呼び出す必要があります。

    use Laravel\Passport\Passport;

    Passport::setDefaultScope([
        'check-status',
        'place-orders',
    ]);

<a name="assigning-scopes-to-tokens"></a>
### トークンへのスコープ割り付け

#### 許可コードのリクエスト時

許可コードグラントを用い、アクセストークンをリクエストする際、利用者は`scope`クエリ文字列パラメータとして、希望するスコープを指定する必要があります。`scope`パラメータはスコープを空白で区切ったリストです。

    Route::get('/redirect', function () {
        $query = http_build_query([
            'client_id' => 'client-id',
            'redirect_uri' => 'http://example.com/callback',
            'response_type' => 'code',
            'scope' => 'place-orders check-status',
        ]);

        return redirect('http://your-app.com/oauth/authorize?'.$query);
    });

#### パーソナルアクセストークン発行時

`User`モデルの`createToken`メソッドを使用し、パーソナルアクセストークンを発行する場合、メソッドの第２引数として希望するスコープを配列で渡します。

    $token = $user->createToken('My Token', ['place-orders'])->accessToken;

<a name="checking-scopes"></a>
### スコープのチェック

Passportには、指定されたスコープが許可されているトークンにより、送信されたリクエストが認証されているかを確認するために使用できる、2つのミドルウエアが用意されています。これを使用するには、`app/Http/Kernel.php`ファイルの`$routeMiddleware`プロパティへ、以下のミドルウェアを追加してください。

    'scopes' => \Laravel\Passport\Http\Middleware\CheckScopes::class,
    'scope' => \Laravel\Passport\Http\Middleware\CheckForAnyScope::class,

#### 全スコープの確認

`scopes`ミドルウェアは、リストしたスコープが**すべて**、送信されてきたリクエストのアクセストークンに含まれていることを確認するため、ルートへ指定します。

    Route::get('/orders', function () {
        // アクセストークンは"check-status"と"place-orders"、両スコープを持っている
    })->middleware(['auth:api', 'scopes:check-status,place-orders']);

#### 一部のスコープの確認

`scope`ミドルウエアは、リストしたスコープのうち、**最低1つ**が送信されてきたリクエストのアクセストークンに含まれていることを確認するため、ルートへ指定します。

    Route::get('/orders', function () {
        // アクセストークンは、"check-status"か"place-orders"、どちらかのスコープを持っている
    })->middleware(['auth:api', 'scope:check-status,place-orders']);

#### トークンインスタンスでのスコープチェック

アクセストークンを確認されたリクエストがアプリケーションにやってきた後でも、認証済みの`User`インスタンスへ`tokenCan`メソッドを使用し、トークンが指定したスコープを持っているかを確認できます。

    use Illuminate\Http\Request;

    Route::get('/orders', function (Request $request) {
        if ($request->user()->tokenCan('place-orders')) {
            //
        }
    });

#### その他のスコープメソッド

`scopeIds`メソッドは定義済みの全ID／名前の配列を返します。

    Laravel\Passport\Passport::scopeIds();

`scopes`メソッドは定義済みの全スコープを`Laravel\Passport\Scope`のインスタンスの配列として返します。

    Laravel\Passport\Passport::scopes();

`scopesFor`メソッドは、指定したID／名前に一致する`Laravel\Passport\Scope`インスタンスの配列を返します。

    Laravel\Passport\Passport::scopesFor(['place-orders', 'check-status']);

指定したスコープが定義済みであるかを判定するには、`hasScope`メソッドを使います。

    Laravel\Passport\Passport::hasScope('place-orders');

<a name="consuming-your-api-with-javascript"></a>
## APIをJavaScriptで利用

API構築時にJavaScriptアプリケーションから、自分のAPIを利用できたらとても便利です。このAPI開発のアプローチにより、世界中で共有されるのと同一のAPIを自身のアプリケーションで使用できるようになります。自分のWebアプリケーションやモバイルアプリケーション、サードパーティアプリケーション、そしてさまざまなパッケージマネージャ上で公開するSDKにより、同じAPIが使用されます。

通常、皆さんのAPIをJavaScriptアプリケーションから使用しようとするなら、アプリケーションに対しアクセストークンを自分で送り、それを毎回リクエストするたび、一緒にアプリケーションへ渡す必要があります。しかし、Passportにはこれを皆さんに変わって処理するミドルウェアが用意してあります。必要なのは`app/Http/Kernel.php`ファイル中の、`web`ミドルウェアグループに対し、`CreateFreshApiToken`ミドルウェアを追加することだけです。

    'web' => [
        // 他のミドルウェア…
        \Laravel\Passport\Http\Middleware\CreateFreshApiToken::class,
    ],

> {note} ミドルウェアの指定の中で、`CreateFreshApiToken`ミドルウェアを確実に最後へリストしてください。

このPassportミドルウェアは`laravel_token`クッキーを送信するレスポンスへ付加します。このクッキーはPassportが、皆さんのJavaScriptアプリケーションからのAPIリクエストを認可するために使用する、暗号化されたJWTを含んでいます。JWTは`session.lifetime`設定値と同じ有効期間です。これで、アクセストークンを明示的に渡さなくても、あなたのアプリケーションのAPIへリクエストを作成できるようになります。

    axios.get('/api/user')
        .then(response => {
            console.log(response.data);
        });

#### クッキー名のカスタマイズ

必要であれば、`Passport::cookie`メソッドを使用し、`laravel_token`クッキーの名前をカスタマイズできます。通常、このメソッドは`AuthServiceProvider`の`boot`メソッドから呼び出します。

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

#### CSRF保護

この認証方法を使用する場合、リクエストのヘッダに有効なCSRFトークンを確実に含める必要があります。デフォルトのLaravel JavaScriptスカフォールドはAxiosインスタンスを含み、同一オリジンリクエスト上に`X-XSRF-TOKEN`ヘッダを送るために、暗号化された`XSRF-TOKEN`クッキーを自動的に使用します。

> {tip} `X-XSRF-TOKEN`の代わりに`X-CSRF-TOKEN`ヘッダを送る方法を取る場合は、`csrf_token()`により提供される復元したトークンを使用する必要があります。

<a name="events"></a>
## イベント

Passportはアクセストークン発行時とトークンリフレッシュ時にイベントを発行します。これらのイベントをデータベース状の他のアクセストークンを破棄したり、無効にしたりするために使用できます。アプリケーションの`EventServiceProvider`で、これらのイベントをリッスンできます。

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

    public function testServerCreation()
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

    public function testGetOrders()
    {
        Passport::actingAsClient(
            Client::factory()->create(),
            ['check-status']
        );

        $response = $this->get('/api/orders');

        $response->assertStatus(200);
    }
