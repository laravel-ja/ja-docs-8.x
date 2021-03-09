# エラー処理

- [イントロダクション](#introduction)
- [設定](#configuration)
- [例外ハンドラ](#the-exception-handler)
    - [例外のレポート](#reporting-exceptions)
    - [タイプによる例外の無視](#ignoring-exceptions-by-type)
    - [例外のレンダー](#rendering-exceptions)
    - [Reportable／Renderable例外](#renderable-exceptions)
- [HTTP例外](#http-exceptions)
    - [カスタムHTTPエラーページ](#custom-http-error-pages)

<a name="introduction"></a>
## イントロダクション

エラーと例外の処理は、新しいLaravelプロジェクトの開始時に最初から設定されています。`App\Exceptions\Handler`クラスは、アプリケーションが投げるすべての例外がログに記録され、ユーザーへレンダーする場所です。このドキュメント全体を通して、このクラスについて詳しく説明します。

<a name="configuration"></a>
## 設定

`config/app.php`設定ファイルの`debug`オプションは、エラーに関する情報が実際にユーザーに表示される量を決定します。デフォルトでは、このオプションは、`.env`ファイルに保存されている`APP_DEBUG`環境変数の値を尊重するように設定されています。

ローカル開発中は、`APP_DEBUG`環境変数を`true`に設定する必要があります。**実稼働環境では、この値は常に`false`である必要があります。本番環境で値が`true`に設定されていると、機密性の高い設定値がアプリケーションのエンドユーザーに公開されるリスクが起きます。**

<a name="the-exception-handler"></a>
## 例外ハンドラ

<a name="reporting-exceptions"></a>
### 例外のレポート

すべての例外は、`App\Exceptions\Handler`クラスが処理します。このクラスは、カスタム例外レポートとレンダリングコールバックを登録できる`register`メソッドを持っています。こうした各概念について詳しく説明します。例外レポートは、例外をログに記録したり、[Flare](https://flareapp.io)、[Bugsnag](https://bugsnag.com)、[Sentry](https://github.com/getsentry/sentry-laravel)などの外部サービスへ送信したりするために使用します。デフォルトで例外は[ログ](/docs/{{version}}/logging)設定に基づいてログに記録します。ただし、必要に応じて例外を自由に記録できます。

たとえば、さまざまなタイプの例外をさまざまな方法で報告する必要がある場合は、`reportable`メソッドを使用して、特定のタイプの例外を報告する必要があるときに実行するクロージャを登録できます。Laravelは、クロージャのタイプヒントを調べることで、クロージャが報告する例外のタイプを推測します。

    use App\Exceptions\InvalidOrderException;

    /**
     * アプリケーションの例外処理コールバックを登録
     *
     * @return void
     */
    public function register()
    {
        $this->reportable(function (InvalidOrderException $e) {
            //
        });
    }

`reportable`メソッドを使用してカスタム例外レポートコールバックを登録した場合でも、Laravelはアプリケーションのデフォルトのログ設定を使用して例外をログに記録します。デフォルトのログスタックへ例外の伝播を停止する場合は、レポートコールバックを定義するときに`stop`メソッドを使用するか、コールバックから`false`を返します。

    $this->reportable(function (InvalidOrderException $e) {
        //
    })->stop();

    $this->reportable(function (InvalidOrderException $e) {
        return false;
    });

> {tip} 特定の例外の例外レポートをカスタマイズするには、[レポート可能な例外](/docs/{{version}}/errors#renderable-exceptions)の使用も検討できます。

<a name="global-log-context"></a>
#### グローバルログコンテキスト

利用可能な場合、Laravelは現在のユーザーのIDをコンテキストデータとしてすべての例外のログメッセージに自動的に追加します。アプリケーションの`App\Exceptions\Handler`クラスの`context`メソッドをオーバーライドすることで、独自のグローバルコンテキストデータを定義できます。この情報は、アプリケーションによって書き込まれるすべての例外のログメッセージに含まれます。

    /**
     * ログ用のデフォルトのコンテキスト変数を取得
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

場合により、例外を報告する必要はあるが、現在のリクエストの処理を続行する必要がある場合もあります。`report`ヘルパ関数を使用すると、エラーページをユーザーに表示せずに、例外ハンドラを介して例外をすばやく報告できます。

    public function isValid($value)
    {
        try {
            // 値のバリデーション…
        } catch (Throwable $e) {
            report($e);

            return false;
        }
    }

<a name="ignoring-exceptions-by-type"></a>
### タイプによる例外の無視

アプリケーションを構築するときに、単に無視するだけで報告したくないタイプの例外もいくつかあるでしょう。アプリケーションの例外ハンドラには、空の配列に初期化されている`$dontReport`プロパティが含まれています。このプロパティに追加したクラスは報告されません。ただし、カスタムレンダリングロジックがある場合もあります。

    use App\Exceptions\InvalidOrderException;

    /**
     * 報告しない例外タイプのリスト
     *
     * @var array
     */
    protected $dontReport = [
        InvalidOrderException::class,
    ];

> {tip} Laravelは、404 HTTP "not found"エラーや無効なCSRFトークンによって生成された419 HTTPレスポンスに起因する例外など、いくつかのタイプのエラーを皆さんのために裏でこっそり無視しています。

<a name="rendering-exceptions"></a>
### 例外のレンダー

デフォルトでは、Laravel例外ハンドラは例外をHTTPレスポンスへ変換します。ただし、特定タイプの例外に対して、カスタムレンダリングクロージャを自由に登録できます。これは、例外ハンドラの`renderable`メソッドを介して実行します。

`renderable`メソッドへ渡すクロージャは、`Response`ヘルパを介して生成される`Illuminate\Http\Response`のインスタンスを返す必要があります。Laravelは、クロージャのタイプヒントを調べることで、どのタイプの例外をクロージャがレンダーするのか推測します。

    use App\Exceptions\InvalidOrderException;

    /**
     * アプリケーションの例外処理コールバックを登録
     *
     * @return void
     */
    public function register()
    {
        $this->renderable(function (InvalidOrderException $e, $request) {
            return response()->view('errors.invalid-order', [], 500);
        });
    }

<a name="renderable-exceptions"></a>
### Reportable／Renderable例外

例外ハンドラの`register`メソッドで例外を型チェックする代わりに、カスタム例外に直接`report`メソッドと`render`メソッドを定義することもできます。これらのメソッドが存在する場合、フレームワークによって自動的に呼び出されます。

    <?php

    namespace App\Exceptions;

    use Exception;

    class InvalidOrderException extends Exception
    {
        /**
         * 例外を報告
         *
         * @return void
         */
        public function report()
        {
            //
        }

        /**
         * 例外をHTTPレスポンスへレンダリング
         *
         * @param  \Illuminate\Http\Request  $request
         * @return \Illuminate\Http\Response
         */
        public function render($request)
        {
            return response(...);
        }
    }

特定の条件が満たされた場合にのみ必要なカスタムレポートロジックが例外に含まれている場合は、デフォルトの例外処理設定を使用して例外をレポートするようにLaravelに指示する必要が起き得ます。これを行うには、例外の`report`メソッドから`false`を返します。

    /**
     * 例外を報告
     *
     * @return bool|void
     */
    public function report()
    {
        // 例外にカスタムレポートが必要かどうかを判定…

        return false;
    }

> {tip} `report`メソッドで必要な依存関係をタイプヒントすると、Laravelの[サービスコンテナ](/docs/{{version}}/container)がメソッドへ自動的に依存を注入します。

<a name="http-exceptions"></a>
## HTTP例外

一部の例外は、サーバからのHTTPエラーコードを表します。たとえば、「ページが見つかりません」エラー(404)、「不正なエラー」(401)、または開発者が500エラーを生成する可能性もあります。アプリケーションのどこからでもこのようなレスポンスを生成したい場合は、`abort`ヘルパを使用できます。

    abort(404);

<a name="custom-http-error-pages"></a>
### カスタムHTTPエラーページ

Laravelを使用すると、さまざまなHTTPステータスコードのカスタムエラーページを簡単に表示できます。たとえば、404 HTTPステータスコードのエラーページをカスタマイズする場合は、`resources/views/errors/404.blade.php`を作成します。このファイルは、アプリケーションが生成するすべての404エラーで表示されます。このディレクトリ内のビューには、対応するHTTPステータスコードと一致する名前を付ける必要があります。`abort`関数によって生成された`Symfony\Component\HttpKernel\Exception\HttpException`インスタンスは`$exception`変数としてビューに渡されます。

    <h2>{{ $exception->getMessage() }}</h2>

`vendor:publish` Artisanコマンドを使用して、Laravelのデフォルトのエラーページテンプレートをリソース公開できます。テンプレートをリソース公開したら、好みに合わせてカスタマイズしてください。

    php artisan vendor:publish --tag=laravel-errors
