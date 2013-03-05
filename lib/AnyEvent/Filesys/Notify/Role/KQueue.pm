package AnyEvent::Filesys::Notify::Role::KQueue;

# ABSTRACT: Use IO::KQueue to watch for changed files

use Moose::Role;
use namespace::autoclean;
use AnyEvent;
use IO::KQueue;
use Carp;

# Arbitrary limit on open filehandles before issuing a warning
our $WARN_FILEHANDLE_LIMIT = 50;

sub _init {
    my $self = shift;

    my $kqueue = IO::KQueue->new()
      or croak "Unable to create new IO::KQueue object";
    $self->_fs_monitor($kqueue);

    # Need to add all the subdirs to the watch list, this will catch
    # modifications to files too.
    my $old_fs = $self->_old_fs;
    my @paths  = keys %$old_fs;

    # Add each file and each directory
    my @fhs;
    for my $path (@paths) {
        push @fhs, $self->_watch($path);
    }

    # Now use AE to watch the KQueue
    my $w;
    $w = AE::io $$kqueue, 0, sub {
        if ( my @events = $kqueue->kevent ) {
            $self->_process_events(@events);
        }
    };
    $self->_watcher( { fhs => \@fhs, w => $w } );

    $self->_check_filehandle_count;
    return 1;
}

# Need to add newly created items (directories and files).
# This is done after filtering. So entire dirs can be ignored efficiently.
around '_process_events' => sub {
    my ( $orig, $self, @e ) = @_;

    my $events = $self->$orig(@e);

    for my $event (@$events) {
        next unless $event->is_created;

        my $fh = $self->_watch( $event->path );
        push @{ $self->_watcher->{fhs} }, $fh;

    }

    $self->_check_filehandle_count;
    return $events;
};

sub _watch {
    my ( $self, $path ) = @_;

    open my $fh, '<', $path or do {
        warn
          "KQueue requires a filehandle for each watched file and directory.\n"
          . "You have exceeded the number of filehandles permitted by the OS.\n"
          if $! =~ /^Too many open files/;
        croak "Can't open file ($path): $!";
    };

    $self->_fs_monitor->EV_SET(
        fileno($fh),
        EVFILT_VNODE,
        EV_ADD | EV_ENABLE | EV_CLEAR,
        NOTE_DELETE | NOTE_WRITE | NOTE_EXTEND | NOTE_ATTRIB | NOTE_LINK |
          NOTE_RENAME | NOTE_REVOKE,
    );

    return $fh;
}

sub _check_filehandle_count {
    my ($self) = @_;

    my $count = $self->_watcher_count;
    carp "KQueue requires a filehandle for each watched file and directory.\n"
      . "You currently have $count filehandles for this AnyEvent::Filesys::Notify object.\n"
      . "The use of the KQueue backend is not recommended."
      if $count > $WARN_FILEHANDLE_LIMIT;
}

sub _watcher_count {
    my ($self) = @_;
    my $fhs = $self->_watcher->{fhs};
    return scalar @$fhs;
}

1;

__END__

=pod

=head1 NAME

AnyEvent::Filesys::Notify::Role::KQueue - Use IO::KQueue to watch for changed files

=head1 VERSION

version 0.22

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
