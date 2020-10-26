# コントローラ

- [イントロダクション](#introduction)
- [基本のコントローラ](#basic-controllers)
    - [コントローラの定義](#defining-controllers)
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
- [ルートキャッシュ](#route-caching)

<a name="introduction"></a>
## イントロダクション

全リクエストの処理をルートファイルのクロージャで定義するよりも、コントローラクラスにより組織立てたいと、皆さんも考えるでしょう。関連のあるHTTPリクエストの処理ロジックを一つのクラスへまとめ、グループ分けができます。コントローラは`app/Http/Controllers`ディレクトリ下に設置します。

<a name="basic-controllers"></a>
## 基本のコントローラ

<a name="defining-controllers"></a>
### コントローラの定義

これは基本的なコントローラの一例です。すべてのLaravelコントローラはLaravelに含まれている基本コントローラクラスを拡張します。コントローラアクションにミドルウェアを追加するために使う`middleware`メソッドのように、便利なメソッドをベースクラスは提供しています。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Models\User;

    class UserController extends Controller
    {
        /**
         * 指定ユーザーのプロフィール表示
         *
         * @param  int  $id
         * @return \Illuminate\View\View
         */
        public function show($id)
        {
            return view('user.profile', ['user' => User::findOrFail($id)]);
        }
    }

コントローラアクションへルート付けるには、次のようにします。

    use App\Http\Controllers\UserController;

    Route::get('user/{id}', [UserController::class, 'show']);

これで指定したルートのURIにリクエストが一致すれば、`UserController`の`show`メソッドが実行されます。ルートパラメーターはメソッドに渡されます。

> {tip} コントローラはベースクラスの拡張を**要求**してはいません。しかし、`middleware`、`validate`、`dispatch`のような便利な機能へアクセスできなくなります。

<a name="single-action-controllers"></a>
### シングルアクションコントローラ

アクションを一つだけ含むコントローラを定義したい場合は、そのコントローラに`__invoke`メソッドを設置してください。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Models\User;

    class ShowProfile extends Controller
    {
        /**
         * 指定ユーザーのプロフィール表示
         *
         * @param  int  $id
         * @return \Illuminate\View\View
         */
        public function __invoke($id)
        {
            return view('user.profile', ['user' => User::findOrFail($id)]);
        }
    }

シングルアクションコントローラへのルートを定義するとき、メソッドを指定する必要はありません。

    use App\Http\Controllers\ShowProfile;

    Route::get('user/{id}', ShowProfile::class);

`make:controller` Artisanコマンドに、`--invokable`オプションを指定すると、`__invoke`メソッドを含んだコントローラを生成できます。

    php artisan make:controller ShowProfile --invokable

> {tip} [stubのリソース公開](/docs/{{version}}/artisan#stub-customization)を使用し、コントローラのスタブをカスタマイズできます。

<a name="controller-middleware"></a>
## コントローラミドルウェア

[ミドルウェア](/docs/{{version}}/middleware)はルートファイルの中で、コントローラのルートに対して指定します。

    Route::get('profile', [UserController::class, 'show'])->middleware('auth');

もしくは、コントローラのコンストラクタの中でミドルウェアを指定するほうが、より便利でしょう。コントローラのコンストラクタで、`middleware`メソッドを使い、コントローラのアクションに対するミドルウェアを簡単に指定できます。コントローラクラスの特定のメソッドに対してのみ、ミドルウェアの適用を制限することもできます。

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

コントローラではクロージャを使い、ミドルウェアを登録することもできます。これはミドルウェア全体を定義せずに、一つのコントローラのために、一つのミドルウェアを定義する便利な方法です。

    $this->middleware(function ($request, $next) {
        // ...

        return $next($request);
    });

> {tip} コントローラアクションの一部へミドルウェアを適用することはできますが、しかしながら、これはコントローラが大きくなりすぎたことを示しています。代わりに、コントローラを複数の小さなコントローラへ分割することを考えてください。

<a name="resource-controllers"></a>
## リソースコントローラ

Laravelリソースルートは一行のコードで、典型的な「CRUD」ルートをコントローラへ割り付けます。たとえば、アプリケーションへ保存されている「写真(photo)」に対する全HTTPリクエストを処理するコントローラを作成したいとしましょう。`make:controller` Artisanコマンドを使えば、このようなコントローラは素早く生成できます。

    php artisan make:controller PhotoController --resource

このArtisanコマンドは`app/Http/Controllers/PhotoController.php`としてコントローラファイルを生成します。コントローラは使用可能な各リソース操作に対するメソッドを含んでいます。

次に、コントローラへのリソースフルルートを登録します。

    Route::resource('photos', PhotoController::class);

リソースに対するさまざまなアクションを処理する、複数のルートがこの１定義により生成されます。これらのアクションをHTTP動詞と処理するURIの情報を注記と一緒に含むスタブメソッドとして、生成されたコントローラはすでに含んでいます。

一度に多くのリソースコントローラを登録するには、`resources`メソッドへ配列で渡します。

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

ルートモデル結合を使用しているが、リソースコントローラのメソッドでタイプヒントされるモデルインスタンスを指定したい場合は、コントローラの生成時に`--model`オプションを使用します。

    php artisan make:controller PhotoController --resource --model=Photo

<a name="restful-partial-resource-routes"></a>
### 部分的なリソースルート

リソースルートの宣言時に、デフォルトアクション全部を指定する代わりに、ルートで処理するアクションの一部を指定可能です。

    Route::resource('photos', PhotoController::class)->only([
        'index', 'show'
    ]);

    Route::resource('photos', PhotoController::class)->except([
        'create', 'store', 'update', 'destroy'
    ]);

<a name="api-resource-routes"></a>
#### APIリソースルート

APIに使用するリソースルートを宣言する場合、`create`や`edit`のようなHTMLテンプレートを提供するルートを除外したいことがよく起こります。そのため、これらの２ルートを自動的に除外する、`apiResource`メソッドが使用できます。

    Route::apiResource('photos', PhotoController::class);

`apiResources`メソッドに配列として渡すことで、一度に複数のAPIリソースコントローラを登録できます。

    Route::apiResources([
        'photos' => PhotoController::class,
        'posts' => PostController::class,
    ]);

`create`や`edit`メソッドを含まないAPIリソースコントローラを素早く生成するには、`make:controller`コマンドを実行する際、`--api`スイッチを使用してください。

    php artisan make:controller API/PhotoController --api

<a name="restful-nested-resources"></a>
### ネストしたリソース

ネストしたリソースへのルートを定義する場合も起きるでしょう。たとえば、電話リソースが複数のコメントを持ち、コメントは一つの電話に所属しているとしましょう。リソースコントローラをネストするには、「ドット」記法をルート定義で使用します。

    Route::resource('photos.comments', PhotoCommentController::class);

このルートにより次のようなURLでアクセスされる、ネストされたリソースが定義されます。

    /photos/{photo}/comments/{comment}

<a name="scoping-nested-resources"></a>
#### ネストしたリソースのスコープ

Laravelの[暗黙的なモデル結合](/docs/{{version}}/routing#implicit-model-binding-scoping)機能は、依存解決された子モデルが親モデルに属していることが確約されるように、ネストされたバインディングのスコープを自動的に設定します。ネストされたリソースを定義するときに、`scoped`メソッドを使用することで、自動スコープを有効にするだけでなく、子リソースのどのフィールドを獲得するかLaravelに指示できます。

    Route::resource('photos.comments', PhotoCommentController::class)->scoped([
        'comment' => 'slug',
    ]);

このルートは次のようなURIでアクセスされる、スコープしたネストリソースを登録します。

    /photos/{photo}/comments/{comment:slug}

<a name="shallow-nesting"></a>
#### Shallowネスト

子のIDがすでに一意な識別子になってる場合、親子両方のIDをURIに含める必要はまったくありません。主キーの自動増分のように、一意の識別子をURIセグメント中でモデルを識別するために使用しているのなら、「shallow（浅い）ネスト」を使用できます。

    Route::resource('photos.comments', CommentController::class)->shallow();

上記のルート定義により、以下のルートが用意されます。

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

すべてのリソースコントローラアクションは、デフォルトのルート名が決められています。しかし、オプションに`names`配列を渡せば、こうした名前をオーバーライドできます。

    Route::resource('photos', PhotoController::class)->names([
        'create' => 'photos.build'
    ]);

<a name="restful-naming-resource-route-parameters"></a>
### リソースルートパラメータの命名

`Route::resource`はデフォルトで、リソース名の「複数形」を元にし、リソースルートのルートパラメータを生成します。`parameters`メソッドを使用して、リソース毎にこれを簡単にオーバーライドできます。リソース名とパラメータ名の連想配列を`parameters`へ渡してください。

    Route::resource('users', AdminUserController::class)->parameters([
        'users' => 'admin_user'
    ]);

上記のサンプルコードは、リソースの`show`ルートで次のURIを生成します。

    /users/{admin_user}

<a name="restful-scoping-resource-routes"></a>
### リソースルートのスコープ

リソースルート定義で複数のEloquentモデルを暗黙的にバインドする場合、最初のEloquentモデルの子限定のように、２番目のEloquentモデルをスコープする必要が起きえます。たとえば、指定ユーザーのスラグでブログ投稿を取得する状況を考えてください。

    use App\Http\Controllers\PostsController;

    Route::resource('users.posts', PostsController::class)->scoped();

`scoped`メソッドに配列を渡し、デフォルトモデルのルートキーをオーバーライドできます。

    use App\Http\Controllers\PostsController;

    Route::resource('users.posts', PostsController::class)->scoped([
        'post' => 'slug',
    ]);

ネストしたルートパラメータとしてカスタムキー付きの暗黙のバインディングを使用すると、Laravelは自動的にネストしたモデルを取得するためにクエリをスコープします。このとき、親には規約に即したリレーション名が使われているものとして扱います。今回の例の場合、`User`モデルには`Post`モデルを取得するために使用できる`posts`（ルートパラメーター名の複数型）の名前を持つリレーションがあると仮定します。

<a name="restful-localizing-resource-uris"></a>
### リソースURIのローカライズ

`Route::resource`はデフォルトで、リソースURIに英語の動詞を使います。`create`と`edit`アクションの動詞をローカライズする場合は、`Route::resourceVerbs`メソッドを使います。このメソッドは、`AppServiceProvider`の`boot`メソッド中で呼び出します。

    use Illuminate\Support\Facades\Route;

    /**
     * 全アプリケーションサービスの初期起動処理
     *
     * @return void
     */
    public function boot()
    {
        Route::resourceVerbs([
            'create' => 'crear',
            'edit' => 'editar',
        ]);
    }

動詞をカスタマイズすると、`Route::resource('fotos', 'PhotoController')`のようなリソースルートの登録により、以下のようなURIが生成されるようになります。

    /fotos/crear

    /fotos/{foto}/editar

<a name="restful-supplementing-resource-controllers"></a>
### リソースコントローラへのルート追加

デフォルトのリソースルート以外のルートをリソースコントローラへ追加する場合は、`Route::resource`の呼び出しより前に定義する必要があります。そうしないと、`resource`メソッドにより定義されるルートが、追加のルートより意図に反して優先されます。

    Route::get('photos/popular', [PhotoController::class, 'popular']);

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
         * @param  UserRepository  $users
         * @return void
         */
        public function __construct(UserRepository $users)
        {
            $this->users = $users;
        }
    }

[Laravelの契約](/docs/{{version}}/contracts)もタイプヒントに指定できます。コンテナが依存解決可能であれば、タイプヒントで指定できます。 アプリケーションによりますが、依存をコントローラへ注入することで、より良いテスタビリティが得られるでしょう。

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
         * @param  Request  $request
         * @return Response
         */
        public function store(Request $request)
        {
            $name = $request->name;

            //
        }
    }

コントローラメソッドへルートパラメーターによる入力値が渡される場合も、依存定義の後に続けてルート引数を指定します。たとえば以下のようにルートが定義されていれば：

    Route::put('user/{id}', [UserController::class, 'update']);

下記のように`Illuminate\Http\Request`をタイプヒントで指定しつつ、コントローラメソッドで定義している`id`パラメータにアクセスできます。

    <?php

    namespace App\Http\Controllers;

    use Illuminate\Http\Request;

    class UserController extends Controller
    {
        /**
         * 指定ユーザーの更新
         *
         * @param  Request  $request
         * @param  string  $id
         * @return Response
         */
        public function update(Request $request, $id)
        {
            //
        }
    }

<a name="route-caching"></a>
## ルートキャッシュ

アプリケーションがコントローラベースのルート定義だけを使用しているなら、Laravelのルートキャッシュを利用できる利点があります。ルートキャッシュを使用すれば、アプリケーションの全ルートを登録するのに必要な時間を劇的に減らすことができます。ある場合には、ルート登録が１００倍も早くなります。ルートキャッシュを登録するには、`route:cache` Arisanコマンドを実行するだけです。

    php artisan route:cache

このコマンドを実行後、キャッシュ済みルートファイルが、リクエストのたびに読み込まれます。新しいルートを追加する場合は、新しいルートキャッシュを生成する必要があることを覚えておきましょう。ですからプロジェクトの開発期間の最後に、一度だけ`route:cache`を実行するほうが良いでしょう。

キャッシュルートのファイルを削除するには、`route:clear`コマンドを使います。

    php artisan route:clear
