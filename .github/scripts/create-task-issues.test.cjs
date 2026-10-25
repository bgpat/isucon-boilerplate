const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { parseTask, loadTasks, createTaskIssues } = require('./create-task-issues.cjs');
const template = (title, dependencies = [], needs = false) => `---\ntitle: "${title}"\nlabels:\n  - type:task\ndepends_on:${dependencies.length ? '\n' + dependencies.map(d => '  - ' + d).join('\n') : ' []'}\nneeds-user-action: ${needs}\n---\n\n# 目的\n本文\n`;
function fixture(t, files) {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'task-issues-'));
  t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
  for (const [name, text] of Object.entries(files)) fs.writeFileSync(path.join(directory, name), text);
  return directory;
}
test('すべての共通タスクを検証する', () => assert.equal(loadTasks('tasks').length, 33));
test('不正なメタデータ・不明な依存先・循環依存を拒否する', t => {
  assert.throws(() => parseTask('bad.md', '# no metadata'));
  assert.throws(() => parseTask('bad.md', template('task').replace('needs-user-action: false', 'needs-user-action: yes')));
  assert.throws(() => loadTasks(fixture(t, { 'a.md': template('A', ['missing.md']) })), /不明/);
  assert.throws(() => loadTasks(fixture(t, { 'a.md': template('A', ['b.md']), 'b.md': template('B', ['a.md']) })), /循環/);
});
function mock() {
  // More than one API page of unrelated issues; closed tasks must also be found.
  const issues = Array.from({ length: 105 }, (_, i) => ({ id: i + 1, number: i + 1, title: 'unrelated', body: '' }));
  const children = [], edges = new Map(), labels = new Set();
  let failLink = false, writes = 0;
  const create = async params => {
    writes++;
    const issue = { ...params, id: issues.length + 1, number: issues.length + 1, html_url: 'https://example.test/issue' };
    issues.push(issue); return { data: issue };
  };
  const github = {
    rest: { issues: { listForRepo: 'issues', listLabelsForRepo: 'labels', create,
      createLabel: async ({ name }) => { labels.add(name); writes++; } } },
    paginate: async (route, params) => {
      assert.equal(params.per_page, 100);
      if (route === 'issues') { assert.equal(params.state, 'all'); return issues; }
      if (route === 'labels') return [...labels].map(name => ({ name }));
      if (route.endsWith('/sub_issues')) return children;
      return [...(edges.get(params.issue_number) || [])].map(id => ({ id }));
    },
    request: async (route, params) => {
      if (route.endsWith('/sub_issues')) {
        if (failLink) { failLink = false; throw new Error('temporary failure'); }
        children.push({ id: params.sub_issue_id });
      } else {
        const ids = edges.get(params.issue_number) || new Set();
        ids.add(params.issue_id); edges.set(params.issue_number, ids);
      }
      writes++;
    },
  };
  return { github, issues, children, edges, get writes() { return writes; }, failNextLink() { failLink = true; } };
}
test('親・複数依存・確認欄を作成し、再実行で閉じた Issue と本文を保持する', async t => {
  const directory = fixture(t, { 'a.md': template('A'), 'b.md': template('B'), 'c.md': template('C', ['a.md', 'b.md'], true) });
  const m = mock(), args = { github: m.github, context: { repo: { owner: 'owner', repo: 'repo' } }, directory };
  await createTaskIssues(args);
  assert.equal(m.children.length, 3);
  const c = m.issues.find(i => i.title === 'C');
  assert.equal(m.edges.get(c.number).size, 2);
  assert.ok(c.body.includes('## ユーザー確認'));
  assert.ok(c.labels.includes('needs-user-action'));
  c.state = 'closed'; c.body += '\n実施結果';
  const writes = m.writes;
  await createTaskIssues(args);
  assert.equal(m.writes, writes);
  assert.equal(c.state, 'closed'); assert.ok(c.body.endsWith('実施結果'));
});
test('Issue 作成後の関連付け失敗から重複なしで復旧する', async t => {
  const directory = fixture(t, { 'a.md': template('A') });
  const m = mock(), args = { github: m.github, context: { repo: {} }, directory };
  m.failNextLink();
  await assert.rejects(createTaskIssues(args), /temporary/);
  await createTaskIssues(args);
  assert.equal(m.issues.filter(i => i.title === 'A').length, 1);
  assert.equal(m.children.length, 1);
});
test('重複 Issue がある場合は変更前に停止する', async t => {
  const directory = fixture(t, { 'a.md': template('A') });
  const m = mock();
  m.issues.push({ title: 'A', body: '<!-- task-template: a.md -->' }, { title: 'A2', body: '<!-- task-template: a.md -->' });
  await assert.rejects(createTaskIssues({ github: m.github, context: { repo: {} }, directory }), /重複/);
  assert.equal(m.writes, 0);
});
