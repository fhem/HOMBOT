###############################################################################
# 
# Developed with Kate
#
#  (c) 2015 Copyright: Marko Oldenburg (leongaultier at gmail dot com)
#  All rights reserved
#
#  This script is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  any later version.
#
#  The GNU General Public License can be found at
#  http://www.gnu.org/copyleft/gpl.html.
#  A copy is found in the textfile GPL.txt and important notices to the license
#  from the author is found in LICENSE.txt distributed with these scripts.
#
#  This script is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#
# $Id$
#
###############################################################################


package main;

use strict;
use warnings;
use Time::HiRes qw(gettimeofday);

use HttpUtils;
use TcpServerUtils;

my $version = "0.0.2";




# my %jsonCmd =   (         Wird gebraucht wenn wir auf die JSON Schnittstelle umstellen
                  #);






sub HOMEBOT_Initialize($) {

    my ($hash) = @_;

    $hash->{SetFn}	= "HOMEBOT_Set";
    $hash->{DefFn}	= "HOMEBOT_Define";
    $hash->{UndefFn}	= "HOMEBOT_Undef";
    $hash->{AttrFn}	= "HOMEBOT_Attr";
    
    $hash->{AttrList} 	= "interval ".
			  "disable:1 ".
			  $readingFnAttributes;
    
    foreach my $d(sort keys %{$modules{HOMEBOT}{defptr}}) {
	my $hash = $modules{HOMEBOT}{defptr}{$d};
	$hash->{VERSION} 	= $version;
    }
}

sub HOMEBOT_Define($$) {

    my ( $hash, $def ) = @_;
    
    my @a = split( "[ \t][ \t]*", $def );

    return "too few parameters: define <name> HOMEBOT <HOST>" if( @a != 3 );

    my $name    	= $a[0];
    my $host    	= $a[2];
    my $port		= 6260;
    my $interval  	= 180;

    $hash->{HOST} 	= $host;
    $hash->{PORT} 	= $port;
    $hash->{INTERVAL} 	= $interval;
    $hash->{VERSION} 	= $version;


    Log3 $name, 3, "HOMEBOT ($name) - defined with host $hash->{HOST} on port $hash->{PORT} and interval $hash->{INTERVAL} (sec)";

    $attr{$name}{room} = "HOMEBOT" if( !defined( $attr{$name}{room} ) );    # sorgt für Diskussion, überlegen ob nötig
    #readingsSingleUpdate ( $hash, "state", "initialized", 1 );  bleibt solange bis ein Request gemacht werden kann und Readings angelegt
    readingsSingleUpdate ( $hash, "state", "active", 1 );

    #InternalTimer( gettimeofday()+$hash->{INTERVAL}, "HOMEBOT_Get_stateRequest", $hash, 0 ); zum testen deaktiviert
	
    return undef;
}

sub HOMEBOT_Undef($$) {

    my ( $hash, $arg ) = @_;
    
    my $host = $hash->{HOST};
    my $name = $hash->{NAME};
    
    delete $modules{HOMEBOT}{defptr}{$hash->{HOST}};
    RemoveInternalTimer( $hash );
    
    return undef;
}

