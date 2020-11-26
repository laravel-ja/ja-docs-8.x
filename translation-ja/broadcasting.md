# ブロードキャスト

- [イントロダクション](#introduction)
    - [設定](#configuration)
    - [ドライバ要求](#driver-prerequisites)
- [概論](#concept-overview)
    - [サンプルアプリケーションの使用](#using-example-application)
- [ブロードキャストイベントの定義](#defining-broadcast-events)
    - [ブロードキャスト名](#broadcast-name)
    - [ブロードキャストデータ](#broadcast-data)
    - [ブロードキャストキュー](#broadcast-queue)
    - [ブロードキャスト条件](#broadcast-conditions)
- [認証中チャンネル](#authorizing-channels)
    - [認証ルート定義](#defining-authorization-routes)
    - [認証コールバック定義](#defining-authorization-callbacks)
    - [チャンネル名の登録](#defining-channel-classes)
- [ブロードキャストイベント](#broadcasting-events)
    - [認証中ユーザーの回避](#only-to-others)
- [ブロードキャストの受け取り](#receiving-broadcasts)
    - [Laravel Echoのインストール](#installing-laravel-echo)
    - [イベントのリッスン](#listening-for-events)
    - [チャンネルの離脱](#leaving-a-channel)
    - [名前空間](#namespaces)
- [プレゼンスチャンネル](#presence-channels)
    - [プレゼンスチャンネルの許可](#authorizing-presence-channels)
    - [プレゼンスチャンネルへの参加](#joining-presence-channels)
    - [プレゼンスチャンネルへのブロードキャスト](#broadcasting-to-presence-channels)
- [クライアントイベント](#client-events)
- [通知](#notifications)

<a name="introduction"></a>
## イントロダクション

多くの近代的なアプリケーションでは、リアルタイムでライブ更新されるユーザーインターフェイスを実装するために、WebSocketが使用されています。サーバ上で何かのデータが更新されると、通常WebSocket接続を通じメッセージが送信され、クライアントにより処理されます。これは変更をアプリケーションに対しポーリングし続ける方法よりも、強固で効率的です。

こうしたタイプのアプリケーション構築を援助するため、LaravelはWebSocket接続経由で、[イベント](/docs/{{version}}/events)を簡単に「ブロードキャスト」できます。Laravelでイベントをブロードキャストすることにより、サーバサイドのコードとクライアントサイドのJavaScriptで、同じ名前のイベントを共有できます。

> {tip} ブロードキャストを開始する前に、Laravelの[イベントとリスナ](/docs/{{version}}/events)に関するドキュメントをすべてしっかりと読んでください。

<a name="configuration"></a>
### 設定

イベントブロードキャストの設定オプションは、すべて`config/broadcasting.php`設定ファイルの中にあります。Laravelはドライバをいくつか準備しています。[Pusherチャンネル](https://pusher.com/channels)や[Redis](/docs/{{version}}/redis)、それにローカルの開発とデバッグのための`log`ドライバがあります。さらにブロードキャストを完全に無効にするための、`null`ドライバも用意しています。`config/broadcasting.php`設定ファイルに、各ドライバの設定例が含まれています。

<a name="broadcast-service-provider"></a>
#### ブロードキャストサービスプロバイダ

イベントをブロードキャストするには、事前に`App\Providers\BroadcastServiceProvider`を登録する必要があります。インストールしたばかりのLaravelアプリケーションで、`config/app.php`設定ファイル中の、`providers`配列配列にある、このプロバイダのコメントを外してください。このプロバイダはブロードキャスト認証ルートとコールバックを登録します。

<a name="csrf-token"></a>
#### CSRFトークン

[Laravel Echo](#installing-laravel-echo)は、現在のセッションのCSRFトークンへアクセスする必要があります。アプリケーションの`head` HTML要素を確認し、CSRFトークンを含むように`meta`タグを定義してください。

    <meta name="csrf-token" content="{{ csrf_token() }}">

<a name="driver-prerequisites"></a>
### ドライバ要求

<a name="pusher-channels"></a>
#### Pusherチャンネル

イベントを[Pusherチャンネル](https://pusher.com/channels)によりブロードキャストする場合、Composerパッケージマネージャを使い、PusherチャンネルPHP SDKをインストールする必要があります。

    composer require pusher/pusher-php-server "~4.0"

次に、チャンネルの認証情報を`config/broadcasting.php`設定ファイル中で設定する必要があります。Pusherチャンネルの設定例はこのファイルに含まれ、チャンネルキーと秘密キー、アプリケーションIDを簡単に指定できます。`config/broadcasting.php`ファイルの`pusher`設定では、チャンネルでサポートされているクラスタなど、追加のオプション（`options`）も設定可能です。

    'options' => [
        'cluster' => 'eu',
        'useTLS' => true
    ],

チャンネルと[Laravel Echo](#installing-laravel-echo)を使用する場合、`resources/js/bootstrap.js`ファイルのEchoインスタンスをインスタンス化する時に、使用するブロードキャスタとして、`pusher`を指定する必要があります。

    import Echo from "laravel-echo";

    window.Pusher = require('pusher-js');

    window.Echo = new Echo({
        broadcaster: 'pusher',
        key: 'your-pusher-channels-key'
    });

最後に、`.env`ファイル中のブロードキャストドライバーを`pusher`へ変更する必要があります。

    BROADCAST_DRIVER=pusher

<a name="pusher-compatible-laravel-websockets"></a>
#### Pusher互換のLaravel　WebSocket

[laravel-websockets](https://github.com/beyondcode/laravel-websockets)はPHPで実装された、Laravel用のPusher互換のWebSocketパッケージです。このパッケージは外部WebソケットプロバイダやNodeを使用しなくてもLaravelブロードキャストの能力を最大限に活用できます。このパッケージのインストールと使用の詳細は、[公式ドキュメント]（https://beyondco.de/docs/laravel-websockets）を参照してください。

<a name="redis"></a>
#### Redis

Redisブロードキャスタを使用する場合は、phpredis PHP拡張をPECLを使いインストールするか、PredisライブラリをComposerを使用しインストールする必要があります。

    composer require predis/predis

次に、`.env`ファイル中のブロードキャストドライバーを`redis`へ変更する必要があります。

    BROADCAST_DRIVER=redis

RedisブロードキャスタはRedisのpub/sub機能を使用し、メッセージをブロードキャストします。Redisからのメッセージを受け、WebSocketチャンネルへブロードキャストできるように、これをWebSocketとペアリングする必要があります。

Redisブロードキャスタがイベントを発行すると、そのイベントに指定されたチャンネル名へ発行され、イベント名、`data`ペイロード、イベントのソケットIDを生成したユーザー（該当する場合）を含む、ペイロードはJSONエンコードされた文字列になります。

<a name="socketio"></a>
#### Socket.IO

RedisブロードキャスタとSocket.IOサーバをペアリングする場合、アプリケーションへSocket.IO JavaScriptクライアントライブラリをインクルードする必要があります。NPMパッケージマネージャにより、インストールできます。

    npm install --save-dev socket.io-client@2

次に、`socket.io`コネクタと`host`を指定し、Echoをインスタンス化します。

    import Echo from "laravel-echo"

    window.io = require('socket.io-client');

    window.Echo = new Echo({
        broadcaster: 'socket.io',
        host: window.location.hostname + ':6001'
    });

最後に、Socket.IOのコンパチブルサーバを実行する必要があります。LaravelにはSocket.IOサーバの実装は含まれていません。しかし、[tlaverdure/laravel-echo-server](https://github.com/tlaverdure/laravel-echo-server) GitHubリポジトリで、コミュニティにより現在、Socket.IOサーバがメンテナンスされています。

<a name="queue-prerequisites"></a>
#### キュー事前要件

イベントをブロードキャストし始める前に、[キューリスナ](/docs/{{version}}/queues)を設定し、実行する必要もあります。イベントのブロードキャストは、すべてキュージョブとして行われるため、アプリケーションのレスポンスタイムにはシリアスな影響はでません。

<a name="concept-overview"></a>
## 概論

LaravelのイベントブロードキャストはサーバサイドのLaravelイベントから、WebSocketに対する駆動ベースのアプローチを使っているあなたのクライアントサイドのJavaScriptアプリケーションへ、ブロードキャストできるようにします。現在、[Pusherチャンネル](https://pusher.com/channels)とRedisドライバーが用意されています。[Laravel Echo](#installing-laravel-echo) JavaScriptパッケージを使用したクライアントサイド上で、イベントは簡単に利用できます。

パブリック、もしくはプライベートに指定された「チャンネル」上で、イベントはブロードキャストされます。アプリケーションの全訪問者は、認証も認可も必要ないパブリックチャンネルを購入できます。しかし、プライベートチャンネルを購入するためには、認証され、そのチャンネルをリッスンできる認可が必要です。

> {tip} Pusherの代替になるPHPで動作するオープンソースを使用したい場合は、[laravel-websockets](https://github.com/beyondcode/laravel-websockets)パッケージをチェックしてください。

<a name="using-example-application"></a>
### サンプルアプリケーションの使用

イベントブロードキャストの各コンポーネントへ飛び込む前に、例としてeコマースショップを使い、ハイレベルな概念を把握しましょう。このドキュメント中の別のセクションで詳細を説明するため、[Pusherチャンネル](https://pusher.com/channels)と[Laravel Echo](#installing-laravel-echo)の設定についての詳細は省きます。

このアプリケーションでは、ユーザーに注文の発送状態を確認してもらうビューページがあるとしましょう。さらに、アプリケーションが発送状態を変更すると、`ShippingStatusUpdated`イベントが発行されるとしましょう。

    event(new ShippingStatusUpdated($update));

<a name="the-shouldbroadcast-interface"></a>
#### `ShouldBroadcast`インターフェイス

ユーザーがある注文を閲覧している時に、ビューの状態を変更するために、ユーザーがページを再読込しなくてはならないなんてしたくありません。代わりにアップデートがあることをアプリケーションへブロードキャストしたいわけです。そのため、`ShouldBroadcast`インターフェイスを実装した、`ShippingStatusUpdated`イベントを作成する必要があります。このインターフェイスはイベントが発行されると、ブロードキャストすることをLaravelへ指示しています。

    <?php

    namespace App\Events;

    use Illuminate\Broadcasting\Channel;
    use Illuminate\Broadcasting\InteractsWithSockets;
    use Illuminate\Broadcasting\PresenceChannel;
    use Illuminate\Broadcasting\PrivateChannel;
    use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
    use Illuminate\Queue\SerializesModels;

    class ShippingStatusUpdated implements ShouldBroadcast
    {
        /**
         * 発送状態更新の情報
         *
         * @var string
         */
        public $update;
    }

`ShouldBroadcast`インターフェイスはイベントで、`broadcastOn`メソッドを定義することを求めています。このメソッドはイベントをブロードキャストすべきチャンネルを返す責任を持っています。イベントクラスを生成すると、すでにこのメソッドは空のスタブクラスに作成されていますので、詳細を埋めるだけになっています。オーダーの発注者だけに状態の変更を見てもらいたいので、そのオーダーに紐付いたプライベートチャンネルへ、イベントをブロードキャストしましょう。

    /**
     * イベントをブロードキャストすべき、チャンネルの取得
     *
     * @return \Illuminate\Broadcasting\PrivateChannel
     */
    public function broadcastOn()
    {
        return new PrivateChannel('order.'.$this->update->order_id);
    }

<a name="example-application-authorizing-channels"></a>
#### 認証中チャンネル

プライベートチャンネルをリッスンするには、ユーザーは認可されている必要があることを思い出してください。`routes/channels.php`ファイルでチャンネルの認可ルールを定義してください。この例の場合、プライベート`order.1`チャンネルをリッスンしようとするユーザーは、実際にそのオーダーの発注者であることを確認しています。

    Broadcast::channel('order.{orderId}', function ($user, $orderId) {
        return $user->id === Order::findOrNew($orderId)->user_id;
    });

`channel`メソッドは引数を２つ取ります。チャンネルの名前と、ユーザーにそのチャネルをリッスンする認可があるかどうかを`true`か`false`で返すコールバックです。

認可コールバックは、最初の引数に現在認証中のユーザーを受け取ります。引き続き、追加のプレースホルダパラメータを指定します。この例の場合、チャンネル名中で"ID"の部分を表す、`{orderID}`プレースホルダーを使っています。

<a name="listening-for-event-broadcasts"></a>
#### イベントブロードキャストのリッスン

次に、皆さんのJavaScriptアプリケーションでイベントをリッスンします。このために、Laravel Echoが利用できます。最初に、プライベートチャンネルを購読するために、`private`メソッドを使います。それから、`ShippingStatusUpdated`イベントをリッスンするために、`listen`メソッドを使用します。デフォルトでは、イベントのpublicプロパティは、すべてブロードキャストイベントに含まれています。

    Echo.private('order.' + orderId)
        .listen('ShippingStatusUpdated', (e) => {
            console.log(e.update);
        });

<a name="defining-broadcast-events"></a>
## ブロードキャストイベントの定義

Laravelへイベントをブロードキャストすることを知らせるためには、そのイベントクラスで`Illuminate\Contracts\Broadcasting\ShouldBroadcast`インターフェイスを実装します。このインターフェイスは、フレームワークにより生成されたすべてのイベントクラスで、useされていますので、イベントへ簡単に追加できます。

`ShouldBroadcast`インターフェイスは、`broadcastOn`メソッド一つのみ実装を求めています。`broadcastOn`メソッドは、そのイベントをブロードキャストすべきチャンネルか、チャンネルの配列を返します。チャンネルは`Channel`、`PrivateChannel`、`PresenceChannel`のインスタンスです。`Channel`インスタンスはユーザーが行動するパブリックチャンネルを表しています。一方、`PrivateChannel`と`PresenceChannel`は、[チャンネル認可](#authorizing-channels)が必要な、プライベートチャンネルを表しています。

    <?php

    namespace App\Events;

    use App\Models\User;
    use Illuminate\Broadcasting\Channel;
    use Illuminate\Broadcasting\InteractsWithSockets;
    use Illuminate\Broadcasting\PresenceChannel;
    use Illuminate\Broadcasting\PrivateChannel;
    use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
    use Illuminate\Queue\SerializesModels;

    class ServerCreated implements ShouldBroadcast
    {
        use SerializesModels;

        public $user;

        /**
         * 新しいイベントインスタンスの生成
         *
         * @return void
         */
        public function __construct(User $user)
        {
            $this->user = $user;
        }

        /**
         * イベントをブロードキャストすべき、チャンネルの取得
         *
         * @return Channel|array
         */
        public function broadcastOn()
        {
            return new PrivateChannel('user.'.$this->user->id);
        }
    }

これで、あと必要なのは、通常通りに[イベントを発行](/docs/{{version}}/events)するだけです。イベントを発行すると、[キュージョブ](/docs/{{version}}/queues)が指定済みのドライバを通して、自動的にそのイベントをブロードキャストします。

<a name="broadcast-name"></a>
### ブロードキャスト名

デフォルトでLaravelはイベントのクラス名を使い、そのイベントをブロードキャストします。イベントに`broadcastAs`メソッドを定義することにより、ブロードキャスト名をカスタマイズできます。

    /**
     * イベントブロードキャスト名
     *
     * @return string
     */
    public function broadcastAs()
    {
        return 'server.created';
    }

`broadcastAs`メソッドを使い、ブロードキャスト名をカスタマイズする場合、`.`文字を先頭に付けたリスナを登録するのを忘れないでください。これによりそのイベントへ、アプリケーションの名前空間を付けないよう、Echoに指示します。

    .listen('.server.created', function (e) {
        ....
    });

<a name="broadcast-data"></a>
### ブロードキャストデータ

イベントがブロードキャストされると、イベントのペイロードとして`public`プロパティはすべて自動的にシリアライズされます。これによりJavaScriptアプリケーションより、publicデータにアクセスできます。ですから、たとえば、あるイベントにEloquentモデルを含むpublicの`$user`プロパティがあれば、そのイベントのブロードキャストペイロードは次のようになります。

    {
        "user": {
            "id": 1,
            "name": "Patrick Stewart"
            ...
        }
    }

しかしながら、ブロードキャストペイロードをより上手くコントロールしたければ、そのイベントへ`broadcastWith`メソッドを追加してください。このメソッドから、イベントペイロードとしてブロードキャストしたいデータの配列を返してください。

    /**
     * ブロードキャストするデータを取得
     *
     * @return array
     */
    public function broadcastWith()
    {
        return ['id' => $this->user->id];
    }

<a name="broadcast-queue"></a>
### ブロードキャストキュー

デフォルトでは各ブロードキャストイベントは、`queue.php`設定ファイルで指定されているデフォルトキュー接続の、デフォルトキューへ投入されます。イベントクラスの`broadcastQueue`プロパティを定義することにより、使用するキューをカスタマイズできます。このプロパティには、ブロードキャスト時に使用したいキューの名前を指定してください。

    /**
     * イベントを投入するキューの名前
     *
     * @var string
     */
    public $broadcastQueue = 'your-queue-name';

デフォルトキュードライバーの代わりに、`sync`キューを使いイベントをブロードキャストする場合、`ShouldBroadcast`の代わりに`ShouldBroadcastNow`インターフェイスを実装してください。

    <?php

    use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;

    class ShippingStatusUpdated implements ShouldBroadcastNow
    {
        //
    }
<a name="broadcast-conditions"></a>
### ブロードキャスト条件

指定した条件がtrueの場合のみ、ブロードキャストを行いたい場合もあるでしょう。イベントクラスへ、`broadcastWhen`メソッドを追加すれば、こうした条件を定義できます。

    /**
     * このイベントでブロードキャストするかを決定
     *
     * @return bool
     */
    public function broadcastWhen()
    {
        return $this->value > 100;
    }

<a name="authorizing-channels"></a>
## 認証中チャンネル

プライベートチャンネルでは、現在の認証ユーザーが実際にそのチャンネルをリッスンできるか、認可する必要があります。これは、Laravelアプリケーションへチャンネル名を含めたHTTPリクエストを作成し、アプリケーションにそのユーザーが、そのチャンネルをリッスンできるかを決めさせることで実現します。[Laravel Echo](#installing-laravel-echo)を使用する場合、プライベートチャンネルへの購入許可HTTPリクエストは、自動的に作成されます。しかし、そうしたリクエストに対してレスポンスする、ルートを確実に定義する必要があります。

<a name="defining-authorization-routes"></a>
### 認証ルート定義

嬉しいことに、Laravelでは、チャンネル認可にクエストに対するレスポンスのルート定義も簡単です。Laravelアプリケーションに含まれている`BroadcastServiceProvider`で、`Broadcast::routes`メソッドが呼びだされているのが見つかります。このメソッドが認可リクエストを処理する、`/broadcasting/auth`ルートを登録しています。

    Broadcast::routes();

`Broadcast::routes`メソッドは自動的に、そのルートを`web`ミドルウェアグループの中に設置しますが、割り付ける属性をカスタマイズしたければ、メソッドへルート属性の配列を渡すことができます。

    Broadcast::routes($attributes);

<a name="customizing-the-authorization-endpoint"></a>
#### 認可エンドポイントのカスタマイズ

デフォルトでは、チャンネルアクセスの認可にEchoは`/broadcasting/auth`エンドポイントを使用します。しかしながら、Echoインスタンスへ`authEndpoint`設定オプションを渡せば、独自の認可エンドポイントを指定できます。

    window.Echo = new Echo({
        broadcaster: 'pusher',
        key: 'your-pusher-channels-key',
        authEndpoint: '/custom/endpoint/auth'
    });

<a name="defining-authorization-callbacks"></a>
### 認証コールバック定義

次に、チャンネル認可を実際に行うロジックを定義する必要があります。アプリケーションに含まれる、`routes/channels.php`ファイルで行います。このメソッドの中で、`Broadcast::channel`メソッドを使い、チャンネル認可コールバックを登録します。

    Broadcast::channel('order.{orderId}', function ($user, $orderId) {
        return $user->id === Order::findOrNew($orderId)->user_id;
    });

`channel`メソッドは引数を２つ取ります。チャンネルの名前と、ユーザーにそのチャネルをリッスンする認可があるかどうかを`true`か`false`で返すコールバックです。

認可コールバックは、最初の引数に現在認証中のユーザーを受け取ります。引き続き、追加のプレースホルダパラメータを指定します。この例の場合、チャンネル名中で"ID"の部分を表す、`{orderID}`プレースホルダーを使っています。

<a name="authorization-callback-model-binding"></a>
#### 認証コールバックモデル結合

HTTPルートと同様にチャンネルルートでも、暗黙あるいは明白な[ルートモデル結合](/docs/{{version}}/routing#route-model-binding)を利用できます。たとえば、文字列や数値の注文IDを受け取る代わりに、実際の`Order`モデルインスタンスを要求できます。

    use App\Models\Order;

    Broadcast::channel('order.{order}', function ($user, Order $order) {
        return $user->id === $order->user_id;
    });

<a name="authorization-callback-authentication"></a>
#### 認可コールバックと認証

プライベートとプレゼンス・ブロードキャスト・チャンネルは、アプリケーションのデフォルト認証ガードにより、現在のユーザーを認証します。ユーザーが認証されていない場合、チャンネルの許可は自動的に拒否され、認可コールバックは実行されません。しかし必要ならば、受信したリクエストを認証するカスタムガードを複数指定可能です。

    Broadcast::channel('channel', function () {
        // ...
    }, ['guards' => ['web', 'admin']]);

<a name="defining-channel-classes"></a>
### チャンネル名の登録

アプリケーションで多くのチャンネルを利用していると、`routes/channels.php`ファイルは膨大になってしまいます。認証チャンネルのクロージャを使用する代わりに、チャンネルクラスを使用するのが良いでしょう。チャンネルクラスを生成するには、`make:channel`　Aritisanコマンドが使用できます。このコマンドは、新しいチャンネルクラスを`App/Broadcasting`ディレクトリへ生成します。

    php artisan make:channel OrderChannel

次に、チャンネルを`routes/channels.php`ファイルで登録します。

    use App\Broadcasting\OrderChannel;

    Broadcast::channel('order.{order}', OrderChannel::class);

最後に、チャンネルの認証ロジックをチャンネルクラスの`join`へ記述します。典型的な場合ではチャンネル認証クロージャに設置するのと同じロジックをこの`join`メソッドに設置します。チャンネルモデル結合の利点も利用できます。

    <?php

    namespace App\Broadcasting;

    use App\Models\Order;
    use App\Models\User;

    class OrderChannel
    {
        /**
         * 新しいチャンネルインスタンスの生成
         *
         * @return void
         */
        public function __construct()
        {
            //
        }

        /**
         * ユーザーのチャンネルへアクセスを認証
         *
         * @param  \App\Models\User  $user
         * @param  \App\Models\Order  $order
         * @return array|bool
         */
        public function join(User $user, Order $order)
        {
            return $user->id === $order->user_id;
        }
    }

> {tip} Laravelの他のクラスと同様に、チャンネルクラスは自動的に[サービスコンテナ](/docs/{{version}}/container)により、依存を解決されます。そのため、コンストラクタでタイプヒントにより、チャンネルで必要な依存を指定できます。

<a name="broadcasting-events"></a>
## ブロードキャストイベント

イベントを定義し、`ShouldBroadcast`インターフェイスを実装したら、後は`event`関数を使い、イベントを発行するだけです。イベントディスパッチャは、そのイベントが`ShouldBroadcast`インターフェイスにより印付けられていることに注目しており、ブロードキャストするためにイベントをキューへ投入します。

    event(new ShippingStatusUpdated($update));

<a name="only-to-others"></a>
### 認証中ユーザーの回避

イベントブロードキャストを使用するアプリケーションを構築しているとき、`event`関数を`broadcast`関数へ置き換えることもできます。`event`関数と同様に、`broadcast`関数もイベントをサーバサイドリスナへディスパッチします。

    broadcast(new ShippingStatusUpdated($update));

しかし、`broadcast`関数には、ブロードキャストの受取人から現在のユーザーを除外できる、`toOthers`メソッドが用意されています。

    broadcast(new ShippingStatusUpdated($update))->toOthers();

`toOthers`メソッドをいつ使うのかをよく理解してもらうため、タスク名を入力してもらうことにより新しいタスクをユーザーが作成できる、タスクリストアプリケーションを想像してください。タスクを作成するためにアプリケーションは、タスクの生成をブロードキャストし、新しいタスクのJSON表現を返す、`/task`エンドポイントへリクエストを作成するでしょう。JavaScriptアプリケーションがそのエンドポイントからレスポンスを受け取る時、その新しいタスクをタスクリストへ直接挿入するでしょう。次のようにです。

    axios.post('/task', task)
        .then((response) => {
            this.tasks.push(response.data);
        });

しかしながら、タスクの生成もブロードキャストしていることを思い出してください。JavaScriptアプリケーションがこのイベントをタスクリストへタスクを追加するためにリッスンしている場合、リストにそのタスクを二重登録してしまいます。ひとつはエンドポイントから、もう一つはブロードキャストからです。これを解決するには、toOthers`メソッドを使用し、ブロードキャスターへそのイベントを現在のユーザーに対してブロードキャストしないように指示してください。

> {note} イベントで`toOthers`メソッドを呼び出すには、`Illuminate\Broadcasting\InteractsWithSockets`トレイトを使用する必要があります。

<a name="only-to-others-configuration"></a>
#### 設定

Laravel Echoインスタンスを初期化する時、接続へソケットIDをアサインします。[Vue](https://vuejs.org)と[Axios](https://github.com/mzabriskie/axios)を使用していれば、`X-Socket-ID`ヘッダとして、送信する全リクエストへ自動的に付加されます。そのため、`toOthers`メソッドを呼び出す場合、LaravelはヘッダからソケットIDを取り除き、そのソケットIDを使い全接続へブロードキャストしないように、ブロードキャスタに対し指示します。

VueとAxiosを使用しない場合、JavaScriptアプリケーションで`X-Socket-ID`ヘッダを送信するように、設定する必要があります。ソケットIDは`Echo.socketId`メソッドにより取得できます。

    var socketId = Echo.socketId();

<a name="receiving-broadcasts"></a>
## ブロードキャストの受け取り

<a name="installing-laravel-echo"></a>
### Laravel Echoのインストール

Laravel EchoはJavaScriptライブラリで、チャンネルの購読とLaravelによるイベントブロードキャストのリッスンを苦労なしに実現してくれます。EchoはNPMパッケージマネージャにより、インストールします。以降の例で、Pusherチャンネルブロードキャストを使用する予定のため、`pusher-js`パッケージもインストールしています。

    npm install --save-dev laravel-echo pusher-js

Echoがインストールできたら、アプリケーションのJavaScriptで、真新しいEchoインスタンスを作成する準備が整いました。これを行うには、Laravelフレームワークに含まれている、`resources/js/bootstrap.js`ファイルの最後が、良いでしょう。

    import Echo from "laravel-echo"

    window.Echo = new Echo({
        broadcaster: 'pusher',
        key: 'your-pusher-channels-key'
    });

`pusher`コネクタを使うEchoインスタンスを作成するときには、`cluster`と同時にTLS接続を行うかどうかを指定することもできます。（デフォルトはTLS接続を使います。`forceTLS`が`false`の場合は非TLS接続設定です。非TLS接続設定では、そのページをHTTPでロードするか、TLS接続に失敗した時のフォールバックとしてHTTPで接続します。）

    window.Echo = new Echo({
        broadcaster: 'pusher',
        key: 'your-pusher-channels-key',
        cluster: 'eu',
        forceTLS: true
    });

<a name="using-an-existing-client-instance"></a>
#### 既存クライアントインスタンスの利用

Echoで使用したいPusherチャンネルやSocket.ioクライアントを前もって用意してあれば、`client`設定オプションによりEchoへ指定できます。

    const client = require('pusher-js');

    window.Echo = new Echo({
        broadcaster: 'pusher',
        key: 'your-pusher-channels-key',
        client: client
    });

<a name="listening-for-events"></a>
### イベントのリッスン

インストールが済み、Echoをインスタンス化したら、イベントブロードキャストをリスニングする準備が整いました。最初に、`channel`メソッドを使い、チャンネルインスタンスを取得し、それから`listen`メソッドで特定のイベントをリッスンしてください。

    Echo.channel('orders')
        .listen('OrderShipped', (e) => {
            console.log(e.order.name);
        });

プライベートチャンネルのイベントをリッスンしたい場合は、`private`メソッドを代わりに使用してください。一つのチャンネルに対し、複数のイベントをリッスンする場合は、`listen`メソッドをチェーンして呼び出してください。

    Echo.private('orders')
        .listen(...)
        .listen(...)
        .listen(...);

<a name="leaving-a-channel"></a>
### チャンネルの離脱

チャンネルを離脱するには、Echoインスタンスの`leaveChannel`メソッドを呼び出してください。

    Echo.leaveChannel('orders');

チャンネルを離脱し、関連するプライベートチャンネル、現在のチャンネルも離脱したい場合は、`leave`メソッドを呼び出してください。

    Echo.leave('orders');

<a name="namespaces"></a>
### 名前空間

上の例で、イベントクラスの完全な名前空間を指定していないことに、皆さん気がついたでしょう。その理由は、Echoはイベントが`App\Events`名前空間へ設置されると仮定しているからです。しかし、ルートの名前空間を設定変更している場合は、Echoのインスタンス化時に、`namespace`設定オプションを渡してください。

    window.Echo = new Echo({
        broadcaster: 'pusher',
        key: 'your-pusher-channels-key',
        namespace: 'App.Other.Namespace'
    });

もしくは、Echoを使用し購入する時点で、イベントクラスへ`.`を使い、プリフィックスを付けてください。

    Echo.channel('orders')
        .listen('.Namespace\Event\Class', (e) => {
            //
        });

<a name="presence-channels"></a>
## プレゼンスチャンネル

プレゼンスチャンネルは、誰がチャンネルを購入しているかの情報を取得できる機能を提供しつつ、安全なプライベートチャンネルを構築します。これにより、他のユーザーが同じページを閲覧していることを知らせるような、パワフルでコラボレート可能な機能を持つアプリケーションを簡単に構築できます。

<a name="authorizing-presence-channels"></a>
### プレゼンスチャンネルの許可

全プレゼンスチャンネルは、プライベートチャンネルでもあります。そのため、ユーザーは[アクセスする許可](#authorizing-channels)が必要です。プレゼンスチャンネルの認可コールバックを定義する場合、ユーザーがチャンネルへ参加する許可があるならば、`true`をリターンしないでください。代わりに、ユーザー情報の配列を返してください。

認可コールバックから返されるデータは、JavaScriptアプリケーションのプレゼンスチャンネルイベントリスナで利用できるようになります。ユーザーがプレゼンスチャンネルへ参加する許可がない場合は、`false`か`null`を返してください。

    Broadcast::channel('chat.{roomId}', function ($user, $roomId) {
        if ($user->canJoinRoom($roomId)) {
            return ['id' => $user->id, 'name' => $user->name];
        }
    });

<a name="joining-presence-channels"></a>
### プレゼンスチャンネルへの参加

プレゼンスチャンネルへ参加するには、Echoの`join`メソッドを使用します。`join`メソッドは、すでに説明した`listen`メソッドに付け加え、`here`、`joining`、`leaving`イベントを購入できるようになっている、`PresenceChannel`実装を返します。

    Echo.join('chat.' + roomId)
        .here((users) => {
            //
        })
        .joining((user) => {
            console.log(user.name);
        })
        .leaving((user) => {
            console.log(user.name);
        });

`here`コールバックはチャンネル参加に成功すると、すぐに実行されます。そして、このチャンネルを現在購入している、他の全ユーザー情報を含む配列を返します。`joining`メソッドは、チャンネルに新しいユーザーが参加した時に実行されます。一方の`leaving`メソッドは、ユーザーがチャンネルから離脱した時に実行されます。

<a name="broadcasting-to-presence-channels"></a>
### プレゼンスチャンネルへのブロードキャスト

パブリックやプライベートチャンネルと同じように、プレゼンスチャンネルはイベントを受け取ります。チャットルームを例にしましょう。その部屋のプレゼンスチャンネルへの`NewMessage`イベントがブロードキャストされるのを受け取りたいとします。そのために、イベントの`broadcastOn`メソッドで、`PresenceChannel`のインスタンスを返します。

    /**
     * イベントをブロードキャストすべき、チャンネルの取得
     *
     * @return Channel|array
     */
    public function broadcastOn()
    {
        return new PresenceChannel('room.'.$this->message->room_id);
    }

パブリックやプライベートイベントと同様に、プレゼンスチャンネルイベントは`broadcast`関数を使用しブロードキャストします。他のイベントと同様に、ブロードキャストが届けるイベントから現在のユーザーを除くため、`[toOthers]`メソッドも利用できます。

    broadcast(new NewMessage($message));

    broadcast(new NewMessage($message))->toOthers();

Echoの`listen`メソッドにより、参加イベントをリッスンできます。

    Echo.join('chat.' + roomId)
        .here(...)
        .joining(...)
        .leaving(...)
        .listen('NewMessage', (e) => {
            //
        });

<a name="client-events"></a>
## クライアントイベント

> {tip} [Pusherチャンネル](https://pusher.com/channels)を使用する場合、クライアントイベントを送信するために、[application dashboard](https://dashboard.pusher.com/)の"App Settings"にある、"Client Events"オプションを有効にしてください。

Laravelアプリケーションにまったく関係ないイベントを他の接続クライアントへブロードキャストしたい場合もあることでしょう。これはとくにアプリケーションユーザーへ他のユーザーがキーボードをタイプしているメッセージをページ中で表示するための「タイプ中…」通知をする場合に便利です。

クライアントイベントをブロードキャストするには、Echoの`whisper`メソッドを使用します。

    Echo.private('chat')
        .whisper('typing', {
            name: this.user.name
        });

クライアントイベントをリッスンするには、`listenForWhisper`メソッドを使います。

    Echo.private('chat')
        .listenForWhisper('typing', (e) => {
            console.log(e.name);
        });

<a name="notifications"></a>
## 通知

イベントブロードキャストと[通知](/docs/{{version}}/notifications)をペアリングすることで、JavaScriptアプリケーションはページを再読み込みする必要なく、新しい通知を受け取ることができます。最初に、[ブロードキャスト通知チャンネル](/docs/{{version}}/notifications#broadcast-notifications)の使用法ドキュメントをよく読んでください。

ブロードキャストチャンネルを使用する通知の設定を終えたら、Echoの`notification`メソッドを使用し、ブロードキャストイベントをリッスンできます。チャンネル名は、通知を受けるエンティティのクラス名と一致している必要があることを覚えておいてください。

    Echo.private(`App.Models.User.${userId}`)
        .notification((notification) => {
            console.log(notification.type);
        });

上記の例の場合、「ブロードキャスト」チャンネルを通じ、`App\Models\User`インスタンスへ送られる通知は、全部コールバックにより受け取られます。`App.Models.User.{id}`チャンネルのチャンネル認可コールバックは、Laravelフレームワークに用意されている、デフォルトの`BroadcastServiceProvider`に含まれています。
