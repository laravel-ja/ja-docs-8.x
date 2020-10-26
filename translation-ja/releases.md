# リリースノート

- [バージョニング規約](#versioning-scheme)
- [サポートポリシー](#support-policy)
- [Laravel8](#laravel-8)

<a name="versioning-scheme"></a>
## バージョニング規約

Laravelとファーストパーティパッケージは、[セマンティックバージョニング](https://semver.org)にしたがっています。メジャーなフレームのリリースは、３月と９月の半年ごとにリリースされます。マイナーとパッチリリースはより細かく毎週リリースされます。マイナーとパッチリリースは、**決して**ブレーキングチェンジを含みません

皆さんのアプリケーションやパッケージからLaravelフレームワークかコンポーネントを参照する場合は、Laravelのメジャーリリースはブレーキングチェンジを含まないわけですから、`^8.0`のようにバージョンを常に指定してください。しかし、新しいメジャーリリースへ１日以内でアップデートできるように、私たちは常に努力しています。

<a name="support-policy"></a>
## サポートポリシー

Laravel6のようなLTSリリースでは、バグフィックスは２年間、セキュリティフィックスは３年間提供します。これらのリリースは長期間に渡るサポートとメンテナンスを提供します。 一般的なリリースでは、バグフィックスは７ヶ月、セキュリティフィックスは１年です。Lumenのようなその他の追加ライブラリでは、最新リリースのみでバグフィックスを受け付けています。また、[Laravelがサポートする](/docs/{{version}}/database#introduction)データベースのサポートについても確認してください。

| バージョン | リリース           | バグフィックス期限   | セキュリティフィックス期限 |
| ---------- | ------------------ | -------------------- | -------------------------- |
| 6 (LTS)    | ２０１９年９月３日 | ２０２１年１０月３日   | ２０２２年９月３日         |
| 7 | ２０２０年３月３日 | ２０２０年１０月６日 | ２０２１年３月３１日 |
| 8 | ２０２０年９月８日 | ２０２１年４月６日 | ２０２１年９月８日 |

<a name="laravel-8"></a>
## Laravel8

Laravel8は、Laravel7.xで行われた向上に加え、以降の変更で構成されています。Laravel Jetstreamの導入、モデルファクトリクラスの導入、マイグレーションの圧縮の導入、ジョブバッチの導入、レート制限の向上、キューの向上、ダイナミックBladeコンポーネントの導入、Tailwindペジネーションビューの導入、時間テストヘルパの導入、`artisan serve`の向上、イベントリスナの向上、ならびに多くのバグフィックスとユーザービリティの向上です

<a name="laravel-jetstream"></a>
### Laravel Jetstream

_Laravel Jettreamは、[Taylor Otwell](https://github.com/taylorotwell)により書かれました_。

[Laravel Jetstream](https://jetstream.laravel.com)（[和訳](/jetstream/1.0/ja/introduction.html)）は、Laravelのために美しくデザインされたアプリケーションのスカフォールドです。Jetstreamは、ログイン、ユーザー登録、メール認証、二要素認証、セッション管理、Laravel SanctumによるのAPIサポート、およびオプションのチーム管理など、次のプロジェクトのための完璧なスタートポイントを提供します。Laravel Jetstreamは、以前のLaravelバージョンで利用可能であったレガシーな認証UIのスカフォールドに代わるものであり、改善されています。

Jetstreamは[Tailwind CSS](https://tailwindcss.com)を使用してデザインされており、[Livewire](https://laravel-livewire.com)か[Inertia](https://inertiajs.com)のどちらかのスカフォールドを選択できます。

<a name="models-directory"></a>
### モデルディレクトリ

コミュニティからの圧倒的な要望により、デフォルトのLaravelアプリケーションのスケルトンに`app/Models`ディレクトリが含まれるようになりました。Eloquentモデルの新しいホームをお楽しみください。関連するジェネレータコマンドはすべて、モデルが`app/Models`ディレクトリ内に存在する仮定のもとに更新されました。ディレクトリが存在しない場合、フレームワークはモデルが`app`ディレクトリ内にあると仮定します。

<a name="model-factory-classes"></a>
### モデルファクトリクラス

_モデルファクトリクラスは、[Taylor Otwell](https://github.com/taylorotwell)が貢献しました_。

Eloquent[モデルファクトリ](/docs/{{version}}/data-testing#creating-factories)は、クラスベースのファクトリとして完全に書き直され、ファーストクラスのリレーションシップをサポートするように改良されました。たとえば、Laravelに含まれる`UserFactory`は次のように書かれています。

    <?php

    namespace Database\Factories;

    use App\Models\User;
    use Illuminate\Database\Eloquent\Factories\Factory;
    use Illuminate\Support\Str;

    class UserFactory extends Factory
    {
        /**
         * モデルに対応したファクトリの名前
         *
         * @var string
         */
        protected $model = User::class;

        /**
         * モデルのデフォルト状態
         *
         * @return array
         */
        public function definition()
        {
            return [
                'name' => $this->faker->name,
                'email' => $this->faker->unique()->safeEmail,
                'email_verified_at' => now(),
                'password' => '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password
                'remember_token' => Str::random(10),
            ];
        }
    }

生成されたモデルで利用できる新しい`HasFactory`トレイトのおかげで、モデルファクトリを以下のように利用できます。

    use App\Models\User;

    User::factory()->count(50)->create();

モデルファクトリは現在、シンプルな PHP クラスになったため、状態遷移はクラスメソッドとして記述できます。さらに、必要に応じて他のヘルパクラスをEloquentモデルファクトリに追加できます。

たとえば`User`モデルは、デフォルトの属性値の一つを変更する`suspended`状態を持っているとしましょう。ベースファクトリの`state`メソッドを使い、状態遷移を定義できます。ステートメソッドには好きな名前を付けてください。つまるところ、これは典型的なPHPのメソッドです。

    /**
     * そのユーザーが利用停止であることを表す
     *
     * @return \Illuminate\Database\Eloquent\Factories\Factory
     */
    public function suspended()
    {
        return $this->state([
            'account_status' => 'suspended',
        ]);
    }

状態遷移メソッドを定義したら、以下のように使用します。

    use App\Models\User;

    User::factory()->count(5)->suspended()->create();

前述のとおり、Laravel8のモデルファクトリはリレーションのファーストクラスをサポートしています。ですから、`User`モデルに`posts`リレーションがあると仮定し、以下のコードを実行して、3つのポストを持つユーザーを生成できます。

    $users = User::factory()
                ->hasPosts(3, [
                    'published' => false,
                ])
                ->create();

簡単にアップグレードできるよう、[laravel/legacy-factories](https://github.com/laravel/legacy-factories)パッケージがリリースされ、Laravel8.x内のモデルファクトリの以前の反復をサポートしています。

リライトしたLaravelのファクトリは、皆さんに気に入ってもらえるような多くの機能が含まれています。モデルファクトリの詳細は、[データベーステストのドキュメント](/docs/{{version}}/databasetesting#creating-factories)を参照してください。

<a name="migration-squashing"></a>
### マイグレーションの圧縮

_マイグレーションの圧縮は、[Taylor Otwell](https://github.com/taylorotwell)が貢献しました_.

アプリケーションを構築するにつれ、時間の経過とともに段々多くのマイグレーションが溜まっていく可能性があります。これにより、マイグレーションディレクトリが数百ものマイグレーションで肥大化するかもしれません。MySQLもしくはPostgreSQLを使用している場合は、マイグレーションを１つのＳＱＬファイルに「圧縮」できます。利用するには、`schema：dump`コマンドを実行します：

    php artisan schema:dump

    // 現在のデータベーススキーマを圧縮し、既存のマイグレーションを削除する
    php artisan schema:dump --prune

このコマンドを実行すると、Laravelは「スキーマ」ファイルを`database/schema`ディレクトリに書き込みます。これにより、データベースをマイグレートしようとするときに他のマイグレーションは実行されず、Laravelは最初にスキーマファイルのＳＱＬを実行します。スキーマファイルのコマンドを実行した後、Laravelはスキーマダンプに圧縮されていない残りのマイグレーションを実行します。

<a name="job-batching"></a>
### ジョブバッチ

_ジョブバッチは、[Taylor Otwell](https://github.com/taylorotwell)と[Mohamed Said](https://github.com/themsaid)が貢献しました。_.

Laravelのジョブバッチ処理機能を使用すると、バッチジョブを簡単に実行し、バッチの実行が完了したときに何らかのアクションを実行できます。

`Bus`ファサードの新しい`batch`メソッドを使用して、バッチジョブをディスパッチできます。もちろん、バッチ処理は終了コールバックと合わせて使用すると、特に便利です。そのため、`then`、` catch`、`finally`メソッドにより、バッチの終了コールバックが定義できます。こうしたコールバックはそれぞれ呼び出し時に、`Illuminate\Bus\Batch`インスタンスを引数に受け取ります。

    use App\Jobs\ProcessPodcast;
    use App\Podcast;
    use Illuminate\Bus\Batch;
    use Illuminate\Support\Facades\Bus;
    use Throwable;

    $batch = Bus::batch([
        new ProcessPodcast(Podcast::find(1)),
        new ProcessPodcast(Podcast::find(2)),
        new ProcessPodcast(Podcast::find(3)),
        new ProcessPodcast(Podcast::find(4)),
        new ProcessPodcast(Podcast::find(5)),
    ])->then(function (Batch $batch) {
        // 全ジョブが実行成功して終了した
    })->catch(function (Batch $batch, Throwable $e) {
        // 最初にバッチジョブの失敗が検出された
    })->finally(function (Batch $batch) {
        // バッチの実行が終了した
    })->dispatch();

    return $batch->id;

バッチジョブの詳細は、[キューのドキュメント](/docs/{{version}}/queues#job-batching)をお読みください。

<a name="improved-rate-limiting"></a>
### レート制限の向上

_レート制限の向上は、[Taylor Otwell](https://github.com/taylorotwell)が貢献しました_.

Laravelのリクエストレート制限機能は、以前のリリースの`throttle`ミドルウェアAPIとの下位互換性を維持しながら、柔軟性とパワーが強化されています。

レート制限は、`RateLimiter`ファサードの`for`メソッドを使い定義します。`for`メソッドの引数は、レート制限名と、このレート宣言を割り当てるルートに適用する制限設定を返すクロージャです。

    use Illuminate\Cache\RateLimiting\Limit;
    use Illuminate\Support\Facades\RateLimiter;

    RateLimiter::for('global', function (Request $request) {
        return Limit::perMinute(1000);
    });

レート制限コールバックは、受信HTTPリクエストインスタンスを引数に受けるため、受信リクエストまたは認証済みユーザーに基づいた適切なレート制限を動的に構築できます。

    RateLimiter::for('uploads', function (Request $request) {
        return $request->user()->vipCustomer()
                    ? Limit::none()
                    : Limit::perMinute(100);
    });

レート制限を任意の値で分割したい場合があります。たとえば、ユーザーが特定のルートにIPアドレスに対し1分あたり１００回アクセスすることを許可したい場合です。それには、レート制限を作成するときに`by`メソッドを使用します。

    RateLimiter::for('uploads', function (Request $request) {
        return $request->user()->vipCustomer()
                    ? Limit::none()
                    : Limit::perMinute(100)->by($request->ip());
    });

レート制限は、`throttle` [ミドルウェア](/docs/{{version}}/middleware)を使用してルートまたはルートグループに付加します。スロットルミドルウェアの引数は、ルートに割り付けるレート制限の名前です。

    Route::middleware(['throttle:uploads'])->group(function () {
        Route::post('/audio', function () {
            //
        });

        Route::post('/video', function () {
            //
        });
    });

レート制限の詳細は、[ルーティングドキュメント](/docs/{{version}}/routing#rate-limiting)を参照してください。

<a name="improved-maintenance-mode"></a>
### メンテナンスモードの向上

_メンテナンスモードの向上は[Spatie](https://spatie.be)からインスピレーションを受け、[Taylor Otwell](https://github.com/taylorotwell)が貢献しました_.

以前のLaravelリリースではアプリケーションへのアクセスを許可するIPアドレスの「許可リスト」を使用して、`php artisan down`メンテナンスモード機能をバイパスできました。この機能は、より単純な「秘密」/トークンによる解決法導入により削除しました。

While in maintenance mode, you may use the `secret` option to specify a maintenance mode bypass token:メンテナンスモードの間、`secret`オプションを使用してメンテナンスモードのバイパストークンを指定します。

    php artisan down --secret="1630542a-246b-4b66-afa1-dd72a4c43515"

アプリケーションをメンテナンスモードにした後、このトークンに一致するアプリケーションURLへ移行すると、LaravelはブラウザへメンテナンスモードのバイパスCookieを発行します。

    https://example.com/1630542a-246b-4b66-afa1-dd72a4c43515

この隠しルートにアクセスすると、アプリケーションの`/`ルートへリダイレクトします。ブラウザにクッキーが発行されれば、メンテナンスモードではないときと同じように、アプリケーションを通常通り閲覧できます。

<a name="pre-rendering-the-maintenance-mode-view"></a>
#### メンテナンスモードビューの事前レンダリング

デプロイ時、`php artisan down`コマンドを使用する場合、Composerの依存関係またはその他の基礎コンポーネントの更新中にユーザーがアプリケーションへアクセスすることで、エラーが発生する可能性があります。これはアプリケーションがメンテナンスモードであることを確認し、テンプレートエンジンを使用してメンテナンスモードビューを表示するためには、Laravelフレームワークの重要な部分が起動されている必要があるためです。

このためLaravelは、リクエストサイクルの最初に返されるメンテナンスモードビューを事前レンダリングできるようになりました。このビューは、アプリケーションの依存パッケージが読み込まれる前にレンダリングされます。`down`コマンドの` render`オプションを使用して、選択したテンプレートを事前レンダーできます：

    php artisan down --render="errors::503"

<a name="closure-dispatch-chain-catch"></a>
### ディスパッチクロージャと`catch`チェーン

_Catchの向上は[Mohamed Said](https://github.com/themsaid)が貢献しました_.

新しい`catch`メソッドを使用し、キュー設定の再試行をすべて使い果たした後に、キュー投入したクロージャが正常に完了しなかった場合に実行する必要があるクロージャを指定できます。

    use Throwable;

    dispatch(function () use ($podcast) {
        $podcast->publish();
    })->catch(function (Throwable $e) {
        // このジョブは失敗した
    });

<a name="dynamic-blade-components"></a>
### 動的Bladeコンポーネント

_動的Bladeコンポーネントは、[Taylor Otwell](https://github.com/taylorotwell)が貢献しました_.

コンポーネントをレンダーする必要があるが、実行時までどれをレンダーするかわからない場合があります。この状況では、Laravelに組み込まれている`dynamic-component`コンポーネントを使用して、ランタイム値や変数に基づきコンポーネントをレンダリングできます。

    <x-dynamic-component :component="$componentName" class="mt-4" />

Bladeコンポーネントの詳細は、[Bladeのドキュメント]（/docs/{{version}}/blade＃components）をご覧ください。

<a name="event-listener-improvements"></a>
### イベントリスナの向上

_イベントリスナの向上は、[Taylor Otwell](https://github.com/taylorotwell)[Taylor Otwell](https://github.com/taylorotwell)が貢献しました_.

クロージャベースのイベントリスナは、クロージャを`Event::listen`メソッドに渡すだけで登録できるようになりました。Laravelはクロージャを調べ、リスナが処理するイベントのタイプを判別します。

    use App\Events\PodcastProcessed;
    use Illuminate\Support\Facades\Event;

    Event::listen(function (PodcastProcessed $event) {
        //
    });

さらに、クロージャベースのイベントリスナは、`Illuminate\Events\queueable`関数を使用して、キュー可能としてマークされるようになりました。

    use App\Events\PodcastProcessed;
    use function Illuminate\Events\queueable;
    use Illuminate\Support\Facades\Event;

    Event::listen(queueable(function (PodcastProcessed $event) {
        //
    }));

キュー投入するジョブと同様に、キューリスナの実行をカスタマイズする`onConnection`、`onQueue`、`delay`メソッドが使用できます。

    Event::listen(queueable(function (PodcastProcessed $event) {
        //
    })->onConnection('redis')->onQueue('podcasts')->delay(now()->addSeconds(10)));

匿名のキュー済みリスナの失敗を処理する場合は、 `queueable`リスナを定義するときに`catch`メソッドへクロージャを渡してください。

    use App\Events\PodcastProcessed;
    use function Illuminate\Events\queueable;
    use Illuminate\Support\Facades\Event;
    use Throwable;

    Event::listen(queueable(function (PodcastProcessed $event) {
        //
    })->catch(function (PodcastProcessed $event, Throwable $e) {
        // キュー済みリスナは失敗した
    }));

<a name="time-testing-helpers"></a>
### 時間テストのヘルパ

_時間テストのヘルパはRuby on Railsからインスピレーションを受け、[Taylor Otwell](https://github.com/taylorotwell)が貢献しました_.

テスト時、`now`や`Illuminate\SupportCarbon::now()`のようなヘルパが返す時間を変更する必要が起き得ます。Laravelの機能テストクラスのベースには、現時刻を操作できるヘルパを用意しています。

    public function testTimeCanBeManipulated()
    {
        // 未来へ時間移動する
        $this->travel(5)->milliseconds();
        $this->travel(5)->seconds();
        $this->travel(5)->minutes();
        $this->travel(5)->hours();
        $this->travel(5)->days();
        $this->travel(5)->weeks();
        $this->travel(5)->years();

        // 過去へ時間移動する
        $this->travel(-5)->hours();

        // 特定の時刻へ時間移動する
        $this->travelTo(now()->subHours(6));

        // 現在時刻へ戻る
        $this->travelBack();
    }

<a name="artisan-serve-improvements"></a>
### Artisan `serve`の向上

_Artisan `serve`の向上は、[Taylor Otwell](https://github.com/taylorotwell)が貢献しました。_.

Artisan `serve`コマンドは、ローカルの`.env`ファイル内で環境変数の変更が検出されたとき、自動でリロードするように改善されました。以前は、コマンドを手動で停止して再起動しなければなりませんでした。

<a name="tailwind-pagination-views"></a>
### Tailwindペジネーションビュー

Laravelのペジネータはデフォルトで[Tailwind CSS](https://tailwindcss.com)フレームワークを使用するように変更しました。Tailwind CSSは高度にカスタマイズできる低レベルなCSSフレームワークで、オーバーライドのために戦う必要のある煩わしい意見的なスタイルを使用せずに、お誂え向きのデザインを構築するために必要なすべてのビルディングブロックを提供してくれます。もちろん、Bootstrap３と４のビューも利用可能です。

<a name="routing-namespace-updates"></a>
### ルートの名前空間の向上

以前のリリースのLaravelでは、`RouteServiceProvider`は`$namespace`プロパティを持っていました。このプロパティの値は、コントローラのルート定義や`action`ヘルパ／`URL::action`メソッドの呼び出しに、自動でプレフィックスを付加していました。Laravel8.xでこのプロパティはデフォルトで`null`です。これは、Laravelは自動的に名前空間のプレフィクスを付けなくなったことを意味します。そのため、新しいLaravel8.xアプリケーションでは、コントローラルートの定義は標準的なPHPで呼び出し可能な構文を使って定義する必要があります。

    use App\Http\Controllers\UserController;

    Route::get('/users', [UserController::class, 'index']);

`action`関係のメソッドの呼び出しも、同じく呼び出し可能な記法を使ってください。

    action([UserController::class, 'index']);

    return Redirect::action([UserController::class, 'index']);

Laravel7.xスタイルのコントローラルートのプレフィックスが好みならば、アプリケーションの`RouteServiceProvider`の中に、`$namespace`プレフィックスをただ追加するだけです。

> {note} この変更は新しいLaravel8.xアプリケーションでのみ影響します。Laravel7xからアップグレードしたアプリケーションは、`RouteServiceProvider`に`$namespace`プロパティを持ったままでしょう。