sub HOMEBOT_Attr(@) {

    my ( $cmd, $name, $attrName, $attrVal ) = @_;
    my $hash = $defs{$name};

    if( $attrName eq "disable" ) {
	if( $cmd eq "set" ) {
	    if( $attrVal eq "0" ) {
		RemoveInternalTimer( $hash );
		InternalTimer( gettimeofday()+2, "HOMEBOT_Get_stateRequest", $hash, 0 ) if( ReadingsVal( $hash->{NAME}, "state", 0 ) eq "disabled" );
		readingsSingleUpdate ( $hash, "state", "active", 1 );
		Log3 $name, 3, "HOMEBOT ($name) - enabled";
	    } else {
		readingsSingleUpdate ( $hash, "state", "disabled", 1 );
		RemoveInternalTimer( $hash );
		Log3 $name, 3, "HOMEBOT ($name) - disabled";
	    }
	}
	elsif( $cmd eq "del" ) {
	    RemoveInternalTimer( $hash );
	    InternalTimer( gettimeofday()+2, "HOMEBOT_Get_stateRequest", $hash, 0 ) if( ReadingsVal( $hash->{NAME}, "state", 0 ) eq "disabled" );
	    readingsSingleUpdate ( $hash, "state", "active", 1 );
	    Log3 $name, 3, "HOMEBOT ($name) - enabled";

	} else {
	    if($cmd eq "set") {
		$attr{$name}{$attrName} = $attrVal;
		Log3 $name, 3, "HOMEBOT ($name) - $attrName : $attrVal";
	    }
	    elsif( $cmd eq "del" ) {
	    }
	}
    }
    
    if( $attrName eq "interval" ) {
	if( $cmd eq "set" ) {
	    if( $attrVal < 60 ) {
		Log3 $name, 3, "HOMEBOT ($name) - interval too small, please use something > 60 (sec), default is 180 (sec)";
		return "interval too small, please use something > 60 (sec), default is 180 (sec)";
	    } else {
		$hash->{INTERVAL} = $attrVal;
		Log3 $name, 3, "HOMEBOT ($name) - set interval to $attrVal";
	    }
	}
	elsif( $cmd eq "del" ) {
	    $hash->{INTERVAL} = 180;
	    Log3 $name, 3, "HOMEBOT ($name) - set interval to default";
	
	} else {
	    if( $cmd eq "set" ) {
		$attr{$name}{$attrName} = $attrVal;
		Log3 $name, 3, "HOMEBOT ($name) - $attrName : $attrVal";
	    }
	    elsif( $cmd eq "del" ) {
	    }
	}
    }
    
    return undef;
}

sub HOMEBOT_Get_stateRequestLocal($) {

my ( $hash ) = @_;
    my $name = $hash->{NAME};

    HOMEBOT_RetrieveHomebotInfomations( $hash ) if( ReadingsVal( $hash->{NAME}, "state", 0 ) ne "initialized" && AttrVal( $name, "disable", 0 ) ne "1" );
    
    return 0;
}

sub HOMEBOT_Get_stateRequest($) {

    my ( $hash ) = @_;
    my $name = $hash->{NAME};
 
    HOMEBOT_RetrieveHomebotInfomations( $hash ) if( AttrVal( $name, "disable", 0 ) ne "1" );
  
    InternalTimer( gettimeofday()+$hash->{INTERVAL}, "HOMEBOT_Get_stateRequest", $hash, 1 );
    Log3 $name, 4, "HOMEBOT ($name) - Call HOMEBOT_Get_stateRequest";

    return 1;
}

sub HOMEBOT_RetrieveHomebotInfomations($) {

    my ($hash) = @_;
    my $name = $hash->{NAME};
    my $host = $hash->{HOST};
    my $port = $hash->{PORT};

    
    my $url = "http://" . $host . ":" . $port . "/json.cgi?"; # Path muß so im Automagic als http request Trigger drin stehen
  
    HttpUtils_NonblockingGet(
	{
	    url		=> $url,
	    timeout	=> 10,
	    hash	=> $hash,
	    method	=> "GET",
	    doTrigger	=> 1,
	    callback	=> \&HOMEBOT_Parse_HomebotInfomations,
	}
    );
    Log3 $name, 4, "HOMEBOT ($name) - NonblockingGet get URL";
    Log3 $name, 4, "HOMEBOT ($name) - HOMEBOT_RetrieveHomebotInfomations: calling Host: $host";
}

