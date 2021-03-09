# 暗号化

- [イントロダクション](#introduction)
- [設定](#configuration)
- [エンクリプタの使用](#using-the-encrypter)

<a name="introduction"></a>
## イントロダクション

Laravelの暗号化サービスは、AES-256およびAES-128暗号化を使用してOpenSSLを介してテキストを暗号化および復号化するためのシンプルで便利なインターフェイスを提供します。Laravelの暗号化された値はすべて、メッセージ認証コード(MAC)を使用して署名されているため、暗号化された値の基になる値を変更したり改ざんしたりすることはできません。

<a name="configuration"></a>
## 設定

Laravelの暗号化を使用する前に、`config/app.php`設定ファイルで`key`設定オプションを設定する必要があります。この設定値は、`APP_KEY`環境変数が反映されます。`php artisan key:generate`コマンドを使用してこの変数の値を生成する必要があります。これは、`key:generate`コマンドがPHPの安全なランダムバイトジェネレーターを使用して、アプリケーションの暗号的に安全なキーを構築するためです。通常、`APP_KEY`環境変数の値は、[Laravelのインストール](/docs/{{version}}/インストール)中に生成されます。

<a name="using-the-encrypter"></a>
## エンクリプタの使用

<a name="encrypting-a-value"></a>
#### 値の暗号化

`Crypt`ファサードが提供する`encryptString`メソッドを使用して値を暗号化できます。暗号化された値はすべて、OpenSSLとAES-256-CBC暗号を使用して暗号化されます。さらに、暗号化されたすべての値は、メッセージ認証コード(MAC)で署名されます。統合されたメッセージ認証コードは、悪意のあるユーザーにより改ざんされた値の復号化を防ぎます。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Models\User;
    use Illuminate\Http\Request;
    use Illuminate\Support\Facades\Crypt;

    class DigitalOceanTokenController extends Controller
    {
        /**
         * ユーザーのDigitalOceanAPIトークンを保存
         *
         * @param  \Illuminate\Http\Request  $request
         * @return \Illuminate\Http\Response
         */
        public function storeSecret(Request $request)
        {
            $request->user()->fill([
                'token' => Crypt::encryptString($request->token),
            ])->save();
        }
    }

<a name="decrypting-a-value"></a>
#### 値の復号

`Crypt`ファサードが提供する`decryptString`メソッドを使用して値を復号化できます。メッセージ認証コードが無効な場合など、値を適切に復号化できない場合、`Illuminate\Contracts\Encryption\DecryptException`を投げます。

    use Illuminate\Contracts\Encryption\DecryptException;
    use Illuminate\Support\Facades\Crypt;

    try {
        $decrypted = Crypt::decryptString($encryptedValue);
    } catch (DecryptException $e) {
        //
    }
