#! /usr/bin/perl -w

use strict;
use CGI;

#use CGI::Ajax;
use JSON::XS;
use CoGe::Accessory::LogUser;
use CoGe::Accessory::Web;
use CoGeX;
use HTML::Template;
use Digest::MD5 qw(md5_base64);
use URI::Escape;
use Data::Dumper;
use File::Path;

no warnings 'redefine';

use vars
  qw($P $DBNAME $DBHOST $DBPORT $DBUSER $DBPASS $connstr $PAGE_NAME $TEMPDIR $USER $DATE $BASEFILE $coge $cogeweb %FUNCTION $COOKIE_NAME $FORM $URL $COGEDIR $TEMPDIR $TEMPURL);
$P = CoGe::Accessory::Web::get_defaults( $ENV{HOME} . 'coge.conf' );

$DATE = sprintf(
	"%04d-%02d-%02d %02d:%02d:%02d",
	sub { ( $_[5] + 1900, $_[4] + 1, $_[3] ), $_[2], $_[1], $_[0] }
	  ->(localtime)
);

$FORM = new CGI;

$DBNAME  = $P->{DBNAME};
$DBHOST  = $P->{DBHOST};
$DBPORT  = $P->{DBPORT};
$DBUSER  = $P->{DBUSER};
$DBPASS  = $P->{DBPASS};
$connstr =
  "dbi:mysql:dbname=" . $DBNAME . ";host=" . $DBHOST . ";port=" . $DBPORT;
$coge = CoGeX->connect( $connstr, $DBUSER, $DBPASS );

$COOKIE_NAME = $P->{COOKIE_NAME};
$URL         = $P->{URL};
$COGEDIR     = $P->{COGEDIR};
$TEMPDIR     = $P->{TEMPDIR} . "Groups/";
mkpath( $TEMPDIR, 0, 0777 ) unless -d $TEMPDIR;
$TEMPURL = $P->{TEMPURL} . "Groups/";

my ($cas_ticket) = $FORM->param('ticket');
$USER = undef;
($USER) = CoGe::Accessory::Web->login_cas(
	cookie_name => $COOKIE_NAME,
	ticket      => $cas_ticket,
	coge        => $coge,
	this_url    => $FORM->url()
  )
  if ($cas_ticket);
($USER) = CoGe::Accessory::LogUser->get_user(
	cookie_name => $COOKIE_NAME,
	coge        => $coge
  )
  unless $USER;

%FUNCTION = (
	gen_html                 => \&gen_html,
	get_groups_for_user      => \&get_groups_for_user,
	create_group             => \&create_group,
	delete_group             => \&delete_group,
	add_genome_to_group      => \&add_genome_to_group,
	remove_genome_from_group => \&remove_genome_from_group,
);

dispatch();

sub dispatch {
	my %args  = $FORM->Vars;
	my $fname = $args{'fname'};
	if ($fname) {
		#my %args = $FORM->Vars;
		#print STDERR Dumper \%args;
		if ( $args{args} ) {
			my @args_list = split( /,/, $args{args} );
			print $FORM->header, $FUNCTION{$fname}->(@args_list);
		}
		else {
			print $FORM->header, $FUNCTION{$fname}->(%args);
		}
	}
	else {
		print $FORM->header, gen_html();
	}
}

sub gen_html {
	my $html;
	my $template =
	  HTML::Template->new( filename => $P->{TMPLDIR} . 'generic_page.tmpl' );
	$template->param( HELP => '/wiki/index.php?title=Groups' );
	my $name = $USER->user_name;
	$name = $USER->first_name if $USER->first_name;
	$name .= " " . $USER->last_name if $USER->first_name && $USER->last_name;
	$template->param( USER       => $name );
	$template->param( TITLE      => qq{Manage User Groups} );
	$template->param( PAGE_TITLE => qq{Manage Groups} );
	$template->param( LOGO_PNG   => "Groups-logo.png" );
	$template->param( LOGON      => 1 ) unless $USER->user_name eq "public";
	$template->param( DATE       => $DATE );
	$template->param( BODY       => gen_body() );
	$template->param( ADJUST_BOX => 1 );
	$name .= $name =~ /s$/ ? "'" : "'s";
	$template->param( BOX_NAME => $name . " groups" );
	$html .= $template->output;
}

sub gen_body {
	my $template =
	  HTML::Template->new( filename => $P->{TMPLDIR} . 'Groups.tmpl' );
	$template->param( PAGE_NAME => $FORM->url );
	$template->param( MAIN      => 1 );
	my $groups = get_groups_for_user();
	$template->param( MAIN_TABLE => $groups );
	my $roles = get_roles();
	$template->param( ROLE_LOOP => $roles );
	$template->param( ADMIN_AREA => 1 ) if $USER->is_admin;
	my $ugid = $FORM->param('ugid') if defined $FORM->param('ugid');
	my $box_open = $ugid ? 'true' : 'false';
	$template->param( EDIT_BOX_OPEN    => $box_open );
	$template->param( ADDITIONAL_STUFF => qq{edit_group({ugid: $ugid});} ) if $ugid;
	
	return $template->output;
}

sub get_roles {
	my @roles;
	foreach my $role ( $coge->resultset('Role')->all() ) {
		next if $role->name =~ /admin/i && !$USER->is_admin;
		next if $role->name =~ /owner/i && !$USER->is_admin;
		my $name = $role->name;
		$name .= ": " . $role->description if $role->description;
		push @roles, { RID => $role->id, NAME => $name };
	}
	return \@roles;
}

