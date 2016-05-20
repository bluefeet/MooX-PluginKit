package MooX::PluginKit::Consumer;
$MooX::PluginKit::Consumer::VERSION = '0.01';
=head1 NAME

MooX::PluginKit::Consumer - Declare a class as a consumer of
PluginKit plugins.

=head1 SYNOPSIS

  package My::Class;
  use Moo;
  use MooX::PluginKit::Consumer;
  
  # Optional, defaults to just 'My::Class'.
  plugin_namespace 'My::Class::Plugin';
  
  has_pluggable_object some_object => (
    class => 'Some::Object',
  );
  
  my $object = My::Class->new(
    plugins => [...],
    some_object=>{...},
  );

=head1 DESCRIPTION

This module, when C<use>d, sets the callers base class to the
L<MooX::PluginKit::ConsumerBase> class, applies the
L<MooX::PluginKit::ConsumerRole> role to the caller, and
exports several candy functions (see L</CANDY>) into the
caller.

Some higher-level documentation about how to consume plugins can
be found at L<MooX::PluginKit/CONSUMING PLUGINS>.

=cut

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

=head1 CANDY

=head2 plugin_namespace

  plugin_namespace 'Location::Of::My::Plugins';

When the L<MooX::PluginKit::ConsumerRole/plugins> argument is set
the user may choose to pass relative plugins.  Setting this namespace
changes the default root namespae used to resolve these relative
plugin names to absolute ones.

This defaults to the package name of the class which uses this module.

Read more about this at L<MooX::PluginKit/Relative Plugin Namespace>.

=cut

sub plugin_namespace {
  my ($consumer) = caller();
  local $Carp::Internal{ (__PACKAGE__) } = 1;
  set_consumer_namespace( $consumer, @_ );
  return;
}

=head2 has_pluggable_object

  has_pluggable_object foo_bar => (
    class => 'Foo::Bar',
  );

This function acts like L<Moo/has> but adds a bunch of functionality,
making it easy to cascade the creation of objects which automatically
have applicable plugins applied to them, at run-time.

In the above C<foo_bar> example, the user of your class can then specify
the C<foo_bar> argument as a hashref.  This hashref will be used to
create an object of the C<Foo::Bar> class, but not until after any
applicable plugins set on the consumer class have been applied to it.

This function only support a subset of the arguments that L<Moo/has>
supports.  They are:

  handles
  default
  builder
  required
  weak_ref
  init_arg

Any other arguments will be ignored.

Read more about this at L<MooX::PluginKit/Object Attributes>.

=cut

sub has_pluggable_object {
  my ($attr_name, %args) = @_;
  my $consumer_class = (caller())[0];

  my $has = get_consumer_moo_has( $consumer_class );

  my $object_class = delete $args{class};
  my $isa = InstanceOf[ $object_class ];

  my $init_name = "_init_$attr_name";

  $has->(
    $init_name,
    init_arg => $attr_name,
    is       => 'ro',
    isa      => $isa | HashRef,
    lazy     => 1,
    (
      map { $_ => $args{$_} }
      grep { exists $args{$_} }
      qw( default builder required weak_ref init_arg )
    ),
  );

  my $attr_isa = $isa;
  $attr_isa = $attr_isa | Undef if !$args{required};

  $has->(
    $attr_name,
    init_arg => undef,
    is       => 'lazy',
    isa      => $attr_isa,
    (
      map { $_ => $args{$_} }
      grep { exists $args{$_} }
      qw( handles weak_ref )
    ),
    builder => sub{
      my ($self) = @_;

      my $args = $self->$init_name();
      return $args if ref($args) ne 'HASH';

      return $self->class_new_with_plugins(
        $object_class, $args,
      );
    },
  );

  return;
}

1;
__END__

=head1 AUTHORS AND LICENSE

See L<MooX::PluginKit/AUTHOR> and L<MooX::PluginKit/LICENSE>.

