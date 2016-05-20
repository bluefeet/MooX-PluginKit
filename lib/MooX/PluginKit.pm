package MooX::PluginKit;

# I don't do anything.

1;
__END__

=head1 NAME

MooX::PluginKit - A comprehensive plugin system.

=head1 INTRODUCTION

PluginKit provides a simple interface for creating plugins and
consuming those plugins.

PluginKit is comprised of two main pieces: the plugins, and the
classes which consume the plugins.  A plugin is just a regular
old L<Moo::Role> with some extra (optional) metadata, and the
consumers of plugins are regular old L<Moo> classes.

But, what makes this all interesting and useful is the intersection
of the two primary features provided by this module.

=over

=item *

Plugins are contextual, in that they may choose which classes
they apply to.

=item *

Plugins may include other plugins.

=back

This means that you can make groups of plugins which apply to various
classes in a hierarchy.

=head1 IN THE REAL WORLD

What fun would a fancy idea be if it had no real world applications!

Here's some real-world plugins/things done-right and done-wrong and
how PluginKit could play a role in them.

NOTE: This section is purely the opinion of the author.  If you disagree
or have better examples/wording/ideas, please let him know!

=head2 Catalyst

L<Catalyst> could benefit from this module.  Currently extending the
context class, the request class, and the response class all require
separate directives manually entered in by the end-user of Catalyst.
Its really a lot of mess when a feature is implemented by, for example,
both a request and response plugin.  If you forget one, the whole thing
breaks.  Here's a fake example of how things currently look:

  use Catalyst (
    SomeContextPlugin
  );
  use CatalystX::RoleApplicator;
  __PACKAGE__->apply_request_class_roles(
    SomeRequestPlugin
  );
  __PACKAGE__->apply_response_class_roles(
    SomeResponsePlugin
  );
  # Note, there is also apply_engine_class_roles, apply_dispatcher_class_roles
  # and apply_stats_class_roles.

Oh my!  Let's say we start off by using a PluginKit plugin's ability to
declare which classes they belong to.  Then we could just do this:

  use Catalyst (
    SomeContextPlugin
    SomeRequestPlugin
    SomeResponsePlugin
  );

And then one step further if those three plugins, when used together, comprised
a single feature then we could just:

  use Catalyst (
    SomePlugin
  );

If Catalyst used PluginKit then all the user would have to do is declare that
they use the root plugin and the rest of the plugins would automatically find
their way into the appropriate classes.

=head2 Starch

L<Starch> is the inspiration for this module.  It has a home-grown plugin
system very similar, but inferior, to PluginKit.  Starch has complex plugins
which alter the behavior of various systems (classes) within Starch.  For
a simple example, L<Starch::Plugin::Trace> injects C<around()> modifiers
within 3 different classes at object construction time.  And all a user need
to do is:

  my $starch = Starch->new( plugins=>['::Trace'] );

Without a plugin system to hide away these complexities the user would have
been exposed to implementation details and would leave gaping holes for
humans to make errors.

=head2 Test::WWW::Mechanize::PSGI

Yay!  Fake a web server with L<Test::WWW::Mechanize::PSGI>!  Thats awesome.
But, uh, what if you want the C<::PSGI> but don't need the C<Test::>.  What
if you don't want the C<::Mechanize::> and want just C<LWP::UserAgent::PSGI>?
Wouldn't it be nice if you could just do:

  my $ua = LWP::UserAgent->new( plugins=>['::PSGI', '::Test'] );

PluginKit would make this super simple to support.  Also there is a god awful
number CPAN module subclasses and subclasses of those subclasses on
CPAN.  Its a world of hurt with no flexibility.  It has made me cry a few
times.

=head1 CREATING PLUGINS

=head2 Basics

The most minimal plugin is a L<Moo::Role>:

  package MyApp::Plugin::Foo;
  use Moo::Role;

But if that is all you are doing then you're just using PluginKit as
a tool to apply roles at run-time.  That's cool and all, but PluginKit
can do so much more.

=head2 Bundling

Let's include another plugin in this plugin:

  use MooX::PluginKit::Plugin;
  plugin_includes 'MyApp::Plugin::Foo::Bar';

We could also write that using a relative (to the including plugin)
plugin name:

  plugin_includes '::Bar';

C<plugin_includes> takes a list, so you may include multiple plugins.
Gnarly, we can package together plugins!  Yes, you could get the
same effect with a simple L<Moo/with>, but then you wouldn't get
the contextual nature of PluginKit plugins as described next.

=head2 Contextual

Take everything you learned so far and throw this awesome bomb
at it:

  plugin_applies_to 'MyApp::SomeClass';

