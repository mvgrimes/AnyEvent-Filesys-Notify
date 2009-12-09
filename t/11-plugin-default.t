use Test::More tests => 5;
use Test::Exception;
use strict;
use warnings;

use AnyEvent::Filesys::Notify;

use Test::Without::Module qw(Linux::Inotify2 Mac::FSEvents);

my $w =
  AnyEvent::Filesys::Notify->new( dir => 't', cb => sub { }, pure_perl => 1 );
isa_ok( $w, 'AnyEvent::Filesys::Notify' );
ok( $w->does('AnyEvent::Filesys::Notify::Role::Default'), '... default' );
ok( !$w->does('AnyEvent::Filesys::Notify::Role::Linux'),  '... Inotify2' );
ok( !$w->does('AnyEvent::Filesys::Notify::Role::Mac'),    '... FSEvents' );

SKIP: {
    skip 'Test for Mac/Linux only', 1 unless $^O eq 'linux' or $^O eq 'darwin';

    throws_ok {
        AnyEvent::Filesys::Notify->new( dir => 't', cb => sub { } );
    }
    qr/You probably need to install/, 'fails ok';
}

done_testing;