#sub add_genome_to_group {
#	my %opts  = @_;
#	my $ugid  = $opts{ugid};
#	my $dsgid = $opts{dsgid};
#	return "DSGID and/or UGID not specified" unless $dsgid && $ugid;
#	my $is_owner = $USER->is_owner( dsg => $dsgid );
#	$is_owner = 1 if $USER->is_admin;
#	return "You are not the owner of this genome" unless $is_owner;
#	my ($ugdc) =
#	  $coge->resultset('UserGroupDataConnector')
#	  ->create( { genome_id => $dsgid, user_group_id => $ugid } );
#	return 1;
#}
#
#sub remove_genome_from_group {
#	my %opts  = @_;
#	my $ugid  = $opts{ugid};
#	my $dsgid = $opts{dsgid};
#	return "DSGID and/or UGID not specified" unless $dsgid && $ugid;
#	my ($ugdc) =
#	  $coge->resultset('UserGroupDataConnector')
#	  ->search( { genome_id => $dsgid, user_group_id => $ugid } );
#	$ugdc->delete;
#	return 1;
#}

sub create_group {
	my %opts = @_;
	return "You need to be a registered user to create a user group!" unless $USER->id;
	my $name = $opts{name};
	return "No specified name!" unless $name;
	my $desc = $opts{desc};
	my $rid  = $opts{rid};

	my ($role) = $coge->resultset('Role')->find( { name => "Reader" } );
	$rid = $role->id unless $rid;
	my $group = $coge->resultset('UserGroup')->create( 
	  { creator_user_id => $USER->id, 
	  	name => $name, 
	  	description => 
	  	$desc, 
	  	role_id => $rid 
	  } );
	my $ugc = $coge->resultset('UserGroupConnector')->create( { user_id => $USER->id, user_group_id => $group->id } );
	
	$coge->resultset('Log')->create( { user_id => $USER->id, description => 'create user group ' . $group->id } );
	
	return 1;
}

sub delete_group {
	my %opts  = @_;
	my $ugid  = $opts{ugid};
	my $group = $coge->resultset('UserGroup')->find($ugid);
	return unless $group;
	if ( $group->locked && !$USER->is_admin ) {
		return "This is a locked group.  Admin permission is needed to delete.";
	}
	$group->delete();

	$coge->resultset('Log')->create( { user_id => $USER->id, description => 'delete user group ' . $group->id } );
}

sub get_groups_for_user
{
	my %opts = @_;
	
	my @group_list;
	if ( $USER->is_admin ) {
		@group_list = $coge->resultset('UserGroup')->all();
	}
	else {
		@group_list = $USER->groups;
	}
	
	my @groups;
	foreach my $group (@group_list) {
		my $id = $group->id;
		my $is_creator = ($USER->id == $group->creator_user_id);
				
		my %row;
		$row{NAME} = qq{<span class=link onclick='window.open("GroupView.pl?ugid=$id")'>} . $group->name . "</span>" . " (id$id)" ;
		$row{DESC} = $group->description if $group->description;
		my $role = $group->role->name;

#		$role .= ": ".$group->role->description if $group->role->description;
		$row{ROLE} = $role;

#		my $perm = join (", ", map {$_->name} $group->role->permissions);
#		$row{PERM}=$perm;
		my @users;
		foreach my $user ( sort { $a->last_name cmp $b->last_name } $group->users ) {
			my $display_name = $user->display_name;
			if ($user->id == $group->creator_user_id) { # is this user the creator?
				$display_name = '<b>' . $display_name . '</b> <span style="color: gray;">(creator)</span>';
			}
			push @users, $display_name;
		}

#		push @users, "Self only" unless @users;
		$row{MEMBERS} = join( ",<br>", @users );
		my %lists;
		foreach my $list (sort { $a->type->name cmp $b->type->name || $a->name cmp $b->name } $group->lists ) {
			my $name;
			$name .= "(R)" if !$list->restricted;    #list is open to the public (P)
			$name .= $list->name;
			$name = qq{<span class="link" onclick="window.open('ListView.pl?lid=} . $list->id . qq{');">} . $name . "</span>";
			push @{ $lists{ $list->type->name } }, $name;
		}
		my $lists = "<table class='small'>";
		foreach my $type ( sort keys %lists ) {
			$lists .= qq{<tr><td>$type<td>} . join( "<br>", @{ $lists{$type} } );
		}
		$lists .= "</table>";
		$row{LISTS} = join( ",<br>", $lists );

###	my @genome;
#	push @genome, "Apotheosis" if $group->role->name =~ /admin/i;
#	foreach my $genome (sort {$a->organism->name cmp $b->organism->name || $a->version cmp $b->version || $a->genomic_sequence_type_id  <=> $b->genomic_sequence_type_id} $group->genomes)
#	  {
#	    my $name = $genome->organism->name;
#	    $name .= " (v".$genome->version.", ".$genome->type->name.")";
#	    $name = qq{<span class="link" onclick="window.open('OrganismView.pl?dsgid=}.$genome->id.qq{');">}.$name."</span>";
#	    push @genome, $name;
#	  }
#	$row{GENOMES}=join (",<br>", @genome);

		$row{BUTTONS} = 1;
		if ($is_creator) {
			$row{EDIT_BUTTON} = "<span class='link ui-icon ui-icon-gear' onclick='window.open(\"GroupView.pl?ugid=$id\")'></span>";
			$row{DELETE_BUTTON} = "<span class='link ui-icon ui-icon-trash' onclick=\"delete_group({ugid: '$id'});\"></span>";
		}

		push @groups, \%row;
	}
	my $template = HTML::Template->new( filename => $P->{TMPLDIR} . 'Groups.tmpl' );
	$template->param( GROUP_TABLE => 1 );
	$template->param( GROUPS_LOOP => \@groups );
	$template->param( BUTTONS => 1 );
	return $template->output;
}

