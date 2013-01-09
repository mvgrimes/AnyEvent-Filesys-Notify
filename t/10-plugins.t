use Test::More;
use Test::Exception;
use strict;
use warnings;

use AnyEvent::Filesys::Notify;

# Used to shorten the tests
my $AEFN = 'AnyEvent::Filesys::Notify';

subtest 'Try to load the correct backend for this O/S' => sub {
    if ( $^O eq 'linux' and eval { require Linux::Inotify2; 1 } ) {
        my $w = AnyEvent::Filesys::Notify->new( dirs => ['t'], cb => sub { } );
        isa_ok( $w, $AEFN );
        ok( !$w->does( $AEFN . '::Role::Fallback' ), '... Fallback' );
        ok( $w->does( $AEFN . '::Role::Linux' ),     '... Inotify2' );
        ok( !$w->does( $AEFN . '::Role::Mac' ),      '... FSEvents' );
        ok( !$w->does( $AEFN . '::Role::FreeBSD' ),  '... KQueue' );

    } elsif (
        $^O eq 'darwin' and eval {
            require Mac::FSEvents;
            1;
        } )
    {
        my $w = AnyEvent::Filesys::Notify->new( dirs => ['t'], cb => sub { } );
        isa_ok( $w, $AEFN );
        ok( !$w->does( $AEFN . '::Role::Fallback' ), '... Fallback' );
        ok( !$w->does( $AEFN . '::Role::Linux' ),    '... Inotify2' );
        ok( $w->does( $AEFN . '::Role::Mac' ),       '... FSEvents' );
        ok( !$w->does( $AEFN . '::Role::FreeBSD' ),  '... KQueue' );

    } elsif (
        $^O eq 'freebsd' and eval {
            require IO::KQueue;
            1;
        } )
    {
        my $w = AnyEvent::Filesys::Notify->new( dirs => ['t'], cb => sub { } );
        isa_ok( $w, $AEFN );
        ok( !$w->does( $AEFN . '::Role::Fallback' ), '... Fallback' );
        ok( !$w->does( $AEFN . '::Role::Linux' ),    '... Inotify2' );
        ok( !$w->does( $AEFN . '::Role::Mac' ),      '... FSEvents' );
        ok( $w->does( $AEFN . '::Role::FreeBSD' ),   '... KQueue' );

    } else {
        my $w = AnyEvent::Filesys::Notify->new( dirs => ['t'], cb => sub { } );
        isa_ok( $w, $AEFN );
        ok( $w->does( $AEFN . '::Role::Fallback' ), '... Fallback' );
        ok( !$w->does( $AEFN . '::Role::Linux' ),   '... Inotify2' );
        ok( !$w->does( $AEFN . '::Role::Mac' ),     '... FSEvents' );
        ok( !$w->does( $AEFN . '::Role::FreeBSD' ), '... KQueue' );
    }
};

subtest 'Try to load the fallback backend via no_external' => sub {
    my $w = AnyEvent::Filesys::Notify->new(
        dirs        => ['t'],
        cb          => sub { },
        no_external => 1,
    );
    isa_ok( $w, $AEFN );
    ok( $w->does( $AEFN . '::Role::Fallback' ), '... Fallback' );
    ok( !$w->does( $AEFN . '::Role::Linux' ),   '... Inotify2' );
    ok( !$w->does( $AEFN . '::Role::Mac' ),     '... FSEvents' );
    ok( !$w->does( $AEFN . '::Role::FreeBSD' ), '... KQueue' );
};

subtest 'Try to specify Fallback via the backend arguement' => sub {
    my $w = AnyEvent::Filesys::Notify->new(
        dirs    => ['t'],
        cb      => sub { },
        backend => 'Fallback',
    );
    isa_ok( $w, $AEFN );
    ok( $w->does( $AEFN . '::Role::Fallback' ), '... Fallback' );
    ok( !$w->does( $AEFN . '::Role::Linux' ),   '... Inotify2' );
    ok( !$w->does( $AEFN . '::Role::Mac' ),     '... FSEvents' );
    ok( !$w->does( $AEFN . '::Role::FreeBSD' ), '... KQueue' );
};

subtest 'Try to specify +AEFNR::Fallback via the backend arguement' => sub {
    my $w = AnyEvent::Filesys::Notify->new(
        dirs    => ['t'],
        cb      => sub { },
        backend => "+${AEFN}::Role::Fallback",
    );
    isa_ok( $w, $AEFN );
    ok( $w->does( $AEFN . '::Role::Fallback' ), '... Fallback' );
    ok( !$w->does( $AEFN . '::Role::Linux' ),   '... Inotify2' );
    ok( !$w->does( $AEFN . '::Role::Mac' ),     '... FSEvents' );
    ok( !$w->does( $AEFN . '::Role::FreeBSD' ), '... KQueue' );
};

if ( $^O eq 'darwin' and eval { require IO::KQueue; 1; } ) {

    # IO::KQueue fails mightily with "invalid arguement" on a Mac. IO::KQueue
    # seems to be working fine on FreeBSD. I don't have the experience or time
    # to fix it on a Mac.  I would greatly appreciate any help troubleshooting.

  TODO: {
        todo_skip 'IO::KQueue reports invalid arguement', 5;

        subtest 'Try to force KQueue on Mac with IO::KQueue installed' => sub {
            my $w = eval {
                AnyEvent::Filesys::Notify->new(
                    dirs    => ['t'],
                    cb      => sub { },
                    backend => 'FreeBSD'
                );
            };
            isa_ok( $w, $AEFN );
            ok( !$w->does( $AEFN . '::Role::Fallback' ), '... Fallback' );
            ok( !$w->does( $AEFN . '::Role::Linux' ),    '... Inotify2' );
            ok( !$w->does( $AEFN . '::Role::Mac' ),      '... FSEvents' );
            ok( $w->does( $AEFN . '::Role::FreeBSD' ),   '... KQueue' );
          }
    }
}

done_testing;
