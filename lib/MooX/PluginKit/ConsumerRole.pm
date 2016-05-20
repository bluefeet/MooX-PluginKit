package MooX::PluginKit::ConsumerRole;

use MooX::PluginKit::Core;
use MooX::PluginKit::Factory;
use Types::Standard -types;

use Moo::Role;
use strictures 2;
use namespace::clean;

around BUILDARGS => sub{
  my $orig = shift;
  my $class = shift;
  my $args = $class->$orig( @_ );

  return $args if !exists $args->{plugins};

  my $factory = MooX::PluginKit::Factory->new(
    plugins   => delete( $args->{plugins} ),
    namespace => get_consumer_namespace( $class ),
  );

  $args->{plugin_factory} = $factory;

  return $args;
};

has plugin_factory => (
  is  => 'ro',
  isa => InstanceOf[ 'MooX::PluginKit::Factory' ],
);

sub class_new_with_plugins {
  my $self = shift;
  my $class = shift;

  return $self->plugin_factory->class_new( $class, @_ );
}

1;
