# メール確認

- [イントロダクション](#introduction)
- [モデルの準備](#model-preparation)
- [データベースの検討](#verification-database)
- [ルート](#verification-routing)
    - [保護下のルート](#protecting-routes)
- [ビュー](#verification-views)
- [イベント](#events)

<a name="introduction"></a>
## イントロダクション

多くのWebアプリケーションはアプリケーション利用開始前に、ユーザーのメールアドレスを確認する必要があります。アプリケーションごとに再実装しなくても済むように、Laravelはメールを送信し、メールの確認リクエストを検証する便利なメソッドを用意しています。

#### てっとり早く始める

早速使い始めたいですか？真新しくインストールしたLaravelパッケージへ、[Laravel Jetstream](https://jetstream.laravel.com)をインストールしてください。データベースをマイグレーションしたら、`/register`へブラウザでアクセスするか、アプリケーションに割り付けた別のURLへアクセスしましょう。Jetstreamはメール確認を含め、認証システム全体のスカフォールディングを面倒見ます！

<a name="model-preparation"></a>
## モデルの準備

使い始めるには、`App\Models\User`モデルが`Illuminate\Contracts\Auth\MustVerifyEmail`契約を実装していることを確認してください。

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

メール確認を行うのに必要なルートはすべて、[Laravel Jetstream](https://jetstream.laravel.com)に含まれています。Jetstreamのインストールのやり方は、公式[Jetstreamドキュメント](https://jetstream.laravel.com)をご覧ください。

<a name="protecting-routes"></a>
### 保護下のルート

[Routeミドルウェア](/docs/{{version}}/middleware)を指定したルートに対しメールアドレス確認済みのユーザーのみアクセスを許すために使用します。`Illuminate\Auth\Middleware\EnsureEmailIsVerified`で定義している`verified`ミドルウェアをLaravelは用意しています。このミドルウェアは、アプリケーションのHTTPカーネルで登録済みですので、ルート定義にこのミドルウェアを指定するだけです。

    Route::get('profile', function () {
        // 確認済みユーザーのときだけ実行されるコード…
    })->middleware('verified');

<a name="verification-views"></a>
## ビュー

メール確認を行うのに必要なビューはすべて、[Laravel Jetstream](https://jetstream.laravel.com)に含まれています。Jetstreamのインストールのやり方は、公式[Jetstreamドキュメント](https://jetstream.laravel.com)をご覧ください。

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
