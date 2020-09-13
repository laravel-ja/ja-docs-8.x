# JavaScriptとCSSスカフォールド

- [イントロダクション](#introduction)
- [CSSの出力](#writing-css)
- [JavaScriptの出力](#writing-javascript)
    - [Vueコンポーネントの出力](#writing-vue-components)
    - [Reactの使用](#using-react)
- [プリセットの追加](#adding-presets)

<a name="introduction"></a>
## イントロダクション

LaravelはJavaScriptやCSSプリプロセッサの使用を規定してはいませんが、開発時点の元としてほとんどのアプリケーションで役立つだろう[Bootstrap](https://getbootstrap.com)や[React](https://reactjs.org/)、[Vue](https://vuejs.org)を提供しています。これらのフロントエンドパッケージをインストールするため、Laravelは[NPM](https://www.npmjs.org)を使用しています。

Laravelが提供するBootstrapとVueのスカフォールドは、Composerを使いインストールする`laravel/ui`パッケージに用意してあります。

    composer require laravel/ui

`laravel/ui`パッケージをインストールできたら、`ui` Artisanコマンドを使いフロントエンドのスカフォールドをインストールします。

    // 基本的なスカフォールドを生成
    php artisan ui bootstrap
    php artisan ui vue
    php artisan ui react

    // ログイン／ユーザー登録スカフォールドを生成
    php artisan ui bootstrap --auth
    php artisan ui vue --auth
    php artisan ui react --auth

#### CSS

CSSをもっと楽しく取り扱うために役立つ、変数やmixinなどのパワフルな機能を通常のCSSへ付け加え、SASSとLESSをコンパイルするため、[Laravel Mix](/docs/{{version}}/mix)はクリーンで表現的なAPIを提供しています。このドキュメントでは、CSSコンパイル全般について簡単に説明します。SASSとLESSのコンパイルに関する情報は、[Laravel Mix documentation](/docs/{{version}}/mix)で確認してください。

#### JavaScript

アプリケーションを構築するために、特定のJavaScriptフレームワークやライブラリの使用をLaravelは求めていません。しかし、[Vue](https://vuejs.org)ライブラリを使用した近代的なJavaScriptを書き始めやすくできるように、基本的なスカフォールドを用意しています。Vueはコンポーネントを使った堅牢なJavaScriptアプリケーションを構築するために、記述的なAPIを提供しています。CSSに関しては、Laravel Mixを使用し、JavaScriptコンポーネントをブラウザでそのまま使用できる１ファイルへ、簡単に圧縮できます。

<a name="writing-css"></a>
## CSSの出力

`laravel/ui` Composerパッケージをインストールし、[フロントエンドスカフォールドを生成](#introduction)すると、Laravelの`package.json`ファイルに`bootstrap`パッケージが追加されます。これはBootstrapを使用したアプリケーションフロントエンドのプロトタイピングを開始する手助けになるからです。しかしながら、アプリケーションの必要に応じて、`package.json`への追加や削除は自由に行ってください。Bootstrapを選んでいる人には良いスタートポイントを提供しますが、Laravelアプリケーションを構築するために必須ではありません。

CSSのコンパイルを始める前に、プロジェクトのフロントエンド開発に必要な依存パッケージである、[Nodeプロジェクトマネージャー(NPM)](https://www.npmjs.org)を使用し、インストールしてください。

    npm install

`npm install`を使い、依存パッケージをインストールし終えたら、[Laravel Mix](/docs/{{version}}/mix#working-with-stylesheets)を使用して、SASSファイルを通常のCSSへコンパイルできます。`npm run dev`コマンドは`webpack.mix.js`ファイル中の指示を処理します。通常、コンパイル済みCSSは`public/css`ディレクトリへ設置されます。

    npm run dev

Laravelのフロントエンドスカフォールドを含んでいる`webpack.mix.js`ファイルは、`resources/sass/app.scss` SASSファイルをコンパイルします。この`app.scss`ファイルはSASS変数をインポートし、大抵のアプリケーションでよりスタートポイントとなるBootstrapをロードします。お好みに合わせ、もしくはまったく異なったプリプロセッサを使うならば、[Laravel Mixの設定](/docs/{{version}}/mix)に従い自由に`app.scss`ファイルをカスタマイズしてください。

<a name="writing-javascript"></a>
## JavaScriptの出力

アプリケーションで要求されている、JavaScriptの全依存パッケージは、プロジェクトルートディレクトリにある`package.json`ファイルで見つかります。このファイルは`composer.json`ファイルと似ていますが、PHPの依存パッケージの代わりにJavaScriptの依存が指定されている点が異なります。依存パッケージは、[Node package manager (NPM)](https://www.npmjs.org)を利用し、インストールできます。

    npm install

> {tip} デフォルトで`package.json`ファイルは、JavaScriptアプリケーションを構築する良い開始点を手助けする`lodash`や`axios`のようなわずかなパッケージを含んでいるだけです。アプリケーションの必要に応じ、自由に`package.json`に追加や削除を行ってください。

`webpack.mix.js` file:パッケージをインストールしたら、`npm run dev`コマンドで[アセットをコンパイル](/docs/{{version}}/mix)できます。webpackは、モダンなJavaScriptアプリケーションのための、モジュールビルダです。`npm run dev`コマンドを実行すると、webpackは`webpack.mix.js`ファイル中の指示を実行します。

    npm run dev

デフォルトでLaravelの`webpack.mix.js`ファイルは、SASSと`resources/js/app.js`ファイルをコンパイルするように指示しています。`app.js`ファイルの中で、Vueコンポーネントを登録してください。もしくは、他のフーレムワークが好みであれば、自分のJavaScriptアプリケーションの設定を行えます。コンパイル済みのJavaScriptは通常、`public/js`ディレクトリへ出力されます。

> {tip} `app.js`ファイルは、Vue、Axios、jQuery、その他のJavaScript依存パッケージを起動し、設定する`resources/js/bootstrap.js`ファイルをロードします。JacaScript依存パッケージを追加した場合、このファイルの中で設定してください。

<a name="writing-vue-components"></a>
### Vueコンポーネントの出力

フロントエンドのスカフォールドに`laravel/ui`パッケージを利用するとき、`resources/js/components`ディレクトリの中に`ExampleComponent.vue` Vueコンポーネントが設置されます。`ExampleComponent.vue`ファイルはJavaScriptとHTMLテンプレートを同じファイルで定義する、[シングルファイルVueコンポーネント](https://vuejs.org/guide/single-file-components)のサンプルです。シングルファイルコンポーネントはJavaScriptで駆動するアプリケーションを構築するための便利なアプローチを提供しています。このサンプルコンポーネントは`app.js`ファイルで登録されています。

    Vue.component(
        'example-component',
        require('./components/ExampleComponent.vue').default
    );

コンポーネントをアプリケーションで使用するには、HTMLテンプレートの中へ埋め込みます。たとえば、アプリケーションの認証と登録スクリーンをスカフォールドするために、`php artisan ui vue --auth` Artisanコマンドを実行下後に、`home.blade.php` Bladeテンプレートへ埋め込みます。

    @extends('layouts.app')

    @section('content')
        <example-component></example-component>
    @endsection

> {tip} Vueコンポーネントを変更したら、毎回`npm run dev`コマンドを実行しなくてはならないことを覚えておきましょう。もしくは、`npm run watch`コマンドを実行して監視すれば、コンポーネントが更新されるたび、自動的に再コンパイルされます。

Vueコンポーネントの記述を学ぶことに興味があれば、Vueフレームワーク全体についての概念を簡単に読み取れる、[Vueドキュメント](https://vuejs.org/guide/)を一読してください。

<a name="using-react"></a>
### Reactの使用

JavaScriptアプリケーションでReactを使用するほうが好みであれば、VueスカフォールドをReactスカフォールドへ簡単に切り替えられます。

    composer require laravel/ui

    // 基本的なスカフォールドを生成
    php artisan ui react

    // ログイン／ユーザー登録スカフォールドを生成
    php artisan ui react --auth

<a name="adding-presets"></a>
## プリセットの追加

独自メソッドを`UiCommand`へ追加できるように、プリセットは「マクロ可能(macroable)」になっています。たとえば以下の例では、`UiCommand`へ`nextjs`メソッドのコードを追加しています。通常、プリセットマクロは[サービスプロバイダ](/docs/{{version}}/providers)で定義します。

    use Laravel\Ui\UiCommand;

    UiCommand::macro('nextjs', function (UiCommand $command) {
        // 独自フロントエンドのスカフォールド…
    });

次に、`ui`コマンドで新しいプリセットを呼び出します。

    php artisan ui nextjs
