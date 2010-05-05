#!perl

use strict;
use warnings;

use EV                        ();
use AnyEvent                  ();
use AnyEvent::Filesys::Notify ();
use Cwd                       ();
use Devel::Cycle              ();
use Devel::Leak;

# my $handle;
# my $count = Devel::Leak::NoteSV($handle);

my $notify = AnyEvent::Filesys::Notify->new(
                 dirs   => [ Cwd::getcwd() ],
                 filter => sub { 1 },
                 cb     => sub { },
                 # no_external => 1,
             );
Devel::Cycle::find_cycle($notify);
print "done looking for cycle\n";
undef $notify;


my $timer = AnyEvent->timer( after => 1, cb => sub {} );
undef $timer;

Devel::Cycle::find_cycle($timer);
print "done looking for cycle\n";

# Devel::Leak::CheckSV( $handle );

EV::loop;

__END__

Cycle (1):

	$Class::MOP::Class::__ANON__::SERIAL::1::A->{'_fs_monitor'} => \%Linux::Inotify2::B
	    $Linux::Inotify2::B->{'w'} => \%C
	                     $C->{'1'} => \%Linux::Inotify2::Watch::D
	$Linux::Inotify2::Watch::D->{'cb'} => \&E
	             $E variable $self => \$F
	                           $$F => \%Class::MOP::Class::__ANON__::SERIAL::1::A

