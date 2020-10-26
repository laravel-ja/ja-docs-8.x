# エラー処理

- [イントロダクション](#introduction)
- [設定](#configuration)
- [例外ハンドラ](#the-exception-handler)
    - [例外のレポート](#reporting-exceptions)
    - [例外のレンダー](#rendering-exceptions)
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
### 例外のレポート

例外はすべて、`App\Exceptions\Handler`クラスで処理されます。このクラスはカスタム例外レポーターとレンダラのコールバックを登録するための`register`メソッドを持っています。このコンセプトを詳細に確認していきましょう。例外レポーターは例外をログするか、[Flare](https://flareapp.io)や[BugSnag](https://bugsnag.com)、[Sentry](https://github.com/getsentry/sentry-laravel)のような外部サービスへ送信するために使います。デフォルトでは[ログ](/docs/{{version}}/logging)設定に基づき、例外をログします。しかし、お望みであれば自由に例外をログできます。

たとえば異なった例外を別々の方法でレポートする必要がある場合、`reportable`メソッドを使用して、特定のタイプの例外を報告する必要があるときに実行するクロージャを登録できます。Laravelはクロージャのタイプヒントを調べ、クロージャが報告する例外のタイプを推測します。

    use App\Exceptions\CustomException;

    /**
     * アプリケーションの例外処理コールバックの登録
     *
     * @return void
     */
    public function register()
    {
        $this->reportable(function (CustomException $e) {
            //
        });
    }

`reportable`メソッドを使用しカスタム例外レポートコールバックを登録する場合でも、Laravelはアプリケーションのデフォルトログ設定を使い例外をログします。デフォルトログスタックへその例外が伝わるのを止めたい場合は、レポートコールバックの定義時に`stop`メソッドを使用してください。

    $this->reportable(function (CustomException $e) {
        //
    })->stop();

> {tip} 指定した例外に対する例外レポートをカスタマイズするには、[reportable例外](/docs/{{version}}/errors#renderable-exceptions)を使用することも一考してください。

<a name="global-log-context"></a>
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

<a name="the-report-helper"></a>
#### `report`ヘルパ

例外のレポートは必要だが、現在のリクエストの処理は続行したい場合もあります。`report`ヘルパ関数は、エラーページをレンダリングせずに、例外ハンドラを使用し簡単にレポートできます。

    public function isValid($value)
    {
        try {
            // 値の確認…
        } catch (Throwable $e) {
            report($e);

            return false;
        }
    }

<a name="ignoring-exceptions-by-type"></a>
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
### 例外のレンダー

Laravelの例外ハンドラはデフォルトで例外をHTTPレスポンスに変換します。しかし、自由に特定のタイプの例外をレンダリングするカスタムクロージャを登録することもできます。例外ハンドラの`renderable`メソッドにより実現します。Laravelはクロージャのタイプヒントを調べ、クロージャがレンダーする例外のタイプを推測します。

    use App\Exceptions\CustomException;

    /**
     * アプリケーションの例外処理コールバックの登録
     *
     * @return void
     */
    public function register()
    {
        $this->renderable(function (CustomException $e, $request) {
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

明確な条件と一致する場合のみ実行されるレポートのカスタムロジックが例外に含まれている場合、デフォルトの例外処理の設定を使用し、その例外をレポートするようにLaravelへ指示する必要があるでしょう。そのためには例外の`report`メソッドから`false`を返してください。

    /**
     * 例外のレポート
     *
     * @return bool|void
     */
    public function report()
    {
        // 例外がカスタムレポートする必要があるかを決める

        return false;
    }

> {tip} `report`メソッドに必要な依存をタイプヒントで指定することで、Laravelの[サービスコンテナ](/docs/{{version}}/container)によりメソッドへ、自動的に依存注入されます。

<a name="http-exceptions"></a>
## HTTP例外

例外の中にはサーバでのHTTPエラーコードを表しているものがあります。たとえば「ページが見つかりません」エラー(404)や「未認証エラー」(401)、開発者が生成した500エラーなどです。アプリケーションのどこからでもこの種のレスポンスを生成するには、abortヘルパを使用します。

    abort(404);

<a name="custom-http-error-pages"></a>
### カスタムHTTPエラーページ

さまざまなHTTPステータスコードごとに、Laravelはカスタムエラーページを簡単に返せます。たとえば404 HTTPステータスコードに対してカスタムエラーページを返したければ、`resources/views/errors/404.blade.php`を作成してください。このファイルはアプリケーションで起こされる全404エラーに対し動作します。ビューはこのディレクトリに置かれ、対応するHTTPコードと一致した名前にしなくてはなりません。`abort`ヘルパが生成する`HttpException`インスタンスは、`$exception`変数として渡されます。

    <h2>{{ $exception->getMessage() }}</h2>

Laravelのエラーページテンプレートは、`vendor:publish` Artisanコマンドでリソース公開できます。テンプレートをリソース公開したら、好みのようにカスタマイズできます。

    php artisan vendor:publish --tag=laravel-errors
