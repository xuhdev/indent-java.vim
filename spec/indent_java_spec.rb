require 'vimrunner'

vim = Vimrunner.start
vim.add_plugin(File.expand_path('../..', __FILE__), 'indent/java.vim')
vim.command 'set et sw=4 ts=4'

# test indent
def test_indent(vim, file_name, line_num, correct_indent)
  vim.edit File.expand_path("../#{file_name}", __FILE__)
  vim.set('ft', 'java')
  vim.normal "#{line_num}G=="
  expect(vim.echo("indent(#{line_num})")).to eq("#{correct_indent}")
  vim.command "bd!"
end

describe 'indent/java.vim' do
  after(:all) do
    vim.kill
  end

  describe '#Annotation next line' do
    it 'Indent level should be the same if previous line is an annotation line' do
      test_indent(vim, 'annotation.java', 3, 4)
    end
  end

  describe '#Extends line' do
    it 'Indent level of "extends" lines should be &sw more than previous line' do
      test_indent(vim, 'extends.java', 2, 4)
    end
  end

  describe '#Implements line' do
    it 'Indent level of "implements" lines should be &sw more than previous line' do
      test_indent(vim, 'implements.java', 2, 4)
    end
  end
end

# vim: ts=2 sw=2 et
