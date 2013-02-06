package Validate;

use Email::Valid;
use HTML::TagFilter;
use HTML::Entities;
use Data::Dumper;
use Encode;
use Encode::Guess;

sub val_alpha {
	my $self = shift;
	my ($mand, $len, $value) = @_;
	if (!$value && $mand) {
		return (undef, { msg => 'cannot be blank' });
	} elsif ($len && (length($value) > $len) ) {
		return (undef, { msg => 'is limited to '.$len.' characters' });
	} elsif ($value && $value !~ /^([A-Za-z äÄöÖüÜß]*)$/) {
		return (undef, { msg => 'can only use letters.' });
	} else {
		my $tf = new HTML::TagFilter;
		if ($value) {	# This is to prevent empty strings from returning as the folder name.
			return ($tf->filter($1));	# $1 is a tricky value. If value is blank $1 will be the name of the folder from the instance script.
		} else {
			return '';	# Take that $1. Conditional statement to the face.
		}
	}
}

sub val_number {
	my $self = shift;
	my ($mand, $len, $value) = @_;
	if ((!defined $value or $value eq '') && $mand) {
		return (undef, { msg => 'cannot be blank' });
	} elsif ($len && (length($value) > $len) ) {
		return (undef, { msg => 'is limited to '.$len.' characters' });
	} elsif ($value && $value !~ /^([-\.]*\d[\d\.-]*)$/) {
		return (undef, { msg => 'can only use numbers and . or -' });
	} else {
		if ($value) {	# This is to prevent empty strings from returning as the folder name.
			return ($1);	# $1 is a tricky value. If value is blank $1 will be the name of the folder from the instance script.
		} else {
			return '';	# Take that $1. Conditional statement to the face.
		}
	}
}

sub val_float {   #  Validation that requires just a number
	my $self = shift;
	my ($mand, $len, $value) = @_;
	if ($value eq '' && $mand) {
		return (undef, { msg => 'cannot be blank' });
	} elsif ($len && (length($value) > $len) ) {
		return (undef, { msg => 'is limited to '.$len.' characters' });
	} elsif (( $value == 0 || $value ) && $value !~ /^([\.]*\d[\d\.]*)$/) {
		return (undef, { msg => 'can only use numbers and .' });
	} else {
    	return ($1);
	}
}

#--- Include 0
sub val_whole {
	my $self = shift;
	my ($mand, $value) = @_;

	if ($value != 0 && !$value && $mand) {
		return (undef, { msg => 'cannot be blank.' });
	} elsif (!is_whole($value) ) {
		return (undef, { msg => 'must be 0 or greater and cannot use decimals' });
	} else {
    	return ($value);
	}
}
sub is_whole ($) {
    return unless defined $_[0];
    return unless $_[0] =~ /^[\d.]+$/;
    return 1;
}

sub val_int {
	my $self = shift;
	my ($mand, $value) = @_;
	if ($value != 0 && !$value && $mand) {
		return (undef, { msg => 'cannot be blank.' });
	} elsif ($value !~ /^[-]?\d+$/) {
		return (undef, { msg => 'can only use numbers' });
	} else {
    	return ($1);
	}
}

sub val_alphanum {
	my $self = shift;
	my ($mand, $len, $value) = @_;
	if (!$value && $mand) {
		return (undef, { msg => 'cannot be blank' });
	} elsif ($len && (length($value) > $len) ) {
		return (undef, { msg => 'is limited to '.$len.' characters.' });
	} elsif ($value && $value !~ /^(\w*)$/) {
		return (undef, { msg => 'can only use letters, numbers and _' });
	} else {
		my $tf = new HTML::TagFilter;
		if ($value) {	# This is to prevent empty strings from returning as the folder name.
			return ($tf->filter($1));	# $1 is a tricky value. If value is blank $1 will be the name of the folder from the instance script.
		} else {
			return '';	# Take that $1. Conditional statement to the face.
		}
	}
}

sub val_alphanumspc {
	my $self = shift;
	my ($mand, $len, $value) = @_;
	if (!$value && $mand) {
		return (undef, { msg => 'cannot be blank' });
	} elsif ($len && (length($value) > $len) ) {
		return (undef, { msg => 'is limited to '.$len.' characters' });
	} elsif ($value && $value !~ /^([\w ]*)$/) {
		return (undef, { msg => 'can only use letters, numbers, spaces and _' });
	} else {
		my $tf = new HTML::TagFilter;
		if ($value) {	# This is to prevent empty strings from returning as the folder name.
			return ($tf->filter($1));	# $1 is a tricky value. If value is blank $1 will be the name of the folder from the instance script.
		} else {
			return '';	# Take that $1. Conditional statement to the face.
		}
	}
}

