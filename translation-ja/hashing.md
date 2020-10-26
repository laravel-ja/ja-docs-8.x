# ハッシュ

- [イントロダクション](#introduction)
- [設定](#configuration)
- [基本的な使用法](#basic-usage)

<a name="introduction"></a>
## イントロダクション

Laravelの`Hash` [ファサード](/docs/{{version}}/facades)は、ユーザーパスワードを保存するための安全なBcryptおよびArgon2ハッシュを提供します。[Laravel Jetstream](https://jetstream.laravel.com)（[和訳](/jetstream/1.0/ja/introduction.html)）認証スカフォールドを使用している場合、デフォルトでユーザー登録と認証にBcryptが使用されます。

> {tip} Bcryptは「ストレッチ回数」が調整できるのでパスワードのハッシュには良い選択肢です。つまりハードウェアのパワーを上げればハッシュの生成時間を早くすることができます。

<a name="configuration"></a>
## 設定

アプリケーションのデフォルトハッシュドライバーは、`config/hashing.php`設定ファイルで指定します。現在、[Bcrypt](https://en.wikipedia.org/wiki/Bcrypt)および、[Argon2](https://en.wikipedia.org/wiki/Argon2)（Argon2iとArgon2id）の３ドライバーをサポートしています。

> {note} Argon2iドライバーはPHP7.2.0以上、Argon2idドライバーはPHP7.3.0以上が必要です。

<a name="basic-usage"></a>
## 基本的な使用法

`Hash`ファサードの`make`メソッドを呼び出し、パスワードをハッシュできます。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use Illuminate\Http\Request;
    use Illuminate\Support\Facades\Hash;

    class UpdatePasswordController extends Controller
    {
        /**
         * ユーザーパスワードを更新
         *
         * @param  Request  $request
         * @return Response
         */
        public function update(Request $request)
        {
            // 新しいパスワードの長さのバリデーション…

            $request->user()->fill([
                'password' => Hash::make($request->newPassword)
            ])->save();
        }
    }

<a name="adjusting-the-bcrypt-work-factor"></a>
#### BcryptのWork Factorの調整

Bcryptアルゴリズムを使用する場合、`make`メソッドで`rounds`オプションを使用することにより、アルゴリズムのwork factorを管理できます。しかし、ほとんどのアプリケーションではデフォルト値で十分でしょう。

    $hashed = Hash::make('password', [
        'rounds' => 12,
    ]);

<a name="adjusting-the-argon2-work-factor"></a>
#### Argon2のWork Factorの調整

Argon2アルゴリズムを使用する場合、`memory`と`time`、`threads`オプションを指定することにより、アルゴリズムのwork factorを管理できます。しかし、ほとんどのアプリケーションではデフォルト値で十分でしょう。

    $hashed = Hash::make('password', [
        'memory' => 1024,
        'time' => 2,
        'threads' => 2,
    ]);

> {tip} これらのオプションの詳細情報は、[PHP公式ドキュメント](https://secure.php.net/manual/ja/function.password-hash.php)をご覧ください。

<a name="verifying-a-password-against-a-hash"></a>
#### パスワードとハッシュ値の比較

`check`メソッドにより指定した平文文字列と指定されたハッシュ値を比較確認できます。

    if (Hash::check('plain-text', $hashedPassword)) {
        // パスワード一致
    }

<a name="checking-if-a-password-needs-to-be-rehashed"></a>
#### パスワードの再ハッシュが必要か確認

パスワードがハシュされてからハッシャーのストレッチ回数が変更されているかを調べるには、`needsRehash`メソッドを使います。

    if (Hash::needsRehash($hashed)) {
        $hashed = Hash::make('plain-text');
    }
