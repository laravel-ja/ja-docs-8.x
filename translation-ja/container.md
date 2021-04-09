# サービスコンテナ

- [イントロダクション](#introduction)
    - [設定なしの依存解決](#zero-configuration-resolution)
    - [いつコンテナを使用するか](#when-to-use-the-container)
- [結合](#binding)
    - [結合の基本](#binding-basics)
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

Laravelサービスコンテナは、クラスの依存関係を管理し、依存注入を実行するための強力なツールです。依存の注入は、本質的にこれを意味する派手なフレーズです。クラスの依存は、コンストラクターまたは場合によっては「セッター」メソッドを介してクラスに「注入」されます。

簡単な例を見てみましょう。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Repositories\UserRepository;
    use App\Models\User;

    class UserController extends Controller
    {
        /**
         * Userリポジトリの実装
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
         * 指定ユーザーのプロファイル表示
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

この例では、`UserController`はデータソースからユーザーを取得する必要があります。そのため、ユーザーを取得できるサービスを**注入**します。このコンテキストでは、`UserRepository`はおそらく[Eloquent](/docs/{{version}}/eloquent)を使用してデータベースからユーザー情報を取得します。しかし、リポジトリが挿入されているため、別の実装と簡単に交換可能です。また、アプリケーションをテストするときに、「UserRepository」のダミー実装を簡単に「モック」または作成することもできます。

Laravelサービスコンテナを深く理解することは、強力で大規模なアプリケーションを構築するため、およびLaravelコア自体に貢献するために不可欠です。

<a name="zero-configuration-resolution"></a>
### 設定なしの依存解決

クラスに依存関係がない場合、または他の具象クラス(インターフェイスではない)のみに依存している場合、そのクラスを依存解決する方法をコンテナへ指示する必要はありません。たとえば、以下のコードを`routes/web.php`ファイルに配置できます。

    <?php

    class Service
    {
        //
    }

    Route::get('/', function (Service $service) {
        die(get_class($service));
    });

この例でアプリケーションの`/`ルートを訪問すれば、自動的に`Service`クラスが依存解決され、ルートのハンドラに依存挿入されます。これは大転換です。これは、アプリケーションの開発において、肥大化する設定ファイルの心配をせず依存注入を利用できることを意味します。

幸いに、Laravelアプリケーションを構築するときに作成するクラスの多くは、[コントローラ](/docs/{{version}}/controllers)、[イベントリスナ](/docs/{{version}}/events)、[ミドルウェア](/docs/{{version}}/middleware)などの`handle`メソッドにより依存関係を注入ができます。設定なしの自動的な依存注入の力を味わったなら、これなしに開発することは不可能だと思うことでしょう。

<a name="when-to-use-the-container"></a>
### いつコンテナを使用するか

ありがたいことに依存解決の設定がいらないため、ルート、コントローラ、イベントリスナ、その他どこでも、コンテナを手動で操作しなくても、依存関係を頻繁にタイプヒントするでしょう。たとえば、現在のリクエストに簡単にアクセスできるように、ルート定義で`Illuminate\Http\Request`オブジェクトをタイプヒントできます。このコードを書くため、コンテナーを操作する必要はありません。コンテナーはこうした依存関係の注入をバックグラウンドで管理しています。

    use Illuminate\Http\Request;

    Route::get('/', function (Request $request) {
        // ...
    });

多くの場合、自動依存注入と[ファサード](/docs/{{version}}/facades)のおかげで、コンテナーから手動でバインドしたり依存解決したりすることなく、Laravelアプリケーションを構築できます。**では、いつ手動でコンテナを操作するのでしょう？**２つの状況を調べてみましょう。

第１に、インターフェイスを実装するクラスを作成し、そのインターフェイスをルートまたはクラスコンストラクターで型指定する場合は、[コンテナーにそのインターフェイスを解決する方法を指示する](#binding-interfaces-to-implementations)必要があります。第２に、他のLaravel開発者と共有する予定の[Laravelパッケージの作成](/docs/{{version}}/packages)の場合、パッケージのサービスをコンテナーにバインドする必要がある場合があります。

<a name="binding"></a>
## 結合

<a name="binding-basics"></a>
### 結合の基本

<a name="simple-bindings"></a>
#### シンプルな結合

ほとんどすべてのサービスコンテナ結合は[サービスプロバイダ](/docs/{{version}}/provider)内で登録されるため、こうした例のほとんどは、この状況でのコンテナの使用法になります。

サービスプロバイダ内では、常に`$this->app`プロパティを介してコンテナにアクセスできます。`bind`メソッドを使用して結合を登録しできます。登録するクラスまたはインターフェイス名を、クラスのインスタンスを返すクロージャとともに渡します。

    use App\Services\Transistor;
    use App\Services\PodcastParser;

    $this->app->bind(Transistor::class, function ($app) {
        return new Transistor($app->make(PodcastParser::class));
    });

リゾルバの引数としてコンテナ自体を受け取ることに注意してください。そのコンテナを使用して、構築中のオブジェクトの依存関係を解決できるのです。

前述のように、通常はサービスプロバイダ内のコンテナーの中で操作します。ただし、サービスプロバイダの外部でコンテナーとやり取りする場合は、`App`[ファサード](/docs/{{version}}/facades)を用いて操作します。

    use App\Services\Transistor;
    use Illuminate\Support\Facades\App;

    App::bind(Transistor::class, function ($app) {
        // ...
    });

> {tip} クラスがどのインターフェイスにも依存しない場合、クラスをコンテナーにバインドする必要はありません。コンテナは、リフレクションを使用してこれらのオブジェクトを自動的に解決できるため、これらのオブジェクトの作成方法を指示する必要はありません。

<a name="binding-a-singleton"></a>
#### シングルトンの結合

`singleton`メソッドは、クラスまたはインターフェイスをコンテナーにバインドしますが、これは１回のみ依存解決される必要がある結合です。シングルトン結合が依存解決されたら、コンテナに対する後続の呼び出しで、同じオブジェクトインスタンスが返されます。

    use App\Services\Transistor;
    use App\Services\PodcastParser;

    $this->app->singleton(Transistor::class, function ($app) {
        return new Transistor($app->make(PodcastParser::class));
    });

<a name="binding-instances"></a>
#### インスタンスの結合

`instance`メソッドを使用して、既存のオブジェクトインスタンスをコンテナへ結合することもできます。指定したインスタンスは、コンテナに対する後続の呼び出しで常に返されます。

    use App\Services\Transistor;
    use App\Services\PodcastParser;

    $service = new Transistor(new PodcastParser);

    $this->app->instance(Transistor::class, $service);

<a name="binding-interfaces-to-implementations"></a>
### インターフェイスと実装の結合

サービスコンテナの非常に強力な機能は、インターフェイスを特定の実装に結合する機能です。たとえば、`EventPusher`インターフェイスと`RedisEventPusher`実装があると仮定しましょう。このインターフェイスの`RedisEventPusher`実装をコーディングしたら、次のようにサービスコンテナーに登録できます。

    use App\Contracts\EventPusher;
    use App\Services\RedisEventPusher;

    $this->app->bind(EventPusher::class, RedisEventPusher::class);

この文は、クラスが`EventPusher`の実装を必要とするときに、`RedisEventPusher`を注入する必要があることをコンテナーに伝えています。これで、コンテナーにより依存解決されるクラスのコンストラクタで`EventPusher`インターフェイスをタイプヒントできます。Laravelアプリケーション内のコントローラ、イベントリスナ、ミドルウェア、およびその他のさまざまなタイプのクラスは、常にコンテナを使用して解決されることを忘れないでください。

    use App\Contracts\EventPusher;

    /**
     * 新しいクラスインスタンスの生成
     *
     * @param  \App\Contracts\EventPusher  $pusher
     * @return void
     */
    public function __construct(EventPusher $pusher)
    {
        $this->pusher = $pusher;
    }

<a name="contextual-binding"></a>
### コンテキストによる結合

同じインターフェイスを利用する２つのクラスがある場合、各クラスに異なる実装を依存注入したい場合があります。たとえば、２つのコントローラは、`Illuminate\Contracts\Filesystem\Filesystem`[契約](/docs/{{version}}/Contracts)の異なる実装に依存する場合があります。Laravelは、この動作を定義するためのシンプルで流暢なインターフェイスを提供します。

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

注入されたクラスを受け取るだけでなく、整数などのプリミティブ値も注入され、受け取るクラスがときにはあるでしょう。コンテキストによる結合を使用して、クラスへ必要な値を簡単に依存注入できます。

    $this->app->when('App\Http\Controllers\UserController')
              ->needs('$variableName')
              ->give($value);

クラスが[タグ付き](#tagging)インスタンスの配列へ依存する場合があります。`giveTagged`メソッドを使用すると、そのタグを使用してすべてのコンテナバインディングを簡単に挿入できます。

    $this->app->when(ReportAggregator::class)
        ->needs('$reports')
        ->giveTagged('reports');

アプリケーションの設定ファイルの１つから値を注入する必要がある場合は、`giveConfig`メソッドを使用します。

    $this->app->when(ReportAggregator::class)
        ->needs('$timezone')
        ->giveConfig('app.timezone');

<a name="binding-typed-variadics"></a>
### 型指定した可変引数の結合

時折、可変コンストラクター引数を使用して型付きオブジェクトの配列を受け取るクラスが存在する場合があります。

    <?php

    use App\Models\Filter;
    use App\Services\Logger;

    class Firewall
    {
        /**
         * ロガーインスタンス
         *
         * @var \App\Services\Logger
         */
        protected $logger;

        /**
         * フィルタインスタンス
         *
         * @var array
         */
        protected $filters;

        /**
         * 新しいクラスインスタンスの生成
         *
         * @param  \App\Services\Logger  $logger
         * @param  array  $filters
         * @return void
         */
        public function __construct(Logger $logger, Filter ...$filters)
        {
            $this->logger = $logger;
            $this->filters = $filters;
        }
    }

文脈による結合を使用すると、依存解決した`Filter`インスタンスの配列を返すクロージャを`give`メソッドへ渡すことで、この依存関係を解決できます。

    $this->app->when(Firewall::class)
              ->needs(Filter::class)
              ->give(function ($app) {
                    return [
                        $app->make(NullFilter::class),
                        $app->make(ProfanityFilter::class),
                        $app->make(TooLongFilter::class),
                    ];
              });

利便性のため、いつでも`Firewall`が`Filter`インスタンスを必要とするときは、コンテナが解決するクラス名の配列も渡せます。

    $this->app->when(Firewall::class)
              ->needs(Filter::class)
              ->give([
                  NullFilter::class,
                  ProfanityFilter::class,
                  TooLongFilter::class,
              ]);

<a name="variadic-tag-dependencies"></a>
#### 可変引数タグの依存

クラスには、特定のクラスとしてタイプヒントされた可変引数の依存関係を持つ場合があります(`Report ...$reports`)。`needs`メソッドと`giveTagged`メソッドを使用すると、特定の依存関係に対して、その[tag](#tagging)を使用してすべてのコンテナー結合を簡単に挿入できます。

    $this->app->when(ReportAggregator::class)
        ->needs(Report::class)
        ->giveTagged('reports');

<a name="tagging"></a>
### タグ付け

場合により、特定の結合「カテゴリ」をすべて依存解決する必要が起きます。たとえば、さまざまな`Report`インターフェイス実装の配列を受け取るレポートアナライザを構築しているとしましょう。`Report`実装を登録した後、`tag`メソッドを使用してそれらにタグを割り当てられます。

    $this->app->bind(CpuReport::class, function () {
        //
    });

    $this->app->bind(MemoryReport::class, function () {
        //
    });

    $this->app->tag([CpuReport::class, MemoryReport::class], 'reports');

サービスにタグ付けしたら、コンテナの`tagged`メソッドを使用して簡単にすべてを依存解決できます。

    $this->app->bind(ReportAnalyzer::class, function ($app) {
        return new ReportAnalyzer($app->tagged('reports'));
    });

<a name="extending-bindings"></a>
### 結合の拡張

`extend`メソッドを使用すると、依存解決済みのサービスを変更できます。たとえば、サービスを依存解決した後、追加のコードを実行してサービスをデコレートまたは設定できます。`extend`メソッドは唯一クロージャを引数に取ります。このクロージャは新しく変更するサービスを返す必要があります。このクロージャは解決するサービスとコンテナーインスタンスを引数に受け取ります。

    $this->app->extend(Service::class, function ($service, $app) {
        return new DecoratedService($service);
    });

<a name="resolving"></a>
## 依存解決

<a name="the-make-method"></a>
### `make`メソッド

`make`メソッドを使用して、コンテナからクラスインスタンスを解決します。`make`メソッドは、解決したいクラスまたはインターフェイスの名前を受け入れます。

    use App\Services\Transistor;

    $transistor = $this->app->make(Transistor::class);

クラスの依存関係の一部がコンテナを介して解決できない場合は、それらを連想配列として`makeWith`メソッドに渡すことでそれらを依存注入できます。たとえば、`Transistor`サービスに必要な`$id`コンストラクタ引数を手動で渡すことができます。

    use App\Services\Transistor;

    $transistor = $this->app->makeWith(Transistor::class, ['id' => 1]);

サービスプロバイダの外部で、`$app`変数にアクセスできないコードの場所では、`App`　[ファサード](/docs/{{version}}/facades)を使用してコンテナからクラスインスタンスを依存解決します。

    use App\Services\Transistor;
    use Illuminate\Support\Facades\App;

    $transistor = App::make(Transistor::class);

Laravelコンテナインスタンス自体をコンテナにより解決中のクラスへ依存注入したい場合は、クラスのコンストラクタで`Illuminate\Container\Container`クラスを入力してください。

    use Illuminate\Container\Container;

    /**
     * 新しいクラスインスタンスの生成
     *
     * @param  \Illuminate\Container\Container  $container
     * @return void
     */
    public function __construct(Container $container)
    {
        $this->container = $container;
    }

<a name="automatic-injection"></a>
### 自動注入

あるいは、そして重要なことに、[コントローラ](/docs/{{version}}/controllers)、[イベントリスナ](/docs/{{version}}/events)、[ミドルウェア](/docs/{{version}}/middleware)など、コンテナにより解決されるクラスのコンストラクターでは、依存関係をタイプヒントすることができます。さらに、[キュー投入するジョブ](/docs/{{version}}/queues)の`handle`メソッドでも、依存関係をタイプヒントできます。実践的に、ほとんどのオブジェクトはコンテナにより解決されるべきでしょう。

たとえば、コントローラのコンストラクタでアプリケーションが定義したリポジトリをタイプヒントすることができます。リポジトリは自動的に解決され、クラスに依存注入されます。

    <?php

    namespace App\Http\Controllers;

    use App\Repositories\UserRepository;

    class UserController extends Controller
    {
        /**
         * Userリポジトリインスタンス
         *
         * @var \App\Repositories\UserRepository
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

        /**
         * 指定したIDのユーザーを表示
         *
         * @param  int  $id
         * @return \Illuminate\Http\Response
         */
        public function show($id)
        {
            //
        }
    }

<a name="container-events"></a>
## コンテナイベント

サービスコンテナは、オブジェクトを依存解決するたびにイベントを発生させます。`resolving`メソッドを使用してこのイベントをリッスンできます。

    use App\Services\Transistor;

    $this->app->resolving(Transistor::class, function ($transistor, $app) {
        // コンテナがTransistorタイプのオブジェクトを解決するときに呼び出される
    });

    $this->app->resolving(function ($object, $app) {
        // コンテナが任意のタイプのオブジェクトを解決するときに呼び出される
    });

ご覧のとおり、解決しているオブジェクトがコールバックに渡され、利用側に渡される前にオブジェクトへ追加のプロパティを設定できます。

<a name="psr-11"></a>
## PSR-11

Laravelのサービスコンテナは、[PSR-11](https://github.com/php-fig/fig-standards/blob/master/accepted/PSR-11-container.md)インターフェイスを実装しています。したがって、PSR-11コンテナインターフェイスをタイプヒントして、Laravelコンテナのインスタンスを取得できます。

    use App\Services\Transistor;
    use Psr\Container\ContainerInterface;

    Route::get('/', function (ContainerInterface $container) {
        $service = $container->get(Transistor::class);

        //
    });

指定した識別子を解決できない場合は例外を投げます。識別子が結合されなかった場合、例外は`Psr\Container\NotFoundExceptionInterface`のインスタンスです。識別子が結合されているが依存解決できなかった場合、`Psr\Container\ContainerExceptionInterface`のインスタンスを投げます。
