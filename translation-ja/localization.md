# 多言語化

- [イントロダクション](#introduction)
    - [ロケールの設定](#configuring-the-locale)
- [翻訳文字列の定義](#defining-translation-strings)
    - [短縮キーの使用](#using-short-keys)
    - [翻訳文字列のキー使用](#using-translation-strings-as-keys)
- [翻訳文字列の取得](#retrieving-translation-strings)
    - [翻訳文字列中のパラメータ置換](#replacing-parameters-in-translation-strings)
    - [複数形](#pluralization)
- [パッケージの言語ファイルのオーバーライド](#overriding-package-language-files)

<a name="introduction"></a>
## イントロダクション

Laravelのローカリゼーション機能はアプリケーションで多言語をサポートできるように、さまざまな言語の文字列を便利に取得できる方法を提供します。 言語の文字列は`resources/lang`ディレクトリ下のファイルに保存します。このディレクトリの中にアプリケーションでサポートする言語のディレクトリを設置します。

    /resources
        /lang
            /en
                messages.php
            /es
                messages.php

すべての言語ファイルはキーと文字列の配列をリターンします。例を見てください。

    <?php

    return [
        'welcome' => 'Welcome to our application',
    ];

> {note} 地域によって異なる言語では、ISO 15897に従った言語ディレクトリを名付けるべきでしょう。たとえば、ブリティッシュ・イングリッシュでは、"en-gb"の代わりに、"en_GB"を使用するべきです。

<a name="configuring-the-locale"></a>
### ロケールの設定

アプリケーションのデフォルト言語は`config/app.php`設定ファイルで指定します。この値はアプリケーションに合うように変更できます。さらに`App`ファサードの`setLocale`メソッドを使い、実行時にアクティブな言語を変更することもできます。

    Route::get('welcome/{locale}', function ($locale) {
        if (! in_array($locale, ['en', 'es', 'fr'])) {
            abort(400);
        }

        App::setLocale($locale);

        //
    });

現時点のロケールとして指定した言語の翻訳文字列が存在しない場合に使用される、「フォールバック言語」を設定することもできます。デフォルト言語と同様に、フォールバック言語も`config/app.php`設定ファイルで指定されます。

    'fallback_locale' => 'en',

<a name="determining-the-current-locale"></a>
#### 現在のロケール判定

現在のロケールを調べたり、特定のロケールであるかを判定したりするには、`App`ファサードの`getLocale`や`isLocale`を使います。

    $locale = App::getLocale();

    if (App::isLocale('en')) {
        //
    }

<a name="defining-translation-strings"></a>
## 翻訳文字列の定義

<a name="using-short-keys"></a>
### 短縮キーの使用

通常、翻訳文字列は`resources/lang`ディレクトリ下のファイルに保存されています。このディレクトリにはアプリケーションでサポートする各言語のサブディレクトリを用意します。

    /resources
        /lang
            /en
                messages.php
            /es
                messages.php

すべての言語ファイルはキーと文字列の配列をリターンします。例を見てください。

    <?php

    // resources/lang/en/messages.php

    return [
        'welcome' => 'Welcome to our application',
    ];

<a name="using-translation-strings-as-keys"></a>
### 翻訳文字列のキー使用

たくさんの翻訳が必要なアプリケーションでは、すべての文字列に「短いキー」を付けようとすると、ビューで参照する際、すぐにこんがらがってきます。そのため、Laravelでは翻訳文字列を「デフォルト」翻訳の文字列をキーとして利用できます。

翻訳文字列をキーとして使用する翻訳ファイルは、`resources/lang`ディレクトリ下にJSONファイルとして保存します。たとえば、アプリケーションにスペイン語の翻訳がある場合、`resources/lang/es.json`ファイルを作成します。

    {
        "I love programming.": "Me encanta programar."
    }

<a name="retrieving-translation-strings"></a>
## 翻訳文字列の取得

言語ファイルから行を取得するには、`__`ヘルパ関数を使用します。`__`メソッドは、最初の引数として翻訳文字列のファイルとキーを受け付けます。例として、`resources/lang/messages.php`原語ファイルから`welcome`翻訳文字列を取得してみましょう。

    echo __('messages.welcome');

    echo __('I love programming.');

[Bladeテンプレートエンジン](/docs/{{version}}/blade)を使用している場合は、`{{ }}`記法で翻訳文字列をechoするか、`@lang`ディレクティブを使用します。

    {{ __('messages.welcome') }}

    @lang('messages.welcome')

指定した翻訳文字列が存在しない場合、`__`関数は翻訳文字列キーをそのまま返します。そのため、上記の例で`__`関数は、翻訳文字列がない場合に`messages.welcome`を返します。

> {note} `@lang`ディレクティブは出力をまったくエスケープしません。このディレクティブ使用時の出力のエスケープは、**すべて皆さんの責任**です。

<a name="replacing-parameters-in-translation-strings"></a>
### 翻訳文字列中のパラメータ置換

お望みならば、翻訳文字列にプレースホルダを定義できます。全プレースホルダは`:`のプレフィックスを付けます。例として、welcomeメッセージにnameプレースホルダを定義してみましょう。

    'welcome' => 'Welcome, :name',

翻訳文字列を取得する時に、プレースホルダを置き換えるには、`__`関数の第２引数として、置換文字の配列を渡します。

    echo __('messages.welcome', ['name' => 'dayle']);

プレースホルダを全部大文字にするか、最初の一文字を大文字にすると、その方法に合わせて値が大文字に変換されます。

    'welcome' => 'Welcome, :NAME', // Welcome, DAYLE
    'goodbye' => 'Goodbye, :Name', // Goodbye, Dayle

<a name="pluralization"></a>
### 複数形化

複数形化は複雑な問題であり、異なった言語において多種複雑な複数形化のルールが存在しています。「パイプ」記号の縦線を使うことで、単数形の文字列と複数形の文字列を分けることができます。

    'apples' => 'There is one apple|There are many apples',

複数の範囲を翻訳行に指定することで、もっと便利な複数形化のルールも簡単に作成できます。

    'apples' => '{0} There are none|[1,19] There are some|[20,*] There are many',

複数形化オプションの翻訳文字列を定義したら、`trans_choice`関数に「数」を指定し、行を取得します。以下の例では数が１より大きので、複数形の翻訳行が返されます。

    echo trans_choice('messages.apples', 10);

複数形化の文字列の中でも、プレースホルダを定義可能です。プレースホルダは`trans_choice`関数の第３引数に配列として指定します。

    'minutes_ago' => '{1} :value minute ago|[2,*] :value minutes ago',

    echo trans_choice('time.minutes_ago', 5, ['value' => 5]);

`trans_choice`関数へ渡した整数値を表示したい場合は、`:count`プレースホルダを使用します。

    'apples' => '{0} There are none|{1} There is one|[2,*] There are :count',

<a name="overriding-package-language-files"></a>
## パッケージの言語ファイルのオーバーライド

いくつかのパッケージではそれ自身の言語ファイルが提供されています。出力される文言を調整するためパッケージのコアをハックする代わりに、`resources/lang/vendor/{パッケージ}/{ロケールコード}`ディレクトリにファイルを設置することで、オーバーライドできます。

たとえば`skyrim/hearthfire`という名前のパッケージが持っている`messages.php`の英語の翻訳行をオーバーライドする必要があるなら、`resources/lang/vendor/hearthfire/en/messages.php`に言語ファイルを設置します。このファイルには置き換えたい翻訳行の定義のみを設置できます。オーバーライドしなかった翻訳行は、パッケージのオリジナルな言語ファイル中の定義のままロードされます。
