require 'vimrunner'

vim = Vimrunner.start
vim.add_plugin(File.expand_path('../../indent/', __FILE__), 'java.vim')
vim.command 'set et sw=4 ts=4'

# test indent
def test_indent(vim, file_name, line_num, correct_indent)
  vim.edit File.expand_path("../#{file_name}", __FILE__)
  vim.set('ft', 'java')
  vim.echo("GetJavaIndent(#{line_num})").should == "#{correct_indent}"
  vim.command "bd!"
end

describe 'indent/java.vim' do
  after(:all) do
    vim.kill
  end

  describe '#Module loaded' do
    it 'The GetJavaIndent function should be defined' do
      vim.echo('exists("*GetJavaIndent")').should == "1"
    end
  end

  describe '#Annotation next line' do
    it 'Indent level should be the same if previous line is an annotation line' do
      test_indent(vim, 'annotation.java', 5, 0)
      test_indent(vim, 'annotation.java', 6, 0)
      test_indent(vim, 'annotation.java', 11, 4)
    end
  end

  describe '#Annotation after comment' do
    it ' Indent level of annotations should not be affected by comments on the previous line' do
      test_indent(vim, 'annotation.java', 4, 0)
      test_indent(vim, 'annotation.java', 10, 4)
    end
  end

  describe '#Class details' do
    it 'Indent level of implements or extends statements should be &sw more than the class definition' do
      test_indent(vim, 'class_details.java', 2, 4)
      test_indent(vim, 'class_details.java', 6, 4)
      test_indent(vim, 'class_details.java', 10, 4)
      test_indent(vim, 'class_details.java', 11, 4)
      test_indent(vim, 'class_details.java', 15, 4)
      test_indent(vim, 'class_details.java', 17, 4)
    end
  end

  describe '#Class details continuation' do
    it 'Indent level of items in multi-line implements or extends should line up with the first item' do
      test_indent(vim, 'class_details.java', 16, 12)
      test_indent(vim, 'class_details.java', 18, 15)
      test_indent(vim, 'class_details.java', 19, 15)
    end
  end

  describe '#Class contents after class details' do
    it 'Indent level of class contents should be &sw greater than the class definition even after class details' do
      test_indent(vim, 'class_details.java', 20, 4)
    end
  end

  describe '#Method details' do
    it 'Method details should be indented &sw greater than the method definition' do
      test_indent(vim, 'method_details.java', 3, 8)
      test_indent(vim, 'method_details.java', 12, 8)
    end
  end

  describe '#Method details list' do
    it 'Method details should line up correctly with the previous detail in the list' do
      test_indent(vim, 'method_details.java', 7, 15)
      test_indent(vim, 'method_details.java', 13, 15)
    end
  end

  describe '#Method details list edge case' do
      it 'Ensuring method details line up even in odd edge cases' do
          test_indent(vim, 'method_detail_edge_case.java', 13, 15)
      end
  end


  describe '#Close braces after class details' do
    it 'Indent level of brackets should match the class definition, not the class details' do
      test_indent(vim, 'brackets.java', 6, 0)
    end
  end

  describe '#Close braces after method details' do
    it 'Indent level of brackets should match the method definition, not the method details' do
      test_indent(vim, 'brackets.java', 5, 4)
    end
  end

  describe '#Block comments' do
    it 'When we are in the middle of block comments, we expect the indent to match with the rightmost *' do
      test_indent(vim, 'comments.java', 1, 0)
      test_indent(vim, 'comments.java', 2, 1)
      test_indent(vim, 'comments.java', 3, 1)
    end
  end

  describe '#Comments after class details' do
    it 'Indent level of comments after class details should have indentation of class definition + &sw' do
      test_indent(vim, 'comments.java', 6, 4)
    end
  end

end

# vim: ts=2 sw=2 et