sub HOMEBOT_Parse_HomebotInfomations($$$) {
    
    my ( $param, $err, $data ) = @_;
    my $hash = $param->{hash};
    my $doTrigger = $param->{doTrigger};
    my $name = $hash->{NAME};
    my $host = $hash->{HOST};

    Log3 $name, 4, "HOMEBOT ($name) - HOMEBOT_Parse_HomebotInfomations: processed request data";
    


    ### Begin Error Handling
    if( $hash->{helper}{infoErrorCounter} > 2 ) {
	readingsBeginUpdate( $hash );
	readingsBulkUpdate( $hash, "lastStatusRequestState", "statusRequest_error" );
	
	if( $hash->{helper}{infoErrorCounter} > 9 && $hash->{helper}{setCmdErrorCounter} > 4 ) {
	    readingsBulkUpdate( $hash, "lastStatusRequestError", "unknown error, please contact the developer" );
	    
	    Log3 $name, 4, "HOMEBOT ($name) - UNKNOWN ERROR, PLEASE CONTACT THE DEVELOPER, DEVICE DISABLED";
	    
	    $attr{$name}{disable} = 1;
	    readingsBulkUpdate ( $hash, "state", "Unknown Error, device disabled");
	    
	    $hash->{helper}{infoErrorCounter} = 0;
	    $hash->{helper}{setCmdErrorCounter} = 0;
	    
	    return;
	}

	elsif( $hash->{helper}{infoErrorCounter} > 9 ) {
	    readingsBulkUpdate( $hash, "lastStatusRequestError", "to many errors, check your network configuration" );
	    
	    Log3 $name, 4, "HOMEBOT ($name) - To many Errors please check your Network Configuration";

	    readingsBulkUpdate ( $hash, "state", "To many Errors");
	    $hash->{helper}{infoErrorCounter} = 0;
	}
	readingsEndUpdate( $hash, 1 );
    }
    
    if( defined( $err ) ) {
	if( $err ne "" ) {
	    readingsBeginUpdate( $hash );
	    readingsBulkUpdate ( $hash, "state", "$err") if( ReadingsVal( $name, "state", 1 ) ne "initialized" );
	    $hash->{helper}{infoErrorCounter} = ( $hash->{helper}{infoErrorCounter} + 1 );

	    readingsBulkUpdate( $hash, "lastStatusRequestState", "statusRequest_error" );
	  
	    if( $err =~ /timed out/ ) {
		readingsBulkUpdate( $hash, "lastStatusRequestError", "connect to your device is timed out. check network ");
	    }
	    elsif( ( $err =~ /Keine Route zum Zielrechner/ ) && $hash->{helper}{infoErrorCounter} > 1 ) {
		readingsBulkUpdate( $hash,"lastStatusRequestError", "no route to target. bad network configuration or network is down ");
	    } else {
		readingsBulkUpdate($hash, "lastStatusRequestError", $err );
	    }

	readingsEndUpdate( $hash, 1 );
	
	Log3 $name, 4, "HOMEBOT ($name) - HOMEBOT_Parse_HomebotInfomations: error while request: $err";
	return;
	}
    }

    if( $data eq "" and exists( $param->{code} ) ) {
	readingsBeginUpdate( $hash );
	readingsBulkUpdate ( $hash, "state", $param->{code} ) if( ReadingsVal( $name, "state", 1 ) ne "initialized" );
	$hash->{helper}{infoErrorCounter} = ( $hash->{helper}{infoErrorCounter} + 1 );
    
	readingsBulkUpdate( $hash, "lastStatusRequestState", "statusRequest_error" );
    
	if( $param->{code} ne 200 ) {
	    readingsBulkUpdate( $hash," lastStatusRequestError", "http Error ".$param->{code} );
	}
	
	readingsBulkUpdate( $hash, "lastStatusRequestError", "empty response" );
	readingsEndUpdate( $hash, 1 );
    
	Log3 $name, 4, "HOMEBOT ($name) - HOMEBOT_RetrieveHomebotInfomationsFinished: received http code ".$param->{code}." without any data after requesting HOMEBOT Device";

	return;
    }

    if( ( $data =~ /Error/i ) and exists( $param->{code} ) ) {    
	readingsBeginUpdate( $hash );
	readingsBulkUpdate( $hash, "state", $param->{code} ) if( ReadingsVal( $name, "state" ,0) ne "initialized" );
	$hash->{helper}{infoErrorCounter} = ( $hash->{helper}{infoErrorCounter} + 1 );

	readingsBulkUpdate( $hash, "lastStatusRequestState", "statusRequest_error" );
    
	    if( $param->{code} eq 404 ) {
		readingsBulkUpdate( $hash, "lastStatusRequestError", "HTTP Server at Homebot offline" );
	    } else {
		readingsBulkUpdate( $hash, "lastStatusRequestError", "http error ".$param->{code} );
	    }
	
	readingsEndUpdate( $hash, 1 );
    
	Log3 $name, 4, "HOMEBOT ($name) - HOMEBOT_Parse_HomebotInfomations: received http code ".$param->{code}." receive Error after requesting HOMEBOT";

	return;
    }

    ### End Error Handling

    $hash->{helper}{infoErrorCounter} = 0;
 
    ### Begin Parse Processing
    readingsSingleUpdate( $hash, "state", "active", 1) if( ReadingsVal( $name, "state", 0 ) ne "initialized" or ReadingsVal( $name, "state", 0 ) ne "active" );






    my @valuestring = split( '@@@@',  $data );
    my %buffer;
    foreach( @valuestring ) {
	my @values = split( '@@' , $_ );
	$buffer{$values[0]} = $values[1];
    }


    readingsBeginUpdate( $hash );
    
    my $t;
    my $v;
    while( ( $t, $v ) = each %buffer ) {
	$v =~ s/null//g;
	readingsBulkUpdate( $hash, $t, $v ) if( defined( $v ) );
    }
    
    readingsBulkUpdate( $hash, "lastStatusRequestState", "statusRequest_done" );
    
    
    
    $hash->{helper}{infoErrorCounter} = 0;
    ### End Response Processing
    
    readingsBulkUpdate( $hash, "state", "active" ) if( ReadingsVal( $name, "state", 0 ) eq "initialized" );
    readingsEndUpdate( $hash, 1 );
    
    return undef;
}

