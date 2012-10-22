package AnyEvent::Filesys::Notify::Role::Linux;

# ABSTRACT: Use Linux::Inotify2 to watch for changed files

use Moose::Role;
use namespace::autoclean;
use AnyEvent;
use Linux::Inotify2;
use Carp;

# use Scalar::Util qw(weaken);  # Attempt to address RT#57104, but alas...

sub _init {
    my $self = shift;

    my $inotify = Linux::Inotify2->new()
      or croak "Unable to create new Linux::Inotify2 object";

    # Need to add all the subdirs to the watch list, this will catch
    # modifications to files too.
    my $old_fs = $self->_old_fs;
    my @dirs = grep { $old_fs->{$_}->{is_dir} } keys %$old_fs;

    # weaken $self; # Attempt to address RT#57104, but alas...

    for my $dir (@dirs) {
        $inotify->watch(
            $dir,
            IN_MODIFY | IN_CREATE | IN_DELETE | IN_DELETE_SELF |
              IN_MOVE | IN_MOVE_SELF | IN_ATTRIB,
            sub { my $e = shift; $self->_process_events($e); } );
    }

    $self->_fs_monitor($inotify);

    $self->_watcher(
        AnyEvent->io(
            fh   => $inotify->fileno,
            poll => 'r',
            cb   => sub {
                $inotify->poll;
            } ) );

    return 1;
}

# Need to add newly created sub-dirs to the watch list.
# This is done after filtering. So entire dirs can be ignored efficiently;
around '_process_events' => sub {
    my ( $orig, $self, @e ) = @_;

    my $events = $self->$orig(@e);

    for my $event (@$events) {
        next unless $event->is_dir && $event->is_created;

        $self->_fs_monitor->watch(
            $event->path,
            IN_MODIFY | IN_CREATE | IN_DELETE | IN_DELETE_SELF |
                IN_MOVE | IN_MOVE_SELF | IN_ATTRIB,
            sub { my $e = shift; $self->_process_events($e); } );

    }

    return $events;
};

1;

__END__

=pod

=head1 NAME

AnyEvent::Filesys::Notify::Role::Linux - Use Linux::Inotify2 to watch for changed files

=head1 VERSION

version 0.09

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
