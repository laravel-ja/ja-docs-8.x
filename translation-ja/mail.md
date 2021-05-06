# メール

- [イントロダクション](#introduction)
    - [設定](#configuration)
    - [ドライバ事前設定](#driver-prerequisites)
- [Mailableの生成](#generating-mailables)
- [Mailableの記述](#writing-mailables)
    - [Senderの設定](#configuring-the-sender)
    - [ビューの設定](#configuring-the-view)
    - [ビューデータ](#view-data)
    - [添付](#attachments)
    - [インライン添付](#inline-attachments)
    - [SwiftMailerメッセージのカスタマイズ](#customizing-the-swiftmailer-message)
- [Markdown Mailable](#markdown-mailables)
    - [Markdown Mailableの生成](#generating-markdown-mailables)
    - [Markdownメッセージの記述](#writing-markdown-messages)
    - [コンポーネントのカスタマイズ](#customizing-the-components)
- [メール送信](#sending-mail)
    - [メールのキュー投入](#queueing-mail)
- [Mailableのレンダー](#rendering-mailables)
    - [ブラウザによるMailableのプレビュー](#previewing-mailables-in-the-browser)
- [Mailableの多言語化](#localizing-mailables)
- [Mailableのテスト](#testing-mailables)
- [メールとローカル開発](#mail-and-local-development)
- [イベント](#events)

<a name="introduction"></a>
## イントロダクション

メールの送信は複雑である必要はありません。Laravelは、人気のある[SwiftMailer](https://swiftmailer.symfony.com/)ライブラリを利用したクリーンでシンプルなメールAPIを提供します。LaravelとSwiftMailerは、SMTP、Mailgun、Postmark、AmazonSES、および`sendmail`を介して電子メールを送信するためのドライバーを提供し、選択したローカルまたはクラウドベースのサービスを介してメールの送信をすばやく開始できるようにします。

<a name="configuration"></a>
### 設定

Laravelのメールサービスは、アプリケーションの`config/mail.php`設定ファイルを介して設定できます。このファイル内で設定された各メーラーには、独自の設定と独自の「トランスポート」があり、アプリケーションがさまざまな電子メールサービスを使用して特定の電子メールメッセージを送信できるようにします。たとえば、アプリケーションでPostmarkを使用してトランザクションメールを送信し、AmazonSESを使用して一括メールを送信するなどです。

`mail`設定ファイル内に、`mailers`設定配列があります。この配列には、Laravelがサポートしている主要なメールドライバ／トランスポートごとのサンプル設定エントリが含まれています。その中で`default`設定値は、アプリケーションが電子メールメッセージを送信する必要があるときにデフォルトで使用するメーラーを決定します。

<a name="driver-prerequisites"></a>
### ドライバ／トランスポートの前提条件

MailgunやPostmarkなどのAPIベースのドライバは、多くの場合、SMTPサーバを介してメールを送信するよりも簡単で高速です。可能な限り、これらのドライバのいずれかを使用することを推奨します。すべてのAPIベースのドライバには、Composerパッケージマネージャーを介してインストールできるGuzzle HTTPライブラリが必要です。

    composer require guzzlehttp/guzzle

<a name="mailgun-driver"></a>
#### Mailgunドライバ

Mailgunドライバを使用するには、最初にGuzzle HTTPライブラリをインストールします。次に、`config/mail.php`設定ファイルの`default`オプションを`mailgun`に設定します。次に、`config/services.php`設定ファイルに次のオプションを確実に含めてください。

    'mailgun' => [
        'domain' => env('MAILGUN_DOMAIN'),
        'secret' => env('MAILGUN_SECRET'),
    ],

米国の[Mailgunリージョン](https://documentation.mailgun.com/en/latest/api-intro.html#mailgun-regions)を使用していない場合は、`services`設定ファイルでリージョンのエンドポイントを定義できます。

    'mailgun' => [
        'domain' => env('MAILGUN_DOMAIN'),
        'secret' => env('MAILGUN_SECRET'),
        'endpoint' => env('MAILGUN_ENDPOINT', 'api.eu.mailgun.net'),
    ],

<a name="postmark-driver"></a>
#### Postmarkドライバ

Postmarkドライバを使用するには、Composerを介してPostmarkのSwiftMailerトランスポートをインストールします。

    composer require wildbit/swiftmailer-postmark

次に、Guzzle HTTPライブラリをインストールし、`config/mail.php`設定ファイルの`default`オプションを`postmark`に設定します。最後に、`config/services.php`設定ファイルに以下のオプションを確実に含めてください。

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

特定のメーラで使用する必要があるPostmarkメッセージストリームを指定したい場合は、`message_stream_id`設定オプションをメーラの設定配列に追加してください。この設定配列は、アプリケーションの`config/mail.php`設定ファイルにあります。

    'postmark' => [
        'transport' => 'postmark',
        'message_stream_id' => env('POSTMARK_MESSAGE_STREAM_ID'),
    ],

この方法で、メッセージストリームが異なる複数のPostmarkメーラを設定することもできます。

<a name="ses-driver"></a>
#### SESドライバ

Amazon SESドライバを使用するには、最初にAmazon AWS SDK for PHPをインストールする必要があります。このライブラリは、Composerパッケージマネージャーを介してインストールできます。

```bash
composer require aws/aws-sdk-php
```

次に、`config/mail.php`設定ファイルの`default`オプションを`ses`に設定し、`config/services.php`設定ファイルに以下のオプションを確実に含めてください。

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

メール送信時にAWS SDKの`SendRawEmail`メソッドへLaravelが渡すべき[追加オプション](https://docs.aws.amazon.com/aws-sdk-php/v3/api/api-email-2010-12-01.html#sendrawemail)を定義したい場合、`ses`設定内で`options`配列を定義してください。

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
        'options' => [
            'ConfigurationSetName' => 'MyConfigurationSet',
            'Tags' => [
                ['Name' => 'foo', 'Value' => 'bar'],
            ],
        ],
    ],

<a name="generating-mailables"></a>
## Mailableの生成

Laravelアプリケーションを構築する場合、アプリケーションが送信する各タイプの電子メールは"Mailable"クラスとして表します。これらのクラスは`app/Mail`ディレクトリに保存されます。アプリケーションにこのディレクトリが存在しなくても心配ありません。`make:mail`　Artisanコマンドを使用して最初のメール可能なクラスを作成するときに、生成されます。

    php artisan make:mail OrderShipped

<a name="writing-mailables"></a>
## Mailableの記述

Mailableクラスを生成したら、それを開いて、その内容を調べてください。まず、メール可能なクラスの設定はすべて`build`メソッドで行われることに注意してください。このメソッド内で`from`、`subject`、`view`、`attach`などのさまざまなメソッドを呼び出して、電子メールの表示と配信を設定できます。

<a name="configuring-the-sender"></a>
### Senderの設定

<a name="using-the-from-method"></a>
#### `from`メソッドの使用

まず、メールの送信者の設定について見ていきましょう。言い換えると、電子メールを送信したのは誰かです。送信者を設定するには２つの方法があります。まず、Mailableクラスの`build`メソッド内で`from`メソッドを使用する方法です。

    /**
     * メッセージの作成
     *
     * @return $this
     */
    public function build()
    {
        return $this->from('example@example.com')
                    ->view('emails.orders.shipped');
    }

<a name="using-a-global-from-address"></a>
#### グローバル`from`アドレスの使用

ただし、アプリケーションがすべての電子メールに同じ「送信者」アドレスを使用している場合、生成する各メール可能クラスで`from`メソッドを呼び出すのは面倒です。代わりに、`config/mail.php`設定ファイルでグローバルな「送信者」アドレスを指定できます。このアドレスは、Mailableクラス内で「送信者」アドレスを指定しない場合に使用します。

    'from' => ['address' => 'example@example.com', 'name' => 'App Name'],

また、`config/mail.php`設定ファイル内でグローバルな"reply_to"アドレスも定義できます。

    'reply_to' => ['address' => 'example@example.com', 'name' => 'App Name'],

<a name="configuring-the-view"></a>
### ビューの設定

Mailableクラスの`build`メソッド内で、`view`メソッドを使用して、電子メールのコンテンツをレンダーするときに使用するテンプレートを指定できます。通常、各メールは[Bladeテンプレート](/docs/{{version}}/Blade)を使用してコンテンツをレンダーするため、メールのHTMLを作成するときにBladeテンプレートエンジンの能力と利便性を最大限に活用できます。

    /**
     * メッセージの作成
     *
     * @return $this
     */
    public function build()
    {
        return $this->view('emails.orders.shipped');
    }

> {tip} すべてのメールテンプレートを格納するために`resources/views/emails`ディレクトリを作成することを推奨します。ただし、`resources/views`ディレクトリ内ならば好きな場所へ自由に配置できます。

<a name="plain-text-emails"></a>
#### 平文テキストの電子メール

電子メールの平文テキストバージョンを定義する場合は、`text`メソッドを使用します。`view`メソッドと同様に、`text`メソッドは電子メールの内容をレンダーするために使用するテンプレート名を引数に取ります。メッセージのHTMLバージョンと平文テキストバージョンの両方を自由に定義できます。

    /**
     * メッセージの作成
     *
     * @return $this
     */
    public function build()
    {
        return $this->view('emails.orders.shipped')
                    ->text('emails.orders.shipped_plain');
    }

<a name="view-data"></a>
### ビューデータ

<a name="via-public-properties"></a>
#### Publicなプロパティ経由

通常、電子メールのHTMLをレンダーするときに使用するデータをビューへ渡す必要があります。ビューでデータを利用できるようにする方法は２つあります。まず、Mailableクラスで定義したパブリックプロパティは、自動的にビューで使用できるようになります。したがって、たとえばMailableクラスのコンストラクタにデータを渡し、そのデータをクラスで定義したパブリックプロパティに設定できます。

    <?php

    namespace App\Mail;

    use App\Models\Order;
    use Illuminate\Bus\Queueable;
    use Illuminate\Mail\Mailable;
    use Illuminate\Queue\SerializesModels;

    class OrderShipped extends Mailable
    {
        use Queueable, SerializesModels;

        /**
         * 注文インスタンス
         *
         * @var \App\Models\Order
         */
        public $order;

        /**
         * 新しいメッセージインスタンスの生成
         *
         * @param  \App\Models\Order  $order
         * @return void
         */
        public function __construct(Order $order)
        {
            $this->order = $order;
        }

        /**
         * メッセージを作成
         *
         * @return $this
         */
        public function build()
        {
            return $this->view('emails.orders.shipped');
        }
    }

データをパブリックプロパティへ設定すると、ビューで自動的に利用できるようになるため、Bladeテンプレートの他のデータにアクセスするのと同じようにアクセスできます。

    <div>
        Price: {{ $order->price }}
    </div>

<a name="via-the-with-method"></a>
#### `with`メソッド経由

テンプレートへ送信する前にメールのデータの形式をカスタマイズしたい場合は、`with`メソッドを使用して手動でデータをビューへ渡せます。通常、Mailableクラスのコンストラクターを介してデータを渡します。ただし、このデータを`protected`または`private`プロパティに設定して、データがテンプレートで自動的に使用可能にならないようにする必要があります。次に、`with`メソッドを呼び出すときに、テンプレートで使用できるようにするデータの配列を渡します。

    <?php

    namespace App\Mail;

    use App\Models\Order;
    use Illuminate\Bus\Queueable;
    use Illuminate\Mail\Mailable;
    use Illuminate\Queue\SerializesModels;

    class OrderShipped extends Mailable
    {
        use Queueable, SerializesModels;

        /**
         * 注文インスタンス
         *
         * @var \App\Models\Order
         */
        protected $order;

        /**
         * 新しいメッセージインスタンスの生成
         *
         * @param  \App\Models\Order  $order
         * @return void
         */
        public function __construct(Order $order)
        {
            $this->order = $order;
        }

        /**
         * メッセージを作成
         *
         * @return $this
         */
        public function build()
        {
            return $this->view('emails.orders.shipped')
                        ->with([
                            'orderName' => $this->order->name,
                            'orderPrice' => $this->order->price,
                        ]);
        }
    }

データが`with`メソッドに渡されると、ビューで自動的に利用できるようになるため、Bladeテンプレートの他のデータにアクセスするのと同じようにアクセスできます。

    <div>
        Price: {{ $orderPrice }}
    </div>

<a name="attachments"></a>
### 添付

電子メールに添付ファイルを追加するには、Mailableクラスの`build`メソッド内で`attach`メソッドを使用します。`attach`メソッドは、ファイルへのフルパスを最初の引数に受けます。

    /**
     * メッセージを作成
     *
     * @return $this
     */
    public function build()
    {
        return $this->view('emails.orders.shipped')
                    ->attach('/path/to/file');
    }

メッセージにファイルを添付する場合、`array`を`attach`メソッドの２番目の引数に渡すことにより、表示名やMIMEタイプを指定することもできます。

    /**
     * メッセージを作成
     *
     * @return $this
     */
    public function build()
    {
        return $this->view('emails.orders.shipped')
                    ->attach('/path/to/file', [
                        'as' => 'name.pdf',
                        'mime' => 'application/pdf',
                    ]);
    }

<a name="attaching-files-from-disk"></a>
#### ディスクからファイルを添付

[ファイルシステムディスク](/docs/{{version}}/filesystem)のいずれかにファイルを保存している場合は、`attachFromStorage`メソッドを使用してファイルを電子メールに添付できます。

    /**
     * メッセージを作成
     *
     * @return $this
     */
    public function build()
    {
       return $this->view('emails.orders.shipped')
                   ->attachFromStorage('/path/to/file');
    }

必要に応じて、`attachFromStorage`メソッドの２番目と３番目の引数を使用して、ファイルの添付ファイル名と追加オプションを指定できます。

    /**
     * メッセージを作成
     *
     * @return $this
     */
    public function build()
    {
       return $this->view('emails.orders.shipped')
                   ->attachFromStorage('/path/to/file', 'name.pdf', [
                       'mime' => 'application/pdf'
                   ]);
    }

デフォルトのディスク以外のストレージディスクを指定する必要がある場合は、`attachFromStorageDisk`メソッドを使用します。

    /**
     * メッセージを作成
     *
     * @return $this
     */
    public function build()
    {
       return $this->view('emails.orders.shipped')
                   ->attachFromStorageDisk('s3', '/path/to/file');
    }

<a name="raw-data-attachments"></a>
#### 素のデータの添付ファイル

`attachData`メソッドを使用して、素のバイト文字列を添付ファイルとして添付できます。たとえば、メモリ内にPDFを生成し、ディスクに書き込まずに電子メールに添付する場合は、この方法を使用できます。`attachData`メソッドは、最初の引数に素のデータバイトを取り、２番目の引数にファイルの名前、３番目の引数にオプションの配列を取ります。

    /**
     * メッセージを作成
     *
     * @return $this
     */
    public function build()
    {
        return $this->view('emails.orders.shipped')
                    ->attachData($this->pdf, 'name.pdf', [
                        'mime' => 'application/pdf',
                    ]);
    }

<a name="inline-attachments"></a>
### インライン添付

インライン画像をメールに埋め込むのは、通常面倒です。ただし、Laravelはメールに画像を添付する便利な方法を提供しています。インライン画像を埋め込むには、メールテンプレート内の`$message`変数で`embed`メソッドを使用します。Laravelは自動的に`$message`変数をすべてのメールテンプレートで利用できるようにするので、手動で渡すことを心配する必要はありません。

    <body>
        Here is an image:

        <img src="{{ $message->embed($pathToImage) }}">
    </body>

> {note} 平文ンテキストメッセージはインライン添付ファイルを利用しないため、`$message`変数は平文テキストメッセージテンプレートでは使用できません。

<a name="embedding-raw-data-attachments"></a>
#### 素のデータの添付ファイルへの埋め込み

電子メールテンプレートに埋め込みたい素の画像データ文字列がすでにある場合は、`$message`変数で`embedData`メソッドを呼び出すことができます。`embedData`メソッドを呼び出すときは、埋め込み画像に割り当てる必要のあるファイル名を指定する必要があります。

    <body>
        Here is an image from raw data:

        <img src="{{ $message->embedData($data, 'example-image.jpg') }}">
    </body>

<a name="customizing-the-swiftmailer-message"></a>
### SwiftMailerメッセージのカスタマイズ

`Mailable`基本クラスの`withSwiftMessage`メソッドを使用すると、メッセージを送信する前にSwiftMailerメッセージインスタンスで呼び出されるクロージャを登録できます。これにより、メッセージが配信される前に、メッセージを大幅にカスタマイズする機会が得られます。

    /**
     * メッセージを作成
     *
     * @return $this
     */
    public function build()
    {
        $this->view('emails.orders.shipped');

        $this->withSwiftMessage(function ($message) {
            $message->getHeaders()->addTextHeader(
                'Custom-Header', 'Header Value'
            );
        });
        
        return $this;
    }

<a name="markdown-mailables"></a>
## Markdown Mailable

Markdown Mailableメッセージを使用すると、Mailableで[メール通知](/docs/{{version}}/notifys#mail-notifications)の事前に作成されたテンプレートとコンポーネントを利用できます。メッセージはMarkdownで記述されているため、Laravelはメッセージの美しくレスポンシブなHTMLテンプレートをレンダーすると同時に、平文テキスト版も自動的に生成できます。

<a name="generating-markdown-mailables"></a>
### Markdown Mailableの生成

対応するMarkdownテンプレートを使用してMailableファイルを生成するには、`make:mail` Artisanコマンドの`--markdown`オプションを使用します。

    php artisan make:mail OrderShipped --markdown=emails.orders.shipped

次に、Mailableオブジェクトをその`build`メソッド内で設定するときに、`view`メソッドの代わりに`markdown`メソッドを呼び出します。`markdown`メソッドは、Markdownテンプレートの名前と、テンプレートで使用するデータ配列をオプションとして引数に取ります。

    /**
     * メッセージを作成
     *
     * @return $this
     */
    public function build()
    {
        return $this->from('example@example.com')
                    ->markdown('emails.orders.shipped', [
                        'url' => $this->orderUrl,
                    ]);
    }

<a name="writing-markdown-messages"></a>
### Markdownメッセージの記述

Markdown Mailableは、BladeコンポーネントとMarkdown構文の組み合わせを使用して、Laravelに組み込まれた電子メールUIコンポーネントを活用しながら、メールメッセージを簡単に作成できるようにします。

    @component('mail::message')
    # Order Shipped

    Your order has been shipped!

    @component('mail::button', ['url' => $url])
    View Order
    @endcomponent

    Thanks,<br>
    {{ config('app.name') }}
    @endcomponent

> {tip} Markdownメールを書くときに余分なインデントを使用しないでください。Markdown標準に従って、Markdownパーサーはインデントされたコンテンツをコードブロックとしてレンダリングします。

<a name="button-component"></a>
#### ボタンコンポーネント

ボタンコンポーネントは、中央に配置されたボタンリンクをレンダーします。コンポーネントは、`url`とオプションの`color`の２つの引数を取ります。サポートしている色は、`primary`、`success`、`error`です。メッセージには、必要なだけのボタンコンポーネントを追加できます。

    @component('mail::button', ['url' => $url, 'color' => 'success'])
    View Order
    @endcomponent

<a name="panel-component"></a>
#### パネルコンポーネント

パネルコンポーネントは、メッセージの残りの部分とはわずかに異なる背景色を持つパネルで、指定するテキストのブロックをレンダーします。これにより、特定のテキストブロックに注意を引くことができます。

    @component('mail::panel')
    This is the panel content.
    @endcomponent

<a name="table-component"></a>
#### テーブルコンポーネント

テーブルコンポーネントを使用すると、MarkdownテーブルをHTMLテーブルに変換できます。コンポーネントは、そのコンテンツとしてMarkdownテーブルを受け入れます。テーブルの列の配置は、デフォルトのMarkdownテーブルの配置構文をサポートします。

    @component('mail::table')
    | Laravel       | Table         | Example  |
    | ------------- |:-------------:| --------:|
    | Col 2 is      | Centered      | $10      |
    | Col 3 is      | Right-Aligned | $20      |
    @endcomponent

<a name="customizing-the-components"></a>
### コンポーネントのカスタマイズ

カスタマイズするために、すべてのMarkdownメールコンポーネントを自身のアプリケーションへエクスポートできます。コンポーネントをエクスポートするには、`vendor:publish`　Artisanコマンドを使用して`laravel-mail`アセットタグでリソース公開します。

    php artisan vendor:publish --tag=laravel-mail

このコマンドは、Markdownメールコンポーネントを`resources/views/vendor/mail`ディレクトリへリソース公開します。`mail`ディレクトリには`html`ディレクトリと`text`ディレクトリが含まれ、それぞれに利用可能なすべてのコンポーネントのそれぞれの表現が含まれます。これらのコンポーネントは自由にカスタマイズできます。

<a name="customizing-the-css"></a>
#### CSSのカスタマイズ

コンポーネントをエクスポートした後、`resources/views/vendor/mail/html/themes`ディレクトリには`default.css`ファイルが含まれます。このファイルのCSSをカスタマイズすると、MarkdownメールメッセージのHTML表現内でスタイルが自動的にインラインCSSスタイルに変換されます。

LaravelのMarkdownコンポーネント用にまったく新しいテーマを作成したい場合は、CSSファイルを`html/themes`ディレクトリに配置できます。CSSファイルに名前を付けて保存した後、アプリケーションの`config/mail.php`設定ファイルの`theme`オプションを更新して、新しいテーマの名前と一致させます。

個々のMailableのテーマをカスタマイズするには、Mailableクラスの`$theme`プロパティを、そのMailableを送信するときに使用するテーマの名前に設定します。

<a name="sending-mail"></a>
## メール送信

メッセージを送信するには、`Mail`[ファサード](/docs/{{version}}/facades)で`to`メソッドを使用します。`to`メソッドは、電子メールアドレス、ユーザーインスタンス、またはユーザーのコレクションを受け入れます。オブジェクトまたはオブジェクトのコレクションを渡すと、メーラーは電子メールの受信者を決定するときに自動的に`email`および`name`プロパティを使用するため、これらの属性がオブジェクトで使用可能であることを確認してください。受信者を指定したら、Mailableクラスのインスタンスを`send`メソッドに渡すことができます。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use App\Mail\OrderShipped;
    use App\Models\Order;
    use Illuminate\Http\Request;
    use Illuminate\Support\Facades\Mail;

    class OrderShipmentController extends Controller
    {
        /**
         * 指定注文を発送
         *
         * @param  \Illuminate\Http\Request  $request
         * @return \Illuminate\Http\Response
         */
        public function store(Request $request)
        {
            $order = Order::findOrFail($request->order_id);

            // 注文を発送…

            Mail::to($request->user())->send(new OrderShipped($order));
        }
    }

メッセージを送信するときに「宛先」の受信者を指定するだけに限定されません。それぞれのメソッドをチェーン化することで、「to」、「cc」、「bcc」の受信者を自由に設定できます。

    Mail::to($request->user())
        ->cc($moreUsers)
        ->bcc($evenMoreUsers)
        ->send(new OrderShipped($order));

<a name="looping-over-recipients"></a>
#### 受信者をループする

場合によっては、受信者/電子メールアドレスの配列を反復処理して、受信者のリストにMailableファイルを送信する必要が起きるでしょう。しかし、`to`メソッドはメールアドレスをMailable受信者のリストに追加するため、ループを繰り返すたびに、以前のすべての受信者に別のメールが送信されます。したがって、受信者ごとにMailableインスタンスを常に再作成する必要があります。

    foreach (['taylor@example.com', 'dries@example.com'] as $recipient) {
        Mail::to($recipient)->send(new OrderShipped($order));
    }

<a name="sending-mail-via-a-specific-mailer"></a>
#### 特定のメーラーを介してメールを送信

デフォルトでは、Laravelはアプリケーションの`mail`設定ファイルで`default`メーラーとして設定されたメーラーを使用してメールを送信します。しかし、`mailer`メソッドを使用して、特定のメーラー設定を使用してメッセージを送信することができます。

    Mail::mailer('postmark')
            ->to($request->user())
            ->send(new OrderShipped($order));

<a name="queueing-mail"></a>
### メールのキュー投入

<a name="queueing-a-mail-message"></a>
#### メールメッセージのキュー投入

電子メールメッセージの送信はアプリケーションのレスポンス時間に悪影響を与える可能性があるため、多くの開発者はバックグラウンド送信のために電子メールメッセージをキューに投入することを選択します。Laravelは組み込みの[統一キューAPI](/docs/{{version}}/queues)を使用してこれを簡単にしています。メールメッセージをキューに投入するには、メッセージの受信者を指定した後、`Mail`ファサードで`queue`メソッドを使用します。

    Mail::to($request->user())
        ->cc($moreUsers)
        ->bcc($evenMoreUsers)
        ->queue(new OrderShipped($order));

このメソッドは、メッセージがバックグラウンドで送信されるように、ジョブをキューへ自動的に投入処理します。この機能を使用する前に、[キューを設定](/docs/{{version}}/queues)しておく必要があります。

<a name="delayed-message-queueing"></a>
#### 遅延メッセージキュー

キューに投入した電子メールメッセージの配信を遅らせたい場合は、`later`メソッドを使用します。`later`メソッドは最初の引数にメッセージの送信時期を示す`DateTime`インスタンスを取ります。。

    Mail::to($request->user())
        ->cc($moreUsers)
        ->bcc($evenMoreUsers)
        ->later(now()->addMinutes(10), new OrderShipped($order));

<a name="pushing-to-specific-queues"></a>
#### 特定のキューへの投入

`make:mail`コマンドを使用して生成したすべてのMailableクラスは`Illuminate\Bus\Queueable`トレイトを利用するため、任意のMailableクラスインスタンスで`onQueue`メソッドと`onConnection`メソッドを呼び出して、メッセージに使う接続とキュー名を指定できます。

    $message = (new OrderShipped($order))
                    ->onConnection('sqs')
                    ->onQueue('emails');

    Mail::to($request->user())
        ->cc($moreUsers)
        ->bcc($evenMoreUsers)
        ->queue($message);

<a name="queueing-by-default"></a>
#### デフォルトでのキュー投入

常にキューに入れたいMailableクラスがある場合は、クラスに`ShouldQueue`契約を実装できます。これで、メール送信時に`send`メソッドを呼び出しても、この契約を実装しているため、Mailableはキューへ投入されます。

    use Illuminate\Contracts\Queue\ShouldQueue;

    class OrderShipped extends Mailable implements ShouldQueue
    {
        //
    }

<a name="queued-mailables-and-database-transactions"></a>
#### Mailableのキュー投入とデータベーストランザクション

キュー投入されたMailableがデータベーストランザクション内でディスパッチされると、データベーストランザクションがコミットされる前にキューによって処理される場合があります。これが発生した場合、データベーストランザクション中にモデルまたはデータベースレコードに加えた更新は、データベースにまだ反映されていない可能性があります。さらに、トランザクション内で作成したモデルまたはデータベースレコードは、データベースに存在しない可能性があります。Mailableがこれらのモデルに依存している場合、キューに入れられたMailableを送信するジョブが処理されるときに予期しないエラーが発生する可能性があります。

キュー接続の`after_commit`設定オプションが`false`に設定されている場合でも、Mailableクラスで`$afterCommit`プロパティを定義することにより、開いているすべてのデータベーストランザクションがコミットされた後に、特定のキューに入れられたMailableをディスパッチする必要があることを明示できます。

    use Illuminate\Contracts\Queue\ShouldQueue;

    class OrderShipped extends Mailable implements ShouldQueue
    {
        public $afterCommit = true;
    }

> {tip} これらの問題の回避方法の詳細は、[キュー投入したジョブとデータベーストランザクション](/docs/{{version}}/queues#jobs-and-database-transactions)に関するドキュメントを確認してください。

<a name="rendering-mailables"></a>
## Mailableのレンダー

MailableのHTMLコンテンツを送信せずにキャプチャしたい場合があります。これを行うには、Mailableの`render`メソッドを呼び出してください。このメソッドは、Mailableファイルの評価済みHTMLコンテンツを文字列として返します。

    use App\Mail\InvoicePaid;
    use App\Models\Invoice;

    $invoice = Invoice::find(1);

    return (new InvoicePaid($invoice))->render();

<a name="previewing-mailables-in-the-browser"></a>
### ブラウザによるMailableのプレビュー

Mailableのテンプレートを設計するときは、通常のBladeテンプレートのように、レンダー済みMailableをブラウザですばやくプレビューできると便利です。このためLaravelでは、ルートクロージャまたはコントローラから直接Mailableを返せます。Mailableが返されると、ブラウザでレンダーされ表示されるため、実際の電子メールアドレスへ送信しなくても、デザインをすばやくプレビューできます。

    Route::get('/mailable', function () {
        $invoice = App\Models\Invoice::find(1);

        return new App\Mail\InvoicePaid($invoice);
    });

> {note} [インライン添付ファイル](#inline-attachments)は、Mailableファイルがブラウザでプレビューされたときにレンダリングされません。これらのメーラブルをプレビューするには、[MailHog](https://github.com/mailhog/MailHog)や[HELO](https://usehelo.com)などのメールテストアプリケーションに送信する必要があります。

<a name="localizing-mailables"></a>
## Mailableの多言語化

Laravelを使用すると、リクエストの現在のロケール以外のロケールでMailableファイルを送信でき、メールがキュー投入される場合でもこのロケールを記憶しています。

これを実現するために、`Mail`ファサードは目的の言語を設定するための`locale`メソッドを提供します。Mailableのテンプレートが評価されると、アプリケーションはこのロケールに変更され、評価が完了すると前のロケールに戻ります。

    Mail::to($request->user())->locale('es')->send(
        new OrderShipped($order)
    );

<a name="user-preferred-locales"></a>
### ユーザー優先ロケール

場合によっては、アプリケーションは各ユーザーの優先ロケールを保存しています。１つ以上のモデルに`HasLocalePreference`コントラクトを実装することで、メールを送信するときにこの保存されたロケールを使用するようにLaravelに指示できます。

    use Illuminate\Contracts\Translation\HasLocalePreference;

    class User extends Model implements HasLocalePreference
    {
        /**
         * ユーザーの希望するロケールを取得
         *
         * @return string
         */
        public function preferredLocale()
        {
            return $this->locale;
        }
    }

このインターフェイスを実装すると、LaravelはMailableと通知をモデルへ送信するとき、自動的に優先ロケールを使用します。したがって、このインターフェイスを使用する場合、`locale`メソッドを呼び出す必要はありません。

    Mail::to($request->user())->send(new OrderShipped($order));

<a name="testing-mailables"></a>
## Mailableのテスト

Laravelは、Mailableに期待するコンテンツが含まれていることをテストするための便利な方法をいくつか提供しています。これらのメソッドは、`assertSeeInHtml`、`assertDontSeeInHtml`、`assertSeeInText`、`assertDontSeeInText`です。

ご想像のとおり、"HTML"アサートは、メーラブルのHTMLバージョンに特定の文字列が含まれていることを宣言し、"text"アサートは、Mailableの平文テキストバージョンに特定の文字列が含まれていることを宣言します。

    use App\Mail\InvoicePaid;
    use App\Models\User;

    public function test_mailable_content()
    {
        $user = User::factory()->create();

        $mailable = new InvoicePaid($user);

        $mailable->assertSeeInHtml($user->email);
        $mailable->assertSeeInHtml('Invoice Paid');

        $mailable->assertSeeInText($user->email);
        $mailable->assertSeeInText('Invoice Paid');
    }

<a name="testing-mailable-sending"></a>
#### Mailableの送信テスト

指定のMailableが特定のユーザーへ「送信」されたことをアサートするテストとは別に、Mailableのコンテンツをテストするのを推奨します。メールが送信されたことをテストする方法については、[Mail fake](/docs/{{version}}/mocking#mail-fake)のドキュメントをご覧ください。

<a name="mail-and-local-development"></a>
## メールとローカル開発

電子メールを送信するアプリケーションを開発する場合、実際の電子メールアドレスに電子メールを送信したくない場合があります。Laravelは、ローカル開発中に実際の電子メールの送信を「無効にする」ためのいくつかの方法を提供します。

<a name="log-driver"></a>
#### Logドライバ

メールを送信する代わりに、`log`メールドライバは検査のためにすべてのメールメッセージをログファイルに書き込みます。通常、このドライバはローカル開発中にのみ使用されます。環境ごとのアプリケーションの設定の詳細については、[設定ドキュメント](/docs/{{version}}/configuration#environment-configuration)を確認してください。

<a name="mailtrap"></a>
#### HELO／Mailtrap／MailHog

[HELO](https://usehelo.com)や[Mailtrap](https://mailtrap.io)などのサービスと`smtp`ドライバを使用して、メールメッセージを「ダミー」メールボックスに送信可能です。本当の電子メールクライアントでそれらを表示できます。このアプローチには、Mailtrapのメッセージビューアで最終的な電子メールを実際に調べられるという利点があります。

[Laravel Sail](/docs/{{version}}/sale)を使用している場合は、[MailHog](https://github.com/mailhog/MailHog)を使用してメッセージをプレビューできます。Sailの実行中は、`http://localhost:8025`でMailHogインターフェイスにアクセスできます。

<a name="events"></a>
## イベント

Laravelは、メールメッセージの送信プロセス中に２つのイベントを発行します。`MessageSending`イベントはメッセージが送信される前に発生し、`MessageSent`イベントはメッセージが送信された後に発生します。これらのイベントは、メールをキューへ投入したときではなく、メールが**送信されている**ときに発生することを忘れないでください。このイベントのイベントリスナは、`App\Providers\EventServiceProvider`サービスプロバイダで登録できます。

    /**
     * アプリケーションのイベントリスナマッピング
     *
     * @var array
     */
    protected $listen = [
        'Illuminate\Mail\Events\MessageSending' => [
            'App\Listeners\LogSendingMessage',
        ],
        'Illuminate\Mail\Events\MessageSent' => [
            'App\Listeners\LogSentMessage',
        ],
    ];
