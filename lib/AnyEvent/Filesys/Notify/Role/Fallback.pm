package AnyEvent::Filesys::Notify::Role::Fallback;

# ABSTRACT: Fallback method of file watching (check in regular intervals)

use Moose::Role;
use namespace::autoclean;
use AnyEvent;
use Carp;

sub _init {
    my $self = shift;

    $self->_watcher(
        AnyEvent->timer(
            after    => $self->interval,
            interval => $self->interval,
            cb       => sub {
                $self->_process_events();
            } ) ) or croak "Error creating timer: $@";

    return 1;
}

1;

__END__

=pod

=head1 NAME

AnyEvent::Filesys::Notify::Role::Fallback - Fallback method of file watching (check in regular intervals)

=head1 VERSION

version 0.17

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
