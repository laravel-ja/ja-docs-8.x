# ビュー

- [ビューの作成](#creating-views)
- [ビューにデータを渡す](#passing-data-to-views)
    - [全ビュー間のデータ共有](#sharing-data-with-all-views)
- [ビューコンポーザ](#view-composers)
- [ビューの最適化](#optimizing-views)

<a name="creating-views"></a>
## ビューの作成

> {tip} Bladeテンプレートをどう書いたら良いのかをもっと知りたいですか？取り掛かるには、[Bladeのドキュメント](/docs/{{version}}/blade)を確認してください。

ビューはアプリケーションとして動作するHTMLにより構成されており、コントローラ／アプリケーションロジックをプレゼンテーションロジックから分離します。ビューは`resources/views`ディレクトリに保存します。 シンプルなビューは、以下のような形態です。

    <!-- resources/views/greeting.blade.phpとして保存されているビュー -->

    <html>
        <body>
            <h1>Hello, {{ $name }}</h1>
        </body>
    </html>

このビューを`resources/views/greeting.blade.php`として保存していますので、以下のようにグローバル`view`ヘルパ関数を使用し結果を返します。

    Route::get('/', function () {
        return view('greeting', ['name' => 'James']);
    });

ご覧の通り、`view`ヘルパに渡している最初の引数は、`resources/views`ディレクトリ中のビューファイル名に対応しています。２つ目の引数は、ビューで使用するデータの配列です。上記の例では、ビューに`name`変数を渡し、それは[Blade記法](/docs/{{version}}/blade)を使用しているビューの中に表示されます。

ビューは`resources/views`ディレクトリのサブディレクトリにネストすることもできます。ネストしたビューを参照するために「ドット」記法が使えます。たとえば、ビューを`resources/views/admin/profile.blade.php`として保存するなら、次のように指定します。

    return view('admin.profile', $data);

> {note} ビューのディレクトリ名には、`.`文字を含めてはいけません。

#### ビューの存在を検査

ビューが存在しているかを判定する必要があれば、`View`ファサードを使います。ビューが存在していれば、`exists`メソッドは`true`を返します。

    use Illuminate\Support\Facades\View;

    if (View::exists('emails.customer')) {
        //
    }

#### 利用可能な最初のViewの作成

`first`メソッドは、指定したビュー配列の中で、最初に存在するビューを作成します。これはアプリケーションやパッケージで、ビューをカスタマイズ、上書きする場合に役立ちます。

    return view()->first(['custom.admin', 'admin'], $data);

`View`[ファサード](/docs/{{version}}/facades)を使い、このメソッドを呼び出すこともできます。

    use Illuminate\Support\Facades\View;

    return View::first(['custom.admin', 'admin'], $data);

<a name="passing-data-to-views"></a>
## ビューにデータを渡す

前例で見たように、簡単にデータを配列でビューに渡せます。

    return view('greetings', ['name' => 'Victoria']);

この方法で情報を渡す場合、その情報はキー／値ペアの配列です。ビューの中で各値へは対抗するキーでアクセスできます。たとえば`<?php echo $key; ?>`のように表示可能です。全データを`view`ヘルパ関数へ渡す代わりに、`with`メソッドでビューに渡すデータを個別に追加することもできます。

    return view('greeting')->with('name', 'Victoria');

<a name="sharing-data-with-all-views"></a>
#### 全ビュー間のデータ共有

アプリケーションでレンダーする全ビューに対し、一部のデータを共有する必要があることも多いと思います。Viewファサードの`share`メソッドを使ってください。 通常、サービスプロバイダの`boot`メソッド内で`share`を呼び出します。`AppServiceProvider`に追加しても良いですし、独立したサービスプロバイダを作成することもできます。

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

ビューコンポーザはビューがレンダーされる時に呼び出される、コールバックかクラスメソッドのことです。ビューがレンダーされるたびに結合したい情報があるなら、ビューコンポーザがロジックを一箇所へまとめるのに役立ちます。

この例の[サービスプロバイダ](/docs/{{version}}/providers)の中に、ビューコンポーザを組み込みましょう。`View`ファサードの裏で動作している、`Illuminate\Contracts\View\Factory`契約の実装にアクセスします。Laravelはデフォルトのビューコンポーザ置き場を用意していないことに注意してください。お好きな場所に置くことができます。たとえば、`app/Http/View/Composers`ディレクトリを作成することもできます。

    <?php

    namespace App\Providers;

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
            View::composer(
                'profile', 'App\Http\View\Composers\ProfileComposer'
            );

            // クロージャベースのコンポーザを使用する
            View::composer('dashboard', function ($view) {
                //
            });
        }
    }

> {note} 新しいサービスプロバイダをビューコンポーザ登録のために作成したら、`config/app.php`設定ファイルの`providers`配列へ追加する必要があるのを忘れないでください。

では`profile`ビューがレンダーされるたび実行される、`ProfileComposer@compose`メソッドをコンポーザとして登録してみましょう。まず、このコンポーザクラスを定義します。

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
         * @param  UserRepository  $users
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
         * @param  View  $view
         * @return void
         */
        public function compose(View $view)
        {
            $view->with('count', $this->users->count());
        }
    }

ビューがレンダーされる直前に、`Illuminate\View\View`インスタンスに対しコンポーザの`compose`メソッドが呼びだされます。

> {tip} すべてのビューコンポーザは[サービスコンテナ](/docs/{{version}}/container)により依存解決されます。ですから、コンポーザのコンストラクターで必要な依存をタイプヒントで指定できます。

#### 複数ビューへの適用

複数のビューにビューコンポーザを適用するには、`composer`メソッドの最初の引数にビューの配列を渡してください。

    View::composer(
        ['profile', 'dashboard'],
        'App\Http\View\Composers\MyViewComposer'
    );

全ビューコンポーザに適用できるように、`composer`メソッドでは`*`をワイルドカードとして使用できます。

    View::composer('*', function ($view) {
        //
    });

#### Viewクリエーター

ビュー**クリエイター**は、ビューコンポーザとほぼ同じ働きをします。しかし、ビューがレンダーされるまで待つのではなく、インスタンス化されるとすぐに実行されます。ビュークリエイターを登録するには、`creator`メソッドを使います。

    View::creator('profile', 'App\Http\View\Creators\ProfileCreator');

<a name="optimizing-views"></a>
## ビューの最適化

デフォルトでビューは必要時にコンパイルされます。ビューをレンダーするリクエストを受け取ると、Laravelはコンパイル済みのビューがすでに存在するか確認します。存在する場合、コンパイル時より後にビューが更新されているか確認します。コンパイル済みビューが存在しないか、ビューが更新されている場合、Laravelはそのビューをコンパイルします。

リクエスト中にビューをコンパイルするとパフォーマンスに悪い影響が起きます。そのため、アプリケーションで使用しているすべてのビューを事前にコンパイルする`view:cache` Artisanコマンドを用意してあります。パフォーマンスを上げるには、デプロイ過程の一部としてこのコマンドを実行してください。

    php artisan view:cache

ビューキャッシュを消去するには、`view:clear`コマンドを使います。

    php artisan view:clear