sub HOMEBOT_Set($$@) {
    
    my ( $hash, $name, $cmd, @val ) = @_;


	my $list = "";
	$list .= "cleanStart:noArg ";
	$list .= "homing:noArg ";
	$list .= "pause:noArg ";
	$list .= "statusRequest:noArg ";
	$list .= "cleanMode:CLEAN_SB,CLEAN_ZZ ";
	

	if( lc $cmd eq 'cleanstart'
	    || lc $cmd eq 'homing'
	    || lc $cmd eq 'pause'
	    || lc $cmd eq 'statusrequest'
	    || lc $cmd eq 'cleanmode' ) {

	    Log3 $name, 5, "HOMEBOT ($name) - set $name $cmd ".join(" ", @val);
	  
	    return "set command only works if state not equal initialized, please wait for next interval run" if( ReadingsVal( $hash->{NAME}, "state", 0 ) eq "initialized");
	  
	    return HOMEBOT_SelectSetCmd( $hash, $cmd, @val ) if( ( @val ) || lc $cmd eq 'statusrequest' || lc $cmd eq 'cleanstart'|| lc $cmd eq 'homing' || lc $cmd eq 'pause' );
	}

	return "Unknown argument $cmd, bearword as argument or wrong parameter(s), choose one of $list";
}

