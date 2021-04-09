# Eloquent：ＡＰＩリソース

- [イントロダクション](#introduction)
- [リソースの生成](#generating-resources)
- [概論](#concept-overview)
    - [リソースコレクション](#resource-collections)
- [リソースの記述](#writing-resources)
    - [データのラップ](#data-wrapping)
    - [ペジネーション](#pagination)
    - [条件付き属性](#conditional-attributes)
    - [条件付きリレーション](#conditional-relationships)
    - [メタデータの追加](#adding-meta-data)
- [リソースレスポンス](#resource-responses)

<a name="introduction"></a>
## イントロダクション

APIを構築する場合、Eloquentモデルと実際にアプリケーションのユーザーへ返すJSONレスポンスの間に変換レイヤーが必要になるでしょう。たとえば、ユーザーのサブセットに対して特定の属性を表示し、他のユーザーには表示したくない場合や、モデルのJSON表現に常に特定のリレーションを含めたい場合などです。Eloquentのリソースクラスを使用すると、モデルとモデルコレクションを表現力豊かかつ簡単にJSONに変換できます。

もちろん、`toJson`メソッドを使用してEloquentモデルまたはコレクションをJSONへいつでも変換できます。ただし、Eloquentリソースは、モデルのJSONシリアル化とそれらの関係をよりきめ細かく堅牢に制御します。

<a name="generating-resources"></a>
## リソースの生成

リソースクラスを生成するには、`make:resource` Artisanコマンドを使用します。リソースはアプリケーションの`app/Http/Resources`ディレクトリにデフォルトで配置されます。リソースは`Illuminate\Http\Resources\Json\JsonResource`クラスを拡張します。

    php artisan make:resource UserResource

<a name="generating-resource-collections"></a>
#### リソースコレクション

個々のモデルを変換するリソースを生成することに加えて、モデルのコレクションの変換を担当するリソースを生成することもできます。これにより、JSONレスポンスへ指定するリソースのコレクション全体へ関連するリンクやその他のメタ情報を含められます。

リソースコレクションを生成するには、リソースを生成するときに`--collection`フラグを使用する必要があります。または、リソース名に`Collection`という単語を含めると、コレクションリソースを作成する必要があるとLaravelに指示できます。コレクションリソースは、`Illuminate\Http\Resources\JSON\ResourceCollection`クラスを拡張します。

    php artisan make:resource User --collection

    php artisan make:resource UserCollection

<a name="concept-overview"></a>
## 概論

> {tip} これは、リソースとリソースコレクションの概要です。リソースによって提供されるカスタマイズとパワーをより深く理解するために、このドキュメントの他のセクションも読むことを強く推奨します。

リソースを作成するときに利用できるすべてのオプションに飛び込む前に、まずLaravel内でリソースがどのように使用されているかを大まかに見てみましょう。リソースクラスは、JSON構造に変換する必要がある単一のモデルを表します。たとえば、以下は単純な`UserResource`リソースクラスです。

    <?php

    namespace App\Http\Resources;

    use Illuminate\Http\Resources\Json\JsonResource;

    class UserResource extends JsonResource
    {
        /**
         * リソースを配列に変換
         *
         * @param  \Illuminate\Http\Request  $request
         * @return array
         */
        public function toArray($request)
        {
            return [
                'id' => $this->id,
                'name' => $this->name,
                'email' => $this->email,
                'created_at' => $this->created_at,
                'updated_at' => $this->updated_at,
            ];
        }
    }

リソースをルートまたはコントローラメソッドからのレスポンスとして返すときにJSONへ変換する必要があるため、属性の配列を返す`toArray`メソッドをすべてのリソースクラスで定義します。

`$this`変数からモデルのプロパティに直接アクセスできることに注意してください。これは、リソースクラスがプロパティとメソッドのアクセスを基になるモデルに自動的にプロキシしており、アクセスを便利にしているためです。リソースを定義したら、ルートまたはコントローラから返せます。リソースは、コンストラクターを介して基になるモデルインスタンスを受け入れます。

    use App\Http\Resources\UserResource;
    use App\Models\User;

    Route::get('/user/{id}', function ($id) {
        return new UserResource(User::findOrFail($id));
    });

<a name="resource-collections"></a>
### リソースコレクション

リソースのコレクションまたはページ分割されたレスポンスを返す場合は、ルートまたはコントローラでリソースインスタンスを作成するときに、リソースクラスによって提供される`collection`メソッドを使用する必要があります。

    use App\Http\Resources\UserResource;
    use App\Models\User;

    Route::get('/users', function () {
        return UserResource::collection(User::all());
    });

これでは、コレクションとともに返す必要のあるカスタムメタデータがある場合でもそれらを追加できないことに注意してください。リソースコレクションのレスポンスをカスタマイズする場合は、コレクションを表す専用のリソースを生成してください。

    php artisan make:resource UserCollection

リソースコレクションクラスを生成したら、レスポンスに含める必要のあるメタデータを簡単に定義できます。

    <?php

    namespace App\Http\Resources;

    use Illuminate\Http\Resources\Json\ResourceCollection;

    class UserCollection extends ResourceCollection
    {
        /**
         * リソースコレクションを配列に変換
         *
         * @param  \Illuminate\Http\Request  $request
         * @return array
         */
        public function toArray($request)
        {
            return [
                'data' => $this->collection,
                'links' => [
                    'self' => 'link-value',
                ],
            ];
        }
    }

リソースコレクションを定義したら、ルートまたはコントローラから返せます。

    use App\Http\Resources\UserCollection;
    use App\Models\User;

    Route::get('/users', function () {
        return new UserCollection(User::all());
    });

<a name="preserving-collection-keys"></a>
#### コレクションキーの保存

あるルートからリソースコレクションを返す場合、Laravelはコレクションのキーをリセットして番号順に並べます。しかし、コレクションの元のキーを保持する必要があるかどうかを示す`preserveKeys`プロパティをリソースクラスに追加できます。

    <?php

    namespace App\Http\Resources;

    use Illuminate\Http\Resources\Json\JsonResource;

    class UserResource extends JsonResource
    {
        /**
         * リソースのコレクションキーを保持する必要がある事を示す
         *
         * @var bool
         */
        public $preserveKeys = true;
    }

`preserveKeys`プロパティが`true`に設定されている場合、コレクションをルートまたはコントローラから返すとき、コレクションのキーが保持されます。

    use App\Http\Resources\UserResource;
    use App\Models\User;

    Route::get('/users', function () {
        return UserResource::collection(User::all()->keyBy->id);
    });

<a name="customizing-the-underlying-resource-class"></a>
#### 基礎となるリソースクラスのカスタマイズ

通常、リソースコレクションの`$this->collection`プロパティへは、コレクションの各アイテムをその単一のリソースクラスにマッピングした結果を自動的に代入します。単一のリソースクラスは、クラス名の末尾から`Collection`部分除いたコレクションのクラス名であると想定します。さらに、個人的な好みにもよりますが、単数形のリソースクラスには、`Resource`というサフィックスが付いていてもいなくてもかまいません。

たとえば、`UserCollection`は指定ユーザーインスタンスを`UserResource`リソースにマップしようとします。この動作をカスタマイズするには、リソースコレクションの`$collects`プロパティをオーバーライドします。

    <?php

    namespace App\Http\Resources;

    use Illuminate\Http\Resources\Json\ResourceCollection;

    class UserCollection extends ResourceCollection
    {
        /**
         * このリソースが収集するリソース
         *
         * @var string
         */
        public $collects = Member::class;
    }

<a name="writing-resources"></a>
## リソースの記述

> {tip} [概論](#concept-overview)を読んでいない場合は、このドキュメント読み進める前に一読することを強く推奨します。

本質的に、リソースは単純です。特定のモデルを配列に変換するだけで済みます。したがって、各リソースには、モデルの属性をアプリケーションのルートまたはコントローラから返すことができるAPIフレンドリーな配列に変換する`toArray`メソッドが含まれています。

    <?php

    namespace App\Http\Resources;

    use Illuminate\Http\Resources\Json\JsonResource;

    class UserResource extends JsonResource
    {
        /**
         * リソースを配列に変換
         *
         * @param  \Illuminate\Http\Request  $request
         * @return array
         */
        public function toArray($request)
        {
            return [
                'id' => $this->id,
                'name' => $this->name,
                'email' => $this->email,
                'created_at' => $this->created_at,
                'updated_at' => $this->updated_at,
            ];
        }
    }

リソースを定義したら、ルートまたはコントローラから直接返せます。

    use App\Http\Resources\UserResource;
    use App\Models\User;

    Route::get('/user/{id}', function ($id) {
        return new UserResource(User::findOrFail($id));
    });

<a name="relationships"></a>
#### リレーション

リレーションをレスポンスへ含めたい場合は、リソースの`toArray`メソッドから返す配列にそれらを追加できます。この例では、`PostResource`リソースの`collection`メソッドを使用して、ユーザーのブログ投稿をリソースレスポンスへ追加しています。

    use App\Http\Resources\PostResource;

    /**
     * リソースを配列に変換
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array
     */
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'posts' => PostResource::collection($this->posts),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }

> {tip} リレーションがすでにロードされている場合にのみリレーションを含めたい場合は、[条件付きリレーション](#conditional-relationships)のドキュメントを確認してください。

<a name="writing-resource-collections"></a>
#### リソースコレクション

リソースは単一のモデルを配列に変換しますが、リソースコレクションはモデルのコレクションを配列に変換します。ただし、すべてのリソースが「アドホック」リソースコレクションを簡単に生成するために`collection`メソッドを提供しているため、モデルごとにリソースコレクションクラスを定義する必要はありません。

    use App\Http\Resources\UserResource;
    use App\Models\User;

    Route::get('/users', function () {
        return UserResource::collection(User::all());
    });

ただし、コレクションとともに返されるメタデータをカスタマイズする必要がある場合は、独自のリソースコレクションを定義する必要があります。

    <?php

    namespace App\Http\Resources;

    use Illuminate\Http\Resources\Json\ResourceCollection;

    class UserCollection extends ResourceCollection
    {
        /**
         * リソースコレクションを配列に変換
         *
         * @param  \Illuminate\Http\Request  $request
         * @return array
         */
        public function toArray($request)
        {
            return [
                'data' => $this->collection,
                'links' => [
                    'self' => 'link-value',
                ],
            ];
        }
    }

単一のリソースと同様に、リソースコレクションはルートまたはコントローラから直接返されるでしょう。

    use App\Http\Resources\UserCollection;
    use App\Models\User;

    Route::get('/users', function () {
        return new UserCollection(User::all());
    });

<a name="data-wrapping"></a>
### データのラップ

デフォルトでは、リソースレスポンスがJSONに変換されるときに、最も外側のリソースが`data`キーでラップされます。したがって、たとえば、一般的なリソースコレクションのレスポンスは次のようになります。

    {
        "data": [
            {
                "id": 1,
                "name": "Eladio Schroeder Sr.",
                "email": "therese28@example.com",
            },
            {
                "id": 2,
                "name": "Liliana Mayert",
                "email": "evandervort@example.com",
            }
        ]
    }

`data`の代わりにカスタムキーを使用したい場合は、リソースクラスに`$wrap`属性を定義します。

    <?php

    namespace App\Http\Resources;

    use Illuminate\Http\Resources\Json\JsonResource;

    class UserResource extends JsonResource
    {
        /**
         * 適用する「データ」ラッパー
         *
         * @var string
         */
        public static $wrap = 'user';
    }

最も外側のリソースのラッピングを無効にする場合は、ベースの`Illuminate\Http\Resources\Json\JsonResource`クラスで`withoutWrapping`メソッドを呼び出す必要があります。通常、このメソッドは、アプリケーションへのすべてのリクエストで読み込まれる`AppServiceProvider`か、別の[サービスプロバイダ](/docs/{{version}}/provider)から呼び出す必要があります。

    <?php

    namespace App\Providers;

    use Illuminate\Http\Resources\Json\JsonResource;
    use Illuminate\Support\ServiceProvider;

    class AppServiceProvider extends ServiceProvider
    {
        /**
         * 全アプリケーションサービスの登録
         *
         * @return void
         */
        public function register()
        {
            //
        }

        /**
         * アプリケーションサービスの全初期起動処理
         *
         * @return void
         */
        public function boot()
        {
            JsonResource::withoutWrapping();
        }
    }

> {note} `withoutWrapping`メソッドは最も外側のレスポンスにのみ影響し、独自のリソースコレクションに手動で追加した`data`キーは削除しません。

<a name="wrapping-nested-resources"></a>
#### ネストされたリソースのラップ

リソースのリレーションをどのようにラップするか、決定する完全な自由が皆さんにあります。ネストに関係なくすべてのリソースコレクションを`data`キーでラップする場合は、リソースごとにリソースコレクションクラスを定義し、`data`キー内でコレクションを返す必要があります。

これにより、もっとも外側のリソースが２つの`data`キーにラップされてしまうのか疑問に思われるかもしれません。心配ありません。Laravelが誤ってリソースを二重にラップすることは決してないので、変換するリソースコレクションのネストレベルについて心配する必要はありません。

    <?php

    namespace App\Http\Resources;

    use Illuminate\Http\Resources\Json\ResourceCollection;

    class CommentsCollection extends ResourceCollection
    {
        /**
         * リソースコレクションを配列に変換
         *
         * @param  \Illuminate\Http\Request  $request
         * @return array
         */
        public function toArray($request)
        {
            return ['data' => $this->collection];
        }
    }

<a name="data-wrapping-and-pagination"></a>
#### データのラップとペジネーション

リソースレスポンスを介してページ付けされたコレクションを返す場合、Laravelは`withoutWrapping`メソッドが呼び出された場合でも、リソースデータを`data`キーでラップします。これはページ化されたレスポンスには、常にページネーターの状態に関する情報を含む`meta`キーと`links`キーが含まれているためです。

    {
        "data": [
            {
                "id": 1,
                "name": "Eladio Schroeder Sr.",
                "email": "therese28@example.com",
            },
            {
                "id": 2,
                "name": "Liliana Mayert",
                "email": "evandervort@example.com",
            }
        ],
        "links":{
            "first": "http://example.com/pagination?page=1",
            "last": "http://example.com/pagination?page=1",
            "prev": null,
            "next": null
        },
        "meta":{
            "current_page": 1,
            "from": 1,
            "last_page": 1,
            "path": "http://example.com/pagination",
            "per_page": 15,
            "to": 10,
            "total": 10
        }
    }

<a name="pagination"></a>
### ペジネーション

Laravel ペジネータインスタンスをリソースの`collection`メソッドまたはカスタムリソースコレクションに渡すことができます。

    use App\Http\Resources\UserCollection;
    use App\Models\User;

    Route::get('/users', function () {
        return new UserCollection(User::paginate());
    });

ページ化されたレスポンスには、常に、ページネーターの状態に関する情報を含む`meta`キーと`links`キーが含まれます。

    {
        "data": [
            {
                "id": 1,
                "name": "Eladio Schroeder Sr.",
                "email": "therese28@example.com",
            },
            {
                "id": 2,
                "name": "Liliana Mayert",
                "email": "evandervort@example.com",
            }
        ],
        "links":{
            "first": "http://example.com/pagination?page=1",
            "last": "http://example.com/pagination?page=1",
            "prev": null,
            "next": null
        },
        "meta":{
            "current_page": 1,
            "from": 1,
            "last_page": 1,
            "path": "http://example.com/pagination",
            "per_page": 15,
            "to": 10,
            "total": 10
        }
    }

<a name="conditional-attributes"></a>
### 条件付き属性

特定の条件が満たされた場合にのみ、リソースレスポンスに属性を含めたい場合があるでしょう。たとえば、現在のユーザーが「管理者（administrator）」である場合にのみ値を含めることができます。Laravelはこうした状況で、皆さんを支援するためのさまざまなヘルパメソッドを提供します。`when`メソッドを使用して、リソースレスポンスに属性を条件付きで追加できます。

    use Illuminate\Support\Facades\Auth;

    /**
     * リソースを配列に変換
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array
     */
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'secret' => $this->when(Auth::user()->isAdmin(), 'secret-value'),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }

この例では、認証済みユーザーの`isAdmin`メソッドが`true`を返した場合にのみ、最終的なリソースレスポンスで`secret`キーが返されます。メソッドが`false`を返す場合、`secret`キーは、クライアントに送信される前にリソースレスポンスから削除されます。`when`メソッドを使用すると、配列を作成するときに条件文に頼ることなく、リソースを表現的に定義できます。

`when`メソッドは２番目の引数としてクロージャも受け入れ、指定する条件が`true`の場合にのみ結果の値を計算できるようにします。

    'secret' => $this->when(Auth::user()->isAdmin(), function () {
        return 'secret-value';
    }),

<a name="merging-conditional-attributes"></a>
#### 条件付き属性のマージ

同じ条件に基づいてリソースレスポンスにのみ含める必要のある属性が複数存在する場合があります。この場合、指定する条件が`true`の場合にのみ、`mergeWhen`メソッドを使用して属性をレスポンスへ含められます。

    /**
     * リソースを配列に変換
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array
     */
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            $this->mergeWhen(Auth::user()->isAdmin(), [
                'first-secret' => 'value',
                'second-secret' => 'value',
            ]),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }

この場合も、指定する条件が`false`の場合、これらの属性は、クライアントに送信される前にリソースレスポンスから削除されます。

> {note} `mergeWhen`メソッドは、文字列キーと数値キーが混在する配列内では使用しないでください。さらに、順番に並べられていない数値キーを持つ配列内では使用しないでください。

<a name="conditional-relationships"></a>
### 条件付きリレーション

条件付きで属性をロードすることに加え、リレーションがすでにモデルにロードされているかどうかの条件付きで、リソースレスポンスへリレーションを含めることもできます。これにより、コントローラはモデルにロードする必要のあるリレーションを決定でき、リソースは実際にロードされた場合にのみ簡単に含めることができます。最終的に、これにより、リソース内の「Ｎ＋１」クエリの問題を簡単に回避できます。

`whenLoaded`メソッドを使用して、リレーションを条件付きでロードできます。リレーションを不必要にロードすることを避けるために、このメソッドはリレーション自体ではなくリレーション名を引数に取ります。

    use App\Http\Resources\PostResource;

    /**
     * リソースを配列に変換
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array
     */
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'posts' => PostResource::collection($this->whenLoaded('posts')),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }

この例では、リレーションがロードされていない場合、`posts`キーはクライアントに送信される前に、リソースレスポンスから削除されます。

<a name="conditional-pivot-information"></a>
#### 条件付きピボット情報

リソースレスポンスへリレーション情報を条件付きで含めることに加えて、`whenPivotLoaded`メソッドを使用して、多対多関係の中間テーブルからのデータを条件付きで含めることもできます。`whenPivotLoaded`メソッドは、最初の引数にピボットテーブル名を取ります。２番目の引数は、モデルでピボット情報が利用可能な場合に返す値を返すクロージャである必要があります。

    /**
     * リソースを配列に変換
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array
     */
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'expires_at' => $this->whenPivotLoaded('role_user', function () {
                return $this->pivot->expires_at;
            }),
        ];
    }

リレーションが[カスタム中間テーブルモデル](/docs/{{version}}/eloquent-relationships#defining-custom-intermediate-table-models)を使用している場合は、`whenPivotLoaded`メソッドへの最初の引数に中間テーブルモデルのインスタンスを渡すことができます。:

    'expires_at' => $this->whenPivotLoaded(new Membership, function () {
        return $this->pivot->expires_at;
    }),

中間テーブルが`pivot`以外のアクセサを使用している場合は、`whenPivotLoadedAs`メソッドを使用します。

    /**
     * リソースを配列に変換
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array
     */
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'expires_at' => $this->whenPivotLoadedAs('subscription', 'role_user', function () {
                return $this->subscription->expires_at;
            }),
        ];
    }

<a name="adding-meta-data"></a>
### メタデータの追加

一部のJSON API基準では、リソースおよびリソースコレクションのレスポンスへメタデータを追加する必要があります。これには多くの場合、リソースまたは関連リソースへの「リンク（`links`）」や、リソース自体に関するメタデータなどが含まれます。リソースに関する追加のメタデータを返す必要がある場合は、それを`toArray`メソッドに含めます。たとえば、リソースコレクションを変換するときに`link`情報を含めることができます。

    /**
     * リソースを配列に変換
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array
     */
    public function toArray($request)
    {
        return [
            'data' => $this->collection,
            'links' => [
                'self' => 'link-value',
            ],
        ];
    }

リソースから追​​加のメタデータを返す場合、ページ付けされたレスポンスを返すときにLaravelによって自動的に追加される`links`または`meta`キーを誤ってオーバーライドしてしまうことを心配する必要はありません。追加定義した`links`は、ページネーターによって提供されるリンクとマージされます。

<a name="top-level-meta-data"></a>
#### トップレベルのメタデータ

リソースが返えす最も外側のリソースである場合、リソースレスポンスへ特定のメタデータのみを含めたい場合があります。通常、これにはレスポンス全体に関するメタ情報が含まれます。このメタデータを定義するには、リソースクラスに`with`メソッドを追加します。このメソッドは、リソースが変換される最も外側のリソースである場合にのみ、リソースレスポンスに含めるメタデータの配列を返す必要があります。

    <?php

    namespace App\Http\Resources;

    use Illuminate\Http\Resources\Json\ResourceCollection;

    class UserCollection extends ResourceCollection
    {
        /**
         * リソースコレクションを配列に変換
         *
         * @param  \Illuminate\Http\Request  $request
         * @return array
         */
        public function toArray($request)
        {
            return parent::toArray($request);
        }

        /**
         * Getリソース配列とともに返す必要のある追加データ
         *
         * @param  \Illuminate\Http\Request  $request
         * @return array
         */
        public function with($request)
        {
            return [
                'meta' => [
                    'key' => 'value',
                ],
            ];
        }
    }

<a name="adding-meta-data-when-constructing-resources"></a>
#### リソースを構築する際のメタデータの追加

ルートまたはコントローラでリソースインスタンスを構築するときに、トップレベルのデータを追加することもできます。すべてのリソースで使用できる`additional`メソッドは、リソースレスポンスへ追加する必要のあるデータの配列を引数に取ります。

    return (new UserCollection(User::all()->load('roles')))
                    ->additional(['meta' => [
                        'key' => 'value',
                    ]]);

<a name="resource-responses"></a>
## リソースレスポンス

すでにお読みになったように、リソースはルートとコントローラから直接返します。

    use App\Http\Resources\UserResource;
    use App\Models\User;

    Route::get('/user/{id}', function ($id) {
        return new UserResource(User::findOrFail($id));
    });

しかし、クライアントに送信する前に、送信HTTPレスポンスをカスタマイズする必要が起きる場合があります。これを実現するには２つの方法があります。最初の方法は、`response`メソッドをリソースにチェーンすることです。このメソッドは`Illuminate\Http\JsonResponse`インスタンスを返し、皆さんがレスポンスのヘッダを完全にコントロールできるようにします。

    use App\Http\Resources\UserResource;
    use App\Models\User;

    Route::get('/user', function () {
        return (new UserResource(User::find(1)))
                    ->response()
                    ->header('X-Value', 'True');
    });

もう一つの方法は、リソース自身の中で`withResponse`メソッドを定義することです。このメソッドは、リソースがレスポンスにおいて最も外側のリソースとして返されるときに呼び出されます。

    <?php

    namespace App\Http\Resources;

    use Illuminate\Http\Resources\Json\JsonResource;

    class UserResource extends JsonResource
    {
        /**
         * リソースを配列に変換
         *
         * @param  \Illuminate\Http\Request  $request
         * @return array
         */
        public function toArray($request)
        {
            return [
                'id' => $this->id,
            ];
        }

        /**
         * リソースの送信レスポンスのカスタマイズ
         *
         * @param  \Illuminate\Http\Request  $request
         * @param  \Illuminate\Http\Response  $response
         * @return void
         */
        public function withResponse($request, $response)
        {
            $response->header('X-Value', 'True');
        }
    }
