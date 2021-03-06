#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Math::Prime::Util qw/binomial factorial factorialmod
                         forcomb forperm forderange formultiperm
                         numtoperm permtonum randperm shuffle/;
my $extra = defined $ENV{EXTENDED_TESTING} && $ENV{EXTENDED_TESTING};

use Math::BigInt try => "GMP,Pari";

my %perms = (
 0 => [[]],
 1 => [[0]],
 2 => [[0,1],[1,0]],
 3 => [[0,1,2],[0,2,1],[1,0,2],[1,2,0],[2,0,1],[2,1,0]],
 4 => [[0,1,2,3],[0,1,3,2],[0,2,1,3],[0,2,3,1],[0,3,1,2],[0,3,2,1],[1,0,2,3],[1,0,3,2],[1,2,0,3],[1,2,3,0],[1,3,0,2],[1,3,2,0],[2,0,1,3],[2,0,3,1],[2,1,0,3],[2,1,3,0],[2,3,0,1],[2,3,1,0],[3,0,1,2],[3,0,2,1],[3,1,0,2],[3,1,2,0],[3,2,0,1],[3,2,1,0]],
);

my @binomials = (
 [ 0,0, 1 ],
 [ 0,1, 0 ],
 [ 1,0, 1 ],
 [ 1,1, 1 ],
 [ 1,2, 0 ],
 [ 13,13, 1 ],
 [ 13,14, 0 ],
 [ 35,16, 4059928950 ],             # We can do this natively even in 32-bit
 [ 40,19, "131282408400" ],         # We can do this in 64-bit
 [ 67,31, "11923179284862717872" ], # ...and this
 [ 228,12, "30689926618143230620" ],# But the result of this is too big.
 [ 177,78, "3314450882216440395106465322941753788648564665022000" ],
 [ -10,5, -2002 ],
 [ -11,22, 64512240 ],
 [ -12,23, -286097760 ],
 [ -23,-26, -2300 ],     # Kronenburg extension
 [ -12,-23, -705432 ],   # same
 [  12,-23, 0 ],
 [  12,-12, 0 ],
 [ -12,0, 1 ],
 [  0,-1, 0 ],
);

# TODO: Add a bunch of combs here:  "5,3" => [[..],[..],[..]],

plan tests => 1                        # Factorial
            + 1 + 1*$extra             # Factorialmod
            + 2 + scalar(@binomials)   # Binomial
            + 7 + 4                    # Combinations
            + scalar(keys(%perms)) + 1 # Permutations
            + 4                        # Multiset Permutations
            + 5                        # Derangements
            + 5 + 5 + 1                # numtoperm, permtonum
            + 5                        # randperm
            + 5                        # shuffle
            ;

###### factorial
sub fact { my $n = Math::BigInt->new("$_[0]"); $n->bfac; }
{
  my @result = map { factorial($_) } 0 .. 100;
  my @expect = map { fact($_) } 0 .. 100;
  is_deeply( \@result, \@expect, "Factorials 0 to 100" );
}

###### factorialmod
{
  my @result = map { my $m=$_; map { factorialmod($_,$m) } 0..$m-1; } 1 .. 40;
  my @expect = map { my $m=$_; map { factorial($_) % $m; } 0..$m-1; } 1 .. 40;
  is_deeply( \@result, \@expect, "factorialmod n! mod m for m 1 to 50, n 0 to m" );
}
if ($extra) {
  is( factorialmod(5000001,"8000036000054000027"), "4179720539133404343", "factorialmod with large n and large composite non-square-free m" );
}

###### binomial
foreach my $r (@binomials) {
  my($n, $k, $exp) = @$r;
  is( binomial($n,$k), $exp, "binomial($n,$k)) = $exp" );
}
is_deeply( [map { binomial(10, $_) } -15 .. 15],
           [qw/0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 10 45 120 210 252 210 120 45 10 1 0 0 0 0 0/],
           "binomial(10,n) for n in -15 .. 15" );
is_deeply( [map { binomial(-10, $_) } -15 .. 15],
           [qw/-2002 715 -220 55 -10 1 0 0 0 0 0 0 0 0 0 1 -10 55 -220 715 -2002 5005 -11440 24310 -48620 92378 -167960 293930 -497420 817190 -1307504/],
           "binomial(-10,n) for n in -15 .. 15" );

###### forcomb
{ my @p = (); forcomb { push @p, [@_] } 0;
  is_deeply( [@p], [[]], "forcomb 0" ); }
{ my @p = (); forcomb { push @p, [@_] } 1;
  is_deeply( [@p], [[],[0]], "forcomb 1" ); }
{ my @p = (); forcomb { push @p, [@_] } 0,0;
  is_deeply( [@p], [[]], "forcomb 0,0" ); }
{ my @p = (); forcomb { push @p, [@_] } 5,0;
  is_deeply( [@p], [[]], "forcomb 5,0" ); }
{ my @p = (); forcomb { push @p, [@_] } 5,6;
  is_deeply( [@p], [], "forcomb 5,6" ); }
{ my @p = (); forcomb { push @p, [@_] } 5,5;
  is_deeply( [@p], [[0,1,2,3,4]], "forcomb 5,5" ); }
{ my @p = (); forcomb { push @p, [@_] } 3;
  is_deeply( [@p], [[],[0],[1],[2],[0,1],[0,2],[1,2],[0,1,2]], "forcomb 3 (power set)" ); }

