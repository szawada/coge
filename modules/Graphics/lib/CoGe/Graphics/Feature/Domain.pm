package CoGe::Graphics::Feature::Domain;
use strict;
use base qw(CoGe::Graphics::Feature);


BEGIN {
    use vars qw($VERSION $HEIGHT $BLOCK_HEIGHT);
    $VERSION     = '0.1';
    $HEIGHT = 25;
    $BLOCK_HEIGHT = 20;
    __PACKAGE__->mk_accessors(
"block_height",
"segments", 
"print_label", #flag for printing feature label in gene
"add_type", #flag to set if gene type should be appended to label
);
}

sub add_segment
  {
    my $self = shift;
    my %opts = @_;
    my $start = $opts{start} || $opts{begin} || $opts{START} || $opts{BEGIN};
    my $stop = $opts{stop} || $opts{end} || $opts{STOP} || $opts{END};
    if ($start > $stop)
      {
	my $tmp = $start;
	$start = $stop;
	$stop = $tmp;
      }
    my @segs;
    push @segs,  @{$self->segments} if $self->segments;
    push @segs, [$start, $stop];
    $self->segments([sort {$a->[0]<=>$b->[0]} @segs]);
  }

sub _initialize
  {
    my $self = shift;
    my %opts = @_;
    my $h = $HEIGHT; #total image height 
    my $s;
    my $e;
    $self->segments([]) unless $self->segments;
    foreach my $seg (sort {$a->[0] <=> $b->[0]} @{$self->segments})
      {
	$s = $seg->[0] unless $s;
	$e = $seg->[1] unless $e;
	$s = $seg->[0] if $seg->[0] < $s;
	$e = $seg->[1] if $seg->[1] > $e;
      }
    my $w = $e-$s;
    $self->start($s);
    $self->stop($e);
    $self->image_width($w);
    $self->image_height($h);
    $self->merge_percent(35);
    $self->bgcolor([255,255,255]) unless $self->bgcolor;
    $self->color([255,255,0]);
    $self->skip_overlap_search(1);
    $self->font_size(.5);
    $self->block_height($BLOCK_HEIGHT) unless $self->block_height;
    $self->print_label(0) unless defined $self->print_label();
    $self->label_location('bot');
  }

sub _post_initialize
  {
    my $self = shift;
    my %opts = @_;
    $self->label($self->label." (".$self->type.")") if $self->add_type && $self->type;
    my $gd = $self->gd;
    $gd->fill(0,0, $self->get_color($self->bgcolor));
#    $gd->transparent($self->get_color($self->bgcolor));
    my $s = $self->start;
    my $black = $self->get_color(0,0,0);
    my $color = $self->get_color($self->color);
    my $last;
    my $c = $self->ih()/2;
    my $bh = $self->image_height/2;
    my @sorted = sort {$a->[0] <=> $b->[0]} @{$self->segments};
    foreach my $seg (@sorted)
      {
	my $x1 = $seg->[0] - $s;
	my $x2 = $seg->[1] - $s;
	my $y1 = $c-$bh;
	my $y2 = $c+$bh;
	$gd->filledRectangle($x1,$y1, $x2, $y2, $color);
	$gd->rectangle($x1,$y1, $x2, $y2, $black);
	$gd->setStyle($black, $black, $black, GD::gdTransparent, GD::gdTransparent);
	if ($last)
	  {
	    my $mid = ($x1-$last)/2+$last;
	    $gd->line($last, $y1, $mid, 0, GD::gdStyled);
	    $gd->line($mid, 0, $x1, $y1, GD::gdStyled);
	  }
	$last = $x2;
      }
#    $self->_gd_string(y=>$c-$bh+2, x=>$x, text=>$self->label, size=>$self->block_height-4) if $self->print_label;
  }

#################### subroutine header begin ####################

=head2 sample_function

 Usage     : How to use this function/method
 Purpose   : What it does
 Returns   : What it returns
 Argument  : What it wants to know
 Throws    : Exceptions and other anomolies
 Comment   : This is a sample subroutine header.
           : It is polite to include more pod and fewer comments.

See Also   : 

=cut

#################### subroutine header end ####################


#################### main pod documentation begin ###################
## Below is the stub of documentation for your module. 
## You better edit it!


=head1 NAME

CoGe::Graphics::Feature::Base

=head1 SYNOPSIS

  use CoGe::Graphics::Feature::Base


=head1 DESCRIPTION

=head1 USAGE



=head1 BUGS



=head1 SUPPORT



=head1 AUTHOR

	Eric Lyons
	elyons@nature.berkeley.edu

=head1 COPYRIGHT

This program is free software licensed under the...

	The Artistic License

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

