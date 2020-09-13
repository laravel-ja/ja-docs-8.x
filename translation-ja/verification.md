# メール確認

- [イントロダクション](#introduction)
- [モデルの準備](#model-preparation)
- [データベースの検討](#verification-database)
- [ルート](#verification-routing)
    - [保護下のルート](#protecting-routes)
- [ビュー](#verification-views)
- [メール確認後](#after-verifying-emails)
- [イベント](#events)

<a name="introduction"></a>
## イントロダクション

多くのWebアプリケーションはアプリケーション利用開始前に、ユーザーのメールアドレスを確認する必要があります。アプリケーションごとに再実装しなくても済むように、Laravelはメールを送信し、メールの確認リクエストを検証する便利なメソッドを用意しています。

<a name="model-preparation"></a>
## モデルの準備

To get started, verify that your `App\Models\User` model implements the `Illuminate\Contracts\Auth\MustVerifyEmail` contract:

    <?php

    namespace App\Models;

    use Illuminate\Contracts\Auth\MustVerifyEmail;
    use Illuminate\Foundation\Auth\User as Authenticatable;
    use Illuminate\Notifications\Notifiable;

    class User extends Authenticatable implements MustVerifyEmail
    {
        use Notifiable;

        // ...
    }

モデルへこのインターフェイスを追加すると、新しい登録ユーザーへ自動的にメール確認のリンクを含むメールが送信されます。`EventServiceProvider`で確認できるように、`Illuminate\Auth\Events\Registered`イベントに対する`SendEmailVerificationNotification`リスナの指定をLaravelは用意しています。

<a name="verification-database"></a>
### データベースの検討

#### メール確認カラム

次に、メールアドレスを確認した日時を保存するための、`email_verified_at`カラムを`users`テーブルに含める必要があります。Laravelフレームワークにデフォルトで含まれている、`users`テーブルマイグレーションには、あらかじめこのカラムが準備されています。ですから、必要なのはデータベースマイグレーションを実行することだけです。

    php artisan migrate

<a name="verification-routing"></a>
## ルート

確認リンクを送信し、メールを確認するために必要なロジックを含む、`Auth\VerificationController`クラスをLaravelは用意しています。このコントローラに必要なルートを登録するには、`Auth::routes`メソッドに、`verify`オプションを渡してください。

    Auth::routes(['verify' => true]);

<a name="protecting-routes"></a>
### 保護下のルート

[Routeミドルウェア](/docs/{{version}}/middleware)を指定したルートに対しメールアドレス確認済みのユーザーのみアクセスを許すために使用します。`Illuminate\Auth\Middleware\EnsureEmailIsVerified`で定義している`verified`ミドルウェアをLaravelは用意しています。このミドルウェアは、アプリケーションのHTTPカーネルで登録済みですので、ルート定義にこのミドルウェアを指定するだけです。

    Route::get('profile', function () {
        // 確認済みユーザーのときだけ実行されるコード…
    })->middleware('verified');

<a name="verification-views"></a>
## ビュー

メール確認に必要なビューは、`laravel/ui` Composerパッケージを使用して生成します。

    composer require laravel/ui

    php artisan ui vue --auth

メール確認のビューは`resources/views/auth/verify.blade.php`として設置されます。アプリケーションの必要に合わせて自由にカスタマイズしてください。

<a name="after-verifying-emails"></a>
## メール確認後

メールアドレスを確認後、ユーザーを自動的に`/home`ヘリダイレクトします。`VerificationController`の`redirectTo`メソッドかプロパティにより、確認後のリダイレクト先をカスタマイズできます。

    protected $redirectTo = '/dashboard';

<a name="events"></a>
## イベント

メールの確認過程で、Laravelは[イベント](/docs/{{version}}/events)をディスパッチします。`EventServiceProvider`の中で、これらのイベントにリスナを指定できます。

    /**
     * アプリケーションにマップするイベントリスナ
     *
     * @var array
     */
    protected $listen = [
        'Illuminate\Auth\Events\Verified' => [
            'App\Listeners\LogVerifiedUser',
        ],
    ];
