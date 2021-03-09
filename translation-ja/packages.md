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
- [リソース公開アセット](#public-assets)
- [ファイルグループのリソース公開](#publishing-file-groups)

<a name="introduction"></a>
## イントロダクション

パッケージは、Laravelに機能を追加するための主要な方法です。パッケージは、[Carbon](https://github.com/briannesbitt/Carbon)のような日付を処理するための優れた方法から、Spatieの[Laravel Media Library](https://github.com/spatie/laravel-medialibrary)のようなEloquentモデルにファイルを関連付けることができるパッケージまであります。

パッケージにはさまざまな種類があります。一部のパッケージはスタンドアロンです。つまり、どのPHPフレームワークでも機能します。CarbonとPHPUnitは、スタンドアロンパッケージの例です。これらのパッケージはいずれも、`composer.json`ファイルでリクエストすることにより、Laravelで使用できます。

逆にLaravelと一緒に使用することを意図したパッケージもあります。こうしたパッケージはLaravelアプリケーションを高めることをとくに意図したルート、コントローラ、ビュー、設定を持つことでしょう。このガイドはLaravelに特化したパッケージの開発を主に説明します。

<a name="a-note-on-facades"></a>
### ファサード使用の注意

Laravelアプリケーションを作成する場合、コントラクトとファサードのどちらを使用しても、どちらも基本的に同じレベルのテスト容易性を提供するため、通常は問題になりません。ただし、パッケージを作成する場合、通常、パッケージはLaravelのすべてのテストヘルパにアクセスできるわけではありません。パッケージが一般的なLaravelアプリケーション内にインストールされているかのようにパッケージテストを記述できるようにしたい場合は、[Orchestral Testbench](https://github.com/orchestral/testbench)パッケージを使用できます。

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

<a name="opting-out-of-package-discovery"></a>
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

[サービスプロバイダ](/docs/{{version}}/provider)は、パッケージとLaravelの間の接続ポイントです。サービスプロバイダは、Laravelの[サービスコンテナ](/docs/{{version}}/container)と結合し、ビュー、設定、ローカリゼーションファイルなどのパッケージリソースをロードする場所をLaravelに通知する責任を担当します。

サービスプロバイダは`Illuminate\Support\ServiceProvider`クラスを拡張し、`register`と`boot`の２メソッドを含んでいます。ベースの`ServiceProvider`クラスは、`illuminate/support` Composerパッケージにあります。 サービスプロバイダの構造と目的について詳細を知りたければ、[ドキュメント](/docs/{{version}}/providers)を調べてください。

<a name="resources"></a>
## リソース

<a name="configuration"></a>
### 設定

通常、パッケージの設定ファイルをアプリケーションの`config`ディレクトリにリソース公開する必要があります。これにより、パッケージのユーザーはデフォルトの設定オプションを簡単に上書きできます。設定ファイルをリソース公開できるようにするには、サービスプロバイダの`boot`メソッドから`publishes`メソッドを呼び出します。

    /**
     * 全パッケージサービスの初期起動処理
     *
     * @return void
     */
    public function boot()
    {
        $this->publishes([
            __DIR__.'/../config/courier.php' => config_path('courier.php'),
        ]);
    }

これで、皆さんのパッケージのユーザーが、Laravelの`vendor:publish`コマンドを実行すると、特定のリソース公開場所へファイルがコピーされます。設定がリソース公開されても、他の設定ファイルと同様に値にアクセスできます。

    $value = config('courier.option');

> {note} 設定ファイルでクロージャを定義しないでください。ユーザーが`config:cache` Artisanコマンドを実行すると、正しくシリアル化できません。

<a name="default-package-configuration"></a>
#### デフォルトパッケージ設定

独自のパッケージ設定ファイルをアプリケーションのリソース公開コピーとマージすることもできます。これにより、ユーザーは、設定ファイルのリソース公開されたコピーで実際にオーバーライドするオプションのみを定義できます。設定ファイルの値をマージするには、サービスプロバイダの`register`メソッド内で`mergeConfigFrom`メソッドを使用します。

`mergeConfigFrom`メソッドは、パッケージの設定ファイルへのパスを最初の引数に取り、アプリケーションの設定ファイルのコピーの名前を２番目の引数に取ります。

    /**
     * 全アプリケーションサービスの登録
     *
     * @return void
     */
    public function register()
            __DIR__.'/../config/courier.php', 'courier'
        $this->mergeConfigFrom(
            __DIR__.'/../config/courier.php', 'courier'
        );
    }

> {note} このメソッドは設定配列の一次レベルのみマージします。パッケージのユーザーが部分的に多次元の設定配列を定義すると、マージされずに欠落するオプションが発生します。

<a name="routes"></a>
### ルート

パッケージにルートを含めている場合は、`loadRoutesFrom`メソッドでロードします。このメソッドは自動的にアプリケーションのルートがキャッシュされているかを判定し、すでにキャッシュ済みの場合はロードしません。

    /**
     * 全パッケージサービスの初期起動
     *
     * @return void
     */
    public function boot()
    {
        $this->loadRoutesFrom(__DIR__.'/../routes/web.php');
    }

<a name="migrations"></a>
### マイグレーション

もしパッケージが[データベースマイグレーション](/docs/{{version}}/migrations)を含んでいる場合、`loadMigrationsFrom`メソッドを使用し、Laravelへどのようにロードするのかを知らせます。`loadMigrationsFrom`メソッドは引数を一つ取り、パッケージのマイグレーションのパスです。

    /**
     * 全パッケージサービスの初期起動
     *
     * @return void
     */
    public function boot()
    {
        $this->loadMigrationsFrom(__DIR__.'/../database/migrations');
    }

パッケージのマイグレーションを登録すると、`php artisan migrate`コマンドが実行されるとき自動的に実行されます。マイグレーションをアプリケーションの`database/migrations`ディレクトリにエクスポートする必要はありません。

<a name="translations"></a>
### 言語ファイル

パッケージが[言語ファイル](/docs/{{version}}/localization)を含む場合、`loadTranslationsFrom`メソッドを使用し、Laravelへどのようにロードするのかを伝えてください。たとえば、パッケージの名前が`courier`の場合、以下のコードをサービスプロバイダの`boot`メソッドに追加します。

    /**
     * 全パッケージサービスの初期起動処理
     *
     * @return void
     */
    public function boot()
    {
        $this->loadTranslationsFrom(__DIR__.'/../resources/lang', 'courier');
    }

パッケージの翻訳は、`package::file.line`規約を使い参照します。ですから、`courier`パッケージの`messages`ファイル中の、`welcome`行をロードするには、次のようになります。

    echo trans('courier::messages.welcome');

<a name="publishing-translations"></a>
#### 翻訳のリソース公開

パッケージの翻訳をアプリケーションの`resources/lang/vendor`ディレクトリへリソース公開したい場合は、サービスプロバイダの`publishes`メソッドを使用します。`publishes`メソッドはパッケージパスとリソース公開したい場所の配列を引数に取ります。たとえば、`courier`パッケージの言語ファイルをリソース公開する場合は、次のようになります。

    /**
     * 全パッケージサービスの初期起動処理
     *
     * @return void
     */
    public function boot()
    {
        $this->loadTranslationsFrom(__DIR__.'/../resources/lang', 'courier');

        $this->publishes([
            __DIR__.'/../resources/lang' => resource_path('lang/vendor/courier'),
        ]);
    }

これで、皆さんのパッケージのユーザーが、Laravelの`vendor:publish` Artisanコマンドを実行すると、パッケージの翻訳は指定されたリソース公開場所で公開されます。

<a name="views"></a>
### ビュー

パッケージの[ビュー](/docs/{{version}}/views)をLaravelへ登録するには、ビューがどこにあるのかをLaravelに知らせる必要があります。そのために、サービスプロバイダの`loadViewsFrom`メソッドを使用してください。`loadViewsFrom`メソッドは２つの引数を取ります。ビューテンプレートへのパスと、パッケージの名前です。たとえば、パッケージ名が`courier`であれば、以下の行をサービスプロバイダの`boot`メソッドに追加してください。

    /**
     * 全パッケージサービスの初期起動処理
     *
     * @return void
     */
    public function boot()
    {
        $this->loadViewsFrom(__DIR__.'/../resources/views', 'courier');
    }

パッケージのビューは、`package::view`記法を使い参照します。そのため、ビューのパスを登録し終えたあとで、`courier`パッケージの`admin`ビューをロードする場合は、次のようになります。

    Route::get('admin', function () {
        return view('courier::admin');
    });

<a name="overriding-package-views"></a>
#### パッケージビューのオーバーライド

`loadViewsFrom`メソッドを使用すると、Laravelはビューの２つの場所を実際に登録します。アプリケーションの`resources/views/vendor`ディレクトリと指定したディレクトリです。そのため、たとえば`courier`パッケージを使用すると、Laravelは最初にカスタムバージョンのビューが開発者によって`resources/views/vendor/courier`ディレクトリに配置されているかどうかを確認します。次に、ビューがカスタマイズされていない場合、Laravelは`loadViewsFrom`の呼び出しで指定したパッケージビューディレクトリを検索します。これにより、パッケージユーザーはパッケージのビューを簡単にカスタマイズ／オーバーライドできます。

<a name="publishing-views"></a>
#### ビューのリソース公開

パッケージのビューを`resources/views/vendor`ディレクトリでリソース公開したい場合は、サービスプロバイダの`publishes`メソッドを使ってください。`publishes`メソッドはパッケージのビューパスと、リソース公開場所の配列を引数に取ります。

    /**
     * 全パッケージサービスの初期起動処理
     *
     * @return void
     */
    public function boot()
    {
        $this->loadViewsFrom(__DIR__.'/../resources/views', 'courier');

        $this->publishes([
            __DIR__.'/../resources/views' => resource_path('views/vendor/courier'),
        ]);
    }

これで皆さんのパッケージのユーザーが、Laravelの`vendor::publish` Artisanコマンドを実行すると、パッケージのビューは指定されたリソース公開場所へコピーされます。

<a name="view-components"></a>
### ビューコンポーネント

パッケージに[ビューコンポーネント](/docs/{{version}}/Blade#components)が含まれている場合は、`loadViewComponentsAs`メソッドを使用して、それらのロード方法をLaravelに通知します。`loadViewComponentsAs`メソッドは、ビューコンポーネントのタグプレフィックスとビューコンポーネントクラス名の配列の２つの引数とります。たとえば、パッケージのプレフィックスが`courier`で、`Alert`および`Button`ビューコンポーネントがある場合、サービスプロバイダの`boot`メソッドへ以下を追加します。

    use Courier\Components\Alert;
    use Courier\Components\Button;

    /**
     * 全パッケージサービスの初期起動処理
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

<a name="anonymous-components"></a>
#### 無名コンポーネント

パッケージが無名コンポーネントを持っている場合、"views"ディレクトリ（`loadViewsFrom`で指定している場所）の`components`ディレクトリの中へ設置する必要があります。すると、パッケージのビュー名前空間を先頭に付けたコンポーネント名でレンダーできます。

    <x-courier::alert />

<a name="commands"></a>
## コマンド

パッケージのArtisanコマンドをLaravelへ登録するには、`commands`メソッドを使います。このメソッドは、コマンドクラス名の配列を引数に取ります。コマンドを登録したら、[Artisan CLI](/docs/{{version}}/artisan)を使い、実行できます。

    use Courier\Console\Commands\InstallCommand;
    use Courier\Console\Commands\NetworkCommand;

    /**
     * パッケージサービスの初期処理
     *
     * @return void
     */
    public function boot()
    {
        if ($this->app->runningInConsole()) {
            $this->commands([
                InstallCommand::class,
                NetworkCommand::class,
            ]);
        }
    }

<a name="public-assets"></a>
## リソース公開アセット

パッケージには、JavaScript、CSS、画像などのアセットが含まれている場合があります。これらのアセットをアプリケーションの`public`ディレクトリにリソース公開するには、サービスプロバイダの`publishes`メソッドを使用します。この例では、関連するアセットのグループを簡単にリソース公開するために使用できる`public`アセットグループタグも追加します。

    /**
     * 全パッケージサービスの初期起動
     *
     * @return void
     */
    public function boot()
    {
        $this->publishes([
            __DIR__.'/../public' => public_path('vendor/courier'),
        ], 'public');
    }

これで、パッケージのユーザーが`vendor:publish`コマンドを実行すると、アセットが指定するリソース公開場所にコピーされます。通常、ユーザーはパッケージが更新されるたびにアセットを上書きする必要があるため、`--force`フラグを使用できます。

    php artisan vendor:publish --tag=public --force

<a name="publishing-file-groups"></a>
## ファイルグループのリソース公開

パッケージアセットとリソースのグループを個別にリソース公開することを推奨します。たとえば、パッケージのアセットをリソース公開することを強制されることなく、ユーザーがパッケージの設定ファイルをリソース公開できるようにしたい場合もあるでしょう。パッケージのサービスプロバイダから`publishes`メソッドを呼び出すときに、それらに「タグ付け」することでこれを行うことができます。例として、タグを使用して、パッケージのサービスプロバイダの`boot`メソッドで２つのリソース公開グループ(`config`と`migrations`)を定義してみましょう。

    /**
     * 全パッケージサービスの初期起動処理
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
