# アセットのコンパイル（Mix）

- [イントロダクション](#introduction)
- [インストールと準備](#installation)
- [Mixの実行](#running-mix)
- [スタイルシートの操作](#working-with-stylesheets)
    - [Tailwind CSS](#tailwindcss)
    - [PostCSS](#postcss)
    - [Sass](#sass)
    - [URL処理](#url-processing)
    - [ソースマップ](#css-source-maps)
- [JavaScriptの操作](#working-with-scripts)
    - [Vue](#vue)
    - [React](#react)
    - [ベンダーの抽出](#vendor-extraction)
    - [Webpackカスタム設定](#custom-webpack-configuration)
- [バージョニング／キャッシュの破棄](#versioning-and-cache-busting)
- [Browsersyncによるリロード](#browsersync-reloading)
- [環境変数](#environment-variables)
- [通知](#notifications)

<a name="introduction"></a>
## イントロダクション

[Laravel Mix](https://github.com/JeffreyWay/laravel-mix)は、[Laracasts](https://laracasts.com)を作ったJeffrey Wayが開発したパッケージで、[webpack](https://webpack.js.org)を定義するためスラスラと書けるAPIを提供しています。多くの一般的なCSSおよびJavaScriptプリプロセッサを使用してLaravelアプリケーションのビルドステップを定義します。

言い換えると、Mixを使用すると、アプリケーションのCSSファイルとJavaScriptファイルを簡単にコンパイルして圧縮できます。シンプルなメソッドチェーンにより、アセットパイプラインを流暢に定義できます。例をご覧ください。

    mix.js('resources/js/app.js', 'public/js')
        .postCss('resources/css/app.css', 'public/css');

Webpackとアセットのコンパイルを使い始めようとして混乱し圧倒されたことがある方は、Laravel　Mixを気に入ってくれるでしょう。ただし、アプリケーションの開発に必ず使用する必要はありません。お好きなアセットパイプラインツールを使用するも、まったく使用しないのも自由です。

> {tip} Laravelと[Tailwind CSS](https://tailwindcss.com)を使用してアプリケーションの構築を早急に開始する必要がある場合は、[アプリケーションスターターキット](/docs/{{version}}/starter-kits)のいずれかをチェックしてください。

<a name="installation"></a>
## インストールと準備

<a name="installing-node"></a>
#### Installing Node

Mixを実行する前に、まずNode.jsとNPMをマシンへ確実にインストールする必要があります。

    node -v
    npm -v

[Nodeの公式ウェブサイト](https://nodejs.org/en/download/)から簡単なグラフィカルインストーラを使用して、最新バージョンのNodeとNPMを簡単にインストールできます。または、[Laravel Sail](/docs/{{version}}/sale)を使用している場合は、Sailを介してNodeとNPMを呼び出すことができます。

    ./sail node -v
    ./sail npm -v

<a name="installing-laravel-mix"></a>
#### Laravel Mixのインストール

残りの唯一のステップは、Laravel Mixをインストールすることです。Laravelの新規インストールでは、ディレクトリ構造のルートに`package.json`ファイルがあります。デフォルトの`package.json`ファイルには、Laravel Mixの使用を開始するために必要なすべてのものがすでに含まれています。このファイルは、PHPの依存関係ではなくNodeの依存関係を定義することを除けば、`composer.json`ファイルと同じように考えてください。以下を実行して、参照する依存関係をインストールします。

    npm install

<a name="running-mix"></a>
## Mixの実行

Mixは[webpack](https://webpack.js.org)の上の設定レイヤーであるため、Mixタスクを実行するには、デフォルトのLaravel　`package.json`ファイルに含まれているNPMスクリプトの１つを実行するだけです。`dev`または`production`スクリプトを実行すると、アプリケーションのすべてのCSSおよびJavaScriptアセットがコンパイルされ、アプリケーションの`public`ディレクトリへ配置されます。

    // すべてのMixタスクを実行...
    npm run dev

    // すべてのMixタスクを実行し、出力を圧縮。
    npm run prod

<a name="watching-assets-for-changes"></a>
#### アセットの変更を監視

`npm run watch`コマンドはターミナルで実行され続け、関連するすべてのCSSファイルとJavaScriptファイルの変更を監視します。Webpackは、こうしたファイルのいずれか一つの変更を検出すると、アセットを自動的に再コンパイルします。

    npm run watch

Webpackは、特定のローカル開発環境でファイルの変更を検出できない場合があります。これがシステムに当てはまる場合は、`watch-poll`コマンドの使用を検討してください。

    npm run watch-poll

<a name="working-with-stylesheets"></a>
## スタイルシートの操作

アプリケーションの`webpack.mix.js`ファイルは、すべてのアセットをコンパイルするためのエントリポイントです。[webpack](https://webpack.js.org)の軽い設定ラッパーと考えてください。ミックスタスクをチェーン化して、アセットのコンパイル方法を正確に定義できます。

<a name="tailwindcss"></a>
### Tailwind CSS

[Tailwind CSS](https://tailwindcss.com)は、HTMLを離れることなく、すばらしいサイトを構築するための最新のユーティリティファーストフレームワークです。Laravel Mixを使用したLaravelプロジェクトでこれを使い始める方法を掘り下げてみましょう。まず、NPMを使用してTailwindをインストールし、Tailwind設定ファイルを生成する必要があります。

    npm install

    npm install -D tailwindcss

    npx tailwindcss init

`init`コマンドは`tailwind.config.js`ファイルを生成します。このファイル内で、アプリケーションのすべてのテンプレートとJavaScriptへのパスを設定して、CSSを本番用に最適化するときにTailwindが未使用のスタイルをツリーシェイクできるようにすることができます。

```js
purge: [
    './storage/framework/views/*.php',
    './resources/**/*.blade.php',
    './resources/**/*.js',
    './resources/**/*.vue',
],
```

次に、Tailwindの各「レイヤー」をアプリケーションの`resources/css/app.css`ファイルに追加する必要があります。

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

Tailwindのレイヤーを設定したら、アプリケーションの`webpack.mix.js`ファイルを更新して、Tailwindを利用したCSSをコンパイルする準備が整います。

```js
mix.js('resources/js/app.js', 'public/js')
    .postCss('resources/css/app.css', 'public/css', [
        require('tailwindcss'),
    ]);
```

最後に、アプリケーションのプライマリレイアウトテンプレートでスタイルシートを参照する必要があります。多くのアプリケーションは、このテンプレートを`resources/views/layouts/app.blade.php`に保存することを選択します。さらに、レスポンシブビューポートの`meta`タグがまだ存在しない場合は、必ず追加してください。

```html
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link href="/css/app.css" rel="stylesheet">
</head>
```

<a name="postcss"></a>
### PostCSS

[PostCSS](https://postcss.org/)は、CSSを変換するための強力なツールであり、Laravel Mixにはじめから含まれています。デフォルトで、Mixは人気のある[Autoprefixer](https://github.com/postcss/autoprefixer)プラグインを利用して、必要なすべてのCSS3ベンダープレフィックスを自動的に適用します。ただし、アプリケーションに適したプラグインを自由に追加できます。

まず、NPMを介して希望するプラグインをインストールし、Mixの`postCss`メソッドを呼び出すときにプラグインの配列に含めます。`postCss`メソッドは、CSSファイルへのパスを最初の引数に取り、コンパイルしたファイルを配置するディレクトリを２番目の引数に取ります。

    mix.postCss('resources/css/app.css', 'public/css', [
        require('postcss-custom-properties')
    ]);

または、単純なCSSのコンパイルと圧縮を実現するために、追加のプラグインなしで`postCss`を実行することもできます。

    mix.postCss('resources/css/app.css', 'public/css');

<a name="sass"></a>
### Sass

`sass`メソッドを使用すると、[Sass](https://sass-lang.com/)をWebブラウザで理解できるCSSにコンパイルできます。`sass`メソッドは、Sassファイルへのパスを最初の引数に取り、コンパイルしたファイルを配置するディレクトリを２番目の引数に取ります。

    mix.sass('resources/sass/app.scss', 'public/css');

複数のSassファイルをそれぞれのCSSファイルにコンパイルし、`sass`メソッドを複数回呼び出すことで、結果のCSSの出力ディレクトリをカスタマイズすることもできます。

    mix.sass('resources/sass/app.sass', 'public/css')
        .sass('resources/sass/admin.sass', 'public/css/admin');

<a name="url-processing"></a>
### URL処理

LaravelMixはwebpackの上に構築されているため、いくつかのwebpackの概念を理解することが重要です。CSSコンパイルの場合、webpackはスタイルシート内の`url()`呼び出しを書き直して最適化します。これは最初は奇妙に聞こえるかもしれませんが、信じられないほど強力な機能です。画像への相対URLを含むSassをコンパイルしたいとします。

    .example {
        background: url('../images/example.png');
    }

> {note} `url()`へ指定された絶対パスはURLの書き換えから除外されます。たとえば、`url('/images/thing.png')`または`url('http://example.com/images/thing.png')`は変更されません。

デフォルトでは、Laravel Mixとwebpackは`example.png`を見つけ、それを`public/images`フォルダにコピーしてから、生成されたスタイルシート内の`url()`を書き換えます。そのため、コンパイルされたCSSは次のようになります。

    .example {
        background: url(/images/example.png?d41d8cd98f00b204e9800998ecf8427e);
    }

この機能は便利かもしれませんが、皆さん既にお好みの方法でフォルダ構造を構成しているでしょう。この場合、次のように`url()`の書き換えを無効にすることができます。

    mix.sass('resources/sass/app.scss', 'public/css').options({
        processCssUrls: false
    });

この`webpack.mix.js`ファイルの変更により、Mixは`url()`と一致しなくなり、アセットをパブリックディレクトリにコピーしなくなります。つまり、コンパイルされたCSSは、最初に入力した方法と同じようになります。

    .example {
        background: url("../images/thing.png");
    }

<a name="css-source-maps"></a>
### ソースマップ

デフォルトでは無効になっていますが、ソースマップは`webpack.mix.js`ファイルの`mix.sourceMaps()`メソッドを呼び出すことでアクティブにできます。コンパイル／パフォーマンスのコストが伴いますが、これにより、コンパイルされたアセットを使用するときに、ブラウザの開発者ツールに追加のデバッグ情報が提供されます。

    mix.js('resources/js/app.js', 'public/js')
        .sourceMaps();

<a name="style-of-source-mapping"></a>
#### ソースマッピングのスタイル

Webpackは、さまざまな[ソースマッピングスタイル](https://webpack.js.org/configuration/devtool/#devtool)を提供しています。デフォルトでは、Mixのソースマッピングスタイルは`eval-source-map`に設定されており、これにより再構築時間が短縮されます。マッピングスタイルを変更したい場合は、`sourceMaps`メソッドを使用して変更できます。

    let productionSourceMaps = false;

    mix.js('resources/js/app.js', 'public/js')
        .sourceMaps(productionSourceMaps, 'source-map');

<a name="working-with-scripts"></a>
## JavaScriptの操作

Mixは、現代的なECMAScriptのコンパイル、モジュールのバンドル、圧縮、プレーンなJavaScriptファイルの連結など、JavaScriptファイルの操作に役立つの機能をいくつか提供します。さらに良いことに、これはすべてシームレスに機能し、大量のカスタム設定を必要としません。

    mix.js('resources/js/app.js', 'public/js');

この１行のコードで、次の利点を活用できます。

<div class="content-list" markdown="1">
- 最新のEcmaScript文法.
- モジュール
- 本番環境での圧縮
</div>

<a name="vue"></a>
### Vue

Mixは、`vue`メソッドを使用するときに、Vue単一ファイルコンポーネントのコンパイルサポートに必要なBabelプラグインを自動的にインストールします。これ以上の設定は必要ありません。

    mix.js('resources/js/app.js', 'public/js')
       .vue();

JavaScriptがコンパイルされたら、アプリケーションから参照できます。

```html
<head>
    <!-- ... -->

    <script src="/js/app.js"></script>
</head>
```

<a name="react"></a>
### React

MixはReactサポートに必要なBabelプラグインを自動的にインストールします。利用開始するには、`react`メソッドの呼び出しを追加してください。

    mix.js('resources/js/app.jsx', 'public/js')
       .react();

裏でMixは適切な`babel-preset-react` Babelプラグインをダウンロードして取り込みます。JavaScriptをコンパイルしたら、アプリケーションから参照できます。

```html
<head>
    <!-- ... -->

    <script src="/js/app.js"></script>
</head>
```

<a name="vendor-extraction"></a>
### ベンダーの抽出

アプリケーション固有のJavaScriptをすべてReactやVueなどのベンダーライブラリへバンドルすることの潜在的な欠点のひとつは、長期的なキャッシュが困難になることです。たとえば、アプリケーションコードを１回更新すると、変更されていない場合でも、ブラウザはすべてのベンダーライブラリを再ダウンロードする必要があります。

アプリケーションのJavaScriptを頻繁に更新する場合は、すべてのベンダーライブラリを独自のファイルに抽出することを検討する必要があります。この方法により、アプリケーションコードを変更しても、大きな`vendor.js`ファイルのキャッシュには影響しません。Mixの`extract`メソッドはこれを簡単にします:

    mix.js('resources/js/app.js', 'public/js')
        .extract(['vue'])

`extract`メソッドは、`vendor.js`ファイルに抽出したいすべてのライブラリまたはモジュールの配列を受け入れます。上記のスニペットを例として使用すると、Mixは次のファイルを生成します。

<div class="content-list" markdown="1">
- `public/js/manifest.js`: **Webpackマニフェストランタイム**
- `public/js/vendor.js`: **皆さんのvendorライブラリー**
- `public/js/app.js`: **皆さんのアプリケーションコード**
</div>

JavaScriptエラーを回避するため、以下のファイルを正しい順序でロードしてください。

    <script src="/js/manifest.js"></script>
    <script src="/js/vendor.js"></script>
    <script src="/js/app.js"></script>

<a name="custom-webpack-configuration"></a>
### Webpackカスタム設定

時折、ベースとなるWebpack設定を手動で変更する必要が起きるでしょう。たとえば、参照する必要がある特別なローダーまたはプラグインがある可能性があります。

Mixは、短いWebpack設定オーバーライドをマージできる便利な`webpackConfig`メソッドを提供します。これは、`webpack.config.js`ファイルの独自のコピーをコピーして維持する必要がないため、特に魅力的です。`webpackConfig`メソッドはオブジェクトを受け入れます。オブジェクトには、適用する[Webpack固有の設定](https://webpack.js.org/configuration/)が含まれている必要があります。

    mix.webpackConfig({
        resolve: {
            modules: [
                path.resolve(__dirname, 'vendor/laravel/spark/resources/assets/js')
            ]
        }
    });

<a name="versioning-and-cache-busting"></a>
## バージョニング／キャッシュの破棄

多くの開発者は、コンパイルしたアセットにタイムスタンプまたは一意のトークンの接尾辞を付けて、提供してきたコードの古くなったコピーの代わりに、ブラウザに新しいアセットをロードするように強制します。Mixは、`version`メソッドを使用してこれを自動的に処理できます。

`version`メソッドは、コンパイルしたすべてのファイルのファイル名に一意のハッシュを追加し、より便利なブラウザキャッシュ破棄を可能にしています。

    mix.js('resources/js/app.js', 'public/js')
        .version();

バージョン付きファイルを生成すると、正確なファイル名がわからなくなります。したがって、[views](/docs/{{version}}/views)内でLaravelのグローバルな`mix`関数を使用して、適切にハッシュされたアセットをロードする必要があります。`mix`関数は、ハッシュされたファイルの現在の名前を自動的に判別します。

    <script src="{{ mix('/js/app.js') }}"></script>

通常、バージョン付きファイルは開発では不要であるため、`npm run prod`の実行中にのみ実行するよう、バージョン付け処理に指示できます。

    mix.js('resources/js/app.js', 'public/js');

    if (mix.inProduction()) {
        mix.version();
    }

<a name="custom-mix-base-urls"></a>
#### カスタムMixベースURL

Mixでコンパイルされたアセットをアプリケーションとは別のCDNにデプロイする場合は、`mix`関数にが生成するベースURLを変更する必要があります。これには、アプリケーションの`config/app.php`設定ファイルに`mix_url`設定オプションを追加します。

    'mix_url' => env('MIX_ASSET_URL', null)

Mix URLを設定すると、以降はアセットへのURLを生成するときに、`mix`関数は設定したURLのプレフィックスを付けます。

```bash
https://cdn.example.com/js/app.js?id=1964becbdd96414518cd
```

<a name="browsersync-reloading"></a>
## Browsersyncによるリロード

[BrowserSync](https://browsersync.io/)は、ファイルの変更を自動的に監視し、手動で更新しなくても変更をブラウザに反映できます。`mix.browserSync()`メソッドを呼び出すことにより、これのサポートを有効にすることができます。

```js
mix.browserSync('laravel.test');
```

[BrowserSyncオプション](https://browsersync.io/docs/options)は、JavaScriptオブジェクトを`browserSync`メソッドに渡すことで指定できます。

```js
mix.browserSync({
    proxy: 'laravel.test'
});
```

次に、`npm run watch`コマンドを使用してwebpackの開発サーバを起動します。これで、スクリプトまたはPHPファイルを変更すると、ブラウザがページを即座に更新して、変更を反映するのを目にできるでしょう。

<a name="environment-variables"></a>
## 環境変数

`.env`ファイルの環境変数の1つに`MIX_`のプレフィックスを付けることで、環境変数を`webpack.mix.js`スクリプトに挿入できます。

    MIX_SENTRY_DSN_PUBLIC=http://example.com

変数を`.env`ファイルで定義したら、以降は`process.env`オブジェクトを介して変数へアクセスできます。ただし、タスクの実行中に環境変数の値が変更された場合は、タスクを再起動する必要があります。

    process.env.MIX_SENTRY_DSN_PUBLIC

<a name="notifications"></a>
## 通知

利用可能な場合、Mixはコンパイル時にＯＳ通知を自動的に表示し、コンパイルが成功したかを即座にフィードバックします。しかし、これらの通知を無効にしたい状況もあるでしょう。そのような例の１つは、本番サーバでMixをトリガーするときです。通知は、`disableNotifications`メソッドを使用して非アクティブ化できます。

    mix.disableNotifications();
