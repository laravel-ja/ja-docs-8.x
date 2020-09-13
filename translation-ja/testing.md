# テスト: テストの準備

- [イントロダクション](#introduction)
- [環境](#environment)
- [テストの生成と実行](#creating-and-running-tests)
    - [Artisan Test Runner](#artisan-test-runner)

<a name="introduction"></a>
## イントロダクション

Laravelはユニットテストも考慮して構築されています。実際、PHPUnitをサポートしており、最初から含まれています。アプリケーションのために`phpunit.xml`ファイルも最初から準備されています。さらにフレームワークはアプリケーションを記述的にテストするために便利なヘルパメソッドも持っています。

デフォルトでアプリケーションの`tests`ディレクトリには、２つのディレクトリが存在しています。`Feature` と`Unit`です。ユニットテストは極小さい、コードの独立した一部をテストします。実際、ほとんどのユニット(Unit)テストは一つのメソッドに焦点をあてます。機能(Feature)テストは、多くのオブジェクトがそれぞれどのように関しているかとか、JSONエンドポイントへ完全なHTTPリクエストを送ることさえ含む、コードの幅広い範囲をテストします。

`Feature`と`Unit`、両テストディレクトリには、`ExampleTest.php`が用意されています。真新しいLaravelアプリケーションをインストールしたらテストを実行するため、コマンドラインから`vendor/bin/phpunit`を実行してください。

<a name="environment"></a>
## 環境

`phpunit.xml`ファイル中で環境変数が設定されているため、`vendor/bin/phpunit`を実行するとLaravelは自動的に設定環境を`testing`にセットします。Laravelはまた、セッションとキャッシュの設定を`array`ドライバーに設定し、テスト中のセッションやキャッシュデータが残らないようにします。

必要であれば他のテスト設定環境を自由に作成することもできます。`testing`動作環境変数は`phpunit.xml`の中で設定されています。テスト実行前には、`config:clear` Artisanコマンドを実行し、設定キャッシュをクリアするのを忘れないでください。

さらに、プロジェクトのルートディレクトリで、`.env.testing`ファイルを生成することも可能です。PHPUnitテストやArtisanコマンドを`--env=testing`オプション付きで実行する場合、`.env`ファイルをこのファイルの内容でオーバーライドします。

<a name="creating-and-running-tests"></a>
## テストの生成と実行

新しいテストケースを作成するには、`make:test` Artisanコマンドを使います。

    // Featureディレクトリにテストを生成する
    php artisan make:test UserTest

    // Unitディレクトリにテストを生成する
    php artisan make:test UserTest --unit

> {tip} [stubのリソース公開](/docs/{{version}}/artisan#stub-customization) を使って、Testスタブをカスタマイズできます。

テストを生成したら、PHPUnitを使用するときと同じようにテストメソッドを定義してください。テストを実行するには、ターミナルで`phpunit`か`artisan test`コマンドを実行します。

    <?php

    namespace Tests\Unit;

    use PHPUnit\Framework\TestCase;

    class ExampleTest extends TestCase
    {
        /**
         * 基本的なテスト例
         *
         * @return void
         */
        public function testBasicTest()
        {
            $this->assertTrue(true);
        }
    }

> {note} テストクラスに独自の`setUp`メソッドを定義する場合は、親のクラスの`parent::setUp()`／`parent::tearDown()`を確実に呼び出してください。

<a name="artisan-test-runner"></a>
### Artisanテストランナー

In addition to the `phpunit` command, you may use the `test` Artisan command to run your tests. The Artisan test runner provides verbose test reports in order to ease development and debugging:

    php artisan test

`phpunit`コマンドで使用できる引数はすべてArtisan `test`コマンドにも渡せます。

    php artisan test --group=feature --stop-on-failure
