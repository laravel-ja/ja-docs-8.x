# モック

- [イントロダクション](#introduction)
- [オブジェクトのモック](#mocking-objects)
- [Bus Fake](#bus-fake)
- [Event Fake](#event-fake)
    - [イベントのサブセットのFake](#scoped-event-fakes)
- [HTTP Fake](#http-fake)
- [Mail Fake](#mail-fake)
- [Notification Fake](#notification-fake)
- [Queue Fake](#queue-fake)
- [Storage Fake](#storage-fake)
- [時間操作](#interacting-with-time)
- [ファサード](#mocking-facades)

<a name="イントロダクション"></a>
## イントロダクション

Laravelアプリケーションをテストするとき、アプリケーションの一部分を「モック」し、特定のテストを行う間は実際のコードを実行したくない場合があります。たとえば、イベントを発行するコントローラをテストする時は、実際に実行したくないイベントリスナをモックしたいと思うことでしょう。これにより、コントローラのHTTPレスポンスだけをテストでき、イベントリスナの実行は心配しなくて済みます。なぜなら、イベントリスナは自身のテストケースにおいて、テストできるからです。

Laravelにはイベント、ジョブ、ファサードを最初からモックできるヘルパが準備されています。これらのヘルパは主に[Mockery](http://docs.mockery.io/en/latest/)上で動作する便利なレイヤーを提供しているので、複雑なMockeryのメソッドコールを自分で作成する必要はありません。MockeryやPHPUnitを使用し、自身のモックやスパイを自由に作成してください。

<a name="mocking-objects"></a>
## オブジェクトのモック

Laravelのサービスコンテナにより、アプリケーションへ依存注入されるオブジェクトをモックする場合は、モックしたインスタンスをコンテナへ、`instance`結合する必要があります。これによりコンテナへ対象のオブジェクトそのものを構築する代わりに、モックしたインスタンスオブジェクトを使用するように指示します。

    use App\Service;
    use Mockery;

    $this->instance(Service::class, Mockery::mock(Service::class, function ($mock) {
        $mock->shouldReceive('process')->once();
    }));

これをより便利にするため、Laravelのベーステストケースクラスでは、`mock`メソッドが使用できます。

    use App\Service;

    $this->mock(Service::class, function ($mock) {
        $mock->shouldReceive('process')->once();
    });

オブジェクトのいくつかのメソッドだけをモックする必要があるなら、`partialMock`メソッドが使えます。モックしていないメソッドは、呼び出し時に通常通り実行されます。

    use App\Service;

    $this->partialMock(Service::class, function ($mock) {
        $mock->shouldReceive('process')->once();
    });

同様に、オブジェクトをスパイしたい場合は、Laravelの便利な`Mockery::spy`ラッパーであり、ベースのテストケースクラスで提供している`spy`メソッドを用います。

    use App\Service;

    $this->spy(Service::class, function ($mock) {
        $mock->shouldHaveReceived('process');
    });

<a name="bus-fake"></a>
## Bus Fake

モックの別の方法は、`Bus`ファサードの`fake`メソッドを使用し、ジョブがディスパッチされないようにすることです。fakeを使用する場合、アサートはテスト下のコードが終了した時点で行われます。

    <?php

    namespace Tests\Feature;

    use App\Jobs\ShipOrder;
    use Illuminate\Foundation\Testing\RefreshDatabase;
    use Illuminate\Foundation\Testing\WithoutMiddleware;
    use Illuminate\Support\Facades\Bus;
    use Tests\TestCase;

    class ExampleTest extends TestCase
    {
        public function testOrderShipping()
        {
            Bus::fake();

            // 注文の実行コード…

            // 指定したテストに成功する特定のタイプのジョブがディスパッチされたことを宣言
            Bus::assertDispatched(function (ShipOrder $job) use ($order) {
                return $job->order->id === $order->id;
            });

            // ジョブがディスパッチされないことを宣言
            Bus::assertNotDispatched(AnotherJob::class);
        }
    }

<a name="event-fake"></a>
## Event Fake

モックの別の方法は、`Event`ファサードの`fake`メソッドを使用し、全イベントリスナが実行されないようにすることです。その後で、イベントがディスパッチされたことをアサートし、さらに受け取ったデータの検査もできます。fakeを使用する場合、アサートはテストを実施したコードの後に実行されます。

    <?php

    namespace Tests\Feature;

    use App\Events\OrderFailedToShip;
    use App\Events\OrderShipped;
    use Illuminate\Foundation\Testing\RefreshDatabase;
    use Illuminate\Foundation\Testing\WithoutMiddleware;
    use Illuminate\Support\Facades\Event;
    use Tests\TestCase;

    class ExampleTest extends TestCase
    {
        /**
         * 注文発送のテスト
         */
        public function testOrderShipping()
        {
            Event::fake();

            // 注文の実行コード…

            // 指定したテストに成功する特定のタイプのイベントがディスパッチされたことを宣言
            Event::assertDispatched(function (OrderShipped $event) use ($order) {
                return $event->order->id === $order->id;
            });

            // イベントが２回ディスパッチされることを宣言
            Event::assertDispatched(OrderShipped::class, 2);

            // イベントがディスパッチされないことを宣言
            Event::assertNotDispatched(OrderFailedToShip::class);
        }
    }

> {note} `Event::fake()`を呼び出した後は、イベントリスナは実行されなくなります。そのためたとえば、モデルの`creating`イベントでUUIDを生成するなど、イベントに結びつけたモデルファクトリの使用をテストする場合は、ファクトリを呼び出した**後に**、`Event::fake()`を呼び出す必要があります。

#### イベントのサブセットのFake

特定のイベントに対してだけ、イベントリスナをフェイクしたい場合は、`fake`か`fakeFor`メソッドに指定してください。

    /**
     * 受注処理のテスト
     */
    public function testOrderProcess()
    {
        Event::fake([
            OrderCreated::class,
        ]);

        $order = Order::factory()->create();

        Event::assertDispatched(OrderCreated::class);

        // 他のイベントは通常通りにディスパッチされる
        $order->update([...]);
    }

<a name="scoped-event-fakes"></a>
### 限定的なEvent Fake

テストの一部分だけでイベントをフェイクしたい場合は、`fakeFor`メソッドを使用します。

    <?php

    namespace Tests\Feature;

    use App\Events\OrderCreated;
    use App\Models\Order;
    use Illuminate\Foundation\Testing\RefreshDatabase;
    use Illuminate\Support\Facades\Event;
    use Illuminate\Foundation\Testing\WithoutMiddleware;
    use Tests\TestCase;

    class ExampleTest extends TestCase
    {
        /**
         * 注文発送のテスト
         */
        public function testOrderProcess()
        {
            $order = Event::fakeFor(function () {
                $order = Order::factory()->create();

                Event::assertDispatched(OrderCreated::class);

                return $order;
            });

            // イベントは通常通りにディスパッチされ、オブザーバが実行される
            $order->update([...]);
        }
    }

<a name="http-fake"></a>
## HTTP Fake

`Http`ファサードの`fake`メソッドでHTTPリクエスト作成時に、スタブした／ダミーのレスポンスを返すようにHTTPクライアントへ指示できます。送信するHTTPリクエストのFakeの詳細は、[HTTPクライアントテストのドキュメント](/docs/{{version}}/http-client#testing)を調べてください。

<a name="mail-fake"></a>
## Mail Fake

`Mail`ファサードの`fake`メソッドを使い、メールが送信されるのを防ぐことができます。その後で、[Mailable](/docs/{{version}}/mail)がユーザーへ送信されたかをアサートし、受け取ったデータを調べることさえできます。Fakeを使用する場合、テスト対象のコードが実行された後で、アサートしてください。

    <?php

    namespace Tests\Feature;

    use App\Mail\OrderShipped;
    use Illuminate\Foundation\Testing\RefreshDatabase;
    use Illuminate\Foundation\Testing\WithoutMiddleware;
    use Illuminate\Support\Facades\Mail;
    use Tests\TestCase;

    class ExampleTest extends TestCase
    {
        public function testOrderShipping()
        {
            Mail::fake();

            // Mailableがまったく送信されなかったことを宣言
            Mail::assertNothingSent();

            // 注文の実行コード…

            // 指定するテストに成功する特定のタイプのMailableがディスパッチされたことを宣言
            Mail::assertSent(function (OrderShipped $mail) use ($order) {
                return $mail->order->id === $order->id;
            });

            // メッセージが指定したユーザーに届いたことを宣言
            Mail::assertSent(OrderShipped::class, function ($mail) use ($user) {
                return $mail->hasTo($user->email) &&
                       $mail->hasCc('...') &&
                       $mail->hasBcc('...');
            });

            // mailableが２回送信されたことを宣言
            Mail::assertSent(OrderShipped::class, 2);

            // mailableが送られなかったことを宣言
            Mail::assertNotSent(AnotherMailable::class);
        }
    }

バックグランドで送信するために、mailableをキュー投入している場合は、`assertSent`の代わりに`assertQueued`メソッドを使用してください。

    Mail::assertQueued(...);
    Mail::assertNotQueued(...);

<a name="notification-fake"></a>
## Notification Fake

`Notification`ファサードの`fake`メソッドを使用し、[通知](/docs/{{version}}/notifications)が送られるのを防ぐことができます。その後で、通知がユーザーへ送られたことをアサートし、受け取ったデータを調べることさえできます。Fakeを使用するときは、テスト対象のコードが実行された後で、アサートを作成してください。

    <?php

    namespace Tests\Feature;

    use App\Notifications\OrderShipped;
    use Illuminate\Foundation\Testing\RefreshDatabase;
    use Illuminate\Foundation\Testing\WithoutMiddleware;
    use Illuminate\Notifications\AnonymousNotifiable;
    use Illuminate\Support\Facades\Notification;
    use Tests\TestCase;

    class ExampleTest extends TestCase
    {
        public function testOrderShipping()
        {
            Notification::fake();

            // 通知がまったく送られていないことを宣言
            Notification::assertNothingSent();

            // 注文の実行コード…

            // 指定するテストに成功する特定のタイプの通知が送信されたことを宣言
            Notification::assertSentTo(
                $user,
                function (OrderShipped $notification, $channels) use ($order) {
                    return $notification->order->id === $order->id;
                }
            );

            // 通知が指定したユーザーへ送られたことを宣言
            Notification::assertSentTo(
                [$user], OrderShipped::class
            );

            // 通知が送られなかったことを宣言
            Notification::assertNotSentTo(
                [$user], AnotherNotification::class
            );

            // 通知がNotification::route()メソッドにより送られたことを宣言
            Notification::assertSentTo(
                new AnonymousNotifiable, OrderShipped::class
            );

            // Notification::route()メソッドで通知を現在のユーザーに送ったことを宣言
            Notification::assertSentTo(
                new AnonymousNotifiable,
                OrderShipped::class,
                function ($notification, $channels, $notifiable) use ($user) {
                    return $notifiable->routes['mail'] === $user->email;
                }
            );
        }
    }

<a name="queue-fake"></a>
## Queue Fake

モックの代替として、`Queue`ファサードの`fake`メソッドを使い、ジョブがキューされるのを防ぐことができます。その後で、ジョブがキューへ投入されたことをアサートし、受け取ったデータの内容を調べることもできます。Fakeを使う場合は、テスト対象のコードを実行したあとで、アサートしてください。

    <?php

    namespace Tests\Feature;

    use App\Jobs\AnotherJob;
    use App\Jobs\FinalJob;
    use App\Jobs\ShipOrder;
    use Illuminate\Foundation\Testing\RefreshDatabase;
    use Illuminate\Foundation\Testing\WithoutMiddleware;
    use Illuminate\Support\Facades\Queue;
    use Tests\TestCase;

    class ExampleTest extends TestCase
    {
        public function testOrderShipping()
        {
            Queue::fake();

            // ジョブがまったく投入されていないことを宣言
            Queue::assertNothingPushed();

            // 注文の実行コード…

            // 指定するテストに成功する特定のタイプのジョブがキュー投入されたことを宣言
            Queue::assertPushed(function (ShipOrder $job) use ($order) {
                return $job->order->id === $order->id;
            });

            // 特定のキューへジョブが投入されたことを宣言
            Queue::assertPushedOn('queue-name', ShipOrder::class);

            // ジョブが２回投入されたことを宣言
            Queue::assertPushed(ShipOrder::class, 2);

            // ジョブが投入されなかったことを宣言
            Queue::assertNotPushed(AnotherJob::class);

            // ジョブが指定したジョブチェーンで投入され、クラスが一致していることを宣言
            Queue::assertPushedWithChain(ShipOrder::class, [
                AnotherJob::class,
                FinalJob::class
            ]);

            // ジョブが指定したジョブチェーンで投入され、クラスとプロパティ両方が一致していることを宣言
            Queue::assertPushedWithChain(ShipOrder::class, [
                new AnotherJob('foo'),
                new FinalJob('bar'),
            ]);

            // ジョブチェーンを使わずに、ジョブが投入されたことを宣言
            Queue::assertPushedWithoutChain(ShipOrder::class);
        }
    }

<a name="storage-fake"></a>
## Storage Fake

とてもシンプルにファイルアップロードのテストを行うため、`Storage`ファサードの`fake`メソッドにより、`UploadedFile`クラスのファイル生成ユーティリティと組み合わされたフェイクディスクを簡単に生成できます。

    <?php

    namespace Tests\Feature;

    use Illuminate\Foundation\Testing\RefreshDatabase;
    use Illuminate\Foundation\Testing\WithoutMiddleware;
    use Illuminate\Http\UploadedFile;
    use Illuminate\Support\Facades\Storage;
    use Tests\TestCase;

    class ExampleTest extends TestCase
    {
        public function testAlbumUpload()
        {
            Storage::fake('photos');

            $response = $this->json('POST', '/photos', [
                UploadedFile::fake()->image('photo1.jpg'),
                UploadedFile::fake()->image('photo2.jpg')
            ]);

            // ひとつ以上のファイルが保存されたことをアサート
            Storage::disk('photos')->assertExists('photo1.jpg');
            Storage::disk('photos')->assertExists(['photo1.jpg', 'photo2.jpg']);

            // ひとつ以上のファイルが保存されなかったことをアサート
            Storage::disk('photos')->assertMissing('missing.jpg');
            Storage::disk('photos')->assertMissing(['missing.jpg', 'non-existing.jpg']);
        }
    }

> {tip} `fake`メソッドはデフォルトとして、一時ディレクトリ内の全ファイルを削除します。ファイルを残しておきたい場合は、代わりに`persistentFake`メソッドを使用してください。

<a name="interacting-with-time"></a>
## 時間操作

Gテスト時、`now`や`Illuminate\Support\Carbon::now()`のようなヘルパが返す時間を変更したいことはよくあります。ありがたいことに、Laravelのベース機能テストクラスは現在時間を操作するヘルパを用意しています。

    public function testTimeCanBeManipulated()
    {
        // 未来へ移行する
        $this->travel(5)->milliseconds();
        $this->travel(5)->seconds();
        $this->travel(5)->minutes();
        $this->travel(5)->hours();
        $this->travel(5)->days();
        $this->travel(5)->weeks();
        $this->travel(5)->years();

        // 過去へ移行する
        $this->travel(-5)->hours();

        // 特定の時間へ移行する
        $this->travelTo(now()->subHours(6));

        // 現在時刻へ戻る
        $this->travelBack();
    }

<a name="mocking-facades"></a>
## ファサード

伝統的な静的メソッドの呼び出しと異なり、[ファサード](/docs/{{version}}/facades)はモックできます。これにより伝統的な静的メソッドより遥かなアドバンテージを得られ、依存注入を使用する場合と同じテスタビリティを持てます。テスト時は、コントローラのLaravelファサード呼び出しを頻繁にモックしたくなります。例として、以下のようなコントローラアクションを考えてください。

    <?php

    namespace App\Http\Controllers;

    use Illuminate\Support\Facades\Cache;

    class UserController extends Controller
    {
        /**
         * アプリケーションの全ユーザーリストの表示
         *
         * @return Response
         */
        public function index()
        {
            $value = Cache::get('key');

            //
        }
    }

`shouldReceive`メソッドを使用し、`Cache`ファサードへの呼び出しをモックできます。これは[Mockery](https://github.com/padraic/mockery)インスタンスを返します。ファサードはLaravelの[サービスコンテナ](/docs/{{version}}/container)により管理され、依存解決されていますので、典型的な静的クラスよりもかなり高いテスタビリティーを持っています。例として`Cache`ファサードへの`get`メソッド呼び出しをモックしてみましょう。

    <?php

    namespace Tests\Feature;

    use Illuminate\Foundation\Testing\RefreshDatabase;
    use Illuminate\Foundation\Testing\WithoutMiddleware;
    use Illuminate\Support\Facades\Cache;
    use Tests\TestCase;

    class UserControllerTest extends TestCase
    {
        public function testGetIndex()
        {
            Cache::shouldReceive('get')
                        ->once()
                        ->with('key')
                        ->andReturn('value');

            $response = $this->get('/users');

            // ...
        }
    }

> {note} `Request`ファサードをモックしてはいけません。代わりに、テスト実行時は`get`や`post`のようなHTTPヘルパメソッドへ、望む入力を引数として渡してください。同様に、`Config`ファサードはモックを使う代わりに、テストでは`Config::set`メソッドを呼び出してください。
