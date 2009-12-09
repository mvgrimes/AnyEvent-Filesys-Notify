use Test::More tests => 6;

use strict;
use warnings;
use lib 't/lib';
$|++;

use TestSupport qw(create_test_files delete_test_files $dir);

use AnyEvent::Filesys::Notify;
use AnyEvent::Impl::Perl;

my $cv;
my @expected = ();

my $n = AnyEvent::Filesys::Notify->new(
    dir      => $dir,
    interval => 0.5,
    cb       => sub {
        is_deeply( [ map { $_->type } @_ ], \@expected, '... got events' );
        $cv->send;
    },
    no_external => 1,
);
isa_ok( $n, 'AnyEvent::Filesys::Notify' );
ok( $n->does('AnyEvent::Filesys::Notify::Role::Fallback'),
    '... with the fallback role' );
diag "This might take a 5 seconds or so....";

@expected = qw(created created created);
create_test_files(qw(2 two/2));
$cv = AnyEvent->condvar;
$cv->recv;

@expected = qw(modified);
create_test_files(qw(2));
$cv = AnyEvent->condvar;
$cv->recv;

@expected = qw(deleted);
delete_test_files(qw(2));
$cv = AnyEvent->condvar;
$cv->recv;

ok( 1, '... arrived' );

