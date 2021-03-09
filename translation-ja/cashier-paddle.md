# Laravel Cashier (Paddle)

- [Introduction](#introduction)
- [Upgrading Cashier](#upgrading-cashier)
- [Installation](#installation)
    - [Database Migrations](#database-migrations)
    - [Database Migrations](#database-migrations)
- [Configuration](#configuration)
    - [Billable Model](#billable-model)
    - [API Keys](#api-keys)
    - [Paddle JS](#paddle-js)
    - [Currency Configuration](#currency-configuration)
- [Core Concepts](#core-concepts)
    - [Pay Links](#pay-links)
    - [Inline Checkout](#inline-checkout)
    - [User Identification](#user-identification)
- [Prices](#prices)
- [Customers](#customers)
    - [Customer Defaults](#customer-defaults)
- [Subscriptions](#subscriptions)
    - [Creating Subscriptions](#creating-subscriptions)
    - [Checking Subscription Status](#checking-subscription-status)
    - [Subscription Single Charges](#subscription-single-charges)
    - [Updating Payment Information](#updating-payment-information)
    - [Changing Plans](#changing-plans)
    - [Subscription Quantity](#subscription-quantity)
    - [Pausing Subscriptions](#pausing-subscriptions)
    - [Cancelling Subscriptions](#cancelling-subscriptions)
- [Subscription Trials](#subscription-trials)
    - [With Payment Method Up Front](#with-payment-method-up-front)
    - [Without Payment Method Up Front](#without-payment-method-up-front)
- [Handling Paddle Webhooks](#handling-paddle-webhooks)
    - [Verifying Webhook Signatures](#verifying-webhook-signatures)
- [Single Charges](#single-charges)
    - [Simple Charge](#simple-charge)
    - [Charging Products](#charging-products)
    - [Refunding Orders](#refunding-orders)
- [Receipts](#receipts)
    - [Past & Upcoming Payments](#past-and-upcoming-payments)
- [Handling Failed Payments](#handling-failed-payments)
- [Testing](#testing)

<a name="introduction"></a>
## Introduction

Laravel Cashier Paddle provides an expressive, fluent interface to [Paddle's](https://paddle.com) subscription billing services. It handles almost all of the boilerplate subscription billing code you are dreading. In addition to basic subscription management, Cashier can handle: coupons, swapping subscription, subscription "quantities", cancellation grace periods, and more.

While working with Cashier we recommend you also review Paddle's [user guides](https://developer.paddle.com/guides) and [API documentation](https://developer.paddle.com/api-reference/intro).

<a name="upgrading-cashier"></a>
## Upgrading Cashier

When upgrading to a new version of Cashier, it's important that you carefully review [the upgrade guide](https://github.com/laravel/cashier-paddle/blob/master/UPGRADE.md).

<a name="installation"></a>
## Installation

First, install the Cashier package for Paddle using the Composer package manager:

    composer require laravel/cashier-paddle

> {note} To ensure Cashier properly handles all Paddle events, remember to [set up Cashier's webhook handling](#handling-paddle-webhooks).

<a name="database-migrations"></a>
### Database Migrations

The Cashier service provider registers its own database migration directory, so remember to migrate your database after installing the package. The Cashier migrations will create a new `customers` table. In addition, a new `subscriptions` table will be created to store all of your customer's subscriptions. Finally, a new `receipts` table will be created to store all of your application's receipt information:

    php artisan migrate

If you need to overwrite the migrations that are included with Cashier, you can publish them using the `vendor:publish` Artisan command:

    php artisan vendor:publish --tag="cashier-migrations"

If you would like to prevent Cashier's migrations from running entirely, you may use the `ignoreMigrations` provided by Cashier. Typically, this method should be called in the `register` method of your `AppServiceProvider`:

    use Laravel\Paddle\Cashier;

    /**
     * Register any application services.
     *
     * @return void
     */
    public function register()
    {
        Cashier::ignoreMigrations();
    }
     * Register any application services.
     *
     * @return void
     */
    public function register()
    {
        Cashier::ignoreMigrations();
    }

<a name="configuration"></a>
## Configuration

<a name="billable-model"></a>
### Billable Model

Before using Cashier, you must add the `Billable` trait to your user model definition. This trait provides various methods to allow you to perform common billing tasks, such as creating subscriptions, applying coupons and updating payment method information:

    use Laravel\Paddle\Billable;
    use Illuminate\Database\Eloquent\Model;

    class User extends Authenticatable
    {
        use Billable;
    }

If you have billable entities that are not users, you may also add the trait to those classes:

    use Illuminate\Database\Eloquent\Model;
    use Laravel\Paddle\Billable;
Next, you should configure your Paddle keys in your application's `.env` file. You can retrieve your Paddle API keys from the Paddle control panel:
    class Team extends Model
    {
        use Billable;
    }

<a name="api-keys"></a>
### API Keys

Paddle relies on its own JavaScript library to initiate the Paddle checkout widget. You can load the JavaScript library by placing the `@paddleJS` Blade directive right before your application layout's closing `</head>` tag:

    PADDLE_VENDOR_ID=your-paddle-vendor-id
    PADDLE_VENDOR_AUTH_CODE=your-paddle-vendor-auth-code
    PADDLE_PUBLIC_KEY="your-paddle-public-key"

<a name="paddle-js"></a>
### Paddle JS

Paddle relies on its own JavaScript library to initiate the Paddle checkout widget. You can load the JavaScript library by placing the `@paddleJS` Blade directive right before your application layout's closing `</head>` tag:

The default Cashier currency is United States Dollars (USD). You can change the default currency by defining a `CASHIER_CURRENCY` environment variable within your application's `.env` file:
        ...

        @paddleJS
    </head>

<a name="currency-configuration"></a>
### Currency Configuration

The default Cashier currency is United States Dollars (USD). You can change the default currency by defining a `CASHIER_CURRENCY` environment variable within your application's `.env` file:

    CASHIER_CURRENCY=EUR

In addition to configuring Cashier's currency, you may also specify a locale to be used when formatting money values for display on invoices. Internally, Cashier utilizes [PHP's `NumberFormatter` class](https://www.php.net/manual/en/class.numberformatter.php) to set the currency locale:

    CASHIER_CURRENCY_LOCALE=nl_BE
Paddle lacks an extensive CRUD API to perform subscription state changes. Therefore, most interactions with Paddle are done through its [checkout widget](https://developer.paddle.com/guides/how-tos/checkout/paddle-checkout). Before we can display the checkout widget, we must generate a "pay link" using Cashier. A "pay link" will inform the checkout widget of the billing operation we wish to perform:
> {note} In order to use locales other than `en`, ensure the `ext-intl` PHP extension is installed and configured on your server.
    use App\Models\User;
    use Illuminate\Http\Request;
    use App\Models\User;
    Route::get('/user/subscribe', function (Request $request) {
        $payLink = $request->user()->newSubscription('default', $premium = 34567)
            ->returnTo(route('home'))
            ->create();

        return view('billing', ['payLink' => $payLink]);
    });

Cashier includes a `paddle-button` [Blade component](/docs/{{version}}/blade#components). We may pass the pay link URL to this component as a "prop". When this button is clicked, Paddle's checkout widget will be displayed:

```html
<x-paddle-button :url="$payLink" class="px-8 py-4">
    Subscribe
</x-paddle-button>
```
        $payLink = $request->user()->newSubscription('default', $premium = 34567)
            ->returnTo(route('home'))
            ->create();
```html
<x-paddle-button :url="$payLink" class="px-8 py-4" data-theme="none">
    Subscribe
</x-paddle-button>
```

The Paddle checkout widget is asynchronous. Once the user creates or updates a subscription within the widget, Paddle will send your application webhooks so that you may properly update the subscription state in our own database. Therefore, it's important that you properly [set up webhooks](#handling-paddle-webhooks) to accommodate for state changes from Paddle.

For more information on pay links, you may review [the Paddle API documentation on pay link generation](https://developer.paddle.com/api-reference/product-api/pay-links/createpaylink).
<x-paddle-button :url="$payLink" class="px-8 py-4">
> {note} After a subscription state change, the delay for receiving the corresponding webhook is typically minimal but you should account for this in your application by considering that your user's subscription might not be immediately available after completing the checkout.
</x-paddle-button>
```

By default, this will display a button with the standard Paddle styling. You can remove all Paddle styling by adding the `data-theme="none"` attribute to the component:
If you don't want to make use of Paddle's "overlay" style checkout widget, Paddle also provides the option to display the widget inline. While this approach does not allow you to adjust any of the checkout's HTML fields, it allows you to embed the widget within your application.
```html
<x-paddle-button :url="$payLink" class="px-8 py-4" data-theme="none">
    Subscribe
```html
<x-paddle-checkout :override="$payLink" class="w-full" />
```
```

The Paddle checkout widget is asynchronous. Once the user creates or updates a subscription within the widget, Paddle will send your application webhooks so that you may properly update the subscription state in our own database. Therefore, it's important that you properly [set up webhooks](#handling-paddle-webhooks) to accommodate for state changes from Paddle.

For more information on pay links, you may review [the Paddle API documentation on pay link generation](https://developer.paddle.com/api-reference/product-api/pay-links/createpaylink).

> {note} After a subscription state change, the delay for receiving the corresponding webhook is typically minimal but you should account for this in your application by considering that your user's subscription might not be immediately available after completing the checkout.

<a name="inline-checkout"></a>
### Inline Checkout

If you don't want to make use of Paddle's "overlay" style checkout widget, Paddle also provides the option to display the widget inline. While this approach does not allow you to adjust any of the checkout's HTML fields, it allows you to embed the widget within your application.

To make it easy for you to get started with inline checkout, Cashier includes a `paddle-checkout` Blade component. To get started, you should [generate a pay link](#pay-links) and pass the pay link to the component's `override` attribute:

```html
<x-paddle-checkout :override="$payLink" class="w-full" />
Please consult Paddle's [guide on Inline Checkout](https://developer.paddle.com/guides/how-tos/checkout/inline-checkout) as well as their [parameter reference](https://developer.paddle.com/reference/paddle-js/parameters) for further details on the inline checkout's available options.

> {note} If you would like to also use the `passthrough` option when specifying custom options, you should provide a key / value array as its value. Cashier will automatically handle converting the array to a JSON string. In addition, the `customer_id` passthrough option is reserved for internal Cashier usage.

    <x-paddle-checkout :override="$payLink" class="w-full" height="500" />

<a name="inline-checkout-without-pay-links"></a>
In contrast to Stripe, Paddle users are unique across all of Paddle, not unique per Paddle account. Because of this, Paddle's API's do not currently provide a method to update a user's details such as their email address. When generating pay links, Paddle identifies users using the `customer_email` parameter. When creating a subscription, Paddle will try to match the user provided email to an existing Paddle user.

Alternatively, you may customize the widget with custom options instead of using a pay link:

Therefore, when displaying subscriptions you should always inform the user which email address or payment method information is connected to the subscription on a per-subscription basis. Retrieving this information can be done with the following methods provided by the `Laravel\Paddle\Subscription` model:
        'product' => $productId,
        'title' => 'Product Title',
    ];
    $subscription->paddleEmail();
    $subscription->paymentMethod();
    $subscription->cardBrand();
    $subscription->cardLastFour();
    $subscription->cardExpirationDate();
> {note} If you would like to also use the `passthrough` option when specifying custom options, you should provide a key / value array as its value. Cashier will automatically handle converting the array to a JSON string. In addition, the `customer_id` passthrough option is reserved for internal Cashier usage.

<a name="user-identification"></a>
### User Identification

In contrast to Stripe, Paddle users are unique across all of Paddle, not unique per Paddle account. Because of this, Paddle's API's do not currently provide a method to update a user's details such as their email address. When generating pay links, Paddle identifies users using the `customer_email` parameter. When creating a subscription, Paddle will try to match the user provided email to an existing Paddle user.
Paddle allows you to customize prices per currency, essentially allowing you to configure different prices for different countries. Cashier Paddle allows you to retrieve all of the prices for a given product using the `productPrices` method. This method accepts the product IDs of the products you wish to retrieve prices for:
In light of this behavior, there are some important things to keep in mind when using Cashier and Paddle. First, you should be aware that even though subscriptions in Cashier are tied to the same application user, **they could be tied to different users within Paddle's internal systems**. Secondly, each subscription has its own connected payment method information and could also have different email addresses within Paddle's internal systems (depending on which email was assigned to the user when the subscription was created).

Therefore, when displaying subscriptions you should always inform the user which email address or payment method information is connected to the subscription on a per-subscription basis. Retrieving this information can be done with the following methods provided by the `Laravel\Paddle\Subscription` model:
    $subscription = $user->subscription('default');

    $subscription->paddleEmail();
    $subscription->paymentMethod();
    $subscription->cardBrand();
    $subscription->cardLastFour();

There is currently no way to modify a user's email address through the Paddle API. When a user wants to update their email address within Paddle, the only way for them to do so is to contact Paddle customer support. When communicating with Paddle, they need to provide the `paddleEmail` value of the subscription to assist Paddle in updating the correct user.

<a name="prices"></a>
```html
<ul>
    @foreach ($prices as $price)
        <li>{{ $price->product_title }} - {{ $price->price()->gross() }}</li>
    @endforeach
</ul>
```

    $prices = Cashier::productPrices([123, 456]);

```html
<ul>
    @foreach ($prices as $price)
        <li>{{ $price->product_title }} - {{ $price->price()->net() }} (+ {{ $price->price()->tax() }} tax)</li>
    @endforeach
</ul>
```

After retrieving the prices you may display them however you wish:

```html
<ul>
    @foreach ($prices as $price)
        <li>{{ $price->product_title }} - Initial: {{ $price->initialPrice()->gross() }} - Recurring: {{ $price->recurringPrice()->gross() }}</li>
    @endforeach
</ul>
```
</ul>
```

You may also display the net price (excludes tax) and display the tax amount separately:

```html
<ul>
    @foreach ($prices as $price)
        <li>{{ $price->product_title }} - {{ $price->price()->net() }} (+ {{ $price->price()->tax() }} tax)</li>
    @endforeach
```

If you retrieved prices for subscription plans you can display their initial and recurring price separately:

```html
<ul>
    @foreach ($prices as $price)
        <li>{{ $price->product_title }} - Initial: {{ $price->initialPrice()->gross() }} - Recurring: {{ $price->recurringPrice()->gross() }}</li>
    @endforeach
</ul>
```
    $prices = Cashier::productPrices([123, 456], [
        'coupons' => 'SUMMERSALE,20PERCENTOFF'
    ]);
For more information, [check Paddle's API documentation on prices](https://developer.paddle.com/api-reference/checkout-api/prices/getprices).

<a name="prices-customers"></a>
```html
<ul>
    @foreach ($prices as $price)
        <li>{{ $price->product_title }} - {{ $price->price()->gross() }}</li>
    @endforeach
</ul>
```

    $prices = User::find(1)->productPrices([123, 456]);

```html
<ul>
    @foreach ($prices as $price)
        <li>{{ $price->product_title }} - {{ $price->listPrice()->gross() }}</li>
    @endforeach
</ul>
```
You may also choose to display prices after a coupon reduction. When calling the `productPrices` method, coupons may be passed as a comma delimited string:

    use Laravel\Paddle\Cashier;

    $prices = Cashier::productPrices([123, 456], [
        'coupons' => 'SUMMERSALE,20PERCENTOFF'
    ]);

Then, display the calculated prices using the `price` method:
Cashier allows you to define some useful defaults for your customers when creating pay links. Setting these defaults allow you to pre-fill a customer's email address, country, and postal code so that they can immediately move on to the payment portion of the checkout widget. You can set these defaults by overriding the following methods on your billable model:
```html
<ul>
    @foreach ($prices as $price)
        <li>{{ $price->product_title }} - {{ $price->price()->gross() }}</li>
    @endforeach
</ul>
```

You may display the original listed prices (without coupon discounts) using the `listPrice` method:

```html
<ul>
    @foreach ($prices as $price)
        <li>{{ $price->product_title }} - {{ $price->listPrice()->gross() }}</li>
    @endforeach
</ul>
```

> {note} When using the prices API, Paddle only allows to apply coupons to one-time purchase products and not to subscription plans.

<a name="customers"></a>
## Customers

<a name="customer-defaults"></a>
### Customer Defaults
     * Get the customer's postal code to associate with Paddle.
Cashier allows you to define some useful defaults for your customers when creating pay links. Setting these defaults allow you to pre-fill a customer's email address, country, and postal code so that they can immediately move on to the payment portion of the checkout widget. You can set these defaults by overriding the following methods on your billable model:

    /**
     * Get the customer's email address to associate with Paddle.
     *
     * @return string|null
     */
    public function paddleEmail()
    {
        return $this->email;
    }

    /**
     * Get the customer's country to associate with Paddle.
     *
     * This needs to be a 2 letter code. See the link below for supported countries.
     *
     * @return string|null
     * @link https://developer.paddle.com/reference/platform-parameters/supported-countries
     */
    public function paddleCountry()
    use Illuminate\Http\Request;
        //
    Route::get('/user/subscribe', function (Request $request) {
        $payLink = $user->newSubscription('default', $premium = 12345)
            ->returnTo(route('home'))
            ->create();
     * Get the customer's postal code to associate with Paddle.
        return view('billing', ['payLink' => $payLink]);
    });
     * See the link below for countries which require this.
     *
     * @return string|null
The `create` method will create a pay link which you can use to generate a payment button. The payment button can be generated using the `paddle-button` [Blade component](/docs/{{version}}/blade#components) that is included with Cashier Paddle:
     */
```html
<x-paddle-button :url="$payLink" class="px-8 py-4">
    Subscribe
</x-paddle-button>
```
    }

These defaults will be used for every action in Cashier that generates a [pay link](#pay-links).

<a name="subscriptions"></a>
## Subscriptions
If you would like to specify additional customer or subscription details, you may do so by passing them as an array of key / value pairs to the `create` method. To learn more about the additional fields supported by Paddle, check out Paddle's documentation on [generating pay links](https://developer.paddle.com/api-reference/product-api/pay-links/createpaylink):
<a name="creating-subscriptions"></a>
### Creating Subscriptions

To create a subscription, first retrieve an instance of your billable model, which typically will be an instance of `App\Models\User`. Once you have retrieved the model instance, you may use the `newSubscription` method to create the model's subscription pay link:

    use Illuminate\Http\Request;

            ->returnTo(route('home'))
            ->create();

        return view('billing', ['payLink' => $payLink]);
    });

The first argument passed to the `newSubscription` method should be the name of the subscription. If your application only offers a single subscription, you might call this `default` or `primary`. The second argument is the specific plan the user is subscribing to. This value should correspond to the plan's identifier in Paddle. The `returnTo` method accepts a URL that your user will be redirected to after they successfully complete the checkout.

The `create` method will create a pay link which you can use to generate a payment button. The payment button can be generated using the `paddle-button` [Blade component](/docs/{{version}}/blade#components) that is included with Cashier Paddle:

```html
<x-paddle-button :url="$payLink" class="px-8 py-4">
    Subscribe
</x-paddle-button>
```

After the user has finished their checkout, a `subscription_created` webhook will be dispatched from Paddle. Cashier will receive this webhook and setup the subscription for your customer. In order to make sure all webhooks are properly received and handled by your application, ensure you have properly [setup webhook handling](#handling-paddle-webhooks).

<a name="additional-details"></a>
#### Additional Details

If you would like to specify additional customer or subscription details, you may do so by passing them as an array of key / value pairs to the `create` method. To learn more about the additional fields supported by Paddle, check out Paddle's documentation on [generating pay links](https://developer.paddle.com/api-reference/product-api/pay-links/createpaylink):

    $payLink = $user->newSubscription('default', $monthly = 12345)
        ->returnTo(route('home'))
        ->create([
            'vat_number' => $vatNumber,
        ]);

<a name="subscriptions-coupons"></a>
#### Coupons

If you would like to apply a coupon when creating the subscription, you may use the `withCoupon` method:
    <?php

    namespace App\Http\Middleware;

    use Closure;

    class EnsureUserIsSubscribed
    $payLink = $user->newSubscription('default', $monthly = 12345)
        /**
         * Handle an incoming request.
         *
         * @param  \Illuminate\Http\Request  $request
         * @param  \Closure  $next
         * @return mixed
         */
        public function handle($request, Closure $next)
        {
            if ($request->user() && ! $request->user()->subscribed('default')) {
                // This user is not a paying customer...
                return redirect('billing');
            }
<a name="metadata"></a>
            return $next($request)
        }

You can also pass an array of metadata using the `withMetadata` method:
If you would like to determine if a user is still within their trial period, you may use the `onTrial` method. This method can be useful for determining if you should display a warning to the user that they are still on their trial period:
    $payLink = $user->newSubscription('default', $monthly = 12345)
        ->returnTo(route('home'))
        ->withMetadata(['key' => 'value'])
        ->create();

> {note} When providing metadata, please avoid using `subscription_name` as a metadata key. This key is reserved for internal use by Cashier.

<a name="checking-subscription-status"></a>
### Checking Subscription Status

Once a user is subscribed to your application, you may check their subscription status using a variety of convenient methods. First, the `subscribed` method returns `true` if the user has an active subscription, even if the subscription is currently within its trial period:

    if ($user->subscribed('default')) {
        //
    }

The `subscribed` method also makes a great candidate for a [route middleware](/docs/{{version}}/middleware), allowing you to filter access to routes and controllers based on the user's subscription status:

    <?php

    namespace App\Http\Middleware;

    use Closure;

    class EnsureUserIsSubscribed
    {
To determine if the user was once an active subscriber but has cancelled their subscription, you may use the `cancelled` method:
         * Handle an incoming request.
         *
         * @param  \Illuminate\Http\Request  $request
         * @param  \Closure  $next
         * @return mixed
         */
        public function handle($request, Closure $next)
        {
            if ($request->user() && ! $request->user()->subscribed('default')) {
                // This user is not a paying customer...
                return redirect('billing');
            }

            return $next($request)
        }
    }

<a name="past-due-status"></a>
#### Past Due Status

If a payment fails for a subscription, it will be marked as `past_due`. When your subscription is in this state it will not be active until the customer has updated their payment information. You may determine if a subscription is past due using the `pastDue` method on the subscription instance:

    if ($user->subscription('default')->pastDue()) {
        //
    }

When a subscription is past due, you should instruct the user to [update their payment information](#updating-payment-information). You may configure how past due subscriptions are handled in your [Paddle subscription settings](https://vendors.paddle.com/subscription-settings).

If you would like subscriptions to still be considered active when they are `past_due`, you may use the `keepPastDueSubscriptionsActive` method provided by Cashier. Typically, this method should be called in the `register` method of your `AppServiceProvider`:

    use Laravel\Paddle\Cashier;

    /**
     * Register any application services.
     *
     * @return void
     */
    public function register()
    {
        Cashier::keepPastDueSubscriptionsActive();
    }

> {note} When a subscription is in a `past_due` state it cannot be changed until payment information has been updated. Therefore, the `swap` and `updateQuantity` methods will throw an exception when the subscription is in a `past_due` state.

If you would like to determine if a user is still within their trial period, you may use the `onTrial` method. This method can be useful for determining if you should display a warning to the user that they are still on their trial period:

    if ($user->subscription('default')->onTrial()) {
        //
    }

The `subscribedToPlan` method may be used to determine if the user is subscribed to a given plan based on a given Paddle plan ID. In this example, we will determine if the user's `default` subscription is actively subscribed to the monthly plan:

    if ($user->subscribedToPlan($monthly = 12345, 'default')) {
        //
    }

By passing an array to the `subscribedToPlan` method, you may determine if the user's `default` subscription is actively subscribed to the monthly or the yearly plan:

    if ($user->subscribedToPlan([$monthly = 12345, $yearly = 54321], 'default')) {
        //
    }

The `recurring` method may be used to determine if the user is currently subscribed and is no longer within their trial period:

    if ($user->subscription('default')->recurring()) {
        //
    }

<a name="cancelled-subscription-status"></a>
#### Cancelled Subscription Status

To determine if the user was once an active subscriber but has cancelled their subscription, you may use the `cancelled` method:

If you would like subscriptions to still be considered active when they are `past_due`, you may use the `keepPastDueSubscriptionsActive` method provided by Cashier. Typically, this method should be called in the `register` method of your `AppServiceProvider`:

    use Laravel\Paddle\Cashier;

    /**
     * Register any application services.
In contrast to [single charges](#single-charges), this method will immediately charge the customer's stored payment method for the subscription. The charge amount should always be defined in the currency of the subscription.
     * @return void
     */
    public function register()
    {
        Cashier::keepPastDueSubscriptionsActive();
    }
    use App\Models\User;

    $user = User::find(1);
> {note} When a subscription is in a `past_due` state it cannot be changed until payment information has been updated. Therefore, the `swap` and `updateQuantity` methods will throw an exception when the subscription is in a `past_due` state.

<a name="subscription-scopes"></a>
#### Subscription Scopes

```html
<x-paddle-button :url="$updateUrl" class="px-8 py-4">
    Update Card
</x-paddle-button>
```
    $subscriptions = Subscription::query()->active()->get();

    // Get all of the cancelled subscriptions for a user...
    $subscriptions = $user->subscriptions()->cancelled()->get();

A complete list of available scopes is available below:
After a user has subscribed to your application, they may occasionally want to change to a new subscription plan. To update the subscription plan for a user, you should pass the Paddle plan's identifier to the subscription's `swap` method:
    Subscription::query()->active();
    use App\Models\User;

    $user = User::find(1);
    Subscription::query()->notOnTrial();
    Subscription::query()->pastDue();
    Subscription::query()->recurring();
If the user is on a trial, the trial period will be maintained. Also, if a "quantity" exists for the subscription, that quantity will also be maintained.
    Subscription::query()->paused();
    Subscription::query()->notPaused();
    Subscription::query()->onPausedGracePeriod();
    Subscription::query()->notOnPausedGracePeriod();
    Subscription::query()->cancelled();
    Subscription::query()->notCancelled();
    Subscription::query()->onGracePeriod();
    Subscription::query()->notOnGracePeriod();

    $user = User::find(1);
### Subscription Single Charges

Subscription single charges allow you to charge subscribers with a one-time charge on top of their subscriptions:

    $response = $user->subscription('default')->charge(12.99, 'Support Add-on');

In contrast to [single charges](#single-charges), this method will immediately charge the customer's stored payment method for the subscription. The charge amount should always be defined in the currency of the subscription.

<a name="updating-payment-information"></a>
### Updating Payment Information

Paddle always saves a payment method per subscription. If you want to update the default payment method for a subscription, you should first generate a subscription "update URL" using the `updateUrl` method on the subscription model:

Sometimes subscriptions are affected by "quantity". For example, a project management application might charge $10 per month per project. To easily increment or decrement your subscription's quantity, use the `incrementQuantity` and `decrementQuantity` methods:

    $user = User::find(1);

    $updateUrl = $user->subscription('default')->updateUrl();

Then, you may use the generated URL in combination with Cashier's provided `paddle-button` Blade component to allow the user to initiate the Paddle widget and update their payment information:

```html
<x-paddle-button :url="$updateUrl" class="px-8 py-4">
    Update Card
    // Subtract five from the subscription's current quantity...
```

When a user has finished updating their information, a `subscription_updated` webhook will be dispatched by Paddle and the subscription details will be updated in your application's database.

<a name="changing-plans"></a>
### Changing Plans

After a user has subscribed to your application, they may occasionally want to change to a new subscription plan. To update the subscription plan for a user, you should pass the Paddle plan's identifier to the subscription's `swap` method:

    use App\Models\User;

    $user = User::find(1);

    $user->subscription('default')->swap($premium = 34567);

If the user is on a trial, the trial period will be maintained. Also, if a "quantity" exists for the subscription, that quantity will also be maintained.

When a subscription is paused, Cashier will automatically set the `paused_from` column in your database. This column is used to know when the `paused` method should begin returning `true`. For example, if a customer pauses a subscription on March 1st, but the subscription was not scheduled to recur until March 5th, the `paused` method will continue to return `false` until March 5th. This is done because a user is typically allowed to continue using an application until the end of their billing cycle.

    $user->subscription('default')
            ->skipTrial()
            ->swap($premium = 34567);

If you would like to swap plans and immediately invoice the user instead of waiting for their next billing cycle, you may use the `swapAndInvoice` method:

    $user = User::find(1);

    $user->subscription('default')->swapAndInvoice($premium = 34567);

<a name="prorations"></a>
#### Prorations

By default, Paddle prorates charges when swapping between plans. The `noProrate` method may be used to update the subscription's without prorating the charges:

    $user->subscription('default')->noProrate()->swap($premium = 34567);

<a name="subscription-quantity"></a>
### Subscription Quantity
When a subscription is cancelled, Cashier will automatically set the `ends_at` column in your database. This column is used to know when the `subscribed` method should begin returning `false`. For example, if a customer cancels a subscription on March 1st, but the subscription was not scheduled to end until March 5th, the `subscribed` method will continue to return `true` until March 5th. This is done because a user is typically allowed to continue using an application until the end of their billing cycle.
Sometimes subscriptions are affected by "quantity". For example, a project management application might charge $10 per month per project. To easily increment or decrement your subscription's quantity, use the `incrementQuantity` and `decrementQuantity` methods:

    $user = User::find(1);

    $user->subscription('default')->incrementQuantity();

    // Add five to the subscription's current quantity...
    $user->subscription('default')->incrementQuantity(5);

    $user->subscription('default')->decrementQuantity();

    // Subtract five from the subscription's current quantity...
    $user->subscription('default')->decrementQuantity(5);

Alternatively, you may set a specific quantity using the `updateQuantity` method:

    $user->subscription('default')->updateQuantity(10);

The `noProrate` method may be used to update the subscription's quantity without prorating the charges:

    $user->subscription('default')->noProrate()->updateQuantity(10);

<a name="pausing-subscriptions"></a>
    use Illuminate\Http\Request;

    Route::get('/user/subscribe', function (Request $request) {
        $payLink = $request->user()->newSubscription('default', $monthly = 12345)
                    ->returnTo(route('home'))
                    ->trialDays(10)
                    ->create();
When a subscription is paused, Cashier will automatically set the `paused_from` column in your database. This column is used to know when the `paused` method should begin returning `true`. For example, if a customer pauses a subscription on March 1st, but the subscription was not scheduled to recur until March 5th, the `paused` method will continue to return `false` until March 5th. This is done because a user is typically allowed to continue using an application until the end of their billing cycle.
        return view('billing', ['payLink' => $payLink]);
    });
You may determine if a user has paused their subscription but are still on their "grace period" using the `onPausedGracePeriod` method:
This method will set the trial period ending date on the subscription record within your application's database, as well as instruct Paddle to not begin billing the customer until after this date.
    if ($user->subscription('default')->onPausedGracePeriod()) {
        //
    }
You may determine if the user is within their trial period using either the `onTrial` method of the user instance or the `onTrial` method of the subscription instance. The two examples below are equivalent:
To resume a paused a subscription, you may call the `unpause` method on the user's subscription:

    $user->subscription('default')->unpause();

> {note} A subscription cannot be modified while it is paused. If you want to swap to a different plan or update quantities you must resume the subscription first.

<a name="cancelling-subscriptions"></a>
### Cancelling Subscriptions

To cancel a subscription, call the `cancel` method on the user's subscription:

    $user->subscription('default')->cancel();

When a subscription is cancelled, Cashier will automatically set the `ends_at` column in your database. This column is used to know when the `subscribed` method should begin returning `false`. For example, if a customer cancels a subscription on March 1st, but the subscription was not scheduled to end until March 5th, the `subscribed` method will continue to return `true` until March 5th. This is done because a user is typically allowed to continue using an application until the end of their billing cycle.

You may determine if a user has cancelled their subscription but are still on their "grace period" using the `onGracePeriod` method:

    if ($user->subscription('default')->onGracePeriod()) {
        //
    use App\Models\User;

    }
        // ...
If you wish to cancel a subscription immediately, you may call the `cancelNow` method on the user's subscription:

    $user->subscription('default')->cancelNow();

> {note} Paddle's subscriptions cannot be resumed after cancellation. If your customer wishes to resume their subscription, they will have to subscribe to a new subscription.

<a name="subscription-trials"></a>
## Subscription Trials

<a name="with-payment-method-up-front"></a>
### With Payment Method Up Front

> {note} While trialing and collecting payment method details up front, Paddle prevents any subscription changes such as swapping plans or updating quantities. If you want to allow a customer to swap plans during a trial the subscription must be cancelled and recreated.

    use Illuminate\Http\Request;

    Route::get('/user/subscribe', function (Request $request) {
        $payLink = $user->newSubscription('default', $monthly = 12345)
            ->returnTo(route('home'))
            ->create();

        return view('billing', ['payLink' => $payLink]);
    });
        $payLink = $request->user()->newSubscription('default', $monthly = 12345)
                    ->returnTo(route('home'))
                    ->trialDays(10)
                    ->create();

        return view('billing', ['payLink' => $payLink]);
    });
You may use the `onGenericTrial` method if you wish to know specifically that the user is within their "generic" trial period and has not created an actual subscription yet:
This method will set the trial period ending date on the subscription record within your application's database, as well as instruct Paddle to not begin billing the customer until after this date.

> {note} If the customer's subscription is not cancelled before the trial ending date they will be charged as soon as the trial expires, so you should be sure to notify your users of their trial ending date.

You may determine if the user is within their trial period using either the `onTrial` method of the user instance or the `onTrial` method of the subscription instance. The two examples below are equivalent:

    if ($user->onTrial('default')) {
        //
    }

Paddle can notify your application of a variety of events via webhooks. By default, a route that points to Cashier's webhook controller is registered by the Cashier service provider. This controller will handle all incoming webhook requests.
        //
By default, this controller will automatically handle cancelling subscriptions that have too many failed charges ([as defined by your Paddle subscription settings](https://vendors.paddle.com/subscription-settings)), subscription updates, and payment method changes; however, as we'll soon discover, you can extend this controller to handle any Paddle webhook event you like.

To ensure your application can handle Paddle webhooks, be sure to [configure the webhook URL in the Paddle control panel](https://vendors.paddle.com/alerts-webhooks). By default, Cashier's webhook controller responds to the `/paddle/webhook` URL path. The full list of all webhooks you should enable in the Paddle control panel are:
You may choose to define how many trial days your plan's receive in the Paddle dashboard or always pass them explicitly using Cashier. If you choose to define your plan's trial days in Paddle you should be aware that new subscriptions, including new subscriptions for a customer that had a subscription in the past, will always receive a trial period unless you explicitly call the `trialDays(0)` method.

<a name="without-payment-method-up-front"></a>
### Without Payment Method Up Front

If you would like to offer trial periods without collecting the user's payment method information up front, you may set the `trial_ends_at` column on the customer record attached to your user to your desired trial ending date. This is typically done during user registration:

    use App\Models\User;

    $user = User::create([
        // ...
    ]);
Since Paddle webhooks need to bypass Laravel's [CSRF protection](/docs/{{version}}/csrf), be sure to list the URI as an exception in your `App\Http\Middleware\VerifyCsrfToken` middleware or list the route outside of the `web` middleware group:
    $user->createAsCustomer([
        'trial_ends_at' => now()->addDays(10)
    ]);

Cashier refers to this type of trial as a "generic trial", since it is not attached to any existing subscription. The `onTrial` method on the `User` instance will return `true` if the current date is not past the value of `trial_ends_at`:

    if ($user->onTrial()) {
        // User is within their trial period...
Cashier automatically handles subscription cancellation on failed charges and other common Paddle webhooks, but if you have additional webhook events you would like to handle, you should extend Cashier's `WebhookController`.

Your controller's method names should correspond to Cashier's controller method conventions. Specifically, methods should be prefixed with `handle` and the "camel case" name of the webhook you wish to handle. For example, if you wish to handle the `payment_succeeded` webhook, you should add a `handlePaymentSucceeded` method to the controller:

Once you are ready to create an actual subscription for the user, you may use the `newSubscription` method as usual:

    use Illuminate\Http\Request;

    Route::get('/user/subscribe', function (Request $request) {
        $payLink = $user->newSubscription('default', $monthly = 12345)
            ->returnTo(route('home'))
            ->create();

        return view('billing', ['payLink' => $payLink]);
    });

To retrieve the user's trial ending date, you may use the `trialEndsAt` method. This method will return a Carbon date instance if a user is on a trial or `null` if they aren't. You may also pass an optional subscription name parameter if you would like to get the trial ending date for a specific subscription other than the default one:

    if ($user->onTrial()) {
        $trialEndsAt = $user->trialEndsAt('main');
            // Handle the event...

You may use the `onGenericTrial` method if you wish to know specifically that the user is within their "generic" trial period and has not created an actual subscription yet:

Next, define a route to your Cashier webhook controller within your application's `routes/web.php` file. This will overwrite the default route registered by Cashier's service provider:
        // User is within their "generic" trial period...
    }

    Route::post('/paddle/webhook', WebhookController::class);

<a name="handling-paddle-webhooks"></a>
## Handling Paddle Webhooks

Paddle can notify your application of a variety of events via webhooks. By default, a route that points to Cashier's webhook controller is registered by the Cashier service provider. This controller will handle all incoming webhook requests.

- `Laravel\Paddle\Events\PaymentSucceeded`
- `Laravel\Paddle\Events\SubscriptionPaymentSucceeded`
- `Laravel\Paddle\Events\SubscriptionCreated`
- `Laravel\Paddle\Events\SubscriptionUpdated`
- `Laravel\Paddle\Events\SubscriptionCancelled`
- Subscription Updated
- Subscription Cancelled
You can also override the default, built-in webhook route by defining the `CASHIER_WEBHOOK` environment variable in your application's `.env` file. This value should be the full URL to your webhook route and needs to match the URL set in your Paddle control panel:
- Subscription Payment Succeeded
```bash
CASHIER_WEBHOOK=https://example.com/my-paddle-webhook-url
```
Since Paddle webhooks need to bypass Laravel's [CSRF protection](/docs/{{version}}/csrf), be sure to list the URI as an exception in your `App\Http\Middleware\VerifyCsrfToken` middleware or list the route outside of the `web` middleware group:

    protected $except = [
        'paddle/*',
    ];

To enable webhook verification, ensure that the `PADDLE_PUBLIC_KEY` environment variable is defined in your application's `.env` file. The public key may be retrieved from your Paddle account dashboard.
### Defining Webhook Event Handlers

Cashier automatically handles subscription cancellation on failed charges and other common Paddle webhooks, but if you have additional webhook events you would like to handle, you should extend Cashier's `WebhookController`.

Your controller's method names should correspond to Cashier's controller method conventions. Specifically, methods should be prefixed with `handle` and the "camel case" name of the webhook you wish to handle. For example, if you wish to handle the `payment_succeeded` webhook, you should add a `handlePaymentSucceeded` method to the controller:

    <?php
If you would like to make a one-time charge against a customer, you may use the `charge` method on a billable model instance to generate a pay link for the charge. The `charge` method accepts the charge amount (float) as its first argument and a charge description as its second argument:
    namespace App\Http\Controllers;
    use Illuminate\Http\Request;
    use Laravel\Paddle\Http\Controllers\WebhookController as CashierController;
    Route::get('/store', function (Request $request) {
        return view('store', [
            'payLink' => $user->charge(12.99, 'Action Figure')
        ]);
    });
    class WebhookController extends CashierController
    {
        /**
```html
<x-paddle-button :url="$payLink" class="px-8 py-4">
    Buy
</x-paddle-button>
```
         * @return void
         */
        public function handlePaymentSucceeded($payload)
    $payLink = $user->charge(12.99, 'Action Figure', [
            // Handle the event...
        }
    }
Charges happen in the currency specified in the `cashier.currency` configuration option. By default, this is set to USD. You may override the default currency by defining the `CASHIER_CURRENCY` environment variable in your application's `.env` file:
Next, define a route to your Cashier webhook controller within your application's `routes/web.php` file. This will overwrite the default route registered by Cashier's service provider:
```bash
CASHIER_CURRENCY=EUR
```
    use App\Http\Controllers\WebhookController;

    Route::post('/paddle/webhook', WebhookController::class);

Cashier emits a `Laravel\Paddle\Events\WebhookReceived` event when a webhook is received and a `Laravel\Paddle\Events\WebhookHandled` event when a webhook was handled. Both events contain the full payload of the Paddle webhook.

    ], 'Action Figure');

<div class="content-list" markdown="1">
- `Laravel\Paddle\Events\PaymentSucceeded`
- `Laravel\Paddle\Events\SubscriptionPaymentSucceeded`
If you would like to make a one-time charge against a specific product configured within Paddle, you may use the `chargeProduct` method on a billable model instance to generate a pay link:
- `Laravel\Paddle\Events\SubscriptionUpdated`
    use Illuminate\Http\Request;
</div>
    Route::get('/store', function (Request $request) {
        return view('store', [
            'payLink' => $request->user()->chargeProduct($productId = 123)
        ]);
    });
You can also override the default, built-in webhook route by defining the `CASHIER_WEBHOOK` environment variable in your application's `.env` file. This value should be the full URL to your webhook route and needs to match the URL set in your Paddle control panel:

```bash
```html
<x-paddle-button :url="$payLink" class="px-8 py-4">
    Buy
</x-paddle-button>
```
<a name="verifying-webhook-signatures"></a>
### Verifying Webhook Signatures

To secure your webhooks, you may use [Paddle's webhook signatures](https://developer.paddle.com/webhook-reference/verifying-webhooks). For convenience, Cashier automatically includes a middleware which validates that the incoming Paddle webhook request is valid.

To enable webhook verification, ensure that the `PADDLE_PUBLIC_KEY` environment variable is defined in your application's `.env` file. The public key may be retrieved from your Paddle account dashboard.

<a name="single-charges"></a>
## Single Charges

If you need to refund a Paddle order, you may use the `refund` method. This method accepts the Paddle order ID as its first argument. You may retrieve the receipts for a given billable model using the `receipts` method:

    use App\Models\User;

    $user = User::find(1);
### Simple Charge

If you would like to make a one-time charge against a customer, you may use the `charge` method on a billable model instance to generate a pay link for the charge. The `charge` method accepts the charge amount (float) as its first argument and a charge description as its second argument:

    use Illuminate\Http\Request;
You may optionally specify a specific amount to refund as well as a reason for the refund:
    Route::get('/store', function (Request $request) {
        return view('store', [
            'payLink' => $user->charge(12.99, 'Action Figure')
        ]);
    });

After generating the pay link, you may use Cashier's provided `paddle-button` Blade component to allow the user to initiate the Paddle widget and complete the charge:

```html
<x-paddle-button :url="$payLink" class="px-8 py-4">
    Buy
</x-paddle-button>
```

    use App\Models\User;

    $user = User::find(1);

The `charge` method accepts an array as its third argument, allowing you to pass any options you wish to the underlying Paddle pay link creation. Please consult [the Paddle documentation](https://developer.paddle.com/api-reference/product-api/pay-links/createpaylink) to learn more about the options available to you when creating charges:

When listing the receipts for the customer, you may use the receipt instance's methods to display the relevant receipt information. For example, you may wish to list every receipt in a table, allowing the user to easily download any of the receipts:
        'custom_option' => $value,
```html
<table>
    @foreach ($receipts as $receipt)
        <tr>
            <td>{{ $receipt->paid_at->toFormattedDateString() }}</td>
            <td>{{ $receipt->amount() }}</td>
            <td><a href="{{ $receipt->receipt_url }}" target="_blank">Download</a></td>
        </tr>
    @endforeach
</table>
```

    $payLink = $user->charge([
        'USD:19.99',
        'EUR:15.99',
You may use the `lastPayment` and `nextPayment` methods to retrieve and display a customer's past or upcoming payments for recurring subscriptions:

    use App\Models\User;

    $user = User::find(1);

<a name="charging-products"></a>
### Charging Products

If you would like to make a one-time charge against a specific product configured within Paddle, you may use the `chargeProduct` method on a billable model instance to generate a pay link:

    use Illuminate\Http\Request;

    Route::get('/store', function (Request $request) {
        return view('store', [
            'payLink' => $request->user()->chargeProduct($productId = 123)
        ]);
    });

Then, you may provide the pay link to the `paddle-button` component to allow the user to initialize the Paddle widget:

```html
<x-paddle-button :url="$payLink" class="px-8 py-4">
    Buy
</x-paddle-button>
```

The `chargeProduct` method accepts an array as its second argument, allowing you to pass any options you wish to the underlying Paddle pay link creation. Please consult [the Paddle documentation](https://developer.paddle.com/api-reference/product-api/pay-links/createpaylink) regarding the options that are available to you when creating charges:

    $payLink = $user->chargeProduct($productId, [
        'custom_option' => $value,
    ]);

<a name="refunding-orders"></a>
### Refunding Orders

If you need to refund a Paddle order, you may use the `refund` method. This method accepts the Paddle order ID as its first argument. You may retrieve the receipts for a given billable model using the `receipts` method:

    use App\Models\User;

    $user = User::find(1);

    $receipt = $user->receipts()->first();

    $refundRequestId = $user->refund($receipt->order_id);

You may optionally specify a specific amount to refund as well as a reason for the refund:

    $receipt = $user->receipts()->first();

    $refundRequestId = $user->refund(
        $receipt->order_id, 5.00, 'Unused product time'
    );

> {tip} You can use the `$refundRequestId` as a reference for the refund when contacting Paddle support.

<a name="receipts"></a>
## Receipts

You may easily retrieve an array of a billable model's receipts using the `receipts` method:

    use App\Models\User;

    $user = User::find(1);

    $receipts = $user->receipts();

When listing the receipts for the customer, you may use the receipt instance's methods to display the relevant receipt information. For example, you may wish to list every receipt in a table, allowing the user to easily download any of the receipts:

```html
<table>
    @foreach ($receipts as $receipt)
        <tr>
            <td>{{ $receipt->paid_at->toFormattedDateString() }}</td>
            <td>{{ $receipt->amount() }}</td>
            <td><a href="{{ $receipt->receipt_url }}" target="_blank">Download</a></td>
        </tr>
    @endforeach
</table>
```

<a name="past-and-upcoming-payments"></a>
### Past & Upcoming Payments

You may use the `lastPayment` and `nextPayment` methods to retrieve and display a customer's past or upcoming payments for recurring subscriptions:

    use App\Models\User;

    $user = User::find(1);

    $subscription = $user->subscription('default');

    $lastPayment = $subscription->lastPayment();
    $nextPayment = $subscription->nextPayment();

Both of these methods will return an instance of `Laravel\Paddle\Payment`; however, `nextPayment` will return `null` when the billing cycle has ended (such as when a subscription has been cancelled):

    Next payment: {{ $nextPayment->amount() }} due on {{ $nextPayment->date()->format('d/m/Y') }}

<a name="handling-failed-payments"></a>
## Handling Failed Payments

Subscription payments fail for various reasons, such as expired cards or a card having insufficient funds. When this happens, we recommend that you let Paddle handle payment failures for you. Specifically, you may [setup Paddle's automatic billing emails](https://vendors.paddle.com/subscription-settings) in your Paddle dashboard.

Alternatively, you can perform more precise customization by catching the [`subscription_payment_failed`](https://developer.paddle.com/webhook-reference/subscription-alerts/subscription-payment-failed) webhook and enabling the "Subscription Payment Failed" option in the Webhook settings of your Paddle dashboard:

    <?php

    namespace App\Http\Controllers;

    use Laravel\Paddle\Http\Controllers\WebhookController as CashierController;

    class WebhookController extends CashierController
    {
        /**
         * Handle subscription payment failed.
         *
         * @param  array  $payload
         * @return void
         */
        public function handleSubscriptionPaymentFailed($payload)
        {
            // Handle the failed subscription payment...
        }
    }

<a name="testing"></a>
## Testing

Paddle currently lacks a proper CRUD API so you will need to manually test your billing flow. Paddle also lacks a sandboxed developer environment so any card charges you make are live charges. In order to work around this, we recommend you use coupons with a 100% discount or free products during testing.
