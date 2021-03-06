#
#    Tangaza
#
#    Copyright (C) 2010 Nokia Corporation.
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#    Authors: Billy Odero, Jonathan Ledlie

package Nokia::Tangaza::Update;

use Exporter;
@ISA = ('Exporter');
@EXPORT = ('update_main_menu');

use strict;
use DBI;
use Nokia::Tangaza::Network;
use Nokia::Common::Sound;
use Nokia::Common::Tools;

my $tmp_dir = '/mnt/tmpfs/';
my $tmp_rec_dir = $tmp_dir.'record/';

######################################################################
sub can_post {
    my ($self, $group_id) = @_;
    
    #if 'mine' group then you have to be admin to post
    my $count = 0;
    my $group = $self->{server}{schema}->resultset('Groups')->find($group_id);
    
    return 1 if ('mine' ne $group->group_type);

    my $rs = $self->{server}{schema}->resultset('GroupAdmin')->search
	(group_id => $group_id, user_id => $self->{user}->{id});	
    
    return ($rs->count() > 0) ? 1 : 0;
    
}

######################################################################

sub update_main_menu {
    my ($self, $annotation) = @_;

    $self->log (4, "start update_main_menu");

    if (&get_total_friend_count($self) == 0) {
	$self->log (4, "user has no friends");
	&play_random ($self, &msg($self,'please-add-people-to-network'), 'bummer');
	return 'ok';
    }

        
    my @select_network_prompts = &msg ($self, 'select-network');
    
    my $channels = &select_network_menu ($self, \@select_network_prompts, 1);
    
    if (!defined($channels)) {
	&stream_file ($self, "no-network-defined-on-that-slot");
	return 'ok';
    }
    
    if (!&can_post($self, $channels)) {
    	&stream_file($self, 'you-cannot-post-to-this-group');
    	return 'ok';
    }
    
    $self->log (4, "received channel ".$channels);
    
    if ($channels eq 'timeout' ||
	$channels eq 'hangup' ||
	$channels eq 'cancel') {
	$self->log (4, "UPDATE return id ".$self->{user}->{id}.
		    " select_network_prompt $channels");
	return $channels;
    }
    
    # Make sure user has friends on in *this* network
    my $friend_count = &get_friend_count_on_network ($self, $channels);
    $self->log (4, "selected network friend count ".$friend_count);
    
    if ($friend_count <= 0) {
	&play_random ($self, &msg($self,'please-add-people-to-network'), 'bummer');
	return 'ok';
    }
    
    my $record_update_prompt = "record-update-all";
    my $update_file = &record_file ($self, &msg($self, $record_update_prompt), 20,
				    &msg($self,'to-keep-your-recording'), 0);
    
    $self->log (4, "UPDATE id ".$self->{user}->{id}." return $update_file");
    
    if ($update_file eq 'cancel') {
	&play_random ($self, &msg($self,'cancelled-update'), 'ok');
	return 'cancel';
    }
    
    if ($update_file eq 'timeout') { return 'timeout'; }
    
    if (defined($annotation)) {
	#concat the 2msgs
	my $file = $tmp_rec_dir.$update_file.".gsm";
	my $concat = "sox --combine sequence $annotation.gsm  $file $file";
	$self->log (4, "Forwarding: $concat");
	system ($concat);
    }
    
    # Move the message into the right location
    $update_file = mv_tmp_to_status_dir ($self, $update_file, 0);
    
    # move failed
    if (!defined($update_file)) {
	&play_random ($self, &msg($self,'error-has-occured'), 'bummer');
	$self->agi->stream_file(&msg($self,'please-try-again-later'), "*#", "0");
	return 'ok';
    }
    
    my $pub_id = &save_pub_message($self, $update_file, $channels);
    my $friend_tuples = &get_friends_on_network ($self, $channels);
    
    $self->log (4, "starting insert into sub_messages");
    my @dst_user_ids = ();
    
    foreach my $friend_tuple (@$friend_tuples) {
	my $dst_user_id = $friend_tuple->user_id->user_id;
	#my $channel = $friend_tuple->{channel};
	
	$self->log (4, "dst $dst_user_id channel $channels");
	
	# Update each person on this channel
	&save_sub_message ($self, $pub_id, $dst_user_id, $channels, \@dst_user_ids);
    }
    
    $self->log (4, "finished insert into sub_messages");
    
    # Update friends dirty bit
    foreach my $dst_user_id (@dst_user_ids) {
	$self->log (4, "dirty user_id $dst_user_id");
	&set_dirty_bit ($self, $dst_user_id, 1);
	
    }
    
    # Tell user that we are finished
    if (! &user_has_hungup($self)) {
	&stream_file($self,'sent-update', "*#", "0");
    }
    
    eval {
	&notify_dest($self, \@dst_user_ids, $channels);
    };
    
    $self->log (4, "end update_main_menu");
    
    return 'ok';
}

######################################################################
sub notify_dest {
    my ($self, $friends, $channel) = @_;
    $self->log(4, "Notifying users: ". join( ',', map { $_ } @$friends ));
    
    my $user_rs = $self->{server}{schema}->resultset('UserPhones')->search
	({user_id => {'IN' => [@$friends]}},
	 {select => 'phone_number'});
    
    my $group = $self->{server}{schema}->resultset('Groups')->find($channel);
    
    while (my $phone = $user_rs->next) {
	my $num = $phone->phone_number;
	$num =~ s/^2547/07/;
	&flash_update ($self, $num);
	#&send_sms_update ($self, $$phone->phone_number, $group);
    }
    
}
######################################################################
sub send_sms_update {
    my ($self, $phone, $group) = @_;
    
    my $directions = "Tangaza! $self->{callerid} sent you a Tangaza \@".$group;
    &sms_enqueue ($self, $phone, $directions);
}

######################################################################
sub flash_update {
    my ($self, $phone) = @_;
    
    my $outbound = $phone;
    $outbound =~ s/^07/2547/;
    
    my $call_content =
        "Channel: SIP/nora01/1\n".
        "Context: jnctn-callback-tangaza\n".
        "Extension: 1\n".
        "CallerID: $phone\n".
	"Setvar: OUTBOUNDID=$outbound\n".
        "WaitTime: 15\n";
    
    $self->log (4, "Making missed call to $phone");
    $self->log (4, "content $call_content");                                                                            
    
    &place_call ($call_content);

}

######################################################################
sub save_pub_message {
    my ($self, $update_file, $channels) = @_;
    $self->log (4, "START save_pub_message: $update_file $channels");
    # Insert into pub_messages
    my $msg = $self->{server}{schema}->resultset('PubMessages')->create
	({src_user_id => $self->{user}->{id}, channel => $channels,
	  filename => $update_file});
    
    my $pub_id = $msg->pub_id;
    $self->log (4, "created pub_messages id ".$pub_id);
    
    return $pub_id;
}

######################################################################
sub save_sub_message {
    my ($self, $pub_id, $dst_user_id, $channel, $dst_user_ids) = @_;
    
    my $msg = $self->{server}{schema}->resultset('SubMessages')->create
	({message_id => $pub_id, dst_user_id => $dst_user_id, 
	  channel => $channel});
    
    push (@$dst_user_ids, $dst_user_id);
}
1;
