# Bladeテンプレート

- [イントロダクション](#introduction)
- [データの表示](#displaying-data)
    - [HTMLエンティティエンコーディング](#html-entity-encoding)
    - [BladeとJavaScriptフレームワーク](#blade-and-javascript-frameworks)
- [Bladeディレクティブ](#blade-directives)
    - [If文](#if-statements)
    - [Switch文](#switch-statements)
    - [繰り返し](#loops)
    - [ループ変数](#the-loop-variable)
    - [コメント](#comments)
    - [サブビューの読み込み](#including-subviews)
    - [`@once`ディレクティブ](#the-once-directive)
    - [生PHP](#raw-php)
- [コンポーネント](#components)
    - [コンポーネントのレンダー](#rendering-components)
    - [コンポーネントへのデータ渡し](#passing-data-to-components)
    - [コンポーネント属性](#component-attributes)
    - [予約語](#reserved-keywords)
    - [スロット](#slots)
    - [インラインコンポーネントビュー](#inline-component-views)
    - [匿名コンポーネント](#anonymous-components)
    - [動的コンポーネント](#dynamic-components)
    - [コンポーネントの手動登録](#manually-registering-components)
- [レイアウト構築](#building-layouts)
    - [コンポーネントを使用したレイアウト](#layouts-using-components)
    - [テンプレートの継承を使用したレイアウト](#layouts-using-template-inheritance)
- [フォーム](#forms)
    - [CSRFフィールド](#csrf-field)
    - [メソッドフィールド](#method-field)
    - [バリデーションエラー](#validation-errors)
- [スタック](#stacks)
- [サービス注入](#service-injection)
- [Bladeの拡張](#extending-blade)
    - [カスタムIf文](#custom-if-statements)

<a name="introduction"></a>
## イントロダクション

Bladeは、Laravelに含まれているシンプルでありながら強力なテンプレートエンジンです。一部のPHPテンプレートエンジンとは異なり、BladeはテンプレートでプレーンなPHPコードの使用を制限しません。実際、すべてのBladeテンプレートはプレーンなPHPコードにコンパイルされ、変更されるまでキャッシュされます。つまり、Bladeはアプリケーションに実質的にオーバーヘッドをかけません。Bladeテンプレートファイルは`.blade.php`ファイル拡張子を使用し、通常は`resources/views`ディレクトリに保存します。

Bladeビューは、グローバルな`view`ヘルパを使用してルートまたはコントローラから返します。もちろん、[views](/docs/{{version}}/views)のドキュメントに記載されているように、データを`view`ヘルパの２番目の引数を使用してBladeビューに渡せます。

    Route::get('/', function () {
        return view('greeting', ['name' => 'Finn']);
    });

> {tip} Bladeを深く掘り下げる前に、Laravel[ビュードキュメント](/docs/{{version}}/views)を必ずお読みください。

<a name="displaying-data"></a>
## データの表示

変数を中括弧で囲むことにより、Bladeビューに渡すデータを表示できます。たとえば、以下のルートがあるとします。

    Route::get('/', function () {
        return view('welcome', ['name' => 'Samantha']);
    });

次のように `name`変数の内容を表示できます。

    Hello, {{ $name }}.

> {tip} Bladeの`{{ }}`エコー文は、XSS攻撃を防ぐために、PHPの`htmlspecialchars`関数を通して自動的に送信します。

ビューに渡した変数の内容を表示するに留まりません。PHP関数の結果をエコーすることもできます。実際、Bladeエコーステートメント内に任意のPHPコードを入れることができます。

    The current UNIX timestamp is {{ time() }}.

<a name="rendering-json"></a>
#### JSONのレンダー

JavaScript変数を初期化するために、配列をJSONとしてレンダリングする目的でビューに配列を渡す場合があります。一例をご確認ください。

    <script>
        var app = <?php echo json_encode($array); ?>;
    </script>

ただし、手動で`json_encode`を呼び出す代わりに、`@json`Bladeディレクティブが使用できます。`@json`ディレクティブは、PHPの`json_encode`関数と同じ引数を取ります。デフォルトの`@json`ディレクティブは`JSON_HEX_TAG`、`JSON_HEX_APOS`、`JSON_HEX_AMP`、`JSON_HEX_QUOT`フラグを使用して`json_encode`関数を呼び出します。

    <script>
        var app = @json($array);

        var app = @json($array, JSON_PRETTY_PRINT);
    </script>

> {note} @jsonディレクティブは既存の変数をJSONとしてレンダするためだけに使用してください。Bladeテンプレートは正規表現ベースのため、複雑な式をディレクティブに渡すと予期しない不良動作の原因になります。

<a name="html-entity-encoding"></a>
### HTMLエンティティエンコーディング

デフォルトのBlade(およびLaravel`e`ヘルパ)はHTMLエンティティをダブルエンコードします。ダブルエンコーディングを無効にする場合は、`AppServiceProvider`の`boot`メソッドから`Blade::withoutDoubleEncoding`メソッドを呼び出します。

    <?php

    namespace App\Providers;

    use Illuminate\Support\Facades\Blade;
    use Illuminate\Support\ServiceProvider;

    class AppServiceProvider extends ServiceProvider
    {
        /**
         * 全アプリケーションサービスの初期起動処理
         *
         * @return void
         */
        public function boot()
        {
            Blade::withoutDoubleEncoding();
        }
    }

<a name="displaying-unescaped-data"></a>
#### エスケープしないデータの表示

デフォルトのBlade `{{ }}`文は、XSS攻撃を防ぐために、PHPの`htmlspecialchars`関数を通して自動的に送信します。データをエスケープしたくない場合は、次の構文を使用します。

    Hello, {!! $name !!}.

> {note} アプリケーションのユーザーによって提供されるコンテンツをエコーするときは十分に注意してください。ユーザーが入力したデータを表示するときはXSS攻撃を防ぐために、通常はエスケープする二重中括弧構文を使用してください。

<a name="blade-and-javascript-frameworks"></a>
### BladeとJavaScriptフレームワーク

多くのJavaScriptフレームワークでも「中括弧」を使用して、特定の式をブラウザに表示することを示しているため、`@`記号を使用して式をそのままにしておくように、Bladeレンダリングエンジンへ通知できます。例を確認してください。

    <h1>Laravel</h1>

    Hello, @{{ name }}.

この例の`@`記号はBladeが削除します。そして、`{{ name }}`式はBladeエンジンによって変更されないので、JavaScriptフレームワークでレンダリングできます。

`@`記号は、Bladeディレクティブをエスケープするためにも使用できます。

    {{-- Bladeテンプレート --}}
    @@json()

    <!-- HTML出力 -->
    @json()

<a name="the-at-verbatim-directive"></a>
#### `@verbatim`ディレクティブ

テンプレートの大部分でJavaScript変数を表示している場合は、HTMLを`@verbatim`ディレクティブでラップして、各Bladeエコーステートメントの前に`@`記号を付ける必要がないようにできます。

    @verbatim
        <div class="container">
            Hello, {{ name }}.
        </div>
    @endverbatim

<a name="blade-directives"></a>
## Bladeディレクティブ

テンプレートの継承とデータの表示に加えて、Bladeは条件ステートメントやループなど一般的なPHP制御構造への便利なショートカットも提供しています。こうしたショートカットは、PHP制御構造を操作するための非常にクリーンで簡潔な方法を提供する一方で、慣れ親しんだ同等のPHP構文も生かしています。

<a name="if-statements"></a>
### If文

`@if`、`@elseif`、`@else`、`@endif`ディレクティブを使用して`if`ステートメントを作成できます。これらのディレクティブは、対応するPHPの構文と同じように機能します。

    @if (count($records) === 1)
        I have one record!
    @elseif (count($records) > 1)
        I have multiple records!
    @else
        I don't have any records!
    @endif

使いやすいように、Bladeは`@unless`ディレクティブも提供しています。

    @unless (Auth::check())
        You are not signed in.
    @endunless

すでに説明した条件付きディレクティブに加えて、`@isset`および`@empty`ディレクティブをそれぞれのPHP関数の便利なショートカットとして使用できます。

    @isset($records)
        // $recordsが定義されており、nullでもない
    @endisset

    @empty($records)
        // $recordsは空
    @endempty

<a name="authentication-directives"></a>
#### 認証ディレクティブ

`@auth`および`@guest`ディレクティブを使用すると、現在のユーザーが[認証済み](/docs/{{version}}/authentication)であるか、ゲストであるかを簡潔に判断できます。

    @auth
        // ユーザーは認証済み
    @endauth

    @guest
        // ユーザーは認証されていない
    @endguest

必要に応じて、`@auth`および`@guest`ディレクティブを使用するときにチェックする必要がある認証ガードを指定できます。

    @auth('admin')
        // ユーザーは認証済み
    @endauth

    @guest('admin')
        // ユーザーは認証されていない
    @endguest

<a name="environment-directives"></a>
#### 環境ディレクティブ

`@production`ディレクティブを使用して、アプリケーションが本番環境で実行されているかを確認できます。

    @production
        // 本番環境だけのコンテンツ
    @endproduction

または、`@env`ディレクティブを使用して、アプリケーションが特定の環境で実行されているかどうかを判断できます。

    @env('staging')
        // アプリケーションは"staging"環境で動いている
    @endenv

    @env(['staging', 'production'])
        // アプリケーションは"staging"か"production"環境で動いている
    @endenv

<a name="section-directives"></a>
#### セクションディレクティブ

`@hasSection`ディレクティブを使用して、テンプレート継承セクションにコンテンツがあるかどうかを判断できます。

```html
@hasSection('navigation')
    <div class="pull-right">
        @yield('navigation')
    </div>

    <div class="clearfix"></div>
@endif
```

`sectionMissing`ディレクティブを使用して、セクションにコンテンツがないかどうかを判断できます。

```html
@sectionMissing('navigation')
    <div class="pull-right">
        @include('default-navigation')
    </div>
@endif
```

<a name="switch-statements"></a>
### Switch文

Switchステートメントは、`@switch`、`@case`、`@break`、`@default`、`@endswitch`ディレクティブを使用して作成できます。

    @switch($i)
        @case(1)
            最初のケース
            @break

        @case(2)
            ２番目のケース
            @break

        @default
            デフォルトケース
    @endswitch

<a name="loops"></a>
### 繰り返し

条件文に加えて、BladeはPHPのループ構造を操作するための簡単なディレクティブを提供します。繰り返しますが、これらの各ディレクティブは、対応するPHPと同じように機能します。

    @for ($i = 0; $i < 10; $i++)
        The current value is {{ $i }}
    @endfor

    @foreach ($users as $user)
        <p>This is user {{ $user->id }}</p>
    @endforeach

    @forelse ($users as $user)
        <li>{{ $user->name }}</li>
    @empty
        <p>ユーザーが存在しない</p>
    @endforelse

    @while (true)
        <p>無限にループ中。</p>
    @endwhile

> {tip} ループするときは、[ループ変数](#the-loop-variable)を使用して、ループの最初の反復か最後の反復かなど、ループに関する重要な情報を取得できます。

ループを使用する場合は、`@continue`および`@break`ディレクティブを使用して、ループを終了するか、現在の反復をスキップすることもできます。

    @foreach ($users as $user)
        @if ($user->type == 1)
            @continue
        @endif

        <li>{{ $user->name }}</li>

        @if ($user->number == 5)
            @break
        @endif
    @endforeach

ディレクティブ宣言に継続条件または中断条件を含めることもできます。

    @foreach ($users as $user)
        @continue($user->type == 1)

        <li>{{ $user->name }}</li>

        @break($user->number == 5)
    @endforeach

<a name="the-loop-variable"></a>
### ループ変数

ループするとき、`$loop`変数がループ内で利用可能になります。この変数は、現在のループインデックスや、これがループの最初または最後の反復であるかどうかなど、いくつかの有用な情報へのアクセスを提供します。

    @foreach ($users as $user)
        @if ($loop->first)
            ここは最初の繰り返し
        @endif

        @if ($loop->last)
            ここは最後の繰り返し
        @endif

        <p>This is user {{ $user->id }}</p>
    @endforeach

ネストしたループ内にいる場合は、`parent`プロパティを介して親ループの`$loop`変数にアクセスできます。

    @foreach ($users as $user)
        @foreach ($user->posts as $post)
            @if ($loop->parent->first)
                ここは親ループの最初の繰り返し処理
            @endif
        @endforeach
    @endforeach

`$loop`変数は、他にもいろいろと便利なプロパティを持っています。

プロパティ  | 説明
------------- | -------------
`$loop->index`  |  現在の反復のインデックス（初期値０）
`$loop->iteration`  |  現在の反復数（初期値１）。
`$loop->remaining`  |  反復の残数。
`$loop->count`  |  反復している配列の総アイテム数
`$loop->first`  |  ループの最初の繰り返しか判定
`$loop->last`  |  ループの最後の繰り返しか判定
`$loop->even`  |  今回が偶数回目の繰り返しか判定
`$loop->odd`  |  今回が奇数回目の繰り返しか判定
`$loop->depth`  |  現在のループのネストレベル
`$loop->parent`  |  ループがネストしている場合、親のループ変数

<a name="comments"></a>
### コメント

Bladeでは、ビューにコメントを定義することもできます。ただし、HTMLコメントとは異なり、Bladeコメントはアプリケーションから返されるHTMLに含まれていません。

    {{-- このコメントは、レンダーするHTMLで表示されません --}}

<a name="including-subviews"></a>
### サブビューの読み込み

> {tip} `@include`ディレクティブは自由に使用できますが、Blade[コンポーネント](#components)は同様の機能を提供しつつ、データや属性のバインドなど`@include`ディレクティブに比べていくつかの利点があります。

Bladeの`@include`ディレクティブを使用すると、別のビュー内からBladeビューを読み込めます。親ビューで使用できるすべての変数は、読み込むビューで使用できます。

```html
<div>
    @include('shared.errors')

    <form>
        <!-- フォームのコンテンツ -->
    </form>
</div>
```

読み込むビューは親ビューで使用可能なすべてのデータを継承しますが、読み込むビューで使用可能にする必要がある追加データの配列を渡すこともできます。

    @include('view.name', ['status' => 'complete'])

存在しないビューを`@include`しようとすると、Laravelはエラーを投げます。存在する場合と存在しない場合があるビューを読み込む場合は、`@includeIf`ディレクティブを使用する必要があります。

    @includeIf('view.name', ['status' => 'complete'])

指定する論理式が`true`か`false`と評価された場合に、ビューを`@include`したい場合は、`@includeWhen`および`@includeUnless`ディレクティブを使用できます。

    @includeWhen($boolean, 'view.name', ['status' => 'complete'])

    @includeUnless($boolean, 'view.name', ['status' => 'complete'])

指定するビュー配列中、存在する最初のビューを含めるには、`includeFirst`ディレクティブを使用します。

    @includeFirst(['custom.admin', 'admin'], ['status' => 'complete'])

> {note} Bladeビューで`__DIR__`と`__FILE__`定数は使用しないでください。これらは、キャッシュされコンパイルされたビューの場所を参照するためです。

<a name="rendering-views-for-collections"></a>
#### コレクションのビューのレンダー

ループと読み込みをBladeの`@each`ディレクティブで1行に組み合わせられます。

    @each('view.name', $jobs, 'job')

`@each`ディレクティブの最初の引数は、配列またはコレクション内の各要素に対してレンダーするビューです。２番目の引数は、反復する配列またはコレクションであり、３番目の引数は、ビュー内で現在の反復要素に割り当てる変数名です。したがって、たとえば`jobs`配列を反復処理する場合、通常はビュー内で`job`変数として各ジョブにアクセスしたいと思います。現在の反復の配列キーは、ビュー内で`key`変数として使用できます。

`@each`ディレクティブに４番目の引数を渡すこともできます。この引数は、指定された配列が空の場合にレンダーするビューを指定します。

    @each('view.name', $jobs, 'job', 'view.empty')

> {note} `@each`を使いレンダーするビューは、親ビューから変数を継承しません。子ビューでそうした変数が必要な場合は、代わりに`@foreach`と`@include`ディレクティブを使用する必要があります。

<a name="the-once-directive"></a>
### `@once`ディレクティブ

`@once`ディレクティブを使用すると、レンダリングサイクルごとに１回だけ評価されるテンプレートの部分を定義できます。これは、[stacks](#stacks)を使用してJavaScriptの特定の部分をページのヘッダへ入れ込むのに役立つでしょう。たとえば、ループ内で特定の[コンポーネント](#components)をレンダーする場合に、コンポーネントが最初にレンダーされるときにのみ、あるJavaScriptをヘッダに入れ込みたい場合があるとしましょう。

    @once
        @push('scripts')
            <script>
                // カスタムJavaScript…
            </script>
        @endpush
    @endonce

<a name="raw-php"></a>
### 生PHP

状況によっては、PHPコードをビューに埋め込めると便利です。Blade`@php`ディレクティブを使用して、テンプレート内でプレーンPHPのブロックを定義し、実行できます。

    @php
        $counter = 1;
    @endphp

<a name="components"></a>
## コンポーネント

コンポーネントとスロットは、セクション、レイアウト、インクルードと同様の利便性を提供します。ただし、コンポーネントとスロットのメンタルモデルが理解しやすいと感じる人もいるでしょう。コンポーネントを作成するには、クラスベースのコンポーネントと匿名コンポーネントの2つのアプローチがあります。

クラスベースのコンポーネントを作成するには、`make:component` Artisanコマンドを使用できます。コンポーネントの使用方法を説明するために、単純な「アラート（`Alert`）」コンポーネントを作成します。`make:component`コマンドは、コンポーネントを`App\View\Components`ディレクトリに配置します。

    php artisan make:component Alert

`make:component`コマンドは、コンポーネントのビューテンプレートも作成します。ビューは`resources/views/components`ディレクトリに配置されます。独自のアプリケーション用のコンポーネントを作成する場合、コンポーネントは`app/View/Components`ディレクトリと`resources/views/components`ディレクトリ内で自動的に検出するため、通常それ以上のコンポーネント登録は必要ありません。

サブディレクトリ内にコンポーネントを作成することもできます。

    php artisan make:component Forms/Input

上記のコマンドは、`App\View\Components\Forms`ディレクトリに`Input`コンポーネントを作成し、ビューは`resources/views/components/forms`ディレクトリに配置します。

<a name="manually-registering-package-components"></a>
#### パッケージコンポーネントの手動登録

独自のアプリケーション用コンポーネントを作成する場合、コンポーネントを`app/View/Components`ディレクトリと`resources/views/components`ディレクトリ内で自動的に検出します。

ただし、Bladeコンポーネントを利用するパッケージを構築する場合は、コンポーネントクラスとそのHTMLタグエイリアスを手動で登録する必要があります。通常、コンポーネントはパッケージのサービスプロバイダの`boot`メソッドに登録する必要があります。

    use Illuminate\Support\Facades\Blade;

    /**
     * パッケージの全サービスの初期起動処理
     */
    public function boot()
    {
        Blade::component('package-alert', Alert::class);
    }

コンポーネントを登録すると、タグエイリアスを使用してレンダリングできます。

    <x-package-alert/>

または、規約により、`componentNamespace`メソッドを使用してコンポーネントクラスを自動ロードすることもできます。たとえば、`Nightshade`パッケージには、`Package\Views\Components`名前空間内にある`Calendar`と`ColorPicker`コンポーネントが含まれているとしましょう。

    use Illuminate\Support\Facades\Blade;

    /**
     * パッケージの全サービスの初期起動処理
     *
     * @return void
     */
    public function boot()
    {
        Blade::componentNamespace('Nightshade\\Views\\Components', 'nightshade');
    }

これにより、`package-name::`構文を使用して、ベンダーの名前空間でパッケージコンポーネントが使用できるようになります。

    <x-nightshade::calendar />
    <x-nightshade::color-picker />

Bladeは、コンポーネント名のパスカルケースを使い、コンポーネントにリンクしているクラスを自動的に検出します。サブディレクトリもサポートしており、「ドット」表記を使用します。

<a name="rendering-components"></a>
### コンポーネントのレンダー

コンポーネントを表示するために、Bladeテンプレート１つの中でBladeコンポーネントタグを使用できます。Bladeコンポーネントタグは、文字列`x-`で始まり、その後にコンポーネントクラスのケバブケース名を続けます。

    <x-alert/>

    <x-user-profile/>

コンポーネントクラスが`App\View\Components`ディレクトリ内のより深い場所にネストしている場合は、`.`文字を使用してディレクトリのネストを表せます。たとえば、コンポーネントが`App\View\Components\Inputs\Button.php`にあるとしたら、以下のようにレンダリングできます。

    <x-inputs.button/>

<a name="passing-data-to-components"></a>
### コンポーネントへのデータ渡し

HTML属性を使用してBladeコンポーネントへデータを渡せます。ハードコードするプリミティブ値は、単純なHTML属性文字列を使用してコンポーネントに渡すことができます。PHPの式と変数は、接頭辞として`:`文字を使用する属性を介してコンポーネントに渡す必要があります。

    <x-alert type="error" :message="$message"/>

コンポーネントの必要なデータは、そのクラスコンストラクターで定義する必要があります。コンポーネントのすべてのパブリックプロパティは、コンポーネントのビューで自動的に使用可能になります。コンポーネントの`render`メソッドからビューにデータを渡す必要はありません。

    <?php

    namespace App\View\Components;

    use Illuminate\View\Component;

    class Alert extends Component
    {
        /**
         * 警告タイプ
         *
         * @var string
         */
        public $type;

        /**
         * 警告メッセージ
         *
         * @var string
         */
        public $message;

        /**
         * コンポーネントインスタンスを作成
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
         * コンポーネントを表すビュー／コンテンツを取得
         *
         * @return \Illuminate\View\View|\Closure|string
         */
        public function render()
        {
            return view('components.alert');
        }
    }

コンポーネントをレンダーするときに、変数を名前でエコーすることにより、コンポーネントのパブリック変数の内容を表示できます。

```html
<div class="alert alert-{{ $type }}">
    {{ $message }}
</div>
```

<a name="casing"></a>
#### ケース形式

コンポーネントコンストラクタの引数はキャメルケース（`camelCase`）を使用して指定する必要がありますが、HTML属性で引数名を参照する場合はケバブケース（`kebab-case`）を使用する必要があります。たとえば、次のようにコンポーネントコンストラクタに渡します。

    /**
     * コンポーネントインスタンスの作成
     *
     * @param  string  $alertType
     * @return void
     */
    public function __construct($alertType)
    {
        $this->alertType = $alertType;
    }

`$alertType`引数は、次のようにコンポーネントに提供できます。

    <x-alert alert-type="danger" />

<a name="escaping-attribute-rendering"></a>
#### 属性レンダーのエスケープ

alpine.jsなどのJavaScriptフレームワークもコロンプレフィックスで属性を指定するため、属性がPHP式ではないことをBladeへ知らせるために二重のコロン(`::`)プレフィックスを使用してください。たとえば、以下のコンポーネントが存在しているとしましょう。

    <x-button ::class="{ danger: isDeleting }">
        Submit
    </x-button>

Bladeにより、以下のHTMLとしてレンダーされます。

    <button :class="{ danger: isDeleting }">
        Submit
    </button>

<a name="component-methods"></a>
#### コンポーネントメソッド

コンポーネントテンプレートで使用できるパブリック変数に加えて、コンポーネントの任意のパブリックメソッドを呼び出すこともできます。たとえば、`isSelected`メソッドを持つコンポーネントを想像してみてください。

    /**
     * 指定したオプションが現在選択されているオプションであるか判別
     *
     * @param  string  $option
     * @return bool
     */
    public function isSelected($option)
    {
        return $option === $this->selected;
    }

メソッドの名前に一致する変数を呼び出すことにより、コンポーネントテンプレートでこのメソッドを実行できます。

    <option {{ $isSelected($value) ? 'selected="selected"' : '' }} value="{{ $value }}">
        {{ $label }}
    </option>

<a name="using-attributes-slots-within-component-class"></a>
#### コンポーネントクラス内の属性とスロットへのアクセス

Bladeコンポーネントを使用すると、クラスのrenderメソッド内のコンポーネント名、属性、およびスロットにアクセスすることもできます。ただし、このデータにアクセスするには、コンポーネントの`render`メソッドからクロージャを返す必要があります。クロージャは、唯一の引数として`$data`配列を取ります。この配列はコンポーネントに関する情報を提供するいくつかの要素が含んでいます。

    /**
     * コンポーネントを表すビュー／コンテンツを取得
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

`componentName`は、HTMLタグで`x-`プレフィックスの後に使用されている名前と同じです。したがって、`<x-alert/>`の`componentName`は`alert`になります。`attributes`要素には、HTMLタグに存在していたすべての属性が含まれます。`slot`要素は、コンポーネントのスロットの内容を含む`Illuminate\Support\HtmlString`インスタンスです。

クロージャは文字列を返す必要があります。返された文字列が既存のビューに対応している場合、そのビューがレンダリングされます。それ以外の場合、返される文字列はインラインBladeビューとして評価されます。

<a name="additional-dependencies"></a>
#### 追加の依存関係

コンポーネントがLaravelの[サービスコンテナ](/docs/{{version}}/container)からの依存を必要とする場合、コンポーネントのデータ属性の前にそれらをリストすると、コンテナによって自動的に注入されます。

    use App\Services\AlertCreator

    /**
     * コンポーネントインスタンスを作成
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

<a name="hiding-attributes-and-methods"></a>
#### 非表示属性/メソッド

パブリックメソッドまたはプロパティがコンポーネントテンプレートへ変数として公開されないようにする場合は、コンポーネントの`$except`配列プロパティへ追加してください。

    <?php

    namespace App\View\Components;

    use Illuminate\View\Component;

    class Alert extends Component
    {
        /**
         * alertタイプ
         *
         * @var string
         */
        public $type;

        /**
         * コンポーネントテンプレートに公開してはいけないプロパティ／メソッド。
         *
         * @var array
         */
        protected $except = ['type'];
    }

<a name="component-attributes"></a>
### コンポーネント属性

データ属性をコンポーネントへ渡す方法は、すでに説明しました。ただ、コンポーネントが機能するためには、不必要な`class`などの追加のHTML属性データを指定する必要が起きることもあります。通常これらの追加の属性は、コンポーネントテンプレートのルート要素に渡します。たとえば、次のように`alert`コンポーネントをレンダリングしたいとします。

    <x-alert type="error" :message="$message" class="mt-4"/>

コンポーネントのコンストラクタの一部ではないすべての属性は、コンポーネントの「属性バッグ」に自動的に追加されます。この属性バッグは、`$attributes`変数を通じてコンポーネントで自動的に使用可能になります。この変数をエコーすることにより、すべての属性をコンポーネント内でレンダリングできます。

    <div {{ $attributes }}>
        <!-- コンポーネントの内容 -->
    </div>

> {note} コンポーネントタグ内での`@env`などのディレクティブの使用は、現時点でサポートしていません。たとえば、`<x-alert :live="@env('production')"/>`はコンパイルしません。

<a name="default-merged-attributes"></a>
#### デフォルト/マージした属性

属性のデフォルト値を指定したり、コンポーネントの属性の一部へ追加の値をマージしたりする必要のある場合があります。これを実現するには、属性バッグの`merge`メソッドを使用できます。このメソッドは、コンポーネントに常に適用する必要のあるデフォルトのCSSクラスのセットを定義する場合、特に便利です。

    <div {{ $attributes->merge(['class' => 'alert alert-'.$type]) }}>
        {{ $message }}
    </div>

このコンポーネントが以下のように使用されると仮定しましょう。

    <x-alert type="error" :message="$message" class="mb-4"/>

コンポーネントが最終的にレンダーするHTMLは、以下のようになります。

```html
<div class="alert alert-error mb-4">
    <!-- $message変数の中身 -->
</div>
```

<a name="conditionally-merge-classes"></a>
#### 条件付きマージクラス

特定の条件が`true`である場合に、クラスをマージしたい場合があります。これは`class`メソッドで実行でき、クラスの配列を引数に取ります。配列のキーには追加したいクラスを含み、値に論理式を指定します。配列要素に数字キーがある場合は、レンダーするクラスリストへ常に含まれます。

    <div {{ $attributes->class(['p-4', 'bg-red' => $hasError]) }}>
        {{ $message }}
    </div>

他の属性をコンポーネントにマージする必要がある場合は、`merge`メソッドを`class`メソッドへチェーンできます。

    <button {{ $attributes->class(['p-4'])->merge(['type' => 'button']) }}>
        {{ $slot }}
    </button>

<a name="non-class-attribute-merging"></a>
#### 非クラス属性のマージ

`class`属性ではない属性をマージする場合、`merge`メソッドへ指定する値は属性の「デフォルト」値と見なします。ただし、`class`属性とは異なり、こうした属性は挿入した属性値とマージしません。代わりに上書きします。たとえば、`button`コンポーネントの実装は次のようになるでしょう。

    <button {{ $attributes->merge(['type' => 'button']) }}>
        {{ $slot }}
    </button>

カスタム`type`を指定してボタンコンポーネントをレンダーすると、このコンポーネントを使用するときにそれが指定されます。タイプが指定されない場合、`button`タイプを使用します。

    <x-button type="submit">
        Submit
    </x-button>

この例でレンダリングされる、`button`コンポーネントのHTMLは以下のようになります。

    <button type="submit">
        Submit
    </button>

`class`以外の属性にデフォルト値と挿入する値を結合させたい場合は、`prepends`メソッドを使用します。この例では、`data-controller`属性は常に`profile-controller`で始まり、追加で挿入する`data-controller`値はデフォルト値の後に配置されます。

    <div {{ $attributes->merge(['data-controller' => $attributes->prepends('profile-controller')]) }}>
        {{ $slot }}
    </div>

<a name="filtering-attributes"></a>
#### 属性の取得とフィルタリング

`filter`メソッドを使用して属性をフィルタリングできます。このメソッドは、属性を属性バッグへ保持する場合に`true`を返す必要があるクロージャを引数に取ります。

    {{ $attributes->filter(fn ($value, $key) => $key == 'foo') }}

キーが特定の文字列で始まるすべての属性を取得するために、`whereStartsWith`メソッドを使用できます。

    {{ $attributes->whereStartsWith('wire:model') }}

逆に、`whereDoesntStartWith`メソッドは、指定する文字列で始まるすべての属性を除外するために使用します。

    {{ $attributes->whereDoesntStartWith('wire:model') }}

`first`メソッドを使用して、特定の属性バッグの最初の属性をレンダーできます。

    {{ $attributes->whereStartsWith('wire:model')->first() }}

属性がコンポーネントに存在するか確認する場合は、`has`メソッドを使用できます。このメソッドは、属性名をその唯一の引数に取り、属性が存在していることを示す論理値を返します。

    @if ($attributes->has('class'))
        <div>Class attribute is present</div>
    @endif

`get`メソッドを使用して特定の属性の値を取得できます。

    {{ $attributes->get('class') }}

<a name="reserved-keywords"></a>
### 予約語

コンポーネントをレンダーするBladeの内部使用のため、いくつかのキーワードを予約しています。以下のキーワードは、コンポーネント内のパブリックプロパティまたはメソッド名として定できません。

<div class="content-list" markdown="1">
- `data`
- `render`
- `resolveView`
- `shouldRender`
- `view`
- `withAttributes`
- `withName`
</div>

<a name="slots"></a>
### スロット

多くの場合、「スロット」を利用して追加のコンテンツをコンポーネントに渡す必要があることでしょう。コンポーネントスロットは、`$slot`変数をエコーしレンダーします。この概念を学習するために、`alert`コンポーネントに次のマークアップがあると過程してみましょう。

```html
<!-- /resources/views/components/alert.blade.php -->

<div class="alert alert-danger">
    {{ $slot }}
</div>
```

コンポーネントにコンテンツを挿入することにより、そのコンテンツを`slot`に渡せます。

```html
<x-alert>
    <strong>Whoops!</strong> Something went wrong!
</x-alert>
```

コンポーネント内の異なる場所へ、複数の異なるスロットをレンダーする必要のある場合があります。「タイトル（"title"）」スロットへ挿入できるようにするため、アラートコンポーネントを変更してみましょう。

```html
<!-- /resources/views/components/alert.blade.php -->

<span class="alert-title">{{ $title }}</span>

<div class="alert alert-danger">
    {{ $slot }}
</div>
```

`x-slot`タグを使用して、名前付きスロットのコンテンツを定義できます。明示的に`x-slot`タグ内にないコンテンツは、`$slot`変数のコンポーネントに渡されます。

```html
<x-alert>
    <x-slot name="title">
        Server Error
    </x-slot>

    <strong>Whoops!</strong> Something went wrong!
</x-alert>
```

<a name="scoped-slots"></a>
#### スコープ付きスロット

VueのようなJavaScriptフレームワークを使用している方は「スコープ付きスロット」に慣れていると思います。これは、スロットの中でコンポーネントのデータやメソッドへアクセスできる機構です。コンポーネントにパブリックメソッドまたはプロパティを定義し、`$component`変数を使いスロット内のコンポーネントにアクセスすることで、Laravelと同様の動作を実現できます。この例では、`x-alert`コンポーネントのコンポーネントクラスにパブリック`formatAlert`メソッドが定義されていると想定しています。

```html
<x-alert>
    <x-slot name="title">
        {{ $component->formatAlert('Server Error') }}
    </x-slot>

    <strong>Whoops!</strong> Something went wrong!
</x-alert>
```

<a name="inline-component-views"></a>
### インラインコンポーネントビュー

非常に小さいコンポーネントの場合、コンポーネントクラスとビューテンプレートの両方を管理するのは面倒だと感じるかもしれません。そのため、コンポーネントのマークアップを`render`メソッドから直接返すことができます。

    /**
     * コンポーネントを表すビュー／コンテンツの取得
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

<a name="generating-inline-view-components"></a>
#### インラインビューコンポーネントの生成

インラインビューをレンダーするコンポーネントを作成するには、`make:component`コマンドを実行するときに`inline`オプションを使用します。

    php artisan make:component Alert --inline

<a name="anonymous-components"></a>
### 匿名コンポーネント

インラインコンポーネントと同様に、匿名コンポーネントは、単一のファイルを介してコンポーネントを管理するためのメカニズムを提供します。ただし、匿名コンポーネントは単一のビューファイルを利用し、関連するクラスはありません。匿名コンポーネントを定義するには、`resources/views/components`ディレクトリ内にBladeテンプレートを配置するだけで済みます。たとえば、`resources/views/components/alert.blade.php`でコンポーネントを定義すると、以下のようにレンダーできます。

    <x-alert/>

`.`文字を使用して、コンポーネントが`components`ディレクトリ内のより深い場所にネストしていることを示せます。たとえば、コンポーネントが`resources/views/components/input/button.blade.php`で定義されていると仮定すると、次のようにレンダリングできます。

    <x-inputs.button/>

<a name="data-properties-attributes"></a>
#### データのプロパティ／属性

匿名コンポーネントには関連付けたクラスがないため、どのデータを変数としてコンポーネントに渡す必要があり、どの属性をコンポーネントの[属性バッグ](#component-attributes)に配置する必要があるか、どう区別するか疑問に思われるかもしれません。

コンポーネントのBladeテンプレートの上部にある`@props`ディレクティブを使用して、データ変数と見なすべき属性を指定できます。コンポーネント上の他のすべての属性は、コンポーネントの属性バッグを介して利用します。データ変数にデフォルト値を指定する場合は、変数の名前を配列キーに指定し、デフォルト値を配列値として指定します。

    <!-- /resources/views/components/alert.blade.php -->

    @props(['type' => 'info', 'message'])

    <div {{ $attributes->merge(['class' => 'alert alert-'.$type]) }}>
        {{ $message }}
    </div>

上記のコンポーネント定義をすると、そのコンポーネントは次のようにレンダーできます。

    <x-alert type="error" :message="$message" class="mb-4"/>

<a name="dynamic-components"></a>
### 動的コンポーネント

コンポーネントをレンダーする必要があるが、実行時までどのコンポーネントをレンダーする必要のわからない場合があります。その状況では、Laravel組み込みの`dynamic-component`コンポーネントを使用して、ランタイム値または変数に基づいてコンポーネントをレンダーできます。

    <x-dynamic-component :component="$componentName" class="mt-4" />

<a name="manually-registering-components"></a>
### コンポーネントの手動登録

> {note} コンポーネントの手動登録に関する以下のドキュメントは、主にビューコンポーネントを含むLaravelパッケージを作成している人に当てはまります。パッケージを作成していない場合は、コンポーネントドキュメントのこの箇所は関係ないでしょう。

独自のアプリケーション用のコンポーネントを作成する場合、コンポーネントは`app/View/Components`ディレクトリと`resources/views/components`ディレクトリ内で自動的に検出されます。

ただし、Bladeコンポーネントを利用するパッケージを構築する場合、またはコンポーネントを従来とは異なるディレクトリに配置する場合は、Laravelがコンポーネントの場所を認識できるように、コンポーネントクラスとそのHTMLタグエイリアスを手動で登録する必要があります。通常、コンポーネントはパッケージのサービスプロバイダの`boot`メソッドで、登録する必要があります。

    use Illuminate\Support\Facades\Blade;
    use VendorPackage\View\Components\AlertComponent;

    /**
     * パッケージの全サービスの初期起動処理
     *
     * @return void
     */
    public function boot()
    {
        Blade::component('package-alert', AlertComponent::class);
    }

コンポーネントを登録すると、タグエイリアスを使用してレンダーできます。

    <x-package-alert/>

#### パッケージコンポーネントの自動ロード

または、規約により、`componentNamespace`メソッドを使用してコンポーネントクラスを自動ロードすることもできます。たとえば、`Nightshade`パッケージには、`Package\Views\Components`名前空間内にある`Calendar`と`ColorPicker`コンポーネントが含まれているとしましょう。

    use Illuminate\Support\Facades\Blade;

    /**
     * パッケージの全サービスの初期起動処理
     *
     * @return void
     */
    public function boot()
    {
        Blade::componentNamespace('Nightshade\\Views\\Components', 'nightshade');
    }

これにより、`package-name::`構文を使用して、ベンダーの名前空間でパッケージコンポーネントを使用できるようになります。

    <x-nightshade::calendar />
    <x-nightshade::color-picker />

Bladeは、コンポーネント名のパスカルケースを使い、コンポーネントにリンクしているクラスを自動的に検出します。サブディレクトリもサポートしており、「ドット」表記を使用します

<a name="building-layouts"></a>
## レイアウト構築

<a name="layouts-using-components"></a>
### コンポーネント使用の構築

ほとんどのWebアプリケーションは、さまざまなページ間で同じ一般的なレイアウトを共有しています。私たちが作成するすべてのビューでレイアウト全体のHTMLを繰り返さなければならない場合、アプリケーションを維持するのは非常に面倒になると懸念できるでしょう。幸いに、このレイアウトを単一の[Bladeコンポーネント](#コンポーネント)として定義し、アプリケーション全体で使用できるため、便利です。

<a name="defining-the-layout-component"></a>
#### レイアウトコンポーネントの定義

例として、「TODO」リストアプリケーションを構築していると想像してください。次のような`layout`コンポーネントを定義できるでしょう。

```html
<!-- resources/views/components/layout.blade.php -->

<html>
    <head>
        <title>{{ $title ?? 'Todo Manager' }}</title>
    </head>
    <body>
        <h1>Todos</h1>
        <hr/>
        {{ $slot }}
    </body>
</html>
```

<a name="applying-the-layout-component"></a>
#### レイアウトコンポーネントの適用

`layout`コンポーネントを定義したら、コンポーネントを利用するBladeビューを作成できます。この例では、タスクリストを表示する簡単なビューを定義します。

```html
<!-- resources/views/tasks.blade.php -->

<x-layout>
    @foreach ($tasks as $task)
        {{ $task }}
    @endforeach
</x-layout>
```

コンポーネントへ挿入されるコンテンツは、`layout`コンポーネント内のデフォルト`$slot`変数として提供されることを覚えてください。お気づきかもしれませんが、`layout`も提供されるのであれば、`$title`スロットを尊重します。それ以外の場合は、デフォルトのタイトルが表示されます。[コンポーネントのドキュメント](#components)で説明している標準スロット構文を使用して、タスクリストビューからカスタムタイトルを挿入できます。

```html
<!-- resources/views/tasks.blade.php -->

<x-layout>
    <x-slot name="title">
        カスタムタイトル
    </x-slot>

    @foreach ($tasks as $task)
        {{ $task }}
    @endforeach
</x-layout>
```

レイアウトとタスクリストのビューを定義したので、ルートから`task`ビューを返す必要があります。

    use App\Models\Task;

    Route::get('/tasks', function () {
        return view('tasks', ['tasks' => Task::all()]);
    });

<a name="layouts-using-template-inheritance"></a>
### テンプレート継承を使用するレイアウト

<a name="defining-a-layout"></a>
#### レイアウトの定義

レイアウトは、「テンプレート継承」を介して作成することもできます。これは、[コンポーネント](#components)の導入前にアプリケーションを構築するための主な方法でした。

始めるにあたり、簡単な例を見てみましょう。まず、ページレイアウトを調べます。ほとんどのWebアプリケーションはさまざまなページ間で同じ一般的なレイアウトを共有するため、このレイアウトを単一のBladeビューとして定義でき、便利です。

```html
<!-- resources/views/layouts/app.blade.php -->

<html>
    <head>
        <title>App Name - @yield('title')</title>
    </head>
    <body>
        @section('sidebar')
            This is the master sidebar.
        @show

        <div class="container">
            @yield('content')
        </div>
    </body>
</html>
```

ご覧のとおり、このファイルには典型的なHTMLマークアップが含まれています。ただし、`@section`と`@yield`ディレクティブに注意してください。名前が暗示するように、`@section`ディレクティブは、コンテンツのセクションを定義しますが、`@yield`ディレクティブは指定するセクションの内容を表示するために使用します。

アプリケーションのレイアウトを定義したので、レイアウトを継承する子ページを定義しましょう。

<a name="extending-a-layout"></a>
#### レイアウトの拡張

子ビューを定義するときは、`@extends` Bladeディレクティブを使用して、子ビューが「継承する」のレイアウトを指定します。Bladeレイアウトを拡張するビューは、`@section`ディレクティブを使用してレイアウトのセクションにコンテンツを挿入できます。上記の例で見たように、これらのセクションの内容は`@yield`を使用してレイアウトへ表示できます。

```html
<!-- resources/views/child.blade.php -->

@extends('layouts.app')

@section('title', 'Page Title')

@section('sidebar')
    @@parent

    <p>これはマスターサイドバーに追加される</p>
@endsection

@section('content')
    <p>これは本文の内容</p>
@endsection
```

この例では、`sidebar`のセクションは、`@parent`ディレクティブを利用して、(上書きするのではなく)、レイアウトのサイドバーにコンテンツを追加しています。`@parent`ディレクティブは、ビューをレンダーするときにレイアウトの内容へ置き換えられます。

> {tip} 前の例とは反対に、この「サイドバー」のセクションは`@show`の代わりに`@endection`で終わります。`@endection`ディレクティブはセクションを定義するだけですが、一方の`@show`は定義し、そのセクションを**すぐに挿入**します。

`@yield`ディレクティブは、デフォルト値を２番目の引数に取ります。この値は、生成するセクションが未定義の場合にレンダーされます。

    @yield('content', 'Default content')

<a name="forms"></a>
## フォーム

<a name="csrf-field"></a>
### CSRFフィールド

アプリケーションでHTMLフォームを定義したときは、[CSRF保護]((/docs/{{version}}/csrf))ミドルウェアがリクエストをバリデートできるように、フォームへ隠しCSRFトークンフィールドを含める必要があります。`@csrf` Bladeディレクティブを使用してトークンフィールドを生成できます。

```html
<form method="POST" action="/profile">
    @csrf

    ...
</form>
```

<a name="method-field"></a>
### Methodフィールド

HTMLフォームは`put`、`patch`、または`delete`リクエストを作ることができないので、これらのHTTP動詞を偽装するために`_Method`隠しフィールドを追加する必要があります。`@method`Bladeディレクティブは、皆さんのためこのフィールドを作成します。

```html
<form action="/foo/bar" method="POST">
    @method('PUT')

    ...
</form>
```

<a name="validation-errors"></a>
### バリデーションエラー

指定する属性に[バリデーションエラーメッセージ](/docs/{{version}}/validation#quick-displaying-the-validation-errors)が存在するかをすばやく確認するために`@error`ディレクティブを使用できます。`@error`ディレクティブ内では、エラーメッセージを表示するため、`$message`変数をエコーできます。

```html
<!-- /resources/views/post/create.blade.php -->

<label for="title">Post Title</label>

<input id="title" type="text" class="@error('title') is-invalid @enderror">

@error('title')
    <div class="alert alert-danger">{{ $message }}</div>
@enderror
```

ページが複数のフォームを含んでいる場合にエラーメッセージを取得するため、[特定のエラーバッグの名前](/docs/{{version}}/validation#named-error-bags)を第２引数へ渡せます。

```html
<!-- /resources/views/auth.blade.php -->

<label for="email">Email address</label>

<input id="email" type="email" class="@error('email', 'login') is-invalid @enderror">

@error('email', 'login')
    <div class="alert alert-danger">{{ $message }}</div>
@enderror
```

<a name="stacks"></a>
## スタック

Bladeを使用すると、別のビューまたはレイアウトのどこか別の場所でレンダーできる名前付きスタックに入れ込めます。これは、子ビューに必要なJavaScriptライブラリを指定する場合、とくに便利です。

```html
@push('scripts')
    <script src="/example.js"></script>
@endpush
```

必要な回数だけスタックに入れ込めます。スタックしたコンテンツを完全にレンダーするには、スタックの名前を`@stack`ディレクティブに渡します。

```html
<head>
    <!-- HEADのコンテンツ -->

    @stack('scripts')
</head>
```

スタックの先頭にコンテンツを追加する場合は、`@prepend`ディレクティブを使用します。

```html
@push('scripts')
    これは２番めになる
@endpush

// Later...

@prepend('scripts')
    これが最初になる
@endprepend
```

<a name="service-injection"></a>
## サービス注入

`@inject`ディレクティブは、Laravel[サービスコンテナ](/docs/{{version}}/container)からサービスを取得するために使用します。`@inject`に渡す最初の引数は、サービスが配置される変数の名前であり、２番目の引数は解決したいサービスのクラスかインターフェイス名です。

```html
@inject('metrics', 'App\Services\MetricsService')

<div>
    Monthly Revenue: {{ $metrics->monthlyRevenue() }}.
</div>
```

<a name="extending-blade"></a>
## Bladeの拡張

Bladeでは、`directive`メソッドを使用して独自のカスタムディレクティブを定義できます。Bladeコンパイラは、カスタムディレクティブを検出すると、ディレクティブに含まれる式を使用して、提供したコールバックを呼び出します。

次の例は、指定した`$var`をフォーマットする`@datetime($var)`ディレクティブを作成します。これは`DateTime`インスタンスである必要があります。

    <?php

    namespace App\Providers;

    use Illuminate\Support\Facades\Blade;
    use Illuminate\Support\ServiceProvider;

    class AppServiceProvider extends ServiceProvider
    {
        /**
         * アプリケーションの全サービスの登録
         *
         * @return void
         */
        public function register()
        {
            //
        }

        /**
         * アプリケーションの全サービスの初期起動処理
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

ご覧のとおり、ディレクティブに渡される式に`format`メソッドをチェーンします。したがって、この例でディレクティブが生成する最終的なPHPは、以下のよ​​うになります。

    <?php echo ($var)->format('m/d/Y H:i'); ?>

> {note} Bladeディレクティブのロジックを更新した後は、キャッシュ済みのBladeビューをすべて削除する必要があります。キャッシュ済みBladeビューは、`view:clear` Artisanコマンドを使用して削除できます。

<a name="custom-if-statements"></a>
### カスタムIf文

カスタムディレクティブのプログラミングは、単純なカスタム条件ステートメントを定義するとき、必要以上の複雑さになる場合があります。そのため、Bladeには`Blade::if`メソッドが用意されており、クロージャを使用してカスタム条件付きディレクティブをすばやく定義できます。たとえば、アプリケーションのデフォルト「ディスク」の設定をチェックするカスタム条件を定義しましょう。これは、`AppServiceProvider`の`boot`メソッドで行います。

    use Illuminate\Support\Facades\Blade;

    /**
     * アプリケーションの全サービスの初期起動処理
     *
     * @return void
     */
    public function boot()
    {
        Blade::if('disk', function ($value) {
            return config('filesystems.default') === $value;
        });
    }

カスタム条件を定義すると、テンプレート内で使用できます。

```html
@disk('local')
    <!-- アプリケーションはローカルディスクを使用している -->
@elsedisk('s3')
    <!-- アプリケーションはs3ディスクを使用している -->
@else
    <!-- アプリケーションは他のディスクを使用している -->
@enddisk

@unlessdisk('local')
    <!-- アプリケーションはローカルディスクを使用していない -->
@enddisk
```
