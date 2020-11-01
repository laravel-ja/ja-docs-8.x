# Eloquent: APIリソース

- [イントロダクション](#introduction)
- [リソース生成](#generating-resources)
- [概略](#concept-overview)
    - [リソースコレクション](#resource-collections)
- [リソース記述](#writing-resources)
    - [データラップ](#data-wrapping)
    - [ペジネーション](#pagination)
    - [条件付き属性](#conditional-attributes)
    - [条件付きリレーション](#conditional-relationships)
    - [メタデータ追加](#adding-meta-data)
- [リソースレスポンス](#resource-responses)

<a name="introduction"></a>
## イントロダクション

API構築時、Eloquentモデルと、アプリケーションユーザーに対して実際に返信するJSONリスポンスとの間に、トランスレーション層を設置することが必要となります。Laravelのリソースクラスは、モデルやモデルコレクションを記述しやすく簡単に、JSONへと変換してくれます。

<a name="generating-resources"></a>
## リソース生成

リソースクラスを生成するには、`make:resource` Artisanコマンドを使用します。リソースはデフォルトで、アプリケーションの`app/Http/Resources`ディレクトリに設置されます。リソースは、`Illuminate\Http\Resources\Json\JsonResource`クラスを拡張します。

    php artisan make:resource User

<a name="generating-resource-collections"></a>
#### コレクションのリソース

個別のモデルのリソースに加え、モデルのコレクションを変換し、返信するリソースを生成することも可能です。これにより、レスポンスにリンクと、指定したコレクションリソース全体を表す他のメタ情報を含めることができるようになります。

コレクションリソースを生成するには、リソース生成時に`--collection`フラグを指定してください。もしくは、リソース名へ`Collection`を含め、Laravelへコレクションリソースを生成するように指示できます。コレクションリソースは、`Illuminate\Http\Resources\Json\ResourceCollection`クラスを拡張します。

    php artisan make:resource User --collection

    php artisan make:resource UserCollection

<a name="concept-overview"></a>
## 概略

> {tip} このセクションは、リソースとコレクションリソースについて、大雑把に概略を説明します。リソースで実現可能な機能とカスタマイズについて深く理解するため、このドキュメントの他の部分もお読みください。

リソースを書く場合に指定可能な全オプションを説明する前に、最初はLaravelでリソースがどのように使われるかという点を俯瞰し、確認しておきましょう。リソースクラスは、JSON構造へ変換する必要のある一つのモデルを表します。例として、シンプルな`User`クラスを見てみましょう。

    <?php

    namespace App\Http\Resources;

    use Illuminate\Http\Resources\Json\JsonResource;

    class User extends JsonResource
    {
        /**
         * リソースを配列へ変換する
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

レスポンスを送り返す時に、JSONへ変換する必要のある属性の配列を返す、`toArray`メソッドを全リソースクラスで定義します。`$this`変数を使用し、直接モデルのプロパティへアクセスできる点に注目です。これはリソースクラスが、変換するためにアクセスするモデルの、プロパティとメソッドを自動的に仲介するからです。リソースが定義できたら、ルートやコントローラから返します。

    use App\Http\Resources\User as UserResource;
    use App\Models\User;

    Route::get('/user', function () {
        return new UserResource(User::find(1));
    });

<a name="resource-collections"></a>
### コレクションリソース

ページ付けしたリソースやコレクションを返す場合は、ルートかコントローラの中で、リソースインスタンスを生成する時に、`collection`メソッドを使用します。

    use App\Http\Resources\User as UserResource;
    use App\Models\User;

    Route::get('/user', function () {
        return UserResource::collection(User::all());
    });

これにより返信するコレクションに付加する必要のあるメタデータが、追加されるわけではありません。コレクションリソースレスポンスをカスタマイズしたい場合は、そのコレクションを表すための専用リソースを生成してください。

    php artisan make:resource UserCollection

コレクションリソースを生成すれば、レスポンスに含めたいメタデータを簡単に定義できます。

    <?php

    namespace App\Http\Resources;

    use Illuminate\Http\Resources\Json\ResourceCollection;

    class UserCollection extends ResourceCollection
    {
        /**
         * コレクションリソースを配列へ変換
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

定義したコレクションリソースは、ルートかコントローラから返してください。

    use App\Http\Resources\UserCollection;
    use App\Models\User;

    Route::get('/users', function () {
        return new UserCollection(User::all());
    });

<a name="preserving-collection-keys"></a>
#### コレクションキーの保持

ルートからリソースコレクションが返ってくる場合、Laravelは単純な数字順にするように、コレクションのキーをリセットします。しかしながら、リソースクラスへ`preserveKeys`プロパティを追加し、コレクションのキーを保持するように指定できます。

    <?php

    namespace App\Http\Resources;

    use Illuminate\Http\Resources\Json\JsonResource;

    class User extends JsonResource
    {
        /**
         * リソースのコレクションのキーを保持する
         *
         * @var bool
         */
        public $preserveKeys = true;
    }

`preserveKeys`プロパティが`true`にセットされると、コレクションのキーは保持されるようになります。

    use App\Http\Resources\User as UserResource;
    use App\Models\User;

    Route::get('/user', function () {
        return UserResource::collection(User::all()->keyBy->id);
    });

<a name="customizing-the-underlying-resource-class"></a>
#### 背後のリソースクラスのカスタマイズ

リソースコレクションの`$this->collection`は、リソースクラスコレクションの単数形で、各アイテムのマッピング結果を自動的に収集します。コレクションのクラス名から、末尾の`Collection`文字列を除いたものが、単数形のリソースクラス名と仮定します。

たとえば、`UserCollection`は、指定ユーザーインスタンスを`User`リソースへマッピングしようとします。この動作をカスタマイズする場合は、リソースコレクションの`$collects`プロパティをオーバーライドしてください。

    <?php

    namespace App\Http\Resources;

    use Illuminate\Http\Resources\Json\ResourceCollection;

    class UserCollection extends ResourceCollection
    {
        /**
         * このリソースを収集するリソース
         *
         * @var string
         */
        public $collects = 'App\Http\Resources\Member';
    }

<a name="writing-resources"></a>
## リソース記述

> {tip} [概略](#concept-overview)をまだ読んでいないのなら、ドキュメントを読み進める前に目を通しておくことを強く推奨します。

リソースの本質はシンプルです。特定のモデルを配列に変換する必要があるだけです。そのため、APIフレンドリーな配列としてユーザーへ送り返せるように、モデルの属性を変換するための`toArray`メソッドをリソースは持っています。

    <?php

    namespace App\Http\Resources;

    use Illuminate\Http\Resources\Json\JsonResource;

    class User extends JsonResource
    {
        /**
         * リソースを配列へ変換する
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

リソースを定義したら、ルートかコントローラから、直接返してください。

    use App\Http\Resources\User as UserResource;
    use App\Models\User;

    Route::get('/user', function () {
        return new UserResource(User::find(1));
    });

<a name="relationships"></a>
#### リレーション

関連するリソースをレスポンスへ含めるには、`toArray`メソッドから返す配列に追加します。以下の例では、`Post`リソースの`collection`メソッドを使用し、ユーザーのブログポストをリソースレスポンスへ追加しています。

    /**
     * リソースを配列へ変換
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

> {tip} すでにロードされている場合のみ、リレーションを含めたい場合は、[条件付きリレーション](#conditional-relationships)のドキュメントを参照してください。

<a name="writing-resource-collections"></a>
#### コレクションのリソース

リソースは一つのモデルを配列へ変換するのに対し、コレクションリソースはモデルのコレクションを配列へ変換します。モデルタイプそれぞれに対し、コレクションリソースを絶対に定義する必要があるわけではありません。すべてのリソースは、簡単に「アドホック」なコレクションリソースを生成するために、`collection`メソッドを提供しています。

    use App\Http\Resources\User as UserResource;
    use App\Models\User;

    Route::get('/user', function () {
        return UserResource::collection(User::all());
    });

しかしながら、コレクションと一緒に返すメタデータをカスタマイズする必要がある場合は、コレクションリソースを定義する必要があります。

    <?php

    namespace App\Http\Resources;

    use Illuminate\Http\Resources\Json\ResourceCollection;

    class UserCollection extends ResourceCollection
    {
        /**
         * コレクションリソースを配列へ変換
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

１モデルを扱うリソースと同様にコレクションリソースも、ルートやコントローラから直接返してください。

    use App\Http\Resources\UserCollection;
    use App\Models\User;

    Route::get('/users', function () {
        return new UserCollection(User::all());
    });

<a name="data-wrapping"></a>
### データラップ

デフォルトではリソースレスポンスがJSONに変換されるとき、一番外側のリソースを`data`キー下にラップします。たとえば、典型的なコレクションリソースのレスポンスは、次のようになるでしょう。

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

`data`の代わりにカスタムキーを使用したい場合は、リソースクラスで`$wrap`属性を定義してください。

    <?php

    namespace App\Http\Resources;

    use Illuminate\Http\Resources\Json\JsonResource;

    class User extends JsonResource
    {
        /**
         * 適用する"data"ラッパー
         *
         * @var string
         */
        public static $wrap = 'user';
    }

一番外部のリソースでラップしないようにしたい場合は、ベースのリソースクラスに対し、`withoutWrapping`メソッドを使用してください。通常、このメソッドはアプリケーションに対するリクエストごとにロードされる、`AppServiceProvider`か、もしくは他の[サービスプロバイダ](/docs/{{version}}/providers)から呼び出します。

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
         * 全アプリケーションサービスの初期処理
         *
         * @return void
         */
        public function boot()
        {
            JsonResource::withoutWrapping();
        }
    }

> {note} `withoutWrapping`メソッドは、最も外側のレスポンスだけに影響を与えます。コレクションリソースに皆さんが自分で追加した`data`キーは、削除されません。

<a name="wrapping-nested-resources"></a>
### ネストしたリソースのラップ

リソースのリレーションをどのようにラップするかは、完全に自由です。ネスト状態にかかわらず、`data`キーの中に全コレクションリソースをラップしたい場合は、リソースそれぞれに対するコレクションリソースを定義し、`data`キーにコレクションを含めて返す必要があります。

それにより、一番外側のリソースが二重の`data`キーでラップされてしまうのではないかと、疑うのは当然です。心配ありません。Laravelは決してリソースを間違って二重にラップしたりしません。変換するコレクションリソースのネストレベルについて、心配する必要はありません。

    <?php

    namespace App\Http\Resources;

    use Illuminate\Http\Resources\Json\ResourceCollection;

    class CommentsCollection extends ResourceCollection
    {
        /**
         * コレクションリソースを配列へ変換
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
### データラップとペジネーション

リソースレスポンスの中から、ページ付けしたコレクションを返す場合、`withoutWrapping`メソッドが呼び出されていても、Laravelはリソースデータを`data`キーでラップします。なぜなら、ページ付けしたレスポンスは、ペジネータの状態を含めた`meta`と`links`キーを常に含めるからです。

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

常にペジネータインスタンスをリソースの`collection`メソッドや、カスタムコレクションリソースへ渡せます。

    use App\Http\Resources\UserCollection;
    use App\Models\User;

    Route::get('/users', function () {
        return new UserCollection(User::paginate());
    });

ページ付けしたレスポンスは常に、ペジネータの状態を含む`meta`と`links`キーを持っています。

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

条件が一致する場合のみ、リソースレスポンスへ属性を含めたいこともあります。たとえば、現在のユーザーが"administrator"の場合のみ、ある値を含めたいときです。こうした状況で役に立つさまざまなヘルパメソッドをLaravelは提供しています。`when`メソッドは条件により、リソースレスポンスへ属性を追加する場合に使用します。

    /**
     * リソースを配列へ変換
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

この例では、認証済みユーザーの`isAdmin`メソッドが`true`を返す場合のみ、最終的なリソースレスポンスに`secret`キーが返されます。メソッドが`false`の場合、クライアントへ送り返される前に、リソースレスポンスから`secret`キーは完全に削除されます。`when`メソッドにより配列の構築時でも条件文に頼らず、リソースを記述的に定義できます。

`when`メソッドは第２引数にクロージャを引き受け、指定した条件が`true`の場合のみ結果の値を算出することもできます。

    'secret' => $this->when(Auth::user()->isAdmin(), function () {
        return 'secret-value';
    }),

<a name="merging-conditional-attributes"></a>
#### 条件付き属性のマージ

リソースレスポンスへ同じ条件にもとづいて、多くの属性を含めたい場合もあります。この場合、指定した条件が`true`の場合のみ、レスポンスへ属性を組み入れる`mergeWhen`メソッドを使用します。

    /**
     * リソースを配列へ変換
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

このメソッドでも、指定した条件が`false`の場合、利用者へ送り返される前に、属性はリソースレスポンスから完全に取り除かれます。

> {note} `mergeWhen`メソッドは、文字列と数値のキーが混ざっている配列の中では、使用しないでください。さらに、順番に並んでいない数値キーの配列でも、使用しないでください。

<a name="conditional-relationships"></a>
### 条件付きリレーション

条件によりロードする属性に付け加え、リレーションがモデルにロードされているかに基づいて、リソースレスポンスへリレーションを条件付きで含めることもできます。これにより、どのリレーションをモデルにロードさせるかをコントローラで決め、リソースが実際にロード済みの場合のみ、レスポンスへ含めることが簡単に実現できます。

究極的には、これによりリソースの中で「N＋１」クエリ問題を簡単に防ぐことができます。`whenLoaded`メソッドは、リレーションを条件付きでロードするために使われます。不必要なリレーションのロードを防ぐために、このメソッドはリレーションそのものの代わりに、リレーションの名前を引数に取ります

    /**
     * リソースを配列へ変換
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

この例の場合、リレーションがロードされていない場合、`posts`キーは利用者へ送り返される前に、レスポンスから完全に取り除かれます。

<a name="conditional-pivot-information"></a>
#### 条件付きピボット情報

リソースレスポンスへ条件付きでリレーション情報を含める機能に付け加え、`whenPivotLoaded`メソッドを使用し、多対多リレーションの中間テーブルからのデータを含めることもできます。`whenPivotLoaded`メソッドは、第１引数に中間テーブルの名前を引き受けます。第２引数には、ピボット情報がそのモデルに対し利用可能な場合の返却値を定義するクロージャを指定します。

    /**
     * リソースを配列へ変換
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

中間テーブルが`pivot`以外のアクセサにより使用されている場合は、`whenPivotLoadedAs`メソッドを使用してください。

    /**
     * リソースを配列へ変換
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
### メタデータ追加

いくつかのJSON API規約では、リソースとコレクションリソースレスポンスで、追加のメタデータを要求しています。これらには、リソースへの`link`のような情報や、関連するリソース、リソース自体のメタデータなどがよく含まれます。リソースに関する追加のメタデータを返す必要がある場合は、`toArray`メソッドに含めます。たとえば、コレクションリソースを変換する時に、`link`情報を含めるには次のようにします。

    /**
     * リソースを配列へ変換
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

追加のメタデータをリソースから返す場合、ページ付けレスポンスへLaravelが自動的に付け加える、`links`や`meta`キーを意図せずオーバーライドしてしまう心配はありません。追加の`links`定義は、ペジネータが提供するリンク情報にマージされます。

<a name="top-level-meta-data"></a>
#### トップレベルメタデータ

一番外側のリソースが返される場合にのみ、特定のメタデータをリソースレスポンスへ含めたい場合があります。典型的な例は、レスポンス全体のメタ情報です。こうしたメタデータを定義するには、リソースクラスへ`with`メソッドを追加します。このメソッドには、一番外側のリソースを返す場合のみ、リソースレスポンスへ含めるメタデータの配列を返します。

    <?php

    namespace App\Http\Resources;

    use Illuminate\Http\Resources\Json\ResourceCollection;

    class UserCollection extends ResourceCollection
    {
        /**
         * コレクションリソースを配列へ変換
         *
         * @param  \Illuminate\Http\Request  $request
         * @return array
         */
        public function toArray($request)
        {
            return parent::toArray($request);
        }

        /**
         * リソース配列と共に返すべき、追加データの取得
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
#### リソース構築時のメタデータ追加

ルートやコントローラの中で、リソースインスタンスを構築する時に、トップレベルのデータを追加することもできます。全リソースの中で利用可能な`additional`メソッドは、リソースレスポンスへ含めるべき追加データの配列を引数に取ります。

    return (new UserCollection(User::all()->load('roles')))
                    ->additional(['meta' => [
                        'key' => 'value',
                    ]]);

<a name="resource-responses"></a>
## リソースレスポンス

すでに説明したように、リソースはルートかコントローラから直接返されます。

    use App\Http\Resources\User as UserResource;
    use App\Models\User;

    Route::get('/user', function () {
        return new UserResource(User::find(1));
    });

しかし、利用者へ送信する前に、HTTPレスポンスをカスタマイズする必要がときどき起こるでしょう。リソースに対して`response`メソッドをチェーンしてください。このメソッドは、`Illuminate\Http\JsonResponse`インスタンスを返しますので、レスポンスヘッダを完全にコントロールできます。

    use App\Http\Resources\User as UserResource;
    use App\Models\User;

    Route::get('/user', function () {
        return (new UserResource(User::find(1)))
                    ->response()
                    ->header('X-Value', 'True');
    });

もしくは、`withResponse`メソッドをレスポンス自身の中で定義することもできます。このメソッドはレスポンスの中で一番外側のリソースとして返す場合に呼び出されます。

    <?php

    namespace App\Http\Resources;

    use Illuminate\Http\Resources\Json\JsonResource;

    class User extends JsonResource
    {
        /**
         * リソースを配列へ変換する
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
         * リソースに対して送信するレスポンスのカスタマイズ
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
