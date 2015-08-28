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

multi sub MAIN("add", $date, Int $kilometer) {
	say "add";

	my $posix = date_is_valid($date);
	die "Could not recognize date string '$date'. Expect patter dd.mm.yyyy" unless $posix;

	die "$date already exists in the database. Use command change to alter existing entry" if date_exists($date);

	my $sth = $dbh.prepare(q:to/STATEMENT/);
		INSERT INTO bycicle_kilometer(bk_date, bk_kilometer) VALUES(?,?)
		STATEMENT

	$sth.execute($posix, $kilometer);
	$sth.finish;
	say "added";

}

multi sub MAIN("change", $date, $kilometer) {
	say "change";
}

multi sub MAIN("average", $type) {
	say "average";
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

sub date_is_valid($date) {
	if $date ~~ / <day> \. <month> \. <year> / {
		my $d = DateTime.new(year => +$<year>, month => +$<month>, day => +$<day>);
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
