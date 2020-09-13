# コンソールテスト

- [イントロダクション](#introduction)
- [入出力の期待値](#expecting-input-and-output)

<a name="introduction"></a>
## イントロダクション

LaravelではHTTPテストも簡単に行えますが、さらにユーザー入力を尋ねるコンソールアプリケーションテストに対する、シンプルなAPIも提供しています。

<a name="expecting-input-and-output"></a>
## 入出力の期待値

Laravelで`expectsQuestion`メソッドを使用すれば、コンソールコマンドのユーザー入力を簡単に「モック」できます。さらに、終了コードを`assertExitCode`メソッドで、コンソールコマンドに期待する出力を`expectsOutput`メソッドでそれぞれ指定することもできます。

    Artisan::command('question', function () {
        $name = $this->ask('What is your name?');

        $language = $this->choice('Which language do you program in?', [
            'PHP',
            'Ruby',
            'Python',
        ]);

        $this->line('Your name is '.$name.' and you program in '.$language.'.');
    });

このコマンドを以下のように、`expectsQuestion`、`expectsOutput`、`assertExitCode`メソッドを活用してテストできます。

    /**
     * コンソールコマンドのテスト
     *
     * @return void
     */
    public function testConsoleCommand()
    {
        $this->artisan('question')
             ->expectsQuestion('What is your name?', 'Taylor Otwell')
             ->expectsQuestion('Which language do you program in?', 'PHP')
             ->expectsOutput('Your name is Taylor Otwell and you program in PHP.')
             ->assertExitCode(0);
    }

"yes"／"no"形態の答えを確認したいコマンドを書いている場合は、`expectsConfirmation`メソッドが役に立ちます。

    $this->artisan('module:import')
        ->expectsConfirmation('Do you really wish to run this command?', 'no')
        ->assertExitCode(1);
