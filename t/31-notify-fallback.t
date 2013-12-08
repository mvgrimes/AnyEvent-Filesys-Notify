use Test::More tests => 11;

use strict;
use warnings;
use File::Spec;
use lib 't/lib';
$|++;

use TestSupport qw(create_test_files delete_test_files move_test_files $dir);

use AnyEvent::Filesys::Notify;
use AnyEvent::Impl::Perl;

create_test_files(qw(one/1));
create_test_files(qw(two/1));
create_test_files(qw(three));

my $cv;
my @expected = ();

my $n = AnyEvent::Filesys::Notify->new(
    dirs => [
        File::Spec->catfile( $dir, 'one' ), File::Spec->catfile( $dir, 'two' ), File::Spec->catfile( $dir, 'three' ),
    ],
    interval => 0.5,
    filter   => sub { shift !~ qr/ignoreme/ },
    cb       => sub {
        is_deeply(
            [ map { $_->type } @_ ], \@expected,
            '... got events: ' . join ',', @expected
        );
        $cv->send;
    },
    no_external => 1,
);

isa_ok( $n, 'AnyEvent::Filesys::Notify' );
ok( $n->does('AnyEvent::Filesys::Notify::Role::Fallback'),
    '... with the fallback role' );

my $w =
  AnyEvent->timer( after => 9, cb => sub { die '... events timed out'; } );
diag "This might take a few seconds to run...";

@expected = qw(created created created);
create_test_files(qw(one/2 two/sub/2));
$cv = AnyEvent->condvar;
$cv->recv;

@expected = qw(modified);
create_test_files(qw(one/2));
$cv = AnyEvent->condvar;
$cv->recv;

@expected = qw(deleted);
delete_test_files(qw(two/sub/2));
$cv = AnyEvent->condvar;
$cv->recv;

@expected = qw(created);
create_test_files(qw(one/ignoreme one/3));
$cv = AnyEvent->condvar;
$cv->recv;

@expected = qw(deleted created);
move_test_files( 'one/3' => 'one/5' );
$cv = AnyEvent->condvar;
$cv->recv;

@expected = qw(modified);
create_test_files(qw(three));
$cv = AnyEvent->condvar;
$cv->recv;

@expected = qw(deleted);
move_test_files( 'three' => 'three_1' );
$cv = AnyEvent->condvar;
$cv->recv;

$n->filter(qr/onlyme/);

@expected = qw(created);
create_test_files(qw(one/onlyme one/4));
$cv = AnyEvent->condvar;
$cv->recv;

ok( 1, '... arrived' );
