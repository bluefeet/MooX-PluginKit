package MooX::PluginKit::ConsumerBase;
$MooX::PluginKit::ConsumerBase::VERSION = '0.01';
=head1 NAME

MooX::PluginKit::ConsumerBase - Parent class for PluginKit consumers.

=head2 DESCRIPTION

This module is a total hack to get around
L<MooX::PluginKit/Cleanly Alter Constructor>.

=cut

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
__END__

=head1 AUTHORS AND LICENSE

See L<MooX::PluginKit/AUTHOR> and L<MooX::PluginKit/LICENSE>.

