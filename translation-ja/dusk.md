# Laravel Dusk

- [イントロダクション](#introduction)
- [インストール](#installation)
    - [ChromeDriverインストールの管理](#managing-chromedriver-installations)
    - [他ブラウザの使用](#using-other-browsers)
- [利用の開始](#getting-started)
    - [テストの生成](#generating-tests)
    - [データベースマイグレーション](#migrations)
    - [テストの実行](#running-tests)
    - [環境の処理](#environment-handling)
- [ブラウザの基本](#browser-basics)
    - [環境の処理](#environment-handling)
    - [ナビゲーション](#navigation)
    - [ブラウザウィンドウのリサイズ](#resizing-browser-windows)
    - [ブラウザマクロ](#browser-macros)
    - [認証](#authentication)
    - [クッキー](#cookies)
    - [JavaScriptの実行](#executing-javascript)
    - [スクリーンショットの取得](#taking-a-screenshot)
    - [コンソール出力をディスクに保存](#storing-console-output-to-disk)
    - [ページソースをディスクへ保存](#storing-page-source-to-disk)
- [要素操作](#interacting-with-elements)
    - [Duskセレクタ](#dusk-selectors)
    - [テキスト、値、属性](#text-values-and-attributes)
    - [フォーム操作](#interacting-with-forms)
    - [添付ファイル](#attaching-files)
    - [ボタンを押す](#pressing-buttons)
    - [リンクのクリック](#clicking-links)
    - [キーワードの使用](#using-the-keyboard)
    - [マウスの使用](#using-the-mouse)
    - [JavaScriptダイアログ](#javascript-dialogs)
    - [セレクタの範囲指定](#scoping-selectors)
    - [要素の待機](#waiting-for-elements)
    - [要素のビュー内へのスクロール](#scrolling-an-element-into-view)
- [使用可能なアサート](#available-assertions)
- [ページ](#pages)
    - [ページの生成](#generating-pages)
    - [ページの設定](#configuring-pages)
    - [ページへのナビゲーション](#navigating-to-pages)
    - [セレクタの簡略記述](#shorthand-selectors)
    - [ページメソッド](#page-methods)
- [コンポーネント](#components)
    - [コンポーネントの生成](#generating-components)
    - [コンポーネントの使用](#using-components)
- [継続的インテグレーション](#continuous-integration)
    - [Heroku CI](#running-tests-on-heroku-ci)
    - [Travis CI](#running-tests-on-travis-ci)
    - [GitHubアクション](#running-tests-on-github-actions)

<a name="introduction"></a>
## イントロダクション

Laravel Duskは、表現力豊かで使いやすいブラウザ自動化およびテストAPIを提供します。デフォルトではDuskを使用するために、ローカルコンピュータへJDKやSeleniumをインストールする必要はありません。代わりに、Duskはスタンドアロンの[ChromeDriver](https://sites.google.com/a/chromium.org/chromedriver/home)を使用します。ただし、他のSelenium互換ドライバーも自由に利用できます。

<a name="installation"></a>
## インストール

使用を開始するには、`laravel/dusk`コンポーサ依存パッケージをプロジェクトへ追加します。

    composer require --dev laravel/dusk

> {note} 本番環境にDuskをインストールしてはいけません。インストールすると、アプリケーションに対する未認証でのアクセスを許すようになります。

Duskパッケージをインストールし終えたら、`dusk:install` Artisanコマンドを実行します。`dusk:install`コマンドは、`tests/Browser`ディレクトリとサンプルのDuskテストを作成します。

    php artisan dusk:install

次に、アプリケーションの`.env`ファイルに`APP_URL`環境変数を設定します。この値は、ブラウザでアプリケーションにアクセスするために使用するURLと一致させる必要があります。

> {tip} [Laravel Sail](/docs/{{version}}/sale)を使用してローカル開発環境を管理している場合は、[Duskテストの設定と実行](/docs/{{version}}/sail#laravel-dusk)に関するSailのドキュメントも参照してください。

<a name="managing-chromedriver-installations"></a>
### ChromeDriverインストールの管理

Laravel Duskにデフォルトで含まれるChromeDriverとは別のバージョンをインストールしたい場合は、`dusk:chrome-driver`コマンドが使用できます。

    # OSに合う、最新バージョンのChromeDriverのインストール
    php artisan dusk:chrome-driver

    # OSに合う、指定バージョンのChromeDriverのインストール
    php artisan dusk:chrome-driver 86

    # 全OSをサポートしている、指定バージョンのChromeDriverのインストール
    php artisan dusk:chrome-driver --all

    # OSに合わせ検出したChrome／Chromiumのバージョンと一致するバージョンのChromeDriverをインストール
    php artisan dusk:chrome-driver --detect

> {note} Dusk実行には、実行可能な`chromedriver`バイナリが必要です。Dusk実行時に問題がある場合は、このバイナリを実行可能に確実にするために、`chmod -R 0755 vendor/laravel/dusk/bin`コマンドを実行してみてください。

<a name="using-other-browsers"></a>
### 他ブラウザの使用

デフォルトのDuskは、Google Chromeとスタンドアローンの[ChromeDriver](https://sites.google.com/a/chromium.org/chromedriver/home)をブラウザテスト実行に使用します。しかし、自身のSeleniumサーバを起動し、希望するブラウザに対しテストを実行することもできます。

開始するには、アプリケーションのベースDuskテストケースである、`tests/DuskTestCase.php`ファイルを開きます。このファイルの中の、`startChromeDriver`メソッド呼び出しを削除してください。これにより、ChromeDriverの自動起動を停止します。

    /**
     * Duskテスト実行準備
     *
     * @beforeClass
     * @return void
     */
    public static function prepare()
    {
        // static::startChromeDriver();
    }

次に、皆さんが選んだURLとポートへ接続するために、`driver`メソッドを変更します。WebDriverに渡すべき、"desired capabilities"を更新することもできます。

    /**
     * RemoteWebDriverインスタンスの生成
     *
     * @return \Facebook\WebDriver\Remote\RemoteWebDriver
     */
    protected function driver()
    {
        return RemoteWebDriver::create(
            'http://localhost:4444/wd/hub', DesiredCapabilities::phantomjs()
        );
    }

<a name="getting-started"></a>
## 利用の開始

<a name="generating-tests"></a>
### テストの生成

Duskのテストを生成するには、`dusk:make` Artisanコマンドを使います。生成されたテストは、`tests/Browser`ディレクトリへ設置されます。

    php artisan dusk:make LoginTest

<a name="migrations"></a>
### データベースマイグレーション

作成するテストのほとんどは、アプリケーションのデータベースからデータを取得するページを操作します。ただし、Duskテストでは`RefreshDatabase`トレイトを使用しないでください。`RefreshDatabase`トレイトは、HTTPリクエスト間で適用または利用できないデータベーストランザクションを活用します。代わりに、`DatabaseMigrations`トレイトを使用してください。これにより、テストごとにデータベースが再マイグレーションされます。

    <?php

    namespace Tests\Browser;

    use App\Models\User;
    use Illuminate\Foundation\Testing\DatabaseMigrations;
    use Laravel\Dusk\Chrome;
    use Tests\DuskTestCase;

    class ExampleTest extends DuskTestCase
    {
        use DatabaseMigrations;
    }

> {note} Duskテストの実行時には、SQLiteインメモリデータベースを使用できません。ブラウザは独自のプロセス内で実行されるため、他のプロセスのメモリ内データベースにアクセスすることはできません。

<a name="running-tests"></a>
### テストの実行

ブラウザのテストを実行するには、`dusk` Artisanコマンドを実行します。

    php artisan dusk

`dusk`コマンドで最後に実行したテストが失敗した場合、`dusk:fails`コマンドを使用し、失敗したテストを再実行することにより、時間を節約できます。

    php artisan dusk:fails

`dusk`コマンドは、特定の[グループ](https://phpunit.de/manual/current/en/appendixes.annotations.html#appendixes.annotations.group)のテストのみを実行できるようにするなど、PHPUnitテストランナーが通常受け付ける引数を全て受け入れます。

    php artisan dusk --group=foo

> {tip} [Laravel Sail](/docs/{{version}}/sale)を使用してローカル開発環境を管理している場合は、[Duskテストの設定と実行](/docs/{{version}}/sail#laravel-dusk)に関するSailのドキュメントを参照してください。

<a name="manually-starting-chromedriver"></a>
#### ChromeDriverの手動起動

デフォルトのDuskは、ChromeDriverを自動的に起動しようとします。特定のシステムで自動起動しない場合は、`dusk`コマンドを実行する前に手動でChromeDriverを起動することもできます。ChromeDriverを手動起動する場合は、`tests/DuskTestCase.php`ファイルの以下の行をコメントアウトしてください。

    /**
     * Duskテスト実行準備
     *
     * @beforeClass
     * @return void
     */
    public static function prepare()
    {
        // static::startChromeDriver();
    }

さらに、9515以外のポートでChromeDriverを起動する場合は、同じクラスの`driver`メソッドを変更して正しいポートを反映する必要があります。

    /**
     * RemoteWebDriverインスタンスの生成
     *
     * @return \Facebook\WebDriver\Remote\RemoteWebDriver
     */
    protected function driver()
    {
        return RemoteWebDriver::create(
            'http://localhost:9515', DesiredCapabilities::chrome()
        );
    }

<a name="environment-handling"></a>
### 環境の処理

テスト実行時に独自の環境ファイルを強制的に使用させるには、プロジェクトのルートに`.env.dusk.{environment}`ファイルを作成します。たとえば、`local`環境から`dusk`コマンドを起動する場合は、`.env.dusk.local`ファイルを作成します。

テストを実行すると、Duskは`.env`ファイルをバックアップし、皆さんのDusk環境を`.env`へリネームします。テストが完了したら、`.env`ファイルをリストアします。

<a name="browser-basics"></a>
## ブラウザの基本

<a name="creating-browsers"></a>
### ブラウザの生成

開始にあたり、アプリケーションへログインできることを確認するテストを作成してみましょう。テストを生成した後、ログインページに移動し、ログイン情報を入力して、「ログイン」ボタンをクリックするようにテストを変更します。ブラウザインスタンスを作成するには、Duskテスト内から`browse`メソッドを呼び出します。

    <?php

    namespace Tests\Browser;

    use App\Models\User;
    use Illuminate\Foundation\Testing\DatabaseMigrations;
    use Laravel\Dusk\Chrome;
    use Tests\DuskTestCase;

    class ExampleTest extends DuskTestCase
    {
        use DatabaseMigrations;

        /**
         * 基本的なブラウザテスト例
         *
         * @return void
         */
        public function test_basic_example()
        {
            $user = User::factory()->create([
                'email' => 'taylor@laravel.com',
            ]);

            $this->browse(function ($browser) use ($user) {
                $browser->visit('/login')
                        ->type('email', $user->email)
                        ->type('password', 'password')
                        ->press('Login')
                        ->assertPathIs('/home');
            });
        }
    }

上記の例のように、`browse`メソッドはクロージャを引数に取ります。ブラウザインスタンスは、Duskによってこのクロージャに自動的に渡され、アプリケーションを操作し、アサーションを作成するために使用するメインオブジェクトです。

<a name="creating-multiple-browsers"></a>
#### 複数のブラウザの作成

テストを適切に実行するために、複数のブラウザが必要になる場合があります。たとえば、WebSocketと対話するチャット画面をテストするために複数のブラウザが必要になる場合があります。複数のブラウザを作成するには、`browse`メソッドへ指定するクロージャの引数へブラウザ引数を追加するだけです。

    $this->browse(function ($first, $second) {
        $first->loginAs(User::find(1))
              ->visit('/home')
              ->waitForText('Message');

        $second->loginAs(User::find(2))
               ->visit('/home')
               ->waitForText('Message')
               ->type('message', 'Hey Taylor')
               ->press('Send');

        $first->waitForText('Hey Taylor')
              ->assertSee('Jeffrey Way');
    });

<a name="navigation"></a>
### ナビゲーション

`visit`メソッドを使用して、アプリケーション内の特定のURIに移動できます。

    $browser->visit('/login');

`visitRoute`メソッドを使用して[名前付きルート](/docs/{{version}}/routing#named-routes)へ移動できます。

    $browser->visitRoute('login');

`back`および`forward`メソッドを使用して「戻る」および「進む」をナビゲートできます。

    $browser->back();

    $browser->forward();

`refresh`メソッドを使用してページを更新できます。

    $browser->refresh();

<a name="resizing-browser-windows"></a>
### ブラウザウィンドウのリサイズ

ブラウザウインドウのサイズを調整するため、`resize`メソッドを使用できます。

    $browser->resize(1920, 1080);

ブラウザウィンドウを最大化するには、`maximize`メソッドを使います。

    $browser->maximize();

`fitContent`メソッドは、コンテンツのサイズに一致するようにブラウザウィンドウのサイズを変更します。

   $browser->fitContent();

テスト失敗時にDuskはスクリーンショットを取るために、以前のコンテンツに合うようブラウザを自動的にリサイズします。この機能を無効にするには、テストの中で`disableFitOnFailure`メソッドを呼び出してください。

    $browser->disableFitOnFailure();

スクリーン上の別の位置へブラウザのウィンドウを移動する場合は、`move`メソッドを使います。

    $browser->move($x = 100, $y = 100);

<a name="browser-macros"></a>
### ブラウザマクロ

さまざまなテストで再利用可能なカスタムブラウザメソッドを定義したい場合は、`Browser`クラスで`macro`メソッドを使用できます。通常、このメソッドは[サービスプロバイダ](/docs/{{version}}/provider)の`boot`メソッドで呼び出す必要があります。

    <?php

    namespace App\Providers;

    use Illuminate\Support\ServiceProvider;
    use Laravel\Dusk\Browser;

    class DuskServiceProvider extends ServiceProvider
    {
        /**
         * Duskのブラウザマクロを登録
         *
         * @return void
         */
        public function boot()
        {
            Browser::macro('scrollToElement', function ($element = null) {
                $this->script("$('html, body').animate({ scrollTop: $('$element').offset().top }, 0);");

                return $this;
            });
        }
    }

`macro`関数は、最初の引数に名前を取り、2番目にクロージャを取ります。マクロのクロージャは、`Browser`インスタンスのメソッドとしてマクロを呼び出したときに実行します。

    $this->browse(function ($browser) use ($user) {
        $browser->visit('/pay')
                ->scrollToElement('#credit-card-details')
                ->assertSee('Enter Credit Card Details');
    });

<a name="authentication"></a>
### 認証

多くの場合、認証が必要なページをテストすると思います。すべてのテスト中にアプリケーションのログイン画面と対話するのを回避するために、Duskの`loginAs`メソッドを使用できます。`loginAs`メソッドは、認証可能なモデルまたは認証可能なモデルインスタンスに関連付けられた主キーを引数に取ります。

    use App\Models\User;

    $this->browse(function ($browser) {
        $browser->loginAs(User::find(1))
              ->visit('/home');
    });

> {note} `loginAs`メソッドを使用した後、ファイル内のすべてのテストでユーザーセッションを維持します。

<a name="cookies"></a>
### クッキー

`cookie`メソッドを使用して、暗号化されたCookieの値を取得または設定できます。Laravelによって作成されたすべてのCookieはデフォルトで暗号化されています。

    $browser->cookie('name');

    $browser->cookie('name', 'Taylor');

暗号化していないクッキーの値を取得／セットするには、`plainCookie`メソッドを使います。

    $browser->plainCookie('name');

    $browser->plainCookie('name', 'Taylor');

指定クッキーを削除するには、`deleteCookie`メソッドを使います。

    $browser->deleteCookie('name');

<a name="executing-javascript"></a>
### JavaScriptの実行

`script`メソッドを使用して、ブラウザ内で任意のJavaScript文を実行できます。

    $output = $browser->script('document.documentElement.scrollTop = 0');

    $output = $browser->script([
        'document.body.scrollTop = 0',
        'document.documentElement.scrollTop = 0',
    ]);

<a name="taking-a-screenshot"></a>
### スクリーンショットの取得

スクリーンショットを取るには、`screenshot`メソッドを使います。指定したファイル名で保存されます。スクリーンショットはすべて、`tests/Browser/screenshots`ディレクトリへ保存します。

    $browser->screenshot('filename');

<a name="storing-console-output-to-disk"></a>
### コンソール出力をディスクへ保存

`storeConsoleLog`メソッドを使用して、現在のブラウザのコンソール出力を指定するファイル名でディスクへ書き込められます。コンソール出力は、`tests/Browser/console`ディレクトリへ保存します。

    $browser->storeConsoleLog('filename');

<a name="storing-page-source-to-disk"></a>
### ページソースをディスクへ保存する

`storeSource`メソッドを使用して、現在のページソースを指定するファイル名でディスクへ書き込みできます。ページソースは`tests/Browser/source`ディレクトリへ保存します。

    $browser->storeSource('filename');

<a name="interacting-with-elements"></a>
## 要素操作

<a name="dusk-selectors"></a>
### Duskセレクタ

要素と対話するための適切なCSSセレクタを選択することは、Duskテストを作成する上で最も難しい部分の1つです。時間の経過とともに、フロントエンドの変更により、次のようなCSSセレクタがテストを中断する可能性があります。

    // HTML…

    <button>Login</button>

    // Test…

    $browser->click('.login-page .container div > button');

Duskセレクタを使用すると、CSSセレクタを覚えるよりも、効果的なテストの作成に集中できます。セレクタを定義するには、HTML要素に`dusk`属性を追加します。次に、Duskブラウザを操作するときに、セレクタの前に`@`を付けて、テスト内でアタッチされた要素を操作します。

    // HTML

    <button dusk="login-button">Login</button>

    // Test...

    $browser->click('@login-button');

<a name="text-values-and-attributes"></a>
### テキスト、値、属性

<a name="retrieving-setting-values"></a>
#### 値の取得／設定

Duskは、ページ上の要素の現在の値、表示テキスト、属性を操作するための方法をいくつか提供します。たとえば、特定のCSSまたはDuskセレクタに一致する要素の「値」を取得するには、`value`メソッドを使用します。

    // 値の取得
    $value = $browser->value('selector');

    // 値の設定
    $browser->value('selector', 'value');

指定したフィールド名を持つインプット要素の「値」を取得するには、`inputValue`メソッドを使ってください。

    $value = $browser->inputValue('field');

<a name="retrieving-text"></a>
#### テキストの取得

`text`メソッドは、指定したセレクタに一致する要素の表示テキストを取得します。

    $text = $browser->text('selector');

<a name="retrieving-attributes"></a>
#### 属性の取得

最後に、`attribute`メソッドを使用して、指定するセレクタに一致する要素の属性の値を取得できます。

    $attribute = $browser->attribute('selector', 'value');

<a name="interacting-with-forms"></a>
### フォーム操作

<a name="typing-values"></a>
#### 値のタイプ

Duskはフォームと入力要素を操作する、さまざまなメソッドを提供しています。最初に、入力フィールドへテキストをタイプする例を見てみましょう。

    $browser->type('email', 'taylor@laravel.com');

このメソッドは必要に応じて１引数を取りますが、CSSセレクタを`type`メソッドに渡す必要はないことに注意してください。CSSセレクタが提供されていない場合、Duskは指定した`name`属性を持つ`input`または`textarea`フィールドを検索します。

コンテンツをクリアせずに、フィールドへテキストを追加するには、`append`メソッドを使用します。

    $browser->type('tags', 'foo')
            ->append('tags', ', bar, baz');

入力値をクリアするには、`clear`メソッドを使用します。

    $browser->clear('email');

`typeSlowly`メソッドによりDuskへゆっくりとタイプするように指示できます。Duskはデフォルトでキー押下間に１００ミリ秒の間隔を開けます。このキー押下間の時間をカスタマイズするには、メソッドの第３引数へ適切なミリ秒数を渡してください。

    $browser->typeSlowly('mobile', '+1 (202) 555-5555');

    $browser->typeSlowly('mobile', '+1 (202) 555-5555', 300);

テキストをゆっくりと追加するため、`appendSlowly`メソッドが使用できます。

    $browser->type('tags', 'foo')
            ->appendSlowly('tags', ', bar, baz');

<a name="dropdowns"></a>
#### ドロップダウン

`select`要素で使用可能な値を選択するには、`select`メソッドを使用できます。`type`メソッドと同様に、`select`メソッドは完全なCSSセレクタを必要としません。`select`メソッドに値を渡すときは、表示テキストの代わりに基になるオプション値を渡す必要があります。

    $browser->select('size', 'Large');

２番目の引数を省略すると、ランダムなオプションを選択できます。

    $browser->select('size');

<a name="checkboxes"></a>
#### チェックボックス

チェックボックス入力を「チェック」するには、`check`メソッドを使用します。他の多くの入力関連メソッドと同様に、完全なCSSセレクタは必要ありません。CSSセレクタの一致が見つからない場合、Duskは一致する`name`属性を持つチェックボックスを検索します。

    $browser->check('terms');

`uncheck`メソッドは、チェックボックス入力を「チェック解除」するために使用します。

    $browser->uncheck('terms');

<a name="radio-buttons"></a>
#### ラジオボタン

`radio`入力オプションを「選択」するには、`radio`メソッドを使用します。他の多くの入力関連メソッドと同様に、完全なCSSセレクタは必要ありません。CSSセレクタの一致が見つからない場合、Duskは「name」属性と「value」属性が一致する「radio」入力を検索します。

    $browser->radio('size', 'large');

<a name="attaching-files"></a>
### ファイルの添付

`attach`メソッドは、ファイルを`file`入力要素に添付するために使用します。他の多くの入力関連メソッドと同様に、完全なCSSセレクタは必要ありません。CSSセレクタの一致が見つからない場合、Duskは一致する`name`属性を持つ`file`入力を検索します。

    $browser->attach('photo', __DIR__.'/photos/mountains.png');

> {note} 添付機能を使用するには、サーバへ`Zip` PHP拡張機能をインストールし、有効にする必要があります。

<a name="pressing-buttons"></a>
### ボタンの押下

`press`メソッドを使用して、ページ上のボタン要素をクリックできます。`press`メソッドに与えられる最初の引数は、ボタンの表示テキストまたはCSS/Duskセレクタのどちらかです。

    $browser->press('Login');

フォームを送信する場合、多くのアプリケーションは、フォームが押された後にフォームの送信ボタンを無効にし、フォーム送信のHTTPリクエストが完了したときにボタンを再度有効にします。ボタンを押してボタンが再度有効になるのを待つには、`pressAndWaitFor`メソッドを使用します。

    // ボタンを押して、有効になるまで最大5秒待つ
    $browser->pressAndWaitFor('Save');

    // ボタンを押して、有効になるまで最大1秒待つ
    $browser->pressAndWaitFor('Save', 1);

<a name="clicking-links"></a>
### リンクのクリック

リンクをクリックするには、ブラウザインスタンスで`clickLink`メソッドを使用します。`clickLink`メソッドは、指定した表示テキストを持つリンクをクリックします。

    $browser->clickLink($linkText);

`seeLink`メソッドを使用して、指定する表示テキストのリンクがページに表示されているかどうかを確認できます。

    if ($browser->seeLink($linkText)) {
        // ...
    }

> {note} これらのメソッドはjQueryを操作します。jQueryがページで利用できない場合、Duskは自動的にそれをページに挿入して、テストの期間中利用できるようにします。

<a name="using-the-keyboard"></a>
### キーボードの使用

`keys`メソッドを使用すると、`type`メソッドで通常できるより複雑な入力シーケンスを特定の要素に提供できます。たとえば、値を入力するときに修飾キーを押したままにするようにDuskに指示できます。以下の例では、指定したセレクタに一致する要素へ`taylor`を入力している間、`shift`キーが押されます。`taylor`の入力後、`swift`が修飾キーなしで入力されます。

    $browser->keys('selector', ['{shift}', 'taylor'], 'swift');

`keys`メソッドのもう1つの有益な使用例は、アプリケーションのプライマリCSSセレクタに「キーボードショートカット」の組み合わせを送信することです。

    $browser->keys('.app', ['{command}', 'j']);

> {tip} `{command}`など、すべての修飾キーは`{}`文字でラップし、[GitHubで見つかる](https://github.com/php-webdriver/php-webdriver/blob/master/lib/WebDriverKeys.php)`Facebook\WebDriver\WebDriverKeys`クラスで定義された定数です。

<a name="using-the-mouse"></a>
### マウスの使用

<a name="clicking-on-elements"></a>
#### 要素のクリック

`click`メソッドを使用して、指定したCSSまたはDuskセレクタに一致する要素をクリックできます。

    $browser->click('.selector');

`clickAtXPath`メソッドを使用して、指定したXPath式に一致する要素をクリックできます。

    $browser->clickAtXPath('//div[@class = "selector"]');

`clickAtPoint`メソッドを使用して、ブラウザの表示可能領域を基準にした特定の座標ペアで最上位の要素をクリックできます。

    $browser->clickAtPoint($x = 0, $y = 0);

`doubleClick`メソッドを使用して、マウスのダブルクリックをシミュレートできます。

    $browser->doubleClick();

`rightClick`メソッドを使用して、マウスの右クリックをシミュレートできます。

    $browser->rightClick();

    $browser->rightClick('.selector');

`clickAndHold`メソッドを使用して、マウスボタンがクリックされたままにしている状況をシミュレートできます。その後の`releaseMouse`メソッドの呼び出しは、この動作を元に戻し、マウスボタンを離します。

    $browser->clickAndHold()
            ->pause(1000)
            ->releaseMouse();

<a name="mouseover"></a>
#### マウスオーバ

`mouseover`メソッドは、指定したCSSまたはDuskセレクタに一致する要素の上にマウスを移動する必要がある場合に使用します。

    $browser->mouseover('.selector');

<a name="drag-drop"></a>
#### ドラッグ・アンド・ドロップ

`drag`メソッドを使用して、指定したセレクタに一致する要素を別の要素にドラッグできます。

    $browser->drag('.from-selector', '.to-selector');

または、要素を一方向にドラッグすることもできます。

    $browser->dragLeft('.selector', $pixels = 10);
    $browser->dragRight('.selector', $pixels = 10);
    $browser->dragUp('.selector', $pixels = 10);
    $browser->dragDown('.selector', $pixels = 10);

最後に、指定したオフセットで要素をドラッグできます。

    $browser->dragOffset('.selector', $x = 10, $y = 10);

<a name="javascript-dialogs"></a>
### JavaScriptダイアログ

Duskは、JavaScriptダイアログを操作するためにさまざまなメソッドを提供しています。たとえば、`waitForDialog`メソッドを使用して、JavaScriptダイアログが表示されるまで待機できます。このメソッドは、ダイアログが表示されるまで何秒待つかを示すオプションの引数を受け入れます。

    $browser->waitForDialog($seconds = null);

`assertDialogOpened`メソッドを使用して、ダイアログが表示され、指定するメッセージが含まれていることを宣言できます。

    $browser->assertDialogOpened('Dialog message');

JavaScriptダイアログにプロンプ​​トが含​​まれている場合は、`typeInDialog`メソッドを使用してプロンプトに値を入力できます。

    $browser->typeInDialog('Hello World');

"OK"ボタンをクリックして開いているJavaScriptダイアログを閉じるには、`acceptDialog`メソッドを呼び出します。

    $browser->acceptDialog();

[キャンセル]ボタンをクリックして開いているJavaScriptダイアログを閉じるには、`dismissDialog`メソッドを呼び出します。

    $browser->dismissDialog();

<a name="scoping-selectors"></a>
### セレクタの範囲指定

特定のセレクタ内のすべての操作をスコープしながら、いくつかの操作を実行したい場合があります。たとえば、一部のテキストがテーブル内にのみ存在することを宣言してから、そのテーブル内のボタンをクリックしたい場合があります。これを実現するには、`with`メソッドを使用できます。`with`メソッドに与えられたクロージャ内で実行されるすべての操作は、元のセレクタにスコープされます。

    $browser->with('.table', function ($table) {
        $table->assertSee('Hello World')
              ->clickLink('Delete');
    });

現在のスコープ外でアサートを実行する必要がある場合があります。これを実現するには、`elsewhere`メソッドを使用できます。

     $browser->with('.table', function ($table) {
        // 現在のスコープは`body .table`

        $browser->elsewhere('.page-title', function ($title) {
            // 現在のスコープは`body .page-title`
            $title->assertSee('Hello World');
        });

        $browser->elsewhereWhenAvailable('.page-title', function ($title) {
            // 現在のスコープは`body. page-title`
            $title->assertSee('Hello World');
        });
     });

<a name="waiting-for-elements"></a>
### 要素の待機

広範囲に渡りJavaScriptを使用しているアプリケーションのテストでは、テストを進める前に特定の要素やデータが利用可能になるまで、「待つ(wait)」必要がしばしば起きます。Duskではこれも簡単に行えます。数多くのメソッドを使い、ページで要素が見えるようになるまで、もしくはJavaScriptの評価が`true`になるまで待機できます。

<a name="waiting"></a>
#### 待機

指定するミリ秒数だけテストを一時停止する必要がある場合は、`pause`メソッドを使用します。

    $browser->pause(1000);

<a name="waiting-for-selectors"></a>
#### セレクタの待機

`waitFor`メソッドを使用して、指定するCSSまたはDuskセレクタに一致する要素がページに表示されるまでテストの実行を一時停止できます。デフォルトでは、これは例外をスローする前に最大5秒間テストを一時停止します。必要に応じて、メソッドの２番目の引数にカスタムタイムアウトしきい値を渡せます。

    // セレクタを最長５秒間待つ
    $browser->waitFor('.selector');

    // セレクタを最長１秒待つ
    $browser->waitFor('.selector', 1);

指定するセレクタに一致する要素に指定するテキストが含まれるまで待つこともできます。

    // セレクタが指定テキストを持つまで、最長５秒待つ
    $browser->waitForTextIn('.selector', 'Hello World');

    // セレクタが指定テキストを持つまで、最長５秒待つ
    $browser->waitForTextIn('.selector', 'Hello World', 1);

指定するセレクタに一致する要素がページから無くなるまで待つこともできます。

    // セレクタが消えるまで、最長５秒待つ
    $browser->waitUntilMissing('.selector');

    // セレクタが消えるまで、最長１秒待つ
    $browser->waitUntilMissing('.selector', 1);

<a name="scoping-selectors-when-available"></a>
#### 利用可能時限定のセレクタ

場合によっては、特定のセレクタに一致する要素が表示されるのを待ってから、その要素と対話したいことがあります。たとえば、モーダルウィンドウが使用可能になるまで待ってから、モーダル内の"OK"ボタンを押すことができます。これを実現するには、`whenAvailable`メソッドを使用します。指定するクロージャ内で実行されるすべての要素操作は、元のセレクタにスコープされます。

    $browser->whenAvailable('.modal', function ($modal) {
        $modal->assertSee('Hello World')
              ->press('OK');
    });

<a name="waiting-for-text"></a>
#### テキストの待機

指定したテキストがページに表示されるまで待ちたい場合は、`waitForText`メソッドを使います。

    // テキストを最大５秒間待つ
    $browser->waitForText('Hello World');

    // テキストを最大１秒待つ
    $browser->waitForText('Hello World', 1);

ページに表示されている指定したテキストが削除されるまで待ちたい場合は、`waitUntilMissingText`メソッドを使います。

    // テキストが削除されるまで最大５秒間待つ
    $browser->waitUntilMissingText('Hello World');

    // テキストが削除されるまで最大１秒間待つ
    $browser->waitUntilMissingText('Hello World', 1);

<a name="waiting-for-links"></a>
#### リンクの待機

ページに指定したリンクテキストが表示されるまで待つ場合は、`waitForLink`メソッドを使います。

    // リンクを最大５秒間待つ
    $browser->waitForLink('Create');

    // リンクを最大１秒間待つ
    $browser->waitForLink('Create', 1);

<a name="waiting-on-the-page-location"></a>
#### ページロケーションの待機

`$browser->assertPathIs('/home')`のようなパスをアサートするときに、`window.location.pathname`が非同期更新中の場合、アサートは失敗するでしょう。指定値のロケーションを待機するために、`waitForLocation`メソッドを使ってください。

    $browser->waitForLocation('/secret');

[名前付きルート](/docs/{{version}}/routing#named-routes)のロケーションを待機することも可能です。

    $browser->waitForRoute($routeName, $parameters);

<a name="waiting-for-page-reloads"></a>
#### ページリロードの待機

ページのリロード後にアサートする必要がある場合は、`waitForReload`メソッドを使ってください。

    $browser->click('.some-action')
            ->waitForReload()
            ->assertSee('something');

<a name="waiting-on-javascript-expressions"></a>
#### JavaScriptの評価の待機

指定したJavaScript式の評価が`true`になるまで、テストの実行を中断したい場合もときどきあります。`waitUntil`メソッドで簡単に行えます。このメソッドに式を渡す時に、`return`キーワードや最後のセミコロンを含める必要はありません。

    // 式がtrueになるまで最大５秒間待つ
    $browser->waitUntil('App.data.servers.length > 0');

    // 式がtrueになるまで最大１秒間待つ
    $browser->waitUntil('App.data.servers.length > 0', 1);

<a name="waiting-on-vue-expressions"></a>
#### Vue式の待機

`waitUntilVue`メソッドと`waitUntilVueIsNot`メソッドを使用して、[Vueコンポーネント](https://vuejs.org)属性が指定した値になるまで待機できます。

    // コンポーネント属性に指定した値が含まれるまで待つ
    $browser->waitUntilVue('user.name', 'Taylor', '@user');

    // コンポーネント属性に指定した値が含まれなくなるまで待つ
    $browser->waitUntilVueIsNot('user.name', null, '@user');

<a name="waiting-with-a-callback"></a>
#### コールバックによる待機

Duskの"wait"メソッドの多くは、基盤となる`waitUsing`メソッドに依存しています。このメソッドを直接使用して、特定のクロージャが`true`を返すのを待つことができます。`waitUsing`メソッドは、待機する最大秒数、クロージャを評価する間隔、クロージャ、およびオプションの失敗メッセージを引数に取ります。

    $browser->waitUsing(10, 1, function () use ($something) {
        return $something->isReady();
    }, "Something wasn't ready in time.");

<a name="scrolling-an-element-into-view"></a>
### 要素をスクロールしてビューに表示

要素がブラウザの表示可能領域の外にあるために、要素をクリックできない場合があります。`scrollIntoView`メソッドは、指定したセレクタの要素がビュー内に入るまでブラウザウィンドウをスクロールします。

    $browser->scrollIntoView('.selector')
            ->click('.selector');

<a name="available-assertions"></a>
## 使用可能なアサート

Duskはアプリケーションに対する数多くのアサートを提供しています。使用できるアサートを以下のリストにまとめます。

<style>
    .collection-method-list > p {
        column-count: 3; -moz-column-count: 3; -webkit-column-count: 3;
        column-gap: 2em; -moz-column-gap: 2em; -webkit-column-gap: 2em;
    }

    .collection-method-list a {
        display: block;
    }
</style>

<div class="collection-method-list" markdown="1">
[assertTitle](#assert-title)
[assertTitleContains](#assert-title-contains)
[assertUrlIs](#assert-url-is)
[assertSchemeIs](#assert-scheme-is)
[assertSchemeIsNot](#assert-scheme-is-not)
[assertHostIs](#assert-host-is)
[assertHostIsNot](#assert-host-is-not)
[assertPortIs](#assert-port-is)
[assertPortIsNot](#assert-port-is-not)
[assertPathBeginsWith](#assert-path-begins-with)
[assertPathIs](#assert-path-is)
[assertPathIsNot](#assert-path-is-not)
[assertRouteIs](#assert-route-is)
[assertQueryStringHas](#assert-query-string-has)
[assertQueryStringMissing](#assert-query-string-missing)
[assertFragmentIs](#assert-fragment-is)
[assertFragmentBeginsWith](#assert-fragment-begins-with)
[assertFragmentIsNot](#assert-fragment-is-not)
[assertHasCookie](#assert-has-cookie)
[assertHasPlainCookie](#assert-has-plain-cookie)
[assertCookieMissing](#assert-cookie-missing)
[assertPlainCookieMissing](#assert-plain-cookie-missing)
[assertCookieValue](#assert-cookie-value)
[assertPlainCookieValue](#assert-plain-cookie-value)
[assertSee](#assert-see)
[assertDontSee](#assert-dont-see)
[assertSeeIn](#assert-see-in)
[assertDontSeeIn](#assert-dont-see-in)
[assertSeeAnythingIn](#assert-see-anything-in)
[assertSeeNothingIn](#assert-see-nothing-in)
[assertScript](#assert-script)
[assertSourceHas](#assert-source-has)
[assertSourceMissing](#assert-source-missing)
[assertSeeLink](#assert-see-link)
[assertDontSeeLink](#assert-dont-see-link)
[assertInputValue](#assert-input-value)
[assertInputValueIsNot](#assert-input-value-is-not)
[assertChecked](#assert-checked)
[assertNotChecked](#assert-not-checked)
[assertRadioSelected](#assert-radio-selected)
[assertRadioNotSelected](#assert-radio-not-selected)
[assertSelected](#assert-selected)
[assertNotSelected](#assert-not-selected)
[assertSelectHasOptions](#assert-select-has-options)
[assertSelectMissingOptions](#assert-select-missing-options)
[assertSelectHasOption](#assert-select-has-option)
[assertSelectMissingOption](#assert-select-missing-option)
[assertValue](#assert-value)
[assertAttribute](#assert-attribute)
[assertAriaAttribute](#assert-aria-attribute)
[assertDataAttribute](#assert-data-attribute)
[assertVisible](#assert-visible)
[assertPresent](#assert-present)
[assertNotPresent](#assert-not-present)
[assertMissing](#assert-missing)
[assertDialogOpened](#assert-dialog-opened)
[assertEnabled](#assert-enabled)
[assertDisabled](#assert-disabled)
[assertButtonEnabled](#assert-button-enabled)
[assertButtonDisabled](#assert-button-disabled)
[assertFocused](#assert-focused)
[assertNotFocused](#assert-not-focused)
[assertAuthenticated](#assert-authenticated)
[assertGuest](#assert-guest)
[assertAuthenticatedAs](#assert-authenticated-as)
[assertVue](#assert-vue)
[assertVueIsNot](#assert-vue-is-not)
[assertVueContains](#assert-vue-contains)
[assertVueDoesNotContain](#assert-vue-does-not-contain)
</div>

<a name="assert-title"></a>
#### assertTitle

ページタイトルが指定した文字列と一致することを宣言します。

    $browser->assertTitle($title);

<a name="assert-title-contains"></a>
#### assertTitleContains

ページタイトルに、指定したテキストが含まれていることを宣言します。

    $browser->assertTitleContains($title);

<a name="assert-url-is"></a>
#### assertUrlIs

クエリ文字列を除いた、現在のURLが指定した文字列と一致するのを宣言します。

    $browser->assertUrlIs($url);

<a name="assert-scheme-is"></a>
#### assertSchemeIs

現在のURLスキームが、指定したスキームと一致することを宣言します。

    $browser->assertSchemeIs($scheme);

<a name="assert-scheme-is-not"></a>
#### assertSchemeIsNot

現在のURLスキームが、指定したスキームと一致しないことを宣言します。

    $browser->assertSchemeIsNot($scheme);

<a name="assert-host-is"></a>
#### assertHostIs

現在のURLのホストが、指定したホストと一致することを宣言します。

    $browser->assertHostIs($host);

<a name="assert-host-is-not"></a>
#### assertHostIsNot

現在のURLのホストが、指定したホストと一致しないことを宣言します。

    $browser->assertHostIsNot($host);

<a name="assert-port-is"></a>
#### assertPortIs

現在のURLポートが、指定したポートと一致することを宣言します。

    $browser->assertPortIs($port);

<a name="assert-port-is-not"></a>
#### assertPortIsNot

現在のURLポートが、指定したポートと一致しないことを宣言します。

    $browser->assertPortIsNot($port);

<a name="assert-path-begins-with"></a>
#### assertPathBeginsWith

現在のURLパスが指定したパスで始まることを宣言します。

    $browser->assertPathBeginsWith('/home');

<a name="assert-path-is"></a>
#### assertPathIs

現在のパスが指定したパスであることを宣言します。

    $browser->assertPathIs('/home');

<a name="assert-path-is-not"></a>
#### assertPathIsNot

現在のパスが指定したパスではないことを宣言します。

    $browser->assertPathIsNot('/home');

<a name="assert-route-is"></a>
#### assertRouteIs

現在のURLが指定する[名前付きルート](/docs/{{version}}/routing#named-routes)のURLと一致することを表明します。

    $browser->assertRouteIs($name, $parameters);

<a name="assert-query-string-has"></a>
#### assertQueryStringHas

指定したクエリ文字列パラメータが存在していることを宣言します。

    $browser->assertQueryStringHas($name);

指定したクエリ文字列パラメータが存在し、指定値を持っていることを宣言します。

    $browser->assertQueryStringHas($name, $value);

<a name="assert-query-string-missing"></a>
#### assertQueryStringMissing

指定した文字列パラメータが存在しないことを宣言します。

    $browser->assertQueryStringMissing($name);

<a name="assert-fragment-is"></a>
#### assertFragmentIs

URLの現在のハッシュフラグメントが指定するフラグメントと一致することを宣言します。

    $browser->assertFragmentIs('anchor');

<a name="assert-fragment-begins-with"></a>
#### assertFragmentBeginsWith

URLの現在のハッシュフラグメントが指定するフラグメントで始まることを宣言します。

    $browser->assertFragmentBeginsWith('anchor');

<a name="assert-fragment-is-not"></a>
#### assertFragmentIsNot

URLの現在のハッシュフラグメントが指定するフラグメントと一致しないことを宣言します。

    $browser->assertFragmentIsNot('anchor');

<a name="assert-has-cookie"></a>
#### assertHasCookie

指定した暗号化クッキーが存在することを宣言します。

    $browser->assertHasCookie($name);

<a name="assert-has-plain-cookie"></a>
#### assertHasPlainCookie

指定した暗号化していないクッキーが存在していることを宣言します。

    $browser->assertHasPlainCookie($name);

<a name="assert-cookie-missing"></a>
#### assertCookieMissing

指定した暗号化クッキーが存在していないことを宣言します。

    $browser->assertCookieMissing($name);

<a name="assert-plain-cookie-missing"></a>
#### assertPlainCookieMissing

指定した暗号化していないクッキーが存在していないことを宣言します。

    $browser->assertPlainCookieMissing($name);

<a name="assert-cookie-value"></a>
#### assertCookieValue

指定した暗号化クッキーが、指定値を持っていることを宣言します。

    $browser->assertCookieValue($name, $value);

<a name="assert-plain-cookie-value"></a>
#### assertPlainCookieValue

暗号化されていないクッキーが、指定値を持っていることを宣言します。

    $browser->assertPlainCookieValue($name, $value);

<a name="assert-see"></a>
#### assertSee

指定したテキストが、ページ上に存在することを宣言します。

    $browser->assertSee($text);

<a name="assert-dont-see"></a>
#### assertDontSee

指定したテキストが、ページ上に存在しないことを宣言します。

    $browser->assertDontSee($text);

<a name="assert-see-in"></a>
#### assertSeeIn

指定したテキストが、セレクタに含まれていることを宣言します。

    $browser->assertSeeIn($selector, $text);

<a name="assert-dont-see-in"></a>
#### assertDontSeeIn

指定したテキストが、セレクタに含まれていないことを宣言します。

    $browser->assertDontSeeIn($selector, $text);

<a name="assert-see-anything-in"></a>
#### assertSeeAnythingIn

セレクタ内にテキストが存在することを宣言します。

    $browser->assertSeeAnythingIn($selector);

<a name="assert-see-nothing-in"></a>
#### assertSeeNothingIn

セレクタ内にテキストが存在しないことを宣言します。

    $browser->assertSeeNothingIn($selector);

<a name="assert-script"></a>
#### assertScript

指定するJavaScript式の評価結果が指定値であることを宣言します。

    $browser->assertScript('window.isLoaded')
            ->assertScript('document.readyState', 'complete');

<a name="assert-source-has"></a>
#### assertSourceHas

指定したソースコードが、ページ上に存在していることを宣言します。

    $browser->assertSourceHas($code);

<a name="assert-source-missing"></a>
#### assertSourceMissing

指定したソースコードが、ページ上に存在していないことを宣言します。

    $browser->assertSourceMissing($code);

<a name="assert-see-link"></a>
#### assertSeeLink

指定したリンクが、ページ上に存在していることを宣言します。

    $browser->assertSeeLink($linkText);

<a name="assert-dont-see-link"></a>
#### assertDontSeeLink

指定したリンクが、ページ上に存在していないことを宣言します。

    $browser->assertDontSeeLink($linkText);

<a name="assert-input-value"></a>
#### assertInputValue

指定した入力フィールドが、指定値を持っていることを宣言します。

    $browser->assertInputValue($field, $value);

<a name="assert-input-value-is-not"></a>
#### assertInputValueIsNot

指定した入力フィールドが、指定値を持っていないことを宣言します。

    $browser->assertInputValueIsNot($field, $value);

<a name="assert-checked"></a>
#### assertChecked

指定したチェックボックスが、チェック済みであることを宣言します。

    $browser->assertChecked($field);

<a name="assert-not-checked"></a>
#### assertNotChecked

指定したチェックボックスが、チェックされていないことを宣言します。

    $browser->assertNotChecked($field);

<a name="assert-radio-selected"></a>
#### assertRadioSelected

指定したラジオフィールドが選択されていることを宣言します。

    $browser->assertRadioSelected($field, $value);

<a name="assert-radio-not-selected"></a>
#### assertRadioNotSelected

指定したラジオフィールドが選択されていないことを宣言します。

    $browser->assertRadioNotSelected($field, $value);

<a name="assert-selected"></a>
#### assertSelected

指定したドロップダウンで指定値が選択されていることを宣言します。

    $browser->assertSelected($field, $value);

<a name="assert-not-selected"></a>
#### assertNotSelected

指定したドロップダウンで指定値が選択されていないことを宣言します。

    $browser->assertNotSelected($field, $value);

<a name="assert-select-has-options"></a>
#### assertSelectHasOptions

指定した配列値が選択可能であることを宣言します。

    $browser->assertSelectHasOptions($field, $values);

<a name="assert-select-missing-options"></a>
#### assertSelectMissingOptions

指定した配列値が選択不可であることを宣言します。

    $browser->assertSelectMissingOptions($field, $values);

<a name="assert-select-has-option"></a>
#### assertSelectHasOption

指定したフィールドで、指定した値が選択可能であることを宣言します。

    $browser->assertSelectHasOption($field, $value);

<a name="assert-select-missing-option"></a>
#### assertSelectMissingOption

指定する値が選択できないことを宣言します。

    $browser->assertSelectMissingOption($field, $value);

<a name="assert-value"></a>
#### assertValue

指定したセレクタに一致する要素が、指定値であることを宣言します。

    $browser->assertValue($selector, $value);

<a name="assert-attribute"></a>
#### assertAttribute

指定セレクタにマッチする要素が、指定属性に指定値を持っていることを宣言します。

    $browser->assertAttribute($selector, $attribute, $value);

<a name="assert-aria-attribute"></a>
#### assertAriaAttribute

指定セレクタにマッチする要素が、指定aria属性に指定値を持っていることを宣言します。

    $browser->assertAriaAttribute($selector, $attribute, $value);

たとえば、指定するマークアップが`<button aria-label="Add"></button>`であり、`aria-label`に対して宣言する場合は、次のようになります。

    $browser->assertAriaAttribute('button', 'label', 'Add')

<a name="assert-data-attribute"></a>
#### assertDataAttribute

指定したセレクタに一致する要素が、指定データ属性に指定値を持っていることを宣言します。

    $browser->assertDataAttribute($selector, $attribute, $value);

たとえば、指定するマークアップが`<tr id="row-1" data-content="attendees"></tr>`であり、`data-label`属性に対して宣言をする場合、次のようになります。

    $browser->assertDataAttribute('#row-1', 'content', 'attendees')

<a name="assert-visible"></a>
#### assertVisible

指定したセレクタに一致する要素が、ビジブルであることを宣言します。

    $browser->assertVisible($selector);

<a name="assert-present"></a>
#### assertPresent

指定したセレクタに一致する要素が、存在することを宣言します。

    $browser->assertPresent($selector);

<a name="assert-not-present"></a>
#### assertNotPresent

指定したセレクタに一致する要素が、ソースに存在しないことを宣言します。

    $browser->assertNotPresent($selector);

<a name="assert-missing"></a>
#### assertMissing

指定したセレクタに一致する要素が、ビジブルでないことを宣言します。

    $browser->assertMissing($selector);

<a name="assert-dialog-opened"></a>
#### assertDialogOpened

指定したメッセージを持つ、JavaScriptダイアログが開かれていることを宣言します。

    $browser->assertDialogOpened($message);

<a name="assert-enabled"></a>
#### assertEnabled

指定したフィールドが、enabledであることを宣言します。

    $browser->assertEnabled($field);

<a name="assert-disabled"></a>
#### assertDisabled

指定したフィールドが、disabledであることを宣言します。

    $browser->assertDisabled($field);

<a name="assert-button-enabled"></a>
#### assertButtonEnabled

指定したボタンが、enabledであることを宣言します。

    $browser->assertButtonEnabled($button);

<a name="assert-button-disabled"></a>
#### assertButtonDisabled

指定したボタンが、disabledであることを宣言します。

    $browser->assertButtonDisabled($button);

<a name="assert-focused"></a>
#### assertFocused

指定したフィールドに、フォーカスがあることを宣言します。

    $browser->assertFocused($field);

<a name="assert-not-focused"></a>
#### assertNotFocused

指定したフィールドから、フォーカスが外れていることを宣言します。

    $browser->assertNotFocused($field);

<a name="assert-authenticated"></a>
#### assertAuthenticated

そのユーザーが認証済みであることを宣言します。

    $browser->assertAuthenticated();

<a name="assert-guest"></a>
#### assertGuest

そのユーザーが認証されていないことを宣言します。

    $browser->assertGuest();

<a name="assert-authenticated-as"></a>
#### assertAuthenticatedAs

そのユーザーが指定したユーザーとして認証されていることを宣言します。

    $browser->assertAuthenticatedAs($user);

<a name="assert-vue"></a>
#### assertVue

Duskでは、[Vueコンポーネント](https://vuejs.org)データの状態についてアサーションを作成することもできます。たとえば、アプリケーションに次のVueコンポーネントが含まれているとします。

    // HTML…

    <profile dusk="profile-component"></profile>

    // コンポーネント定義…

    Vue.component('profile', {
        template: '<div>{{ user.name }}</div>',

        data: function () {
            return {
                user: {
                    name: 'Taylor'
                }
            };
        }
    });

次のように、Vueコンポーネントの状態を宣言できます。

    /**
     * 基本的なVueテストの例
     *
     * @return void
     */
    public function testVue()
    {
        $this->browse(function (Browser $browser) {
            $browser->visit('/')
                    ->assertVue('user.name', 'Taylor', '@profile-component');
        });
    }

<a name="assert-vue-is-not"></a>
#### assertVueIsNot

指定したVueコンポーネントのデータプロパティが、指定値と一致しないことを宣言します。

    $browser->assertVueIsNot($property, $value, $componentSelector = null);

<a name="assert-vue-contains"></a>
#### assertVueContains

指定したVueコンポーネントのデータプロパティが配列で、指定値を含むことを宣言します。

    $browser->assertVueContains($property, $value, $componentSelector = null);

<a name="assert-vue-does-not-contain"></a>
#### assertVueDoesNotContain

指定したVueコンポーネントのデータプロパティが配列で、指定値を含まないことを宣言します。

    $browser->assertVueDoesNotContain($property, $value, $componentSelector = null);

<a name="pages"></a>
## ページ

テストでは、いくつかの複雑なアクションを順番に実行する必要がある場合があります。これにより、テストが読みにくくなり、理解しにくくなる可能性があります。Duskページでは、一つのメソッドにより指定ページで実行できる表現力豊かなアクションを定義できます。ページを使用すると、アプリケーションまたは単一ページの一般的なセレクタへのショートカットを定義することもできます。

<a name="generating-pages"></a>
### ページの生成

ページオブジェクトを生成するには、`dusk:page` Artisanコマンドを実行します。すべてのページオブジェクトは、アプリケーションの`tests/Browser/Pages`ディレクトリに配置されます。

    php artisan dusk:page Login

<a name="configuring-pages"></a>
### ページの設定

デフォルトでページには、`url`、`assert`、`elements`の３メソッドが用意されています。`url`と`assert`メソッドは、この後説明します。`elements`メソッドについては、[のちほど詳細を紹介](#shorthand-selectors)します。

<a name="the-url-method"></a>
#### `url`メソッド

`url`メソッドでは、そのページを表すURLのパスを返します。Duskはブラウザでこのページへ移動するとき、このURLを使用します。

    /**
     * このページのURL取得
     *
     * @return string
     */
    public function url()
    {
        return '/login';
    }

<a name="the-assert-method"></a>
#### `assert`メソッド

assert`メソッドは、ブラウザが実際に指定したページを訪れていることを確認するために必要なアサートができます。このメソッドに実際に何かを記述する必要はありませんが、必要に応じて自由にアサーションを行えます。これらのアサーションは、ページに移動する際に自動的に実行されます。

    /**
     * ブラウザがページ上にあることを宣言
     *
     * @return void
     */
    public function assert(Browser $browser)
    {
        $browser->assertPathIs($this->url());
    }

<a name="navigating-to-pages"></a>
### ページへのナビゲーション

ページが定義できたら、`visit`メソッドを使用してそのページに移動します。

    use Tests\Browser\Pages\Login;

    $browser->visit(new Login);

すでに特定のページに移動済みで、現在のテストコンテキストへそのページのセレクタとメソッドを「ロード」する必要が起き得ます。この状況は、明示的に移動していなくても、あるボタンを押すことで指定ページへリダイレクトしてしまう場合に発生します。そうした場合は、`on`メソッドで、そのページをロードできます。

    use Tests\Browser\Pages\CreatePlaylist;

    $browser->visit('/dashboard')
            ->clickLink('Create Playlist')
            ->on(new CreatePlaylist)
            ->assertSee('@create');

<a name="shorthand-selectors"></a>
### セレクタの簡略記述

ページクラス内の`elements`メソッドを使用すると、ページ上の任意のCSSセレクタのすばやく覚えやすいショートカットを定義できます。たとえば、アプリケーションのログインページの"email"入力フィールドのショートカットを定義しましょう。

    /**
     * ページ要素の短縮形を取得
     *
     * @return array
     */
    public function elements()
    {
        return [
            '@email' => 'input[name=email]',
        ];
    }

ショートカットを定義したら、通常は完全なCSSセレクタを使用する場所であればどこでもショートカットセレクタを使用できます。

    $browser->type('@email', 'taylor@laravel.com');

<a name="global-shorthand-selectors"></a>
#### グローバルなセレクタ簡略記述

Duskをインストールすると、ベース`Page`クラスが`tests/Browser/Pages`ディレクトリへ設置されます。このクラスは、アプリケーション全部のどのページからでも利用可能な、グローバル短縮セレクタを定義する`siteElements`メソッドを含んでいます。

    /**
     * サイトのグローバル要素短縮形の取得
     *
     * @return array
     */
    public static function siteElements()
    {
        return [
            '@element' => '#selector',
        ];
    }

<a name="page-methods"></a>
### ページメソッド

ページに対し定義済みのデフォルトメソッドに加え、テスト全体で使用できる追加メソッドも定義できます。たとえば、音楽管理アプリケーションを構築中だと想像してみましょう。アプリケーションのあるページでプレイリストを作成するのは、よくあるアクションです。各テストごとにプレイリスト作成のロジックを書き直す代わりに、ページクラスに`createPlaylist`メソッドを定義できます。

    <?php

    namespace Tests\Browser\Pages;

    use Laravel\Dusk\Browser;

    class Dashboard extends Page
    {
        // 他のページメソッドの定義…

        /**
         * 新しいプレイリストの作成
         *
         * @param  \Laravel\Dusk\Browser  $browser
         * @param  string  $name
         * @return void
         */
        public function createPlaylist(Browser $browser, $name)
        {
            $browser->type('name', $name)
                    ->check('share')
                    ->press('Create Playlist');
        }
    }

メソッドを定義したら、ページを利用する任意のテスト内でメソッドを使用できます。ブラウザインスタンスは、カスタムページメソッドの最初の引数として自動的に渡されます。

    use Tests\Browser\Pages\Dashboard;

    $browser->visit(new Dashboard)
            ->createPlaylist('My Playlist')
            ->assertSee('My Playlist');

<a name="components"></a>
## コンポーネント

コンポーネントはDuskの「ページオブジェクト」と似ていますが、ナビゲーションバーや通知ウィンドウのような、UI群と機能をアプリケーション全体で再利用するためのものです。コンポーネントは特定のURLと結びついていません。

<a name="generating-components"></a>
### コンポーネント生成

コンポーネントを生成するには、`dusk:component` Artisanコマンドを実行します。新しいコンポーネントは`tests/Browser/Components`ディレクトリへ配置します。

    php artisan dusk:component DatePicker

上記の「日付ピッカー」は、アプリケーション全体のさまざまなページで利用されるコンポーネントの一例です。テストスーツ全体の何ダースものテスト中で、日付を選択するブラウザ自動化ロジックを一々書くのは大変な手間です。その代わりに、日付ピッカーを表すDuskコンポーネントを定義し、そうしたロジックをコンポーネントへカプセル化できます。

    <?php

    namespace Tests\Browser\Components;

    use Laravel\Dusk\Browser;
    use Laravel\Dusk\Component as BaseComponent;

    class DatePicker extends BaseComponent
    {
        /**
         * コンポーネントのルートセレクタ取得
         *
         * @return string
         */
        public function selector()
        {
            return '.date-picker';
        }

        /**
         * ブラウザページにそのコンポーネントが含まれていることを宣言
         *
         * @param  Browser  $browser
         * @return void
         */
        public function assert(Browser $browser)
        {
            $browser->assertVisible($this->selector());
        }

        /**
         * コンポーネントの要素のショートカットを取得
         *
         * @return array
         */
        public function elements()
        public function selectDate(Browser $browser, $year, $month, $day)
            return [
                '@date-field' => 'input.datepicker-input',
                '@year-list' => 'div > div.datepicker-years',
                '@month-list' => 'div > div.datepicker-months',
                '@day-list' => 'div > div.datepicker-days',
            ];
        }

        /**
         * 指定日付のセレクト
         *
         * @param  \Laravel\Dusk\Browser  $browser
         * @param  int  $year
         * @param  int  $month
         * @param  int  $day
         * @return void
         */
        public function selectDate(Browser $browser, $year, $month, $day)
        {
            $browser->click('@date-field')
                    ->within('@year-list', function ($browser) use ($year) {
                        $browser->click($year);
                    })
                    ->within('@month-list', function ($browser) use ($month) {
                        $browser->click($month);
                    })
                    ->within('@day-list', function ($browser) use ($day) {
                        $browser->click($day);
                    });
        }
    }

<a name="using-components"></a>
### コンポーネントの使用

コンポーネントを定義したら、全テスト中からデートピッカーの中の指定日付を簡単にセレクトできます。日付選択で必要なロジックに変更が起きたら、このコンポーネントを更新するだけです。

    <?php

    namespace Tests\Browser;

    use Illuminate\Foundation\Testing\DatabaseMigrations;
    use Laravel\Dusk\Browser;
    use Tests\Browser\Components\DatePicker;
    use Tests\DuskTestCase;

    class ExampleTest extends DuskTestCase
    {
        /**
         * 基本的なコンポーネントテスト例
         *
         * @return void
         */
        public function testBasicExample()
        {
            $this->browse(function (Browser $browser) {
                $browser->visit('/')
                        ->within(new DatePicker, function ($browser) {
                            $browser->selectDate(2019, 1, 30);
                        })
                        ->assertSee('January');
            });
        }
    }

<a name="continuous-integration"></a>
## 継続的インテグレーション

> {note} ほとんどのDusk継続的インテグレーション設定では、Laravelアプリケーションがポート8000​​の組み込みPHP開発サーバを使用して提供されることを想定しています。したがって、続行する前に、継続的インテグレーション環境の`APP_URL`環境変数値を確実に`http://127.0.0.1:8000`に指定してください。

<a name="running-tests-on-heroku-ci"></a>
### Heroku CI

Duskテストを[Heroku CI](https://www.heroku.com/continuous-integration)上で実行するには、Herokuの`app.json`ファイルへ、以下のGoogle Chromeビルドパックとスクリプトを追加してください。

    {
      "environments": {
        "test": {
          "buildpacks": [
            { "url": "heroku/php" },
            { "url": "https://github.com/heroku/heroku-buildpack-google-chrome" }
          ],
          "scripts": {
            "test-setup": "cp .env.testing .env",
            "test": "nohup bash -c './vendor/laravel/dusk/bin/chromedriver-linux > /dev/null 2>&1 &' && nohup bash -c 'php artisan serve > /dev/null 2>&1 &' && php artisan dusk"
          }
        }
      }
    }

<a name="running-tests-on-travis-ci"></a>
### Travis CI

[Travis CI](https://travis-ci.org)上でDuskテストを実行するためには、以降の`.travis.yml`設定を使用してください。Travis CIはグラフィカルな環境ではないため、Chromeブラウザを実行するには追加の手順を行う必要があります。さらに、PHPの組み込みWebサーバを起動するために、`php artisan serve`を使用する必要もあるでしょう。

    language: php

    php:
      - 7.3

    addons:
      chrome: stable

    install:
      - cp .env.testing .env
      - travis_retry composer install --no-interaction --prefer-dist --no-suggest
      - php artisan key:generate
      - php artisan dusk:chrome-driver

    before_script:
      - google-chrome-stable --headless --disable-gpu --remote-debugging-port=9222 http://localhost &
      - php artisan serve &

    script:
      - php artisan dusk

<a name="running-tests-on-github-actions"></a>
### GitHubアクション

[Github Actions](https://github.com/features/actions)を使用してDuskテストを実行する場合は、次の設定ファイルを開始点として使用できます。TravisCIと同様に、`php artisan serve`コマンドを使用してPHPの組み込みWebサーバを起動します。

    name: CI
    on: [push]
    jobs:

      dusk-php:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v2
          - name: Prepare The Environment
            run: cp .env.example .env
          - name: Create Database
            run: |
              sudo systemctl start mysql
              mysql --user="root" --password="root" -e "CREATE DATABASE 'my-database' character set UTF8mb4 collate utf8mb4_bin;"
          - name: Install Composer Dependencies
            run: composer install --no-progress --no-suggest --prefer-dist --optimize-autoloader
          - name: Generate Application Key
            run: php artisan key:generate
          - name: Upgrade Chrome Driver
            run: php artisan dusk:chrome-driver `/opt/google/chrome/chrome --version | cut -d " " -f3 | cut -d "." -f1`
          - name: Start Chrome Driver
            run: ./vendor/laravel/dusk/bin/chromedriver-linux &
          - name: Run Laravel Server
            run: php artisan serve &
          - name: Run Dusk Tests
            env:
              APP_URL: "http://127.0.0.1:8000"
            run: php artisan dusk
          - name: Upload Screenshots
            if: failure()
            uses: actions/upload-artifact@v2
            with:
              name: screenshots
              path: tests/Browser/screenshots
          - name: Upload Console Logs
            if: failure()
            uses: actions/upload-artifact@v2
            with:
              name: console
              path: tests/Browser/console
