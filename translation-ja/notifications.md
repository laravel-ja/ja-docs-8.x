# 通知

- [イントロダクション](#introduction)
- [通知の生成](#generating-notifications)
- [通知の送信](#sending-notifications)
    - [notifiableトレイトの使用](#using-the-notifiable-trait)
    - [Notificationファサードの使用](#using-the-notification-facade)
    - [配信チャンネルの指定](#specifying-delivery-channels)
    - [通知のキューイング](#queueing-notifications)
    - [オンデマンド通知](#on-demand-notifications)
- [メール通知](#mail-notifications)
    - [メールメッセージのフォーマット](#formatting-mail-messages)
    - [送信者のカスタマイズ](#customizing-the-sender)
    - [受信者のカスタマイズ](#customizing-the-recipient)
    - [件名のカスタマイズ](#customizing-the-subject)
    - [Mailerのカスタマイズ](#customizing-the-mailer)
    - [テンプレートのカスタマイズ](#customizing-the-templates)
    - [添付](#mail-attachments)
    - [メール通知のプレビュー](#previewing-mail-notifications)
- [Markdownメール通知](#markdown-mail-notifications)
    - [メッセージ生成](#generating-the-message)
    - [メッセージ記述](#writing-the-message)
    - [コンポーネントカスタマイズ](#customizing-the-components)
- [データベース通知](#database-notifications)
    - [事前要件](#database-prerequisites)
    - [データベース通知のフォーマット](#formatting-database-notifications)
    - [通知へのアクセス](#accessing-the-notifications)
    - [Readとしての通知作成](#marking-notifications-as-read)
- [ブロードキャスト通知](#broadcast-notifications)
    - [事前要件](#broadcast-prerequisites)
    - [ブロードキャスト通知のフォーマット](#formatting-broadcast-notifications)
    - [通知のリッスン](#listening-for-notifications)
- [SMS通知](#sms-notifications)
    - [事前要件](#sms-prerequisites)
    - [SMS通知のフォーマット](#formatting-sms-notifications)
    - [ショートコード通知のフォーマット](#formatting-shortcode-notifications)
    - [発信元電話番号のカスタマイズ](#customizing-the-from-number)
    - [SMS通知のルート指定](#routing-sms-notifications)
- [Slack通知](#slack-notifications)
    - [事前要件](#slack-prerequisites)
    - [Slack通知のフォーマット](#formatting-slack-notifications)
    - [Slack添付](#slack-attachments)
    - [Slack通知のルート指定](#routing-slack-notifications)
- [通知のローカライズ](#localizing-notifications)
- [通知イベント](#notification-events)
- [カスタムチャンネル](#custom-channels)

<a name="introduction"></a>
## イントロダクション

[メールの送信](/docs/{{version}}/mail)のサポートに加えて、LaravelはメールやSMS（[Vonage](https://www.vonage.com/communications-apis/)経由、以前はNexmoとして知られていました）および[Slack](https://slack.com)など、さまざまな配信チャンネルで通知を送信するためのサポートを提供しています。さらに、さまざまな[コミュニティが構築した通知チャンネル](https://laravel-notification-channels.com/about/#suggesting-a-new-channel)が作成され、数十の異なるチャンネルで通知を送信できます！通知はWebインターフェイスに表示するため、データベースに保存される場合もあります。

通常、通知はアプリケーションで何かが起きたことをユーザーへ知らせる、短い情報メッセージです。たとえば、課金アプリを作成しているなら、メールとSMSチャンネルで「課金支払い」を送信できます。

<a name="generating-notifications"></a>
## 通知の生成

Laravelでは、各通知は通常、`app/Notifications`ディレクトリに保存される単一のクラスで表します。アプリケーションにこのディレクトリが存在しなくても心配しないでください。`make:notification` Artisanコマンドを実行すると作成されます。

    php artisan make:notification InvoicePaid

このコマンドは `app/Notifications`ディレクトリに新しい通知クラスを配置します。各通知クラスは`via`メソッドと`toMail`や`toDatabase`などのメッセージ構築メソッドを含み、通知を特定のチャンネルに合わせたメッセージに変換します。

<a name="sending-notifications"></a>
## 通知の送信

<a name="using-the-notifiable-trait"></a>
### Notifiableトレイトの使用

通知は、`Notifiable`トレイトの`notify`メソッドを使用する方法と、`Notification`[ファサード](/docs/{{version}}/facades)を使用する方法の２つの方法で送信できます。`Notizable`トレイトは、アプリケーションの`App\Models\User`モデルにデフォルトで含まれています。

    <?php

    namespace App\Models;

    use Illuminate\Foundation\Auth\User as Authenticatable;
    use Illuminate\Notifications\Notifiable;

    class User extends Authenticatable
    {
        use Notifiable;
    }

このトレイトが提供する`notify`メソッドは、通知インスタンスを引数に受けます。

    use App\Notifications\InvoicePaid;

    $user->notify(new InvoicePaid($invoice));

> {tip} どのモデルでも`Notifiable`トレイトを使用できることを忘れないでください。`User`モデルに含めるだけに限定されません。

<a name="using-the-notification-facade"></a>
### Notificationファサードの使用

別のやり方として、`Notification`[ファサード](/docs/{{version}}/facades)を介して通知を送信することもできます。このアプローチは、ユーザーのコレクションなど、複数の通知エンティティに通知を送信する必要がある場合に役立ちます。ファサードを使用して通知を送信するには、すべてのnotifiableエンティティと通知インスタンスを`send`メソッドに渡します。

    use Illuminate\Support\Facades\Notification;

    Notification::send($users, new InvoicePaid($invoice));

<a name="specifying-delivery-channels"></a>
### 配信チャンネルの指定

通知を配信するチャンネルを指定するため、すべての通知クラスは`via`メソッドを持っています。通知は`mail`、`database`、`broadcast`、`nexmo`、`slack`へ送れるようになっています。

> {tip} TelegramやPusherのような、他の配信チャンネルを利用したい場合は、コミュニティが管理している、[Laravel Notification Channels website](http://laravel-notification-channels.com)をご覧ください。

`via`メソッドは、通知を送っているクラスのインスタンスである、`$notifiable`インスタンスを引数に受け取ります。`$notifiable`を使い、通知をどこに配信するチャンネルなのかを判定できます。

    /**
     * 通知の配信チャンネルを取得
     *
     * @param  mixed  $notifiable
     * @return array
     */
    public function via($notifiable)
    {
        return $notifiable->prefers_sms ? ['nexmo'] : ['mail', 'database'];
    }

<a name="queueing-notifications"></a>
### 通知のキューイング

> {note} 通知をキューへ投入する前に、キューを設定して[ワーカを起動](/docs/{{version}}/queues)する必要があります。

通知の送信には時間がかかる場合があります。特に、チャンネルが通知を配信するために外部API呼び出しを行う必要がある場合に当てはまります。アプリケーションのレスポンス時間を短縮するには、クラスに`ShouldQueue`インターフェイスと`Queueable`トレイトを追加して、通知をキューに入れてください。インターフェイスとトレイトは、`make:notification`コマンドを使用して生成されたすべての通知であらかじめインポートされているため、すぐに通知クラスに追加できます。

    <?php

    namespace App\Notifications;

    use Illuminate\Bus\Queueable;
    use Illuminate\Contracts\Queue\ShouldQueue;
    use Illuminate\Notifications\Notification;

    class InvoicePaid extends Notification implements ShouldQueue
    {
        use Queueable;

        // ...
    }

`ShouldQueue`インターフェイスを通知クラスへ追加したら、通常通りに送信してください。Laravelはクラスの`ShouldQueue`インターフェイスを見つけ、自動的に通知の配信をキューへ投入します。

    $user->notify(new InvoicePaid($invoice));

通知の配信を遅らせたい場合、`delay`メソッドを通知のインスタンスへチェーンしてください。

    $delay = now()->addMinutes(10);

    $user->notify((new InvoicePaid($invoice))->delay($delay));

特定のチャンネルの遅​​延量を指定するため、配列を`delay`メソッドに渡せます。

    $user->notify((new InvoicePaid($invoice))->delay([
        'mail' => now()->addMinutes(5),
        'sms' => now()->addMinutes(10),
    ]));

通知をキューへ投入すると、受信者とチャンネルの組み合わせごとにキュー投入済みジョブが作成されます。たとえば、通知に３つの受信者と２つのチャンネルがある場合、６つのジョブがキューにディスパッチされます。

<a name="customizing-the-notification-queue-connection"></a>
#### 通知キュー接続のカスタマイズ

キューへ投入した通知は、アプリケーションのデフォルトのキュー接続を使用してキュー投入します。特定の通知に別の接続を使用する必要がある場合は、通知クラスに`$connection`プロパティを定義します。

    /**
     * 通知をキューに入れるときに使用するキュー接続名
     *
     * @var string
     */
    public $connection = 'redis';

<a name="customizing-notification-channel-queues"></a>
#### 通知チャンネルキューのカスタマイズ

各通知チャンネルが使用し、その通知がサポートしている特定のキューを指定する場合、通知へ`viaQueues`メソッドを定義してください。このメソッドはチャンネル名／キュー名のペアの配列を返してください。

    /**
     * 各通知チャンネルで使用するキューを判断。
     *
     * @return array
     */
    public function viaQueues()
    {
        return [
            'mail' => 'mail-queue',
            'slack' => 'slack-queue',
        ];
    }

<a name="queued-notifications-and-database-transactions"></a>
#### キュー投入する通知とデータベーストランザクション

キューへ投入した通知がデータベーストランザクション内でディスパッチされると、データベーストランザクションがコミットされる前にキューによって処理される場合があります。これが発生した場合、データベーストランザクション中にモデルまたはデータベースレコードに加えた更新は、データベースにまだ反映されていない可能性があります。さらに、トランザクション内で作成されたモデルまたはデータベースレコードは、データベースに存在しない可能性があります。通知がこれらのモデルに依存している場合、キューに入れられた通知を送信するジョブが処理されるときに予期しないエラーが発生する可能性があります。

キュー接続の`after_commit`設定オプションが`false`に設定されている場合でも、通知クラスで`$afterCommit`プロパティを定義することにより、開いているすべてのデータベーストランザクションがコミットされた後に特定のキュー通知をディスパッチする必要があることを示すことができます。

    <?php

    namespace App\Notifications;

    use Illuminate\Bus\Queueable;
    use Illuminate\Contracts\Queue\ShouldQueue;
    use Illuminate\Notifications\Notification;

    class InvoicePaid extends Notification implements ShouldQueue
    {
        use Queueable;

        public $afterCommit = true;
    }

> {tip} この問題の回避方法の詳細は、[キュー投入されるジョブとデータベーストランザクション](/docs/{{version}}/queues#jobs-and-database-transactions)に関するドキュメントを確認してください。

<a name="on-demand-notifications"></a>
### オンデマンド通知

アプリケーションの「ユーザー」として保存されていない人に通知を送信する必要がある場合があります。`Notification`ファサードの`route`メソッドを使用して、通知を送信する前にアドホックな通知ルーティング情報を指定します。

    Notification::route('mail', 'taylor@example.com')
                ->route('nexmo', '5555555555')
                ->route('slack', 'https://hooks.slack.com/services/...')
                ->notify(new InvoicePaid($invoice));

<a name="mail-notifications"></a>
## メール通知

<a name="formatting-mail-messages"></a>
### メールメッセージのフォーマット

通知が電子メール送信をサポートしている場合は、通知クラスで`toMail`メソッドを定義する必要があります。このメソッドは`$notifiable`エンティティを受け取り、`Illuminate\Notifications\Messages\MailMessage`インスタンスを返す必要があります。

`MailMessage`クラスには、トランザクションメールメッセージの作成に役立ついくつかの簡単なメソッドが含まれています。メールメッセージには、「行動を促すフレーズ」だけでなく、テキスト行も含まれる場合があります。`toMail`メソッドの例を見てみましょう。

    /**
     * 通知のメールプレゼンテーションを取得
     *
     * @param  mixed  $notifiable
     * @return \Illuminate\Notifications\Messages\MailMessage
     */
    public function toMail($notifiable)
    {
        $url = url('/invoice/'.$this->invoice->id);

        return (new MailMessage)
                    ->greeting('Hello!')
                    ->line('課金が支払われました。')
                    ->action('インボイス確認', $url)
                    ->line('私達のアプリケーションをご利用いただき、ありがとうございます。');
    }

> {tip} `toMail`メソッドの中で、`$this->invoice->id`を使っていることに注意してください。通知メッセージを生成するために必要な情報は、どんなものでも通知のコンストラクタへ渡せます。

この例では、挨拶、テキスト行、行動を促すフレーズ、そして別のテキスト行を登録します。`MailMessage`オブジェクトが提供するこれらのメソッドにより、小さなトランザクションメールを簡単かつ迅速にフォーマットできます。次に、メールチャンネルは、メッセージコンポーネントを、平文テキストと対応する美しいレスポンス性の高いHTML電子メールテンプレートに変換します。`mail`チャンネルが生成する電子メールの例を次に示します。

<img src="https://laravel.com/img/docs/notification-example-2.png">

> {tip} メール通知を送信するときは、必ず`config/app.php`設定ファイルで`name`設定オプションを設定してください。この値は、メール通知メッセージのヘッダとフッターに使用されます。

<a name="other-mail-notification-formatting-options"></a>
#### その他のメール通知フォーマットオプション

通知クラスの中にテキストの「行(line)」を定義する代わりに、通知メールをレンダーするためのカスタムテンプレートを`view`メソッドを使い、指定できます。

    /**
     * 通知のメールプレゼンテーションを取得
     *
     * @param  mixed  $notifiable
     * @return \Illuminate\Notifications\Messages\MailMessage
     */
    public function toMail($notifiable)
    {
        return (new MailMessage)->view(
            'emails.name', ['invoice' => $this->invoice]
        );
    }

`view`メソッドに与える配列の２番目の要素としてビュー名を渡すことにより、メールメッセージの平文テキストビューを指定できます。

    /**
     * 通知のメールプレゼンテーションを取得
     *
     * @param  mixed  $notifiable
     * @return \Illuminate\Notifications\Messages\MailMessage
     */
    public function toMail($notifiable)
    {
        return (new MailMessage)->view(
            ['emails.name.html', 'emails.name.plain'],
            ['invoice' => $this->invoice]
        );
    }

さらに、`toMail`メソッドから[Mailableオブジェクト](/docs/{{version}}/mail)をそのまま返すこともできます。

    use App\Mail\InvoicePaid as InvoicePaidMailable;

    /**
     * 通知のメールプレゼンテーションを取得
     *
     * @param  mixed  $notifiable
     * @return Mailable
     */
    public function toMail($notifiable)
    {
        return (new InvoicePaidMailable($this->invoice))
                    ->to($notifiable->email);
    }

<a name="error-messages"></a>
#### エラーメッセージ

一部の通知は、請求書の支払いの失敗などのエラーをユーザーに通知します。メッセージを作成するときに`error`メソッドを呼び出すことにより、メールメッセージがエラーに関するものであることを示すことができます。メールメッセージで`error`メソッドを使用すると、行動を促すフレーズのボタンが黒ではなく赤になります。

    /**
     * 通知のメールプレゼンテーションを取得
     *
     * @param  mixed  $notifiable
     * @return \Illuminate\Notifications\Message
     */
    public function toMail($notifiable)
    {
        return (new MailMessage)
                    ->error()
                    ->subject('Notification Subject')
                    ->line('...');
    }

<a name="customizing-the-sender"></a>
### 送信者のカスタマイズ

デフォルトのメール送信者／Fromアドレスは、`config/mail.php`設定ファイルで定義されています。しかし、特定の通知でFromアドレスを指定する場合は、`from`メソッドで指定します。

    /**
     * 通知のメールプレゼンテーションを取得
     *
     * @param  mixed  $notifiable
     * @return \Illuminate\Notifications\Messages\MailMessage
     */
    public function toMail($notifiable)
    {
        return (new MailMessage)
                    ->from('barrett@example.com', 'Barrett Blair')
                    ->line('...');
    }

<a name="customizing-the-recipient"></a>
### 受信者のカスタマイズ

`mail`チャンネルを介して通知を送信すると、通知システムは通知エンティティの`email`プロパティを自動的に検索します。通知エンティティで`routeNotificationForMail`メソッドを定義することにより、通知の配信に使用される電子メールアドレスをカスタマイズできます。

    <?php

    namespace App\Models;

    use Illuminate\Foundation\Auth\User as Authenticatable;
    use Illuminate\Notifications\Notifiable;

    class User extends Authenticatable
    {
        use Notifiable;

        /**
         * メールチャンネルに対する通知をルートする
         *
         * @param  \Illuminate\Notifications\Notification  $notification
         * @return array|string
         */
        public function routeNotificationForMail($notification)
        {
            // メールアドレスのみを返す場合
            return $this->email_address;

            // メールアドレスと名前を返す場合
            return [$this->email_address => $this->name];
        }
    }

<a name="customizing-the-subject"></a>
### 件名のカスタマイズ

デフォルトでは、電子メールの件名は「タイトルケース」にフォーマットされた通知のクラス名です。したがって、通知クラスの名前が`InvoicePaid`の場合、メールの件名は`Invoice Paid`になります。メッセージに別の件名を指定する場合は、メッセージを作成するときに「subject」メソッドを呼び出します。

    /**
     * 通知のメールプレゼンテーションを取得
     *
     * @param  mixed  $notifiable
     * @return \Illuminate\Notifications\Messages\MailMessage
     */
    public function toMail($notifiable)
    {
        return (new MailMessage)
                    ->subject('Notification Subject')
                    ->line('...');
    }

<a name="customizing-the-mailer"></a>
### Mailerのカスタマイズ

デフォルトでは、電子メール通知は、`config/mail.php`設定ファイルで定義しているデフォルトのメーラーを使用して送信されます。ただし、メッセージの作成時に`mailer`メソッドを呼び出すことにより、実行時に別のメーラーを指定できます。

    /**
     * 通知のメールプレゼンテーションを取得
     *
     * @param  mixed  $notifiable
     * @return \Illuminate\Notifications\Messages\MailMessage
     */
    public function toMail($notifiable)
    {
        return (new MailMessage)
                    ->mailer('postmark')
                    ->line('...');
    }

<a name="customizing-the-templates"></a>
### テンプレートのカスタマイズ

通知パッケージのリソースをリソース公開することにより、メール通知で使用されるHTMLと平文テキストのテンプレートを変更することが可能です。次のコマンドを実行した後、メール通知のテンプレートは`resources/views/vendor/notifications`ディレクトリ下に作成されます。

    php artisan vendor:publish --tag=laravel-notifications

<a name="mail-attachments"></a>
### 添付

電子メール通知に添付ファイルを追加するには、メッセージの作成中に`attach`メソッドを使用します。`attach`メソッドは、ファイルへの絶対パスを最初の引数に受けます。

    /**
     * 通知のメール表現の取得
     *
     * @param  mixed  $notifiable
     * @return \Illuminate\Notifications\Messages\MailMessage
     */
    public function toMail($notifiable)
    {
        return (new MailMessage)
                    ->greeting('Hello!')
                    ->attach('/path/to/file');
    }

メッセージにファイルを添付するとき、`attach`メソッドの第２引数として配列を渡し、表示名やMIMEタイプの指定もできます。

    /**
     * 通知のメール表現の取得
     *
     * @param  mixed  $notifiable
     * @return \Illuminate\Notifications\Messages\MailMessage
     */
    public function toMail($notifiable)
    {
        return (new MailMessage)
                    ->greeting('Hello!')
                    ->attach('/path/to/file', [
                        'as' => 'name.pdf',
                        'mime' => 'application/pdf',
                    ]);
    }

Mailableオブジェクトにファイルを添付するのとは異なり、`attachFromStorage`を使用してストレージディスクから直接ファイルを添付することはできません。むしろ、ストレージディスク上のファイルへの絶対パスを指定して`attach`メソッドを使用する必要があります。または、`toMail`メソッドから[mailable](/docs/{{version}}/mail#generated-mailables)を返すこともできます。

    use App\Mail\InvoicePaid as InvoicePaidMailable;

    /**
     * 通知のメール表現の取得
     *
     * @param  mixed  $notifiable
     * @return Mailable
     */
    public function toMail($notifiable)
    {
        return (new InvoicePaidMailable($this->invoice))
                    ->to($notifiable->email)
                    ->attachFromStorage('/path/to/file');
    }

<a name="raw-data-attachments"></a>
#### 素のデータの添付

`attachData`メソッドを使用して、生のバイト文字列を添付ファイルとして添付できます。`attachData`メソッドを呼び出すときは、添付ファイルへ割り当てる必要のあるファイル名を指定する必要があります。

    /**
     * 通知のメール表現の取得
     *
     * @param  mixed  $notifiable
     * @return \Illuminate\Notifications\Messages\MailMessage
     */
    public function toMail($notifiable)
    {
        return (new MailMessage)
                    ->greeting('Hello!')
                    ->attachData($this->pdf, 'name.pdf', [
                        'mime' => 'application/pdf',
                    ]);
    }

<a name="previewing-mail-notifications"></a>
### メール通知のプレビュー

メール通知テンプレートを設計するときは、通常のBladeテンプレートのように、レンダリングしたメールメッセージをブラウザですばやくプレビューできると便利です。このため、Laravelはメール通知によって生成したメールメッセージをルートクロージャまたはコントローラから直接返すことができます。`MailMessage`が返されると、ブラウザにレンダリングされて表示されるため、実際のメールアドレスに送信しなくてもデザインをすばやくプレビューできます。

    use App\Invoice;
    use App\Notifications\InvoicePaid;

    Route::get('/notification', function () {
        $invoice = Invoice::find(1);

        return (new InvoicePaid($invoice))
                    ->toMail($invoice->user);
    });

<a name="markdown-mail-notifications"></a>
## Markdownメール通知

Markdownメール通知により、事前に構築したテンプレートとメール通知のコンポーネントの利点をMailable中で利用できます。メッセージをMarkdownで記述すると、Laravelは美しいレスポンシブHTMLテンプレートをレンダーすると同時に、自動的に平文テキスト版も生成します。

<a name="generating-the-message"></a>
### メッセージ生成

対応するMarkdownテンプレートを指定し、Mailableを生成するには、`make:notification` Artisanコマンドを`--markdown`オプション付きで使用します。

    php artisan make:notification InvoicePaid --markdown=mail.invoice.paid

他のすべてのメール通知と同様に、Markdownテンプレートを使用する通知では、通知クラスに`toMail`メソッドを定義する必要があります。ただし、`line`メソッドと`action`メソッドを使用して通知を作成する代わりに、`markdown`メソッドを使用して使用するMarkdownテンプレートの名前を指定します。テンプレートで使用できるようにするデータの配列は、メソッドの２番目の引数として渡します。

    /**
     * 通知のメールプレゼンテーションを取得
     *
     * @param  mixed  $notifiable
     * @return \Illuminate\Notifications\Messages\MailMessage
     */
    public function toMail($notifiable)
    {
        $url = url('/invoice/'.$this->invoice->id);

        return (new MailMessage)
                    ->subject('Invoice Paid')
                    ->markdown('mail.invoice.paid', ['url' => $url]);
    }

<a name="writing-the-message"></a>
### メッセージ記述

Markdownメール通知ではBladeコンポーネントとMarkdown記法が利用でき、メールメッセージを簡単に構築できると同時に、Laravelが用意している通知コンポーネントも活用できます。

    @component('mail::message')
    # 発送のお知らせ

    商品が発送されました！

    @component('mail::button', ['url' => $url])
    注文の確認
    @endcomponent

    注文の確認<br>
    {{ config('app.name') }} 様
    @endcomponent

<a name="button-component"></a>
#### Buttonコンポーネント

ボタンコンポーネントは、中央寄せに配置したボタンリンクをレンダリングします。コンポーネントは、`url`とオプションの`color`の２つの引数を取ります。サポートしている色は、`primary`、`green`、`red`です。通知には、必要なだけボタンコンポーネントを追加できます。

    @component('mail::button', ['url' => $url, 'color' => 'green'])
    注文の確認
    @endcomponent

<a name="panel-component"></a>
#### Panelコンポーネント

パネルコンポーネントは、メッセージの他の部分とは少し異なった背景色のパネルの中に、指定されたテキストブロックをレンダーします。これにより、指定するテキストに注目を集められます。

    @component('mail::panel')
    ここはパネルの内容です。
    @endcomponent

<a name="table-component"></a>
#### Tableコンポーネント

テーブルコンポーネントは、MarkdownテーブルをHTMLテーブルへ変換します。このコンポーネントはMarkdownテーブルを内容として受け入れます。デフォルトのMarkdownテーブルの記法を使った、文字寄せをサポートしています。

    @component('mail::table')
    | Laravel       | テーブル      | 例       |
    | ------------- |:-------------:| --------:|
    | 第２カラムは  | 中央寄せ      | $10      |
    | 第３カラムは  | 右寄せ        | $20      |
    @endcomponent

<a name="customizing-the-components"></a>
### コンポーネントカスタマイズ

自身のアプリケーション向きにカスタマイズできるように、Markdown通知コンポーネントはすべてエクスポートできます。コンポーネントをエクスポートするには、`vendor:publish` Artisanコマンドを使い、`laravel-mail`アセットをリソース公開します。

    php artisan vendor:publish --tag=laravel-mail

このコマンドにより、`resources/views/vendor/mail`ディレクトリ下にMarkdownメールコンポーネントがリソース公開されます。`mail`ディレクトリ下に、`html`と`text`ディレクトリがあります。各ディレクトリは名前が示す形式で、利用できるコンポーネントすべてのレスポンシブなプレゼンテーションを持っています。これらのコンポーネントはお好きなよう、自由にカスタマイズしてください。

<a name="customizing-the-css"></a>
#### CSSのカスタマイズ

コンポーネントをエクスポートすると、`resources/views/vendor/mail/html/themes`ディレクトリに、`default.css`ファイルが用意されます。このファイル中のCSSをカスタマイズすれば、Markdownメール通知変換後のHTML形式の中に、インラインCSSとして自動的に取り込まれます。

LaravelのMarkdownコンポーネントの完全に新しいテーマを作成したい場合は、`html/themes`ディレクトリの中にCSSファイルを設置してください。CSSファイルに名前をつけ保存したら、`mail`設定ファイルの`theme`オプションを新しいテーマの名前に更新してください。

個別の通知にカスタムテーマを使いたい場合は、通知のメールメッセージを構築する時に、`theme`メソッドを呼び出してください。`theme`メソッドの引数は、その通知送信で使用するテーマの名前です。

    /**
     * 通知のメールプレゼンテーションを取得
     *
     * @param  mixed  $notifiable
     * @return \Illuminate\Notifications\Messages\MailMessage
     */
    public function toMail($notifiable)
    {
        return (new MailMessage)
                    ->theme('invoice')
                    ->subject('Invoice Paid')
                    ->markdown('mail.invoice.paid', ['url' => $url]);
    }

<a name="database-notifications"></a>
## データベース通知

<a name="database-prerequisites"></a>
### 事前要件

`database`通知チャンネルは、通知情報をデータベーステーブルに格納します。このテーブルには、通知タイプや通知を説明するJSONデータ構造などの情報が含まれます。

テーブルにクエリを実行して、アプリケーションのユーザーインターフェイスで通知を表示できます。ただし、その前に、通知を保存しておくデータベーステーブルを作成する必要があります。`notifications:table`コマンドを使用して、適切なテーブルスキーマを定義する[マイグレーション](/docs/{{version}}/migrations)を生成できます。

    php artisan notifications:table

    php artisan migrate

<a name="formatting-database-notifications"></a>
### データベース通知のフォーマット

通知でデータベーステーブルへの保存をサポートする場合、通知クラスに`toDatabase`か`toArray`メソッドを定義する必要があります。このメソッドは`$notifiable`エンティティを受け取り、プレーンなPHP配列を返す必要があります。返された配列はJSONへエンコードされ、`notifications`テーブルの`data`カラムに保存されます。`toArray`メソッドの例を見てみましょう。

    /**
     * 通知の配列プレゼンテーションの取得
     *
     * @param  mixed  $notifiable
     * @return array
     */
    public function toArray($notifiable)
    {
        return [
            'invoice_id' => $this->invoice->id,
            'amount' => $this->invoice->amount,
        ];
    }

<a name="todatabase-vs-toarray"></a>
#### `toDatabase`対`toArray`

`toArray`メソッドは`broadcast`チャンネルでも使用され、JavaScriptで駆動するフロントエンドへブロードキャストするデータを決定するため使われます。`database`チャンネルと`broadcast`チャンネルに別々な２つの配列表現が必要な場合は、`toArray`メソッドの代わりに`toDatabase`メソッドを定義する必要があります。

<a name="accessing-the-notifications"></a>
### 通知へのアクセス

通知をデータベースへ保存したら、notifiableエンティティからアクセスするための便利な方法が必要になるでしょう。Laravelのデフォルトの`App\Models\User`モデルに含まれている`Illuminate\Notifications\Notification`トレイトには、エンティティのために通知を返す`notifications`[Eloquentリレーション](/docs/{{version}}/eloquent-relationships)が含まれています。通知を取得するため、他のEloquentリレーションと同様にこのメソッドにアクセスできます。デフォルトで通知は「created_at」タイムスタンプで並べ替えられ、コレクションの先頭に最新の通知が表示されます。

    $user = App\Models\User::find(1);

    foreach ($user->notifications as $notification) {
        echo $notification->type;
    }

「未読」通知のみを取得する場合は、`unreadNotifications`リレーションを使用します。この場合も、コレクションの先頭に最新の通知を含むよう、`created_at`タイムスタンプで並べ替えられます。

    $user = App\Models\User::find(1);

    foreach ($user->unreadNotifications as $notification) {
        echo $notification->type;
    }

> {tip} JavaScriptクライアントから通知にアクセスするには、現在のユーザーなどのnotifiableエンティティの通知を返す、通知コントローラをアプリケーションで定義する必要があります。次に、JavaScriptクライアントからそのコントローラのURLへHTTPリクエストを送信します。

<a name="marking-notifications-as-read"></a>
### Readとしての通知作成

通常、ユーザーが閲覧したときに、その通知を「既読」とマークするでしょう。`Illuminate\Notifications\Notifiable`トレイトは、通知のデータベースレコード上にある、`read_at`カラムを更新する`markAsRead`メソッドを提供しています。

    $user = App\Models\User::find(1);

    foreach ($user->unreadNotifications as $notification) {
        $notification->markAsRead();
    }

各通知をループで処理する代わりに、`markAsRead`メソッドを通知コレクションへ直接使用できます。

    $user->unreadNotifications->markAsRead();

データベースから取得せずに、全通知に既読をマークするため、複数更新クエリを使用することもできます。

    $user = App\Models\User::find(1);

    $user->unreadNotifications()->update(['read_at' => now()]);

テーブルエンティティから通知を削除するために、`delete`を使うこともできます。

    $user->notifications()->delete();

<a name="broadcast-notifications"></a>
## ブロードキャスト通知

<a name="broadcast-prerequisites"></a>
### 事前要件

通知をブロードキャストする前に、Laravelの[イベントブロードキャスト](/docs/{{version}}/Broadcasting)サービスを設定して理解しておく必要があります。イベントブロードキャストは、JavaScriptを利用したフロントエンドから送信するサーバサイドのLaravelイベントに対応する方法を提供しています。

<a name="formatting-broadcast-notifications"></a>
### ブロードキャスト通知のフォーマット

`broadcast`チャンネルは、Laravelの[イベントブロードキャスト](/docs/{{version}}/Broadcasting)サービスを使用して通知をブロードキャストし、JavaScriptを利用したフロントエンドがリアルタイムで通知をキャッチできるようにします。通知でブロードキャストをサポートする場合は、通知クラスで`toBroadcast`メソッドを定義します。このメソッドは`$notify`エンティティを受け取り、`BroadcastMessage`インスタンスを返す必要があります。`toBroadcast`メソッドが存在しない場合は、`toArray`メソッドを使用してブロードキャストする必要のあるデータを収集します。返したデータはJSONへエンコードされ、JavaScriptを利用したフロントエンドにブロードキャストされます。`toBroadcast`メソッドの例を見てみましょう。

    use Illuminate\Notifications\Messages\BroadcastMessage;

    /**
     * 通知のブロードキャストプレゼンテーションの取得
     *
     * @param  mixed  $notifiable
     * @return BroadcastMessage
     */
    public function toBroadcast($notifiable)
    {
        return new BroadcastMessage([
            'invoice_id' => $this->invoice->id,
            'amount' => $this->invoice->amount,
        ]);
    }

<a name="broadcast-queue-configuration"></a>
#### ブロードキャストキュー設定

すべてのブロードキャスト通知はキューへ投入されます。ブロードキャスト操作に使用されるキューの接続や名前を設定したい場合は、`BroadcastMessage`の`onConnection`と`onQueue`メソッドを使用してください。

    return (new BroadcastMessage($data))
                    ->onConnection('sqs')
                    ->onQueue('broadcasts');

<a name="customizing-the-notification-type"></a>
#### 通知タイプのカスタマイズ

指定したデータに加えて、すべてのブロードキャスト通知には、通知の完全なクラス名を含む`type`フィールドもあります。通知の`type`をカスタマイズする場合は、通知クラスで`broadcastType`メソッドを定義します。

    use Illuminate\Notifications\Messages\BroadcastMessage;

    /**
     * ブロードキャストする通知のタイプ
     *
     * @return string
     */
    public function broadcastType()
    {
        return 'broadcast.message';
    }

<a name="listening-for-notifications"></a>
### 通知のリッスン

通知は、`{notifiable}.{id}`命名規則を使用してフォーマットされたプライベートチャンネルでブロードキャストされます。したがって、IDが「1」の「App\Models\User」インスタンスに通知を送信する場合、通知は「App.Models.User.1」プライベートチャンネルでブロードキャストされます。[Laravel Echo](/docs/{{version}}/Broadcasting)を使用する場合、`notification`メソッドを使用してチャンネルで通知を簡単にリッスンできます。

    Echo.private('App.Models.User.' + userId)
        .notification((notification) => {
            console.log(notification.type);
        });

<a name="customizing-the-notification-channel"></a>
#### 通知チャンネルのカスタマイズ

エンティティのブロードキャスト通知がブロードキャストされるチャンネルをカスタマイズする場合は、notifiableエンティティに`receivesBroadcastNotificationsOn`メソッドを定義します。

    <?php

    namespace App\Models;

    use Illuminate\Broadcasting\PrivateChannel;
    use Illuminate\Foundation\Auth\User as Authenticatable;
    use Illuminate\Notifications\Notifiable;

    class User extends Authenticatable
    {
        use Notifiable;

        /**
         * ユーザーがブロードキャストされる通知を受け取るチャンネル
         *
         * @return string
         */
        public function receivesBroadcastNotificationsOn()
        {
            return 'users.'.$this->id;
        }
    }

<a name="sms-notifications"></a>
## SMS通知

<a name="sms-prerequisites"></a>
### 事前要件

LaravelでのSMS通知の送信は、[Vonage](https://www.vonage.com/)（旧称Nexmo）を利用しています。Vonage経由で通知を送信する前に、`laravel/nexmo-notification-channel`と`nexmo/laravel`Composerパッケージをインストールする必要があります

    composer require laravel/nexmo-notification-channel nexmo/laravel

`nexmo/laravel`パッケージは、[独自の設定ファイル](https://github.com/Nexmo/nexmo-laravel/blob/master/config/nexmo.php)を持っています。しかし、この設定ファイルを独自のアプリケーションにエクスポートする必要はありません。`NEXMO_KEY`および`NEXMO_SECRET`環境変数を使用するだけで、Vonageの公開鍵と秘密鍵を設定できます。

次に、`nexmo`設定エントリを`config/services.php`設定ファイルに追加する必要があります。以下の設定例をコピーして開始できます。

    'nexmo' => [
        'sms_from' => '15556666666',
    ],

`sms_from`オプションは、SMSメッセージの送信元の電話番号です。Vonageコントロールパネルでアプリケーションの電話番号を生成する必要があります。

<a name="formatting-sms-notifications"></a>
### SMS通知のフォーマット

SMSとしての通知をサポートするには、通知クラスに`toNexmo`メソッドを定義する必要があります。このメソッドは`$notifiable`エンティティを受け取り、`Illuminate\Notifications\Messages\NexmoMessage`インスタンスを返す必要があります。

    /**
     * 通知のVonage／SMS表現を取得
     *
     * @param  mixed  $notifiable
     * @return NexmoMessage
     */
    public function toNexmo($notifiable)
    {
        return (new NexmoMessage)
                    ->content('Your SMS message content');
    }

<a name="unicode-content"></a>
#### Unicodeコンテンツ

SMSメッセージにUnicode文字が含まれる場合は、`NexmoMessage`インスタンスを作成するときに`unicode`メソッドを呼び出す必要があります。

    /**
     * 通知のVonage／SMS表現を取得
     *
     * @param  mixed  $notifiable
     * @return \Illuminate\Notifications\Messages\NexmoMessage
     */
    public function toNexmo($notifiable)
    {
        return (new NexmoMessage)
                    ->content('Your unicode message')
                    ->unicode();
    }

<a name="formatting-shortcode-notifications"></a>
### ショートコード通知のフォーマット

Laravelは、Vonageアカウントで事前定義されたメッセージテンプレートであるショートコード通知の送信もサポートしています。ショートコードSMS通知を送信するには、通知クラスで`toShortcode`メソッドを定義する必要があります。このメソッド内から、通知のタイプ(`alert`、`2fa`、または`marketing`)と、テンプレートに入力するカスタム値を指定する配列を返してください。

    /**
     * 通知のVonage／Shortcode表現を取得
     *
     * @param  mixed  $notifiable
     * @return array
     */
    public function toShortcode($notifiable)
    {
        return [
            'type' => 'alert',
            'custom' => [
                'code' => 'ABC123',
            ];
        ];
    }

> {tip} [SMS通知のルート指定](#routing-sms-notifications)と同様に、通知モデル`routeNotificationForShortcode`メソッドを実装する必要があります。

<a name="customizing-the-from-number"></a>
### 発信元電話番号のカスタマイズ

`config/services.php`ファイルで指定している電話番号とは別の電話番号から通知を送信したい場合は、`NexmoMessage`インスタンスで`from`メソッドを呼び出すことができます。

    /**
     * 通知のVonage／SMS表現を取得します。
     *
     * @param  mixed  $notifiable
     * @return NexmoMessage
     */
    public function toNexmo($notifiable)
    {
        return (new NexmoMessage)
                    ->content('Your SMS message content')
                    ->from('15554443333');
    }

<a name="routing-sms-notifications"></a>
### SMS通知のルート指定

Vonage通知を適切な電話番号にルーティングするには、通知エンティティで`routeNotificationForNexmo`メソッドを定義します。

    <?php

    namespace App\Models;

    use Illuminate\Foundation\Auth\User as Authenticatable;
    use Illuminate\Notifications\Notifiable;

    class User extends Authenticatable
    {
     * @return \Illuminate\Notifications\Message\SlackMessage

        /**
         * Nexmoチャンネルへの通知をルートする
         *
         * @param  \Illuminate\Notifications\Notification  $notification
         * @return string
         */
        public function routeNotificationForNexmo($notification)
        {
            return $this->phone_number;
        }
    }

<a name="slack-notifications"></a>
## Slack通知

<a name="slack-prerequisites"></a>
### 事前要件

Slackへの通知を送信し始める前に、ComposerによりSlack通知チャンネルをインストールする必要があります。

    composer require laravel/slack-notification-channel

さらに、Slackチームの["Incoming Webhook"](https://slack.com/apps/A0F7XDUAZ-incoming-webhooks)インテグレーションを設定する必要もあります。このインテグレーションは、[Slack通知のルート](#routing-slack-notifications)を行う時に使用するURLを提供します。

<a name="formatting-slack-notifications"></a>
### Slack通知のフォーマット

通知がSlackメッセージとしての送信をサポートする場合、通知クラスに`toSlack`メソッドを定義する必要があります。このメソッドは`$notifiable`エンティティを受け取り、`Illuminate\Notifications\Messages\SlackMessage`インスタンスを返す必要があります。Slackメッセージはテキストと同時に、追加テキストのフォーマットか、フィールドの配列を「添付」として含みます。基本的な`toSlack`の例を見てください。

    /**
     * 通知のSlackプレゼンテーションを取得
     *
     * @param  mixed  $notifiable
     * @return \Illuminate\Notifications\Message\SlackMessage
     */
    public function toSlack($notifiable)
    {
        return (new SlackMessage)
                    ->content('One of your invoices has been paid!');
    }

<a name="customizing-the-sender-recipient"></a>
#### 送信者と受信者のカスタマイズ

`from`と`to`メソッドを使い、送信者と受信者のカスタマイズができます。`from`メソッドはユーザー名と絵文字識別子を受け付け、`to`メソッドはチャンネルかユーザー名を受け取ります。

    /**
     * 通知のSlackプレゼンテーションを取得
     *
     * @param  mixed  $notifiable
     * @return \Illuminate\Notifications\Messages\SlackMessage
     */
    public function toSlack($notifiable)
    {
        return (new SlackMessage)
                    ->from('Ghost', ':ghost:')
                    ->to('#bots')
                    ->content('This will be sent to #bots');
    }

文字の代わりに「ロゴ」からの画像を使用することもできます。

    /**
     * 通知のSlackプレゼンテーションを取得
     *
     * @param  mixed  $notifiable
     * @return \Illuminate\Notifications\Messages\SlackMessage
     */
    public function toSlack($notifiable)
    {
        return (new SlackMessage)
                    ->from('Laravel')
                    ->image('https://laravel.com/img/favicon/favicon.ico')
                    ->content('This will display the Laravel logo next to the message');
    }

<a name="slack-attachments"></a>
### Slack添付

Slackメッセージに「添付」を追加することもできます。添付はシンプルなテキストメッセージよりも、リッチなフォーマットのオプションを提供します。以下の例では、アプリケーションで起きた例外についてのエラー通知で、例外についての詳細情報を表示するリンクを含めています。

    /**
     * 通知のSlackプレゼンテーションを取得
     *
     * @param  mixed  $notifiable
     * @return \Illuminate\Notifications\Messages\SlackMessage
     */
    public function toSlack($notifiable)
    {
        $url = url('/exceptions/'.$this->exception->id);

        return (new SlackMessage)
                    ->error()
                    ->content('Whoops! Something went wrong.')
                    ->attachment(function ($attachment) use ($url) {
                        $attachment->title('Exception: File Not Found', $url)
                                   ->content('File [background.jpg] was not found.');
                    });
    }

添付ではさらに、ユーザーに対し表示すべきデータの配列を指定することもできます。簡単によめるよう指定したデータは、テーブルスタイルの形式で表示されます。

    /**
     * 通知のSlackプレゼンテーションを取得
     *
     * @param  mixed  $notifiable
     * @return SlackMessage
     */
    public function toSlack($notifiable)
    {
        $url = url('/invoices/'.$this->invoice->id);

        return (new SlackMessage)
                    ->success()
                    ->content('One of your invoices has been paid!')
                    ->attachment(function ($attachment) use ($url) {
                        $attachment->title('Invoice 1322', $url)
                                   ->fields([
                                        'Title' => 'Server Expenses',
                                        'Amount' => '$1,234',
                                        'Via' => 'American Express',
                                        'Was Overdue' => ':-1:',
                                    ]);
                    });
    }

<a name="markdown-attachment-content"></a>
#### Markdown添付コンテンツ

添付フィールドをMarkdownで構成している場合、`markdown`メソッドでSlackへ指定した添付フィールドがMarkdown形式のテキストであるため、パースしてから表示するように指示します。このメソッドが受け取る値は、`pretext`、`text`、`fields`です。Slackの添付形式についての詳細は、[Slack APIドキュメント](https://api.slack.com/docs/message-formatting#message_formatting)をご覧ください。

    /**
     * 通知のSlackプレゼンテーションを取得
     *
     * @param  mixed  $notifiable
     * @return SlackMessage
     */
    public function toSlack($notifiable)
    {
        $url = url('/exceptions/'.$this->exception->id);

        return (new SlackMessage)
                    ->error()
                    ->content('Whoops! Something went wrong.')
                    ->attachment(function ($attachment) use ($url) {
                        $attachment->title('Exception: File Not Found', $url)
                                   ->content('File [background.jpg] was *not found*.')
                                   ->markdown(['text']);
                    });
    }

<a name="routing-slack-notifications"></a>
### Slack通知のルート指定

Slack通知を適切なSlackチームとチャンネルにルーティングするには、通知エンティティで`routeNotificationForSlack`メソッドを定義します。これは通知の配信先となるWebフックURLを返します。WebフックURLは、Slackチームに「IncomingWebhook」サービスを追加することで生成できます。

    <?php

    namespace App\Models;

    use Illuminate\Foundation\Auth\User as Authenticatable;
    use Illuminate\Notifications\Notifiable;

    class User extends Authenticatable
    {
        use Notifiable;

        /**
         * Slackチャンネルに対する通知をルートする
         *
         * @param  \Illuminate\Notifications\Notification  $notification
         * @return string
         */
        public function routeNotificationForSlack($notification)
        {
            return 'https://hooks.slack.com/services/...';
        }
    }

<a name="localizing-notifications"></a>
## 通知のローカライズ

Laravelを使用すると、HTTPリクエストの現在のロケール以外のロケールで通知を送信でき、通知をキュー投入する場合でもこのロケールを記憶しています。

このために、`Illuminate\Notifications\Notification`クラスは目的の言語を指定するための`locale`メソッドを提供しています。通知が評価されると、アプリケーションはこのロケールに変更され、評価が完了すると前のロケールに戻ります。

    $user->notify((new InvoicePaid($invoice))->locale('es'));

通知可能な複数のエンティティをローカライズするのも、`Notification`ファサードにより可能です。

    Notification::locale('es')->send(
        $users, new InvoicePaid($invoice)
    );

<a name="user-preferred-locales"></a>
### ユーザー希望のローケル

ユーザーの希望するローケルをアプリケーションで保存しておくことは良くあります。notifiableモデルで`HasLocalePreference`契約を実装すると、通知送信時にこの保存してあるローケルを使用するように、Laravelへ指示できます。

    use Illuminate\Contracts\Translation\HasLocalePreference;

    class User extends Model implements HasLocalePreference
    {
        /**
         * ユーザーの希望するローケルの取得
         *
         * @return string
         */
        public function preferredLocale()
        {
            return $this->locale;
        }
    }

このインターフェイスを実装すると、そのモデルに対しmailableや通知を送信する時に、Laravelは自動的に好みのローケルを使用します。そのため、このインターフェイスを使用する場合、`locale`メソッドを呼び出す必要はありません。

    $user->notify(new InvoicePaid($invoice));

<a name="notification-events"></a>
## 通知イベント

通知が送信されると、通知システムによって`Illuminate\Notifications\Events\NotificationSent`[イベント](/docs/{{version}}/events)が発行されます。これには、"notifiable"エンティティと通知インスタンス自体が含まれます。このイベントのリスナを`EventServiceProvider`に登録できます。

    /**
     * アプリケーションにマップされるイベントリスナ
     *
     * @var array
     */
    protected $listen = [
        'Illuminate\Notifications\Events\NotificationSent' => [
            'App\Listeners\LogNotification',
        ],
    ];

> {tip} `EventServiceProvider`でリスナを登録した後に、`event:generate` Artisanコマンドを使うと、リスナクラスが素早く生成できます。

イベントリスナの中で、通知受信者や通知自身について調べるために、そのイベントの`notifiable`、`notification`、`channel`プロパティにアクセスできます。

    /**
     * イベントの処理
     *
     * @param  \Illuminate\Notifications\Events\NotificationSent  $event
     * @return void
     */
    public function handle(NotificationSent $event)
    {
        // $event->channel
        // $event->notifiable
        // $event->notification
        // $event->response
    }

<a name="custom-channels"></a>
## カスタムチャンネル

Laravelには通知チャンネルがいくつか付属していますが、他のチャンネルを介して通知を配信する独自​​のドライバを作成することもできます。Laravelではこれをシンプルに実現できます。作成開始するには、`send`メソッドを含むクラスを定義します。このメソッドは、`$notifying`と`$notification`の2つの引数を受け取る必要があります。

`send`メソッド内で、通知メソッドを呼び出して、チャンネルが理解できるメッセージオブジェクトを取得し、必要に応じて通知を`$notizable`インスタンスに送信します。

    <?php

    namespace App\Channels;

    use Illuminate\Notifications\Notification;

    class VoiceChannel
    {
        /**
         * 指定された通知の送信
         *
         * @param  mixed  $notifiable
         * @param  \Illuminate\Notifications\Notification  $notification
         * @return void
         */
        public function send($notifiable, Notification $notification)
        {
            $message = $notification->toVoice($notifiable);

            // 通知を$notifiableインスタンスへ送信する…
        }
    }

通知チャンネルクラスを定義したら、任意の通知の`via`メソッドからクラス名を返せます。この例では、通知の`toVoice`メソッドは、ボイスメッセージを表すために選択するどんなオブジェクトも返せます。たとえば、次のメッセージを表すために独自の`VoiceMessage`クラスを定義できます。

    <?php

    namespace App\Notifications;

    use App\Channels\Messages\VoiceMessage;
    use App\Channels\VoiceChannel;
    use Illuminate\Bus\Queueable;
    use Illuminate\Contracts\Queue\ShouldQueue;
    use Illuminate\Notifications\Notification;

    class InvoicePaid extends Notification
    {
        use Queueable;

        /**
         * 通知チャンネルの取得
         *
         * @param  mixed  $notifiable
         * @return array|string
         */
        public function via($notifiable)
        {
            return [VoiceChannel::class];
        }

        /**
         * 通知の音声プレゼンテーションを取得
         *
         * @param  mixed  $notifiable
         * @return VoiceMessage
         */
        public function toVoice($notifiable)
        {
            // ...
        }
    }
