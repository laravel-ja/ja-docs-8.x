# ルーティング

- [基本的なルーティング](#basic-routing)
    - [リダイレクトルート](#redirect-routes)
    - [ビュールート](#view-routes)
- [ルートパラメーター](#route-parameters)
    - [必須パラメータ](#required-parameters)
    - [任意パラメータ](#parameters-optional-parameters)
    - [正規表現制約](#parameters-regular-expression-constraints)
- [名前付きルート](#named-routes)
- [ルートグループ](#route-groups)
    - [ミドルウェア](#route-group-middleware)
    - [サブドメインルーティング](#route-group-subdomain-routing)
    - [ルートプレフィックス](#route-group-prefixes)
    - [ルート名プリフィックス](#route-group-name-prefixes)
- [モデル結合ルート](#route-model-binding)
    - [暗黙の結合](#implicit-binding)
    - [明示的な結合](#explicit-binding)
- [フォールバックルート](#fallback-routes)
- [レート制限](#rate-limiting)
    - [レート制限の定義](#defining-rate-limiters)
    - [レート制限をルートに付加する](#attaching-rate-limiters-to-routes)
- [擬似フォームメソッド](#form-method-spoofing)
- [現在のルートへのアクセス](#accessing-the-current-route)
- [Cross-Origin Resource Sharing (CORS)](#cors)

<a name="basic-routing"></a>
## 基本的なルーティング

一番基本のLaravelルートはURIと「クロージャ」により定義され、単純で記述しやすいルートの定義方法を提供しています。

    Route::get('foo', function () {
        return 'Hello World';
    });

<a name="the-default-route-files"></a>
#### デフォルトルート定義ファイル

Laravelの全ルートは、`routes`ディレクトリ下に設置されている、ルートファイルで定義されます。これらのファイルはフレームワークにより、自動的に読み込まれます。`routes/web.php`ファイルで、Webインターフェイスのルートを定義します。定義されたルートは`web`ミドルウェアグループにアサインされ、セッション状態やCSRF保護などの機能が提供されます。`routes/api.php`中のルートはステートレスで、`api`ミドルウェアグループにアサインされます。

ほとんどのアプリケーションでは、`routes/web.php`ファイルからルート定義を始めます。`routes/web.php`中で定義されたルートは、ブラウザで定義したルートのURLを入力することでアクセスします。たとえば、次のルートはブラウザから`http://your-app.test/user`でアクセスします。

    use App\Http\Controllers\UserController;

    Route::get('/user', [UserController::class, 'index']);

`routes/api.php`ファイル中で定義したルートは`RouteServiceProvider`により、ルートグループの中にネストされます。このグループには、`/api`のURIが自動的にプレフィックスされ、それによりこのファイル中の全ルートにわざわざ指定する必要はありません。プレフィックスや他のルートグループオプションに変更する場合は、`RouteServiceProvider`を変更してください。

<a name="available-router-methods"></a>
#### 使用可能なルート定義メソッド

ルータはHTTP動詞に対応してルートを定義できるようにしています。

    Route::get($uri, $callback);
    Route::post($uri, $callback);
    Route::put($uri, $callback);
    Route::patch($uri, $callback);
    Route::delete($uri, $callback);
    Route::options($uri, $callback);

複数のHTTP動詞に対応したルートを登録する必要が起きることもあります。`match`メソッドが利用できます。もしくは全HTTP動詞に対応する`any`メソッドを使い、ルート登録することもできます。

    Route::match(['get', 'post'], '/', function () {
        //
    });

    Route::any('/', function () {
        //
    });

<a name="csrf-protection"></a>
#### CSRF保護

`web`ルートファイル中で定義され、`POST`、`PUT`、`PATCH`、`DELETE`ルートへ送信されるHTMLフォームはすべて、CSRFトークンフィールドを含んでいる必要があります。含めていないと、そのリクエストは拒否されます。CSRF保護についての詳細は、[CSRFのドキュメント](/docs/{{version}}/csrf)をご覧ください。

    <form method="POST" action="/profile">
        @csrf
        ...
    </form>

<a name="redirect-routes"></a>
### リダイレクトルート

他のURIへリダイレクトするルートを定義する場合は、`Route::redirect`メソッドを使用します。このメソッドは便利な短縮形を提供しているので、単純なリダイレクトを実行するために、完全なルートやコントローラを定義する必要はありません。

    Route::redirect('/here', '/there');

`Route::redirect`はデフォルトで、`302`ステータスコードを返します。オプションの第３引数を利用し、ステータスコードをカスタマイズできます。

    Route::redirect('/here', '/there', 301);

`Route::permanentRedirect`メソッドを使えば、`301`ステータスコードが返されます。

    Route::permanentRedirect('/here', '/there');

> {注}リダイレクトルートでルートパラメータを使用する場合、`destination`と`status`パラメータは、Laravelにより予約されているため、使用できません。

<a name="view-routes"></a>
### ビュールート

ルートからビューを返すだけの場合は、`Route::view`メソッドを使用します。`redirect`メソッドと同様に、このメソッドはシンプルな短縮形を提供しており、完全なルートやコントローラを定義する必要はありません。`view`メソッドは、最初の引数にURIを取り、ビュー名は第２引数です。さらに、オプションの第３引数として、ビューへ渡すデータの配列を指定することもできます。

    Route::view('/welcome', 'welcome');

    Route::view('/welcome', 'welcome', ['name' => 'Taylor']);

> {注}ビュールートでルートパラメータを使用する場合、`view`、`data`、`status`、`headers`パラメータはLaravelにより予約されいるため、使用できません。

<a name="route-parameters"></a>
## ルートパラメーター

<a name="required-parameters"></a>
### 必須パラメータ

ルートの中のURIセグメントを取り出す必要が起きることもあります。たとえば、URLからユーザーIDを取り出したい場合です。ルートパラメーターを定義してください。

    Route::get('user/{id}', function ($id) {
        return 'User '.$id;
    });

ルートで必要なだけ、ルートパラメーターを定義できます。

    Route::get('posts/{post}/comments/{comment}', function ($postId, $commentId) {
        //
    });

ルートパラメータは、いつも`{}`括弧で囲み、アルファベット文字で構成してください。ルートパラメータには、ハイフン（`-`）を使えません。下線（`_`）を代わりに使用してください。ルートパラメータは、ルートコールバック／コントローラへ順番通りに注入されます。コールバック／コントローラ引数の名前は考慮されません。

<a name="parameters-optional-parameters"></a>
### 任意パラメータ

ルートパラメータを指定してもらう必要があるが、指定は任意にしたいこともよく起こります。パラメータ名の後に`?`を付けると、任意指定のパラメータになります。対応するルートの引数に、デフォルト値を必ず付けてください。

    Route::get('user/{name?}', function ($name = null) {
        return $name;
    });

    Route::get('user/{name?}', function ($name = 'John') {
        return $name;
    });

<a name="parameters-regular-expression-constraints"></a>
### 正規表現制約

ルートインスタンスの`where`メソッドを使用し、ルートパラメータのフォーマットを制約できます。`where`メソッドはパラメータ名と、そのパラメータがどのように制約を受けるのかを定義する正規表現を引数に取ります。

    Route::get('user/{name}', function ($name) {
        //
    })->where('name', '[A-Za-z]+');

    Route::get('user/{id}', function ($id) {
        //
    })->where('id', '[0-9]+');

    Route::get('user/{id}/{name}', function ($id, $name) {
        //
    })->where(['id' => '[0-9]+', 'name' => '[a-z]+']);

<a name="parameters-global-constraints"></a>
#### グローバル制約

指定した正規表現でいつもルートパラメータを制約したい場合は、`pattern`メソッドを使ってください。`RouteServiceProvider`の`boot`メソッドの中で、このようなパターンを定義します。

    /**
     * ルートモデル結合、パターンフィルタなどの定義
     *
     * @return void
     */
    public function boot()
    {
        Route::pattern('id', '[0-9]+');
    }

パターンを定義すると、パラメータ名を使用している全ルートで、自動的に提供されます。

    Route::get('user/{id}', function ($id) {
        // {id}が数値の場合のみ実行される
    });

<a name="parameters-encoded-forward-slashes"></a>
#### スラッシュのエンコード

Laravelのルーティングコンポーネントは、`/`を除くすべての文字を許可しています。プレースホルダの一部として、明確に`/`を許可する場合は、`where`で正規表現の条件を指定します。

    Route::get('search/{search}', function ($search) {
        return $search;
    })->where('search', '.*');

> {note} スラッシュのエンコードは、最後のルートセグメントでのみサポートしています。

<a name="named-routes"></a>
## 名前付きルート

名前付きルートは特定のルートへのURLを生成したり、リダイレクトしたりする場合に便利です。ルート定義に`name`メソッドをチェーンすることで、そのルートに名前がつけられます。

    Route::get('user/profile', function () {
        //
    })->name('profile');

コントローラアクションに対しても名前を付けることができます。

    Route::get('user/profile', [UserProfileController::class, 'show'])->name('profile');

> {note} ルート名は常に一意にしてください。

<a name="generating-urls-to-named-routes"></a>
#### 名前付きルートへのURLを生成する

ルートに一度名前を付ければ、その名前をグローバルな`route`関数で使用すれば、URLを生成したり、リダイレクトしたりできます。

    // URLの生成
    $url = route('profile');

    // リダイレクトの生成
    return redirect()->route('profile');

そのルートでパラメーターを定義してある場合は、`route`関数の第２引数としてパラメーターを渡してください。指定されたパラメーターは自動的にURLの正しい場所へ埋め込まれます。

    Route::get('user/{id}/profile', function ($id) {
        //
    })->name('profile');

    $url = route('profile', ['id' => 1]);

配列に追加のパラメーターを渡した場合、そうしたキー／値ペアは自動的にクエリ文字列として生成されるURLへ追加されます。

    Route::get('user/{id}/profile', function ($id) {
        //
    })->name('profile');

    $url = route('profile', ['id' => 1, 'photos' => 'yes']);

    // /user/1/profile?photos=yes

> {tip} たとえば現在のローケルのように、URLパラメータへ複数回のリクエスト間に渡るデフォルト値を指定したい場合も時々あります。このためには、[`URL::defaults`メソッド](/docs/{{version}}/urls#default-values)を使用して下さい。

<a name="inspecting-the-current-route"></a>
#### 現在ルートの検査

現在のリクエストが指定した名前付きルートのものであるかを判定したい場合は、Routeインスタンスの`named`メソッドを使います。たとえば、ルートミドルウェアから、現在のルート名を判定できます。

    /**
     * 送信されたリクエストの処理
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure  $next
     * @return mixed
     */
    public function handle($request, Closure $next)
    {
        if ($request->route()->named('profile')) {
            //
        }

        return $next($request);
    }

<a name="route-groups"></a>
## ルートグループ

ルートグループは多くのルートで共通なミドルウェアや名前空間のようなルート属性をルートごとに定義するのではなく、一括して適用するための手法です。`Route::group`メソッドの最初の引数には、共通の属性を配列で指定します。

グループをネストさせると、親のグループに対して属性をできるだけ賢く「マージ」します。ミドルウェアと`where`条件はマージし、名前とプレフィックスは追加します。名前空間のデリミタとURIプレフィックス中のスラッシュは、自動的かつ適切に追加します。

<a name="route-group-middleware"></a>
### ミドルウェア

グループ中の全ルートにミドルウェアを指定するには、そのグループを定義する前に`middleware`メソッドを使用します。ミドルウェアは、配列に定義された順番で実行されます。

    Route::middleware(['first', 'second'])->group(function () {
        Route::get('/', function () {
            // firstとsecondミドルウェアを使用
        });

        Route::get('user/profile', function () {
            // firstとsecondミドルウェアを使用
        });
    });

<a name="route-group-subdomain-routing"></a>
### サブドメインルーティング

ルートグループはワイルドカードサブドメインをルート定義するためにも使えます。サブドメインの部分を取り出しルートやコントローラで使用するために、ルートURIにおけるルートパラメーターのように指定できます。サブドメインはグループを定義する前に、`domain`メソッドを呼び出し指定します。

    Route::domain('{account}.myapp.com')->group(function () {
        Route::get('user/{id}', function ($account, $id) {
            //
        });
    });

> {note} サブドメインルートまで処理を確実に届けるには、ルートドメインルートより前にサブドメインルートを登録する必要があります。これにより、同じURIパスに対するサブドメインルートがルートドメインルートによりオーバーライドされるのを防げます。

<a name="route-group-prefixes"></a>
### ルートプレフィックス

`prefix`メソッドはグループ内の各ルートに対して、指定されたURIのプレフィックスを指定するために使用します。たとえばグループ内の全ルートのURIに`admin`を付けたければ、次のように指定します。

    Route::prefix('admin')->group(function () {
        Route::get('users', function () {
            // Matches The "/admin/users" URL
        });
    });

<a name="route-group-name-prefixes"></a>
### ルート名プリフィックス

`name`メソッドはグループ内の各ルート名へ、指定した文字列をプレフィックスするために使用します。たとえば、グループ内の全ルート名へ`admin`というプレフィックスを付けたいとしましょう。指定した指定した文字列はそのままルート名の前に付きます。そのため、プレフィックスへ最後の`.`文字を確実に指定してください。

    Route::name('admin.')->group(function () {
        Route::get('users', function () {
            // "admin.users"という名前へ結合したルート…
        })->name('users');
    });

<a name="route-model-binding"></a>
## モデル結合ルート

ルートかコントローラアクションへモデルIDが指定される場合、IDに対応するそのモデルを取得するため、大抵の場合クエリします。Laravelのモデル結合はルートへ直接、そのモデルインスタンスを自動的に注入する便利な手法を提供しています。つまり、ユーザーのIDが渡される代わりに、指定されたIDに一致する`User`モデルインスタンスが渡されます。

<a name="implicit-binding"></a>
### 暗黙の結合

Laravelはタイプヒントされた変数名とルートセグメント名が一致する場合、Laravelはルートかコントローラアクション中にEloquentモデルが定義されていると、自動的に依存解決します。

    Route::get('api/users/{user}', function (App\Models\User $user) {
        return $user->email;
    });

`$user`変数が`App\Models\User` Eloquentモデルとしてタイプヒントされており、変数名が`{user}` URIセグメントと一致しているため、Laravelは、リクエストされたURIの対応する値に一致するIDを持つ、モデルインスタンスを自動的に注入します。一致するモデルインスタンスがデータベースへ存在しない場合、404 HTTPレスポンスが自動的に生成されます。

もちろん、コントローラメソッドを使用する場合でも、暗黙的な結合は可能です。繰り返しますが、`{user}` URIセグメントは`App\Models\User`タイプヒントを含むコントローラの`$user`変数と一致することに注意してください。

    use App\Http\Controllers\UserController;
    use App\Models\User;

    Route::get('users/{user}', [UserController::class, 'show']);

    public function show(User $user)
    {
        return view('user.profile', ['user' => $user]);
    }

<a name="customizing-the-key"></a>
#### キーのカスタマイズ

`id`以外のカラムを使用するEloquentモデルでも暗黙の結合を使いたい場合があるでしょう。それには、ルートパラメータ定義でカラムを指定してください。

    Route::get('api/posts/{post:slug}', function (App\Models\Post $post) {
        return $post;
    });

<a name="implicit-model-binding-scoping"></a>
#### カスタムキーと取得

一つの定義中に複数のEloquentモデルを暗黙的に結合し、２つ目のEloquentモデルが最初のEloquentモデルの子である必要がある場合などでは、その２つ目のモデルを取得したいと思うでしょう。例として、特定のユーザーのブログポストをスラグで取得する場合を想像してください。

    use App\Models\Post;
    use App\Models\User;

    Route::get('api/users/{user}/posts/{post:slug}', function (User $user, Post $post) {
        return $post;
    });

カスタムなキーを付けた暗黙の結合をネストしたルートパラメータで使用するとき、親で定義されるリレーションは慣習にしたがい名付けられているだろうとLaravelは推測し、ネストしたモデルへのクエリを自動的に制約します。この場合、`User`モデルには`Post`モデルを取得するために`posts`（ルートパラメータ名の複数形）という名前のリレーションがあると想定します。

<a name="customizing-the-default-key-name"></a>
#### デフォルトキー名のカスタマイズ

特定のモデルの取得時に、`id`以外のデフォルトデータベースカラム名を使用しモデル結合したい場合は、そのEloquentモデルの`getRouteKeyName`メソッドをオーバーライドしてください。

    /**
     * モデルのルートキーの取得
     *
     * @return string
     */
    public function getRouteKeyName()
    {
        return 'slug';
    }

<a name="explicit-binding"></a>
### 明示的な結合

明示的に結合を登録するには、ルータの`model`メソッドで、渡されるパラメータに対するクラスを指定します。`RouteServiceProvider`クラスの`boot`メソッドの中の最初で明示的なモデル結合を定義してください。

    /**
     * ルートモデル結合、パターンフィルタなどの定義
     *
     * @return void
     */
    public function boot()
    {
        Route::model('user', App\Models\User::class);

        // ...
    }

次に`{user}`パラメーターを含むルートを定義します。

    Route::get('profile/{user}', function (App\Models\User $user) {
        //
    });

`{user}`パラメーターを`App\Models\User`モデルへ結合しているため、`User`インスタンスはルートへ注入されます。ですからたとえば、`profile/1`のリクエストでは、データベースからIDが`1`の`User`インスタンスが注入されます。

一致するモデルインスタンスがデータベース上に見つからない場合、404 HTTPレスポンスが自動的に生成されます。

<a name="customizing-the-resolution-logic"></a>
#### 依存解決ロジックのカスタマイズ

独自の依存解決ロジックを使いたい場合は、`Route::bind`メソッドを使います。`bind`メソッドに渡す「クロージャ」は、URIセグメントの値を受け取るので、ルートへ注入したいクラスのインスタンスを返してください。

    /**
     * ルートモデル結合、パターンフィルタなどの定義
     *
     * @return void
     */
    public function boot()
    {
        Route::bind('user', function ($value) {
            return App\Models\User::where('name', $value)->firstOrFail();
        });

        // ...
    }

別の方法として、Eloquentモデルの`resolveRouteBinding`メソッドをオーバーライドすることもできます。このメソッドはURIセグメントの値を受け取り、ルートへ注入すべきクラスのインスタンスを返す必要があります。

    /**
     * 結合値のモデル取得
     *
     * @param  mixed  $value
     * @param  string|null  $field
     * @return \Illuminate\Database\Eloquent\Model|null
     */
    public function resolveRouteBinding($value, $field = null)
    {
        return $this->where('name', $value)->firstOrFail();
    }

ルートが[暗黙的な結合のスコープ](#implicit-model-binding-scoping)を利用している場合、親モデルの子結合を依存解決するために、`resolveChildRouteBinding`メソッドをします。

    /**
     * 値を結合する子モデルの取得
     *
     * @param  string  $childType
     * @param  mixed  $value
     * @param  string|null  $field
     * @return \Illuminate\Database\Eloquent\Model|null
     */
    public function resolveChildRouteBinding($childType, $value, $field)
    {
        return parent::resolveChildRouteBinding($childType, $value, $field);
    }

<a name="fallback-routes"></a>
## フォールバックルート

`Route::fallback`メソッドを使用すれば、受け取ったリクエストが他のルートと一致しない場合に、実行するルートを定義できます。通常、アプリケーションの例外ハンドラにより、処理できないリクエストに対し自動的に"404"ページがレンダーされます。しかしながら、`routes/web.php`ファイルに`fallback`ルートが定義されていれば、`web`ミドルウェアグループの中のすべてのミドルウェアで、このルートが適用されます。必要に応じ、このルートを他のミドルウェアに追加するかどうかは、皆さんの自由です。

    Route::fallback(function () {
        //
    });

> {note} フォールバックルートは、アプリケーションのルート登録で常に一番最後に行わなければなりません。

<a name="rate-limiting"></a>
## レート制限

<a name="defining-rate-limiters"></a>
### レート制限の定義

Laravelは指定ルートまたはルートグループのトラフィック量を制限するために利用できる、強力でカスタマイズ可能なレート制限サービスを用意しています。使い始めるには、アプリケーションの必要に適したレート制限の設定を定義する必要があります。通常、これはアプリケーションの`RouteServiceProvider`で行います。

レート宣言は、`RateLimiter`ファサードの`for`メソッドを使用して定義します。`for`メソッドはレートリミッター名と、このレートリミッターが割り当てられているルートに適用される制限設定を返すクロージャを引数に取ります。

    use Illuminate\Cache\RateLimiting\Limit;
    use Illuminate\Support\Facades\RateLimiter;

    RateLimiter::for('global', function (Request $request) {
        return Limit::perMinute(1000);
    });

受信リクエストが指定されたレート制限を超えると、Laravelは429HTTPステータスコードのレスポンスを自動的に返します。レート制限により返す独自のレスポンスを定義する場合は、`response`メソッドを使用します。

    RateLimiter::for('global', function (Request $request) {
        return Limit::perMinute(1000)->response(function () {
            return response('Custom response...', 429);
        });
    });

レート制限コールバックは受信HTTPリクエストインスタンスを引数に受けるため、受信リクエストまたは認証済みユーザーに基づいた適切なレート制限を動的に構築できます。

    RateLimiter::for('uploads', function (Request $request) {
        return $request->user()->vipCustomer()
                    ? Limit::none()
                    : Limit::perMinute(100);
    });

<a name="segmenting-rate-limits"></a>
#### 分割レート制限

レート制限を任意の値で分割したい場合があります。たとえば、ユーザーが指定ルートへIPアドレスごとに1分あたり100回のアクセスを許可したいとします。これを行うには、レート制限の作成時に`by`メソッドを使用します。

    RateLimiter::for('uploads', function (Request $request) {
        return $request->user()->vipCustomer()
                    ? Limit::none()
                    : Limit::perMinute(100)->by($request->ip());
    });

<a name="multiple-rate-limits"></a>
#### 複数のレート制限

必要であれば、指定するレート制限設定の配列を返せます。各レート制限は配列内で配置された順序に基づき、ルートに対して評価されます。

    RateLimiter::for('login', function (Request $request) {
        return [
            Limit::perMinute(500),
            Limit::perMinute(3)->by($request->input('email')),
        ];
    });

<a name="attaching-rate-limiters-to-routes"></a>
### レート制限をルートに付加する

レート制限は、`throttle`[ミドルウェア](/docs/{{version}}/middleware)を使用して、ルートまたはルートグループに割り付けます。throttleミドルウェアは、そのルートに割り当てるレート制限の名前を引数に取ります。

    Route::middleware(['throttle:uploads'])->group(function () {
        Route::post('/audio', function () {
            //
        });

        Route::post('/video', function () {
            //
        });
    });

<a name="throttling-with-redis"></a>
#### Redis使用時の利用回数制限

通常、`throttle`ミドルウェアは`Illuminate\Routing\Middleware\ThrottleRequests`クラスへマップされます。このマッピングは、アプリケーションのHTTPカーネルで定義されています。ただし、アプリケーションのキャッシュドライバーとしてRedisを使用している場合はこのマッピングを変更して、`Illuminate\Routing\Middleware\ThrottleRequestsWithRedis`クラスを使用することをおすすめします。このクラスは、レート制限の管理でより効率的にRedisを使用します。

    'throttle' => \Illuminate\Routing\Middleware\ThrottleRequestsWithRedis::class,

<a name="form-method-spoofing"></a>
## 擬似フォームメソッド

HTMLフォームは`PUT`、`PATCH`、`DELETE`アクションをサポートしていません。ですから、HTMLフォームから呼ばれる`PUT`、`PATCH`、`DELETE`ルートを定義する時、フォームに`_method`隠しフィールドを追加する必要があります。`_method`フィールドとして送られた値は、HTTPリクエストメソッドとして使用されます。

    <form action="/foo/bar" method="POST">
        <input type="hidden" name="_method" value="PUT">
        <input type="hidden" name="_token" value="{{ csrf_token() }}">
    </form>

`_method`フィールドを生成するために、`@method` Bladeディレクティブを使用することもできます。

    <form action="/foo/bar" method="POST">
        @method('PUT')
        @csrf
    </form>

<a name="accessing-the-current-route"></a>
## 現在のルートへのアクセス

送信されたリクエストを処理しているルートに関する情報へアクセスするには、`Route`ファサードへ`current`、`currentRouteName`、`currentRouteAction`メソッドを使用します。

    $route = Route::current();

    $name = Route::currentRouteName();

    $action = Route::currentRouteAction();

組み込まれている全メソッドを確認するには、[Routeファサードの裏で動作しているクラス](https://laravel.com/api/{{version}}/Illuminate/Routing/Router.html)と、[Routeインスタンス](https://laravel.com/api/{{version}}/Illuminate/Routing/Route.html)の２つについてのAPIドキュメントを参照してください。

<a name="cors"></a>
## Cross-Origin Resource Sharing (CORS)

Laravelは指定値に従い自動的にCORSオプションリクエストへ対応します。CORSの設定はすべて`cors`設定ファイルで行われ、オプションリクエストはグローバルミドルウェアスタックにデフォルトで含まれる`HandleCors`ミドルウェアにより自動的に処理されます。

> {tip} CORSとそのヘッダの詳細は、[CROSに関するMDN Webドキュメンテーション](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#The_HTTP_response_headers)で調べてください。
