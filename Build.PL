use Module::Build;
my $build = Module::Build->new(
    module_name   => 'AnyEvent::Filesys::Notify',
    license       => 'perl',
    create_readme => 1,
    ## create_makefile_pl => 'passthrough',
    requires => {
        'Moose'            => 0,
        'AnyEvent'         => 0,
        'File::Find::Rule' => 0,
        'Cwd'              => 0,
        'Carp'             => 0,
        ( $^O eq 'linux'  ? ( 'Linux::Inotify2' => 0 ) : () ),
        ( $^O eq 'darwin' ? ( 'Mac::FSEvents'   => 0 ) : () ),
    },

    # recommends => {
    #     Test::Kwalitee     => 0,
    #     Test::Perl::Critic => 0,
    # },
);

$build->create_build_script;

