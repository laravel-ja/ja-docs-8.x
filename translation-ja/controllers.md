# コントローラ

- [イントロダクション](#introduction)
- [コントローラを書く](#writing-controllers)
    - [基本のコントローラ](#basic-controllers)
    - [シングルアクションコントローラ](#single-action-controllers)
- [コントローラミドルウェア](#controller-middleware)
- [リソースコントローラ](#resource-controllers)
    - [部分的なリソースルート](#restful-partial-resource-routes)
    - [ネストしたリソース](#restful-nested-resources)
    - [リソースルートの命名](#restful-naming-resource-routes)
    - [リソースルートパラメータの命名](#restful-naming-resource-route-parameters)
    - [リソースルートのスコープ](#restful-scoping-resource-routes)
    - [リソースURIのローカライズ](#restful-localizing-resource-uris)
    - [リソースコントローラへのルート追加](#restful-supplementing-resource-controllers)
- [依存注入とコントローラ](#dependency-injection-and-controllers)

<a name="introduction"></a>
## イントロダクション

すべてのリクエスト処理ロジックをルートファイルのクロージャとして定義する代わりに、「コントローラ」クラスを使用してこの動作を整理することを推奨します。コントローラにより、関係するリクエスト処理ロジックを単一のクラスにグループ化できます。たとえば、`UserController`クラスは、ユーザーの表示、作成、更新、削除など、ユーザーに関連するすべての受信リクエストを処理するでしょう。コントローラはデフォルトで、`app/Http/Controllers`ディレクトリに保存します。

<a name="writing-controllers"></a>
## コントローラを書く

<a name="basic-controllers"></a>
### 基本のコントローラ

基本的なコントローラの一例を見てみましょう。コントローラは、Laravelに含まれている基本コントローラクラス、`App\Http\Controllers\Controller`を拡張することに注意してください::

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Models\User;

    class UserController extends Controller
    {
        /**
         * 指定ユーザーのプロファイルを表示
         *
         * @param  int  $id
         * @return \Illuminate\View\View
         */
        public function show($id)
        {
            return view('user.profile', [
                'user' => User::findOrFail($id)
            ]);
        }
    }

このコントローラメソッドのルートは、次のように定義できます。

    use App\Http\Controllers\UserController;

    Route::get('/user/{id}', [UserController::class, 'show']);

受信リクエストが指定したルートURIに一致すると、`App\Http\Controllers\UserController`クラスの`show`メソッドが呼び出され、ルートパラメータがメソッドに渡されます。

> {tip} コントローラは基本クラスを拡張する**必要**はありません。ただし、`middleware`や`authorize`メソッドなどの便利な機能にはアクセスできません。

<a name="single-action-controllers"></a>
### シングルアクションコントローラ

コントローラのアクションがとくに複雑な場合は、コントローラクラス全体をその単一のアクション専用にするのが便利です。これを利用するには、コントローラ内で単一の`__invoke`メソッドを定義します。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Models\User;

    class ProvisionServer extends Controller
    {
        /**
         * 新しいWebサーバをプロビジョニング
         *
         * @return \Illuminate\Http\Response
         */
        public function __invoke()
        {
            // ...
        }
    }

シングルアクションコントローラのルートを登録する場合、コントローラ方式を指定する必要はありません。代わりに、コントローラの名前をルーターに渡すだけです。

    use App\Http\Controllers\ProvisionServer;

    Route::post('/server', ProvisionServer::class);

`make:controller` Artisanコマンドで`--invokable`オプションを指定すると、`__invoke`メソッドを含んだコントローラを生成できます。

    php artisan make:controller ProvisionServer --invokable

> {tip} [stubのリソース公開](/docs/{{version}}/artisan#stub-customization)を使用し、コントローラのスタブをカスタマイズできます。

<a name="controller-middleware"></a>
## コントローラミドルウェア

[ミドルウェア](/docs/{{version}}/middleware)はルートファイルの中で、コントローラのルートに対して指定します。

    Route::get('profile', [UserController::class, 'show'])->middleware('auth');

または、コントローラのコンストラクター内でミドルウェアを指定できると便利な場合があります。コントローラのコンストラクタ内で`middleware`メソッドを使用して、コントローラのアクションにミドルウェアを割り当てられます。

    class UserController extends Controller
    {
        /**
         * 新しいUserControllerインスタンスの生成
         *
         * @return void
         */
        public function __construct()
        {
            $this->middleware('auth');
            $this->middleware('log')->only('index');
            $this->middleware('subscribed')->except('store');
        }
    }

コントローラでは、クロージャを使用したミドルウェアの登録もできます。これにより、ミドルウェアクラス全体を定義せずに、単一のコントローラ用のインラインミドルウェアを便利に定義できます。

    $this->middleware(function ($request, $next) {
        return $next($request);
    });

<a name="resource-controllers"></a>
## リソースコントローラ

アプリケーション内の各Eloquentモデルを「リソース」と考える場合、通常、アプリケーション内の各リソースに対して同じ一連のアクションを実行します。たとえば、アプリケーションに`Photo`モデルと`Movie`モデルが含まれているとします。ユーザーはこれらのリソースを作成、読み取り、更新、または削除できるでしょう。

このようなコモン・ケースのため、Laravelリソースルーティングは、通常の作成、読み取り、更新、および削除("CRUD")ルートを１行のコードでコントローラに割り当てます。使用するには、`make:controller` Artisanコマンドへ`--resource`オプションを指定すると、こうしたアクションを処理するコントローラをすばやく作成できます。

    php artisan make:controller PhotoController --resource

このコマンドは、`app/Http/Controllers/PhotoController.php`にコントローラを生成します。コントローラには、そのまま使用可能な各リソース操作のメソッドを用意してあります。次に、コントローラを指すリソースルートを登録しましょう。

    use App\Http\Controllers\PhotoController;

    Route::resource('photos', PhotoController::class);

この一つのルート宣言で、リソースに対するさまざまなアクションを処理するための複数のルートを定義しています。生成したコントローラには、これらのアクションごとにスタブしたメソッドがすでに含まれています。`route:list` Artisanコマンドを実行すると、いつでもアプリケーションのルートの概要をすばやく確認できます。

配列を`resources`メソッドに渡すことで、一度に多くのリソースコントローラを登録することもできます。

    Route::resources([
        'photos' => PhotoController::class,
        'posts' => PostController::class,
    ]);

<a name="actions-handled-by-resource-controller"></a>
#### リソースコントローラにより処理されるアクション

動詞      | URI                    | アクション       | ルート名
----------|------------------------|--------------|---------------------
GET       | `/photos`              | index        | photos.index
GET       | `/photos/create`       | create       | photos.create
POST      | `/photos`              | store        | photos.store
GET       | `/photos/{photo}`      | show         | photos.show
GET       | `/photos/{photo}/edit` | edit         | photos.edit
PUT/PATCH | `/photos/{photo}`      | update       | photos.update
DELETE    | `/photos/{photo}`      | destroy      | photos.destroy

<a name="specifying-the-resource-model"></a>
#### リソースモデルの指定

[ルートモデル結合](/docs/{{version}}/routing#route-model-binding)を使用していて、リソースコントローラのメソッドでモデルインスタンスをタイプヒントしたい場合は、コントローラを生成するときのオプションに`--model`を使用します。

    php artisan make:controller PhotoController --resource --model=Photo

<a name="restful-partial-resource-routes"></a>
### 部分的なリソースルート

リソースルートの宣言時に、デフォルトアクション全部を指定する代わりに、ルートで処理するアクションの一部を指定可能です。

    use App\Http\Controllers\PhotoController;

    Route::resource('photos', PhotoController::class)->only([
        'index', 'show'
    ]);

    Route::resource('photos', PhotoController::class)->except([
        'create', 'store', 'update', 'destroy'
    ]);

<a name="api-resource-routes"></a>
#### APIリソースルート

APIに使用するリソースルートを宣言する場合、`create`や`edit`のようなHTMLテンプレートを提供するルートを除外したいことがよく起こります。そのため、これらの２ルートを自動的に除外する、`apiResource`メソッドが使用できます。

    use App\Http\Controllers\PhotoController;

    Route::apiResource('photos', PhotoController::class);

`apiResources`メソッドに配列として渡すことで、一度に複数のAPIリソースコントローラを登録できます。

    use App\Http\Controllers\PhotoController;
    use App\Http\Controllers\PostController;

    Route::apiResources([
        'photos' => PhotoController::class,
        'posts' => PostController::class,
    ]);

`create`や`edit`メソッドを含まないAPIリソースコントローラを素早く生成するには、`make:controller`コマンドを実行する際、`--api`スイッチを使用してください。

    php artisan make:controller PhotoController --api

<a name="restful-nested-resources"></a>
### ネストしたリソース

ネストしたリソースへのルートを定義したい場合もあるでしょう。たとえば、写真リソースは、写真へ投稿された複数のコメントを持っているかもしれません。リソースコントローラをネストするには、ルート宣言で「ドット」表記を使用します。

    use App\Http\Controllers\PhotoCommentController;

    Route::resource('photos.comments', PhotoCommentController::class);

このルートにより次のようなURLでアクセスする、ネストしたリソースが定義できます。

    /photos/{photo}/comments/{comment}

<a name="scoping-nested-resources"></a>
#### ネストしたリソースのスコープ

Laravelの[暗黙的なモデル結合](/docs/{{version}}/routing#implicit-model-binding-scoping)機能は、リソース解決する子モデルが親モデルに属することを確認するように、ネストした結合を自動的にスコープできます。ネストしたリソースを定義するときに`scoped`メソッドを使用することにより、自動スコープを有効にしたり、子リソースを取得するフィールドをLaravelに指示したりできます。この実現方法の詳細は、[リソースルートのスコープ](#restful-scoping-resource-routes)に関するドキュメントを参照してください。

<a name="shallow-nesting"></a>
#### Shallowネスト

子のIDがすでに一意な識別子になってる場合、親子両方のIDをURIに含める必要はまったくありません。主キーの自動増分のように、一意の識別子をURIセグメント中でモデルを識別するために使用しているのなら、「shallow（浅い）ネスト」を使用できます。

    use App\Http\Controllers\CommentController;

    Route::resource('photos.comments', CommentController::class)->shallow();

このルート定義は、以下のルートを定義します。

動詞      | URI                               | アクション       | ルート名
----------|-----------------------------------|--------------|---------------------
GET       | `/photos/{photo}/comments`        | index        | photos.comments.index
GET       | `/photos/{photo}/comments/create` | create       | photos.comments.create
POST      | `/photos/{photo}/comments`        | store        | photos.comments.store
GET       | `/comments/{comment}`             | show         | comments.show
GET       | `/comments/{comment}/edit`        | edit         | comments.edit
PUT/PATCH | `/comments/{comment}`             | update       | comments.update
DELETE    | `/comments/{comment}`             | destroy      | comments.destroy

<a name="restful-naming-resource-routes"></a>
### リソースルートの命名

すべてのリソースコントローラアクションにはデフォルトのルート名があります。ただし、`names`配列に指定したいルート名を渡すことで、この名前を上書きできます。

    use App\Http\Controllers\PhotoController;

    Route::resource('photos', PhotoController::class)->names([
        'create' => 'photos.build'
    ]);

<a name="restful-naming-resource-route-parameters"></a>
### リソースルートパラメータの命名

`Route::resource`はデフォルトで、リソース名の「単数形」バージョンに基づいて、リソースルートのルートパラメータを作成します。`parameters`メソッドを使用して、リソースごとにこれを簡単にオーバーライドできます。`parameters`メソッドに渡す配列は、リソース名とパラメーター名の連想配列である必要があります。

    use App\Http\Controllers\AdminUserController;

    Route::resource('users', AdminUserController::class)->parameters([
        'users' => 'admin_user'
    ]);

上記の例では、リソースの`show`ルートに対して以下のURIが生成されます。

    /users/{admin_user}

<a name="restful-scoping-resource-routes"></a>
### リソースルートのスコープ

Laravelの[スコープ付き暗黙モデル結合](/docs/{{version}}/routing#implicit-model-binding-scoping)機能は、解決する子モデルが親モデルに属することを確認するように、ネストした結合を自動的にスコープできます。ネストしたリソースを定義するときに`scoped`メソッドを使用することで、自動スコープを有効にし、以下のように子リソースを取得するフィールドをLaravelに指示できます。

    use App\Http\Controllers\PhotoCommentController;

    Route::resource('photos.comments', PhotoCommentController::class)->scoped([
        'comment' => 'slug',
    ]);

このルートは、以下のようなURIでアクセスする、スコープ付きのネストしたリソースを登録します。

    /photos/{photo}/comments/{comment:slug}

ネストしたルートパラメーターとしてカスタムキー付き暗黙的結合を使用する場合、親からネストしているモデルを取得するために、Laravelはクエリのスコープを自動的に設定し、親のリレーション名を推測する規則を使用します。この場合、`Photo`モデルには、`Comment`モデルを取得するために使用できる`comments`(ルートパラメータ名の複数形)という名前のリレーションがあると想定します。

<a name="restful-localizing-resource-uris"></a>
### リソースURIのローカライズ

`Route::resource`はデフォルトで、英語の動詞を使用してリソースURIを作成します。`create`および`edit`アクション動詞をローカライズする必要がある場合は、`Route::resourceVerbs`メソッドを使用します。これは、アプリケーションの`App\Providers\RouteServiceProvider`内の`boot`メソッドの先頭で実行します。

    /**
     * ルートモデルの結合、パターンフィルターなどを定義
     *
     * @return void
     */
    public function boot()
    {
        Route::resourceVerbs([
            'create' => 'crear',
            'edit' => 'editar',
        ]);

        // ...
    }

動詞をカスタマイズすると、`Route::resource('fotos'、PhotoController::class)`などのリソースルート登録により、次のURIが生成されます。

    /fotos/crear

    /fotos/{foto}/editar

<a name="restful-supplementing-resource-controllers"></a>
### リソースコントローラへのルート追加

リソースルートのデフォルトセットを超えてリソースコントローラにルートを追加する必要がある場合は、`Route::resource`メソッドを呼び出す前にそれらのルートを定義する必要があります。そうしないと、`resource`メソッドで定義されたルートが、意図せずに補足ルートよりも優先される可能性があります。

    use App\Http\Controller\PhotoController;

    Route::get('/photos/popular', [PhotoController::class, 'popular']);
    Route::resource('photos', PhotoController::class);

> {tip} コントローラの責務を限定することを思い出してください。典型的なリソースアクションから外れたメソッドが繰り返して必要になっているようであれば、コントローラを２つに分け、小さなコントローラにすることを考えましょう。

<a name="dependency-injection-and-controllers"></a>
## 依存注入とコントローラ

<a name="constructor-injection"></a>
#### コンストラクターインジェクション

全コントローラの依存を解決するために、Laravelの[サービスコンテナ](/docs/{{version}}/container)が使用されます。これにより、コントローラが必要な依存をコンストラクターにタイプヒントで指定できるのです。依存クラスは自動的に解決され、コントローラへインスタンスが注入されます。

    <?php

    namespace App\Http\Controllers;

    use App\Repositories\UserRepository;

    class UserController extends Controller
    {
        /**
         * ユーザーリポジトリインスタンス
         */
        protected $users;

        /**
         * 新しいコントローラインスタンスの生成
         *
         * @param  \App\Repositories\UserRepository  $users
         * @return void
         */
        public function __construct(UserRepository $users)
        {
            $this->users = $users;
        }
    }

<a name="method-injection"></a>
#### メソッドインジェクション

コンストラクターによる注入に加え、コントローラのメソッドでもタイプヒントにより依存を指定することもできます。メソッドインジェクションの典型的なユースケースは、コントローラメソッドへ`Illuminate\Http\Request`インスタンスを注入する場合です。

    <?php

    namespace App\Http\Controllers;

    use Illuminate\Http\Request;

    class UserController extends Controller
    {
        /**
         * 新ユーザーの保存
         *
         * @param  \Illuminate\Http\Request  $request
         * @return \Illuminate\Http\Response
         */
        public function store(Request $request)
        {
            $name = $request->name;

            //
        }
    }

コントローラメソッドへルートパラメーターによる入力値が渡される場合も、依存定義の後に続けてルート引数を指定します。たとえば以下のようにルートが定義されていれば：

    use App\Http\Controllers\UserController;

    Route::put('/user/{id}', [UserController::class, 'update']);

下記のように`Illuminate\Http\Request`をタイプヒントで指定しつつ、コントローラメソッドで定義している`id`パラメータにアクセスできます。

    <?php

    namespace App\Http\Controllers;

    use Illuminate\Http\Request;

    class UserController extends Controller
    {
        /**
         * 指定ユーザーの更新
         *
         * @param  \Illuminate\Http\Request  $request
         * @param  string  $id
         * @return \Illuminate\Http\Response
         */
        public function update(Request $request, $id)
        {
            //
        }
    }
