# ビュー

- [イントロダクション](#introduction)
- [ビューの作成とレンダー](#creating-and-rendering-views)
    - [ネストしたビューディレクトリ](#nested-view-directories)
    - [最初に利用可能なビュー](#creating-the-first-available-view)
    - [ビューの存在の判定](#determining-if-a-view-exists)
- [ビューにデータを渡す](#passing-data-to-views)
    - [全ビュー間のデータ共有](#sharing-data-with-all-views)
- [ビューコンポーザ](#view-composers)
    - [View Creators](#view-creators)
- [ビューの最適化](#optimizing-views)

<a name="introduction"></a>
## イントロダクション

もちろん、ルートやコントローラから直接HTMLドキュメントの文字列全体を返すことは実用的ではありません。幸い、Laravelのビュー機能はすべてのHTMLを別々のファイルに配置できる便利な方法を提供します。ビューはプレゼンテーションロジックをコントローラ／アプリケーションロジックから分離し、`resources/views`ディレクトリ下へ保存します。単純なビューは以下のようになります。

```html
<!-- View stored in resources/views/greeting.blade.php -->

<html>
    <body>
        <h1>Hello, {{ $name }}</h1>
    </body>
</html>
```

このビューを`resources/views/greeting.blade.php`として保存し、以下のようにグローバル`view`ヘルパ関数を使用し結果を返します。

    Route::get('/', function () {
        return view('greeting', ['name' => 'James']);
    });

> {tip} Bladeテンプレートの作成方法の詳細をお探しですか？最初に完全な[Bladeドキュメント](/docs/{{version}}/ブレード)を確認してください。

<a name="creating-and-rendering-views"></a>
## ビューの作成とレンダー

アプリケーションの`resources/views`ディレクトリに`.blade.php`拡張子の付いたファイルを配置することで、ビューを作成できます。`.blade.php`拡張子は、ファイルに[Bladeテンプレート](/docs/{{version}}/blade)が含まれていることをフレームワークに通知します。BladeテンプレートはHTML、値を簡単にエコーしたり、"if"文を作成したり、データを反復処理したりできるBladeディレクティブを含みます。

ビューを作成したら、グローバルな`view`ヘルパを使用して、アプリケーションのルートまたはコントローラからビューを返すことができます。

    Route::get('/', function () {
        return view('greeting', ['name' => 'James']);
    });

ビューは、`View`ファサードを使用して返すこともできます。

    use Illuminate\Support\Facades\View;

    return View::make('greeting', ['name' => 'James']);

ご覧のとおり、`view`ヘルパに渡たす最初の引数は、`resources/views`ディレクトリ内のビューファイルの名前に対応しています。２番目の引数は、ビューで使用するデータの配列です。この場合、[Blade構文](/docs/{{version}}/ブレード)を使用してビューに表示する、`name`変数を渡しています。

<a name="nested-view-directories"></a>
### ネストしたビューディレクトリ

ビューは、`resources/views`ディレクトリのサブディレクトリ内にネストすることもできます。「ドット」表記は、ネストしたビューを参照するために使用できます。たとえば、ビューが`resources/views/admin/profile.blade.php`に保存されている場合、以下のようにアプリケーションのルート／コントローラからビューを返すことができます。

    return view('admin.profile', $data);

> {note} ビューのディレクトリ名には、`.`文字を含めてはいけません。

<a name="creating-the-first-available-view"></a>
### 最初に利用可能なビュー

`View`ファサードの`first`メソッドを使用して、指定したビューの配列に存在する最初のビューを生成できます。これは、アプリケーションまたはパッケージでビューのカスタマイズまたは上書きが許可されている場合に役立つでしょう。

    use Illuminate\Support\Facades\View;

    return View::first(['custom.admin', 'admin'], $data);

<a name="determining-if-a-view-exists"></a>
### ビューの存在の判定

ビューが存在しているかを判定する必要があれば、`View`ファサードを使います。ビューが存在していれば、`exists`メソッドは`true`を返します。

    use Illuminate\Support\Facades\View;

    if (View::exists('emails.customer')) {
        //
    }

<a name="passing-data-to-views"></a>
## ビューにデータを渡す

前例で見たように、データの配列をビューに渡し、そのデータをビューで使用できます。

    return view('greetings', ['name' => 'Victoria']);

この方法で情報を渡す場合、データはキー／値ペアの配列です。ビューにデータを渡した後、`<?php echo $name; ?>`などのデータキーを使用して、ビュー内の各値にアクセスします。

データの完全な配列を`view`ヘルパ関数に渡す代わりに、`with`メソッドを使用して個々のデータをビューへ追加することもできます。`with`メソッドはビューオブジェクトのインスタンスを返すため、ビューを返す前にメソッドのチェーンを続けられます。

    return view('greeting')
                ->with('name', 'Victoria')
                ->with('occupation', 'Astronaut');

<a name="sharing-data-with-all-views"></a>
### すべてのビューでデータを共有

時に、アプリケーションがレンダーするすべてのビューとデータを共有する必要が起きます。これは、`View`ファサードの`share`メソッドで可能です。通常、サービスプロバイダの`boot`メソッド内で`share`メソッドを呼び出す必要があります。それらを`App\Providers\AppServiceProvider`クラスへ追加するか、それらを収容するための別のサービスプロバイダを生成することもできます。

    <?php

    namespace App\Providers;

    use Illuminate\Support\Facades\View;

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
         * 全アプリケーションサービスの初期起動
         *
         * @return void
         */
        public function boot()
        {
            View::share('key', 'value');
        }
    }

<a name="view-composers"></a>
## ビューコンポーザ

ビューコンポーザは、ビューをレンダーするときに呼び出すコールバックまたはクラスメソッドです。ビューをレンダーするたびにビューへ結合するデータがある場合、ビューコンポーザを使用すると、そのロジックを１つの場所に集約できます。ビューコンポーザは、アプリケーション内の複数のルートかコントローラが同じビューを返し、常に特定のデータが必要な場合にきわめて役立ちます。

通常、ビューコンポーザーは、アプリケーションの[サービスプロバイダ](/docs/{{version}}/provider)のいずれかで登録します。この例では、このロジックを格納するために新しい`App\Providers\ViewServiceProvider`を作成したと想定しましょう。

`View`ファサードの`composer`メソッドを使用して、ビューコンポーザを登録します。Laravelには、クラスベースのビューコンポーザーのデフォルトディレクトリが含まれていないため、自由に整理できます。たとえば、`app/Http/View/Composers`ディレクトリを作成して、アプリケーションのすべてのビューコンポーザを保存できます。

    <?php

    namespace App\Providers;

    use App\Http\View\Composers\ProfileComposer;
    use Illuminate\Support\Facades\View;
    use Illuminate\Support\ServiceProvider;

    class ViewServiceProvider extends ServiceProvider
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
         * 全アプリケーションサービスの初期起動
         *
         * @return void
         */
        public function boot()
        {
            // クラスベースのコンポーザを使用する
            View::composer('profile', ProfileComposer::class);

            // クロージャベースのコンポーザを使用
            View::composer('dashboard', function ($view) {
                //
            });
        }
    }

> {note} 新しいサービスプロバイダをビューコンポーザ登録のために作成した場合は、`config/app.php`設定ファイルの`providers`配列へ追加する必要があるのを忘れないでください。

コンポーザを登録したので、`profile`ビューがレンダーされるたびに`App\Http\View\Composers\ProfileComposer`クラスの`compose`メソッドが実行されます。コンポーザクラスの例を見てみましょう。

    <?php

    namespace App\Http\View\Composers;

    use App\Repositories\UserRepository;
    use Illuminate\View\View;

    class ProfileComposer
    {
        /**
         * userリポジトリの実装
         *
         * @var UserRepository
         */
        protected $users;

        /**
         * 新しいプロフィールコンポーザの生成
         *
         * @param  \App\Repositories\UserRepository  $users
         * @return void
         */
        public function __construct(UserRepository $users)
        {
            // 依存はサービスコンテナにより自動的に解決される
            $this->users = $users;
        }

        /**
         * データをビューと結合
         *
         * @param  \Illuminate\View\View  $view
         * @return void
         */
        public function compose(View $view)
        {
            $view->with('count', $this->users->count());
        }
    }

ご覧のとおり、すべてのビューコンポーザは[サービスコンテナ](/docs/{{version}}/container)を介して依存解決されるため、コンポーザのコンストラクタ内で必要な依存関係を依存注入できます。

<a name="attaching-a-composer-to-multiple-views"></a>
#### 複数ビューへの適用

複数のビューにビューコンポーザを適用するには、`composer`メソッドの最初の引数にビューの配列を渡してください。

    use App\Http\Views\Composers\MultiComposer;

    View::composer(
        ['profile', 'dashboard'],
        MultiComposer::class
    );

全ビューコンポーザに適用するため、`composer`メソッドは`*`をワイルドカードとして使用できます。

    View::composer('*', function ($view) {
        //
    });

<a name="view-creators"></a>
### ビュークリエータ

ビューの「クリエータ」は、ビューコンポーザと非常によく似ています。ただし、ビューがレンダリングされるまで待つのではなく、ビューがインスタンス化された直後に実行されます。ビュークリエータを登録するには、`creator`メソッドを使用します。

    use App\Http\View\Creators\ProfileCreator;
    use Illuminate\Support\Facades\View;

    View::creator('profile', ProfileCreator::class);

<a name="optimizing-views"></a>
## ビューの最適化

Bladeテンプレートビューはデフォルトでは、オンデマンドでコンパイルされます。ビューをレンダーするリクエストが実行されると、Laravelはコンパイル済みバージョンのビューが存在するかどうかを判断します。ファイルが存在する場合、Laravelはコンパイルされていないビューがコンパイル済みビューよりも最近変更されたかどうかを判断します。コンパイル済みビューが存在しないか、コンパイルされていないビューが変更されている場合、Laravelはビューをコンパイルします。

リクエスト中にビューをコンパイルすると、パフォーマンスにわずかな悪影響が及ぶ可能性があるため、Laravelは、アプリケーションで使用するすべてのビューをプリコンパイルするために`view:cache`　Artisanコマンドを提供しています。パフォーマンスを向上させるために、デプロイプロセスの一部として次のコマンドを実行することを推奨します。

    php artisan view:cache

ビューキャッシュを消去するには、`view:clear`コマンドを使います。

    php artisan view:clear
