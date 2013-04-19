# Indent/java.vim

This is the [Vim][] indent script for [Java][]. You could also find this script
at [Vim Online][].

This script has been included in the official Vim distribution since Vim
version 7.3.409.

To install, simply drop `indent/java.vim` to your Vim `runtimepath`, which is
usually `~/.vim` in UNIX-like systems and `$VIM_INSTALLATION_FOLDER\vimfiles`
in Windows.

The tests are built upon [rspec][]. To run the test, first please have [Ruby][]
and [bundler][] installed. Then run `bundle` to install all the files needed
for testing. Finally run `bundle exec rake` to run the test.

[Java]: http://java.com
[Ruby]: http://www.ruby-lang.org
[Vim Online]: http://www.vim.org/scripts/script.php?script_id=3899
[Vim]: http://www.vim.org
[bundler]: http://gembundler.com/
[rspec]: http://rspec.info
