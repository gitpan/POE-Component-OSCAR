#!/usr/bin/perl

# This sample script is an OSCAR-to-telnet gateway.  Once the script
# is started, you can telnet to a port (localhost:10101 by default)
# and interact with the user specified by $SEND_TO_SCREENNAME.

use strict;
use POE::Preprocessor;
use POE qw(Component::Server::TCP Component::OSCAR);

my ($oscar, $client);

# create a screenname for your script at http://www.aol.com
my $MY_SCREENNAME = 'SCREENNAME';
my $MY_PASSWORD = 'PASSWORD';

# if you telnet to localhost:10101, all messages will be sent to:
my $SEND_TO_SCREENNAME = 'THIS_SCREENNAME';

POE::Session->create(
	package_states => [
		main => [qw(_start _stop im_in signon_done)]
	]
);
$poe_kernel->run();

sub _start {

	# start the Oscar module and set up some callbacks
	$oscar = POE::Component::OSCAR->new();

	$oscar->loglevel( 5 );

	# Oscar's 'signon_done' callback will call our state, 'signon_done'; similarly for 'im_in'
	# See the Net::OSCAR docs for all the possible callbacks
	$oscar->set_callback( signon_done => 'signon_done' );
	$oscar->set_callback( im_in => 'im_in' );

	$oscar->signon( screenname => $MY_SCREENNAME, password => $MY_PASSWORD );

	# start a server on port 10101
	POE::Component::Server::TCP->new(
		Address => '127.0.0.1',
		Port => 10101,
		Alias => 'server',
		ClientConnected => sub {
			$client = $_[HEAP]->{client};
		},
		ClientInput => sub {
			my $msg = $_[ARG0];

			print "Sending to $SEND_TO_SCREENNAME: $msg\n";

			$oscar->send_im( $SEND_TO_SCREENNAME => $msg );
		}
	);

}

sub signon_done {
	print "Signon done!\n";
}

sub im_in {
	# first arg is empty; see the Net::OSCAR module for details about
	# the other arguments
	my $args = $_[ARG1];
	my ($object, $who, $what, $away) = @$args;

	print "Received from $who: $what\n";

	if ($client) {
		$client->put( "$who: $what" );
	} else {
		warn "No client connected yet!";
	}
}

sub _stop {
}
