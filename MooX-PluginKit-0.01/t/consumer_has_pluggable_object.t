#!/usr/bin/env perl
use strictures 2;
use Test::More;

{
  package Consumer;
  use Moo;
  use MooX::PluginKit::Consumer;
  has_pluggable_object foo => (
    class => 'Consumer::Foo',
  );
  sub test { 'Consumer' }
}
{
  package Consumer::Foo;
  use Moo;
  sub test { 'Consumer::Foo' }
}
{
  package Consumer::FooPlugin;
  use Moo::Role;
  use MooX::PluginKit::Plugin;
  plugin_applies_to 'Consumer::Foo';
  around test => sub{ my($o,$s)=@_; return('Consumer::FooPlugin', $s->$o()) };
}

my $consumer = Consumer->new( plugins=>['::FooPlugin'], foo=>{} );
my $foo = $consumer->foo();

is_deeply(
  [ $consumer->test() ],
  [qw( Consumer )],
);
is_deeply(
  [ $foo->test() ],
  [qw( Consumer::FooPlugin Consumer::Foo )],
);

done_testing;