Did you hear the mic drop?  Maybe not, so let me explain it for ya.  You
can create groups of plugins (even groups of groups of groups of plugins)
and each plugin, at any level, can declare what kinds of classes it (and its
included plugins) applies to.  This means you can tell your end-user "use
plugin X" and behind the scenes they could potentially be using dozens of
plugins applied dynamically to dozens of classes.  This makes something that is
normally hard and complex for the end-user something that only the plugin
author needs to deal with and can tightly control.

Is it a good idea to write a dozen plugins and apply them to a dozen classes?
Probably not!  Would it be fun to write a dozen plugins and dynamically apply
them to a dozen classes at run time without the user's knowledge?  Heck ya!

Note that when you specify the C<plugin_applies_to> you can provide a package
name, a regex, an array ref of method names (aka duck type), or a custom subroutine
reference.

Read more about implementing plugins at L<MooX::PluginKit::Plugin>.

=head1 CONSUMING PLUGINS

You've got a few options here, but the typical way to consume plugins
involves enabling it on the class people use as the main entry point
to your library.

=head2 Plugins Argument

L<MooX::PluginKit::Consumer>, when C<use>d sets the subclass, applies a role,
and exports some candy functions to make creating a plugin consuming class
simple as pie.

To make your class accept a C<plugins> argument it goes something like this
(well, actually, exactly like this):

  package MyApp;
  use Moo;
  use MooX::PluginKit::Consumer;

This class now supports the C<plugins> argument when calling C<new()>, like
so:

  my $app = MyApp->new( plugins=>[...] );

=head2 Object Attributes

But, there is more!  Your objects often refer to other objects, right?  Those
other objects shouldn't be left out of the plugin goodness, so open up your
arms and hug them in!

  has_pluggable_object foo => (
    class => 'MyApp::Foo',
  );

C<has_pluggable_object> takes many of the same arguments as L<Moo/has>.  When setup like
above, rather than passing an object as the argument you'd pass a hashref which will be
automatically coerced into an object with all relevant plugins applied.  If you'd like
to default the object you can with something like this:

  has_pluggable_object foo => (
    class   => 'MyApp::Foo',
    default => sub{ {} },
  );

See more at L<MooX::PluginKit::Consumer/has_pluggable_object>.

=head2 Relative Plugin Namespace

If your user specifies a plugin starting with C<::> that means the plugin is
relative.  By default it will be relative to your consuming class name, so
if your class is C<MyApp> and the user wants to apply the C<::Foo> plugin then
that will resolve to the C<MyApp::Foo> plugin.  Unlike many things in life, you
can change this:

  plugin_namespace 'MyApp::Plugin';

Now if the user specified C<::Foo> as a plugin it would resolve to
C<MyApp::Plugin::Foo>.

See more at L<MooX::PluginKit::Consumer/plugin_namespace>.

=head2 The Factory

Alternatively you are welcome to use L<MooX::PluginKit::Factory> directly.  It is
a more direct and lower level interface to popping out objects with plugins applied,
so its considered a power-user tool.

=head1 TODO

=head2 Use Coercion

The L<MooX::PluginKit::Consumer/has_pluggable_object> function jumps through a bunch
of hoops due to the fact that L<Moo/coerce> subroutines do not get access to the
instance that the value is being set on.  Due to this we create two accessors, one
which acts as the writer, and the other which acts as the object builder and reader.

This design makes it difficult to support common L<Moo/has> arguments such as
C<predicate> and C<clearer>, etc.  For now the design of C<has_pluggable_object>
has been limited somewhat so that we don't have to come back later and make
backwards-incompatible changes.

=head2 Cleanly Alter Constructor

Its totally funky that L<MooX::PluginKit::Consumer> sets L<MooX::PluginKit::ConsumerBase>
as the base class.  This is only done because when calling new with plugins changes the
class name that new is being called on, which means we need to change the behavior of new
itself to return the object blessed into a different package than it was called with.

The problem is that C<Method::Generator::Constructor>, a part of L<Moo>, throws exceptions
if you try to alter the behavior of new with an C<around()> modifier or somesuch.  So,
to circumvent these exceptions we use a non-Moo parent class with a custom C<new>, but then
L<Moo> gets into this mode where it acts slightly differently because its inheriting from
a non-Moo class.  For example, when inheriting from a non-Moo class in Moo you don't get a
BUILDARGS.  Despite that, BUILDARGS support has been shimmed in, but there may be other
non-Moo Moo issues.

It would be nice to find a fix for this as I expect it might bite someone.

=head2 Document Core Library

The L<MooX::PluginKit::Core> library contains a bunch of functions for low-level interaction
with plugins and consumers.  This API should be formalized with documentation, once it is in
a final state that can be relied on to not change much.  For now, don't use anything in there
directly.

=head1 AUTHOR

Aran Clary Deltac <bluefeetE<64>gmail.com>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

