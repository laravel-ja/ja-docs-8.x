# パッケージ開発

- [イントロダクション](#introduction)
    - [ファサード使用の注意](#a-note-on-facades)
- [パッケージディスカバリー](#package-discovery)
- [サービスプロバイダ](#service-providers)
- [リソース](#resources)
    - [設定](#configuration)
    - [マイグレーション](#migrations)
    - [ルート](#routes)
    - [翻訳](#translations)
    - [ビュー](#views)
    - [ビューコンポーネント](#view-components)
- [コマンド](#commands)
- [公開アセット](#public-assets)
- [ファイルグループのリソース公開](#publishing-file-groups)

<a name="introduction"></a>
## イントロダクション

パッケージはLaravelに機能を追加する一番重要な方法です。パッケージとして何でも動作させることができます。たとえば日付ライブラリーである[Carbon](https://github.com/briannesbitt/Carbon)や、振る舞い駆動開発(BDD)テストフレームワークの[Behat](https://github.com/Behat/Behat)などです。

パッケージには、色々な種類が存在しています。スタンドアローンで動作するパッケージがあります。つまり、どんなPHPフレームワークでも動作します。CarbonもBehatもスタンドアローンパッケージの例です。Laravelと一緒に使用するには`composer.json`ファイルで使用を指定します。

逆にLaravelと一緒に使用することを意図したパッケージもあります。こうしたパッケージはLaravelアプリケーションを高めることをとくに意図したルート、コントローラ、ビュー、設定を持つことでしょう。このガイドはLaravelに特化したパッケージの開発を主に説明します。

<a name="a-note-on-facades"></a>
### ファサード使用の注意

Laravelアプリケーションをプログラムする場合は、契約とファサードのどちらを使用しても、一般的には問題ありません。両方共に基本的に同じレベルのテスタビリティがあるからです。しかし、パッケージを書く場合は、通常すべてのLaravelテストヘルパにアクセスできません。Laravelアプリケーション内で行うように、パッケージでテストを書けるようにするには、[Orchestral Testbench](https://github.com/orchestral/testbench)パッケージを使用してください。

<a name="package-discovery"></a>
## パッケージディスカバリー

Laravelアプリケーションの`config/app.php`設定ファイルには、Laravelがロードすべきサービスプロバイダのリストが、`providers`オプションで定義されています。誰かが皆さんのパッケージをインストールしたら、皆さんのサービスプロバイダをこのリストに含めてもらいたいと思うことでしょう。このリストへユーザー自身がサービスプロバイダを追加することを要求する代わりに、皆さんのパッケージの`composer.json`ファイルの`extra`セクションで、プロバイダを定義してください。登録してもらいたい[ファサード](/docs/{{version}}/facades)もリストできます。

    "extra": {
        "laravel": {
            "providers": [
                "Barryvdh\\Debugbar\\ServiceProvider"
            ],
            "aliases": {
                "Debugbar": "Barryvdh\\Debugbar\\Facade"
            }
        }
    },

ディスカバリー用にパッケージを設定したら、Laravelはサービスプロバイダとファサードをインストール時に自動的に登録します。皆さんのパッケージユーザーに、便利なインストール体験をもたらします。

### パッケージディスカバリーの不使用

パッケージを利用する場合に、パッケージディスカバリーを使用したくない場合は、アプリケーションの`composer.json`ファイルの`extra`セクションに、使用しないパッケージをリストしてください。

    "extra": {
        "laravel": {
            "dont-discover": [
                "barryvdh/laravel-debugbar"
            ]
        }
    },

全パッケージに対してディスカバリーを使用しない場合は、アプリケーションの`dont-discover`ディレクティブに、`*`文字を指定してください。

    "extra": {
        "laravel": {
            "dont-discover": [
                "*"
            ]
        }
    },

<a name="service-providers"></a>
## サービスプロバイダ

[サービスプロバイダ](/docs/{{version}}/providers)はパッケージとLaravelを結びつけるところです。サービスプロバイダは何かをLaravelの[サービスコンテナ](/docs/{{version}}/container)と結合し、ビューや設定、言語ファイルのようなリソースをどこからロードするかをLaravelに知らせる責務を持っています。

サービスプロバイダは`Illuminate\Support\ServiceProvider`クラスを拡張し、`register`と`boot`の２メソッドを含んでいます。ベースの`ServiceProvider`クラスは、`illuminate/support` Composerパッケージにあります。 サービスプロバイダの構造と目的について詳細を知りたければ、[ドキュメント](/docs/{{version}}/providers)を調べてください。

<a name="resources"></a>
## リソース

<a name="configuration"></a>
### 設定

通常、パッケージの設定ファイルをアプリケーション自身の`config`ディレクトリへリソース公開する必要が起きます。これにより、ユーザーが皆さんのパッケージのデフォルト設定オプションを簡単にオーバーライドできるようになります。設定ファイルをリソース公開するには、サービスプロバイダの`boot`メソッドで、`publishes`メソッドを呼び出してください。

    /**
     * 全アプリケーションサービスの初期起動
     *
     * @return void
     */
    public function boot()
    {
        $this->publishes([
            __DIR__.'/path/to/config/courier.php' => config_path('courier.php'),
        ]);
    }

これで、皆さんのパッケージのユーザーが、Laravelの`vendor:publish`コマンドを実行すると、特定のリソース公開場所へファイルがコピーされます。設定がリソース公開されても、他の設定ファイルと同様に値にアクセスできます。

    $value = config('courier.option');

> {note} 設定ファイル中でクロージャを定義してはいけません。パッケージ使用者が`config:cache` Artisanコマンドを使用している場合に、正しくシリアライズできません。

#### デフォルトパッケージ設定

もしくは、アプリケーションへリソース公開したコピーと、自身のパッケージの設定ファイルをマージすることもできます。これにより、ユーザーはリソース公開された設定のコピーの中で、実際にオーバーライドしたいオプションのみを定義すればよくなります。設定をマージする場合は、サービスプロバイダの`register`メソッドの中で、`mergeConfigFrom`メソッドを使用します。

    /**
     * 全アプリケーションサービスの登録
     *
     * @return void
     */
    public function register()
    {
        $this->mergeConfigFrom(
            __DIR__.'/path/to/config/courier.php', 'courier'
        );
    }

> {note} このメソッドは設定配列の一次レベルのみマージします。パッケージのユーザーが部分的に多次元の設定配列を定義すると、マージされずに欠落するオプションが発生します。

<a name="routes"></a>
### ルート

パッケージにルートを含めている場合は、`loadRoutesFrom`メソッドでロードします。このメソッドは自動的にアプリケーションのルートがキャッシュされているかを判定し、すでにキャッシュ済みの場合はロードしません。

    /**
     * 全アプリケーションサービスの初期起動
     *
     * @return void
     */
    public function boot()
    {
        $this->loadRoutesFrom(__DIR__.'/routes.php');
    }

<a name="migrations"></a>
### マイグレーション

もしパッケージが[データベースマイグレーション](/docs/{{version}}/migrations)を含んでいる場合、`loadMigrationsFrom`メソッドを使用し、Laravelへどのようにロードするのかを知らせます。`loadMigrationsFrom`メソッドは引数を一つ取り、パッケージのマイグレーションのパスです。

    /**
     * 全アプリケーションサービスの初期起動
     *
     * @return void
     */
    public function boot()
    {
        $this->loadMigrationsFrom(__DIR__.'/path/to/migrations');
    }

パッケージのマイグレーションが登録されると、`php artisan migrate`コマンド実行時に、自動的にパッケージのマイグレーションも行われます。アプリケーションの`database/migrations`ディレクトリへリソース公開する必要はありません。

<a name="translations"></a>
### 言語ファイル

パッケージが[言語ファイル](/docs/{{version}}/localization)を含む場合、`loadTranslationsFrom`メソッドを使用し、Laravelへどのようにロードするのかを伝えてください。たとえば、パッケージの名前が`courier`の場合、以下のコードをサービスプロバイダの`boot`メソッドに追加します。

    /**
     * 全アプリケーションサービスの初期起動
     *
     * @return void
     */
    public function boot()
    {
        $this->loadTranslationsFrom(__DIR__.'/path/to/translations', 'courier');
    }

パッケージの翻訳は、`package::file.line`規約を使い参照します。ですから、`courier`パッケージの`messages`ファイル中の、`welcome`行をロードするには、次のようになります。

    echo trans('courier::messages.welcome');

#### 翻訳のリソース公開

パッケージの翻訳をアプリケーションの`resources/lang/vendor`ディレクトリへリソース公開したい場合は、サービスプロバイダの`publishes`メソッドを使用します。`publishes`メソッドはパッケージパスとリソース公開したい場所の配列を引数に取ります。たとえば、`courier`パッケージの言語ファイルをリソース公開する場合は、次のようになります。

    /**
     * 全アプリケーションサービスの初期起動
     *
     * @return void
     */
    public function boot()
    {
        $this->loadTranslationsFrom(__DIR__.'/path/to/translations', 'courier');

        $this->publishes([
            __DIR__.'/path/to/translations' => resource_path('lang/vendor/courier'),
        ]);
    }

これで、皆さんのパッケージのユーザーが、Laravelの`vendor:publish` Artisanコマンドを実行すると、パッケージの翻訳は指定されたリソース公開場所で公開されます。

<a name="views"></a>
### ビュー

パッケージの[ビュー](/docs/{{version}}/views)をLaravelへ登録するには、ビューがどこにあるのかをLaravelに知らせる必要があります。そのために、サービスプロバイダの`loadViewsFrom`メソッドを使用してください。`loadViewsFrom`メソッドは２つの引数を取ります。ビューテンプレートへのパスと、パッケージの名前です。たとえば、パッケージ名が`courier`であれば、以下の行をサービスプロバイダの`boot`メソッドに追加してください。

    /**
     * 全アプリケーションサービスの初期起動
     *
     * @return void
     */
    public function boot()
    {
        $this->loadViewsFrom(__DIR__.'/path/to/views', 'courier');
    }

パッケージのビューは、`package::view`記法を使い参照します。そのため、ビューのパスを登録し終えたあとで、`courier`パッケージの`admin`ビューをロードする場合は、次のようになります。

    Route::get('admin', function () {
        return view('courier::admin');
    });

#### パッケージビューのオーバーライド

`loadViewsFrom`メソッドを使用する場合、Laravelはビューの２つの場所を実際には登録します。一つはアプリケーションの`resources/views/vendor`ディレクトリで、もう一つは皆さんが指定したディレクトリです。では、`courier`の例を使って確認しましょう。Laravelは最初に`resources/views/vendor/courier`の中に、カスタムバージョンのビューが開発者により用意されていないかチェックします。カスタムビューが用意されていなければ、次に`loadViewsFrom`の呼び出しで指定した、パッケージビューディレクトリを探します。この仕組みのおかげで、パッケージのビューがエンドユーザーにより簡単にカスタマイズ／オーバーライドできるようになっています。

#### ビューのリソース公開

パッケージのビューを`resources/views/vendor`ディレクトリでリソース公開したい場合は、サービスプロバイダの`publishes`メソッドを使ってください。`publishes`メソッドはパッケージのビューパスと、リソース公開場所の配列を引数に取ります。

    /**
     * 全アプリケーションサービスの初期起動
     *
     * @return void
     */
    public function boot()
    {
        $this->loadViewsFrom(__DIR__.'/path/to/views', 'courier');

        $this->publishes([
            __DIR__.'/path/to/views' => resource_path('views/vendor/courier'),
        ]);
    }

これで皆さんのパッケージのユーザーが、Laravelの`vendor::publish` Artisanコマンドを実行すると、パッケージのビューは指定されたリソース公開場所へコピーされます。

<a name="view-components"></a>
### ビューコンポーネント

パッケージに[ビューコンポーネント](/docs/{{version}}/blade#components)を含める場合、Laravelへロード方法を知らせるために`loadViewComponentsAs`メソッドを使用してください。`loadViewComponentsAs`メソッドは２つの引数を取ります。ビューコンポーネントのタグプレフィックスとビューコンポーネントクラスの配列です。たとえばパッケージのプレフィックスが`courier`で、`Alert`と`Button`コンポーネントを持っている場合、サービスプロバイダの`boot`メソッドへ次のように追加します。

    /**
     * 全アプリケーションサービスの初期起動
     *
     * @return void
     */
    public function boot()
    {
        $this->loadViewComponentsAs('courier', [
            Alert::class,
            Button::class,
        ]);
    }

ビューコンポーネントをサービスプロバイダ中で登録したら、以下のようにビューの中で参照します。

    <x-courier-alert />

    <x-courier-button />

#### 無名コンポーネント

パッケージが無名コンポーネントを持っている場合、"views"ディレクトリ（`loadViewsFrom`で指定している場所）の`components`ディレクトリの中へ設置する必要があります。すると、パッケージのビュー名前空間を先頭に付けたコンポーネント名でレンダーできます。

    <x-courier::alert />

<a name="commands"></a>
## コマンド

パッケージのArtisanコマンドをLaravelへ登録するには、`commands`メソッドを使います。このメソッドは、コマンドクラス名の配列を引数に取ります。コマンドを登録したら、[Artisan CLI](/docs/{{version}}/artisan)を使い、実行できます。

    /**
     * アプリケーションサービスの初期処理
     *
     * @return void
     */
    public function boot()
    {
        if ($this->app->runningInConsole()) {
            $this->commands([
                FooCommand::class,
                BarCommand::class,
            ]);
        }
    }

<a name="public-assets"></a>
## リソース公開アセット

パッケージにはJavaScriptやCSS、画像などのアセットを含むと思います。こうしたアセットを`public`ディレクトリへリソース公開するには、サービスプロバイダの`publishes`メソッドを使用してください。次の例では、関連するアセットをまとめてリソース公開するために`public`アセットグループタグも追加指定しています。

    /**
     * 全アプリケーションサービスの初期起動
     *
     * @return void
     */
    public function boot()
    {
        $this->publishes([
            __DIR__.'/path/to/assets' => public_path('vendor/courier'),
        ], 'public');
    }

これで、皆さんのパッケージのユーザーが、`vendor:publish`コマンドを実行した時に、アセットは指定したリソース公開場所へコピーされます。通常、パッケージが更新されるごとに、アセットをオーバーライトする必要がありますので、`--force`フラグと一緒に使用します。

    php artisan vendor:publish --tag=public --force

<a name="publishing-file-groups"></a>
## ファイルグループのリソース公開

アセットとリソースのパッケージグループを別々にリソース公開したいこともあるでしょう。たとえば、パッケージのアセットのリソース公開を強要せずに、設定ファイルをリソース公開したい場合です。パッケージのサービスプロバイダで呼び出す、`publishes`メソッド実行時の「タグ指定」で行えます。例として、パッケージのサービスプロバイダの`boot`メソッドで、２つのリソース公開グループを定義してみましょう。

    /**
     * 全アプリケーションサービスの初期起動
     *
     * @return void
     */
    public function boot()
    {
        $this->publishes([
            __DIR__.'/../config/package.php' => config_path('package.php')
        ], 'config');

        $this->publishes([
            __DIR__.'/../database/migrations/' => database_path('migrations')
        ], 'migrations');
    }

これでユーザーは、`vendor::publish` Artisanコマンドを使用するときにタグ名を指定することで、グループを別々にリソース公開できます。

    php artisan vendor:publish --tag=config
