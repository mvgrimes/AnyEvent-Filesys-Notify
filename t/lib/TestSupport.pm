package TestSupport;

use File::Temp qw(tempdir);
use File::Path;
use File::Basename;
use autodie;

use Exporter qw(import);
our @EXPORT_OK = qw(create_test_files delete_test_files $dir);

our $dir = tempdir( CLEANUP => 1 );
my $size = 1;

sub create_test_files {
    my (@files) = @_;

    for my $file (@files) {
        my $full_file = File::Spec->catfile( $dir, $file );
        my $full_dir = dirname($full_file);

        mkpath $full_dir unless -d $full_dir;

        open my $fd, ">", $full_file;
        print $fd "Test\n" x $size++;
        close $fd;
    }
}

sub delete_test_files {
    my (@files) = @_;

    for my $file (@files) {
        my $full_file = File::Spec->catfile( $dir, $file );
        if   ( -d $full_file ) { rmdir $full_file; }
        else                   { unlink $full_file; }
    }
}

1;
