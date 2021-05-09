# Laravel Fortify

- [イントロダクション](#introduction)
    - [Fortifyとは？](#what-is-fortify)
    - [いつFortifyを使用すべきか？](#when-should-i-use-fortify)
- [インストール](#installation)
    - [Fortifyサービスプロバイダ](#the-fortify-service-provider)
    - [Fortifyの機能](#fortify-features)
    - [ビューの無効化](#disabling-views)
- [ユーザー認証](#authentication)
    - [ユーザー認証のカスタマイズ](#customizing-user-authentication)
- [２要素認証](#two-factor-authentication)
    - [２要素認証の有効化](#enabling-two-factor-authentication)
    - [２要素認証による認証](#authenticating-with-two-factor-authentication)
    - [２要素認証の無効化](#disabling-two-factor-authentication)
- [ユーザー登録](#registration)
    - [ユーザー登録のカスタマイズ](#customizing-registration)
- [パスワードリセット](#password-reset)
    - [パスワードリセットリンクのリクエスト](#requesting-a-password-reset-link)
    - [パスワードのリセット](#resetting-the-password)
    - [パスワードリセットのカスタマイズ](#customizing-password-resets)
- [メールの確認](#email-verification)
    - [ルートの保護](#protecting-routes)
- [パスワードの確認](#password-confirmation)

<a name="introduction"></a>
## イントロダクション

Laravel Fortifyは、Laravelのフロントエンドにとらわれない認証バックエンドの実装です。Fortifyは、ログイン、ユーザー登録、パスワードのリセット、メールの検証など、Laravelの認証機能をすべて実装するために必要なルートとコントローラを登録します。Fortifyをインストールした後に、`route:list` Artisanコマンドを実行して、Fortifyが登録したルートを確認できます。

Fortifyは独自のユーザーインターフェイスを提供しません。つまり、登録したルートにリクエストを送信する皆さん自身の​​のユーザーインターフェイスと組み合わせることを目的としています。このドキュメントの残りの部分で、こうしたルートにリクエストを送信する方法について正確に説明します。

> {tip} Fortifyは、Laravelの認証機能の実装をすぐに開始できるようにすることを目的としたパッケージであることを忘れないでください。**必ずしも使用する必要はありません。** [認証](/docs/{{version}}/authentication)、[パスワードリセット](/docs/{{version}}/passwords)、[メール確認](/docs/{{version}}/verification)にあるドキュメントに従って、Laravelの認証サービスをいつでも自分で操作できます。

<a name="what-is-fortify"></a>
### Fortifyとは？

前述のように、Laravel FortifyはLaravelのフロントエンドに依存しない認証バックエンドの実装です。Fortifyは、ログイン、ユーザー登録、パスワードのリセット、メールの検証など、Laravelのすべての認証機能を実装するために必要なルートとコントローラを登録します。

**Laravelの認証機能を使用するために、Fortifyを使う必要はありません。** [認証](/docs/{{version}}/authentication)、[パスワードリセット](/docs/{{version}}/passwords)、および[メール検証](/docs/{{version}}/verification)のドキュメントにしたがい、Laravelの認証サービスをいつでも自前で操作できます。

Laravelを初めて使用する場合は、Laravel Fortifyを使用する前に、[Laravel Breeze](/docs/{{version}}/starter-kits)アプリケーションスターターキットを調べることをお勧めします。Laravel Breezeは、[Tailwind CSS](https://tailwindcss.com)で構築されたユーザーインターフェイスを含む、アプリケーションの認証スカフォールドを提供します。Fortifyとは異なり、Breezeはルートとコントローラをアプリケーションに直接リソース公開します。これにより、Laravel Fortifyによりこれらの機能を実装させる前に、Laravelの認証機能を学習して慣れることができます。

基本的にLaravel Fortifyは、Laravel Breezeのルートとコントローラを持っており、ユーザーインターフェイスを含まないパッケージとして提供しています。これにより特定のフロントエンドに関する意見に縛られることなく、アプリケーションの認証レイヤーのバックエンド実装をすばやくスキャフォールディングできます。

<a name="when-should-i-use-fortify"></a>
### いつFortifyを使用すべきか？

LaravelFortifyをいつ使用するのが適切か疑問に思われるかもしれません。まず、Laravelの[アプリケーションスターターキット](/docs/{{version}}/starter-kits)で説明されているいずれかを使用している場合、Laravelのすべてのアプリケーションスターターキットはあらかじめ完全な認証実装を提供しているため、LaravelFortifyをインストールする必要はありません。 。

アプリケーションスターターキットを使用しておらず、アプリケーションに認証機能が必要な場合は、アプリケーションの認証機能を自分で実装するか、Laravel Fortifyを使用してこうした機能のバックエンド実装を提供するか、２つのオプションがあります。

Fortifyのインストールを選択した場合、ユーザーインターフェイスは、ユーザーを認証および登録するために、このドキュメントで詳しく説明されているFortifyの認証ルートにリクエストを送ります。

Fortifyを使用する代わりにLaravelの認証サービスを自前で操作することを選択した場合は、[認証](/docs/{{version}}/authentication)、[パスワードリセット](/docs/{{version}}/passwords)、[メール検証](/docs/{{version}}/verification)のドキュメントにしたがってください。

<a name="laravel-fortify-and-laravel-sanctum"></a>
#### Laravel FortifyとLaravel Sanctum

一部の開発者は、[Laravel Sanctum](/docs/{{version}}/sanctum)とLaravel Fortifyの違いについて混乱します。 ２つのパッケージは２つの関連はあるが別々の問題を解決するため、Laravel FortifyとLaravel Sanctumは相互に排他的、もしくは競合するパッケージではありません。

Laravel Sanctumは、APIトークンの管理と、セッションCookieまたはトークンを使用した既存のユーザーの認証のみに関係しています。 Sanctumは、ユーザー登録、パスワードのリセットなどを処理するルートを提供していません。

APIを提供するアプリケーション、またはシングルページアプリケーションのバックエンドとして機能するアプリケーションの認証レイヤーを自前で構築しようとしている場合は、Laravel Fortify（ユーザー登録、パスワードのリセットなど）およびLaravel Sanctum（APIトークン管理、セッション認証）の両方を利用すのは完全に可能です。

<a name="installation"></a>
## インストール

使用開始するには、Composerパッケージマネージャーを使用してFortifyをインストールします。

```nothing
composer require laravel/fortify
```

次に、`vendor:publish`コマンドを使用してFortifyのリソースを公開します。

```bash
php artisan vendor:publish --provider="Laravel\Fortify\FortifyServiceProvider"
```

このコマンドは、Fortifyのアクションを`app/Actions`ディレクトリにリソース公開します。ディレクトリが存在しない場合は作成します。さらに、Fortifyの構成ファイルとマイグレーションもリソース公開されます。

次に、データベースをマイグレートする必要があります。

```bash
php artisan migrate
```

<a name="the-fortify-service-provider"></a>
### Fortifyサービスプロバイダ

上で説明した`vendor:publish`コマンドは、`App\Providers\FortifyServiceProvider`クラスもリソース公開します。このクラスが、アプリケーションの`config/app.php`構成ファイルの`providers`配列内に登録されていることを確認する必要があります。

Fortifyサービスプロバイダは、Fortifyが公開したアクションを登録し、それぞれのタスクがFortifyによって実行されるときに各アクションを使用するようにFortifyに指示しています。

<a name="fortify-features"></a>
### Fortifyの機能

`fortify`設定ファイルには、`features`設定配列が含まれています。この配列は、Fortifyがデフォルトで公開するバックエンドルート/機能を定義しています。Fortifyを[Laravel Jetstream](https://jetstream.laravel.com)（[和文](https://readouble.com/jetstream/1.0/ja/introduction.html)）と組み合わせて使用​​していない場合は、ほとんどのLaravelアプリケーションで提供するであろう基本認証機能である以下の機能のみ有効にすることを推奨します。

```php
'features' => [
    Features::registration(),
    Features::resetPasswords(),
    Features::emailVerification(),
],
```

<a name="disabling-views"></a>
### ビューの無効化

デフォルトでは、Fortifyはログイン画面や登録画面など、ビューを返すことを目的としたルートを定義します。ただし、JavaScript駆動のシングルページアプリケーションを構築している場合は、こうしたルートは必要ない場合があります。そのため、アプリケーションの`config/fortify.php`設定ファイル内の`views`設定値を`false`にセットすれば、こうしたルートを完全に無効にできます。

```php
'views' => false,
```

<a name="disabling-views-and-password-reset"></a>
#### ビューの無効化とパスワードリセット

Fortifyのビューを無効にし、アプリケーションでパスワードリセット機能を実装する場合でも、アプリケーションの「パスワードのリセット」ビューの表示を担当する`password.reset`という名前のルートを定義する必要があります。Laravelの `Illuminate\Auth\Notifications\ResetPassword`通知は、`password.reset`という名前のルートを介してパスワードリセットURLを生成するため、これが必要です。

<a name="authentication"></a>
## ユーザー認証

使い始めるには、「ログイン」ビューを返す方法をFortifyに指示する必要があります。Fortifyはヘッドレス認証ライブラリであることを忘れないでください。あらかじめ完成しているLaravelの認証機能のフロントエンド実装が必要な場合は、[アプリケーションスターターキット](/docs/{{version}}/starter-kits)を使用する必要があります。

認証ビューのレンダリングロジックはすべて、`Laravel\Fortify\Fortify`クラスで利用できる適切なメソッドを使用してカスタマイズできます。通常、このメソッドはアプリケーションの`App\Providers\FortifyServiceProvider`クラスの`boot`メソッドから呼び出す必要があります。Fortifyはこのビューを返す、`/ login`ルートの定義を処理します。

    use Laravel\Fortify\Fortify;

    /**
     * 全アプリケーションサービスの起動処理
     *
     * @return void
     */
    public function boot()
    {
        Fortify::loginView(function () {
            return view('auth.login');
        });

        // ...
    }

ログインテンプレートには、`/login`へのPOSTリクエストを行うフォームが含まれている必要があります。`/login`エンドポイントは、文字列のメール／ユーザー名とパスワード（`password`）を想定しています。 メール／ユーザー名フィールドの名前は、`config/fortify.php`設定ファイル内の`username`値に一致する必要があります。さらに、論理値の`remember`フィールドを提供して、Laravelの提供する継続ログイン（rememberme）機能をユーザーが使用することを指定可能にできます。

ログイン試行が成功するとFortifyは、アプリケーションの`fortify`設定ファイル内の`home`設定オプションを介して設定したURIへリダイレクトします。ログインリクエストがXHRリクエストの場合、200HTTPレスポンスを返します。

リクエストが成功しなかった場合、ユーザーはログイン画面にリダイレクトされ、バリデーションエラーは共有の`$errors` [Bladeテンプレート変数](/docs/{{version}}/validation#quick-displaying-the-validation-errors)で共有されます。または、XHRリクエストの場合、バリデーションエラーは422HTTPレスポンスで返されます。

<a name="customizing-user-authentication"></a>
### ユーザー認証のカスタマイズ

Fortifyは提供された資格情報とアプリケーション用に構成された認証ガードに基づいて、ユーザーを自動的に取得して認証します。しかし、ログイン資格情報の認証方法とユーザーの取得方法を完全にカスタマイズしたい場合もあります。幸運なことにFortifyでは、`Fortify::authenticateUsing`メソッドを使用し、これが簡単に実行できます。

このメソッドは、受信したHTTPリクエストを受け取るクロージャを引数に取ります。クロージャは、リクエストに添付されたログイン資格情報を検証し、関連するユーザーインスタンスを返す責任があります。資格情報が無効であるかユーザーが見つからない場合、クロージャは`null`または`false`を返します。通常このメソッドは、`FortifyServiceProvider`の`boot`メソッドで呼び出す必要があります。

```php
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Laravel\Fortify\Fortify;

/**
 * 全アプリケーションサービスの起動処理
 *
 * @return void
 */
public function boot()
{
    Fortify::authenticateUsing(function (Request $request) {
        $user = User::where('email', $request->email)->first();

        if ($user &&
            Hash::check($request->password, $user->password)) {
            return $user;
        }
    });

    // ...
}
```

<a name="authentication-guard"></a>
#### 認証ガード

アプリケーションの`fortify`設定ファイル内で、Fortifyが使用する認証ガードをカスタマイズできます。ただし、設定するガードに`Illuminate\Contracts\Auth\StatefulGuard`を確実に実装してください。Laravel Fortifyを使用してSPAを認証しようとしている場合は、Laravelのデフォルトの`web`ガードと[Laravel Sanctum](https://laravel.com/docs/sanctum)を組み合わせて使用​​する必要があります。

<a name="two-factor-authentication"></a>
## ２要素認証

Fortifyの２要素認証機能を有効にしている場合、ユーザーは認証プロセス中に６桁の数値トークンを入力する必要があります。このトークンは、Google AuthenticatorなどのTOTP互換のモバイル認証アプリケーションから取得できる時間ベースのワンタイムパスワード（TOTP）を使用して生成されます。

使用開始する前に、アプリケーションの`App\Models\User`モデルで、`Laravel\Fortify\TwoFactorAuthenticatable`トレイトを使用していることを確認してください。

```php
<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Fortify\TwoFactorAuthenticatable;

class User extends Authenticatable
{
    use Notifiable, TwoFactorAuthenticatable;
}
```

次に、ユーザーが２要素認証設定を管理できる画面をアプリケーション内に構築する必要があります。この画面でユーザーが２要素認証を有効または無効にしたり、２要素認証の回復コードを再生成したりできるようにする必要があります。

> `fortify`設定ファイルの`features`配列によりデフォルトで、変更前にパスワードの確認を要求するようにFortifyの２要素認証設定に指示しています。そのため、皆さんのアプリケーションでFortifyの続行時[パスワード確認](#password-confirmation)機能を実装する必要があります。

<a name="enabling-two-factor-authentication"></a>
### ２要素認証の有効化

２要素認証を有効にするには、アプリケーションはFortifyで定義された`/user/two-factor-authentication`エンドポイントにPOSTリクエストを行う必要があります。リクエストが成功すると、ユーザーは前のURLにリダイレクトされ、`status`セッション変数は`two-factor-authentication-enabled`にセットされます。テンプレート内でこの`status`セッション変数を検出して、適切な成功メッセージを表示してください。リクエストがXHRリクエストの場合、`200` HTTPレスポンスが返されます。

```html
@if (session('status') == 'two-factor-authentication-enabled')
    <div class="mb-4 font-medium text-sm text-green-600">
        Two factor authentication has been enabled.
    </div>
@endif
```

次に、ユーザーの認証アプリケーションでスキャンしログインするための、２要素認証ＱＲコードを表示する必要があります。 Bladeを使用してアプリケーションのフロントエンドをレンダリングしている場合は、ユーザーインスタンスで使用可能な `twoFactorQrCodeSvg`メソッドを使用してQRコードSVGを取得できます。

```php
$request->user()->twoFactorQrCodeSvg();
```

JavaScriptを利用したフロントエンドを構築している場合は、`/user/two-factor-qr-code`エンドポイントにXHRのGETリクエストを送信して、ユーザーの2要素認証ＱＲコードを取得できます。このエンドポイントは、`svg`キーを含むJSONオブジェクトを返します。

<a name="displaying-the-recovery-codes"></a>
#### リカバリコードの表示

また、ユーザーの２要素リカバリコードも表示する必要があります。これらのリカバリコードにより、ユーザーはモバイルデバイスにアクセスできなくなった場合にも認証できます。Bladeを使用してアプリケーションのフロントエンドをレンダリングしている場合は、認証済みのユーザーインスタンスを介してリカバリコードにアクセスできます。

```php
(array) $request->user()->recoveryCodes()
```

JavaScriptを利用したフロントエンドを構築している場合は、`/user/two-factor-recovery-codes`エンドポイントに対してXHRのGETリクエストを行ってください。このエンドポイントは、ユーザーのリカバリコードを含むJSON配列を返します。

ユーザーのリカバリコードを再生成するとき、アプリケーションは`/user/two-factor-recovery-codes`エンドポイントに対してPOSTリクエストを行う必要があります。

<a name="authenticating-with-two-factor-authentication"></a>
### ２要素認証による認証

認証プロセス中にFortifyはユーザーをアプリケーションの２要素認証チャレンジ画面に自動的にリダイレクトします。ただし、アプリケーションがXHRログイン要求を行っている場合、認証の試行が成功した後に返されるJSON応答には、`two_factor`論理値プロパティを持つJSONオブジェクトが含まれます。この値を調べ、アプリケーションの２要素認証チャレンジ画面にリダイレクトする必要があるかどうかを確認する必要があります。

２要素認証機能の実装を開始するには、２要素認証チャレンジビューを返す方法をFortifyに指示する必要があります。 Fortifyの認証ビューレンダリングロジックはすべて、`Laravel\Fortify\Fortify`クラスで利用できる適切なメソッドを使用してカスタマイズできます。通常このメソッドは、アプリケーションの`App\Providers\FortifyServiceProvider`クラスの`boot`メソッドから呼び出す必要があります。

```php
use Laravel\Fortify\Fortify;

/**
 * 全アプリケーションサービスの起動処理
 *
 * @return void
 */
public function boot()
{
    Fortify::twoFactorChallengeView(function () {
        return view('auth.two-factor-challenge');
    });

    // ...
}
```

Fortifyはこのビューを返す、`/two-factor-challenge`ルートの定義を処理します。`two-factor-challenge`テンプレートには、`/two-factor-challenge`エンドポイントにPOSTリクエストを行うフォームを含める必要があります。`/two-factor-challenge`アクションは、有効なTOTPトークンを含む`code`フィールドまたはユーザーのリカバリコードの1つを含む`recovery_code`フィールドを期待します。

ログインの試行が成功すると、Fortifyはアプリケーションの`fortify`設定ファイル内の`home`設定オプションにより設定されたURIへ、ユーザーをリダイレクトします。ログイン要求がXHR要求であった場合、204 HTTPレスポンスが返されます。

リクエストが成功しなかった場合、ユーザーはログイン画面にリダイレクトされ、バリデーションエラーは共有の`$errors` [Bladeテンプレート変数](/docs/{{version}}/validation#quick-displaying-the-validation-errors)により利用できます。XHRリクエストの場合、バリデーションエラーは422 HTTPレスポンスで返されます。

<a name="disabling-two-factor-authentication"></a>
### ２要素認証の無効化

２要素認証を無効にするには、アプリケーションが`/user/two-factor-authentication`エンドポイントに対してDELETEリクエストを行う必要があります。 Fortifyの2要素認証エンドポイントは、呼び出される前に[パスワード確認](#password-confirmation)を必要とすることを忘れないでください。

<a name="registration"></a>
## ユーザー登録

アプリケーションの登録機能の実装をはじめるには、「登録（register）」ビューを返す方法をFortifyに指示する必要があります。Fortifyはヘッドレス認証ライブラリであることを忘れないでください。あらかじめ完成しているLaravelの認証機能のフロントエンド実装が必要な場合は、[アプリケーションスターターキット](/docs/{{version}}/starter-kits)を使用する必要があります。

Fortifyのビューレンダリングロジックはすべて、`Laravel\Fortify\Fortify`クラスで利用できる適切なメソッドを使用してカスタマイズできます。通常、このメソッドは、`App\Providers\FortifyServiceProvider`クラスの` boot`メソッドから呼び出す必要があります。

```php
use Laravel\Fortify\Fortify;

/**
 * 全アプリケーションサービスの起動処理
 *
 * @return void
 */
public function boot()
{
    Fortify::registerView(function () {
        return view('auth.register');
    });

    // ...
}
```

Fortifyは、このビューを返す`/register`ルートの定義を処理します。`register`テンプレートには、Fortifyが定義した`/register`エンドポイントへPOSTリクエストを行うフォームが含まれている必要があります。

`/register`エンドポイントは、文字列の`name`、文字列のメールアドレス／ユーザー名、`password`と`password_confirmation`フィールドを必要とします。メール／ユーザー名フィールドの名前は、アプリケーションの`fortify`設定ファイル内で定義する`username`設定値と一致させる必要があります。

登録の試行が成功すると、Fortifyはアプリケーションの`fortify`設定ファイル内の`home`設定オプションで指定してあるURIにユーザーをリダイレクトします。ログインリクエストがXHRリクエストの場合、200 HTTPレスポンスが返されます。

リクエストが成功しなかった場合、ユーザーは登録画面にリダイレクトされ、バリデーションエラーは共有の`$errors` [Bladeテンプレート変数](/docs/{{version}}/validation#quick-displaying-the-validation-errors)により利用可能になります。XHRリクエストの場合、バリデーションエラーは422 HTTPレスポンスで返されます。

<a name="customizing-registration"></a>
### ユーザー登録のカスタマイズ

ユーザーのバリデーションと作成のプロセスは、Laravel Fortifyのインストール時に生成される`App\Actions\Fortify\CreateNewUser`アクションを変更すればカスタマイズできます。

<a name="password-reset"></a>
## パスワードリセット

<a name="requesting-a-password-reset-link"></a>
### パスワードリセットリンクのリクエスト

アプリケーションのパスワードリセット機能の実装を開始するには、「パスワードを忘れた（forgot password）」ビューを返す方法をFortifyに指示する必要があります。Fortifyはヘッドレス認証ライブラリであることを忘れないでください。あらかじめ完成しているLaravelの認証機能のフロントエンド実装が必要な場合は、[アプリケーションスターターキット](/docs/{{version}}/starter-kits)を使用する必要があります。

Fortifyのビューレンダリングロジックはすべて、`Laravel\Fortify\Fortify`クラスで利用できる適切なメソッドを使用してカスタマイズできます。通常このメソッドは、アプリケーションの`App\Providers\FortifyServiceProvider`クラスの`boot`メソッドから呼び出す必要があります。

```php
use Laravel\Fortify\Fortify;

/**
 * 全アプリケーションサービスの起動処理
 *
 * @return void
 */
public function boot()
{
    Fortify::requestPasswordResetLinkView(function () {
        return view('auth.forgot-password');
    });

    // ...
}
```

Fortifyは、このビューを返す`/forgot-password`エンドポイントの定義を処理します。`forgot-password`テンプレートには`/forgot-password`エンドポイントにPOSTリクエストを行うフォームを含める必要があります。

`/forgot-password`エンドポイントは文字列`email`フィールドを必要とします。このフィールド/データベースカラムの名前は、アプリケーションの`fortify`設定ファイル内の`email`設定値と一致する必要があります。

<a name="handling-the-password-reset-link-request-response"></a>
#### パスワードリセットのリンクリクエスト処理レスポンス

パスワードリセットリンクリクエストが成功した場合、Fortifyはユーザーを`/forgot-password`エンドポイントにリダイレクトし、パスワードのリセットに使用できる安全なリンクを記載したメールをユーザーに送信します。リクエストがXHRリクエストの場合、200 HTTPレスポンスを返します。

リクエストが成功した後、`/forgot-password`エンドポイントにリダイレクトされたとき、`status`セッション変数を使用して、パスワードリセットリンクリクエストの実行ステータスを表示できます。このセッション変数の値は、アプリケーションの`passwords`[言語ファイル](/docs/{{version}}/localization)内で定義されている翻訳文字列の1つと一致します。

```html
@if (session('status'))
    <div class="mb-4 font-medium text-sm text-green-600">
        {{ session('status') }}
    </div>
@endif
```

リクエストが成功しなかった場合、ユーザーはリクエストパスワードリセットリンク画面にリダイレクトされ、共有の`$errors` [Bladeテンプレート変数](/docs/{{version}}/validation#quick-displaying-the-validation-errors)により、バリデーションエラーを利用できます。XHRリクエストの場合、バリデーションエラーは422 HTTPレスポンスで返されます。

<a name="resetting-the-password"></a>
### パスワードのリセット

アプリケーションのパスワードリセット機能の実装を完了するには、「パスワードのリセット（reset password）」ビューを返す方法をFortifyに指示する必要があります。

Fortifyのビューのレンダリングロジックはすべて、`Laravel\Fortify\Fortify`クラスで利用できる適切なメソッドを使用してカスタマイズできます。通常、このメソッドは、アプリケーションの`App\Providers\FortifyServiceProvider`クラスの`boot`メソッドから呼び出す必要があります。

```php
use Laravel\Fortify\Fortify;

/**
 * 全アプリケーションサービスの起動処理
 *
 * @return void
 */
public function boot()
{
    Fortify::resetPasswordView(function ($request) {
        return view('auth.reset-password', ['request' => $request]);
    });

    // ...
}
```

Fortifyは、このビューを表示するためのルートの定義を処理します。`reset-password`テンプレートには、`/reset-password`へのPOSTリクエストを行うフォームを含める必要があります。

`/reset-password`エンドポイントには、文字列の`email`フィールド、`password`フィールド、`password_confirmation`フィールド、`request()->route('token')`の値を含む`token`という名前の非表示フィールドが必要です。"email"フィールド／データベースカラム名は、アプリケーションの`fortify`設定ファイル内で定義されている`email`設定値と一致する必要があります。

<a name="handling-the-password-reset-response"></a>
#### パスワードリセットの処理レスポンス

パスワードリセットのリクエストが成功した場合、Fortifyは新しいパスワードでログインできるように、ユーザーを`/login`ルートへリダイレクトします。さらに、ログイン画面で正常にリセットした状態を表示できるように、`status`セッション変数が設定されます。

```html
@if (session('status'))
    <div class="mb-4 font-medium text-sm text-green-600">
        {{ session('status') }}
    </div>
@endif
```

リクエストがXHRリクエストの場合、200 HTTPレスポンスが返されます。

リクエストが成功しなかった場合、ユーザーはパスワードのリセット画面にリダイレクトされ、バリデーションエラーは共有の`$errors` [Bladeテンプレート変数](/docs/{{version}}/validation#quick-displaying-the-validation-errors)により利用できます。XHRリクエストの場合、バリデーションエラーは422 HTTPレスポンスで返されます。

<a name="customizing-password-resets"></a>
### パスワードリセットのカスタマイズ

パスワードのリセットプロセスは、Laravel　Fortifyのインストール時に生成された`App\Actions\ResetUserPassword`アクションを変更することでカスタマイズできます。

<a name="email-verification"></a>
## メールの確認

ユーザー登録後、ユーザーがアプリケーションへアクセスし続ける前に、ユーザーのメールアドレスを確認したい場合があります。これを行うには、`fortify`設定ファイルの`features`配列で`emailVerification`機能を確実に有効にしてください。次に、`App\Models\User`クラスが`Illuminate\Contracts\Auth\MustVerifyEmail`インターフェイスを実装していることを確認する必要があります。

これらの２つの設定手順が完了すると、新しく登録したユーザーへメールアドレスを所有していることを確認するメールが届きます。ただし、メール内の確認リンクをクリックする必要があることをユーザーに通知する、メール確認画面の表示方法をFortifyに通知する必要があります。

Fortifyのビューのレンダリングロジックはすべて、`Laravel\Fortify\Fortify`クラスで利用できる適切なメソッドを使用してカスタマイズできます。通常、このメソッドは、アプリケーションの`App\Providers\FortifyServiceProvider`クラスの`boot`メソッドから呼び出す必要があります。

```php
use Laravel\Fortify\Fortify;

/**
 * 全アプリケーションサービスの起動処理
 *
 * @return void
 */
public function boot()
{
    Fortify::verifyEmailView(function () {
        return view('auth.verify-email');
    });

    // ...
}
```

Fortifyは、ユーザーがLaravel組み込み済みの`verified`ミドルウェアにより、`/email/verify`エンドポイントへリダイレクトされたときにこのビューを表示するルートの定義を処理します。

`verify-email`テンプレートには、メールアドレスに送信されたメール確認リンクをクリックするようにユーザーへ指示する情報メッセージを含める必要があります。

<a name="resending-email-verification-links"></a>
#### メール検証リンクの再送信

必要に応じて、アプリケーションの`verify-email`テンプレートにボタンを追加して、`/email/verification-notification`エンドポイントへのPOSTリクエストを送信することもできます。このエンドポイントがリクエストを受信すると、新しい確認メールリンクがユーザーにメールで送信されるため、前の確認リンクが誤って削除されたり失われたりした場合でも、ユーザーは新しい確認リンクを取得できます。

確認リンクの電子メールを再送信するリクエストが成功した場合、Fortifyはユーザーを`status`セッション変数とともに、`/email/verify`エンドポイントにリダイレクトします。この変数でユーザーに操作が成功したメッセージを伝えられます。リクエストがXHRリクエストの場合、202 HTTPレスポンスが返されます。

```html
@if (session('status') == 'verification-link-sent')
    <div class="mb-4 font-medium text-sm text-green-600">
        A new email verification link has been emailed to you!
    </div>
@endif
```

<a name="protecting-routes"></a>
### ルートの保護

ルートまたはルートのグループでユーザーが自分のメールアドレスを確認する必要があることを指定するには、Laravelの組み込みの`verified`ミドルウェアをルートに指定する必要があります。このミドルウェアは、アプリケーションの`App\Http\Kernel`クラスで登録されています。

```php
Route::get('/dashboard', function () {
    // ...
})->middleware(['verified']);
```

<a name="password-confirmation"></a>
## パスワードの確認

アプリケーションを構築していると、実行する前にユーザーへパスワードを確認してもらう必要のあるアクションが、よく発生する場合があります。通常これらのルートは、Laravelへ組み込み済みの`password.confirm`ミドルウェアによって保護されています。

パスワード確認機能の実装を開始するには、アプリケーションの「パスワード確認（password confirmation）」ビューを返す方法をFortifyに指示する必要があります。Fortifyはヘッドレス認証ライブラリであることを忘れないでください。あらかじめ完成しているLaravelの認証機能のフロントエンド実装が必要な場合は、[アプリケーションスターターキット](/docs/{{version}}/starter-kits)を使用する必要があります。

Fortifyのビューレンダリングロジックはすべて、`Laravel\Fortify\Fortify`クラスで利用できる適切なメソッドを使用してカスタマイズできます。通常、このメソッドは、アプリケーションの`App\Providers\FortifyServiceProvider`クラスの`boot`メソッドから呼び出す必要があります。

```php
use Laravel\Fortify\Fortify;

/**
 * 全アプリケーションサービスの起動処理
 *
 * @return void
 */
public function boot()
{
    Fortify::confirmPasswordView(function () {
        return view('auth.confirm-password');
    });

    // ...
}
```

Fortifyは、このビューを返す`/user/confirm-password`エンドポイントの定義を処理します。`confirm-password`テンプレートは、`/user/confirm-password`エンドポイントへPOSTリクエストを行うフォームを含める必要があります。`/user/confirm-password`エンドポイントは、ユーザーの現在のパスワードを含む`password`フィールドが渡されることを期待しています。

パスワードがユーザーの現在のパスワードと一致する場合、Fortifyはユーザーをアクセスしようとしたルートにリダイレクトします。リクエストがXHRリクエストの場合、201 HTTPレスポンスが返されます。

リクエストが成功しなかった場合、ユーザーはパスワードの確認画面にリダイレクトされ、共有の`$errors`Bladeテンプレート変数を利用してバリデーションエラーが利用できます。XHRリクエストの場合、バリデーションエラーは422 HTTPレスポンスで返されます。
