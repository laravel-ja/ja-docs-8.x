# イベント

- [イントロダクション](#introduction)
- [イベント／リスナ登録](#registering-events-and-listeners)
    - [イベント／リスナ生成](#generating-events-and-listeners)
    - [任意のイベント登録](#manually-registering-events)
    - [イベントディスカバリ](#event-discovery)
- [イベント定義](#defining-events)
- [リスナ定義](#defining-listeners)
- [イベントリスナのキュー投入](#queued-event-listeners)
    - [キューへの任意アクセス](#manually-accessing-the-queue)
    - [失敗したジョブの取り扱い](#handling-failed-jobs)
- [イベントの発行](#dispatching-events)
- [イベント購読](#event-subscribers)
    - [イベント購読プログラミング](#writing-event-subscribers)
    - [イベント購読登録](#registering-event-subscribers)

<a name="introduction"></a>
## イントロダクション

Laravelのイベントはシンプルなオブザーバの実装で、アプリケーションで発生するさまざまなイベントを購読し、リッスンするために使用します。イベントクラスは通常、`app/Events`ディレクトリに保存されます。一方、リスナは`app/Listeners`ディレクトリへ保存されます。アプリケーションに両ディレクトリが存在しなくても、心配ありません。Artisanコンソールコマンドを使い、イベントとリスナを生成するとき、ディレクトリも生成されます。

一つのイベントは、互いに依存していない複数のリスナに紐付けられますので、アプリケーションのさまざまな要素を独立させるための良い手段として活用できます。たとえば、注文を配送するごとにSlack通知をユーザーへ届けたいとします。注文の処理コードとSlackの通知コードを結合する代わりに、`OrderShipped`イベントを発行し、リスナがそれを受け取り、Slack通知へ変換するように実装できます。

<a name="registering-events-and-listeners"></a>
## イベント／リスナ登録

Laravelアプリケーションに含まれている`EventServiceProvider`は、イベントリスナを全部登録するために便利な場所を提供しています。`listen`プロパティは全イベント（キー）とリスナ（値）で構成されている配列です。アプリケーションで必要とされているイベントをこの配列に好きなだけ追加できます。例として、`OrderShipped`イベントを追加してみましょう。

    /**
     * アプリケーションのイベントリスナをマップ
     *
     * @var array
     */
    protected $listen = [
        'App\Events\OrderShipped' => [
            'App\Listeners\SendShipmentNotification',
        ],
    ];

<a name="generating-events-and-listeners"></a>
### イベント／リスナ生成

毎回ハンドラやリスナを作成するのは、当然のことながら手間がかかります。代わりにハンドラとリスナを`EventServiceProvider`に追加し、`event:generate`コマンドを使いましょう。このコマンドは`EventServiceProvider`にリストしてあるイベントやリスナを生成してくれます。既存のイベントとハンドラには、変更を加えません。

    php artisan event:generate

<a name="manually-registering-events"></a>
### イベントの手動登録

通常イベントは、`EventServiceProvider`の`$listen`配列により登録するべきです。しかし、`EventServiceProvider`の`boot`メソッドの中で、クロージャベースリスナを登録できます。

    use App\Events\PodcastProcessed;

    /**
     * アプリケーションの他のイベントを登録する
     *
     * @return void
     */
    public function boot()
    {
        Event::listen(function (PodcastProcessed $event) {
            //
        });
    }

<a name="queuable-anonymous-event-listeners"></a>
#### Queueable Anonymous Event Listeners

When registering evnet listeners manually, you may wrap the listener Closure within the `Illuminate\Events\queueable` function to instruct Laravel to execute the listener using the [queue](/docs/{{version}}/queues):

    use App\Events\PodcastProcessed;
    use function Illuminate\Events\queueable;
    use Illuminate\Support\Facades\Event;

    /**
     * アプリケーションの他のイベントを登録する
     *
     * @return void
     */
    public function boot()
    {
        Event::listen(queueable(function (PodcastProcessed $event) {
            //
        }));
    }

Like queued jobs, you may use the `onConnection`, `onQueue`, and `delay` methods to customize the execution of the queued listener:

    Event::listen(queueable(function (PodcastProcessed $event) {
        //
    })->onConnection('redis')->onQueue('podcasts')->delay(now()->addSeconds(10)));

If you would like to handle anonymous queued listener failures, you may provide a Closure to the `catch` method while defining the `queueable` listener:

    use App\Events\PodcastProcessed;
    use function Illuminate\Events\queueable;
    use Illuminate\Support\Facades\Event;
    use Throwable;

    Event::listen(queueable(function (PodcastProcessed $event) {
        //
    })->catch(function (PodcastProcessed $event, Throwable $e) {
        // The queued listener failed...
    }));

#### ワイルドカードリスナ

登録したリスナが、`*`をワイルドカードパラメータとして使用している場合、同じリスナで複数のイベントを捕捉できます。ワイルドカードリスナは、イベント全体のデータ配列を最初の引数として、イベントデータ全体を第２引数として受け取ります。

    Event::listen('event.*', function ($eventName, array $data) {
        //
    });

<a name="event-discovery"></a>
### イベントディスカバリ

`EventServiceProvider`の`$listen`配列へ、自分でイベントとリスナを登録する代わりに、自動的にイベントを検出させることができます。イベントディスカバリを有効にすると、Laravelはアプリケーションの`Listeners`ディレクトリをスキャンし、自動的にイベントとリスナを見つけ出して登録します。さらに、`EventServiceProvider`で明示的に定義されたイベントリストも今まで通りに登録します。

Laravelはリフレクションを使いリスナクラスをスキャンし、イベントリスナを見つけます。Laravelは`handle`で始まるイベントリスナクラスメソッドを見つけると、そのメソッド引数のタイプヒントで示すイベントに対する、イベントリスナとしてメソッドを登録します。

    use App\Events\PodcastProcessed;

    class SendPodcastProcessedNotification
    {
        /**
         * 指定イベントの処理
         *
         * @param  \App\Events\PodcastProcessed
         * @return void
         */
        public function handle(PodcastProcessed $event)
        {
            //
        }
    }

イベントディスカバリはデフォルトで無効になっています。アプリケーションの`EventServiceProvider`にある`shouldDiscoverEvents`をオーバーライドすることで、有効にできます。

    /**
     * イベントとリスナを自動的に検出するか指定
     *
     * @return bool
     */
    public function shouldDiscoverEvents()
    {
        return true;
    }

アプリケーションのListenersディレクトリ中の全リスナが、デフォルトでスキャンされます。スキャンする追加のディレクトリを定義したい場合は、`EventServiceProvider`の`discoverEventsWithin`をオーバーライドしてください。

    /**
     * イベントを見つけるために使用するリスナディレクトリの取得
     *
     * @return array
     */
    protected function discoverEventsWithin()
    {
        return [
            $this->app->path('Listeners'),
        ];
    }

実働時はリクエストのたびに、すべてのリスナをフレームワークにスキャンさせるのは好ましくないでしょう。アプリケーションのイベントとリスナの全目録をキャッシュする、`event:cache` Artisanコマンドを実行すべきです。この目録はフレームワークによるイベント登録処理をスピードアップするために使用されます。`event:clear`コマンドにより、このキャッシュは破棄されます。

> {tip} `event:list`コマンドで、アプリケーションに登録されたすべてのイベントとリスナを一覧表示できます。

<a name="defining-events"></a>
## イベント定義

イベントクラスはデータコンテナとして、イベントに関する情報を保持します。たとえば生成した`OrderShipped`イベントが[Eloquent ORM](/docs/{{version}}/eloquent)オブジェクトを受け取るとしましょう。

    <?php

    namespace App\Events;

    use App\Models\Order;
    use Illuminate\Broadcasting\InteractsWithSockets;
    use Illuminate\Foundation\Events\Dispatchable;
    use Illuminate\Queue\SerializesModels;

    class OrderShipped
    {
        use Dispatchable, InteractsWithSockets, SerializesModels;

        public $order;

        /**
         * 新しいイベントインスタンスの生成
         *
         * @param  \App\Models\Order  $order
         * @return void
         */
        public function __construct(Order $order)
        {
            $this->order = $order;
        }
    }

ご覧の通り、このクラスはロジックを含みません。購入された`Order`オブジェクトのための、コンテナです。イベントオブジェクトがPHPの`serialize`関数でシリアライズされる場合でも、Eloquentモデルをイベントがuseしている`SerializesModels`トレイトが優雅にシリアライズします。

<a name="defining-listeners"></a>
## リスナの定義

次にサンプルイベントのリスナを取り上げましょう。イベントリスナはイベントインスタンスを`handle`メソッドで受け取ります。`event:generate`コマンドは自動的に適切なイベントクラスをインポートし、`handle`メソッドのイベントのタイプヒントを指定します。そのイベントに対応するため必要なロジックを`handle`メソッドで実行してください。

    <?php

    namespace App\Listeners;

    use App\Events\OrderShipped;

    class SendShipmentNotification
    {
        /**
         * イベントリスナ生成
         *
         * @return void
         */
        public function __construct()
        {
            //
        }

        /**
         * イベントの処理
         *
         * @param  \App\Events\OrderShipped  $event
         * @return void
         */
        public function handle(OrderShipped $event)
        {
            // $event->orderにより、注文へアクセス…
        }
    }

> {tip} イベントリスナでも、必要な依存をコンストラクターのタイプヒントで指定できます。イベントリスナはすべてLaravelの[サービスコンテナで](/docs/{{version}}/container)依存解決されるので、依存は自動的に注入されます。

#### イベントの伝播の停止

場合によりイベントが他のリスナへ伝播されるのを止めたいこともあります。その場合は`handle`メソッドから`false`を返してください。

<a name="queued-event-listeners"></a>
## イベントリスナのキュー投入

メール送信やHTTPリクエストを作成するなど、遅い仕事を担当する場合、そのリスナをキューイングできると便利です。キューリスナへ取り掛かる前に、[キューの設定](/docs/{{version}}/queues)を確実に行い、サーバかローカル開発環境でキューリスナを起動しておいてください。

リスナをキュー投入するように指定するには、`ShouldQueue`インターフェイスをリスナクラスに追加します。`event:generate` Artisanコマンドにより生成したリスナには、すでにこのインターフェイスが現在の名前空間下にインポートされていますので、すぐに使用できます。

    <?php

    namespace App\Listeners;

    use App\Events\OrderShipped;
    use Illuminate\Contracts\Queue\ShouldQueue;

    class SendShipmentNotification implements ShouldQueue
    {
        //
    }

これだけです！これでこのリスナがイベントのために呼び出されると、Laravelの[キューシステム](/docs/{{version}}/queues)を使い、イベントデスパッチャーにより自動的にキューへ投入されます。キューにより実行されるリスナから例外が投げられなければ、そのキュージョブは処理が済み次第、自動的に削除されます。

#### キュー接続とキュー名のカスタマイズ

イベントリスナのキュー接続とキュー名、イベントリスナのキュー遅延時間をカスタマイズしたい場合は、`$connection`、`$queue`、`$delay`プロパティをリスナクラスで定義します。

    <?php

    namespace App\Listeners;

    use App\Events\OrderShipped;
    use Illuminate\Contracts\Queue\ShouldQueue;

    class SendShipmentNotification implements ShouldQueue
    {
        /**
         * ジョブを投入する接続名
         *
         * @var string|null
         */
        public $connection = 'sqs';

        /**
         * ジョブを投入するキュー名
         *
         * @var string|null
         */
        public $queue = 'listeners';

        /**
         * ジョブが処理開始されるまでの時間（秒）
         *
         * @var int
         */
        public $delay = 60;
    }

実行時のリスナのキューを定義したい場合は、リスナ上に`viaQueue`メソッドを定義してください。

    /**
     * リスナのキュー名の取得
     *
     * @return string
     */
    public function viaQueue()
    {
        return 'listeners';
    }

#### 条件付きリスナのキュー投入

あるデータが存在する場合のみ、実行時にリスナをキューすると判断する必要が起きる場合もあります。そのためには`shouldQueue`メソッドをリスナへ追加し、そのリスナがキューされるかどうかを決めます。`shouldQueue`が`false`を返すとそのリスナは実行されません。

    <?php

    namespace App\Listeners;

    use App\Events\OrderPlaced;
    use Illuminate\Contracts\Queue\ShouldQueue;

    class RewardGiftCard implements ShouldQueue
    {
        /**
         * 顧客にギフトカードを贈る
         *
         * @param  \App\Events\OrderPlaced  $event
         * @return void
         */
        public function handle(OrderPlaced $event)
        {
            //
        }

        /**
         * リスナがキューされるかどうかを決める
         *
         * @param  \App\Events\OrderPlaced  $event
         * @return bool
         */
        public function shouldQueue(OrderPlaced $event)
        {
            return $event->order->subtotal >= 5000;
        }
    }

<a name="manually-accessing-the-queue"></a>
### キューへの任意アクセス

リスナの裏で動作しているキュージョブの、`delete`や`release`メソッドを直接呼び出したければ、`Illuminate\Queue\InteractsWithQueue`トレイトを使えます。このトレイトは生成されたリスナにはデフォルトとしてインポートされており、これらのメソッドへアクセスできるようになっています。

    <?php

    namespace App\Listeners;

    use App\Events\OrderShipped;
    use Illuminate\Contracts\Queue\ShouldQueue;
    use Illuminate\Queue\InteractsWithQueue;

    class SendShipmentNotification implements ShouldQueue
    {
        use InteractsWithQueue;

        /**
         * イベントの処理
         *
         * @param  \App\Events\OrderShipped  $event
         * @return void
         */
        public function handle(OrderShipped $event)
        {
            if (true) {
                $this->release(30);
            }
        }
    }

<a name="handling-failed-jobs"></a>
### 失敗したジョブの取り扱い

キュー投入したイベントリスナはときどき落ちることがあります。キューワーカにより定義された最大試行回数を超え、キュー済みのリスナが実行されると、リスナの`failed`メソッドが実行されます。`failed`メソッドはイベントインスタンスと落ちた原因の例外を引数に受け取ります。

    <?php

    namespace App\Listeners;

    use App\Events\OrderShipped;
    use Illuminate\Contracts\Queue\ShouldQueue;
    use Illuminate\Queue\InteractsWithQueue;

    class SendShipmentNotification implements ShouldQueue
    {
        use InteractsWithQueue;

        /**
         * イベントの処理
         *
         * @param  \App\Events\OrderShipped  $event
         * @return void
         */
        public function handle(OrderShipped $event)
        {
            //
        }

        /**
         * 失敗したジョブの処理
         *
         * @param  \App\Events\OrderShipped  $event
         * @param  \Throwable  $exception
         * @return void
         */
        public function failed(OrderShipped $event, $exception)
        {
            //
        }
    }

<a name="dispatching-events"></a>
## イベントの発行

イベントを発行するには、`event`ヘルパにイベントのインスタンスを渡してください。このヘルパは登録済みのリスナ全部へイベントをディスパッチします。`event`ヘルパはグローバルに使用できますので、アプリケーションのどこからでも呼び出すことができます。

    <?php

    namespace App\Http\Controllers;

    use App\Events\OrderShipped;
    use App\Http\Controllers\Controller;
    use App\Models\Order;

    class OrderController extends Controller
    {
        /**
         * 指定した注文を発送
         *
         * @param  int  $orderId
         * @return Response
         */
        public function ship($orderId)
        {
            $order = Order::findOrFail($orderId);

            // 注文発送ロジック…

            event(new OrderShipped($order));
        }
    }

もしくは、イベントが`Illuminate\Foundation\Events\Dispatchable`トレイトを使用していれば、そのイベントの静的`dispatch`メソッドを呼び出せます。`dispatch`メソッドへ渡したすべての引数は、そのイベントのコンストラクタへ渡されます。

    OrderShipped::dispatch($order);

> {tip} テスト時は実際にリスナを起動せずに、正しいイベントがディスパッチされたことをアサートできると便利です。Laravelに[組み込まれたテストヘルパ](/docs/{{version}}/mocking#event-fake)で簡単に行なえます。

<a name="event-subscribers"></a>
## イベント

<a name="writing-event-subscribers"></a>
### イベント購読プログラミング

イベント購読クラスは、その内部で複数のイベントを購読でき、一つのクラスで複数のイベントハンドラを定義できます。購読クラスは、イベントディスパッチャインスタンスを受け取る、`subscribe`メソッドを定義する必要があります。イベントリスナを登録するには、渡されたディスパッチャの`listen`メソッドを呼び出します。

    <?php

    namespace App\Listeners;

    class UserEventSubscriber
    {
        /**
         * ユーザーログインイベント処理
         */
        public function handleUserLogin($event) {}

        /**
         * ユーザーログアウトイベント処理
         */
        public function handleUserLogout($event) {}

        /**
         * 購読するリスナの登録
         *
         * @param  \Illuminate\Events\Dispatcher  $events
         * @return void
         */
        public function subscribe($events)
        {
            $events->listen(
                'Illuminate\Auth\Events\Login',
                [UserEventSubscriber::class, 'handleUserLogin']
            );

            $events->listen(
                'Illuminate\Auth\Events\Logout',
                [UserEventSubscriber::class, 'handleUserLogout']
            );
        }
    }

Alternatively, your subscriber's `subscribe` method may return an array of event to handler mappings. In this case, the event listener mappings will be registered for you automatically:

    use Illuminate\Auth\Events\Login;
    use Illuminate\Auth\Events\Logout;

    /**
     * Register the listeners for the subscriber.
     *
     * @return array
     */
    public function subscribe()
    {
        return [
            Login::class => [UserEventSubscriber::class, 'handleUserLogin'],
            Logout::class => [UserEventSubscriber::class, 'handleUserLogout'],
        ];
    }

<a name="registering-event-subscribers"></a>
### イベント購読登録

購読クラスを書いたら、イベントディスパッチャへ登録できる準備が整いました。`EventServiceProvider`の`$subscribe`プロパティを使用し、購読クラスを登録します。例として、`UserEventSubscriber`をリストに追加してみましょう。

    <?php

    namespace App\Providers;

    use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;

    class EventServiceProvider extends ServiceProvider
    {
        /**
         * アプリケーションのイベントリスナをマップ
         *
         * @var array
         */
        protected $listen = [
            //
        ];

        /**
         * 登録する購読クラス
         *
         * @var array
         */
        protected $subscribe = [
            'App\Listeners\UserEventSubscriber',
        ];
    }
