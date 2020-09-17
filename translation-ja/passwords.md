# パスワードリセット

- [イントロダクション](#introduction)
- [データベースの検討事項](#resetting-database)
- [ルート定義](#resetting-routing)
- [ビュー](#resetting-views)
- [カスタマイズ](#password-customization)

<a name="introduction"></a>
## イントロダクション

大抵のWebアプリケーションはパスワードをリセットする手段を提供しています。それぞれのアプリケーションで何度も実装する代わりに、Laravelはパスワードリマインダを送り、パスワードリセットを実行する便利な方法を提供しています。

> {note} Laravelのパスワードリセット機能を使用開始する前に、ユーザーが`Illuminate\Notifications\Notifiable`トレイトを使用していることを確認してください。

#### てっとり早く始める

早速使い始めたいですか？真新しくインストールしたLaravelパッケージへ、[Laravel Jetstream](https://jetstream.laravel.com)をインストールしてください。データベースをマイグレーションしたら、`/register`へブラウザでアクセスするか、アプリケーションに割り付けた別のURLへアクセスしましょう。Jetstreamはパスワードの再設定を含めた認証システム全体のスカフォールディングを面倒見ます！

<a name="resetting-database"></a>
## データベースの検討事項

利用を始めるには、`App\Models\User`モデルが`Illuminate\Contracts\Auth\CanResetPassword`契約を実装しているか確認してください。フレームワークに用意されている`App\Models\User`モデルでは、すでにこのインターフェイスが実装されています。`Illuminate\Auth\Passwords\CanResetPassword`トレイトで、このインターフェイスで実装する必要のあるメソッドが定義されています。

#### リセットトークンテーブルマイグレーションの生成

次にパスワードリセットトークンを保存しておくためのテーブルを作成します。このテーブルのマイグレーションはデフォルトインストールしたLaravelに含まれています。そのため、パスワードリセットトークン・データベーステーブルを生成するには、`migrate`コマンドを使用してください。

    php artisan migrate

<a name="resetting-routing"></a>
## ルート定義

パスワードリセットに必要な全ルートは[Laravel Jetstream](https://jetstream.laravel.com)に入っています。Jetstreamのインストール方法は、公式の[Jetstreamドキュメント](https://jetstream.laravel.com)をご覧ください。

<a name="resetting-views"></a>
## ビュー

パスワードリセットに必要な全ビューは[Laravel Jetstream](https://jetstream.laravel.com)に入っています。Jetstreamのインストール方法は、公式の[Jetstreamドキュメント](https://jetstream.laravel.com)をご覧ください

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
