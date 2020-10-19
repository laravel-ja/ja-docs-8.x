# HTTPテスト

- [イントロダクション](#introduction)
    - [リクエストヘッダのカスタマイズ](#customizing-request-headers)
    - [クッキー](#cookies)
    - [レスポンスのデバッグ](#debugging-responses)
- [セッション／認証](#session-and-authentication)
- [JSON APIのテスト](#testing-json-apis)
- [ファイルアップロードのテスト](#testing-file-uploads)
- [ビューのテスト](#testing-views)
- [利用可能なアサート](#available-assertions)
    - [レスポンスのアサート](#response-assertions)
    - [認証のアサート](#authentication-assertions)

<a name="introduction"></a>
## イントロダクション

アプリケーションに対しHTTPリクエストを作成し、出力を調べるために、Laravelはとても読み書きしやすいAPIを提供しています。

    <?php

    namespace Tests\Feature;

    use Illuminate\Foundation\Testing\RefreshDatabase;
    use Illuminate\Foundation\Testing\WithoutMiddleware;
    use Tests\TestCase;

    class ExampleTest extends TestCase
    {
        /**
         * 基本的な機能テストの例
         *
         * @return void
         */
        public function testBasicTest()
        {
            $response = $this->get('/');

            $response->assertStatus(200);
        }
    }

`get`メソッドはアプリケーションに対して、`GET`リクエストを作成します。`assertStatus`メソッドは返されたレスポンスが指定したHTTPステータスコードを持っていることをアサートします。このシンプルな例に加え、レスポンスヘッダ、コンテンツ、JSON構造などを検査するさまざまなアサートをLaravelは用意しています。

<a name="customizing-request-headers"></a>
### リクエストヘッダのカスタマイズ

アプリーケーションへ送り返す前に、リクエストヘッダをカスタマイズするには、`withHeaders`メソッドを使います。これにより任意のカスタムヘッダをリクエストに追加できます。

    <?php

    class ExampleTest extends TestCase
    {
        /**
         * 基本的な機能テストの例
         *
         * @return void
         */
        public function testBasicExample()
        {
            $response = $this->withHeaders([
                'X-Header' => 'Value',
            ])->json('POST', '/user', ['name' => 'Sally']);

            $response
                ->assertStatus(201)
                ->assertJson([
                    'created' => true,
                ]);
        }
    }

> {tip} テスト実行時、CSRFミドルウェアは自動的に無効になります。

<a name="cookies"></a>
### クッキー

リクエスト作成時に、`withCookie`メソッドや`withCookies`メソッドを使用し、クッキーの値を設定できます。`withCookie`メソッドは引数を２つ取り、クッキーの名前と値です。もう一つの`withCookies`メソッドは、名前／値ペアの配列を引数に取ります。

    <?php

    class ExampleTest extends TestCase
    {
        public function testCookies()
        {
            $response = $this->withCookie('color', 'blue')->get('/');

            $response = $this->withCookies([
                'color' => 'blue',
                'name' => 'Taylor',
            ])->get('/');
        }
    }

<a name="debugging-responses"></a>
### レスポンスのデバッグ

アプリケーションへ送るテストリクエストを作成し終えたら、レスポンスの内容を確認し、デバッグするために`dump`と`dumpHeaders`、`dumpSession`メソッドが使用できます。

    <?php

    namespace Tests\Feature;

    use Illuminate\Foundation\Testing\RefreshDatabase;
    use Illuminate\Foundation\Testing\WithoutMiddleware;
    use Tests\TestCase;

    class ExampleTest extends TestCase
    {
        /**
         * 基本的な機能テストの例
         *
         * @return void
         */
        public function testBasicTest()
        {
            $response = $this->get('/');

            $response->dumpHeaders();

            $response->dumpSession();

            $response->dump();
        }
    }

<a name="session-and-authentication"></a>
## セッション／認証

Laravelはテスト時にセッションを操作するたくさんのヘルパも提供しています。１つ目は指定した配列をセッションに保存する`withSession`メソッドです。これはアプリケーションのリクエストをテストする前に、データをセッションへロードしたい場合に便利です。

    <?php

    class ExampleTest extends TestCase
    {
        public function testApplication()
        {
            $response = $this->withSession(['foo' => 'bar'])
                             ->get('/');
        }
    }

認証済みのユーザーのようなユーザー状態をセッションへ保持するのは一般的です。`actingAs`ヘルパメソッドは現在認証済みのユーザーを指定する簡単な手段を提供します。例として、[モデルファクトリ](/docs/{{version}}/database-testing#writing-factories)でユーザーを生成し、認証してみましょう。

    <?php

    use App\Models\User;

    class ExampleTest extends TestCase
    {
        public function testApplication()
        {
            $user = User::factory()->create();

            $response = $this->actingAs($user)
                             ->withSession(['foo' => 'bar'])
                             ->get('/');
        }
    }

ユーザーの認証にどのガードを使用するかを指定したい場合、`actingAs`メソッドの第２引数にガード名を渡します。

    $this->actingAs($user, 'api')

<a name="testing-json-apis"></a>
## JSON APIのテスト

LaravelはJSON APIとレスポンスをテストする数多くのヘルパを用意しています。たとえば、`json`, `getJson`, `postJson`, `putJson`, `patchJson`, `deleteJson`, and `optionsJson`メソッドは、それぞれのHTTP動詞のJSONリクエストを発生させるために使用します。これらのメソッドには簡単にデータやヘッダを渡せます。手始めに、`/user`に対する`POST`リクエストを作成し、期待したデータが返されることをアサートするテストを書いてみましょう。

    <?php

    class ExampleTest extends TestCase
    {
        /**
         * 基本的な機能テストの例
         *
         * @return void
         */
        public function testBasicExample()
        {
            $response = $this->postJson('/user', ['name' => 'Sally']);

            $response
                ->assertStatus(201)
                ->assertJson([
                    'created' => true,
                ]);
        }
    }

> {tip} The `assertJson`メソッドはレスポンスを配列へ変換し、`PHPUnit::assertArraySubset`を使用しアプリケーションへ戻ってきたJSONレスポンスの中に、指定された配列が含まれているかを確認します。そのため、JSONレスポンスの中に他のプロパティが存在していても、このテストは指定した一部が残っている限り、テストはパスし続けます。

付け加えて、JSONレスポンスのデータは、レスポンスの配列変数としてアクセスできます。

    $this->assertTrue($response['created']);

<a name="verifying-exact-match"></a>
### JSONとの完全一致を検証

アプリケーションから返されるJSONが、指定した配列と**完全に**一致することを検証したい場合は、`assertExactJson`メソッドを使用します。

    <?php

    class ExampleTest extends TestCase
    {
        /**
         * 基本的な機能テストの例
         *
         * @return void
         */
        public function testBasicExample()
        {
            $response = $this->json('POST', '/user', ['name' => 'Sally']);

            $response
                ->assertStatus(201)
                ->assertExactJson([
                    'created' => true,
                ]);
        }
    }

<a name="verifying-json-paths"></a>
### JSONパスの検証

JSONレスポンスの特定パスに、指定したデータが含まれているかを検証したい場合は、`assertJsonPath`メソッドを使用します。

    <?php

    class ExampleTest extends TestCase
    {
        /**
         * 基本的な機能テストの例
         *
         * @return void
         */
        public function testBasicExample()
        {
            $response = $this->json('POST', '/user', ['name' => 'Sally']);

            $response
                ->assertStatus(201)
                ->assertJsonPath('team.owner.name', 'foo')
        }
    }

<a name="testing-file-uploads"></a>
## ファイルアップロードのテスト

`Illuminate\Http\UploadedFile`クラスは、テストのためにファイルやイメージのダミーを生成するための`fake`メソッドを用意しています。これを`Storage`ファサードの`fake`メソッドと組み合わせることで、ファイルアップロードのテストがとてもシンプルになります。例として、２つの機能を組み合わせて、アバターのアップロードをテストしてみましょう。

    <?php

    namespace Tests\Feature;

    use Illuminate\Foundation\Testing\RefreshDatabase;
    use Illuminate\Foundation\Testing\WithoutMiddleware;
    use Illuminate\Http\UploadedFile;
    use Illuminate\Support\Facades\Storage;
    use Tests\TestCase;

    class ExampleTest extends TestCase
    {
        public function testAvatarUpload()
        {
            Storage::fake('avatars');

            $file = UploadedFile::fake()->image('avatar.jpg');

            $response = $this->json('POST', '/avatar', [
                'avatar' => $file,
            ]);

            // ファイルが保存されたことをアサートする
            Storage::disk('avatars')->assertExists($file->hashName());

            // ファイルが存在しないことをアサートする
            Storage::disk('avatars')->assertMissing('missing.jpg');
        }
    }

#### ダミーファイルのカスタマイズ

`fake`メソッドでファイルを生成するときには、バリデーションルールをより便利にテストできるよう、画像の幅、高さ、サイズを指定できます。

    UploadedFile::fake()->image('avatar.jpg', $width, $height)->size(100);

画像の生成に付け加え、`create`メソッドで他のタイプのファイルも生成できます。

    UploadedFile::fake()->create('document.pdf', $sizeInKilobytes);

ファイルが返すべきMIMEタイプを明示的に定義するために、このメソッドに`$mimeType`引数を必要に応じて渡すことも可能です。

    UploadedFile::fake()->create('document.pdf', $sizeInKilobytes, 'application/pdf');

<a name="testing-views"></a>
## ビューのテスト

LaravelではアプリケーションへのHTTPリクエストをシミュレートしなくても、ビューを分離してレンダリングできます。そのためには、テストの中で`view`メソッドを使ってください。`view`メソッドはビュー名とオプションの配列を引数に取ります。メソッドは`Illuminate\Testing\TestView`インスタンスを返します。

    public function testWelcomeView()
    {
        $view = $this->view('welcome', ['name' => 'Taylor']);

        $view->assertSee('Taylor');
    }

`TestView`オブジェクトは、`assertSee`、`assertSeeInOrder`、`assertSeeText`、`assertSeeTextInOrder`、`assertDontSee`、`assertDontSeeText`のアサートメソッドを提供しています。

必要であれば、`TestView`インスタンスを文字列へキャストすることで、ビューをレンダーした内容をそのまま取得できます。

    $contents = (string) $this->view('welcome');

#### エラーの共有

いくらかのビューは、Laravelが提供するグローバルエラーバッグで共有しているエラーに依存していることがあります。エラーバッグにエラーメッセージを追加するには、`withViewErrors`メソッドを使うことができます。

    $view = $this->withViewErrors([
        'name' => ['Please provide a valid name.']
    ])->view('form');

    $view->assertSee('Please provide a valid name.');

#### Bladeとコンポーネントのレンダリング

必要であれば、もとのBlade文字列を評価しレンダーするため、`blade`メソッドが使用できます。`blade`メソッドは`Illuminate\Testing\TestView`インスタンスを返します。

    $view = $this->blade(
        '<x-component :name="$name" />',
        ['name' => 'Taylor']
    );

    $view->assertSee('Taylor');

`component`メソッドを使用して、Bladeコンポーネントを評価およびレンダーできます。`view`メソッドと同様に、`component`メソッドは`Illuminate\Testing\TestView`のインスタンスを返します。

    $view = $this->component(Profile::class, ['name' => 'Taylor']);

    $view->assertSee('Taylor');

<a name="available-assertions"></a>
## 利用可能なアサート

<a name="response-assertions"></a>
### レスポンスのアサート

[PHPUnit](https://phpunit.de/)機能テスト用に、数多くの追加アサートメソッドをLaravelは提供しています。以下のアサートで、`json`、`get`、`post`、`put`、`delete`テストメソッドから返されたレスポンスへアクセスしてください。

<style>
    .collection-method-list > p {
        column-count: 2; -moz-column-count: 2; -webkit-column-count: 2;
        column-gap: 2em; -moz-column-gap: 2em; -webkit-column-gap: 2em;
    }

    .collection-method-list a {
        display: block;
    }
</style>

<div class="collection-method-list" markdown="1">

[assertCookie](#assert-cookie)
[assertCookieExpired](#assert-cookie-expired)
[assertCookieNotExpired](#assert-cookie-not-expired)
[assertCookieMissing](#assert-cookie-missing)
[assertCreated](#assert-created)
[assertDontSee](#assert-dont-see)
[assertDontSeeText](#assert-dont-see-text)
[assertExactJson](#assert-exact-json)
[assertForbidden](#assert-forbidden)
[assertHeader](#assert-header)
[assertHeaderMissing](#assert-header-missing)
[assertJson](#assert-json)
[assertJsonCount](#assert-json-count)
[assertJsonFragment](#assert-json-fragment)
[assertJsonMissing](#assert-json-missing)
[assertJsonMissingExact](#assert-json-missing-exact)
[assertJsonMissingValidationErrors](#assert-json-missing-validation-errors)
[assertJsonPath](#assert-json-path)
[assertJsonStructure](#assert-json-structure)
[assertJsonValidationErrors](#assert-json-validation-errors)
[assertLocation](#assert-location)
[assertNoContent](#assert-no-content)
[assertNotFound](#assert-not-found)
[assertOk](#assert-ok)
[assertPlainCookie](#assert-plain-cookie)
[assertRedirect](#assert-redirect)
[assertSee](#assert-see)
[assertSeeInOrder](#assert-see-in-order)
[assertSeeText](#assert-see-text)
[assertSeeTextInOrder](#assert-see-text-in-order)
[assertSessionHas](#assert-session-has)
[assertSessionHasInput](#assert-session-has-input)
[assertSessionHasAll](#assert-session-has-all)
[assertSessionHasErrors](#assert-session-has-errors)
[assertSessionHasErrorsIn](#assert-session-has-errors-in)
[assertSessionHasNoErrors](#assert-session-has-no-errors)
[assertSessionDoesntHaveErrors](#assert-session-doesnt-have-errors)
[assertSessionMissing](#assert-session-missing)
[assertStatus](#assert-status)
[assertSuccessful](#assert-successful)
[assertUnauthorized](#assert-unauthorized)
[assertViewHas](#assert-view-has)
[assertViewHasAll](#assert-view-has-all)
[assertViewIs](#assert-view-is)
[assertViewMissing](#assert-view-missing)

</div>

<a name="assert-cookie"></a>
#### assertCookie

レスポンスが指定したクッキーを持っていることを宣言。

    $response->assertCookie($cookieName, $value = null);

<a name="assert-cookie-expired"></a>
#### assertCookieExpired

レスポンスが指定したクッキーを持っており、期限切れであることを宣言。

    $response->assertCookieExpired($cookieName);

<a name="assert-cookie-not-expired"></a>
#### assertCookieNotExpired

レスポンスが指定したクッキーを持っており、期限切れでないことを宣言。

    $response->assertCookieNotExpired($cookieName);

<a name="assert-cookie-missing"></a>
#### assertCookieMissing

レスポンスが指定したクッキーを持っていないことを宣言。

    $response->assertCookieMissing($cookieName);

<a name="assert-created"></a>
#### assertCreated

レスポンスが２０１ステータスコードを持っていることを宣言。

    $response->assertCreated();

<a name="assert-dont-see"></a>
#### assertDontSee

指定した文字列がレスポンスに含まれていないことを宣言。このアサートは第２引数に`false`を指定しない限り、自動的に指定した文字列をエスケープします。

    $response->assertDontSee($value, $escaped = true);

<a name="assert-dont-see-text"></a>
#### assertDontSeeText

指定した文字列がレスポンステキストに含まれていないことを宣言。このアサートは第２引数に`false`を指定しない限り、自動的に指定した文字列をエスケープします。

    $response->assertDontSeeText($value, $escaped = true);

<a name="assert-exact-json"></a>
#### assertExactJson

レスポンスが指定したJSONデータと完全に一致するデータを持っていることを宣言。

    $response->assertExactJson(array $data);

<a name="assert-forbidden"></a>
#### assertForbidden

レスポンスがforbiddenステータスコード（４０３）を持っていることを宣言。

    $response->assertForbidden();

<a name="assert-header"></a>
#### assertHeader

レスポンスに指定したヘッダが存在していることを宣言。

    $response->assertHeader($headerName, $value = null);

<a name="assert-header-missing"></a>
#### assertHeaderMissing

レスポンスに指定したヘッダが存在していないことを宣言。

    $response->assertHeaderMissing($headerName);

<a name="assert-json"></a>
#### assertJson

レスポンスが指定したJSONデータを持っていることを宣言。

    $response->assertJson(array $data, $strict = false);

<a name="assert-json-count"></a>
#### assertJsonCount

レスポンスJSONが、指定したキーのアイテムを、期待値分持っていることを宣言。

    $response->assertJsonCount($count, $key = null);

<a name="assert-json-fragment"></a>
#### assertJsonFragment

レスポンスが指定したJSONの一部を含んでいることを宣言。

    $response->assertJsonFragment(array $data);

<a name="assert-json-missing"></a>
#### assertJsonMissing

レスポンスが指定したJSONの一部を含んでいないことを宣言。

    $response->assertJsonMissing(array $data);

<a name="assert-json-missing-exact"></a>
#### assertJsonMissingExact

レスポンスがJSONの一部をそのまま含んでいないことを宣言。

    $response->assertJsonMissingExact(array $data);

<a name="assert-json-missing-validation-errors"></a>
#### assertJsonMissingValidationErrors

レスポンスが指定したキーに対するJSONバリデーションエラーを含んていないことを宣言。

    $response->assertJsonMissingValidationErrors($keys);

<a name="assert-json-path"></a>
#### assertJsonPath

レスポンスが特定のパスへ指定したデータを含んでいるかを宣言。

    $response->assertJsonPath($path, array $data, $strict = true);

<a name="assert-json-structure"></a>
#### assertJsonStructure

レスポンスが指定したJSONの構造を持っていることを宣言。

    $response->assertJsonStructure(array $structure);

<a name="assert-json-validation-errors"></a>
#### assertJsonValidationErrors

レスポンスが指定したJSONバリデーションエラーを持っていることを宣言。

    $response->assertJsonValidationErrors(array $data);

<a name="assert-location"></a>
#### assertLocation

レスポンスの`Location`ヘッダが、指定したURIを持つことを宣言。

    $response->assertLocation($uri);

<a name="assert-no-content"></a>
#### assertNoContent

レスポンスが指定したステータスコードを持ち、コンテンツを持たないことを宣言。

    $response->assertNoContent($status = 204);

<a name="assert-not-found"></a>
#### assertNotFound

レスポンスがnot foundのステータスコードを持っていることを宣言。

    $response->assertNotFound();

<a name="assert-ok"></a>
#### assertOk

レスポンスが200のステータスコードを持っていることを宣言。

    $response->assertOk();

<a name="assert-plain-cookie"></a>
#### assertPlainCookie

レスポンスが指定した暗号化されていないクッキーを持っていることを宣言。

    $response->assertPlainCookie($cookieName, $value = null);

<a name="assert-redirect"></a>
#### assertRedirect

クライアントが指定したURIへリダイレクトすることを宣言。

    $response->assertRedirect($uri);

<a name="assert-see"></a>
#### assertSee

指定した文字列がレスポンスに含まれていることを宣言。このアサートは第２引数に`false`を指定しない限り、自動的に指定した文字列をエスケープします。

    $response->assertSee($value, $escaped = true);

<a name="assert-see-in-order"></a>
#### assertSeeInOrder

指定した文字列が、順番通りにレスポンスへ含まれていることを宣言。このアサートは第２引数に`false`を指定しない限り、自動的に指定した文字列をエスケープします。

    $response->assertSeeInOrder(array $values, $escaped = true);

<a name="assert-see-text"></a>
#### assertSeeText

指定した文字列がレスポンステキストに含まれていることを宣言。このアサートは第２引数に`false`を指定しない限り、自動的に指定した文字列をエスケープします。

    $response->assertSeeText($value, $escaped = true);

<a name="assert-see-text-in-order"></a>
#### assertSeeTextInOrder

指定した文字列が、順番通りにレスポンステキストへ含まれていることを宣言このアサートは第２引数に`false`を指定しない限り、自動的に指定した文字列をエスケープします。

    $response->assertSeeTextInOrder(array $values, $escaped = true);

<a name="assert-session-has"></a>
#### assertSessionHas

セッションが指定したデータを持っていることを宣言。

    $response->assertSessionHas($key, $value = null);

<a name="assert-session-has-input"></a>
#### assertSessionHasInput

そのセッションが指定値をフラッシュデータの入力配列中に持っていることを宣言。

    $response->assertSessionHasInput($key, $value = null);

<a name="assert-session-has-all"></a>
#### assertSessionHasAll

セッションが指定したリストの値を持っていることを宣言。

    $response->assertSessionHasAll(array $data);

<a name="assert-session-has-errors"></a>
#### assertSessionHasErrors

セッションが指定した`$keys`に対するエラーを持っていることを宣言する。`$keys`が連想配列の場合、それぞれのフィールド(key)に対し指定したエラーメッセージ（値）をセッションが持っていることを宣言する。

    $response->assertSessionHasErrors(array $keys, $format = null, $errorBag = 'default');

<a name="assert-session-has-errors-in"></a>
#### assertSessionHasErrorsIn

セッションが指定したエラーバッグの中に、指定した`$keys`のエラーを持っていることを宣言する。`$keys`が連想配列の場合はエラーバッグの中に、それぞれのフィールド(key)に対し指定したエラーメッセージ（値）をセッションが持っていることを宣言する。

    $response->assertSessionHasErrorsIn($errorBag, $keys = [], $format = null);

<a name="assert-session-has-no-errors"></a>
#### assertSessionHasNoErrors

セッションがエラーを持っていないことを宣言。

    $response->assertSessionHasNoErrors();

<a name="assert-session-doesnt-have-errors"></a>
#### assertSessionDoesntHaveErrors

セッションが、指定したキーに対するエラーを持っていないことを宣言。

    $response->assertSessionDoesntHaveErrors($keys = [], $format = null, $errorBag = 'default');

<a name="assert-session-missing"></a>
#### assertSessionMissing

セッションが指定したキーを持っていないことを宣言。

    $response->assertSessionMissing($key);

<a name="assert-status"></a>
#### assertStatus

クライアントのレスポンスが指定したコードであることを宣言。

    $response->assertStatus($code);

<a name="assert-successful"></a>
#### assertSuccessful

レスポンスが成功（２００以上、３００未満）ステータスコードであることを宣言。

    $response->assertSuccessful();

<a name="assert-unauthorized"></a>
#### assertUnauthorized

レスポンスがオーソライズされていない(401)ステータスコードであることを宣言。

    $response->assertUnauthorized();

<a name="assert-view-has"></a>
#### assertViewHas

レスポンスビューが指定したデータを持っていることを宣言。

    $response->assertViewHas($key, $value = null);

ビューのデータは、レスポンスの配列変数としてアクセスできます。

    $this->assertEquals('Taylor', $response['name']);

<a name="assert-view-has-all"></a>
#### assertViewHasAll

レスポンスビューが指定したリストのデータを持っていることを宣言。

    $response->assertViewHasAll(array $data);

<a name="assert-view-is"></a>
#### assertViewIs

ルートにより、指定したビューが返されたことを宣言。

    $response->assertViewIs($value);

<a name="assert-view-missing"></a>
#### assertViewMissing

レスポンスビューが指定したデータを持っていないことを宣言。

    $response->assertViewMissing($key);

<a name="authentication-assertions"></a>
### 認証のアサート

Laravelは、[PHPUnit](https://phpunit.de/)機能テストのために認証関連のさまざまなアサーションも提供しています。

メソッド           |                 説明
------------------------------------------ | --------------------------------------------
`$this->assertAuthenticated($guard = null);`  |  ユーザーが認証されていることを宣言。
`$this->assertGuest($guard = null);`  |  ユーザーが認証されていないことを宣言。
`$this->assertAuthenticatedAs($user, $guard = null);`  |  指定したユーザーが認証されていることを宣言。
`$this->assertCredentials(array $credentials, $guard = null);`  |  指定した認証情報が有効であることを宣言。
`$this->assertInvalidCredentials(array $credentials, $guard = null);`  |  指定した認証情報が無効であることを宣言。
