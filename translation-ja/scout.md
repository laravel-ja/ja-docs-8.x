# Laravel Scout

- [イントロダクション](#introduction)
- [インストール](#installation)
    - [キュー](#queueing)
    - [ドライバの事前要件](#driver-prerequisites)
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

Laravel Scout（スカウト、斥候）は、[Eloquentモデル](/docs/{{version}}/eloquent)へ、シンプルなドライバベースのフルテキストサーチを提供します。モデルオブサーバを使い、Scoutは検索インデックスを自動的にEloquentレコードと同期します。

現在、Scoutは[Algolia](https://www.algolia.com/)ドライバを用意しています。カスタムドライバは簡単に書けますので、独自の検索を実装し、Scoutを拡張できます。

<a name="installation"></a>
## インストール

最初に、Composerパッケージマネージャを使い、Scoutをインストールします。

    composer require laravel/scout

Scoutをインストールしたら、`vendor:publish` Artisanコマンドを使用し、Scout設定ファイルをリソース公開します。このコマンドは、`config`ディレクトリ下に`scout.php`設定ファイルをリソース公開します。

    php artisan vendor:publish --provider="Laravel\Scout\ScoutServiceProvider"

最後に、検索可能にしたいモデルへ、`Laravel\Scout\Searchable`トレイトを追加します。このトレイトはモデルオブザーバを登録し、サーチドライバとモデルの同期を取り続けます。

    <?php

    namespace App\Models;

    use Illuminate\Database\Eloquent\Model;
    use Laravel\Scout\Searchable;

    class Post extends Model
    {
        use Searchable;
    }

<a name="queueing"></a>
### キュー

Scoutを厳格（リアルタイム）に利用する必要がないのであれば、このライブラリを使用する前に[キュードライバ](/docs/{{version}}/queues)の設定を考えてみるべきでしょう。キューワーカの実行により、モデルの情報を検索インデックスに同期する全操作をキューイングでき、アプリケーションのWebインターフェイスのレスポンス時間を改善できるでしょう。

キュードライバを設定したら、`config/scout.php`設定ファイルの`queue`オプション値を`true`に設定してください。

    'queue' => true,

<a name="driver-prerequisites"></a>
### ドライバの事前要件

<a name="algolia"></a>
#### Algolia

Algoliaドライバを使用する場合、Algolia `id`と`secret`接続情報を`config/scout.php`設定ファイルで設定する必要があります。接続情報を設定し終えたら、Algolia PHP SDKをComposerパッケージマネージャで、インストールする必要があります。

    composer require algolia/algoliasearch-client-php

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
         * モデルのインデックス名取得
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

            // 配列のカスタマイズ…

            return $array;
        }
    }

<a name="configuring-the-model-id"></a>
### モデルIDの設定

Scoutはデフォルトとして、モデルの主キーを検索インデックスへ保存するユニークなIDとして使用します。この振る舞いをカスタマイズしたい場合は、モデルの`getScoutKey`と`getScoutKeyName`メソッドをオーバーライドしてください。

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

ScoutはAlgoliaを使用する場合、自動的にユーザーを識別します。認証済みユーザーを検索操作と結びつけると、Algoliaダッシュボードで検索分析を閲覧する場合、役に立つでしょう。`.env`ファイル中の`SCOUT_IDENTIFY`を`true`に設定するとユーザー認証が有効になります。

    SCOUT_IDENTIFY=true

この機能を有効にすると、リクエストのIPアドレスと認証済みユーザーのプライマリ識別子もAlgoliaに渡されるため、これらのデータはそのユーザーが行った検索リクエストへ関連付けられます。

<a name="indexing"></a>
## インデックス

<a name="batch-import"></a>
### バッチ取り込み

既存プロジェクトにScoutをインストールする場合、検索ドライバへ取り込むために必要なデータベースレコードは、すでに存在しています。Scoutは既存の全レコードを検索インデックスへ取り込むために使用する、`import` Artisanコマンドを提供しています。

    php artisan scout:import "App\Models\Post"

`flush`コマンドは、検索インデックスからモデルの全レコードを削除するために使用します。

    php artisan scout:flush "App\Models\Post"

<a name="adding-records"></a>
### レコード追加

モデルに`Laravel\Scout\Searchable`トレイトを追加したら、必要なのはモデルインスタンスを`save`することです。これにより自動的に検索インデックスへ追加されます。Scoutで[キューを使用する](#queueing)設定にしている場合は、この操作はキューワーカにより、バックグランドで実行されます。

    $order = new App\Models\Order;

    // ...

    $order->save();

<a name="adding-via-query"></a>
#### クエリによる追加

Eloquentクエリにより、検索インデックスへモデルのコレクションを追加したい場合は、Eloquentクエリに`searchable`メソッドをチェーンします。`searchable`メソッドは、クエリの[結果をチャンクへ分割](/docs/{{version}}/eloquent#chunking-results)し、レコードを検索エンジンへ追加します。この場合も、Scoutでキューを使用する設定をしていれば、キューワーカが全チャンクをバックグランドで追加します。

    // Eloquentクエリにより追加
    App\Models\Order::where('price', '>', 100)->searchable();

    // リレーションにより、レコードを追加することもできる
    $user->orders()->searchable();

    // コレクションにより、追加することもできる
    $orders->searchable();

`searchable`メソッドは"upsert(update+insert)"操作と考えられます。言い換えれば、モデルレコードがインデックスへすでに存在していれば、更新されます。検索エンジンに存在していなければ、インデックスへ追加されます。

<a name="updating-records"></a>
### レコード更新

検索可能モデルを更新するには、モデルインスタンスのプロパティを更新し、`save`でモデルをデータベースへ保存します。Scoutは自動的に変更を検索インデックスへ保存します。

    $order = App\Models\Order::find(1);

    // 注文を更新…

    $order->save();

モデルのコレクションを更新するためにも、Eloquentクエリの`searchable`メソッドを使用します。検索エンジンにモデルが存在していない場合は、作成します。

    // Eloquentクエリによる更新
    App\Models\Order::where('price', '>', 100)->searchable();

    // リレーションによる更新も可能
    $user->orders()->searchable();

    // コレクションによる更新も可能
    $orders->searchable();

<a name="removing-records"></a>
### レコード削除

インデックスからレコードを削除するには、データベースからモデルを`delete`で削除します。この形態による削除は、モデルの[ソフト削除](/docs/{{version}}/eloquent#soft-deleting)と互換性があります。

    $order = App\Models\Order::find(1);

    $order->delete();

レコードを削除する前に、モデルを取得したくない場合は、Eloquentクエリインスタンスかコレクションに対し、`unsearchable`メソッドを使用します。

    // Eloquentクエリによる削除
    App\Models\Order::where('price', '>', 100)->unsearchable();

    // リレーションによる削除も可能
    $user->orders()->unsearchable();

    // コレクションによる削除も可能
    $orders->unsearchable();

<a name="pausing-indexing"></a>
### インデックスの一時停止

Eloquentモデルをバッチ処理するが、検索インデックスへモデルデータを同期したくない場合もときどきあります。`withoutSyncingToSearch`メソッドを使用することで可能です。このメソッドは、即時に実行されるコールバックを１つ引数に取ります。コールバック中のモデル操作は、インデックスへ同期されることはありません。

    App\Models\Order::withoutSyncingToSearch(function () {
        // モデルアクションの実行…
    });

<a name="conditionally-searchable-model-instances"></a>
### 条件付き検索可能モデルインスタンス

特定の条件下でのみ、モデルを検索可能にする必要がある場合も起きるでしょう。たとえば、`App\Models\Post`モデルが、"draft"か"published"の２つのうち、どちらか１つの状態を取ると想像してください。「公開済み:published」のポストのみ検索可能にする必要があります。これを実現するには、モデルに`shouldBeSearchable`メソッドを定義してください。

    public function shouldBeSearchable()
    {
        return $this->isPublished();
    }

`shouldBeSearchable`メソッドは、`save`メソッド、クエリ、リレーションによるモデル操作の場合のみ適用されます。`searchable`メソッドを使用し、直接searchableなモデルかコレクションを作成する場合は、`shouldBeSearchable`メソッドの結果をオーバーライドします。

    // "shouldBeSearchable"が利用される
    App\Models\Order::where('price', '>', 100)->searchable();

    $user->orders()->searchable();

    $order->save();

    // "shouldBeSearchable"はオーバーライドされる
    $orders->searchable();

    $order->searchable();

<a name="searching"></a>
## 検索

`search`メソッドにより、モデルの検索を開始しましょう。`search`メソッドはモデルを検索するために使用する文字列だけを引数に指定します。`get`メソッドを検索クエリにチェーンし、指定した検索クエリに一致するEloquentモデルを取得できます。

    $orders = App\Models\Order::search('Star Trek')->get();

Scoutの検索ではEloquentモデルのコレクションが返されるため、ルートやコントローラから直接結果を返せば、自動的にJSONへ変換されます。

    use Illuminate\Http\Request;

    Route::get('/search', function (Request $request) {
        return App\Models\Order::search($request->search)->get();
    });

Eloquentモデルにより変換される前の、結果をそのまま取得したい場合は、`raw`メソッドを使用してください。

    $orders = App\Models\Order::search('Star Trek')->raw();

検索クエリは通常、モデルの[`searchableAs`](#configuring-model-indexes)メソッドに指定されたインデックスを使い実行されます。しかし、その代わりに検索で使用するカスタムインデックスを`within`メソッドで使用することもできます。

    $orders = App\Models\Order::search('Star Trek')
        ->within('tv_shows_popularity_desc')
        ->get();

<a name="where-clauses"></a>
### Where節

Scoutは検索クエリに対して"WHERE"節を単に追加する方法も提供しています。現在、この節としてサポートしているのは、基本的な数値の一致を確認することだけで、主にIDにより検索クエリを絞り込むために使用します。検索インデックスはリレーショナル・データベースではないため、より上級の"WHERE"節は現在サポートしていません。

    $orders = App\Models\Order::search('Star Trek')->where('user_id', 1)->get();

<a name="pagination"></a>
### ペジネーション

コレクションの取得に付け加え、検索結果を`paginate`メソッドでページづけできます。このメソッドは、`Paginator`インスタンスを返しますので、[Eloquentクエリのペジネーション](/docs/{{version}}/pagination)と同様に取り扱えます。

    $orders = App\Models\Order::search('Star Trek')->paginate();

`paginate`メソッドの第１引数として、各ページごとに取得したいモデル数を指定します。

    $orders = App\Models\Order::search('Star Trek')->paginate(15);

結果が取得できたら、通常のEloquentクエリのペジネーションと同様に、結果を表示し、[Blade](/docs/{{version}}/blade)を使用してページリンクをレンダーできます。

    <div class="container">
        @foreach ($orders as $order)
            {{ $order->price }}
        @endforeach
    </div>

    {{ $orders->links() }}

<a name="soft-deleting"></a>
### ソフトデリート

インデックス付きのモデルが[ソフトデリート](/docs/{{version}}/eloquent#soft-deleting)され、ソフトデリート済みのモデルをサーチする必要がある場合、`config/scout.php`設定ファイルの`soft_delete`オプションを`true`に設定してください。

    'soft_delete' => true,

この設定オプションを`true`にすると、Scoutは検索インデックスからソフトデリートされたモデルを削除しません。代わりに、インデックスされたレコードへ、隠し`__soft_deleted`属性をセットします。これにより、検索時にソフトデリート済みレコードを取得するために、`withTrashed`や`onlyTrashed`メソッドがつかえます。

    // 結果の取得時に、削除済みレコードも含める
    $orders = App\Models\Order::search('Star Trek')->withTrashed()->get();

    // 結果の取得時に、削除済みレコードのみを対象とする
    $orders = App\Models\Order::search('Star Trek')->onlyTrashed()->get();

> {tip} ソフトデリートされたモデルが、`forceDelete`により完全に削除されると、Scoutは自動的に検索インデックスから削除します。

<a name="customizing-engine-searches"></a>
### エンジンの検索のカスタマイズ

エンジンの検索の振る舞いをカスタマイズする必要があれば、`search`メソッドの第２引数にコールパックを渡してください。たとえば、Algoliaへサーチクエリが渡される前に、サーチオプションにgeo-locationデータを追加するために、このコールバックが利用できます。

    use Algolia\AlgoliaSearch\SearchIndex;

    App\Models\Order::search('Star Trek', function (SearchIndex $algolia, string $query, array $options) {
        $options['body']['query']['bool']['filter']['geo_distance'] = [
            'distance' => '1000km',
            'location' => ['lat' => 36, 'lon' => 111],
        ];

        return $algolia->search($query, $options);
    })->get();

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

カスタムエンジンを書いたら、Scoutエンジンマネージャの`extend`メソッドを使用し、Scoutへ登録します。`AppServiceProvider`かアプリケーションで使用している他のサービスプロバイダの`boot`メソッドで、`extend`メソッドを呼び出してください。たとえば、`MySqlSearchEngine`を書いた場合、次のように登録します。

    use Laravel\Scout\EngineManager;

    /**
     * 全アプリケーションサービスの登録
     *
     * @return void
     */
    public function boot()
    {
        resolve(EngineManager::class)->extend('mysql', function () {
            return new MySqlSearchEngine;
        });
    }

エンジンが登録できたら、Scoutのデフォルト`driver`として、`config/scout.php`設定ファイルで設定します。

    'driver' => 'mysql',

<a name="builder-macros"></a>
## ビルダマクロ

カスタムビルダメソッドを定義したい場合は、`Laravel\Scout\Builder`クラスの`macro`メソッドを使用してください。通常、「マクロ」は[サービスプロバイダ](/docs/{{version}}/providers)の`boot`メソッドの中で定義します。

    <?php

    namespace App\Providers;

    use Illuminate\Support\Facades\Response;
    use Illuminate\Support\ServiceProvider;
    use Laravel\Scout\Builder;

    class ScoutMacroServiceProvider extends ServiceProvider
    {
        /**
         * アプリケーションのScoutマクロ登録
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
    }

`macro`関数の最初の引数は、名前を渡します。第２引数はクロージャです。マクロのクロージャは`Laravel\Scout\Builder`実装から、そのマクロ名を呼び出されたときに実行されます。

    App\Models\Order::search('Star Trek')->count();
