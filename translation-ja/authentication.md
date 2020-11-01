# 認証

- [イントロダクション](#introduction)
    - [データベースの検討事項](#introduction-database-considerations)
    - [エコシステム概論](#ecosystem-overview)
- [認証クイックスタート](#authentication-quickstart)
    - [ルーティング](#included-routing)
    - [ビュー](#included-views)
    - [認証](#included-authenticating)
    - [認証済みユーザーの取得](#retrieving-the-authenticated-user)
    - [ルートの保護](#protecting-routes)
    - [認証回数制限](#login-throttling)
- [手動のユーザー認証](#authenticating-users)
    - [継続ログイン](#remembering-users)
    - [その他の認証方法](#other-authentication-methods)
- [HTTP基本認証](#http-basic-authentication)
    - [ステートレスHTTP基本認証](#stateless-http-basic-authentication)
- [ログアウト](#logging-out)
    - [他のデバイス上のセッションを無効化](#invalidating-sessions-on-other-devices)
- [パスワード確認](#password-confirmation)
    - [設定](#password-confirmation-configuration)
    - [ルート](#password-confirmation-routing)
    - [ルート保護](#password-confirmation-protecting-routes)
- [ソーシャル認証]](/docs/{{version}}/socialite)
- [カスタムガードの追加](#adding-custom-guards)
    - [クロージャリクエストガード](#closure-request-guards)
- [カスタムユーザープロバイダの追加](#adding-custom-user-providers)
    - [ユーザープロバイダ契約](#the-user-provider-contract)
    - [Authenticatable契約](#the-authenticatable-contract)
- [イベント](#events)

<a name="introduction"></a>
## イントロダクション

Laravelでは簡単に認証が実装できます。実のところ、ほぼすべて最初から設定済みです。認証の設定ファイルは`config/auth.php`に用意してあり、認証サービスの振る舞いを調整できるように、読みやすいコメント付きでたくさんのオプションが用意されています。

Laravelの認証機能は「ガード」と「プロバイダ」を中心概念として構成されています。ガードは各リクエストごとに、どのようにユーザーを認証するかを定義します。たとえば、Laravelにはセッションストレージとクッキーを使いながら状態を維持する`session`ガードが用意されています。

プロバイダは永続ストレージから、どのようにユーザーを取得するかを定義します。LaravelはEloquentとデータベースクリエビルダを使用しユーザーを取得する機能を用意しています。しかし、アプリケーションの必要性に応じて、自由にプロバイダを追加できます。

混乱しても心配ありません。通常のアプリケーションでは、デフォルトの認証設定を変更する必要はありません。

<a name="getting-started-fast"></a>
#### てっとり早く始める

早速使い始めたいですか？真新しくインストールしたLaravelパッケージへ、[Laravel Jetstream](https://jetstream.laravel.com)（[和訳](/jetstream/1.0/ja/introduction.html)）をインストールしてください。データベースをマイグレーションしたら、`/register`へブラウザでアクセスするか、アプリケーションに割り付けた別のURLへアクセスしましょう。Jetstreamは認証システム全体のスカフォールディングを面倒見ます！

<a name="introduction-database-considerations"></a>
### データベースの検討事項

Laravelはデフォルトで、`app/Models`ディレクトリの中に`App\Models\User` [Eloquentモデル](/docs/{{version}}/eloquent)を設置します。このモデルは、デフォルトのEloquent認証ドライバと共に使用します。アプリケーションでEloquentを使用しない場合は、Laravelのクエリビルダを使用する`database`認証ドライバを使用することになるでしょう。

`App\Models\User`モデルのデータベーススキマーを構築するときは、パスワードカラムが最低でも６０文字確保してください。デフォルトの文字列カラム長である２５５文字のままにしておくのは、良い選択です。

さらに`users`、もしくは同等の働きをするテーブルには、１００文字の`remember_token`文字列カラムも含めてください。このカラムはログイン時に、アプリケーションで"remember me"を選んだユーザーのトークンを保存しておくカラムとして使用されます。

<a name="ecosystem-overview"></a>
### エコシステム概論

Laravelは、認証に関連するパッケージをいくつか提供しています。説明を続ける前にLaravelにおける一般的な認証のエコシステムを確認し、各パッケージの使用目的について説明します。

最初に、認証の仕組みを考えましょう。Webブラウザを使用するとき、ユーザーはログインフォームを介してユーザー名とパスワードを入力します。この認証情報が正しい場合、アプリケーションは認証したユーザーに関する情報をユーザーの[セッション](/docs/{{version}}/session)に保存します。ブラウザへ発行されたCookieにはセッションIDが含まれているため、アプリケーションへの後続のリクエストでユーザーを正しいセッションに関連付けできます。セッションクッキーを受信すると、アプリケーションはセッションIDに基づいてセッションデータを取得し、認証情報がセッションに格納されていることに注意して、ユーザーを「認証済み」と見なします。

APIへアクセスするためにリモートサービスが認証を必要とする場合、Webブラウザがないためクッキーを通常使用しません。代わりにリモートサービスは、リクエストごとにAPIトークンをAPIに送信します。アプリケーションは有効なAPIトークンのテーブルに照らし合わせ受信トークンを検証し、そのAPIトークンに関連付けられているユーザーが実行しているリクエストを「認証」できます。

<a name="laravels-built-in-browser-authentication-services"></a>
#### Laravel組み込みのブラウザ認証サービス

Laravelは、通常`Auth`および`Session`ファサードを介してアクセスする組み込み認証とセッションサービスを用意しています。これらの機能はWebブラウザから開始されたリクエストにクッキーベースの認証を提供しています。ユーザーの認証情報を確認し、そのユーザーを認証するメソッドを提供しています。さらに、これらのサービスは適切なデータをユーザーのセッションに自動的に保存し、適切なセッションクッキーを発行します。こうしたサービスの使用方法は、このドキュメントに記載しています。

**Jetstream / Fortify**

このドキュメント中で説明するように、こうした認証サービスを自分で操作して、アプリケーション独自の認証レイヤーを構築できます。しかし、より迅速に開始できるよう、認証レイヤー全体の堅牢で最新のスカフォールドを提供する無料パッケージをリリースしました。[Laravel Jetstream]（https://jetstream.laravel.com）（[和訳](/jetstream/1.0/ja/introduction.html)）と[Laravel Fortify]（https://github.com/laravel/fortify）パッケージです。

Laravel FortifyはLaravelのヘッドレス認証バックエンドです。クッキーベースの認証や２要素認証、メールバリデーションなど他の機能を含め、このドキュメントで多くの機能を説明しています。Laravel Jetstreamは、[Tailwind CSS](https://tailwindcss.com)、[Laravel Livewire](https://laravel-livewire.com)、[Inertia.js](https://inertiajs.com)を使い、美しくモダンなUIでFortifyの認証サービスを利用および公開するUIです。Laravel Jetstreamは、ブラウザベースのクッキー認証の提供に加えAPIトークン認証を提供するため、Laravel Sanctumとの統合を組み込んでいます。LaravelのAPI認証サービスについては、以下で説明します。

<a name="laravels-api-authentication-services"></a>
#### LaravelのAPI認証サービス

Laravelは、APIトークンの管理とAPIトークンで行われたリクエストの認証を支援する2つのオプションパッケージを提供しています。[Passport](/docs/{{version}}/passport)と[Sanctum](/docs/{{version}}/sanctum)です。これらのライブラリとLaravelの組み込みCookieベースの認証ライブラリは互いに排他的でないことを注意してください。これらのライブラリは主にAPIトークン認証に重点を置いていますが、組み込みの認証サービスはクッキーベースのブラウザ認証に重点を置いています。多くのアプリケーションは、Laravelの組み込みクッキーベースの認証サービスと、LaravelのAPI認証パッケージのどちらか１つの、両方を使用するでしょう。

**Passport**

PassportはOAuth2認証プロバイダであり、さまざまなタイプのトークンを発行できる多様なOAuth2「許可タイプ」を提供します。大まかに言えば、これはAPI認証の堅牢で複雑なパッケージです。ただ、ほとんどのアプリケーションはOAuth2仕様が提供する複雑な機能を必要としないため、ユーザーと開発者の両方が混乱する可能性があります。さらに、開発者はこれまで、Passportと同じようなOAuth2認証プロバイダを使用してSPAアプリケーションまたはモバイルアプリケーションを認証する方法について混乱させられてきました。

**Sanctum**

OAuth2の複雑さと開発者の混乱に対応するため、WebブラウザからのファーストパーティWebリクエストと、トークンによるAPIリクエストの両方を処理できる、よりシンプルで合理化された認証パッケージの構築に着手しました。このゴールは、[Laravel Sanctum](/docs/{{version}}/sanctum)のリリースで達成できました。これは、APIに加えファーストパーティのWeb UIの提供、もしくはバックエンドのLaravelアプリケーションから独立して存在するシングルページアプリケーションやモバイルクライアントを提供するアプリケーション向きの推奨認証パッケージと考えてください。

Laravel Sanctumは、アプリケーションの認証プロセス全体を管理できるハイブリッドWeb／API認証パッケージです。Sanctumベースのアプリケーションがリクエストを受信すると、まずSanctumはリクエストに認証済みセッションを参照するセッションクッキーが含まれているかどうかを判断するため、これが可能になります。Sanctumは、これまでに説明したLaravelの組み込み認証サービスを呼び出すことでこれを実現しますリクエストがセッションクッキーを介して認証されていない場合、SanctumはAPIトークンのリクエストを検査します。APIトークンが存在する場合、Sanctumはそのトークンを使用してリクエストを認証します。このプロセスの詳細については、Sanctumの["動作の仕組み"](/docs/{{version}}/sanctum#how-it-works)ドキュメントをご覧ください。

Laravel Sanctumは、[Laravel Jetstream](https://jetstream.laravel.com)（[和訳](/jetstream/1.0/ja/introduction.html)）認証スカフォールドに含める選択をしたAPIパッケージです。なぜなら、Webアプリケーションの認証ニーズの大部分に最適であると考えているためです。

<a name="summary-choosing-your-stack"></a>
#### まとめと選択方法

要約すると、ブラウザを使用してアプリケーションにアクセスする場合、アプリケーションはLaravelの組み込み認証サービスを使用します。

次に、アプリケーションがAPIを提供する場合は、[Passport](/docs/{{version}}/passport)または[Sanctum](/docs/{{version}}/sanctum)を選択してください。「スコープ」や「アビリティ」のサポートを含むAPI認証やSPA認証、モバイル認証のためのシンプルで完全なソリューションであるため、一般に、可能であればSanctumをおすすめします。

アプリケーションがOAuth2仕様で提供されるすべての機能を絶対に必要とする場合、Passportを選択してください。。

また、すぐに使い始めたい場合は、新しいLaravelアプリケーションをすばやく開始するための迅速な方法として、Laravelの優先認証スタックである組み込み認証サービスとLaravel Sanctumを始めから使用している、[Laravel Jetstream](https://jetstream.laravel.com)（[和訳](/jetstream/1.0/ja/introduction.html)）をおすすめします。

<a name="authentication-quickstart"></a>
## 認証クイックスタート

> {note} ドキュメントのこの部分では、[Laravel Jetstream](https://jetstream.laravel.com)（[和訳](/jetstream/1.0/ja/introduction.html)）パッケージを使用したユーザーの認証について説明します。これには、すぐに使い始めるのに役立つUIのスカフォールドが含まれています。Laravelの認証システムを直接統合したい場合は、[手動のユーザー認証](#authenticating-users)のドキュメントをご覧ください。

<a name="included-routing"></a>
### ルート定義

Laravel'の`laravel/jetstream`パッケージは、簡単なコマンドで認証に必要なルートとビュー、バックエンドのロジックを素早くすべてスカフォールドする方法を提供します。

    composer require laravel/jetstream

    // Livewireスタックを使用するJetstreamをインストールする
    php artisan jetstream:install livewire

    // Inertiaスタックを使用するJetstreamをインストールする
    php artisan jetstream:install inertia

このコマンドは真新しくインストールしたアプリケーションで使用してください。認証の全エンドポイントに対するルートと同時に、レイアウトビュー、登録とログインビューをインストールします。ログイン後のリクエストを処理するため、アプリケーションのダッシュボードを`/dashboard`ルートとして生成します。

<a name="creating-applications-including-authentication"></a>
#### 認証を含むアプリケーションの生成

真新しいアプリケーションを開始し、認証のスカフォールドを含めたい場合は、アプリケーションの生成時にLaravelインストーラへ`--jet`ディレクティブを使ってください。このコマンドはアプリケーションへ認証スカフォールドを全部インストールし、コンパイルします。

    laravel new kitetail --jet

> {tip} Jetstreamの詳細は、公式[Jetstreamドキュメント](https://jetstream.laravel.com)（[和訳](/jetstream/1.0/ja/introduction.html)）をご覧ください。

<a name="included-views"></a>
### ビュー

前セクションで述べた通り、`laravel/jetstream`パッケージの`php artisan jetstream:install`コマンドは、認証に必要なビューをすべて生成し、`resources/views/auth`ディレクトリへ設置します。

Jetstreamはアプリケーションのベースレイアウトを含む`resources/views/layouts`ディレクトリも生成します。これらのビューはすべて[Tailwind CSS](https://tailwindcss.com)フレームワークを使用していますが、ご希望であれば自由にカスタマイズできます。

<a name="included-authenticating"></a>
### 認証

これでアプリケーションが認証用にスカフォールドされたので、ユーザー登録して認証する準備ができました。Jetstreamの認証コントローラには既存のユーザーを認証してデータベースに新しいユーザーを保存するロジックがすでに含まれているため、ブラウザでアプリケーションにアクセスするだけです。

<a name="path-customization"></a>
#### パスのカスタマイズ

Wユーザーが認証に成功した場合、典型的には`/home`のURIへリダイレクトすると思います。`RouteServiceProvider`に`HOME`定数を定義することにより、認証後のリダイレクトパスをカスタマイズできます。

    public const HOME = '/home';

Laravel Jetstreamを使う場合、Jetstreamのインストール処理は`HOME`の値を`/dashboard`へ変更します。

<a name="retrieving-the-authenticated-user"></a>
### 認証済みユーザーの取得

受信リクエストを処理しているとき、`Auth`ファサードにより認証済みユーザーへアクセスできます。

    use Illuminate\Support\Facades\Auth;

    // 現在認証されているユーザーの取得
    $user = Auth::user();

    // 現在認証されているユーザーのID取得
    $id = Auth::id();

もしくは、ユーザーが一度認証したら、`Illuminate\Http\Request`インスタンスによりその認証済みユーザーへアクセスできます。コントローラのメソッドでタイプヒントされたクラスは、自動的に注入されることを思い出してください。`Illuminate\Http\Request`オブジェクトをタイプヒントすることにより、アプリケーションのどのコントローラでも認証ユーザーへ簡単にアクセスできます。

    <?php

    namespace App\Http\Controllers;

    use Illuminate\Http\Request;

    class FlightController extends Controller
    {
        /**
         * 利用可能な全フライトの取得
         *
         * @param  Request  $request
         * @return Response
         */
        public function update(Request $request)
        {
            // $request->user()は認証済みユーザーのインスタンスを返す
        }
    }

<a name="determining-if-the-current-user-is-authenticated"></a>
#### 現在のユーザーが認証されているか調べる

ユーザーがすでにアプリケーションにログインしているかを調べるには、`Auth`ファサードの`check`メソッドが使えます。認証時に`true`を返します。

    use Illuminate\Support\Facades\Auth;

    if (Auth::check()) {
        // ユーザーはログインしている
    }

> {tip} `check`メソッドを使っても、あるユーザーが認証済みであるかを判定可能です。特定のルートやコントローラへユーザーをアクセスさせる前に、認証済みであるかをミドルウェアにより確認する場面で、典型的に使用します。より詳細については[ルートの保護](/docs/{{version}}/authentication#protecting-routes)のドキュメントを参照してください。

<a name="protecting-routes"></a>
### ルートの保護

[ルートミドルウェア](/docs/{{version}}/middleware)は特定のルートに対し、認証済みユーザーのみアクセスを許すために使われます。Laravelには`Illuminate\Auth\Middleware\Authenticate`クラスの中で参照されている`auth`ミドルウェアを最初から用意しています。このミドルウェアは、HTTPカーネルで登録済みのため、必要なのはルート定義でこのミドルウェアを指定するだけです。

    Route::get('flights', function () {
        // 認証済みのユーザーのみが入れる
    })->middleware('auth');

<a name="redirecting-unauthenticated-users"></a>
#### 未認証ユーザーのリダイレクト

ミドルウェアが未認証ユーザーを突き止めると、ユーザーを`login`[名前付きルート](/docs/{{version}}/routing#named-routes)へリダイレクトします。この振る舞いは、`app/Http/Middleware/Authenticate.php`ファイルの`redirectTo`関数で変更できます。

    /**
     * ユーザーをリダイレクトさせるパスの取得
     *
     * @param  \Illuminate\Http\Request  $request
     * @return string
     */
    protected function redirectTo($request)
    {
        return route('login');
    }

<a name="specifying-a-guard"></a>
#### ガードの指定

`auth`ミドルウェアをルートに対し指定するときに、そのユーザーに対し認証を実行するガードを指定することもできます。指定されたガードは、`auth.php`設定ファイルの`guards`配列のキーを指定します。

    Route::get('flights', function () {
        // 認証済みのユーザーのみが入れる
    })->middleware('auth:api');

<a name="login-throttling"></a>
### 認証回数制限

Laravel Jetstreamの利用時、自動的にログインの試みは回数制限されます。何度かログイン情報の入力へ失敗すると、そのユーザーはデフォルトで一分間ログインできなくなります。制限はユーザーのユーザー名／メールアドレスとIPアドレスの組み合わせで制限されます。

> {tip} ルートをレート制限する場合は、[レート制限のドキュメント](/docs/{{version}}/routing#rate-limiting)を確認してください。

<a name="authenticating-users"></a>
## 自前のユーザー認証

Laravel Jetstreamが用意する認証スカフォールドを使う必要はないことに留意してください。このスカフォールドを使用しない選択をした場合、Laravelの認証クラスを直接使用し、ユーザーの認証管理を行う必要があります。心配ありません。それも簡単です！

Laravelの認証サービスには`Auth`[ファサード](/docs/{{version}}/facades)でアクセスできます。クラスの最初で`Auth`ファサードを確実にインポートしておきましょう。次に`attempt`メソッドを見てみましょう。

    <?php

    namespace App\Http\Controllers;

    use Illuminate\Http\Request;
    use Illuminate\Support\Facades\Auth;

    class LoginController extends Controller
    {
        /**
         * 認証を処理する
         *
         * @param  \Illuminate\Http\Request $request
         *
         * @return Response
         */
        public function authenticate(Request $request)
        {
            $credentials = $request->only('email', 'password');

            if (Auth::attempt($credentials)) {
                // 認証に成功した
                return redirect()->intended('dashboard');
            }
        }
    }

`attempt`メソッドは最初の引数として、キー／値ペアの配列を受け取ります。配列中の他の値は、データベーステーブルの中からそのユーザーを見つけるために使用されます。そのため、上の例では`email`カラム値によりユーザーが取得されます。データベース中のハッシュ済みパスワードと比較する前に、フレームワークは自動的に値をハッシュ化するため、`password`へ指定する値はハッシュ化しないでください。２つのハッシュ済みパスワードが一致したら、そのユーザーの新しい認証セッションが開始されます。

`attempt`メソッドは、認証が成功すれば`true`を返します。失敗時は`false`を返します。

リダイレクタの`intended`メソッドは、認証フィルターで引っかかる前にアクセスしようとしていたURLへ、ユーザーをリダイレクトしてくれます。そのリダイレクトが不可能な場合の移動先として、フォールバックURIをこのメソッドに指定してください。

<a name="specifying-additional-conditions"></a>
#### 追加条件の指定

お望みであれば、ユーザーのメールアドレスとパスワードに付け加え、認証時のクエリに追加の条件を指定することも可能です。例として、ユーザーが「アクティブ」である条件を追加してみましょう。

    if (Auth::attempt(['email' => $email, 'password' => $password, 'active' => 1])) {
        // ユーザーは存在しており、かつアクティブで、資格停止されていない
    }

> {note} この例のように、`email`を必ず認証に使用しなくてならない訳ではありません。データーベース中にあるユーザー名(username)に該当する、一意にユーザーを特定できるカラムであれば何でも使用できます。

<a name="accessing-specific-guard-instances"></a>
#### 特定のGuardインスタンスへのアクセス

`Auth`ファサードの`guard`メソッドにより、使用したいガードインスタンスを指定できます。これによりまったく異なった認証用のモデルやユーザーテーブルを使い、アプリケーションの別々の部分に対する認証が管理できます。

`guard`メソッドへ渡すガード名は、`auth.php`認証ファイルのguards設定の一つと対応している必要があります。

    if (Auth::guard('admin')->attempt($credentials)) {
        //
    }

<a name="manually-logging-out"></a>
#### ログアウト

アプリケーションからユーザーをログアウトさせるには、`Auth`ファサードの`logout`メソッドを使用してください。これはユーザーセッションの認証情報をクリアします。

    Auth::logout();

<a name="remembering-users"></a>
### 継続ログイン

アプリケーションでログイン維持(Remember me)機能を持たせたい場合は、`attempt`メソッドの第２引数に論理値を指定します。ユーザーが自分でログアウトしない限り、認証を無期限に保持します。"remember me"トークンを保存するために使用する文字列の`remember_token`カラムを`users`テーブルに持たせる必要があります。

    if (Auth::attempt(['email' => $email, 'password' => $password], $remember)) {
        // このメンバーは継続ログインされる
    }

この機能を使用している時に、ユーザーが"remember me"クッキーを使用して認証されているかを判定するには、`viaRemember`メソッドを使用します。

    if (Auth::viaRemember()) {
        //
    }

<a name="other-authentication-methods"></a>
### 他の認証方法

<a name="authenticate-a-user-instance"></a>
#### Userインスタンスによる認証

既存ユーザーインスタンスをアプリケーションへログインさせたい場合、そのユーザーインスタンスの`login`メソッドを呼び出します。指定オブジェクトは`Illuminate\Contracts\Auth\Authenticatable`[契約](/docs/{{version}}/contracts)を実装しておく必要があります。Laravelの`App\Models\User`モデルは、このインターフェイスを始めから実装しています。この認証方法は、ユーザーがアプリケーションに登録した直後など、すでに有効なユーザーインスタンスがある場合に役立ちます。

    Auth::login($user);

    // 指定したユーザーでログインし、"remember"にする
    Auth::login($user, true);

使用したいガードインスタンスを指定することもできます。

    Auth::guard('admin')->login($user);

<a name="authenticate-a-user-by-id"></a>
#### IDによるユーザー認証

ユーザーをアプリケーションへIDによりログインさせる場合は、`loginUsingId`メソッドを使います。このメソッドは認証させたいユーザーの主キーを引数に受け取ります。

    Auth::loginUsingId(1);

    // 指定したユーザーでログインし、"remember"にする
    Auth::loginUsingId(1, true);

<a name="authenticate-a-user-once"></a>
#### ユーザーを一度だけ認証する

`once`メソッドを使用すると、アプリケーションにユーザーをそのリクエストの間だけログインさせることができます。セッションもクッキーも使用しないため、ステートレスなAPIを構築する場合に便利です。

    if (Auth::once($credentials)) {
        //
    }

<a name="http-basic-authentication"></a>
## HTTP基本認証

[HTTP基本認証](https://en.wikipedia.org/wiki/Basic_access_authentication)により、専用の「ログイン」ページを用意しなくても手っ取り早くアプリケーションにユーザーをログインさせられます。これを使用するには、ルートに`auth.basic`[ミドルウェア](/docs/{{version}}/middleware)を付けてください。`auth.basic`ミドルウェアはLaravelフレームワークに含まれているので、定義する必要はありません。

    Route::get('profile', function() {
        // 認証済みのユーザーのみが入れる
    })->middleware('auth.basic');

ミドルウェアをルートに指定すれば、ブラウザからこのルートへアクセスされると自動的に認証が求められます。デフォルトでは、`auth.basic`ミドルウェアはユーザーを決める"username"としてユーザーの`email`カラムを使用します。

<a name="a-note-on-fastcgi"></a>
#### FastCGIの注意

PHP FastCGIを使用している場合、初期状態のままでHTTP基本認証は正しく動作しないでしょう。以下の行を`.htaccess`ファイルへ追加してください。

    RewriteCond %{HTTP:Authorization} ^(.+)$
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

<a name="stateless-http-basic-authentication"></a>
### ステートレスなHTTP基本認証

セッションの識別クッキーを用いずにHTTP基本認証を使用することもできます。これはとくにAPI認証に便利です。実装するには、`onceBasic`メソッドを呼び出す[ミドルウェアを定義](/docs/{{version}}/middleware)してください。`onceBasic`メソッドが何もレスポンスを返さなかった場合、リクエストをアプリケーションの先の処理へ通します。

    <?php

    namespace App\Http\Middleware;

    use Illuminate\Support\Facades\Auth;

    class AuthenticateOnceWithBasicAuth
    {
        /**
         * 送信されたリクエストの処理
         *
         * @param  \Illuminate\Http\Request  $request
         * @param  \Closure  $next
         * @return mixed
         */
        public function handle($request, $next)
        {
            return Auth::onceBasic() ?: $next($request);
        }

    }

次に[ルートミドルウェアを登録](/docs/{{version}}/middleware#registering-middleware)し、ルートに付加します。

    Route::get('api/user', function() {
        // 認証済みのユーザーのみが入れる
    })->middleware('auth.basic.once');

<a name="logging-out"></a>
## ログアウト

アプリケーションからユーザーをログアウトさせる場合、`Auth`ファサードの`logout`メソッドを使用してください。これにより、ユーザーセッションの認証情報はクリアされます。

    use Illuminate\Support\Facades\Auth;

    Auth::logout();

<a name="invalidating-sessions-on-other-devices"></a>
### 他のデバイス上のセッションを無効化

さらにLaravelは現在のユーザーの現在のデバイス上のセッションを無効化せずに、他のデバイス上のセッションを無効化し、「ログアウト」させるメカニズムを提供しています。通常この機能は、ユーザーがパスワードを変更した場合に現在のデバイスの認証を保持したまま、他のデバイスのセッションを切断したいときに便利でしょう。

これを使用するには、`app/Http/Kernel.php`クラスの`web`ミドルウェアグループ中に、`Illuminate\Session\Middleware\AuthenticateSession`ミドルウェアが存在し、コメントを確実に外してください。

    'web' => [
        // ...
        \Illuminate\Session\Middleware\AuthenticateSession::class,
        // ...
    ],

それから、`Auth`ファサードの`logoutOtherDevices`メソッドを使用してください。このメソッドは、入力フォームからアプリケーションが受け取る、現在のパスワードを引数に渡す必要があります。

    use Illuminate\Support\Facades\Auth;

    Auth::logoutOtherDevices($password);

`logoutOtherDevices`メソッドが起動すると、ユーザーの他のセッションはすべて無効になります。つまり、以前に認証済みのすべてのガードが「ログアウト」されます。

> {note} `login`ルートに対するルート名をカスタマイズしながら、`AuthenticateSession`ミドルウェアを使用している場合は、アプリケーションの例外ハンドラにある`unauthenticated`メソッドをオーバーライドし、ログインページへユーザーを確実にリダイレクトしてください。

<a name="password-confirmation"></a>
## パスワード確認

アプリケーションの構築時、あるアクションを実行する前にユーザーからパスワードを確認してもらう必要が起きるでしょう。Laravelはこの処理を簡単にできるミドルウェアを組み込んでいます。この機能を実装するには２つのルートを定義してください。１つはユーザーにパスワードの確認を求めるビューを表示するルート、もう1つはパスワードが有効であることを確認してユーザーを目的先にリダイレクトするルートです。

> {tip} 以降のドキュメントでは、Laravelのパスワード確認機能を自分で直接統合する方法について説明しています。ただし、もっと早く始めたい場合は[Laravel Jetstream](https://jetstream.laravel.com)認証スキャフォールディングパッケージ（[ドキュメント和訳](/jetstream/1.0/ja/introduction.html)）でこの機能がサポートされています。

<a name="password-confirmation-configuration"></a>
### 設定

ユーザーによるパスワード確認後、３時間パスワードの再確認は求められません。ただし、`auth`設定ファイル内の`password_timeout`設定値の値を変更し、ユーザーがパスワードの再入力を求められるまでの時間を設定できます。

<a name="password-confirmation-routing"></a>
### ルート

<a name="the-password-confirmation-form"></a>
#### パスワード確認フォーム

はじめに、ユーザーへパスワードの確認を行うビューを表示するために必要なルートを定義します。

    Route::get('/confirm-password', function () {
        return view('auth.confirm-password');
    })->middleware(['auth'])->name('password.confirm');

ご想像のとおり、このルートが返すビューには、`password`フィールドを含むフォームが必要です。さらに、ユーザーがアプリケーションの保護領域に入っており、パスワードを確認する必要があることを説明するテキストをビュー内に含めてください。

<a name="confirming-the-password"></a>
#### パスワードの確認

次に、「パスワードの確認」ビューからのフォームリクエストを処理するルートを定義します。このルートは、パスワードを検証し、ユーザーを目的先にリダイレクトする責務を持っています。

    use Illuminate\Http\Request;
    use Illuminate\Support\Facades\Hash;

    Route::post('/confirm-password', function (Request $request) {
        if (! Hash::check($request->password, $request->user()->password)) {
            return back()->withErrors([
                'password' => ['The provided password does not match our records.']
            ]);
        }

        $request->session()->passwordConfirmed();

        return redirect()->intended();
    })->middleware(['auth', 'throttle:6,1'])->name('password.confirm');

先へ進む前に、このルートをより詳しく調べましょう。まず、リクエストの`password`属性が、認証済みユーザーのパスワードと完全に一致するか判定されます。パスワードが有効な場合、ユーザーがパスワードを確認したことをLaravelのセッションに知らせる必要があります。`passwordConfirmed`メソッドは、ユーザーのセッションにタイムスタンプをセットします。このタイムスタンプを使用して、Laravelはユーザーが最後にパスワードを確認した日時を判別できます。最後に、ユーザーを目的先にリダイレクトします。

<a name="password-confirmation-protecting-routes"></a>
### ルート保護

パスワードが最近確認されたことを確実にする必要があるアクションを実行するすべてのルートへ、`password.confirm`ミドルウェアを確実に割り当ててください。このミドルウェアはLaravelのデフォルトのインストールに含まれており、ユーザーの意図した宛先をセッションへ自動的に保存し、ユーザーがパスワードを確認した後にその場所へリダイレクトします。ユーザーが意図した宛先をセッションに保存した後、このミドルウェアはユーザーを`password.confirm`[名前付きルート](/docs/{{version}}/routing#named-routes)にリダイレクトします。

    Route::get('/settings', function () {
        // ...
    })->middleware(['password.confirm']);

    Route::post('/settings', function () {
        // ...
    })->middleware(['password.confirm']);

<a name="adding-custom-guards"></a>
## カスタムガードの追加

独自の認証ガードは`Auth`ファサードの`extend`メソッドを使用し、定義します。[サービスプロバイダ](/docs/{{version}}/providers)の中で呼び出します。`AuthServiceProvider`をLaravelはあらかじめ用意しているので、この中にコードを設置できます。

    <?php

    namespace App\Providers;

    use App\Services\Auth\JwtGuard;
    use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;
    use Illuminate\Support\Facades\Auth;

    class AuthServiceProvider extends ServiceProvider
    {
        /**
         * サービスの初期起動後の登録実行
         *
         * @return void
         */
        public function boot()
        {
            $this->registerPolicies();

            Auth::extend('jwt', function($app, $name, array $config) {
                // Illuminate\Contracts\Auth\Guardのインスタンスを返す

                return new JwtGuard(Auth::createUserProvider($config['provider']));
            });
        }
    }

上記の例のように、コールバックを`extend`メソッドに渡し、`Illuminate\Contracts\Auth\Guard`の実装を返します。このインスタンスは、カスタムガードで定義が必要ないくつかのメソッドを持っています。カスタムガードを定義したら、`auth.php`設定ファイルの、`guards`設定で使用できます。

    'guards' => [
        'api' => [
            'driver' => 'jwt',
            'provider' => 'users',
        ],
    ],

<a name="closure-request-guards"></a>
### クロージャリクエストガード

HTTPリクエストをベースとした、カスタム認証システムを実装する一番簡単な方法は、`Auth::viaRequest`メソッドを使用する方法です。このメソッドは一つのクロージャの中で、認証プロセスを素早く定義できるように用意しています。

利用するには`AuthServiceProvider`の`boot`メソッドの中から、`Auth::viaRequest`メソッドを呼び出してください。`viaRequest`メソッドの最初の引数は、認証ドライバ名です。名前にはカスタムガードを表す文字列を何でも使用できます。メソッド２つ目の引数は、受信したHTTPリクエストを受け取り、ユーザーインスタンスか認証失敗時の`null`を返すクロージャを指定します。

    use App\Models\User;
    use Illuminate\Http\Request;
    use Illuminate\Support\Facades\Auth;

    /**
     * 全認証／認可サービスの登録
     *
     * @return void
     */
    public function boot()
    {
        $this->registerPolicies();

        Auth::viaRequest('custom-token', function ($request) {
            return User::where('token', $request->token)->first();
        });
    }

カスタム認証ドライバーを定義したら、`auth.php`設定ファイルの`guards`設定で、そのドライバを利用します。

    'guards' => [
        'api' => [
            'driver' => 'custom-token',
        ],
    ],

<a name="adding-custom-user-providers"></a>
## カスタムユーザープロバイダの追加

ユーザー情報を保管するために伝統的なリレーショナルデータベースを使用したくなければ、Laravelに独自の認証ユーザープロバイダを拡張する必要があります。`Auth`ファサードの`provider`メソッドを使い、カスタムユーザープロバイダを定義します。

    <?php

    namespace App\Providers;

    use App\Extensions\RiakUserProvider;
    use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;
    use Illuminate\Support\Facades\Auth;

    class AuthServiceProvider extends ServiceProvider
    {
        /**
         * サービスの初期起動後の登録実行
         *
         * @return void
         */
        public function boot()
        {
            $this->registerPolicies();

            Auth::provider('riak', function($app, array $config) {
                // Illuminate\Contracts\Auth\UserProviderのインスタンスを返す

                return new RiakUserProvider($app->make('riak.connection'));
            });
        }
    }

`provider`メソッドでプロバイダを登録したら、`auth.php`設定ファイルで新しいユーザープロバイダへ切り替えます。最初に、新しいドライバを使用する`provider`を定義します。

    'providers' => [
        'users' => [
            'driver' => 'riak',
        ],
    ],

次に、このプロバイダを`guards`設定項目で利用します。

    'guards' => [
        'web' => [
            'driver' => 'session',
            'provider' => 'users',
        ],
    ],

<a name="the-user-provider-contract"></a>
### ユーザープロバイダ契約

`Illuminate\Contracts\Auth\UserProvider`は、MySQLやRiakなどのような持続性のストレージシステムに対する`Illuminate\Contracts\Auth\Authenticatable`の実装を取得することだけに責任を持っています。これらの２つのインターフェイスはユーザーデータがどのように保存されているか、それを表すのがどんなタイプのクラスなのかにかかわらず、認証メカニズムを機能し続けるために役立っています。

`Illuminate\Contracts\Auth\UserProvider`契約を見てみましょう。

    <?php

    namespace Illuminate\Contracts\Auth;

    interface UserProvider
    {
        public function retrieveById($identifier);
        public function retrieveByToken($identifier, $token);
        public function updateRememberToken(Authenticatable $user, $token);
        public function retrieveByCredentials(array $credentials);
        public function validateCredentials(Authenticatable $user, array $credentials);
    }

`retrieveById`関数は、通常MySQLデータベースの自動増分IDのようなユーザーを表すキーを受け付けます。IDにマッチする`Authenticatable`実装が取得され、返されます。

`retrieveByToken`関数は、一意の`$identifier`と`remember_token`フィールドに保存されている"remember me" `$token`からユーザーを取得します。前のメソッドと同じく、`Authenticatable`実装が返されます。

`updateRememberToken`メソッドは、`$user`の`remember_token`フィールドを新しい`$token`で更新します。真新しいトークンは、"remember me"ログインの試みに成功するか、そのユーザーがログアウトしたときにアサインされます。

`retrieveByCredentials`メソッドはアプリケーションへのログイン時に、`Auth::attempt`メソッドに指定するのと同じユーザー認証情報の配列を引数に取ります。メソッドは裏で動作する持続ストレージにより、認証情報に一致するユーザーを「クエリ」する必要があります。典型的な使用法の場合、このメソッドは`$credentials['username']`の"where"条件でクエリを実行するでしょう。メソッドは`Authenticatable`の実装を返します。**このメソッドはパスワードバリデーションや認証を行ってはいけません**

`validateCredentials`メソッドは指定された`$user`と、そのユーザーを認証するための`$credentials`とを比較します。たとえば、このメソッドで`$user->getAuthPassword()`の値と`$credentials['password']`を`Hash::check`により値を比較します。このメソッドは、パスワードが有効であるかを示す`true`か`false`だけを返します。

<a name="the-authenticatable-contract"></a>
### Authenticatable契約

これで`UserProvider`の各メソッドが明らかになりました。続いて`Authenticatable`契約を見てみましょう。プロバイダは`retrieveById`と`retrieveByToken`、`retrieveByCredentials`メソッドでこのインターフェイスの実装を返していたことを思い出してください。

    <?php

    namespace Illuminate\Contracts\Auth;

    interface Authenticatable
    {
        public function getAuthIdentifierName();
        public function getAuthIdentifier();
        public function getAuthPassword();
        public function getRememberToken();
        public function setRememberToken($value);
        public function getRememberTokenName();
    }

このインターフェイスはシンプルです。`getAuthIdentifierName`メソッドは、ユーザーの「主キー」フィールドの名前を返します。`getAuthIdentifier`メソッドはユーザーの主キーを返します。MySQLを裏で使用している場合、これは自動増分される主キーでしょう。`getAuthPassword`はユーザーのハッシュ済みのパスワードを返します。このインターフェイスはどのORMや抽象ストレージ層を使用しているかにかかわらず、どんなUserクラスに対しても認証システムが動作するようにしてくれています。デフォルトでLaravelは`app`ディレクトリ中に、このインターフェイスを実装してる`User`クラスを持っています。ですから実装例として、このクラスを調べてみてください。

<a name="events"></a>
## イベント

Laravelは認証処理の過程で、さまざまな[イベント](/docs/{{version}}/events)を発行します。`EventServiceProvider`の中で、こうしたイベントに対するリスナを設定できます。:

    /**
     * アプリケーションに指定されたイベントリスナ
     *
     * @var array
     */
    protected $listen = [
        'Illuminate\Auth\Events\Registered' => [
            'App\Listeners\LogRegisteredUser',
        ],

        'Illuminate\Auth\Events\Attempting' => [
            'App\Listeners\LogAuthenticationAttempt',
        ],

        'Illuminate\Auth\Events\Authenticated' => [
            'App\Listeners\LogAuthenticated',
        ],

        'Illuminate\Auth\Events\Login' => [
            'App\Listeners\LogSuccessfulLogin',
        ],

        'Illuminate\Auth\Events\Failed' => [
            'App\Listeners\LogFailedLogin',
        ],

        'Illuminate\Auth\Events\Validated' => [
            'App\Listeners\LogValidated',
        ],

        'Illuminate\Auth\Events\Verified' => [
            'App\Listeners\LogVerified',
        ],

        'Illuminate\Auth\Events\Logout' => [
            'App\Listeners\LogSuccessfulLogout',
        ],

        'Illuminate\Auth\Events\CurrentDeviceLogout' => [
            'App\Listeners\LogCurrentDeviceLogout',
        ],

        'Illuminate\Auth\Events\OtherDeviceLogout' => [
            'App\Listeners\LogOtherDeviceLogout',
        ],

        'Illuminate\Auth\Events\Lockout' => [
            'App\Listeners\LogLockout',
        ],

        'Illuminate\Auth\Events\PasswordReset' => [
            'App\Listeners\LogPasswordReset',
        ],
    ];