sub HOMEBOT_SelectSetCmd($$@) {

    my ( $hash, $cmd, @data ) = @_;
    my $name = $hash->{NAME};
    my $host = $hash->{HOST};
    my $port = $hash->{PORT};

    if( lc $cmd eq 'cleanstart' ) {
	
	my $url = "http://" . $host . ":" . $port . "/json.cgi?%7b%22COMMAND%22:%22CLEAN_START%22%7d";

	Log3 $name, 4, "HOMEBOT ($name) - Homebot start cleaning";
	    
	return HOMEBOT_HTTP_POST( $hash,$url );
    }
    
    elsif( lc $cmd eq 'homing' ) {
	
	my $url = "http://" . $host . ":" . $port . "/json.cgi?%7b%22COMMAND%22:%22HOMING%22%7d";

	Log3 $name, 4, "HOMEBOT ($name) - Homebot come home";
	    
	return HOMEBOT_HTTP_POST( $hash,$url );
    }
    
    elsif( lc $cmd eq 'pause' ) {
	
	my $url = "http://" . $host . ":" . $port . "/json.cgi?%7b%22COMMAND%22:%22PAUSE%22%7d";

	Log3 $name, 4, "HOMEBOT ($name) - Homebot paused";
	    
	return HOMEBOT_HTTP_POST( $hash,$url );
    }
    
    elsif( lc $cmd eq 'cleanmod' ) {
        my $mode = join( " ", @data );
	
	my $url = "http://" . $host . ":" . $port . "/json.cgi?%7b%22COMMAND%22:%7b%22CLEAN_MODE%22:".$mode."%22%7d%7d";

	Log3 $name, 4, "HOMEBOT ($name) - Homebot paused";
	    
	return HOMEBOT_HTTP_POST( $hash,$url );
    }

    return undef;
}

sub HOMEBOT_HTTP_POST($$) {

    my ( $hash, $url ) = @_;
    my $name = $hash->{NAME};
    
    my $state = ReadingsVal( $name, "state", 0 );
    
    readingsSingleUpdate( $hash, "state", "Send HTTP POST", 1 );
    
    HttpUtils_NonblockingGet(
	{
	    url		=> $url,
	    timeout	=> 10,
	    hash	=> $hash,
	    method	=> "POST",
	    doTrigger	=> 1,
	    callback	=> \&HOMEBOT_HTTP_POSTerrorHandling,
	}
    );
    Log3 $name, 4, "HOMEBOT ($name) - Send HTTP POST with URL $url";

    readingsSingleUpdate( $hash, "state", $state, 1 );

    return undef;
}

