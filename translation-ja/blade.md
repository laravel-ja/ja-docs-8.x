# Bladeテンプレート

- [イントロダクション](#introduction)
- [テンプレートの継承](#template-inheritance)
    - [レイアウトの定義](#defining-a-layout)
    - [レイアウトの拡張](#extending-a-layout)
- [データ表示](#displaying-data)
    - [BladeとJavaScriptフレームワーク](#blade-and-javascript-frameworks)
- [制御構文](#control-structures)
    - [If文](#if-statements)
    - [Switch文](#switch-statements)
    - [繰り返し](#loops)
    - [ループ変数](#the-loop-variable)
    - [コメント](#comments)
    - [PHP](#php)
    - [`@once`ディレクティブ](#the-once-directive)
- [フォーム](#forms)
    - [CSRFフィールド](#csrf-field)
    - [Methodフィールド](#method-field)
    - [バリデーションエラー](#validation-errors)
- [コンポーネント](#components)
    - [コンポーネントの表示](#displaying-components)
    - [コンポーネントへのデータ渡し](#passing-data-to-components)
    - [属性の管理](#managing-attributes)
    - [スロット](#slots)
    - [インラインコンポーネントビュー](#inline-component-views)
    - [無名コンポーネント](#anonymous-components)
    - [動的コンポーネント](#dynamic-components)
- [サブビューの読み込み](#including-subviews)
    - [コレクションのレンダービュー](#rendering-views-for-collections)
- [スタック](#stacks)
- [サービス注入](#service-injection)
- [Blade拡張](#extending-blade)
    - [カスタムif文](#custom-if-statements)

<a name="introduction"></a>
## イントロダクション

BladeはシンプルながらパワフルなLaravelのテンプレートエンジンです。他の人気のあるPHPテンプレートエンジンとは異なり、ビューの中にPHPを直接記述することを許しています。全BladeビューはPHPへコンパイルされ、変更があるまでキャッシュされます。つまりアプリケーションのオーバーヘッドは基本的に０です。Bladeビューには`.blade.php`ファイル拡張子を付け、通常は`resources/views`ディレクトリの中に設置します。

<a name="template-inheritance"></a>
## テンプレートの継承

<a name="defining-a-layout"></a>
### レイアウト定義

Bladeを使用する主な利点は、**テンプレートの継承**と**セクション**です。初めに簡単な例を見てください。通常ほとんどのアプリケーションでは、数多くのページを同じ全体的なレイアウトの中に表示するので、最初は"master"ページレイアウトを確認しましょう。レイアウトは一つのBladeビューとして、簡単に定義できます。

    <!-- resources/views/layouts/app.blade.phpとして保存 -->

    <html>
        <head>
            <title>アプリ名 - @yield('title')</title>
        </head>
        <body>
            @section('sidebar')
                ここがメインのサイドバー
            @show

            <div class="container">
                @yield('content')
            </div>
        </body>
    </html>

ご覧の通り、典型的なHTMLマークアップで構成されたファイルです。しかし、`@section`や`@yield`ディレクティブに注目です。`@section`ディレクティブは名前が示す通りにコンテンツのセクションを定義し、一方の`@yield`ディレクティブは指定したセクションの内容を表示するために使用します。

これでアプリケーションのレイアウトが定義できました。このレイアウトを継承する子のページを定義しましょう。

<a name="extending-a-layout"></a>
### レイアウト拡張

子のビューを定義するには、「継承」するレイアウトを指定する、Blade `@extends`ディレクティブを使用します。Bladeレイアウトを拡張するビューは、`@section`ディレクティブを使用し、レイアウトのセクションに内容を挿入します。前例にあるようにレイアウトでセクションを表示するには`@yield`を使用します。

    <!-- resources/views/child.blade.phpとして保存 -->

    @extends('layouts.app')

    @section('title', 'Page Title')

    @section('sidebar')
        @@parent

        <p>ここはメインのサイドバーに追加される</p>
    @endsection

    @section('content')
        <p>ここが本文のコンテンツ</p>
    @endsection

この例の`sidebar`セクションでは、レイアウトのサイドバーの内容をコンテンツに上書きするのではなく追加するために`@@parent`ディレクティブを使用しています。`@@parent`ディレクティブはビューをレンダーするときに、レイアウトの内容に置き換わります。

> {tip} 直前の例とは異なり、この`sidebar`セクションは`@show`の代わりに`@endsection`で終わっています。`@endsection`ディレクティブはセクションを定義するだけに対し、`@show`は定義しつつ、そのセクションを**即時にその場所に取り込みます**。

`@yield`ディレクティブは、デフォルト値を第２引数に受け取ります。この値は埋め込み対象のセクションが未定義の場合にレンダーされます。

    @yield('content', View::make('view.name'))

Bladeビューはグローバルな`view`ヘルパを使用し、ルートから返すことができます。

    Route::get('blade', function () {
        return view('child');
    });

<a name="displaying-data"></a>
## データ表示

Bladeビューに渡されたデータは、波括弧で変数を囲うことで表示できます。たとえば、次のルートがあるとしましょう。

    Route::get('greeting', function () {
        return view('welcome', ['name' => 'Samantha']);
    });

`name`変数の内容を表示しましょう。

    Hello, {{ $name }}.

> {tip} Bladeの`{{ }}`記法はXSS攻撃を防ぐため、自動的にPHPの`htmlspecialchars`関数を通されます。

ビューに渡された変数の内容を表示するだけに限られません。PHP関数の結果をechoすることもできます。実際、どんなPHPコードもBladeのecho文の中に書けます。

    The current UNIX timestamp is {{ time() }}.

#### エスケープしないデータの表示

デフォルトでブレードの`{{ }}`文はXSS攻撃を防ぐために、PHPの`htmlspecialchars`関数を自動的に通されます。しかしデータをエスケープしたくない場合は、以下の構文を使ってください。

    Hello, {!! $name !!}.

> {note} アプリケーションでユーザーの入力内容をechoする場合は注意が必要です。ユーザーの入力を表示するときは、常に二重の波括弧の記法でHTMLエンティティにエスケープすべきです。

#### JSONのレンダー

JavaScriptの変数を初期化するために、配列をビューに渡してJSONとして描画できます。

    <script>
        var app = <?php echo json_encode($array); ?>;
    </script>

その際、`json_encode`を使う代わりに、`@json`ディレクティブを使うことができます。`@json`ディレクティブは、PHPの`json_encode`関数と同じ引数を受けます。

    <script>
        var app = @json($array);

        var app = @json($array, JSON_PRETTY_PRINT);
    </script>

> {note} 既存の変数をJSONとしてレンダーするには、`@json`ディレクティブだけを使用してください。正規表現ベースのBladeテンプレートに、複雑な正規表現をディレクティブで渡すと、予期しない不良動作の原因になります。

#### HTMLエンティティエンコーディング

Blade（およびLaravelの`e`ヘルパ）はデフォルトで、HTMLエンティティをdouble encodeします。double encodeを無効にするには、`AppServiceProvider`の`boot`メソッドで、`Blade::withoutDoubleEncoding`メソッドを呼び出してください。

    <?php

    namespace App\Providers;

    use Illuminate\Support\Facades\Blade;
    use Illuminate\Support\ServiceProvider;

    class AppServiceProvider extends ServiceProvider
    {
        /**
         * アプリケーションの全サービスの初期処理
         *
         * @return void
         */
        public function boot()
        {
            Blade::withoutDoubleEncoding();
        }
    }

<a name="blade-and-javascript-frameworks"></a>
### BladeとJavaScriptフレームワーク

与えられた式をブラウザに表示するため、多くのJavaScriptフレームワークでも波括弧を使っているので、`@`シンボルでBladeレンダリングエンジンに波括弧の展開をしないように指示することが可能です。

    <h1>Laravel</h1>

    Hello, @{{ name }}.

この例で、`@`記号はBladeにより削除されます。しかし、`{{ name }}`式はBladeエンジンにより変更されずにそのまま残り、JavaScriptフレームワークによりレンダリングできるようになります。

`@`記号は、Bladeディレクティブをエスケープするためにも使用します。

    {{-- Blade --}}
    @@json()

    <!-- HTML出力 -->
    @json()

#### `@verbatim`ディレクティブ

テンプレートの広い箇所でJavaScript変数を表示する場合は、HTMLを`@verbatim`ディレクティブで囲めば、各Blade echo文の先頭に`@`記号を付ける必要はなくなります。

    @verbatim
        <div class="container">
            Hello, {{ name }}.
        </div>
    @endverbatim

<a name="control-structures"></a>
## 制御構文

テンプレートの継承とデータ表示に付け加え、Bladeは条件文やループなどの一般的なPHPの制御構文の便利な短縮記述方法を提供しています。こうした短縮形は、PHP制御構文の美しく簡潔な記述を提供しつつも、対応するPHPの構文と似せています。

<a name="if-statements"></a>
### If文

`if`文の構文には、`@if`、`@elseif`、`@else`、`@endif`ディレクティブを使用します。これらの使い方はPHPの構文と同じです。

    @if (count($records) === 1)
        １レコードある！
    @elseif (count($records) > 1)
        複数レコードある！
    @else
        レコードがない！
    @endif

便利な@unlessディレクティブも提供しています。

    @unless (Auth::check())
        あなたはログインしていません。
    @endunless

さらに、すでに説明したように`@isset`と`@empty`ディレクティブも、同名のPHP関数の便利なショートカットとして使用できます。

    @isset($records)
        // $recordsは定義済みでnullでない
    @endisset

    @empty($records)
        // $recordsが「空」だ
    @endempty

#### 認証ディレクティブ

`@auth`と`@guest`ディレクティブは、現在のユーザーが認証されているか、もしくはゲストであるかを簡単に判定するために使用します。

    @auth
        // ユーザーは認証済み
    @endauth

    @guest
        // ユーザーは認証されていない
    @endguest

必要であれば、`@auth`と`@guest`ディレクティブ使用時に、確認すべき[認証ガード](/docs/{{version}}/authentication)を指定できます。

    @auth('admin')
        // ユーザーは認証済み
    @endauth

    @guest('admin')
        // ユーザーは認証されていない
    @endguest

#### セクションディレクティブ

セクションがコンテンツを持っているかを判定したい場合は、`@hasSection`ディレクティブを使用します。

    @hasSection('navigation')
        <div class="pull-right">
            @yield('navigation')
        </div>

        <div class="clearfix"></div>
    @endif

セクションに何か内容が含まれているかを判定するために、`@sectionMissing`ディレクティブが使用できます。

    @sectionMissing('navigation')
        <div class="pull-right">
            @include('default-navigation')
        </div>
    @endif

#### 環境ディレクティブ

アプリケーションが実働環境("production")で実行されているかを調べるには、`@production`ディレクティブを使います。

    @production
        // 実働環境のコンテンツを指定…
    @endproduction

もしくは、特定の環境でアプリケーションが実行されているかを判定するには、`@env`ディレクティブを使います。

    @env('staging')
        // アプリケーションが"staging"環境で実行中
    @endenv

    @env(['staging', 'production'])
        // アプリケーションが"staging"と"production"環境で実行中
    @endenv

<a name="switch-statements"></a>
### Switch文

`@switch`、`@case`、`@break`、`@default`、`@endswitch`ディレクティブを使用し、switch文を構成できます。

    @switch($i)
        @case(1)
            最初のケース
            @break

        @case(2)
            ２番めのケース
            @break

        @default
            デフォルトのケース
    @endswitch

<a name="loops"></a>
### 繰り返し

条件文に加え、BladeはPHPがサポートしている繰り返し構文も提供しています。これらも、対応するPHP構文と使い方は一緒です。

    @for ($i = 0; $i < 10; $i++)
        現在の値は： {{ $i }}
    @endfor

    @foreach ($users as $user)
        <p>これは {{ $user->id }} ユーザーです。</p>
    @endforeach

    @forelse ($users as $user)
        <li>{{ $user->name }}</li>
    @empty
        <p>ユーザーなし</p>
    @endforelse

    @while (true)
        <p>無限ループ中</p>
    @endwhile

> {tip} 繰り返し中は[ループ変数](#the-loop-variable)を使い、繰り返しの最初や最後なのかなど、繰り返し情報を取得できます。

繰り返しを使用する場合、ループを終了するか、現在の繰り返しをスキップすることもできます。

    @foreach ($users as $user)
        @if ($user->type == 1)
            @continue
        @endif

        <li>{{ $user->name }}</li>

        @if ($user->number == 5)
            @break
        @endif
    @endforeach

もしくは、ディレクティブに条件を記述して、一行で済ますこともできます。

    @foreach ($users as $user)
        @continue($user->type == 1)

        <li>{{ $user->name }}</li>

        @break($user->number == 5)
    @endforeach

<a name="the-loop-variable"></a>
### ループ変数

繰り返し中は、`$loop`変数が使用できます。この変数により、現在のループインデックスや繰り返しの最初／最後なのかなど、便利な情報にアクセスできます。

    @foreach ($users as $user)
        @if ($loop->first)
            これは最初の繰り返し
        @endif

        @if ($loop->last)
            これは最後の繰り返し
        @endif

        <p>これは {{ $user->id }} ユーザーです。</p>
    @endforeach

ネストした繰り返しでは、親のループの`$loop`変数に`parent`プロパティを通じアクセスできます。

    @foreach ($users as $user)
        @foreach ($user->posts as $post)
            @if ($loop->parent->first)
                これは親のループの最初の繰り返しだ
            @endif
        @endforeach
    @endforeach

`$loop`変数は、他にもいろいろと便利なプロパティを持っています。

プロパティ  | 説明
------------- | ----------------------
`$loop->index`  |  現在のループのインデックス（初期値0）
`$loop->iteration`  |  現在の繰り返し数（初期値1）
`$loop->remaining`  |  繰り返しの残り数
`$loop->count`  |  繰り返し中の配列の総アイテム数
`$loop->first`  |  ループの最初の繰り返しか判定
`$loop->last`  |  ループの最後の繰り返しか判定
`$loop->even`  |  これは偶数回目の繰り返しか判定
`$loop->odd`  |  これは奇数回目の繰り返しか判定
`$loop->depth`  |  現在のループのネストレベル
`$loop->parent`  |  ループがネストしている場合、親のループ変数

<a name="comments"></a>
### コメント

Bladeでビューにコメントを書くこともできます。HTMLコメントと異なり、Bladeのコメントはアプリケーションから返されるHTMLには含まれません。

    {{-- このコメントはレンダー後のHTMLには現れない --}}

<a name="php"></a>
### PHP

PHPコードをビューへ埋め込むと便利な場合もあります。Bladeの`@php`ディレクティブを使えば、テンプレートの中でプレーンなPHPブロックを実行できます。

    @php
        //
    @endphp

> {tip} Bladeはこの機能を提供していますが、数多く使用しているのであれば、それはテンプレートへ多すぎるロジックを埋め込んでいるサインです。

<a name="the-once-directive"></a>
### `@once`ディレクティブ

`@once`ディレクティブは、レンダリングサイクルごとに一度だけ評価されるテンプレートの一部を定義できます。これは[stacks](#stacks)を使い、JavaScriptをページのヘッダへ挿入するのに便利です。たとえば、ループ内で与えられた [コンポーネント](#components)をレンダリングしている場合、最初にコンポーネントがレンダリングされたときのみ、JavaScriptをヘッダにプッシュできます。

    @once
        @push('scripts')
            <script>
                // カスタムJavaScriptコード…
            </script>
        @endpush
    @endonce

<a name="forms"></a>
## フォーム

<a name="csrf-field"></a>
### CSRFフィールド

アプリケーションでHTMLフォームを定義する場合、[CSRF保護](/docs/{{version}}/csrf)ミドルウェアがリクエストを検査できるようにするため、隠しCSRFトークンフィールドを含める必要があります。このトークンフィールドを生成するには、`@csrf` Bladeディレクティブを使用します。

    <form method="POST" action="/profile">
        @csrf

        ...
    </form>

<a name="method-field"></a>
### Methodフィールド

HTMLフォームでは、`PUT`、`PATCH`、`DELETE`リクエストを作成できないため、見かけ上のHTTP動詞を指定するための`_method`フィールドを追加する必要があります。`@method` Bladeディレクティブでこのフィールドを生成できます。

    <form action="/foo/bar" method="POST">
        @method('PUT')

        ...
    </form>

<a name="validation-errors"></a>
### バリデーションエラー

`@error`ディレクティブは、指定した属性の[バリデーションエラーメッセージ](/docs/{{version}}/validation#quick-displaying-the-validation-errors)があるかを簡単に判定するために使用します。`@error`ディレクティブの中でエラーメッセージを表示するために、`$message`変数をエコーすることも可能です。

    <!-- /resources/views/post/create.blade.php -->

    <label for="title">Post Title</label>

    <input id="title" type="text" class="@error('title') is-invalid @enderror">

    @error('title')
        <div class="alert alert-danger">{{ $message }}</div>
    @enderror

複数のフォームにより構成されたページで、バリデーションエラーを取得するために、`@error`ディレクティブの第２引数として[特定のエラーバッグの名前](/docs/{{version}}/validation#named-error-bags)が渡せます。

    <!-- /resources/views/auth.blade.php -->

    <label for="email">Email address</label>

    <input id="email" type="email" class="@error('email', 'login') is-invalid @enderror">

    @error('email', 'login')
        <div class="alert alert-danger">{{ $message }}</div>
    @enderror

<a name="components"></a>
## コンポーネント

コンポーネントとスロットは、レイアウトとセクションに似た利便性をもたらします。ですがコンポーネントとスロットのほうが簡単に理解できるメンタルモデルであるとわかってもらえるでしょう。コンポーネントを書くには２つのアプローチがあります。クラスベースコンポーネントと匿名コンポーネントです。

`make:component` Artisanコマンドを使えば、クラスベースのコンポーネントを生成できます。コンポーネントの使い方を説明するために、簡単な`Alert`コンポーネントを作成してみましょう。`make:component`コマンドは`App\View\Components`ディレクトリの中にコンポーネントを生成します。

    php artisan make:component Alert

`make:component`コマンドは、コンポーネントのためのビューテンプレートも生成します。このビューは`resources/views/components`ディレクトリに生成されます。

#### パッケージコンポーネントの登録

アプリケーションのために書いたコンポーネントは、自動的に`app/View/Components`と`resources/views/components`ディレクトリの中で見つけられます。

しかしながら、Bladeコンポーネントを活用したパッケージを構築している場合、コンポーネントクラスとそのHTMLタグエイリアスを皆さん自身で登録する必要があります。通常、皆さんのパッケージのサービスプロバイダ内にある`boot`メソッドで、コンポーネントを登録する必要があります。

    use Illuminate\Support\Facades\Blade;

    /**
     * パッケージのサービスの初期処理
     */
    public function boot()
    {
        Blade::component('package-alert', AlertComponent::class);
    }

コンポーネントを登録したら、そのタグエイリアスを使用してレンダーします。

    <x-package-alert/>

代わりに、 `componentNamespace`メソッドを使用して、規約によりコンポーネントクラスをオートロードすることも便利です。たとえば`Nightshade`パッケージには、`Package\Views\Components`名前空間内に存在する`Calendar`と`ColorPicker`コンポーネントがあるとしましょう。

    use Illuminate\Support\Facades\Blade;

    /**
     * パッケージサービスの初期処理
     */
    public function boot()
    {
        Blade::componentNamespace('Nightshade\Views\Components', 'nightshade');
    }

これにより、`パッケージ名::`構文を使用してベンダーの名前空間でパッケージコンポーネントを使用できるようになります。

    <x-nightshade::calendar />
    <x-nightshade::color-picker />

Bladeは、コンポーネント名をアッパーキャメルに変換し、このコンポーネントにリンクされているクラスを自動的に検出します。「ドット」記法により、サブディレクトリもサポートします。

<a name="displaying-components"></a>
### コンポーネントの表示

コンポーネントを表示するには、Bladeテンプレートの中でBladeコンポーネントタグを使用します。Bladeコンポーネントタグとは、コンポーネントクラス名のケバブケースを`x-`に続けた文字列のことです。

    <x-alert/>

    <x-user-profile/>

`App\View\Components`ディレクトリの中にコンポーネントクラスをネストしている場合は、ディレクトリのネストを表すために`.`を使います。たとえば`App\View\Components\Inputs\Button.php`がコンポーネントだとすると、次のようにレンダーします。

    <x-inputs.button/>

<a name="passing-data-to-components"></a>
### コンポーネントへのデータ渡し

HTML属性を使い、Bladeコンポーネントへデータを渡すことができます。シンプルなHTML属性を使い、ハードコードしたプリミティブ値をコンポーネントへ渡します。PHP表現と変数は、`:`文字を前に付けた属性によりコンポーネントへ渡します。

    <x-alert type="error" :message="$message"/>

コンポーネントで必須のデータは、クラスのコンストラクタで定義する必要があります。コンポーネント上のパブリックプロパティはすべて、コンポーネントのビューで自動的に使えます。コンポーネントの`render`メソッドからビューへデータを渡す必要はありません。

    <?php

    namespace App\View\Components;

    use Illuminate\View\Component;

    class Alert extends Component
    {
        /**
         * alertのタイプ
         *
         * @var string
         */
        public $type;

        /**
         * alertのメッセージ
         *
         * @var string
         */
        public $message;

        /**
         * コンポーネントインスタンスの生成
         *
         * @param  string  $type
         * @param  string  $message
         * @return void
         */
        public function __construct($type, $message)
        {
            $this->type = $type;
            $this->message = $message;
        }

        /**
         * コンポーネントを表すビュー／コンテンツの取得
         *
         * @return \Illuminate\View\View|\Closure|string
         */
        public function render()
        {
            return view('components.alert');
        }
    }

コンポーネントがレンダーされるときに、名前が一致するコンポーネントのパブリック変数がエコーされることにより、コンテンツは表示されます。

    <div class="alert alert-{{ $type }}">
        {{ $message }}
    </div>

#### キャスト

コンポーネントのコンストラクタ引数はキャメルケース（`camelCase`）を使用し、HTML属性の中で引数名を参照するときはケバブケース（`kebab-case`）を使用します。たとえば、以下のようなコンポーネントコンストラクタがあったとしましょう。

    /**
     * コンポーネントインスタンスの生成
     *
     * @param  string  $alertType
     * @return void
     */
    public function __construct($alertType)
    {
        $this->alertType = $alertType;
    }

`$alertType`引数は以下のように指定します。

    <x-alert alert-type="danger" />

#### コンポーネントメソッド

コンポーネントテンプレートではパブリックな変数が使えるのに加え、コンポーネントの全パブリックメソッドも実行可能です。たとえば、コンポーネントに`isSelected`メソッドがあると想像してください。

    /**
     * 指定されたオプションが現在選ばれているか判定する
     *
     * @param  string  $option
     * @return bool
     */
    public function isSelected($option)
    {
        return $option === $this->selected;
    }

メソッド名と一致する変数を呼び出せば、コンポーネントテンプレートからこのメソッドを実行できます。

    <option {{ $isSelected($value) ? 'selected="selected"' : '' }} value="{{ $value }}">
        {{ $label }}
    </option>

#### クラス内での属性／スロットの使用

Bladeコンポーネントはクラスのrenderメソッドの中からコンポーネント名、属性、スロットへアクセスできます。しかし、このデータにアクセスするにはコンポーネントの`render`メソッドからクロージャを返す必要があります。クロージャは唯一の引数として`$data`配列を受け取ります。

    /**
     * コンポーネントを表すビュー／内容の取得
     *
     * @return \Illuminate\View\View|\Closure|string
     */
    public function render()
    {
        return function (array $data) {
            // $data['componentName'];
            // $data['attributes'];
            // $data['slot'];

            return '<div>Components content</div>';
        };
    }

`componentName`は、HTMLタグ中で`x-`プレフィックスに続けて使用している名前と同じです。そのため、`<x-alert />`の`componentName`は`alert`となります。`attributes`要素はHTMLタグ中に現れるすべての属性を含みます。`slot`要素はそのコンポーネントのスロットの内容の`Illuminate\Support\HtmlString`インスタンスです。

このクロージャは文字列を返す必要があります。返す文字列が既存のビューに対応している場合、そのビューをレンダーします。対応していない場合、返す文字列はインラインBladeビューとして評価します。

#### 依存の追加

コンポーネントがLaravelの[サービスコンテナ](/docs/{{version}}/container)からの依存注入を必要としているなら、コンポーネントのデータ属性の前に依存をリストしておけば、コンテナにより自動的に注入されます。

    use App\Services\AlertCreator

    /**
     * コンポーネントインスタンスの生成
     *
     * @param  \App\Services\AlertCreator  $creator
     * @param  string  $type
     * @param  string  $message
     * @return void
     */
    public function __construct(AlertCreator $creator, $type, $message)
    {
        $this->creator = $creator;
        $this->type = $type;
        $this->message = $message;
    }

<a name="managing-attributes"></a>
### 属性の管理

コンポーネントへデータ属性を渡す方法はすでに説明しました。しかしながら、たとえばコンポーネントが機能するためには必須でないデータである`class`のような、追加のHTML属性を指定する必要も起き得ます。コンポーネントテンプレートのルート要素へ追加の属性を渡したい場合が、典型例でしょう。例として、`alert`コンポーネントを次のようにレンダーするのを想像してください。

    <x-alert type="error" :message="$message" class="mt-4"/>

コンポーネントのコンストラクタで依存していしていない残りの属性すべては、そのコンポーネントの「属性バッグ」へ追加されます。この属性バッグは`$attributes`変数によりコンポーネントで使用可能になります。この変数をエコーすることにより、コンポーネント中ですべての属性がレンダーされます。

    <div {{ $attributes }}>
        <!-- コンポーネントのコンテンツ -->
    </div>

> {note} コンポーネントでの`@env`ディレクティブの使用は、今のところサポートしていません。

#### デフォルト／属性のマージ

属性にデフォルト値を指定、またはコンポーネントの属性へ追加の値をマージする必要も時に起きます。これには属性バッグの`merge`メソッドを使用します。

    <div {{ $attributes->merge(['class' => 'alert alert-'.$type]) }}>
        {{ $message }}
    </div>

このコンポーネントを次のように使用すると仮定してみましょう。

    <x-alert type="error" :message="$message" class="mb-4"/>

最終的にこのコンポーネントは、以下のようなHTMLでレンダーされます。

    <div class="alert alert-error mb-4">
        <!-- ここには$message変数の内容がレンダーされる -->
    </div>

#### 非クラス属性のマージ

`class`ではない属性をマージする場合、`merge`メソッドに渡される値は、コンポーネントの利用者により上書きされる可能性がある、属性の「デフォルト」値と見なします。`class`属性とは異なり、非クラス属性は互いに追加されません。たとえば、`button`コンポーネントは次のようになります。

    <button {{ $attributes->merge(['type' => 'button']) }}>
        {{ $slot }}
    </button>

カスタム`type`を使用してボタンコンポーネントをレンダリングするには、そのコンポーネントを使用するときに指定してください。タイプが指定されていない場合は`button`タイプが使用されます。

    <x-button type="submit">
        Submit
    </x-button>

この例にある`button`コンポーネントのHTMLをレンダーするには、以下のようになります。

    <button type="submit">
        Submit
    </button>

#### 属性のフィルタリング

`filter`メソッドを使い、属性をフィルタリングできます。このメソッドはクロージャを引数に取り、属性バックの中へ残す属性に対し`true`を返してください。

    {{ $attributes->filter(fn ($value, $key) => $key == 'foo') }}

より便利に使うため、指定文字列から始まるキー名の属性を全部取得する、`whereStartsWith`メソッドを使うことも可能です。

    {{ $attributes->whereStartsWith('wire:model') }}

`first`メソッドを使い、指定した属性バッグの中の最初の属性をレンダーすることもできます。

    {{ $attributes->whereStartsWith('wire:model')->first() }}

<a name="slots"></a>
### スロット

コンポーネントに「スロット」を使用して、追加のコンテンツを渡す必要性がしばしばあると思います。次のような`aleat`コンポーネントを作ったとイメージしてください。

    <!-- /resources/views/components/alert.blade.php -->

    <div class="alert alert-danger">
        {{ $slot }}
    </div>

コンポーネントにコンテンツを挿入することにより、`slot`に内容を渡せます。

    <x-alert>
        <strong>あーーー！</strong> なんか変だ！
    </x-alert>

コンポーネント中の別々の場所に、複数の別々なスロットをレンダーする必要も起きるでしょう。ではalertコンポーネントへ"title"を挿入できるように変更してみましょう。

    <!-- /resources/views/components/alert.blade.php -->

    <span class="alert-title">{{ $title }}</span>

    <div class="alert alert-danger">
        {{ $slot }}
    </div>

`x-slot`タグを使い、名前付きスロットのコンテンツを定義します。`x-slot`の外のコンテンツは、すべて`$slot`変数によりコンポーネントへ渡されます。

    <x-alert>
        <x-slot name="title">
            サーバエラー
        </x-slot>

        <strong>あーーー！</strong> なんか変だ！
    </x-alert>

#### スコープ付きスロット

VueのようなJavaScriptフレームワークを使用している方は「スコープ付きスロット」に慣れていると思います。これは、スロットの中でコンポーネントのデータやメソッドへアクセスできる機構です。同様の振る舞いはLaravelでも、コンポーネントでpublicメソッドやプロパティを定義すれば可能です。`component`変数によりスロットの中でコンポーネントへアクセスします。

    <x-alert>
        <x-slot name="title">
            {{ $component->formatAlert('Server Error') }}
        </x-slot>

        <strong>あーーー！</strong> なんか変だ！
    </x-alert>

<a name="inline-component-views"></a>
### インラインコンポーネントビュー

小さなコンポーネントでは、コンポーネントクラスとコンポーネントのビューテンプレート両方を管理するのは面倒に感じるでしょう。そのため、コンポーネントのマークアップを直接`render`メソッドから返せます。

    /**
     * コンポーネントを表すビュー／内容の取得
     *
     * @return \Illuminate\View\View|\Closure|string
     */
    public function render()
    {
        return <<<'blade'
            <div class="alert alert-danger">
                {{ $slot }}
            </div>
        blade;
    }

#### インラインビューコンポーネントの生成

インラインビューをレンダーするコンポーネントを生成するには、`make:component`コマンド実行時に`inline`オプションを使用します。

    php artisan make:component Alert --inline

<a name="anonymous-components"></a>
### 無名コンポーネント

インラインコンポーネントと同様に、一つのファイルでコンポーネントを管理する仕組みを提供しているのが、無名コンポーネントです。違いは、無名コンポーネントは一つのビューファイルを使用し、関係するクラスはありません。無名コンポーネントを定義するには、`resources/views/components`ディレクトリの中にBladeテンプレートを設置する必要があります。ここでは`resources/views/components/alert.blade.php`にコンポーネントを定義すると仮定しましょう。

    <x-alert/>

`components`ディレクトリ下にネストしたサブディレクトリ中へコンポーネントを設置する場合は、`.`を使ってください。たとえば、`resources/views/components/inputs/button.blade.php`へ定義する場合、次のようになります。

    <x-inputs.button/>

#### データプロパティ／属性

無名コンポーネントには関連するクラスがないため、どのデータが変数を通じてコンポーネントへ渡され、どの属性がコンポーネントの[属性バッグ](#managing-attributes)に入れられるのかの違いに迷うと思います。

コンポーネントのBladeテンプレートの先頭で`@props`ディレクティブを使い、データ変数としてどの属性を取り扱うかを指定します。コンポーネント中の他の属性は、属性バッグを使い利用可能です。データ変数にデフォルト値を指定する場合は、変数の名前を配列キーとして指定し、デフォルト値を配列値として指定します。

    <!-- /resources/views/components/alert.blade.php -->

    @props(['type' => 'info', 'message'])

    <div {{ $attributes->merge(['class' => 'alert alert-'.$type]) }}>
        {{ $message }}
    </div>

<a name="dynamic-components"></a>
### 動的コンポーネント

場合により、実行時までどのコンポーネントをレンダーすればよいのかわからないことがあります。このような状況では、Laravelに組み込まれている`dynamic-component`コンポーネントで、実行時の値や変数をもとにコンポーネントをレンダーしてください。

    <x-dynamic-component :component="$componentName" class="mt-4" />

<a name="including-subviews"></a>
## サブビューの読み込み

Bladeの`@include`ディレクディブを使えば、ビューの中から簡単に他のBladeビューを取り込めます。読み込み元のビューで使用可能な変数は、取り込み先のビューでも利用可能です。

    <div>
        @include('shared.errors')

        <form>
            <!-- フォームの内容 -->
        </form>
    </div>

親のビューの全データ変数が取り込み先のビューに継承されますが、追加のデータも配列で渡すことができます。

    @include('view.name', ['some' => 'data'])

存在しないビューを`@include`すれば、Laravelはエラーを投げます。存在しているかどうかわからないビューを取り込みたい場合は、`@includeIf`ディレクティブを使います。

    @includeIf('view.name', ['some' => 'data'])

指定した論理条件が`true`の場合に`@include`したい場合は、`@includeWhen`ディレクティブを使用します。

    @includeWhen($boolean, 'view.name', ['some' => 'data'])

指定した論理条件が`false`の場合に`@include`したい場合は、`@includeUnless`ディレクティブを使用します。

    @includeUnless($boolean, 'view.name', ['some' => 'data'])

指定するビューの配列から、最初に存在するビューを読み込むには、`includeFirst`ディレクティブを使用します。

    @includeFirst(['custom.admin', 'admin'], ['some' => 'data'])

> {note} Bladeビューの中では`__DIR__`や`__FILE__`を使わないでください。キャッシュされたコンパイル済みのビューのパスが返されるからです。

#### サブビューのエイリアス

Bladeのサブビューがサブディレクトリへ設置されている場合でも簡潔にアクセスできるよう、エイリアスを使用できます。たとえば、以下の内容のBladeサブビューが、`resources/views/includes/input.blade.php`へ保存されていると想像してください。

    <input type="{{ $type ?? 'text' }}">

`includes.input`への`input`エイリアスを設定するには、`include`メソッドを使用します。通常これは、`AppServiceProvider`の`boot`メソッドの中で行うべきです。

    use Illuminate\Support\Facades\Blade;

    Blade::include('includes.input', 'input');

サブビューのエイリアスを設定したら、Bladeディレクティブとして、そのエイリアス名を使用することにより、レンダーされます。

    @input(['type' => 'email'])

<a name="rendering-views-for-collections"></a>
### コレクションのレンダービュー

Bladeの`@each`ディレクティブを使い、ループとビューの読み込みを組み合わせられます。

    @each('view.name', $jobs, 'job')

最初の引数は配列かコレクションの各要素をレンダーするための部分ビューです。第２引数は繰り返し処理する配列かコレクションで、第３引数はビューの中の繰り返し値が代入される変数名です。ですから、たとえば`jobs`配列を繰り返す場合なら、部分ビューの中で各ジョブには`job`変数としてアクセスしたいと通常は考えるでしょう。 現在の繰り返しのキーは、部分ビューの中の`key`変数で参照できます。

`@each`ディレクティブには第４引数を渡たせます。この引数は配列が空の場合にレンダーされるビューを指定します。

    @each('view.name', $jobs, 'job', 'view.empty')

> {note} `@each`を使ってレンダーされるビューは、親のビューから変数を継承しません。子ビューで親ビューの変数が必要な場合は、代わりに`@foreach`と`@include`を使用してください。

<a name="stacks"></a>
## スタック

Bladeはさらに、他のビューやレイアウトでレンダーできるように、名前付きのスタックへ内容を退避できます。子ビューで必要なJavaScriptを指定する場合に、便利です。

    @push('scripts')
        <script src="/example.js"></script>
    @endpush

必要なだけ何回もスタックをプッシュできます。スタックした内容をレンダーするには、`@stack`ディレクティブにスタック名を指定してください。

    <head>
        <!-- Headの内容 -->

        @stack('scripts')
    </head>

スタックの先頭に内容を追加したい場合は、`@prepend`ディレクティブを使用してください。

    @push('scripts')
        ここは２番目
    @endpush

    // …後から

    @prepend('scripts')
        ここは最初
    @endprepend

<a name="service-injection"></a>
## サービス注入

`@inject`ディレクティブはLaravelの[サービスコンテナ](/docs/{{version}}/container)からサービスを取得するために使用します。`@inject`の最初の引数はそのサービスを取り込む変数名で、第２引数は依存解決したいクラス／インターフェイス名です。

    @inject('metrics', 'App\Services\MetricsService')

    <div>
        Monthly Revenue: {{ $metrics->monthlyRevenue() }}.
    </div>

<a name="extending-blade"></a>
## Blade拡張

Bladeでは`directive`メソッドを使い、自分のカスタムディレクティブを定義できます。Bladeコンパイラがそのカスタムディレクティブを見つけると、そのディレクティブに渡される引数をコールバックへの引数として呼び出します。

次の例は`@datetime($var)`ディレクティブを作成し、渡される`DateTime`インスタンスの`$var`をフォーマットします。

    <?php

    namespace App\Providers;

    use Illuminate\Support\Facades\Blade;
    use Illuminate\Support\ServiceProvider;

    class AppServiceProvider extends ServiceProvider
    {
        /**
         * 全アプリケーションサービスの登録
         *
         * @return void
         */
        public function register()
        {
            //
        }

        /**
         * アプリケーションの全サービスの初期処理
         *
         * @return void
         */
        public function boot()
        {
            Blade::directive('datetime', function ($expression) {
                return "<?php echo ($expression)->format('m/d/Y H:i'); ?>";
            });
        }
    }

ご覧の通り、ディレクティブがどんなものであれ、渡された引数に`format`メソッドをチェーンし、呼び出しています。そのため、この例のディレクティブの場合、最終的に生成されるPHPコードは、次のようになります。

    <?php echo ($var)->format('m/d/Y H:i'); ?>

> {note} Bladeディレクティブのロジックを更新した後に、Bladeビューのキャッシュを全部削除する必要があります。`view:clear` Artisanコマンドで、キャッシュされているBladeビューを削除できます。

<a name="custom-if-statements"></a>
### カスタムif文

シンプルなカスタム条件文を定義する時、必要以上にカスタムディレクティブのプログラミングが複雑になってしまうことが、ときどき起きます。そのため、Bladeはクロージャを使用し、カスタム条件ディレクティブを素早く定義できるように、`Blade::if`メソッドを提供しています。例として、現在のアプリケーションのクラウドプロバイダをチェックするカスタム条件を定義してみましょう。`AppServiceProvider`の`boot`メソッドで行います。

    use Illuminate\Support\Facades\Blade;

    /**
     * 全アプリケーションサービスの初期起動
     *
     * @return void
     */
    public function boot()
    {
        Blade::if('cloud', function ($provider) {
            return config('filesystems.default') === $provider;
        });
    }

カスタム条件を定義したら、テンプレートの中で簡単に利用できます。

    @cloud('digitalocean')
        // アプリケーションはdigitaloceanクラウドプロバイダを使用している
    @elsecloud('aws')
        // アプリケーションはawsプロバイダを使用している
    @else
        // アプリケーションはdigitaloceanとawsプロバイダを使用していない
    @endcloud

    @unlesscloud('aws')
        // アプリケーションはawsプロバイダを使用していない
    @endcloud
