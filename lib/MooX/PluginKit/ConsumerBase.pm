package MooX::PluginKit::ConsumerBase;

use Moo::Object qw();

use strictures 2;
use namespace::clean;

sub new {
  my $class = shift;

  my $args = $class->BUILDARGS( @_ );
  my $factory = $args->{plugin_factory};
  $class = $factory->build_class( $class ) if $factory;

  return bless {}, $class;
}

sub BUILDARGS {
  my $class = shift;
  return Moo::Object->BUILDARGS( @_ );
}

1;
