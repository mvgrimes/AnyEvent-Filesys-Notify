use Test::More tests => 12;
use Test::Exception;
use strict;
use warnings;

use AnyEvent::Filesys::Notify;

sub do_test {
if ( $^O eq 'linux' and eval { require Linux::Inotify2; 1 } ) {
    my $w = AnyEvent::Filesys::Notify->new( dirs => ['t'], cb => sub { } );
    isa_ok( $w, 'AnyEvent::Filesys::Notify' );
    ok( !$w->does('AnyEvent::Filesys::Notify::Role::Fallback'), '... Fallback' );
    ok( $w->does('AnyEvent::Filesys::Notify::Role::Linux'),    '... Inotify2' );
    ok( !$w->does('AnyEvent::Filesys::Notify::Role::Mac'),     '... FSEvents' );

} elsif ( $^O eq 'darwin' and eval { require Mac::FSEvents; 1; } ) {
    my $w = AnyEvent::Filesys::Notify->new( dirs => ['t'], cb => sub { } );
    isa_ok( $w, 'AnyEvent::Filesys::Notify' );
    ok( !$w->does('AnyEvent::Filesys::Notify::Role::Fallback'), '... Fallback' );
    ok( !$w->does('AnyEvent::Filesys::Notify::Role::Linux'), '... Inotify2' );
    ok( $w->does('AnyEvent::Filesys::Notify::Role::Mac'), '... FSEvents' );

} else {
    my $w = AnyEvent::Filesys::Notify->new( dirs => ['t'], cb => sub { } );
    isa_ok( $w, 'AnyEvent::Filesys::Notify' );
    ok( $w->does('AnyEvent::Filesys::Notify::Role::Fallback'), '... Fallback' );
    ok( !$w->does('AnyEvent::Filesys::Notify::Role::Linux'), '... Inotify2' );
    ok( !$w->does('AnyEvent::Filesys::Notify::Role::Mac'), '... FSEvents' );
}
}

do_test();
# Load a second time just for good measure
do_test();

my $w = AnyEvent::Filesys::Notify->new( dirs => ['t'], cb => sub { }, no_external => 1 );
isa_ok( $w, 'AnyEvent::Filesys::Notify' );
ok( $w->does('AnyEvent::Filesys::Notify::Role::Fallback'), '... Fallback' );
ok( !$w->does('AnyEvent::Filesys::Notify::Role::Linux'), '... Inotify2' );
ok( !$w->does('AnyEvent::Filesys::Notify::Role::Mac'), '... FSEvents' );

done_testing;
