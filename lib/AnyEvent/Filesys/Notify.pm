package AnyEvent::Filesys::Notify;

# ABSTRACT: AnyEvent based Filesys::Notify

use Moose;
use AnyEvent;
use File::Find::Rule;
use Cwd qw/abs_path/;
use AnyEvent::Filesys::Notify::Event;
use Carp;
use Try::Tiny;

has dir       => ( is => 'ro', required => 1 );
has cb        => ( is => 'rw', required => 1 );
has interval  => ( is => 'ro', default  => 2 );
has pure_perl => ( is => 'ro', default  => 0 );    ## TODO: -> defualt/no_ext
has _fs     => ( is => 'rw', );
has _old_fs => ( is => 'rw', isa => 'HashRef' );
has _watcher => ( is => 'rw', );

sub BUILD {
    my $self = shift;

    $self->_old_fs( _scan_fs( $self->dir ) );

    if ( $self->pure_perl ) {
        with 'AnyEvent::Filesys::Notify::Role::Default';
    } elsif ( $^O eq 'linux' ) {
        try { with 'AnyEvent::Filesys::Notify::Role::Linux' }
        catch {
            croak
              "Unable to load the Linux plugin. You probably need to install Linux::INotify2 or specify 'use_default' (but that is very inefficient):\n$_";
        }
    } elsif ( $^O eq 'darwin' ) {
        try { with 'AnyEvent::Filesys::Notify::Role::Mac' }
        catch {
            croak
              "Unable to load the Mac plugin. You probably need to install Mac::FSEvents or specify 'use_default' (but that is very inefficient):\n$_";
        }
    } else {
        with 'AnyEvent::Filesys::Notify::Role::Default';
    }

    $self->_init;
}

sub _process_events {
    my ( $self, @raw_events ) = @_;

    # We are just ingoring the raw events for now... Mac::FSEvents
    # doesn't provide much information, so rescan our selves

    my $new_fs = _scan_fs( $self->dir );
    my @events = _diff_fs( $self->_old_fs, $new_fs );

    $self->_old_fs($new_fs);
    $self->cb->(@events) if @events;
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

__END__

=head1 SYNOPSIS

    use <Module::Name>;
    # Brief but working code example(s) here showing the most common usage(s)

    # This section will be as far as many users bother reading
    # so make it as educational and exemplary as possible.


=head1 DESCRIPTION

A full description of the module and its features.
May include numerous subsections (i.e. =head2, =head3, etc.)

=cut