sub HOMEBOT_HTTP_POSTerrorHandling($$$) {

    my ( $param, $err, $data ) = @_;
    my $hash = $param->{hash};
    my $name = $hash->{NAME};
    

    ### Begin Error Handling
    if( $hash->{helper}{setCmdErrorCounter} > 2 ) {
	readingsBeginUpdate( $hash );
	readingsBulkUpdate( $hash, "lastSetCommandState", "statusRequest_error" );
	
	if( $hash->{helper}{infoErrorCounter} > 9 && $hash->{helper}{setCmdErrorCounter} > 4 ) {
	    readingsBulkUpdate($hash, "lastSetCommandError", "unknown error, please contact the developer" );
	    
	    Log3 $name, 4, "HOMEBOT ($name) - UNKNOWN ERROR, PLEASE CONTACT THE DEVELOPER, DEVICE DISABLED";
	    
	    $attr{$name}{disable} = 1;
	    readingsBulkUpdate( $hash, "state", "Unknown Error" );
	    $hash->{helper}{infoErrorCounter} = 0;
	    $hash->{helper}{setCmdErrorCounter} = 0;
	    
	    return;
	}

	elsif( $hash->{helper}{setCmdErrorCounter} > 4 ){
	    readingsBulkUpdate( $hash, "lastSetCommandError", "HTTP Server at Homebot offline" );
	    
	    Log3 $name, 4, "HOMEBOT ($name) - Please check HTTP Server at Homebot";
	} 
	elsif( $hash->{helper}{setCmdErrorCounter} > 9 ) {
	    readingsBulkUpdate( $hash, "lastSetCommandError", "to many errors, check your network or device configuration" );
	    
	    Log3 $name, 4, "HOMEBOT ($name) - To many Errors please check your Network or Device Configuration";

	    readingsBulkUpdate( $hash, "state", "To many Errors" );
	    $hash->{helper}{setCmdErrorCounter} = 0;
	}
	readingsEndUpdate( $hash, 1 );
    }
    
    if( defined( $err ) ) {
	if( $err ne "" ) {
	  readingsBeginUpdate( $hash );
	  readingsBulkUpdate( $hash, "state", $err ) if( ReadingsVal( $name, "state", 0 ) ne "initialized" );
	  $hash->{helper}{setCmdErrorCounter} = ($hash->{helper}{setCmdErrorCounter} + 1);
	  
	  readingsBulkUpdate( $hash, "lastSetCommandState", "cmd_error" );
	  
	  if( $err =~ /timed out/ ) {
	      readingsBulkUpdate( $hash, "lastSetCommandError", "connect to your device is timed out. check network" );
	  }
	  elsif( $err =~ /Keine Route zum Zielrechner/ ) {
	      readingsBulkUpdate( $hash, "lastSetCommandError", "no route to target. bad network configuration or network is down" );
	  } else {
	      readingsBulkUpdate( $hash, "lastSetCommandError", "$err" );
	  }
	  readingsEndUpdate( $hash, 1 );
	  
	  Log3 $name, 5, "HOMEBOT ($name) - HOMEBOT_HTTP_POST: error while POST Command: $err";
	  
	  return;
	}
    }
 
    if( $data eq "" and exists( $param->{code} ) && $param->{code} ne 200 ) {
	readingsBeginUpdate( $hash );
	readingsBulkUpdate( $hash, "state", $param->{code} ) if( ReadingsVal( $hash, "state", 0 ) ne "initialized" );
	
	$hash->{helper}{setCmdErrorCounter} = ( $hash->{helper}{setCmdErrorCounter} + 1 );

	readingsBulkUpdate($hash, "lastSetCommandState", "cmd_error" );
	readingsBulkUpdate($hash, "lastSetCommandError", "http Error ".$param->{code} );
	readingsEndUpdate( $hash, 1 );
    
	Log3 $name, 5, "HOMEBOT ($name) - HOMEBOT_HTTP_POST: received http code ".$param->{code};

	return;
    }
        
    if( ( $data =~ /Error/i ) and exists( $param->{code} ) ) {
	readingsBeginUpdate( $hash );
	readingsBulkUpdate( $hash, "state", $param->{code} ) if( ReadingsVal( $name, "state", 0 ) ne "initialized" );
	
	$hash->{helper}{setCmdErrorCounter} = ( $hash->{helper}{setCmdErrorCounter} + 1 );

	readingsBulkUpdate( $hash, "lastSetCommandState", "cmd_error" );
    
	    if( $param->{code} eq 404 ) {
		readingsBulkUpdate( $hash, "lastSetCommandError", "HTTP Server at Homebot is offline!" );
	    } else {
		readingsBulkUpdate( $hash, "lastSetCommandError", "http error ".$param->{code} );
	    }
	
	return;
    }
    
    ### End Error Handling
    
    readingsSingleUpdate( $hash, "lastSetCommandState", "cmd_done", 1 );
    $hash->{helper}{setCmdErrorCounter} = 0;
    
    return undef;
}

sub HOMEBOT_Header2Hash($) {       
    my ( $string ) = @_;
    my %hash = ();

    foreach my $line (split("\r\n", $string)) {
        my ($key,$value) = split( ": ", $line );
        next if( !$value );

        $value =~ s/^ //;
        $hash{$key} = $value;
    }     
        
    return \%hash;
}




1;

=pod
=begin html

<a name="HOMEBOT"></a>
<h3>HOMEBOT</h3>
<ul>

</ul>

=end html
=begin html_DE

<a name="HOMEBOT"></a>
<h3>HOMEBOT</h3>
<ul>

</ul>

=end html_DE
=cut