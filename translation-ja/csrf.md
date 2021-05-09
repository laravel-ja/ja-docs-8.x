# CSRF保護

- [イントロダクション](#csrf-introduction)
- [CSRFリクエストの防止](#preventing-csrf-requests)
    - [除外URI](#csrf-excluding-uris)
- [X-CSRF-Token](#csrf-x-csrf-token)
- [X-XSRF-Token](#csrf-x-xsrf-token)

<a name="csrf-introduction"></a>
## イントロダクション

クロスサイトリクエストフォージェリは、認証済みユーザーに代わって不正なコマンドを実行する、悪意のある攻撃の一種です。幸いに、Laravelを使用すれば、[クロスサイトリクエストフォージェリ](https://en.wikipedia.org/wiki/Cross-site_request_forgery)（CSRF）攻撃からアプリケーションを簡単に保護できます。

<a name="csrf-explanation"></a>
#### 脆弱性の説明

あなたがクロスサイトリクエストフォージェリを知らない場合に備え、この脆弱性を悪用する方法の例を説明しましょう。アプリケーションに、認証済みユーザーの電子メールアドレスを変更するための`POST`リクエストを受け入れる`/user/email`ルートがあるとします。ほとんどの場合、このルートでは、`email`入力フィールドにユーザーが使用を開始したいメールアドレスが含まれている必要があります。

CSRF保護がないと、悪意のあるWebサイトがアプリケーションの`/user/email`ルートを指すHTMLフォームを作成し、悪意のあるユーザー自身の電子メールアドレスを送信する可能性があります。

    <form action="https://your-application.com/user/email" method="POST">
        <input type="email" value="malicious-email@example.com">
    </form>

    <script>
        document.forms[0].submit();
    </script>

悪意のあるWebサイトがページの読み込み時にフォームを自動的に送信する場合、悪意のあるユーザーは、アプリケーションの疑いを持たないユーザーを誘惑してWebサイトにアクセスするだけで、あなたのアプリケーションの電子メールアドレスが変更されます。

この脆弱性を防ぐには、すべての受信`POST`、`PUT`、`PATCH`、`DELETE`リクエストを調べて、悪意のあるアプリケーションがアクセスできないシークレットセッション値を確認する必要があります。

<a name="preventing-csrf-requests"></a>
## CSRFリクエストの防止

Laravelは、アプリケーションによって管理されているアクティブな[ユーザーセッション](/docs/{{version}}/session)ごとにCSRF「トークン」を自動的に生成します。このトークンは、認証済みユーザーが実際にアプリケーションへリクエストを行っているユーザーであることを確認するために使用されます。このトークンはユーザーのセッションに保存され、セッションが再生成されるたびに変更されるため、悪意のあるアプリケーションはこのトークンへアクセスできません。

現在のセッションのCSRFトークンには、リクエストのセッションまたは`csrf_token`ヘルパ関数を介してアクセスできます。

    use Illuminate\Http\Request;

    Route::get('/token', function (Request $request) {
        $token = $request->session()->token();

        $token = csrf_token();

        // ...
    });

アプリケーションで"POST"、"PUT"、"PATCH"、"DELETE" HTMLフォームを定義するときはいつでも、CSRF保護ミドルウェアがリクエストを検証できるように、フォームに非表示のCSRF`_token`フィールドを含める必要があります。便利なように、`@csrf` Bladeディレクティブを使用して、非表示のトークン入力フィールドを生成できます。

    <form method="POST" action="/profile">
        @csrf

        <!-- Equivalent to... -->
        <input type="hidden" name="_token" value="{{ csrf_token() }}" />
    </form>

`web`ミドルウェアグループへデフォルトで含まれている`App\Http\Middleware\VerificationCsrfToken`[ミドルウェア](/docs/{{version}}/ミドルウェア)は、リクエスト入力のトークンがセッションに保存されたトークンと一致するかを自動的に検証します。この２トークンが一致すれば、認証済みユーザーがリクエストを開始したことがわかります。

<a name="csrf-tokens-and-spas"></a>
### CSRFトークンとSPA

LaravelをAPIバックエンドとして利用するSPAを構築している場合は、APIによる認証とCSRFの脆弱性からの保護について、[Laravel　Sanctumドキュメント](/docs/{{version}}/sanctum)を参照してください。

<a name="csrf-excluding-uris"></a>
### CSRF保護から除外するURI

場合により、一連のURIをCSRF保護から除外したいことが起きます。たとえば、[Stripe](https://stripe.com)を使用して支払いを処理し、そのWebhookシステムを利用している場合、StripeはどのCSRFトークンをルートへ送るのか認識していないため、Stripe　WebフックハンドラルートをCSRF保護から除外する必要があります。

通常、これらの種類のルートは`routes/web.php`ファイル中で、`App\Providers\RouteServiceProvider`がすべてのルートへ適用する`web`ミドルウェアグループの外側に配置する必要があります。ただし、`VerifyCsrfToken`ミドルウェアの`$except`プロパティにURIを追加してルートを除外することもできます。

    <?php

    namespace App\Http\Middleware;

    use Illuminate\Foundation\Http\Middleware\VerifyCsrfToken as Middleware;

    class VerifyCsrfToken extends Middleware
    {
        /**
         * CSRF検証から除外するURI
         *
         * @var array
         */
        protected $except = [
            'stripe/*',
            'http://example.com/foo/bar',
            'http://example.com/foo/*',
        ];
    }

> {tip} 利便性向上のため、[テスト実行](/docs/{{version}}/tests)時に、CSRFミドルウェアはすべてのルートで自動的に無効になります。

<a name="csrf-x-csrf-token"></a>
## X-CSRF-TOKEN

POSTパラメータとしてCSRFトークンをチェックすることに加えて、`App\Http\Middleware\VerifyCsrfToken`ミドルウェアは`X-CSRF-TOKEN`リクエストヘッダもチェックします。たとえば、トークンはHTMLの`meta`タグに含められます。

    <meta name="csrf-token" content="{{ csrf_token() }}">

次にjQueryなどのライブラリで、すべてのリクエストヘッダへトークンを自動的に追加するように指示できます。これにより、レガシーJavaScriptテクノロジーを使用して、AJAXベースのアプリケーションにシンプルで便利なCSRF保護を提供しています。

    $.ajaxSetup({
        headers: {
            'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
        }
    });

<a name="csrf-x-xsrf-token"></a>
## X-XSRF-TOKEN

Laravelはフレームワークが生成する各レスポンスに含める`XSRF-TOKEN`暗号化クッキーへ、現在のCSRFトークンを保存します。クッキー値を使用して、`X-XSRF-TOKEN`リクエストヘッダを設定できます。

AngularやAxiosなどの一部のJavaScriptフレームワークとライブラリは、同じオリジンのリクエストでその値を自動的に`X-XSRF-TOKEN`ヘッダへ配置するため、このクッキーは主に開発者の利便性のために送信されます。

> {tip} デフォルトで、`resources/js/bootstrap.js`ファイルにはAxios HTTPライブラリが含まれており、`X-XSRF-TOKEN`ヘッダを自動的に送信します。
