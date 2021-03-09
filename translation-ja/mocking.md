# モック

- [イントロダクション](#introduction)
- [オブジェクトのモック](#mocking-objects)
- [ファサードのモック](#mocking-facades)
    - [ファサードのスパイ](#facade-spies)
- [Bus Fake](#bus-fake)
    - [ジョブチェーン](#bus-job-chains)
    - [ジョブバッチ](#job-batches)
- [Event Fake](#event-fake)
    - [限定的なEvent Fake](#scoped-event-fakes)
- [HTTP Fake](#http-fake)
- [Mail Fake](#mail-fake)
- [Notification Fake](#notification-fake)
- [Queue Fake](#queue-fake)
    - [ジョブチェーン](#job-chains)
- [Storage Fake](#storage-fake)
- [時間操作](#interacting-with-time)

<a name="introduction"></a>
## イントロダクション

Laravelアプリケーションをテストするとき、アプリケーションの一部分を「モック」し、特定のテストを行う間は実際のコードを実行したくない場合があります。たとえば、イベントをディスパッチするコントローラをテストする場合、テスト中に実際に実行されないように、イベントリスナをモックすることができます。これにより、イベントリスナはそれ自身のテストケースでテストできるため、イベントリスナの実行について気を取られずに、コントローラのHTTPレスポンスのみをテストできます。

Laravelは最初からイベント、ジョブ、その他のファサードをモックするための便利な方法を提供しています。これらのヘルパは主にMockeryの便利なレイヤーを提供するため、複雑なMockeryメソッド呼び出しを手動で行う必要はありません。

<a name="mocking-objects"></a>
## オブジェクトのモック

Laravelの[サービスコンテナ](/docs/{{version}}/container)を介してアプリケーションに注入されるオブジェクトをモックする場合、モックしたインスタンスを`instance`結合としてコンテナに結合する必要があります。これにより、オブジェクト自体を構築する代わりに、オブジェクトのモックインスタンスを使用するようコンテナへ指示できます。

    use App\Service;
    use Mockery;
    use Mockery\MockInterface;

    public function test_something_can_be_mocked()
    {
        $this->instance(
            Service::class,
            Mockery::mock(Service::class, function (MockInterface $mock) {
                $mock->shouldReceive('process')->once();
            })
        );
    }

これをより便利にするために、Laravelの基本テストケースクラスが提供する`mock`メソッドを使用できます。たとえば、以下の例は上記の例と同じです。

    use App\Service;
    use Mockery\MockInterface;

    $mock = $this->mock(Service::class, function (MockInterface $mock) {
        $mock->shouldReceive('process')->once();
    });

オブジェクトのいくつかのメソッドをモックするだけでよい場合は、`partialMock`メソッドを使用できます。モックされていないメソッドは、通常どおり呼び出されたときに実行されます。

    use App\Service;
    use Mockery\MockInterface;

    $mock = $this->partialMock(Service::class, function (MockInterface $mock) {
        $mock->shouldReceive('process')->once();
    });

同様に、オブジェクトを[スパイ](http://docs.mockery.io/en/latest/reference/spies.html)したい場合のため、Laravelの基本テストケースクラスは、`Mockery::spy`メソッドの便利なラッパーとして`spy`メソッドを提供しています。スパイはモックに似ています。ただし、スパイはスパイとテスト対象のコードとの間のやり取りを一度記録するため、コードの実行後にアサーションを作成できます。

    use App\Service;

    $spy = $this->spy(Service::class);

    // …

    $spy->shouldHaveReceived('process')

<a name="mocking-facades"></a>
## ファサードのモック

従来の静的メソッド呼び出しとは異なり、[ファサード](/docs/{{version}}/facade（[リアルタイムファサード](/docs/{{version}}/facades#real-time-facades)を含む）もモックできます。これにより、従来の静的メソッドに比べて大きな利点が得られ、従来の依存注入を使用した場合と同じくテストが簡単になります。テスト時、コントローラの１つで発生するLaravelファサードへの呼び出しをモックしたい場合がよくあるでしょう。例として、次のコントローラアクションについて考えてみます。

    <?php

    namespace App\Http\Controllers;

    use Illuminate\Support\Facades\Cache;

    class UserController extends Controller
    {
        /**
         * アプリケーションのすべてのユーザーのリストを取得
         *
         * @return \Illuminate\Http\Response
         */
        public function index()
        {
            $value = Cache::get('key');

            //
        }
    }

`shouldReceive`メソッドを使用して`Cache`ファサードへの呼び出しをモックできます。これにより、[Mockery](https://github.com/padraic/mockery)モックのインスタンスが返されます。ファサードは実際にはLaravel[サービスコンテナ](/docs/{{version}}/container)によって依存解決および管理されるため、通常の静的クラスよりもはるかにテストがやりやすいのです。たとえば、`Cache`ファサードの`get`メソッドの呼び出しをモックしてみましょう。

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

            // …
        }
    }

>{note}`Request`ファサードをモックしないでください。代わりに、テストの実行時に、`get`や`post`などの[HTTPテストメソッド](/docs/{{version}}/http-tests)に必要な入力を渡します。同様に、`Config`ファサードをモックする代わりに、テストでは`Config::set`メソッドを呼び出してください。

<a name="facade-spies"></a>
### ファサードのスパイ

ファサードで[スパイ](http://docs.mockery.io/en/latest/reference/spies.html)したい場合は、対応するファサードで`spy`メソッドを呼び出します。スパイはモックに似ています。ただし、スパイはスパイとテスト対象のコードとの間のやり取りを一時的に記録しているため、コードの実行後にアサーションを作成できます。

    use Illuminate\Support\Facades\Cache;

    public function test_values_are_be_stored_in_cache()
    {
        Cache::spy();

        $response = $this->get('/');

        $response->assertStatus(200);

        Cache::shouldHaveReceived('put')->once()->with('name', 'Taylor', 10);
    }

<a name="bus-fake"></a>
## Bus Fake

ジョブをディスパッチするコードをテストするときは、通常、特定のジョブがディスパッチされたことをアサートするが、実際にはジョブをキューに投入したり、実行したりは行う必要がありません。これは通常、ジョブの実行は、別のテストクラスでテストできるためです。

`Bus`ファサードの`fake`メソッドを使用して、ジョブがキューにディスパッチされないようにすることができます。それから、テスト対象のコードを実行した後、`assertDispatched`メソッドと`assertNotDispatched`メソッドを使用してアプリケーションがディスパッチしようとしたジョブを調べられます。

    <?php

    namespace Tests\Feature;

    use App\Jobs\ShipOrder;
    use Illuminate\Foundation\Testing\RefreshDatabase;
    use Illuminate\Foundation\Testing\WithoutMiddleware;
    use Illuminate\Support\Facades\Bus;
    use Tests\TestCase;

    class ExampleTest extends TestCase
    {
        public function test_orders_can_be_shipped()
        {
            Bus::fake();

            // 注文の実行コード…

            // ジョブがディスパッチされたことをアサート
            Bus::assertDispatched(ShipOrder::class);

            // ジョブがディスパッチされなかったことをアサート
            Bus::assertNotDispatched(AnotherJob::class);
        }
    }

特定の「論理テスト」に合格するジョブがディスパッチされたことをアサートするために、`assertDispatched`または`assertNotDispatched`メソッドへクロージャを渡せます。指定する論理テストに合格するジョブが最低１つディスパッチされた場合、アサーションは成功します。たとえば、ジョブが特定の注文でディスパッチされたことをアサートしたい場合があります。

    Bus::assertDispatched(function (ShipOrder $job) use ($order) {
        return $job->order->id === $order->id;
    });

<a name="bus-job-chains"></a>
### ジョブチェーン

`Bus`ファサードの`assertChained`メソッドを使用して、[ジョブのチェーン](/docs/{{version}}/queues#job-chaining)がディスパッチされたことをアサートできます。`assertChained`メソッドは、最初の引数にチェーンするジョブの配列を取ります。

    use App\Jobs\RecordShipment;
    use App\Jobs\ShipOrder;
    use App\Jobs\UpdateInventory;
    use Illuminate\Support\Facades\Bus;

    Bus::assertChained([
        ShipOrder::class,
        RecordShipment::class,
        UpdateInventory::class
    ]);

上記の例でわかるように、チェーンジョブの配列はジョブのクラス名の配列です。ただし、実際のジョブインスタンスの配列を提供することもできます。そうすることで、Laravelは、ジョブインスタンスが同じクラスであり、アプリケーションがディスパッチしたチェーンジョブと同じプロパティ値を持つことを保証します。

    Bus::assertChained([
        new ShipOrder,
        new RecordShipment,
        new UpdateInventory,
    ]);

<a name="job-batches"></a>
### ジョブバッチ

`Bus`ファサードの`assertBatched`メソッドを使用して、[ジョブのバッチ](/docs/{{version}}/queues#job-batches)がディスパッチされたことをアサートできます。`assertBatched`メソッドへ渡すクロージャは、`Illuminate\Bus\PendingBatch`のインスタンスを受け取ります。これはバッチ内のジョブを検査するために使用できます。

    use Illuminate\Bus\PendingBatch;
    use Illuminate\Support\Facades\Bus;

    Bus::assertBatched(function (PendingBatch $batch) {
        return $batch->name == 'import-csv' &&
               $batch->jobs->count() === 10;
    });

<a name="event-fake"></a>
## Event Fake

イベントをディスパッチするコードをテストするときは、イベントのリスナを実際に実行しないようにLaravelに指示することを推奨します。`Event`ファサードの`fake`メソッドを使用すると、リスナの実行を阻止し、テスト対象のコードを実行してから、`assertDispatched`メソッドと`assertNotDispatched`メソッドを使用してアプリケーションによってディスパッチされたイベントをアサートできます。

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
        public function test_orders_can_be_shipped()
        {
            Event::fake();

            // 注文の実行コード…

            // イベントがディスパッチされたことをアサート
            Event::assertDispatched(OrderShipped::class);

            // イベントが２回ディスパッチされることをアサート
            Event::assertDispatched(OrderShipped::class, 2);

            // イベントがディスパッチされないことをアサート
            Event::assertNotDispatched(OrderFailedToShip::class);
        }
    }

特定の「論理」に合格するイベントがディスパッチされたことをアサートするために、`assertDispatched`または`assertNotDispatched`メソッドへクロージャを渡すことができます。指定する論理テストに合格するイベントが少なくとも１つディスパッチされた場合、アサーションは成功します。

    Event::assertDispatched(function (OrderShipped $event) use ($order) {
        return $event->order->id === $order->id;
    });

> {note} `Event::fake()`を呼び出した後、イベントリスナはすべて実行されません。したがって、モデルの`creating`イベント中にUUIDを作成するなど、イベントに依存するモデルファクトリをテストで使用する場合は、ファクトリを使用した**後に**`Event::fake()`を呼び出す必要があります。

<a name="faking-a-subset-of-events"></a>
#### イベントのサブセットのFake

特定のイベントに対してだけ、イベントリスナをフェイクしたい場合は、`fake`か`fakeFor`メソッドに指定してください。

    /**
     * 受注処理のテスト
     */
    public function test_orders_can_be_processed()
    {
        Event::fake([
            OrderCreated::class,
        ]);

        $order = Order::factory()->create();

        Event::assertDispatched(OrderCreated::class);

        // Other events are dispatched as normal...
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
        public function test_orders_can_be_processed()
        {
            $order = Event::fakeFor(function () {
                $order = Order::factory()->create();

                Event::assertDispatched(OrderCreated::class);

                return $order;
            });

            // イベントは通常どおりディスパッチされ、オブザーバが実行される
            $order->update([...]);
        }
    }

<a name="http-fake"></a>
## HTTP Fake

`Http`ファサードの`fake`メソッドでHTTPリクエスト作成時に、スタブした／ダミーのレスポンスを返すようにHTTPクライアントへ指示できます。送信するHTTPリクエストのFakeの詳細は、[HTTPクライアントテストのドキュメント](/docs/{{version}}/http-client#testing)を調べてください。

<a name="mail-fake"></a>
## Mail Fake

`Mail`ファサードの`fake`メソッドを使用して、メールが送信されないようにすることができます。通常、メールの送信は、実際にテストするコードとは関係ありません。ほとんどの場合、Laravelが特定のメールを送信するよう指示されたとアサートするだけで十分です。

`Mail`ファサードの`fake`メソッドを呼び出した後、[mailables](/docs/{{version}}/mail)がユーザーに送信されるように指示されたことを宣言し、mailablesが受信したデータを検査することもできます。

    <?php

    namespace Tests\Feature;

    use App\Mail\OrderShipped;
    use Illuminate\Foundation\Testing\RefreshDatabase;
    use Illuminate\Foundation\Testing\WithoutMiddleware;
    use Illuminate\Support\Facades\Mail;
    use Tests\TestCase;

    class ExampleTest extends TestCase
    {
        public function test_orders_can_be_shipped()
        {
            Mail::fake();

            // 注文配送を実行

            // mailableが送信されなかったことをアサート
            Mail::assertNothingSent();

            // mailableが送られたことをアサート
            Mail::assertSent(OrderShipped::class);

            // mailableが２回送信されたことをアサート
            Mail::assertSent(OrderShipped::class, 2);

            // mailableが送信されなかったことをアサート
            Mail::assertNotSent(AnotherMailable::class);
        }
    }

バックグラウンドで配信するためにmailableをキュー投入する場合は、`assertSent`の代わりに`assertQueued`メソッドを使用する必要があります。

    Mail::assertQueued(OrderShipped::class);

    Mail::assertNotQueued(OrderShipped::class);

特定の「論理テスト」に合格したメーラブルが送信されたことを宣言するために、`assertSent`または`assertNotSent`メソッドにクロージャを渡すこともできます。指定する論理テストに合格する郵送物が少なくとも１つ送信された場合、アサーションは成功します。

    Mail::assertSent(function (OrderShipped $mail) use ($order) {
        return $mail->order->id === $order->id;
    });

`Mail`ファサードのアサートメソッドを呼び出すと、引数中のクロージャが受け取るmailableインスタンスは、mailableの受信者を調べる便利なメソッドを提供しています。

    Mail::assertSent(OrderShipped::class, function ($mail) use ($user) {
        return $mail->hasTo($user->email) &&
               $mail->hasCc('...') &&
               $mail->hasBcc('...');
    });

<a name="notification-fake"></a>
## Notification Fake

`Notification`ファサードの`fake`メソッドを使用して、通知が送信されないようにすることができます。通常、通知の送信は、実際にテストしているコードとは関係ありません。ほとんどの場合、Laravelが特定の通知を送信するように指示したことをアサートするだけで十分です。

`Notification`ファサードの`fake`メソッドを呼び出した後、[通知](/docs/{{version}}/notifications)がユーザーへ送信されるように指示されたことをアサートし、通知が受信したデータを検査することもできます。

    <?php

    namespace Tests\Feature;

    use App\Notifications\OrderShipped;
    use Illuminate\Foundation\Testing\RefreshDatabase;
    use Illuminate\Foundation\Testing\WithoutMiddleware;
    use Illuminate\Support\Facades\Notification;
    use Tests\TestCase;

    class ExampleTest extends TestCase
    {
        public function test_orders_can_be_shipped()
        {
            Notification::fake();

            // 注文の発送処理…

            // 通知がまったく送られていないことをアサート
            Notification::assertNothingSent();

            // 指定するユーザーに通知が送信されたことをアサート
            Notification::assertSentTo(
                [$user], OrderShipped::class
            );

            // 通知が送信されなかったことをアサート
            Notification::assertNotSentTo(
                [$user], AnotherNotification::class
            );
        }
    }

特定の「論理テスト」に合格した通知が送信されたことをアサートするために、`assertSentTo`または`assertNotSentTo`メソッドへクロージャを渡すこともできます。指定する論理テストに合格する通知が少な​​くとも１つ送信された場合、アサーションは成功します。

    Notification::assertSentTo(
        $user,
        function (OrderShipped $notification, $channels) use ($order) {
            return $notification->order->id === $order->id;
        }
    );

<a name="on-demand-notifications"></a>
#### オンデマンド通知

テストしているコードが[オンデマンド通知](/docs/{{version}}/notifys#on-demand-notifications)を送信する場合は、通知が`Illuminate\Notifications\AnonymousNotifiable`インスタンスへ送信されたことを宣言する必要があります。

    use Illuminate\Notifications\AnonymousNotifiable;

    Notification::assertSentTo(
        new AnonymousNotifiable, OrderShipped::class
    );

通知アサーションメソッドの３番目の引数としてクロージャを渡すことにより、オンデマンド通知が正しい「ルート」アドレスに送信されたか判定できます。

    Notification::assertSentTo(
        new AnonymousNotifiable,
        OrderShipped::class,
        function ($notification, $channels, $notifiable) use ($user) {
            return $notifiable->routes['mail'] === $user->email;
        }
    );

<a name="queue-fake"></a>
## Queue Fake

`Queue`ファサードの`fake`メソッドを使用して、キュー投入するジョブをキュー投入しないでおくことができます。ほとんどの場合、キュー投入するジョブ自体は別のテストクラスでテストされる可能性が高いため、Laravelが特定のジョブをキューへ投入するように指示したことをアサートするだけで十分です。

`Queue`ファサードの`fake`メソッドを呼び出した後、アプリケーションがジョブをキューに投入しようとしたことをアサートできます。

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
        public function test_orders_can_be_shipped()
        {
            Queue::fake();

            // 注文の発送処理…

            // ジョブまったく投入されなかったことをアサート
            Queue::assertNothingPushed();

            // ジョブが特定のキューへ投入されたことをアサート
            Queue::assertPushedOn('queue-name', ShipOrder::class);

            // ジョブが２回投入されたことをアサート
            Queue::assertPushed(ShipOrder::class, 2);

            // ジョブが投入されなかったことをアサート
            Queue::assertNotPushed(AnotherJob::class);
        }
    }

特定の「論理テスト」に合格するジョブが投入されたことをアサートするために、`assertPushed`または`assertNotPushed`メソッドにクロージャを渡すこともできます。指定する論理テストに合格するジョブが少なくとも１つ投入された場合、アサートは成功します。

    Queue::assertPushed(function (ShipOrder $job) use ($order) {
        return $job->order->id === $order->id;
    });

<a name="job-chains"></a>
### ジョブチェーン

`Queue`ファサードの`assertPushedWithChain`メソッドと`assertPushedWithoutChain`メソッドを使用して、投入したジョブのジョブチェーンを検査できます。`assertPushedWithChain`メソッドは、最初の引数にプライマリジョブをとり、２番目の引数としてチェーンジョブの配列を取ります。

    use App\Jobs\RecordShipment;
    use App\Jobs\ShipOrder;
    use App\Jobs\UpdateInventory;
    use Illuminate\Support\Facades\Queue;

    Queue::assertPushedWithChain(ShipOrder::class, [
        RecordShipment::class,
        UpdateInventory::class
    ]);

上記の例でわかるように、チェーンジョブの配列はジョブのクラス名の配列です。ただし、実際のジョブインスタンスの配列を渡すこともできます。それによりLaravelは、ジョブインスタンスが同じクラスであり、アプリケーションがディスパッチしたチェーンジョブと同じプロパティ値を持つことを保証します。

    Queue::assertPushedWithChain(ShipOrder::class, [
        new RecordShipment,
        new UpdateInventory,
    ]);

`assertPushedWithoutChain`メソッドを使用して、ジョブチェーンなしでジョブが投入されたことをアサートできます。

    Queue::assertPushedWithoutChain(ShipOrder::class);

<a name="storage-fake"></a>
## Storage Fake

`Storage`ファサードの`fake`メソッドを使用すると、偽のディスクを簡単に生成できます。これを`Illuminate\Http\UploadedFile`クラスのファイル生成ユーティリティと組み合わせると、ファイルアップロードのテストが大幅に簡素化できます。例をご覧ください。

    <?php

    namespace Tests\Feature;

    use Illuminate\Foundation\Testing\RefreshDatabase;
    use Illuminate\Foundation\Testing\WithoutMiddleware;
    use Illuminate\Http\UploadedFile;
    use Illuminate\Support\Facades\Storage;
    use Tests\TestCase;

    class ExampleTest extends TestCase
    {
        public function test_albums_can_be_uploaded()
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

ファイルアップロードのテストの詳細には、[ファイルアップロードに関するHTTPテストドキュメントの情報](/docs/{{version}}/http-tests#testing-file-uploads)を参照してください。

> {tip} デフォルトでは、`fake`メソッドは一時ディレクトリ内のすべてのファイルを削除します。これらのファイルを保持したい場合は、代わりに"persistentFake"メソッドを使用できます。

<a name="interacting-with-time"></a>
## 時間操作

テスト時、`now`や`Illuminate\Support\Carbon::now()`のようなヘルパが返す時間を変更したいことはよくあります。幸いなことに、Laravelのベース機能テストクラスは現在時間を操作するヘルパを用意しています。

    public function testTimeCanBeManipulated()
    {
        // Travel into the future...
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
