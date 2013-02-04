package AnyEvent::Filesys::Notify::Role::KQueue;

# ABSTRACT: Use IO::KQueue to watch for changed files

use Moose::Role;
use namespace::autoclean;
use AnyEvent;
use IO::KQueue;
use Carp;

sub _init {
    my $self = shift;

    my $kqueue = IO::KQueue->new()
      or croak "Unable to create new IO::KQueue object";

    my @fhs = map {
        open my $fh, '<', $_ or croak "Can't open file: $_";

        $kqueue->EV_SET(
            fileno($fh),
            EVFILT_VNODE,
            EV_ADD | EV_ENABLE,
            NOTE_DELETE | NOTE_WRITE | NOTE_EXTEND | NOTE_ATTRIB |
            NOTE_LINK | NOTE_RENAME | NOTE_REVOKE,
        );
        $fh;
    } @{ $self->dirs };

    my $w;
    $w = AE::io $$kqueue, 0, sub {
        if ( my @events = $kqueue->kevent ) {
            $self->_process_events(@events);
        }
    };

    $self->_fs_monitor($kqueue);

    $self->_watcher( { fhs => \@fhs, w => $w } );

    return 1;
}

1;

__END__

=pod

=head1 NAME

AnyEvent::Filesys::Notify::Role::KQueue - Use IO::KQueue to watch for changed files

=head1 VERSION

version 0.21

=head1 CONTRIBUTORS

Thanks to Gasol Wu E<lt>gasol.wu@gmail.comE<gt> who contributed the FreeBSD
support for IO::KQueue.

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
