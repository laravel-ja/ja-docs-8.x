# パスワードリセット

- [イントロダクション](#introduction)
    - [モデルの準備](#model-preparation)
    - [データベース準備](#database-preparation)
    - [信頼するホストの設定](#configuring-trusted-hosts)
- [ルート](#routing)
    - [パスワードリセットリンクの要求](#requesting-the-password-reset-link)
    - [パスワードのリセット](#resetting-the-password)
- [カスタマイズ](#password-customization)

<a name="introduction"></a>
## イントロダクション

ほとんどのWebアプリケーションは、ユーザーが忘れたパスワードをリセットする方法を提供します。Laravelでは、構築するすべてのアプリケーションでこれを手動で再実装する必要はなく、パスワードリセットリンクを送信してパスワードを安全にリセットするための便利なサービスを提供しています。

> {tip} さっそく始めたいですか？Laravel[アプリケーションスターターキット](/docs/{{version}}/starter-kits)を新しいLaravelアプリケーションにインストールしてください。Laravelのスターターキットは、忘れたパスワードのリセットを含む、認証システム全体のスカフォールドの面倒を見ています。

<a name="model-preparation"></a>
### モデルの準備

Laravelのパスワードリセット機能を使用する前に、アプリケーションの`App\Models\User`モデルで`Illuminate\Notifications\Notizable`トレイトを使用する必要があります。通常、このトレイトは、新しいLaravelアプリケーションで作成されるデフォルトの`App\Models\User`モデルに最初から含まれています。

次に、`App\Models\User`モデルが`Illuminate\Contracts\Auth\CanResetPassword`コントラクトを実装していることを確認します。フレームワークに含まれている`App\Models\User`モデルは、最初からこのインターフェイスを実装しており、`Illuminate\Auth\Passwords\CanResetPassword`トレイトを使用して、インターフェイスの実装に必要なメソッドを持っています。

<a name="database-preparation"></a>
### データベース準備

アプリケーションのパスワードリセットトークンを保存するためのテーブルを作成する必要があります。このテーブルのマイグレーションはデフォルトのLaravelアプリケーションに含まれているため、データベースをマイグレーションするだけでこのテーブルを作成できます。

    php artisan migrate

<a name="configuring-trusted-hosts"></a>
### 信頼するホストの設定

デフォルトでは、LaravelはHTTPリクエストの`host`ヘッダの内容に関係なく受信したすべてのリクエストにレスポンスします。さらに、Webリクエスト中にアプリケーションへの絶対URLを生成するときに、`host`ヘッダの値を使用します。

通常、NginxやApacheなどのウェブサーバは、与えられたホスト名にマッチするリクエストのみをアプリケーションに送信するように設定する必要があります。しかし、ウェブサーバを直接カスタマイズできず、Laravelに特定のホスト名にしか応答しないように指示する必要がある場合は、アプリケーションのミドルウェアである`App\Http\Middleware\TrustHosts`を有効にすることで、それが可能になります。これは、アプリケーションがパスワードリセット機能を提供している場合、特に重要です。

このミドルウェアについて詳しく知りたい方は、[`TrustHosts`ミドルウェアのドキュメント](/docs/{{version}}/requests#configuring-trusted-hosts)を参照してください。

<a name="routing"></a>
## ルート

ユーザーがパスワードをリセットできるようにするためのサポートを適切に実装するには、ルートをいくつか定義する必要があります。最初に、ユーザーが自分の電子メールアドレスを介してパスワードリセットリンクをリクエストできるようにするためのルートのペアが必要になります。２つ目は、ユーザーが電子メールで送られてきたパスワードリセットリンクにアクセスしてパスワードリセットフォームに記入した後、実際にパスワードをリセットするためのルートが必要になります。

<a name="requesting-the-password-reset-link"></a>
### パスワードリセットリンクの要求

<a name="the-password-reset-link-request-form"></a>
#### パスワードリセットリンクリクエストフォーム

まず、パスワードリセットリンクをリクエストするために必要なルートを定義します。手始めに、パスワードリセットリンクリクエストフォームを使用してビューを返すルートを定義します。

    Route::get('/forgot-password', function () {
        return view('auth.forgot-password');
    })->middleware('guest')->name('password.request');

このルートによって返されるビューには、`email`フィールドを含むフォームが必要です。これにより、ユーザーは特定の電子メールアドレスのパスワードリセットリンクをリクエストできます。

<a name="password-reset-link-handling-the-form-submission"></a>
#### フォーム送信処理

次に、「パスワードを忘れた」ビューからのフォーム送信リクエストを処理するルートを定義します。このルートは、電子メールアドレスを検証し、対応するユーザーにパスワードリセットリクエストを送信する責任があります。

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
    })->middleware('guest')->name('password.email');

先に進む前に、このルートをさらに詳しく調べてみましょう。最初に、リクエストの`email`属性が検証されます。次に、Laravelの組み込みの「パスワードブローカ」(`Password`ファサードが返す)を使用して、パスワードリセットリンクをユーザーに送信します。パスワードブローカは、指定するフィールド(この場合はメールアドレス)でユーザーを取得し、Laravelの組み込み[通知システム](/docs/{{version}}/notifications)を介してユーザーにパスワードリセットリンクを送信します。

`sendResetLink`メソッドは「ステータス」スラッグを返します。このステータスは、リクエストのステータスに関するユーザーフレンドリーなメッセージを表示するために、Laravelの[多言語化](/docs/{{version}}/localization)ヘルパを使用して変換できます。パスワードリセットステータスの変換は、アプリケーションの`resources/lang/{lang}/passwords.php`言語ファイルによって決定されます。ステータススラッグの可能な各値のエントリは、`passwords`言語ファイル内にあります。

`Password`ファサードの`sendResetLink`メソッドを呼び出すときに、Laravelがアプリケーションのデータベースからユーザーレコードを取得する方法をどのように知っているのか疑問に思われるかもしれません。Laravelパスワードブローカは、認証システムの「ユーザープロバイダ」を利用してデータベースレコードを取得します。パスワードブローカが使用するユーザープロバイダは、`config/auth.php`設定ファイルの`passwords`設定配列内で設定します。カスタムユーザープロバイダの作成の詳細については、[認証ドキュメント](/docs/{{version}}/authentication#adding-custom-user-providers)を参照してください。

> {tip} パスワードのリセットを手動で実装する場合は、ビューの内容とルートを自分で定義する必要があります。必要なすべての認証および検証ロジックを含むスカフォールドが必要な場合は、[Laravelアプリケーションスターターキット](/docs/{{version}}/starter-kits)を確認してください。

<a name="resetting-the-password"></a>
### パスワードのリセット

<a name="the-password-reset-form"></a>
#### パスワードリセットフォーム

次に、電子メールで送信されたパスワードリセットリンクをユーザーがクリックして新しいパスワードを入力したときに、実際にパスワードをリセットするために必要なルートを定義します。まず、ユーザーがパスワードのリセットリンクをクリックしたときに表示されるパスワードのリセットフォームを表示するルートを定義しましょう。このルートは、後でパスワードリセットリクエストを確認するために使用する`token`パラメータを受け取ります。

    Route::get('/reset-password/{token}', function ($token) {
        return view('auth.reset-password', ['token' => $token]);
    })->middleware('guest')->name('password.reset');

このルートが返すビューにより、`email`フィールド、`password`フィールド、`password_confirmation`フィールド、および非表示の`token`フィールドを含むフォームを表示します。これにはルートが受け取る秘密の`$token`の値が含まれている必要があります。

<a name="password-reset-handling-the-form-submission"></a>
#### フォーム送信の処理

もちろん、パスワードリセットフォームの送信を実際に処理するためルートを定義する必要もあります。このルートは、受信リクエストのバリデーションとデータベース内のユーザーのパスワードの更新を担当します。

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
            function ($user, $password) {
                $user->forceFill([
                    'password' => Hash::make($password)
                ])->setRememberToken(Str::random(60));

                $user->save();

                event(new PasswordReset($user));
            }
        );

        return $status === Password::PASSWORD_RESET
                    ? redirect()->route('login')->with('status', __($status))
                    : back()->withErrors(['email' => [__($status)]]);
    })->middleware('guest')->name('password.update');

先に進む前に、このルートをさらに詳しく調べてみましょう。最初に、リクエストの`token`、`email`、および`password`属性がバリデーションされます。次に、Laravelの組み込みの「パスワードブローカ」(`Password`ファサードが返す)を使用して、パスワードリセットリクエストの資格情報を検証します。

パスワードブローカに与えられたトークン、電子メールアドレス、およびパスワードが有効である場合、`reset`メソッドに渡されたクロージャが呼び出されます。ユーザーインスタンスとパスワードリセットフォームに提供された平文テキストのパスワードを受け取るこのクロージャ内で、データベース内のユーザーのパスワードを更新します。

`reset`メソッドは「ステータス」スラッグを返します。このステータスは、リクエストのステータスに関するユーザーフレンドリーなメッセージを表示するために、Laravelの[多言語化](/docs/{{version}}/localization)ヘルパを使用して変換できます。パスワードリセットステータスの変換は、アプリケーションの`resources/lang/{lang}/passwords.php`言語ファイルによって決定されます。ステータススラッグの各値のエントリは、`passwords`言語ファイル内にあります。

先に進む前に、`Password`ファサードの`reset`メソッドを呼び出すときに、Laravelがアプリケーションのデータベースからユーザーレコードを取得する方法をどのように知っているのか疑問に思われるかもしれません。Laravelパスワードブローカーは、認証システムの「ユーザープロバイダ」を利用してデータベースレコードを取得します。パスワードブローカが使用するユーザープロバイダは、`config/auth.php`設定ファイルの`passwords`設定配列内で設定しています。カスタムユーザープロバイダの作成の詳細については、[認証ドキュメント](/docs/{{version}}/authentication#adding-custom-user-providers)を参照してください。

<a name="password-customization"></a>
## カスタマイズ

<a name="reset-link-customization"></a>
#### リセットリンクのカスタマイズ

`ResetPassword`通知クラスが提供する`createUrlUsing`メソッドを使用して、パスワードリセットリンクURLをカスタマイズできます。このメソッドは、通知を受信して​​いるユーザーインスタンスとパスワードリセットリンクトークンを受信するクロージャを受け入れます。通常、このメソッドは、`App\Providers\AuthServiceProvider`サービスプロバイダの`boot`メソッドから呼び出す必要があります。

    use Illuminate\Auth\Notifications\ResetPassword;

    /**
     * 全認証／承認サービスの登録
     *
     * @return void
     */
    public function boot()
    {
        $this->registerPolicies();

        ResetPassword::createUrlUsing(function ($user, string $token) {
            return 'https://example.com/reset-password?token='.$token;
        });
    }

<a name="reset-email-customization"></a>
#### リセットメールカスタマイズ

パスワードリセットリンクをユーザーに送信するために使用する通知クラスは簡単に変更できます。それには、`App\Models\User`モデルの`sendPasswordResetNotification`メソッドをオーバーライドします。このメソッド内で、自分で作成した[通知クラス](/docs/{{version}}/notifys)を使用して通知を送信できます。パスワードリセット`$token`は、メソッドが受け取る最初の引数です。この`$token`を使用して、パスワードリセットURLを作成し、ユーザーに通知を送信します。

    use App\Notifications\ResetPasswordNotification;

    /**
     * パスワードリセット通知をユーザーに送信
     *
     * @param  string  $token
     * @return void
     */
    public function sendPasswordResetNotification($token)
    {
        $url = 'https://example.com/reset-password?token='.$token;

        $this->notify(new ResetPasswordNotification($url));
    }
