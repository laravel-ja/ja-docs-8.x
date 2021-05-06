# 認可

- [イントロダクション](#introduction)
- [ゲート](#gates)
    - [ゲートの作成](#writing-gates)
    - [アクションの認可](#authorizing-actions-via-gates)
    - [ゲートのレスポンス](#gate-responses)
    - [ゲートチェックの割り込み](#intercepting-gate-checks)
- [ポリシーの作成](#creating-policies)
    - [ポリシーの生成](#generating-policies)
    - [ポリシーの登録](#registering-policies)
- [ポリシーの作成](#writing-policies)
    - [ポリシーメソッド](#policy-methods)
    - [ポリシーのレスポンス](#policy-responses)
    - [モデルのないメソッド](#methods-without-models)
    - [ゲストユーザー](#guest-users)
    - [ポリシーフィルタ](#policy-filters)
- [ポリシーを使用したアクションの認可](#authorizing-actions-using-policies)
    - [ユーザーモデル経由](#via-the-user-model)
    - [コントローラヘルパ経由](#via-controller-helpers)
    - [ミドルウェア経由](#via-middleware)
    - [Bladeテンプレート経由](#via-blade-templates)
    - [追加コンテキストの提供](#supplying-additional-context)

<a name="introduction"></a>
## イントロダクション

組み込み[認証](/docs/{{version}}/authentication)サービスの提供に加え、Laravelは特定のリソースに対するユーザーアクションを認可する手軽な方法も提供しています。たとえば、あるユーザーが認証されていても、アプリケーションが管理している特定のEloquentモデルまたはデータベースレコードを更新や削除する権限を持っていない場合があるでしょう。Laravelの認可機能は、こうしたタイプの認可チェックを管理するための簡単で組織化された方法を提供します。

Laravelは、アクションを認可する2つの主要な方法を提供します。[ゲート](#gates)と[ポリシー](#creating-policies)です。ゲートとポリシーは、ルートやコントローラのようなものだと考えてください。ゲートは認可のためのクロージャベースのシンプルなアプローチを提供します。一方でポリシーはコントローラのように、特定のモデルやリソース周辺のロジックをひとかたまりにまとめます。このドキュメントでは、最初にゲートを説明し、その後でポリシーを見ていきましょう。

アプリケーションを構築するときに、ゲートのみを使用するか、ポリシーのみを使用するかを選択する必要はありません。ほとんどのアプリケーションには、ゲートとポリシーが混在する可能性が高く、それはまったく問題ありません。ゲートは、管理者ダッシュボードの表示など、モデルやリソースに関連しないアクションに最も適しています。対照的に、特定のモデルまたはリソースのアクションを認可する場合は、ポリシーを使用する必要があります。

<a name="gates"></a>
## ゲート

<a name="writing-gates"></a>
### ゲートの作成

> {note} ゲートは、Laravelの認可機能の基本を学ぶための優れた方法です。ただし、堅牢なLaravelアプリケーションを構築するときは、[ポリシー](#creating-policies)を使用して認可ルールを整理することを検討する必要があります。

ゲートは、ユーザーが特定のアクションを実行することを許可されているかどうかを判断する単なるクロージャです。通常、ゲートは、`Gate`ファサードを使用して`App\Providers\AuthServiceProvider`クラスの`boot`メソッド内で定義されます。ゲートは常に最初の引数としてユーザーインスタンスを受け取り、オプションで関連するEloquentモデルなどの追加の引数を受け取る場合があります。

以下の例では、ユーザーが特定の`App\Models\Post`モデルを更新できるかどうかを判断するためのゲートを定義します。ユーザーの`id`と、投稿を作成したユーザーの`user_id`を比較しすることで、このゲートは可否を判定します。

    use App\Models\Post;
    use App\Models\User;
    use Illuminate\Support\Facades\Gate;

    /**
     * 全認証／承認サービスを登録
     *
     * @return void
     */
    public function boot()
    {
        $this->registerPolicies();

        Gate::define('update-post', function (User $user, Post $post) {
            return $user->id === $post->user_id;
        });
    }

コントローラと同様に、ゲートもクラスコールバック配列を使用して定義できます。

    use App\Policies\PostPolicy;
    use Illuminate\Support\Facades\Gate;

    /**
     * 全認証／承認サービスを登録
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

ゲートを使用してアクションを認可するには、`Gate`ファサードが提供する`allows`か`denies`メソッドを使用する必要があります。現在認証済みのユーザーをこれらのメソッドに渡す必要はないことに注意してください。Laravelは自動的にユーザーをゲートクロージャに引き渡します。認可が必要なアクションを実行する前に、アプリケーションのコントローラ内でゲート認可メソッドを呼び出すのが一般的です。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Models\Post;
    use Illuminate\Http\Request;
    use Illuminate\Support\Facades\Gate;

    class PostController extends Controller
    {
        /**
         * 指定した投稿を更新
         *
         * @param  \Illuminate\Http\Request  $request
         * @param  \App\Models\Post  $post
         * @return \Illuminate\Http\Response
         */
        public function update(Request $request, Post $post)
        {
            if (! Gate::allows('update-post', $post)) {
                abort(403);
            }

            // 投稿を更新…
        }
    }

現在認証済みユーザー以外のユーザーがアクションの実行を許可されているかを確認する場合は、`Gate`ファサードで`forUser`メソッドを使用します。

    if (Gate::forUser($user)->allows('update-post', $post)) {
        // ユーザーは投稿を更新可能
    }

    if (Gate::forUser($user)->denies('update-post', $post)) {
        // ユーザーは投稿を更新不可能
    }

`any`または`none`メソッドを使用して、一度に複数のアクション認可を確認できます。

    if (Gate::any(['update-post', 'delete-post'], $post)) {
        // ユーザーは投稿を更新または削除可能
    }

    if (Gate::none(['update-post', 'delete-post'], $post)) {
        // ユーザーは投稿を更新または削除不可能
    }

<a name="authorizing-or-throwing-exceptions"></a>
#### 認可または例外を投げる

アクションを認可をチェックし、ユーザーが指定のアクションの実行を許可されていない場合は、`Illuminate\Auth\Access\AuthorizationException`を自動で投げたい場合は、`Gate`ファサードの`authorize`メソッドを使用します。`AuthorizationException`のインスタンスは、Laravelの例外ハンドラによって自動的に403HTTPレスポンスへ変換されます。

    Gate::authorize('update-post', $post);

    // アクションは認可されている

<a name="gates-supplying-additional-context"></a>
#### 追加コンテキストの提供

アビリティを認可するためのゲートメソッド（`allows`、`denis`、`check`、`any`、`none`、`authorize`、`can`、`cannot`）と認可[Bladeディレクティブ](#via-blade-templates)（`@can`、`@cannot`、`@canany`）は、２番目の引数として配列を取れます。これらの配列要素は、パラメータとしてゲートクロージャに渡され、認可を決定する際の追加のコンテキストに使用できます。

    use App\Models\Category;
    use App\Models\User;
    use Illuminate\Support\Facades\Gate;

    Gate::define('create-post', function (User $user, Category $category, $pinned) {
        if (! $user->canPublishToGroup($category->group)) {
            return false;
        } elseif ($pinned && ! $user->canPinPosts()) {
            return false;
        }

        return true;
    });

    if (Gate::check('create-post', [$category, $pinned])) {
        // ユーザーは投稿を作成可能
    }

<a name="gate-responses"></a>
### ゲートのレスポンス

これまで、単純な論理値を返すゲートのみ見てきました。しかし、エラーメッセージなどのより詳細なレスポンスを返したい場合もあります。これには、ゲートから`Illuminate\Auth\Access\Response`を返してください。

    use App\Models\User;
    use Illuminate\Auth\Access\Response;
    use Illuminate\Support\Facades\Gate;

    Gate::define('edit-settings', function (User $user) {
        return $user->isAdmin
                    ? Response::allow()
                    : Response::deny('You must be an administrator.');
    });

ゲートから認可レスポンスを返した場合でも、`Gate::allows`メソッドは単純なブール値を返します。ただし、`Gate::inspect`メソッドを使用して、ゲートから返される完全な認可レスポンスを取得できます。

    $response = Gate::inspect('edit-settings');

    if ($response->allowed()) {
        // アクションは認可されている
    } else {
        echo $response->message();
    }

アクションが認可されていない場合に`AuthorizationException`を投げる`Gate::authorize`メソッドを使用すると、認可レスポンスが提供するエラーメッセージがHTTPレスポンスへ伝播されます。

    Gate::authorize('edit-settings');

    // アクションは認可されている

<a name="intercepting-gate-checks"></a>
### ゲートチェックの割り込み

特定のユーザーにすべての機能を付与したい場合があります。`before`メソッドを使用して、他のすべての認可チェックの前に実行するクロージャを定義できます。

    use Illuminate\Support\Facades\Gate;

    Gate::before(function ($user, $ability) {
        if ($user->isAdministrator()) {
            return true;
        }
    });

`before`クロージャがnull以外の結果を返した場合、その結果を許可チェックの結果とみなします。

`after`メソッドを使用して、他のすべての認可チェックの後に実行されるクロージャを定義できます。

    Gate::after(function ($user, $ability, $result, $arguments) {
        if ($user->isAdministrator()) {
            return true;
        }
    });

`before`メソッドと同様に、`after`クロージャがnull以外の結果を返した場合、その結果は認可チェックの結果とみなします。

<a name="creating-policies"></a>
## ポリシーの作成

<a name="generating-policies"></a>
### ポリシーの生成

ポリシーは、特定のモデルまたはリソースに関する認可ロジックを集めたクラスです。たとえば、アプリケーションがブログの場合、`App\Models\Post`モデルと投稿の作成や更新などのユーザーアクションを認可するためのPostモデルと対応する`App\Policies\PostPolicy`があるでしょう。

`make:policy`　Artisanコマンドを使用してポリシーを生成できます。生成するポリシーは`app/Policies`ディレクトリへ配置します。このディレクトリがアプリケーションに存在しない場合、Laravelが作成します。

    php artisan make:policy PostPolicy

`make:policy`コマンドは、空のポリシークラスを生成します。リソースの表示、作成、更新、削除に関連するポリシーメソッドのサンプルを含んだクラスを生成する場合は、コマンドの実行時に`--model`オプションを指定します。

    php artisan make:policy PostPolicy --model=Post

<a name="registering-policies"></a>
### ポリシーの登録

ポリシークラスを作成したら、登録する必要があります。ポリシーの登録とは、特定のモデルタイプに対するアクションを認可するときに、使用するポリシーをLaravelに指示する方法です。

新しいLaravelアプリケーションに含まれている`App\Providers\AuthServiceProvider`には、Eloquentモデルを対応するポリシーにマップする`policies`プロパティが含まれています。ポリシーを登録すると、特定のEloquentモデルに対するアクションを認可するときに使用するポリシーがLaravelに指示されます。

    <?php

    namespace App\Providers;

    use App\Models\Post;
    use App\Policies\PostPolicy;
    use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;
    use Illuminate\Support\Facades\Gate;

    class AuthServiceProvider extends ServiceProvider
    {
        /**
         * アプリケーションのポリシーマッピング
         *
         * @var array
         */
        protected $policies = [
            Post::class => PostPolicy::class,
        ];

        /**
         * 全アプリケーション認証／認可サービス登録
         *
         * @return void
         */
        public function boot()
        {
            $this->registerPolicies();

            //
        }
    }

<a name="policy-auto-discovery"></a>
#### ポリシーの自動検出

モデルポリシーを手動で登録する代わりに、モデルとポリシーが標準のLaravel命名規約に従っている限り、Laravelはポリシーを自動的に検出できます。具体的にポリシーは、モデルを含むディレクトリが存在する階層より上の`Policies`ディレクトリにある必要があります。したがって、たとえばモデルは`app/Models`ディレクトリに配置し、ポリシーは`app/Policies`ディレクトリに配置する場合があるでしょう。この場合、Laravelは`app/Models/Policies`、次に`app/Policies`のポリシーをチェックします。さらに、ポリシー名はモデル名と一致し、`Policy`サフィックスが付いている必要があります。したがって、`User`モデルは`UserPolicy`ポリシークラスに対応します。

独自のポリシー検出ロジックを定義する場合は、`Gate::guessPolicyNamesUsing`メソッドを使用してカスタムポリシー検出コールバックを登録できます。通常、このメソッドは、アプリケーションの`AuthServiceProvider`の`boot`メソッドから呼び出す必要があります。

    use Illuminate\Support\Facades\Gate;

    Gate::guessPolicyNamesUsing(function ($modelClass) {
        // 指定されたモデルに対するポリシークラスの名前を返す…
    });

> {note} `AuthServiceProvider`で明示的にマッピングされるポリシーは、自動検出される可能性のあるポリシーよりも優先されます。

<a name="writing-policies"></a>
## ポリシーの作成

<a name="policy-methods"></a>
### ポリシーメソッド

ポリシークラスを登録したら、認可するアクションごとにメソッドを追加できます。例として、ある`App\Models\User`がある`App\Models\Post`インスタンスを更新できるかどうかを決定する`PostPolicy`で`update`メソッドを定義してみましょう。

`update`メソッドは引数として`User`と`Post`インスタンスを受け取り、そのユーザーが指定した`Post`を更新する権限があるかどうかを示す`true`または`false`を返す必要があります。したがって、この例では、ユーザーの`id`が投稿の`user_id`と一致することを確認しています。

    <?php

    namespace App\Policies;

    use App\Models\Post;
    use App\Models\User;

    class PostPolicy
    {
        /**
         * 指定した投稿をユーザーが更新可能かを判定
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

ポリシーが認可するさまざまなアクションの必要に合わせ、ポリシーに追加のメソッドをどんどん定義できます。たとえば、`view`または`delete`メソッドを定義して、さまざまな`Post`関連のアクションを認可できますが、ポリシーメソッドには任意の名前を付けることができることを覚えておいてください。

Artisanコンソールを介してポリシーを生成するときに`--model`オプションを使用した場合、はじめから`viewAny`、`view`、`create`、`update`、`delete`、`restore`、`forceDelete`アクションのメソッドが用意されます。

> {tip} すべてのポリシーはLaravel[サービスコンテナ](/docs/{{version}}/container)を介して解決されるため、ポリシーのコンストラクターで必要な依存関係をタイプヒントして、自動的に依存注入することができます。

<a name="policy-responses"></a>
### ポリシーのレスポンス

これまで、単純な論理値値を返すポリシーメソッドについてのみ説明してきました。しかし、エラーメッセージなどより詳細なレスポンスを返したい場合があります。これにはポリシーメソッドから`Illuminate\Auth\Access\Response`インスタンスを返してください。

    use App\Models\Post;
    use App\Models\User;
    use Illuminate\Auth\Access\Response;

    /**
     * 指定された投稿をユーザーが更新可能か判定
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

ポリシーから認可レスポンスを返す場合でも、`Gate::allows`メソッドは単純な論理値を返します。ただし、`Gate::inspect`メソッドを使用して、ゲートが返す完全な認可レスポンスを取得できます。

    use Illuminate\Support\Facades\Gate;

    $response = Gate::inspect('update', $post);

    if ($response->allowed()) {
        // アクションは認可されている
    } else {
        echo $response->message();
    }

アクションが認可されていない場合に`AuthorizationException`を投げる`Gate::authorize`メソッドを使用すると、認可レスポンスが提供するエラーメッセージをHTTPレスポンスへ伝播します。

    Gate::authorize('update', $post);

    // アクションは認可されている

<a name="methods-without-models"></a>
### モデルのないメソッド

一部のポリシーメソッドは、現在認証済みユーザーのインスタンスのみを受け取ります。この状況は、`create`アクションを認可するばあいに頻繁に見かけます。たとえば、ブログを作成している場合、ユーザーが投稿の作成を認可されているかを確認したい場合があります。このような状況では、ポリシーメソッドはユーザーインスタンスのみを受け取る必要があります。

    /**
     * 指定ユーザーが投稿を作成可能か確認
     *
     * @param  \App\Models\User  $user
     * @return bool
     */
    public function create(User $user)
    {
        return $user->role == 'writer';
    }

<a name="guest-users"></a>
### ゲストユーザー

デフォルトでは、受信HTTPリクエストが認証済みユーザーによって開始されたものでない場合、すべてのゲートとポリシーは自動的に`false`を返します。ただし、「オプションの」タイプヒントを宣言するか、ユーザーの引数定義で`null`のデフォルト値を指定することで、これらの認可チェックをゲートとポリシーに渡すことができます。

    <?php

    namespace App\Policies;

    use App\Models\Post;
    use App\Models\User;

    class PostPolicy
    {
        /**
         * 指定投稿をユーザーが更新可能か判定
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
### ポリシーフィルタ

ある特定のユーザーには、特定のポリシー内のすべてのアクションを認可したい場合があります。これには、ポリシーで「before」メソッドを定義します。`before`メソッドは、ポリシー上の他のメソッドの前に実行されるため、目的のポリシーメソッドが実際に呼び出される前にアクションを認可する機会に利用できます。この機能は、アプリケーション管理者にアクションの実行を許可するために最も一般的に使用されます。

    use App\Models\User;

    /**
     * 事前認可チェックの実行
     *
     * @param  \App\Models\User  $user
     * @param  string  $ability
     * @return void|bool
     */
    public function before(User $user, $ability)
    {
        if ($user->isAdministrator()) {
            return true;
        }
    }

特定のタイプのユーザー全員の認可チェックを拒否したい場合は、`before`メソッドから`false`を返してください。`null`を返す場合は、認可チェックはポリシーメソッドへ委ねられます。

> {note} ポリシークラスの`before`メソッドは、チェックしている機能の名前と一致する名前のメソッドがクラスに含まれていない場合は呼び出されません。

<a name="authorizing-actions-using-policies"></a>
## ポリシーを使用したアクションの認可

<a name="via-the-user-model"></a>
### ユーザーモデル経由

Laravelアプリケーションに含まれている`App\Models\User`モデルには、アクションを認可するための２つの便利なメソッド`can`と`cannot`が含まれています。`can`メソッドと`cannot`メソッドは、認可するアクションの名前と関連するモデルを受け取ります。たとえば、ユーザーが特定の`App\Models\Post`モデルを更新する権限を持っているかどうかを確認しましょう。通常、これはコントローラメソッド内で実行されます。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Models\Post;
    use Illuminate\Http\Request;

    class PostController extends Controller
    {
        /**
         * 指定した投稿を更新
         *
         * @param  \Illuminate\Http\Request  $request
         * @param  \App\Models\Post  $post
         * @return \Illuminate\Http\Response
         */
        public function update(Request $request, Post $post)
        {
            if ($request->user()->cannot('update', $post)) {
                abort(403);
            }

            // 投稿を更新…
        }
    }

指定したモデルの[ポリシーが登録されている](#registering-policies)の場合、`can`メソッドは自動的に適切なポリシーを呼び出し、論理値の結果を返します。モデルにポリシーが登録されていない場合、`can`メソッドは、指定されたアクション名に一致するクロージャベースのゲートを呼び出そうとします。

<a name="user-model-actions-that-dont-require-models"></a>
#### モデルを必要としないアクション

一部のアクションは、モデルインスタンスを必要としない`create`などのポリシーメソッドに対応する場合があることに注意してください。このような状況では、クラス名を`can`メソッドに渡すことができます。クラス名は、アクションを認可するときに使用するポリシーを決定するために使用されます。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Models\Post;
    use Illuminate\Http\Request;

    class PostController extends Controller
    {
        /**
         * 投稿を作成
         *
         * @param  \Illuminate\Http\Request  $request
         * @return \Illuminate\Http\Response
         */
        public function store(Request $request)
        {
            if ($request->user()->cannot('create', Post::class)) {
                abort(403);
            }

            // 投稿を作成…
        }
    }

<a name="via-controller-helpers"></a>
### コントローラヘルパ経由

Laravelは、`App\Models\User`モデルが提供する便利なメソッドに加えて、`App\Http\Controllers\Controller`基本クラスを拡張する任意のコントローラに役立つ`authorize`メソッドを提供します。

`can`メソッドと同様に、このメソッドは、認可するアクションの名前とリレーションモデルを受け入れます。アクションが認可されていない場合、`authorize`メソッドは`Illuminate\Auth\Access\AuthorizationException`例外を投げ、Laravel例外ハンドラは自動的に403ステータスコードのHTTPレスポンスに変換します。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Models\Post;
    use Illuminate\Http\Request;

    class PostController extends Controller
    {
        /**
         * 指定したブログ投稿の更新
         *
         * @param  \Illuminate\Http\Request  $request
         * @param  \App\Models\Post  $post
         * @return \Illuminate\Http\Response
         *
         * @throws \Illuminate\Auth\Access\AuthorizationException
         */
        public function update(Request $request, Post $post)
        {
            $this->authorize('update', $post);

            // 現在のユーザーはこのブログ投稿を更新可能
        }
    }

<a name="controller-actions-that-dont-require-models"></a>
#### モデルを必要としないアクション

すでに説明したように、`create`などの一部のポリシーメソッドはモデルインスタンスを必要としません。このような状況では、クラス名を`authorize`メソッドに渡す必要があります。クラス名は、アクションを認可するときに使用するポリシーを決定するために使用されます。

    use App\Models\Post;
    use Illuminate\Http\Request;

    /**
     * 新しいブログ投稿の作成
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     *
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function create(Request $request)
    {
        $this->authorize('create', Post::class);

        // 現在のユーザーはブログ投稿を作成可能
    }

<a name="authorizing-resource-controllers"></a>
#### リソースコントローラの認可

[リソースコントローラ](/docs/{{version}}/controllers#resource-controllers)を使用している場合は、コントローラのコンストラクターで`authorizeResource`メソッドを使用できます。このメソッドは、適切な`can`ミドルウェア定義をリソースコントローラのメソッドにアタッチします。

`authorizeResource`メソッドは、最初の引数としてモデルのクラス名を受け入れ、２番目の引数としてモデルのIDを含むルート/リクエストパラメーターの名前を受け入れます。[リソースコントローラ](/docs/{{version}}/controllers#resource-controllers)が`--model`フラグを使用して作成されていることを確認して、必要なメソッド引数とタイプヒントが含まれるようにしてください。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Models\Post;
    use Illuminate\Http\Request;

    class PostController extends Controller
    {
        /**
         * コントローラインスタンスの生成
         *
         * @return void
         */
        public function __construct()
        {
            $this->authorizeResource(Post::class, 'post');
        }
    }

以下ののコントローラメソッドは、対応するポリシーメソッドにマップされています。リクエストが特定のコントローラメソッドにルーティングされると、コントローラメソッドが実行される前に、対応するポリシーメソッドが自動的に呼び出されます。

| コントローラメソッド | ポリシーメソッド |
| --- | --- |
| index | viewAny |
| show | view |
| create | create |
| store | create |
| edit | update |
| update | update |
| destroy | delete |

> {tip} `make:policy`コマンドを`--model`オプションとともに使用し、特定のモデルのポリシークラスを手早く生成できます。`php artisan make:policy PostPolicy --model=Post`

<a name="via-middleware"></a>
### ミドルウェア経由

Laravelには、受信リクエストがルートやコントローラに到達する前にアクションを認可できるミドルウェアが含まれています。デフォルトでは、`Illuminate\Auth\Middleware\Authorize`ミドルウェアには`App\Http\Kernel`クラスの`can`キーが割り当てられています。`can`ミドルウェアを使用して、ユーザーが投稿を更新できることを認可する例を見てみましょう。

    use App\Models\Post;

    Route::put('/post/{post}', function (Post $post) {
        // 現在のユーザーは投稿を更新可能
    })->middleware('can:update,post');

この例では、`can`ミドルウェアに２つの引数を渡します。１つ目は認可するアクションの名前であり、２つ目はポリシーメソッドに渡すルートパラメーターです。この場合、[暗黙のモデルバインディング](/docs/{{version}}/Routing#implicit-binding)を使用しているため、`App\Models\Post`モデルがポリシーメソッドに渡されます。ユーザーが特定のアクションを実行する権限を持っていない場合、ミドルウェアは403ステータスコードのHTTPレスポンスを返します。

<a name="middleware-actions-that-dont-require-models"></a>
#### モデルを必要としないアクション

繰り返しますが、`create`のようないくつかのポリシーメソッドはモデルインスタンスを必要としません。このような状況では、クラス名をミドルウェアに渡すことができます。クラス名は、アクションを認可するときに使用するポリシーを決定するために使用されます。

    Route::post('/post', function () {
        // 現在のユーザーは投稿を作成可能
    })->middleware('can:create,App\Models\Post');

<a name="via-blade-templates"></a>
### Bladeテンプレート経由

Bladeテンプレートを作成するとき、ユーザーが特定のアクションを実行する許可がある場合にのみ、ページの一部を表示したい場合があります。たとえば、ユーザーが実際に投稿を更新できる場合にのみ、ブログ投稿の更新フォームを表示したい場合があります。この状況では、`@can`および`@cannot`ディレクティブを使用できます。

```html
@can('update', $post)
    <!-- 現在のユーザーは投稿を更新可能 -->
@elsecan('create', App\Models\Post::class)
    <!-- 現在のユーザーは新しい投稿を作成可能 -->
@else
    <!-- ... -->
@endcan

@cannot('update', $post)
    <!-- 現在のユーザーは投稿を更新不可能 -->
@elsecannot('create', App\Models\Post::class)
    <!-- 現在のユーザーは新しい投稿を作成可能 -->
@endcannot
```

これらのディレクティブは、`@if`と`@unless`ステートメントを短く記述するための便利な短縮形です。上記の`@can`および`@cannot`ステートメントは、以下のステートメントと同等です。

```html
@if (Auth::user()->can('update', $post))
    <!-- 現在のユーザーは投稿を更新可能 -->
@endif

@unless (Auth::user()->can('update', $post))
    <!-- 現在のユーザーは投稿を更新不可能 -->
@endunless
```

また、ユーザーが複数のアクションの実行を認可されているかを判定することもできます。これには、`@canany`ディレクティブを使用します。

```html
@canany(['update', 'view', 'delete'], $post)
    <!-- 現在のユーザーは、投稿を更新、表示、削除可能 -->
@elsecanany(['create'], \App\Models\Post::class)
    <!-- 現在のユーザーは投稿を作成可能 -->
@endcanany
```

<a name="blade-actions-that-dont-require-models"></a>
#### モデルを必要としないアクション

他のほとんどの認可メソッドと同様に、アクションがモデルインスタンスを必要としない場合は、クラス名を`@can`および`@cannot`ディレクティブに渡すことができます。

```html
@can('create', App\Models\Post::class)
    <!-- 現在のユーザーは投稿を作成可能 -->
@endcan

@cannot('create', App\Models\Post::class)
    <!-- 現在のユーザーは投稿を作成不可能 -->
@endcannot
```

<a name="supplying-additional-context"></a>
### 追加コンテキストの提供

ポリシーを使用してアクションを認可する場合、２番目の引数としてさまざまな認可関数とヘルパに配列を渡すことができます。配列の最初の要素は、呼び出すポリシーを決定するために使用され、残りの配列要素は、パラメーターとしてポリシーメソッドに渡され、認可の決定を行う際の追加のコンテキストに使用できます。たとえば、追加の`$category`パラメータを含む次の`PostPolicy`メソッド定義について考えてみます。

    /**
     * 指定投稿をユーザーが更新できるか判断
     *
     * @param  \App\Models\User  $user
     * @param  \App\Models\Post  $post
     * @param  int  $category
     * @return bool
     */
    public function update(User $user, Post $post, int $category)
    {
        return $user->id === $post->user_id &&
               $user->canUpdateCategory($category);
    }

認証済みユーザーが特定の投稿を更新できるか判断する場合、次のようにこのポリシーメソッドを呼び出すことができます。

    /**
     * 指定ブログ投稿を更新
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Post  $post
     * @return \Illuminate\Http\Response
     *
     * @throws \Illuminate\Auth\Access\AuthorizationException
     */
    public function update(Request $request, Post $post)
    {
        $this->authorize('update', [$post, $request->category]);

        // 現在のユーザーはブログ投稿を更新可能
    }
