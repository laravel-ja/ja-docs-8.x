# コンソールテスト

- [イントロダクション](#introduction)
- [入力/出力の期待値](#input-output-expectations)

<a name="introduction"></a>
## イントロダクション

Laravelは、HTTPテストを簡素化することに加え、アプリケーションの[カスタムコンソールコマンド](/docs/{{version}}/artisan)をテストするためのシンプルなAPIも提供します。

<a name="input-output-expectations"></a>
## 入力/出力の期待値

Laravelで`expectsQuestion`メソッドを使用すれば、コンソールコマンドのユーザー入力を簡単に「モック」できます。さらに、終了コードを`assertExitCode`メソッドで、コンソールコマンドに期待する出力を`expectsOutput`メソッドでそれぞれ指定することもできます。

    Artisan::command('question', function () {
        $name = $this->ask('What is your name?');

        $language = $this->choice('Which language do you prefer?', [
            'PHP',
            'Ruby',
            'Python',
        ]);

        $this->line('Your name is '.$name.' and you prefer '.$language.'.');
    });

このコマンドは、`expectsQuestion`、`expectsOutput`、`doesntExpectOutput`、`assertExitCode`メソッドを利用する以下の例でテストできます。

    /**
     * Test a console command.
     *
     * @return void
     */
    public function testConsoleCommand()
    {
        $this->artisan('question')
             ->expectsQuestion('What is your name?', 'Taylor Otwell')
             ->expectsQuestion('Which language do you prefer?', 'PHP')
             ->expectsOutput('Your name is Taylor Otwell and you prefer PHP.')
             ->doesntExpectOutput('Your name is Taylor Otwell and you prefer Ruby.')
             ->assertExitCode(0);
    }

<a name="confirmation-expectations"></a>
#### 確認の期待

「はい」または「いいえ」の回答の形式で確認を期待するコマンドを作成する場合は、`expectsConfirmation`メソッドを使用できます。

    $this->artisan('module:import')
        ->expectsConfirmation('Do you really wish to run this command?', 'no')
        ->assertExitCode(1);

<a name="table-expectations"></a>
#### テーブルの期待

コマンドがArtisanの`table`メソッドを使用して情報のテーブルを表示する場合、テーブル全体の出力期待値を書き込むのは面倒な場合があります。代わりに、`expectsTable`メソッドを使用できます。このメソッドは、テーブルのヘッダを最初の引数として受け入れ、テーブルのデータを２番目の引数として受け入れます。

    $this->artisan('users:all')
        ->expectsTable([
            'ID',
            'Email',
        ], [
            [1, 'taylor@example.com'],
            [2, 'abigail@example.com'],
        ]);
