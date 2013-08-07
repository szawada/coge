#! /usr/bin/perl -w

use strict;
use CGI;
use HTML::Template;
use CoGeX;
use CoGe::Accessory::Web;

use vars qw( $P $PAGE_TITLE $USER $coge %FUNCTION $FORM );

$PAGE_TITLE = 'Notebooks';

$FORM = new CGI;

( $coge, $USER, $P ) = CoGe::Accessory::Web->init(
    ticket     => $FORM->param('ticket'),
    url        => $FORM->url,
    page_title => $PAGE_TITLE
);

%FUNCTION = (
    create_list        => \&create_list,
    delete_list        => \&delete_list,
    get_lists_for_user => \&get_lists_for_user,
);

CoGe::Accessory::Web->dispatch( $FORM, \%FUNCTION, \&gen_html );

sub gen_html {
    my $template =
      HTML::Template->new( filename => $P->{TMPLDIR} . 'generic_page.tmpl' );
    $template->param( HELP => "/wiki/index.php?title=$PAGE_TITLE" );
    my $name = $USER->user_name;
    $name = $USER->first_name if $USER->first_name;
    $name .= " " . $USER->last_name if $USER->first_name && $USER->last_name;
    $template->param( USER       => $name );
    $template->param( TITLE      => qq{} );
    $template->param( PAGE_TITLE => $PAGE_TITLE );
    $template->param( LOGO_PNG   => "$PAGE_TITLE-logo.png" );
    $template->param( LOGON      => 1 ) unless $USER->user_name eq "public";
    $template->param( BODY       => gen_body() );

    #	$name .= $name =~ /s$/ ? "'" : "'s";
    #	$template->param( BOX_NAME   => $name . " Data Lists:" );
    $template->param( ADJUST_BOX => 1 );
    return $template->output;
}

sub gen_body {
    my $template =
      HTML::Template->new( filename => $P->{TMPLDIR} . "$PAGE_TITLE.tmpl" );
    $template->param( PAGE_NAME  => "$PAGE_TITLE.pl" );
    $template->param( MAIN       => 1 );
    $template->param( LIST_INFO  => get_lists_for_user() );
    $template->param( ADMIN_AREA => 1 ) if $USER->is_admin;
    return $template->output;
}

sub create_list {
    my %opts = @_;
    return "You need to be a registered user to create a new notebook."
      unless $USER->id;
    return "No specified name!" unless $opts{name};
    return "No specified type!" unless $opts{typeid};

    # Create the new list
    my $list = $coge->resultset('List')->create(
        {
            name         => $opts{name},
            description  => $opts{desc},
            list_type_id => $opts{typeid},
            restricted   => 1
        }
    );
    return unless $list;

    # Make this user the owner of the new list
    my $conn = $coge->resultset('UserConnector')->create(
        {
            parent_id   => $USER->id,
            parent_type => 5,           # FIXME hardcoded to "user"
            child_id    => $list->id,
            child_type  => 1,           # FIXME hardcoded to "list"
            role_id     => 2,           # FIXME hardcoded to "owner"
        }
    );
    return unless $conn;

    # Record in the log
    CoGe::Accessory::Web::log_history(
        db          => $coge,
        user_id     => $USER->id,
        page        => "$PAGE_TITLE",
        description => 'create notebook id' . $list->id
    );

    return 1;
}

sub delete_list {
    my %opts = @_;
    my $lid  = $opts{lid};
    return "Must have valid notebook id\n" unless ($lid);

    # Delete the list and associated connectors
    my $list = $coge->resultset('List')->find($lid);
    return 0 if ( $list->locked );
    $list->delete;

    CoGe::Accessory::Web::log_history(
        db          => $coge,
        user_id     => $USER->id,
        page        => "$PAGE_TITLE",
        description => 'delete notebook id' . $list->id
    );

    return 1;
}

sub get_lists_for_user {

    #my %opts = @_;

    my ( @lists, @admin_lists );
    if ( $USER->is_admin ) {
        @admin_lists = $coge->resultset('List')->all();
    }
    @lists = $USER->lists;
    my %user_list_ids =
      map { $_->id, 1 } @lists;   #for admins -- marks lists that they don't own
    my %seen_list_ids
      ;    #for admins -- their lists are listed first, then all lists
    my @list_info;
    @lists = sort listcmp @lists;
    push @lists, sort listcmp @admin_lists;
    foreach my $list (@lists) {

        #next if ($list->is_owner && !$USER->is_admin); # skip owner lists
        next if $seen_list_ids{ $list->id };
        $seen_list_ids{ $list->id } = 1;
        my $name =
            qq{<span class=link onclick='window.open("NotebookView.pl?lid=}
          . $list->id
          . qq{")'>}
          . $list->name
          . "</span>";
        $name = '&reg; ' . $name   if $list->restricted;
        $name = '&alpha; ' . $name if !$user_list_ids{ $list->id };

        push @list_info, {
            NAME => $name,
            DESC => $list->description,
            TYPE => ( $list->type ? $list->type->name : '' ),
            ANNO => join(
                "<br>",
                map {
                        $_->type->name . ": "
                      . $_->annotation
                      . ( $_->image ? ' (image)' : '' )
                  } sort sortAnno $list->annotations
            ),
            DATA => $list->data_summary(),

            #GROUP => $list->group->info_html,
            RESTRICTED => ( $list->restricted ? 'yes' : 'no' ),
            EDIT_BUTTON => $list->locked
            ? "<span class='link ui-icon ui-icon-locked' onclick=\"alert('This list is locked and cannot be edited.')\"></span>"
            : "<span class='link ui-icon ui-icon-gear' onclick=\"window.open('NotebookView.pl?lid="
              . $list->id
              . "')\"></span>",
            DELETE_BUTTON => $list->locked
            ? "<span class='link ui-icon ui-icon-locked' onclick=\"alert('This list is locked and cannot be deleted.')\"></span>"
            : "<span class='link ui-icon ui-icon-trash' onclick=\"dialog_delete_list({lid: '"
              . $list->id
              . "'});\"></span>"
        };
    }

    my $template =
      HTML::Template->new( filename => $P->{TMPLDIR} . "$PAGE_TITLE.tmpl" );
    $template->param( LIST_STUFF => 1 );
    $template->param( LIST_LOOP  => \@list_info );
    $template->param( TYPE_LOOP  => get_list_types() );

    return $template->output;
}

sub sortAnno {
    $a->type->name cmp $b->type->name || $a->annotation cmp $b->annotation;
}

sub get_list_types {
    my @types;
    foreach my $type ( $coge->resultset('ListType')->all() ) {
        next
          if ( $type->name =~ /owner/i )
          ;    # reserve this type for system-created lists
        my $name =
          $type->name . ( $type->description ? ": " . $type->description : '' );
        push @types, { TID => $type->id, NAME => $name };
    }
    return \@types;
}

#FIXME this routine duplicated elsewhere
sub listcmp {
    no warnings 'uninitialized';    # disable warnings for undef values in sort
    $a->name cmp $b->name;
}
