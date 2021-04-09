# メール確認

- [イントロダクション](#introduction)
    - [モデルの準備](#model-preparation)
    - [データベースの検討事項](#database-preparation)
- [ルート](#verification-routing)
    - [メール確認の通知](#the-email-verification-notice)
    - [メール確認のハンドラ](#the-email-verification-handler)
    - [メール確認の再送信](#resending-the-verification-email)
    - [保護下のルート](#protecting-routes)
- [カスタマイズ](#customization)
- [イベント](#events)

<a name="introduction"></a>
## イントロダクション

多くのWebアプリケーションでは、ユーザーがアプリケーションを使用開始する前に電子メールアドレスを確認する必要があります。Laravelでは、作成するアプリケーションごとにこの機能を手動で再実装する必要はなく、電子メール確認リクエストを送信および検証するための便利な組み込みサービスを提供しています。

> {tip} てっとり早く始めたいですか？[Laravelアプリケーションスターターキット](/docs/{{version}}/starter-kits)の１つを新しいLaravelアプリケーションにインストールしてください。スターターキットは、電子メール確認サポートを含む、認証システム全体のスカフォールドを処理します。

<a name="model-preparation"></a>
### モデルの準備

はじめる前に、`App\Models\User`モデルが`Illuminate\Contracts\Auth\MustVerifyEmail`契約を実装していることを確認してください。

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

このインターフェイスをモデルへ追加したら、新しく登録したユーザーへ、確認リンクを含む電子メールが自動的に送信されます。アプリケーションの`App\Providers\EventServiceProvider`を調べるとわかるように、はじめからLaravelは、`Illuminate\Auth\Events\Registered`イベントへアタッチ済みの`SendEmailVerificationNotification`[リスナ](/docs/{{version}}/events)を用意してあります。このイベントリスナが、電子メール確認リンクをユーザーへ送信します。

[スターターキット](/docs/{{version}}/starter-kits)を使用する代わりに、アプリケーション内で手動で登録を実装する場合は、ユーザーの登録が成功した後に、`Illuminate\Auth\Events\Registered`イベントを確実に発行してください。

    use Illuminate\Auth\Events\Registered;

    event(new Registered($user));

<a name="database-preparation"></a>
### データベースの検討事項

次に、`user`テーブルにユーザーの電子メールアドレスが確認された日時を格納するための`email_verified_at`カラムを用意する必要があります。デフォルトでLaravelフレームワークに含まれている`users`テーブルのマイグレーションには、はじめからこのカラムが含まれています。したがって、必要なのはデータベースのマイグレーションを実行することだけです。

    php artisan migrate

<a name="verification-routing"></a>
## ルート

電子メール確認を適切に実装するには、３つのルートを定義する必要があります。第１に、Laravelがユーザー登録後に送信する確認メール中のメールアドレス確認リンクをクリックする必要があるという通知をユーザーに表示するためのルートが必要になります。

第２に、ユーザーが電子メール内の電子メール確認リンクをクリックしたときに生成されるリクエストを処理するルートです。

第３に、ユーザーが誤って最初の確認リンクを紛失した場合に、確認リンクを再送信するためのルートです。

<a name="the-email-verification-notice"></a>
### メール確認の通知

前述のように、登録後にLaravelがメールで送信するメール確認リンクをクリックするようにユーザーに指示するビューを返すルートを定義する必要があります。このビューは、ユーザーが最初に電子メールアドレスを確認せずにアプリケーションの他の部分にアクセスしようとしたときに表示されます。`App\Models\User`モデルが`MustVerifyEmail`インターフェイスを実装している限り、リンクは自動的にユーザーへ電子メールで送信されることに注意してください。

    Route::get('/email/verify', function () {
        return view('auth.verify-email');
    })->middleware('auth')->name('verification.notice');

メール確認通知を返すルートの名前は `verification.notice`にする必要があります。[Laravelが用意している](#protecting-routes)`verified`ミドルウェアは、ユーザーがメールアドレスを確認していない場合、このルート名に自動的にリダイレクトするため、ルートへ正確にこの名前を割り当てることが重要です。

> {tip} 電子メール検証を手動で実装する場合は、検証通知ビューの内容を自分で定義する必要があります。必要なすべての認証ビューと検証ビューを含むスカフォールドが必要な場合は、[Laravelアプリケーションスターターキット](/docs/{{version}}/starter-kits)をチェックしてください。

<a name="the-email-verification-handler"></a>
### メール確認のハンドラ

次に、ユーザーが電子メールで送信された電子メール確認リンクをクリックしたときに生成されるリクエストを処理するルートを定義する必要があります。このルートには`verification.verify`という名前を付け、`auth`および`signed`ミドルウェアを割り当てる必要があります。

    use Illuminate\Foundation\Auth\EmailVerificationRequest;
    use Illuminate\Http\Request;

    Route::get('/email/verify/{id}/{hash}', function (EmailVerificationRequest $request) {
        $request->fulfill();

        return redirect('/home');
    })->middleware(['auth', 'signed'])->name('verification.verify');

先に進む前に、このルートを詳しく見てみましょう。まず、通常の`Illuminate\Http\Request`インスタンスの代わりに`EmailVerificationRequest`リクエストタイプを使用していることに気付くでしょう。`EmailVerificationRequest`は、Laravelに含まれている[フォームリクエスト](/docs/{{version}}/validation#form-request-validation)です。このリクエストは、リクエストの`id`パラメータと`hash`パラメータの検証を自動的に処理します。

次に、リクエスト上の`fulfill`メソッドを直接呼び出します。このメソッドは、認証済みユーザーの`markEmailAsVerified`メソッドを呼び出し、`Illuminate\Auth\Events\Verified`イベントを発行します。`markEmailAsVerified`メソッドは、`Illuminate\Foundation\Auth\User`ベースクラスを介してデフォルトの`App\Models\User`モデルで利用できます。 ユーザーのメールアドレスを検証したら、好きな場所にリダイレクトできます。

<a name="resending-the-verification-email"></a>
### メール確認の再送信

たまにユーザーはメールアドレスの確認メールを紛失したり、誤って削除したりすることがあります。これに対応するため、ユーザーが確認メールの再送信をリクエストできるルートを定義できます。次に、[確認通知ビュー](#the-email-verification-notice)内にシンプルなフォーム送信ボタンを配置することで、このルートへのリクエストを行うことができるようにしましょう。

    use Illuminate\Http\Request;

    Route::post('/email/verification-notification', function (Request $request) {
        $request->user()->sendEmailVerificationNotification();

        return back()->with('message', 'Verification link sent!');
    })->middleware(['auth', 'throttle:6,1'])->name('verification.send');

<a name="protecting-routes"></a>
### 保護下のルート

[ルートミドルウェア](/docs/{{version}}/middleware)は、確認済みユーザーのみが特定のルートにアクセスできるようにするために使用できます。Laravelには、`Illuminate\Auth\Middleware\EnsureEmailIsVerified`クラスを参照する`verified`ミドルウェアが付属しています。このミドルウェアはアプリケーションのHTTPカーネルではじめから登録されているため、必要なのはミドルウェアをルート定義にアタッチすることだけです。

    Route::get('/profile', function () {
        // 確認済みのユーザーのみがこのルートにアクセス可能
    })->middleware('verified');

このミドルウェアが割り当てられているルートに、未確認ユーザーがアクセスしようとすると自動的に`verification.notice`[名前付きルート](/docs/{{version}}/routing#named-routes)にリダイレクトされます。

<a name="customization"></a>
## カスタマイズ

<a name="verification-email-customization"></a>
#### 確認メールのカスタマイズ

デフォルトの電子メール確認通知はほとんどのアプリケーションの要件を満たすと思いますが、Laravelでは電子メール確認メールメッセージの構築をカスタマイズできます。

取り掛かるには、`Illuminate\Auth\Notifications\VerifyEmail`通知によって提供される`toMailUsing`メソッドにクロージャを渡します。クロージャは、通知を受信するnotifiableモデルインスタンスと、ユーザーがメールアドレスを確認するためにアクセスする必要のある署名済みのメール確認URLを受け取ります。クロージャは、`Illuminate\Notifications\Messages\MailMessage`のインスタンスを返す必要があります。通常、アプリケーションの`App\Providers\AuthServiceProvider`クラスの`boot`メソッドから`toMailUsing`メソッドを呼び出す必要があります。

    use Illuminate\Auth\Notifications\VerifyEmail;
    use Illuminate\Notifications\Messages\MailMessage;

    /**
     * 全認証／承認サービスの登録
     *
     * @return void
     */
    public function boot()
    {
        // …

        VerifyEmail::toMailUsing(function ($notifiable, $url) {
            return (new MailMessage)
                ->subject('Verify Email Address')
                ->line('Click the button below to verify your email address.')
                ->action('Verify Email Address', $url);
        });
    }

> {tip}メール通知の詳細は、[メール通知ドキュメント](/docs/{{version}}/notifys#mail-notifications)を参照してください。

<a name="events"></a>
## イベント

[Laravelアプリケーションスターターキット](/docs/{{version}}/starter-kits)を使用する場合、Laravelはメール確認プロセス中に[イベント](/docs/{{version}}/events)を発行します。アプリケーションの電子メール確認を手動で処理する場合は、確認の完了後にこれらのイベントを手動で発行することを推奨します。アプリケーションの`EventServiceProvider`でこれらのイベントへリスナをアタッチできます。

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
