'use strict';

const emojiChoices = [
  { name: '📃 ドキュメントの更新', value: '📃' },
  { name: '✨ 新機能の追加', value: '✨' },
  { name: '🐛 バグの修正', value: '🐛' },
  { name: '♻️ コードの整理', value: '♻️' },
  { name: '💄 UI・デザインの変更', value: '💄' },
  { name: '⚡️ パフォーマンス改善', value: '⚡️' },
  { name: '✅ テストの追加・修正', value: '✅' }
];

module.exports = {
  prompter(cz, commit) {
    cz.prompt([
      {
        type: 'list',
        name: 'emoji',
        message: '変更内容を選択してください',
        choices: emojiChoices
      },
      {
        type: 'input',
        name: 'issue',
        message: 'Issue番号',
        validate(value) {
          return /^\d+$/.test(value.trim()) || 'Issue番号は数字で入力してください';
        }
      },
      {
        type: 'input',
        name: 'content',
        message: '内容',
        validate(value) {
          return value.trim().length > 0 || '内容を入力してください';
        }
      }
    ]).then(({ emoji, issue, content }) => {
      commit(`${emoji} #${issue.trim()} ${content.trim()}`);
    });
  }
};
