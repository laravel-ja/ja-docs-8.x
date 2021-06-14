# Laravel Cashier (Stripe)

- [イントロダクション](#introduction)
- [Cashierのアップデート](#upgrading-cashier)
- [インストール](#installation)
    - [データベースマイグレーション](#database-migrations)
- [設定](#configuration)
    - [Billableモデル](#billable-model)
    - [ＡＰＩキー](#api-keys)
    - [通貨設定](#currency-configuration)
    - [ログ](#logging)
    - [カスタムモデルの使用](#using-custom-models)
- [顧客](#customers)
    - [顧客の取得](#retrieving-customers)
    - [顧客の作成](#creating-customers)
    - [顧客の更新](#updating-customers)
    - [タックスID](#tax-ids)
    - [顧客データをStripeと同期する](#syncing-customer-data-with-stripe)
    - [請求ポータル](#billing-portal)
- [Payment Methods](#payment-methods)
    - [支払い方法の保存](#storing-payment-methods)
    - [支払い方法の取得](#retrieving-payment-methods)
    - [顧客に支払い方法があるか判定](#check-for-a-payment-method)
    - [デフォルト支払い方法の変更](#updating-the-default-payment-method)
    - [支払い方法の追加](#adding-payment-methods)
    - [支払い方法の削除](#deleting-payment-methods)
- [Subscriptions](#subscriptions)
    - [サブスクリプションの作成](#creating-subscriptions)
    - [サブスクリプション状態のチェック](#checking-subscription-status)
    - [値段の変更](#changing-prices)
    - [サブスクリプション数](#subscription-quantity)
    - [複数価格のサブスクリプション](#multiprice-subscriptions)
    - [従量制課金](#metered-billing)
    - [サブスクリプションの税率](#subscription-taxes)
    - [サブスクリプション基準日](#subscription-anchor-date)
    - [サブスクリプションの取り消し](#cancelling-subscriptions)
    - [サブスクリプションの再開](#resuming-subscriptions)
- [サブスクリプションの試用期間](#subscription-trials)
    - [支払い方法の事前登録](#with-payment-method-up-front)
    - [支払い方法事前登録なし](#without-payment-method-up-front)
    - [試用期間の延長](#extending-trials)
- [StripeのWebフックの処理](#handling-stripe-webhooks)
    - [Webフックイベントハンドラの定義](#defining-webhook-event-handlers)
    - [Webフック署名の確認](#verifying-webhook-signatures)
- [一回限りの支払い](#single-charges)
      - [シンプルな支払い](#simple-charge)
    - [インボイス付きの支払い](#charge-with-invoice)
    - [支払いの払い戻し](#refunding-charges)
- [支払い](#checkout)
    - [商品の支払い](#product-checkouts)
    - [一回限りの支払い](#single-charge-checkouts)
    - [サブスクリプションの支払い](#subscription-checkouts)
    - [支払いボタンのスタイル](#styling-the-checkout-button)
- [インボイス](#invoices)
    - [インボイスの取得](#retrieving-invoices)
    - [将来のインボイス](#upcoming-invoices)
    - [サブスクリプションインボイスのプレビュー](#previewing-subscription-invoices)
    - [インボイスＰＤＦの生成](#generating-invoice-pdfs)
- [支払い失敗の処理](#handling-failed-payments)
- [強力な顧客認証（ＳＣＡ）](#strong-customer-authentication)
    - [追加の確認が必要な支払い](#payments-requiring-additional-confirmation)
    - [オフセッション支払い通知](#off-session-payment-notifications)
- [Stripe SDK](#stripe-sdk)
- [テスト](#testing)

<a name="introduction"></a>
## イントロダクション

Laravel Cashierは、[Stripe](https://stripe.com)のサブスクリプション課金サービスに対する表現力豊かで流暢なインターフェイスを提供します。それはあなたが書くことを恐れている定型的なサブスクリプション請求コードのほとんどすべてを処理します。キャッシャーは、基本的なサブスクリプション管理に加えて、クーポン、サブスクリプションの交換、サブスクリプションの「数量」、キャンセルの猶予期間を処理し、請求書のPDFを生成することもできます。

<a name="upgrading-cashier"></a>
## Cashierのアップデート

キャッシャーの新しいバージョンにアップグレードするときは、[アップグレードガイド](https://github.com/laravel/cashier-stripe/blob/master/UPGRADE.md)を注意深く確認することが重要です。

> {note} 重大な変更を防ぐために、Cashierは固定のStripe APIバージョンを使用します。Cashier13はStripeAPIバージョン`2020-08-27`を利用しています。StripeAPIバージョンは、新しいStripe機能と改善点を利用するために、マイナーリリースで更新されます。

<a name="installation"></a>
## インストール

まず、Composerパッケージマネージャーを使用して、StripeのCashierパッケージをインストールします。

    composer require laravel/cashier

> {note} CashierにすべてのStripeイベントを適切に処理させるには、[キャッシャーのWebhook処理](#handling-stripe-webhooks)を忘れずに設定してください。

<a name="database-migrations"></a>
### データベースマイグレーション

Cashierのサービスプロバイダは独自のデータベースマイグレーションディレクトリを登録しているため、パッケージのインストール後にデータベースをマイグレーションするのを忘れないでください。Cashierのマイグレーションにより、`users`テーブルへ列がいくつか追加されるだけでなく、顧客のすべてのサブスクリプションを保持する新しい`subscriptions`テーブルが作成されます。

    php artisan migrate

Cashierに同梱されているマイグレーションを上書きする必要がある場合は、`vendor:publish` Artisanコマンドを使用してそれらをリソース公開できます。

    php artisan vendor:publish --tag="cashier-migrations"

Cashierのマイグレーションを完全に実行しないようにする場合は、Cashierが提供する`ignoreMigrations`メソッドを使用してください。通常、このメソッドは、`AppServiceProvider`の`register`メソッドで呼び出す必要があります。

    use Laravel\Cashier\Cashier;

    /**
     * 全アプリケーションサービスの登録
     *
     * @return void
     */
    public function register()
    {
        Cashier::ignoreMigrations();
    }

> {note} Stripeは、Stripe識別子の格納に使用される列では大文字と小文字を区別することを推奨しています。したがって、MySQLを使用する場合は、`stripe_id`列の列照合順序を確実に`utf8_bin`へ設定する必要があります。これに関する詳細は、[Stripeドキュメント](https://stripe.com/docs/upgrades#what-c​​hanges-does-stripe-consider-to-be-backwards-compatible)にあります。

<a name="configuration"></a>
## 設定

<a name="billable-model"></a>
### Billableモデル

Cashierを使用する前に、Billableなモデルの定義へ`Billable`トレイトを追加してください。通常、これは`App\Models\User`モデルになるでしょう。このトレイトはサブスクリプションの作成、クーポンの適用、支払い方法情報の更新など、一般的な請求タスクを実行できるようにするさまざまなメソッドを提供します。

    use Laravel\Cashier\Billable;

    class User extends Authenticatable
    {
        use Billable;
    }

CashierはLaravelに同梱されている`App\Models\User`クラスをBillableなモデルとして想定しています。これを変更したい場合は、`useCustomerModel`メソッドで別のモデルを指定します。このメソッドは通常、`AppServiceProvider`クラスの`boot`メソッドで呼び出します。

    use App\Models\Cashier\User;
    use Laravel\Cashier\Cashier;

    /**
     * アプリケーション全サービスの初期起動処理
     *
     * @return void
     */
    public function boot()
    {
        Cashier::useCustomerModel(User::class);
    }

> {note} Laravelが提供する`App\Models\User`モデル以外のモデルを使用する場合は、代替モデルのテーブル名と一致するように、提供されている[Cashierマイグレーション](#installation)をリソース公開し、変更する必要があります。

<a name="api-keys"></a>
### ＡＰＩキー

次に、アプリケーションの`.env`ファイルでStripeAPIキーを設定する必要があります。StripeAPIキーはStripeコントロールパネルから取得できます。

    STRIPE_KEY=your-stripe-key
    STRIPE_SECRET=your-stripe-secret

<a name="currency-configuration"></a>
### 通貨設定

デフォルトのCashier通貨は米ドル(USD)です。アプリケーションの`.env`ファイル内で`CASHIER_CURRENCY`環境変数を設定することにより、デフォルトの通貨を変更できます。

    CASHIER_CURRENCY=eur

Cashierの通貨の設定に加え、請求書に表示するの金額の値をフォーマットするときに使用するロケールを指定することもできます。内部的には、Cashierは[PHPの`NumberFormatter`クラス](https://www.php.net/manual/en/class.numberformatter.php)を利用して通貨ロケールを設定します。

    CASHIER_CURRENCY_LOCALE=nl_BE

> {note} `en`以外のロケールを使用するには、`ext-intl` PHP拡張機能を確実にサーバにインストールおよび設定してください。

<a name="logging"></a>
### ログ

Cashierを使用すると、Stripe関連のすべての例外をログに記録するときに使用するログチャネルを指定できます。アプリケーションの`.env`ファイル内で`CASHIER_LOGGER`環境変数を定義することにより、ログチャネルを指定できます。

    CASHIER_LOGGER=stack

<a name="using-custom-models"></a>
### カスタムモデルの使用

独自のモデルを定義し対応するCashierモデルを拡張することにより、Cashierが内部で使用するモデルを自由に拡張できます。

    use Laravel\Cashier\Subscription as CashierSubscription;

    class Subscription extends CashierSubscription
    {
        // ...
    }

モデルを定義した後、`Laravel\Cashier\Cashier`クラスを介してカスタムモデルを使用するようにCashierへ指示します。通常、アプリケーションの`App\Providers\AppServiceProvider`クラスの`boot`メソッドで、カスタムモデルをキャッシャーへ通知する必要があります。

    use App\Models\Cashier\Subscription;
    use App\Models\Cashier\SubscriptionItem;

    /**
     * 全アプリケーションサービスの初期起動処理
     *
     * @return void
     */
    public function boot()
    {
        Cashier::useSubscriptionModel(Subscription::class);
        Cashier::useSubscriptionItemModel(SubscriptionItem::class);
    }

<a name="customers"></a>
## 顧客

<a name="retrieving-customers"></a>
### 顧客の取得

`Cashier::findBillable`メソッドを使用して、StripeIDで顧客を取得できます。このメソッドは、Billableなモデルのインスタンスを返します。

    use Laravel\Cashier\Cashier;

    $user = Cashier::findBillable($stripeId);

<a name="creating-customers"></a>
### 顧客の作成

まれに、サブスクリプションを開始せずにStripeの顧客を作成したいことも起きるでしょう。これは、`createAsStripeCustomer`メソッドを使用して実行できます。

    $stripeCustomer = $user->createAsStripeCustomer();

Stripeで顧客を作成しておき、あとからサブスクリプションを開始できます。オプションの`$options`配列を指定して、追加の[StripeAPIでサポートされている顧客作成パラメーター](https://stripe.com/docs/api/customers/create)を渡せます。

    $stripeCustomer = $user->createAsStripeCustomer($options);

BillableなモデルのStripe顧客オブジェクトを返す場合は、`asStripeCustomer`メソッドを使用できます。

    $stripeCustomer = $user->asStripeCustomer();

`createOrGetStripeCustomer`メソッドは、特定のBillableモデルのStripe顧客オブジェクトを取得したいが、BillableモデルがすでにStripe内の顧客であるかわからない場合に使用できます。このメソッドは、Stripeに新しい顧客がまだ存在しない場合、新しい顧客を作成します。

    $stripeCustomer = $user->createOrGetStripeCustomer();

<a name="updating-customers"></a>
### 顧客の更新

たまに、Stripeの顧客を追加情報と一緒に直接更新したい状況が起こるでしょう。これは、`updateStripeCustomer`メソッドを使用して実行できます。このメソッドは、[StripeAPIでサポートされている顧客更新オプション](https://stripe.com/docs/api/customers/update)の配列を引数に取ります。

    $stripeCustomer = $user->updateStripeCustomer($options);

<a name="tax-ids"></a>
### タックスID

Cashierでは、顧客のタックスIDを簡単に管理できます。例えば、`taxIds`メソッドを使って、顧客に割り当てられている全ての[タックスID](https://stripe.com/docs/api/customer_tax_ids/object)をコレクションとして取得できます。

    $taxIds = $user->taxIds();

識別子により、顧客の特定のタックスIDを取得することもできます。

    $taxId = $user->findTaxId('txi_belgium');

有効な[タイプ](https://stripe.com/docs/api/customer_tax_ids/object#tax_id_object-type)と値を`createTaxId`メソッドへ渡し、新しいタックスIDを作成できます。

    $taxId = $user->createTaxId('eu_vat', 'BE0123456789');

`createTaxId`メソッドは、VAT IDを顧客のアカウントへ即座に追加します。[VAT IDの検証はStripeも行います](https://stripe.com/docs/invoicing/customer/tax-ids#validation)が、これは非同期のプロセスです。検証の更新を通知するには、`customer.tax_id.updated` Webフックイベントを購読し、[VAT IDの`verification`パラメータ](https://stripe.com/docs/api/customer_tax_ids/object#tax_id_object-verification)を検査します。Webフックの取り扱いについては、[Webフックの処理の定義に関するドキュメント](#handling-stripe-webhooks)を参照してください。

`deleteTaxId`メソッドを使ってタックスIDを削除できます。

    $user->deleteTaxId('txi_belgium');

<a name="syncing-customer-data-with-stripe"></a>
### 顧客データをStripeと同期する

通常、アプリケーションのユーザーが氏名、メールアドレス、その他のStripeも保存している情報を更新した場合、その更新をStripeへ通知する必要があります。それにより、Stripeの情報とアプリケーションの情報が同期されます。

これを自動化するには、Billableモデルにイベントリスナを定義して、モデルの`updated`イベントに対応させます。そして、イベントリスナの中で、モデルの`syncStripeCustomerDetails`メソッドを呼び出します。

    /**
     * The "booted" method of the model.
     *
     * @return void
     */
    protected static function booted()
    {
        static::updated(queueable(function ($customer) {
            $customer->syncStripeCustomerDetails();
        }));
    }

これで、顧客モデルが更新されるたびに、その情報がStripeと同期されます。便利なように、Cashierは顧客の初回作成時、自動的に顧客の情報をStripeと同期します。

Cashierが提供する様々なメソッドをオーバーライドすることで、顧客情報をStripeに同期する際に使用するカラムをカスタマイズすることができます。例として、`stripeName`メソッドをオーバーライドして、Cashierが顧客情報をStripeに同期する際に、顧客の「名前」とみなす属性をカスタマイズしてみましょう。

    /**
     * ストライプと同期する顧客名の取得
     *
     * @return string|null
     */
    public function stripeName()
    {
        return $this->company_name;
    }

同様に、`stripeEmail`、`stripePhone`、`stripeAddress`メソッドをオーバーライドできます。これらのメソッドは、[Stripe顧客オブジェクトの更新](https://stripe.com/docs/api/customers/update)の際に、対応する顧客パラメータへ情報を同期します。顧客情報の同期プロセスを完全にコントロールしたい場合は、`syncStripeCustomerDetails`メソッドをオーバーライドできます。

<a name="billing-portal"></a>
### 請求ポータル

Stripeは、[請求ポータルを設定する簡単な方法](https://stripe.com/docs/billing/subscriptions/customer-portal)を提供しており、顧客はサブスクリプション、支払い方法を管理し、請求履歴を表示できます。コントローラまたはルートからBillableモデルで`redirectToBillingPortal`メソッドを呼び出すことにより、ユーザーを請求ポータルにリダイレクトできます。

    use Illuminate\Http\Request;

    Route::get('/billing-portal', function (Request $request) {
        return $request->user()->redirectToBillingPortal();
    });

デフォルトでは、ユーザーがサブスクリプションの管理を終了すると、Stripe課金ポータル内のリンクを介してアプリケーションの`home`ルートに戻ることができます。`redirectToBillingPortal`メソッドに引数としてURLを渡すことにより、ユーザーが戻る必要のあるカスタムURLを指定できます。

    use Illuminate\Http\Request;

    Route::get('/billing-portal', function (Request $request) {
        return $request->user()->redirectToBillingPortal(route('billing'));
    });

HTTPリダイレクトレスポンスを生成せずに課金ポータルへのURLを生成したい場合は、`billingPortalUrl`メソッドを呼び出してください。

    $url = $request->user()->billingPortalUrl(route('billing'));

<a name="payment-methods"></a>
## 支払い方法

<a name="storing-payment-methods"></a>
### 支払い方法の保存

Stripeでサブスクリプションを作成したり、「１回限りの」料金を実行したりするには、支払い方法を保存し、Stripeからその識別子を取得する必要があります。これを実現するアプローチは、サブスクリプションに支払い方法を使用するか、単一料金を使用するかにより異なるため、以降で両方とも説明します。

<a name="payment-methods-for-subscriptions"></a>
#### サブスクリプションの支払い方法

サブスクリプションで将来使用するときのため顧客のクレジットカード情報を保存する場合、Stripeの"Setup Intents" APIを使用して、顧客の支払い方法の詳細を安全に収集する必要があります。"Setup Intent "は、顧客の支払い方法により課金する意図をStripeに示します。Cashierの`Billable`トレイトには、新しいセットアップインテントを簡単に作成するための`createSetupIntent`メソッドを用意しています。顧客の支払い方法の詳細を収集するフォームをレンダーするルートまたはコントローラからこのメソッドを呼び出す必要があります。

    return view('update-payment-method', [
        'intent' => $user->createSetupIntent()
    ]);

セットアップインテントを作成してビューに渡したら、支払い方法を収集する要素にそのシークレットを添付する必要があります。たとえば、次の「支払い方法の更新」フォームについて考えてみます。

```html
<input id="card-holder-name" type="text">

<!-- ストライプ要素のプレースホルダ -->
<div id="card-element"></div>

<button id="card-button" data-secret="{{ $intent->client_secret }}">
    Update Payment Method
</button>
```

次に、Stripe.jsライブラリを使用して、[Stripe要素](https://stripe.com/docs/stripe-js)をフォームに添付し、顧客の支払いの詳細を安全に収集します。

```html
<script src="https://js.stripe.com/v3/"></script>

<script>
    const stripe = Stripe('stripe-public-key');

    const elements = stripe.elements();
    const cardElement = elements.create('card');

    cardElement.mount('#card-element');
</script>
```

次に、カードを確認し、[Stripeの`confirmCardSetup`メソッド](https://stripe.com/docs/js/setup_intents/confirm_card_setup)を使用してStripeから安全な「支払い方法識別子」を取得します。

```js
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
        // "error.message"をユーザーに表示…
    } else {
        // カードは正常に検証された…
    }
});
```

カードがStripeによって検証されたあとに、結果の`setupIntent.payment_method`識別子をLaravelアプリケーションに渡して、顧客にアタッチします。支払い方法は、[新しい支払い方法として追加](#adding-payment-methods)または[デフォルトの支払い方法の更新に使用](#updating-the-default-payment-method)のいずれかです。すぐに支払い方法識別子を使用して[新しいサブスクリプションを作成](#creating-subscriptions)することもできます。

> {tip} セットアップインテントと顧客の支払いの詳細の収集について詳しく知りたい場合は、[Stripeが提供しているこの概要を確認してください](https://stripe.com/docs/payments/save-and-reuse#php)。

<a name="payment-methods-for-single-charges"></a>
#### 一回限りの支払いの支払い方法

もちろん、お客様の支払い方法に対して１回請求を行う場合、支払い方法IDを使用する必要があるのは１回だけです。Stripeの制約により、顧客が保存したデフォルトの支払い方法を単一の請求に使用することはできません。Stripe.jsライブラリを使用して、顧客が支払い方法の詳細を入力できるようにする必要があります。たとえば、次のフォームについて考えてみます。

```html
<input id="card-holder-name" type="text">

<!-- ストライプ要素プレースホルダ -->
<div id="card-element"></div>

<button id="card-button">
    Process Payment
</button>
```

このようなフォームを定義した後、Stripe.jsライブラリを使用して[Stripe要素](https://stripe.com/docs/stripe-js)をフォームに添付し、顧客の支払いの詳細を安全に収集します。

```html
<script src="https://js.stripe.com/v3/"></script>

<script>
    const stripe = Stripe('stripe-public-key');

    const elements = stripe.elements();
    const cardElement = elements.create('card');

    cardElement.mount('#card-element');
</script>
```

次にカードを確認し、[Stripeの`createPaymentMethod`メソッド](https://stripe.com/docs/stripe-js/reference#stripe-create-payment-method)を使用してStripeから安全な「支払い方法識別子」を取得します。

```js
const cardHolderName = document.getElementById('card-holder-name');
const cardButton = document.getElementById('card-button');

cardButton.addEventListener('click', async (e) => {
    const { paymentMethod, error } = await stripe.createPaymentMethod(
        'card', cardElement, {
            billing_details: { name: cardHolderName.value }
        }
    );

    if (error) {
        // "error.message"をユーザーに表示…
    } else {
        // カードは正常に検証された…
    }
});
```

カードが正常に確認されたら、`paymentMethod.id`をLaravelアプリケーションに渡して、[一回限りの請求](#simple-charge)を処理できます。

<a name="retrieving-payment-methods"></a>
### 支払い方法の取得

Billableなモデルインスタンスの`paymentMethods`メソッドは、`Laravel\Cashier\PaymentMethod`インスタンスのコレクションを返します。

    $paymentMethods = $user->paymentMethods();

このメソッドはデフォルトで、`card`タイプの支払い方法を返します。別のタイプの支払い方法を取得するには、メソッドの引数に`type`を渡します。

    $paymentMethods = $user->paymentMethods('sepa_debit');

顧客のデフォルトの支払い方法を取得するには、`defaultPaymentMethod`メソッドを使用します。

    $paymentMethod = $user->defaultPaymentMethod();

`findPaymentMethod`メソッドを使用して、Billableモデルに関連付けている特定の支払い方法を取得できます。

    $paymentMethod = $user->findPaymentMethod($paymentMethodId);

<a name="check-for-a-payment-method"></a>
### 顧客に支払い方法があるか判定

Billableなモデルのアカウントにデフォルトの支払い方法が関連付けられているかどうかを確認するには、`hasDefaultPaymentMethod`メソッドを呼び出します。

    if ($user->hasDefaultPaymentMethod()) {
        //
    }

`hasPaymentMethod`メソッドを使用して、Billableなモデルのアカウントに少なくとも1つの支払い方法が関連付けられているかを判定できます。

    if ($user->hasPaymentMethod()) {
        //
    }

このメソッドは、Billableモデルが`card`タイプの支払い方法を持っているかどうかを判断します。そのモデルに別のタイプの支払い方法が存在するかを判断するには、メソッドの引数に`type`を渡してください。

    if ($user->hasPaymentMethod('sepa_debit')) {
        //
    }

<a name="updating-the-default-payment-method"></a>
### デフォルト支払い方法の変更

`updateDefaultPaymentMethod`メソッドは、顧客のデフォルトの支払い方法情報を更新するために使用します。このメソッドは、Stripe支払い方法識別子を受け入れ、新しい支払い方法をデフォルトの請求支払い方法として割り当てます。

    $user->updateDefaultPaymentMethod($paymentMethod);

デフォルトの支払い方法情報をStripeの顧客のデフォルトの支払い方法情報と同期するには、`updateDefaultPaymentMethodFromStripe`メソッドを使用できます。

    $user->updateDefaultPaymentMethodFromStripe();

> {note} 顧客のデフォルトの支払い方法は、新しいサブスクリプションの請求と作成にのみ使用できます。Stripeの制約により、１回だけの請求には使用できません。

<a name="adding-payment-methods"></a>
### 支払い方法の追加

新しい支払い方法を追加するには、支払い方法IDを渡して、Billableモデルで`addPaymentMethod`メソッドを呼び出してください。

    $user->addPaymentMethod($paymentMethod);

> {tip} 支払い方法の識別子を取得する方法については、[支払い方法の保存に関するドキュメント](#storing-payment-methods)を確認してください。

<a name="deleting-payment-methods"></a>
### 支払い方法の削除

支払い方法を削除するには、削除したい`Laravel\Cashier\PaymentMethod`インスタンスで`delete`メソッドを呼び出してください。

    $paymentMethod->delete();

`deletePaymentMethods`メソッドは、Billableなモデルのすべての支払い方法情報を削除します。

    $user->deletePaymentMethods();

このメソッドはデフォルトで、`card`タイプの支払い方法を削除します。別のタイプの支払い方法を削除するには、メソッドの引数に`type`を渡します。

    $user->deletePaymentMethods('sepa_debit');

> {note} ユーザーがアクティブなサブスクリプションを持っている場合、アプリケーションはユーザーがデフォルトの支払い方法を削除することを許してはいけません。

<a name="subscriptions"></a>
## サブスクリプション

サブスクリプションは、顧客に定期的な支払いを設定する方法を提供します。Cashierが管理するStripeサブスクリプションは、複数価格のサブスクリプション、サブスクリプション数量、トライアルなどをサポートします。

<a name="creating-subscriptions"></a>
### サブスクリプションの作成

サブスクリプションを作成するには、最初にBillableなモデルのインスタンスを取得します。これは通常、`App\Models\User`のインスタンスになります。モデルインスタンスを取得したら、`newSubscription`メソッドを使用してモデルのサブスクリプションを作成できます。

    use Illuminate\Http\Request;

    Route::post('/user/subscribe', function (Request $request) {
        $request->user()->newSubscription(
            'default', 'price_monthly'
        )->create($request->paymentMethodId);

        // ...
    });

`newSubscription`メソッドに渡す最初の引数は、サブスクリプションの名前です。アプリケーションが単一のサブスクリプションのみを提供する場合は、これを`default`または`primary`と付けるのが良いでしょう。２番目の引数は、ユーザーがサブスクライブする価格の指定です。この値は、Stripeの価格識別子に対応している必要があります。

[Stripe支払い方法識別子](#storing-payment-methods)またはStripe`PaymentMethod`オブジェクトを引数に取る`create`メソッドは、サブスクリプションを開始するのと同時に、BillableなモデルのStripe顧客IDおよびその他の関連する課金情報でデータベースを更新します。

> {note} 支払い方法識別子を`create`サブスクリプションメソッドへ直接渡すと、ユーザーの保存済み支払い方法にも自動的に追加されます。

<a name="subscription-quantities"></a>
#### サブスクリプション数

サブスクリプションの作成時にの価格に[数量](https://stripe.com/docs/billing/subscriptions/quantities)を指定する場合は、サブスクリプションを作成する前にビルダで`quantity`メソッドを呼び出してください。

    $user->newSubscription('default', 'price_monthly')
         ->quantity(5)
         ->create($paymentMethod);

<a name="additional-details"></a>
#### 詳細の追加

Stripeがサポートしている[顧客](https://stripe.com/docs/api/customers/create)や[サブスクリプション](https://stripe.com/docs/api/subscriptions/create)オプションを指定する場合、`create`メソッドの２番目と３番目の引数に指定することで、追加できます。

    $user->newSubscription('default', 'price_monthly')->create($paymentMethod, [
        'email' => $email,
    ], [
        'metadata' => ['note' => 'Some extra information.'],
    ]);

<a name="coupons"></a>
#### クーポン

サブスクリプションの作成時にクーポンを適用する場合は、`withCoupon`メソッドを使用できます。

    $user->newSubscription('default', 'price_monthly')
         ->withCoupon('code')
         ->create($paymentMethod);

または、[Stripeプロモーションコード](https://stripe.com/docs/billing/subscriptions/discounts/codes)を適用する場合は、`withPromotionCode`メソッドを使用します。

    $user->newSubscription('default', 'price_monthly')
         ->withPromotionCode('promo_code')
         ->create($paymentMethod);

<a name="adding-subscriptions"></a>
#### サブスクリプションの追加

すでにデフォルトの支払い方法を持っている顧客へサブスクリプションを追加する場合は、サブスクリプションビルダで`add`メソッドを呼び出してください。

    use App\Models\User;

    $user = User::find(1);

    $user->newSubscription('default', 'price_monthly')->add();

<a name="creating-subscriptions-from-the-stripe-dashboard"></a>
#### Stripeダッシュボードからのサブスクリプション作成

Stripeダッシュボード自体からも、サブスクリプションを作成できます。その際、Cashierは新しく追加したサブスクリプションを同期し、それらに`default`の名前を割り当てます。ダッシュボードから作成するサブスクリプションに割り当てるサブスクリプション名をカスタマイズするには、[`WebhookController`を拡張](/docs/{{version}}/billing#defining-webhook-event-handlers)し、`newSubscriptionName`メソッドを上書きします。

また、Stripeダッシュボードから作成できるサブスクリプションのタイプは１つだけです。アプリケーションが異なる名前を使用する複数のサブスクリプションを提供している場合でも、Stripeダッシュボードから追加できるサブスクリプションのタイプは１つのみです。

最後に、アプリケーションが提供するサブスクリプションのタイプごとに、アクティブなサブスクリプションを１つだけ追加するようにしてください。顧客が２つの`default`サブスクリプションを持っている場合、たとえ両方がアプリケーションのデータベースと同期されていても、最後に追加したサブスクリプションのみ、Cashierは使用します。

<a name="checking-subscription-status"></a>
### サブスクリプション状態のチェック

顧客がアプリケーションでサブスクリプションを購入すると、さまざまな便利なメソッドを使用して、サブスクリプションの状態を簡単に確認できます。まず、`subscribed`メソッドは、そのサブスクリプションが現在試用期間内であっても、顧客がアクティブなサブスクリプションを持っている場合は、`true`を返します。`subscribed`メソッドは、最初の引数としてサブスクリプションの名前を受け入れます。

    if ($user->subscribed('default')) {
        //
    }

`subscribed`メソッドは[ルートミドルウェア](/docs/{{version}}/middleware)の優れた候補にもなり、ユーザーのサブスクリプション状態に基づいてルートとコントローラへのアクセスをフィルタリングできます。

    <?php

    namespace App\Http\Middleware;

    use Closure;

    class EnsureUserIsSubscribed
    {
        /**
         * 受信リクエストの処理
         *
         * @param  \Illuminate\Http\Request  $request
         * @param  \Closure  $next
         * @return mixed
         */
        public function handle($request, Closure $next)
        {
            if ($request->user() && ! $request->user()->subscribed('default')) {
                // このユーザーは、支払い済みユーザーではない
                return redirect('billing');
            }

            return $next($request);
        }
    }

ユーザーがまだ試用期間内であるかどうかを確認したい場合は、`onTrial`メソッドを使用します。このメソッドは、ユーザーがまだ試用期間中であるという警告をユーザーに表示する必要があるかどうかを判断するのに役立ちます。

    if ($user->subscription('default')->onTrial()) {
        //
    }

`subscribedToProduct`メソッドは、ユーザーが指定のStripe製品識別子に基づき、指定の製品を購読しているかどうかを判断するために使用します。Stripeでの商品とは、価格のコレクションです。この例では、ユーザーの`default`サブスクリプションが、アプリケーションの「プレミアム」製品をアクティブに購読しているかを判定してみます。指定するStripe製品識別子は、Stripeダッシュボード内の製品識別子のいずれかに対応する必要があります。

    if ($user->subscribedToProduct('prod_premium', 'default')) {
        //
    }

`subscribedToProduct`メソッドへ配列を渡し、ユーザーの`default`サブスクリプションがアプリケーションの"basic"か"premium"製品をアクティブに購読しているかを判断してみます。

    if ($user->subscribedToProduct(['prod_basic', 'prod_premium'], 'default')) {
        //
    }

`subscribedToPrice`メソッドは、顧客のサブスクリプションが指定する価格IDに対応しているかを判断するために使用します。

    if ($user->subscribedToPrice('price_basic_monthly', 'default')) {
        //
    }

`recurring`メソッドを使用して、ユーザーが現在サブスクリプションを購入してお​​り、試用期間でないことを判定します。

    if ($user->subscription('default')->recurring()) {
        //
    }

> {note} ユーザーが同じ名前のサブスクリプションを２つ持っている場合、`subscription`メソッドは最新のサブスクリプションを常に返します。たとえば、ユーザーが`default`という名前のサブスクリプションレコードを２つ持っているとします。この場合、サブスクリプションの１つは古い期限切れのサブスクリプションであり、もう１つは現在のアクティブなサブスクリプションである可能性があります。最新のサブスクリプションを常に返しますが、古いサブスクリプションは履歴レビューのためにデータベースに保持されます。

<a name="cancelled-subscription-status"></a>
#### キャンセル済みサブスクリプション状態

ユーザーがかつてアクティブなサブスクリプション購入者であったが、そのサブスクリプションをキャンセルしたかを判定するには、`cancelled`メソッドを使用します。

    if ($user->subscription('default')->cancelled()) {
        //
    }

また、ユーザーがサブスクリプションをキャンセルしたが、サブスクリプションが完全に期限切れになるまで「猶予期間」にあるかを判定することもできます。たとえば、ユーザーが３月１０日に期限切れになる予定のサブスクリプションを３月５日にキャンセルした場合、ユーザーは３月１０日まで「猶予期間」になります。この間、`subscribed`メソッドは引き続き`true`を返すことに注意してください。

    if ($user->subscription('default')->onGracePeriod()) {
        //
    }

ユーザーがサブスクリプションをキャンセルし、「猶予期間」も過ぎていることを判断するには、`ended`メソッドを使用します。

    if ($user->subscription('default')->ended()) {
        //
    }

<a name="incomplete-and-past-due-status"></a>
#### 不完全および延滞ステータス

サブスクリプションの作成後に二次支払いアクションが必要な場合、サブスクリプションは「未完了（`incomplete`）」としてマークされます。サブスクリプションステータスは、Cashierの`subscriptions`データベーステーブルの`stripe_status`列に保存されます。

同様に、価格を変更するときに二次支払いアクションが必要な場合、サブスクリプションは「延滞（`past_due`）」としてマークされます。サブスクリプションがこれらの状態のどちらかにある場合、顧客が支払いを確認するまでサブスクリプションはアクティブになりません。サブスクリプションの支払いが不完全であるかの判定は、Billableモデルまたはサブスクリプションインスタンスで`hasIncompletePayment`メソッドを使用します。

    if ($user->hasIncompletePayment('default')) {
        //
    }

    if ($user->subscription('default')->hasIncompletePayment()) {
        //
    }

サブスクリプションの支払いが不完全な場合は、`latestPayment`識別子を渡して、ユーザーをCashierの支払い確認ページに誘導する必要があります。サブスクリプションインスタンスで使用可能な`latestPayment`メソッドを使用して、この識別子を取得できます。

```html
<a href="{{ route('cashier.payment', $subscription->latestPayment()->id) }}">
    Please confirm your payment.
</a>
```

サブスクリプションが`past_due`状態のときにアクティブであると見なしたい場合は、Cashierが提供する`keepPastDueSubscriptionsActive`メソッドを使用します。通常、このメソッドは、`App\Providers\AppServiceProvider`の`register`メソッドで呼び出す必要があります。

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

> {note} サブスクリプションが`incomplete`状態の場合、支払いが確認されるまで変更できません。したがって、サブスクリプションが`incomplete`状態の場合、`swap`メソッドと`updateQuantity`メソッドは例外を投げます。

<a name="subscription-scopes"></a>
#### サブスクリプションのスコープ

ほとんどのサブスクリプション状態はクエリスコープとしても利用できるため、特定の状態にあるサブスクリプションはデータベースで簡単にクエリできます。

    // すべてのアクティブなサブスクリプションを取得
    $subscriptions = Subscription::query()->active()->get();

    // ユーザーのキャンセルしたサブスクリプションをすべて取得
    $subscriptions = $user->subscriptions()->cancelled()->get();

使用可能なスコープの完全なリストは、以下のとおりです。

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

<a name="changing-prices"></a>
### 値段の変更

顧客がアプリケーションでサブスクリプションを購読した後に、新しいサブスクリプション価格に変更したいと思うことがあるでしょう。顧客のサブスクリプションを新しい価格に変更するには、Stripe価格の識別子を`swap`メソッドに渡します。指定する価格識別子は、Stripeダッシュボードの利用可能な Stripe価格の識別子に対応する必要があります。

    use App\Models\User;

    $user = App\Models\User::find(1);

    $user->subscription('default')->swap('price_yearly');

その顧客が試用中の場合、試用期間は維持されます。さらに、サブスクリプションに「数量」が存在する場合、その数量も維持されます。

価格を交換して、顧客が現在行っている試用期間をキャンセルしたい場合は、`skipTrial`メソッドを呼び出してください。

    $user->subscription('default')
            ->skipTrial()
            ->swap('price_yearly');

価格を交換して、次の請求サイクルを待たずにすぐに顧客に請求する場合は、`swapAndInvoice`メソッドを使用します。

    $user = User::find(1);

    $user->subscription('default')->swapAndInvoice('price_yearly');

<a name="prorations"></a>
#### 按分

デフォルトで、Stripeは価格を変更するときに料金を按分します。`noProrate`メソッドを使用すると、料金を按分せずにサブスクリプションの価格を更新できます。

    $user->subscription('default')->noProrate()->swap('price_yearly');

サブスクリプションの按分について詳しくは、[Stripeドキュメント](https://stripe.com/docs/billing/subscriptions/prorations)を参照してください。

> {note} `swapAndInvoice`メソッドの前に`noProrate`メソッドを実行しても、按分には影響しません。請求書は常に発行されます。

<a name="subscription-quantity"></a>
### サブスクリプション数

サブスクリプションは「数量」の影響を受ける場合があります。たとえば、プロジェクト管理アプリケーションは、プロジェクトごとに月額$10を請求する場合があります。`incrementQuantity`メソッドと`decrementQuantity`メソッドを使用して、サブスクリプション数量を簡単に増減できます。

    use App\Models\User;

    $user = User::find(1);

    $user->subscription('default')->incrementQuantity();

    // サブスクリプションの現在の数量へ５個追加
    $user->subscription('default')->incrementQuantity(5);

    $user->subscription('default')->decrementQuantity();

    // サブスクリプションの現在の数量から５個減少
    $user->subscription('default')->decrementQuantity(5);

または、`updateQuantity`メソッドを使用して特定の数量を設定することもできます。

    $user->subscription('default')->updateQuantity(10);

`noProrate`メソッドを使用すると、料金を按分せずにサブスクリプションの数量を更新できます。

    $user->subscription('default')->noProrate()->updateQuantity(10);

サブスクリプション数量の詳細については、[Stripeドキュメント](https://stripe.com/docs/subscriptions/quantities)を参照してください。

<a name="multiprice-subscription-quantities"></a>
#### 複数価格でのサブスクリプション数

サブスクリプションが[複数価格のサブスクリプション](#multiprice-subscriptions)の場合は、増量または減量したい価格の名前をincrement／decrementメソッドの第２引数に渡す必要があります。

    $user->subscription('default')->incrementQuantity(1, 'price_chat');

<a name="multiprice-subscriptions"></a>
### 複数価格のサブスクリプション

[複数価格のサブスクリプション](https://stripe.com/docs/billing/subscriptions/multiple-products)では、1つのサブスクリプションに複数の請求価格を割り当て可能です。例えば、カスタマーサービスの「ヘルプデスク」アプリケーションを構築しているとします。このアプリケーションの基本サブスクリプション価格は月額１０ドルですが、ライブチャットのアドオン価格は月額１５ドルに設定しましょう。複数価格のサブスクリプションの情報は、Cashierの`subscription_items`データベーステーブルに格納されます。

`newSubscription`メソッドの第２引数に価格の配列を渡すことで、指定したサブスクリプションに複数の価格を指定できます。

    use Illuminate\Http\Request;

    Route::post('/user/subscribe', function (Request $request) {
        $request->user()->newSubscription('default', [
            'price_monthly',
            'price_chat',
        ])->create($request->paymentMethodId);

        // ...
    });

上記の例では、顧客の`default`サブスクリプションに２つの価格を設定しています。どちらの価格も、それぞれの請求間隔で請求されます。必要に応じて、`quantity`メソッドを使用して、各価格に特定の数量を指定できます。

    $user = User::find(1);

    $user->newSubscription('default', ['price_monthly', 'price_chat'])
        ->quantity(5, 'price_chat')
        ->create($paymentMethod);

既存のサブスクリプションに別の価格を追加したい場合は、サブスクリプションの`addPrice`メソッドを呼び出します。

    $user = User::find(1);

    $user->subscription('default')->addPrice('price_chat');

上記の例では、新しい価格が追加され、次の請求サイクルで顧客へ請求します。すぐに顧客へ請求したい場合は、`addPriceAndInvoice`メソッドを使います。

    $user->subscription('default')->addPriceAndInvoice('price_chat');

数量を指定して価格を追加したい場合には、`addPrice`または`addPriceAndInvoice`メソッドの第２引数に数量を渡します。

    $user = User::find(1);

    $user->subscription('default')->addPrice('price_chat', 5);

サブスクリプションから価格を削除するには、`removePrice`メソッドを使用します。

    $user->subscription('default')->removePrice('price_chat');

> {note} サブスクリプションの最後の価格は削除できません。代わりに、単にサブスクリプションをキャンセルしてください。

<a name="swapping-prices"></a>
#### 価格の交換

複数価格のサブスクリプションに設定した価格を変更することもできます。例えば、ある顧客が`price_basic`のサブスクリプションに`price_chat`のアドオン価格を設定していて、その顧客を`price_basic`から`price_pro`にアップグレードしたいとします。

    use App\Models\User;

    $user = User::find(1);

    $user->subscription('default')->swap(['price_pro', 'price_chat']);

上記の例を実行すると、`price_basic`のサブスクリプションアイテムが削除され、`price_chat`のサブスクリプションアイテムが保存されます。さらに、`price_pro`のサブスクリプションアイテムが新たに作成されます。

また、キーと値のペアの配列を`swap`メソッドに渡すことで、サブスクリプションアイテムのオプションを指定することもできます。たとえば、サブスクリプション価格の数量を指定する必要があるかもしれません。

    $user = User::find(1);

    $user->subscription('default')->swap([
        'price_pro' => ['quantity' => 5],
        'price_chat'
    ]);

サブスクリプションの価格を１つだけ交換したい場合は、サブスクリプションアイテム自体の`swap`メソッドを使って交換できます。この方法は、サブスクリプションの他の価格に関する既存のメタデータをすべて保持したい場合に特に有効です。

    $user = User::find(1);

    $user->subscription('default')
            ->findItemOrFail('price_basic')
            ->swap('price_pro');

<a name="proration"></a>
#### 按分

デフォルトで、Stripeは複数価格サブスクリプションに価格を追加または削除するとき、料金を按分します。按分せずに調整したい場合は、`noProrate`メソッドを価格の操作へチェーンする必要があります。

    $user->subscription('default')->noProrate()->removePrice('price_chat');

<a name="swapping-quantities"></a>
#### 個数

個々のサブスクリプション価格の個数を変更する場合は、[既存の個数メソッド](#subscription-quantity)を使用して、価格の名前をメソッドの追加引数として渡すことで更新できます。

    $user = User::find(1);

    $user->subscription('default')->incrementQuantity(5, 'price_chat');

    $user->subscription('default')->decrementQuantity(3, 'price_chat');

    $user->subscription('default')->updateQuantity(10, 'price_chat');

> {note} サブスクリプションに複数の価格がある場合、`Subscription`モデルの`stripe_plan`属性と`quantity`属性は`null`になります。個々の価格属性にアクセスするには、`Subscription`モデルで使用可能な`items`リレーションを使用する必要があります。

<a name="subscription-items"></a>
#### サブスクリプションアイテム

サブスクリプションに複数の価格がある場合、データベースの`subscription_items`テーブルに複数のサブスクリプション「アイテム」が保存されます。サブスクリプションの`items`リレーションを介してこれらにアクセスできます。

    use App\Models\User;

    $user = User::find(1);

    $subscriptionItem = $user->subscription('default')->items->first();

    // 特定のアイテムのStripe価格と個数を取得
    $stripePrice = $subscriptionItem->stripe_price;
    $quantity = $subscriptionItem->quantity;

`findItemOrFail`メソッドを使用して特定の価格を取得できます。

    $user = User::find(1);

    $subscriptionItem = $user->subscription('default')->findItemOrFail('price_chat');

<a name="metered-billing"></a>
### 従量制課金

[従量制課金](https://stripe.com/docs/billing/subscriptions/metered-billing)を使用すると、課金サイクル中の製品の使用状況に基づき顧客へ請求できます。たとえば、顧客が１か月に送信するテキストメッセージまたは電子メールの数に基づいて顧客に請求するケースが考えられます。

従量制課金を使用開始するには、最初に、Stripeダッシュボードの従量制価格（metered price）で新しい製品を作成する必要があります。次に、`meteredPrice`を使用して、従量制の価格IDを顧客のサブスクリプションに追加します。

    use Illuminate\Http\Request;

    Route::post('/user/subscribe', function (Request $request) {
        $request->user()->newSubscription('default')
            ->meteredPrice('price_metered')
            ->create($request->paymentMethodId);

        // ...
    });

[Stripeの支払い](#checkout)から従量制サブスクリプションを開始することもできます。

    $checkout = Auth::user()
            ->newSubscription('default', [])
            ->meteredPrice('price_metered')
            ->checkout();

    return view('your-checkout-view', [
        'checkout' => $checkout,
    ]);

<a name="reporting-usage"></a>
#### 資料状況の報告

顧客がアプリケーションを使用しているとき、正確な請求ができるように、使用状況をStripeへ報告します。従量制サブスクリプションの使用量を増やすには、`reportUsage`メソッドを使用します。

    $user = User::find(1);

    $user->subscription('default')->reportUsage();

デフォルトでは、「使用量」１が請求期間に追加されます。または、指定の「使用量」を渡して、請求期間中の顧客の使用量に追加することもできます。

    $user = User::find(1);

    $user->subscription('default')->reportUsage(15);

アプリケーションが単一のサブスクリプションで複数の価格を提供している場合は、`reportUsageFor`メソッドを使用して、使用状況を報告する従量制価格を指定する必要があります。

    $user = User::find(1);

    $user->subscription('default')->reportUsageFor('price_metered', 15);

以前に報告した使用状況を更新する必要も起こるでしょう。これにはタイムスタンプまたは`DateTimeInterface`インスタンスを２番目のパラメータとして`reportUsage`に渡します。その際、Stripeはその時点で報告された使用状況を更新します。指定する日時は現在の請求期間内であるため、以前の使用記録を引き続き更新できます。

    $user = User::find(1);

    $user->subscription('default')->reportUsage(5, $timestamp);

<a name="retrieving-usage-records"></a>
#### 使用記録の取得

顧客の過去の使用状況を取得するには、サブスクリプションインスタンスの`usageRecords`メソッドを使用します。

    $user = User::find(1);

    $usageRecords = $user->subscription('default')->usageRecords();

アプリケーションが１つのサブスクリプションで複数の価格を提供している場合は、`usageRecordsFor`メソッドを使用して、使用記録を取得する従量制価格を指定します。

    $user = User::find(1);

    $usageRecords = $user->subscription('default')->usageRecordsFor('price_metered');

`usageRecords`メソッドと`usageRecordsFor`メソッドは、使用レコードの連想配列を含むCollectionインスタンスを返します。この配列を繰り返し処理して、顧客の合計使用量を表示できます。

    @foreach ($usageRecords as $usageRecord)
        - Period Starting: {{ $usageRecord['period']['start'] }}
        - Period Ending: {{ $usageRecord['period']['end'] }}
        - Total Usage: {{ $usageRecord['total_usage'] }}
    @endforeach

返されるすべての使用状況データの完全なリファレンスと、Stripeのカーソルベースのペジネーションの使用方法については、[Stripe公式のAPIドキュメント](https://stripe.com/docs/api/usage_records/subscription_item_summary_list)を参照してください。

<a name="subscription-taxes"></a>
### サブスクリプションの税率

ユーザーがサブスクリプションで支払う税率を指定するには、Billableなモデルに`taxRates`メソッドを実装し、Stripe税率IDを含む配列を返す必要があります。これらの税率は、[Stripeダッシュボード](https://dashboard.stripe.com/test/tax-rates)で定義します。

    /**
     * 顧客のサブスクリプションに適用する税率
     *
     * @return array
     */
    public function taxRates()
    {
        return ['txr_id'];
    }

`taxRates`メソッドを使用すると、顧客ごとに税率を適用できます。これは、ユーザーベースが複数の国と税率にまたがる場合に役立つでしょう。

複数価格サブスクリプションを提供している場合は、Billableなモデルに`priceTaxRates`メソッドを実装することで、プランごとに異なる税率を定義できます。

    /**
     * 顧客のサブスクリプションに適用する税率
     *
     * @return array
     */
    public function priceTaxRates()
    {
        return [
            'price_monthly' => ['txr_id'],
        ];
    }

> {note} `taxRates`メソッドはサブスクリプション料金にのみ適用されます。Cashierを使用して「１回限り」の料金を請求する場合は、その時点で税率を手動で指定する必要があります。

<a name="syncing-tax-rates"></a>
#### 税率の同期

`taxRates`メソッドから返すハードコードした税率IDを変更する場合、ユーザーの既存サブスクリプションの設定税率は同じままです。既存のサブスクリプションの税額を新しい`taxRates`値で更新する場合は、ユーザーのサブスクリプションインスタンスで`syncTaxRates`メソッドを呼び出す必要があります。

    $user->subscription('default')->syncTaxRates();

これにより、複数価格のサブスクリプションアイテムの税率も同期されます。複数価格のサブスクリプションを提供している場合は、Billableモデルが[前述](#subscription-taxes)の`priceTaxRates`メソッドを実装していることを確認する必要があります。

<a name="tax-exemption"></a>
#### 非課税

Cashierは、顧客が非課税であるかどうかを判断するために、`isNotTaxExempt`、`isTaxExempt`、`reverseChargeApplies`メソッドも提供しています。これらのメソッドは、StripeAPIを呼び出して、顧客の免税ステータスを判定します。

    use App\Models\User;

    $user = User::find(1);

    $user->isTaxExempt();
    $user->isNotTaxExempt();
    $user->reverseChargeApplies();

> {note} これらのメソッドは、すべての`Laravel\Cashier\Invoice`オブジェクトでも使用できます。ただし、`Invoice`オブジェクトで呼び出されると、メソッドは請求書が作成されたときの免除ステータスを用います。

<a name="subscription-anchor-date"></a>
### サブスクリプション基準日

デフォルトの請求サイクル基準日は、サブスクリプションが作成された日付、または試用期間が使用されている場合は試用が終了した日付です。請求基準日を変更する場合は、`anchorBillingCycleOn`メソッドを使用します。

    use Illuminate\Http\Request;

    Route::post('/user/subscribe', function (Request $request) {
        $anchor = Carbon::parse('first day of next month');

        $request->user()->newSubscription('default', 'price_monthly')
                    ->anchorBillingCycleOn($anchor->startOfDay())
                    ->create($request->paymentMethodId);

        // ...
    });

サブスクリプションの請求サイクルの管理の詳細については、[Stripe請求サイクルのドキュメント](https://stripe.com/docs/billing/subscriptions/billing-cycle)を参照してください。

<a name="cancelling-subscriptions"></a>
### サブスクリプションの取り消し

サブスクリプションをキャンセルするには、ユーザーのサブスクリプションで`cancel`メソッドを呼び出します。

    $user->subscription('default')->cancel();

サブスクリプションがキャンセルされると、Cashierは自動的に`subscriptions`データベーステーブルの`ends_at`カラムを設定します。このカラムは、`subscribed`メソッドが`false`を返し始めるタイミングを決めるため使用されます。

たとえば、顧客が３月１日にサブスクリプションをキャンセルしたが、そのサブスクリプションが３月５日までに終了するようスケジュールされていなかった場合、`subscribed`メソッドは３月５日まで`true`を返し続けます。この振る舞いを行うのは、ユーザーは請求サイクルが終了するまでアプリケーションの使用を通常継続できるためです。

`onGracePeriod`メソッドを使用して、ユーザーがサブスクリプションをキャンセルしたが、まだ「猶予期間」にあるかどうかを判断できます。

    if ($user->subscription('default')->onGracePeriod()) {
        //
    }

サブスクリプションをすぐにキャンセルする場合は、ユーザーのサブスクリプションで`cancelNow`メソッドを呼び出します。

    $user->subscription('default')->cancelNow();

サブスクリプションをすぐにキャンセルし、従量制による使用量の未請求部分や、新規/保留中の請求項目を請求する場合は、ユーザーのサブスクリプションに対し`cancelNowAndInvoice`メソッドを呼び出します。

    $user->subscription('default')->cancelNowAndInvoice();

特定の時間に購読をキャンセルすることもできます。

    $user->subscription('default')->cancelAt(
        now()->addDays(10)
    );

<a name="resuming-subscriptions"></a>
### サブスクリプションの再開

顧客がサブスクリプションをキャンセルし、それを再開する場合は、サブスクリプションに対し`resume`メソッドを呼び出します。サブスクリプションを再開するには、顧客は「猶予期間」内である必要があります。

    $user->subscription('default')->resume();

顧客がサブスクリプションをキャンセルし、サブスクリプションが完全に期限切れになる前にそのサブスクリプションを再開する場合、請求はすぐに顧客へ課せられれません。代わりに、サブスクリプションを再アクティブ化し、元の請求サイクルで請求します。

<a name="subscription-trials"></a>
## サブスクリプションの試用期間

<a name="with-payment-method-up-front"></a>
### 支払い方法の事前登録

事前に支払い方法情報を収集し、顧客に試用期間を提供したい場合は、サブスクリプションの作成時に`trialDays`メソッドを使用します。

    use Illuminate\Http\Request;

    Route::post('/user/subscribe', function (Request $request) {
        $request->user()->newSubscription('default', 'price_monthly')
                    ->trialDays(10)
                    ->create($request->paymentMethodId);

        // ...
    });

このメソッドは、データベース内のサブスクリプションレコードに試用期間の終了日を設定し、この日付が過ぎるまで顧客への請求を開始しないようにStripeに指示します。`trialDays`メソッドを使用すると、CashierはStripeの価格に設定しているデフォルトの試用期間を上書きします。

> {note} 試用期間の終了日より前に顧客のサブスクリプションがキャンセルされなかった場合、試用期間の終了時にすぐ課金されるため、試用期間の終了日をユーザーに必ず通知する必要があります。

`trialUntil`メソッドを使用すると、試用期間をいつ終了するかを指定する`DateTime`インスタンスを渡せます。

    use Carbon\Carbon;

    $user->newSubscription('default', 'price_monthly')
                ->trialUntil(Carbon::now()->addDays(10))
                ->create($paymentMethod);

ユーザーインスタンスの`onTrial`メソッドまたはサブスクリプションインスタンスの`onTrial`メソッドのいずれかを使用して、ユーザーが試用期間内にあるかどうか判定できます。以下の２例は同じ働きです。

    if ($user->onTrial('default')) {
        //
    }

    if ($user->subscription('default')->onTrial()) {
        //
    }

`endTrial`メソッドを使用して、サブスクリプションの試用期間を即時終了できます。

    $user->subscription('default')->endTrial();

<a name="defining-trial-days-in-stripe-cashier"></a>
#### ストライプ／Cashierでの試用期間日数の定義

価格が受け取るトライアル日数をStripeダッシュボードで定義するか、常にCashierを使用して明示的に渡すかを選択できます。Stripeで価格の試用日数を定義することを選択した場合、過去にそのサブスクリプションを購読していた顧客の新しいサブスクリプションを含む、新しいサブスクリプションは全部、明示的に`skipTrial()`メソッドを呼び出さない限り、常に試用期間が提供されることに注意してください。

<a name="without-payment-method-up-front"></a>
### 支払い方法事前登録なし

ユーザーの支払い方法情報を事前に収集せずに試用期間を提供したい場合は、ユーザーレコードの`trial_ends_at`列を希望の試用終了日に設定してください。これは通常、ユーザー登録時に行います。

    use App\Models\User;

    $user = User::create([
        // ...
        'trial_ends_at' => now()->addDays(10),
    ]);

> {note} Billableなモデルのクラス定義内の`trial_ends_at`属性に[datecast](/docs/{{version}}/eloquent-mutators##date-casting)を必ず追加してください。

Cashierはこのタイプの試用期間を「一般的な試用期間（generic trial）」と呼んでいます。これは、既存のサブスクリプションに関連付けられていないからです。Billableなモデルインスタンスの`onTrial`メソッドは、現在の日付が`trial_ends_at`の値を超えていない場合に`true`を返します。

    if ($user->onTrial()) {
        // ユーザーは試用期間内
    }

ユーザーの実際のサブスクリプションを作成する準備ができたら、通常どおり`newSubscription`メソッドを使用できます。

    $user = User::find(1);

    $user->newSubscription('default', 'price_monthly')->create($paymentMethod);

ユーザーの試用終了日を取得するには、`trialEndsAt`メソッドを使用します。このメソッドは、ユーザーが試用中の場合はCarbon日付インスタンスを返し、そうでない場合は`null`を返します。デフォルト以外の特定のサブスクリプションの試用終了日を取得する場合は、オプションのサブスクリプション名パラメーターを渡すこともできます。

    if ($user->onTrial()) {
        $trialEndsAt = $user->trialEndsAt('main');
    }

ユーザーが「一般的な」試用期間内であり、実際のサブスクリプションをまだ作成していないことを具体的に知りたい場合は、`onGenericTrial`メソッドを使用することもできます。

    if ($user->onGenericTrial()) {
        // ユーザーは「一般的な」試用期間内
    }

<a name="extending-trials"></a>
### 試用期間の延長

`extendTrial`メソッドを使用すると、サブスクリプションの作成後にサブスクリプションの試用期間を延長できます。試用期間がすでに終了していて、顧客にサブスクリプションの料金が既に請求されている場合でも、延長試用期間を提供できます。試用期間内に費やされた時間は、その顧客の次の請求から差し引かれます。

    use App\Models\User;

    $subscription = User::find(1)->subscription('default');

    // 今から７日後に試用期間終了
    $subscription->extendTrial(
        now()->addDays(7)
    );

    // 試用期間をさらに５日追加
    $subscription->extendTrial(
        $subscription->trial_ends_at->addDays(5)
    );

<a name="handling-stripe-webhooks"></a>
## StripeのWebフックの処理

> {tip} [Stripe CLI](https://stripe.com/docs/stripe-cli)を使用して、ローカル開発中にWebhookをテストすることができます。

Stripeは、Webフックを介してさまざまなイベントをアプリケーションに通知できます。デフォルトでは、CashierのWebフックコントローラを指すルートは、Cashierサービスプロバイダにより自動的に登録されます。このコントローラは、すべての受信Webフックリクエストを処理します。

デフォルトでは、Cashier Webフックコントローラは、（Stripe設定で定義する）課金失敗が多すぎるサブスクリプションのキャンセル、顧客の更新、顧客の削除、サブスクリプションの更新、および支払い方法の変更を自動的に処理します。ただし、すぐにわかりますが、このコントローラを拡張して、任意のStripe Webフックイベントを処理できます。

アプリケーションがStripe Webフックを処理できるようにするには、StripeコントロールパネルでWebフックURLを設定してください。デフォルトでは、CashierのWebフックコントローラは`/stripe/webhook`URLパスに応答します。Stripeコントロールパネルで有効にする必要があるすべてのWebフックの完全なリストは次のとおりです。

- `customer.subscription.created`
- `customer.subscription.updated`
- `customer.subscription.deleted`
- `customer.updated`
- `customer.deleted`
- `invoice.payment_action_required`

> {note} Cashierが持っている[Webフック署名検証](/docs/{{version}}/billing#verifying-webhook-signatures)ミドルウェアを使用して、受信Stripe Webフックリクエストを保護してください。

<a name="webhooks-csrf-protection"></a>
#### WebフックとCSRF保護

Stripe WebフックはLaravelの[CSRF保護](/docs/{{version}}/csrf)をバイパスする必要があるため、アプリケーションの`App\Http\Middleware\VerifyCsrfToken`ミドルウェアに例外としてURIをリストするか、`web`ミドルウェアグループの外にルートをリストしてください。

    protected $except = [
        'stripe/*',
    ];

<a name="defining-webhook-event-handlers"></a>
### Webフックイベントハンドラの定義

Cashierは、失敗した請求やその他の一般的なStripe Webフックイベントのサブスクリプションを自動的にキャンセル処理します。ただし、思い通りに処理したいWebフックイベントがある場合は、Cashier Webフックコントローラを拡張し処理できます。

コントローラのメソッド名は、Cashierのコントローラの規則に対応している必要があります。具体的には、メソッドのプリフィックスとして`handle`と、処理するWebフックの「キャメルケース」名を付ける必要があります。たとえば、`invoice.payment_succeeded`　Webフックを処理する場合は、コントローラに`handleInvoicePaymentSucceeded`メソッドを追加する必要があります。

    <?php

    namespace App\Http\Controllers;

    use Laravel\Cashier\Http\Controllers\WebhookController as CashierController;

    class WebhookController extends CashierController
    {
        /**
         * 請求の支払い処理に成功
         *
         * @param  array  $payload
         * @return \Symfony\Component\HttpFoundation\Response
         */
        public function handleInvoicePaymentSucceeded($payload)
        {
            // 受信イベントの処理…
        }
    }

次に、アプリケーションの`routes/web.php`ファイル内でCashier Webフックコントローラのルートを定義します。これにより、Cashierのサービスプロバイダが登録したデフォルトルートが上書きされます。

    use App\Http\Controllers\WebhookController;

    Route::post(
        '/stripe/webhook',
        [WebhookController::class, 'handleWebhook']
    );

> {tip} Cashierは、Webフックを受信すると`Laravel\Cashier\Events\WebhookReceived`イベントを発行し、WebフックがCashierによって処理されると`Laravel\Cashier\Events\WebhookHandled`イベントを発行します。どちらのイベントにも、Stripe Webフックの全ペイロードが含まれています。

<a name="verifying-webhook-signatures"></a>
### Webフック署名の確認

Webフックを保護するために、[StripeのWebhook署名](https://stripe.com/docs/webhooks/signatures)を使用できます。便利なように、Cashierには受信Stripe Webフックリクエストが有効であるかを検証するミドルウェアが自動的に含まれています。

Webフックの検証を有効にするには、`STRIPE_WEBHOOK_SECRET`環境変数がアプリケーションの`.env`ファイルに設定されていることを確認してください。Webフックの`secret`は、Stripeアカウントダッシュボードから取得できます。

<a name="single-charges"></a>
## 一回限りの支払い

<a name="simple-charge"></a>
### シンプルな支払い

> {note} `charge`メソッドは、アプリケーションで使用する通貨の最小単位で請求する金額を受け入れます。たとえば、米ドルを使用する場合、金額はペニーで指定する必要があります。

顧客に対して1回限りの請求を行う場合は、Billableなモデルインスタンスで`charge`メソッドを使用します。`charge`メソッドの２番目の引数として[支払い方法識別子を指定](#payment-methods-for-single-charges)する必要があります。

    use Illuminate\Http\Request;

    Route::post('/purchase', function (Request $request) {
        $stripeCharge = $request->user()->charge(
            100, $request->paymentMethodId
        );

        // ...
    });

`charge`メソッドは３番目の引数を取り、ベースにあるStripeの課金作成へのオプションを指定できます。課金作成時に利用できるオプションの詳細は、[Stripeドキュメント](https://stripe.com/docs/api/charges/create)を参照してください。

    $user->charge(100, $paymentMethod, [
        'custom_option' => $value,
    ]);

また、基礎となる顧客やユーザーなしに`charge`メソッドを使用することもできます。そのためには、アプリケーションのBillableなモデルの新しいインスタンスで`charge`メソッドを呼び出します。

    use App\Models\User;

    $stripeCharge = (new User)->charge(100, $paymentMethod);

課金失敗の場合、`charge`メソッドは例外を投げます。課金が成功すると、メソッドは`Laravel\Cashier\Payment`のインスタンスを返します。

    try {
        $payment = $user->charge(100, $paymentMethod);
    } catch (Exception $e) {
        //
    }

<a name="charge-with-invoice"></a>
### インボイス付きの支払い

時に１回限りの請求を行い、PDFレシートを顧客に提供する必要がおきるでしょう。`invoiceFor`メソッドを使用すると、まさにそれを実行できます。たとえば、「メンテナンス料金」を顧客に$5.00請求するとします。

    $user->invoiceFor('One Time Fee', 500);

インボイスは、ユーザーのデフォルトの支払い方法に対し即時請求されます。`invoiceFor`メソッドは３番目の引数として配列も受け入れます。この配列には、インボイスアイテムの請求オプションを指定します。メソッドの４番目の引数も配列で、インボイス自体の請求オプションを指定します。

    $user->invoiceFor('Stickers', 500, [
        'quantity' => 50,
    ], [
        'default_tax_rates' => ['txr_id'],
    ]);

> {note} `invoiceFor`メソッドは、失敗した請求を再試行するStripeインボイスを作成します。課金に失敗した請求を再試行したくない場合は、最初の失敗した請求の後にStripe　APIを使用し、インボイスをを閉じる必要があります。

<a name="refunding-charges"></a>
### 支払いの払い戻し

Stripeの料金を払い戻す必要がある場合は、`refund`メソッドを使用します。このメソッドは、最初の引数にStripe[支払いインテントID](#payment-methods-for-single-charges)を取ります。

    $payment = $user->charge(100, $paymentMethodId);

    $user->refund($payment->id);

<a name="invoices"></a>
## インボイス

<a name="retrieving-invoices"></a>
### インボイスの取得

`invoices`メソッドを使用して、Billableなモデルのインボイスの配列を簡単に取得できます。`invoices`メソッドは`Laravel\Cashier\Invoice`インスタンスのコレクションを返します。

    $invoices = $user->invoices();

結果に保留中のインボイスを含めたい場合は、`invoicesInclusivePending`メソッドを使用します。

    $invoices = $user->invoicesIncludingPending();

`findInvoice`メソッドを使用して、IDで特定のインボイスを取得できます。

    $invoice = $user->findInvoice($invoiceId);

<a name="displaying-invoice-information"></a>
#### インボイス情報の表示

ある顧客のインボイスを一覧表示する場合、インボイスのメソッドを使用し関連するインボイス情報を表示すると思います。たとえば、テーブル中の全インボイスをリストする場合、ユーザーがどれでも簡単にダウンロードできるようにしたいことでしょう。

    <table>
        @foreach ($invoices as $invoice)
            <tr>
                <td>{{ $invoice->date()->toFormattedDateString() }}</td>
                <td>{{ $invoice->total() }}</td>
                <td><a href="/user/invoice/{{ $invoice->id }}">Download</a></td>
            </tr>
        @endforeach
    </table>

<a name="upcoming-invoices"></a>
### 将来のインボイス

顧客の将来のインボイスを取得するには、`upcomingInvoice`メソッドを使います。

    $invoice = $user->upcomingInvoice();

同様に、顧客が複数のサブスクリプションを持っている場合、指定するサブスクリプションの次期インボイスを取得することもできます。

    $invoice = $user->subscription('default')->upcomingInvoice();

<a name="previewing-subscription-invoices"></a>
### サブスクリプションインボイスのプレビュー

`previewInvoice`メソッドを使うと、価格変更をする前にインボイスをプレビューできます。これにより、特定の価格変更を行う場合、顧客のインボイスがどのようなものになるか確認できます。

    $invoice = $user->subscription('default')->previewInvoice('price_yearly');

新しい複数価格のインボイスをプレビューするには、価格の配列を`previewInvoice`メソッドへ渡します。

    $invoice = $user->subscription('default')->previewInvoice(['price_yearly', 'price_metered']);

<a name="generating-invoice-pdfs"></a>
### インボイスＰＤＦの生成

ルートまたはコントローラ内から、`downloadInvoice`メソッドを使用して、特定のインボイスのＰＤＦダウンロードを生成できます。このメソッドは、インボイスのダウンロードに必要なHTTP応答を適切かつ自動的に生成します。

    use Illuminate\Http\Request;

    Route::get('/user/invoice/{invoice}', function (Request $request, $invoiceId) {
        return $request->user()->downloadInvoice($invoiceId);
    });

インボイスのすべてのデータはデフォルトで、Stripeに保存されている顧客と請求書のデータから作成します。しかし、`downloadInvoice`メソッドの第２引数に配列を指定することで、データの一部をカスタマイズ可能です。この配列で、会社や製品の詳細などの情報がカスタマイズできます。

    return $request->user()->downloadInvoice($invoiceId, [
        'vendor' => 'Your Company',
        'product' => 'Your Product',
        'street' => 'Main Str. 1',
        'location' => '2000 Antwerp, Belgium',
        'phone' => '+32 499 00 00 00',
        'email' => 'info@example.com',
        'url' => 'https://example.com',
        'vendorVat' => 'BE123456789',
    ], 'my-invoice');

`downloadInvoice`メソッドの第３引数でカスタムファイル名の指定もできます。このファイル名には自動的に`.pdf`というサフィックスが付きます。

    return $request->user()->downloadInvoice($invoiceId, [], 'my-invoice');

<a name="checkout"></a>
## チェックアウト

Cashier Stripeは、[Stripe Checkout](https://stripe.com/en-be/payments/checkout)もサポートしています。Stripe Checkoutは、チェックアウトページを事前に構築しホストするという、支払いを受け入れるためカスタムページを実装する手間を省きます。

以下のドキュメントで、Stripe Checkoutをどのように利用開始するのかに関する情報を説明します。Stripe Checkoutの詳細は、[StrepeのCheckoutに関するドキュメント](https://stripe.com/docs/payments/checkout)を確認する必要があるでしょう

<a name="product-checkouts"></a>
### 商品の支払い

Billableなモデル上の`checkout`メソッドを使用して、Stripeダッシュボード内に作成した既存の製品のチェックアウトを実行できます。`checkout`メソッドは新しいStripeチェックアウトセッションを開始します。デフォルトで、Stripe価格IDを渡す必要があります。

    $checkout = $user->checkout('price_tshirt');

    return view('your-checkout-view', [
        'checkout' => $checkout,
    ]);

必要に応じて、製品数量を指定することもできます。

    $checkout = $user->checkout(['price_tshirt' => 15]);

チェックアウトセッションインスタンスをビューに渡し、ユーザーをStripeチェックアウトに向かわせるボタンを`button`メソッドを使用してレンダーできます。

    {{ $checkout->button('Buy') }}

顧客がこのボタンをクリックすると、Stripeのチェックアウトページにリダイレクトされます。デフォルトでは、ユーザーが購入を正常に完了した場合、または購入をキャンセルすると、`Home`ルートへリダイレクトされますが、`success_url`と`cancel_url`オプションを使ってカスタムコールバックURLを指定できます。

    $checkout = $user->checkout(['price_tshirt' => 1], [
        'success_url' => route('your-success-route'),
        'cancel_url' => route('your-cancel-route'),
    ]);

<a name="checkout-promotion-codes"></a>
#### プロモーションコード

Stripe Checkoutはデフォルトで、[ユーザーが商品に使用できるプロモーションコード](https://stripe.com/docs/billing/subscriptions/discounts/code)を許可していません。幸いわいに、チェックアウトページでこれを有効にする簡単な方法があります。そのためには、`allowPromotionCodes`メソッドを呼び出します。

    $checkout = $user->allowPromotionCodes()->checkout('price_tshirt');

<a name="single-charge-checkouts"></a>
### 一回限りの支払い

ストライプダッシュボードに作成していない、アドホックな商品をシンプルに課金することもできます。これには、Billableなモデルで`checkoutCharge`メソッドを使用し、課金可能な料金、製品名、およびオプションの数量を渡たします。

    $checkout = $user->checkoutCharge(1200, 'T-Shirt', 5);

    return view('your-checkout-view', [
        'checkout' => $checkout,
    ]);

チェックアウトセッションインスタンスをビューに渡し、ユーザーをStripeチェックアウトへ向かわせるボタンを`button`メソッドでレンダーできます。

    {{ $checkout->button('Buy') }}

顧客がこのボタンをクリックすると、Stripeのチェックアウトページにリダイレクトされます。

> {note}`checkoutCharge`メソッドを使用する場合、Stripeは常にStripeダッシュボードに新しい製品と価格を作成します。したがって、代わりにStripeダッシュボードで事前に商品を作成し、`checkout`メソッドを使用することを推奨します。

<a name="subscription-checkouts"></a>
### サブスクリプションの支払い

> {note} Stripe Checkoutのサブスクリプションを使用するには、Stripeダッシュボードで`customer.subscription.created` Webフックを有効にする必要があります。このWebフックは、データベースにサブスクリプションレコードを作成し、すべてのサブスクリプション関連アイテムを保存します。

サブスクリプションを開始するには、Stripe Checkoutを使用することもできます。Cashierのサブスクリプションビルダメソッドを使用してサブスクリプションを定義した後に、`checkout`メソッドを呼び出せます。

    $checkout = Auth::user()
            ->newSubscription('default', 'price_monthly')
            ->checkout();

    return view('your-checkout-view', [
        'checkout' => $checkout,
    ]);

製品のチェックアウトと同様に、成功およびキャンセルのURLをカスタマイズできます。

    $checkout = Auth::user()->newSubscription('default', 'price_monthly')->checkout([
        'success_url' => route('your-success-route'),
        'cancel_url' => route('your-cancel-route'),
    ]);

もちろん、サブスクリプションチェックアウトのプロモーションコードを有効にすることもできます。

    $checkout = Auth::user()->newSubscription('default', 'price_monthly')
        ->allowPromotionCodes()
        ->checkout();

チェックアウトセッションインスタンスをビューへ渡し、ユーザーをStripeチェックアウトに向かわせるボタンを`button`メソッドを使用してレンダーできます。

    {{ $checkout->button('Subscribe') }}

顧客がこのボタンをクリックすると、Stripeのチェックアウトページにリダイレクトされます。

> {note} 残念ながらStripe Checkoutはサブスクリプションを開始するとき、すべてのサブスクリプション請求オプションをサポートしていません。サブスクリプションビルダの`anchorBillingCycleOn`メソッドを使用して、プロレーション動作の設定、または支払い動作の設定は、Stripeチェックアウトセッション中に全く効果はありません。どのパラメータが利用可能であるかを確認するには、[Stripe CheckoutセッションAPIのドキュメント](https://stripe.com/docs/api/checkout/sessions/create)を参照してください。

<a name="stripe-checkout-trial-periods"></a>
#### Stripeの支払と試用期間

もちろん、Stripe Checkoutを使用して購読を作成する際、試用期間の完了時間を定義できます。

    $checkout = Auth::user()->newSubscription('default', 'price_monthly')
        ->trialDays(3)
        ->checkout();

ただし、試用期間は最低４８時間でなければならず、これはStripe Checkoutでサポートされている試行時間の最短時間です。

<a name="stripe-checkout-subscriptions-and-webhooks"></a>
#### サブスクリプションとWebフック

StripeとCashierはWebフックを使いサブスクリプションの状態を更新することを覚えておいてください。そのため、顧客が支払い情報を入力した後でアプリケーションに戻った時点で、サブスクリプションが有効になっていない可能性があります。このシナリオを処理するには、ユーザーに支払いやサブスクリプションが保留中であることをユーザーに知らせるメッセージを表示することを推奨します。

<a name="styling-the-checkout-button"></a>
### 支払いボタンのスタイル

チェックアウトボタンをレンダーするときは、`class`と`style`オプションを使ってボタンスタイルをカスタマイズできます。これらのオプションは、連想配列として`button`メソッドへの第２引数に渡す必要があります。

    {{ $checkout->button('Buy', ['class' => 'p-4 bg-blue-500 text-white']) }}

<a name="handling-failed-payments"></a>
## 支払い失敗の処理

サブスクリプションまたは１回限りの支払いが失敗する場合もあります。これが起きると、Cashierはこの発生を通知する`Laravel\Cashier\Exceptions\IncompletePayment`例外を投げます。この例外をキャッチした後に続行する方法は、２つの選択肢があります。

１つ目はCashierが用意している専用の支払い確認ページに顧客をリダイレクトすることです。このページは、Cashierのサービスプロバイダを介して登録済みの名前付きルートがすでに割り振られています。したがって、`IncompletePayment`例外をキャッチして、ユーザーを支払い確認ページにリダイレクトできます。

    use Laravel\Cashier\Exceptions\IncompletePayment;

    try {
        $subscription = $user->newSubscription('default', 'price_monthly')
                                ->create($paymentMethod);
    } catch (IncompletePayment $exception) {
        return redirect()->route(
            'cashier.payment',
            [$exception->payment->id, 'redirect' => route('home')]
        );
    }

支払い確認ページで、顧客はクレジットカード情報を再度入力し、「3Dセキュア」確認などのStripeに必要な追加のアクションを実行するように求められます。支払いを確認すると、ユーザーは上記の`redirect`パラメータで指定したURLへリダイレクトされます。リダイレクト時に、`message`(文字列)および`success`(整数)クエリ文字列変数をURLへ追加します。支払い確認ページでは現在、以下の決済方法に対応しています。

<div class="content-list" markdown="1">
- Credit Cards
- Alipay
- Bancontact
- BECS Direct Debit
- EPS
- Giropay
- iDEAL
- SEPA Direct Debit
</div>

もう一つの方法として、Stripeに支払い確認の処理を任せることもできます。この場合、支払い確認ページにリダイレクトする代わりに、Stripeダッシュボードで[Stripeの自動請求メールを設定](https://dashboard.stripe.com/account/billing/automatic)してください。ただし、`IncompletePayment`例外がキャッチされた場合でも、支払い確認の手順を記載したメールがユーザーへ届くよう、通知する必要があります。

`Billable`トレイトを使用するモデルの`charge`、`invoiceFor`、`invoice`メソッドでは、支払いの例外が投げられる場合があります。サブスクリプションを操作する場合では、`SubscriptionBuilder`の`create`メソッド、および`Subscription`と`SubscriptionItem`モデルの`incrementAndInvoice`メソッドと`swapAndInvoice`メソッドは、不完全な支払い例外を投げる可能性があります。

既存のサブスクリプションの支払いが不完全であるかどうかの判断は、Billableモデルまたはサブスクリプションインスタンスで`hasIncompletePayment`メソッドを使用して行えます。

    if ($user->hasIncompletePayment('default')) {
        //
    }

    if ($user->subscription('default')->hasIncompletePayment()) {
        //
    }

例外インスタンスの`payment`プロパティを調べると、不完全な支払いの具体的なステータスを調べられます。

    use Laravel\Cashier\Exceptions\IncompletePayment;

    try {
        $user->charge(1000, 'pm_card_threeDSecure2Required');
    } catch (IncompletePayment $exception) {
        // 支払いインテント状態の取得
        $exception->payment->status;

        // 特定の条件の確認
        if ($exception->payment->requiresPaymentMethod()) {
            // ...
        } elseif ($exception->payment->requiresConfirmation()) {
            // ...
        }
    }

<a name="strong-customer-authentication"></a>
## 強力な顧客認証（ＳＣＡ）

あなたのビジネスがヨーロッパに拠点を置いているか、顧客がヨーロッパにいる場合は、ＥＵの強力な顧客認証（ＳＣＡ）法令を遵守する必要があります。これらの法令は、支払い詐欺を防ぐために２０１９年９月に欧州連合によって課されました。幸いにして、StripeとCashierは、ＳＣＡ準拠のアプリケーションを構築する準備ができています。

> {note} 使用開始前に、[PSD2とSCAに関するStripeのガイド](https://stripe.com/guides/strong-customer-authentication)と[新しいSCA APIに関するドキュメント](https://stripe.com/docs/strong-customer-authentication)を確認してください。

<a name="payments-requiring-additional-confirmation"></a>
### 追加の確認が必要な支払い

ＳＣＡ法令では支払いを確認し処理するため、追加の検証が頻繁に必要になります。これが起きると、Cashierは追加の検証が必要であることを通知する`Laravel\Cashier\Exceptions\IncompletePayment`例外を投げます。こうした例外の処理方法の詳細は、[失敗した支払いの処理](#handling-failed-payments)のドキュメントを参照してください。

StripeとCashierが提供する支払い確認画面は、特定の銀行またはカード発行者の支払いフローに合わせて調整することができ、追加のカード確認、一時的な少額の支払い、個別のデバイス認証、その他の形式の検証を含むことができます。

<a name="incomplete-and-past-due-state"></a>
#### 不完了と期限超過の状態

支払いに追加の確認が必要な場合、サブスクリプションは`stripe_status`データベースカラムが示すように、`incomplete`か`past_due`状態のままになります。Cashierは支払いの確認が完了し、アプリケーションがWebフックを介してStripeから完了の通知を受けるととすぐに、顧客のサブスクリプションを自動的にアクティブ化します。

`incomplete`および`past_due`状態の詳細については、[これらの状態に関する追加のドキュメント](#incomplete-and-past-due-status)を参照してください。

<a name="off-session-payment-notifications"></a>
### オフセッション支払い通知

ＳＣＡの法令では、サブスクリプションがアクティブな場合でも、顧客は支払いの詳細を時々確認する必要があるため、Cashierはオフセッションでの支払い確認が必要なときに顧客に通知を送信できます。たとえばこれは、サブスクリプションの更新時に発生する可能性があります。Cashierの支払い通知は、`CASHIER_PAYMENT_NOTIFICATION`環境変数を通知クラスに設定することで有効にできます。デフォルトでは、この通知は無効になっています。もちろん、Cashierにはこの目的で使用できる通知クラスが含まれていますが、必要に応じて独自の通知クラスを自由に提供できます。

    CASHIER_PAYMENT_NOTIFICATION=Laravel\Cashier\Notifications\ConfirmPayment

オフセッションでの支払い確認通知が確実に配信されるようにするため、アプリケーションで[Stripe Webフックが設定されている](#handling-stripe-webhooks)ことと、Stripeダッシュボードで`invoice.payment_action_required`webhookが有効になっていることを確認してください。さらに、`Billable`モデルでLaravelの`Illuminate\Notifications\Notizable`トレイトを使用していることも確認する必要があります。

> {note} 顧客が追加の確認を必要とする支払いを手動で行う場合でも、通知は送信されます。残念ながら、支払いが手動なのか「オフセッション」で行われたかをStripeが知る方法はありません。ただし、顧客が支払いを確認した後に支払いページへアクセスすると、「支払いが成功しました（Payment Successful）」というメッセージが表示されます。謝って顧客へ同じ支払いを２回確認させ、２回目の請求を行粉なってしまうことはありません。

<a name="stripe-sdk"></a>
## Stripe SDK

Cashierのオブジェクトの多くは、StripeSDKオブジェクトのラッパーです。Stripeオブジェクトを直接操作したい場合は、`asStripe`メソッドを使用してオブジェクトを簡単に取得できます。

    $stripeSubscription = $subscription->asStripeSubscription();

    $stripeSubscription->application_fee_percent = 5;

    $stripeSubscription->save();

`updateStripeSubscription`メソッドを使用して、Stripeサブスクリプションを直接更新することもできます。

    $subscription->updateStripeSubscription(['application_fee_percent' => 5]);

<a name="testing"></a>
## テスト

Cashierを使用するアプリケーションをテストする場合、Stripe APIへの実際のHTTPリクエストをモックすることができます。ただし、これには、Cashier自身の動作を部分的に再実装する必要があります。したがって、テストが実際のStripe APIにヒットすることを許可することをおすすめします。これは遅いですが、アプリケーションが期待どおりに機能しているという確信が高まり、遅いテストは独自のPHPUnitテストグループ内に配置するのが良いでしょう。

テストするときは、Cashier自体には優れたテストスイートを既に持っていることを忘れないでください。したがって、基本的なCashierの動作すべてではなく、独自のアプリケーションのサブスクリプションと支払いフローのテストにのみ焦点を当てる必要があります。

テスト開始するには、Stripeシークレットの**テスト**バージョンを`phpunit.xml`ファイルに追加します。

    <env name="STRIPE_SECRET" value="sk_test_<your-key>"/>

これで、テスト中にCashierとやり取りするたびに、実際のAPIリクエストがStripeテスト環境に送信されます。便宜上、Stripeテストアカウントに、テスト中に使用できるサブスクリプション/価格を事前に入力する必要があります。

> {tip} クレジットカードの拒否や失敗など、さまざまな請求シナリオをテストするため、Stripeが提供しているさまざまな[カード番号とトークンのテスト](https://stripe.com/docs/testing)を使用できます。
