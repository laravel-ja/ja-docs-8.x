# HTTPリダイレクト

- [リダイレクトの作成](#creating-redirects)
- [名前付きルートへのリダイレクト](#redirecting-named-routes)
- [コントローラアクションへのリダイレクト](#redirecting-controller-actions)
- [フラッシュセッションデータを伴うリダイレクト](#redirecting-with-flashed-session-data)

<a name="creating-redirects"></a>
## リダイレクトの作成

リダイレクトレスポンスは、`Illuminate\Http\RedirectResponse`クラスのインスタンスで、ユーザーを他のURLへリダイレクトするために必要なしっかりとしたヘッダを含んでいる必要があります。`RedirectResponse`インスタンスを生成する方法はいくつかあります。一番簡単なのは、グローバルな`redirect`ヘルパを使用する方法です。

    Route::get('dashboard', function () {
        return redirect('home/dashboard');
    });

無効なフォームが送信された場合など、まれにユーザーを直前のページへリダイレクトする必要が起きます。グローバルな`back`ヘルパ関数を使用することで行なえます。この機能は[セッション](/docs/{{version}}/session)を利用しているため、`back`関数を呼び出すルートが`web`ミドルウェアグループを使用しているか、全セッションミドルウェアを確実に適用してください。

    Route::post('user/profile', function () {
        // リクエスのバリデート処理…

        return back()->withInput();
    });

<a name="redirecting-named-routes"></a>
## 名前付きルートへのリダイレクト

`redirect`ヘルパを引数なしで呼び出すと、`Illuminate\Routing\Redirector`インスタンスが返されるため、`Redirector`インスタンスの全メソッドを呼び出せます。たとえば、名前付きルートへの`RedirectResponse`を生成する場合は、`route`メソッドを使用できます。

    return redirect()->route('login');

ルートにパラメータが必要な場合は、`route`メソッドの第２引数として渡してください。

    // profile/{id}ルートへのリダイレクト

    return redirect()->route('profile', ['id' => 1]);

#### Eloquentモデルを使用したパラメータの埋め込み

あるEloquentモデルの"ID"パラメータを含むルートへリダイレクトする場合は、そのモデル自身を渡してください。IDは自動的に取り出されます。

    // profile/{id}ルートへのリダイレクト

    return redirect()->route('profile', [$user]);

ルートパラメータへ含める値をカスタマイズしたい場合は、Eloquentモデルの`getRouteKey`メソッドをオーバーライドしてください。

    /**
     * モデルのルートキー値の取得
     *
     * @return mixed
     */
    public function getRouteKey()
    {
        return $this->slug;
    }

<a name="redirecting-controller-actions"></a>
## コントローラアクションへのリダイレクト

[コントローラアクション](/docs/{{version}}/controllers)へのリダイレクトを生成することもできます。そのためには、`action`メソッドへコントローラとアクションの名前を渡してください。

    use App\Http\Controllers\HomeController;

    return redirect()->action([HomeController::class, 'index']);

コントローラルートがパラメータを必要としている場合、`action`メソッドの第２引数として渡してください。

    return redirect()->action(
        [UserController::class, 'profile'], ['id' => 1]
    );

<a name="redirecting-with-flashed-session-data"></a>
## フラッシュセッションデータを伴うリダイレクト

新しいURLへリダイレクトし、[セッションへデータを保持する](/docs/{{version}}/session#flash-data)のは、通常同時に行います。あるアクションが正しく実行された後に、セッションへ成功メッセージをフラッシュデータとして保存するのが典型的なケースでしょう。便利なように、`RedirectResponse`インスタンスを生成し、データをセッションへフラッシュデータとして保存するには、記述的なチェーン一つで行なえます。

    Route::post('user/profile', function () {
        // ユーザープロフィールの更新処理…

        return redirect('dashboard')->with('status', 'プロフィールを更新しました！');
    });

ユーザーをリダイレクトしたあと、[セッション](/docs/{{version}}/session)のフラッシュデータとして保存したメッセージを表示できます。例として[Blade記法](/docs/{{version}}/blade)を使ってみます。

    @if (session('status'))
        <div class="alert alert-success">
            {{ session('status') }}
        </div>
    @endif
