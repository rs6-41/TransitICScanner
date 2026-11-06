'use strict';

const emojiChoices = [
  { name: '📃 Document Update / ドキュメント更新', value: '📃' },
  { name: '✨ New Features / 新機能の追加', value: '✨' },
  { name: '🐛 Bug Fix / バグ修正', value: '🐛' },
  { name: '♻️  Refactoring / コード整理', value: '♻️' },
  { name: '💄 UI/Design changes / UI・デザインの変更', value: '💄' },
  { name: '⚡️ Improve Performance / パフォーマンス改善', value: '⚡️' },
  { name: '✅ Add/Fix Test / テストの追加・修正', value: '✅' }
];

module.exports = {
  prompter(cz, commit) {
    cz.prompt([
      {
        type: 'list',
        name: 'emoji',
        message: 'Changes / 変更内容:',
        choices: emojiChoices
      },
      {
        type: 'input',
        name: 'issue',
        message: 'Issue:',
        validate(value) {
          return /^\d+$/.test(value.trim()) || 'Please enter a numeric Issue number. / Issue番号は数字で入力してください';
        }
      },
      {
        type: 'input',
        name: 'content',
        message: 'Content / 内容:',
        validate(value) {
          return value.trim().length > 0 || 'Enter text. / 内容を入力してください';
        }
      }
    ]).then(({ emoji, issue, content }) => {
      commit(`${emoji} #${issue.trim()} ${content.trim()}`);
    });
  }
};
