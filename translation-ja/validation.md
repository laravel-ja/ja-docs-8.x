# バリデーション

- [イントロダクション](#introduction)
- [クイックスタート](#validation-quickstart)
    - [ルート定義](#quick-defining-the-routes)
    - [コントローラ作成](#quick-creating-the-controller)
    - [バリデーションロジック作成](#quick-writing-the-validation-logic)
    - [バリデーションエラー表示](#quick-displaying-the-validation-errors)
    - [フォームの再取得](#repopulating-forms)
    - [オプションフィールドに対する注意](#a-note-on-optional-fields)
- [フォームリクエストバリデーション](#form-request-validation)
    - [フォームリクエスト作成](#creating-form-requests)
    - [フォームリクエストの認可](#authorizing-form-requests)
    - [エラーメッセージのカスタマイズ](#customizing-the-error-messages)
    - [検証のための入力準備](#preparing-input-for-validation)
- [バリデータの生成](#manually-creating-validators)
    - [自動リダイレクト](#automatic-redirection)
    - [名前付きエラーバッグ](#named-error-bags)
    - [エラーメッセージのカスタマイズ](#manual-customizing-the-error-messages)
    - [バリデーション後フック](#after-validation-hook)
- [エラーメッセージ操作](#working-with-error-messages)
    - [言語ファイルでのカスタムメッセージの指定](#specifying-custom-messages-in-language-files)
    - [言語ファイルでの属性の指定](#specifying-attribute-in-language-files)
    - [言語ファイルでの値の指定](#specifying-values-replacements-in-language-files)
- [使用可能なバリデーションルール](#available-validation-rules)
- [条件付きの追加ルール](#conditionally-adding-rules)
- [配列のバリデーション](#validating-arrays)
- [パスワードのバリデーション](#validating-passwords)
- [カスタムバリデーションルール](#custom-validation-rules)
    - [ルールオブジェクトの使用](#using-rule-objects)
    - [クロージャの使用](#using-closures)
    - [暗黙のルール](#implicit-rules)

<a name="introduction"></a>
## イントロダクション

Laravelは、アプリケーションの受信データをバリデーションするために複数の異なるアプローチを提供します。すべての受信HTTPリクエストで使用可能な`validate`メソッドを使用するのがもっとも一般的です。しかし、バリデーションに対する他のアプローチについても説明します。

Laravelは、データに適用できる便利で数多くのバリデーションルールを持っており、特定のデータベーステーブルで値が一意であるかどうかをバリデーションする機能も提供します。Laravelのすべてのバリデーション機能に精通できるように、各バリデーションルールを詳しく説明します。

<a name="validation-quickstart"></a>
## クイックスタート

Laravelの強力なバリデーション機能について学ぶため、フォームをバリデーションし、エラーメッセージをユーザーに表示する完全な例を見てみましょう。この高レベルの概要を読むことで、Laravelを使用して受信リクエストデータをバリデーションする一般的な方法を理解できます。

<a name="quick-defining-the-routes"></a>
### ルート定義

まず、`routes/web.php`ファイルに以下のルートを定義してあるとしましょう。

    use App\Http\Controllers\PostController;

    Route::get('/post/create', [PostController::class, 'create']);
    Route::post('/post', [PostController::class, 'store']);

`GET`のルートは新しいブログポストを作成するフォームをユーザーへ表示し、`POST`ルートで新しいブログポストをデータベースへ保存します。

<a name="quick-creating-the-controller"></a>
### コントローラ作成

次に、これらのルートへの受信リクエストを処理する単純なコントローラを見てみましょう。今のところ、`store`メソッドは空のままにしておきます。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use Illuminate\Http\Request;

    class PostController extends Controller
    {
        /**
         * 新ブログポスト作成フォームの表示
         *
         * @return \Illuminate\View\View
         */
        public function create()
        {
            return view('post.create');
        }

        /**
         * 新しいブログポストの保存
         *
         * @param  \Illuminate\Http\Request  $request
         * @return \Illuminate\Http\Response
         */
        public function store(Request $request)
        {
            // ブログポストのバリデーションと保存コード…
        }
    }

<a name="quick-writing-the-validation-logic"></a>
### バリデーションロジック

これで、新しいブログ投稿をバリデーションするロジックを`store`メソッドに入力する準備が整いました。これを行うには、`Illuminate\Http\Request`オブジェクトによって提供される`validate`メソッドを使用します。バリデーションルールにパスすると、コードは正常に実行され続けます。しかし、バリデーションに失敗すると例外が投げられ、適切なエラーレスポンスが自動的にユーザーに返送されます。

伝統的なHTTPリクエスト処理中にバリデーションが失敗した場合、直前のURLへのリダイレクトレスポンスが生成されます。受信リクエストがXHRリクエストの場合、バリデーションエラーメッセージを含むJSONレスポンスが返されます。

`validate`メソッドをもっとよく理解するため、`store`メソッドに取り掛かりましょう。

    /**
     * 新ブログポストの保存
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|unique:posts|max:255',
            'body' => 'required',
        ]);

        // ブログポストは有効
    }

ご覧のとおり、バリデーションルールは`validate`メソッドへ渡されます。心配いりません。利用可能なすべてのバリデーションルールは[文書化](#available-validation-rules)されています。この場合でもバリデーションが失敗したとき、適切な応答が自動的に生成されます。バリデーションにパスすると、コントローラは正常に実行を継続します。

もしくは、バリデーションルールを`|`で区切られた一つの文字列の代わりに、ルールの配列で指定することもできます。

    $validatedData = $request->validate([
        'title' => ['required', 'unique:posts', 'max:255'],
        'body' => ['required'],
    ]);

さらに、`validateWithBag`メソッドを使用して、リクエストをバリデーションした結果のエラーメッセージを[namederrorbag](#named-error-bags)内へ保存できます。

    $validatedData = $request->validateWithBag('post', [
        'title' => ['required', 'unique:posts', 'max:255'],
        'body' => ['required'],
    ]);

<a name="stopping-on-first-validation-failure"></a>
#### 最初のバリデーション失敗時に停止

最初のバリデーションに失敗したら、残りのバリデーションルールの判定を停止したいことも、ときどきあります。このためには、`bail`ルールを使ってください。

    $request->validate([
        'title' => 'bail|required|unique:posts|max:255',
        'body' => 'required',
    ]);

この例の場合、`title`属性の`unique`ルールに失敗すると、`max`ルールはチェックされません。ルールは指定した順番にバリデートされます。

<a name="a-note-on-nested-attributes"></a>
#### ネストした属性の注意点

受信HTTPリクエストに「ネストされた」フィールドデータが含まれている場合は、「ドット」構文を使用してバリデーションルールでこうしたフィールドを指定できます。

    $request->validate([
        'title' => 'required|unique:posts|max:255',
        'author.name' => 'required',
        'author.description' => 'required',
    ]);

フィールド名にピリオドそのものが含まれている場合は、そのピリオドをバックスラッシュでエスケープし、「ドット」構文として解釈されることを明示的に防げます。

    $request->validate([
        'title' => 'required|unique:posts|max:255',
        'v1\.0' => 'required',
    ]);

<a name="quick-displaying-the-validation-errors"></a>
### バリデーションエラー表示

では、受信リクエストフィールドが指定したバリデーションルールにパスしない場合はどうなるでしょうか。前述のように、Laravelはユーザーを直前の場所へ自動的にリダイレクトします。さらに、すべてのバリデーションエラーと[リクエスト入力](/docs/{{version}}/requests#retrieveing-old-input)は自動的に[セッションに一時保持](/docs/{{version}}/session#flash-data)保存されます。

`$errors`変数は、`web`ミドルウェアグループが提供する`Illuminate\View\Middleware\ShareErrorsFromSession`ミドルウェアにより、アプリケーションのすべてのビューで共有されます。このミドルウェアが適用されると、ビューで`$errors`変数は常に定義され、`$errors`変数が常に使用可能になり、安全・便利に使用できると想定できます。`$errors`変数は`Illuminate\Support\MessageBag`のインスタンスです。このオブジェクトの操作の詳細は、[ドキュメントを確認してください](#working-with-error-messages)。

この例では、バリデーションに失敗すると、エラーメッセージをビューで表示できるように、コントローラの`create`メソッドへリダイレクトされることになります。

```html
<!-- /resources/views/post/create.blade.php -->

<h1>Create Post</h1>

@if ($errors->any())
    <div class="alert alert-danger">
        <ul>
            @foreach ($errors->all() as $error)
                <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
@endif

<!-- Postフォームの作成 -->
```

<a name="quick-customizing-the-error-messages"></a>
#### エラーメッセージのカスタマイズ

Laravelの組み込みバリデーションルールにはそれぞれエラーメッセージがあり、アプリケーションの`resources/lang/en/validation.php`ファイルに登録されています。このファイル内に、各バリデーションルールの翻訳エントリがあります。アプリケーションの要求に基づいて、これらのメッセージを自由に変更できます。

さらに、アプリケーションの言語へメッセージを翻訳するために、このファイルを別の翻訳言語ディレクトリにコピーできます。Laravelのローカリゼーションの詳細については、完全な[多言語化ドキュメント](/docs/{{version}}/localization)をご覧ください。

<a name="quick-xhr-requests-and-validation"></a>
#### XHRリクエストとバリデーション

この例では、従来のフォームを使用してデータをアプリケーションに送信しました。ただし、多くのアプリケーションは、JavaScriptを利用したフロントエンドからXHRリクエストを受信します。XHRリクエスト中に`validate`メソッドを使用すると、Laravelはリダイレクト応答を生成しません。代わりに、Laravelはすべてのバリデーションエラーを含むJSONレスポンスを生成します。このJSONレスポンスは、422 HTTPステータスコードとともに送信されます。

<a name="the-at-error-directive"></a>
#### `@error`ディレクティブ

`@error`[Blade](/docs/{{version}}/brade)ディレクティブを使用して、特定の属性にバリデーションエラーメッセージが存在するかどうかを簡単に判断できます。`@error`ディレクティブ内で、`$message`変数をエコーし​​てエラーメッセージを表示ができます。

```html
<!-- /resources/views/post/create.blade.php -->

<label for="title">Post Title</label>

<input id="title" type="text" name="title" class="@error('title') is-invalid @enderror">

@error('title')
    <div class="alert alert-danger">{{ $message }}</div>
@enderror
```

<a name="repopulating-forms"></a>
### フォームの再取得

Laravelがバリデーションエラーのためにリダイレクトレスポンスを生成するとき、フレームワークは自動的に[セッションへのリクエストのすべての入力を一時保持保存します](/docs/{{version}}/session#flash-data)。これは、直後のリクエスト時、保存しておいた入力に簡単にアクセスし、ユーザーが送信しようとしたフォームを再入力・再表示できるようにします。

直前のリクエストから一時保持保存された入力を取得するには、`Illuminate\Http\Request`のインスタンスで`old`メソッドを呼び出します。`old`メソッドは、直前に一時保持保存した入力データを[session](/docs/{{version}}/session)から取り出します。

    $title = $request->old('title');

Laravelはグローバルな`old`ヘルパも提供しています。[Bladeテンプレート](/docs/{{version}}/Blade)内に古い入力を表示している場合は、`old`ヘルパを使用してフォームを再入力・再表示する方が便利です。指定されたフィールドに古い入力が存在しない場合、`null`が返されます。

    <input type="text" name="title" value="{{ old('title') }}">

<a name="a-note-on-optional-fields"></a>
### オプションフィールドに対する注意

Laravelは`TrimStrings`と`ConvertEmptyStringsToNull`ミドルウェアをアプリケーションのデフォルトグローバルミドルウェアスタックに含んでいます。これらのミドルウェアは`App\Http\Kernel`クラスでリストされています。このため、バリデータが`null`値を無効であると判定しないように、オプションフィールドへ`nullable`を付ける必要が頻繁に起きるでしょう。

    $request->validate([
        'title' => 'required|unique:posts|max:255',
        'body' => 'required',
        'publish_at' => 'nullable|date',
    ]);

上記の例の場合、`publish_at`フィールドが`null`か、有効な日付表現であることを指定しています。ルール定義に`nullable`が追加されないと、バリデータは`null`を無効な日付として判定します。

<a name="form-request-validation"></a>
## フォームリクエストバリデーション

<a name="creating-form-requests"></a>
### フォームリクエスト作成

より複雑なバリデーションシナリオの場合は、「フォームリクエスト」を作成することをお勧めします。フォームリクエストは、独自のバリデーションおよび承認ロジックをカプセル化するカスタムリクエストクラスです。フォームリクエストクラスを作成するには、`make:request` Artisan CLIコマンドを使用します。

    php artisan make:request StorePostRequest

生成したフォームリクエストクラスは、`app/Http/Requests`ディレクトリに配置されます。このディレクトリが存在しない場合は、`make:request`コマンドの実行時に作成されます。Laravelにより生成される各フォームリクエストには、`authorize`と`rules`の2つのメソッドがあります。

ご想像のとおり、`authorize`メソッドは、現在認証されているユーザーがリクエストによって表されるアクションを実行できるかどうかを判断し、`rules`メソッドはリクエスト中のデータを検証するバリデーションルールを返します。

    /**
     * リクエストに適用するバリデーションルールを取得
     *
     * @return array
     */
    public function rules()
    {
        return [
            'title' => 'required|unique:posts|max:255',
            'body' => 'required',
        ];
    }

> {tip} `rules`メソッドの引数で必要な依存関係をタイプヒントにより指定することができます。それらはLaravel[サービスコンテナ](/docs/{{version}}/container)を介して自動的に依存解決されます。

では、どのようにバリデーションルールを実行するのでしょうか？必要なのはコントローラのメソッドで、このリクエストをタイプヒントで指定することです。やって来たフォームリクエストはコントローラメソッドが呼び出される前にバリデーションを行います。つまり、コントローラでバリデーションロジックを取っ散らかす必要はありません。

    /**
     * 新しいブログ投稿を保存
     *
     * @param  \App\Http\Requests\StorePostRequest  $request
     * @return Illuminate\Http\Response
     */
    public function store(StorePostRequest $request)
    {
        // 送信されたリクエストは正しい

        // バリデーション済みデータの取得
        $validated = $request->validated();
    }

バリデーションが失敗した場合、リダイレクトレスポンスが生成され、ユーザーを直前の場所に送り返します。エラーもセッ​​ションに一時保持され、表示できます。リクエストがXHRリクエストの場合、バリデーションエラーのJSON表現を含む422ステータスコードのHTTPレスポンスがユーザーに返されます。

<a name="adding-after-hooks-to-form-requests"></a>
#### フォームリクエストへのAfterフックを追加

フォームリクエストに"after"のバリデーションフックを追加する場合は、`withValidator`メソッドを使用します。このメソッドは完全に構築されたバリデータを受け取り、バリデーションルールの実際の評価前に、メソッドのいずれでも呼び出せます。

    /**
     * バリデータインスタンスの設定
     *
     * @param  \Illuminate\Validation\Validator  $validator
     * @return void
     */
    public function withValidator($validator)
    {
        $validator->after(function ($validator) {
            if ($this->somethingElseIsInvalid()) {
                $validator->errors()->add('field', 'Something is wrong with this field!');
            }
        });
    }


<a name="request-stopping-on-first-validation-rule-failure"></a>
#### 最初のバリデーション失敗属性で停止

リクエストクラスに`stopOnFirstFailure`プロパティを追加することで、バリデーションの失敗が起きてすぐに、すべての属性のバリデーションを停止する必要があることをバリデータへ指示できます。

    /**
     * バリデータが最初のルールの失敗で停​​止するかを指示
     *
     * @var bool
     */
    protected $stopOnFirstFailure = true;

<a name="authorizing-form-requests"></a>
### フォームリクエストの認可

フォームリクエストクラスには、`authorize`メソッドも含まれています。このメソッド内で、認証済みユーザーが特定のリソースを更新する権限を持っているかどうかを判別できます。たとえば、ユーザーが更新しようとしているブログコメントを実際に所有しているかどうかを判断できます。ほとんどの場合、次の方法で[認可ゲートとポリシー](/docs/{{version}}/authentication)を操作します。

    use App\Models\Comment;

    /**
     * ユーザーがこのリクエストの権限を持っているかを判断する
     *
     * @return bool
     */
    public function authorize()
    {
        $comment = Comment::find($this->route('comment'));

        return $comment && $this->user()->can('update', $comment);
    }

全フォームリクエストはLaravelのベースリクエストクラスを拡張していますので、現在認証済みユーザーへアクセスする、`user`メソッドが使えます。また、上記例中の`route`メソッドの呼び出しにも、注目してください。たとえば`{comment}`パラメーターのような、呼び出しているルートで定義してあるURIパラメータにもアクセスできます。

    Route::post('/comment/{comment}');

したがって、アプリケーションが[ルートモデル結合](/docs/{{version}}/routing#route-model-binding)を利用している場合、解決されたモデルをリクエストのプロパティとしてアクセスすることで、コードをさらに簡潔にすることができます。

    return $this->user()->can('update', $this->comment);

`authorize`メソッドが`false`を返すと、403ステータスコードのHTTPレスポンスを自動的に返し、コントローラメソッドは実行しません。

アプリケーションの別の部分でリクエストの認可ロジックを処理する場合は、`authorize`メソッドから`true`を返してください。

    /**
     * ユーザーがこのリクエストの権限を持っているか判断
     *
     * @return bool
     */
    public function authorize()
    {
        return true;
    }

> {tip} `authorize`メソッドの引数で、必要な依存をタイプヒントにより指定できます。それらはLaravelの[サービスコンテナ](/docs/{{version}}/container)により、自動的に依存解決されます。

<a name="customizing-the-error-messages"></a>
### エラーメッセージのカスタマイズ

フォームリクエストにより使用されているメッセージは`message`メソッドをオーバーライドすることによりカスタマイズできます。このメソッドから属性／ルールと対応するエラーメッセージのペアを配列で返してください。

    /**
     * 定義済みバリデーションルールのエラーメッセージ取得
     *
     * @return array
     */
    public function messages()
    {
        return [
            'title.required' => 'A title is required',
            'body.required' => 'A message is required',
        ];
    }

<a name="customizing-the-validation-attributes"></a>
#### バリデーション属性のカスタマイズ

Laravelの組み込みバリデーションルールエラーメッセージの多くは、`:attribute`プレースホルダーを含んでいます。バリデーションメッセージの`:attribute`プレースホルダーをカスタム属性名に置き換えたい場合は、`attributes`メソッドをオーバーライドしてカスタム名を指定します。このメソッドは、属性と名前のペアの配列を返す必要があります。

    /**
     * バリデーションエラーのカスタム属性の取得
     *
     * @return array
     */
    public function attributes()
    {
        return [
            'email' => 'email address',
        ];
    }

<a name="preparing-input-for-validation"></a>
### 検証のための入力準備

バリデーションルールを適用する前にリクエストからのデータを準備またはサニタイズする必要がある場合は、`prepareForValidation`メソッド使用します。

    use Illuminate\Support\Str;

    /**
     * バリーデーションのためにデータを準備
     *
     * @return void
     */
    protected function prepareForValidation()
    {
        $this->merge([
            'slug' => Str::slug($this->slug),
        ]);
    }

<a name="manually-creating-validators"></a>
## バリデータの生成

リクエストの`validate`メソッドを使用したくない場合は、`Validator`[ファサード](/docs/{{version}}/facades)を使用し、バリデータインスタンスを生成する必要があります。 このファサードの`make`メソッドで、新しいバリデータインスタンスを生成します。

    <?php

    namespace App\Http\Controllers;

    use App\Http\Controllers\Controller;
    use Illuminate\Http\Request;
    use Illuminate\Support\Facades\Validator;

    class PostController extends Controller
    {
        /**
         * 新しいブログポストの保存
         *
         * @param  Request  $request
         * @return Response
         */
        public function store(Request $request)
        {
            $validator = Validator::make($request->all(), [
                'title' => 'required|unique:posts|max:255',
                'body' => 'required',
            ]);

            if ($validator->fails()) {
                return redirect('post/create')
                            ->withErrors($validator)
                            ->withInput();
            }

            // ブログポストの保存処理…
        }
    }

`make`メソッドの第１引数は、バリデーションを行うデータです。第２引数はそのデータに適用するバリデーションルールの配列です。

リクエストのバリデーションが失敗したかどうかを判断した後、`withErrors`メソッドを使用してエラーメッセージをセッションに一時保持保存できます。この方法を使用すると、リダイレクト後に`$errors`変数がビューと自動的に共有されるため、メッセージをユーザーへ簡単に表示できます。`withErrors`メソッドは、バリデータ、`MessageBag`、またはPHPの`array`を引数に取ります。

#### 最初のバリデート失敗時に停止

`stopOnFirstFailure`メソッドは、バリデーションが失敗したら、すぐにすべての属性のバリデーションを停止する必要があることをバリデータへ指示します。

    if ($validator->stopOnFirstFailure()->fails()) {
        // ...
    }

<a name="automatic-redirection"></a>
### 自動リダイレクト

バリデータインスタンスを手動で作成するが、HTTPリクエストの`validate`メソッドによって提供される自動リダイレクトを利用したい場合は、既存のバリデータインスタンスで`validate`メソッドを呼び出すことができます。バリデーションが失敗した場合、ユーザーは自動的にリダイレクトされます。XHRリクエストの場合は、JSONレスポンスが返されます。

    Validator::make($request->all(), [
        'title' => 'required|unique:posts|max:255',
        'body' => 'required',
    ])->validate();

`validateWithBag`メソッドを使用しリクエストのバリデートを行った結果、失敗した場合に、エラーメッセージを[名前付きエラーバッグ](#named-error-bags)へ保存することもできます。

    Validator::make($request->all(), [
        'title' => 'required|unique:posts|max:255',
        'body' => 'required',
    ])->validateWithBag('post');

<a name="named-error-bags"></a>
### 名前付きエラーバッグ

1つのページに複数のフォームがある場合は、バリデーションエラーを含む`MessageBag`に名前を付けて、特定のフォームのエラーメッセージを取得可能にできます。これを実現するには、`withErrors`の２番目の引数として名前を渡します。

    return redirect('register')->withErrors($validator, 'login');

`$errors`変数を使い、名前を付けた`MessageBag`インスタンスへアクセスできます。

    {{ $errors->login->first('email') }}

<a name="manual-customizing-the-error-messages"></a>
### エラーメッセージのカスタマイズ

必要に応じて、Laravelが提供するデフォルトのエラーメッセージの代わりにバリデータインスタンスが使用するカスタムエラーメッセージを指定できます。カスタムメッセージを指定する方法はいくつかあります。まず、カスタムメッセージを`validator::make`メソッドに３番目の引数として渡す方法です。

    $validator = Validator::make($input, $rules, $messages = [
        'required' => 'The :attribute field is required.',
    ]);

この例の、`:attribute`プレースホルダーは、バリデーション中のフィールドの名前に置き換えられます。バリデーションメッセージには他のプレースホルダーも利用できます。例をご覧ください。

    $messages = [
        'same' => 'The :attribute and :other must match.',
        'size' => 'The :attribute must be exactly :size.',
        'between' => 'The :attribute value :input is not between :min - :max.',
        'in' => 'The :attribute must be one of the following types: :values',
    ];

<a name="specifying-a-custom-message-for-a-given-attribute"></a>
#### 特定の属性に対するカスタムメッセージ指定

特定の属性に対してのみカスタムエラーメッセージを指定したい場合があります。「ドット」表記を使用してこれを行うことができます。最初に属性の名前を指定し、次にルールを指定します。

    $messages = [
        'email.required' => 'We need to know your email address!',
    ];

<a name="specifying-custom-attribute-values"></a>
#### カスタム属性値の指定

Laravelの組み込みエラーメッセージの多くには、バリデーション中のフィールドや属性の名前に置き換えられる`:attribute`プレースホルダーが含まれています。特定のフィールドでこれらのプレースホルダーを置き換える値をカスタマイズするには、カスタム属性表示名の配列を4番目の引数として`Validator::make`メソッドに渡します。

    $validator = Validator::make($input, $rules, $messages, [
        'email' => 'email address',
    ]);

<a name="after-validation-hook"></a>
### バリデーション後のフック

バリデーションが完了した後に実行するコールバックを添付することもできます。これにより、追加のバリデーションを簡単に実行し、メッセージコレクションにエラーメッセージを追加することもできます。利用するには、バリデータインスタンスで`after`メソッドを呼び出します。

    $validator = Validator::make(...);

    $validator->after(function ($validator) {
        if ($this->somethingElseIsInvalid()) {
            $validator->errors()->add(
                'field', 'Something is wrong with this field!'
            );
        }
    });

    if ($validator->fails()) {
        //
    }

<a name="working-with-error-messages"></a>
## エラーメッセージの操作

`Validator`インスタンスの`errors`メソッドを呼び出すと、エラーメッセージを操作する便利なメソッドを数揃えた、`Illuminate\Support\MessageBag`インスタンスを受け取ります。自動的に作成され、すべてのビューで使用できる`$errors`変数も、`MessageBag`クラスのインスタンスです。

<a name="retrieving-the-first-error-message-for-a-field"></a>
#### 指定フィールドの最初のエラーメッセージ取得

指定したフィールドの最初のエラーメッセージを取得するには、`first`メソッドを使います。

    $errors = $validator->errors();

    echo $errors->first('email');

<a name="retrieving-all-error-messages-for-a-field"></a>
#### 指定フィールドの全エラーメッセージ取得

指定したフィールドの全エラーメッセージを配列で取得したい場合は、`get`メソッドを使います。

    foreach ($errors->get('email') as $message) {
        //
    }

配列形式のフィールドをバリデーションする場合は、`*`文字を使用し、各配列要素の全メッセージを取得できます。

    foreach ($errors->get('attachments.*') as $message) {
        //
    }

<a name="retrieving-all-error-messages-for-all-fields"></a>
#### 全フィールドの全エラーメッセージ取得

全フィールドの全メッセージの配列を取得したい場合は、`all`メソッドを使います。

    foreach ($errors->all() as $message) {
        //
    }

<a name="determining-if-messages-exist-for-a-field"></a>
#### 指定フィールドのメッセージ存在確認

`has`メソッドは、指定したフィールドのエラーメッセージが存在しているかを判定するために使います。

    if ($errors->has('email')) {
        //
    }

<a name="specifying-custom-messages-in-language-files"></a>
### 言語ファイルでのカスタムメッセージの指定

Laravelの各組み込みバリデーションルールには、アプリケーションの`resources/lang/en/validation.php`ファイルにエラーメッセージが用意されています。このファイル内に、各バリデーションルールの翻訳エントリがあります。アプリケーションのニーズに基づいて、これらのメッセージを自由に変更または変更できます。

さらに、このファイルを別の翻訳言語ディレクトリにコピーして、アプリケーションの言語のメッセージを翻訳できます。Laravelのローカリゼーションの詳細については、完全な[多言語化ドキュメント](/docs/{{version}}/localization)をご覧ください。

<a name="custom-messages-for-specific-attributes"></a>
#### 特定の属性のカスタムメッセージ

アプリケーションのバリデーション言語ファイル内で、属性とルールの組み合わせを指定して、エラーメッセージをカスタマイズできます。これを行うには、カスタマイズメッセージをアプリケーションの`resources/lang/xx/validation.php`言語ファイルの`custom`配列へ追加します。

    'custom' => [
        'email' => [
            'required' => 'We need to know your email address!',
            'max' => 'Your email address is too long!'
        ],
    ],

<a name="specifying-attribute-in-language-files"></a>
### 言語ファイルでの属性の指定

Laravelの組み込みエラーメッセージの多くには、バリデーション中のフィールドまたは属性の名前に置き換えられる`:attribute`プレースホルダーが含まれています。バリデーションメッセージの`:attribute`部分をカスタム値に置き換えたい場合は、`resources/lang/xx/validation.php`言語ファイルの`attributes`配列でカスタム属性名を指定してください。

    'attributes' => [
        'email' => 'email address',
    ],

<a name="specifying-values-in-language-files"></a>
### 言語ファイルでの値の指定

Laravelの組み込みバリデーションルールエラーメッセージの一部には、リクエスト属性の現在の値に置き換えられる`:value`プレースホルダーが含まれています。ただし、バリデーションメッセージの`:value`部分を値のカスタム表現へ置き換えたい場合があるでしょう。たとえば、`payment_type`の値が`cc`の場合にクレジットカード番号が必要であることを定義する次のルールについて考えてみます。

    Validator::make($request->all(), [
        'credit_card_number' => 'required_if:payment_type,cc'
    ]);

このバリデーションルールが通らない場合に、次のようなメッセージが表示されるとします。

    The credit card number field is required when payment type is cc.

支払いタイプの値として`cc`を表示する代わりに、`values`配列を定義することにより、`resources/lang/xx/validation.php`言語ファイルでよりユーザーフレンドリーな値表現が指定できます。

    'values' => [
        'payment_type' => [
            'cc' => 'credit card'
        ],
    ],

この値を定義したら、バリデーションルールは次のエラーメッセージを生成します。

    The credit card number field is required when payment type is credit card.

<a name="available-validation-rules"></a>
## 使用可能なバリデーションルール

使用可能な全バリデーションルールとその機能の一覧です。

<style>
    .collection-method-list > p {
        column-count: 3; -moz-column-count: 3; -webkit-column-count: 3;
        column-gap: 2em; -moz-column-gap: 2em; -webkit-column-gap: 2em;
    }

    .collection-method-list a {
        display: block;
    }
</style>

<div class="collection-method-list" markdown="1">

[受け入れ](#rule-accepted)
[アクティブなURL](#rule-active-url)
[（日付）より後](#rule-after)
[（日付）以降](#rule-after-or-equal)
[アルファベット](#rule-alpha)
[アルファベット記号](#rule-alpha-dash)
[アルファベット数字](#rule-alpha-num)
[配列](#rule-array)
[継続終了](#rule-bail)
[（日付）より前](#rule-before)
[（日付）以前](#rule-before-or-equal)
[範囲](#rule-between)
[論理](#rule-boolean)
[確認](#rule-confirmed)
[日付](#rule-date)
[同一日付](#rule-date-equals)
[日付形式](#rule-date-format)
[相違](#rule-different)
[桁指定数値](#rule-digits)
[桁範囲指定数値](#rule-digits-between)
[寸法(画像ファイル)](#rule-dimensions)
[別々](#rule-distinct)
[メールアドレス](#rule-email)
[文字列終了](#rule-ends-with)
[条件一致時フィールド除外](#rule-exclude-if)
[条件不一致時フィールド除外](#rule-exclude-unless)
[存在（データベース）](#rule-exists)
[ファイル](#rule-file)
[充満](#rule-filled)
[より大きい](#rule-gt)
[以上](#rule-gte)
[画像（ファイル)](#rule-image)
[内包](#rule-in)
[配列内](#rule-in-array)
[整数](#rule-integer)
[IPアドレス](#rule-ip)
[JSON](#rule-json)
[より小さい](#rule-lt)
[以下](#rule-lte)
[最大値](#rule-max)
[MIMEタイプ](#rule-mimetypes)
[MIMEタイプ(ファイル拡張子)](#rule-mimes)
[最小値](#rule-min)
[倍数値](#multiple-of)
[非内包](#rule-not-in)
[正規表現不一致](#rule-not-regex)
[NULL許可](#rule-nullable)
[数値](#rule-numeric)
[パスワード](#rule-password)
[存在](#rule-present)
[禁止](#rule-prohibited)
[禁止If](#rule-prohibited-if)
[禁止Unless](#rule-prohibited-unless)
[正規表現](#rule-regex)
[必須](#rule-required)
[指定フィールド値一致時必須](#rule-required-if)
[指定フィールド値非一致時必須](#rule-required-unless)
[指定フィールド存在時必須](#rule-required-with)
[全指定フィールド存在時必須](#rule-required-with-all)
[指定フィールド非存在時必須](#rule-required-without)
[全指定フィールド非存在時必須](#rule-required-without-all)
[同一](#rule-same)
[サイズ](#rule-size)
[存在時バリデート実行](#validating-when-present)
[文字列開始](#rule-starts-with)
[文字列](#rule-string)
[タイムゾーン](#rule-timezone)
[一意（データベース）](#rule-unique)
[URL](#rule-url)
[UUID](#rule-uuid)

</div>

<a name="rule-accepted"></a>
#### accepted

フィールドが、`"yes"`、`"on"`、`1`、または`true`であることをバリデートします。これは、「利用規約」の承認または同様のフィールドをバリデーションするのに役立ちます。

<a name="rule-active-url"></a>
#### active_url

フィールドが、`dns_get_record` PHP関数により、有効なAかAAAAレコードであることをバリデートします。`dns_get_record`へ渡す前に、`parse_url` PHP関数により指定したURLのホスト名を切り出します。

<a name="rule-after"></a>
#### after:_日付_

フィールドは、指定された日付以降の値であることをバリデートします。日付を有効な`DateTime`インスタンスに変換するため、`strtotime`PHP関数に渡します。

    'start_date' => 'required|date|after:tomorrow'

`strtotime`により評価される日付文字列を渡す代わりに、その日付と比較する他のフィールドを指定することもできます。

    'finish_date' => 'required|date|after:start_date'

<a name="rule-after-or-equal"></a>
#### after\_or\_equal:_日付_

フィールドが指定した日付以降であることをバリデートします。詳細は[after](#rule-after)ルールを参照してください。

<a name="rule-alpha"></a>
#### alpha

フィールドが全部アルファベット文字であることをバリデートします。

<a name="rule-alpha-dash"></a>
#### alpha_dash

フィールドが全部アルファベット文字と数字、ダッシュ(-)、下線(_)であることをバリデートします。

<a name="rule-alpha-num"></a>
#### alpha_num

フィールドが全部アルファベット文字と数字であることをバリデートします。

<a name="rule-array"></a>
#### array

フィールドがPHPの配列タイプであることをバリデートします。

`array`ルールに追加の値を指定する場合、入力配列の各キーは、ルールに指定した値のリスト内に存在する必要があります。次の例では、入力配列の`admin`キーは、`array`ルールにした値のリストに含まれていないので、無効です。

    use Illuminate\Support\Facades\Validator;

    $input = [
        'user' => [
            'name' => 'Taylor Otwell',
            'username' => 'taylorotwell',
            'admin' => true,
        ],
    ];

    Validator::make($input, [
        'user' => 'array:username,locale',
    ]);

<a name="rule-bail"></a>
#### bail

フィールドでバリデーションにはじめて失敗した時点で、残りのルールのバリデーションを中止します。

`bail`ルールはバリデーションが失敗したときに、特定のフィールドのバリデーションのみを停止するだけで、一方の`stopOnFirstFailure`メソッドは、ひとつバリデーション失敗が発生したら、すべての属性のバリデーションを停止する必要があることをバリデータに指示します。

    if ($validator->stopOnFirstFailure()->fails()) {
        // ...
    }

<a name="rule-before"></a>
#### before:_日付_

フィールドは、指定された日付より前の値であることをバリデートします。日付を有効な`DateTime`インスタンスへ変換するために、PHPの`strtotime`関数へ渡します。さらに、[`after`](#rule-after)ルールと同様に、バリデーション中の別のフィールドの名前を`date`の値として指定できます。

<a name="rule-before-or-equal"></a>
#### before\_or\_equal:_日付_

フィールドは、指定された日付より前または同じ値であることをバリデートします。日付を有効な`DateTime`インスタンスへ変換するために、PHPの`strtotime`関数へ渡します。さらに、[`after`](#rule-after)ルールと同様に、バリデーション中の別のフィールドの名前を`date`の値として指定できます。

<a name="rule-between"></a>
#### between:_min_,_max_

フィールドが指定された**最小値**と**最大値**の間のサイズであることをバリデートします。[`size`](#rule-size)ルールと同様の判定方法で、文字列、数値、配列、ファイルが評価されます。

<a name="rule-boolean"></a>
#### boolean

フィールドが論理値として有効であることをバリデートします。受け入れられる入力は、`true`、`false`、`1`、`0`、`"1"`、`"0"`です。

<a name="rule-confirmed"></a>
#### confirmed

フィールドが、`{field}_confirmation`フィールドと一致する必要があります。たとえば、バリデーション中のフィールドが「password」の場合、「password_confirmation」フィールドが入力に存在し一致している必要があります。

<a name="rule-date"></a>
#### date

パリデーションされる値はPHP関数の`strtotime`により、有効で相対日付ではないことをバリデートします。

<a name="rule-date-equals"></a>
#### date_equals:_日付_

フィールドが、指定した日付と同じことをバリデートします。日付を有効な`DateTime`インスタンスに変換するために、PHPの`strtotime`関数へ渡します。

<a name="rule-date-format"></a>
#### date\_format:_フォーマット_

バリデーションされる値が**フォーマット**定義と一致するか確認します。バリデーション時には`date`か`date_format`の**どちらか**を使用しなくてはならず、両方はできません。このバリデーションはPHPの[DateTime](https://www.php.net/manual/ja/class.datetime.php)クラスがサポートするフォーマットをすべてサポートしています。

<a name="rule-different"></a>
#### different:_フィールド_

フィールドが指定された**フィールド**と異なった値を指定されていることをバリデートします。

<a name="rule-digits"></a>
#### digits:_値_

フィールドが**数値**で、**値**の桁数であることをバリデートします。

<a name="rule-digits-between"></a>
#### digits_between:_最小値_,_最大値_

フィールドが**整数で**、桁数が**最小値**から**最大値**の間であることをバリデートします。

<a name="rule-dimensions"></a>
#### dimensions

バリデーション対象のファイルが、パラメータにより指定されたサイズに合致することをバリデートします。

    'avatar' => 'dimensions:min_width=100,min_height=200'

使用可能なパラメータは、**min\_width**、**max\_width**、**min\_height**、**max\_height**、**width_**、**_height**、**ratio**です。

**_ratio_**制約は、幅を高さで割ったものとして表す必要があります。これは、`3/2`のような分数または`1.5`のようなfloatのいずれかで指定します。

    'avatar' => 'dimensions:ratio=3/2'

このルールは多くの引数を要求するので、`Rule::dimensions`メソッドを使い、記述的にこのルールを構築してください。

    use Illuminate\Support\Facades\Validator;
    use Illuminate\Validation\Rule;

    Validator::make($data, [
        'avatar' => [
            'required',
            Rule::dimensions()->maxWidth(1000)->maxHeight(500)->ratio(3 / 2),
        ],
    ]);

<a name="rule-distinct"></a>
#### distinct

配列のバリデーション時、フィールドに重複した値がないことをバリデートします。

    'foo.*.id' => 'distinct'

distinctはデフォルトで緩い比較を使用します。厳密な比較を使用するには、検証ルール定義に`strict`パラメータを追加することができます。

    'foo.*.id' => 'distinct:strict'

バリデーションルールの引数に`ignore_case`を追加して、大文字と小文字の違いを無視するルールを加えられます。

    'foo.*.id' => 'distinct:ignore_case'

<a name="rule-email"></a>
#### email

バリデーション中のフィールドは、電子メールアドレスのフォーマットである必要があります。このバリデーションルールは、[`egulias/email-validator`](https://github.com/egulias/EmailValidator)パッケージを使用して電子メールアドレスをバリデーションします。デフォルトでは`RFCValidation`バリデータが適用されますが、他のバリデーションスタイルを適用することもできます。

    'email' => 'email:rfc,dns'

上記の例では、`RFCValidation`と`DNSCheckValidation`バリデーションを適用しています。適用可能なバリデーションスタイルは、次の通りです。

<div class="content-list" markdown="1">
- `rfc`: `RFCValidation`
- `strict`: `NoRFCWarningsValidation`
- `dns`: `DNSCheckValidation`
- `spoof`: `SpoofCheckValidation`
- `filter`: `FilterEmailValidation`
</div>

PHPの`filter_var`関数を使用する`filter`バリデータは、Laravelに付属しており、Laravelバージョン5.8より前のLaravelのデフォルトの電子メールバリデーション動作でした。

> {note} `dns`および`spoof`バリデータには、PHPの`intl`拡張が必要です。

<a name="rule-ends-with"></a>
#### ends_with:_foo_,_bar_,...

フィールドの値が、指定された値で終わることをバリデートします。

<a name="rule-exclude-if"></a>
#### exclude_if:_他のフィールド_,_値_

**他のフィールド**が**値**と等しい場合、`validate`と`validated`メソッドが返すリクエストデータから、バリデーション指定下のフィールドが除外されます。

<a name="rule-exclude-unless"></a>
#### exclude_unless:_他のフィールド_,_値_

**他のフィールド**が**値**と等しくない場合、`validate`と`validated`メソッドが返すリクエストデータから、バリデーション指定下のフィールドが除外されます。もし**値**が`null`（`exclude_unless:name,null`）の場合は、比較フィールドが`null`であるか、比較フィールドがリクエストデータに含まれていない限り、バリデーション指定下のフィールドは除外されます。

<a name="rule-exists"></a>
#### exists:_テーブル_,_カラム_

フィールドは、指定のデータベーステーブルに存在する必要があります。

<a name="basic-usage-of-exists-rule"></a>
#### 基本的なExistsルールの使用法

    'state' => 'exists:states'

`column`オプションが指定されていない場合、フィールド名が使用されます。したがって、この場合、ルールは、`states`データベーステーブルに、リクエストの`state`属性値と一致する`state`カラム値を持つレコードが含まれていることをバリデーションします。

<a name="specifying-a-custom-column-name"></a>
#### カスタムカラム名の指定

データベーステーブル名の後に配置することで、バリデーションルールで使用するデータベースカラム名を明示的に指定できます。

    'state' => 'exists:states,abbreviation'

場合によっては、`exists`クエリに使用する特定のデータベース接続を指定する必要があります。これは、接続名をテーブル名の前に付けることで実現できます。

    'email' => 'exists:connection.staff,email'

テーブル名を直接指定する代わりに、Eloquentモデルを指定することもできます。

    'user_id' => 'exists:App\Models\User,id'

バリデーションルールで実行されるクエリをカスタマイズしたい場合は、ルールをスラスラと定義できる`Rule`クラスを使ってください。下の例では、`|`文字を区切りとして使用する代わりに、バリデーションルールを配列として指定しています。

    use Illuminate\Support\Facades\Validator;
    use Illuminate\Validation\Rule;

    Validator::make($data, [
        'email' => [
            'required',
                return $query->where('account_id', 1);
                $query->where('account_id', 1);
            }),
        ],
    ]);

<a name="rule-file"></a>
#### file

フィールドがアップロードに成功したファイルであることをバリデートします。

<a name="rule-filled"></a>
#### filled

フィールドが存在する場合、空でないことをバリデートします。

<a name="rule-gt"></a>
#### gt:_field_

フィールドが指定した**フィールド**より大きいことをバリデートします。２つのフィールドは同じタイプでなくてはなりません。文字列、数値、配列、ファイルは、[`size`](#rule-size)ルールと同じ規約により評価します。

<a name="rule-gte"></a>
#### gte:_field_

フィールドが指定した**フィールド**以上であることをバリデートします。２つのフィールドは同じタイプでなくてはなりません。文字列、数値、配列、ファイルは、[`size`](#rule-size)ルールと同じ規約により評価します。

<a name="rule-image"></a>
#### image

ファイルは画像（jpg、jpeg、png、bmp、gif、svg、webp）である必要があります。

<a name="rule-in"></a>
#### in:foo,bar...

フィールドが指定したリストの中の値に含まれていることをバリデートします。このルールを使用するために配列を`implode`する必要が多くなりますので、ルールを記述的に構築するには、`Rule::in`メソッドを使ってください。

    use Illuminate\Support\Facades\Validator;
    use Illuminate\Validation\Rule;

    Validator::make($data, [
        'zones' => [
            'required',
            Rule::in(['first-zone', 'second-zone']),
        ],
    ]);

`in`ルールと`array`ルールを組み合わせた場合、入力配列の各値は、`in`ルールに指定した値のリスト内に存在しなければなりません。次の例では，入力配列中の`LAS`空港コードは，`in`ルールへ指定した空港のリストに含まれていないため無効です。

    use Illuminate\Support\Facades\Validator;
    use Illuminate\Validation\Rule;

    $input = [
        'airports' => ['NYC', 'LAS'],
    ];

    Validator::make($input, [
        'airports' => [
            'required',
            'array',
            Rule::in(['NYC', 'LIT']),
        ],
    ]);

<a name="rule-in-array"></a>
#### in_array:_他のフィールド_.*

フィールドが、**他のフィールド**の値のどれかであることをバリデートします。

<a name="rule-integer"></a>
#### integer

フィールドが整数値であることをバリデートします。

> {note} このバリデーションルールは、入力が「整数」変数タイプであるか確認しません。入力がPHPの`FILTER_VALIDATE_INT`ルールで受け入れられるか検証するだけです。入力を数値として検証する必要がある場合は、このルールを[`numeric`バリデーションルール](#rule-numeric)と組み合わせて使用​​してください。

<a name="rule-ip"></a>
#### ip

フィールドがIPアドレスの形式として正しいことをバリデートします。

<a name="ipv4"></a>
#### ipv4

フィールドがIPv4アドレスの形式として正しいことをバリデートします。

<a name="ipv6"></a>
#### ipv6

フィールドがIPv6アドレスの形式として正しいことをバリデートします。

<a name="rule-json"></a>
#### json

フィールドが有効なJSON文字列であることをバリデートします。

<a name="rule-lt"></a>
#### lt:_field_

フィールドが指定した**フィールド**より小さいことをバリデートします。２つのフィールドは同じタイプでなくてはなりません。文字列、数値、配列、ファイルは、[`size`](#rule-size)ルールと同じ規約により評価します。

<a name="rule-lte"></a>
#### lte:_field_

フィールドが指定した**フィールド**以下であることをバリデートします。２つのフィールドは同じタイプでなくてはなりません。文字列、数値、配列、ファイルは、[`size`](#rule-size)ルールと同じ規約により評価します。

<a name="rule-max"></a>
#### max:_値_

フィールドが最大値として指定された**値**以下であることをバリデートします。[`size`](#rule-size)ルールと同様の判定方法で、文字列、数値、配列、ファイルが評価されます。

<a name="rule-mimetypes"></a>
#### mimetypes:*text/plain*,...

フィールドが指定されたMIMEタイプのどれかであることをバリデートします。

    'video' => 'mimetypes:video/avi,video/mpeg,video/quicktime'

アップロードしたファイルのMIMEタイプを判別するために、ファイルの内容が読み取られ、フレームワークはMIMEタイプを推測します。これは、クライアントが提供するMIMEタイプとは異なる場合があります。

<a name="rule-mimes"></a>
#### mimes:_foo_,_bar_,...

フィールドで指定されたファイルが拡張子のリストの中のMIMEタイプのどれかと一致することをバリデートします。

<a name="basic-usage-of-mime-rule"></a>
#### MIMEルールの基本的な使用法

    'photo' => 'mimes:jpg,bmp,png'

拡張子を指定するだけでもよいのですが、このルールは実際には、ファイルの内容を読み取ってそのMIMEタイプを推測することにより、ファイルのMIMEタイプをバリデーションします。MIMEタイプとそれに対応する拡張子の完全なリストは、次の場所にあります。

[https://svn.apache.org/repos/asf/httpd/httpd/trunk/docs/conf/mime.types](https://svn.apache.org/repos/asf/httpd/httpd/trunk/docs/conf/mime.types)

<a name="rule-min"></a>
#### min:_値_

フィールドが最小値として指定された**値**以上であることをバリデートします。[`size`](#rule-size)ルールと同様の判定方法で、文字列、数値、配列、ファイルが評価されます。

<a name="multiple-of"></a>
#### multiple_of:_値_

フィールドが、**値**の倍数であることをバリデートします。

<a name="rule-not-in"></a>
#### not_in:_foo_,_bar_,...

フィールドが指定された値のリスト中に含まれていないことをバリデートします。`Rule::notIn`メソッドのほうが、ルールの構成が読み書きしやすいでしょう。

    use Illuminate\Validation\Rule;

    Validator::make($data, [
        'toppings' => [
            'required',
            Rule::notIn(['sprinkles', 'cherries']),
        ],
    ]);

<a name="rule-not-regex"></a>
#### not_regex:_正規表現_

フィールドが指定した正規表現と一致しないことをバリデートします。

このルールは内部でPHPの`preg_match`関数を使用しています。パターンは有効なデリミタを使用していることも含め、`preg_match`が求めているフォーマットにしたがって指定する必要があります。たとえば：`'email' => 'not_regex:/^.+$/i'`

> {note} `regex`／`not_regex`パターンを使用するとき、特に正規表現に`|`文字が含まれている場合は、`|`区切り文字を使用する代わりに配列を使用してバリデーションルールを指定する必要があります。

<a name="rule-nullable"></a>
#### nullable

フィールドは`null`であることをバリデートします。

<a name="rule-numeric"></a>
#### numeric

フィールドは[数値](https://www.php.net/manual/en/function.is-numeric.php)であることをバリデートします。

<a name="rule-password"></a>
#### password

フィールドは、認証済みユーザーのパスワードと一致する必要があります。ルールの最初のパラメーターを使用して、[認証ガード](/docs/{{version}}/authentication)を指定できます。

    'password' => 'password:api'

<a name="rule-present"></a>
#### present

フィールドが存在していることをバリデートしますが、存在していれば空を許します。

<a name="rule-prohibited"></a>
#### prohibited

フィールドが空であるか、存在していないことをバリデートします。

<a name="rule-prohibited-if"></a>
#### prohibited_if:_anotherfield_,_value_,...

**anotherfield**フィールドが任意の**value**と等しい場合、対象のフィールドは空であるか、存在しないことをバリデートします。

<a name="rule-prohibited-unless"></a>
#### prohibited_unless:_anotherfield_,_value_,...

**anotherfiel**フィールドが任意の**value**と等しくない場合、対象のフィールドは空であるか、存在していないことをバリデートします。

<a name="rule-regex"></a>
#### regex:_正規表現_

フィールドが指定された正規表現にマッチすることをバリデートします。

このルールは内部でPHPの`preg_match`関数を使用しています。パターンは有効なデリミタを使用していることも含め、`preg_match`が求めているフォーマットにしたがって指定する必要があります。たとえば：`'email' => 'regex:/^.+@.+$/i'`

> {note} `regex`／`not_regex`パターンを使用するとき、特に正規表現に`|`文字が含まれている場合は、`|`区切り文字を使用する代わりに、配列でルールを指定する必要があります。

<a name="rule-required"></a>
#### required

フィールドが入力データに存在しており、かつ空でないことをバリデートします。フィールドは以下の条件の場合、「空」であると判断されます。

<div class="content-list" markdown="1">

- 値が`null`である。
- 値が空文字列である。
- 値が空の配列か、空の`Countable`オブジェクトである。
- 値がパスのないアップロード済みファイルである。

</div>

<a name="rule-required-if"></a>
#### required\_if:_他のフィールド_,_値_,...

**他のフィールド**が**値**のどれかと一致している場合、このフィールドが存在し、かつ空でないことをバリデートします。

`required_if`ルールのより複雑な条件を作成したい場合は、`Rule::requiredIf`メソッドを使用できます。このメソッドは、ブール値またはクロージャを受け入れます。クロージャが渡されると、クロージャは「true」または「false」を返し、バリデーション中のフィールドが必要かどうかを示します。

    use Illuminate\Support\Facades\Validator;
    use Illuminate\Validation\Rule;

    Validator::make($request->all(), [
        'role_id' => Rule::requiredIf($request->user()->is_admin),
    ]);

    Validator::make($request->all(), [
        'role_id' => Rule::requiredIf(function () use ($request) {
            return $request->user()->is_admin;
        }),
    ]);

<a name="rule-required-unless"></a>
#### required\_unless:_他のフィールド_,_値_,...

**他のフィールド**が**値**のどれとも一致していない場合、このフィールドが存在し、かつ空でないことをバリデートします。これは**値**が`null`でない限り、**他のフィールド**はリクエストデータに存在しなければならないという意味でもあります。もし**値**が`null`（`required_unless:name,null`）の場合は、比較フィールドが`null`であるか、リクエストデータに比較フィールドが存在しない限り、バリデーション対象下のフィールドは必須です。

<a name="rule-required-with"></a>
#### required\_with:_foo_,_bar_,...

指定した他のフィールドが**一つでも存在している**場合、このフィールドが存在し、かつ空でないことをバリデートします。

<a name="rule-required-with-all"></a>
#### required\_with_all:_foo_,_bar_,...

指定した他のフィールドが**すべて存在している**場合、このフィールドが存在し、かつ空でないことをバリデートします。

<a name="rule-required-without"></a>
#### required\_without:_foo_,_bar_,...

指定した他のフィールドの**どれか一つでも存在していない**場合、このフィールドが存在し、かつ空でないことをバリデートします。

<a name="rule-required-without-all"></a>
#### required\_without_all:_foo_,_bar_,...

指定した他のフィールドが**すべて存在していない**場合、このフィールドが存在し、かつ空でないことをバリデートします。

<a name="rule-same"></a>
#### same:_フィールド_

フィールドが、指定されたフィールドと同じ値であることをバリデートします。

<a name="rule-size"></a>
#### size:_値_

フィールドは指定された**値**と同じサイズであることをバリデートします。文字列の場合、**値**は文字長です。数値項目の場合、**値**は整数値（属性に`numeric`か`integer`ルールを持っている必要があります）です。配列の場合、**値**は配列の個数(`count`)です。ファイルの場合、**値**はキロバイトのサイズです。

    // 文字列長が１２文字ちょうどであることをバリデートする
    'title' => 'size:12';

    // 指定された整数が１０であることをバリデートする
    'seats' => 'integer|size:10';

    // 配列にちょうど５要素あることをバリデートする
    'tags' => 'array|size:5';

    // アップロードしたファイルが５１２キロバイトぴったりであることをバリデートする
    'image' => 'file|size:512';

<a name="rule-starts-with"></a>
#### starts_with:_foo_,_bar_,...

フィールドが、指定した値のどれかで始まることをバリデートします。

<a name="rule-string"></a>
#### string

フィルードは文字列タイプであることをバリデートします。フィールドが`null`であることも許す場合は、そのフィールドに`nullable`ルールも指定してください。

<a name="rule-timezone"></a>
#### timezone

`timezone_identifiers_list` PHP関数の値に基づき、フィールドがタイムゾーンとして識別されることをバリデートします。

<a name="rule-unique"></a>
#### unique:_テーブル_,_カラム_,_除外ID_,_IDカラム_

フィールドが、指定されたデータベーステーブルに存在しないことをバリデートします。

**カスタムテーブル／カラム名の指定**

テーブル名を直接指定する代わりに、Eloquentモデルを指定することもできます。

    'email' => 'unique:App\Models\User,email_address'

`column`オプションは、フィールドの対応するデータベースカラムを指定するために使用します。`column`オプションが指定されていない場合、バリデーション中のフィールドの名前が使用されます。

    'email' => 'unique:users,email_address'

**カスタムデータベース接続の指定**

場合により、バリデータが行うデータベースクエリのカスタム接続を指定する必要があります。これには、接続名をテーブル名の前に追加します。

    'email' => 'unique:connection.users,email_address'

**指定されたIDのuniqueルールを無視する**

場合により、uniqueのバリデーション中に特定のIDを無視したいことがあります。たとえば、ユーザーの名前、メールアドレス、および場所を含む「プロファイルの更新」画面について考えてみます。メールアドレスが一意であることを確認したいでしょう。しかし、ユーザーが名前フィールドのみを変更し、メールフィールドは変更しない場合、ユーザーは当該電子メールアドレスの所有者であるため、バリデーションエラーが投げられるのは望ましくありません。

バリデータにユーザーIDを無視するように指示するには、ルールをスラスラと定義できる`Rule`クラスを使います。以下の例の場合、さらにルールを`|`文字を区切りとして使用する代わりに、バリデーションルールを配列として指定しています。

    use Illuminate\Support\Facades\Validator;
    use Illuminate\Validation\Rule;

    Validator::make($data, [
        'email' => [
            'required',
            Rule::unique('users')->ignore($user->id),
        ],
    ]);

> {note} ユーザーがコントロールするリクエストの入力を`ignore`メソッドへ、決して渡してはいけません。代わりに、Eloquentモデルインスタンスの自動増分IDやUUIDのような、生成されたユニークなIDだけを渡してください。そうしなければ、アプリケーションがSQLインジェクション攻撃に対し、脆弱になります。

モデルキーの値を`ignore`メソッドに渡す代わりに、モデルインスタンス全体を渡すこともできます。Laravelはモデルからキーを自動的に抽出します:

    Rule::unique('users')->ignore($user)

もし、テーブルの主キーとして`id`以外のカラム名を使用している場合は、`ignore`メソッドを呼び出す時に、カラムの名前を指定してください。

    Rule::unique('users')->ignore($user->id, 'user_id')

`unique`ルールはデフォルトで、バリデートしようとしている属性名と一致するカラムの同一性をチェックします。しかしながら、`unique`メソッドの第２引数として、異なったカラム名を渡すことも可能です。

    Rule::unique('users', 'email_address')->ignore($user->id),

**追加のWHERE節を付け加える**

`where`メソッドを使用してクエリをカスタマイズすることにより、追加のクエリ条件を指定できます。たとえば、`account_id`列の値が`1`の検索レコードのみ検索するクエリ条件で絞り込むクエリを追加してみます。

    'email' => Rule::unique('users')->where(function ($query) {
        return $query->where('account_id', 1);
    })

<a name="rule-url"></a>
#### url

フィールドが有効なURLであることをバリデートします。

<a name="rule-uuid"></a>
#### uuid

フィールドが有効な、RFC 4122（バージョン1、3、4、5）universally unique identifier (UUID)であることをバリデートします。

<a name="conditionally-adding-rules"></a>
## 条件付きでルールを追加する

<a name="skipping-validation-when-fields-have-certain-values"></a>
#### フィールドが特定値を持つ場合にバリデーションを飛ばす

他のフィールドに指定値が入力されている場合は、バリデーションを飛ばしたい状況がときどき起きるでしょう。`exclude_if`バリデーションルールを使ってください。`appointment_date`と`doctor_name`フィールドは、`has_appointment`フィールドが`false`値の場合バリデートされません。

    use Illuminate\Support\Facades\Validator;

    $validator = Validator::make($data, [
        'has_appointment' => 'required|boolean',
        'appointment_date' => 'exclude_if:has_appointment,false|required|date',
        'doctor_name' => 'exclude_if:has_appointment,false|required|string',
    ]);

もしくは逆に`exclude_unless`ルールを使い、他のフィールドに指定値が入力されていない場合は、バリデーションを行わないことも可能です。

    $validator = Validator::make($data, [
        'has_appointment' => 'required|boolean',
        'appointment_date' => 'exclude_unless:has_appointment,true|required|date',
        'doctor_name' => 'exclude_unless:has_appointment,true|required|string',
    ]);

<a name="validating-when-present"></a>
#### 項目存在時のバリデーション

状況によっては、フィールドがバリデーション対象のデータに存在する場合にのみ、フィールドに対してバリデーションチェックを実行したい場合があります。これをすばやく実行するには、`sometimes`ルールをルールリストに追加します。

    $v = Validator::make($request->all(), [
        'email' => 'sometimes|required|email',
    ]);

上の例では`email`フィールドが、`$data`配列の中に存在している場合のみバリデーションが実行されます。

> {tip} フィールドが常に存在しているが、空であることをバリデートする場合は、[この追加フィールドに対する注意事項](#a-note-on-optional-fields)を確認してください。

<a name="complex-conditional-validation"></a>
#### 複雑な条件のバリデーション

ときどきもっと複雑な条件のロジックによりバリデーションルールを追加したい場合もあります。たとえば他のフィールドが１００より大きい場合のみ、指定したフィールドが入力されているかをバリデートしたいときなどです。もしくは２つのフィールドのどちらか一方が存在する場合は、両方共に値を指定する必要がある場合です。こうしたルールを付け加えるのも面倒ではありません。最初に`Validator`インスタンスを生成するのは、**固定ルール**の場合と同じです。

    use Illuminate\Support\Facades\Validator;

    $validator = Validator::make($request->all(), [
        'email' => 'required|email',
        'games' => 'required|numeric',
    ]);

私たちのWebアプリケーションがゲームコレクター向けであると仮定しましょう。ゲームコレクターがアプリケーションに登録し、100を超えるゲームを所有している場合は、なぜこれほど多くのゲームを所有しているのかを説明してもらいます。たとえば、ゲームの再販店を経営している場合や、ゲームの収集を楽しんでいる場合などです。この要件を条件付きで追加するには、`Validator`インスタンスで`sometimes`メソッドを使用できます。

    $v->sometimes('reason', 'required|max:500', function ($input) {
        return $input->games >= 100;
    });

`sometimes`メソッドに渡される最初の引数は、条件付きでバリデーションするフィールドの名前です。２番目の引数は、追加するルールのリストです。３番目の引数として渡すクロージャが`true`を返す場合、ルールが追加されます。この方法で、複雑な条件付きバリデーションを簡単に作成できます。複数のフィールドに条件付きバリデーションを一度に追加することもできます。

    $v->sometimes(['reason', 'cost'], 'required', function ($input) {
        return $input->games >= 100;
    });

> {tip} クロージャに渡される`$input`パラメーターは、`Illuminate\Support\Fluent`のインスタンスであり、バリデーション中の入力とファイルへアクセスするために使用できます。

<a name="validating-arrays"></a>
## 配列のバリデーション

フォーム入力フィールドの配列をバリデーションするのに苦労する必要はありません。配列中の属性をバリデーションするために「ドット記法」が使えます。たとえば、送信されたHTTPリクエストに、`photos[profile]`フィールドが含まれているかをバリデーションするには、次のように行います。

    use Illuminate\Support\Facades\Validator;

    $validator = Validator::make($request->all(), [
        'photos.profile' => 'required|image',
    ]);

配列の各要素をバリデーションすることもできます。たとえば、特定の配列入力フィールドの各メールが一意であることをバリデーションするには、次のようにします。

    $validator = Validator::make($request->all(), [
        'person.*.email' => 'email|unique:users',
        'person.*.first_name' => 'required_with:person.*.last_name',
    ]);

同様に、[言語ファイルのカスタムバリデーションメッセージ](#custom-messages-for-specific-attributes)を指定するときに`*`文字を使用すると、配列ベースのフィールドに単一のバリデーションメッセージを簡単に使用できます。

    'custom' => [
        'person.*.email' => [
            'unique' => 'Each person must have a unique email address',
        ]
    ],

<a name="validating-passwords"></a>
## パスワードのバリデーション

パスワードが十分なレベルの複雑さがあることを確認するために、Laravelの`Password`ルールオブジェクトを使用できます。

    use Illuminate\Support\Facades\Validator;
    use Illuminate\Validation\Rules\Password;

    $validator = Validator::make($request->all(), [
        'password' => ['required', 'confirmed', Password::min(8)],
    ]);

`Password`ルールオブジェクトを使用すると、文字・数字・記号を最低１文字必要にしたり、文字種を組み合わせたりのように、パスワードの指定をアプリケーションで使用する複雑さの要件に合うよう簡単にカスタマイズできます。

    // 最低８文字必要
    Password::min(8)

    // 最低１文字の文字が必要
    Password::min(8)->letters()

    // 最低大文字小文字が１文字ずつ必要
    Password::min(8)->mixedCase()

    // 最低一文字の数字が必要
    Password::min(8)->numbers()

    // 最低一文字の記号が必要
    Password::min(8)->symbols()

さらに、`uncompromised`メソッドを使って、公開されているパスワードのデータ漏洩によるパスワード漏洩がないことを確認することもできます。

    Password::min(8)->uncompromised()

内部的には、`Password`ルールオブジェクトは、[k-Anonymity](https://en.wikipedia.org/wiki/K-anonymity)モデルを使用して、ユーザーのプライバシーやセキュリティを犠牲にすることなく、パスワードが[haveibeenpwned.com](https://haveibeenpwned.com)サービスを介してリークされているかを判断します。

デフォルトでは、データリークに少なくとも1回パスワードが表示されている場合は、侵害されたと見なします。`uncompromised`メソッドの最初の引数を使用してこのしきい値をカスタマイズできます。

    // 同一のデータリークにおいて、パスワードの出現回数が3回以下であることを確認
    Password::min(8)->uncompromised(3);

もちろん、上記の例ですべてのメソッドをチェーン化することができます。

    Password::min(8)
        ->letters()
        ->mixedCase()
        ->numbers()
        ->symbols()
        ->uncompromised()

<a name="defining-default-password-rules"></a>
#### デフォルトパスワードルールの定義

パスワードのデフォルトバリデーションルールをアプリケーションの一箇所で指定できると便利でしょう。クロージャを引数に取る`Password::defaults`メソッドを使用すると、これを簡単に実現できます。`defaults`メソッドへ渡すクロージャは、パスワードルールのデフォルト設定を返す必要があります。通常、`defaults`ルールはアプリケーションのサービスプロバイダの1つの`boot`メソッド内で呼び出すべきです。

```php
use Illuminate\Validation\Rules\Password;

/**
 * アプリケーションの全サービスの初期処理
 *
 * @return void
 */
public function boot()
{
    Password::defaults(function () {
        $rule = Password::min(8);

        return $this->app->isProduction()
                    ? $rule->mixedCase()->uncompromised()
                    : $rule;
    });
}
```

そして、バリデーションで特定のパスワードへデフォルトルールを適用したい場合に、引数なしで`defaults`メソッドを呼び出します。

    'password' => ['required', Password::defaults()],

<a name="custom-validation-rules"></a>
## カスタムバリデーションルール

<a name="using-rule-objects"></a>
### ルールオブジェクトの使用

Laravelは有用な数多くのバリデーションルールを提供しています。ただし、独自のものを指定することもできます。カスタムバリデーションルールを登録する１つの方法は、ルールオブジェクトを使用することです。新しいルールオブジェクトを生成するには、`make:rule`Artisanコマンドを使用できます。このコマンドを使用して、文字列が大文字であることを確認するルールを生成してみましょう。Laravelは新しいルールを`app/Rules`ディレクトリに配置します。このディレクトリが存在しない場合、Artisanコマンドを実行してルールを作成すると、Laravelがそのディレクトリを作成します。

    php artisan make:rule Uppercase

ルールを生成したら、動作を定義する準備ができました。ルールオブジェクトは２つのメソッドを含みます。`passes`と`message`です。`passes`メソッドは属性の値と名前を受け取り、その属性値が有効であれば`true`、無効であれば`false`を返します。`message`メソッドは、バリデーション失敗時に使用する、バリデーションエラーメッセージを返します。

    <?php

    namespace App\Rules;

    use Illuminate\Contracts\Validation\Rule;

    class Uppercase implements Rule
    {
        /**
         * バリデーションの成功を判定
         *
         * @param  string  $attribute
         * @param  mixed  $value
         * @return bool
         */
        public function passes($attribute, $value)
        {
            return strtoupper($value) === $value;
        }

        /**
         * バリデーションエラーメッセージの取得
         *
         * @return string
         */
        public function message()
        {
            return 'The :attribute must be uppercase.';
        }
    }

もちろん、翻訳ファイルのエラーメッセージを返したい場合は、`message`メソッドから`trans`ヘルパを呼び出せます。

    /**
     * バリデーションエラーメッセージの取得
     *
     * @return string
     */
    public function message()
    {
        return trans('validation.uppercase');
    }

ルールが定義できたら、他のバリデーションルールと一緒に、ルールオブジェクトのインスタンスをバリデータへ渡し、指定します。

    use App\Rules\Uppercase;

    $request->validate([
        'name' => ['required', 'string', new Uppercase],
    ]);

<a name="using-closures"></a>
### クロージャの使用

アプリケーション全体でカスタムルールの機能が１回だけ必要な場合は、ルールオブジェクトの代わりにクロージャを使用できます。クロージャは、属性の名前、属性の値、およびバリデーションが失敗した場合に呼び出す必要がある`$fail`コールバックを受け取ります。

    use Illuminate\Support\Facades\Validator;

    $validator = Validator::make($request->all(), [
        'title' => [
            'required',
            'max:255',
            function ($attribute, $value, $fail) {
                if ($value === 'foo') {
                    $fail('The '.$attribute.' is invalid.');
                }
            },
        ],
    ]);

<a name="implicit-rules"></a>
### 暗黙のルール

デフォルトでは、バリデーションされる属性が存在しないか、空の文字列が含まれている場合、カスタムルールを含む通常のバリデーションルールは実行されません。たとえば、[`unique`](#rule-unique)ルールは空の文字列に対して実行されません。

    use Illuminate\Support\Facades\Validator;

    $rules = ['name' => 'unique:users,name'];

    $input = ['name' => ''];

    Validator::make($input, $rules)->passes(); // true

属性が空の場合でもカスタムルールを実行するには、ルールは属性が必須であることを意味する必要があります。「暗黙の」ルールを作成するには、`Illuminate\Contracts\Validation\ImplicitRule`インターフェイスを実装します。このインターフェイスは、バリデータの「マーカーインターフェイス」として機能します。したがって、通常の`Rule`インターフェイスで必要なメソッド以外に実装する必要のある追加のメソッドは含まれていません。

> {note} 「暗黙の」ルールは、属性が必要であることを**暗黙的に**します。欠落している属性または空の属性を実際に無効にするかどうかは、あなた次第です。
