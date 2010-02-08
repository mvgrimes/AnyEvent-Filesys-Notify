package AnyEvent::Filesys::Notify;

use Moose;
use Moose::Util qw(apply_all_roles);
use namespace::autoclean;
use AnyEvent;
use File::Find::Rule;
use Cwd qw/abs_path/;
use AnyEvent::Filesys::Notify::Event;
use Carp;
use Try::Tiny;

our $VERSION = '0.05';

has dirs        => ( is => 'ro', isa => 'ArrayRef[Str]', required => 1 );
has cb          => ( is => 'rw', isa => 'CodeRef',       required => 1 );
has interval    => ( is => 'ro', isa => 'Num',           default  => 2 );
has no_external => ( is => 'ro', isa => 'Bool',          default  => 0 );
has filter      => ( is => 'rw', isa => 'RegexpRef|CodeRef' );
has _fs_monitor => ( is => 'rw', );
has _old_fs => ( is => 'rw', isa => 'HashRef' );
has _watcher => ( is => 'rw', );

sub BUILD {
    my $self = shift;

    $self->_old_fs( _scan_fs( $self->dirs ) );

    $self->_load_backend;
    return $self->_init;    # initialize the backend
}

sub _process_events {
    my ( $self, @raw_events ) = @_;

    # We are just ingoring the raw events for now... Mac::FSEvents
    # doesn't provide much information, so rescan ourselves

    my $new_fs = _scan_fs( $self->dirs );
    my @events = $self->_apply_filter( _diff_fs( $self->_old_fs, $new_fs ) );

    $self->_old_fs($new_fs);
    $self->cb->(@events) if @events;

    return \@events;
}

sub _apply_filter {
    my ( $self, @events ) = @_;

    if ( ref $self->filter eq 'CODE' ) {
        my $cb = $self->filter;
        @events = grep { $cb->( $_->path ) } @events;
    } elsif ( ref $self->filter eq 'Regexp' ) {
        my $re = $self->filter;
        @events = grep { $_->path =~ $re } @events;
    }

    return @events;
}

# Return a hash ref representing all the files and stats in @path.
# Keys are absolute path and values are path/mtime/size/is_dir
# Takes either array or arrayref
sub _scan_fs {
    my (@args) = @_;

    # Accept either an array of dirs or a array ref of dirs
    my @paths = ref $args[0] eq 'ARRAY' ? @{ $args[0] } : @args;

    # Separated into two lines to avoid stat on files multiple times.
    my %files = map { $_ => 1 } File::Find::Rule->in(@paths);
    %files = map { abs_path($_) => _stat($_) } keys %files;

    return \%files;
}

sub _diff_fs {
    my ( $old_fs, $new_fs ) = @_;
    my @events = ();

    for my $path ( keys %$old_fs ) {
        if ( not exists $new_fs->{$path} ) {
            push @events,
              AnyEvent::Filesys::Notify::Event->new(
                path   => $path,
                type   => 'deleted',
                is_dir => $old_fs->{$path}->{is_dir},
              );
        } elsif ( _is_path_modified( $old_fs->{$path}, $new_fs->{$path} ) ) {
            push @events,
              AnyEvent::Filesys::Notify::Event->new(
                path   => $path,
                type   => 'modified',
                is_dir => $old_fs->{$path}->{is_dir},
              );
        }
    }

    for my $path ( keys %$new_fs ) {
        if ( not exists $old_fs->{$path} ) {
            push @events,
              AnyEvent::Filesys::Notify::Event->new(
                path   => $path,
                type   => 'created',
                is_dir => $new_fs->{$path}->{is_dir},
              );
        }
    }

    return @events;
}

sub _is_path_modified {
    my ( $old_path, $new_path ) = @_;

    return   if $new_path->{is_dir};
    return 1 if $new_path->{mtime} != $old_path->{mtime};
    return 1 if $new_path->{size} != $old_path->{size};
    return;
}

# Taken from Filesys::Notify::Simple --Thanks Miyagawa
sub _stat {
    my $path = shift;

    my @stat = stat $path;
    return {
        path   => $path,
        mtime  => $stat[9],
        size   => $stat[7],
        is_dir => -d _,
    };

}

