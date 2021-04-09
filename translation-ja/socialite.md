# Laravel Socialite

- [イントロダクション](#introduction)
- [インストール](#installation)
- [Socialiteのアップグレード](#upgrading-socialite)
- [設定](#configuration)
- [認証](#authentication)
    - [ルート](#routing)
    - [オプションのパラメータ](#optional-parameters)
    - [アクセススコープ](#access-scopes)
- [ユーザー詳細情報の取得](#retrieving-user-details)

<a name="introduction"></a>
## イントロダクション

Laravelは、一般的なフォームベースの認証に加えて、[Laravel Socialite](https://github.com/laravel/socialite)(ソーシャライト：名士)を使用したOAuthプロバイダで認証するためのシンプルで便利な方法も提供します。Socialiteは現在、Facebook、Twitter、LinkedIn、Google、GitHub、GitLab、Bitbucketでの認証をサポートしています。

> {tip} 他のプラットフォームのアダプタは、コミュニティにより管理されている[Socialiteプロバイダ](https://socialiteproviders.com/)Webサイトで一覧できます。

<a name="installation"></a>
## インストール

Socialiteを使い始めるには、Composerパッケージマネージャーを使用して、プロジェクトの依存関係へパッケージを追加します。

    composer require laravel/socialite

<a name="upgrading-socialite"></a>
## Socialiteのアップグレード

Socialiteの新しいメジャーバージョンにアップグレードするときは、[アップグレードガイド](https://github.com/laravel/socialite/blob/master/UPGRADE.md)を注意深く確認することが重要です。

<a name="configuration"></a>
## 設定

Socialiteを使用する前に、アプリケーションが使用するOAuthプロバイダの資格情報を追加する必要があります。これらの認証情報は、アプリケーションの`config/services.php`設定ファイルへ配置しておく必要があり、アプリケーションに必要なプロバイダに応じキーとして`facebook`、`twitter`、`linkedin`、`google`、`github`、`gitlab`、`bitbucket`を使用する必要があります。

    'github' => [
        'client_id' => env('GITHUB_CLIENT_ID'),
        'client_secret' => env('GITHUB_CLIENT_SECRET'),
        'redirect' => 'http://example.com/callback-url',
    ],

> {tip} `redirect`オプションが相対パスである場合、自動的に完全なURLへ解決されます。

<a name="authentication"></a>
## 認証

<a name="routing"></a>
### ルート

OAuthプロバイダを使用してユーザーを認証するには、２つのルートが必要です。１つはユーザーをOAuthプロバイダにリダイレクトするためのもので、もう１つは認証後にプロバイダからのコールバックを受信するためのものです。以下のコントローラの例は、両方のルートの実装を示しています。

    use Laravel\Socialite\Facades\Socialite;

    Route::get('/auth/redirect', function () {
        return Socialite::driver('github')->redirect();
    });

    Route::get('/auth/callback', function () {
        $user = Socialite::driver('github')->user();

        // $user->token
    });

`Socialite`ファサードが提供する`redirect`メソッドは、ユーザーをOAuthプロバイダへリダイレクトしますが、`user`メソッドは、受信したリクエストを読み取り、認証後にプロバイダからユーザーの情報を取得します。

<a name="optional-parameters"></a>
### オプションのパラメータ

多くのOAuthプロバイダがリダイレクトリクエスト中のオプションパラメータをサポートしています。リクエストにオプションパラメータを含めるには、`with`メソッドを呼び出し、連想配列を渡します。

    use Laravel\Socialite\Facades\Socialite;

    return Socialite::driver('google')
        ->with(['hd' => 'example.com'])
        ->redirect();

> {note} `with`メソッドを使用時は、`state`や`response_type`などの予約キーワードを渡さないように注意してください。

<a name="access-scopes"></a>
### アクセススコープ

ユーザーをリダイレクトする前に、`scopes`メソッドを使用して認証リクエストに「スコープ」を追加することもできます。このメソッドは、既存のすべてのスコープを指定したスコープとマージします。

    use Laravel\Socialite\Facades\Socialite;

    return Socialite::driver('github')
        ->scopes(['read:user', 'public_repo'])
        ->redirect();

`setScopes`メソッドを使用して、認証リクエストの既存のスコープをすべて上書きできます。

    return Socialite::driver('github')
        ->setScopes(['read:user', 'public_repo'])
        ->redirect();

<a name="retrieving-user-details"></a>
## ユーザー詳細情報の取得

ユーザーを認証コールバックルートへリダイレクトした後、Socialiteの`user`メソッドを使用してユーザーの詳細を取得できます。`user`メソッドが返すユーザーオブジェクトは、ユーザーに関する情報を独自のデータベースに保存するために使用できるさまざまなプロパティとメソッドを提供します。認証するOAuthプロバイダがOAuth1.0またはOAuth2.0のどちらをサポートしているかに応じて、さまざまなプロパティとメソッドが使用できます。

    Route::get('/auth/callback', function () {
        $user = Socialite::driver('github')->user();

        // OAuth2.0プロバイダ
        $token = $user->token;
        $refreshToken = $user->refreshToken;
        $expiresIn = $user->expiresIn;

        // OAuth1.0プロバイダ
        $token = $user->token;
        $tokenSecret = $user->tokenSecret;

        // 両プロバイダ
        $user->getId();
        $user->getNickname();
        $user->getName();
        $user->getEmail();
        $user->getAvatar();
    });

<a name="retrieving-user-details-from-a-token-oauth2"></a>
#### トークンからのユーザー詳細情報の取得(OAuth2)

ユーザーの有効なアクセストークンを既に持っている場合は、Socialiteの`userFromToken`メソッドを使用してユーザーの詳細を取得できます。

    use Laravel\Socialite\Facades\Socialite;

    $user = Socialite::driver('github')->userFromToken($token);

<a name="retrieving-user-details-from-a-token-and-secret-oauth1"></a>
#### トークンとSecretからのユーザー詳細情報の取得(OAuth1)

ユーザーの有効なトークンとシークレットが既にある場合は、Socialiteの`userFromTokenAndSecret`メソッドを使用してユーザーの詳細を取得できます。

    use Laravel\Socialite\Facades\Socialite;

    $user = Socialite::driver('twitter')->userFromTokenAndSecret($token, $secret);

<a name="stateless-authentication"></a>
#### ステートレス認証

`stateless`メソッドを使用して、セッション状態の検証を無効にすることができます。これは、APIにソーシャル認証を追加するときに役立ちます。

    use Laravel\Socialite\Facades\Socialite;

    return Socialite::driver('google')->stateless()->user();

> {note} ステートレス認証は、認証にOAuth1.0を使用するTwitterドライバでは使用できません。
