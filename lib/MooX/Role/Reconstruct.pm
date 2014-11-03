package MooX::Role::Reconstruct;

use strict;
use warnings FATAL => 'all';

use 5.006;

our $VERSION = 'v0.1_1';

use Sub::Quote;
use Sub::Defer;
use Moo::Role;

sub import {
    my $target  = shift;
    my %args = @_ ? ( @_ ) : ( method => 'reconstruct' );

    my $method = delete( $args{method} );

    die 'MooX::Role::Reconstruct can only be used on Moo classes.'
      unless $Moo::MAKERS{$target} && $Moo::MAKERS{$target}{is_class};
 
    my $con = Moo->_constructor_maker_for($target);

    Moo::_install_tracked( $target, $method,
    defer_sub( "${target}::${method}" => sub {
        # don't alter the original specs if called before new
        my %spec;
        for ( keys( %{$con->{attribute_specs}} ) ) {
            $spec{$_} = { %{$con->{attribute_specs}{$_}} };
        }
        foreach my $attr ( grep exists( $spec{$_}{init_arg} ), keys(%spec) ) {
            delete( $spec{$attr}{init_arg} ) unless $spec{$attr}{keep_init};
        }

        unquote_sub $con->generate_method(
            $target, $method, \%spec, { no_install => 1 }
        )
    }));

    return;
}

1;

__END__

=head1 NAME

MooX::Role::Reconstruct - Reconstruct Moo Objects

=head1 SYNOPSIS

  
 # use default method name: reconstruct
 use Moo;
 with qw( MooX::Role::Reconstruct );
  

=head1 DESCRIPTION

It is often desirable to create an object from a database row or a decoded
JSON object. However, it is quite likely that you might have declared some
attributes with C<init_arg => undef> so simply calling
C<<class->new( %hash )>> will fail.

This module makes it possible by providing a constructor that will ignore
all C<init_arg> directives. This behavior can be disabled on a case-by-case
basis by specifying C<keep_init => 1> in the C<has> structure for a given
attribute as shown below:

  
 has foo => (
    is => 'ro',
    default => 'bar',
    init_arg => 'baz',
    keep_init => 1,
 );
  

This presumes that one has written sensible C<coerce> and C<isa> conditions.

=head1 METHODS INSTALLED

=head2 reconstruct

The module installs a method named C<reconstruct> by default. This can be
changed by supplying the C<method> option as shown in the synopsis.

Note: Any naming conflicts will show up as a C<Subroutine redefined> error.

=head1 ERROR CONDITIONS

This module require that L<Moo> be loaded prior to use. The module will
C<die> otherwise.

Passing in the name of a method that already exists in your code as the
name of the reconstructor will result in a C<Subroutine redfined> error.

=head1 SEE ALSO

=head1 AUTHOR

Jim Bacon E<lt>jim@nortx.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Jim Bacon

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.16 or,
at your option, any later version of Perl 5 you may have available.

=cut
