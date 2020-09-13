# 貢献ガイド

- [バグレポート](#bug-reports)
- [質問のサポート](#support-questions)
- [コア開発の議論](#core-development-discussion)
- [どのブランチ？](#which-branch)
- [アセットのコンパイル](#compiled-assets)
- [セキュリティ脆弱性](#security-vulnerabilities)
- [コーディングスタイル](#coding-style)
    - [PHPDoc](#phpdoc)
    - [StyleCI](#styleci)
- [行動規範](#code-of-conduct)

<a name="bug-reports"></a>
## バグレポート

より積極的に援助して頂きたいため、Laravelではただのバグレポートでなく、プルリクエストしてくれることを強く推奨しています。「バグレポート」は失敗するテストを含めた、プルリクエストの形式で送ってください。

しかし、バグレポートを提出する場合にはその問題をタイトルに含め、明確に内容を記述してください。できる限り関連する情報や、その問題をデモするコードも含めてください。バグレポートの目的はあなた自身、そして他の人でも、簡単にバグが再現でき修正されるようにすることです。

Remember, bug reports are created in the hope that others with the same problem will be able to collaborate with you on solving it. Do not expect that the bug report will automatically see any activity or that others will jump to fix it. Creating a bug report serves to help yourself and others start on the path of fixing the problem. If you want to chip in, you can help out by fixing [any bugs listed in our issue trackers](https://github.com/issues?q=is%3Aopen+is%3Aissue+label%3Abug+user%3Alaravel+-repo%3Alaravel%2Fnova-issues).

LaravelのソースコードはGitHubで管理され、各Laravelプロジェクトのリポジトリが存在しています。

<div class="content-list" markdown="1">
- [Laravel Application](https://github.com/laravel/laravel)
- [Laravel Art](https://github.com/laravel/art)
- [Laravel Documentation](https://github.com/laravel/docs)
- [Laravel Dusk](https://github.com/laravel/dusk)
- [Laravel Cashier Stripe](https://github.com/laravel/cashier)
- [Laravel Cashier Paddle](https://github.com/laravel/cashier-paddle)
- [Laravel Echo](https://github.com/laravel/echo)
- [Laravel Envoy](https://github.com/laravel/envoy)
- [Laravel Framework](https://github.com/laravel/framework)
- [Laravel Homestead](https://github.com/laravel/homestead)
- [Laravel Homestead Build Scripts](https://github.com/laravel/settler)
- [Laravel Horizon](https://github.com/laravel/horizon)
- [Laravel Passport](https://github.com/laravel/passport)
- [Laravel Sanctum](https://github.com/laravel/sanctum)
- [Laravel Scout](https://github.com/laravel/scout)
- [Laravel Socialite](https://github.com/laravel/socialite)
- [Laravel Telescope](https://github.com/laravel/telescope)
- [Laravel Website](https://github.com/laravel/laravel.com-next)
- [Laravel UI](https://github.com/laravel/ui)
</div>

<a name="support-questions"></a>
## 質問のサポート

LaravelのGitHubイシュートラッカーは、Laravelのヘルプやサポートの提供を目的としていません。代わりに以下のチャンネルを利用してください。

<div class="content-list" markdown="1">
- [GitHub Discussions](https://github.com/laravel/framework/discussions)
- [Laracasts Forums](https://laracasts.com/discuss)
- [Laravel.io Forums](https://laravel.io/forum)
- [StackOverflow](https://stackoverflow.com/questions/tagged/laravel)
- [Discord](https://discordapp.com/invite/KxwQuKb)
- [Larachat](https://larachat.co)
- [IRC](https://webchat.freenode.net/?nick=artisan&channels=%23laravel&prompt=1)
</div>

<a name="core-development-discussion"></a>
## コア開発の議論

新機能や、現存のLaravelの振る舞いについて改善を提言したい場合は、Laravelアイデア[issueボード](https://github.com/laravel/ideas/issues)へおねがいします。新機能を提言する場合は自発的に、それを完動させるのに必要な、コードを最低限でも実装してください。

バグ、新機能、既存機能の実装についてのざっくばらんな議論は、[Laravel Discord server](https://discordapp.com/invite/mPZNm7A)の`#internals`チャンネルで行っています。LaravelのメンテナーであるTaylor Otwellは、通常ウイークエンドの午前８時から５時まで（America/Chicago標準時、UTC-6:00）接続しています。他の時間帯では、ときどき接続しています。

<a name="which-branch"></a>
## どのブランチ？

**すべての**バグフィックスは最新の安定ブランチ、もしくは[現行のLTSブランチ](/docs/{{version}}/releases#support-policy)へ送ってください。次のリリースの中にだけ存在している機能に対する修正でない限り、決してバグフィックスを`master`ブランチに送っては**いけません**。

現在のリリースと**完全な後方コンパティビリティ**を持っている**マイナー**な機能は、最新の安定ブランチへ送ってください。

次のリリースに含めるべき**メジャー**な新機能は、常に`master`ブランチへ送ってください。

もし、あなたの新機能がメジャーなのか、マイナーなのかはっきりしなければ、[Laravel Discord server](https://discordapp.com/invite/mPZNm7A)の`#internals`チャンネルでTaylor Otwellに尋ねてください。

<a name="compiled-assets"></a>
## アセットのコンパイル

`laravel/laravel`リポジトリの`resources/sass`や`resources/js`下のほとんどのファイルのように、コンパイル済みファイルに影響を及ぼすファイルへ変更を行う場合、コンパイル済みファイルをコミットしないでください。大きなファイルサイズであるため、メンテナは実際レビューできません。悪意のあるコードをLaravelへ紛れ込ませる方法を提供してしまいます。これを防御的に防ぐため、すべてのコンパイル済みファイルはLaravelメンテナが生成し、コミットします。

<a name="security-vulnerabilities"></a>
## セキュリティ脆弱性

Laravelにセキュリティー脆弱性を見つけたときは、メールで[Taylor Otwell(taylorotwell@laravel.com)](mailto:taylor@laravel.com)に連絡してください。全セキュリティー脆弱性は、速やかに対応されるでしょう。

<a name="coding-style"></a>
## コーディングスタイル

Laravelは[PSR-2](https://github.com/php-fig/fig-standards/blob/master/accepted/PSR-2-coding-style-guide.md)コーディング規約と[PSR-4](https://github.com/php-fig/fig-standards/blob/master/accepted/PSR-4-autoloader.md)オートローディング規約に準拠しています。

<a name="phpdoc"></a>
### PHPDoc

次に正しいLaravelのドキュメントブロックの例を示します。`@param`属性に続け２スペース、引数タイプ、２スペース、最後に変数名となっていることに注意してください。

    /**
     * Register a binding with the container.
     *
     * @param  string|array  $abstract
     * @param  \Closure|string|null  $concrete
     * @param  bool  $shared
     * @return void
     *
     * @throws \Exception
     */
    public function bind($abstract, $concrete = null, $shared = false)
    {
        //
    }

<a name="styleci"></a>
### StyleCI

コードのスタイルが完璧でなくても心配ありません。プルリクエストがマージされた後で、[StyleCI](https://styleci.io/)が自動的にスタイルを修正し、Laravelリポジトリへマージします。これによりコードスタイルではなく、貢献の内容へ集中できます。

<a name="code-of-conduct"></a>
## 行動規範

Laravelの行動規範はRubyの行動規範を基にしています。行動規範の違反はTaylor Otwell(taylor@laravel.com)へ報告してください。

<div class="content-list" markdown="1">
- 参加者は反対意見に寛容であること。
- 参加者は個人攻撃や個人的な発言の誹謗に陥らぬように言動に気をつけてください。
- 相手の言動を解釈する時、参加者は常に良い意図だと仮定してください。
- 嫌がらせと考えるのがふさわしい振る舞いは、寛容に扱いません。
</div>
