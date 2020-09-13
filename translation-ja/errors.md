# エラー処理

- [イントロダクション](#introduction)
- [設定](#configuration)
- [例外ハンドラ](#the-exception-handler)
    - [Reporting Exceptions](#reporting-exceptions)
    - [Rendering Exceptions](#rendering-exceptions)
    - [Reportable／Renderable例外](#renderable-exceptions)
- [HTTP例外](#http-exceptions)
    - [カスタムHTTPエラーページ](#custom-http-error-pages)

<a name="introduction"></a>
## イントロダクション

新しいLaravelプロジェクトを開始する時点で、エラーと例外の処理はあらかじめ設定済みです。`App\Exceptions\Handler`クラスはアプリケーションで発生する全例外をログし、ユーザーへ表示するためのクラスです。このドキュメントでは、このクラスの詳細を確認します。

<a name="configuration"></a>
## 設定

アプリケーションエラー発生時にユーザーに対し表示する詳細の表示量は、`config/app.php`設定ファイルの`debug`設定オプションで決定します。デフォルト状態でこの設定オプションは、`.env`ファイルで指定される`APP_DEBUG`環境変数の値を反映します。

local環境では`APP_DEBUG`環境変数を`true`に設定すべきでしょう。実働環境ではこの値をいつも`false`にすべきです。実働環境でこの値を`true`にしてしまうと、アプリケーションのエンドユーザーへ、セキュリティリスクになりえる設定情報を表示するリスクを犯すことになります。

<a name="the-exception-handler"></a>
## 例外ハンドラ

<a name="reporting-exceptions"></a>
### Reporting Exceptions

All exceptions are handled by the `App\Exceptions\Handler` class. This class contains a `register` method where you may register custom exception reporter and renderer callbacks. We'll examine each of these concepts in detail. Exception reporting is used to log exceptions or send them to an external service like [Flare](https://flareapp.io), [Bugsnag](https://bugsnag.com) or [Sentry](https://github.com/getsentry/sentry-laravel). By default, exceptions will be logged based on your [logging](/docs/{{version}}/logging) configuration. However, you are free to log exceptions however you wish.

For example, if you need to report different types of exceptions in different ways, you may use the the `reportable` method to register a Closure that should be executed when an exception of a given type needs to be reported. Laravel will deduce what type of exception the Closure reports by examining the type-hint of the Closure:

    use App\Exceptions\CustomException;

    /**
     * Register the exception handling callbacks for the application.
     *
     * @return void
     */
    public function register()
    {
        $this->reportable(function (CustomException $e) {
            //
        });
    }

When you register a custom exception reporting callback using the `reportable` method, Laravel will still log the exception using the default logging configuration for the application. If you wish to stop the propagation of the exception to the default logging stack, you may use the `stop` method when defining your reporting callback:

    $this->reportable(function (CustomException $e) {
        //
    })->stop();

> {tip} To customize the exception reporting for a given exception, you may also consider using [reportable exceptions](/docs/{{version}}/errors#renderable-exceptions)

#### グローバルログコンテキスト

Laravelは可能である場合、文脈上のデータとしてすべての例外ログへ、現在のユーザーのIDを自動的に追加します。アプリケーションの`App\Exceptions\Handler`クラスにある、`context`メソッドをオーバーライドすることにより、独自のグローバルコンテキストデータを定義できます。この情報は、アプリケーションにより書き出されるすべての例外ログメッセージに含まれます。

    /**
     * ログのデフォルトコンテキスト変数の取得
     *
     * @return array
     */
    protected function context()
    {
        return array_merge(parent::context(), [
            'foo' => 'bar',
        ]);
    }

#### `report`ヘルパ

Sometimes you may need to report an exception but continue handling the current request. The `report` helper function allows you to quickly report an exception using your exception handler without rendering an error page:

    public function isValid($value)
    {
        try {
            // 値の確認…
        } catch (Throwable $e) {
            report($e);

            return false;
        }
    }

#### タイプによる例外の無視

例外ハンドラの`$dontReport`プロパティは、ログしない例外のタイプの配列で構成します。たとえば、404エラー例外と同様に、他のタイプの例外もログしたくない場合です。必要に応じてこの配列へ、他の例外を付け加えてください。

    /**
     * レポートしない例外のリスト
     *
     * @var array
     */
    protected $dontReport = [
        \Illuminate\Auth\AuthenticationException::class,
        \Illuminate\Auth\Access\AuthorizationException::class,
        \Symfony\Component\HttpKernel\Exception\HttpException::class,
        \Illuminate\Database\Eloquent\ModelNotFoundException::class,
        \Illuminate\Validation\ValidationException::class,
    ];

<a name="rendering-exceptions"></a>
### Rendering Exceptions

By default, the Laravel exception handler will convert exceptions into an HTTP response for you. However, you are free to register a custom rendering Closure for exceptions of a given type. You may accomplish this via the `renderable` method of your exception handler. Laravel will deduce what type of exception the Closure renders by examining the type-hint of the Closure:

    use App\Exceptions\CustomException;

    /**
     * Register the exception handling callbacks for the application.
     *
     * @return void
     */
    public function register()
    {
        $this->renderable(function (CustomException $e) {
            return response()->view('errors.custom', [], 500);
        });
    }

<a name="renderable-exceptions"></a>
### Reportable／Renderable例外

例外ハンドラの中の`report`と`render`メソッドの中で、例外のタイプをチェックする代わりに、自身のカスタム例外で`report`と`render`メソッドを定義できます。これらのメソッドが存在すると、フレームワークにより自動的に呼び出されます。

    <?php

    namespace App\Exceptions;

    use Exception;

    class RenderException extends Exception
    {
        /**
         * 例外のレポート
         *
         * @return void
         */
        public function report()
        {
            //
        }

        /**
         * 例外をＨＴＴＰレスポンスへレンダー
         *
         * @param  \Illuminate\Http\Request  $request
         * @return \Illuminate\Http\Response
         */
        public function render($request)
        {
            return response(...);
        }
    }

If your exception contains custom reporting logic that only occurs when certain conditions are met, you may need to instruct Laravel to report the exception using the default exception handling configuration. To accomplish this, you may return `false` from the exception's `report` method:

    /**
     * Report the exception.
     *
     * @return bool|void
     */
    public function report()
    {
        // Determine if the exception needs custom reporting...

        return false;
    }

> {tip} `report`メソッドに必要な依存をタイプヒントで指定することで、Laravelの[サービスコンテナ](/docs/{{version}}/container)によりメソッドへ、自動的に依存注入されます。

<a name="http-exceptions"></a>
## HTTP例外

例外の中にはサーバでのHTTPエラーコードを表しているものがあります。たとえば「ページが見つかりません」エラー(404)や「未認証エラー」(401)、開発者が生成した500エラーなどです。アプリケーションのどこからでもこの種のレスポンスを生成するには、abortヘルパを使用します。

    abort(404);

`abort`ヘルパは即座に例外を発生させ、その例外は例外ハンドラによりレンダーされることになります。オプションとしてレスポンスのテキストを指定することもできます。

    abort(403, 'Unauthorized action.');

<a name="custom-http-error-pages"></a>
### カスタムHTTPエラーページ

さまざまなHTTPステータスコードごとに、Laravelはカスタムエラーページを簡単に返せます。たとえば404 HTTPステータスコードに対してカスタムエラーページを返したければ、`resources/views/errors/404.blade.php`を作成してください。このファイルはアプリケーションで起こされる全404エラーに対し動作します。ビューはこのディレクトリに置かれ、対応するHTTPコードと一致した名前にしなくてはなりません。`abort`ヘルパが生成する`HttpException`インスタンスは、`$exception`変数として渡されます。

    <h2>{{ $exception->getMessage() }}</h2>

Laravelのエラーページテンプレートは、`vendor:publish` Artisanコマンドでリソース公開できます。テンプレートをリソース公開したら、好みのようにカスタマイズできます。

    php artisan vendor:publish --tag=laravel-errors
