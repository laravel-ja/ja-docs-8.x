# パスワードリセット

- [イントロダクション](#introduction)
    - [モデルの検討事項](#model-preparation)
    - [データベースの検討事項](#database-preparation)
- [ルート定義](#routing)
    - [パスワードリセットリンクの要求](#requesting-the-password-reset-link)
    - [パスワードリセット](#resetting-the-password)
- [カスタマイズ](#password-customization)

<a name="introduction"></a>
## イントロダクション

大抵のWebアプリケーションはパスワードをリセットする手段を提供しています。それぞれのアプリケーションで何度も実装する代わりに、Laravelはパスワードリマインダを送り、パスワードリセットを実行する便利な方法を提供しています。

> {tip} さっそく始めたいですか？ [Laravel Jetstream](https://jetstream.laravel.com)（[和訳](/jetstream/1.0/ja/introduction.html)）を真新しいLaravelアプリケーションにインストールしてください。データベースをマイグレートしたら、ブラウザでアプリケーションの`/register`、もしくはアプリケーションに割り付けた他のURLに移動します。Jetstreamはパスワードのリセットを含め、認証システム全体のスカフォールドを受け持ちます。

<a name="model-preparation"></a>
### モデルの検討事項

Laravelのパスワードリセット機能を使用する前に、`App\Models\User`モデルで`Illuminate\Notifications\Notifiable`トレイトを使用する必要があります。通常このトレイトは、Laravelに含まれているデフォルトの`App\Models\User`モデルに最初から含まれています。

モデルが、`Illuminate\Contracts\Auth\CanResetPassword`契約を実装していることを確認します。フレームワークに含まれている`App\Models\User`モデルははじめからこのインターフェイスを実装しており、インターフェイスの実装に必要なメソッドを取り込むために`Illuminate\Auth\Passwords\CanResetPassword`トレイトを使用しています。

<a name="database-preparation"></a>
### データベースの検討事項

アプリケーションのパスワードリセットトークンを保存するためのテーブルを作成する必要があります。このテーブルのマイグレーションは、デフォルトのLaravelインストールに含まれているため、データベースマイグレーションを実行してこのテーブルを作成するだけです。

    php artisan migrate

<a name="routing"></a>
## ルート定義

ユーザーがパスワードをリセットできるようにするためのサポートを適切に実装するには、ルートを２つ定義する必要があります。まず、ユーザーが自分のメールアドレスを介してパスワードリセットリンクをリクエストできるようにするためのルートです。２つ目はユーザーが電子メールで送信されたパスワードリセットリンクにアクセスしたら、実際にパスワードをリセットするためのルートが必要です。

<a name="requesting-the-password-reset-link"></a>
### パスワードリセットリンクの要求

#### パスワードリセットリンク要求フォーム

最初に、パスワードリセットリンクを要求するために必要なルートを定義します。そのために、パスワードリセットリンクリクエストフォームを含むビューを返すルートを定義します。

    Route::get('/forgot-password', function () {
        return view('auth.forgot-password');
    })->middleware(['guest'])->name('password.request');

このルートによって返されるビューには、 `email`フィールドを含むフォームが必要です。これにより、ユーザーは特定のメールアドレスのパスワードリセットリンクをリクエストできます。

#### フォーム送信の処理

次に、「パスワードを忘れた」ビューからのフォーム要求を処理するルートを定義します。このルートは、電子メールアドレスを検証し、該当するユーザーへパスワードリセットリクエストを送る責務を負います。

    use Illuminate\Http\Request;
    use Illuminate\Support\Facades\Password;

    Route::post('/forgot-password', function (Request $request) {
        $request->validate(['email' => 'required|email']);

        $status = Password::sendResetLink(
            $request->only('email')
        );

        return $status === Password::RESET_LINK_SENT
                    ? back()->with(['status' => __($status)])
                    : back()->withErrors(['email' => __($status)]);
    })->middleware(['guest'])->name('password.email');

先へ進む前に、このルートの詳細を確認しましょう。まず、リクエストの `email`属性が検証されます。 次に、Laravelの組み込みの（`Password`ファサードによる）「パスワードブローカ」を使用し、パスワードリセットリンクをユーザーに送信します。パスワードブローカーは、指定されたフィールド（この場合はメールアドレス）でユーザーを取得し、Laravelの組み込み[通知システム](/docs/{{version}}/notifications)を介してパスワードリセットリンクをユーザーに送ります。

`sendResetLink`メソッドは「ステータス」スラッグを返します。このステータスはリクエストのステータスに関するユーザーフレンドリーなメッセージを翻訳して表示するために、Laravelの[多言語化](/docs/{{version}}/localization)ヘルパを使用します。パスワードリセットステータスの翻訳は、アプリケーションの `resources/lang/{lang}/passwords.php`言語ファイルにの内容で行われます。ステータススラグの可能な各値のエントリは、`passwords`言語ファイル内にあります。

> {tip} パスワードのリセットを自前で実装する場合は、ビューのコンテンツとルートを自分で定義する必要があります。必要なすべての認証および検証ロジックを含むスカフォールドが必要な場合は、[Laravel Jetstream](https://jetstream.laravel.com)（[和訳](/jetstream/1.0/ja/introduction.html)）をチェックしてください。

<a name="resetting-the-password"></a>
### パスワードリセット

#### パスワードリセットフォーム

次に、ユーザーがメールで送られてきたパスワードリセットリンクをクリックして、新しいパスワードを入力し実際にパスワードをリセットするのに必要なルートを定義します。まず、ユーザーがパスワード再設定リンクをクリックしたときに表示されるパスワード再設定フォームを表示するルートを定義しましょう。このルートは後でパスワードリセットリクエストを確認するために使用する `token`パラメーターを受け取ります。

    Route::get('/reset-password/{token}', function ($token) {
        return view('auth.reset-password', ['token' => $token]);
    })->middleware(['guest'])->name('password.reset');

このルートによって返されるビューには、 `email`フィールド、` password`フィールド、`password_confirmation`フィールド、および非表示でルートが受け取るシークレットトークンの値を含む`token`フィールドを持つフォームが必要です。

#### フォーム送信の処理

もちろん、パスワードリセットフォームの送信内容を実際に処理するためのルートを定義する必要があります。このルートは、受信リクエストの検証とデータベース内のユーザーのパスワードの更新の責務を負います。

    use Illuminate\Auth\Events\PasswordReset;
    use Illuminate\Http\Request;
    use Illuminate\Support\Facades\Hash;
    use Illuminate\Support\Facades\Password;
    use Illuminate\Support\Str;

    Route::post('/reset-password', function (Request $request) {
        $request->validate([
            'token' => 'required',
            'email' => 'required|email',
            'password' => 'required|min:8|confirmed',
        ]);

        $status = Password::reset(
            $request->only('email', 'password', 'password_confirmation', 'token'),
            function ($user, $password) use ($request) {
                $user->forceFill([
                    'password' => Hash::make($password)
                ])->save();

                $user->setRememberToken(Str::random(60));

                event(new PasswordReset($user));
            }
        );

        return $status == Password::PASSWORD_RESET
                    ? redirect()->route('login')->with('status', __($status))
                    : back()->withErrors(['email' => __($status)]);
    })->middleware(['guest'])->name('password.update');

先へ進む前に、このルートをさらに詳しく見てみましょう。まず、リクエストの`token`、`email`、`password`属性が検証されます。 次に、Laravel組み込みの（`Password`ファサードによる）「パスワードブローカー」を使用し、パスワードリセットリクエストの認証情報を検証します。

パスワードブローカーに提供されたトークン、メールアドレス、パスワードが有効な場合、`reset`メソッドに渡されたクロージャが実行されます。ユーザーインスタンスと平文テキストパスワードを受け取るこのクロージャ内で、データベース上のユーザーパスワードを更新します。

`reset`メソッドは「ステータス」スラグを返します。このステータスは、リクエストのステータスに関してユーザーにわかりやすいメッセージを翻訳し表示するために、Laravelの[多言語化](/docs/{{version}}/localization)ヘルパを使用します。パスワードリセットステータスの翻訳内容は、アプリケーションの`resources/lang/{lang}/passwords.php`言語ファイル内にあります。ステータススラグの指定可能な各値のエントリは、`passwords`言語ファイル内にあります。

<a name="password-customization"></a>
## カスタマイズ

#### リセットメールのカスタマイズ

パスワードリセットリンクをユーザーへ送るために使用する、通知クラスは簡単に変更できます。手始めに、`User`モデルの`sendPasswordResetNotification`メソッドをオーバーライドしましょう。このメソッドの中で、皆さんが選んだ通知クラスを使用し、通知を送信できます。パスワードリセット`$token`は、メソッドの第1引数として受け取ります。

    /**
     * パスワードリセット通知の送信
     *
     * @param  string  $token
     * @return void
     */
    public function sendPasswordResetNotification($token)
    {
        $this->notify(new ResetPasswordNotification($token));
    }
