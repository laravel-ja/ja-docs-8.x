# メール確認

- [イントロダクション](#introduction)
    - [モデルの準備](#model-preparation)
    - [データベースの検討事項](#database-preparation)
- [ルート](#verification-routing)
    - [メール確認の通知](#the-email-verification-notice)
    - [メール確認のハンドラ](#the-email-verification-handler)
    - [メール確認の再送信](#resending-the-verification-email)
    - [保護下のルート](#protecting-routes)
- [イベント](#events)

<a name="introduction"></a>
## イントロダクション

多くのWebアプリケーションはアプリケーション利用開始前に、ユーザーのメールアドレスを確認する必要があります。アプリケーションごとに再実装しなくても済むように、Laravelはメールを送信し、メールの確認リクエストを検証する便利なメソッドを用意しています。

> {tip} さっそく始めたいですか？ [Laravel Jetstream](https://jetstream.laravel.com)（[和訳](/jetstream/1.0/ja/introduction.html)）を新しいLaravelアプリケーションにインストールしてください。データベースをマイグレーションしたら、ブラウザで`/register`、もしくはアプリケーションに割り振った他のURLを閲覧します。Jetstreamはメール確認のサポートを含む、認証システム全体のスカフォールドの面倒を見ます！

<a name="model-preparation"></a>
### モデルの準備

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

このインターフェイスがモデルに追加されると、新しく登録されたユーザーへメール確認リンクを含むメールが自動的に送信されます。`EventServiceProvider`を調べるとわかるように、Laravelははじめから`Illuminate\Auth\Events\Registered`イベントに指定した`SendEmailVerificationNotification`[リスナ](/docs/{{version}}/events)を用意しています。

[Laravel Jetstream](https://jetstream.laravel.com)（[和訳](/jetstream/1.0/ja/introduction.html)）を使用する代わりに、自前でユーザー登録をアプリケーションへ実装する場合は、ユーザーの登録成功後に`Illuminate\Auth\Events\Registered`イベントを確実に発行してください。

    use Illuminate\Auth\Events\Registered;

    event(new Registered($user));

<a name="database-preparation"></a>
### データベースの検討事項

次に、メールアドレスを確認した日時を保存するための、`email_verified_at`カラムを`users`テーブルに含める必要があります。Laravelフレームワークにデフォルトで含まれている、`users`テーブルマイグレーションには、あらかじめこのカラムが準備されています。ですから、必要なのはデータベースマイグレーションを実行することだけです。

    php artisan migrate

<a name="verification-routing"></a>
## ルート

電子メールの検証を適切に実装するには、3つのルートを定義する必要があります。まず、登録後にLaravelが送信する確認メールの中にある、メール確認リンクをクリックする必要がある旨の通知をユーザーに表示するためルートが必要です。次に、ユーザーがメール中のメール確認リンクをクリックしたときに生成されるリクエストを処理するためのルートが必要です。３つ目に、ユーザーが最初のメールを誤って失った場合に、確認リンクを再送信するためのルートが必要になります。

<a name="the-email-verification-notice"></a>
### メール確認の通知

前述のとおり、Laravelがメール送信したメール確認リンクをクリックするように、ユーザーに指示するビューを返すルートを定義する必要があります。このビューは、ユーザーが最初にメールアドレスを確認せずにアプリケーションの他の部分にアクセスしようとしたときに表示されます。`App\Models\User`モデルが`MustVerifyEmail`インターフェイスを実装していると、リンクは自動的にユーザーにメールで送信されます：

    Route::get('/email/verify', function () {
        return view('auth.verify-email');
    })->middleware(['auth'])->name('verification.notice');

メール確認通知を返すルートの名前は `verification.notice`にする必要があります。[Laravelが用意している](#protecting-routes)`verified`ミドルウェアは、ユーザーがメールアドレスを確認していない場合、このルート名に自動的にリダイレクトするため、ルートへ正確にこの名前を割り当てることが重要です。

> {tip} 電子メール検証を自前で実装する場合、検証通知ビューの内容を自分で定義する必要があります。必要なすべての認証および検証ビューを含むスカフォールドが必要な場合は、[Laravel Jetstream](https://jetstream.laravel.com)（[和訳](/jetstream/1.0/ja/introduction.html)）をチェックしてください。

<a name="the-email-verification-handler"></a>
### メール確認のハンドラ

次に、メールで送信したメール確認リンクをユーザーがクリックしたときに送信してくるリクエストを処理するルートが必要です。このルートには`verification.verify`という名前を付け、`auth`と`signed`ミドルウェアを割り当てる必要があります。

    use Illuminate\Foundation\Auth\EmailVerificationRequest;
    use Illuminate\Http\Request;

    Route::get('/email/verify/{id}/{hash}', function (EmailVerificationRequest $request) {
        $request->fulfill();

        return redirect('/home');
    })->middleware(['auth', 'signed'])->name('verification.verify');

先へ進む前に、このルートを詳しく見てみましょう。まず、典型的な`Illuminate\Http\Request`インスタンスの代わりに`EmailVerificationRequest`リクエストタイプを使用していることに気が付かれると思います。`EmailVerificationRequest`は、Laravelが用意している[form request](/docs/{{version}}/validation#form-request-validation)です。このリクエストタイプは、リクエストの`id`および`hash`パラメーターを自動的に検証する処理を行います。

次に、リクエスト上の`fulfill`メソッドを直接呼び出すことができます。このメソッドは、認証済みユーザーの`markEmailAsVerified`メソッドを呼び出し、`Illuminate\Auth\Events\Verified`イベントを発行します。`markEmailAsVerified`メソッドは、`Illuminate\Foundation\Auth\User`ベースクラスを介してデフォルトの`App\Models\User`モデルで利用できます。 ユーザーのメールアドレスが検証されたら、好きな場所にリダイレクトできます。

<a name="resending-the-verification-email"></a>
### メール確認の再送信

たまにユーザーはメールアドレスの確認メールを紛失したり、誤って削除したりすることがあります。これに対応するため、ユーザーが確認メールの再送信をリクエストできるルートを定義できます。次に、[確認通知ビュー](#the-email-verification-notice)内にシンプルなフォーム送信ボタンを配置することで、このルートへのリクエストを行うことができるようにしましょう。

    use Illuminate\Http\Request;

    Route::post('/email/verification-notification', function (Request $request) {
        $request->user()->sendEmailVerificationNotification();

        return back()->with('status', 'verification-link-sent');
    })->middleware(['auth', 'throttle:6,1'])->name('verification.send');

<a name="protecting-routes"></a>
### 保護下のルート

[ルートミドルウェア](/docs/{{version}}/middleware)を使用すると、確認済みのユーザーのみが特定のルートへアクセスできるようになります。Laravelには、`Illuminate\Auth\Middleware\EnsureEmailIsVerified`クラスを参照する`verified`ミドルウェアが付属しています。このミドルウェアははじめからアプリケーションのHTTPカーネルに登録されているため、ミドルウェアをルート定義に指定するだけです。

    Route::get('profile', function () {
        // 確認済みユーザーのときだけ実行されるコード…
    })->middleware('verified');

このミドルウェアが割り当てられているルートに、未確認ユーザーがアクセスしようとすると自動的に`verification.notice`[名前付きルート](/docs/{{version}}/routing#named-routes)にリダイレクトされます。

<a name="events"></a>
## イベント

[Laravel Jetstream](https://jetstream.laravel.com)を使用している場合、Laravelはメール検証プロセス中に[イベント](/docs/{{version}}/events)をディスパッチします。アプリケーションの電子メール検証を自前で処理している場合は、検証の完了後にこれらのイベントを自分でディスパッチしたい場合があります。 `EventServiceProvider`でこれらのイベントにリスナを指定できます：

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
