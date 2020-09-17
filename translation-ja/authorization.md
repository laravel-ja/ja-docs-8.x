# 認可

- [イントロダクション](#introduction)
- [ゲート](#gates)
    - [ゲートの記述](#writing-gates)
    - [アクションの認可](#authorizing-actions-via-gates)
    - [ゲートレスポンス](#gate-responses)
    - [ゲートチェックのインターセプト](#intercepting-gate-checks)
- [ポリシーの作成](#creating-policies)
    - [ポリシーの生成](#generating-policies)
    - [ポリシーの登録](#registering-policies)
- [ポリシーの記述](#writing-policies)
    - [ポリシーのメソッド](#policy-methods)
    - [ポリシーレスポンス](#policy-responses)
    - [モデルを持たないメソッド](#methods-without-models)
    - [ゲストユーザー](#guest-users)
    - [ポリシーフィルタ](#policy-filters)
- [ポリシーを使ったアクションの認可](#authorizing-actions-using-policies)
    - [Userモデルによる認可](#via-the-user-model)
    - [ミドルウェアによる認可](#via-middleware)
    - [コントローラヘルパによる認可](#via-controller-helpers)
    - [Bladeテンプレートによる認可](#via-blade-templates)
    - [追加コンテキストの指定](#supplying-additional-context)

<a name="introduction"></a>
## イントロダクション

Laravelは組み込み済みの[認証](/docs/{{version}}/authentication)サービスに加え、特定のリソースに対するユーザーアクションを認可する簡単な手法も提供しています。認証と同様に、Laravelの認可のアプローチはシンプルで、主に２つの認可アクションの方法があります。ゲートとポリシーです。

ゲートとポリシーは、ルートとコントローラのようなものであると考えてください。ゲートはシンプルな、クロージャベースのアプローチを認可に対してとっています。一方のコントローラに似ているポリシーとは、特定のモデルやリソースに対するロジックをまとめたものです。最初にゲートを説明し、次にポリシーを確認しましょう。

アプリケーション構築時にゲートだけを使用するか、それともポリシーだけを使用するかを決める必要はありません。ほとんどのアプリケーションでゲートとポリシーは混在して使われますが、それで正しいのです。管理者のダッシュボードのように、モデルやリソースとは関連しないアクションに対し、ゲートは主に適用されます。それに対し、ポリシーは特定のモデルやリソースに対するアクションを認可したい場合に、使用する必要があります。

<a name="gates"></a>
## ゲート

<a name="writing-gates"></a>
### ゲートの記述

ゲートは、特定のアクションを実行できる許可が、あるユーザーにあるかを決めるクロージャのことです。通常は、`App\Providers\AuthServiceProvider`の中で、`Gate`ファサードを使用し、定義します。ゲートは常に最初の引数にユーザーインスタンスを受け取ります。関連するEloquentモデルのような、追加の引数をオプションとして受け取ることもできます。

    /**
     * 全認証／認可サービスの登録
     *
     * @return void
     */
    public function boot()
    {
        $this->registerPolicies();

        Gate::define('edit-settings', function ($user) {
            return $user->isAdmin;
        });

        Gate::define('update-post', function ($user, $post) {
            return $user->id === $post->user_id;
        });
    }

ゲートはコントローラのように、コールバックの配列を使い定義することもできます。

    use App\Policies\PostPolicy;

    /**
     * 全認証／認可サービスの登録
     *
     * @return void
     */
    public function boot()
    {
        $this->registerPolicies();

        Gate::define('update-post', [PostPolicy::class, 'update']);
    }

<a name="authorizing-actions-via-gates"></a>
### アクションの認可

ゲートを使用しアクションを認可するには、`allows`と`denies`メソッドを使ってください。両メソッドに現在認証中のユーザーを渡す必要はないことに注目しましょう。Laravelが自動的にゲートクロージャにユーザーを渡します。

    if (Gate::allows('edit-settings')) {
        // 現在のユーザーは設定を変更できる
    }

    if (Gate::allows('update-post', $post)) {
        // 現在のユーザーはこのポストを更新できる
    }

    if (Gate::denies('update-post', $post)) {
        // 現在のユーザーはこのポストを更新できない
    }

特定のユーザーがあるアクションを実行できる認可を持っているかを確認するには、`Gate`ファサードの`forUser`メソッドを使用します。

    if (Gate::forUser($user)->allows('update-post', $post)) {
        // 渡されたユーザーはこのポストを更新できる
    }

    if (Gate::forUser($user)->denies('update-post', $post)) {
        // ユーザーはこのポストを更新できない
    }

`any`と`none`メソッドを使い、複数のアクションの許可を一度に指定できます。

    if (Gate::any(['update-post', 'delete-post'], $post)) {
        // ユーザーはポストの更新と削除ができる
    }

    if (Gate::none(['update-post', 'delete-post'], $post)) {
        // ユーザーはポストの更新と削除ができない
    }

#### 認証か例外を投げる

認証を試み、そのユーザーが指定したアクションの実行が許されていない場合は、自動的に`Illuminate\Auth\Access\AuthorizationException`例外を投げる方法を取るには、`Gate::authorize`メソッドを使用します。`AuthorizationException`は自動的に`403` HTTPレスポンスへ変換されます。

    Gate::authorize('update-post', $post);

    // アクションが認証された…

#### 追加コンテキストの指定

認可アビリティのゲートメソッド（`allows`、`denies`、`check`、`any`、`none`、`authorize`、`can`、`cannot`）と認可[Bladeディレクティブ](#via-blade-templates)（`@can`、`@cannot`、`@canany`）では２番めの引数として配列を受け取れます。これらの配列要素はゲートにパラメータとして渡されたもので、認可の可否を決定する際に、追加コンテキストとして利用できます。

    Gate::define('create-post', function ($user, $category, $extraFlag) {
        return $category->group > 3 && $extraFlag === true;
    });

    if (Gate::check('create-post', [$category, $extraFlag])) {
        // このユーザーはポストを新規作成できる
    }

<a name="gate-responses"></a>
### ゲートレスポンス

ここまでは、単純な論理値を返すゲートのみを見てきました。しかしながら、エラーメッセージを含んだ、より詳細なレスポンスを返したい場合もあるでしょう。そのためには、ゲートから`Illuminate\Auth\Access\Response`を返します。

    use Illuminate\Auth\Access\Response;
    use Illuminate\Support\Facades\Gate;

    Gate::define('edit-settings', function ($user) {
        return $user->isAdmin
                    ? Response::allow()
                    : Response::deny('You must be a super administrator.');
    });

認可レスポンスをゲートから返す場合、`Gate::allows`メソッドはシンプルに論理値を返します。ゲートから返される完全な認可レスポンスを取得したい場合は、`Gate::inspect`を使います。

    $response = Gate::inspect('edit-settings', $post);

    if ($response->allowed()) {
        // アクションは認可された…
    } else {
        echo $response->message();
    }

もちろん、アクションを許可できない場合、`AuthorizationException`を投げるために`Gate::authorize`メソッドを使うと、認可レスポンスが提供するエラーメッセージは、HTTPレスポンスへ伝わります。

    Gate::authorize('edit-settings', $post);

    // アクションが認証された…

<a name="intercepting-gate-checks"></a>
### ゲートチェックのインターセプト

特定のユーザーに全アビリティーへ許可を与えたい場合もあります。`before`メソッドは、他のすべての認可チェック前に実行される、コールバックを定義します。

    Gate::before(function ($user, $ability) {
        if ($user->isSuperAdmin()) {
            return true;
        }
    });

`before`コールバックでNULL以外の結果を返すと、チェックの結果とみなされます。

`after`メソッドで、すべての認可チェック後に実行されるコールバックを定義することも可能です。

    Gate::after(function ($user, $ability, $result, $arguments) {
        if ($user->isSuperAdmin()) {
            return true;
        }
    });

`before`チェックと同様に、`after`コールバックからNULLでない結果を返せば、その結果はチェック結果として取り扱われます。

<a name="creating-policies"></a>
## ポリシー作成

<a name="generating-policies"></a>
### ポリシーの生成

ポリシーは特定のモデルやリソースに関する認可ロジックを系統立てるクラスです。たとえば、ブログアプリケーションの場合、`Post`モデルとそれに対応する、ポストを作成／更新するなどのユーザーアクションを認可する`PostPolicy`を持つことになるでしょう。

`make:policy` [Artisanコマンド](/docs/{{version}}/artisan)を使用し、ポリシーを生成できます。生成したポリシーは`app/Policies`ディレクトリに設置されます。このディレクトリがアプリケーションに存在していなくても、Laravelにより作成されます。

    php artisan make:policy PostPolicy

`make:policy`コマンドは空のポリシークラスを生成します。基本的な「CRUD」ポリシーメソッドを生成するクラスへ含めたい場合は、`make:policy`コマンド実行時に`--model`を指定してください。

    php artisan make:policy PostPolicy --model=Post

> {tip} 全ポリシーはLaravelの [サービスコンテナ](/docs/{{version}}/container)により依存解決されるため、ポリシーのコンストラクタに必要な依存をタイプヒントすれば、自動的に注入されます。

<a name="registering-policies"></a>
### ポリシーの登録

ポリシーができたら、登録する必要があります。インストールしたLaravelアプリケーションに含まれている、`AuthServiceProvider`にはEloquentモデルと対応するポリシーをマップするための`policies`プロパティを含んでいます。ポリシーの登録とは、指定したモデルに対するアクションの認可時に、どのポリシーを利用するかをLaravelへ指定することです。

    <?php

    namespace App\Providers;

    use App\Models\Post;
    use App\Policies\PostPolicy;
    use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;
    use Illuminate\Support\Facades\Gate;

    class AuthServiceProvider extends ServiceProvider
    {
        /**
         * アプリケーションにマップ付されたポリシー
         *
         * @var array
         */
        protected $policies = [
            Post::class => PostPolicy::class,
        ];

        /**
         * アプリケーションの全認証／認可サービスの登録
         *
         * @return void
         */
        public function boot()
        {
            $this->registerPolicies();

            //
        }
    }

#### ポリシーの自動検出

モデルポリシーをいちいち登録する代わりに、モデルとポリシーの標準命名規則にしたがっているポリシーを自動的にLaravelは見つけます。具体的にはモデルが含まれているディレクトリの下に存在する、`Policies`ディレクトリ中のポリシーです。たとえば、モデルが`app/Models`ディレクトリ下にあれば、ポリシーは`app/Policies`ディレクトリへ置く必要があります。この場合は、Laravelは`app/Models/Policies`下を調べ、次に`app/Policies`を調べます。さらに、ポリシーの名前は対応するモデルの名前へ、`Policy`サフィックスを付けたものにする必要があります。ですから、`User`モデルに対応させるには、`UserPolicy`クラスと命名します。

独自のポリシー発見ロジックを利用したい場合、`Gate::guessPolicyNamesUsing`メソッドでカスタムコールバックを登録します。通常このメソッドは、`AuthServiceProvider`の`boot`メソッドから呼び出すべきでしょう。

    use Illuminate\Support\Facades\Gate;

    Gate::guessPolicyNamesUsing(function ($modelClass) {
        // ポリシークラス名を返す
    });

> {note} Any policies that are explicitly mapped in your `AuthServiceProvider` will take precedence over any potentially auto-discovered policies.

<a name="writing-policies"></a>
## ポリシーの記述

<a name="policy-methods"></a>
### ポリシーのメソッド

ポリシーが登録できたら、認可するアクションごとにメソッドを追加します。たとえば、指定した`User`が指定`Post`インスタンスの更新をできるか決める、`update`メソッドを`PostPolicy`に定義してみましょう。

`update`メソッドは`User`と`Post`インスタンスを引数で受け取り、ユーザーが指定`Post`の更新を行う認可を持っているかを示す、`true`か`false`を返します。ですから、この例の場合、ユーザーの`id`とポストの`user_id`が一致するかを確認しましょう。

    <?php

    namespace App\Policies;

    use App\Models\Post;
    use App\Models\User;

    class PostPolicy
    {
        /**
         * ユーザーにより指定されたポストが更新可能か決める
         *
         * @param  \App\Models\User  $user
         * @param  \App\Models\Post  $post
         * @return bool
         */
        public function update(User $user, Post $post)
        {
            return $user->id === $post->user_id;
        }
    }

必要に応じ、さまざまなアクションを認可するために、追加のメソッドをポリシーに定義してください。たとえば、色々な`Post`アクションを認可するために、`view`や`delete`メソッドを追加できます。ただし、ポリシーのメソッドには好きな名前を自由につけられることを覚えておいてください。

> {tip} ポリシーを`--model`オプションを付け、Artisanコマンドにより生成した場合、`viewAny`、`view`、`create`、`update`、`delete`、`restore`、`forceDelete`アクションが含まれています。

<a name="policy-responses"></a>
### ポリシーレスポンス

これまで、シンプルな論理値を返すポリシーメソッドだけを見てきました。しかし、エラーメッセージを含むより詳細なレスポンスを返したいこともあります。それには、ポリシーメソッドから`Illuminate\Auth\Access\Response`を返してください。

    use Illuminate\Auth\Access\Response;

    /**
     * このユーザーにより、指定ポストが更新できるか判定
     *
     * @param  \App\Models\User  $user
     * @param  \App\Models\Post  $post
     * @return \Illuminate\Auth\Access\Response
     */
    public function update(User $user, Post $post)
    {
        return $user->id === $post->user_id
                    ? Response::allow()
                    : Response::deny('You do not own this post.');
    }

ポリシーから認可レスポンスを返す場合、`Gate::allows`メソッドはシンプルな論理値を返します。しかし、ゲートから完全な認可レスポンスを取得するには、`Gate::inspect`メソッドを使用します。

    $response = Gate::inspect('update', $post);

    if ($response->allowed()) {
        // アクションは認可された…
    } else {
        echo $response->message();
    }

もちろん、アクションを許可できない場合、`AuthorizationException`を投げるために`Gate::authorize`メソッドを使うと、認可レスポンスが提供するエラーメッセージは、HTTPレスポンスへ伝わります。

    Gate::authorize('update', $post);

    // アクションが認証された…

<a name="methods-without-models"></a>
### モデルを持たないメソッド

ポリシーメソッドの中には、現在の認証ユーザーのみを受け取り、認可するためのモデルを必要としないものもあります。この状況は、`create`アクションを認可する場合に、よく現れます。たとえば、ブログを作成する場合、どんなポストかにはかかわらず、そのユーザーが作成可能かを認可したいでしょう。

`create`のように、モデルインスタンスを受け取らないポリシーメソッドを定義する場合は、モデルインスタンスを受け取る必要はありません。代わりに、その認証済みユーザーが期待している人物かをメソッドで定義してください。

    /**
     * 指定されたユーザーがポストを作成できるかを決める
     *
     * @param  \App\Models\User  $user
     * @return bool
     */
    public function create(User $user)
    {
        //
    }

<a name="guest-users"></a>
### ゲストユーザー

HTTPリクエストが認証済みユーザーにより開始されたものでなければ、すべてのゲートとポリシーは自動的にデフォルトとして`false`を返します。しかし、「オプショナル」なタイプヒントを宣言するか、ユーザーの引数宣言に`null`デフォルトバリューを指定することで、ゲートやポリシーに対する認可チェックをパスさせることができます。

    <?php

    namespace App\Policies;

    use App\Models\Post;
    use App\Models\User;

    class PostPolicy
    {
        /**
         * ユーザーにより指定されたポストが更新可能か決める
         *
         * @param  \App\Models\User  $user
         * @param  \App\Models\Post  $post
         * @return bool
         */
        public function update(?User $user, Post $post)
        {
            return optional($user)->id === $post->user_id;
        }
    }

<a name="policy-filters"></a>
### ポリシーフィルター

特定のユーザーには指定したポリシーの全アクションを許可したい場合があります。それには、`before`メソッドをポリシーへ定義してください。`before`メソッドはポリシーの他のメソッドの前に実行されるため、意図するポリシーメソッドが実際に呼び出される前で、アクションを許可する機会を提供します。この機能は主に、アプリケーションの管理者にすべてのアクションを実行する権限を与えるために使用されます。

    public function before($user, $ability)
    {
        if ($user->isSuperAdmin()) {
            return true;
        }
    }

ユーザーに対して全認可を禁止したい場合は、`before`メソッドから`false`を返します。`null`を返した場合、その認可の可否はポリシーメソッドにより決まります。

> {note} クラスがチェックするアビリティと一致する名前のメソッドを含んでいない場合、ポリシークラスの`before`メソッドは呼び出されません。

<a name="authorizing-actions-using-policies"></a>
## ポリシーを使ったアクションの認可

<a name="via-the-user-model"></a>
### Userモデルによる確認

Laravelアプリケーションに含まれる`User`モデルは、アクションを認可するための便利な２つのメソッドを持っています。`can`と`cant`です。`can`メソッドは認可したいアクションと関連するモデルを引数に取ります。例として、ユーザーが指定した`Post`を更新を認可するかを決めてみましょう。

    if ($user->can('update', $post)) {
        //
    }

指定するモデルの[ポリシーが登録済みであれば](#registering-policies)適切なポリシーの`can`メソッドが自動的に呼びだされ、論理型の結果が返されます。そのモデルに対するポリシーが登録されていない場合、`can`メソッドは指定したアクション名に合致する、ゲートベースのクロージャを呼びだそうとします。

#### モデルを必要としないアクション

`create`のようなアクションは、モデルインスタンスを必要としないことを思い出してください。そうした場合は、`can`メソッドにはクラス名を渡してください。クラス名はアクションを認可するときにどのポリシーを使用すべきかを決めるために使われます。

    use App\Models\Post;

    if ($user->can('create', Post::class)) {
        // 関連するポリシーの"create"メソッドが実行される
    }

<a name="via-middleware"></a>
### ミドルウェアによる認可

送信されたリクエストがルートやコントローラへ到達する前に、アクションを認可できるミドルウェアをLaravelは持っています。デフォルトで`App\Http\Kernel`クラスの中で`can`キーに`Illuminate\Auth\Middleware\Authorize`ミドルウェアが割り付けられています。あるユーザーがブログポストを認可するために、`can`ミドルウェアを使う例をご覧ください。

    use App\Models\Post;

    Route::put('/post/{post}', function (Post $post) {
        // 現在のユーザーはこのポストを更新できる
    })->middleware('can:update,post');

この例では、`can`ミドルウェアへ２つの引数を渡しています。最初の引数は認可したいアクションの名前です。２つ目はポリシーメソッドに渡したいルートパラメータです。この場合、[暗黙のモデル結合](/docs/{{version}}/routing#implicit-binding)を使用しているため、`Post`モデルがポリシーメソッドへ渡されます。ユーザーに指定したアクションを実行する認可がない場合、ミドルウェアは`403`ステータスコードのHTTPレスポンスを生成します。

#### モデルを必要としないアクション

この場合も、`create`のようなアクションではモデルインスタンスを必要としません。このようなケースでは、ミドルウェアへクラス名を渡してください。クラス名はアクションを認可するときに、どのポリシーを使用するかの判断に使われます。

    Route::post('/post', function () {
        // 現在のユーザーはポストを更新できる
    })->middleware('can:create,App\Models\Post');

<a name="via-controller-helpers"></a>
### コントローラヘルパによる認可

`User`モデルが提供している便利なメソッドに付け加え、`App\Http\Controllers\Controller`ベースクラスを拡張しているコントローラに対し、Laravelは`authorize`メソッドを提供しています。`can`メソッドと同様に、このメソッドは認可対象のアクション名と関連するモデルを引数に取ります。アクションが認可されない場合、`authorize`メソッドは`Illuminate\Auth\Access\AuthorizationException`例外を投げ、これはデフォルトでLaravelの例外ハンドラにより、`403`ステータスコードのHTTPレスポンスへ変換されます。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Models\Post;
    use Illuminate\Http\Request;

    class PostController extends Controller
    {
        /**
         * 指定したポストの更新
         *
         * @param  Request  $request
         * @param  Post  $post
         * @return Response
         * @throws \Illuminate\Auth\Access\AuthorizationException
         */
        public function update(Request $request, Post $post)
        {
            $this->authorize('update', $post);

            // 現在のユーザーはブログポストの更新が可能
        }
    }

#### モデルを必要としないアクション

すでに説明してきたように、`create`のように、モデルインスタンスを必要としないアクションがあります。この場合、クラス名を`authorize`メソッドへ渡してください。クラス名はアクションの認可時に、どのポリシーを使用するのかを決めるために使われます

    /**
     * 新しいブログポストの生成
     *
     * @param  Request  $request
     * @return Response
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function create(Request $request)
    {
        $this->authorize('create', Post::class);

        // 現在のユーザーはブログポストを生成できる
    }

#### リソースコントローラの認可

[リソースコントローラ](/docs/{{version}}/controllers#resource-controllers)を活用している場合、コントローラのコンストラクタの中で、`authorizeResource`メソッドを使用できます。このメソッドはリソースコントローラのメソッドへ適切な`can`ミドルウェア定義を付加します。

`authorizeResource`メソッドは最初の引数にモデルのクラス名を受け取ります。モデルのIDを含むルート／リクエストパラメータ名を第２引数に受け取ります。必用なメソッド引数とタイプヒントを含んだ[リソースコントローラ](/docs/{{version}}/controllers#resource-controllers)を生成するには、必ず`--model`フラグを付けて生成してください。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Models\Post;
    use Illuminate\Http\Request;

    class PostController extends Controller
    {
        public function __construct()
        {
            $this->authorizeResource(Post::class, 'post');
        }
    }

次のコントローラメソッドが、対応するポリシーメソッドにマップされます。

| コントローラメソッド | ポリシーメソッド |
| --- | --- |
| index | viewAny |
| show | view |
| create | create |
| store | create |
| edit | update |
| update | update |
| destroy | delete |

> {tip} 指定するモデルのポリシークラスを手っ取り早く生成するには、`--model`オプションを付け`make:policy`コマンドを実行します。`php artisan make:policy --model=Post`

<a name="via-blade-templates"></a>
### Bladeテンプレートによる認可

Bladeテンプレートを書くとき、指定したアクションを実行できる認可があるユーザーの場合のみ、ページの一部分を表示したい場合があります。たとえば、実際にポストを更新できるユーザーの場合のみ、ブログポストの更新フォームを表示したい場合です。この場合、`@can`と`@cannot`系ディレクティブを使います。

    @can('update', $post)
        <!-- 現在のユーザーはポストを更新できる -->
    @elsecan('create', App\Models\Post::class)
        <!-- 現在のユーザーはポストを作成できる -->
    @endcan

    @cannot('update', $post)
        <!-- 現在のユーザーはポストを更新できない -->
    @elsecannot('create', App\Models\Post::class)
        <!-- 現在のユーザーはポストを更新できない -->
    @endcannot

これらのディレクティブは`@if`や`@unless`文を使う記述に対する、便利な短縮形です。上記の`@can`と`@cannot`文に対応するコードは以下のようになります。

    @if (Auth::user()->can('update', $post))
        <!-- 現在のユーザーはポストを更新できる -->
    @endif

    @unless (Auth::user()->can('update', $post))
        <!-- 現在のユーザーはポストを更新できない -->
    @endunless

指定するリスト中の認可アビリティをユーザーが持っているかを判定することもできます。`@canany`ディレクティブを使用します。

    @canany(['update', 'view', 'delete'], $post)
        // 現在のユーザーはポストとの更新、閲覧、削除ができる
    @elsecanany(['create'], \App\Models\Post::class)
        // 現在のユーザーはポストを作成できる
    @endcanany

#### モデルを必要としないアクション

他の認可メソッド同様に、アクションでモデルインスタンスが必要でない場合、`@can`と`@cannot`ディレクティブへクラス名を渡すことができます。

    @can('create', App\Models\Post::class)
        <!-- 現在のユーザーはポストを更新できる -->
    @endcan

    @cannot('create', App\Models\Post::class)
        <!-- 現在のユーザーはポストを更新できない -->
    @endcannot

<a name="supplying-additional-context"></a>
### 追加コンテキストの指定

認可アクションにポリシーを使う場合、数多くの認可関数やヘルパで第２引数に配列を渡せます。配列の第１要素はどのポリシーを呼び出すべきか決定するために使われます。残りの配列要素は、ポリシーメソッドへのパラメータとして渡されたもので、認可の可否を決定する際に追加のコンテキストとして利用できます。例として、次のような追加の`$category`パラメータを持つ、`PostPolicy`メソッド定義を考えてみましょう。

    /**
     * このユーザーにより、指定ポストが更新できるか判定
     *
     * @param  \App\Models\User  $user
     * @param  \App\Models\  $post
     * @param  int  $category
     * @return bool
     */
    public function update(User $user, Post $post, int $category)
    {
        return $user->id === $post->user_id &&
               $category > 3;
    }

認証済みのユーザーが指定ポストを更新できるかの判断を試みる時、次のようにこのポリシーメソッドを呼び出せます。

    /**
     * 指定ポストの更新
     *
     * @param  Request  $request
     * @param  Post  $post
     * @return Response
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function update(Request $request, Post $post)
    {
        $this->authorize('update', [$post, $request->input('category')]);

        // 現在のユーザーは、このブログポストを更新できる…
    }
