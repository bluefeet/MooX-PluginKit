package MooX::PluginKit::Factory;

use MooX::PluginKit::Core;
use Types::Standard -types;
use Types::Common::String -types;

use Moo;
use strictures 2;
use namespace::clean;

has plugins => (
  is      => 'ro',
  isa     => ArrayRef[ NonEmptySimpleStr ],
  default => sub{ [] },
);

has resolved_plugins => (
  is       => 'lazy',
  init_arg => undef,
);
sub _build_resolved_plugins {
  my ($self) = @_;

  return [
    map { resolve_plugin( $_, $self->namespace() ) }
    @{ $self->plugins() }
  ];
}

has namespace => (
  is  => 'ro',
  isa => NonEmptySimpleStr,
);

sub build_class {
  my ($self, $base_class) = @_;

  return build_class_with_plugins(
    $base_class,
    @{ $self->resolved_plugins() },
  );
}

sub class_new {
  my $self = shift;
  my $base_class = shift;

  return $self->build_class( $base_class )->new( @_ );
}

1;
