# サービスコンテナ

- [イントロダクション](#introduction)
- [結合](#binding)
    - [結合の基礎](#binding-basics)
    - [インターフェイスと実装の結合](#binding-interfaces-to-implementations)
    - [コンテキストによる結合](#contextual-binding)
    - [プリミティブの結合](#binding-primitives)
    - [型指定した可変引数の結合](#binding-typed-variadics)
    - [タグ付け](#tagging)
    - [結合の拡張](#extending-bindings)
- [依存解決](#resolving)
    - [makeメソッド](#the-make-method)
    - [自動注入](#automatic-injection)
- [コンテナイベント](#container-events)
- [PSR-11](#psr-11)

<a name="introduction"></a>
## イントロダクション

Laravelのサービスコンテナは、クラス間の依存を管理する強力な管理ツールです。依存注入というおかしな言葉は主に「コンストラクターか、ある場合には**セッター**メソッドを利用し、あるクラスをそれらに依存しているクラスへ外部から**注入**する」という意味で使われます。

シンプルな例を見てみましょう。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Repositories\UserRepository;
    use App\Models\User;

    class UserController extends Controller
    {
        /**
         * ユーザーリポジトリの実装
         *
         * @var UserRepository
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

        /**
         * 指定ユーザーのプロフィール表示
         *
         * @param  int  $id
         * @return Response
         */
        public function show($id)
        {
            $user = $this->users->find($id);

            return view('user.profile', ['user' => $user]);
        }
    }

この例中で、`UserController`はデータソースからユーザーを取得する必要があります。そのため、ユーザーを取得できるサービスを**注入**しています。このようなコンテキストでは、データベースからユーザー情報を取得するために、ほとんどの場合で[Eloquent](/docs/{{version}}/eloquent)が使われるでしょう。しかしながら、リポジトリは外部から注入されているため、他の実装へ簡単に交換できます。さらに、「モック」することも簡単ですし、アプリケーションのテストで`UserRepository`のダミー実装を作成することもできます。

パワフルで大きなアプリケーションを構築するのと同時に、Laravelコア自体に貢献するためにも、Laravelのサービスコンテナを深く理解することは重要です。

<a name="binding"></a>
## 結合

<a name="binding-basics"></a>
### 結合の基礎

ほとんどのサービスコンテナの結合は、[サービスプロバイダ](/docs/{{version}}/providers)の中で行われています。そのため、ほとんどの例はコンテナ中で使用される状況をデモンストレートしています。

> {tip} インターフェイスに依存していないのであれば、コンテナでクラスを結合する必要はありません。コンテナにオブジェクトを結合する方法を指示する必要はなく、リフレクションを使用してそのオブジェクトを自動的に依存解決します。

<a name="simple-bindings"></a>
#### シンプルな結合

サービスプロバイダの中からは、いつでも`$this->app`プロパティにより、コンテナへアクセスできます。`bind`メソッドへ登録したいクラス名かインターフェイス名と、クラスのインスタンスを返す「クロージャ」を引数として渡せば、結合を登録できます。

    $this->app->bind('HelpSpot\API', function ($app) {
        return new \HelpSpot\API($app->make('HttpClient'));
    });

コンテナ自身がリゾルバの引数として渡されることに注目してください。これで構築中の依存を解決するためにも、コンテナを利用できます。

<a name="binding-a-singleton"></a>
#### シングルトン結合

`singleton`メソッドは、クラスやインターフェイスが一度だけ依存解決されるようにコンテナに登録します。一度シングルトン結合が解決されるとそれ以降、この結合が参照されるたび、コンテナは同じオブジェクトインスタンスを返します。

    $this->app->singleton('HelpSpot\API', function ($app) {
        return new \HelpSpot\API($app->make('HttpClient'));
    });

<a name="binding-instances"></a>
#### インスタンス結合

すでに存在するオブジェクトのインスタンスを`instance`メソッドを用いて、コンテナに結合することもできます。指定されたインスタンスが、以降のコンテナで呼び出されるたびに返されます。

    $api = new \HelpSpot\API(new HttpClient);

    $this->app->instance('HelpSpot\API', $api);

<a name="binding-interfaces-to-implementations"></a>
### インターフェイスと実装の結合

サービスコンテナーのとても強力な機能は、インターフェイスを指定された実装に結合できることです。たとえば`EventPusher`インターフェイスと`RedisEventPusher`実装があるとしましょう。このインターフェイスの`RedisEventPusher`を実装し終えたら、以下のようにサービスコンテナに登録できます。

    $this->app->bind(
        'App\Contracts\EventPusher',
        'App\Services\RedisEventPusher'
    );

上記の例は、`EventPusher`の実装クラスが必要な時に、コンテナが`RedisEventPusher`を注入するという意味です。ではコンストラクタか、もしくはサービスコンテナが依存を注入できる場所で、`EventPusher`インターフェイスをタイプヒントで指定してみましょう。

    use App\Contracts\EventPusher;

    /**
     * 新しいインスタンスの生成
     *
     * @param  EventPusher  $pusher
     * @return void
     */
    public function __construct(EventPusher $pusher)
    {
        $this->pusher = $pusher;
    }

<a name="contextual-binding"></a>
### コンテキストによる結合

時には、同じインターフェイスを使用した２つのクラスがあり、クラスごとに異なった実装を注入しなくてはならない場合もあるでしょう。たとえば、２つのコントローラが異なった`Illuminate\Contracts\Filesystem\Filesystem`[契約](/docs/{{version}}/contracts)の実装に依存している場合です。Laravelでは、このような振る舞いの定義をシンプルで、読み書きしやすくしています。

    use App\Http\Controllers\PhotoController;
    use App\Http\Controllers\UploadController;
    use App\Http\Controllers\VideoController;
    use Illuminate\Contracts\Filesystem\Filesystem;
    use Illuminate\Support\Facades\Storage;

    $this->app->when(PhotoController::class)
              ->needs(Filesystem::class)
              ->give(function () {
                  return Storage::disk('local');
              });

    $this->app->when([VideoController::class, UploadController::class])
              ->needs(Filesystem::class)
              ->give(function () {
                  return Storage::disk('s3');
              });

<a name="binding-primitives"></a>
### プリミティブの結合

注入したクラスをいくつか受け取るクラスが、整数などのプリミティブ値を注入で受け取る必用があることも起きるでしょう。 コンテキスト結合を使用すれば、クラスに必要などんな値も簡単に注入できます。

    $this->app->when('App\Http\Controllers\UserController')
              ->needs('$variableName')
              ->give($value);

クラスが[タグ付けした](#tagging)インスタンスの配列に依存することもときどき起きます。`giveTagged`メソッドを使用すれば、タグ付けしたコンテナ結合をすべて簡単に注入できます。

    $this->app->when(ReportAggregator::class)
        ->needs('$reports')
        ->giveTagged('reports');

<a name="binding-typed-variadics"></a>
### 型指定した可変引数の結合

コンストラクタの可変引数を使用して、型指定したオブジェクトの配列を受け取るクラスもあるでしょう。

    class Firewall
    {
        protected $logger;
        protected $filters;

        public function __construct(Logger $logger, Filter ...$filters)
        {
            $this->logger = $logger;
            $this->filters = $filters;
        }
    }

コンテキスト結合を使用し、`Filter`インスタンスの配列を返すクロージャを`give`メソッドに渡せば、この依存を解決できます。

    $this->app->when(Firewall::class)
              ->needs(Filter::class)
              ->give(function ($app) {
                    return [
                        $app->make(NullFilter::class),
                        $app->make(ProfanityFilter::class),
                        $app->make(TooLongFilter::class),
                    ];
              });

`Firewall`が`Filter`インスタンスを必用とするときに、コンテナに依存解決して欲しいクラス名の配列を渡すことも、利便性を上げるために可能です。

    $this->app->when(Firewall::class)
              ->needs(Filter::class)
              ->give([
                  NullFilter::class,
                  ProfanityFilter::class,
                  TooLongFilter::class,
              ]);

<a name="variadic-tag-dependencies"></a>
#### Variadic Tag Dependencies可変長タグ依存

クラスが`Report ...$reports`のようにタイプヒントにより、特定のクラスに対して可変の依存を持つことがあります。`needs`と`giveTagged`メソッドを使ってください。指定した依存への[タグ](#tagging)により、すべてのコンテナ結合を簡単に依存注入できます。

    $this->app->when(ReportAggregator::class)
        ->needs(Report::class)
        ->giveTagged('reports');

<a name="tagging"></a>
### タグ付け

一連の「カテゴリー」の結合を全部解決する必要がある場合も存在するでしょう。たとえば、異なった多くの`Report`インターフェイスの実装配列を受け取る、レポート収集プログラム(aggregator)を構築しているとしましょう。`Report`の実装を登録後、それらを`tag`メソッドでタグ付けできます。

    $this->app->bind('SpeedReport', function () {
        //
    });

    $this->app->bind('MemoryReport', function () {
        //
    });

    $this->app->tag(['SpeedReport', 'MemoryReport'], 'reports');

サービスにタグを付けてしまえば、`tagged`メソッドで簡単に全部解決できます。

    $this->app->bind('ReportAggregator', function ($app) {
        return new ReportAggregator($app->tagged('reports'));
    });

<a name="extending-bindings"></a>
### 結合の拡張

`extend`メソッドでサービスの解決結果を修正できます。たとえば、あるサービスが解決されたときに、そのサービスをデコレート、もしくは設定するために追加のコードを実行できます。`extend`メソッドは唯一引数としてクロージャを受け取り、修正したサービスを返します。クロージャは依存解決されたサービスとコンテナインスタンスを受け取ります。

    $this->app->extend(Service::class, function ($service, $app) {
        return new DecoratedService($service);
    });

<a name="resolving"></a>
## 依存解決

<a name="the-make-method"></a>
#### `make`メソッド

コンテナによりクラスインスタンスを依存解決する場合は、`make`メソッドを使います。`make`メソッドには、依存解決したいクラスかインターフェイスの名前を引数として渡します。

    $api = $this->app->make('HelpSpot\API');

もし、`$app`変数へアクセスできない場所で依存解決したい場合は、グローバルな`resolve`ヘルパが使えます。

    $api = resolve('HelpSpot\API');

依存しているクラスが、コンテナにより解決できない場合は、`makeWith`メソッドへ連想配列を渡すことにより注入できます。

    $api = $this->app->makeWith('HelpSpot\API', ['id' => 1]);

<a name="automatic-injection"></a>
#### 自動注入

一番重要な依存解決方法は、コンテナによる依存解決が行われるクラスのコンストラクタで、シンプルに依存を「タイプヒント」で記述するやりかたです。これは[コントローラ](/docs/{{version}}/controllers)、[イベントリスナ](/docs/{{version}}/events)、[ミドルウェア](/docs/{{version}}/middleware)などで利用できます。さらに、[キュージョブ](/docs/{{version}}/queues)の`handle`メソッドでも、依存をタイプヒントで指定できます。実践において、コンテナによりオブジェクトの解決が行われるのは、これが一番多くなります。

たとえば、コントローラのコンストラクタで、アプリケーションにより定義されたリポジトリをタイプヒントしてみましょう。このリポジトリは、自動的に依存解決され、クラスへ注入されます。

    <?php

    namespace App\Http\Controllers;

    use App\Models\Users\Repository as UserRepository;

    class UserController extends Controller
    {
        /**
         * Userリポジトリインスタンス
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

        /**
         * 指定されたIDのユーザー表示
         *
         * @param  int  $id
         * @return Response
         */
        public function show($id)
        {
            //
        }
    }

<a name="container-events"></a>
## コンテナイベント

コンテナはオブジェクトの依存解決時に毎回イベントを発行します。このイベントは、`resolving`を使用して購読できます。

    $this->app->resolving(function ($object, $app) {
        // どんなタイプのオブジェクトをコンテナが解決した場合でも呼び出される
    });

    $this->app->resolving(\HelpSpot\API::class, function ($api, $app) {
        // "HelpSpot\API"クラスのオブジェクトをコンテナが解決した場合に呼び出される
    });

ご覧の通り、依存解決対象のオブジェクトがコールバックに渡され、最終的に取得元へ渡される前に追加でオブジェクトのプロパティをセットできます。

<a name="psr-11"></a>
## PSR-11

Laravelのサービスコンテナは、[PSR-11](https://github.com/php-fig/fig-standards/blob/master/accepted/PSR-11-container.md)インターフェイスを持っています。これにより、Laravelコンテナのインスタンスを取得するために、PSR-11コンテナインターフェイスをタイプヒントで指定できます。

    use Psr\Container\ContainerInterface;

    Route::get('/', function (ContainerInterface $container) {
        $service = $container->get('Service');

        //
    });

指定された識別子を解決できない場合は例外が投げられます。識別子に何も結合されていない場合は、`Psr\Container\NotFoundExceptionInterface`のインスタンスが例外として投げられます。識別子が結合されているが、依存解決できない場合は、`Psr\Container\ContainerExceptionInterface`のインスタンスが投げられます。
