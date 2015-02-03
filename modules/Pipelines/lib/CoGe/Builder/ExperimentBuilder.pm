package CoGe::Builder::ExperimentBuilder;

use Moose;

use CoGe::Accessory::IRODS qw(irods_get_base_path);
use CoGe::Accessory::Web qw(url_for);
use CoGe::Accessory::Utils;
use CoGe::Core::Storage qw(get_experiment_files get_workflow_paths);
use CoGe::Pipelines::Common::Results;
use CoGe::Pipelines::Misc::IPut;

use File::Spec::Functions;
use Data::Dumper;

sub build {
    my $self = shift;

    $self->workflow( $self->jex->create_workflow(name => "Export experiment", init => 1) );
    return unless $self->workflow->id;

    my ($staging_dir, $result_dir) = get_workflow_paths($self->user->name, $self->workflow->id);

    my $dest_type = $self->options->{dest_type};
    $dest_type = "http" unless $dest_type;

    my $eid = $self->params->{eid};
    my $experiment = $self->db->resultset('Experiment')->find($eid);
    my $exp_name = $experiment->name;
       $exp_name = $eid unless $exp_name;

    my $filename = "experiment_$exp_name.tar.gz";
    my $cache_dir = $self->get_download_path($eid);
    my $cache_file = catfile($cache_dir, $filename);
    $self->workflow->logfile(catfile($result_dir, "debug.log"));

    my %job = export_experiment($self->params, $cache_file, $self->conf);
    $self->workflow->add_job(%job);

    if ($dest_type eq "irods") {
        my $base = $self->options->{dest_path};
        $base = irods_get_base_path($self->user->name) unless $base;
        my $dest = catfile($base, $filename);
        my $irods_done = catfile($staging_dir, "irods.done");

        $self->workflow->add_job( export_to_irods($cache_file, $dest, $self->options->{overwrite}, $irods_done) );
        $self->workflow->add_job( generate_results($dest, $dest_type, $result_dir, $self->conf, $irods_done)) ;
    } 
    else {
        $self->workflow->add_job( link_results($cache_file, $cache_file, $result_dir, $self->conf) );
    }
    
    return 1;
}

sub get_download_path { #TODO merge with similar subroutine in GenomeBuilder.pm and move into Storage.pm
    my $self = shift;
    my $eid = shift;
    my $unique_path = get_unique_id();
    my @paths = ($self->conf->{SECTEMPDIR}, 'downloads', 'experiments', $eid, $unique_path);
    return File::Spec->catdir(@paths);
}

sub export_experiment {
    my ($params, $output, $conf) = @_;

    return (
        cmd => catdir($conf->{SCRIPTDIR}, "export_experiment_or_genome.pl"),
        description => "Generating experiment files",
        args => [
            ["-id", $params->{eid}, 0],
            ["-type", '"experiment"', 0],
            ["-output", $output, 1],
            ["-conf", $conf->{_CONFIG_PATH}, 0],
            ["-dir", ".", ""]
        ],
        inputs => [],
        outputs => [$output]
    );
}

with qw(CoGe::Builder::Buildable);

1;
