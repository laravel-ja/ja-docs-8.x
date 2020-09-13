# CSRF保護

- [イントロダクション](#csrf-introduction)
- [URIの除外](#csrf-excluding-uris)
- [X-CSRF-Token](#csrf-x-csrf-token)
- [X-XSRF-Token](#csrf-x-xsrf-token)

<a name="csrf-introduction"></a>
## イントロダクション

Laravelでは、[クロス・サイト・リクエスト・フォージェリ](https://ja.wikipedia.org/wiki/%E3%82%AF%E3%83%AD%E3%82%B9%E3%82%B5%E3%82%A4%E3%83%88%E3%83%AA%E3%82%AF%E3%82%A8%E3%82%B9%E3%83%88%E3%83%95%E3%82%A9%E3%83%BC%E3%82%B8%E3%82%A7%E3%83%AA)(CSRF)からアプリケーションを簡単に守れます。クロス・サイト・リクエスト・フォージェリは悪意のあるエクスプロイトの一種であり、信頼できるユーザーになり代わり、認められていないコマンドを実行します。

Laravelは、アプリケーションにより管理されているアクティブなユーザーの各セッションごとに、CSRF「トークン」を自動的に生成しています。このトークンを認証済みのユーザーが、実装にアプリケーションに対してリクエストを送信しているのかを確認するために利用します。

アプリケーションでHTMLフォームを定義する場合は常に、CSRF保護ミドルウェアがリクエストを検証できるように、隠しCSRFトークンフィールドをそのフォームへ含める必要があります。トークンを生成するには、`@csrf` Bladeディレクティブが使用できます。

    <form method="POST" action="/profile">
        @csrf
        ...
    </form>

`web`ミドルウェアグループに含まれている、`VerifyCsrfToken` [ミドルウェア](/docs/{{version}}/middleware)が、リクエスト中のトークンとセッションに保存されているトークンが一致するか、確認しています。

#### CSRFトークンとJavaScript

JacaScriptで駆動するアプリケーションを構築する場合、JavaScript HTTPライブラリーに対し、すべての送信リクエストへCSRFトークンを自動的に追加させると便利です。`resources/js/bootstrap.js`ファイルの中でデフォルトとして、Axios HTTPライブラリにより暗号化された`XSRF-TOKEN`クッキーの値を用い`X-XSRF-TOKEN`ヘッダを自動的に送信しています。このライブラリを使用しない場合、自身のアプリケーションでこの振る舞いを用意する必要があります。

<a name="csrf-excluding-uris"></a>
## URIの除外

一連のURIをCSRF保護より除外したい場合もあります。たとえば、[Stripe](https://stripe.com)を課金処理に採用しており、そのWebフックシステムを利用している時、LaravelのCSRF保護よりWebフック処理ルートを除外する必要があるでしょう。なぜならルートに送るべきCSRFトークンがどんなものか、Stripeは知らないからです。

通常、この種のルートは`RouteServiceProvider`が`routes/web.php`ファイル中の全ルートへ適用する、`web`ミドルウェアから外しておくべきです。しかし、`VerifyCsrfToken`ミドルウェアの`$except`プロパティへ、そうしたURIを追加することによっても、ルートを除外できます。

    <?php

    namespace App\Http\Middleware;

    use Illuminate\Foundation\Http\Middleware\VerifyCsrfToken as Middleware;

    class VerifyCsrfToken extends Middleware
    {
        /**
         * CSRFバリデーションから除外するURI
         *
         * @var array
         */
        protected $except = [
            'stripe/*',
            'http://example.com/foo/bar',
            'http://example.com/foo/*',
        ];
    }

> {tip} [テスト実行時](/docs/{{version}}/testing)には、自動的にCSRFミドルウェアは無効になります。

<a name="csrf-x-csrf-token"></a>
## X-CSRF-TOKEN

さらに追加でPOSTパラメーターとしてCSRFトークンを確認したい場合は、Laravelの`VerifyCsrfToken`ミドルウェアが`X-CSRF-TOKEN`リクエストヘッダもチェックします。たとえば、HTML中の`meta`タグにトークンを保存します。

    <meta name="csrf-token" content="{{ csrf_token() }}">

`meta`タグを作成したら、jQueryのようなライブラリーで、全リクエストヘッダにトークンを追加できます。この手法によりAJAXベースのアプリケーションにシンプルで便利なCSRF保護を提供できます。

    $.ajaxSetup({
        headers: {
            'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
        }
    });

<a name="csrf-x-xsrf-token"></a>
## X-XSRF-TOKEN

LaravelはCSRFトークンをフレームワークにより生成され、リクエストに含まれる`XSRF-TOKEN`暗号化クッキーの中に保存します。このクッキーの値を`X-XSRF-TOKEN`リクエストヘッダにセットすることが可能です。

いくつかのJavaScriptフレームワークや、AngularとAxiosのようなライブラリーでは、自動的に値をsame-originリクエストの`X-XSRF-TOKEN`ヘッダに設定するため、利便性を主な目的としてこのクッキーを送ります。

> {tip} 自動的に送信するために、`resources/js/bootstrap.js`ファイルはデフォルトでAxios HTTPライブラリを含んでいます。
