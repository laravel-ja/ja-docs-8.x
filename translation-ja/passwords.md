# パスワードリセット

- [イントロダクション](#introduction)
- [データベースの検討事項](#resetting-database)
- [ルート定義](#resetting-routing)
- [ビュー](#resetting-views)
- [パスワードリセット後の処理](#after-resetting-passwords)
- [カスタマイズ](#password-customization)

<a name="introduction"></a>
## イントロダクション

> {tip} **素早く始めたいですか？** 真新しくインストールしたLaravelアプリケーションに`laravel/ui` Composerパッケージをインストールし、`php artisan ui vue --auth`を実行してください。データベースをマイグレーションし、`http://your-app.test/register`かアプリケーションに割り付けた別のURLをブラウザでアクセスしましょう。これらのコマンドがパスワードリセットを含めた、認証システム全体のスカフォールドの面倒見ます。

大抵のWebアプリケーションはパスワードをリセットする手段を提供しています。それぞれのアプリケーションで何度も実装する代わりに、Laravelはパスワードリマインダを送り、パスワードリセットを実行する便利な方法を提供しています。

> {note} Laravelのパスワードリセット機能を使用開始する前に、ユーザーが`Illuminate\Notifications\Notifiable`トレイトを使用していることを確認してください。

<a name="resetting-database"></a>
## データベースの検討事項

To get started, verify that your `App\Models\User` model implements the `Illuminate\Contracts\Auth\CanResetPassword` contract. The `App\Models\User` model included with the framework already implements this interface, and uses the `Illuminate\Auth\Passwords\CanResetPassword` trait to include the methods needed to implement the interface.

#### リセットトークンテーブルマイグレーションの生成

次にパスワードリセットトークンを保存しておくためのテーブルを作成します。このテーブルのマイグレーションは`laravel/ui` Composerパッケージに含まれており、パスワードリセットトークン・データベーステーブルを生成するには、`migrate`コマンドを使用してください。

    composer require laravel/ui

    php artisan migrate

<a name="resetting-routing"></a>
## ルート定義

Laravelはパスワードリセットリンクのメールを送信し、ユーザーのパスワードをリセットするために必要なロジックを全部含んでいる、`Auth\ForgotPasswordController`と`Auth\ResetPasswordController`を用意しています。パスワードリセットに必要な全ルートは、`laravel/ui` Composerパッケージを使用して生成できます。

    composer require laravel/ui

    php artisan ui vue --auth

<a name="resetting-views"></a>
## ビュー

パスワードリセットに必要なすべてのビューは、`laravel/ui` Composerパッケージを使用して生成できます。

    composer require laravel/ui

    php artisan ui vue --auth

ビューは`resources/views/auth/passwords`の中に設置されます。アプリケーションの必要に合わせ、自由に変更してください。

<a name="after-resetting-passwords"></a>
## パスワードリセット後の処理

ユーザーのパスワードをリセットするルートとビューを定義できたら、ブラウザーで`/password/reset`のルートへアクセスできます。フレームワークに含まれている `ForgotPasswordController`は、パスワードリセットリンクを含むメールを送信するロジックを含んでいます。一方の`ResetPasswordController`はユーザーパスワードのリセットロジックを含んでいます。

パスワードがリセットされたら、そのユーザーは自動的にアプリケーションにログインされ、`/home`へリダイレクトされます。パスワードリセット後のリダイレクト先をカスタマイズするには、`ResetPasswordController`の`redirectTo`プロパティを定義してください。

    protected $redirectTo = '/dashboard';

> {note} デフォルトでパスワードリセットトークンは、一時間有効です。これは、`config/auth.php`ファイルの`expire`オプションにより変更できます。

<a name="password-customization"></a>
## カスタマイズ

#### 認証ガードのカスタマイズ

`auth.php`設定ファイルにより、複数のユーザーテーブルごとに認証の振る舞いを定義するために使用する、「ガード」をそれぞれ設定できます。用意されている`ResetPasswordController`コントローラの`guard`メソッドをオーバーライドすることにより、選択したガードを使用するようにカスタマイズできます。このメソッドは、ガードインスタンスを返す必要があります。

    use Illuminate\Support\Facades\Auth;

    /**
     * パスワードリセットの間、使用されるガードの取得
     *
     * @return \Illuminate\Contracts\Auth\StatefulGuard
     */
    protected function guard()
    {
        return Auth::guard('guard-name');
    }

#### パスワードブローカーのカスタマイズ

複数のユーザーテーブルに対するパスワードをリセットするために使用する、別々のパスワード「ブローカー」を`auth.php`ファイルで設定できます。用意されている`ForgotPasswordController`と`ResetPasswordController`の`broker`メソッドをオーバーライドし、選んだブローカーを使用するようにカスタマイズができます。

    use Illuminate\Support\Facades\Password;

    /**
     *パスワードリセットに使われるブローカの取得
     *
     * @return PasswordBroker
     */
    public function broker()
    {
        return Password::broker('name');
    }

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
