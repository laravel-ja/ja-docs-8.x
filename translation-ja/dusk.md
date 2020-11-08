# Laravel Dusk

- [イントロダクション](#introduction)
- [インストール](#installation)
    - [ChromeDriverインストールの管理](#managing-chromedriver-installations)
    - [他ブラウザの使用](#using-other-browsers)
- [利用の開始](#getting-started)
    - [テストの生成](#generating-tests)
    - [テストの実行](#running-tests)
    - [環境の処理](#environment-handling)
    - [ブラウザの生成](#creating-browsers)
    - [ブラウザマクロ](#browser-macros)
    - [認証](#authentication)
    - [データベースマイグレーション](#migrations)
    - [クッキー](#cookies)
    - [スクリーンショットの取得](#taking-a-screenshot)
    - [コンソール出力をディスクへ保存](#storing-console-output-to-disk)
    - [ページソースをディスクへ保存](#storing-page-source-to-disk)
- [要素の操作](#interacting-with-elements)
    - [Duskセレクタ](#dusk-selectors)
    - [リンクのクリック](#clicking-links)
    - [テキスト、値、属性](#text-values-and-attributes)
    - [フォームの使用](#using-forms)
    - [添付ファイル](#attaching-files)
    - [キーワードの使用](#using-the-keyboard)
    - [マウスの使用](#using-the-mouse)
    - [JavaScriptダイアログ](#javascript-dialogs)
    - [セレクタの範囲指定](#scoping-selectors)
    - [要素の待機](#waiting-for-elements)
    - [要素のビュー内へのスクロール](#scrolling-an-element-into-view)
    - [JavaScriptの実行](#executing-javascript)
    - [Veuアサーションの作成](#making-vue-assertions)
- [使用可能なアサート](#available-assertions)
- [ページ](#pages)
    - [ページの生成](#generating-pages)
    - [ページの設定](#configuring-pages)
    - [ページへのナビゲーション](#navigating-to-pages)
    - [セレクタの簡略記述](#shorthand-selectors)
    - [ページメソッド](#page-methods)
- [コンポーネント](#components)
    - [コンポーネント生成](#generating-components)
    - [コンポーネントの使用](#using-components)
- [継続的インテグレーション](#continuous-integration)
    - [CircleCI](#running-tests-on-circle-ci)
    - [Codeship](#running-tests-on-codeship)
    - [Heroku CI](#running-tests-on-heroku-ci)
    - [Travis CI](#running-tests-on-travis-ci)
    - [GitHubアクション](#running-tests-on-github-actions)

<a name="introduction"></a>
## イントロダクション

Laravel Dusk（ダースク：夕暮れ）は、利用が簡単なブラウザの自動操作／テストAPIを提供します。デフォルトのDuskは皆さんのマシンへ、JDKやSeleniumのインストールを求めません。代わりにDuskはスタンドアローンの[ChromeDriver](https://sites.google.com/a/chromium.org/chromedriver/home)を使用します。しかし、好みのSeleniumコンパチドライバも自由に使用することもできます。

<a name="installation"></a>
## インストール

使用を開始するには、`laravel/dusk`コンポーサ依存パッケージをプロジェクトへ追加します。

    composer require --dev laravel/dusk

> {note} 本番環境にDuskをインストールしてはいけません。インストールすると、アプリケーションに対する未認証でのアクセスを許すようになります。

Duskパッケージをインストールし終えたら、`dusk:install` Artisanコマンドを実行します。

    php artisan dusk:install

`test`ディレクトリ中に、サンプルテストを含んだ`Browser`ディレクトリが作成されます。次に、`.env`ファイルで`APP_URL`環境変数を指定します。この値は、ブラウザからアクセスするアプリケーションで使用するURLと一致させます。

テストを実行するには、`dusk` Artisanコマンドを使います。`dusk`コマンドには、`phpunit`コマンドが受け付ける引数をすべて指定できます。

    php artisan dusk

`dusk`コマンドで最後に実行したテストが失敗した場合、`dusk:fails`コマンドを使用し、失敗したテストを再実行することにより、時間を節約できます。

    php artisan dusk:fails

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

<a name="running-tests"></a>
### テストの実行

ブラウザテストを実行するには、`dusk` Artisanコマンドを使用します。

    php artisan dusk

`dusk`コマンドで最後に実行したテストが失敗した場合、`dusk:fails`コマンドを使用し、失敗したテストを再実行することにより、時間を節約できます。

    php artisan dusk:fails

PHPUnitテストランナが通常受け付ける引数は、`dusk`コマンドでも指定できます。たとえば、指定した[グループ](https://phpunit.de/manual/current/en/appendixes.annotations.html#appendixes.annotations.group)のテストのみを実行するなどです。

    php artisan dusk --group=foo

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

また、ChromeDriverを9515以外のポートで起動した場合、同じクラスの`driver`メソッドを変更する必要があります。

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

<a name="creating-browsers"></a>
### ブラウザの生成

手始めに、アプリケーションへログインできることを確認するテストを書いてみましょう。テストを生成したら、ログインページへ移動し、認証情報を入力し、"Login"ボタンをクリックするように変更します。ブラウザインスタンスを生成するには、`browser`メソッドを呼び出します。

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
        public function testBasicExample()
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

上記の例のように、`browse`メソッドはコールバックを引数に受けます。　Duskによりブラウザインスタンスは自動的にこのコールバックに渡され、このオブジェクトで、アプリケーションに対する操作やアサートを行います。

<a name="creating-multiple-browsers"></a>
#### 複数ブラウザの生成

テストを行うために複数のブラウザが必要なこともあります。たとえば、Webソケットを使用するチャットスクリーンをテストするためには、複数のブラウザが必要でしょう。複数ブラウザを生成するには、`browse`メソッドに指定するコールバックの引数で、一つ以上のブラウザを指定します。

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

<a name="resizing-browser-windows"></a>
#### ブラウザウィンドウのリサイズ

ブラウザウインドウのサイズを調整するため、`resize`メソッドを使用できます。

    $browser->resize(1920, 1080);

ブラウザウィンドウを最大化するには、`maximize`メソッドを使います。

    $browser->maximize();

`fitContent`メソッドは、コンテンツに合わせてブラウザウィンドウのサイズをリサイズします。

    $browser->fitContent();

テスト失敗時にDuskはスクリーンショットを取るために、以前のコンテンツに合うようブラウザを自動的にリサイズします。この機能を無効にするには、テストの中で`disableFitOnFailure`メソッドを呼び出してください。

    $browser->disableFitOnFailure();

スクリーン上の別の位置へブラウザのウィンドウを移動する場合は、`move`メソッドを使います。

    $browser->move(100, 100);

<a name="browser-macros"></a>
### ブラウザマクロ

さまざまなテストで再利用可能な、カスタムブラウザメソッドを定義したい場合は、`Browser`クラスの`macro`メソッドを使用してください。

    <?php

    namespace App\Providers;

    use Illuminate\Support\ServiceProvider;
    use Laravel\Dusk\Browser;

    class DuskServiceProvider extends ServiceProvider
    {
        /**
         * Duskのブラウザマクロの登録
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

`macro`関数の第１引数は名前で、第２引数はクロージャです。このクロージャは、`Browser`実装上でメソッドとしてマクロが呼び出された時に、実行されます。

    $this->browse(function ($browser) use ($user) {
        $browser->visit('/pay')
                ->scrollToElement('#credit-card-details')
                ->assertSee('Enter Credit Card Details');
    });

<a name="authentication"></a>
### 認証

認証が必要なページのテストはよくあります。毎回テストのたびにログインスクリーンを操作しなくても済むように、Duskの`loginAs`メソッドを使ってください。`loginAs`メソッドはユーザーIDかユーザーモデルインスタンスを引数に取ります。

    $this->browse(function ($first, $second) {
        $first->loginAs(User::find(1))
              ->visit('/home');
    });

> {note} `loginAs`メソッドを使用後、そのファイルに含まれるすべてのテストに対し、ユーザーセッションは保持されます。

<a name="migrations"></a>
### データベースマイグレーション

上記の認証サンプルのように、マイグレーションをテストする必要がある場合は、`RefreshDatabase`トレイトを使用してはいけません。`RefreshDatabase`トレイトはHTTPリクエストに対し適用されない、データベーストランザクションに活用します。代わりに、`DatabaseMigrations`トレイトを使用してください。

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

> {note} SQLite in-memory databases may not be used when executing Dusk tests. Since the browser executes within its own process, it will not be able to access the in-memory databases of other processes.

<a name="cookies"></a>
### クッキー

暗号化したクッキーの値を取得／セットするには、`cookie`メソッドを使います。

    $browser->cookie('name');

    $browser->cookie('name', 'Taylor');

暗号化していないクッキーの値を取得／セットするには、`plainCookie`メソッドを使います。

    $browser->plainCookie('name');

    $browser->plainCookie('name', 'Taylor');

指定クッキーを削除するには、`deleteCookie`メソッドを使います。

    $browser->deleteCookie('name');

<a name="taking-a-screenshot"></a>
### スクリーンショットの取得

スクリーンショットを取るには、`screenshot`メソッドを使います。指定したファイル名で保存されます。スクリーンショットはすべて、`tests/Browser/screenshots`ディレクトリへ保存します。

    $browser->screenshot('filename');

<a name="storing-console-output-to-disk"></a>
### コンソール出力をディスクへ保存

コンソール出力を指定ファイル名でディスクに書き出すには`storeConsoleLog`メソッドを使います。コンソール出力は`tests/Browser/console`ディレクトリへ保存します。

    $browser->storeConsoleLog('filename');

<a name="storing-page-source-to-disk"></a>
### ページソースをディスクへ保存

そのページの現時点でのソースをディスクに書き出すには`storeSource`メソッドを使います。ページソースは指定名で、`tests/Browser/source`ディレクトリに出力します。

    $browser->storeSource('filename');

<a name="interacting-with-elements"></a>
## 要素の操作

<a name="dusk-selectors"></a>
### Duskセレクタ

要素を操作するために、最適なCSSセレクタを選択するのは、Duskテストで一番難しい部分です。フロントエンドは繰り返し変更され、失敗するようになったテストを修正するため、CSSセレクタを何度も調整しました。

    // HTML

    <button>Login</button>

    // テスト

    $browser->click('.login-page .container div > button');

Duskセレクタにより、CSSセレクタを記憶せず効率的にテストを書くことへ集中できるようになります。セレクタを定義するには、HTML要素に`dusk`属性を追加します。それから、Duskテスト中の要素を操作するために、セレクタの先頭に`@`を付けてください。

    // HTML

    <button dusk="login-button">Login</button>

    // テスト

    $browser->click('@login-button');

<a name="clicking-links"></a>
### リンクのクリック

リンクをクリックするには、ブラウザインスタンスの`clickLink`メソッドを使います。`clickLink`メソッドは指定した表示テキストのリンクをクリックします。

    $browser->clickLink($linkText);

`seeLink`メソッドを使い、指定表示テキストを持つリンクがページ上に表示されるかを判定できます。

    if ($browser->seeLink($linkText)) {
        // ...
    }

> {note} これらのメソッドはJQueryと連携しています。ページでJQueryが使用できない場合Duskは、そのテストの間Jqueryを使用できるようにするため自動的にインジェクションします。

<a name="text-values-and-attributes"></a>
### テキスト、値、属性

<a name="retrieving-setting-values"></a>
#### 値の取得／設定

Duskは現在表示されているテキスト、値、ページ要素の属性を操作する、数多くのメソッドを提供します。たとえば、指定したセレクタに一致する要素の「値(value)」を取得するには、`value`メソッドを使用します。

    // 値の取得
    $value = $browser->value('selector');

    // 値の設定
    $browser->value('selector', 'value');

指定したフィールド名を持つインプット要素の「値」を取得するには、`inputValue`メソッドを使ってください。

    // 入力要素の値の取得
    $inputValue = $browser->inputValue('field');

<a name="retrieving-text"></a>
#### テキストの取得

`text`メソッドは、指定したセレクタに一致する要素の表示テキストを取得します。

    $text = $browser->text('selector');

<a name="retrieving-attributes"></a>
#### 属性の取得

最後の`attribute`メソッドは、セレクタに一致する要素の属性を取得します。

    $attribute = $browser->attribute('selector', 'value');

<a name="using-forms"></a>
### フォームの使用

<a name="typing-values"></a>
#### 値のタイプ

Duskはフォームと入力要素を操作する、さまざまなメソッドを提供しています。最初に、入力フィールドへテキストをタイプする例を見てみましょう。

    $browser->type('email', 'taylor@laravel.com');

必要であれば受け付けますが、`type`メソッドにはCSSセレクタを渡す必要がないことに注意してください。CSSセレクタが指定されない場合、Duskは`name`属性に指定された入力フィールドを探します。最終的に、Duskは指定された`name`属性を持つ`textarea`を見つけようとします。

コンテンツをクリアせずに、フィールドへテキストを追加するには、`append`メソッドを使用します。

    $browser->type('tags', 'foo')
            ->append('tags', ', bar, baz');

入力値をクリアするには、`clear`メソッドを使用します。

    $browser->clear('email');

`typeSlowly`メソッドによりDuskへゆっくりとタイプするように指示できます。Duskはデフォルトでキー押下間に１００ミリ秒の間隔を開けます。このキー押下間の時間をカスタマイズするには、メソッドの第２引数へ適切なミリ秒数を渡してください。

    $browser->typeSlowly('mobile', '+1 (202) 555-5555');

    $browser->typeSlowly('mobile', '+1 (202) 555-5555', 300);

テキストをゆっくりと追加するために`appendSlowly`メソッドも使用できます。

    $browser->type('tags', 'foo')
            ->appendSlowly('tags', ', bar, baz');

<a name="dropdowns"></a>
#### ドロップダウン

ドロップダウンの選択ボックスから値を選ぶには、`select`メソッドを使います。`type`メソッドと同様に、`select`メソッドも完全なCSSセレクタは必要ありません。`select`メソッドに引数を指定するとき、表示テキストの代わりに、オプション値を渡します。

    $browser->select('size', 'Large');

第２引数を省略した場合、ランダムにオプションを選択します。

    $browser->select('size');

<a name="checkboxes"></a>
#### チェックボックス

チェックボックスを「チェック(check)」するには、`check`メソッドを使います。他の関連する多くのメソッドと同様に、完全なCSSセレクタは必要ありません。完全に一致するセレクタが見つからないと、Duskは`name`属性に一致するチェックボックスを探します。

    $browser->check('terms');

    $browser->uncheck('terms');

<a name="radio-buttons"></a>
#### ラジオボタン

ラジオボタンのオプションを「選択」するには、`radio`メソッドを使用します。他の関連する多くのメソッドと同様に、完全なセレクタは必要ありません。完全に一致するセレクタが見つからない場合、Duskは`name`と`value`属性に一致するラジオボタンを探します。

    $browser->radio('version', 'php8');

<a name="attaching-files"></a>
### 添付ファイル

`attach`メソッドは`file`入力要素で、ファイルを指定するために使用します。他の関連する入力メソッドと同様に、完全なCSSセレクタは必要ありません。完全なセレクタが見つからなければ、Duskは`name`属性と一致するファイル入力を探します。

    $browser->attach('photo', __DIR__.'/photos/me.png');

> {note} `attach`関数を利用するには、サーバへ`Zip` PHP拡張をインストールし、有効にする必要があります。

<a name="using-the-keyboard"></a>
### キーワードの使用

`keys`メソッドは、`type`メソッドによる、指定した要素に対する通常の入力よりも、複雑な入力を提供します。たとえば、モデファイヤキーを押しながら、値を入力するなどです。以下の例では、指定したセレクタに一致する要素へ、`taylor`を「シフト(`shift`)」キーを押しながら入力します。`Taylor`をタイプし終えると、`otwell`がモデファイヤキーを押さずにタイプされます。

    $browser->keys('selector', ['{shift}', 'taylor'], 'otwell');

アプリケーションを構成する主要なCSSセレクタへ「ホットキー」を送ることもできます。

    $browser->keys('.app', ['{command}', 'j']);

> {tip} モデファイヤキーは`{}`文字で囲み、`Facebook\WebDriver\WebDriverKeys`クラスで定義されている定数を指定します。[GitHubで確認](https://github.com/php-webdriver/php-webdriver/blob/master/lib/WebDriverKeys.php)できます。

<a name="using-the-mouse"></a>
### マウスの使用

<a name="clicking-on-elements"></a>
#### 要素のクリック

指定したセレクタに一致する要素を「クリック」するには、`click`メソッドを使います。

    $browser->click('.selector');

`clickAtXPath`メソッドは、指定するXPath表現に一致する要素を「クリック」するために使用します。

    $browser->clickAtXPath('//div[@class = "selector"]');

`clickAtPoint`メソッドはブラウザの表示可能領域との相対座標ペアで指定した、最上位の要素を「クリック」するために使用します。

    $browser->clickAtPoint(0, 0);

`doubleClick`メソッドはマウスのダブル「クリック」をシミュレートするために使用します。

    $browser->doubleClick();

`rightClick`メソッドはマウスの右「クリック」をシミュレートするために使用します。

    $browser->rightClick();

    $browser->rightClick('.selector');

`clickAndHold`メソッドはマウスボタンをクリックし、そのまま押し続ける動作をシミュレートするため使用します。続いて呼び出す`releaseMouse`メソッドはこの動作を取り消し、マウスボタンを離します。

    $browser->clickAndHold()
            ->pause(1000)
            ->releaseMouse();

<a name="mouseover"></a>
#### マウスオーバー

指定したセレクタに一致する要素を「マウスオーバー」したい場合は、`mouseover`メソッドを使います。

    $browser->mouseover('.selector');

<a name="drag-drop"></a>
#### ドラッグ＆ドロップ

`drag`メソッドは指定したセレクタに一致する要素をドラッグし、もう一つの要素へドロップします。

    $browser->drag('.from-selector', '.to-selector');

もしくは、特定の方向へ要素をドラッグすることもできます。

    $browser->dragLeft('.selector', 10);
    $browser->dragRight('.selector', 10);
    $browser->dragUp('.selector', 10);
    $browser->dragDown('.selector', 10);

指定したオフセットにより要素をドラッグします。

    $browser->dragOffset('.selector', 10, 10);

<a name="javascript-dialogs"></a>
### JavaScriptダイアログ

DuskはJavaScriptダイアログを操作する、さまざまなメソッドを提供しています。

    // ダイアログが表示されるのを待つ
    $browser->waitForDialog($seconds = null);

    // ダイアログが表示され、メッセージが指定した値と一致することを宣言
    $browser->assertDialogOpened('value');

    // 開いているJavaScript入力(prompt)ダイアログに、指定値をタイプ
    $browser->typeInDialog('Hello World');

開いているJavaScriptダイアログをOKボタンのクリックで閉じるには：

    $browser->acceptDialog();

開いているJavaScriptダイアログをキャンセルボタンのクリックで閉じるには（確認ダイアログのみ）：

    $browser->dismissDialog();

<a name="scoping-selectors"></a>
### セレクタの範囲指定

特定のセレクタの中の全操作を範囲指定しつつ、多くの操作を行いたいこともあります。たとえば、いくつかのテーブル中にあるテキストが存在していることをアサートし、それからテーブル中のボタンをクリックしたい場合です。`with`メソッドで行なえます。`with`メソッドのコールバック中で行われた操作は全部、オリジナルのセレクタに対し限定されます。

    $browser->with('.table', function ($table) {
        $table->assertSee('Hello World')
              ->clickLink('Delete');
    });

現在のスコープ外でアサーションを実行する必要のある場合があります。そのためには、`elsewhere`メソッドを使用します。

     $browser->with('.table', function ($table) {
        // Current scope is `body .table`...
        $browser->elsewhere('.page-title', function ($title) {
            // Current scope is `body .page-title`...
            $title->assertSee('Hello World');
        });
     });

<a name="waiting-for-elements"></a>
### 要素の待機

広範囲に渡りJavaScriptを使用しているアプリケーションのテストでは、テストを進める前に特定の要素やデータが利用可能になるまで、「待つ(wait)」必要がしばしば起きます。Duskではこれも簡単に行えます。数多くのメソッドを使い、ページで要素が見えるようになるまで、もしくはJavaScriptの評価が`true`になるまで待機できます。

<a name="waiting"></a>
#### 待機

指定したミリ秒の間、テストをポーズしたい場合は、`pause`メソッドを使用します。

    $browser->pause(1000);

<a name="waiting-for-selectors"></a>
#### セレクタの待機

`waitFor`メソッドはテストの実行を指定したCSSセレクタがページに表示されるまで中断します。例外が投げられるまで、デフォルトで最長５秒間テストを中断します。必要であれば、カスタムタイムアウトを秒でメソッドの第２引数として指定できます。

    // セレクタを最長５秒間待つ
    $browser->waitFor('.selector');

    // セレクタを最長１秒待つ
    $browser->waitFor('.selector', 1);

セレクタが指定テキストを持つまで中断することもできます。

    // セレクタが指定テキストを持つまで、最長５秒待つ
    $browser->waitForTextIn('.selector', 'Hello World');

    // セレクタが指定テキストを持つまで、最長５秒待つ
    $browser->waitForTextIn('.selector', 'Hello World', 1);

指定したセレクタがページから消えるまで待つこともできます。

    // セレクタが消えるまで、最長５秒待つ
    $browser->waitUntilMissing('.selector');

    // セレクタが消えるまで、最長１秒待つ
    $browser->waitUntilMissing('.selector', 1);

<a name="scoping-selectors-when-available"></a>
#### 利用可能時限定のセレクタ

指定したセレクタを待ち、それからそのセレクタに一致する要素を操作したい場合もよくあります。たとえば、モーダルウィンドウが現れるまで待ち、それからそのモーダルウィンドウ上の"OK"ボタンを押したい場合です。このケースでは`whenAvailable`メソッドを使用します。指定したコールバック内で行われた要素操作はすべて、オリジナルのセレクタに対して限定されます。

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

名前付きルートのロケーションを待機することも可能です。

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
    $browser->waitUntil('App.dataLoaded');

    $browser->waitUntil('App.data.servers.length > 0');

    // 式がtrueになるまで最大１秒間待つ
    $browser->waitUntil('App.data.servers.length > 0', 1);

<a name="waiting-on-vue-expressions"></a>
#### Vue式でwaitする

以下のメソッドで、特定のVueコンポーネント属性が、指定値になるまで待つことができます。

    // 指定したコンポーネント属性が、指定値を含むまで待つ
    $browser->waitUntilVue('user.name', 'Taylor', '@user');

    // 指定したコンポーネント属性が、指定値を含まなくなるまで待つ
    $browser->waitUntilVueIsNot('user.name', null, '@user');

<a name="waiting-with-a-callback"></a>
#### コールバックによる待機

Duskにある数多くの「待機」メソッドは、`waitUsing`メソッドを使用しています。このメソッドを直接利用し、コールバックが`true`を返すまで待機できます。`waitUsing`メソッドは最長待ち秒数とクロージャを評価する間隔秒数、クロージャを引数に取ります。オプションとして、失敗時のメッセージを引数に取ります。

    $browser->waitUsing(10, 1, function () use ($something) {
        return $something->isReady();
    }, "Something wasn't ready in time.");

<a name="scrolling-an-element-into-view"></a>
### 要素のビュー内へのスクロール

ブラウザの表示可能領域の外にあるため、ある要素をクリックできなことも起き得ます。`scrollIntoView`メソッドは指定したセレクタの要素がビューの中に入るまで、ブラウザウィンドウをスクロールします。

    $browser->scrollIntoView('selector')
            ->click('selector');

<a name="executing-javascript"></a>
### JavaScriptの実行

ブラウザでJavaScriptを実行するには、`script`メソッドを使います。

    $output = $browser->script('document.documentElement.scrollTop = 0');

    $output = $browser->script([
        'document.body.scrollTop = 0',
        'document.documentElement.scrollTop = 0',
    ]);

<a name="making-vue-assertions"></a>
### Vueアサーションの作成

Duskでは、[Vue](https://vuejs.org)コンポーネントデータの状態をアサートすることもできます。たとえば、アプリケーションに以下のVueコンポーネントが含まれていると想像してください。

    // HTML

    <profile dusk="profile-component"></profile>

    // コンポーネント定義

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

Vueコンポーネントの状態を以下のようにアサートできます。

    /**
     * 基本的なVueのテスト
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
[assertSelectMissingOption](#assert-select-missing-option)
[assertSelectMissingOptions](#assert-select-missing-options)
[assertSelectHasOption](#assert-select-has-option)
[assertValue](#assert-value)
[assertAttribute](#assert-attribute)
[assertAriaAttribute](#assert-aria-attribute)
[assertDataAttribute](#assert-data-attribute)
[assertVisible](#assert-visible)
[assertPresent](#assert-present)
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

    $browser->assertPathBeginsWith($path);

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

現在のURLが指定した名前付きルートのURLと一致することを宣言します。

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

現在のフラグメントが、指定したフラグメントと一致することを宣言します。

    $browser->assertFragmentIs('anchor');

<a name="assert-fragment-begins-with"></a>
#### assertFragmentBeginsWith

現在のフラグメントが、指定したフラグメントで始まることを宣言します。

    $browser->assertFragmentBeginsWith('anchor');

<a name="assert-fragment-is-not"></a>
#### assertFragmentIsNot

現在のフラグメントが、指定したフラグメントと一致しないことを宣言します。

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

<a name="assert-select-missing-option"></a>
#### assertSelectMissingOption

指定値が選択不可能であることを宣言します。

    $browser->assertSelectMissingOption($field, $value);

<a name="assert-select-missing-options"></a>
#### assertSelectMissingOptions

指定した配列値が選択不可であることを宣言します。

    $browser->assertSelectMissingOptions($field, $values);

<a name="assert-select-has-option"></a>
#### assertSelectHasOption

指定したフィールドで、指定した値が選択可能であることを宣言します。

    $browser->assertSelectHasOption($field, $value);

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

指定したVueコンポーネントのデータプロパティが、指定値と一致することを宣言します。

    $browser->assertVue($property, $value, $componentSelector = null);

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

時にテストで、連続して実行する複雑なアクションをたくさん要求されることがあります。これにより、テストは読みづらく、また理解しづらくなります。ページに対し一つのメソッドを使うだけで、指定ページで実行されるアクションを記述的に定義できます。ページはまた、アプリケーションやシングルページで一般的なセレクタの、短縮記法を定義する方法も提供しています。

<a name="generating-pages"></a>
### ページの生成

ページオプジェクトを生成するには、`dusk:page` Artisanコマンドを使います。すべてのページオブジェクトは、`tests/Browser/Pages`ディレクトリへ設置します。

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

`assert`メソッドでは、ブラウザが実際に指定ページを表示した時に、確認が必要なアサーションを定義します。このメソッドで完全に行う必要はありません。ですが、もしお望みであれば自由にアサートを記述してください。記述されたアサートは、このページへ移行時に自動的に実行されます。

    /**
     * ブラウザがこのページにやって来たときのアサート
     *
     * @return void
     */
    public function assert(Browser $browser)
    {
        $browser->assertPathIs($this->url());
    }

<a name="navigating-to-pages"></a>
### ページへのナビゲーション

ページの設定を終えたら、`visit`メソッドを使い、ページへ移行できます。

    use Tests\Browser\Pages\Login;

    $browser->visit(new Login);

`visitRoute`メソッドを使い、名前付きルートへナビゲートできます。

    $browser->visitRoute('login');

「前へ」と「戻る」操作は、`back`と`forward`メソッドで行います。

    $browser->back();

    $browser->forward();

`refresh`メソッドはページを再描写するために使います。

    $browser->refresh();

すでに特定のページに移動済みで、現在のテストコンテキストへそのページのセレクタとメソッドを「ロード」する必要が起き得ます。この状況は、明示的に移動していなくても、あるボタンを押すことで指定ページへリダイレクトしてしまう場合に発生します。そうした場合は、`on`メソッドで、そのページをロードできます。

    use Tests\Browser\Pages\CreatePlaylist;

    $browser->visit('/dashboard')
            ->clickLink('Create Playlist')
            ->on(new CreatePlaylist)
            ->assertSee('@create');

<a name="shorthand-selectors"></a>
### セレクタの簡略記述

ページの`elements`メソッドにより、覚えやすいCSSセレクタの短縮形を素早く定義できます。例として、アプリケーションのログインページの"email"入力フィールドの短縮形を定義してみましょう。

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

これで、完全なCSSセレクタを指定する箇所ならどこでも、この短縮セレクタを使用できます。

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

メソッドを定義すれば、このページを使用するすべてのテストの中で使用できます。ブラウザインスタンスは自動的にページメソッドへ渡されます。

    use Tests\Browser\Pages\Dashboard;

    $browser->visit(new Dashboard)
            ->createPlaylist('My Playlist')
            ->assertSee('My Playlist');

<a name="components"></a>
## コンポーネント

コンポーネントはDuskの「ページオブジェクト」と似ていますが、ナビゲーションバーや通知ウィンドウのような、UI群と機能をアプリケーション全体で再利用するためのものです。コンポーネントは特定のURLと結びついていません。

<a name="generating-components"></a>
### コンポーネント生成

コンポーネントを生成するには、`dusk:component` Artisanコマンドを使用します。新しいコンポーネントは、`tests/Browser/Components`ディレクトリに設置されます。

    php artisan dusk:component DatePicker

上記の「デートピッカー」は、アプリケーション全体のさまざまなページで利用されるコンポーネントの一例です。テストスーツ全体の何ダースものテスト中で、日付を選択するブラウザ自動化ロジックを一々書くのは大変な手間です。その代わりに、デートピッカーを表すDuskコンポーネントを定義し、そうしたロジックをコンポーネントへカプセル化できます。

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
         * ブラウザページにそのコンポーネントが含まれていることをアサート
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
        {
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
        public function selectDate($browser, $year, $month, $day)
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

> {note} 持続的インテグレーション設定ファイルを追加する前に、`.env.testing`ファイルへ`http://127.0.0.1:8000`の値の`APP_URL`エントリがあることを確認してください。

<a name="running-tests-on-circle-ci"></a>
### CircleCI

DustテストにCircleCIを使用する場合、以下の設定ファイルを手始めに利用できます。TravisCIと同様に、`php artisan serve`コマンドを使用し、PHP組み込みWebサーバを起動できます。

    version: 2
    jobs:
        build:
            steps:
                - run: sudo apt-get install -y libsqlite3-dev
                - run: cp .env.testing .env
                - run: composer install -n --ignore-platform-reqs
                - run: php artisan key:generate
                - run: php artisan dusk:chrome-driver
                - run: npm install
                - run: npm run production
                - run: vendor/bin/phpunit

                - run:
                    name: Start Chrome Driver
                    command: ./vendor/laravel/dusk/bin/chromedriver-linux
                    background: true

                - run:
                    name: Run Laravel Server
                    command: php artisan serve
                    background: true

                - run:
                    name: Run Laravel Dusk Tests
                    command: php artisan dusk

                - store_artifacts:
                    path: tests/Browser/screenshots

                - store_artifacts:
                    path: tests/Browser/console

                - store_artifacts:
                    path: storage/logs


<a name="running-tests-on-codeship"></a>
### Codeship

Duskのテストを[Codeship](https://codeship.com)で実行するには、以下のコマンドをCodeshipプロジェクトへ追加してください。以下のコマンドはひとつの参考例です。必要に応じて、自由にコマンドを追加してください。

    phpenv local 7.3
    cp .env.testing .env
    mkdir -p ./bootstrap/cache
    composer install --no-interaction --prefer-dist
    php artisan key:generate
    php artisan dusk:chrome-driver
    nohup bash -c "php artisan serve 2>&1 &" && sleep 5
    php artisan dusk

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

Duskのテスト実行に[Githubアクション](https://github.com/features/actions)を使う場合は、以下の設定ファイルを手始めに利用できます。TravisCIと同様に、PHPの組み込みサーバを起動するために`php artisan serve`コマンドが実行できます。

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