# Figure out which backend to use:
# I would prefer this to be done at compile time not object build, but I also
# want the user to be able to force the Fallback role. Something like an
# import flag would be great, but Moose creates an import sub for us and
# I'm not sure how to cleanly do it. Maybe need to use traits, but the
# documentation suggests traits are for application of roles by object.
# This will work for now.
sub _load_backend {
    my $self = shift;

    if ( $self->no_external ) {
        apply_all_roles( $self, 'AnyEvent::Filesys::Notify::Role::Fallback' );
    } elsif ( $^O eq 'linux' ) {
        try {
            apply_all_roles( $self, 'AnyEvent::Filesys::Notify::Role::Linux' );
        }
        catch {
            croak "Unable to load the Linux plugin. You may want to install "
              . "Linux::INotify2 or specify 'no_external' (but that is very "
              . "inefficient):\n$_";
        }
    } elsif ( $^O eq 'darwin' ) {
        try {
            apply_all_roles( $self, 'AnyEvent::Filesys::Notify::Role::Mac' );
        }
        catch {
            croak "Unable to load the Mac plugin. You may want to install "
              . "Mac::FSEvents or specify 'no_external' (but that is very "
              . "inefficient):\n$_";
        }
    } else {
        apply_all_roles( $self, 'AnyEvent::Filesys::Notify::Role::Fallback' );
    }

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

AnyEvent::Filesys::Notify - An AnyEvent compatible module to monitor files/directories for changes

=head1 SYNOPSIS

    use AnyEvent::Filesys::Notify;

    my $notifier = AnyEvent::Filesys::Notify->new(
        dirs     => [ qw( this_dir that_dir ) ],
        interval => 2.0,             # Optional depending on underlying watcher
        filter   => sub { shift !~ /\.(swp|tmp)$/ },
        cb       => sub {
            my (@events) = @_;
            # ... process @events ...
        },
    );

    # enter an event loop, see AnyEvent documentation
    Event::loop();

=head1 DESCRIPTION

This module provides a cross platform interface to monitor files and
directories within an L<AnyEvent> event loop. The heavy lifting is done by
L<Linux::INotify2> or L<Mac::FSEvents> on their respective O/S. A fallback
which scans the directories at regular intervals is include for other systems.
See L</IMPLEMENTATIONS> for more on the backends.

Events are passed to the callback (specified as a CodeRef to C<cb> in the
constructor) in the form of L<AnyEvent::Filesys::Notify::Event>s.

=head1 METHODS

=head2 new()

A constructor for a new AnyEvent watcher that will monitor the files in the
given directories and execute a callback when a modification is detected. 
No action is take until a event loop is entered.

Arguments for new are:

=over 4

=item dirs 

    dirs => [ '/var/log', '/etc' ],

An ArrayRef of directories to watch. Required.

=item interval

    interval => 1.5,   # seconds

Specifies the time in fractional seconds between file system checks for
the L<AnyEvent::Filesys::Notify::Role::Fallback> implementation.

Specifies the latency for L<Mac::FSEvents> for the
C<AnyEvent::Filesys::Notify::Role::Mac> implementation.

Ignored for the C<AnyEvent::Filesys::Notify::Role::Linux> implementation.

=item filter

    filter => qr/\.(ya?ml|co?nf|jso?n)$/,
    filter => sub { shift !~ /\.(swp|tmp)$/,

A CodeRef or Regexp which is used to filter wanted/unwanted events. If this
is a Regexp, we attempt to match the absolute path name and filter out any
that do not match. If a CodeRef, the absolute path name is passed as the
only argument and the event is fired only if there sub returns a true value.

=item cb

    cb  => sub { my @events = @_; ... },

A CodeRef that is called when a modification to the monitored directory(ies) is
detected. The callback is passed a list of
L<AnyEvent::Filesys::Notify::Event>s. Required.

=item no_external

    no_external => 1,

Force the use of the L</Fallback> watcher implementation. This is not
encouraged as the L</Fallback> implement is very inefficient, but it 
does not require either L<Linux::INotify2> nor L<Mac::FSEvents>. Optional.

=back

=head1 WATCHER IMPLEMENTATIONS

=head2 Linux

Uses L<Linux::INotify2> to monitor directories. Sets up an C<AnyEvent-E<gt>io>
watcher to monitor the C<$inotify-E<gt>fileno> filehandle.

=head2 Mac

Uses L<Mac::FSEvents> to monitor directories. Sets up an C<AnyEvent-E<gt>io>
watcher to monitor the C<$fsevent-E<gt>watch> filehandle.

=head2 Fallback

A simple scan of the watched directories at regular intervals. Sets up an
C<AnyEvent-E<gt>timer> watcher which is executed every C<interval> seconds
(or fractions thereof). C<interval> can be specified in the constructor to
L<AnyEvent::Filesys::Notify> and defaults to 2.0 seconds.

This is a very inefficient implementation. Use one of the others if possible.

=head1 Why Another Module For File System Notifications

At the time of writing there were several very nice modules that accomplish
the task of watching files or directories and providing notifications about
changes. Two of which offer a unified interface that work on any system:
L<Filesys::Notify::Simple> and L<File::ChangeNotify>.

L<AnyEvent::Filesys::Notify> exists because I need a way to simply tie the
functionality those modules provide into an event framework. Neither of the
existing modules seem to work with well with an event loop.
L<Filesys::Notify::Simple> does not supply a non-blocking interface and
L<File::ChangeNotify> requires you to poll an method for new events. You could
fork off a process to run L<Filesys::Notify::Simple> and use an event handler
to watch for notices from that child, or setup a timer to check
L<File::ChangeNotify> at regular intervals, but both of those approaches seem
inefficient or overly complex. Particularly, since the underlying watcher
implementations (L<Mac::FSEvents> and L<Linux::INotify2>) provide a filehandle
that you can use and IO event to watch.

This is not slight against the authors of those modules. Both are well 
respected, are certainly finer coders than I am, and built modules which 
are perfect for many situations. If one of their modules will work for you
by all means use it, but if you are already using an event loop, this
module may fit the bill.


=head1 SEE ALSO

Modules used to implement this module L<AnyEvent>, L<Mac::FSEvents>,
L<Linux::INotify2>, L<Moose>.

Alternatives to this module L<Filesys::Notify::Simple>, L<File::ChangeNotify>.

=head1 BUGS

Please report any bugs or suggestions at L<http://rt.cpan.org/>

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Mark Grimes

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