sub val_input {
	my $self = shift;
	my ($mand, $len, $value) = @_;
	if (!$value && $mand) {
		return (undef, { msg => 'cannot be blank' });
	} elsif ($len && (length($value) > $len) ) {
		return (undef, { msg => 'is limited to '.$len.' characters' });
	} elsif ($value && $value !~ /^([\w \.\,\-\(\)\?\:\;\"\!\'\/\n\r]*)$/) {
		return (undef, { msg => 'can only use letters, numbers, spaces and -.,&:\'' });
	} else {
		my $tf = new HTML::TagFilter;
		if ($value) {	# This is to prevent empty strings from returning as the folder name.
			return ($tf->filter($1));	# $1 is a tricky value. If value is blank $1 will be the name of the folder from the instance script.
		} else {
			return '';	# Take that $1. Conditional statement to the face.
		}
	}
}

sub val_text {
	my $self = shift;
	my ($mand, $len, $value) = @_;

	# To ensure the text is correctly encoded etc. SZ 7/12/12
	#my $decoder = Encode::Guess->guess($value);	# First guess the decoder
	#if (ref($decoder)){
	#	$value = $decoder->decode($value);	# If a decoder is found, then decode.
	#}
	#$value = Encode::encode_utf8($value);	# If there is no decoder, assume its UTF8

	if ($mand && (!$value || $value =~ /bogus="1"/)) {  #tiny mce
		return (undef, { msg => 'cannot be blank' });
	} elsif ($len && (length($value) > $len) ) {
		return (undef, { msg => 'is limited to '.$len.' characters' });
	} elsif ($value && $value !~ /^([\w \.\,\-\'\"\!\$\#\%\=\&\:\+\(\)\?\;\n\r\<\>\/\@äÄöÖüÜßéÉáÁíÍ]*)$/) {
		return (undef, { msg => 'can only use letters, 0-9 and -.,\'\"!&#$?:()=%<>;/@ (do not cut and paste from a Word document, you must Save As text only)' });
	} else {
		my $tf = new HTML::TagFilter;
		if ($value) {	# This is to prevent empty strings from returning as the folder name.
			return ($tf->filter($1));	# $1 is a tricky value. If value is blank $1 will be the name of the folder from the instance script.
		} else {
			return '';	# Take that $1. Conditional statement to the face.
		}
	}
}

sub val_text_by_words {
	my $self = shift;
	my ($mand, $len, $value) = @_;
	$value =~ s/  / /g;
	my @words = split(/ /,$value);
	if ($mand && (!$value || $value =~ /bogus="1"/)) {  #tiny mce
		return (undef, { msg => 'cannot be blank' });
	} elsif ($len && scalar @words > $len) {
		return (undef, { msg => 'is limited to '.$len.' words' });
	} elsif ($value && $value !~ /^([\w \.\,\-\'\"\!\$\#\%\=\&\:\+\(\)\?\;\n\r\<\>\/\@]*)$/) {
		return (undef, { msg => 'can only use letters, 0-9 and -.,\'\"!&#$?:()=%<>;/@ (do not cut and paste from a Word document, you must Save As text only)' });
	} else {
		my $tf = new HTML::TagFilter;
    	return ($tf->filter($1));
	}
}

sub val_html {
	my $self = shift;
	my ($mand, $len, $value) = @_;
	if (!$value && $mand) {
		return (undef, { msg => 'cannot be blank' });
	} elsif ($len && (length($value) > $len) ) {
		return (undef, { msg => 'is limited to '.$len.' characters' });
	} elsif ($value && $value !~ /^([\w \.\,\-\'\"\!\$\#\%\=\&\:\+\(\)\?\;\n\r\<\>\/\@äÄöÖüÜß]*)$/) {
		return (undef, { msg => 'can only use letters, 0-9 and -.,\'\"!&#$?:()=%<>;/@ (do not cut and paste from a Word document, you must Save As text only)' });
	} else {
		return $value;
	}
}

sub val_email { 
	my $self = shift;
	my ($mand, $value) = @_;
	if ( !Email::Valid->address($value) && $mand ) { 
		return ( undef, { msg => 'address is blank or not valid' }	);
	} elsif ( !Email::Valid->address($value) && $value ) {
		return ( undef, { msg => 'address is blank or not valid' }	);
	} else {
		return $value;
	}
}

sub val_selected {
	my $self = shift;
	my ($value) = @_;
	if (!$value) {
		return (undef, { msg => 'must be selected' });
	} else {
		return $value;
	}
}

sub val_filename {
	my $self = shift;
	my ($mand, $endings, $value) = @_;
	
	if (!$endings) { $endings = "jpg|jpeg|png|gif|flv|swf|css|html|htm|js|xml|xls|docx|pages|doc|pdf"; }
	
	$value =~ s/^(?:(?:[-\\\/\w :.]+)(?:\/|\\)){0,512}([-\w. ]{0,255})/$1/;

	if (!$value && $mand) {
		return (undef, { msg => 'cannot be blank.' });
	} elsif ($value && $value !~ /^[-\w \.]{1,255}\.$endings$/i) {
		return (undef, { msg => 'does not appear to 1) to be the correct file type ('.$endings.'), 2) have an file extension (ex: .txt), or 3) to be in a valid file format.' });
	} elsif ($value) {
		return $value;
	}
}

sub val_exact_filename {
	my $self = shift;
	my ($mand, $exactname, $value) = @_;
		
	if (!$value && $mand) {
		return (undef, { msg => 'cannot be blank' });
	} elsif ($value && $value !~ /^($exactname)$/i) {
		return (undef, { msg => 'is not named correctly ('.$exactname.')' });
	} elsif ($value) {
		return ($1);
	}
}

sub val_date {
	my $self = shift;
	my ($mand, $value) = @_;
	if (!$value && $mand) {
		return (undef, { msg => 'cannot be blank' });
	} elsif ($value && $value !~ /^(0[1-9]|1[0-2])[\-\/](0[1-9]|[1-2][0-9]|3[0-1])[\-\/](\d{4})$/) {
		return (undef, { msg => 'is not in a valid date format of mm-dd-yyyy or is out of range' });
	} elsif ($value) {
		return "$1-$2-$3";
	}
}

sub val_time {
	my $self = shift;
	my ($mand, $value) = @_;
	if (!$value && $mand) {
		return (undef, { msg => 'cannot be blank' });
	} elsif ($value && $value !~ /^(0[1-9]|[1-9]|1[0-2]):([0-5][0-9])$/) {
		return (undef, { msg => 'is not in a valid time format of hh:mm or is out of range' });
	} elsif ($value) {
		return "$1:$2";
	}
}

sub val_wordwash {
	my $self = shift;
	my ($mand, $len, $value) = @_;
	if (!$value && $mand) {
		return (undef, { msg => 'cannot be blank' });
	} elsif ($len && (length($value) > $len) ) {
		return (undef, { msg => 'is limited to '.$len.' characters' });
	} elsif ($value) {
		$value =~ s/[^\w \.\,\-\(\)\?\:\;\"\!\'\/\n\r]+//g;
		return $value;
	}
}

sub val_word {
	my $self = shift;
	my ($mand, $len, $value) = @_;
	$value =~ s/’/&rsquo;/g;
	$value =~ s/•/&bull;/g;
	$value =~ s/“|”/"/g;
	$value =~ s/–/&ndash;/g;
	$value =~ s/—/&mdash;/g;
	$value =~ s/‘/&lsquo;/g;
	$value =~ s/™/&trade;/g;
	$value =~ s/…/\.\.\./g;
	$value =~ s/©/&copy;/g;
	$value =~ s/·/&middot;/;
	$value =~ s/§/&sect;/g;
	$value =~ s/®/&reg;/g;
	$value =~ s/¶/&para;/g;
	$value =~ s/†/&dagger;/g;
	$value =~ s/‡/&Dagger;/g;
	$value =~ s/¢/&cent;/g;
	$value =~ s/£/&pound;/g;
	$value =~ s/¥/&yen;/g;
	$value =~ s/	/ /g;
	$value =~ s/ /&nbsp;/g;
	if ($mand && (!$value || $value =~ /bogus="1"/)) {  #tiny mce
		return (undef, { msg => 'cannot be blank' });
	} elsif ($len && (length($value) > $len) ) {
		return (undef, { msg => 'is limited to '.$len.' characters' });
	} elsif ( $value && $value =~ /<m:|mso\-|<o:|<w:|Word\.Document/ ) {
		return (undef, { msg => ': Do not cut and paste anything from Word, but first save out as raw text,  then open in Note Pad (PC) or Text Edit (Mac), and  copy/paste from there.' });
	} elsif ($value && $value !~ /^([\w \.\,\-\'\"\!\$\#\%\=\&\:\+\[\]~\(\)\?\;\n\r\<\>\*\/\@]*)$/) {
		return (undef, { msg => 'can only use letters, 0-9 and -.,\'"!&#$?:()=%<>;/@ (do not cut and paste from a Word document, you must Save As text only)' });
	} else {
		my $tf = new HTML::TagFilter;
		if ($value) {	# This is to prevent empty strings from returning as the folder name.
			return ($tf->filter($1));	# $1 is a tricky value. If value is blank $1 will be the name of the folder from the instance script.
		} else {
			return '';	# Take that $1. Conditional statement to the face.
		}
	}
}

sub val_editor {
	my $self = shift;
	my ($value) = @_;
	
   if ( $value =~ /<m:|mso\-|<o:|<w:|Word\.Document/ ) {
		return (undef, { msg => 'Do not cut and paste anything from Word, but first save out as raw text,  then open in Note Pad (PC) or Text Edit (Mac), and  copy/paste from there.' });
	}
}

1;
