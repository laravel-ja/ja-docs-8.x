# 通知

- [イントロダクション](#introduction)
- [通知の作成](#creating-notifications)
- [通知の送信](#sending-notifications)
    - [Notifiableトレイトの使用](#using-the-notifiable-trait)
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

[メール送信](/docs/{{version}}/mail)に加え、LaravelはSMS（以前、Nexmoとして知られていた[Vonage](https://www.vonage.com/communications-apis/)を使用）、[Slack](https://slack.com)などの、さまざまな複数チャンネルへ渡る通知をサポートしています。通知はWebインターフェイスで表示できるように、データベースに保存することもできます。

通常、通知はアプリケーションで何かが起きたことをユーザーへ知らせる、短い情報メッセージです。たとえば、課金アプリを作成しているなら、メールとSMSチャンネルで「課金支払い」を送信できます。

<a name="creating-notifications"></a>
## 通知の作成

Laravelの各通知は、（通常、`app/Notifications`ディレクトリに設置される）クラスにより表されます。このディレクトリがアプリケーションで見つからなくても、心配ありません。`make:notification` Artisanコマンドを実行すると、作成されます。

    php artisan make:notification InvoicePaid

このコマンドにより、真新しい通知クラスが、`app/Notifications`ディレクトリに生成されます。各通知クラスは`via`メソッドと、特定のチャンネルに最適化したメッセージへ変換する、いくつかのメッセージ構築メソッド（`toMail`、`toDatabase`など）を含んでいます。

<a name="sending-notifications"></a>
## 通知の送信

<a name="using-the-notifiable-trait"></a>
### Notifiableトレイトの使用

通知は２つの方法で送信されます。`Notifiable`トレイトの`notify`メソッドか、`Notification`[ファサード](/docs/{{version}}/facades)を使う方法です。最初に、トレイトを見ていきましょう。

    <?php

    namespace App\Models;

    use Illuminate\Foundation\Auth\User as Authenticatable;
    use Illuminate\Notifications\Notifiable;

    class User extends Authenticatable
    {
        use Notifiable;
    }

このトレイトは、デフォルトの`App\Models\User`モデルで使用されており、通知を送るための`notify`メソッドを一つ含んでいます。`notify`メソッドは通知インスタンスを受け取ります。

    use App\Notifications\InvoicePaid;

    $user->notify(new InvoicePaid($invoice));

> {tip} みなさんのどんなモデルであっても、`Illuminate\Notifications\Notifiable`トレイトを使えることを覚えておきましょう。使用は`User`モデルだけに限定されているわけでありません。

<a name="using-the-notification-facade"></a>
### Notificationファサードの使用

ほかに、`Notification`[ファサード](/docs/{{version}}/facades)を使用し、通知を送る方法もあります。これは主にユーザーコレクションのような、複数の通知可能エンティティに対し、通知する場合に便利です。ファサードを使い通知するには、`send`メソッドへ通知可能エンティティ全部と、通知インスタンスを渡します。

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

> {note} 通知のキューイングを行う前に、キューを設定し、[ワーカを起動](/docs/{{version}}/queues)する必要があります。

通知の送信には時間が取られます。とくにそのチャンネルが通知を配信するために、外部のAPIを呼び出す必要がある場合はとくにです。アプリケーションのレスポンスタイムを向上させるには、クラスに`ShouldQueue`インターフェイスと、`Queueable`トレイトを追加し、キューイングしましょう。このインターフェイスとトレイトは、`make:notification`を使用して生成された全通知でインポート済みですから、すぐに通知クラスに追加できます。

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

    $when = now()->addMinutes(10);

    $user->notify((new InvoicePaid($invoice))->delay($when));

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

<a name="on-demand-notifications"></a>
### オンデマンド通知

場合により、アプリケーションの「ユーザー」として保存されていない誰かに対し、通知を送る必要が起き得ます。`Notification::route`ファサードメソッドを使い、通知を送る前にアドホックな通知ルーティング情報を指定できます。

    Notification::route('mail', 'taylor@example.com')
                ->route('nexmo', '5555555555')
                ->route('slack', 'https://hooks.slack.com/services/...')
                ->notify(new InvoicePaid($invoice));

<a name="mail-notifications"></a>
## メール通知

<a name="formatting-mail-messages"></a>
### メールメッセージのフォーマット

ある通知でメール送信をサポートする場合、通知クラスに`toMail`メソッドを定義してください。このメソッドは、`$notifiable`エンティティを受け取り、`Illuminate\Notifications\Messages\MailMessage`インスタンスを返す必要があります。メールメッセージはテキスト行と、同時に"call to action"（アクションの呼び出し）を含むことでしょう。`toMail`メソッドの例を見てみましょう。

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

この例では、挨拶、テキスト行、アクションの呼び出し、別のテキスト行を登録しています。これらのメソッドは、小さなトランザクションメールをシンプルで素早くフォーマットする、`MailMessage`オブジェクトが提供しています。メールチャンネルはテンプレートにより、メッセージの構成物をきれいでレスポンシブなHTMLメールへ、変換します。平文メールも用意されます。以下は`mail`チャンネルにより生成されたメールの例です。I

<img src="https://laravel.com/img/docs/notification-example.png" width="551" height="596">

> {tip} メール通知を行うときは、`config/app.php`設定ファイルの`name`値を確実に設定してください。この値は、メール通知メッセージのヘッダとフッタで使用されます。

#### 他の通知フォーマットオプション

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

`MailMessage`:`MailMessage`の`view`メソッドで指定する配列の第２要素としてビュー名を渡すことにより、メールメッセージの平文テキストビューを指定できます。

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

    use App\Mail\InvoicePaid as Mailable;

    /**
     * 通知のメールプレゼンテーションを取得
     *
     * @param  mixed  $notifiable
     * @return Mailable
     */
    public function toMail($notifiable)
    {
        return (new Mailable($this->invoice))->to($notifiable->email);
    }

<a name="error-messages"></a>
#### エラーメッセージ

ある通知はユーザーへエラーを知らせます。たとえば、課金の失敗です。メールメッセージがエラーに関するものであることを知らせるためには、メッセージ構築時に`error`メソッドを呼び出します。`error`メソッドをメールメッセージで使用すると、アクション呼び出しボタンが青の代わりに赤で表示されます。

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
                    ->from('test@example.com', 'Example')
                    ->line('...');
    }

<a name="customizing-the-recipient"></a>
### 受信者のカスタマイズ

`mail`チャンネルを使い通知を送る場合、通知システムは自動的に通知エンティティで`email`プロパティを探します。通知を配信するために使用するメールアドレスをカスタマイズするには、エンティティに対し`routeNotificationForMail`メソッドを定義してください。

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

            // 名前とメールアドレスを返す場合
            return [$this->email_address => $this->name];
        }
    }

<a name="customizing-the-subject"></a>
### 件名のカスタマイズ

デフォルトのメール件名は、通知のクラス名を"title case"にフォーマットしたものです。ですから、`InvoicePaid`という通知クラス名は、`Invoice Paid`というメールの件名になります。メッセージの件名を明確に指定したい場合は、メッセージを構築時に`subject`メソッドを呼び出してください。

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

デフォルトのメール通知は、`config/mail.php`設定ファイルで定義されているデフォルトドライバにより送信されます。しかし、`mailer`メソッドをメッセージ組立時に呼び出せば、実行時に異なるメイラーを指定できます。

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

<a name="previewing-mail-notifications"></a>
### メール通知のプレビュー

メール通知テンプレートをデザインしている時に、通常のBladeテンプレートのようにブラウザでメールメッセージをレンダーし、素早くプレビューできると便利です。そのため、Laravelはルートのクロージャやコントローラから直接メール通知を返すことにより、メールメッセージを生成できます。`MailMessage`が返されるとレンダーされ、ブラウザへ表示されます。実際のメールアドレスへ送信することなく、デザインが素早くプレビューできます。

    Route::get('mail', function () {
        $invoice = App\Invoice::find(1);

        return (new App\Notifications\InvoicePaid($invoice))
                    ->toMail($invoice->user);
    });

<a name="markdown-mail-notifications"></a>
## Markdownメール通知

Markdownメール通知により、事前に構築したテンプレートとメール通知のコンポーネントの利点をMailable中で利用できます。メッセージをMarkdownで記述すると、Laravelは美しいレスポンシブHTMLテンプレートをレンダーすると同時に、自動的に平文テキスト版も生成します。

<a name="generating-the-message"></a>
### メッセージ生成

対応するMarkdownテンプレートを指定し、Mailableを生成するには、`make:notification` Artisanコマンドを`--markdown`オプション付きで使用します。

    php artisan make:notification InvoicePaid --markdown=mail.invoice.paid

他のメール通知すべてと同様に、Markdownテンプレートを使用する通知は、通知クラスに`toMail`メソッドを定義する必要があります。しかし、`line`と`action`メソッドで通知を構成する代わりに、`markdown`メソッドを使用し、使用するMarkdownテンプレートの名前を指定します。

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

#### Buttonコンポーネント

ボタンコンポーネントは中央寄せのボタンリンクをレンダーします。このコンポーネントは引数として、`url`とオプションの`color`を受け取ります。サポートしている色は`blue`、`green`、`red`です。メッセージに好きなだけのボタンコンポーネントを追加できます。

    @component('mail::button', ['url' => $url, 'color' => 'green'])
    注文の確認
    @endcomponent

#### Panelコンポーネント

パネルコンポーネントは、メッセージの他の部分とは少し異なった背景色のパネルの中に、指定されたテキストブロックをレンダーします。これにより、指定するテキストに注目を集められます。

    @component('mail::panel')
    ここはパネルの内容です。
    @endcomponent

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

`database`通知チャンネルは、通知情報をデータベーステーブルへ保存します。このテーブルは通知タイプのような情報と同時に、通知を説明するカスタムJSONデータを含みます。

アプリケーションのユーザーインターフェイスで通知を表示するために、テーブルをクエリできます。しかし、その前に通知を保存するデータベーステーブルを作成する必要があります。実際のテーブルスキーマのマイグレーションを生成するために、`notifications:table`を使用してください。

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

#### `toDatabase` Vs. `toArray`

`toArray`メソッドは、JavaScriptクライアントへどのデータをブロードキャストするかを決めるために、`broadcast`チャンネルでも使用されます。`database`と`broadcast`チャンネルで、別々の配列プレゼンテーションを持ちたい場合は、`toArray`メソッドの代わりに、`toDatabase`メソッドを定義してください。

<a name="accessing-the-notifications"></a>
### 通知へのアクセス

通知をデータベースへ保存したら、通知エンティティから便利にアクセスできる方法が必要になります。Laravelのデフォルト`App\Models\User`モデルに含まれている、`Illuminate\Notifications\Notifiable`トレイトは、`notifications` Eloquentリレーションを含んでおり、そのエンティティの通知を返します。通知を取得するために、他のEloquentリレーションと同様に、このメソッドにアクセスできます。デフォルトで、通知は`created_at`タイムスタンプでソートされます。

    $user = App\Models\User::find(1);

    foreach ($user->notifications as $notification) {
        echo $notification->type;
    }

「未読」の通知のみを取得したい場合は、`unreadNotifications`リレーションシップを使います。この場合も、通知は`created_at`タイムスタンプでソートされます。

    $user = App\Models\User::find(1);

    foreach ($user->unreadNotifications as $notification) {
        echo $notification->type;
    }

> {tip} 通知にJavaScriptクライアントからアクセスするには、現在のユーザーのような、通知可能なエンティティに対する通知を返す、通知コントローラをアプリケーションに定義する必要があります。その後、JavaScriptクライエントから、コントローラのURIへHTTPリクエストを作成します。

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

ブロードキャスト通知の前に、Laravelの[イベントブロードキャスト](/docs/{{version}}/broadcasting)サービスを設定し、慣れておく必要があります。イベントブロードキャストは、JavaScriptクライアント側で、サーバサイドで発行されたLaravelイベントに対処する方法を提供しています。

<a name="formatting-broadcast-notifications"></a>
### ブロードキャスト通知のフォーマット

`broadcast`チャンネルは、リアルタイムでJavaScriptクライアントが通知を補足できるようにする、Laravelの[イベントブロードキャスト](/docs/{{version}}/broadcasting)サービスを用い、通知をブロードキャストします。通知でブロードキャストをサポートする場合、通知クラスで`toBroadcast`メソッドを定義ができます。このメソッドは`$notifiable`エンティティを受け取り、`BroadcastMessage`インスタンスを返す必要があります。`toBroadcast`メソッドが存在しない場合は、ブロードキャストするデータをまとめるために`toArray`メソッドが使用されます。返されるデータはJSONへエンコードされ、JavaScriptクライアントへブロードキャストされます。`toBroadcast`メソッドの例を見てみましょう。

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

#### ブロードキャストキュー設定

すべてのブロードキャスト通知はキューへ投入されます。ブロードキャスト操作に使用されるキューの接続や名前を設定したい場合は、`BroadcastMessage`の`onConnection`と`onQueue`メソッドを使用してください。

    return (new BroadcastMessage($data))
                    ->onConnection('sqs')
                    ->onQueue('broadcasts');

#### 通知タイプのカスタマイズ

データの指定に付け加え、すべてのブロードキャストは通知の完全なクラス名を含む`type`フィールドを持っています。JavaScriptクライアントへ提供される通知`type`をカスタマイズしたい場合は、通知クラスで`broadcastType`メソッドを定義してください。

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

プライベートチャンネルにブロードキャストされる通知は、`{notifiable}.{id}`命名規則に従いフォーマットされます。ですから、IDが`1`の`App\Models\User`インスタンスを通知で送る場合、`App.User.1`プライベートチャンネルへブロードキャストされます。[Laravel Echo](/docs/{{version}}/broadcasting)を使用していれば、`notification`ヘルパメソッドを使い、チャンネルへの通知を簡単にリッスンできます。

    Echo.private('App.User.' + userId)
        .notification((notification) => {
            console.log(notification.type);
        });

#### 通知チャンネルのカスタマイズ

ブロードキャスト通知のNotifiableエンティティを受け取るチャンネルをカスタマイズしたい場合は、そのエンティティに`receivesBroadcastNotificationsOn`メソッドを定義してください。

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

LaravelのSMS通知送信は、[Nexmo](https://www.nexmo.com/)を使用します。Nexmoで通知を送る前に、`laravel/nexmo-notification-channel` Composerパッケージをインストールしてください。

    composer require laravel/nexmo-notification-channel

これにより[`nexmo/laravel`](https://github.com/Nexmo/nexmo-laravel)パッケージもインストールされます。このパッケージは[自身の設定ファイル](https://github.com/Nexmo/nexmo-laravel/blob/master/config/nexmo.php)を持っています。`NEXMO_KEY`と`NEXMO_SECRET`の環境変数を使い、Nexmoパブリックキーとシークレットキーを指定できます。

次に、`config/services.php`設定ファイルへ設定オプションを追加する必要があります。設定例として、以下の設定をコピーして編集してください。

    'nexmo' => [
        'sms_from' => '15556666666',
    ],

`sms_from`オプションはSMSメッセージを送る電話番号です。アプリケーションの電話番号は、Nexmoコントロールパネルで作成してください。

<a name="formatting-sms-notifications"></a>
### SMS通知のフォーマット

SMSとしての通知をサポートするには、通知クラスに`toNexmo`メソッドを定義する必要があります。このメソッドは`$notifiable`エンティティを受け取り、`Illuminate\Notifications\Messages\NexmoMessage`インスタンスを返す必要があります。

    /**
     * 通知のNexmo/SMSプレゼンテーションを取得する
     *
     * @param  mixed  $notifiable
     * @return NexmoMessage
     */
    public function toNexmo($notifiable)
    {
        return (new NexmoMessage)
                    ->content('Your SMS message content');
    }

<a name="formatting-shortcode-notifications"></a>
### ショートコード通知のフォーマット

Nexmoアカウントで事前に定義したメッセージテンプレートである、ショートコード通知の送信もLaravelはサポートしています。通知のタイプ（`alert`、`2fa`、`marketing`など）と、そのテンプレートに埋め込むカスタム値を指定します。

    /**
     * 通知のNexmo／ショートコードプレゼンテーションを取得する
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

#### Unicodeコンテンツ

SMSメッセージにUnicode文字を含む場合は、`NexmoMessage`インスタンスの生成時に、`unicode`メソッドを呼び出してください。

    /**
     * 通知のNexmo/SMSプレゼンテーションを取得する
     *
     * @param  mixed  $notifiable
     * @return NexmoMessage
     */
    public function toNexmo($notifiable)
    {
        return (new NexmoMessage)
                    ->content('Your unicode message')
                    ->unicode();
    }

<a name="customizing-the-from-number"></a>
### 発信元電話番号のカスタマイズ

`config/services.php`ファイルで指定した電話番号とは異なる番号から、通知を送りたい場合は、`NexmoMessage`インスタンスの`from`メソッドを使用します。

    /**
     * 通知のNexmo/SMSプレゼンテーションを取得する
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

特定の電話番号へNexmo通知を送るには、Notifiableエンティティ上で`routeNotificationForNexmo`メソッドを定義してください。

    <?php

    namespace App\Models;

    use Illuminate\Foundation\Auth\User as Authenticatable;
    use Illuminate\Notifications\Notifiable;

    class User extends Authenticatable
    {
        use Notifiable;

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

Slackを通して通知を送れるようにするには、ComposerでSlackの通知チャンネルをインストールしてください。

    composer require laravel/slack-notification-channel

さらに、Slackチームの["Incoming Webhook"](https://slack.com/apps/A0F7XDUAZ-incoming-webhooks)インテグレーションを設定する必要もあります。このインテグレーションは、[Slack通知のルート](#routing-slack-notifications)を行う時に使用するURLを提供します。

<a name="formatting-slack-notifications"></a>
### Slack通知のフォーマット

通知がSlackメッセージとしての送信をサポートする場合、通知クラスに`toSlack`メソッドを定義する必要があります。このメソッドは`$notifiable`エンティティを受け取り、`Illuminate\Notifications\Messages\SlackMessage`インスタンスを返す必要があります。Slackメッセージはテキストと同時に、追加テキストのフォーマットか、フィールドの配列を「添付」として含みます。基本的な`toSlack`の例を見てください。

    /**
     * 通知のSlackプレゼンテーションを取得
     *
     * @param  mixed  $notifiable
     * @return SlackMessage
     */
    public function toSlack($notifiable)
    {
        return (new SlackMessage)
                    ->content('One of your invoices has been paid!');
    }

この例では、Slackへ一行のテキストを送っており、以下のようなメッセージが生成されます。

<img src="https://laravel.com/img/docs/basic-slack-notification.png">

#### 送信者と受信者のカスタマイズ

`from`と`to`メソッドを使い、送信者と受信者のカスタマイズができます。`from`メソッドはユーザー名と絵文字識別子を受け付け、`to`メソッドはチャンネルかユーザー名を受け取ります。

    /**
     * 通知のSlackプレゼンテーションを取得
     *
     * @param  mixed  $notifiable
     * @return SlackMessage
     */
    public function toSlack($notifiable)
    {
        return (new SlackMessage)
                    ->from('Ghost', ':ghost:')
                    ->to('#other')
                    ->content('This will be sent to #other');
    }

絵文字の代わりにロゴイメージを使うこともできます。

    /**
     * 通知のSlackプレゼンテーションを取得
     *
     * @param  mixed  $notifiable
     * @return SlackMessage
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
                                   ->content('File [background.jpg] was not found.');
                    });
    }

上の例は、次のようなSlackメッセージを生成します。

<img src="https://laravel.com/img/docs/basic-slack-attachment.png">

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

上の例は、以下のようなSlackメッセージを作成します。

<img src="https://laravel.com/img/docs/slack-fields-attachment.png">

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

実際の場所へSlack通知をルートするには、通知可能エンティティの`routeNotificationForSlack`メソッドを定義します。これは通知が配送されるべきWebhook URLを返す必要があります。Webhook URLは、Slackチームの"Incoming Webhook"サービスを追加することにより、作成されます。

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

Laravelでは、現在のデフォルト言語とは別のローケルで、通知を送信できます。通知がキュー投入されても、このローケルは保持されます。

希望する言語を指定するために、`Illuminate\Notifications\Notification`クラスに`locale`メソッドが用意されています。通知を整形する時点で、アプリケーションはこのローケルへ変更し、フォーマットが完了したら以前のローケルへ戻します。

    $user->notify((new InvoicePaid($invoice))->locale('es'));

通知可能な複数のエンティティをローカライズするのも、`Notification`ファサードにより可能です。

    Notification::locale('es')->send($users, new InvoicePaid($invoice));

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

通知が送信されると、`Illuminate\Notifications\Events\NotificationSent`イベントが、通知システムにより発行されます。これには「通知可能」エンティティと通知インスンタンス自身が含まれます。このイベントのリスナは、`EventServiceProvider`で登録します。

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
     * @param  NotificationSent  $event
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

Laravelはいくつかの通知チャンネルを用意していますが、他のチャンネルを使用し通知を配信するために、独自のドライバーを書くこともあるでしょう。Laravelでは、これも簡単です。手始めに、`send`メソッドを含むクラスを定義しましょう。このメソッドは`$notifiable`と `$notification`の、２引数を受け取ります。

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

通知チャンネルクラスが定義できたら、通知の`via`メソッドから、クラス名を返します。

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
