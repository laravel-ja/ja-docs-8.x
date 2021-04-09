# Laravel Scout

- [イントロダクション](#introduction)
- [インストール](#installation)
    - [ドライバの事前要件](#driver-prerequisites)
    - [キュー投入](#queueing)
- [設定](#configuration)
    - [モデルインデックスの設定](#configuring-model-indexes)
    - [検索可能データの設定](#configuring-searchable-data)
    - [モデルIDの設定](#configuring-the-model-id)
    - [ユーザーの識別](#identifying-users)
- [インデックス](#indexing)
    - [バッチ取り込み](#batch-import)
    - [レコード追加](#adding-records)
    - [レコード更新](#updating-records)
    - [レコード削除](#removing-records)
    - [インデックスの一時停止](#pausing-indexing)
    - [条件付き検索可能モデルインスタンス](#conditionally-searchable-model-instances)
- [検索](#searching)
    - [Where節](#where-clauses)
    - [ペジネーション](#pagination)
    - [ソフトデリート](#soft-deleting)
    - [エンジンの検索のカスタマイズ](#customizing-engine-searches)
- [カスタムエンジン](#custom-engines)
- [ビルダマクロ](#builder-macros)

<a name="introduction"></a>
## イントロダクション

Laravel Scout（Scout、斥候）は、[Eloquentモデル](/docs/{{version}}/eloquent)へ、シンプルなドライバベースのフルテキストサーチを提供します。モデルオブサーバを使い、Scoutは検索インデックスを自動的にEloquentレコードと同期します。

現在、Scoutは[Algolia](https://www.algolia.com/)ドライバを用意しています。カスタムドライバは簡単に書けますので、独自の検索を実装し、Scoutを拡張できます。

<a name="installation"></a>
## インストール

最初に、Composerパッケージマネージャを使い、Scoutをインストールします。

    composer require laravel/scout

Scoutをインストールした後、`vendor:publish` Artisanコマンドを実行してScout設定ファイルをリソース公開する必要があります。このコマンドは、`scout.php`設定ファイルをアプリケーションの`config`ディレクトリへリソース公開します。

    php artisan vendor:publish --provider="Laravel\Scout\ScoutServiceProvider"

最後に、検索可能にしたいモデルに`Laravel\Scout\Searchable`トレイトを追加します。このトレイトは、モデルを検索ドライバと自動的に同期させるモデルオブザーバを登録します。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;
    use Laravel\Scout\Searchable;

    class Post extends Model
    {
        use Searchable;
    }

<a name="driver-prerequisites"></a>
### ドライバの事前要件

<a name="algolia"></a>
#### Algolia

Algoliaドライバを使用する場合、Algolia `id`と`secret`接続情報を`config/scout.php`設定ファイルで設定する必要があります。接続情報を設定し終えたら、Algolia PHP SDKをComposerパッケージマネージャで、インストールする必要があります。

    composer require algolia/algoliasearch-client-php

<a name="meilisearch"></a>
#### MeiliSearch

MeiliSearchは強力なオープンソースの検索エンジンで、[Laravel Sail](/docs/{{version}}/sail)を使い、ローカルで実行できます。MeiliSearchは、[Laravel向け公式MeiliSearchドライバ](https://github.com/meilisearch/meilisearch-laravel-scout)を提供し、メンテナンスしています。MeiliSearchをLaravel Scoutで使用する方法については、このパッケージのドキュメントを参照してください。

<a name="queueing"></a>
### キュー投入

厳密にはScoutを使用する必要はありませんが、ライブラリを使用する前に、[キュードライバ](/docs/{{version}}/queues)の設定を強く考慮する必要があります。キューワーカを実行すると、Scoutはモデル情報を検索インデックスに同期するすべての操作をキューに入れることができ、アプリケーションのWebインターフェイスのレスポンス時間が大幅に短縮されます。

キュードライバを設定したら、`config/scout.php`設定ファイルの`queue`オプションの値を`true`に設定します。

    'queue' => true,

<a name="configuration"></a>
## 設定

<a name="configuring-model-indexes"></a>
### モデルインデックスの設定

各Eloquentモデルは、検索可能レコードすべてを含む、指定された検索「インデックス」と同期されます。言い換えれば、各インデックスはMySQLテーブルのようなものであると、考えられます。デフォルトで、各モデルはそのモデルの典型的な「テーブル」名に一致するインデックスへ保存されます。通常、モデルの複数形ですが、モデルの`searchableAs`メソッドをオーバーライドすることで、このモデルのインデックスを自由にカスタマイズ可能です。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;
    use Laravel\Scout\Searchable;

    class Post extends Model
    {
        use Searchable;

        /**
         * モデルに関連付けられているインデックスの名前を取得
         *
         * @return string
         */
        public function searchableAs()
        {
            return 'posts_index';
        }
    }

<a name="configuring-searchable-data"></a>
### 検索可能データの設定

デフォルトでは、指定されたモデルの`toArray`形態全体が、検索インデックスへ保存されます。検索インデックスと同期するデータをカスタマイズしたい場合は、そのモデルの`toSearchableArray`メソッドをオーバーライドできます。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;
    use Laravel\Scout\Searchable;

    class Post extends Model
    {
        use Searchable;

        /**
         * モデルのインデックス可能なデータ配列の取得
         *
         * @return array
         */
        public function toSearchableArray()
        {
            $array = $this->toArray();

            // データ配列をカスタマイズ

            return $array;
        }
    }

<a name="configuring-the-model-id"></a>
### モデルIDの設定

デフォルトでは、Scoutはモデルの主キーを、検索インデックスに保存されているモデルの一意のID／キーとして使用します。この動作をカスタマイズする必要がある場合は、モデルの`getScoutKey`メソッドと`getScoutKeyName`メソッドをオーバーライドできます。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;
    use Laravel\Scout\Searchable;

    class User extends Model
    {
        use Searchable;

        /**
         * モデルのインデックスに使用する値の取得
         *
         * @return mixed
         */
        public function getScoutKey()
        {
            return $this->email;
        }

        /**
         * モデルのインデックスに使用するキー名の取得
         *
         * @return mixed
         */
        public function getScoutKeyName()
        {
            return 'email';
        }
    }

<a name="identifying-users"></a>
### ユーザーの識別

Scoutを使用すると、[Algolia](https://algolia.com)を使用するときにユーザーを自動識別することもできます。認証済みユーザーを検索操作に関連付けると、Algoliaのダッシュボード内で検索分析を表示するときに役立つ場合があります。アプリケーションの`.env`ファイルで`SCOUT_IDENTIFY`環境変数を`true`として定義することにより、ユーザー識別を有効にできます。

    SCOUT_IDENTIFY=true

この機能を有効にすると、リクエストのIPアドレスと認証済みユーザーのプライマリ識別子もAlgoliaに渡されるため、これらのデータはそのユーザーが行った検索リクエストへ関連付けられます。

<a name="indexing"></a>
## インデックス

<a name="batch-import"></a>
### バッチ取り込み

Scoutを既存のプロジェクトにインストールする場合は、インデックスへインポートする必要のあるデータベースレコードがすでに存在している可能性があります。Scoutは、既存のすべてのレコードを検索インデックスにインポートするために使用できる`scout:import` Artisanコマンドを提供しています。

    php artisan scout:import "App\Models\Post"

`flush`コマンドは、検索インデックスからモデルの全レコードを削除するために使用します。

    php artisan scout:flush "App\Models\Post"

<a name="modifying-the-import-query"></a>
#### インポートクエリの変更

バッチインポートで全モデルを取得するために使用されるクエリを変更する場合は、モデルに`makeAllSearchableUsing`メソッドを定義してください。これはモデルをインポートする前に、必要になる可能性のあるイエガーリレーションの読み込みを追加するのに最適な場所です。

    /**
     * 全モデルを検索可能にするときの、モデル取得に使用するクエリを変更
     *
     * @param  \Illuminate\Database\Eloquent\Builder  $query
     * @return \Illuminate\Database\Eloquent\Builder
     */
    protected function makeAllSearchableUsing($query)
    {
        return $query->with('author');
    }

<a name="adding-records"></a>
### レコード追加

モデルに`Laravel\Scout\Searchable`トレイトを追加したら、モデルインスタンスを`保存`または`作成`するだけで、検索インデックスに自動的に追加されます。[キューを使用](#queueing)するようにScoutを設定した場合、この操作はキューワーカによってバックグラウンドで実行されます。

    use App\Models\Order;

    $order = new Order;

    // ...

    $order->save();

<a name="adding-records-via-query"></a>
#### クエリによるレコード追加

Eloquentクエリを介してモデルのコレクションを検索インデックスに追加する場合は、`searchable`メソッドをEloquentクエリにチェーンできます。`searchable`メソッドはクエリの[結果をチャンク](/docs/{{version}}/eloquent#chunking-results)し、レコードを検索インデックスに追加します。繰り返しますが、キューを使用するようにScoutを設定した場合、すべてのチャンクはキューワーカによってバックグラウンドでインポートされます。

    use App\Models\Order;

    Order::where('price', '>', 100)->searchable();

Eloquentリレーションインスタンスで `searchable`メソッドを呼び出すこともできます。

    $user->orders()->searchable();

または、メモリ内にEloquentモデルのコレクションが既にある場合は、コレクションインスタンスで`searchable`メソッドを呼び出して、モデルインスタンスを対応するインデックスに追加できます。

    $orders->searchable();

> {tip} `searchable`メソッドは、「アップサート（upsert）」操作と考えるられます。つまり、モデルレコードがすでにインデックスに含まれている場合は、更新され、検索インデックスに存在しない場合は追加されます。

<a name="updating-records"></a>
### レコード更新

検索可能モデルを更新するには、モデルインスタンスのプロパティを更新し、`save`でモデルをデータベースへ保存します。Scoutは自動的に変更を検索インデックスへ保存します。

    use App\Models\Order;

    $order = Order::find(1);

    // 注文を更新…

    $order->save();

Eloquentクエリインスタンスで`searchable`メソッドを呼び出して、モデルのコレクションを更新することもできます。モデルが検索インデックスに存在しない場合は作成されます。

    Order::where('price', '>', 100)->searchable();

リレーションシップ内のすべてのモデルの検索インデックスレコードを更新する場合は、リレーションシップインスタンスで`searchable`を呼び出すことができます。

    $user->orders()->searchable();

または、メモリ内にEloquentモデルのコレクションが既にある場合は、コレクションインスタンスで`searchable`メソッドを呼び出して、対応するインデックスのモデルインスタンスを更新できます。

    $orders->searchable();

<a name="removing-records"></a>
### レコード削除

インデックスからレコードを削除するには、データベースからモデルを`delete`するだけです。これは、[ソフト削除](/docs/{{version}}/eloquent#soft-deleting)モデルを使用している場合でも実行できます。

    use App\Models\Order;

    $order = Order::find(1);

    $order->delete();

レコードを削除する前にモデルを取得したくない場合は、Eloquentクエリインスタンスで`unsearchable`メソッドを使用できます。

    Order::where('price', '>', 100)->unsearchable();

リレーション内のすべてのモデルの検索インデックスレコードを削除する場合は、リレーションインスタンスで`unsearchable`を呼び出してください。

    $user->orders()->unsearchable();

または、メモリ内にEloquentモデルのコレクションが既にある場合は、コレクションインスタンスで`unsearchable`メソッドを呼び出して、対応するインデックスからモデルインスタンスを削除できます。

    $orders->unsearchable();

<a name="pausing-indexing"></a>
### インデックスの一時停止

モデルデータを検索インデックスに同期せずに、モデルに対してEloquent操作のバッチを実行する必要がある場合があります。これは、`withoutSyncingToSearch`メソッドを使用して行うことができます。このメソッドは、すぐに実行される単一のクロージャを引数に取ります。クロージャ内で発行するモデル操作は、モデルのインデックスに同期されません。

    use App\Models\Order;

    Order::withoutSyncingToSearch(function () {
        // モデルアクションを実行
    });

<a name="conditionally-searchable-model-instances"></a>
### 条件付き検索可能モデルインスタンス

特定の条件下でのみ、モデルを検索可能にする必要がある場合も起きるでしょう。たとえば、`App\Models\Post`モデルが、"draft"か"published"の２つのうち、どちらか１つの状態を取ると想像してください。「公開済み:published」のポストのみ検索可能にする必要があります。これを実現するには、モデルに`shouldBeSearchable`メソッドを定義してください。

    /**
     * モデルを検索可能にする判定
     *
     * @return bool
     */
    public function shouldBeSearchable()
    {
        return $this->isPublished();
    }

`shouldBeSearchable`メソッドは、`save`および`create`メソッド、クエリ、またはリレーションを通してモデルを操作する場合にのみ適用されます。`searchable`メソッドを使用してモデルまたはコレクションを直接検索可能にすると、`shouldBeSearchable`メソッドの結果が上書きされます。

<a name="searching"></a>
## 検索

`search`メソッドにより、モデルの検索を開始しましょう。`search`メソッドはモデルを検索するために使用する文字列だけを引数に指定します。`get`メソッドを検索クエリにチェーンし、指定した検索クエリに一致するEloquentモデルを取得できます。

    use App\Models\Order;

    $orders = Order::search('Star Trek')->get();

Scoutの検索ではEloquentモデルのコレクションが返されるため、ルートやコントローラから直接結果を返せば、自動的にJSONへ変換されます。

    use App\Models\Order;
    use Illuminate\Http\Request;

    Route::get('/search', function (Request $request) {
        return Order::search($request->search)->get();
    });

Eloquentモデルへ変換する前に素の検索結果を取得したい場合は、`raw`メソッドを使用できます。

    $orders = Order::search('Star Trek')->raw();

<a name="custom-indexes"></a>
#### カスタムインデックス

検索クエリは通常、モデルの[`searchableAs`](#configuring-model-indexes)メソッドで指定するインデックスに対して実行されます。ただし、`within`メソッドを使用して、代わりに検索する必要があるカスタムインデックスを指定できます。

    $orders = Order::search('Star Trek')->paginate();
        ->within('tv_shows_popularity_desc')
        ->get();

<a name="where-clauses"></a>
### Where節

Scoutを使用すると、検索クエリに単純な「where」句を追加できます。現在、これらの句は基本的な数値の同等性チェックのみをサポートしており、主に所有者IDによる検索クエリのスコープに役立ちます。検索インデックスはリレーショナルデータベースではないため、現在、より高度な「where」句はサポートしていません。

    use App\Models\Order;

    $orders = Order::search('Star Trek')->where('user_id', 1)->get();

<a name="pagination"></a>
### ペジネーション

モデルのコレクションを取得することに加えて、`paginate`メソッドを使用して検索結果をページ分割することができます。このメソッドは、[従来のEloquentクエリをペジネーションする](/docs/{{version}}/pagination)場合と同じように、`Illuminate\Pagination\LengthAwarePaginator`インスタンスを返します。

    use App\Models\Order;

    $orders = Order::search('Star Trek')->paginate();

`paginate`メソッドの第１引数として、各ページごとに取得したいモデル数を指定します。

    $orders = Order::search('Star Trek')->paginate(15);

結果が取得できたら、通常のEloquentクエリのペジネーションと同様に、結果を表示し、[Blade](/docs/{{version}}/blade)を使用してページリンクをレンダーできます。

```html
<div class="container">
    @foreach ($orders as $order)
        {{ $order->price }}
    @endforeach
</div>

{{ $orders->links() }}
```

もちろん、ペジネーションの結果をJSONとして取得したい場合は、ルートまたはコントローラから直接ペジネータインスタンスを返すことができます。

    use App\Models\Order;
    use Illuminate\Http\Request;

    Route::get('/orders', function (Request $request) {
        return Order::search($request->input('query'))->paginate(15);
    });

<a name="soft-deleting"></a>
### ソフトデリート

インデックス付きのモデルが[ソフトデリート](/docs/{{version}}/eloquent#soft-deleting)され、ソフトデリート済みのモデルをサーチする必要がある場合、`config/scout.php`設定ファイルの`soft_delete`オプションを`true`に設定してください。

    'soft_delete' => true,

この設定オプションを`true`にすると、Scoutは検索インデックスからソフトデリートされたモデルを削除しません。代わりに、インデックスされたレコードへ、隠し`__soft_deleted`属性をセットします。これにより、検索時にソフトデリート済みレコードを取得するために、`withTrashed`や`onlyTrashed`メソッドがつかえます。

    use App\Models\Order;

    // 結果の取得時に、削除済みレコードも含める
    $orders = Order::search('Star Trek')->withTrashed()->get();

    // 結果の取得時に、削除済みレコードのみを対象とする
    $orders = Order::search('Star Trek')->onlyTrashed()->get();

> {tip} ソフトデリートされたモデルが、`forceDelete`により完全に削除されると、Scoutは自動的に検索インデックスから削除します。

<a name="customizing-engine-searches"></a>
### エンジンの検索のカスタマイズ

エンジンの検索動作の高度なカスタマイズを実行する必要がある場合は、 `search`メソッドの２番目の引数にクロージャを渡せます。たとえば、このコールバックを使用して、検索クエリがAlgoliaに渡される前に、地理的位置データを検索オプションに追加できます。

    use Algolia\AlgoliaSearch\SearchIndex;
    use App\Models\Order;

    Order::search(
        'Star Trek',
        function (SearchIndex $algolia, string $query, array $options) {
            $options['body']['query']['bool']['filter']['geo_distance'] = [
                'distance' => '1000km',
                'location' => ['lat' => 36, 'lon' => 111],
            ];

            return $algolia->search($query, $options);
        }
    )->get();

<a name="custom-engines"></a>
## カスタムエンジン

<a name="writing-the-engine"></a>
#### エンジンのプログラミング

組み込みのScout検索エンジンがニーズに合わない場合、独自のカスタムエンジンを書き、Scoutへ登録してください。エンジンは、`Laravel\Scout\Engines\Engine`抽象クラスを拡張してください。この抽象クラスは、カスタムエンジンが実装する必要のある、８つのメソッドを持っています。

    use Laravel\Scout\Builder;

    abstract public function update($models);
    abstract public function delete($models);
    abstract public function search(Builder $builder);
    abstract public function paginate(Builder $builder, $perPage, $page);
    abstract public function mapIds($results);
    abstract public function map(Builder $builder, $results, $model);
    abstract public function getTotalCount($results);
    abstract public function flush($model);

これらのメソッドの実装をレビューするために、`Laravel\Scout\Engines\AlgoliaEngine`クラスが役に立つでしょう。このクラスは独自エンジンで、各メソッドをどのように実装すればよいかの、良い取り掛かりになるでしょう。

<a name="registering-the-engine"></a>
#### エンジンの登録

カスタムエンジンを作成したら、Scoutエンジンマネージャの`extend`メソッドを使用してScoutへ登録します。Scoutのエンジンマネージャは、Laravelサービスコンテナが依存解決できます。`App\Providers\AppServiceProvider`クラスの`boot`メソッドまたはアプリケーションが使用している他のサービスプロバイダから`extend`メソッドを呼び出せます。

    use App\ScoutExtensions\MySqlSearchEngine
    use Laravel\Scout\EngineManager;

    /**
     * 全アプリケーションサービスの初期起動処理
     *
     * @return void
     */
    public function boot()
    {
        resolve(EngineManager::class)->extend('mysql', function () {
            return new MySqlSearchEngine;
        });
    }

エンジンを登録したら、アプリケーションの`config/scout.php`設定ファイルでデフォルトのスカウト`driver`として指定できます。

    'driver' => 'mysql',

<a name="builder-macros"></a>
## ビルダマクロ

カスタムのScout検索ビルダメソッドを定義する場合は、`Laravel\Scout\Builder`クラスで`macro`メソッドが使用できます。通常、「マクロ」は[サービスプロバイダ](/docs/{{version}}/provider)の`boot`メソッド内で定義する必要があります。

    use Illuminate\Support\Facades\Response;
    use Illuminate\Support\ServiceProvider;
    use Laravel\Scout\Builder;

    /**
     * 全アプリケーションサービスの初期起動処理
     *
     * @return void
     */
    public function boot()
    {
        Builder::macro('count', function () {
            return $this->engine->getTotalCount(
                $this->engine()->search($this)
            );
        });
    }

`macro`関数は、最初の引数にマクロ名、２番目の引数にクロージャを取ります。マクロのクロージャは、`Laravel\Scout\Builder`実装からマクロ名を呼び出すときに実行されます。

    use App\Models\Order;

    Order::search('Star Trek')->count();
