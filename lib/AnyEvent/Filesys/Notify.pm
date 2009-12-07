package AnyEvent::Filesys::Notify;

use Moose;
use AnyEvent;
use Mac::FSEvents;
use File::Find::Rule;
use Cwd qw/abs_path/;
use AnyEvent::Filesys::Notify::Event;

has dir => ( is => 'ro', required => 1 );
has cb  => ( is => 'rw', required => 1 );
has _fs => ( is => 'rw', );
has _old_fs => ( is => 'rw' );
has _w      => ( is => 'rw', );

sub BUILD {
    my $self = shift;

    $self->_old_fs( _scan_fs( $self->dir ) );

    $self->_fs(
        Mac::FSEvents->new( {
                path    => $self->dir,
                latency => 2.0,
            } ) );

    $self->_w(
        AnyEvent->io(
            fh   => $self->_fs->watch,
            poll => 'r',
            cb   => sub {
                $self->_process_events( $self->_fs->read_events() );
            } ) );

}

sub _process_events {
    my ( $self, @raw_events ) = @_;

    # We are just ingoring the raw events for now... Mac::FSEvents
    # doesn't provide much information, so rescan our selves

    my $new_fs = _scan_fs( $self->dir );
    my @events = _diff_fs( $self->_old_fs, $new_fs );

    $self->_old_fs($new_fs);

    $self->cb->(@events);
}

# Return a hash ref representing all the files and stats in @path.
sub _scan_fs {
    my (@paths) = @_;

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
                path => $path,
                type => 'deleted'
              );
        } elsif ( _is_path_modified( $old_fs->{$path}, $new_fs->{$path} ) ) {
            push @events,
              AnyEvent::Filesys::Notify::Event->new(
                path => $path,
                type => 'modified'
              );
        }
    }

    for my $path ( keys %$new_fs ) {
        if ( not exists $old_fs->{$path} ) {
            push @events,
              AnyEvent::Filesys::Notify::Event->new(
                path => $path,
                type => 'created'
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

1;
