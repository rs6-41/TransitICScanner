module.exports = {
  types: [
    {
      value: '📃',
      name: '📃 ドキュメントの更新',
      title: 'ドキュメントの更新'
    },
    {
      value: '✨',
      name: '✨ 新機能の追加',
      title: '新機能の追加'
    },
    {
      value: '🐛',
      name: '🐛 バグの修正',
      title: 'バグの修正'
    },
    {
      value: '♻️',
      name: '♻️ コードの整理',
      title: 'コードの整理'
    },
    {
      value: '💄',
      name: '💄 UI・デザインの変更',
      title: 'UI・デザインの変更'
    },
    {
      value: '⚡️',
      name: '⚡️ パフォーマンス改善',
      title: 'パフォーマンス改善'
    },
    {
      value: '✅',
      name: '✅ テストの追加・修正',
      title: 'テストの追加・修正'
    }
  ],
  scopes: [],
  allowCustomScopes: true,
  allowBreakingChanges: false,

  allowTicketNumber: true,
  isTicketNumberRequired: true,
  ticketNumberPrefix: '#',
  ticketNumberRegExp: '\\d+',

  messages: {
    type: '変更の種類:',
    ticketNumber: 'Issue番号:',
    scope: 'スコープ:',
    customScope: 'スコープ:',
    subject: 'コミットメッセージ:',
    confirmCommit: 'この内容でコミットしますか?'
  },

  skipQuestions: ['scope', 'body', 'breaking', 'footer'],
  subjectLimit: 100
}