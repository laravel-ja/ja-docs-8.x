# Laravel Cashier

- [イントロダクション](#introduction)
- [Cashierのアップデート](#upgrading-cashier)
- [インストール](#installation)
- [設定](#configuration)
    - [Billableモデル](#billable-model)
    - [APIキー](#api-keys)
    - [通貨設定](#currency-configuration)
    - [ログ](#logging)
- [顧客](#customers)
    - [顧客の取得](#retrieving-customers)
    - [顧客の生成](#creating-customers)
    - [顧客の更新](#updating-customers)
    - [支払いポータル](#billing-portal)
- [支払い方法](#payment-methods)
    - [支払い方法の保存](#storing-payment-methods)
    - [支払い方法の取得](#retrieving-payment-methods)
    - [ユーザーが支払い方法を持っているかの判定](#check-for-a-payment-method)
    - [デフォルト支払い方法の更新](#updating-the-default-payment-method)
    - [支払い方法の追加](#adding-payment-methods)
    - [支払い方法の削除](#deleting-payment-methods)
- [定期サブスクリプション](#subscriptions)
    - [サブスクリプション作成](#creating-subscriptions)
    - [サブスクリプション状態の確認](#checking-subscription-status)
    - [プラン変更](#changing-plans)
    - [サブスクリプション数](#subscription-quantity)
    - [複数のサブスクリプション](#multiplan-subscriptions)
    - [サブスクリプションの税金](#subscription-taxes)
    - [サブスクリプション課金日付け](#subscription-anchor-date)
    - [サブスクリプションキャンセル](#cancelling-subscriptions)
    - [サブスクリプション再開](#resuming-subscriptions)
- [サブスクリプションのトレイト](#subscription-trials)
    - [支払いの事前登録あり](#with-payment-method-up-front)
    - [支払いの事前登録なし](#without-payment-method-up-front)
    - [試用期限の延長](#extending-trials)
- [StripeのWebフック処理](#handling-stripe-webhooks)
    - [Webフックハンドラの定義](#defining-webhook-event-handlers)
    - [サブスクリプション不可](#handling-failed-subscriptions)
    - [Webフック署名の確認](#verifying-webhook-signatures)
- [一回だけの課金](#single-charges)
    - [シンプルな課金](#simple-charge)
    - [インボイス付き課金](#charge-with-invoice)
    - [払い戻し](#refunding-charges)
- [インボイス](#invoices)
    - [インボイス取得](#retrieving-invoices)
    - [インボイスPDF生成](#generating-invoice-pdfs)
- [課金失敗の処理](#handling-failed-payments)
- [堅牢な顧客認証 (SCA)](#strong-customer-authentication)
    - [支払い要求の追加確認](#payments-requiring-additional-confirmation)
    - [非セッション確立時の支払い通知](#off-session-payment-notifications)
- [Stripe SDK](#stripe-sdk)
- [テスト](#testing)

<a name="introduction"></a>
## イントロダクション

Laravel Cashierは[Stripe](https://stripe.com)によるサブスクリプション（定期課金）サービスの読みやすく、スラスラと記述できるインターフェイスを提供します。これにより書くのが恐ろしくなるような、サブスクリプション支払いのための決まりきったコードのほとんどが処理できます。基本的なサブスクリプション管理に加え、Cashierはクーポン、サブスクリプションの変更、サブスクリプション数、キャンセル猶予期間、さらにインボイスのPDF発行まで行います。

<a name="upgrading-cashier"></a>
## Cashierのアップデート

新しいバージョンのCashierへアップグレードする場合は、[アップグレードガイド](https://github.com/laravel/cashier-stripe/blob/master/UPGRADE.md)を注意深く確認することが重要です。

> {note} ブレーキングチェンジを防ぐために、CashierではStripeの固定APIバージョンを使用しています。Cashier12では、Stripeの`2020-03-02`付けAPIバージョンを使用しています。Stripeの新機能や機能向上を利用するため、マイナーリリースでもStripe APIのバージョンを更新することがあります。

<a name="installation"></a>
## インストール

はじめに、Stripe向けCashierパッケージをComposerでインストールしてください。

    composer require laravel/cashier

> {note} Stripeの全イベントをCashierで確実に処理するために、[CashierのWebhook処理の準備](#handling-stripe-webhooks)を行なってください。

#### データベースマイグレーション

CashierサービスプロバーダでCashierのデータベースマイグレーションを登録しています。ですから、パッケージをインストールしたら、データベースのマイグレーションを忘れず実行してください。Cashierマイグレーションは`users`テーブルにいくつものカラムを追加し、顧客のサブスクリプションをすべて保持するために新しい`subscriptions`テーブルを作成します。

    php artisan migrate

Cashierパッケージに始めから含まれているマイグレーションをオーバーライトしたい場合は、`vendor:publish` Artisanコマンドを使用しリソース公開できます。

    php artisan vendor:publish --tag="cashier-migrations"

Cashierのマイグレーション実行を完全に防ぎたい場合は、Cashierが提供している`ignoreMigrations`を使います。通常、このメソッドは`AppServiceProvider`の`register`メソッドの中で実行すべきです。

    use Laravel\Cashier\Cashier;

    Cashier::ignoreMigrations();

> {note} StripeはStripeの識別子を保存しておくカラムはケースセンシティブ（大文字小文字区別）にするべきだと勧めています。そのため`stripe_id`カラムには、たとえばMySQLでは`utf8_bin`のように、適切なカラムコレーションを確実に指定してください。詳しい情報は、[Stripeのドキュメント](https://stripe.com/docs/upgrades#what-changes-does-stripe-consider-to-be-backwards-compatible)をお読みください。

<a name="configuration"></a>
## 設定

<a name="billable-model"></a>
### Billableモデル

Cashierを使い始める前に、モデル定義に`Billable`トレイトを追加します。このトレイトはサブスクリプションの作成やクーポンの適用、支払い情報の更新などのような、共通の支払いタスク実行を提供する数多くのメソッドを提供しています。

    use Laravel\Cashier\Billable;

    class User extends Authenticatable
    {
        use Billable;
    }

CashierはLaravelに含まれている`App\Models\User`クラスがBillableモデルであると仮定しています。これを変更する場合は、`.env`ファイルでモデルを指定してください

    CASHIER_MODEL=App\Models\User

> {note} Laravelの提供する`App\Models\User`モデル以外のモデルを使用する場合は、提供している[マイグレーション](#installation)をリソース公開し、モデルのテーブル名に一致するように変更する必要があります。

<a name="api-keys"></a>
### APIキー

次に、`.env`ファイルの中のStripeキーを設定する必要があります。Stripe APIキーは、Stripeのコントロールパネルから取得できます。

    STRIPE_KEY=your-stripe-key
    STRIPE_SECRET=your-stripe-secret

<a name="currency-configuration"></a>
### 通貨設定

Cashierのデフォルト通貨は米ドル(USD)です。`CASHIER_CURRENCY`環境変数の指定で、デフォルト通貨を変更可能です。

    CASHIER_CURRENCY=eur

Caishierの通貨設定に付け加え、インボイスで表示する金額のフォーマットをローケルを使い指定することも可能です。Cashierは内部で、通貨のローケルを指定するために、[PHPの`NumberFormatter`クラス](https://www.php.net/manual/en/class.numberformatter.php)を利用しています。

    CASHIER_CURRENCY_LOCALE=nl_BE

> {note} `en`以外のローケルを指定する場合は、サーバ設定で`ext-intl` PHP拡張がインストールされているのを確認してください。

<a name="logging"></a>
#### ログ

Stripeに関連する例外をすべてログする時に使用できるログチャンネルをCashierでは指定できます。`CASHIER_LOGGER`環境変数を使用し、ログチャンネルを指定します。

    CASHIER_LOGGER=stack

<a name="customers"></a>
## 顧客

<a name="retrieving-customers"></a>
### 顧客の取得

`Cashier::findBillable`メソッドによりStripe IDで顧客を取得できます。Billableモデルのインスタンスを返します。

    use Laravel\Cashier\Cashier;

    $user = Cashier::findBillable($stripeId);

<a name="creating-customers"></a>
### 顧客の生成

サブスクリプションを開始しなくてもStripeで顧客を作成したい場合が、ときどき起きるでしょう。`createAsStripeCustomer`を使い、作成できます。

    $stripeCustomer = $user->createAsStripeCustomer();

一度顧客をStripe上に作成しておき、後日サブスクリプションを開始することもできます。また、Stripe APIが提供するオプション（`$options`）を配列として、追加引数に渡すことも可能です。

    $stripeCustomer = $user->createAsStripeCustomer($options);

BillableなエンティティがすでにStripeの顧客である場合に顧客オブジェクトを返したい場合は、`asStripeCustomer`メソッドを使用できます。

    $stripeCustomer = $user->asStripeCustomer();

`createOrGetStripeCustomer`メソッドは、顧客オブジェクトを返したいがBillableなエンティティがすでにStripeの顧客であるかどうかわからない場合に使用します。このメソッドは、まだ存在していない場合、Stripeに新しい顧客を作成します。

    $stripeCustomer = $user->createOrGetStripeCustomer();

<a name="updating-customers"></a>
### 顧客の更新

まれに、Stripeの顧客を追加情報と一緒に直接更新したい状況もあります。`updateStripeCustomer`メソッドを使用してください。

    $stripeCustomer = $user->updateStripeCustomer($options);

<a name="billing-portal"></a>
### 支払いポータル

顧客がサブスクリプションや支払い方法を管理したり、履歴を確認したりを簡単にできるよう、Stripeは[支払いポータルを用意](https://stripe.com/docs/billing/subscriptions/customer-portal)しています。コントローラやルートで`redirectToBillingPortal`メソッドを使えば、ユーザーを支払いポータルへリダイレクトできます。

    use Illuminate\Http\Request;

    public function billingPortal(Request $request)
    {
        return $request->user()->redirectToBillingPortal();
    }

サブスクリプションの管理を終えたユーザーは、アプリケーションの`home`ルートへ戻されるのがデフォルトです。`redirectToBillingPortal`メソッドの引数としてユーザーの戻りURLを指定し、カスタマイズ可能です。

    use Illuminate\Http\Request;

    public function billingPortal(Request $request)
    {
        return $request->user()->redirectToBillingPortal(
            route('billing')
        );
    }

支払いポータルへのURLを生成のみしたい場合は`billingPortalUrl`メソッドを使用してください。

    $url = $user->billingPortalUrl(route('billing'));

<a name="payment-methods"></a>
## 支払い方法

<a name="storing-payment-methods"></a>
### 支払い方法の保存

Stripeでサブスクリプションを生成するか「一度だけ」の課金を実行するためには、支払い方法を登録し、IDを取得する必要があります。サブスクリプションのための支払いメソッドか、一回だけの課金ためかによりアプローチが異なるため、以下で両方共にみていきましょう。

#### サブスクリプションの支払い方法

将来の仕様に備えて、顧客のクレジットカードを登録する場合、顧客の支払いメソッドの詳細を安全に集めるためにStripe Setup Intents APIを使う必要があります。"Setup Intent（意図）"は、Stripeに対し顧客の支払いメソッドを登録する意図を示しています。Cashierの`Billable`トレイトは、新しいSetup Intentを簡単に作成できる`createSetupIntent`を含んでいます。顧客の支払いメソッドの詳細情報を集めるフォームをレンダーしたいルートやコントローラから、このメソッドを呼び出してください。

    return view('update-payment-method', [
        'intent' => $user->createSetupIntent()
    ]);

 Setup Intentを作成したらそれをビューに渡し、支払い方法を集める要素にsecretを付け加える必要があります。たとえば、このような「支払い方法更新」フォームを考えてください。

    <input id="card-holder-name" type="text">

    <!-- Stripe要素のプレースホルダ -->
    <div id="card-element"></div>

    <button id="card-button" data-secret="{{ $intent->client_secret }}">
        Update Payment Method
    </button>

Stripe.jsライブラリを使い、Stripe要素をフォームに付け加え、顧客の支払いの詳細を安全に収集します。

    <script src="https://js.stripe.com/v3/"></script>

    <script>
        const stripe = Stripe('stripe-public-key');

        const elements = stripe.elements();
        const cardElement = elements.create('card');

        cardElement.mount('#card-element');
    </script>

これで[Stripeの`confirmCardSetup`メソッド](https://stripe.com/docs/js/setup_intents/confirm_card_setup)を使用してカードを検証し、Stripeから安全な「支払い方法識別子」を取得できます。

    const cardHolderName = document.getElementById('card-holder-name');
    const cardButton = document.getElementById('card-button');
    const clientSecret = cardButton.dataset.secret;

    cardButton.addEventListener('click', async (e) => {
        const { setupIntent, error } = await stripe.confirmCardSetup(
            clientSecret, {
                payment_method: {
                    card: cardElement,
                    billing_details: { name: cardHolderName.value }
                }
            }
        );

        if (error) {
            // ユーザーに"error.message"を表示する…
        } else {
            // カードの検証に成功した…
        }
    });

Stripeによりカードが検証されたら、顧客に付け加えた`setupIntent.payment_method`の結果をLaravelアプリケーションへ渡すことができます。支払い方法は[新しい支払い方法を追加](#adding-payment-methods)するのと、[デフォルトの支払い方法を使用](#updating-the-default-payment-method)する、どちらかが選べます。[新しい支払い方法を追加](#adding-payment-methods)の支払いメソッド識別子を即時に使用することもできます。

> {tip} Setup Intentsと顧客支払いの詳細情報の収集に関するより詳しい情報は、[Stripeが提供している概要](https://stripe.com/docs/payments/save-and-reuse#php)をご覧ください。

#### 一回のみの課金に対する支払い方法

顧客の支払いメソッドに対し一回のみの課金を作成する場合、ワンタイムの支払いメソッド識別子を使う必要があるだけで済みます。Stripeの制限により、保存されている顧客のデフォルト支払い方法は使用できません。Stripe.jsライブラリを使用し、顧客に支払い方法の詳細を入力してもらえるようにする必要があります。例として、以降のフォームを考えてみましょう。

    <input id="card-holder-name" type="text">

    <!-- Stripe要素のプレースホルダ -->
    <div id="card-element"></div>

    <button id="card-button">
        Process Payment
    </button>

Stripe.jsライブラリを使い、Stripe要素をフォームに付け加え、顧客の支払いの詳細を安全に収集します。

    <script src="https://js.stripe.com/v3/"></script>

    <script>
        const stripe = Stripe('stripe-public-key');

        const elements = stripe.elements();
        const cardElement = elements.create('card');

        cardElement.mount('#card-element');
    </script>

[Stripeの`createPaymentMethod`メソッド](https://stripe.com/docs/stripe-js/reference#stripe-create-payment-method)を活用し、Stripeによりカードが検証し、安全な「支払い方法識別子」をSrtipeから取得します。

    const cardHolderName = document.getElementById('card-holder-name');
    const cardButton = document.getElementById('card-button');

    cardButton.addEventListener('click', async (e) => {
        const { paymentMethod, error } = await stripe.createPaymentMethod(
            'card', cardElement, {
                billing_details: { name: cardHolderName.value }
            }
        );

        if (error) {
            // ユーザーに"error.message"を表示する…
        } else {
            // カードの検証に成功した…
        }
    });

カードの検証が成功すれば、`paymentMethod.id`をLaravelアプリケーションに渡し、[１回限りの支払い](#simple-charge)を処理できます。

<a name="retrieving-payment-methods"></a>
### 支払い方法の取得

Billableモデルインスタンスの`paymentMethods`メソッドは、`Laravel\Cashier\PaymentMethod`インスタンスのコレクションを返します。

    $paymentMethods = $user->paymentMethods();

デフォルト支払いメソッドを取得する場合は、`defaultPaymentMethod`メソッドを使用してください。

    $paymentMethod = $user->defaultPaymentMethod();

`findPaymentMethod`メソッドを使用し、そのBillableモデルが持っている特定の支払いメソッドを取得することもできます。

    $paymentMethod = $user->findPaymentMethod($paymentMethodId);

<a name="check-for-a-payment-method"></a>
### ユーザーが支払い方法を持っているかの判定

Billableモデルが自身のアカウントに付加されているデフォルト支払いメソッドを持っているかを判定するには、`hasDefaultPaymentMethod`メソッドを使用します。

    if ($user->hasDefaultPaymentMethod()) {
        //
    }

Billableモデルが自身のアカウントに付加されている支払いメソッドを最低１つ持っているかを判定するには、`hasPaymentMethod`メソッドを使用します。

    if ($user->hasPaymentMethod()) {
        //
    }

<a name="updating-the-default-payment-method"></a>
### デフォルト支払い方法の更新

`updateDefaultPaymentMethod`メソッドは顧客のデフォルト支払い方法の情報を更新するために使用します。このメソッドはStripe支払いメソッド識別子を引数に取り、その新しい支払い方法がデフォルト支払い方法として設定されます。

    $user->updateDefaultPaymentMethod($paymentMethod);

その顧客のデフォルト支払い方法情報をStripeの情報と同期したい場合は、`updateDefaultPaymentMethodFromStripe`メソッドを使用してください。

    $user->updateDefaultPaymentMethodFromStripe();

> {note} 顧客のデフォルト支払い方法は、インボイス発行処理と新しいサブスクリプションの生成にだけ使用されます。Stripeの制限により、一回だけの課金には使用されません。

<a name="adding-payment-methods"></a>
### 支払い方法の追加

新しい支払い方法を追加するには、Billableのユーザーに対し、`addPaymentMethod`を呼び出します。支払いメソッド識別子を渡してください。

    $user->addPaymentMethod($paymentMethod);

> {tip} 支払い方法の識別子の取得方法を学ぶには、[支払い方法保持のドキュメント](#storing-payment-methods)を確認してください。

<a name="deleting-payment-methods"></a>
### 支払い方法の削除

支払い方法を削除するには、削除したい`Laravel\Cashier\PaymentMethod`インスタンス上の`delete`メソッドを呼び出します。

    $paymentMethod->delete();

`deletePaymentMethods`メソッドは、そのBillableモデルの全支払いメソッド情報を削除します。

    $user->deletePaymentMethods();

> {note} アクティブなサブスクリプションがあるユーザーでは、デフォルト支払いメソッドが削除されないようにする必要があるでしょう。

<a name="subscriptions"></a>
## サブスクリプション

サブスクリプションは顧客の定期支払いを設定し、複数のサブスクリプションプラン、数量、試用期間などをサポートする方法を提供します。

<a name="creating-subscriptions"></a>
### サブスクリプション作成

Tサブスクリプションを作成するには最初にbillableなモデルのインスタンスを取得しますが、通常は`App\Models\User`のインスタンスでしょう。モデルインスタンスが獲得できたら、モデルのサブスクリプションを作成するために、`newSubscription`メソッドを使います。

    $user = User::find(1);

    $user->newSubscription('default', 'price_premium')->create($paymentMethod);

`newSubscription`メソッドの最初の引数は、サブスクリプションの名前です。アプリケーションでサブスクリプションを一つしか取り扱わない場合、`default`か`primary`と名づけましょう。２つ目の引数はユーザーが購入しようとしているサブスクリプションのプランを指定します。この値はStripeのプランの価格識別子に対応させる必要があります。

`create`メソッドは[Stripeの支払い方法識別子](#storing-payment-methods)、もしくは`PaymentMethod`オブジェクトを引数に取り、サブスクリプションを開始するのと同時に、データベースの顧客IDと他の関連する支払い情報を更新します。

> {note} サブスクリプションの`create()`へ支払いメソッド識別子を直接渡すと、ユーザーの保存済み支払いメソッドへ自動的に追加します。

#### 注文数

サブスクリプションの作成時に注文数を指定する場合は、`quantity`メソッドを使います。

    $user->newSubscription('default', 'price_monthly')
         ->quantity(5)
         ->create($paymentMethod);

#### 詳細情報の指定

ユーザーとサブスクリプションに関する詳細情報を追加したい場合は、`create`メソッドの第２引数と第３引数へ渡すことができます。

    $user->newSubscription('default', 'price_monthly')->create($paymentMethod, [
        'email' => $email,
    ], [
        'metadata' => ['note' => 'Some extra information.'],
    ]);

Stripeがサポートしている追加のフィールドについてのさらなる情報は、Stripeの[顧客の作成](https://stripe.com/docs/api#create_customer)と[サブスクリプションの作成](https://stripe.com/docs/api/subscriptions/create)ドキュメントを確認してください。

#### クーポン

サブスクリプションの作成時に、クーポンを適用したい場合は、`withCoupon`メソッドを使用してください。

    $user->newSubscription('default', 'price_monthly')
         ->withCoupon('code')
         ->create($paymentMethod);

#### サブスクリプションの追加

デフォルトの支払い方法を設定済みユーザーへサブスクリプションを追加する場合は、`newSubscription`メソッド使用時に`add`メソッドが使えます。

    $user = User::find(1);

    $user->newSubscription('default', 'price_premium')->add();

<a name="checking-subscription-status"></a>
### サブスクリプション状態の確認

ユーザーがアプリケーションで何かを購入したら、バラエティー豊かで便利なメソッドでサブスクリプション状況を簡単にチェックできます。まず初めに`subscribed`メソッドが`true`を返したら、サブスクリプションが現在試用期間であるにしても、そのユーザーはアクティブなサブスクリプションを持っています。

    if ($user->subscribed('default')) {
        //
    }

`subscribed`メソッドは[ルートミドルウェア](/docs/{{version}}/middleware)で使用しても大変役に立つでしょう。ユーザーのサブスクリプション状況に基づいてルートやコントローラへのアクセスをフィルタリングできます。

    public function handle($request, Closure $next)
    {
        if ($request->user() && ! $request->user()->subscribed('default')) {
            // このユーザーは支払っていない顧客
            return redirect('billing');
        }

        return $next($request);
    }

ユーザーがまだ試用期間であるかを調べるには、`onTrial`メソッドを使用します。このメソッドはまだ使用期間中であるとユーザーに警告を表示するために便利です。

    if ($user->subscription('default')->onTrial()) {
        //
    }

`subscribedToPlan`メソッドは、そのユーザーがStripeの価格IDで指定したプランを購入しているかを確認します。以下の例では、ユーザーの`default`サブスクリプションが、購入され有効な`monthly`プランであるかを確認しています。

    if ($user->subscribedToPlan('price_monthly', 'default')) {
        //
    }

`subscribedToPlan`メソッドに配列を渡せば、ユーザーの`default`サブスクリプションが、購入され有効な`monthly`か`yearly`プランであるかを判定できます。

    if ($user->subscribedToPlan(['price_monthly', 'price_yearly'], 'default')) {
        //
    }

`recurring`メソッドはユーザーが現在サブスクリプションを購入中で、試用期間を過ぎていることを判断するために使用します。

    if ($user->subscription('default')->recurring()) {
        //
    }

> {note} ユーザーが同じ名前のサブスクリプションを２つ持っている場合、最新のサブスクリプションが常に `subscription`メソッドによって返されます。たとえば、ユーザーが`default`という名前の２サブスクリプションレコードを持っているとします。しかし、サブスクリプションの１つは古い期限切れのサブスクリプションであり、もう１つは現在のアクティブなサブスクリプションであるとしましょう。最新のサブスクリプションは常に返されますが、一方の古いサブスクリプションは履歴確認のためにデータベースに保持されます。

#### キャンセルしたサブスクリプションの状態

ユーザーが一度アクティブな購入者になってから、サブスクリプションをキャンセルしたことを調べるには、`cancelled`メソッドを使用します。

    if ($user->subscription('default')->cancelled()) {
        //
    }

また、ユーザーがサブスクリプションをキャンセルしているが、まだ完全に期限が切れる前の「猶予期間」中であるかを調べることもできます。たとえば、ユーザーが３月５日にサブスクリプションをキャンセルし、３月１０日で無効になる場合、そのユーザーは３月１０日までは「猶予期間」中です。`subscribed`メソッドは、この期間中、まだ`true`を返すことに注目してください。

    if ($user->subscription('default')->onGracePeriod()) {
        //
    }

ユーザーがサブスクリプションをキャンセルし、「猶予期間」を過ぎていることを調べるには、`ended`メソッドを使ってください。

    if ($user->subscription('default')->ended()) {
        //
    }

#### サブスクリプションスコープ

特定状態のサブスクリプションをデータベースから簡単にクエリできるよう、ほとんどのサブスクリプション状態はクエリスコープとしても利用できます。

    // アクティブサブスクリプションをすべて取得
    $subscriptions = Subscription::query()->active()->get();

    // 特定ユーザーのキャンセル済みサブスクリプションをすべて取得
    $subscriptions = $user->subscriptions()->cancelled()->get();

以下に利用可能なサブスクリプションスコープをリストします。

    Subscription::query()->active();
    Subscription::query()->cancelled();
    Subscription::query()->ended();
    Subscription::query()->incomplete();
    Subscription::query()->notCancelled();
    Subscription::query()->notOnGracePeriod();
    Subscription::query()->notOnTrial();
    Subscription::query()->onGracePeriod();
    Subscription::query()->onTrial();
    Subscription::query()->pastDue();
    Subscription::query()->recurring();

<a name="incomplete-and-past-due-status"></a>
#### 不十分と期日超過の状態

サブスクリプション作成後、そのサブクリプションが２つ目の支払いアクションを要求している場合、`incomplete`（不十分）として印がつけられます。サブスクリプションの状態は、Cashierの`subscriptions`データベーステーブルの`stripe_status`カラムに保存されます。

同様に、サブスクリプションの変更時に第２の支払いアクションが要求されている場合は、`past_due`（期日超過）として印がつけられます。サブスクリプションが２つのどちらかである時、顧客が支払いを受領するまで状態は有効になりません。あるサブクリプションに不十分な支払いがあるかを確認する場合は、Billableモデルかサブクリプションインスタンス上の`hasIncompletePayment`メソッドを使用します。

    if ($user->hasIncompletePayment('default')) {
        //
    }

    if ($user->subscription('default')->hasIncompletePayment()) {
        //
    }

サブクリプションに不完全な支払いがある場合、`latestPayment`（最後の支払い）識別子を渡したCashierの支払い確認ページをそのユーザーへ表示すべきです。この識別子を取得するには、サブクリプションインスタンスの`latestPayment`メソッドが使用できます。

    <a href="{{ route('cashier.payment', $subscription->latestPayment()->id) }}">
        Please confirm your payment.
    </a>

`past_due`状態のときでも、特定のサブスクリプションをアクティブと見なしたい場合は、Cashierが提供する`keepPastDueSubscriptionsActive`メソッドを使用します。通常このメソッドは、`AppServiceProvider`の`register`メソッドの中で呼び出すべきです。

    use Laravel\Cashier\Cashier;

    /**
     * 全アプリケーションサービスの登録
     *
     * @return void
     */
    public function register()
    {
        Cashier::keepPastDueSubscriptionsActive();
    }

> {note} あるサブクリプションに`incomplete`状態がある場合、支払いを確認するまでは変更できません。そのためサブクリプションが`incomplete`状態では、`swap` や`updateQuantity`メソッドは例外を投げます。

<a name="changing-plans"></a>
### プラン変更

アプリケーションの購入済みユーザーが新しいサブスクリプションプランへ変更したくなるのはよくあるでしょう。ユーザーを新しいサブスクリプションに変更するには、`swap`メソッドへプランの価格識別子を渡します。

    $user = App\Models\User::find(1);

    $user->subscription('default')->swap('provider-price-id');

ユーザーが試用期間中の場合、試用期間は継続します。また、そのプランに「購入数」が存在している場合、購入個数も継続します。

プランを変更し、ユーザーの現プランの試用期間をキャンセルする場合は、`skipTrial`メソッドを使用します。

    $user->subscription('default')
            ->skipTrial()
            ->swap('provider-price-id');

次の支払いサイクルまで待つ代わりに、プランを変更時即時にインボイスを発行したい場合は、`swapAndInvoice`メソッドを使用します。

    $user = App\Models\User::find(1);

    $user->subscription('default')->swapAndInvoice('provider-price-id');

#### 按分課金

デフォルトでStripeはプランの変更時に按分課金(日割り計算：prorate)を行います。`noProrate`メソッドは按分課金を行わずにサブスクリプションの更新を指定するために使用します。

    $user->subscription('default')->noProrate()->swap('provider-price-id');

サブスクリプションの按分課金についての情報は、[Stripeドキュメント](https://stripe.com/docs/billing/subscriptions/prorations)で確認してください。

> {note} `swapAndInvoice`メソッドの前に`noProrate`メソッドを実行しても按分課金には影響しません。インボイスは常に発行されます。

<a name="subscription-quantity"></a>
### 購入数

購入数はサブスクリプションに影響をあたえることがあります。たとえば、あるアプリケーションで「ユーザーごと」に毎月１０ドル課金している場合です。購入数を簡単に上げ下げするには、`incrementQuantity`と`decrementQuantity`メソッドを使います。

    $user = User::find(1);

    $user->subscription('default')->incrementQuantity();

    // 現在の購入数を５個増やす
    $user->subscription('default')->incrementQuantity(5);

    $user->subscription('default')->decrementQuantity();

    // 現在の購入数を５個減らす
    $user->subscription('default')->decrementQuantity(5);

もしくは特定の数量を設置するには、`updateQuantity`メソッドを使ってください。

    $user->subscription('default')->updateQuantity(10);

`noProrate`メソッドは、按分課金を行わずにサブスクリプションの購入数を更新するために使用します。

    $user->subscription('default')->noProrate()->updateQuantity(10);

サブスクリプション数の詳細については、[Stripeドキュメント](https://stripe.com/docs/subscriptions/quantities)を読んでください。

> {note} マルチプランサブスクリプションを使用する場合、上記の数量メソッドには追加の「プラン」パラメーターが必要です。

<a name="multiplan-subscriptions"></a>
### 複数のサブスクリプション

[複数のサブスクリプション](https://stripe.com/docs/billing/subscriptions/multiplan)では、1つのサブスクリプションに複数の請求プランを割り当てられます。たとえば、月額１０ドルの基本サブスクリプションがあり、さらに月額１６ドルのライブチャットアドオンプランを提供する、カスタマーサービスの「ヘルプデスク」アプリケーションを構築していると想像してください。

    $user = User::find(1);

    $user->newSubscription('default', [
        'price_monthly',
        'chat-plan',
    ])->create($paymentMethod);

これにより、顧客は新しいデフォルト（`default`）サブスクリプションを購入できました。両プランともそれぞれの課金期間に応じ、課金されます。各プランの購入数を指定するために`quantity`メソッドも使えます。

    $user = User::find(1);

    $user->newSubscription('default', ['price_monthly', 'chat-plan'])
        ->quantity(5, 'chat-plan')
        ->create($paymentMethod);

もしくは`plan`メソッドで、追加のプランと購入数を動的に指定できます。

    $user = User::find(1);

    $user->newSubscription('default', 'price_monthly')
        ->plan('chat-plan', 5)
        ->create($paymentMethod);

他の方法として、既存のサブスクリプションへ後から、新しいプランを追加できます。

    $user = User::find(1);

    $user->subscription('default')->addPlan('chat-plan');

上記の例では新しいプランが追加され、次の請求サイクルで顧客へ請求されます。すぐに顧客に請求したい場合は、`addPlanAndInvoice`メソッドを使用します。

    $user->subscription('default')->addPlanAndInvoice('chat-plan');

プラン追加と同時に購入数を指定したい場合は、`addPlan`や`addPlanAndInvoice`メソッドの第２引数へ購入数を渡してください。

    $user = User::find(1);

    $user->subscription('default')->addPlan('chat-plan', 5);

サブスクリプションからプランを削除したい場合は、`removePlan`メソッドを使用します。

    $user->subscription('default')->removePlan('chat-plan');

> {note} サブスクリプションの最後のプランは削除できません。その代わりにサブスクリプションをシンプルにキャンセルしてください。

### プラン切り替え

複数のサブスクリプションに紐付いているプランを変更することもできます。たとえば、`chat-plan`アドオンを含む`basic-plan`サブスクリプションを利用していて、`pro-plan`プランにアップグレードしたいとします。

    $user = User::find(1);

    $user->subscription('default')->swap(['pro-plan', 'chat-plan']);

上記のコードを実行すると、`basic-plan`を含む基になるサブスクリプションアイテムが削除され、`chat-plan`を含むものが保持されます。さらに、新しい`pro-plan`のために新しいサブスクリプションアイテムが作成されます。

サブスクリプションアイテムのオプションを指定することもできます。たとえば、プランの購入数を指定する必要が起きる場合もあるでしょう。

    $user = User::find(1);

    $user->subscription('default')->swap([
        'pro-plan' => ['quantity' => 5],
        'chat-plan'
    ]);

サブスクリプション上のプランをひとつだけ切り替える場合は、サブスクリプションアイテム自体に対して`swap`メソッドを使用してください。このアプローチは、たとえばサブスクリプションアイテムの既存のメタデータをすべて保持したい場合に役立ちます。

    $user = User::find(1);

    $user->subscription('default')
            ->findItemOrFail('basic-plan')
            ->swap('pro-plan');

#### 按分課金

Stripeはサブスクリプションのプランを追加または削除する場合、デフォルトで料金を按分課金(日割り計算：prorate)します。按分課金を行わずにプランを調整する場合は、`noProrate`メソッドをプラン操作へチェーンしてください。

    $user->subscription('default')->noProrate()->removePlan('chat-plan');

#### 注文数

個々のサブスクリプションプランの購入数を更新する場合は、[既存の購入数メソッド](＃subscription-quantity)をつかい、メソッドの追加の引数としてプラン名を渡してください。

    $user = User::find(1);

    $user->subscription('default')->incrementQuantity(5, 'chat-plan');

    $user->subscription('default')->decrementQuantity(3, 'chat-plan');

    $user->subscription('default')->updateQuantity(10, 'chat-plan');

> {note} サブスクリプションに複数のプランを設定している場合、`Subscription`モデルの`stripe_plan`および`quantity`属性は`null`になります。個々のプランにアクセスするには、`Subscription`モデルで利用可能な`items`リレーションを使用する必要があります。

#### サブスクリプションアイテム

サブスクリプションに複数のプランがある場合、データベースの`subscription_items`テーブルに複数のサブスクリプション「アイテム」が保存されます。サブスクリプションの`items`リレーションを介してこれらにアクセスできます：

    $user = User::find(1);

    $subscriptionItem = $user->subscription('default')->items->first();

    // Retrieve the Stripe plan and quantity for a specific item...
    $stripePlan = $subscriptionItem->stripe_plan;
    $quantity = $subscriptionItem->quantity;

`findItemOrFail`メソッドを使用し、特定のプランを取得することも可能です。

    $user = User::find(1);

    $subscriptionItem = $user->subscription('default')->findItemOrFail('chat-plan');

<a name="subscription-taxes"></a>
### サブスクリプションの税金

ユーザーがサブスクリプションに対して支払う税率を指定するには、Billableモデルに`taxRates`メソッドを実装し、税率IDを含む配列を返してください。これらの税率は、[Stripeダッシュボード]（https://dashboard.stripe.com/test/tax-rates）で定義できます。

    public function taxRates()
    {
        return ['tax-rate-id'];
    }

`taxRates`メソッドを使用すると、モデルごとに税率を適用できます。これは、複数の国や税率にまたがるユーザー向けサービスで役立つでしょう。マルチプランサブスクリプションを使用している場合は、Billableモデルに`planTaxRates`メソッドを実装することで、プランごとに異なる税率を定義できます。

    public function planTaxRates()
    {
        return [
            'plan-id' => ['tax-rate-id'],
        ];
    }

> {note} `taxRates`メソッドはサブスクリプション料金にのみ適用されます。Cashierを使用して「1回限り」の請求を行う場合は、その時点で税率を手動で指定する必要があります。

#### 税率の同期

`taxRates`メソッドが返すハードコードされた税率IDを変更しても、ユーザーの既存サブスクリプションの税率設定は同じままです。返された`taxTaxRates`値で既存サブスクリプションの税率を更新する場合は、ユーザーのサブスクリプションインスタンスに対し、`syncTaxRates`メソッドを呼び出す必要があります。

    $user->subscription('default')->syncTaxRates();

これはサブスクリプションアイテムの税率も同期するため、`planTaxRates`メソッドも適切に変更してください。

#### 非課税

キャッシャーは、Stripe APIを呼び出して顧客が非課税かを判断するメソッドも提供します。`isNotTaxExempt`および`isTaxExempt`、`reverseChargeApplies`メソッドはBillableモデルで使用できます。

    $user = User::find(1);

    $user->isTaxExempt();
    $user->isNotTaxExempt();
    $user->reverseChargeApplies();

これらのメソッドは、任意の `Laravel\Cashier\Invoice`オブジェクトでも使用できます。ただし、`Invoice`オブジェクトでこれらのメソッドを呼び出すと、メソッドはインボイス作成時の非課税状態であると判断します。

<a name="subscription-anchor-date"></a>
### サブスクリプション課金日付け

デフォルトで課金日はサブスクリプションが生成された日付け、もしくは使用期間を使っている場合は、使用期間の終了日です。課金日付を変更したい場合は、`anchorBillingCycleOn`メソッドを使用します。

    use App\Models\User;
    use Carbon\Carbon;

    $user = User::find(1);

    $anchor = Carbon::parse('first day of next month');

    $user->newSubscription('default', 'price_premium')
                ->anchorBillingCycleOn($anchor->startOfDay())
                ->create($paymentMethod);

サブスクリプションの課金間隔を管理する情報は、[Stripeの課金サイクルのドキュメント](https://stripe.com/docs/billing/subscriptions/billing-cycle)をお読みください。

<a name="cancelling-subscriptions"></a>
### サブスクリプションキャンセル

サブスクリプションをキャンセルするには`cancel`メソッドをユーザーのサブスクリプションに対して使ってください。

    $user->subscription('default')->cancel();

サブスクリプションがキャンセルされるとCashierは自動的に、データベースの`ends_at`カラムをセットします。このカラムはいつから`subscribed`メソッドが`false`を返し始めればよいのか、判定するために使用されています。たとえば、顧客が３月１日にキャンセルしたが、そのサブスクリプションが３月５日に終了するようにスケジュールされていれば、`subscribed`メソッドは３月５日になるまで`true`を返し続けます。

ユーザーがサブスクリプションをキャンセルしたが、まだ「猶予期間」が残っているかどうかを調べるには`onGracePeriod`メソッドを使います。

    if ($user->subscription('default')->onGracePeriod()) {
        //
    }

サブスクリプションを即時キャンセルしたい場合は、ユーザーのサブスクリプションに対し、`cancelNow`メソッドを呼び出してください。

    $user->subscription('default')->cancelNow();

<a name="resuming-subscriptions"></a>
### サブスクリプション再開

ユーザーがキャンセルしたサブスクリプションを、再開したいときには、`resume`メソッドを使用してください。サブスクリプションを再開するには、そのユーザーに有効期間が残っている**必要があります**。

    $user->subscription('default')->resume();

ユーザーがサブスクリプションをキャンセルし、それからそのサブスクリプションを再開する場合、そのサブスクリプションの有効期日が完全に切れていなければすぐに課金されません。そのサブスクリプションはシンプルに再度有効になり、元々の支払いサイクルにより課金されます。

<a name="subscription-trials"></a>
## サブスクリプションのトレイト

<a name="with-payment-method-up-front"></a>
### 支払いの事前登録あり

顧客へ試用期間を提供し、支払情報を事前に登録してもらう場合、サブスクリプションを作成するときに`trialDays`メソッドを使ってください。

    $user = User::find(1);

    $user->newSubscription('default', 'price_monthly')
                ->trialDays(10)
                ->create($paymentMethod);

このメソッドはデータベースのサブスクリプションレコードへ、試用期間の終了日を設定すると同時に、Stripeへこの期日が過ぎるまで、顧客へ課金を始めないように指示します。`trialDays`メソッドを使用する場合、Stripeでそのプランに対して設定したデフォルトの試用期間はオーバーライドされます。

> {note} 顧客のサブスクリプションが試用期間の最後の日までにキャンセルされないと、期限が切れると同時に課金されます。そのため、ユーザーに試用期間の終了日を通知しておくべきでしょう。

`trialUntil`メソッドにより、使用期間の終了時を指定する、`DateTime`インスタンスを渡せます。

    use Carbon\Carbon;

    $user->newSubscription('default', 'price_monthly')
                ->trialUntil(Carbon::now()->addDays(10))
                ->create($paymentMethod);

ユーザーが使用期間中であるかを判定するには、ユーザーインスタンスに対し`onTrial`メソッドを使うか、サブスクリプションインスタンスに対して`onTrial`を使用してください。次の２つの例は、同じ目的を達します。

    if ($user->onTrial('default')) {
        //
    }

    if ($user->subscription('default')->onTrial()) {
        //
    }

#### Stripe／Cashierで使用期間を定義する

Stripeダッシュボードによりプランで受け入れる試用日数を定義するか、Cashierを使用して常に明示的に引数で渡すか選んでください。Stripeでプランの試用日数を定義することを選択する場合、過去にサブスクリプションを購入した顧客の新規サブスクリプションも含め、新規サブスクリプションは明示的に`trialDays(0)`を呼び出さない限り、常に試用期間を受け取ることに注意してください。

<a name="without-payment-method-up-front"></a>
### 支払いの事前登録なし

事前にユーザーの支払い方法の情報を登録してもらうことなく、試用期間を提供する場合は、そのユーザーのレコードの`trial_ends_at`に、試用の最終日を設定するだけです。典型的な使い方は、ユーザー登録時に設定する方法でしょう。

    $user = User::create([
        // 他のユーザープロパティの設定…
        'trial_ends_at' => now()->addDays(10),
    ]);

> {note} モデル定義の`trial_ends_at`に対する、[日付ミューテタ](/docs/{{version}}/eloquent-mutators#date-mutators)を付け加えるのを忘れないでください。

既存のサブスクリプションと関連付けが行われていないので、Cashierでは、このタイプの試用を「包括的な試用(generic trial)」と呼んでいます。`User`インスタンスに対し、`onTrial`メソッドが`true`を返す場合、現在の日付は`trial_ends_at`の値を過ぎていません。

    if ($user->onTrial()) {
        // ユーザーは試用期間中
    }

ユーザーに実際のサブスクリプションを作成する準備ができたら、通常は`newSubscription`メソッドを使います。

    $user = User::find(1);

    $user->newSubscription('default', 'price_monthly')->create($paymentMethod);

ユーザーの試用期間終了日を取得するには、`trialEndsAt`メソッドを使用します。このメソッドはユーザーが試用期間中であればCarbon日付インスタンスを返し、そうでなければ`null`を返します。デフォルト以外の特定のサブスクリプションの試用期間終了日を取得する場合は、オプションのサブスクリプション名パラメーターを渡してください。

    if ($user->onTrial()) {
        $trialEndsAt = $user->trialEndsAt('main');
    }

とくに、ユーザーが「包括的な試用」期間中であり、まだサブスクリプションが作成されていないことを調べたい場合は、`onGenericTrial`メソッドが使用できます。

    if ($user->onGenericTrial()) {
        // ユーザーは「包括的」な試用期間中
    }

<a name="extending-trials"></a>
### 試用期限の延長

一度作成したあとに、サブスクリプションの試用期間を延長したい場合は、`extendTrial`メソッドを使用します。

    // 今から７日後に試用期限を終える
    $subscription->extendTrial(
        now()->addDays(7)
    );

    // 使用期限を５日間延長する
    $subscription->extendTrial(
        $subscription->trial_ends_at->addDays(5)
    );

試用期間が過ぎ、顧客がサブスクリプションをすでに購入している場合でも、追加の試用期限を与えられます。試用期間で費やされた時間は、その顧客の次回のインボイスから差し引かれます。

<a name="handling-stripe-webhooks"></a>
## StripeのWebフック処理

> {tip} ローカル環境でWebhooksのテストするには、[Stripe CLI](https://stripe.com/docs/stripe-cli)が役立つでしょう。

StripeはWebフックにより、アプリケーションへさまざまなイベントを通知できます。デフォルトで、CashierのWebhookを処理するルートのコントローラは、Cashierのサービスプロバイダで設定されています。このコントローラはWebhookの受信リクエストをすべて処理します。

デフォルトでこのコントローラは、課金に多く失敗し続ける（Stripeの設定で定義している回数）、顧客の更新、顧客の削除、サブスクリプションの変更、支払い方法の変更があると、自動的にサブスクリプションをキャンセル処理します。しかしながら、すぐに見つけることができるようにこのコントローラを拡張し、どんなWebhookイベントでもお好きに処理できます

アプリケーションでStripeのWebhookを処理するためには、StripeのコントロールパネルでWebhook URLを確実に設定してください。CashierのWebhookのデフォルトコントローラは、`/stripe/webhook`のURIをリッスンしています。Stripeのコントロールパネルで設定する必要のあるWebhookの全リストは、以下のとおりです。

- `customer.subscription.updated`
- `customer.subscription.deleted`
- `customer.updated`
- `customer.deleted`
- `invoice.payment_action_required`

> {note} Cashierに含まれる、[Webフック署名の確認](/docs/{{version}}/billing#verifying-webhook-signatures)ミドルウェアを使用し、受信リクエストを確実に保護してください。

#### WebフックとCSRF保護

StripeのWebフックでは、Laravelの [CSRFバリデーション](/docs/{{version}}/csrf)をバイパスする必要があるため、`VerifyCsrfToken`ミドルウェアのURIを例外としてリストしておくか、ルート定義を`web`ミドルウェアグループのリストから外しておきましょう。

    protected $except = [
        'stripe/*',
    ];

<a name="defining-webhook-event-handlers"></a>
### Webフックハンドラの定義

Cashierは課金の失敗時に、サブスクリプションを自動的にキャンセル処理しますが、他のWebフックイベントを処理したい場合は、Webフックコントローラを拡張します。メソッド名はCashierが期待する命名規則に沿う必要があります。とくにメソッドは`handle`のプレフィックスで始まり、処理したいStripeのWebフックの名前を「キャメルケース」にします。たとえば、`invoice.payment_succeeded` Webフックを処理する場合は、`handleInvoicePaymentSucceeded`メソッドをコントローラに追加します。

    <?php

    namespace App\Http\Controllers;

    use Laravel\Cashier\Http\Controllers\WebhookController as CashierController;

    class WebhookController extends CashierController
    {
        /**
         * インボイス支払い成功時の処理
         *
         * @param  array  $payload
         * @return \Symfony\Component\HttpFoundation\Response
         */
        public function handleInvoicePaymentSucceeded($payload)
        {
            // イベントの処理…
        }
    }

次に、`routes/web.php`の中で、キャッシャーコントローラへのルートを定義します。これにより、デフォルトのルートが上書きされます。

    use App\Http\Controllers\WebhookController;

    Route::post(
        'stripe/webhook',
        [WebhookController::class, 'handleWebhook']
    );

CashierはWebhookを受け取ると、`Laravel\Cashier\Events\WebhookReceived`イベントを発行します。そして、WebhookがCashierにより処理されると、`Laravel\Cashier\Events\WebhookHandled`イベントを発行します。両方のイベント共にStripeのWebhookの完全なペイロードを持っています。

<a name="handling-failed-subscriptions"></a>
### サブスクリプション不可

顧客のクレジットカードが有効期限切れだったら？　心配いりません。CashierのWebhookコントローラが顧客のサブスクリプションをキャンセルします。失敗した支払いは自動的に捉えられ、コントローラにより処理されます。このコントローラはStripeがサブスクリプションに失敗したと判断した場合、顧客のサブスクリプションを取り消します。（通常、３回の課金失敗）

<a name="verifying-webhook-signatures"></a>
### Webフック署名の確認

Webフックを安全にするため、[StripeのWebフック署名](https://stripe.com/docs/webhooks/signatures)が利用できます。便利に利用できるよう、Cashierは送信されてきたWebフックリクエストが有効なものか確認するミドルウェアをあらかじめ用意しています。

Webhookの確認を有効にするには、`.env`ファイル中の`STRIPE_WEBHOOK_SECRET`環境変数を確実に設定してください。Stripeアカウントのダッシュボードから取得される、Webhookの`secret`を指定します。

<a name="single-charges"></a>
## 一回だけの課金

<a name="simple-charge"></a>
### 課金のみ

> {note} `charge`メソッドには**アプリケーションで使用している通貨の最低単位**で金額を指定します。

サブスクリプションを購入している顧客の支払いメソッドに対して、「一回だけ」の課金を行いたい場合は、Billableモデルインスタンス上の`charge`メソッドを使用します。第２引数に[支払い方法識別子](#storing-payment-methods)を渡してください。

    // Stripeはセント単位で課金する
    $stripeCharge = $user->charge(100, $paymentMethod);

`charge`メソッドは第３引数に配列を受け付け、裏で動いているStripeの課金作成に対するオプションを指定できます。課金作成時に使用できるオプションについては、Stripeのドキュメントを参照してください。

    $user->charge(100, $paymentMethod, [
        'custom_option' => $value,
    ]);

裏で動作する顧客やユーザーがなくても、`charge`メソッドは使用できます。

    use App\Models\User;

    $stripeCharge = (new User)->charge(100, $paymentMethod);

課金に失敗すると、`charge`メソッドは例外を投げます。課金に成功すれば、メソッドは`Laravel\Cashier\Payment`のインスタンスを返します。

    try {
        $payment = $user->charge(100, $paymentMethod);
    } catch (Exception $e) {
        //
    }

<a name="charge-with-invoice"></a>
### インボイス付き課金

一回だけ課金をしつつ、顧客へ発行するPDFのレシートとしてインボイスも生成したいことがあります。`invoiceFor`メソッドは、まさにそのために存在しています。例として、「一回だけ」の料金を５ドル課金してみましょう。

    // Stripeはセント単位で課金する
    $user->invoiceFor('One Time Fee', 500);

金額は即時にユーザーのデフォルト支払い方法へ課金されます。`invoiceFor`メソッドは第３引数に配列を受け付けます。この配列はインボイスアイテムへの支払いオプションを含みます。第４引数も配列で、インボイス自身に対する支払いオプションを指定します。

    $user->invoiceFor('Stickers', 500, [
        'quantity' => 50,
    ], [
        'default_tax_rates' => ['tax-rate-id'],
    ]);

> {note} `invoiceFor`メソッドは、課金失敗時にリトライするStripeインボイスを生成します。リトライをしてほしくない場合は、最初に課金に失敗した時点で、Stripe APIを使用し、生成したインボイスを閉じる必要があります。

<a name="refunding-charges"></a>
### 払い戻し

Stripeでの課金を払い戻す必要がある場合は、`refund`メソッドを使用します。このメソッドの第１引数は、Stripe Payment Intent IDです。

    $payment = $user->charge(100, $paymentMethod);

    $user->refund($payment->id);

<a name="invoices"></a>
## インボイス

<a name="retrieving-invoices"></a>
### インボイス取得

`invoices`メソッドにより、billableモデルのインボイスの配列を簡単に取得できます。

    $invoices = $user->invoices();

    // 結果にペンディング中のインボイスも含める
    $invoices = $user->invoicesIncludingPending();

指定したインボイスを取得する、`findInvoice`メソッドも使用できます。

    $invoice = $user->findInvoice($invoiceId);

#### インボイス情報の表示

顧客へインボイスを一覧表示するとき、そのインボイスに関連する情報を表示するために、インボイスのヘルパメソッドを表示に利用できます。ユーザーが簡単にダウンロードできるよう、テーブルで全インボイスを一覧表示する例を見てください。

    <table>
        @foreach ($invoices as $invoice)
            <tr>
                <td>{{ $invoice->date()->toFormattedDateString() }}</td>
                <td>{{ $invoice->total() }}</td>
                <td><a href="/user/invoice/{{ $invoice->id }}">Download</a></td>
            </tr>
        @endforeach
    </table>

<a name="generating-invoice-pdfs"></a>
### インボイスPDF生成

ルートやコントローラの中で`downloadInvoice`メソッドを使うと、そのインボイスのPDFダウンロードを生成できます。このメソッドはブラウザへダウンロードのHTTPレスポンスを正しく行うHTTPレスポンスを生成します。

    use Illuminate\Http\Request;

    Route::get('user/invoice/{invoice}', function (Request $request, $invoiceId) {
        return $request->user()->downloadInvoice($invoiceId, [
            'vendor' => 'Your Company',
            'product' => 'Your Product',
        ]);
    });

`downloadInvoice`メソッドでは、3番目の引数としてオプションのカスタムファイル名も指定できます。このファイル名は自動的に".pdf"のサフィックスが付けられます。

    return $request->user()->downloadInvoice($invoiceId, [
        'vendor' => 'Your Company',
        'product' => 'Your Product',
    ], 'my-invoice');

<a name="handling-failed-payments"></a>
## 課金失敗の処理

サブスクリプションへの支払い、もしくは一回のみの課金は失敗することがあります。これが発生したことを知らせるため、Cashierは`IncompletePayment`例外を投げます。この例外を補足した後の処理方法は、２つの選択肢があります。

最初の方法は、その顧客をCashierに含まれている支払い確認専門ページへリダイレクトする方法です。このページに紐つけたルートは、Cashierのサービスプロバイダで登録済みです。`IncompletePayment`例外を捉えたら、支払い確認ページへリダイレクトします。

    use Laravel\Cashier\Exceptions\IncompletePayment;

    try {
        $subscription = $user->newSubscription('default', $planId)
                                ->create($paymentMethod);
    } catch (IncompletePayment $exception) {
        return redirect()->route(
            'cashier.payment',
            [$exception->payment->id, 'redirect' => route('home')]
        );
    }

支払い確認ページで顧客はクレジットカード情報の入力を再度促され、「３Dセキュア」のような追加のアクションがStripeにより実行されます。支払いが確認されたら、上記のように`redirect`引数で指定されたURLへユーザーはリダイレクトされます。支払いを確認したら、そのユーザーは上記のように`redirect`パラメータで指定されたURLへリダイレクトされます。リダイレクトにはURLへ`message`（文字列）と`success`（整数）クエリ文字列値が追加されます。

別の方法として、Stripeに支払いの処理を任せることもできます。この場合、支払い確認ページへリダイレクトする代わりに、Stripeダッシュボードで[Stripeの自動支払いメール](https://dashboard.stripe.com/account/billing/automatic)を瀬一定する必要があります。しかしながら、`IncompletePayment`例外を捉えたら、支払い確認方法の詳細がメールで送られることをユーザーへ知らせる必要があります。

不完全な支払いの例外は、`Billable`のユーザーに対する`charge`、`invoiceFor`、`invoice`メソッドで投げられる可能性があります。スクリプションが処理される時、`SubscriptionBuilder`の`create`メソッドと、`Subscription`モデルの`incrementAndInvoice`、`swapAndInvoice`メソッドは、例外を発生させる可能性があります。

`IncompletePayment`を拡張している支払い例外は現在２タイプ存在します。必要に応じユーザーエクスペリエンスをカスタマイズするために、これらを別々に補足できます。

<div class="content-list" markdown="1">
- `PaymentActionRequired`： これはStripeが支払いの確認と処理のために、追加の確認を要求していることを示します。
- `PaymentFailure`： これは利用可能な資金が無いなど、様々な理由で支払いが失敗したことを示します。
</div>

<a name="strong-customer-authentication"></a>
## 堅牢な顧客認証 (SCA)

皆さんのビジネスがヨーロッパを基盤とするものであるなら、堅牢な顧客認証 (SCA)規制を守る必要があります。これらのレギュレーションは支払い詐欺を防ぐためにEUにより２０１９年９月に課せられたものです。幸運なことに、StripeとCashierはSCA準拠のアプリケーション構築のために準備をしてきました。

> {note} 始める前に、[StripeのPSD2とSCAのガイド](https://stripe.com/guides/strong-customer-authentication)と、[新SCA APIのドキュメント](https://stripe.com/docs/strong-customer-authentication)を確認してください。

<a name="payments-requiring-additional-confirmation"></a>
### 支払い要求の追加確認

SCA規制は支払いの確認と処理を行うため、頻繁に追加の検証を要求しています。これが起きるとCashierは`PaymentActionRequired`例外を投げ、この追加の検証が必要であるとあなたに知らせます。この例外をどのように処理するかは、[失敗した支払いの処理方法のセクション](#handling-failed-payments)をお読みください。

#### 不十分と期日超過の状態

支払いが追加の確認を必要とする場合そのサブクリプションは、`stripe_status`データベースカラムにより表される`incomplete`か`past_due`状態になります。Cashierは支払いの確認が完了するとすぐに、Webhookによりその顧客のサブスクリプションを自動的に有効にします。

`incomplete`と`past_due`状態の詳細は、[追加のドキュメント](#incomplete-and-past-due-status)を参照してください。

<a name="off-session-payment-notifications"></a>
### 非セッション確立時の支払い通知

SCA規制は、サブスクリプションが有効なときにも、ときどき支払いの詳細を確認することを顧客に求めています。Cashierではセッションが確立していない時に支払いの確認が要求された場合に、顧客へ支払いの通知を送ることができます。たとえば、サブスクリプションを更新する時にこれが起きます。Cashierの支払い通知は`CASHIER_PAYMENT_NOTIFICATION`環境変数へ通知クラスをセットすることで有効になります。デフォルトでは、この通知は無効です。もちろん、Cashierにはこの目的に使うための通知クラスが含まれていますが、必要であれば自作の通知クラスを自由に指定できます。

    CASHIER_PAYMENT_NOTIFICATION=Laravel\Cashier\Notifications\ConfirmPayment

非セッション時の支払い確認通知が確実に届くよう、[StripeのWebhookが設定されており](#handling-stripe-webhooks)、Stripeのダッシュボードで`invoice.payment_action_required` Webhookが有効になっていることを確認してください。さらに、`Billable`モデルがLaravelの`Illuminate\Notifications\Notifiable`トレイトを使用していることも確認してください。

> {note} 定期課金でなく、顧客が自分で支払った場合でも追加の確認が要求された場合は、その顧客に通知が送られます。残念ながら、Stripeはその支払いが手動や「非セッション時」であることを知る方法がありません。しかし、顧客は支払いを確認した後に支払いページを閲覧したら、「支払いが完了しました」メッセージを確認できます。その顧客は同じ支払いを２度行い、二重に課金されるアクシデントに陥ることを防ぐことができるでしょう。

<a name="stripe-sdk"></a>
## Stripe SDK

CashierのオブジェクトはStripe SDKオブジェクト上にラップされています。Stripe SDKオブジェクトを直接操作したい場合は、`asStripe`メソッドを使い簡単に取得できます。

    $stripeSubscription = $subscription->asStripeSubscription();

    $stripeSubscription->application_fee_percent = 5;

    $stripeSubscription->save();

Stripeのサブスクリプションを直接更新するために、`updateStripeSubscription`も使用できます。

    $subscription->updateStripeSubscription(['application_fee_percent' => 5]);

<a name="testing"></a>
## テスト

Cashierを使用するアプリケーションをテストする場合、Stripe APIに対する実際のHTTPリクエストをモックしたいことがあります。しかしながら、これはCashier自身の動作を部分的に再実装する必要があります。そのためテストでは実際のStripe APIへアクセスすることを勧めます。この方法は低速ですが、アプリケーションが期待どおりに動作していることをより確信できます。そして遅いテストは独自のPHPUnitテストグループに配置できます。

Cashier自身はすでに十分なテストスーツを持っているため、Cashierの裏で実行されているすべての振る舞いをテストする必要がないことを思い出してください。自分のアプリケーションにおけるサブスクリプションと支払いのフローをテストすることだけに集中すべきでしょう。

使用開始する前に、`phpunit.xml`ファイルへ**testing**バージョンのStripeシークレットを追加します。

    <env name="STRIPE_SECRET" value="sk_test_<your-key>"/>

これで、常にテスト中のCashierとのやり取りは、Stripeテスト環境へ実際のAPIリクエストが送信されます。便宜上、Stripeテストアカウントで、テスト中に使用するサブスクリプション/プランを事前に入力しておく必要があります。

> {tip} クレジットカードの拒否や失敗など、さまざまな請求シナリオをテストするために、Stripeが提供しているさまざまな[テストカード番号とトークン](https://stripe.com/docs/testing)を使用できます。