{ my @data = (qw/apple bread curry/);
  my @p = (); forcomb { push @p, [@data[@_]] } @data,2;
  my @e = ([qw/apple bread/],[qw/apple curry/],[qw/bread curry/]);
  is_deeply( \@p,\@e, "forcomb 3,2" ); }
{ my @data = (qw/ant bee cat dog/);
  my @p = (); forcomb { push @p, [@data[@_]] } @data,3;
  my @e = ([qw/ant bee cat/],[qw/ant bee dog/],[qw/ant cat dog/],[qw/bee cat dog/]);
  is_deeply( \@p,\@e, "forcomb 4,3" ); }

{ my $b = binomial(20,15);
  my $s = 0; forcomb { $s++ } 20,15;
  is($b, 15504, "binomial(20,15) is 15504");
  is($s, $b, "forcomb 20,15 yields binomial(20,15) combinations"); }


###### forperm
while (my($n, $expect) = each (%perms)) {
  my @p = (); forperm { push @p, [@_] } $n;
  is_deeply( \@p, $expect, "forperm $n" );
}

{ my $s = 0; forperm { $s++ } 7;
  is($s, factorial(7), "forperm 7 yields factorial(7) permutations"); }

###### formultiperm
{ my @p; formultiperm { push @p, [@_] } [];
  is_deeply(\@p, [], "formultiperm []"); }

{ my @p; formultiperm { push @p, [@_] } [1,2,2];
  is_deeply(\@p, [ [1,2,2], [2,1,2], [2,2,1] ], "formultiperm 1,2,2"); }

{ my @p; formultiperm { push @p, [@_] } [qw/a a b b/];
  is_deeply(\@p, [map{[split(//,$_)]} qw/aabb abab abba baab baba bbaa/], "formultiperm a,a,b,b"); }

{ my @p; formultiperm { push @p, join("",@_) } [qw/a a b b/];
  is_deeply(\@p, [qw/aabb abab abba baab baba bbaa/], "formultiperm aabb"); }

###### forderange
{ my @p; forderange { push @p, [@_] } 0;
  is_deeply(\@p, [[]], "forderange 0"); }
{ my @p; forderange { push @p, [@_] } 1;
  is_deeply(\@p, [], "forderange 1"); }
{ my @p; forderange { push @p, [@_] } 2;
  is_deeply(\@p, [[1,0]], "forderange 2"); }
{ my @p; forderange { push @p, [@_] } 3;
  is_deeply(\@p, [[1,2,0],[2,0,1]], "forderange 3"); }
{ my $n=0; forderange { $n++ } 7; is($n, 1854, "forderange 7 count"); }

###### numtoperm / permtonum

is_deeply([numtoperm(0,0)],[],"numtoperm(0,0)");
is_deeply([numtoperm(1,0)],[0],"numtoperm(1,0)");
is_deeply([numtoperm(1,1)],[0],"numtoperm(1,1)");
is_deeply([numtoperm(5,15)],[0,3,2,4,1],"numtoperm(5,15)");
is_deeply([numtoperm(24,987654321)],[0,1,2,3,4,5,6,7,8,9,10,13,11,21,14,20,17,15,12,22,18,19,23,16],"numtoperm(24,987654321)");

is(permtonum([]),0,"permtonum([])");
is(permtonum([0]),0,"permtonum([0])");
is(permtonum([6,3,4,2,5,0,1]),4768,"permtonum([6,3,4,2,5,0,1])");
is(permtonum([reverse(0..14),15..19]),"1790774578500738480","permtonum( 20 )");
is(permtonum([reverse(0..12),reverse(13..25)]),"193228515634198442606207999","permtonum( 26 )");

is(permtonum([numtoperm(14,8467582)]),8467582,"permtonum(numtoperm)");

###### randperm
# TODO: better randperm tests

is(@{[randperm(0)]},0,"randperm(0)");
is(@{[randperm(1)]},1,"randperm(1)");
is(@{[randperm(100,4)]},4,"randperm(100,4)");
{ my @p = 1..100;
  my @s = @p[randperm(0+@p)];
  isnt("@s", "@p", "randperm shuffle has shuffled input");
  my @ss = sort { $a<=>$b } @s;
  is("@ss", "@p", "randperm shuffle contains original data");
}

###### shuffle

is_deeply([shuffle()],[],"shuffle with no args");
is_deeply([shuffle("a")],["a"],"shuffle with one arg");
{ my @p = 1..100;
  my @s = shuffle(@p);
  is(0+@s,0+@p,"argument count is the same for 100 elem shuffle");
  isnt("@s", "@p", "shuffle has shuffled input");
  my @ss = sort { $a<=>$b } @s;
  is("@ss", "@p", "shuffle contains original data");
}
