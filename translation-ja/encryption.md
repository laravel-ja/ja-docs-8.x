# 暗号化

- [イントロダクション](#introduction)
- [設定](#configuration)
- [エンクリプタの使用](#using-the-encrypter)

<a name="introduction"></a>
## イントロダクション

Laravelのエンクリプタ(encrypter)はOpenSSLを使い、AES-256とAES-128暗号化を提供しています。Laravelに組み込まれている暗号化機能を使用し、「自前」の暗号化アルゴリズムに走らないことを強く推奨します。Laravelの全暗号化済み値は、メッセージ認証コード(MAC)を使用し署名され、一度暗号化されると値を変更できません。

<a name="configuration"></a>
## 設定

Laravelのエンクリプタを使用する準備として、`config/app.php`設定ファイルの`key`オプションをセットしてください。`php artisan key:generate`コマンドを使用し、このキーを生成すべきです。このArtisanコマンドはPHPの安全なランダムバイトジェネレータを使用し、キーを作成します。この値が確実に指定されていないと、Laravelにより暗号化された値は、すべて安全ではありません。

<a name="using-the-encrypter"></a>
## エンクリプタの使用

#### 値の暗号化

`Crypt`ファサードの`encryptString`ヘルパを使用し、値を暗号化できます。OpenSSLと`AES-256-CBC`アルゴリズムが使用され、すべての値は暗号化されます。さらに、全暗号化済み値はメッセージ認証コード(MAC)を使用し署名されますので、暗号化済み値の変更は感知されます。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Models\User;
    use Illuminate\Http\Request;
    use Illuminate\Support\Facades\Crypt;

    class UserController extends Controller
    {
        /**
         * ユーザーの秘密のメッセージを保存
         *
         * @param  Request  $request
         * @param  int  $id
         * @return Response
         */
        public function storeSecret(Request $request, $id)
        {
            $user = User::findOrFail($id);

            $user->fill([
                'secret' => Crypt::encryptString($request->secret),
            ])->save();
        }
    }

#### 値の復号

`Crypt`ファサードの`decryptString`ヘルパにより、値を復号できます。MACが無効な場合など、その値が正しくない時は`Illuminate\Contracts\Encryption\DecryptException`が投げられます。

    use Illuminate\Contracts\Encryption\DecryptException;
    use Illuminate\Support\Facades\Crypt;

    try {
        $decrypted = Crypt::decryptString($encryptedValue);
    } catch (DecryptException $e) {
        //
    }
