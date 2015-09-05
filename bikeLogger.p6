#!/usr/bin/env perl6

use v6;
use DBIish;

#########################
# Variables
# #######################
my $dbh = DBIish.connect("SQLite", :database<bycicle_kilometer.sqlite3>, :RaiseError);

my token day	{ \d+ };
my token month	{ \d+ };
my token year	{ \d+ };

multi sub MAIN("delete-database") {
	my $answer = prompt "Do you realy want to delete the database? ";
	if "y" eq lc $answer {
		say "Delete database";
		my $sth = $dbh.do('DROP TABLE if exists bycicle_kilometer');
	} else {
		say "Do not delete database!";
	}
}

multi sub MAIN("create-database") {
	say "Create new database";
	$dbh.do(q:to/STATEMENT/);
		CREATE TABLE if not exists bycicle_kilometer (
			bk_id			INTEGER PRIMARY KEY AUTOINCREMENT,
			bk_date			int,
			bk_kilometer	int
		)
		STATEMENT
}

multi sub MAIN("add-nonstop") {
	my $answer = prompt("Enter 'date' 'kilometer' ('q' quits Enter Mode): ");
	while 'q' ne lc $answer {
		my ($date, $kilometer) = split(' ', $answer);
		if $date && $kilometer {
			add_entry($date, $kilometer);
		} else {
			say "Could not regonize '$answer'";
		}
		$answer = prompt("Enter 'date' 'kilometer' ('q' quits Enter Mode): ");
	}
}

multi sub MAIN("add", $date, Int $kilometer) {
	add_entry($date, $kilometer);
}

multi sub MAIN("change", $date, $kilometer) {
	say "change";
}

multi sub MAIN("average", $type) {
	# first find out what the user want to know.
	# Initial first the database query
	
	my $sth = $dbh.prepare(q:to/STATEMENT/);
		SELECT bk_date, bk_kilometer FROM bycicle_kilometer ORDER BY bk_date
		STATEMENT
	$sth.execute;
	my $array_ref = $sth.fetchall_arrayref;

	my @data_sink;
	my $start_date = DateTime.new(year => 2012, month => 6, day => 19);
	my $last_date = DateTime.new(year => 2012, month => 6, day => 19);
	my $last_kilometer = 0;
	for $array_ref.values -> $date_kilo_array {
		my $d = DateTime.new(+$date_kilo_array[0]);

		# calculate days since last entry.
		my $days = 0;
		while $last_date.posix < $d.posix {
			$days++;
			$last_date = $last_date.later(days => 1);
		}

		my $hash = %(
			dateTime => $d,
			datePosix => $d.posix,
			kilometerTotal => $date_kilo_array[1],
			kilometer => $date_kilo_array[1] - $last_kilometer,
			days => $days,
		);

		@data_sink.push($hash);
		$last_date = $d;
		$last_kilometer = $date_kilo_array[1];
	}

	for @data_sink.values -> $item {
		my $posix = get_date_from_posix(+$item<datePosix>);
		my $kilo_per_day = (0 == $item<days>) ?? 0 !! $item<kilometer> / $item<days>;
		printf("%10s %5d %3d %4d %.02f\n",	$posix,
								$item<kilometerTotal>,
								$item<days>,
								$item<kilometer>,
								$kilo_per_day,);
	}
}

multi sub MAIN("list") {
	my $sth = $dbh.prepare(q:to/STATEMENT/);
		SELECT bk_date, bk_kilometer FROM bycicle_kilometer ORDER BY bk_date
		STATEMENT
	$sth.execute;
	my $arrayref = $sth.fetchall_arrayref;

	say "Date		Kilometer";
	for $arrayref.values {
		say get_date_from_posix(+$_[0]), "\t", $_[1];
	}
}

multi sub MAIN("import", $f) {
	say "Import: ", $f;

	for $f.IO.lines -> $line {
		my ($date, $kilometer) = split ',', $line;
		say "Date $date . kilometer $kilometer";
		add_entry($date, $kilometer);
	}
}

multi sub MAIN("delete", $date) {
	say "Delete $date";

	remove_entry($date);
}

##########################################################
#
#							SUBS
#
##########################################################

sub add_entry($date, $kilometer) {
	my $posix = date_is_valid($date);
	die "Could not recognize date string '$date'. Expect patter dd.mm.yyyy" unless $posix;

	die "$date already exists in the database. Use command change to alter existing entry" if date_exists($date);

	my $sth = $dbh.prepare(q:to/STATEMENT/);
		INSERT INTO bycicle_kilometer(bk_date, bk_kilometer) VALUES(?,?)
		STATEMENT

	$sth.execute($posix, $kilometer);
	$sth.finish;
	say "added $date";
}


sub remove_entry($date) {
	my $posix = date_is_valid($date);

	if $posix && date_exists($posix) {
		my $sth = $dbh.prepare(q:to/STATEMENT/);
			DELETE FROM bycicle_kilometer WHERE bk_date = ?
			STATEMENT
		$sth.execute($posix);
		$sth.finish;
	} else {
		say "Did not find $date";
	}
}

sub date_is_valid($date) {
	if $date ~~ / <day> \. <month> \. <year> / {
		my $d = DateTime.new(
			year	=> +$<year>,
			month	=> +$<month>,
			day		=> +$<day>);
		return $d.posix;
	}

	if $date ~~ / <day> \. <month> / {
		my $now = DateTime.new(now);
		my $d = DateTime.new(
			year	=> $now.year,
			month	=> +$<month>,
			day		=> +$<day>);
		return $d.posix;
	}

	return False;
}

sub date_exists($date_posix) {
	my $sth = $dbh.prepare(q:to/STATEMENT/);
		SELECT bk_date FROM bycicle_kilometer WHERE bk_date = ?
		STATEMENT
	$sth.execute($date_posix);
	my $arrayref = $sth.fetchall_arrayref();
	if 0 < $arrayref.elems {
		$sth.finish;
		return True;
	}

	return False;
}

sub get_date_from_posix($posix) {
	my $d = DateTime.new($posix);

	return sprintf("%02d.%02d.%d", $d.day,$d.month,$d.year);
}

sub help() {
	say qq:to "ENDHELP";
$?FILE date kilometer energy

date : the date pattern dd.mm.yy
kilometer : the kilometer amount
energy : The energy consumed

ENDHELP
}
