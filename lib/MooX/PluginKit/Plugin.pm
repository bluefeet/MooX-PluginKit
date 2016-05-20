package MooX::PluginKit::Plugin;

use MooX::PluginKit::Core;
use Carp qw();
use Exporter qw();

use strictures 2;
use namespace::clean;

our @EXPORT = qw(
  plugin_applies_to
  plugin_includes
);

sub import {
  {
    my $caller = (caller())[0];
    init_plugin( $caller );
  }

  goto &Exporter::import;
}

sub plugin_applies_to {
  my ($plugin) = caller();
  local $Carp::Internal{ (__PACKAGE__) } = 1;
  set_plugin_applies_to( $plugin, @_ );
  return;
}

sub plugin_includes {
  my ($plugin) = caller();
  local $Carp::Internal{ (__PACKAGE__) } = 1;
  set_plugin_includes( $plugin, @_ );
  return;
}

1;
