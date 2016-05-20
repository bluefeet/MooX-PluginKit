package MooX::PluginKit::Consumer;

use MooX::PluginKit::Core;
use MooX::PluginKit::ConsumerRole;
use Types::Standard -types;
use Scalar::Util qw( blessed );
use Carp qw( croak );
use Exporter qw();

use strictures 2;
use namespace::clean;

our @EXPORT = qw(
  plugin_namespace
  has_pluggable_object
);

sub import {
  {
    my $caller = (caller())[0];
    init_consumer( $caller );
    get_consumer_moo_extends( $caller )->('MooX::PluginKit::ConsumerBase');
    get_consumer_moo_with( $caller )->('MooX::PluginKit::ConsumerRole');
  }

  goto &Exporter::import;
}

sub plugin_namespace {
  my ($consumer) = caller();
  local $Carp::Internal{ (__PACKAGE__) } = 1;
  set_consumer_namespace( $consumer, @_ );
  return;
}

sub has_pluggable_object {
  my ($name, %args) = @_;
  my $consumer_class = (caller())[0];

  my $has = get_consumer_moo_has( $consumer_class );

  my $object_class = delete $args{class};
  my $required     = delete $args{required};

  my $original_name = "_original_$name";

  $has->(
    $original_name,
    is       => 'ro',
    isa      => InstanceOf[ $object_class ] | HashRef,
    init_arg => $name,
    $required ? (required=>1) : (),
    %args,
  );

  my $final_type = InstanceOf[ $object_class ];
  $final_type = $final_type | Undef if !$required;

  $has->(
    $name,
    is       => 'lazy',
    isa      => InstanceOf[ $object_class ] | Undef,
    init_arg => undef,
    builder => sub{
      my ($self) = @_;
      my $original = $self->$original_name();
      return $original if ref($original) ne 'HASH';
      return $self->class_new_with_plugins(
        $object_class, $original,
      );
    },
  );

  return;
}

1;
