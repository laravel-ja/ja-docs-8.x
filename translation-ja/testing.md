# テスト: テストの準備

- [イントロダクション](#introduction)
- [環境](#environment)
- [テストの生成と実行](#creating-and-running-tests)
    - [Artisanテストランナー](#artisan-test-runner)

<a name="introduction"></a>
## イントロダクション

Laravelはユニットテストも考慮して構築されています。実際、PHPUnitをサポートしており、最初から含まれています。アプリケーションのために`phpunit.xml`ファイルも最初から準備されています。さらにフレームワークはアプリケーションを記述的にテストするために便利なヘルパメソッドも用意しています。

デフォルトでは、アプリケーションの`tests`ディレクトリには、`Feature`と`Unit`の２つのディレクトリを用意しています。単体テストは、コードの非常に小さな孤立した部分に焦点を当てたテストです。実際、ほとんどの単体テストはおそらく単一のメソッドに焦点を合わせています。「ユニット」テストディレクトリ内のテストはLaravelアプリケーションを起動しないため、アプリケーションのデータベースやその他のフレームワークサービスにアクセスできません。

機能テストでは、複数のオブジェクトが相互作用する方法や、JSONエンドポイントへの完全なHTTPリクエストなど、コードの広い部分をテストします。**一般的に、ほとんどのテストは機能テストである必要があります。これらのタイプのテストは、システム全体が意図したとおりに機能しているという信頼性を一番提供します。**

`ExampleTest.php`ファイルは`Feature`と`Unit`の両方のテストディレクトリで提供されます。新しいLaravelアプリケーションをインストールした後なら、`vendor/bin/phpunit`または`phpartisantest`コマンドを実行してテストを実行できます。

<a name="environment"></a>
## 環境

`vendor/bin/phpunit`を介してテストを実行すると、Laravelは`phpunit.xml`ファイルで定義してある[設定環境](/docs/{{version}}/configuration#environment-configuration)により、設定環境を自動的に`testing`に設定します。Laravelはまた、テスト中にセッションとキャッシュを`array`ドライバに自動的に設定します。つまり、テスト中のセッションまたはキャッシュデータが保持されることはありません。

必要に応じて、他のテスト環境設定値を自由に定義できます。`testing`環境変数はアプリケーションの`phpunit.xml`ファイルで設定していますが、テストを実行する前は必ず`config:clear` Artisanコマンドを使用して設定のキャッシュをクリアしてください。

<a name="the-env-testing-environment-file"></a>
#### `.env.testing`環境ファイル

さらに、プロジェクトのルートに`.env.testing`ファイルを作成することもできます。このファイルは、PHPUnitテストを実行するとき、または`--env=tests`オプションを指定してArtisanコマンドを実行するときに、`.env`ファイルの代わりに使用されます。

<a name="creating-and-running-tests"></a>
## テストの生成と実行

新しいテストケースを作成するには、`make:test` Artisanコマンドを使用します。デフォルトでは、テストは`tests/Feature`ディレクトリへ配置されます。

    php artisan make:test UserTest

`tests/Unit`ディレクトリ内にテストを作成したい場合は、`make:test`コマンドを実行するときに`--unit`オプションを使用します。

    php artisan make:test UserTest --unit

> {tip} [stubのリソース公開](/docs/{{version}}/artisan#stub-customization) を使って、Testスタブをカスタマイズできます。

テストを生成したら、[PHPUnit](https://phpunit.de)を使用する場合と同様にテストメソッドを定義します。テストを実行するには、ターミナルから`vendor/bin/phpunit`または`phpartisantest`コマンドを実行します。

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

テスト実行には`phpunit`コマンドに加え、`test` Artisanコマンドも使用できます。Artisanテストランナーは、開発とデバッグを容易にするため、詳細なテストレポートを提供します

    php artisan test

`phpunit`コマンドで使用できる引数はすべてArtisan `test`コマンドにも渡せます。

    php artisan test --testsuite=Feature --stop-on-failure
